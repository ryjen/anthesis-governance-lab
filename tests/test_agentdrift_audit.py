"""Offline tests for source-locked AgentDrift audit and externally supplied scores."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from tools import agentdrift_audit as audit


def trajectory(ident, split, category, labels, *, task=None, world=None):
    return {
        "id": ident,
        "split": split,
        "agent": "coding",
        "task": task or f"distinct task for {ident}",
        "world": world or {"company": f"world-{ident}"},
        "category": "attacked" if category in audit.POSITIVE else category,
        "source_category": category,
        "steps": [{"label": label, "tool": "synthetic"} for label in labels],
    }


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


class AgentDriftAuditTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.rows = {
            "train": [trajectory("train", "train", "benign", ["benign"] * 3)],
            "val": [trajectory("val", "val", "hard_negative", ["benign"] * 3)],
            "test": [
                trajectory("bn", "test", "benign", ["benign"] * 3),
                trajectory("hn", "test", "hard_negative", ["benign"] * 3),
                trajectory("resisted", "test", "failed_attack",
                           ["benign", "failed_injection", "benign"]),
                trajectory("full", "test", "attacked_full",
                           ["benign", "injection_point", "hijacked"]),
                trajectory("partial", "test", "attacked_partial",
                           ["benign", "injection_point", "hijacked", "benign"]),
                trajectory("delayed", "test", "attacked_delayed",
                           ["benign", "injection_point", "benign", "hijacked", "benign"]),
            ],
        }

    def create_source(self):
        files = {}
        for split, rows in self.rows.items():
            path = self.root / "data_taskdisjoint" / f"{split}.jsonl"
            path.parent.mkdir(parents=True, exist_ok=True)
            data = "".join(json.dumps(x) + "\n" for x in rows).encode()
            path.write_bytes(data)
            files[split] = {
                "relative_path": f"data_taskdisjoint/{split}.jsonl",
                "git_blob_sha1": git_blob(data),
                "count": len(rows),
            }
        return {
            "version": "anthesis-governance-lab.agentdrift-source-lock/v1",
            "split_profile": "data_taskdisjoint",
            "revision": "synthetic-unit-test-only",
            "files": files,
        }

    def perfect_predictions(self):
        return ("\n".join(json.dumps({
            "id": row["id"],
            "attacked": row["source_category"] in audit.POSITIVE,
            "step_labels": [step["label"] for step in row["steps"]],
        }) for row in self.rows["test"]) + "\n").encode()

    def test_disjoint_source_and_perfect_predictions(self):
        manifest = self.create_source()
        report, ground = audit.audit(self.root, manifest)
        self.assertEqual(report["counts"], {"train": 1, "val": 1, "test": 6})
        self.assertTrue(report["source_sha1_verified"])
        self.assertTrue(report["task_disjoint_verified"])
        self.assertTrue(report["exact_world_object_disjoint_verified"])
        self.assertFalse(report["world_identity_leakage_ruled_out"])
        result = audit.score_predictions(self.perfect_predictions(), ground)
        self.assertEqual(result["trajectory"]["tp"], 3)
        self.assertEqual(result["trajectory"]["fp"], 0)
        self.assertEqual(result["trajectory"]["f1"], 1)
        self.assertEqual(result["injection_index_exact_match_attacked"], 1)
        self.assertEqual(result["hijacked_span_mean_iou_attacked"], 1)
        self.assertEqual(result["macro_step_label_f1"], 1)
        for name in audit.NEGATIVE:
            self.assertEqual(result["false_positive_rates"][name]["rate"], 0)
        for name in audit.POSITIVE:
            self.assertEqual(result["recall_by_attack_pattern"][name]["rate"], 1)

    def test_missed_delayed_and_false_positive_are_separate(self):
        manifest = self.create_source()
        _, ground = audit.audit(self.root, manifest)
        predictions = [json.loads(line) for line in self.perfect_predictions().splitlines()]
        for p in predictions:
            if p["id"] == "delayed":
                p["attacked"] = False
                p["step_labels"] = ["benign"] * len(p["step_labels"])
            if p["id"] == "hn":
                p["attacked"] = True
        score = audit.score_predictions(b"\n".join(json.dumps(x).encode() for x in predictions), ground)
        self.assertEqual(score["trajectory"]["fn"], 1)
        self.assertEqual(score["trajectory"]["fp"], 1)
        self.assertEqual(score["false_positive_rates"]["hard_negative"]["rate"], 1)
        self.assertEqual(score["false_positive_rates"]["benign"]["rate"], 0)
        self.assertEqual(score["false_positive_rates"]["failed_attack"]["rate"], 0)
        self.assertEqual(score["recall_by_attack_pattern"]["attacked_delayed"]["rate"], 0)
        self.assertEqual(score["recall_by_attack_pattern"]["attacked_full"]["rate"], 1)
        self.assertLess(score["macro_step_label_f1"], 1)

    def test_source_tamper_fails_closed(self):
        manifest = self.create_source()
        test = self.root / "data_taskdisjoint" / "test.jsonl"
        test.write_bytes(test.read_bytes() + b"\n")
        with self.assertRaisesRegex(audit.AuditError, "Git blob SHA mismatch"):
            audit.audit(self.root, manifest)

    def test_cross_split_task_overlap_is_reported(self):
        self.rows["test"][0]["task"] = self.rows["train"][0]["task"]
        report, _ = audit.audit(self.root, self.create_source())
        self.assertEqual(report["task_overlap_keys_across_splits"], 1)
        self.assertFalse(report["task_disjoint_verified"])

    def test_cross_split_world_overlap_is_reported_without_raw_identity(self):
        self.rows["test"][0]["world"] = self.rows["train"][0]["world"]
        report, _ = audit.audit(self.root, self.create_source())
        self.assertEqual(report["world_overlap_keys_across_splits"], 1)
        self.assertEqual(report["test_records_with_world_overlap"], 1)
        self.assertNotIn("world-train", json.dumps(report))

    def test_invalid_step_grammar_is_rejected(self):
        self.rows["test"][3]["steps"][1]["label"] = "failed_injection"
        with self.assertRaisesRegex(audit.AuditError, "step grammar"):
            audit.audit(self.root, self.create_source())

    def test_prediction_missing_or_duplicate_ids_rejected(self):
        _, ground = audit.audit(self.root, self.create_source())
        lines = self.perfect_predictions().splitlines()
        with self.assertRaisesRegex(audit.AuditError, "do not exactly match"):
            audit.score_predictions(b"\n".join(lines[:-1]), ground)
        with self.assertRaisesRegex(audit.AuditError, "unexpected/duplicate"):
            audit.score_predictions(b"\n".join(lines + [lines[-1]]), ground)

    def test_prediction_schema_and_length_rejected(self):
        _, ground = audit.audit(self.root, self.create_source())
        lines = [json.loads(x) for x in self.perfect_predictions().splitlines()]
        lines[0]["step_labels"] = []
        with self.assertRaisesRegex(audit.AuditError, "step count"):
            audit.score_predictions(b"\n".join(json.dumps(x).encode() for x in lines), ground)
        lines[0]["step_labels"] = [x["label"] for x in self.rows["test"][0]["steps"]]
        lines[0]["approved"] = True
        with self.assertRaisesRegex(audit.AuditError, "prediction schema"):
            audit.score_predictions(b"\n".join(json.dumps(x).encode() for x in lines), ground)


if __name__ == "__main__":
    unittest.main()

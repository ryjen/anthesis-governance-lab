{
  description = "Anthesis Governance Lab development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bash
            coreutils
            cosign
            curl
            git
            gnugrep
            gnutar
            gzip
            jq
            realpath
            sha256sum
          ];

          shellHook = ''
            echo "Anthesis Governance Lab dev shell"
            echo "Includes cosign and documented validation dependencies."
          '';
        };
      });
}

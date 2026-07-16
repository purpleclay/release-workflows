{
  description = "Reusable release workflows for purpleclay projects — SLSA Build L3 provenance, SBOM attestation, and keyless Sigstore signing";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    git-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          package = pkgs.prek;
          hooks = {
            alejandra = {
              enable = true;
              settings = {
                check = true;
              };
            };

            typos = {
              enable = true;
            };

            zizmor = {
              enable = true;
            };
          };
        };
      in
        with pkgs; {
          devShells.default = mkShell {
            inherit (pre-commit-check) shellHook;

            buildInputs =
              [
                alejandra
                nil
                typos
                zizmor
              ]
              ++ pre-commit-check.enabledPackages;
          };
        }
    );
}

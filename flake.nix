# Sources:
# https://pyproject-nix.github.io/pyproject.nix/use-cases/pyproject.html
# https://pyproject-nix.github.io/uv2nix/usage/hello-world.html

{
  description = "Python project environment flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];
      perSystem =
        {
          self',
          pkgs,
          lib,
          ...
        }:
        let
          project = pyproject-nix.lib.project.loadPyproject { projectRoot = ./.; };
          workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

          overlay = workspace.mkPyprojectOverlay {
            sourcePreference = "wheel";
          };

          pyprojectOverrides = _final: _prev: {
            # Implement build fixups here.
          };

          python = pkgs.python3;

          pythonSet =
            (pkgs.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope
              (
                lib.composeManyExtensions [
                  pyproject-build-systems.overlays.default
                  overlay
                  pyprojectOverrides
                ]
              );

        in
        {
          packages = {
            default = self'.packages.package;
            package = python.pkgs.buildPythonPackage (
              (project.renderers.buildPythonPackage { inherit python; }) // { env.CUSTOM_ENVVAR = "hello"; }
            );
            package-env = pythonSet.mkVirtualEnv "package-env" workspace.deps.default;
          };

          devShells = {
            default =
              let
                arg = project.renderers.withPackages {
                  inherit python;
                  extras = [
                    # Add groups found under optional-dependencies
                  ];
                };

                pythonEnv = python.withPackages arg;
              in
              pkgs.mkShell {
                packages = [
                  pythonEnv
                  self'.packages.package
                ];
              };

            impure = pkgs.mkShell {
              packages = [
                python
                pkgs.uv
              ];
              shellHook = ''
                unset PYTHONPATH
              '';
            };

            uv2nix =
              let
                editableOverlay = workspace.mkEditablePyprojectOverlay {
                  root = "$REPO_ROOT";
                };

                editablePythonSet = pythonSet.overrideScope editableOverlay;

                virtualenv = editablePythonSet.mkVirtualEnv "package-dev-env" workspace.deps.default;

              in
              pkgs.mkShell {
                packages = [
                  virtualenv
                  pkgs.uv
                ];
                shellHook = ''
                  unset PYTHONPATH
                  export REPO_ROOT=$(git rev-parse --show-toplevel)
                '';
              };
          };
        };
    };
}

# python.nix

A python development environment using flakes, pyproject.nix and uv2nix.

- The flake is loaded using direnv on entry to the project directory.
- Using pyproject.nix a development shell is created
  with all packages found in the local pyproject.toml file fetched from nixpkgs.
- uv2nix uses pyproject.nix in the background,
  but builds the packages found in pyproject.toml on the fly.
  It also updates the project live without the need of a manual reload.

## Shells

Three shells are available:

1. The **default** shell is based on pyproject.nix.
   Please keep in mind, that all packages need to be available in nixpkgs.
2. An **impure** shell is available for developing on non NixOS systems
   or if one is needed for different reasons. You can use uv to manage dependencies.
   Keep in mind that packages as `numpy` will not work on NixOS systems,
   since additional libraries need to be available (`numpy` depends on `zlib`).
3. If you want to have your package always up to date with,
   you can use the **uv2nix** shell.

## Workflows

- `flake.yml` checks if all outputs of the flake are correct.
  Only because it runs on your machine, does not mean it will on all supported systems.
- `pypi.yml` publishes the package to [pypi](https://pypi.org/).

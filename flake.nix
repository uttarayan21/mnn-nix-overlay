{
  description = "A simple wrapper over mnn to use as a nix package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mnn.url = "github:alibaba/MNN/3.3.0";
    mnn.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      version = "3.3.0";
      overlays = [
        (final: prev: {
          mnn = pkgs.callPackage ./mnn.nix {
            src = inputs.mnn;
            inherit version;
            buildConverter = true;
          };
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in {
      overlays = {
        default = final: prev: {
          mnn = pkgs.callPackage ./mnn.nix {
            inherit version;
            src = inputs.mnn;
          };
        };
      };
      packages = {
        default = pkgs.mnn;
        mnn = pkgs.mnn;
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [mnn];
      };
    });
}

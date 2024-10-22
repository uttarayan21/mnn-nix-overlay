{
  description = "A simple wrapper over mnn to use as a nix package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mnn.url = "github:alibaba/MNN/2.9.6";
    mnn.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        (final: prev: {
          mnn = pkgs.callPackage ./mnn.nix {
            src = inputs.mnn;
            version = "2.9.6";
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
            version = "2.9.6";
            src = inputs.mnn;
          };
        };
      };
      packages = {
        default = pkgs.mnn;
        mnn = pkgs.mnn;
      };
    });
}

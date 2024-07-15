{
  description = "A simple wrapper over mnn to use as a nix package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [
        (final: prev: {
          mnn = pkgs.callPackage ./mnn.nix {};
        })
      ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in {
      overlays = {
        default = final: prev: {
          mnn = pkgs.callPackage ./mnn.nix {};
        };
      };
      packages = {
        default = pkgs.mnn;
        mnn = pkgs.mnn;
      };
    });
}

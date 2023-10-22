{
  description = "A simple rust flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.utils.url = "github:numtide/flake-utils";
  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "utils";
    };
  };
  inputs.crane = {
    url = "github:ipetkov/crane";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, utils, rust-overlay, crane }:
    utils.lib.eachDefaultSystem (system: let
      overlays = [ (import rust-overlay) ];
      pkgs = import nixpkgs { inherit system overlays; };
      rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

      photodedupe = craneLib.buildPackage {
        src = craneLib.cleanCargoSource (craneLib.path ./.);
        strictDeps = true;
        doCheck = false;
      };
      photodedupe-app = utils.lib.mkApp {
        drv = photodedupe;
      };

      shell = with pkgs; mkShell {
        buildInputs = [ rustToolchain ];
        packages = [];
      };
    in {
      checks = { inherit photodedupe; };

      packages.photodedupe = photodedupe;
      packages.default = photodedupe;

      app.photodedupe = photodedupe-app;
      app.default = photodedupe-app;

      devShells.default = shell;
    });
}


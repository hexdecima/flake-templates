{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-26.05";
    naersk-flake.url = "github:nix-community/naersk";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ nixpkgs, rust-overlay, naersk-flake, ... }: let
    readToml = file: builtins.fromTOML (builtins.readFile file);
    systems = [ "x86_64-linux" "aarch64-linux" ];
    overlays = [ (import rust-overlay) ];
    eachSystem = fn: nixpkgs.lib.genAttrs systems 
      (system: fn (import nixpkgs { inherit system overlays; }));
  in {
    devShells = eachSystem (pkgs: let 
      toolchain = (readToml ./rust-toolchain.toml).toolchain;
      rust = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchain {
        inherit (toolchain) channel components targets; 
      };
    in {
      default = pkgs.mkShell {
        packages = (with pkgs; [ just bacon nil nixfmt taplo ]) ++ [ rust ];
      };
    });

    packages = eachSystem (pkgs: let 
      toolchain = (readToml ./rust-toolchain.toml).toolchain;
      rust = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchain {
        inherit (toolchain) channel components targets; 
      };
        naersk = pkgs.callPackage naersk-flake {
          cargo = rust;
          rustc = rust;
        };
    in {
      default = naersk.buildPackage { src = ./.; };
    });
  };
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-26.05";
    rust = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ nixpkgs, rust, ... }: let 
    readToml = file: builtins.fromTOML (builtins.readFile file);
    systems = [ "x86_64-linux" "aarch64-linux" ];
    overlays = [ (import rust) ];
    eachSystem = fn: nixpkgs.lib.genAttrs systems 
      (system: fn (import nixpkgs { inherit system overlays; }));
  in {
    devShells = eachSystem (pkgs: let 
      toolchain = (readToml ./rust-toolchain.toml).toolchain;
      rustBin = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchain {
        inherit (toolchain) channel components targets; 
      };
    in {
      default = pkgs.mkShell { packages = with pkgs; [ 
        rustBin just bacon nil nixfmt-classic taplo 
      ];
      };
    });
  };
}

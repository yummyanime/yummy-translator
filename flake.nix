{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flakelight = {
      url = "github:nix-community/flakelight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { flakelight, ... }:
    flakelight ./. {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      devShell.packages = pkgs: [
        pkgs.python312
        pkgs.python312Packages.fastapi
        pkgs.python312Packages.requests
        pkgs.python312Packages.pysocks
        pkgs.python312Packages.uvicorn
        pkgs.python312Packages.google-generativeai
      ];
    };
}

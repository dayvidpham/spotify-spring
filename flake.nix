{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = inputs@{ self, nixpkgs, flake-utils, ... }: 
    flake-utils.lib.eachDefaultSystem (system:
    let
        pkgs = nixpkgs.legacyPackages.${system};
        java = pkgs.jdk21_headless;
        # idea = pkgs.callPackage pkgs.jetbrains.idea-community { jdk = java; };
        idea =  pkgs.jetbrains.idea-community;
        nativeBuildInputs = with pkgs; [
          idea
          java
          maven
        ];
    in {
        devShells.default = pkgs.mkShell {
            inherit nativeBuildInputs;
        };
    });
}

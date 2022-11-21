{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
    buildInputs = [ elmPackages.elm ];

    shellHook = ''
        alias build="elm make src/Main.elm --output=docs/index.html --optimize"
    '';
}
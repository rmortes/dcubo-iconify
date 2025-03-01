{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [ 
      dart
      flutter
    ];

    shellHook = ''
      export PATH="$PATH":"$HOME/.pub-cache/bin"
    '';
}
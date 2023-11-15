{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = with pkgs.buildPackages; [
      dart-sass
      css-html-js-minify
      pandoc
      watchexec
      nodejs_20
      httplz
      shellcheck
    ];
}
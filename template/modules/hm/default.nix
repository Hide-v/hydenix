{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # ./example.nix - add your modules here
    ./hyprland.nix
  ];

  # home-manager options go here
  home.packages = with pkgs; [
    # pkgs.vscode - hydenix's vscode version
    # pkgs.userPkgs.vscode - your personal nixpkgs version
    google-chrome
    lazygit
    localsend
  ];

  # hydenix home-manager options go here
  hydenix.hm.enable = true;
  # Visit https://github.com/richen604/hydenix/blob/main/docs/options.md for more options
}

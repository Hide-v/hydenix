{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.hydenix.hm.hyde;
  system = pkgs.stdenv.hostPlatform.system;

  pluginPackages = lib.map (pluginName:
    lib.attrsets.getAttrFromPath [ "packages" system pluginName ] inputs.hyprland-plugins
  ) cfg.plugins;

  pluginConfLines = lib.concatMap (pluginName:
    let
      pluginPackage = lib.attrsets.getAttrFromPath [ "packages" system pluginName ] inputs.hyprland-plugins;
      pluginPath = "${pluginPackage}/lib/hyprland/plugins/lib${pluginName}.so";
    in
    [ "plugin = ${pluginPath}" ]
  ) cfg.plugins;


  originalHyprlandConf = builtins.readFile "${pkgs.hydenix.hyde}/Configs/.config/hypr/hyprland.conf";

  customHyprlandConf = builtins.concatStringsSep "\n" ([
    "# ====================================================================="
    "# Hyprland Plugins automatically injected by Nix based on configuration"
    "# ====================================================================="
  ] ++ pluginConfLines ++ [
    ""
    originalHyprlandConf
  ]);
in
{
  options.hydenix.hm.hyde = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.hydenix.hm.enable;
      description = "Enable hyde module";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of hyprland-plugins names to enable (e.g., [\"hyprscrolling\", \"hyprnome\"]).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = (with pkgs; [
      hyde
      Bibata-Modern-Ice
      Tela-circle-dracula
      kdePackages.kconfig
      wf-recorder
      python-pyamdgpuinfo
      hyq
      hydectl
      hyde-ipc
      hyde-config
      hyprcursor
      hyprutils
      xdg-desktop-portal-hyprland
      hyprpicker
      hypridle
    ]) ++ (lib.mkIf (cfg.plugins != []) pluginPackages); # 仅在有插件时追加插件包列表

    home.sessionVariables = {
      HYPRLAND_CONFIG = "${config.xdg.dataHome}/hypr/hyprland.conf";
    };

    fonts.fontconfig.enable = true;

    home.activation.createCavaConfig = lib.hm.dag.entryAfter [ "mutableGeneration" ] ''
      mkdir -p "$HOME/.config/cava"
      touch "$HOME/.config/cava/config"
      chmod 644 "$HOME/.config/cava/config"
    '';
    
    home.activation.createHyprConfigs = lib.hm.dag.entryAfter [ "mutableGeneration" ] ''
      mkdir -p "$HOME/.config/hypr/animations"
      mkdir -p "$HOME/.config/hypr/themes"

      touch "$HOME/.config/hypr/animations/theme.conf"
      touch "$HOME/.config/hypr/themes/colors.conf"
      touch "$HOME/.config/hypr/themes/theme.conf"
      touch "$HOME/.config/hypr/themes/wallbash.conf"

      chmod 644 "$HOME/.config/hypr/animations/theme.conf"
      chmod 644 "$HOME/.config/hypr/themes/colors.conf"
      chmod 644 "$HOME/.config/hypr/themes/theme.conf"
      chmod 644 "$HOME/.config/hypr/themes/wallbash.conf"
    '';

    home.file = {
      ".config/hypr/hyprland.conf" = lib.mkDefault {
        text = customHyprlandConf; 
        force = true;
      };

      ".config/hyde/wallbash" = {
        source = "${pkgs.hyde}/Configs/.config/hyde/wallbash";
        recursive = true;
        force = true;
        mutable = true;
      };

      ".config/systemd/user/hyde-config.service" = {
        text = ''
          [Unit]
          Description=HyDE Configuration Parser Service
          Documentation=https://github.com/HyDE-Project/hyde-config
          After=graphical-session.target
          PartOf=graphical-session.target

          [Service]
          Type=simple
          ExecStart=%h/.local/lib/hyde/hyde-config
          Restart=on-failure
          RestartSec=5s
          Environment="DISPLAY=:0"

          # Make sure the required directories exist
          ExecStartPre=/usr/bin/env mkdir -p %h/.config/hyde
          ExecStartPre=/usr/bin/env mkdir -p %h/.local/state/hyde

          [Install]
          WantedBy=graphical-session.target
        '';
      };
      ".config/systemd/user/hyde-ipc.service" = {
        source = "${pkgs.hyde}/Configs/.config/systemd/user/hyde-ipc.service";
      };

      ".local/bin/hyde-shell" = {
        source = pkgs.writeShellScript "hyde-shell" ''
          export PYTHONPATH="${pkgs.python-pyamdgpuinfo}/${pkgs.python3.sitePackages}:$PYTHONPATH"
          exec "${pkgs.hyde}/Configs/.local/bin/hyde-shell" "$@"
        '';
        executable = true;
      };

      ".local/lib/hyde" = {
        source = "${pkgs.hyde}/Configs/.local/lib/hyde";
        recursive = true;
        executable = true;
        force = true;
      };

      ".local/lib/hyde/resetxdgportal.sh" = {
        text = ''
          #!/usr/bin/env bash

        '';
        executable = true;
        mutable = true;
        force = true;
      };

      ".local/share/fastfetch/presets/hyde" = {
        source = "${pkgs.hyde}/Configs/.local/share/fastfetch/presets/hyde";
        recursive = true;
      };
      ".local/share/hyde" = {
        source = "${pkgs.hyde}/Configs/.local/share/hyde";
        recursive = true;
        executable = true;
        force = true;
        mutable = true;
      };
      ".local/share/wallbash/" = {
        source = "${pkgs.hyde}/Configs/.local/share/wallbash/";
        recursive = true;
        force = true;
        mutable = true;
      };
      ".local/share/waybar/includes" = {
        source = "${pkgs.hyde}/Configs/.local/share/waybar/includes";
        recursive = true;
      };
      ".local/share/waybar/layouts" = {
        source = "${pkgs.hyde}/Configs/.local/share/waybar/layouts";
        recursive = true;
      };
      ".local/share/waybar/menus" = {
        source = "${pkgs.hyde}/Configs/.local/share/waybar/menus";
        recursive = true;
      };
      ".local/share/waybar/modules" = {
        source = "${pkgs.hyde}/Configs/.local/share/waybar/modules";
        recursive = true;
      };
      ".local/share/waybar/styles" = {
        source = "${pkgs.hyde}/Configs/.local/share/waybar/styles";
        force = true;
        mutable = true;
        recursive = true;
      };
      ".config/MangoHud/MangoHud.conf" = {
        source = "${pkgs.hyde}/Configs/.config/MangoHud/MangoHud.conf";
      };
      ".local/share/kio/servicemenus/hydewallpaper.desktop" = {
        source = "${pkgs.hyde}/Configs/.local/share/kio/servicemenus/hydewallpaper.desktop";
      };
      ".local/share/kxmlgui5/dolphin/dolphinui.rc" = {
        source = "${pkgs.hyde}/Configs/.local/share/kxmlgui5/dolphin/dolphinui.rc";
      };

      ".config/electron-flags.conf" = {
        source = "${pkgs.hyde}/Configs/.config/electron-flags.conf";
      };

      ".local/share/icons/Wallbash-Icon" = {
        source = "${pkgs.hyde}/share/icons/Wallbash-Icon";
        force = true;
        recursive = true;
        mutable = true;
      };

      # stateful files
      ".config/hyde/config.toml" = {
        source = "${pkgs.hyde}/Configs/.config/hyde/config.toml";
        force = true;
        mutable = true;
      };
      ".local/share/dolphin/view_properties/global/.directory" = {
        source = "${pkgs.hyde}/Configs/.local/share/dolphin/view_properties/global/.directory";
        force = true;
        mutable = true;
      };
      ".local/share/icons/default/index.theme" = {
        source = "${pkgs.hyde}/Configs/.local/share/icons/default/index.theme";
        force = true;
        mutable = true;
      };
      ".local/share/themes/Wallbash-Gtk" = {
        source = "${pkgs.hyde}/share/themes/Wallbash-Gtk";
        recursive = true;
        force = true;
        mutable = true;
      };
      
      ".config/hypr/hyde.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/hyde.conf"; };
      ".config/hypr/keybindings.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/keybindings.conf"; };
      ".config/hypr/monitors.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/monitors.conf"; };
      ".config/hypr/nvidia.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/nvidia.conf"; };
      ".config/hypr/userprefs.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/userprefs.conf"; };
      ".config/hypr/windowrules.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/windowrules.conf"; };
      ".config/hypr/animations.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations.conf"; };
      ".config/hypr/animations/classic.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/classic.conf"; };
      ".config/hypr/animations/diablo-1.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/diablo-1.conf"; };
      ".config/hypr/animations/diablo-2.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/diablo-2.conf"; };
      ".config/hypr/animations/dynamic.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/dynamic.conf"; };
      ".config/hypr/animations/disable.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/disable.conf"; };
      ".config/hypr/animations/eevee-1.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/eevee-1.conf"; };
      ".config/hypr/animations/eevee-2.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/eevee-2.conf"; };
      ".config/hypr/animations/high.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/high.conf"; };
      ".config/hypr/animations/low-1.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/low-1.conf"; };
      ".config/hypr/animations/low-2.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/low-2.conf"; };
      ".config/hypr/animations/minimal-1.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/minimal-1.conf"; };
      ".config/hypr/animations/minimal-2.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/minimal-2.conf"; };
      ".config/hypr/animations/moving.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/moving.conf"; };
      ".config/hypr/animations/optimized.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/optimized.conf"; };
      ".config/hypr/animations/standard.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/standard.conf"; };
      ".config/hypr/animations/vertical.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/animations/vertical.conf"; };
      ".config/hypr/hypridle.conf" = lib.mkDefault { source = "${pkgs.hydenix.hyde}/Configs/.config/hypr/hypridle.conf"; };
      
    };
    
    wayland.windowManager.hyprland.enable = lib.mkForce false; 
  };
}

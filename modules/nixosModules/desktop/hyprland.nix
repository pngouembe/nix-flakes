{ inputs, ... }:
{
  flake.nixosModules.hyprland =
    { pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      environment.systemPackages = [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.noctalia.inputs.noctalia-qs.packages.${pkgs.stdenv.hostPlatform.system}.quickshell
      ];

      home-manager.users.png = { ... }: {
        xdg.configFile."hypr/hyprland.conf".text                    = builtins.readFile ./hypr/hyprland.conf;
        xdg.configFile."hypr/noctalia/noctalia-colors.conf".text    = builtins.readFile ./hypr/noctalia/noctalia-colors.conf;
        xdg.configFile."noctalia/settings.json".text                = builtins.readFile ./noctalia/settings.json;
        xdg.configFile."noctalia/colors.json".text                  = builtins.readFile ./noctalia/colors.json;
        xdg.configFile."noctalia/plugins.json".text                 = builtins.readFile ./noctalia/plugins.json;
      };
    };
}

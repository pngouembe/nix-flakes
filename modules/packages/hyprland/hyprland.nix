{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, system, ... }:
    let
      runScript = pkgs.writeShellApplication {
        name = "Hyprland";
        runtimeInputs = [
          inputs.hyprland.packages.${system}.hyprland
          inputs.noctalia.packages.${system}.default
          inputs.noctalia.inputs.noctalia-qs.packages.${system}.quickshell
        ];
        text = ''
          cfg=$(mktemp -d)
          mkdir -p "$cfg/hypr/noctalia" "$cfg/noctalia"
          cp ${./hypr/hyprland.conf}                 "$cfg/hypr/hyprland.conf"
          cp ${./hypr/noctalia/noctalia-colors.conf} "$cfg/hypr/noctalia/noctalia-colors.conf"
          cp ${./noctalia/settings.json}             "$cfg/noctalia/settings.json"
          cp ${./noctalia/colors.json}               "$cfg/noctalia/colors.json"
          cp ${./noctalia/plugins.json}              "$cfg/noctalia/plugins.json"
          NIXOS_OZONE_WL=1 XDG_CONFIG_HOME="$cfg" exec Hyprland -c "$cfg/hypr/hyprland.conf"
        '';
      };
    in
    {
      packages.hyprland = runScript;
      packages.hyprland-portal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;

      apps.hyprland = {
        type = "app";
        program = "${runScript}/bin/Hyprland";
      };
    };
}

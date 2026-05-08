{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, system, ... }:
    let
      hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
      noctaliaPkg = inputs.noctalia.packages.${system}.default;
      quickshellPkg = inputs.noctalia.inputs.noctalia-qs.packages.${system}.quickshell;

      # Add a wallpaper image at ./wallpaper.png (or .jpg) to use it here.
      # Falls back to a solid Catppuccin Mocha base colour.
      wallpaperCmd =
        if builtins.pathExists ./wallpaper.png then "swaybg -i ${./wallpaper.png} -m fill"
        else if builtins.pathExists ./wallpaper.jpg then "swaybg -i ${./wallpaper.jpg} -m fill"
        else "swaybg -c 1e1e2e";

      noctaliaConfigDir = pkgs.runCommand "noctalia-config" { } ''
        mkdir -p $out/noctalia
        cp ${./noctalia/settings.json} $out/noctalia/settings.json
        cp ${./noctalia/colors.json}   $out/noctalia/colors.json
        cp ${./noctalia/plugins.json}  $out/noctalia/plugins.json
      '';

      hyprlandWrapped = inputs.wrappers.wrapperModules.hyprland.apply (
        { lib, ... }: {
          inherit pkgs;
          package = lib.mkForce hyprlandPkg;

          "hypr.conf".content =
            builtins.replaceStrings
              [ "source = ./noctalia/noctalia-colors.conf" ]
              [ "source = ${./hypr/noctalia/noctalia-colors.conf}" ]
              (builtins.readFile ./hypr/hyprland.conf)
            + "\nexec-once = ${wallpaperCmd}";

          env = {
            NIXOS_OZONE_WL = "1";
            XDG_CONFIG_HOME = "${noctaliaConfigDir}";
            NOCTALIA_CACHE_DIR = "/tmp/noctalia-cache";
          };

          extraPackages = [
            noctaliaPkg
            quickshellPkg
            pkgs.swaybg
          ];
        }
      );
    in
    {
      packages.hyprland = hyprlandWrapped.wrapper;
      packages.hyprland-portal = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;

      apps.hyprland = {
        type = "app";
        program = "${hyprlandWrapped.wrapper}/bin/Hyprland";
      };
    };
}

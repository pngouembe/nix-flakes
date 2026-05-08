{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, system, ... }:
    let
      hyprlandPkg = inputs.hyprland.packages.${system}.hyprland;
      noctaliaPkg = inputs.noctalia.packages.${system}.default;
      quickshellPkg = inputs.noctalia.inputs.noctalia-qs.packages.${system}.quickshell;

      hyprlandWrapped = inputs.wrappers.wrapperModules.hyprland.apply (
        { lib, ... }: {
          inherit pkgs;
          package = lib.mkForce hyprlandPkg;

          "hypr.conf".content = builtins.replaceStrings
            [ "source = ./noctalia/noctalia-colors.conf" ]
            [ "source = ${./hypr/noctalia/noctalia-colors.conf}" ]
            (builtins.readFile ./hypr/hyprland.conf);

          env = {
            NIXOS_OZONE_WL = "1";
            NOCTALIA_CACHE_DIR = "/tmp/noctalia-cache";
          };

          extraPackages = [
            noctaliaPkg
            quickshellPkg
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

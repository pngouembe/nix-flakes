{ ... }:
{
  flake.nixosModules.development = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      nixfmt
      nil
      nixd
      zed-editor
      gcc
      claude-code
      lmstudio
    ];
  };
}

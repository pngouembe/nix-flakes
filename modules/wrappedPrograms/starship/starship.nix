{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    {
      packages.starship = (inputs.wrappers.wrapperModules.starship.apply {
        inherit pkgs;
        configFile.path = "${./starship.toml}";
      }).wrapper;
    };
}

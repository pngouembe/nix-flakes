{
  pkgs,
  inputs,
  ...
}:

{
  home.username = "png";
  home.homeDirectory = "/home/png";
  home.stateVersion = "25.11";

  # All program configuration lives in ~/dotfiles and is symlinked in by stow,
  # not by Nix. This module only installs packages and a few system-level
  # tweaks that have no plain-file equivalent (cursor theme, dconf, user units).

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

  # `lms server start` reads ~/.lmstudio/.internal/app-install-location.json and
  # spawns the unwrapped Electron binary, which can't run outside the bwrap FHS
  # environment on NixOS. Start the wrapped `lm-studio` binary directly with
  # `--run-as-service` instead.
  systemd.user.services.lmstudio = {
    Unit.Description = "LM Studio headless API server";
    Service = {
      ExecStart = "${pkgs.lmstudio}/bin/lm-studio --run-as-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.packages = with pkgs; [
    # Shell + prompt
    oh-my-zsh
    zsh-autosuggestions
    starship
    nix-your-shell

    # Fuzzy finder + smart cd
    fzf
    zoxide

    # Terminal emulators & multiplexers
    alacritty
    tmux
    zellij

    # Modern CLI tools
    bat
    bottom
    dust
    eza
    fd
    jq
    ripgrep
    tlrc
    just

    # Editors / dev
    neovim
    rustup
    opencode

    # System monitor
    resources

    # Browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Notes & sync
    obsidian
    syncthing

    # Fonts
    nerd-fonts.fira-code
  ];
}

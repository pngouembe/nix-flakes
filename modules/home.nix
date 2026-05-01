{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = "/home/png/workspace/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.username = "png";
  home.homeDirectory = "/home/png";
  home.stateVersion = "25.11";

  # --- Shell ---

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker"
        "docker-compose"
        "git"
      ];
    };

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];

    # Source dotfile configs that don't belong to any HM program module.
    # starship/fzf/zoxide init lines are injected by their own HM modules below.
    initExtra = ''
      source ${dotfiles}/zsh/aliases.zsh
      source ${dotfiles}/zsh/git.zsh
      source ${dotfiles}/zsh/history.zsh

      export BAT_THEME="Catppuccin Mocha"
      export VISUAL=nvim
      export EDITOR=nvim
      export PATH="$PATH:/usr/local/sbin:$HOME/.local/bin"
      export TERM=xterm-256color

      _fzf_compgen_path() {
          fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
          fd --type=d --hidden --follow --exclude .git . "$1"
      }

      _fzf_comprun() {
          local command=$1
          shift
          case "$command" in
              cd)           fzf --preview 'eza --icons --tree {} | head -200' "$@" ;;
              export|unset) fzf --preview "eval 'echo \$' {}" "$@" ;;
              ssh)          fzf --preview 'dig {}' "$@" ;;
              *)            fzf --preview 'bat -n --color=always --style=header,grid --line-range :500 {}' "$@" ;;
          esac
      }
    '';
  };

  # --- Prompt ---

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Symlink live to dotfiles so edits take effect without rebuilding
  home.file.".config/starship.toml".source = link "${dotfiles}/starship/starship.toml";

  # --- Fuzzy finder ---

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
    defaultOptions = [
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
    ];
    fileWidgetCommand = "fd --hidden --strip-cwd-prefix --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=header,grid --line-range :500 {}'"
    ];
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --follow --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --icons --group-directories-first --git --color=always --tree --level=2 {}'"
    ];
  };

  # --- Smart cd ---

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  # --- Terminal emulator & multiplexers ---

  home.file.".config/alacritty/alacritty.yml".source =
    link "${dotfiles}/alacritty/alacritty.yml";

  home.file.".config/tmux/tmux.conf".source =
    link "${dotfiles}/tmux/tmux.conf";

  home.file.".config/zellij/config.kdl".source =
    link "${dotfiles}/zellij/config.kdl";

  # --- Neovim / NvChad ---

  # User config files placed according to dotfiles/nvim/links.prop.
  # These are live symlinks so editing dotfiles is reflected immediately.
  home.file.".config/nvim/lua/custom/chadrc.lua".source =
    link "${dotfiles}/nvim/chadrc.lua";
  home.file.".config/nvim/lua/custom/init.lua".source =
    link "${dotfiles}/nvim/init.lua";
  home.file.".config/nvim/lua/custom/plugins.lua".source =
    link "${dotfiles}/nvim/plugins/init.lua";
  home.file.".config/nvim/lua/custom/mappings.lua".source =
    link "${dotfiles}/nvim/mappings.lua";
  home.file.".config/nvim/lua/custom/configs/lspconfig.lua".source =
    link "${dotfiles}/nvim/configs/lspconfig.lua";
  home.file.".config/nvim/lua/custom/configs/null-ls.lua".source =
    link "${dotfiles}/nvim/configs/null-ls.lua";

  # Clone NvChad once on first activation; subsequent rebuilds skip this.
  # Must run before writeBoundary so the directory exists before HM places
  # the custom symlinks above.
  home.activation.nvchadBootstrap = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
        https://github.com/NvChad/NvChad \
        "$HOME/.config/nvim" --depth 1
    fi
  '';

  # --- Packages ---

  home.packages = with pkgs; [
    # Terminal emulators & multiplexers
    alacritty
    tmux
    zellij

    # Modern CLI tools
    bat
    bottom
    du-dust
    eza
    fd
    ripgrep
    tlrc
    just

    # Development
    neovim
    rustup

    # Fonts
    nerd-fonts.fira-code
  ];
}

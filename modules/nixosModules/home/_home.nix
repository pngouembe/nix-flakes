{
  config,
  pkgs,
  lib,
  inputs,
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
    initContent = ''
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

  # Make `nix-shell` and `nix develop` re-enter zsh so starship + aliases load.
  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- Prompt ---

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.starship;
  };

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
    options = [
      "--cmd"
      "cd"
    ];
  };

  # --- Terminal emulator & multiplexers ---

  home.file.".config/alacritty/alacritty.yml".source = link "${dotfiles}/alacritty/alacritty.yml";

  home.file.".config/tmux/tmux.conf".source = link "${dotfiles}/tmux/tmux.conf";

  home.file.".config/zellij/config.kdl".source = link "${dotfiles}/zellij/config.kdl";

  # --- Neovim / NvChad ---

  # User config files — live symlinks so editing dotfiles is reflected immediately.
  # These follow the NvChad v2.5 starter structure (lua/ not lua/custom/).
  home.file.".config/nvim/lua/chadrc.lua".source = link "${dotfiles}/nvim/chadrc.lua";
  home.file.".config/nvim/lua/plugins/init.lua".source = link "${dotfiles}/nvim/plugins/init.lua";
  home.file.".config/nvim/lua/configs/lspconfig.lua".source =
    link "${dotfiles}/nvim/configs/lspconfig.lua";
  home.file.".config/nvim/lua/configs/null-ls.lua".source =
    link "${dotfiles}/nvim/configs/null-ls.lua";

  # Clone the NvChad starter (not the plugin repo) on first activation.
  # The starter provides init.lua + lazy bootstrap; NvChad itself is fetched
  # by lazy.nvim at first launch.  If the old plugin-repo clone is present
  # (identified by a missing init.lua), remove it first.
  home.activation.nvchadBootstrap = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -d "$HOME/.config/nvim/.git" ] && [ ! -f "$HOME/.config/nvim/init.lua" ]; then
      $DRY_RUN_CMD rm -rf "$HOME/.config/nvim"
    fi
    if [ ! -f "$HOME/.config/nvim/init.lua" ]; then
      if $DRY_RUN_CMD ${pkgs.git}/bin/git clone \
        https://github.com/NvChad/starter \
        "$HOME/.config/nvim" --depth 1; then
        $DRY_RUN_CMD rm -f "$HOME/.config/nvim/lua/chadrc.lua"
        $DRY_RUN_CMD rm -rf "$HOME/.config/nvim/lua/plugins"
      fi
    fi
  '';

  # --- Zed editor ---

  home.file.".config/zed/settings.json".source = ./config/zed/settings.json;
  home.file.".config/zed/keymap.json".source = ./config/zed/keymap.json;

  # --- opencode (AI coding agent, wired to LM Studio for local inference) ---
  #
  # LM Studio exposes an OpenAI-compatible server (default: http://localhost:1234/v1).
  # Start it from the LM Studio app ("Developer" → "Start Server") or via `lms server start`.
  # Add/remove entries under `models` to match what you have loaded in LM Studio
  # (the key must equal the model id LM Studio reports at /v1/models).
  programs.opencode = {
    enable = true;
    settings = {
      provider.lmstudio = {
        npm = "@ai-sdk/openai-compatible";
        name = "LM Studio";
        options.baseURL = "http://localhost:1234/v1";
        models = {
          "qwen/qwen3.6-35b-a3b" = {
            name = "Qwen3.6 35B A3B";
          };
          "google/gemma-4-26b-a4b" = {
            name = "Gemma4 26b A4b";
          };
        };
      };
    };
  };

  # --- Cursor ---

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 24;
  };

  # --- Packages ---

  home.packages = with pkgs; [
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
    ripgrep
    tlrc
    just

    # Development
    neovim
    rustup

    # System monitor
    resources

    # Browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Fonts
    nerd-fonts.fira-code
  ];
}

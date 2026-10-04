{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  # Touch ID for sudo; reattach makes it work inside tmux/herdr sessions too.
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    # Homebrew was already installed with the official script; take it over.
    autoMigrate = true;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "gh"
    ];
    casks = [
      "wezterm"
      "claude-code"
      # browsers
      "google-chrome"
      "firefox"
      # everyday
      "discord"
      "vlc"
      # utilities
      "raycast"
      "rectangle"
      "the-unarchiver"
      "opensuperwhisper"
      # dev
      "visual-studio-code"
      # local ai
      "lm-studio"
      "ollama-app"
      "draw-things"
    ];
  };

  # Pinokio has no Homebrew cask and nixpkgs only builds it for Linux, so install the
  # signed release directly. Only runs when the app is missing; Pinokio self-updates after that.
  system.activationScripts.postActivation.text = ''
    if [ ! -d /Applications/Pinokio.app ]; then
      echo "installing Pinokio..."
      tmp="$(mktemp -d)"
      /usr/bin/curl -fsSL -o "$tmp/pinokio.zip" \
        https://github.com/pinokiocomputer/pinokio/releases/download/v8.2.0/Pinokio-8.2.0-arm64-mac.zip
      /usr/bin/ditto -x -k "$tmp/pinokio.zip" "$tmp"
      # Refuse anything not signed by Pinokio's developer (Starling Protocol, Inc).
      if /usr/bin/codesign -dv "$tmp/Pinokio.app" 2>&1 | /usr/bin/grep -q "TeamIdentifier=TPKP4XK352"; then
        /usr/bin/ditto "$tmp/Pinokio.app" /Applications/Pinokio.app
        /usr/sbin/chown -R ${user}:admin /Applications/Pinokio.app
      else
        echo "warning: Pinokio download failed signature check, skipping" >&2
      fi
      rm -rf "$tmp"
    fi
  '';
}

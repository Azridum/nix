{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    darwinConfiguration = {pkgs, ...}: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = with pkgs; [
        alejandra
        tmux
        git
        unzip
        zip
        neovim
        wget
        alacritty
        jq
        xq
        btop
        docker
        curl
        google-chrome
        tmux
        docker
        python3
        fzf
        watch
        ripgrep
        cmake
      ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh = {
        enable = true;
      };

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # $ darwin-rebuild changelog
      system.stateVersion = 5;
      users.users.attilabanga.home = "/Users/attilabanga";

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      security.pam.enableSudoTouchIdAuth = true;
      environment = {
        etc."pam.d/sudo_local".text = ''
          # Managed by Nix Darwin
          auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
          auth       sufficient     pam_tid.so
        '';
      };
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    darwinConfigurations."MacBook-Pro-Attila" = nix-darwin.lib.darwinSystem {
      modules = [
        darwinConfiguration
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.attilabanga = import ./home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
      #system = "aarch64-darwin";
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."MacBook-Pro-Attila".pkgs;
  };
}

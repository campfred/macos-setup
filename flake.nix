#############################
# DO THIS BEFORE APPLYING THE CONFIGURATION:
# 1. Replace all the references to "SingleBlockOfAlluminum" with your own hostname
# 2. Replace the user name and email in the `user` attribute set
# 3. If need to provision your own certificates, uncomment the `certificates` attribute and set with your own
#    > Note, there's a bunch of sections that are commented out for certificates provisioning, you can uncomment them if you need them

{
  description = "Camp's Nix-Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
    }:
    let
      user = {
        name = "campfred"; # Replace this to your correct username
        email = "macos-setup@campfred.info"; # Replace this to your correct email
      };
      # certificates = {
      #   repo = "http://crldp.pki.campfred.info/crldp";
      #   file = {
      #     ca = {
      #       dem = "RootCA.crt";
      #       pem = "RootCA.pem";
      #     };
      #   };
      #   paths = {
      #     system = {
      #       base = "/etc/ssl/certs";
      #       docker = "/etc/docker/certs.d";
      #       # docker = "/etc/docker/certs.d/campfred.info/ca.pem";
      #     };
      #     user = {
      #       docker = "/Users/${user.name}/.docker/certs.d";
      #     };
      #   };
      # };
      configuration =
        { pkgs, config, ... }:
        {
          ##############################
          # Nix setup
          ##
          nix = {
            # Auto optimize store files
            optimise.automatic = true;

            # Necessary for using flakes on this system.
            settings.experimental-features = "nix-command flakes";

            # # Import certificates
            # settings.ssl-cert-file = "${certificates.paths.system.base}/${certificates.file.ca.pem}";

            # nix.package = pkgs.nix;
          };

          ##############################
          # Services setup
          ##
          services = {
            nix-daemon.enable = true; # Allows auto-upgrading nix packages and the daemon service.
          };

          ##############################
          # Nix packages setup
          ##
          nixpkgs = {
            hostPlatform = "aarch64-darwin"; # M# platform
            config.allowUnfree = true; # Allow proprietary software.
          };

          ##############################
          # Nix packages inventory
          ##
          environment.systemPackages = with pkgs; [
            # List packages installed in system profile.
            # To search by name, run: nix-env -qaP | grep ${package_name}
            wget
            curl
            openssl
            cacert
            mkalias
            direnv
            thefuck
            zoxide
            bat
            lsd
            yq
            starship
            powershell
            python3
            pam-reattach # TouchID outside of Tmux
            btop
            macmon
            gh
            awscli2
            docker
            colima
            kubectl
            tfswitch
            fnm
            yarn
            pnpm
            kubeseal
            # nixfmt-classic
            nixfmt-rfc-style
            fastfetch
            pokeget-rs
            stats
            maccy
            vscode
            httpie
            # httpie-desktop # Not available for darwin build
            # ghostty # Apparently broken. Oh well.
            ollama
            # lmstudio # Apparently broken too. Damm...
            obsidian
            spotify
            supersonic
          ];

          ##############################
          # Homebrew packages inventory
          homebrew = {
            enable = true;

            onActivation = {
              # Automatically upgrade Homebrew packages on activation.
              upgrade = true;
              # Homebrew already updates itself when manually invoked. Might as well update it on activation.
              autoUpdate = true;
              # Nuke Homebrew apps that are not declared in the configuration.
              cleanup = "zap";
            };

            # https://formulaes.brew.sh or `brew search` for available packages.
            brews = [ "mas" ];
            casks = [
              "elgato-camera-hub"
              "focusrite-control-2"
              "betterdisplay"
              "loopback"
              "smooze-pro"
              "hiddenbar"
              "mediamate"
              "phoenix"
              "amethyst"
              "swish"
              "loop"
              "yubico-authenticator"
              "keepassxc"
              "zen-browser"
              "visual-studio-code"
              "fork"
              "ghostty"
              "httpie"
              "lm-studio"
              # "spotify"
              "tidal"
              "pocket-casts"
              "iina"
            ];
            # `mas search` or share link from App Store for IDs.
            # Note: The "Key" in the "Key" = ID format is an arbitrary name. Recommended to put the name of the app.
            masApps = {
              Amphetamine = 937984704;
              # Yoink = 1467837404;
              # PasteNow = 1552536109;
              CARROT-Weather = 961390574;
              CARROT-Weather-Desktop = 993487541;
            };
          };

          # Font packages inventory
          fonts.packages = with pkgs; [
            (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
            
            # nerd-fonts.jetbrains-mono # Only in next releases of Nix
            # https://mynixos.com/packages/nerd-fonts
            # https://www.reddit.com/r/NixOS/comments/1h1nc2a
          ];

          ##############################
          # System setup
          ##
          system = {
            # Set Git commit hash for darwin-version.
            configurationRevision = self.rev or self.dirtyRev or null;

            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            stateVersion = 4;

            ##
            # Input settings
            keyboard = {
              enableKeyMapping = true; # Required for mapping options.
              swapLeftCtrlAndFn = false; # Swap Fn and Left Control keys.

              # Key maps, they need to be preceeded by 0x700000000 to be recognized in hex in command line.
              # https://jonnyzzz.com/blog/2017/12/04/macos-keys/
              # https://developer.apple.com/library/archive/technotes/tn2450/_index.html
              # Just convert it to decimal for applying with Nix.
              # userKeyMapping = [{
              #   HIDKeyboardModifierMappingSrc = 30064771129; # 0x700000039
              #   HIDKeyboardModifierMappingDst = 30064771299; # 0x7000000E3
              # }];
            };

            ##
            # Startup settings
            startup.chime = false; # I want a break.

            ##
            # System settings
            defaults = {
              CustomSystemPreferences = {
                NSGlobalDomain = {
                  "com.apple.mouse.linear" = true; # Disable mouse acceleration plz
                };
              };
              CustomUserPreferences = {
                NSGlobalDomain = {
                  "com.apple.mouse.linear" = true; # Disable mouse acceleration plz
                };
                "com.apple.desktopservices" = {
                  # Plz no .DS_Store files, thx
                  DSDontWriteNetworkStores = true;
                  DSDontWriteUSBStores = true;
                };
              };
              ".GlobalPreferences" = {
                "com.apple.mouse.scaling" = 1.0;
              };

              # Other macOS behaviour settings.
              NSGlobalDomain = {
                AppleInterfaceStyleSwitchesAutomatically = true;
                AppleScrollerPagingBehavior = true;
                AppleShowScrollBars = "Automatic";
                NSDocumentSaveNewDocumentsToCloud = false;
                NSWindowShouldDragOnGesture = true;
                KeyRepeat = 2; # Set key repeat rate to fastest.
                "com.apple.mouse.tapBehavior" = 1; # Trackpad tap click
                _HIHideMenuBar = true;
                "com.apple.sound.beep.feedback" = 1; # Pop! sound on vol change.
                "com.apple.sound.beep.volume" = 0.4723665; # Alerts vol to 25%
                # 25% = 0.4723665 in this world because our perception is ~logarithmic~.
                # https://mynixos.com/nix-darwin/option/system.defaults.NSGlobalDomain.%22com.apple.sound.beep.volume%22
                NSNavPanelExpandedStateForSaveMode = true; # Expanded dialog pls
                NSNavPanelExpandedStateForSaveMode2 = true; # I said...
              };

              # Trackpad settings
              trackpad = {
                Clicking = true;
                Dragging = true;
                TrackpadRightClick = true;
                TrackpadThreeFingerDrag = true;
              };

              # Control center settings.
              controlcenter = {
                AirDrop = false;
                Bluetooth = false;
                Display = false;
                FocusModes = true;
                NowPlaying = true;
                Sound = false;
              };

              # Dock settings
              dock = {
                # Display settings.
                autohide = true;
                autohide-delay = 0.0; # Don't wait at all to autohide.
                autohide-time-modifier = 0.5; # Hide fast!
                mru-spaces = false; # Do not rearrange wtf.

                # Windows settings.
                mineffect = "suck"; # ✨
                slow-motion-allowed = true; # Funny

                # Icons settings
                magnification = true;
                tilesize = 48;
                largesize = 56;
                # 48 (configured "resting" size) + 8 (a little bit of magnification) = 56 ("magnified" size).
                expose-group-apps = true;
                show-recents = false;
                showhidden = true;

                # Persistent icons.
                persistent-apps = [
                  "/Applications/Focusrite Control 2.app"
                  "/Applications/Elgato Camera Hub.app"
                  "/Applications/Yubico Authenticator.app"
                  "/Applications/KeePassXC.app"
                  "/Applications/TIDAL.app"
                  "/Applications/Zen Browser.app"
                  "${pkgs.obsidian}/Applications/Obsidian.app"
                  "/Applications/LM Studio.app"
                  "/Applications/Ghostty.app"
                  "/Applications/Fork.app"
                  "/Applications/Visual Studio Code.app"
                  "/Applications/HTTPie.app"
                ];
                persistent-others = [
                  "/Users/${user.name}/Développement"
                  "/Users/${user.name}"
                  "/Users/${user.name}/Downloads"
                ];

                # Hot corners settings. Somehow that's a Dock configuration on macOS...
                # Ah! That's because the Dock handles the desktop. Derp.
                wvous-bl-corner = 11; # Launchpad on bottom left.
                wvous-br-corner = 2; # Mission Control on bottom right.
                wvous-tl-corner = 5; # Screen Saver on top left.
                wvous-tr-corner = 12; # Notification Center on top right.
              };

              # Finder settings
              finder = {
                # Display settings
                _FXSortFoldersFirst = true; # I like it that way.
                AppleShowAllFiles = true; # I'm a nerd, show me the files.
                AppleShowAllExtensions = true; # Please show too. Thx.

                # I like clean desktops, keep it tidy thx
                CreateDesktop = false;
                ShowExternalHardDrivesOnDesktop = false;
                ShowHardDrivesOnDesktop = false;
                ShowMountedServersOnDesktop = false;
                ShowRemovableMediaOnDesktop = false;

                # Behaviour settings
                # It doesn't really happen that often, but when it does, it's usually an accident. Double check plz.
                FXEnableExtensionChangeWarning = true;
                # I don't wanna have to manage the trash bin, thx.
                FXRemoveOldTrashItems = true;
                # If only Finder was so reliable that I never needed to restart it...
                QuitMenuItem = true;
              };

              # Screenshots settings.
              screencapture = {
                # Remove shadows around windows in screenshots.
                # For real, it might be pretty but it wastes a lot of space.
                # I'd rather have a universal shadow around pictures in documentations.
                disable-shadow = true;
                target = "preview"; # Open screenshots in Preview by default.
                location = "/Users/${user.name}/Pictures/Captures d'écran";
                type = "png"; # MAX QUALITYYYYY
              };

              # Screen saver settings.
              screensaver = {
                askForPassword = true; # Ask for password when waking up.
                askForPasswordDelay = 60; # Grace period for my dumb dumb.
              };

              # Make workspaces *not* span accross displays, let each display have its own workspace.
              spaces = {
                spans-displays = false;
              };

              # Don't show desktop on desktop click
              WindowManager = {
                EnableStandardClickToShowDesktop = false;
              };
            };

            ##
            # Activation scripts (scripts to execute on NixOS activation)
            # https://mynixos.com/nix-darwin/options/system.activationScripts
            # activationScripts = {
            #   preUserActivation = {
            #     enable = true;
            #     text = ''
            #       # Install certificate authority certificate for CLI tools to use.

            #       echo "Pulling root Certificate Authority certificate..."
            #       ${pkgs.curl}/bin/curl "${certificates.repo}/${certificates.file.ca.dem}" --silent --fail --output "$TMPDIR/${certificates.file.ca.dem}"
            #       echo "${certificates.repo}/${certificates.file.ca.dem} -> $TMPDIR/${certificates.file.ca.dem}"

            #       echo "Converting root CA to pem format..."
            #       ${pkgs.openssl}/bin/openssl x509 -in "$TMPDIR/${certificates.file.ca.dem}" -inform der -out "$TMPDIR/${certificates.file.ca.pem}" -outform pem
            #       echo "DER ($TMPDIR/${certificates.file.ca.dem}) -> PEM ($TMPDIR/${certificates.file.ca.pem})"

            #       echo "Making sure it can be read..."
            #       chmod +rx "$TMPDIR/${certificates.file.ca.pem}"
            #       echo "+rx"

            #       echo "Copying to the system certificates folders..."
            #       sudo mkdir -p "${certificates.paths.system.base}"
            #       sudo cp "$TMPDIR/${certificates.file.ca.pem}" "${certificates.paths.system.base}/"
            #       echo "$TMPDIR/${certificates.file.ca.pem} -> ${certificates.paths.system.base}"
            #       sudo mkdir -p "${certificates.paths.system.docker}"
            #       sudo ln -sf "${certificates.paths.system.base}/${certificates.file.ca.pem}" "${certificates.paths.system.docker}/"
            #       echo "${certificates.paths.system.base}/${certificates.file.ca.pem} -> ${certificates.paths.system.docker}/"
            #       sudo mkdir -p "${certificates.paths.user.docker}"
            #       sudo ln -sf "${certificates.paths.system.base}/${certificates.file.ca.pem}" "${certificates.paths.user.docker}/"
            #       echo "${certificates.paths.system.base}/${certificates.file.ca.pem} -> ${certificates.paths.user.docker}/"

            #       echo "Cleaning up..."
            #       rm -f "$TMPDIR/${certificates.file.ca.dem}" "$TMPDIR/${certificates.file.ca.pem}"

            #       echo "Root CA is installed!"
            #       echo "They can be found in the following locations:"
            #       ls "${certificates.paths.system.base}/${certificates.file.ca.pem}" \
            #             ${certificates.paths.system.docker}/${certificates.file.ca.pem} \
            #             ${certificates.paths.user.docker}/${certificates.file.ca.pem}
            #     '';
            #   };

              # Activate user settings immediately
              postUserActivation = {
                enable = true;
                text = ''
                  # Patch Apple's TouchID sudo authentication to also use the Apple Watch
                  # https://github.com/inickt/pam_wtid
                  echo "Patching TouchID sudo authentication to enable authenticating with an Apple Watch when TouchID is unavailable (clamshell mode)..."
                  echo "Removing current patch (assuming it is installed) prior to installing it again..."
                  cd /tmp/
                  git clone https://github.com/inickt/pam_wtid.git
                  cd pam_wtid
                  make disable # Removes the patch
                  echo "Applying patch..."
                  make enable # Applies the patch
                  cd ..
                  rm -rf /tmp/pam_wtid
                  echo "TouchID sudo patched."

                  # Mount network shares
                  echo "Mounting network shares..."
                  open "smb://$USER@nas.local/homes" # Replace with your NAS address and path

                  # Following line should allow us to avoid a logout/login cycle
                  echo "Activating user settings..."
                  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
                '';
              };

              # Create "mac links" allowing Nix Apps to be indexed by macOS Spotlight.
              # https://github.com/dreamsofautonomy/nix-darwin
              applications.text =
                let
                  env = pkgs.buildEnv {
                    name = "system-applications";
                    paths = config.environment.systemPackages;
                    pathsToLink = "/Applications";
                  };
                in
                pkgs.lib.mkForce ''
                  echo "Setting up /Applications..." >&2
                  rm -rf "/Applications/Nix Apps"
                  mkdir -p "/Applications/Nix Apps"
                  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
                  while read -r src; do
                    app_name=$(basename "$src")
                    echo "copying $src" >&2
                    ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
                  done
                '';
            };
          };

          ##############################
          # Security setup
          ##
          security = {
            # TouchID for Sudo authentication.
            # It requires being re-applied on system update since macOS rewrites the sudoers file on OS upgrades.
            # https://mynixos.com/nix-darwin/option/security.pam.enableSudoTouchIdAuth
            pam.enableSudoTouchIdAuth = false; # Disabled for now because I *think* that's already handled by the patch for combining with Apple Watch authentication...
          };

          ##############################
          # Network setup
          ##
          networking = {
            knownNetworkServices = [
              "Thunderbolt Bridge"
              "TBT200 Dock Ethernet" # My own TB dock, replace with yours
              "USB 10/100/1000 LAN" # My own USB dock, replace with yours
              "Wi-Fi"
              "USB iPhone"
            ];
          };

          ##############################
          # Launchd (services) setup
          ##
          launchd = {
            # Agents to run at login, system-wide
            # https://www.danielcorin.com/til/nix-darwin/launch-agents/
            # https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
            agents = {
              # certs-install = {
              #   serviceConfig = {
              #     RunAtLoad = true;
              #     KeepAlive = false;
              #     StandardOutPath = "/Library/Logs/certs-install.out.log";
              #     StandardErrorPath = "/Library/Logs/certs-install.err.log";
              #     StartInterval = 3600; # 1 hour
              #   };
              #   script = ''
              #     # Install custom certificate authority certificate for CLI tools to use.

              #     echo "Installing custom certs..."
              #     echo "Pulling root Certificate Authority certificate..."
              #     ${pkgs.curl}/bin/curl "${certificates.repo}/${certificates.file.ca.dem}" --silent --fail --output "/tmp/${certificates.file.ca.dem}"
              #     echo "${certificates.repo}/${certificates.file.ca.dem} -> /tmp/${certificates.file.ca.dem}"

              #     echo "Converting root CA to pem format..."
              #     ${pkgs.openssl}/bin/openssl x509 -in /tmp/${certificates.file.ca.dem} -inform der -out /tmp/${certificates.file.ca.pem} -outform pem
              #     echo "DER -> PEM"

              #     echo "Making sure it can be read..."
              #     chmod +rx /tmp/${certificates.file.ca.pem}
              #     echo "+rx"

              #     echo "Copying to the system certificates folders..."
              #     mkdir -p ${certificates.paths.system.base}
              #     # cp /tmp/${certificates.file.ca.pem} ${certificates.paths.system.base}/${certificates.file.ca.pem}
              #     cp /tmp/${certificates.file.ca.pem} ${certificates.paths.system.base}
              #     echo "/tmp/${certificates.file.ca.pem} -> ${certificates.paths.system.base}"
              #     mkdir -p ${certificates.paths.system.docker}
              #     # ln -sf ${certificates.paths.system.base}/${certificates.file.ca.pem} ${certificates.paths.system.docker}/${certificates.file.ca.pem}
              #     ln -sf ${certificates.paths.system.base}/${certificates.file.ca.pem} ${certificates.paths.system.docker}/
              #     echo "${certificates.paths.system.base}/${certificates.file.ca.pem} -> ${certificates.paths.system.docker}/"
              #     mkdir -p ${certificates.paths.user.docker}
              #     # ln -sf ${certificates.paths.system.base}/${certificates.file.ca.pem} ${certificates.paths.user.docker}/${certificates.file.ca.pem}
              #     ln -sf ${certificates.paths.system.base}/${certificates.file.ca.pem} ${certificates.paths.user.docker}/
              #     echo "${certificates.paths.system.base}/${certificates.file.ca.pem} -> ${certificates.paths.user.docker}/"

              #     echo "Cleaning up..."
              #     rm -f ${certificates.file.ca.dem} ${certificates.file.ca.pem}

              #     echo "Root CA is installed!"
              #     echo "They can be found in the following locations:"
              #     ls ${certificates.paths.system.base}/${certificates.file.ca.pem} \
              #           ${certificates.paths.system.docker}/${certificates.file.ca.pem} \
              #           ${certificates.paths.user.docker}/${certificates.file.ca.pem}
              #   '';
              # };
            };

            user = {
              envVariables = {
                # # Custom certificates
                # SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # CURL_CA_BUNDLE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # REQUEST_CA_BUNDLE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # PORTABLE_RUBY_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # NODE_EXTRA_CA_CERTS = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # NIX_INSTALLER_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # NIX_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
                # # Need to set them user side because of System Integrity Protection

                # Other stuff
                HOMEBREW_NO_ANALYTICS = "1"; # No analytics at work plx.
                EDITOR = "code --wait"; # Pls use VSCode for editing, thx.
              };

              # Agents to run at login
              # https://www.danielcorin.com/til/nix-darwin/launch-agents/
              # https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
              agents = {
                colima-provision = {
                  serviceConfig = {
                    RunAtLoad = true;
                    KeepAlive = false;
                    StandardOutPath = "/Users/${user.name}/Library/Logs/colima-provision.out.log";
                    StandardErrorPath = "/Users/${user.name}/Library/Logs/colima-provision.err.log";
                    StartInterval = 3600; # 1 hour
                  };
                  script = ''
                    echo
                    echo "--------------------------------"
                    date
                    echo "Provisioning Colima!"

                    # echo "Setting up Python virtual environment..."
                    # ${pkgs.python3}/bin/python3 -m venv /Users/${user.name}/.config/nix-darwin/.venv --upgrade-deps
                    # source /Users/${user.name}/.config/nix-darwin/.venv/bin/activate
                    # echo "Loaded Python virtual environment."

                    # echo "Installing Python dependencies..."
                    # ${pkgs.python3}/bin/python3 -m pip install --requirements /Users/${user.name}/.config/nix-darwin/requirements.txt
                    # echo "Installed Python dependencies."

                    # echo "Applying provisioning script to Colima configuration..."
                    # ${pkgs.python3}/bin/python3 /Users/${user.name}/.config/nix-darwin/provision_colima_ca_cert.py --repo-url ${certificates.repo} --filename ${certificates.file.ca.pem}
                    # echo "Applied provisioning script in Colima configuration."

                    echo "Starting Colima..."
                    ${pkgs.colima}/bin/colima start
                    ${pkgs.colima}/bin/colima status
                    echo "Started Colima."

                    echo "Colima has been provisioned and started!"
                  '';
                };
              };
            };
          };

          ##############################
          # Environment setup
          ##
          environment = {
            shellAliases = {
              nix-install = "nix run nix-darwin -- switch --flake ~/.config/nix-darwin";
              nix-rebuild = "darwin-rebuild switch --flake ~/.config/nix-darwin";
              ls = "lsd";
              ll = "lsd -lh";
              lla = "lsd -lah";
              cat = "bat";
              cd = "z";
              python = "python3";
            };

            interactiveShellInit = ''
              fastfetch
              eval "$(starship init zsh)"
              eval "$(direnv hook zsh)"
              eval "$(zoxide init zsh)"
              eval "$(thefuck --alias)"
              eval "$(thefuck --alias FUCK)"
            '';

            # Disabled as they're no longer needed when setting them session-wide through `launchd` section
            # # Environment variables.
            # variables = {
            #   # Custom certificates
            #   SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   CURL_CA_BUNDLE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   REQUEST_CA_BUNDLE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   PORTABLE_RUBY_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   NODE_EXTRA_CA_CERTS = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   NIX_INSTALLER_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   NIX_SSL_CERT_FILE = "${certificates.paths.system.base}/${certificates.file.ca.pem}";
            #   # Other stuff
            #   HOMEBREW_NO_ANALYTICS = "1"; # No analytics at work plx.
            #   EDITOR = "code --wait"; # Pls use VSCode for editing, thx.
            # };

            # # Kept as a reference for setting up environment variables manually sesssion wide, they're however actually set in the `launchd` section
            # launchAgents = {
            #   environment = {
            #     enable = true;
            #     source = "/Users/${user.name}/Library/LaunchAgents/environment.plist";
            #     text = ''
            #       <?xml version=”1.0″ encoding=”UTF-8″?>
            #       <!DOCTYPE plist PUBLIC “-//Apple//DTD PLIST 1.0//EN” “http://www.apple.com/DTDs/PropertyList-1.0.dtd”>
            #         <plist version=”1.0″>
            #         <dict>
            #         <key>Label</key>
            #         <string>setenv.environment</string>
            #         <key>ProgramArguments</key>
            #         <array>
            #           <string>sh</string>
            #           <string>-c</string>
            #           <string>launchctl setenv ENV_VAR1_NAME ENV_VAR1_VALUE
            #           &&launchctl setenv ENV_VAR2_NAME ENV_VAR2_VALUE
            #           </string>
            #         </array>
            #         <key>RunAtLoad</key>
            #         <true/>
            #       </dict>
            #       </plist>
            #     '';
            #   };
            # };
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#SingleBlockOfAlluminum
      darwinConfigurations."SingleBlockOfAlluminum" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true; # Apple silicon only.
              user = "${user.name}"; # User owning the Homebrew prefix.
              autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."SingleBlockOfAlluminum".pkgs;
    };
}

# 💻 macOS setup

## 🎬 Getting started

> [!IMPORTANT]
> It is necessary to point Nix to a valid certificate authority chain in the first step (1.1) and in your configuration file to allow it to pull anything from the Internet.
> **Do not forget to set this permanently in the configuration or you won't be up for a good time.**

1. Dependancies
   1. (Optional) Custom CA certificate

      ```shell
      curl "http://crldp.pki.campfred.info/crldp/RootCA.crt" --silent --fail --output "$TMPDIR/RootCA.crt"
      export SSL_CERT_FILE=/etc/ssl/certs/RooCA.pem
      sudo openssl x509 -in "$TMPDIR/RootCA.crt" -inform der -out "$SSL_CERT_FILE" -outform pem
      rm RootCA.crt
      export NIX_INSTALLER_SSL_CERT_FILE=${SSL_CERT_FILE}
      export NIX_SSL_CERT_FILE=${SSL_CERT_FILE}
      export REQUEST_CA_BUNDLE=${SSL_CERT_FILE}
      export CURL_CA_BUNDLE=${SSL_CERT_FILE}
      export PORTABLE_RUBY_SSL_CERT_FILE=${SSL_CERT_FILE}
      export NODE_EXTRA_CA_CERTS=${SSL_CERT_FILE}
      ```

   2. Xcode command line tools, from Apple

      ```shell
      xcode-select --install
      ```

   3. Rosetta, from Apple _(optionnal, in case you want to install x86-64 binaries within your setup)_

      ```shell
      softwareupdate --install-rosetta --agree-to-license
      ```

   4. Nix, from Determinate Systems

      ```shell
      export SSL_CERT_FILE=/etc/ssl/certs/RootCA.pem
      export NIX_INSTALLER_SSL_CERT_FILE=${SSL_CERT_FILE}
      export NIX_SSL_CERT_FILE=${SSL_CERT_FILE}
      export REQUEST_CA_BUNDLE=${SSL_CERT_FILE}
      export CURL_CA_BUNDLE=${SSL_CERT_FILE}
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --ssl-cert-file=${NIX_INSTALLER_SSL_CERT_FILE}
      ```

2. Test run

   ```shell
   nix run nixpkgs#hello
   ```

3. Install `nix-darwin`

   ```shell
   nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch --flake . # https://github.com/LnL7/nix-darwin#step-2-installing-nix-darwin
   ```

   Assuming the test run was successful, you can now get the Nix setup going! 🎉

4. Apply configuration

   ```shell
   darwin-rebuild switch --flake .
   ```

5. Yippee! That's it! 🎉
   You now have installed and applied a Nix configuration!
   Now, have fun scrapping your settings and regenerating them!

> [!NOTE]
> Due to the way our administrative privileges are set (they're not set _the macOS way_ but more like _the unix way_), you will need to enter your password several times during builds.
> Use the copy-paste feature of your password manager.

## 🩹 Quirks

### Nix can't find the `darwin` file when attempting to build the config

Simply re-run the `nix run` command from step 3 to rebuild it.

### I used [the official Nix installation procedure](https://nixos.org/download) instead of Determinate Systems' and `flakes` and `nix-command` aren't recognized

`flakes` and `nix-command` aren't available out-of-the-box with the official installer.
You need to enable them in Nix' configuration.

```shell
echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
```

Or you can also specify to include them everytime you run a command that needs them like building the config.

```shell
nix --extra-experimental-features 'nix-command flakes' run .#${command}
```

> [!TIP]
> Keep the `#` before the command.

## ✨ Creating a new configuration

To create a new configuration, simply use the `nix-darwin` template.

```shell
nix flake init --template nix-darwin
```

Then edit your new `flake.nix` configuration file.

> [!TIP]
> You may need to get rid of current `.nix` files in this repository prior to running this command.

## ⛑️ Troubleshooting

### macOS' Dock won't restart

When the macOS Dock app doesn't restart, you may be stuck with a blank desktop with no dock, no workspace and no app switcher (Cmd + Tab).

You may try to launch it manually from a terminal.

```shell
open /System/Library/CoreServices/Dock.app
```

If an error appears stating that the "Launch failed.", you may need to reload the agent that's responsible of restarting the Dock.

```shell
launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
launchctl   load -F /System/Library/LaunchAgents/com.apple.Dock.plist
launchctl start com.apple.Dock.agent
```

[Source 🔗](https://apple.stackexchange.com/a/206440)

## ✨ Extras

These are stuff that I already handle with Nix, but might be useful in case of manual install of a workstation.

### 🏷️ Session-wide environment variables

You can set environment variables that will span accross your session apps and will survive logouts and reboots.
This is especially useful when you need to configure an app or service with environment variables.

So, here's a quick tip for ya that'll allow you to have some environment variables set *✨ all the time ✨*!

1. Make sure that the launch agent / service is indeed unloaded, it's fine if it complains that the file doesn't exist

   > ```shell
   > launchctl unload ~/Library/LaunchAgents/environment.plist
   > ```

2. Edit (or create) the launch agent definition file and add the following content to it then edit the `launchctl setenv` line with your variable's name and value

   > ```xml
   > <?xml version=”1.0″ encoding=”UTF-8″?>
   > <!DOCTYPE plist PUBLIC “-//Apple//DTD PLIST 1.0//EN” “http://www.apple.com/DTDs/PropertyList-1.0.dtd”>
   >   <plist version=”1.0″>
   >   <dict>
   >   <key>Label</key>
   >   <string>setenv.environment</string>
   >   <key>ProgramArguments</key>
   >   <array>
   >     <string>sh</string>
   >     <string>-c</string>
   >     <string>
   >     launchctl setenv ENV_VAR1_NAME ENV_VAR1_VALUE
   >     launchctl setenv ENV_VAR2_NAME ENV_VAR2_VALUE
   >     </string>
   >   </array>
   >   <key>RunAtLoad</key>
   >   <true/>
   > </dict>
   > </plist>
   > ```

3. Reload the launch agent

   > ```shell
   > launchctl load ~/Library/LaunchAgents/environment.plist
   > ````

4. Open a new shell session and check your new environment variable's value! 🎉

   > ```shell
   > env | grep -i ENV_VAR_NAME
   > ```

> [!tip]
> You can also use this tip to run scripts if you like!

### 📦 Colima setup

The Colima VM may need to be provisionned with the custom certificates.
I made a little Python script to get that set up quickly.

> [!caution]
> Make sure to have installed `colima` and to have started the virtual machine at least once with `colima start`.
> Otherwise, the configuration file may not exist and the script will fail.

1. Set up a Python virtual environment

   > ```shell
   > python3 -m venv .venv --upgrade-deps
   > ```

2. Activate it

   > ```shell
   > source .venv/bin/activate
   > ```

3. Install dependencies

   > ```shell
   > python3 -m pip install --requirements requirements.txt
   > ```

4. Run the script

   > ```shell
   > python3 provision_colima_ca_cert.py --repo-url http://crldp.pki.campfred.info/crldp --filename RootCA.crt
   > ```

5. Restart Colima

   > ```shell
   > colima restart
   > ```

> [!tip]
> If you just want to copy-pasta the resulting provisioning script in your `~/.colima/default/colima.yaml` configuration file, here ya go.
>
> ```yaml
> provision:
>   - mode: system
>     script: |
>       echo "Preparing to install custom certificate..."
>       certs_dir="/usr/local/share/ca-certificates/custom_certs"
>       cert_filename="RootCA.pem"
>       url="http://crldp.pki.campfred.info/crldp/$cert_filename"
> 
>       echo "Downloading certificate from $url..."
>       wget $url
> 
>       echo "Converting certificate to PEM format..."
>       sudo mkdir -p "$certs_dir"
>       sudo openssl x509 -inform der -in "$cert_filename" -outform pem -out "$certs_dir/$cert_filename"
> 
>       echo "Installing certificates..."
>       sudo update-ca-certificates
> 
>       echo "Restarting Docker daemon..."
>       sudo systemctl daemon-reload
>       sudo systemctl restart docker
> 
>       echo "Cleaning up..."
>       rm $cert_filename
> 
>       echo "Custom certificate installed."
> ```

## 📚 References

### Libraries

Libraries of resources related to this project.
If you need to add something that's already defined, it's likely listed in one of those.

- [MyNixOS](https://mynixos.com/)
  _Web configuration generator and manager allowing to make and host configurations from the web._
- [nix-darwin Configuration Options](https://daiderd.com/nix-darwin/manual/index.html)
  _Official Nix-Darwin automatically generated documentation._
- [NixOS options library](https://search.nixos.org/options)
  _Official NixOS repository, options section._
- [NixOS packages library](https://search.nixos.org/packages)
  _Official NixOS repository, packages section._
- [Homebrew Formulae](https://formulae.brew.sh/)
  _Official Homebrew repository to find formulas and casks._

### Tutorials and writeups

Any content made about Nix-Darwin, macOS or whatever that has been useful or that inspired the making of this project.

- Nix-Darwin
  - [(Nixacademy) Jacek Galowicz : Setting up Nix on macOS](https://nixcademy.com/posts/nix-on-macos/)
    _Excellent getting started tutorial._
  - [(GitHub) Dustin Lyons : General Purpose Nix Config for macOS + NixOS](https://github.com/dustinlyons/nixos-config)
    _Excellent base templates to start from._
  - [(YouTube) Dreams of Autonomy : Nix is my favorite package manager to use on macOS](https://youtu.be/Z8BL8mdzWHI)
    _Excellent zen configuration and explanations to start from._
  - [(GitHub) Dreams of Autonomy : Nix Darwin](https://github.com/dreamsofautonomy/nix-darwin)
    _Excellent zen configuration and explanations to start from._

- Environment variables
  - [(Dowd and Associates) HowTo: Set an Environment Variable in Mac OS X - launchd.plist](https://www.dowdandassociates.com/blog/content/howto-set-an-environment-variable-in-mac-os-x-launchd-plist/)
    _Simple tutorial on how to leverage services (agents) on macOS to set environment variables accross a GUI session._
  - [(Fig) launchctl setenv <key> <value>](https://fig.io/manual/launchctl/setenv)
    _Command reference for setting environment variables for the GUI session manually._

- Launchd Agents
  - [(Apple) Creating Launch Daemons and Agents](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
    _Official doc for speccing a service on macOS._
  - [(Way Enough) Nix-Darwin Launch Agents](https://www.danielcorin.com/til/nix-darwin/launch-agents/)
    _Tutorial on writing a service agent through Nix-Darwin._

### Related resources

These have been useful for handling stuff either within the configuration or around it.
Including this very ReadMe file!

- [(GitHub) community : [Markdown] An option to highlight a "Note" and "Warning" using blockquote (Beta) #16925](https://github.com/orgs/community/discussions/16925#discussion-4085374)
  _Stylized callouts on GitHub._

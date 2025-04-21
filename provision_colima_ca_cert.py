from pathlib import Path
from typing import List
import argparse, os, logging
import ruamel.yaml
from ruamel.yaml.scalarstring import PreservedScalarString

COLIMA_CONFIG_PATH = f"{Path.home()}/.colima/default/colima.yaml"
CERTS_DIRECTORY_PATH = "/usr/local/share/ca-certificates/custom_certs"  # Maybe change the "custom_certs" one to the name of your domain for better clarity

parser = argparse.ArgumentParser(description="Set colima provision script")
parser.add_argument(
    "-u",
    "--repo-url",
    type=str,
    required=True,
    help="The repository URL to download the CA certificate",
    dest="repo_url",
)
parser.add_argument(
    "-f",
    "--filename",
    type=str,
    required=True,
    help="The name of the CA certificate to download",
)
parser.add_argument(
    "-v",
    "--verbose",
    action="store_true",
    help="Enable verbose output",
)
args = parser.parse_args()
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
if args.verbose:
    logger.setLevel(logging.DEBUG)
yaml = ruamel.yaml.YAML()


class Provision:
    mode: str
    script: str

    def __init__(self, mode: str, script: str) -> None:
        self.mode = mode
        self.script = script


def gen_ca_install_script(repo_url: str, ca_cert_name: str) -> str:
    return f"""\
echo "Preparing to install custom certificate..."
certs_dir="{CERTS_DIRECTORY_PATH}"
cert_filename="{ca_cert_name}"
url="{repo_url}/$cert_filename"

echo "Downloading certificate from $url..."
wget $url

echo "Converting certificate to PEM format..."
sudo mkdir -p "$certs_dir"
sudo openssl x509 -inform der -in "$cert_filename" -outform pem -out "$certs_dir/$cert_filename"

echo "Installing certificate..."
sudo update-ca-certificates

echo "Restarting Docker daemon..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Cleaning up..."
rm $cert_filename

echo "Custom certificate installed."
"""


def main():
    logger.info(
        f"Setting up provision script for installing certificate {args.filename} from {args.repo_url}."
    )
    logger.debug("Opening Colima configuration file...")
    with open(COLIMA_CONFIG_PATH, "+r") as file:
        logger.debug("Reading Colima configuration file...")
        config = yaml.load(file)
        file.close()

        logger.debug("Generating install script...")
        provision_script = gen_ca_install_script(args.repo_url, args.filename)

        logger.debug("Checking if the script already exists...")
        script_exists = any(
            provision.get("script") == provision_script
            for provision in config.get("provision", [])
        )

        if not script_exists:
            logger.debug("Appending script to existing provisioning scripts...")
            config["provision"].append(
                Provision("system", PreservedScalarString(provision_script)).__dict__
            )
            logger.debug("Writing updated configuration file...")
            os.rename(
                COLIMA_CONFIG_PATH,
                f"{COLIMA_CONFIG_PATH}.orig",
            )
            with open(COLIMA_CONFIG_PATH, "w") as file:
                yaml.dump(config, file)
                file.close()
            logger.info(
                f"Provision script added to {COLIMA_CONFIG_PATH}. Please restart Colima."
            )
        else:
            logger.info("Script already exists. Nothing to do.")


if __name__ == "__main__":
    main()

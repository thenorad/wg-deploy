# wg-deploy, it's project for deploing Wireguard VPN + UI

## Requirenments
1. Ubuntu 22.04 (tested, other distros needs to test yourself)
2. Installed `git` package, setup it by comand: `apt install git -y`
3. Use `root` user when running script.

## Installation:
1. Clone repository:
`git clone https://github.com/thenorad/wg-deploy.git`
2. Go to the directory:
`cd ./wg-deploy`
3. Run installation script:
`./install.sh`. Available parameters: `WEB_UI_PASS`, `WG_NETWORK`, `WG_PORT`.

For example: `./install.sh chohGh1ahr 192.168.6.1/24 58100`. 

If parameters are unset, script will generate values automatically.

## Using:
1. Log in to the server via SSH, you will see message that contains WEB UI credentials
2. Open in browser: http://<SERVER_IP>:5000/, log in to the panel with login adn password.
3. Create users that you need,
4. Apply settings by pressing "Apply config" button on top of the screen.

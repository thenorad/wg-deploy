# wg-deploy, it's project for deploing Wireguard VPN + UI

## Installation:
1. Clone repository:
`git clone https://github.com/thenorad/wg-deploy.git`
2. Go to the directory:
`cd ./wg-deploy`
3. Run installation script:
`./install.sh`
Available parameters: `WEB_UI_PASS`, `WG_NETWORK`, `WG_PORT`.

For example: `./install.sh chohGh1ahr 192.168.6.1/24 58100`. 

If parameters are unset, script will generate values automatically.

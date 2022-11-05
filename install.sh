#!/bin/bash
#update system and install packages
autorestart_policy=$(grep 'nrconf.*restart' /etc/needrestart/needrestart.conf | grep -v '^#')
if [[ $autorestart_policy == '' ]]; then sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf; fi
sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
sudo apt update
if [ ! $? -eq 0 ]; then echo 'ERROR: cant update APT cache, try to make it itself: sudo apt update'; exit 1; fi
sudo apt -o Dpkg::Options::='--force-confold' -y upgrade
if [ ! $? -eq 0 ]; then echo 'ERROR: cant upgrade system, try to make it itself: sudo apt upgrade'; exit 1; fi
sudo apt -o Dpkg::Options::='--force-confold' -y install wireguard nftables jq unzip
if [ ! $? -eq 0 ]; then echo 'ERROR: cant download packages, try to make it itself: apt install wireguard nftables jq unzip'; exit 1; fi

#prepare DB and wireguard binary
unzip db.zip
cp -r ./db /root/
chmod +x ./wireguard-ui
cp ./wireguard-ui /root/

#setup web configs
ip_addr=$(curl -s -k 2ip.ru)
sed -i "s/PUBLIC_VPN_ADDR/$ip_addr/g" /root/db/server/global_settings.json
if [ -z $1 ]; then password=$(pwgen 30 -n1); else password="$1"; fi
sed -i "s/PASSWORD/$password/g" /root/db/server/users.json
if [ -z $2 ]; then addr="192.168.6.1/24"; else addr="$2"; fi
sed -i "s/PRIVATE_VPN_ADDR/$addr/g" /root/db/server/interfaces.json
if [ -z $3 ]; then port="21"; else port="$3"; fi
sed -i "s/LISTEN_PORT/$port/g" /root/db/server/interfaces.json

#create systemd services
sudo touch /etc/systemd/system/wgui.service
sudo cat << EOF > /etc/systemd/system/wgui.service
[Unit]
Description=Restart WireGuard
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart wg-quick@wg0.service

[Install]
RequiredBy=wgui.path
EOF

sudo touch /etc/systemd/system/wgui.path
sudo cat << EOF2 > /etc/systemd/system/wgui.path
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes

[Path]
PathModified=/etc/wireguard/wg0.conf

[Install]
WantedBy=multi-user.target
EOF2

sudo touch /etc/systemd/system/wireguard-ui.service
sudo cat << EOF3 > /etc/systemd/system/wireguard-ui.service
[Unit]
Description=Wireguard-UI
After=network.target

[Service]
Type=simple
WorkingDirectory=/root
ExecStart=/root/wireguard-ui
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=Wireguard-UI
User=root
Group=root
Environment=PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/root/botShakes

[Install]
WantedBy=multi-user.target
EOF3

#create directories and files
mkdir -m 0700 /etc/wireguard/
sudo touch /etc/wireguard/wg0.conf

#enable forwarding
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo sysctl -w "net.ipv4.ip_forward=1"

#enable services
sudo systemctl daemon-reload
sudo systemctl enable wgui.{path,service}
sudo systemctl start wgui.{path,service}
sudo systemctl enable wireguard-ui
sudo systemctl start wireguard-ui

#setup firewall
cp ./nftables.conf /etc/nftables.conf
systemctl restart nftables

#show wg status
sudo wg
sudo ip a show wg0

#add colored motd message
cat > /etc/update-motd.d/93-wireguard << 'EOF2'
#!/bin/bash
export TERM=xterm-256color
ip_addr=$(cat /root/db/server/global_settings.json | jq -r '.endpoint_address')
username=$(cat /root/db/server/users.json | jq -r '.username')
password=$(cat /root/db/server/users.json | jq -r '.password')
if echo "$ip_addr" | grep -q ':'; then ip_addr="[$ip_addr]"; fi
echo "$(tput setaf 10)

===================== Wireguard UI =====================
URL: http://$ip_addr:5000/login
Login: $username
Password: $password
========================================================

$(tput sgr0)"
EOF2
chmod +x /etc/update-motd.d/93-wireguard

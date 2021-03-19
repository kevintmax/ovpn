sudo apt update
sudo apt install openvpn
wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
tar xvf EasyRSA-3.0.4.tgz
cd ~/EasyRSA-3.0.4/
cp ~/ovpn/vars ~/EasyRSA-3.0.4/vars
~/EasyRSA-3.0.4/easyrsa init-pki
echo | ~/EasyRSA-3.0.4/easyrsa build-ca nopass
echo | ~/EasyRSA-3.0.4/easyrsa gen-req server nopass
sudo cp ~/EasyRSA-3.0.4/pki/private/server.key /etc/openvpn/
~/EasyRSA-3.0.4/easyrsa sign-req server server <<< "yes"
sudo cp ~/EasyRSA-3.0.4/pki/issued/server.crt /etc/openvpn/
sudo cp ~/EasyRSA-3.0.4/pki/ca.crt /etc/openvpn/
~/EasyRSA-3.0.4/easyrsa gen-dh
openvpn --genkey --secret ta.key
sudo cp ~/EasyRSA-3.0.4/ta.key /etc/openvpn/
sudo cp ~/EasyRSA-3.0.4/pki/dh.pem /etc/openvpn/
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
echo | ~/EasyRSA-3.0.4/easyrsa gen-req vp nopass
cp pki/private/vp.key ~/client-configs/keys/
~/EasyRSA-3.0.4/easyrsa sign-req client vp <<< "yes"
sudo cp pki/issued/vp.crt ~/client-configs/keys/
sudo cp ~/EasyRSA-3.0.4/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz
rm -rf /etc/openvpn/server.conf; cp ~/ovpn/server.conf /etc/openvpn/server.conf
rm -rf /etc/sysctl.conf; cp ~/ovpn/sysctl.conf /etc/sysctl.conf
sudo sysctl -p
fire=$(ip route | grep default | awk '{print $5}')
rm /etc/ufw/before.rules
echo "-A POSTROUTING -s 10.8.0.0/8 -o $fire -j MASQUERADE" >> /etc/ufw/before.rules
echo "# Allow traffic from OpenVPN client to $fire" >> /etc/ufw/before.rules
echo "-A POSTROUTING -s 10.8.0.0/8 -o $fire -j MASQUERADE" >> /etc/ufw/before.rules
echo "COMMIT" >> /etc/ufw/before.rules
echo "# END OPENVPN RULES" >> /etc/ufw/before.rules
echo "#" >> /etc/ufw/before.rules
rm /etc/default/ufw
cp ~/ovpn/ufw /etc/default/ufw
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw disable
sudo ufw enable
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server


sudo apt update
sudo apt install -y openvpn
cd
wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz
tar xvf ~/EasyRSA-3.0.4.tgz

cat ~/ovpn/vars >> ~/EasyRSA-3.0.4/vars

cd ~/EasyRSA-3.0.4/; ./easyrsa init-pki
cd ~/EasyRSA-3.0.4/; echo "" | ./easyrsa build-ca nopass
cd ~/EasyRSA-3.0.4/; echo "" | ./easyrsa gen-req server nopass
sudo cp ~/EasyRSA-3.0.4/pki/private/server.key /etc/openvpn/
cd ~/EasyRSA-3.0.4/; ./easyrsa sign-req server server <<< "yes"
sudo cp ~/EasyRSA-3.0.4/pki/issued/server.crt /etc/openvpn/
sudo cp ~/EasyRSA-3.0.4/pki/ca.crt /etc/openvpn/

cd ~/EasyRSA-3.0.4/; ./easyrsa gen-dh
cd ~/EasyRSA-3.0.4/; openvpn --genkey --secret ta.key
sudo cp ~/EasyRSA-3.0.4/ta.key /etc/openvpn/
sudo cp ~/EasyRSA-3.0.4/pki/dh.pem /etc/openvpn/

mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
cd ~/EasyRSA-3.0.4/; echo "" | ./easyrsa gen-req vagabond nopass
cp pki/private/vagabond.key ~/client-configs/keys/
cd ~/EasyRSA-3.0.4/; ./easyrsa sign-req client vagabond <<< "yes"
sudo cp pki/issued/vagabond.crt ~/client-configs/keys/

sudo cp ~/EasyRSA-3.0.4/ta.key ~/client-configs/keys/
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz
sudo rm -rf /etc/openvpn/server.conf
sudo cp ~/ovpn/server.conf /etc/openvpn/server.conf
sudo rm -rf /etc/sysctl.conf
sudo cp ~/ovpn/sysctl.conf /etc/sysctl.conf
sudo sysctl -p

sudo rm -rf /etc/ufw/before.rules
sudo cp ~/ovpn/before.rules1 /etc/ufw/before.rules
sudo chmod 777 -R /etc/ufw

fire=$(ip route | grep default | awk '{print $5}')
echo "# START OPENVPN RULES" >> /etc/ufw/before.rules 
sudo echo "# NAT table rules" >> /etc/ufw/before.rules 
sudo echo "*nat" >> /etc/ufw/before.rules 
sudo echo ":POSTROUTING ACCEPT [0:0]" >> /etc/ufw/before.rules 
sudo echo "# Allow traffic from OpenVPN client to $fire" >> /etc/ufw/before.rules 
sudo echo "-A POSTROUTING -s 10.8.0.0/8 -o $fire -j MASQUERADE" >> /etc/ufw/before.rules 
sudo echo "COMMIT" >> /etc/ufw/before.rules 
sudo echo "# END OPENVPN RULES" >> /etc/ufw/before.rules 
sudo echo "#" >> /etc/ufw/before.rules 

cat ~/ovpn/before.rules2 >> /etc/ufw/before.rules

sudo chmod 777 -R /etc/default

rm -rf /etc/default/ufw
cp ~/ovpn/ufw /etc/default/ufw

sudo ufw allow 1194/udp
sudo ufw allow OpenSSH

sudo ufw disable
yes | sudo ufw enable

sudo systemctl start openvpn@server
#sudo systemctl status openvpn@server 
ip addr show tun0
sudo systemctl enable openvpn@server

mkdir -p ~/client-configs/files
cp ~/ovpn/base.conf1 ~/client-configs/base.conf
myip=$(hostname -I | awk '{print $1}')
echo "remote $myip 1194" >> ~/client-configs/base.conf
cat ~/ovpn/base.conf2 >> ~/client-configs/base.conf


sudo chmod 700 ~/ovpn/make_config.sh

sudo chmod 777 -R ~/client-configs
cd ~/ovpn; ./make_config.sh vagabond

sudo cp ~/client-configs/keys/ta.key ~/client-configs/files/
cd ~/client-configs/files/; sudo chmod 644 ta.key 

echo "type below commands to download vpn files"
echo "sftp -i ~/.ssh/master root@66.42.41.167:client-configs/files/vagabond.ovpn ~/Desktop/"

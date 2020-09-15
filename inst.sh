#!/bin/bash

#SSH Config
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/script90/2.9/master/install/sshd_config > /dev/null 2>&1
service ssh restart

#Ask for password if necessary
sudo echo

#Add Trusty Sources
sudo touch /etc/apt/sources.list.d/trusty_sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty main universe" | sudo tee --append /etc/apt/sources.list.d/trusty_sources.list > /dev/null

#Update
sudo apt update

#Install Squid
sudo apt install -y squid3=3.3.8-1ubuntu6 squid=3.3.8-1ubuntu6 squid3-common=3.3.8-1ubuntu6

#Install missing init.d script
wget https://raw.githubusercontent.com/script90/squid3/master/squid3
sudo cp squid3 /etc/init.d/
sudo chmod +x /etc/init.d/squid3
sudo update-rc.d squid3 defaults

#Quest Squid
IP=$(wget -qO- ipv4.icanhazip.com)
echo -ne "PARA CONTINUAR CONFIRME SEU IP: "; read -e -i $IP ipdovps
if [[ -z "$ipdovps" ]];then
echo -e "\nIP invalido"
echo ""
read -p "Digite seu IP: " IP
fi
echo -e "\nQUAIS PORTAS DESEJA ULTILIZAR NO SQUID ?"
echo -e "\n[!] DEFINA AS PORTAS EM SEQUENCIA - EX: 80 8080 8799"
echo ""
echo -ne "INFORME AS PORTAS: "; read portass
if [[ -z "$portass" ]]; then
	echo -e "\nPorta invalida!"
	sleep 2
	fun_conexao
fi
for porta in $(echo -e $portass); do
	verif_ptrs $porta
done

#Config Payload
echo ".claro.com.br/
.claro.com.sv/
.facebook.net/
.netclaro.com.br/
.speedtest.net/
.tim.com.br/
.vivo.com.br/
.oi.com.br/" > /etc/squid3/payload.txt

#Config Squid3
echo "acl url1 dstdomain -i 127.0.0.1
acl url2 dstdomain -i localhost
acl url3 dstdomain -i $ipdovps
acl payload url_regex -i /etc/squid3/payload.txt
acl all src 0.0.0.0/0
http_access allow url1
http_access allow url2
http_access allow url3
http_access allow payload
http_access deny all
 
#Portas" > /etc/squid3/squid.conf
for Pts in $(echo -e $portass); do
echo -e "http_port $Pts" >> /etc/squid3/squid.conf
[[ -f "/usr/sbin/ufw" ]] && ufw allow $Pts/tcp
done
echo -e "
#Nome squid
visible_hostname SQUID3 
via off
forwarded_for off
pipeline_prefetch off" >> /etc/squid3/squid.conf

#Start squid
squid3 -k reconfigure
service ssh restart
service squid3 start

#Limpando
rm squid3
rm inst.sh

#Print info
clear
echo "====================================="
echo "Squid 3.3.8 instalado com sucesso!"
echo "====================================="

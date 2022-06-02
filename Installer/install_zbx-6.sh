#!/bin/bash

#Menu
OPTION=$(whiptail --title "Desenvolvido por Daniel Pereira" --radiolist \
"Escolha abaixo:" 15 60 5 \
"Instalar Zabbix - Backend" "" ON \
"Instalar Zabbix - Server" "" OFF \
"Instalar Zabbix - Frontend" "" OFF \
"Instalar Zabbix - Proxy" "" OFF \
"Instalar Grafana" "" OFF 3>&1 1>&2 2>&3)

#Variaveis
URL_ZABBIX=https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
URL_GRAFANA=https://dl.grafana.com/enterprise/release/grafana-enterprise-8.4.5-1.x86_64.rpm

#Opções
case $OPTION in

       	'Instalar Zabbix - Backend')
			#Iniciando
			clear
			
			#Variaveis
			MYSQL="mysql -uroot"
			PASSFE=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c${1:-12}; echo)
			PASSZBX=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c${1:-12}; echo)
			PASSROOT=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c${1:-12}; echo)
			SRVIP=$(whiptail --title "Digite o IP do seu Zabbix Server" --inputbox "IP:" 10 60 3>&1 1>&2 2>&3)
			FEIP=$(whiptail --title "Digite o IP do seu Zabbix Front End" --inputbox "IP:" 10 60 3>&1 1>&2 2>&3)

			#Ajustando Firewall
			echo '1/4: Ajustando Firewall'
			firewall-cmd --permanent --add-port=3306/tcp > /dev/null 2>&1
			firewall-cmd --reload > /dev/null 2>&1
			setenforce 0 > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1

			##Banco de Dados
			#Instalando
			echo '2/4: Instalando Mysql Server'
			dnf clean all > /dev/null 2>&1
			dnf install mysql-server -y > /dev/null 2>&1
			systemctl enable --now mysqld > /dev/null 2>&1

			#Criando banco de dados e alterando a senha de root
			echo '3/4: Criando o Banco de Dados para o Zabbix'
			${MYSQL} -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin";
			${MYSQL} -e "create user 'zabbix_srv'@'"$SRVIP"' identified by '$PASSZBX'";
			${MYSQL} -e "grant all privileges on zabbix.* to 'zabbix_srv'@'"$SRVIP"'";
			${MYSQL} -e "flush privileges";
			${MYSQL} -e "create user 'zabbix_fe'@'"$FEIP"' identified by '$PASSFE'";
			${MYSQL} -e "grant all privileges on zabbix.* to 'zabbix_fe'@'"$FEIP"'";
			${MYSQL} -e "flush privileges";
			${MYSQL} -e "alter user 'root'@'localhost' identified by '$PASSROOT'";

			#Reiniciando os serviços
			echo '4/4: Reiniciando os Serviços'
			systemctl restart mysqld > /dev/null 2>&1
			
			#Informando as senhas geradas
			echo ROOT: $PASSROOT >> mysql.log
			echo ZBX: $PASSZBX >> mysql.log
			echo FE: $PASSFE >> mysql.log
			
			clear
			#Informando as senhas
			echo    
			echo ================================================
			echo "Senha root = $PASSROOT"
			echo "Senha Zabbix Server = $PASSZBX"
			echo "Senha Zabbix Frontend = $PASSFE"
			echo ================================================
			echo    
		;;
		'Instalar Zabbix - Server')
			#Iniciando
			clear

			#Variaveis
			DBIP=$(whiptail --title "Digite o IP do seu banco de dados" --inputbox "IP:" 10 60 3>&1 1>&2 2>&3)
			ZBXPASS=$(whiptail --title "Digite a senha para o usuario Zabbix" --inputbox "SENHA:" 10 60 3>&1 1>&2 2>&3)

			#Ajustando o Firewall
			echo '1/7: Ajustando o Firewall'
			firewall-cmd --permanent --add-port=10051/tcp > /dev/null 2>&1
			firewall-cmd --permanent --add-port=10050/tcp > /dev/null 2>&1
			firewall-cmd --reload > /dev/null 2>&1
			setenforce 0 > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1

			#Instalando o pacote MYSQL
			echo '2/7: Instalando o pacote MYSQL'
			dnf clean all > /dev/null 2>&1
			dnf install mysql -y > /dev/null 2>&1

			##Baixando e instalando os pacotes do Zabbix
			#Baixando
			echo '3/7: Baixando o pacote do Zabbix'  
			dnf clean all > /dev/null 2>&1          
			dnf install $URL_ZABBIX -y > /dev/null 2>&1

			#Instalando
			echo '4/7: Instalando os pacotes' 
			dnf install zabbix-server -y > /dev/null 2>&1

			#Importando o schema
			echo '5/7: Importando o Schema para o Banco de Dados'
			zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -h$DBIP -uzabbix_srv -p"$ZBXPASS" zabbix > /dev/null 2>&1

			#Configurando o zabbix
			echo '6/7: Configurando o Zabbix'
			sed -i "s/# DBPassword=/DBPassword=$ZBXPASS/g" /etc/zabbix/zabbix_server.conf
			sed -i "s/# DBHost=localhost/DBHost=$DBIP/g" /etc/zabbix/zabbix_server.conf
			sed -i "s/# DBUser=zabbix/DBUser=zabbix_srv/g" /etc/zabbix/zabbix_server.conf
			
			#Iniciando os serviços
			echo '7/7: Iniciando os serviços'
			systemctl enable --now zabbix-server > /dev/null 2>&1
		;;
		'Instalar Zabbix - Frontend')
			#Iniciando
			clear
						
			#Ajustando o Firewall
			echo '1/5: Ajustando o Firewall'
			firewall-cmd --permanent --add-service=http
			firewall-cmd --reload > /dev/null 2>&1
			setenforce 0 > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1

			##Baixando e instalando os pacotes do Zabbix
			#Baixando
			echo '2/5: Baixando o pacote do Zabbix'  
			dnf clean all > /dev/null 2>&1          
			dnf install $URL_ZABBIX -y > /dev/null 2>&1

			#Instalando
			echo '3/5: Instalando os pacotes' 
			dnf clean all > /dev/null 2>&1
			dnf install zabbix-web-mysql zabbix-nginx-conf -y > /dev/null 2>&1

			#Alterando o timezone do PHP
			echo '4/5: Alterando o timezone do PHP' 
			echo  "php_value[date.timezone] = America/Sao_Paulo" >> /etc/php-fpm.d/zabbix.conf > /dev/null 2>&1

			#Iniciando os serviços
			echo '5/5: Iniciando os serviços'
			systemctl enable --now nginx php-fpm > /dev/null 2>&1
		;;
		'Instalar Zabbix - Proxy')
			#Iniciando
			clear
			
			#Variaveis
			MYSQL="mysql -uroot"
			PASSZBX=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c${1:-12}; echo)
			PASSROOT=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c${1:-12}; echo)
			ZBXIP=$(whiptail --title "Digite o IP do seu Zabbix Server" --inputbox "IP:" 10 60 3>&1 1>&2 2>&3)
			PRXNAME=$(whiptail --title "Digite o nome do Zabbix Proxy (Hostname):" --inputbox "NOME:" 10 60 3>&1 1>&2 2>&3)

			#Ajustando Firewall
			echo '1/7: Ajustando Firewall'
			setenforce 0 > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1

			##Banco de Dados##
			#Baixando o pacote do mysql
			echo '2/7: Instalando Mysql Server'
			dnf clean all > /dev/null 2>&1
			dnf install mysql-server mysql -y > /dev/null 2>&1
			systemctl enable --now mysqld > /dev/null 2>&1

			#Criando banco de dados e alterando a senha de root
			echo '3/7: Instalando Mysql Server'
			${MYSQL} -e "CREATE DATABASE zabbix_proxy CHARACTER SET utf8 COLLATE utf8_bin";
			${MYSQL} -e "create user 'zabbix'@'localhost' identified by '$PASSZBX'";
			${MYSQL} -e "grant all privileges on zabbix_proxy.* to 'zabbix'@'localhost'";
			${MYSQL} -e "flush privileges";
			${MYSQL} -e "alter user 'root'@'localhost' identified by '$PASSROOT'";

			#Baixando e instalado o pacote do zabbix proxy
			echo '4/7: Instalando Zabbix Proxy'
			dnf clean all > /dev/null 2>&1
			dnf install $URL_ZABBIX -y > /dev/null 2>&1
			dnf install zabbix-proxy-mysql zabbix-sql-scripts -y > /dev/null 2>&1

			#Importando o schema
			echo '5/7: Importando o Schema para o banco de dados'
			zcat /usr/share/doc/zabbix-sql-scripts/mysql/schema.sql.gz | mysql -uzabbix -p$PASSZBX zabbix_proxy

			#Configurações
			echo '6/7: Realizando configurações no arquivo do Zabbix Proxy'
			sed -i "s/# DBPassword=/DBPassword=$PASSZBX/g" /etc/zabbix/zabbix_server.conf
			sed -i "s/# ProxyMode=0/ProxyMode=0/g" /etc/zabbix/zabbix_proxy.conf
			sed -i "s/Server=127.0.0.1/Server=$ZBXIP/g" /etc/zabbix/zabbix_proxy.conf
			sed -i "s/Hostname=Zabbix proxy/Hostname=$PRXNAME/g" /etc/zabbix/zabbix_proxy.conf
			sed -i "s/# ConfigFrequency=3600/ConfigFrequency=60/g" /etc/zabbix/zabbix_proxy.conf
			sed -i "s/# DataSenderFrequency=1/DataSederFrequency=10/g" /etc/zabbix/zabbix_proxy.conf
			sed -i "s/# ProxyOfflineBuffer=1/ProxyOfflineBuffer=72/g" /etc/zabbix/zabbix_proxy.conf

			#Iniciando serviços
			echo '7/7: Inciando os serviços'
			systemctl enable --now zabbix-proxy > /dev/null 2>&1

			clear
			
			#Informando as senhas geradas
			echo ROOT: $PASSROOT >> mysql.log
			echo ZBX: $PASSZBX >> mysql.log

			#Informando as senhas
			echo    
			echo ================================================
			echo "Senha root = $PASSROOT"
			echo "Senha Zabbix Proxy = $PASSZBX"
			echo ================================================
			echo    
		;;
		'Instalar Grafana')
			#Limpando a tela
			clear
			
			#Ajustando o firewall
			echo '1/4: Ajustando Firewall'
			setenforce 0 > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /dev/null 2>&1
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config > /dev/null 2>&1
			firewall-cmd --permanent --add-port=3000/tcp > /dev/null 2>&1
			firewall-cmd --reload > /dev/null 2>&1
			
			#Baixando o pacote
			echo '2/4: Baixando o pacote'
			wget $URL_GRAFANA > /dev/null 2>&1
			
			#Instalando
			echo '3/4: Instalando'
			yum install grafana-enterprise-8.4.5-1.x86_64.rpm -y > /dev/null 2>&1
			
			#Iniciando
			echo '3/4: Iniciando o serviço do grafana-server'
			systemctl enable --now grafana-server > /dev/null 2>&1
		;;
esac

exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "$OPTION Concluido!"
else
    echo "Cancelado"
fi

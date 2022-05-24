#!/bin/bash

#Menu
OPTION=$(whiptail --title "Desenvolvido por Daniel Pereira" --radiolist \
"Escolha abaixo:" 15 60 5 \
"Instalar Zabbix - Backend" "" ON \
"Instalar Zabbix - Server" "" OFF \
"Instalar Zabbix - Frontend" "" OFF \
"Instalar Zabbix - Proxy" "" OFF \
"Instalar Zabbix - Agent" "" OFF \
"Instalar Grafana" "" OFF \
"Aplicar Firewall" "" OFF \
"Rotina de Backup" "" OFF 3>&1 1>&2 2>&3)

#Opções
case $OPTION in

       	 	'Instalar Zabbix - Backend')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Shell/main/Instaladores/Zabbix%206.0/RHEL8/install_zabbix_bd.sh
			chmod +x install_zabbix_bd.sh
			bash install_zabbix_bd.sh
		;;
		'Instalar Zabbix - Server')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Shell/main/Instaladores/Zabbix%206.0/RHEL8/install_zabbix_srv.sh
			chmod +x install_zabbix_srv.sh
			bash install_zabbix_srv.sh
		;;
		'Instalar Zabbix - Frontend')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Shell/main/Instaladores/Zabbix%206.0/RHEL8/install_zabbix_fe.sh
			chmod +x install_zabbix_fe.sh
			bash install_zabbix_fe.sh
		;;
		'Instalar Zabbix - Proxy')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Shell/main/Instaladores/Zabbix%206.0/RHEL8/install_zabbix_proxy.sh
			chmod +x install_zabbix_proxy.sh
			bash install_zabbix_proxy.sh

		;;
		'Instalar Zabbix - Agent')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Scripts/main/Instaladores/install_zabbix_agent.sh
			chmod +x install_zabbix_agent.sh
			bash install_zabbix_agent.sh
		;;
		'Instalar Grafana')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Scripts/main/Instaladores/install_zabbix_agent.sh
			chmod +x install_zabbix_agent.sh
			bash install_zabbix_agent.sh
		;;
		'Instalar Graylog')
			#Limpando a tela
			clear
			
			#Baixando o script
			wget https://raw.githubusercontent.com/danielsilvapereira/Scripts/main/Instaladores/install_graylog.sh
			chmod +x install_graylog.sh
			bash install_graylog.sh
		;;
		'Aplicar Firewall')
			#Limpando a tela
			clear
			
			#Entrando na pasta e baixando o script
			echo '1/1: Baixando o Script'
			cd /etc/init.d/ > /dev/null 2>&1
			wget https://raw.githubusercontent.com/danielsilvapereira/Scripts/main/Firewall/filter_rules.sh > /dev/null 2>&1
			chmod a+x filter_rules.sh > /dev/null 2>&1
			cd /root/ > /dev/null 2>&1
		;;
		'Rotina de Backup')
			clear
			
			#Baixando script na raiz
			echo '1/2: Baixando o Script'
			cd /root/ > /dev/null 2>&1
			wget https://raw.githubusercontent.com/danielsilvapereira/Scripts/main/Backups/bd_local.sh > /dev/null 2>&1
			chmod +x bd_local.sh
			
			#Agendando
			echo '2/2: Agendando no Crontab'
			(crontab -l; echo "0 18 * * * bash /root/bd_local.sh 2>&1") | crontab -
esac

exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "$OPTION Concluido!"
else
    echo "Cancelado"
fi

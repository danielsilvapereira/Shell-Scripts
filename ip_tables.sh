##chmod a+x /etc/init.d/filter_rules.sh##
##/etc/init.d/ip_tables.sh start##

###################################################################################
# Desenvolvido por Daniel Pereira
###################################################################################

#!/bin/bash

#Portas
PORTAS=

#IPs V4 permitindo
IP4GERENCIA=

#IPs V6 permitindo
IP6GERENCIA=
 
#Infos e exec
VERMELHO='\033[1;31m'
VERDE='\033[1;32m'
AZUL='\033[1;36m'
AMARELO='\033[1;33m'
ROSA='\033[1;35m'
NC='\033[0m'
 
function startFirewall(){
    /sbin/iptables -F
    /sbin/iptables -X
    /sbin/iptables -t nat -F
    /sbin/iptables -X -t nat
    /sbin/iptables -F -t mangle
    /sbin/iptables -X -t mangle
    /sbin/ip6tables -F
    /sbin/ip6tables -X
    /sbin/ip6tables -F -t mangle
    /sbin/ip6tables -X -t mangle
    /sbin/modprobe ip_conntrack_ftp
    /sbin/modprobe ip_nat_ftp
    /sbin/modprobe ipt_state
    /sbin/modprobe ipt_limit
    /sbin/modprobe ipt_MASQUERADE
    /sbin/modprobe ipt_LOG
    /sbin/modprobe iptable_nat
    /sbin/modprobe iptable_filter
    /sbin/modprobe ip_gre
    #Protege portas IPv4
    echo; echo -e "[${ROSA} Regras IPv4 ${NC}]"; echo
    portas=$(echo $PORTAS | tr ";" "\n")
    for porta in $portas
    do
        ip4s=$(echo $IP4GERENCIA | tr ";" "\n")
        for ip4 in $ip4s
        do
            /sbin/iptables -A INPUT -s $ip4 -p tcp --dport $porta -j ACCEPT
            /sbin/iptables -A INPUT -s $ip4 -p udp --dport $porta -j ACCEPT
            echo -e "[${VERDE} ok ${NC}] Porta ${AMARELO}[$porta]${NC} aberta para ${AZUL}$ip4${NC}"
            sleep 0.1
        done
    done
    portas=$(echo $PORTAS | tr ";" "\n")
    for porta in $portas
    do
        /sbin/iptables -A INPUT -p tcp --dport $porta -j DROP
        echo -e "[${VERDE} ok ${NC}] Porta ${VERMELHO}[$porta]${NC} fechada"
        sleep 0.1
    done
    #Protege portas IPv6
    echo; echo -e "[${ROSA} Regras IPv6 ${NC}]"; echo
 
    portas=$(echo $PORTAS | tr ";" "\n")
    for porta in $portas
    do
        ip6s=$(echo $IP6GERENCIA | tr ";" "\n")
        for ip6 in $ip6s
        do
            /sbin/ip6tables -A INPUT -s $ip6 -p tcp --dport $porta -j ACCEPT
            /sbin/ip6tables -A INPUT -s $ip6 -p udp --dport $porta -j ACCEPT
            echo -e "[${VERDE} ok ${NC}] Porta ${AMARELO}[$porta]${NC} aberta para ${AZUL}$ip6${NC}"
        done
    done
    portas=$(echo $PORTAS | tr ";" "\n")
    for porta in $portas
    do
        /sbin/ip6tables -A INPUT -p tcp --dport $porta -j DROP
        echo -e "[${VERDE} ok ${NC}] Porta ${VERMELHO}[$porta]${NC} fechada"
        sleep 0.1
    done
}
 
function stopFirewall(){
    /sbin/iptables -F
    /sbin/iptables -X
    /sbin/iptables -t nat -F
    /sbin/iptables -X -t nat
    /sbin/iptables -F -t mangle
    /sbin/iptables -X -t mangle
 
    /sbin/ip6tables -F
    /sbin/ip6tables -X
    /sbin/ip6tables -F -t mangle
    /sbin/ip6tables -X -t mangle
 
    /sbin/modprobe ip_conntrack_ftp
    /sbin/modprobe ip_nat_ftp
    /sbin/modprobe ipt_state
    /sbin/modprobe ipt_limit
    /sbin/modprobe ipt_MASQUERADE
    /sbin/modprobe ipt_LOG
    /sbin/modprobe iptable_nat
    /sbin/modprobe iptable_filter
    /sbin/modprobe ip_gre
}
 
case "$1" in
    start )
        startFirewall
        echo; echo -e "[${VERDE} Firewall carregado ${NC}]"; 
        echo "Use: /etc/init.d/rr-firewall status"
        echo "para verificar as regras"
        ;;
 
    stop )
        stopFirewall
        echo; echo -e "[${VERDE} Regras de firewall removidas ${NC}]"; echo
        ;;
 
    restart )
        stopFirewall
        sleep 1
        startFirewall
        ;;
 
    status )
        echo; echo -e "[${VERDE} Regras IPv4 ${NC}]"; echo
        /sbin/iptables -nL
        echo; echo -e "[${VERDE} Regras IPv6 ${NC}]"; echo
        /sbin/ip6tables -nL
        ;;
 
    * )
        echo "Opção inválida, use rr-firewall start | stop | restart | status"
        ;;
esac

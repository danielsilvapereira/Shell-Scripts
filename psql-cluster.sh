#!/bin/bash

#Inicio
clear
echo "############ INSTALADOR CLUSTER POSTGRESQL ############ "

#Variaveis
repmgr_conf="/var/lib/pgsql/repmgr.conf"

#Opções
read -p "DIGITE A VERSÃO DO POSTGRESQL (default é 13): " versao
versao=${versao:-13}
read -p "DIGITE UM NOME PARA O SERVIDOR MASTER (DEFAULT=node-master): " master_nome
master_nome=${master_nome:-node-master}
read -p "DIGITE O IP DO SERVIDOR MASTER: " master_ip
master_ip=${master_ip:-192.168.1.1}
read -p "DIGITE UM NOME PARA O SERVIDOR SLAVE (DEFAULT=node-slave): " slave_nome
slave_nome=${slave_nome:-node-slave}
read -p "DIGITE O IP DO SERVIDOR SLAVE: " slave_ip
slave_ip=${slave_ip:-192.168.1.2}
read -p "SLAVE: DIGITE A SENHA DE ACESSO AO SERVIDOR SLAVE: " slave_pass
slave_pass=${slave_pass:-}

echo "VERSÃO=$versao"
echo "-- MASTER --"
echo "MASTER HOSTNAME=$master_nome"
echo "MASTER IP=$master_ip"
echo "-- SLAVE --"
echo "SLAVE HOSTNAME=$slave_nome"
echo "SLAVE IP=$slave_ip"

echo "SE AS INFORMAÇÕES ESTAO CORRETAS, CONTINUE"
read -p "CONTINUAR? (S/N): " confirm && [[ $confirm == [sS] || $confirm == [sS][eE][sS] ]] || exit 1

clear

# Variaveis de arquivo
hba_conf="/var/lib/pgsql/$versao/data/pg_hba.conf"
psql_conf="/var/lib/pgsql/$versao/data/postgresql.conf"

# Configurano /etc/hosts
echo -e "$master_ip $master_nome" >> /etc/hosts
echo -e "$slave_ip $slave_nome" >> /etc/hosts


############### MASTER ###############

echo '- MASTER: BAIXANDO OS PACOTES NECESSÁRIOS'
dnf clean all && dnf -y install epel-release yum-utils sshpass && dnf -y install repmgr$versao* 
clear

echo '- MASTER: CONFIGURANDO O ARQUIVO postgresql.conf'
sed -i "s/#max_wal_senders = 10/max_wal_senders = 10/g" $psql_conf
sed -i "s/#max_replication_slots = 10/max_replication_slots = 10/g" $psql_conf
sed -i "s/#wal_level = replica/wal_level = replica/g" $psql_conf
sed -i "s/#hot_standby = on/hot_standby = on/g" $psql_conf
sed -i "s/#archive_mode = off/archive_mode = on/g" $psql_conf
sed -i "s/#archive_command = ''/archive_command = '\/bin\/true'/g" $psql_conf
sed -i "s/shared_preload_libraries = 'timescaledb'/shared_preload_libraries = 'timescaledb,repmgr'/g" $psql_conf

systemctl restart postgresql-13

echo '- MASTER: CRIANDO OS USUÁRIOS'
sudo -u postgres psql -c "create user repmgr with superuser;" > /dev/null 2>&1
sudo -u postgres psql -c "create database repmgr with owner repmgr;" > /dev/null 2>&1

echo '- MASTER: CONFIGURANDO O ARQUIVO pg_hba.conf'
echo -e "############## REPLICA ###############" >> $hba_conf
echo -e     "local   replication     repmgr                                     trust" >> $hba_conf
echo -e     "host    replication     repmgr        $master_ip/32            trust" >> $hba_conf
echo -e     "host    replication     repmgr        $slave_ip/32        trust" >> $hba_conf
echo -e "############## ACESSO AO BANCO ###############" >> $hba_conf
echo -e     "local   repmgr          repmgr                                  trust" >> $hba_conf
echo -e     "host    repmgr          repmgr          $master_ip/32            trust" >> $hba_conf
echo -e     "host    repmgr          repmgr          $slave_ip/32            trust" >> $hba_conf

echo '- MASTER: RECARREGANDO O HBA'
sudo -u postgres psql -c "SELECT pg_reload_conf();" > /dev/null 2>&1

echo '- MASTER: CONFIGURANDO O ARQUIVO repmgr.conf'
cat <<EOT >> $repmgr_conf
cluster='failovertest'
node_id=1
node_name=$master_nome
connection_check_type=connection
conninfo='host=$master_nome user=repmgr dbname=repmgr connect_timeout=2'
data_directory='/var/lib/pgsql/$versao/data/'
failover=automatic
promote_command='/usr/pgsql-$versao/bin/repmgr standby promote -f $repmgr_conf --log-to-file'
follow_command='/usr/pgsql-$versao/bin/repmgr standby follow -f $repmgr_conf --log-to-file --upstream-node-id=%n'
EOT
    
echo '- MASTER: Registrando o master'
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -f $repmgr_conf primary register > /dev/null 2>&1

echo '- MASTER: Status do cluster'
clear
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -f $repmgr_conf cluster show

############### SLAVE ###############
echo '- SLAVE: CONECTANDO AO SERVIDOR SLAVE'
sshpass -p $slave_pass ssh -o StrictHostKeyChecking=no -l root $slave_ip <<EOL
## CONFIGURANDO O /etc/hosts ##
echo -e "$master_ip $master_nome" >> /etc/hosts
echo -e "$slave_ip $slave_nome" >> /etc/hosts

echo '- SLAVE: BAIXANDO OS PACOTES NECESSÁRIOS'
dnf clean all  && dnf -y install epel-release yum-utils sshpass && dnf -y install repmgr$versao*
clear

echo 'SLAVE: CONFIGURANDO O ARQUIVO repmgr.conf'
echo -e "node_id=2" >> $repmgr_conf
echo -e "node_name=$slave_nome" >> $repmgr_conf
echo -e "onnection_check_type=connection" >> $repmgr_conf
echo -e "conninfo='host=$slave_nome user=repmgr dbname=repmgr connect_timeout=2'" >> $repmgr_conf
echo -e "data_directory='/var/lib/pgsql/$versao/data/'" >> $repmgr_conf
echo -e "failover=automatic" >> $repmgr_conf
echo -e "promote_command='/usr/pgsql-$versao/bin/repmgr standby promote -f $repmgr_conf  --log-to-file'" >> $repmgr_conf
echo -e "follow_command='/usr/pgsql-$versao/bin/repmgr standby follow -f $repmgr_conf --log-to-file --upstream-node-id=%n'" >> $repmgr_conf
    
echo 'SLAVE: TESTANDO AS CONFIGURAÇÕES DE CLONE'
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -h $master_nome -U repmgr -d repmgr --force -f $repmgr_conf standby clone --dry-run

echo 'SLAVE: INICIANDO A CLONAGEM'
systemctl stop postgresql-13
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -h $master_nome -U repmgr -d repmgr --force -f $repmgr_conf standby clone

echo 'SLAVE: REGISTANDO O SERVIDOR EM STANDBY'
systemctl start postgresql-13
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -f $repmgr_conf standby register

echo 'SLAVE: VERIFICANDO O STATUS DO CLUSTER'
clear
sudo -u postgres /usr/pgsql-$versao/bin/repmgr -f $repmgr_conf cluster show

echo 'SLAVE: HABILITANDO O FAILOVER AUTOMATICO'
sudo -u postgres /usr/pgsql-$versao/bin/repmgrd -f $repmgr_conf
EOL

echo 'MASTER: HABILITANDO O FAILOVER AUTOMATICO'
sudo -u postgres /usr/pgsql-$versao/bin/repmgrd -f $repmgr_conf

#!/bin/bash

# crontab -e
# 0 18 * * * /bd_local.sh
clear

#VARIAVEIS MYSQL
HOST=""          
USER=""                     
PASSWORD=""                  
DATABASE=""                  

#VARIAVEIS DO SCRIPT
LOCAL=/backup_zabbix/    								
DATA=`/bin/date +%a%d%m%Y`        
DATA2=`/bin/date +%a`             
NOME="$LOCAL/$DATABASE-$DATA.sql"        
NOME2="$LOCAL/$DATABASE-$DATA2.sql"        

   function diretoriobkp() {
   if [ -e $LOCAL ]; then
    echo -e "\e[31;40;1mDiretório de BKP ok...\e[m"
   else
    echo  -e "\e[31;40;1mCriando diretório ...\e[m"
    mkdir -p $LOCAL
   fi
   }
   
   function dumpdb() {
   if [ $DATA2 == 'Dom' ]; then
      echo -e "\e[31;40;1mFazendo o Backup de dados da tabela \e[m""\e[35;20;1m$DATABASE\e[m""\e[31;40;1m...\e[m"
      mysqldump -h $HOST -u $USER -p$PASSWORD $DATABASE | gzip -c9 > $NOME.gz
   else
      echo -e "\e[31;40;1mFazendo o Backup de dados da tabela \e[m""\e[35;20;1m$DATABASE\e[m""\e[31;40;1m...\e[m"
      mysqldump -h $HOST -u $USER -p$PASSWORD $DATABASE | gzip -c9 > $NOME2.gz
   fi
   }

main() {
  diretoriobkp
  dumpdb
}

main

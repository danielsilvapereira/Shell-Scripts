#!/bin/bash


###======== PRE REQUISITOS ========###
## yum install zip -y
## dar permisao para o script chmod +x caminho do script
## colocar no crontab da seguinte forma:     0 23 * * *  root bash caminhodoscript/backup_grafana

###======== RESTORE ========###
## cp grafana.db /var/lib/grafana/grafana.db
## unzip xxx
## chown grafana:grafana grafana.db


## Variaveis
GRAFANA_DIR="/var/lib/grafana/grafana.db"
BACKUP_DIR="/backups/grafana"
DIAS=7

## Criando o diretorio 
mkdir -p $BACKUP_DIR

#Realizando o backup
zip "$BACKUP_DIR/grafana-`date +%d-%m-%Y`.zip" $GRAFANA_DIR


####ROTAÇÃO####

# Backups diarios

# Deleta backups de 7 dias atrás
find $BACKUP_DIR* -maxdepth 1 -mtime +$DIAS -exec rm -rf {} \;

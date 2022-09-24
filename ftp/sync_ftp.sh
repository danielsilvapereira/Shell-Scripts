#!/bin/bash

#======== PRÉ REQUISITOS ========#
## yum install lftp

#======== UTILIZANDO ========#
##./sync_ftp.sh '/root/teste/' 'backups/teste/'

#======== AGENDANDO UMA VEZ POR DIA ========#
00 23 * * * root bash /root/sync_ftp.sh '/backups/grafana/' 'GRAFANA/'

# Variaveis
FTP_HOST=''
FTP_USER=''
FTP_PASS=''
ORIGEM=$1
DESTINO=$2
 
# Sincronizando
lftp -f "
open $FTP_HOST
user $FTP_USER $FTP_PASS
set ftp:ssl-allow false
lcd $ORIGEM
mirror --reverse --delete --verbose $ORIGEM $DESTINO
bye
"

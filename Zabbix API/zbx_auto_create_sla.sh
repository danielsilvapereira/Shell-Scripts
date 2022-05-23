#!/bin/bash

### FORMAT JSON ###
decodeDataFromJson(){
    echo `echo $1 \
            | sed 's/{\"data\"\:{//g' \
            | sed 's/\\\\\//\//g' \
            | sed 's/[{}]//g' \
            | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
            | sed 's/\"\:\"/\|/g' \
            | sed 's/[\,]/ /g' \
            | sed 's/\"// g' \
            | grep -w $2 \
            | awk -F "|" '{print $2}'`
}

### DADOS ZABBIX ###
URL='http://186.216.240.41/api_jsonrpc.php'
HEADER='Content-Type:application/json'
USER='"daniel"'
PASS='"gt1234"'

### DADOS DO HOST ###
CLIENTE=$1 
CONTRATO=$2

### GERANDO O TOKEN DE AUTENTICACAO ###
autenticacao()
{
        JSON='
        {
                "jsonrpc": "2.0",
                "method":"user.login",
                "params": {
                        "user": '$USER',
                        "password": '$PASS'
                },
                "id": 0
        }
        '

        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f8
}
TOKEN=$(autenticacao) 

### PEGAR ID HOST ###
HOSTID=$(
{
	JSON='
	{
			"jsonrpc": "2.0",
    	    "method": "host.get",
            "params": {
            "output": "hostids",
        	"filter": {
                "name": [
                    "'$CONTRATO' - '$CLIENTE'"
            ]
        }
    },
              
         "auth": "'$TOKEN'",
          "id": 1
        }
        '
        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f10
})

### PEGAR TRIGGER ID PARA O SLA ###
TRIGGERID=$(
{
	JSON='
	{
			"jsonrpc": "2.0",
    	    "method": "trigger.get",
            "params": {
				"hostids": "'$HOSTID'",
				"output": "triggerids"
	},
              
		  "auth": "'$TOKEN'",
          "id": 1
        }
        '
        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f10
})

### PEGAR SERVICE NAME ###
SERVICE=$(
{
	JSON='
	{
			"jsonrpc": "2.0",
    	    "method": "service.get",
            "params": {
        	"filter": {
                "name": [
                    "'$CLIENTE'"
            ]
        }
    },
              
         "auth": "'$TOKEN'",
          "id": 1
        }
        '
        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f14
})


### CRIANDO SLA ###
CRIARSLA()
{
	JSON='
	{
			"jsonrpc": "2.0",
    	    "method": "service.create",
            "params": {
				"name": "'$CLIENTE'",
				"parentid": "4683",
				"algorithm": 1,
				"showsla": 1,
				"goodsla": 92.00,
				"sortorder": 1,
				"triggerid": "'$TRIGGERID'"
	},
              
		  "auth": "'$TOKEN'",
          "id": 1
        }
        '
        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL" | cut -d '"' -f10
}

if [ $SERVICE ]; then  
	if [ $CLIENTE != $SERVICE ]; then 
		CRIARSLA
	fi

else 
	CRIARSLA
fi

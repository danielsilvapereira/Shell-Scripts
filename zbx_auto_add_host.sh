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
IP=$3
SERIAL=$4

### DADOS DO AUTENTICADOR ###
IPAUTH=172.31.255.1
CMM=Guaibatelec0m#!

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

### CRIANDO HOST ###
CRIARHOST()
{

        JSON='
        {
                "jsonrpc": "2.0",
                "method":  "host.create",
                "params": {
				"host": "'$CONTRATO' - '$CLIENTE'",
                        "interfaces": [
                           {
                                "type": 1,
								"main": 1,
								"useip": 1,
								"ip": "{$IP}",
								"dns": "",
								"port": "10050"
							},
							{ 
								"type": 2,
								"main": 1,
								"useip": 1,
								"ip": "'$IPAUTH'",
								"dns": "",
								"port": "161",
										 "details": {
												"version": 2,
												"bulk": 0,
												"community": "'$CMM'"
												}
							}
						],
			"groups": [
				{
					"groupid": "800"
				}
		 	],
			"templates": [
				{
					"templateid": "11073"
				}
			],
			"macros": [
				{
					"macro": "{$PPPOE}",
					"value": "'$CLIENTE'"
				},
				{
					"macro": "{$IP}",
					"value": "'$IP'"
				},
				{
					"macro": "{$SERIAL}",
					"value": "'$SERIAL'"
				}
			]
                },
                "auth": "'$TOKEN'",
                "id": 1
        }
        '
        curl -s -X POST -H "$HEADER" -d "$JSON" "$URL"

}
CRIARHOST

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

### ATUALIZAR MACROS ###
ATUALIZARMACROS()
{
	JSON='
	{
			"jsonrpc": "2.0",
			"method": "host.update",
			"params": {
				"hostid": "'$HOSTID'",
				"macros": [
					{
						"macro": "{$SERIAL}",
						"value": "'$SERIAL'"
					},
					{
					
						"macro": "{$PPPOE}",
						"value": "'$CLIENTE'"
					
					},
					{
						"macro": "{$IP}",
						"value": "'$IP'"
					}
				]
						},
						"auth": "'$TOKEN'",
						"id": 1
				}
				'
				curl -s -X POST -H "$HEADER" -d "$JSON" "$URL"

}
ATUALIZARMACROS

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

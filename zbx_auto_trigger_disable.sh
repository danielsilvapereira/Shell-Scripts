from zabbix_api import ZabbixAPI
import json
from crontab import CronTab
from datetime import timedelta,date


### VARIAVEIS DE ACESSO ###
zbx_server = "http://186.216.240.41/zabbix"
user = "daniel"
password = "gt1234"
data_10 = date.today() + timedelta(days=10)


### AUTH ####
zapi = ZabbixAPI(server=zbx_server)
zapi.login(user, password)

### ID DA TRIGGERS COM EVENTOS PROBLEM ####
triggers = zapi.problem.get({
            'output': 'extend',
            'selectTags': ['tag','value'],
            'tags': [{'tag': 'INFO TRIGGER TRAFFIC', 'value': ''}],
            'filter':{'value':1}
            })
### FORMATANDO A SAIDA DE JSON PARA VALUE ###
id = []
for dict in triggers:
    id.append(dict['objectid'])

### LAÇO PARA DESABILITAR AS TRIGGERS ###

for ids in id:
    zapi.trigger.update({
    'triggerid': f'{ids}',
    'status': 1
    })

print(data_10)




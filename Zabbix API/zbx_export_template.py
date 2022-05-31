#!/usr/bin/env python3

import os
from pyzabbix import ZabbixAPI

#Zabbix
server = 'http://192.168.1.203'
user = 'Admin'
password = 'zabbix'

#Linux
path = '/root/zabbix_templates/'

#Git
git_email = ''
git_user = ''
git_repo = ''
git_token = ''

#Configurando o git
os.system(f"git config --global user.email {git_email}")
os.system(f"git config --global user.name {git_user}")
os.system(f"git config --global credential.helper store {git_token}")
os.system(f"cd {path} && git init")

#Configurando git remoto
os.system(git branch -m master main)
os.system(f"cd {path} && git remote add zbx_templates {git_repo}")
os.system(f"cd {path} && git pull zbx_templates main --allow-unrelated-histories")

#Conectando na api do zabbix
zapi = ZabbixAPI(server)
zapi.login(user, password)

#Buscando template
templates = zapi.template.get(
    output=["name", "id"],
    selectGroups=["name"]
)

#Laço para para cada tempalte encontrado
for template in templates:
    template_nome = template['name']
    template_id = int(template['templateid'])

    #Configuração do template em xml
    config = zapi.configuration.export(
        format='xml',
        options={"templates": [template_id]},
    )
    #Laço para cada grupo encontrado
    for grupo in template['groups']:
        #Retirando nome template do grupo
        grupo_nome = grupo['name'].replace('Templates/', "")
        #Criando a pasta com nome do grupo
        os.system(f"mkdir -p {path}'{grupo_nome}'")
        #Criando o template com nome
        os.system(f"touch {path}'{grupo_nome}'/'{template_nome}.xml'")
        #Enviando a config para dentro do arquivo do template
        os.system(f"echo '{config}' > {path}'{grupo_nome}'/'{template_nome}.xml'")


#Atualizando repositorio do github
os.system(f"cd {path} && git add .")
os.system(f"cd {path} && git commit -m 'Zabbix Template Import by'")
os.system(f"cd {path} && git push zbx_templates main")

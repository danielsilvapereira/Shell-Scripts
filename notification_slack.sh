#!/bin/bash

# Slack incoming web-hook URL and user name
url='https://hooks.slack.com/services/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'
username='Zabbix'

# Get the user/channel ($1), subject ($2), and message ($3)
to="$1"
subject="$2"
message="$3"

# Change message emoji and notification color depending on the subject indicating whether it is a trigger $
recoversub='^Resolvido'
problemsub='^Incidente'

if [[ "$subject" =~ $recoversub ]]; then
    emoji=':white_check_mark:'
    color='#0C7BDC'
elif [[ "$subject" =~ $problemsub ]]; then
    emoji=':warning:'
    color='#FFC20A'
else
    emoji=':question:'
    color='#CCCCCC'
fi

# Replace the above hard-coded Slack.com web-hook URL entirely, if one was passed via the optional 4th parameter
url=${4-$url}

# Use optional 5th parameter as proxy server for curl
proxy=${5-""}
if [[ "$proxy" != '' ]]; then
    proxy="-x $proxy"
fi

# Build JSON payload which will be HTTP POST'ed to the Slack.com web-hook URL
payload="payload={\"channel\": \"${to//\"/\\\"}\",  \
\"username\": \"${username//\"/\\\"}\", \
\"attachments\": [{\"fallback\": \"${subject//\"/\\\"}\", \"title\": \"${subject//\"/\\\"}\", \"text\": \"${message//\"/\\\"}\", \"color\": \"${color}\"}], \
\"icon_emoji\": \"${emoji}\"}"

# Execute the HTTP POST request of the payload to Slack via curl, storing stdout (the response body)
return=$(curl $proxy -sm 5 --data-urlencode "${payload}" $url -A 'zabbix-slack-alertscript / https://github.com/ericoc/zabbix-slack-alertscript')

# If the response body was not what was expected from Slack ("ok"), something went wrong so print the Slack error to stderr and exit with non-zero
if [[ "$return" != 'ok' ]]; then
    >&2 echo "$return"
    exit 1
fi


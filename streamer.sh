#! /bin/sh
# T-Mobile TV GO / Magio GO
# v0.2
# Autor: koperfield
# Streamer

# Uživatelské parametry si nastavte při prvním spuštení skriptu login.sh nebo s parametrem --config.

current_location=$(dirname $0)
if [ ! -f "${current_location}/config.file" ] ; then printf "ERROR: Config file not found. Please run login.sh.\n" ; exit 1 ; fi
file=$(cat ${current_location}/config.file | head -n 1 )
service=$(echo ${file} | cut -d ' ' -f1)
quality=$(echo ${file} | cut -d ' ' -f4)
data=$(echo ${file} | cut -d ' ' -f6)
provider=$(echo ${file} | cut -d ' ' -f7)
if [ ! -f "${current_location}/access.token" ] ; then printf "ERROR: Access token not found. Please run login.sh.\n" ; exit 1 ; fi
access_token=$(cat ${current_location}/access.token | head -n 1 )
token=$(echo ${access_token} | cut -d ' ' -f1)
refresh=$(echo ${access_token} | cut -d ' ' -f2)

id=$1

channel=$(curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "https://${service}.magio.tv/v2/television/stream-url?service=LIVE&name=Netscape&devtype=OTT_ANDROID&id=${id}&prof=${quality}&ecid=&drm=verimatrix")
if [ $? != 0 ] || [ $(echo ${channel} | jq -r ".success") != "true" ] ; then exit 1 ; fi
channel=$(echo ${channel} | jq -r ".url")

${data}ffmpeg -fflags +genpts -i ${channel} -vcodec copy -acodec copy -f mpegts -mpegts_service_type digital_tv -metadata service_provider=${provider} -metadata service_name=${service} pipe:1

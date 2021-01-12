#! /bin/sh
# Získání playlistu

current_location=$(dirname $0)

${current_location}/login.sh --silent
if [ $? != 0 ] ; then echo "Login error"; exit 1; fi

if [ ! -f "${current_location}/config.file" ] ; then printf "ERROR: Config file not found. Please run login.sh.\n" ; exit 1 ; fi
file=$(cat ${current_location}/config.file | head -n 1 )
service=$(echo ${file} | cut -d ' ' -f1)
script=$(echo ${file} | cut -d ' ' -f5)

if [ ! -f "${current_location}/access.token" ] ; then printf "ERROR: Access token not found. Please run login.sh.\n" ; exit 1 ; fi
access_token=$(cat ${current_location}/access.token | head -n 1 )
token=$(echo ${access_token} | cut -d ' ' -f1)
refresh=$(echo ${access_token} | cut -d ' ' -f2)

playlist=${current_location}/playlist.general.m3u8
streamer=${script}streamer.sh

PREFIX=#EXTM3U
PREFIX1ST=#EXTINF:-1
PREFIX2ND=pipe://${streamer}

channels=$(curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "https://${service}.magio.tv/v2/television/channels?list=LIVE")
if [ $? != 0 ] ; then printf "ERROR: Unsuccessful channel list request.\n" ; exit 1 ; fi
channels=$(echo ${channels} | tr '\r\n' ' ')
channels_success=$(echo ${channels} | jq -r '.success')
if [ $channels_success != "true" ] ; then
	channels_error=$(echo ${channels} | jq -r '.errorMessage')
	echo "ERROR: Server responded: ${error}"
	exit 1
fi

channels=$(echo ${channels} | tr '\r\n' ' ')
max=$(echo ${channels} | jq -r ".items" | jq -r ".|length")
items=$(echo ${channels} | jq -r ".items")

i=0
printf "${PREFIX}\n" > ${playlist}
while [ $i -lt $max ] ; do
	channel=$(echo ${items} | jq -r ".[${i}].channel")
	id=$(echo ${channel} | jq -r ".channelId")
	name=$(echo ${channel} | jq -r ".name" | sed -f ${current_location}/encode.sed)
	logo=$(echo ${channel} | jq -r ".logoUrl")
	channel_num=$(echo ${channel} | jq -r ".defaultChannelPosition")
	printf "${PREFIX1ST} tvg-logo='%s' tvh-chnum='%s' tvg-id='%s',%s\n" "${logo}" "${channel_num}" "${id}.${service}.magio.tv" "${name}" >> ${playlist}
	printf "${PREFIX2ND} %s '%s'\n" "${id}" "${name}" >> ${playlist}
	i=$((i + 1))
	printf "Generated %s channels.\r" $i
done
printf "\nPlaylist done\n"
printf "Saved into %s.\n" "${playlist}"

exit_code=0
chmod +x ${streamer}
if [ $? != 0 ] ; then printf "WARNING: Bad ${streamer} executable setting\n" ; exit_code=2 ; else printf "File ${streamer} set as executable\n" ; fi

printf "OK\n"

exit ${exit_code}

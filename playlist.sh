#! /bin/sh
# T-Mobile TV GO
# v0.1
# Autor: koperfield
# Získání playlistu

# Uživatelské parametry
# Absolutní cesta k adresáři služby ve tvaru /.../
data=
# Konec zadáni uživatelských parametrů

playlist=${data}playlist.general.m3u8
streamer=${data}streamer.sh

PREFIX=#EXTM3U
PREFIX1ST=#EXTINF:-1,
PREFIX2ND=pipe://${streamer}

access_token=$(cat ${data}access.token | head -n 1 )
token=$(echo ${access_token} | cut -d ' ' -f1)
refresh=$(echo ${access_token} | cut -d ' ' -f2)

channels=$(wget -qO - --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "https://czgo.magio.tv/v2/television/channels?list=LIVE")
if [ $? != 0 ] ; then printf "ERROR: Unsuccessful getting of channel list\n" ; exit 1 ; fi
channels=$(echo ${channels} | tr '\r\n' ' ')
max=$(echo ${channels} | jq -r ".items" | jq -r ".|length")
items=$(echo ${channels} | jq -r ".items")

i=0
printf "${PREFIX}\n" > ${playlist}
while [ $i -lt $max ] ; do
	channel=$(echo ${items} | jq -r ".[${i}].channel")
	id=$(echo ${channel} | jq -r ".channelId")
	name=$(echo ${channel} | jq -r ".name")
	printf "${PREFIX1ST}%s\n" "${name}" >> ${playlist}
	printf "${PREFIX2ND} %s\n" "${id}" >> ${playlist}
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
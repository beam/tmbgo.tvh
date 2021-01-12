#! /bin/sh
# T-Mobile TV GO
# v0.1
# Autor: koperfield
# Streamer

# Uživatelské parametry
# Identifikace poskytovatele služby, které se přense do Kodi jako "Poskytovatel" - zobrazí se v OSD PVR
provider=
# Absolutní cesta k adresáři služby ve tvaru /.../
data=
# Absolutní cesta k adresáři s ffmpeg /.../ nebo prázdné (prog=)
prog=
# Konec zadávání uživatelských parametrů

id=$1

access_token=$(cat ${data}access.token | head -n 1 )
token=$(echo ${access_token} | cut -d ' ' -f1)
refresh=$(echo ${access_token} | cut -d ' ' -f2)

channel=$(wget -qO - --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "https://czgo.magio.tv/v2/television/stream-url?service=LIVE&name=Netscape&devtype=OTT_ANDROID&id=${id}&prof=p0&ecid=&drm=verimatrix")
if [ $? != 0 ] ; then exit 1 ; fi
channel=$(echo ${channel} | jq -r ".url")

${prog}ffmpeg -fflags +genpts -i ${channel} -vcodec copy -acodec copy -f mpegts -mpegts_service_type digital_tv -metadata service_provider=${provider} -metadata service_name=${service} pipe:1
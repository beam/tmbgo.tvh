#! /bin/sh
# Přihlášení

# Uživatelské parametry si nastavte při prvním spuštení skriptu nebo s parametrem --config.

current_location=$(dirname $0)

if [ "$1" = "--silent" ]; then silent_login_if_expired=true; fi

if [ ! -f "${current_location}/config.file" ] || [ "$1" = "--config" ] ; then
    . ${current_location}/config.sh
else
    file=$(cat ${current_location}/config.file | head -n 1 )
    service=$(echo ${file} | cut -d ' ' -f1)
    username=$(echo ${file} | cut -d ' ' -f2 | sed 's/__\+/ /g')
    password=$(echo ${file} | cut -d ' ' -f3)
    quality=$(echo ${file} | cut -d ' ' -f4)
    script=$(echo ${file} | cut -d ' ' -f5)
    data=$(echo ${file} | cut -d ' ' -f6)
    provider=$(echo ${file} | cut -d ' ' -f7)
fi

if [ -f "${current_location}/access.token" ] ; then
    access_token=$(cat ${current_location}/access.token | head -n 1 )
    token=$(echo ${access_token} | cut -d ' ' -f1)
    refresh=$(echo ${access_token} | cut -d ' ' -f2)
    expiry=$(echo ${access_token} | cut -d ' ' -f3)
    current_time=$(date +%s%N | cut -b1-13)
else 
    refresh="login"
fi

if [ "${silent_login_if_expired}" = true ] && [ "${expiry}" ] ; then
    if [ "${current_time}" -lt "${expiry}" ] ; then exit 0; fi
fi

refresh_data={\"refreshToken\":\"${refresh}\"}
refresh_request=$(curl -s --header "Content-Type: application/json" -d "${refresh_data}" "https://${service}.magio.tv/v2/auth/tokens")
if [ $? != 0 ] || [ $(echo ${refresh_request} | jq -r ".success") != "true" ] ; then 
    if [ refresh != "login" ] ; then printf "ERROR: Bad refresh token authorization, trying to login\n" ; fi
    logindata={\"loginOrNickname\":\"${username}\",\"password\":\"${password}\"}
    bearer=$(curl -s --header "Content-Type: application/json" -d "" "https://${service}.magio.tv/v2/auth/init?dsid=Netscape&deviceName=Netscape&deviceType=OTT_LINUX&osVersion=0.0.0&appVersion=0.0.0&language=EN")
    bearer=$(echo ${bearer} | jq -r ".token.accessToken")
    login=$(curl -s --header "Content-Type: application/json" --header "Authorization: Bearer ${bearer}" -d "${logindata}" "https://${service}.magio.tv/v2/auth/login")
    loginsuccess=$(echo ${login} | jq -r ".success")

    if [ ${loginsuccess} != true ] ; then
        error=$(echo ${login} | jq -r ".errorMessage")
        echo "ERROR: Server responded: ${error}"
        exit 1
    fi

    token=$(echo ${login} | jq -r ".token.accessToken")
    expiry=$(echo ${login} | jq -r ".token.expiresIn")
    refresh=$(echo ${login} | jq -r ".token.refreshToken")

    printf "%s %s %s" "${token}" "${refresh}" "${expiry}" > "${current_location}/access.token"
    if [ $? != 0 ] ; then printf "ERROR: Unsuccessful write into ${current_location}/access.token\n" ; exit 1 ; fi
    if [ "${silent_login_if_expired}" != true ] ; then echo "Access token and refresh token saved!"; fi
    exit 0
else
    token=$(echo ${refresh_request} | jq -r ".token.accessToken")
    expiry=$(echo ${refresh_request} | jq -r ".token.expiresIn")
    refresh=$(echo ${refresh_request} | jq -r ".token.refreshToken")
    printf "%s %s %s" "${token}" "${refresh}" "${expiry}" > "${current_location}/access.token"
    if [ $? != 0 ] ; then printf "ERROR: Unsuccessful write into ${current_location}/access.token\n" ; exit 1 ; fi
    if [ "${silent_login_if_expired}" != true ] ; then echo "Access token and refresh token saved!"; fi
    exit 0
fi

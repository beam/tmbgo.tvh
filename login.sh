#! /bin/sh
# T-Mobile TV GO / Magio GO
# v0.2
# Autor: koperfield
# Přihlášení

# Uživatelské parametry si nastavte při prvním spuštení skriptu nebo s parametrem --config.

current_location=$(dirname $0)
if [ ! -f "${current_location}/config.file" ] || [ "$1" = "--config" ] ; then
    [ ! -f "${current_location}/config.file" ] && echo "ERROR: Config file not found. Starting configuration..\n"
    echo "Choose a service:"
    echo "1) T-Mobile TV GO (CZ)"
    echo "2) Magio GO (SK)"
    while true; do
    read -p "Enter number of service or 3 to stop the script: " service
    case $service in
        1) service="czgo"
            break;;
        2) service="skgo"
            break;;
        3) exit;;
        *) echo "ERROR: Invalid input." ;;
    esac
    done

    read -p "Enter username: " username
    username=$(echo ${username} | sed 's/ \+/__/g')
    read -p "Enter password: " password
    echo "\nChoose streaming quality:"
    echo "1) p0 - adaptive (up to 1280x720p, 25fps)"
    echo "2) p1 - lowest"
    echo "3) p2"
    echo "4) p3"
    echo "5) p4"
    echo "6) p5 - highest available (up to 1920x1080, 50fps)"
    while true; do
    read -p "Enter number of quality: " quality
    case $quality in
        1) quality="p0"
            break;;
        2) quality="p1"
            break;;
        3) quality="p2"
            break;;
        4) quality="p3"
            break;;
        5) quality="p4"
            break;;
        6) quality="p5"
            break;;
        *) echo "ERROR: Invalid input." ;;
    esac
    done

    read -p "Enter the absolute location of this script directory (required for playlist generation, format  /.../): " script
    read -p "Enter the absolute location of ffmpeg directory (format /.../ or leave it blank): " data
    read -p "Enter provider name (for Kodi): " provider
    printf "%s %s %s %s %s %s %s" ${service} ${username} ${password} ${quality} ${script} ${data} ${provider} > ${current_location}/config.file
    echo "All done! Configuration file is saved."
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
else refresh="login" ; fi

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
echo "Access token and refresh token saved!"
exit 0
else
token=$(echo ${refresh_request} | jq -r ".token.accessToken")
expiry=$(echo ${refresh_request} | jq -r ".token.expiresIn")
refresh=$(echo ${refresh_request} | jq -r ".token.refreshToken")
printf "%s %s %s" "${token}" "${refresh}" "${expiry}" > "${current_location}/access.token"
if [ $? != 0 ] ; then printf "ERROR: Unsuccessful write into ${current_location}/access.token\n" ; exit 1 ; fi
echo "Access token and refresh token saved!"
exit 0
fi

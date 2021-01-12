#! /bin/sh
# T-Mobile TV GO
# v0.1
# Autor: koperfield
# Přihlášení

# Uživatelské parametry
# Přihlašovací jméno do služby
username=
# Přihlašovací heslo do služby
password=
# Absolutní cesta k adresáři služby ve tvaru /.../
data=
# Konec zadávání uživ. parametrů

logindata='{"loginOrNickname":"'"${username}"'","password":"'"${password}"'"}'
bearer=$(wget -qO - --header "Content-Type: application/json" --post-data "" "https://czgo.magio.tv/v2/auth/init?dsid=Netscape&deviceName=Netscape&deviceType=OTT_LINUX&osVersion=0.0.0&appVersion=0.0.0&language=EN")
bearer=$(echo ${bearer} | jq -r ".token.accessToken")
login=$(wget -qO - --header "Content-Type: application/json" --header "Authorization: Bearer ${bearer}" --post-data "${logindata}" "https://czgo.magio.tv/v2/auth/login")
loginsuccess=$(echo ${login} | jq -r ".success")
if [ ${loginsuccess} != true ] ; then
error=$(echo ${login} | jq -r ".errorMessage")
echo "Error: ${error}"
exit 1
fi
token=$(echo ${login} | jq -r ".token.accessToken")
expiry=$(echo ${login} | jq -r ".token.expiresIn")
refresh=$(echo ${login} | jq -r ".token.refreshToken")
echo "accessToken: ${token}"
echo "refreshToken: ${refresh}"
echo "expiresIn: ${expiry}"

printf "%s %s %s" "${token}" "${refresh}" "${expiry}" > "${data}access.token"
if [ $? != 0 ] ; then printf "ERROR: Unsuccessful write into ${data}access.token\n" ; exit 1 ; fi
echo "All saved!"
exit 0


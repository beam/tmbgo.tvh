#! /bin/sh
# Konfigurace

current_location=$(dirname $0)

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

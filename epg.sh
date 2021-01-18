#!/bin/sh

epg_days=3
current_location=$(dirname $0)
epg_json_file=${current_location}/fetched_schedule.json
xmltv_file=${current_location}/epg.xmltv
final_dest="~/.xmltv/tv_grab_file.xmltv"

${current_location}/login.sh --silent
if [ $? != 0 ] ; then echo "Login error"; exit 1; fi

if [ ! -f "${current_location}/config.file" ] ; then printf "ERROR: Config file not found. Please run login.sh.\n" ; exit 1 ; fi
file=$(cat ${current_location}/config.file | head -n 1 )
service=$(echo ${file} | cut -d ' ' -f1)

if [ ! -f "${current_location}/access.token" ] ; then printf "ERROR: Access token not found. Please run login.sh.\n" ; exit 1 ; fi
access_token=$(cat ${current_location}/access.token | head -n 1 )
token=$(echo ${access_token} | cut -d ' ' -f1)
refresh=$(echo ${access_token} | cut -d ' ' -f2)

printf "Starting fetching EPG\n"
echo -n > ${epg_json_file}

for day in $(seq 0 ${epg_days}); do

  limit=20
  offset=0
  item_count=${limit}

  start_time=$(date --date "${day} days" +"%Y-%m-%dT00:00:00.000Z")
  end_time=$(date --date "$((${day}+1)) days" +"%Y-%m-%dT01:00:00.000Z")
  printf "\rDownloading day: %s " $(date --date "${day} days" +"%Y-%m-%d")

  filter="startTime=ge=${start_time};startTime=le=${end_time}"
  while [ "${item_count}" -eq "${limit}" ] ; do
    echo -n "."
    epg=$(curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "https://${service}.magio.tv/v2/television/epg?limit=${limit}&offset=$(($limit * $offset))&list=LIVE&filter=${filter}")
    epg=$(echo ${epg} | sed ':a;N;$!ba;s/\n/ /g' | sed -E 's/[\\]+([A-Za-z]){1}/ \1/g')
    epg_success=$(echo ${epg} | jq -r '.success')
    if [ "${epg_success}" != "true" ] ; then
      epg_error=$(echo ${epg} | jq -r '.errorMessage,.developerMessage')
      echo ${epg} > ${current_location}/failed.json
      echo "EPG reading failed ${epg_error}"
      exit 1
    fi
    item_count=$(echo ${epg} | jq -r .items | jq length)
    echo ${epg} >> ${epg_json_file}
    offset=$(($offset + 1))
  done
done

printf "\nDownloading finished\n"

echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > ${xmltv_file}
echo '<tv>' >> ${xmltv_file}

echo "Preparing EPG channels."
channels=$(cat ${epg_json_file} | jq -r '.items[].channel' | jq -s '.' | jq -M '.|= unique_by(.channelId)')
channels_count=$(echo ${channels} | jq length)

echo "Writing channels."
i=0
while [ "${i}" -lt "${channels_count}" ] ; do
  channel=$(echo ${channels} | jq -r ".[${i}]")
  channel_id=$(echo $channel | jq -r '.channelId')
  channel_id_full="ch${channel_id}.${service}.magio.tv"
  channel_name=$(echo ${channel} | jq -r ".name" | sed -f ${current_location}/encode.sed | sed -f htmlencode.sed )
  echo "<channel id=\"${channel_id_full}\">" >> ${xmltv_file}
  echo "  <display-name>${channel_name}</display-name>" >> ${xmltv_file}
  echo "</channel>" >> ${xmltv_file}
  i=$(($i + 1))
  printf "CH: %s/%s\r" $i $channels_count
done

echo 'Channels done.'
echo 'Preparing EPG schedules.'

schedules=$(cat ${epg_json_file} | jq -r '.items[].programs[]' | jq -s '.' | jq -M '.|= unique_by(.scheduleId)')
schedules_count=$(echo ${schedules} | jq length)
schedules=$(echo $schedules | jq -c '.[]')

echo "Writing ${schedules_count} schedules."

i=0
IFS=
echo $schedules | while read -r schedule; do
  if ! [ -n "$process_start_time" ]; then process_start_time=$(date +%s); fi
  channel_id=$(echo $schedule | jq -r '.channel.id')
  channel_id_full="ch${channel_id}.${service}.magio.tv"
  start_time=$(date --date "@$(($(echo $schedule | jq -r '.startTimeUTC') / 1000))" +"%Y%m%d%H%M%S %z" )
  end_time=$(date --date "@$(($(echo $schedule | jq -r '.endTimeUTC') / 1000))" +"%Y%m%d%H%M%S %z" )
  
  title=$(echo $schedule | jq -r '.program.title' | sed -f htmlencode.sed )
  description=$(echo $schedule | jq -r '.program.description' | sed -f htmlencode.sed )
  episodetitle=$(echo $schedule | jq -r '.program.episodeTitle' | sed -f htmlencode.sed )
  creationyear=$(echo $schedule | jq -r '.program.programValue.creationYear' | sed -f htmlencode.sed )

  categories=$(echo $schedule | jq '.program.programCategory' | jq -r '[.desc , try .subCategories[].desc] | map("\(.)") | .[]' | sed -f htmlencode.sed )

  echo "<programme channel=\"${channel_id_full}\" start=\"${start_time}\" stop=\"${end_time}\">" >> ${xmltv_file}
  echo "  <title>${title}</title>" >> ${xmltv_file}
  echo "  <desc>${description}</desc>" >> ${xmltv_file}
  if [ $episodetitle != "null" ] ; then  echo "  <sub-title>${episodetitle}</sub-title>" >> ${xmltv_file}; fi
  if [ $creationyear != "null" ] ; then  echo "  <date>${creationyear}</date>" >> ${xmltv_file}; fi

  echo $categories | while read -r category; do
    echo "  <category>${category}</category>" >> ${xmltv_file}
  done
  
  echo "</programme>" >> ${xmltv_file}

  i=$(($i + 1))

  if [ $i -lt 5 ] || [ `echo "$i % 50" | bc` -eq 0 ]; then
    current_time=$(date +%s)
    item_seconds_cost=$(echo "scale=3; (($current_time - $process_start_time) / $i)" | bc)
    seconds_left=$(echo "($schedules_count - $i) * $item_seconds_cost" | bc)
    eta_end=$(date +"%d.%m.%Y %H:%M" --date "+${seconds_left} seconds")
  fi

  printf "SCH: %s/%s | ETA %s ~ %.3g s/item\r" $i $schedules_count $eta_end ${item_seconds_cost}
done
echo '</tv>' >> ${xmltv_file}

echo "\nXMLTV xml done!"

echo "Creating ${final_dest}"
cp ${xmltv_file} ${final_dest}

echo "Finished"
#!/bin/bash
chown $PUID:$PGID /config;
chown $PUID:$PGID /Blackhole;


# Create Transcode folder if not exist
if [[ ! -d "/Blackhole/Transcode" ]]
then
    mkdir "/Blackhole/Transcode";
fi
chown $PUID:$PGID /Blackhole/Transcode;


# Create $ArrFolder folder if not exist (Sonarr or Radarr)
if [[ ! -d "/Blackhole/$ArrFolder" ]]
then
    mkdir "/Blackhole/$ArrFolder";
fi
chown $PUID:$PGID /Blackhole/$ArrFolder;


# Create Transcodarr folder in Config if not exist
if [[ ! -d "/config/Transcodarr" ]]
then
    mkdir "/config/Transcodarr";
fi
chown $PUID:$PGID /config/Transcodarr;

# Create file for script
touch "/config/Transcodarr/fail.txt";
touch "/config/Transcodarr/database.txt";
touch "/config/Transcodarr/waiting.txt";
chown $PUID:$PGID /config/Transcodarr/fail.txt;
chown $PUID:$PGID /config/Transcodarr/database.txt;
chown $PUID:$PGID /config/Transcodarr/waiting.txt;



# create script in Config folder if sonarr is your transcode
if [[ $ArrType = Sonarr ]];
then
echo '#!/bin/bash
if [ \${sonarr_eventtype} = "Test" ]; then
  >&2 echo "[Debug] Testing script";
  exit;
fi
echo "\$sonarr_episodefile_path" >> /config/Transcodarr/waiting.txt' > /config/Transcodarr/addtodbscript.sh;  
fi


# create script in Config folder if radarr is your transcode
if [[ $ArrType = Radarr ]];
then
echo '#!/bin/bash
if [ \${radarr_eventtype} = "Test" ]; then
  >&2 echo "[Debug] Testing script";
  exit;
fi
echo "\${radarr_moviefile_path}" >> /config/Transcodarr/waiting.txt' > /config/Transcodarr/addtodbscript.sh;
fi

chown $PUID:$PGID /config/Transcodarr/addtodbscript.sh;
chmod 777 /config/Transcodarr/addtodbscript.sh;


# End of setup
# Script start here

echo "Transcodarr Start";

IFS=$'\n';
transcodarrdb="/config/Transcodarr/database.txt";
blackholefolder="/Blackhole/$ArrFolder/";
waitingdb="/config/Transcodarr/waiting.txt";
transcodefolder="/Blackhole/Transcode/";
cpucore="$Process";

findFilesToScan (){
  cat $waitingdb >> $transcodarrdb;
  cat /dev/null > $waitingdb
}

transcode (){
  local start=$1;
  local end=$2;
  for file in $(sed -n "$start,${end}p" $transcodarrdb)
  do
      if [[ $(ffprobe -hide_banner -loglevel error -select_streams a -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" | grep -vw 'ac3\|aac') ]];
      then
          ext=$(echo "$file" | rev | cut -d "." -f 1 | rev);
          filename=$(echo "$file" | rev | cut -d "/" -f 1 | cut -c 5- | rev);
          if [[ $(ffmpeg -i "$file" -map 0 -acodec aac -metadata:s:a title= -vcodec copy -scodec srt "$transcodefolder$filename transcodenow.mkv" 2>&1 | grep 'Subtitle encoding') == *"Subtitle encoding"* ]]
          then
            rm "$transcodefolder$filename transcodenow.mkv";
            ffmpeg -i "$file" -map 0 -acodec aac -metadata:s:a title= -vcodec copy -scodec copy "$transcodefolder$filename transcodenow.mkv";
          fi
          if [[ $(du -k "$transcodefolder$filename transcodenow.mkv" | cut -d$'\t' -f 1) < 1000 ]]
          then
              echo "[WARNING] Transcode failed, take another file";
              echo "file deleted "$transcodefolder$filename transcodenow.mkv"";
              rm "$transcodefolder$filename transcodenow.mkv";
          else
              rm "$file";
              chown $PUID:$PGID "$transcodefolder$filename transcodenow.mkv";
              mv "$transcodefolder$filename transcodenow.mkv" "$blackholefolder$filename updated.mkv";
              echo "Transcode completed";
              echo "$filename updated.mkv" sent to "$blackholefolder";
          fi
      else
      if [[ $(ffprobe -v error -select_streams s -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$file" | grep -v 'subrip\|pgs') ]];
      then
          ext=$(echo "$file" | rev | cut -d "." -f 1 | rev);
          filename=$(echo "$file" | rev | cut -d "/" -f 1 | cut -c 5- | rev);
          if [[ $(ffmpeg -i "$file" -map 0 -acodec copy -metadata:s:a title= -vcodec copy -scodec srt "$transcodefolder$filename transcodenow.mkv" 2>&1 | grep 'Subtitle encoding') == *"Subtitle encoding"* ]]
          then
            rm "$transcodefolder$filename transcodenow.mkv";
          fi
          if [[ $(du -k "$transcodefolder$filename transcodenow.mkv" | cut -d$'\t' -f 1) < 1000 ]]
          then
              echo "[WARNING] Transcode failed, take another file";
              echo "file deleted "$transcodefolder$filename transcodenow.mkv"";
              rm "$transcodefolder$filename transcodenow.mkv";
          else
              rm "$file";
              chown $PUID:$PGID "$transcodefolder$filename transcodenow.mkv";
              mv "$transcodefolder$filename transcodenow.mkv" "$blackholefolder$filename updated.mkv";
              echo "Transcode completed";
              echo "$filename updated.mkv" sent to "$blackholefolder";
          fi
      fi
      fi
  done
}



while true;
do
  findFilesToScan;
  sleep 120;
  threads=$cpucore;
  nbLines=$(cat $transcodarrdb | wc -l);
  offset=$(($(($nbLines / $threads)) + 1));
  for loop in $( seq 0 $(($threads - 1)) )
  do
    transcode $((loop * $offset + 1)) $(( $((loop + 1)) * $offset)) $loop &
  done
  wait;
  cat /dev/null > $transcodarrdb
done

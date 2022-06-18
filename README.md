![Logo](https://user-images.githubusercontent.com/17613028/174446467-c7370958-0902-4b80-9496-cabc5505e7ed.svg)
---

Transcodarr is a container build for radarr and sonarr to allows you to transcode only sound into AAC if is not AAC or AC3.


Build Image :

```
git clone https://github.com/TheNexter/Transcodarr
cd Transcodarr
sudo chown root:root transcodarr.sh && sudo chmod 777 transcodarr.sh
docker build -t transcodarr .
```

Installation :

Step 1: Launch Transcodarr with one of the following commands

```
  transcodarr-radarr:
    image: transcodarr
    container_name: transcodarr-radarr
    environment:
      - ArrType=Radarr #or Sonarr
      - ArrFolder=Radarr #name of the folder inside /Blackhole, if you have multiple radarr (Radarr4K, Radarr1080P), you need to run this container two time and each container gonna need different ArrFolder.
      - PUID=1000
      - PGID=1000
      - Process=1 #how many transcode aac in same time you wan't ? ffmpeg use 1 core for one transcode
      - TZ=Europe/London
    volumes:
      - /path/to/config/Radarr:/config #you need to put the same config path have radarr
      - /path/to/movies:/Fichier #you need to put the same path have radarr for your movies
      - /path/to/Blackhole:/Blackhole #this path needs to be available in radarr
    restart: unless-stopped

  transcodarr-sonarr:
    image: transcodarr
    container_name: transcodarr-sonarr
    environment:
      - ArrType=Sonarr #or Radarr
      - ArrFolder=Sonarr #name of the folder inside /Blackhole, if you have multiple sonarr (Sonarr4K, Sonarr1080P...) you need to run this container two time and each container gonna need different ArrFolder.
      - PUID=1000
      - PGID=1000
      - Process=1 #how many transcode aac in same time you wan't ? ffmpeg use 1 core for one transcode
      - TZ=Europe/London
    volumes:
      - /path/to/config/Sonarr:/config #you need to put the same config path have sonarr
      - /path/to/series:/Fichier #you need to put the same path have sonarr for your series
      - /path/to/Blackhole:/Blackhole #this path needs to be available in sonarr
    restart: unless-stopped
```

Step 2: Open Radarr or Sonarr

Step 3: Add a blackhole download client

<img width="400" alt="image" src="https://user-images.githubusercontent.com/17613028/174446983-955eae79-e9cf-4569-b90e-ee96a7c47917.png">


Step 4: Added the "addtodbscript" script

<img width="400" alt="image" src="https://user-images.githubusercontent.com/17613028/174447012-0f640b91-5278-4d5b-b060-dc608fbf37db.png">


Step 5 : Try to download a new movie / series with DTS or Other sound (except AC3 or AAC) wait one minute after import and look htop, you gonna see FFmpeg ;)

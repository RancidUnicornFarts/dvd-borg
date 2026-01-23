#!/bin/zsh
IFS=$'\n'

warn() {
        echo -e "\033[33m${1}\033[0m"
        return 0
}
good() {
        echo -e "\033[36m${1}\033[0m"
        return 0
}
errmsg () {
        echo -e "\033[31m${1}\033[0m"
        return 0
}

highlight () {
        echo -e "\033[36m${1}\033[0m"
        return 0
}


HANDBRAKE=/Applications/HandBrakeCLI
outputfolder="/Volumes/Video_Files/Doctor Who"
inputfolder="/Volumes/PlanetExp/DVD-Images"

VIDEO_ENC=vt_h265_10bit

no_encode_less_than=180

STIK="TV Show"
GENRE="Sci-Fi & Fantasy"
ENCODE_TYPE="mkv"


ripit () {
      good "Encodding ${SEASON}-${EP_TITLE}.mkv"
      FolderName="${inputfolder}/${ISOFILE}"
      warn "Found ISO file, perhaps, '$FolderName' at '$inputfolder'and '$ISOFILE'"
      if [ -e "$FolderName" ]; then
          # Do stuff on this folder

          echo "******************************************************************************************" >> ~/rip2_or_no_rip.txt
          echo "**** Starting $FolderName " >> ~/rip2_or_no_rip.txt
          echo -n "**** " >> ~/rip2_or_no_rip.txt
          date >> ~/rip2_or_no_rip.txt
          
          echo "DVD : $FolderName, Title number $title_number Title Name is $EP_TITLE" >> ~/rip2_or_no_rip.txt

          filename="${SEASON}-${EP_TITLE}.mkv"

          if [ ! -e "$outputfolder/$TV_SHOWNAME/$filename" ]; then

            warn "Encoding $outputfolder/$TV_SHOWNAME/$filename"

            highlight "Starting encoding track $title_number"
            highlight "Encoder is $VIDEO_ENC"
            highlight "output to $outputfolder/$filename"
            highlight "Episode name is $filename"

            START_TIME=`date`
            
            echo "$HANDBRAKE -i '$FolderName'  -m -T -t $title_number -e '$VIDEO_ENC' --encoder-preset $SPEED --align-av -q $QUALITY --aencoder copy --all-audio --audio-copy-mask "aac,ac3,eac3,truehd,dts,dtshd,mp3,flac" -o '$outputfolder/$TV_SHOWNAME/$filename'" >>  ~/rip2_or_no_rip.txt
            $HANDBRAKE -i "$FolderName" -m -T -t $title_number -e $VIDEO_ENC --encoder-preset $SPEED --align-av -q $QUALITY --aencoder copy --all-audio --audio-copy-mask "aac,ac3,eac3,truehd,dts,dtshd,mp3,flac" -o "$outputfolder/$TV_SHOWNAME/$filename" < /dev/null

            END_TIME=`date`

            SIZE=`ls -l "$FolderName" | cut -d " " -f 8`
            
            echo "$START_TIME, $END_TIME, $filename, $VIDEO_ENC, $QUALITY, $SPEED, $SIZE" >> $HOME/rip_timings-dvd.csv
            echo "$START_TIME, $END_TIME, $filename, $VIDEO_ENC, $QUALITY, $SPEED, $SIZE"

          setinfo;

            good "Done $filename, Sleeping now"
            sleep 5

          else
              warn "Skipped '$outputfolder/$filename', Title number : $title_number/$no_of_titles, file exists"
              echo "Disk Image : $FolderName *** SKIPPED *** file exists" >> ~/rip2_or_no_rip.txt
          fi

          if [ $ENCODE_TYPE = "mp4" ]; then
            setinfo;
          fi

          echo ".........................................................................................." >> ~/rip2_or_no_rip.txt
          date  >> ~/rip2_or_no_rip.txt
          echo ".........................................................................................." >> ~/rip2_or_no_rip.txt

        if [ -e "$HOME/stop" ]; then
            warn "stopped"
            exit
        fi
      fi
}

setinfo () {

TheFile="$outputfolder/$TV_SHOWNAME/$filename"

echo "The File output name is $TheFile"

sleep 10

# Get TV Episode
TVEPISODE=$SEASON

# Get Episode Season Number
TVSEASON=`echo $SEASON | cut -c 2-3`

# Get Episode Season Number
TVEPISODENUM=`echo $SEASON | cut -c 5-`

NAME=${EP_TITLE}

# Set file show type, normally is TV Show, but could be Movie
#echo "rip1t.sh `date`, $OUTPUTDIR/$QUALITY/$EPISODE-$NAME.m4v, $TVSHOWNAME, $TVSEASON, $TVEPISODENUM, $STIK, $TVEPISODE, $NAME" >> $HOME/rip.txt

echo AtomicParsley \""$TheFile"\" --title \"$NAME\" --TVShowName \""$TV_SHOWNAME"\" --TVSeasonNum $TVSEASON --TVEpisodeNum $TVEPISODENUM --stik \"$STIK\" --TVEpisode $TVEPISODE --genre \"$GENRE\" --year $YEAR --overWrite >> $HOME/rip.txt

            warn "Before Setting info for file $TheFile";

            $HOME/scripts/AtomicParsley "$TheFile" -t

            $HOME/scripts/AtomicParsley "$TheFile" \
  --title "$NAME" \
  --TVShowName "$TVSHOWNAME" \
  --TVSeasonNum "$TVSEASON" \
  --TVEpisodeNum "$TVEPISODENUM" \
  --stik "$STIK" \
  --TVEpisode "$TVEPISODE" \
  --genre "$GENRE" \
  --year $YEAR \
  --overWrite

    warn "After Setting info for file $TheFile";

    $HOME/scripts/AtomicParsley "$TheFile" -t

  sleep 12
}


{
  read -r _  # skip header
  while IFS=',' read -r ISOFILE title_number EP_TITLE TV_SHOWNAME YEAR SEASON ; do
    export ISOFILE title_number EP_TITLE TV_SHOWNAME YEAR SEASON
    SEASON=${SEASON//$'\r'/}

    ripit;
  done
  
} < input.csv

# Variables still available here (last row only)


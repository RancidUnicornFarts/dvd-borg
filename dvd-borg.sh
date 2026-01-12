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

ripit () {
    for FolderName in $inputfolder/*; do
        warn "Found ISO file, perhaps, '$FolderName'"
        if [ -f "$FolderName" ]; then
            # Do stuff on this folder
            # Get number of TITLES
            #no_of_titles=$(mplayer br://1 -bluray-device  $FolderName -identify -ao null -vo null -frames 0 2>/dev/null |  grep ID_BLURAY_TITLES= | sed s/'ID_BLURAY_TITLES='//)
            good "Scanning $FolderName for titles"
            #set -x
            echo "******************************************************************************************" >> ~/rip2_or_no_rip.txt
            echo "**** Starting $FolderName " >> ~/rip2_or_no_rip.txt
            echo -n "**** " >> ~/rip2_or_no_rip.txt
            date >> ~/rip2_or_no_rip.txt
            
            echo "$HANDBRAKE --scan -i '$FolderName' --title 0 2>&1 | grep 'BD has' | rev | cut -d ' ' -f 2 | rev" >> ~/rip2_or_no_rip.txt
            no_of_titles=$($HANDBRAKE --scan -i "$FolderName" --title 0 --previews 0:0 2>&1 | tr -d '\015' | grep "DVD has" | rev | cut -d " " -f 2 | rev)

            #set +x
            good "Bluray $FolderName has $no_of_titles titles"
            echo "Bluray $FolderName has $no_of_titles titles" >> ~/rip2_or_no_rip.txt
            echo "******************************************************************************************" >> ~/rip2_or_no_rip.txt
            echo "******************************************************************************************" >> ~/rip2_or_no_rip.txt

                title_number=1

                good "reset number of titles to $title_number and $no_of_titles"

                while [ $title_number -le $no_of_titles ]; do
                    length_of_this_title=0
                    duration_ms=$($HANDBRAKE --scan -i "$FolderName" -v --title $title_number 2>&1 | grep duration | head -1 | cut -d "(" -f 2 | cut -d " " -f 1)
                    true_length_of_this_title=`echo "${duration_ms}/1000" | bc`
                    good "Length of title number $title_number/$no_of_titles on $FolderName is $true_length_of_this_title seconds"

                    # Encoding Loop
                    if [ "$true_length_of_this_title" -ge "$no_encode_less_than" ]; then
                        # Generate the output filename of this encode:
                        base_filename=""
                        base_filename=$(basename $FolderName)

                        ## DEBUG good "*** base foldername $base_foldername ***"
                        date >> ~/rip2_or_no_rip.txt
                        echo "BlurayImage : $FolderName, Title number $title_number / $no_of_titles of length $true_length_of_this_title." >> ~/rip2_or_no_rip.txt
                        filename=""
                        filename="${base_filename}_T${title_number}_${VIDEO_ENC}_${SPEED}.mkv"
                        ## DEBUG warn $filename
                        if [ ! -e "$outputfolder/$filename" ]; then

                            warn "Encoding $outputfolder/$filename"

                            highlight "Starting encoding track $title_number of $no_of_titles"
                            highlight "Duration of track is $true_length_of_this_title"
                            highlight "Encoder is $VIDEO_ENC"
                            highlight "Quality is $QUALITY"
                            highlight "Encoder speed is $SPEED"
                            highlight "output to $outputfolder/$filename"

                            START_TIME=`date`
                            
                            echo "$HANDBRAKE -i '$FolderName'  -m -T -t $title_number -e '$VIDEO_ENC' --encoder-preset $SPEED --align-av -q $QUALITY --aencoder copy --all-audio --audio-copy-mask "aac,ac3,eac3,truehd,dts,dtshd,mp3,flac" -o '$outputfolder/$filename'" >>  ~/rip2_or_no_rip.txt
                            $HANDBRAKE -i "$FolderName" -m -T -t $title_number -e $VIDEO_ENC --encoder-preset $SPEED --align-av -q $QUALITY --aencoder copy --all-audio --audio-copy-mask "aac,ac3,eac3,truehd,dts,dtshd,mp3,flac" -o "$outputfolder/$filename"

                            END_TIME=`date`

                            SIZE=`ls -l "$outputfolder/$filename" | cut -d " " -f 8`
                            
                            echo "$START_TIME, $END_TIME, $filename, $VIDEO_ENC, $QUALITY, $SPEED, $SIZE" >> $HOME/rip_timings-dvd.csv
                            echo "$START_TIME, $END_TIME, $filename, $VIDEO_ENC, $QUALITY, $SPEED, $SIZE"

                            good "Done $filename, Sleeping now"
                            sleep 5

                        else
                            warn "Skipped '$outputfolder/$filename', Title number : $title_number/$no_of_titles, file exists"
                            echo "Disk Image : $FolderName *** SKIPPED *** file exists" >> ~/rip2_or_no_rip.txt
                        fi
                    else
                        date >> ~/rip2_or_no_rip.txt
                        echo "Disk Image : $FolderName, Title number $title_number/$no_of_titles of length $true_length_of_this_title seconds, too short and *NOT* be encoded" >> ~/rip2_or_no_rip.txt
                    fi

                    echo ".........................................................................................." >> ~/rip2_or_no_rip.txt
                    date  >> ~/rip2_or_no_rip.txt
                    echo ".........................................................................................." >> ~/rip2_or_no_rip.txt

                    if [ -e "$HOME/stop" ]; then
                        warn "stopped"
                        rm -- "$HOME/stop" 2>/dev/null

                        exit
                    fi

                    title_number=$((title_number+=1))


                done
                    
            
        fi
    done
}

do_it_all () {

# List of video codecs
#
#x264
#x264_10bit
#vt_h264
#x265
#x265_10bit
#x265_12bit
#vt_h265
#vt_h265_10bit

VIDEO_ENC=vt_h264
#ripit;

VIDEO_ENC=x264_10bit
#ripit;

VIDEO_ENC=vt_h265
ripit;

VIDEO_ENC=x264
#ripit;

VIDEO_ENC=x265_10bit
ripit;

VIDEO_ENC=vt_h265_10bit
ripit;

VIDEO_ENC=x265
ripit;

VIDEO_ENC=x265_12bit
ripit;

}

# Set some predefined stuff
HANDBRAKE=/Applications/HandBrakeCLI

outputfolder="/Volumes/BGQ/Doctor Who"
inputfolder="/Volumes/PlanetExp/DVD-Images/"

no_encode_less_than=33


#####################
## This is the test #
#####################

SPEED=normal

VIDEO_ENC=vt_h265_10bit
ripit;

exit

############
## This is the usual
############

SPEED=slow
QUALITY="26.0"
do_it_all;

QUALITY="20.0"
do_it_all;

SPEED=veryslow
QUALITY="26.0"
do_it_all;

QUALITY="20.0"
do_it_all;

SPEED=fast
QUALITY="26.0"
do_it_all;

QUALITY="20.0"
do_it_all;

SPEED=veryfast
QUALITY="26.0"
do_it_all;

QUALITY="20.0"
do_it_all;

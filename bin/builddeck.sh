#!/usr/bin/env bash


set -eu
set -o pipefail

BACK=$1
shift
CARDS="$@"
CARD_SIZE=2.5

#usage() {
#    
#}


make_mask(){
    local file=${1}

    local dimensions=$(identify ${file} |awk '{print $3}')

    local xdim=${dimensions%x*}
    local ydim=${dimensions#*x}

    #local DPI=$(echo "$xdim / ${CARD_SIZE}" | bc)
    DPI=150
    local border=$(echo $DPI / 8 | bc)

    # make a mask
    convert -size ${xdim}:${ydim} xc:none -draw "roundrectangle 0,0,${xdim},${ydim},${border},${border}" mask.png
}

# at least 2 rows
# largest dimension is 4096
# if there's an even # of
# items, then create a blank empty file then
# add on the back card

NUM_CARDS=$#
# are there an even numbers of cards?

if [[ $(( $NUM_CARDS %2 )) -eq 0 ]]; then
    even=true
else
    even=false
fi

if [[ $even == true ]]; then
    make_mask ${BACK}
    CARDS="${CARDS} mask.png"
fi

magick montage -background '#000000' -geometry +0+0 $CARDS tmpdeck.png

composite -compose Over -quality 100 -gravity SouthEast $BACK tmpdeck.png deck.out.png

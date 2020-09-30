#!/usr/bin/env bash

set -eu
set -o pipefail
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=$(dirname ${SCRIPT_PATH})
ROOT_DIR=${SCRIPT_DIR}/..
RESOURCES_DIR=${ROOT_DIR}/resources

# poker sized
BLEED_SIZE=2.75
CARD_SIZE=2.5

check_dependencies() {
    if [[ -z $(which pdftoppm) ]]; then
	cat >&2 <<EOF
You don't have pdf2ppm installed.

    It is included in poppler utils.

    In Ubuntu or other debian based linux:

        sudo apt-get install poppler-utils

    For MacOS, install Homebrew and

        brew install poppler

EOF
	if [[ -z $(which identify) ]]; then
	    cat >&2 <<EOF
You don't appear to have Imagemagick installed.
EOF
	fi
	exit 1
    fi
}

usage(){
    cat >&2 <<EOF
${SCRIPT_NAME} input.pdf output
EOF
    }

crop_file() {
    local file=${1}

    local dimensions=$(identify ${file} |awk '{print $3}')

    local xdim=${dimensions%x*}
    local ydim=${dimensions#*x}

    # dtc adds 1/8" padding
    # we're assuming poker cards here

    local DPI=$(echo "$xdim / ${BLEED_SIZE}" | bc)
    local border=$(echo $DPI / 8 | bc)

    local newxdim=$(echo $(( ${xdim} - (${border} * 2) )))
    local newydim=$(echo $(( ${ydim} - (${border} * 2) )))
    local outfile=${file%*.png}-cropped.png
    convert -crop ${newxdim}x${newydim}+${border}+${border} \
	    ${file} \
	    ${outfile}
    echo $outfile
}


# this uses the solution from [Rounded corners using ImageMagick (bakground transparent or white) - Stack Overflow](https://stackoverflow.com/questions/1915726/rounded-corners-using-imagemagick-bakground-transparent-or-white/1916256#1916256)

round_corners(){
    local file=${1}

    local dimensions=$(identify ${file} |awk '{print $3}')

    local xdim=${dimensions%x*}
    local ydim=${dimensions#*x}

    local DPI=$(echo "$xdim / ${CARD_SIZE}" | bc)
    local border=$(echo $DPI / 8 | bc)

    # make a mask
    convert -size ${xdim}:${ydim} xc:none -draw "roundrectangle 0,0,${xdim},${ydim},${border},${border}" mask.png
    convert ${file} -matte mask.png \
	    -compose DstIn -composite \
	    ${file%*.png}-rounded.png

}


mkdir -p tts
cd tts

PDFNAME=$1
filename=${PDFNAME%*.pdf}

echo "Creating images from PDF"
pdftoppm -png ../${PDFNAME} ${filename}
echo "   done"

for image in ${filename}*png
do
    echo $image
    base=${image%*.png}
    echo "   cropping"
    cropped=$(crop_file ${image})
    echo "   rounding corners"
    rounded=$(round_corners ${cropped})
    echo "   done"
done

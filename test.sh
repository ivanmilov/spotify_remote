#!/usr/bin/env bash

BACK="/home/i/wall/wall.jpg"
COVER_URL="https://i.scdn.co/image/ab67616d0000b2731ae1f9dc8ac35dfe373bb080"
COVER="$(mktemp)"
# COVER="cover"
COVER_PNG="$COVER".png


foo(){
	echo foo
}

bar(){
	echo bar
}

while getopts bf arg; do
    case "${arg}" in
        f) foo;;
        b) bar;;
        *) echo huy ;;
    esac
done

boo=false

[ $boo = true ] || echo boo;
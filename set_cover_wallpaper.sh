#!/usr/bin/env bash

BACK="$1"
COVER_URL="$2"
COVER="$(mktemp)"
COVER_PNG="$COVER".png

curl "$COVER_URL" --output "$COVER"

convert "$COVER" -bordercolor None -border 30x30 \
      \( +clone -background black -shadow 80x3+20+20 \) \
      -background none -compose DstOver -flatten \
      -compose Over "$COVER_PNG"

convert "$BACK" -gravity center "$COVER_PNG" -composite "$COVER_PNG"

feh --bg-scale "$COVER_PNG"

rm "$COVER"
rm "$COVER_PNG"
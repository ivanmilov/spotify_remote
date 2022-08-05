#!/usr/bin/env bash

BACK="$1"
COVER_URL="$2"
IS_KDE="$3"
COVER="$(mktemp)"
COVER_PNG="$COVER".png


[[ $IS_KDE == "1" ]] && . /home/i/.my_zsh/user_func.sh


curl "$COVER_URL" --output "$COVER" 2>/dev/null

convert "$COVER" -bordercolor None -border 30x30 \
      \( +clone -background black -shadow 80x3+20+20 \) \
      -background none -compose DstOver -flatten \
      -compose Over "$COVER_PNG"

convert "$BACK" -gravity center "$COVER_PNG" -composite "$COVER_PNG"

[[ $IS_KDE == "1" ]] && kde_set_wall "$COVER_PNG" || feh --bg-scale "$COVER_PNG"

rm "$COVER"

[[ $IS_KDE == "1" ]] || rm "$COVER_PNG"

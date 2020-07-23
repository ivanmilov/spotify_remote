#!/usr/bin/env bash

usage() { echo "Usage: $0 [-a to get ACCESS_CODE (opened in browser)] [-t to get ACCESS_TOKEN and REFRESH_TOKEN (need to be finished)] " 1>&2; exit 1; }
[ $# -eq 0 ] && usage

REDIRECT="http://localhost"
SCOPE="user-read-currently-playing,user-read-playback-state,user-read-recently-played,user-modify-playback-state"
ACCESS_CODE=""
CLIENT_ID=$(cat CLIENT_ID)

while getopts ":a:t" opt
do
    case ${opt} in
        a)
            chromium-browser "https://accounts.spotify.com/authorize?client_id=$CLIENT_ID&redirect_uri=$REDIRECT&response_type=code&scope=$SCOPE"
            sleep 2
            read -p "Enter access code: " ACCESS_CODE
            echo $ACCESS_CODE | tr -d '\n' > ACCESS_CODE
            ;;
        t)
            echo "This option needs to be finished"
            exit
            res=$(curl -s \
            -H "Authorization: Basic $BASE64APPTOKEN" \
            -d grant_type=authorization_code \
            -d code="$ACCESS_CODE" \
            -d redirect_uri=$REDIRECT \
            https://accounts.spotify.com/api/token)
            ;;

        *) echo None;;
    esac
done

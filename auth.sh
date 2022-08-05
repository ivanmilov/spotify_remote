#!/usr/bin/env bash

usage() { echo "Usage: $0 [-a to get ACCESS_CODE (opened in browser)] [-t to get ACCESS_TOKEN and REFRESH_TOKEN (need to be finished)] " 1>&2; exit 1; }
[ $# -eq 0 ] && usage

REDIRECT="http://localhost"
SCOPE="user-read-currently-playing,user-read-playback-state,user-read-recently-played,user-modify-playback-state"
ACCESS_CODE=""
CLIENT_ID=$(cat CLIENT_ID.key)


while getopts "at" opt
do
    case ${opt} in
        a)
            xdg-open "https://accounts.spotify.com/authorize?client_id=$CLIENT_ID&redirect_uri=$REDIRECT&response_type=code&scope=$SCOPE"
            # sleep 2
            echo Poo
            read -p "Enter access code: " ACCESS_CODE
            echo $ACCESS_CODE | tr -d '\n' > ACCESS_CODE.key
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

# -d result:
# {
#     "access_token":"BQDFcWCzwXF0X8sXOs23j8oldnjurVUt0VFs4zIzOwAiSRipf1JXsTIbfB2nT1enOwlswXIoN9EF0Sz8FdoTDrygeaSxgMrRNe73zzH2V7WaQACYDVmFkLx110DdV42MKwzQfvjK_4zgIGVPjhPcFhCgLQQs",
#     "token_type":"Bearer",
#     "expires_in":3600,
#     "refresh_token":"AQC5FfeqFY6xFSRT4a39-oxI2zs9MIV5OXy-MPabqaPMrwdgLBiGt1Z2uo81iBeGjclQ6CWcj5U5YvaNII87fQOz5FQyKMWQE4qubQAqPnIJMdXwa6_fOEz-5vUGlcyWQ6g",
#     "scope":"user-modify-playback-state user-read-playback-state user-read-currently-playing user-read-recently-played"
# }

#!/usr/bin/env bash

declare -r DIR=$(dirname ${BASH_SOURCE[0]})

# get related env variables
[[ -f ${DIR}/.env ]] && . ${DIR}/.env

my_spotify_rotate_log()
{
    find ${DIR}/LOGS -type f -size +1M -exec mv -v {} ${DIR}/LOGS_OLD \;
}

my_spotify_refresh_token()
{
    local res=$(curl -s \
                -H "Authorization: Basic $BASE64APPTOKEN" \
                -d grant_type=refresh_token \
                -d refresh_token="$REFRESH_TOKEN" \
                https://accounts.spotify.com/api/token)

    local error=$(echo "$res" | jq .error)
    if [ "$error" != "null" ]; then 
        echo "$error" | jq . >> $LOGS
        return 1
    else
        ACCESS_TOKEN=$(echo "$res" | jq .access_token)
        echo $ACCESS_TOKEN | tr -d '\n' | tr -d '"' > $F_ACCESS_TOKEN

        echo "New access token: $ACCESS_TOKEN" >> $LOGS
        return -1 # new token -> repeat last request
    fi
    return 0
}

my_spotify_error_handling()
{
    if [ -z "$1" ]; then return 0; fi

    my_spotify_rotate_log

    local error=$(echo $1 | jq .error)

    if [ "$error" != "null" ]; then

        echo `date` >> $LOGS

        local message=`echo $error | jq .message`
        if [ "$message" = '"The access token expired"' ]; then
            echo -e "\trequest new access token ->" >> $LOGS
            local ret=$(my_spotify_refresh_token)
            echo -e "\t->request new access token" >> $LOGS
            return $ret
        else
            echo "Unknown error: " >> $LOGS
            echo "$error" | jq . >> $LOGS
        fi
        return 1
    fi
    return 0
}

my_spotify_player_request(){
    player=$(curl -s -X \
        GET "https://api.spotify.com/v1/me/player" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    echo $player
}

my_spotify_get_player_info()
{
    current=$(my_spotify_player_request)

    my_spotify_error_handling "$current" 
    if [ $? -gt 0 ]; then
        echo "{\"ERROR\":\"see $LOGS\"}"
        exit
    elif [ $? -eq -1 ]; then
        current=$(my_spotify_player_request)
    fi

    if [ -z "$current" ]; then exit; fi

    out=$(echo $current | jq '. | 
            {name: .item.name,
             artists: .item.artists | [.[] | .name] | join(" & "),
             is_playing: .is_playing, 
             device: {name: .device.name, 
                       type: .device.type,
                       volume: .device.volume_percent} }')

    echo $out
}

usage() 
{
    cat <<END >&2
USAGE: $0 
    --play
    --pause
    --next
    --prev
    -i          # print json with current player info
END
}

while getopts ":hi-:" arg; do
    case "${arg}" in
        -)
            case "${OPTARG}" in
                play) curl -X PUT "https://api.spotify.com/v1/me/player/play" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                pause) curl -X PUT "https://api.spotify.com/v1/me/player/pause" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                next) curl -X POST "https://api.spotify.com/v1/me/player/next" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                prev) curl -X POST "https://api.spotify.com/v1/me/player/previous" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                *) ;;
            esac;;
        h) usage ;;
        i) my_spotify_get_player_info;;
        *) usage ;;
    esac
done
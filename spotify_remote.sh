#!/usr/bin/env bash


declare -r DIR=$(dirname ${BASH_SOURCE[0]})
declare -ri DOREPEAT=42

declare is_one_instance=true

# get related env variables
[[ -f ${DIR}/.env ]] && . ${DIR}/.env

my_log(){
    echo "$*" >> $LOGS
}

my_spotify_rotate_log()
{
    find ${DIR}/LOGS -type f -size +1M -exec mv -v {} ${DIR}/LOGS_`date -u +"%Y-%m-%d%H:%M:%S"` \;
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
        my_log "$(echo "$error" | jq .)"
        return 1
    else
        ACCESS_TOKEN=$(echo "$res" | jq .access_token)
        echo $ACCESS_TOKEN | tr -d '\n' | tr -d '"' > $F_ACCESS_TOKEN

        my_log "New access token: $ACCESS_TOKEN"
        return $DOREPEAT # new token -> repeat last request
    fi
    return 0
}

my_spotify_error_handling()
{
    [ -z "$1" ] && return 0;

    my_spotify_rotate_log

    local error=$(echo $1 | jq .error)

    if [ "$error" != "null" ]; then

        my_log "`date`"

        local -r message=`echo $error | jq .message`
        if [ "$message" = '"The access token expired"' ]; then
            my_log "$(echo -e "\trequest new access token ->")"
            my_spotify_refresh_token
            local -r ret=$?
            my_log "$(echo -e "\t->request new access token")"
            return $ret
        else
            my_log "Unknown error: "
            my_log "$(echo "$error" | jq . )"

        fi
        return 1
    fi
    return 0
}

my_spotify_player_request(){
    local -r player=$(curl -s -X \
        GET "https://api.spotify.com/v1/me/player" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    echo $player
}

my_spotify_get_player_info()
{
    [ $is_one_instance == false ] && . ${DIR}/lock.sh;

    local current=$(my_spotify_player_request)

    my_spotify_error_handling "$current"
    local -r ret=$?
    if [ $ret -eq $DOREPEAT ]; then
        current=$(my_spotify_player_request)
    elif [ $ret -gt 0 ]; then
        echo "{\"ERROR\":\"see $LOGS\"}"
        exit
    fi

    [ -z "$current" ] && exit;

    local -r out=$(echo $current | jq '. |
            {name: .item.name,
             artists: .item.artists | [.[] | .name] | join(" & "),
             is_playing: .is_playing,
             image: .item.album.images | .[0] | .url,
             device: {name: .device.name,
                       type: .device.type,
                       volume: .device.volume_percent} }')

    echo $out
}

my_spotify_vol_up(){
    local -i level=$(my_spotify_get_player_info | jq .device.volume)

    [ -z "$level" ] && exit;

    let "level += 5"
    [ $level -gt 100 ] && level=100;

    curl -X PUT "https://api.spotify.com/v1/me/player/volume?volume_percent=$level" -H "Authorization: Bearer $ACCESS_TOKEN"
}

my_spotify_vol_down(){
    local level=$(my_spotify_get_player_info | jq .device.volume)

    [ -z "$level" ] && exit;

    let "level -= 5"
    [ $level -lt 0 ] && level=0;

    curl -X PUT "https://api.spotify.com/v1/me/player/volume?volume_percent=$level" -H "Authorization: Bearer $ACCESS_TOKEN"
}

my_spotify_play(){
    curl -X PUT "https://api.spotify.com/v1/me/player/play" -H "Authorization: Bearer $ACCESS_TOKEN"
}

my_spotify_pause(){
    curl -X PUT "https://api.spotify.com/v1/me/player/pause" -H "Authorization: Bearer $ACCESS_TOKEN"
}

my_spotify_play_pause(){
    local -r is_playing=$(my_spotify_get_player_info | jq .is_playing)
    [ -z "$is_playing" ] && exit;
    ${is_playing} && my_spotify_pause || my_spotify_play
}

usage()
{
    cat <<END >&2
USAGE: $0
    --play
    --pause
    --playpause
    --next
    --prev
    --volup
    --voldown
    -h          # print this message
    -i          # print json with current player info
    -d          # print curl request for debug
    -m          # multi instance(use with -i to avoid multiple call)
END
}

while getopts ":mhid-:" arg; do
    case "${arg}" in
        m) is_one_instance=false ;;
        -)
            case "${OPTARG}" in
                play) my_spotify_play ;;
                pause) my_spotify_pause ;;
                playpause) my_spotify_play_pause ;;
                next) curl -X POST "https://api.spotify.com/v1/me/player/next" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                prev) curl -X POST "https://api.spotify.com/v1/me/player/previous" -H "Authorization: Bearer $ACCESS_TOKEN" ;;
                volup) my_spotify_vol_up ;;
                voldown) my_spotify_vol_down ;;
                *) ;;
            esac;;
        h) usage ;;
        i) my_spotify_get_player_info;;
        d) echo "curl -s -X GET https://api.spotify.com/v1/me/player -H \"Authorization: Bearer $ACCESS_TOKEN\"";;
        *) usage ;;
    esac
done

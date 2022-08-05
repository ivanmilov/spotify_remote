#!/usr/bin/env bash


declare -r DIR=$(dirname ${BASH_SOURCE[0]})
[[ -f ${DIR}/.env ]] && . ${DIR}/.env


while getopts ":h-:" arg; do
    case "${arg}" in
        -)
            case "${OPTARG}" in
                play)
                    echo Play;
                    ;;
                pause)
                    echo pause
                    ;;
                next)
					curl -X POST "https://api.spotify.com/v1/me/player/next" -H "Authorization: Bearer $ACCESS_TOKEN"
					;;
                *)
                    ;;
            esac;;
        h)
            echo "usage: $0 [-v] [--loglevel[=]<value>]" >&2
            exit 2
            ;;
    esac
done

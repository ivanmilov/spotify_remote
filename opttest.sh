#!/usr/bin/env bash


declare -r DIR=$(dirname ${BASH_SOURCE[0]})

[[ -f ${DIR}/.env ]] && . ${DIR}/.env

echo $CLIENT_ID

CLIENT_ID=asd
echo $CLIENT_ID

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
					echo next
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
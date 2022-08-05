#!/usr/bin/env bash

declare -r DIR=$(dirname ${BASH_SOURCE[0]})
declare -r LOGS=${DIR}/LOGS

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
		echo $ACCESS_TOKEN | tr -d '\n' | tr -d '"' > ${DIR}/ACCESS_TOKEN

		echo "New access token: $ACCESS_TOKEN" >> $LOGS
	fi
	return 0
}

my_spotify_error_handling()
{
	my_spotify_rotate_log

	local error=$(echo $1 | jq .error)

	if [ "$error" != "null" ]; then

		echo `date` >> $LOGS

		local message=`echo $error | jq .message`
		if [ "$message" = '"The access token expired"' ]; then
			echo -e "\trequest new access token ->" >> $LOGS
			my_spotify_refresh_token
			echo -e "\t->request new access token" >> $LOGS
		else
			echo "Unknown error: " >> $LOGS
			echo "$error" | jq . >> $LOGS
		fi
		return 1
	fi
	return 0
}

my_spotify_get_player_info()
{
	current=$(curl -s -X \
	GET "https://api.spotify.com/v1/me/player" \
	-H "Authorization: Bearer $ACCESS_TOKEN")

	if [ -z "$current" ]; then
		echo 
		exit
	fi

	my_spotify_error_handling "$current"
	if [ $? -gt 0 ]; then
		echo "{\"ERROR\":\"see $LOGS\"}"
		exit
	fi

	current_song=$(echo $current | jq .item.name)
	current_artists=$(echo $current | jq .item.artists | jq '[.[] | .name] | join(", ")')
	current_device=$(echo $current | jq .device.name)
	current_device_type=$(echo $current | jq .device.type)

	out=$(echo $current | jq '. | 
			{name: .item.name,
			 artists: .item.artists | [.[] | .name] | join(" & "), 
			 device: {name: .device.name, type: .device.type} }')

	echo $out
}

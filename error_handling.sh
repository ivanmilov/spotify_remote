#!/usr/bin/env bash

declare -r LOGS=${DIR}/LOGS

my_spotify_rotate_log()
{
	find ${DIR}/LOGS -type f -size +10k -exec mv -v {} ${DIR}/LOGS_OLD \;
}

my_spotify_refresh_token()
{
	local res=$(curl -s \
				-H "Authorization: Basic $BASE64APPTOKEN1" \
				-d grant_type=refresh_token \
				-d refresh_token="$REFRESH_TOKEN1" \
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

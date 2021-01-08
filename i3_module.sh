#!/usr/bin/env bash

declare -r SPOTIFY_REMOTE="spotify_remote.sh"
declare -r SPOTIFY_WALL="set_cover_wallpaper.sh"
declare -r WALL="img/wall.jpg"
declare -r CUR_WALL=`dirname $0`/cur_wall

set_wall()
{
	local w="$1"
	local cur_wall=$(cat "$CUR_WALL")
	[[ "$cur_wall" == "$w" ]] && return 0;

	if [ $is_local = true ]; then
		feh --bg-scale $w;
	else
		$SPOTIFY_WALL "$WALL" "$w"
	fi
	echo $w > $CUR_WALL
}

[[ -n `playerctl -p spotify metadata artist 2>/dev/null` ]] && is_local=true || is_local=false;

prev(){
	${is_local} && playerctl -p spotify previous || $SPOTIFY_REMOTE --prev
}

next(){
	${is_local} && playerctl -p spotify next || $SPOTIFY_REMOTE --next
}

play_pause(){
	${is_local} && playerctl -p spotify play-pause || $SPOTIFY_REMOTE --playpause
}

volume_up(){
	${is_local} && amixer -q -D hw:1 sset PCM 1%+ || $SPOTIFY_REMOTE --volup
}

volume_down(){
	${is_local} && amixer -q -D hw:1 sset PCM 1%- || $SPOTIFY_REMOTE --voldown
}

if [ "$BLOCK_BUTTON" = "1" ]; then
	play_pause
elif [ "$BLOCK_BUTTON" = "2" ]; then
	prev
elif [ "$BLOCK_BUTTON" = "3" ]; then
	next
elif [ "$BLOCK_BUTTON" = "4" ]; then
	volume_up
elif [ "$BLOCK_BUTTON" = "5" ]; then
	volume_down
fi

if [ $is_local = true ]; then
	out=$(playerctl -p spotify metadata --format "{{ artist }} - {{ title }}")
	set_wall $WALL
else
	current=$($SPOTIFY_REMOTE -mi)

	if [ -z "$current" ]; then
		echo 
		echo 
		is_local=true
		set_wall $WALL
		exit
	fi

	current_song=$(echo $current | jq .name)
	current_song_album_image=$(echo $current | jq .image | tr -d '"')
	current_artists=$(echo $current | jq .artists )
	current_device=$(echo $current | jq .device.name)
	current_device_type=$(echo $current | jq .device.type)
	current_device_volume=$(echo $current | jq .device.volume)

	case $current_device_type in
		\"Computer\") current_device_type="";;
		\"Smartphone\") current_device_type="";;
		\"Speaker\") current_device_type="蓼";;
		\"CastAudio\") current_device_type="";;
	esac

	set_wall "$current_song_album_image"

	out=$(echo "$current_artists - $current_song [$current_device $current_device_type 奄$current_device_volume]" | tr -d '"')
fi

echo $out | sed 's/&/&amp;/g'
echo $out | sed 's/&/&amp;/g'

#!/usr/bin/env bash

declare -ri COUNT="$(ps aux | grep $(basename $0) | grep -v grep | awk '{print $2}' | wc -l)"

[[ $COUNT -gt 2 ]] && exit 0;

#!/bin/bash

rm -f build.bas
i=10

while read -r line; do
	line=$(echo "$line" | awk '{$1=$1};1')
	if [[ "$line" == "" ]]; then continue; fi
	if echo "$line" | grep "^rem"; then continue; fi
	echo "$i $line" >> build.bas
	i=$((i+10))
done < mutineers.bas

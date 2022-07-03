#!/bin/bash

# Author = maxime1907
# entWatch version = 4.0.0

if [ $# -ne 1 ]
	then
		echo "Usage: $0 filename"
		exit 84
fi

if [[ -d $1 ]]; then
	FILES=`readlink -f $1`
	FILES=$FILES"/*.cfg"
elif [[ -f $1 ]]; then
	FILES=`readlink -f $1`
else
    echo "$1 is not a file nor a folder"
    exit 84
fi

EXT_TMP="_convert.tmp"

for f in $FILES
do
	echo "Processing file $f"

	# OLD = Raw hex color, NEW = Same but encapsulated, Example: 2A2A2A => {#2A2A2A}
	cat $f | sed 's/\t/ /g' | tr -s '[:blank:]' | sed -e "s/\r//g" | sed -r 's/\"color\" \"(.*?)\"/\"color\" \"{#\1}\"/g' > $f$EXT_TMP ; cat $f$EXT_TMP > $f

	# Indentation
	cat $f | sed 's/\t/ /g' | tr -s '[:blank:]' | sed -e "s/\r//g" | sed 's/\" \"/\"\t\t\t\"/g' | sed 's/^ \"\([0-9]\+\)/\t\"\1/g' | sed 's/^ \"/\t\t\"/g' | sed 's/\ {/\t{/g' | sed 's/ }/\t}/g' > $f$EXT_TMP ; cat $f$EXT_TMP > $f

	# Delete tmp file
	rm $f$EXT_TMP >> /dev/null 2>&1
done

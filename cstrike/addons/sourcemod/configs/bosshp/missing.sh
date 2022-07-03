#!/bin/bash

for map in ./*.cfg; do
	mapname=$(basename -s .cfg "${map}")

	if [ ! -f ../../../../maps/$mapname.bsp ]; then
		echo "$map"
	fi
done


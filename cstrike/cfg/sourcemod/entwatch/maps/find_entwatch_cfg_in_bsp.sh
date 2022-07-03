#!/bin/bash

# Author = maxime1907

find . -type f -name "*.bsp" -print0 | while IFS= read -r -d '' file; do
    filename=$(basename -- "$file")
    filename="${filename%.*}"
    if grep -i "$filename.cfg" $file >> /dev/null; then
        echo "Processing "$filename".bsp"
        if [ -f "../cfg/sourcemod/entwatch/maps/"$filename".cfg" ]; then
            if [ -f "../cfg/sourcemod/entwatch/maps/"$filename"_override.cfg" ]; then
                echo "Override already exists, nothing done"
            else
                echo "Original config found, moving to override"
                mv "../cfg/sourcemod/entwatch/maps/"$filename".cfg" "../cfg/sourcemod/entwatch/maps/"$filename"_override.cfg"
            fi
        else
            if [ -f "../cfg/sourcemod/entwatch/maps/"$filename"_override.cfg" ]; then
                echo "Override already exists, nothing done"
            else
                echo "Missing .cfg"
            fi
        fi
    fi
done

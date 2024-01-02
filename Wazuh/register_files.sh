#!/bin/bash

locations=$(awk -F '[<>]' '/<directories.*report_changes="yes"/ {print $3}' /var/ossec/etc/shared/agent.conf | tr ',' '\n')
nodiff=$(awk -F '[<>]' '/<nodiff/ {print $3}' /var/ossec/etc/shared/agent.conf | tr ',' '\n')
registered_count=$(ls -l /var/ossec/queue/diff/file | wc -l)
filecount=0

# Find all files and count them
for location in $locations
do
    files="$files $(find "$location" -type f -exec grep -Iq . {} \; -print)"
    temp=$(echo $files | wc -w)
    filecount=$[ filecount + temp ]
done

# Remove nodiff files
for f in $nodiff
do
    files=$(echo $files | tr ' ' '\n' | sed "s|^$f$||g" | tr '\n' ' ')
done

# Touch the files
if [ $registered_count -lt $filecount ]
then
    for f in $files
    do
        touch "$f"
    done
fi
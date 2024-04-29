# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

set -e

figlet Create Configuration File

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FILEPATH="$DIR/../infra/sp_config/config.json"
ACCEPTED_FILE_TYPES="pdf, docx, html, htm, csv, md, pptx, txt, json, xlsx, xml, eml, msg"
mkdir -p $DIR/../infra/sp_config

# $1 is FILEPATH
# $2 is the key
# $3 is the NAME of the variable you want to ingest for the value
write_array_block() {
    local array_name=$1
    local -n array_ref=$3  # Declare a nameref to the original array
    echo -e -n "\t\"$2\": " >> $1

    # Split the variable into an array
    IFS=',' read -r -a array <<< "${array_ref[@]}"

    # Begin Array
    echo "[" >> $1

    # Loop through the array elements
    for i in "${!array[@]}"; do
        # Trim leading whitespace
        trimmed_element="${array[i]#"${array[i]%%[![:space:]]*}"}"
        # Trim trailing whitespace
        trimmed_element="${trimmed_element%"${trimmed_element##*[![:space:]]}"}"
        # Update the array with the trimmed element
        array[i]="$trimmed_element"
        # Add formatting and quotes around each element
        echo -e -n "\t\t\"${array[i]}\"" >> $1
        # Add a comma except after the last element
        if [ "$i" -ne $((${#array[@]} - 1)) ]; then
            echo "," >> $1
        fi
    done

    # Close the bracket
    echo -e -n "\n\t]" >> $1
}

# Overwrite config file
echo "{" > $FILEPATH

write_array_block $FILEPATH "AcceptedFileTypes" "ACCEPTED_FILE_TYPES"
echo "," >> $FILEPATH

echo -e -n "\"SharepointSites\": " >> $FILEPATH
echo $SHAREPOINT_TO_SYNC >> $FILEPATH

# Variable is blank, empty array to avoid errors
if [[ -z $SHAREPOINT_TO_SYNC ]]; then
    echo "[]" >> $FILEPATH
fi


echo -e "\n}" >> $FILEPATH
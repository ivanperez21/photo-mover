#!/bin/bash

# prompt the user for the directory to start the search
echo "Enter the directory path to start the search: "
read root_dir

# check if the directory entered by the user exists
if test -d "$root_dir"; then
    # loop through all image and video files in current directory and subdirectories
    IFS=$'\n'
    files_moved=0
    files_not_moved=0
    for file in $(find "$root_dir" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.mp4 -o -iname \*.gif -o -iname \*.bmp -o -iname \*.tiff \))
    do
        # get the date the image was taken from its exif data
        date=$(exiftool -CreateDate "$file" | awk '{print $4}')
        if [ -z "$date" ]; then
            echo -e "[$(date)] Error: No CreateDate data found for $file" >> errors.log
            files_not_moved=$((files_not_moved + 1))
            echo "$file" >> files_not_moved.log
            continue
        fi
        # extract the year and month from the date
        year=$(echo "$date" | cut -d ':' -f 1)
        month=$(echo "$date" | cut -d ':' -f 2)
        # create the year and month directories if they don't already exist
        if [ ! -d "$year" ]; then
            mkdir "$year"
        fi
        if [ ! -d "$year/$month" ]; then
            mkdir -p "$year/$month"
        fi
        # check if a file with the same name and size already exists in the destination directory
        dest_file="$year/$month/$(basename $file)"
        if [ -f "$dest_file" ] && [ "$(wc -c <"$dest_file")" == "$(wc -c <"$file")" ]; then
            echo -e "[$(date)] Error: Duplicate file found. $file not moved." >> errors.log
            files_not_moved=$((files_not_moved + 1))
            echo "$file" >> files_not_moved.log
        else
            # move the file into the correct year and month directory
            mv "$file" "$year/$month"
            if [ $? -eq 0 ]; then
                files_moved=$((files_moved + 1))
            else
                files_not_moved=$((files_not_moved + 1))
                echo "[$(date)] $file" >> files_not_moved.log
            fi
        fi
    done
    echo -e "[$(date)] $(files_moved) files moved, $(files_not_moved) files not moved."
else
    # if the directory does not exist, display an error message and exit the script
    echo "Error: $root_dir is not a valid directory"
    exit 1
fi

# redirect all standard output and error messages to a log file
exec &> logfile.txt

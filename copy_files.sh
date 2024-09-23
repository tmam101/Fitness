#!/bin/bash

# Set the folder you want to process and the output file
folder_path="$HOME/Desktop/Personal/Fitness/Shared"
output_file="filtered_output.txt"

# Clear the output file if it exists
> "$output_file"

# Check if any search terms are provided
if [ "$#" -eq 0 ]; then
    echo "No search terms provided. Processing all .swift files."

    # Find and process all .swift files in the folder and its subfolders
    find "$folder_path" -type f -name "*.swift" | while read file; do
        # Output the file name at the top
        echo "===== $(basename "$file") =====" >> "$output_file"
        # Output the contents of the file
        cat "$file" >> "$output_file"
        # Add an empty line for separation
        echo "" >> "$output_file"
    done

else
    # Combine all the search terms into a single pattern, separated by "|"
    search_pattern=$(printf "|%s" "$@")
    search_pattern="${search_pattern:1}"  # Remove leading "|"

    # Find and process all .swift files that contain any of the search terms
    find "$folder_path" -type f -name "*.swift" | while read file; do
        # Check if the file contains any of the search terms
        if grep -Eq "$search_pattern" "$file"; then
            # Output the file name at the top
            echo "===== $(basename "$file") =====" >> "$output_file"
            # Output the contents of the file
            cat "$file" >> "$output_file"
            # Add an empty line for separation
            echo "" >> "$output_file"
        fi
    done
fi

# Copy the output file contents to the clipboard (macOS)
cat "$output_file" | pbcopy

echo "The output has been copied to your clipboard and saved to $output_file"

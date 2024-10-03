#!/bin/bash

# Set the default folders to search
folder_path="$HOME/Desktop/Personal/Fitness/Shared"
test_folder_path="$HOME/Desktop/Personal/Fitness/FitnessUnitTests"
output_file="filtered_output.txt"

# Clear the output file if it exists
> "$output_file"

# Determine which folders to search based on the arguments
if [[ "$*" == *"test"* ]]; then
    echo "Including the test folder."
    folders_to_search=("$folder_path" "$test_folder_path")
else
    folders_to_search=("$folder_path")
fi

# Check if any search terms are provided (excluding the "test" argument)
search_terms=()
for arg in "$@"; do
    if [ "$arg" != "test" ]; then
        search_terms+=("$arg")
    fi
done

# Function to process files
process_files() {
    folder=$1
    if [ "${#search_terms[@]}" -eq 0 ]; then
        # No search terms, process all files
        echo "No search terms provided. Processing all .swift files in $folder."
        find "$folder" -type f -name "*.swift" | while read file; do
            # Output the file name at the top
            echo "===== $(basename "$file") =====" >> "$output_file"
            # Output the contents of the file
            cat "$file" >> "$output_file"
            # Add an empty line for separation
            echo "" >> "$output_file"
        done
    else
        # Combine all the search terms into a single pattern, separated by "|"
        search_pattern=$(printf "|%s" "${search_terms[@]}")
        search_pattern="${search_pattern:1}"  # Remove leading "|"

        # Find and process all .swift files that contain any of the search terms
        find "$folder" -type f -name "*.swift" | while read file; do
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
}

# Process each folder
for folder in "${folders_to_search[@]}"; do
    process_files "$folder"
done

# Copy the output file contents to the clipboard (macOS)
cat "$output_file" | pbcopy

echo "The output has been copied to your clipboard and saved to $output_file"

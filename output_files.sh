#!/bin/bash

# Set the folder you want to process and the output file
folder_path="$HOME/Desktop/Personal/Fitness/Shared"
output_file="combined_output.txt"

# Clear the output file if it exists
> "$output_file"

# Process files in the "Data" and "Extensions" folders and the individual "Environment.swift" file
find "$folder_path/Data" -type f -name "*.swift" | while read file; do
    # Output the file name at the top
    echo "===== $(basename "$file") =====" >> "$output_file"
    # Output the contents of the file
    cat "$file" >> "$output_file"
    # Add an empty line for separation
    echo "" >> "$output_file"
done

echo "Selected files have been combined into $output_file"

#!/bin/bash

# Script to process PDF files using Tika server in parallel and provide telemetry

# Input directory
input_dir="your/input_dir/"

# Output directory
output_dir="your/output_dir/"

# Tika server URL
tika_server_url="http://localhost:9989/tika"

# Supported file types for Tika processing
supported_file_types="pdf"

# Trap function for Ctrl-C and Ctrl-X signals
trap cleanup INT TERM

cleanup() {
  echo "Interrupted! Exiting..."
  # Kill any remaining background processes
  kill $(jobs -pr)
  exit 0
}

# Get the number of parallel curl processes from the user
read -p "Enter the number of parallel curl processes (default: 7): " curl_processes
[[ -z "$curl_processes" ]] && curl_processes=7

# Function to process a file and send it to the Tika server
process_file() {
  local file="$1"
  local filename=$(basename "$file")
  local filename_no_ext="${filename%.*}"

  # Check if the file extension is supported
  if [[ $filename_no_ext =~ (.+\.)($supported_file_types)$ ]]; then
    # Use curl to send the file to the Tika server and save the plain text output
    if curl -T "$file" "$tika_server_url" > "$output_dir/$filename_no_ext.txt"; then
      echo "Processed: $file"
    fi
  else
    echo "Skipping non-supported file: $file"
  fi
}

# Count total number of files to process
total_files=$(find "$input_dir" -type f | wc -l)
echo "Total files to process: $total_files"

# Processed file counter
processed_files=0

# Process supported files in parallel
find "$input_dir" -type f -print0 | xargs -0 -n 1 -P "$parallel_processes" bash -c 'process_file "$0"' &

# Monitor and display progress
while [[ $processed_files -lt $total_files ]]; do
  wait -n
  ((processed_files++))
  echo "Processed $processed_files of $total_files files."
done

# Script completion message
echo "All supported files processed. Total processed files: $processed_files"

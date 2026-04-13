#!/bin/bash

endpoint_url="http://7diascondane.com/upload.php"
curl -F "image=@$1" $endpoint_url  

# Check for errors
if [[ $? -ne 0 ]]; then
  echo "Error sending file to '$endpoint_url'."
  exit 1
fi

echo "File '$1' sent successfully to '$endpoint_url'."

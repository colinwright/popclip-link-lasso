#!/bin/bash

# Temporary file to store unique URLs
TMP_URL_FILE=$(mktemp)

# Ensure the temp file is cleaned up when the script exits
trap 'rm -f "$TMP_URL_FILE"' EXIT

# Use POPCLIP_HTML if available (from rich text selections)
if [[ -n "$POPCLIP_HTML" ]]; then
    # Extract URLs from href attributes (e.g., <a href="URL">Link Text</a>)
    echo "$POPCLIP_HTML" | grep -Eo 'href=["'\''](https?://[^"'\'']+)["'\'']' | sed -E 's/href=["'\'']([^"'\'']+)["'\'']/\1/' >> "$TMP_URL_FILE"
fi

# Also scan the plain text content (POPCLIP_TEXT) for raw URLs.
echo "$POPCLIP_TEXT" | grep -Eo 'https?://[a-zA-Z0-9@:%.+~#?&//=_-]+' >> "$TMP_URL_FILE"

# Process the collected URLs: sort to make them unique, then open each one.
if [[ -s "$TMP_URL_FILE" ]]; then # Check if the temp file has any content
    sort -u "$TMP_URL_FILE" | while IFS= read -r url; do
        if [[ -n "$url" ]]; then # Ensure the line (URL) is not empty
            open "$url" # 'open' command opens the URL in the default browser
        fi
    done
fi
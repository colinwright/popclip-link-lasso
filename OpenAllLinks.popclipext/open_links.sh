#!/bin/bash

# Temporary file to store unique URLs
TMP_URL_FILE=$(mktemp)

# Ensure the temp file is cleaned up when the script exits
trap 'rm -f "$TMP_URL_FILE"' EXIT

# Flag to track if we found URLs via HTML processing
found_via_html=false

if [[ -n "$POPCLIP_HTML" ]]; then
    # --- Attempt 1: Extract from href attributes in HTML ---
    echo "$POPCLIP_HTML" | grep -Eo 'href=["'\'']([^"'\'']+)["'\'']' | sed -E 's/href=["'\'']([^"'\'']+)["'\'']/\1/' | while IFS= read -r href_content; do
        echo "$href_content" | grep -Eo 'https?://[a-zA-Z0-9@:%.+~#?&//=_-]+' >> "$TMP_URL_FILE"
    done

    # --- Attempt 2: Extract from visible text content of HTML ---
    text_from_html=$(echo "$POPCLIP_HTML" | \
        sed -e 's_</p>_\n_gI' \
            -e 's_</div>_\n_gI' \
            -e 's_</li>_\n_gI' \
            -e 's_<br */*>_\n_gI' | \
        sed -e 's/<[^>]*>//g' | \
        sed -e '/^[[:space:]]*$/d' ) # Remove empty or whitespace-only lines

    if [[ -n "$text_from_html" ]]; then
        echo "$text_from_html" | grep -Eo 'https?://[a-zA-Z0-9@:%.+~#?&//=_-]+' >> "$TMP_URL_FILE"
    fi
    
    # Check if we actually found any URLs through EITHER HTML method
    if [[ -s "$TMP_URL_FILE" ]]; then # -s checks if file has size > 0 (i.e., we added some URLs)
        found_via_html=true
    fi
fi

# --- Fallback to POPCLIP_TEXT if no URLs were found via ANY HTML processing ---
if ! $found_via_html ; then
    if [[ -n "$POPCLIP_TEXT" ]]; then # Check if POPCLIP_TEXT is not empty
        echo "$POPCLIP_TEXT" | grep -Eo 'https?://[a-zA-Z0-9@:%.+~#?&//=_-]+' >> "$TMP_URL_FILE"
    fi
fi

# --- Process the collected URLs (if any) ---
if [[ -s "$TMP_URL_FILE" ]]; then # Check if the temp file has any content (from HTML or TEXT)
    sort -u "$TMP_URL_FILE" | while IFS= read -r url; do
        if [[ -n "$url" ]]; then # Ensure the line (URL) is not empty
            # Trim leading/trailing whitespace just in case
            trimmed_url=$(echo "$url" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            open "$trimmed_url"
        fi
    done
fi
#!/bin/bash

TEMP_DIR="/tmp"
CURRENT_WALLPAPER="$TEMP_DIR/current_wallpaper.png"
TEMP_WALLPAPER="$TEMP_DIR/temp_wallpaper.png"
CONFIG_FILE="./config.json"

while true; do
    # read config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$CONFIG_FILE not found"
        exit 1
    fi

    SOURCE=$(jq -r '.source' "$CONFIG_FILE")
    TAGS=$(jq -r '.tags' "$CONFIG_FILE")
    LIMIT=$(jq -r '.limit' "$CONFIG_FILE")
    DELAY=$(jq -r '.delay' "$CONFIG_FILE")
    SCREEN_RES=$(jq -r '.screen_resolution' "$CONFIG_FILE")
    YANDERE_USERNAME=$(jq -r '.yandere.username' "$CONFIG_FILE")
    YANDERE_API_KEY=$(jq -r '.yandere.api_key' "$CONFIG_FILE")
    DANBOORU_USERNAME=$(jq -r '.danbooru.username' "$CONFIG_FILE")
    DANBOORU_API_KEY=$(jq -r '.danbooru.api_key' "$CONFIG_FILE")
    GELBOORU_USER_ID=$(jq -r '.gelbooru.user_id' "$CONFIG_FILE")
    GELBOORU_API_KEY=$(jq -r '.gelbooru.api_key' "$CONFIG_FILE")

    if [[ "$SOURCE" == "g" ]]; then
        # Fetch the first page to get the total number of posts from Gelbooru
        response=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&tags=${TAGS}&limit=1&api_key=${GELBOORU_API_KEY}&user_id=${GELBOORU_USER_ID}")
        
        # Parse XML to get the total number of posts
        total_count=$(echo "$response" | xmllint --xpath "string(//posts/@count)" -)

        if [[ -z "$total_count" || "$total_count" == "0" ]]; then
            echo "Error getting total count from Gelbooru. Response: $response"
            sleep "$DELAY"
            continue
        fi

        # Calculate total pages (count / limit), round up to nearest integer
        pages=$(( (total_count + LIMIT - 1) / LIMIT ))

        # Random page selection between 0 and (pages - 1)
        pid=$((RANDOM % pages))
        response=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&tags=${TAGS}&limit=${LIMIT}&api_key=${GELBOORU_API_KEY}&user_id=${GELBOORU_USER_ID}&pid=${pid}")
        echo "Gelbooru: $pid/$pages"
        
        # Extract image URL from the XML response
        image_url=$(echo "$response" | xmllint --xpath "string(//post/file_url)" -)

        if [[ -z "$image_url" ]]; then
            echo "Error getting image from Gelbooru. Response: $response"
            sleep "$DELAY"
            continue
        fi

    elif [[ "$SOURCE" == "y" ]]; then
        # max page Yandere
        url="https://yande.re/post?tags=${TAGS}"
        page=$(curl -s "$url" | grep -oP '(?<=<a aria-label="Page )\d+' | tail -n 1)

        if [[ -z "$page" ]]; then
            echo "error max page for '$TAGS' on Yandere."
            sleep "$DELAY"
            continue
        fi

        # random page
        RANDOM_PAGE=$((RANDOM % page + 1))

        # get image Yandere
        response=$(curl -s "https://yande.re/post.json?tags=${TAGS}&limit=${LIMIT}&page=${RANDOM_PAGE}&login=${YANDERE_USERNAME}&api_key=${YANDERE_API_KEY}")
        image_url=$(echo "$response" | jq -r '.[0].file_url')

        if [[ -z "$image_url" ]]; then
            echo "error get image Yandere."
            sleep "$DELAY"
            continue
        fi

        echo "Yandere: $RANDOM_PAGE/$page"
    elif [[ "$SOURCE" == "d" ]]; then
        # random image Danbooru
        response=$(curl -s "https://danbooru.donmai.us/posts/random.json?tags=${TAGS}&login=${DANBOORU_USERNAME}&api_key=${DANBOORU_API_KEY}")
        
        if echo "$response" | jq -e 'has("error")' > /dev/null; then
            error_message=$(echo "$response" | jq -r '.error')
            echo "API error Danbooru: $error_message"
            sleep "$DELAY"
            continue
        fi

        # get image URL
        image_url=$(echo "$response" | jq -r '.file_url')

        if [[ -z "$image_url" ]]; then
            echo "error get image Danbooru."
            sleep "$DELAY"
            continue
        fi

    else
        echo "source error config. use 'y' Yandere, 'd' Danbooru or 'g' Gelbooru."
        exit 1
    fi

    echo "$image_url"
    wget -q -O "$TEMP_DIR/current_wallpaper" "$image_url"

    # check format and convert PNG
    mime_type=$(file --mime-type -b "$TEMP_DIR/current_wallpaper")
    if [[ "$mime_type" != "image/png" ]]; then
        convert "$TEMP_DIR/current_wallpaper" "$CURRENT_WALLPAPER"
    else
        mv "$TEMP_DIR/current_wallpaper" "$CURRENT_WALLPAPER"
    fi

    # ratio
    WALLPAPER_RES=$(identify -format "%wx%h" "$CURRENT_WALLPAPER")
    WALLPAPER_ASPECT=$(echo "$WALLPAPER_RES" | awk -Fx '{printf "%.2f", $1/$2}')
    SCREEN_ASPECT=$(echo "$SCREEN_RES" | awk -Fx '{printf "%.2f", $1/$2}')

    if [[ "$WALLPAPER_ASPECT" != "$SCREEN_ASPECT" ]]; then
        # blur bg
        convert "$CURRENT_WALLPAPER" -resize "$SCREEN_RES^" \
            -gravity center -crop "$SCREEN_RES"+0+0 +repage \
            -blur 0x10 "$TEMP_WALLPAPER"

        convert "$TEMP_WALLPAPER" \
            \( "$CURRENT_WALLPAPER" -resize "$SCREEN_RES" -gravity center \) \
            -composite "$CURRENT_WALLPAPER"
    fi

    # use swaybg
    pkill swaybg; swaybg -i "$CURRENT_WALLPAPER" -m fill &

    sleep "$DELAY"
done


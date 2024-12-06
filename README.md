# Random Wallpaper Changer Script

This Bash script automatically downloads random wallpapers from Yandere, Danbooru, or Gelbooru and sets them as your background using `swaybg`. The script allows you to specify tags, resolution, and other configurations via a JSON file.
Tested on Hyprland.

## Features
- Supports **Yandere**, **Danbooru**, and **Gelbooru** API for wallpaper downloads.
- Automatically adjusts wallpaper aspect ratio to fit your screen resolution.
- Periodically changes wallpapers based on a delay setting.
- Includes error handling for failed API requests or image downloads.
- Dynamically change tags in configuration without restarting the script.

## Requirements
The script requires the following packages and tools to work:

- **curl**: For making HTTP requests.
- **jq**: For parsing JSON responses.
- **wget**: For downloading image files.
- **imagemagick**: For image resizing, blurring, and compositing.
- **file**: For checking MIME types of downloaded images.
- **libxml2** (`xmllint`): For parsing XML responses from Gelbooru.
- **swaybg**: To set wallpapers in Sway or Hyprland.

### Installation
Install all required dependencies:
```bash
sudo pacman -S curl jq wget imagemagick file libxml2 swaybg
```

## Configuration
The script uses a `config.json` file for its configuration. Below is an example configuration file:

```json
{
  "source": "d",
  "tags": "tag1+tag2",
  "limit": 1,
  "delay": 10,
  "screen_resolution": "1920x1080",
  "yandere": {
    "username": "your_yandere_username",
    "api_key": "your_yandere_api_key"
  },
  "danbooru": {
    "username": "your_danbooru_username",
    "api_key": "your_danbooru_api_key"
  },
  "gelbooru": {
    "api_key": "your_gelbooru_api_key",
    "user_id": "your_gelbooru_user_id"
  }
}
```

### Configuration Parameters
- **`source`**: Choose the source for wallpapers:
  - `y` for Yandere
  - `d` for Danbooru
  - `g` for Gelbooru
- **`tags`**: Tags to search for wallpapers. Use `+` to separate multiple tags.
- **`limit`**: Number of wallpapers to fetch per request. (**DONT TOUCH THIS**)
- **`delay`**: Time in seconds between wallpaper changes.
- **`screen_resolution`**: Desired screen resolution (e.g., `1920x1080`).
- **`yandere.username` / `yandere.api_key`**: Your Yandere login credentials.
- **`danbooru.username` / `danbooru.api_key`**: Your Danbooru API credentials (for free account max 2 tags).
- **`gelbooru.api_key` / `gelbooru.user_id`**: Your Gelbooru API credentials.

## Usage
1. Clone or download the script to your system.
2. Set up a `config.json` file in the same directory as the script.
4. Run the script:
   ```bash
   ./wallpaper_changer.sh
   ```

## How It Works
1. The script reads the configuration from `config.json`.
2. It fetches a random wallpaper from the selected source (Yandere, Danbooru, or Gelbooru) based on the tags and other settings.
3. The image is downloaded and processed:
   - Resized to match the screen resolution.
   - Blurred background added if the aspect ratio doesn't match.
4. Sets the processed image as the background using `swaybg`.
5. Waits for the specified delay and repeats.

## Troubleshooting
- **Missing Dependencies**: Ensure all required tools are installed (`curl`, `jq`, `wget`, etc.).
- **Invalid API Credentials**: Verify your API keys and usernames in `config.json`.
- **Image Not Changing**: Check if the tags in your configuration return valid results.

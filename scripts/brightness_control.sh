#!/bin/bash

# Display device name (replace with your actual device name)
DEVICE="eDP-1"

# File to store current brightness
BRIGHTNESS_FILE="/tmp/current_brightness"

# Minimum and maximum brightness values
MIN=0.0
MAX=1.0

# Step for increasing/decreasing brightness
STEP=0.1

# Function to read current brightness
read_brightness() {
    if [ -f "$BRIGHTNESS_FILE" ]; then
        CURRENT=$(cat "$BRIGHTNESS_FILE")
    else
        CURRENT=$(xrandr --verbose | grep -i brightness | awk '{ print $2 }')
        echo "$CURRENT" > "$BRIGHTNESS_FILE"
    fi
}

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [inc|dec]"
    exit 1
fi

# Read current brightness
read_brightness

case $1 in
    inc)
        NEW=$(awk -v current="$CURRENT" -v step="$STEP" 'BEGIN { print current + step }')
        ;;
    dec)
        NEW=$(awk -v current="$CURRENT" -v step="$STEP" 'BEGIN { print current - step }')
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
esac

# Ensure the new brightness value is within bounds
if (( $(awk 'BEGIN {print ("'"$NEW"'" >= "'"$MIN"'")}') )) && \
   (( $(awk 'BEGIN {print ("'"$NEW"'" <= "'"$MAX"'")}') )); then
    echo "Setting new brightness $NEW"
    xrandr --output "$DEVICE" --brightness "$NEW"
    echo "$NEW" > "$BRIGHTNESS_FILE"
else
    echo "Brightness cannot be set beyond boundaries: [$MIN - $MAX]"
fi

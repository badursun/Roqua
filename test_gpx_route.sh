#!/bin/bash

# GPX Route Simulator for iOS Simulator
# Usage: ./test_gpx_route.sh <gpx_file> [delay_seconds]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <gpx_file> [delay_seconds]"
    echo "Available GPX files:"
    ls gpx_files/*.gpx
    exit 1
fi

GPX_FILE="$1"
DELAY="${2:-2}"  # Default 2 seconds delay

if [ ! -f "$GPX_FILE" ]; then
    echo "Error: GPX file '$GPX_FILE' not found"
    exit 1
fi

echo "🗺️  Starting GPX route simulation: $GPX_FILE"
echo "⏱️  Delay between points: ${DELAY}s"
echo "📱 Make sure iOS Simulator is running with Roqua app"
echo ""

# Extract coordinates from GPX file
COORDS=$(grep -o 'lat="[^"]*" lon="[^"]*"' "$GPX_FILE" | sed 's/lat="//g' | sed 's/" lon="/,/g' | sed 's/"//g')

POINT_COUNT=$(echo "$COORDS" | wc -l)
echo "📍 Found $POINT_COUNT waypoints in GPX file"
echo "🚀 Starting simulation in 3 seconds..."
sleep 3

CURRENT=1
echo "$COORDS" | while read -r coord; do
    if [ ! -z "$coord" ]; then
        echo "[$CURRENT/$POINT_COUNT] Setting location: $coord"
        xcrun simctl location booted set "$coord"
        
        if [ $CURRENT -lt $POINT_COUNT ]; then
            sleep $DELAY
        fi
        
        CURRENT=$((CURRENT + 1))
    fi
done

echo ""
echo "✅ GPX route simulation completed!"
echo "🌍 GridHashManager should have registered multiple new grids" 
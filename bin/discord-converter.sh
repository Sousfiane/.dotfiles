#!/bin/bash

INPUT="$1"
OUTPUT="${INPUT%.*}_discord.mp4"

TARGET_MB=18.5
AUDIO_BITRATE=96000

if [ -z "$INPUT" ]; then
    echo "Usage: $0 video.mp4"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "File not found: $INPUT"
    exit 1
fi

# Get duration
DURATION=$(ffprobe -v error \
    -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 \
    "$INPUT")

echo "Video: $INPUT"
echo "Duration: ${DURATION}s"
echo

# Calculate target bitrate
TARGET_BITS=$(awk "BEGIN {print $TARGET_MB * 1024 * 1024 * 8}")
TOTAL_BITRATE=$(awk "BEGIN {printf \"%d\", $TARGET_BITS / $DURATION}")
VIDEO_BITRATE=$((TOTAL_BITRATE - AUDIO_BITRATE))

echo "Target size: ${TARGET_MB} MB"
echo "Video bitrate: ${VIDEO_BITRATE} bps"
echo

# Encode
ffmpeg -y -i "$INPUT" \
    -c:v libx264 \
    -preset medium \
    -b:v "$VIDEO_BITRATE" \
    -pass 1 \
    -an \
    -f mp4 /dev/null

ffmpeg -y -i "$INPUT" \
    -c:v libx264 \
    -preset medium \
    -b:v "$VIDEO_BITRATE" \
    -pass 2 \
    -c:a aac \
    -b:a "$AUDIO_BITRATE" \
    -movflags +faststart \
    "$OUTPUT"

rm -f ffmpeg2pass-0.log ffmpeg2pass-0.log.mbtree

# Check actual size
SIZE=$(stat -c%s "$OUTPUT")
SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $SIZE / 1024 / 1024}")

echo
echo "Result: ${SIZE_MB} MB"

if [ "$SIZE" -gt $((20 * 1024 * 1024)) ]; then
    echo "Still over 20 MB!"
    echo "Re-encoding at lower bitrate..."

    # Reduce video bitrate by 15%
    VIDEO_BITRATE=$((VIDEO_BITRATE * 85 / 100))

    ffmpeg -y -i "$INPUT" \
        -c:v libx264 \
        -preset medium \
        -b:v "$VIDEO_BITRATE" \
        -pass 1 \
        -an \
        -f mp4 /dev/null

    ffmpeg -y -i "$INPUT" \
        -c:v libx264 \
        -preset medium \
        -b:v "$VIDEO_BITRATE" \
        -pass 2 \
        -c:a aac \
        -b:a "$AUDIO_BITRATE" \
        -movflags +faststart \
        "$OUTPUT"

    rm -f ffmpeg2pass-0.log ffmpeg2pass-0.log.mbtree

    SIZE=$(stat -c%s "$OUTPUT")
    SIZE_MB=$(awk "BEGIN {printf \"%.2f\", $SIZE / 1024 / 1024}")

    echo "Final size: ${SIZE_MB} MB"
fi

echo
echo "================================"
echo "Done: $OUTPUT"
echo "================================"

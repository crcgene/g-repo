#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CUSTOM_REPO=$(basename "$SCRIPT_DIR")

# Check if required tools are available
if ! command -v pacman &> /dev/null; then
    echo "Error: pacman not found. This script requires pacman"
    exit 1
fi
if ! command -v repo-add &> /dev/null; then
    echo "Error: repo-add not found. Install pacman-contrib"
    exit 1
fi
# Protect from being run in system dirs
case "$CUSTOM_REPO" in
    boot|root|var|usr|etc|mnt|opt|srv|"$USER") \
        echo "Error: can't run in current folder" && exit 1;;
esac
bash "$SCRIPT_DIR/copypkgs.sh"
bash "$SCRIPT_DIR/mkaurs.sh"




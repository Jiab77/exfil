# ExFil

Simple bash script to exfil data within a web service and OpenSSL or GPG.

## Inspirations

This project is based on the amazing work made by the [THC](https://thc.org/) group and their awesome [tips and tricks](https://github.com/hackerschoice/thc-tips-tricks-hacks-cheat-sheet) page.

## Config

Edit the script to set/change the defined web service.

> This feature will be implemented soon.

Here are the default options:

* Encryption: [AES-256-CBC](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Cipher_block_chaining_(CBC))
* Web Service: [transfer.sh](https://transfer.sh/)

## Usage

```console
$ ./exfil.sh -h

Usage: exfil.sh <file|folder> - Encrypt and send file or folder to 'transfer.sh'.

Arguments:
  -h | --help            Print this help message
  -s | --send            Encrypt and send file or folder to 'transfer.sh' (default)
  -d | --download        Download and decrypt file from 'transfer.sh'

Examples:
  * exfil.sh <file|folder>
  * exfil.sh -s <file|folder>
  * exfil.sh -d <url>

```

## Roadmap

* [X] Initial release
* [X] Folder support
* [X] `curl` / `wget` support
* [X] `openssl` support
* [ ] `gpg` support
* [ ] `tor` support

## Author

* __Jiab77__
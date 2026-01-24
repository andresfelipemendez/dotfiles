#!/bin/sh

set -e

info() {
        printf '\033[0;34m%s\033[0m\n' "$1"
}

info "testing the info function"

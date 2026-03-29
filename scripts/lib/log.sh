#!/bin/bash
# Logging helpers. Source this file; do not execute directly.

log() {
    local level=$1
    local message=$2
    echo ""
    case "$level" in
        INFO)  printf "\033[32m[INFO ] %s\033[0m\n" "$message" ;;
        WARN)  printf "\033[33m[WARN ] %s\033[0m\n" "$message" ;;
        ERROR) printf "\033[31m[ERROR] %s\033[0m\n" "$message" ;;
        *)     printf "[%s] %s\n" "$level" "$message" ;;
    esac
    echo ""
}

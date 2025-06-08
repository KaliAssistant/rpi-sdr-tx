#!/bin/bash

#set -e

MOUNT_POINT="/mnt/rpisdrtx"

echoerr() { echo "$@" 1>&2; }

usage() {
    echo "Usage: $0 [start|stop]" 
    exit 1
}

do_mkfiles() {
    mkdir -p "$MOUNT_POINT"/ws2812rpi_spi
    echo "auto" > "$MOUNT_POINT"/ws2812rpi_spi/ledmode
    echo "off" > "$MOUNT_POINT"/ws2812rpi_spi/status
    echo "#000000" > "$MOUNT_POINT"/ws2812rpi_spi/color888

    mkdir -p "$MOUNT_POINT"/rpiLgpio
    echo "basic" > "$MOUNT_POINT"/rpiLgpio/gpiomode
    echo "0" > "$MOUNT_POINT"/rpiLgpio/gpioctl
}

do_start() {
    [ ! -d $MOUNT_POINT ] && echoerr "E: $MOUNT_POINT does not exist. Please check rpisdrtx-mktmpdir.service and mnt-rpisdrtx.mount status." && exit 1 || true
#    exit 1

    do_mkfiles
    echo "Generate successfully."
}

do_stop() {
    echo "Cleaning up $MOUNT_POINT..."
    rm -rf "$MOUNT_POINT"/*
    echo "Done."
}

case "$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    *)
        usage
        ;;
esac

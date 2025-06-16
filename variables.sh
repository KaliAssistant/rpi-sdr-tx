#!/usr/bin/env bash

repo_dir="$(pwd)"

usb_serial=${usb_serial:-$(head -c 16 /dev/urandom | xxd -p -u | tr -d '\n')}

free_space="${free_space:-100}"

rndis_ipv4_address=${rndis_ipv4_address:-"172.16.48.1/24"}
rndis_ipv4_gateway=${rndis_ipv4_gateway:-"172.16.48.254"}
rndis_ipv4_dns=${rndis_ipv4_dns:-"1.1.1.1"}

mirror=${mirror:-"http://raspbian.raspberrypi.com/raspbian"}
suite=${suite:-"bookworm"}
components="main,contrib,non-free,rpi"

if [ -f "${repo_dir}"/builder.txt ]; then
    source "${repo_dir}"/builder.txt
fi

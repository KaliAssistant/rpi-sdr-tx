#!/usr/bin/env bash

RPI_SDR_TX_VERSION="v1.0.0"

repo_dir="$(pwd)"

base_dir="${repo_dir}/base"

work_dir="${base_dir}/working"

# Use 2025-05-13 raspbian armhf lite
RASPBIAN_DOWNLOAD_URL="https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2025-05-13/2025-05-13-raspios-bookworm-armhf-lite.img.xz"

# GPG signature
RASPBIAN_DOWNLOAD_SIG="${repo_dir}/img_sig/2025-05-13-raspios-bookworm-armhf-lite.img.xz.sig"

# raspberrypi official downloads gpg public key
RASPBIAN_DOWNLOAD_GPG_PBKEY="${repo_dir}/img_sig/54c3dd610d9d1b4af82a37758738cd6b956f460c.asc"

RASPBIAN_DOWNLOADED_IMAGE="${repo_dir}/downloads/raspios-bookworm-armhf-lite.img.xz"

RASPBIAN_DECOMPRESSED_IMAGE="${repo_dir}/downloads/raspios-bookworm-armhf-lite.img"

RASPBIAN_DECOMPRESSED_IMAGE_SHA256SUM="27afb17f14c525e8aa56ad78ae306d581f62bf2531a24752ce97e1696883dd64"

BASE_IMAGE="${base_dir}/base_image.img"



usb_serial=${usb_serial:-$(head -c 16 /dev/urandom | xxd -p -u | tr -d '\n')}

free_space="${free_space:-100}"

rndis_ipv4_address=${rndis_ipv4_address:-"172.16.48.1/24"}
rndis_ipv4_gateway=${rndis_ipv4_gateway:-"172.16.48.254"}
rndis_ipv4_dns=${rndis_ipv4_dns:-"1.1.1.1"}

mirror=${mirror:-"http://raspbian.raspberrypi.com/raspbian"}
restore_mirror=${restore_mirror:-"http://raspbian.raspberrypi.com/raspbian"}
suite=${suite:-"bookworm"}
components="main,contrib,non-free,rpi"

if [ -f "${repo_dir}"/builder.txt ]; then
    source "${repo_dir}"/builder.txt
fi

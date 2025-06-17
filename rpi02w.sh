#!/usr/bin/env bash

set -eE

source "$(pwd)/variables.sh"

if [ "$EUID" -ne 0 ]
  then echo -e "\e[1;31m[ABORT] Please run as root !\e[0m"
  exit 1
fi

do_trap_cleanup() {
    # Always try to finish cleanup even if something fails
    set +eE

    echo -e "\e[0;31m[ABORT] Caught a signal, cleaning up …\e[0m"
    sync
    for mp in dev/pts dev sys proc boot/firmware ''; do
        if mountpoint -q "$work_dir/$mp"; then
            umount -lf "$work_dir/$mp" 2>/dev/null || true
        fi
    done
    loop_device="$(losetup -j "$BASE_IMAGE" | cut -d':' -f1)"
    if [ -n "$loop_device" ]; then
        echo "Detaching loop device: $loop_device"
        losetup -d "$loop_device" 2>/dev/null || true
    fi
    echo -e "\e[0;32m[ABORT] Cleanup completed. Exiting.\e[0m"
    exit 1        # Use non‑zero so callers know it aborted
}

do_fail_cleanup() {
    # Always try to finish cleanup even if something fails
    set +eE
    echo -e "\e[1;31m[ERROR] ERROR: ($1) occurred on $2\e[0m"
    echo -e "\e[1;31m[ERROR] Build failed. Exiting...\e[0m"
    sync
    for mp in dev/pts dev sys proc boot/firmware ''; do
        if mountpoint -q "$work_dir/$mp"; then
            umount -lf "$work_dir/$mp" 2>/dev/null || true
        fi
    done
    loop_device="$(losetup -j "$BASE_IMAGE" | cut -d':' -f1)"
    if [ -n "$loop_device" ]; then
        echo "Detaching loop device: $loop_device"
        losetup -d "$loop_device" 2>/dev/null || true
    fi
    exit 1


}

trap do_trap_cleanup SIGINT SIGTERM
trap 'do_fail_cleanup $? $LINENO' ERR

do_init() {

echo -ne "\e[0;35m";
echo -e "    ____  ____  ____    _____ ____  ____      _______  __ ";
echo -e "   / __ \/ __ \/  _/   / ___// __ \/ __ \    /_  __| |/ / ";
echo -e "  / /_/ / /_/ // ______\__ \/ / / / /_/ ______/ /  |   /  ";
echo -e " / _, _/ _____/ /________/ / /_/ / _, _/_____/ /  /   |   ";
echo -e "/_/ |_/_/   /___/    /____/_____/_/ |_|     /_/  /_/|_|   ";
echo -e "                                                          ";
echo -e "--- Raspberry Pi Software Defined Radio * Transmit * ---\n";
echo -ne "\e[0;33m";
echo -e "Version 1.0 system image builder  By KaliAssistant <work.kaliassistant.github@gmail.com>\n";
echo -ne "\e[0m";
echo -e "Thanks to\e[0;36m F5OEO, linux-usb-gadgets, Mike McCauley, benhoyt\e[0m";
echo -e "\e[0;36m rpitx      -\e[0;34m https://github.com/F5OEO/rpitx\e[0m";
echo -e "\e[0;36m libusbgx   -\e[0;34m https://github.com/linux-usb-gadgets/libusbgx\e[0m"
echo -e "\e[0;36m gt         -\e[0;34m https://github.com/linux-usb-gadgets/gt\e[0m";
echo -e "\e[0;36m bcm2835    -\e[0;34m https://www.airspayce.com/mikem/bcm2835\e[0m";
echo -e "\e[0;36m inih       -\e[0;34m https://github.com/benhoyt/inih\e[0m";
echo -e "\n\e[0;32m[INFO]\e[1;37m Start Build script, need internet connection.\e[0m";
}

do_init_cleanup() {
    echo -e "\e[0;32m[INFO]\e[1;37m Init cleanup...\e[0m"
    trash_chksum_files=$(find "$base_dir" -name "*.sha256sum")
    trash_xz_files=$(find "$base_dir" -name "*.xz")
    trash_img_files=$(find "$base_dir" -name "*.img")

    [ ! -n "$trash_chksum_files" ] || rm -f $trash_chksum_files
    [ ! -n "$trash_xz_files" ] || rm -f $trash_xz_files
    [ ! -n "$trash_img_files" ] || rm -f $trash_img_files
}


do_apt_update() {
    echo -e "\e[0;32m[INFO]\e[1;37m Update APT && Install packages\e[0m"
    apt update 
    apt install -y git curl qemu-user qemu-user-static uuid-runtime pixz xz-utils xxd
}

do_download_raspbian() {
    echo -e "\e[0;32m[INFO]\e[1;37m Download raspbian image\e[0m"
    wget -O - "$RASPBIAN_DOWNLOAD_URL" > "$RASPBIAN_DOWNLOADED_IMAGE"
    echo -e "\e[0;32m[INFO\e[1;37m Verify Download...\e[0m"
    gpg --import "$RASPBIAN_DOWNLOAD_GPG_PBKEY"
    gpg --verify "$RASPBIAN_DOWNLOAD_SIG" "$RASPBIAN_DOWNLOADED_IMAGE"
    echo -e "\e[0;32m[INFO]\e[1;37m Decompress image file to base...\e[0m"
    xz -dfk "$RASPBIAN_DOWNLOADED_IMAGE"
    cp "$RASPBIAN_DECOMPRESSED_IMAGE" "$BASE_IMAGE"
}

do_dect_download_exists() {
    echo -e "\e[0;32m[INFO]\e[1;37m Check downloads folder...\e[0m"

    if [ -f "$RASPBIAN_DECOMPRESSED_IMAGE" ]; then
        echo -e "\e[0;32m[INFO]\e[1;37m Found Decompressed image!\e[0m"
        echo -e "\e[0;32m[INFO]\e[1;37m Verify Image...\e[0m"
        verify_shasum=$(sha256sum "$RASPBIAN_DECOMPRESSED_IMAGE" | awk -F' ' '{print $1}')
        [ "$verify_shasum" == "$RASPBIAN_DECOMPRESSED_IMAGE_SHA256SUM" ] || EXIST_DIMAGE_ERR_CHKSUM="ERROR"
        if [ -n "$EXIST_DIMAGE_ERR_CHKSUM" ]; then
            echo -e "\e[1;33m[WARN]\e[0;33m SHA256SUM NOT MATCH ! TRY COMPRESSED IMAGE...\e[0m"
            if [ -f "$RASPBIAN_DOWNLOADED_IMAGE" ]; then
                echo -e "\e[0;32m[INFO]\e[1;37m Found Downloaded image!\e[0m"
                echo -e "\e[0;32m[INFO]\e[1;37m Verify Image...\e[0m"
                gpg --import "$RASPBIAN_DOWNLOAD_GPG_PBKEY"
                gpg --verify "$RASPBIAN_DOWNLOAD_SIG" "$RASPBIAN_DOWNLOADED_IMAGE" || EXIST_IMAGE_GPG_ERROR="ERROR"
                if [ -n "$EXIST_IMAGE_GPG_ERROR" ]; then
                    echo -e "\e[1;33m[WARN]\e[0;33m GPG VERIFY RETURN NON-ZERO EXIT-CODE ! REDOWNLOAD THE IMAGE...\e[0m"
                    do_download_raspbian
                    return 0
                fi
                echo -e "\e[0;32m[INFO]\e[1;37m Decompress image file to base...\e[0m"
                xz -dfk "$RASPBIAN_DOWNLOADED_IMAGE"
                cp "$RASPBIAN_DECOMPRESSED_IMAGE" "$BASE_IMAGE"
                return 0
            fi
            echo -e "\e[0;32m[INFO]\e[1;37m Image not found...\e[0m"
            do_download_raspbian
            return 0
        fi
        echo -e "\e[0;32m[INFO]\e[1;37m Copy image file to base...\e[0m"
        cp "$RASPBIAN_DECOMPRESSED_IMAGE" "$BASE_IMAGE"
        return 0
        
    elif [ -f "$RASPBIAN_DOWNLOADED_IMAGE" ]; then
        echo -e "\e[0;32m[INFO]\e[1;37m Found Downloaded image!\e[0m"
        echo -e "\e[0;32m[INFO]\e[1;37m Verify Image...\e[0m"
        gpg --import "$RASPBIAN_DOWNLOAD_GPG_PBKEY"
        gpg --verify "$RASPBIAN_DOWNLOAD_SIG" "$RASPBIAN_DOWNLOADED_IMAGE" || EXIST_IMAGE_GPG_ERROR="ERROR"
        if [ -n "$EXIST_IMAGE_GPG_ERROR" ]; then
            echo -e "\e[1;33m[WARN]\e[0;33m GPG VERIFY RETURN NON-ZERO EXIT-CODE ! REDOWNLOAD THE IMAGE...\e[0m"
            do_download_raspbian
            return 0
        fi
        echo -e "\e[0;32m[INFO]\e[1;37m Decompress image file to base...\e[0m"
        xz -dfk "$RASPBIAN_DOWNLOADED_IMAGE"
        cp "$RASPBIAN_DECOMPRESSED_IMAGE" "$BASE_IMAGE"
        return 0
    else
        echo -e "\e[0;32m[INFO]\e[1;37m Image not found...\e[0m"
        do_download_raspbian
        return 0
    fi

}

do_resize_img_file() {
    echo -e "\e[0;32m[INFO]\e[1;37m Resize img file to 10G\e[0m"
    truncate -s 10G "$BASE_IMAGE"
}

do_chroot_to_working() {
    echo -e "\e[0;32m[INFO]\e[1;37m Chroot to work_dir\e[0m"

    echo -e "\e[0;32m[INFO]\e[1;37m Mount img to loop...\e[0m"
    loop_device=$(losetup -Pf --show "$BASE_IMAGE")
    
    # kpartx -v -a "${REPO_PWD}/base/base_image.img" || do_failexit
    #loop_device=`losetup --list | grep "${REPO_PWD}/base/base_image.img" | cut -d ' ' -f1 | cut -d'/' -f3`
    mapper_loop_device="${loop_device}p"

    echo -e "\e[0;32m[INFO]\e[1;37m Resize rootfs part...\e[0m"
    
    parted --script "${loop_device}"  "resizepart 2 -1s"
    # kpartx -d "${REPO_PWD}/base/base_image.img" || do_failexit
    # kpartx -v -a "${REPO_PWD}/base/base_image.img" || do_failexit

    losetup -d "$loop_device"

    loop_device=$(losetup -Pf --show "$BASE_IMAGE")

    # loop_device=`losetup --list | grep "${REPO_PWD}/base/base_image.img" | cut -d ' ' -f1 | cut -d'/' -f3`
    mapper_loop_device="${loop_device}p"

    echo -e "\e[0;32m[INFO]\e[1;37m Remount img and check filesystem...\e[0m"

    e2fsck -f ${mapper_loop_device}2
    resize2fs ${mapper_loop_device}2
    mount -o rw ${mapper_loop_device}2 "$work_dir"
    mount -o rw ${mapper_loop_device}1 "${work_dir}/boot/firmware"
    
    echo -e "\e[0;32m[INFO]\e[1;37m Bind dymfs to workdir...\e[0m"

    mount --bind /dev "${work_dir}/dev"
    mount --bind /sys "${work_dir}/sys"
    mount --bind /proc "${work_dir}/proc"
    mount --bind /dev/pts "${work_dir}/dev/pts"

    echo -e "\e[0;32m[INFO]\e[1;37m Generate rpi-sdr-tx install script variables to chroot...\e[0m"
    cat <<EOF >"${work_dir}"/opt/install_rpisdrtx_var.sh
usb_serial=${usb_serial}
nm_addr1=${rndis_ipv4_address},${rndis_ipv4_gateway}
nm_dns=${rndis_ipv4_dns}
EOF

    echo -e "\e[0;32m[INFO]\e[1;37m Generate rpi-sdr-tx install script to chroot...\e[0m"
    cat << 'EOF' > "${work_dir}"/opt/install_rpisdrtx.sh
#!/usr/bin/env bash
set -e

source /opt/install_rpisdrtx_var.sh

apt update && apt -y upgrade
apt install -y git bc cmake pkg-config libconfig-dev autoconf m4 libtool ffmpeg sox libsox-dev libsox-fmt-all uuid-runtime

REPO_PWD="/usr/local/src/rpi-sdr-tx"

git clone https://github.com/KaliAssistant/rpi-sdr-tx.git -b dev "$REPO_PWD"
cd "$REPO_PWD"
git submodule update --init
cd "${REPO_PWD}/rpitx"
./install.sh
cd "${REPO_PWD}/ws2812rpi_spi"
make -j $(nproc)
cp ./bin/ws2812rpi_spi ./bin/ws2812rpi_pipe /usr/local/bin
cd "${REPO_PWD}/libusbgx"
aclocal
autoconf
libtoolize --copy --force --automake
if [ -f "${REPO_PWD}/ltmain.sh" ] && [ ! -f ltmain.sh ]; then
    mv "${REPO_PWD}/ltmain.sh" .
fi

automake --add-missing --copy
./configure
make -j $(nproc) && make install

cd "${REPO_PWD}/gt/source"
mkdir build && cd build
cmake ..
make -j $(nproc)
make install

cd "${REPO_PWD}/src/systemd"
cp ./rpi-gentmpfs.sh /usr/local/bin
cp ./mnt-rpisdrtx.mount ./rpisdrtx-gentmpfs.service ./rpisdrtx-mktmpdir.service ./rpisdrtx-ws2812rpi_spi.service ./rpisdrtx-usb-gadget.service /etc/systemd/system

systemctl enable mnt-rpisdrtx.mount rpisdrtx-gentmpfs.service rpisdrtx-mktmpdir.service rpisdrtx-ws2812rpi_spi.service rpisdrtx-usb-gadget.service

sed -i '/ENV{DEVTYPE}=="gadget", *ENV{NM_UNMANAGED}="1"/s/^/# /' /usr/lib/udev/rules.d/85-nm-unmanaged.rules

cd "${REPO_PWD}/src/usb-gadget"

SERIAL=${usb_serial}

sed -i "s/serialnumber = \".*\";/serialnumber = \"${SERIAL}\";/" rpi-sdr-tx.scheme

mkdir -p /usr/local/share/gt && cp rpi-sdr-tx.scheme /usr/local/share/gt
cd "${REPO_PWD}/src/conf.d"
cp ws2812rpi_spi.conf /etc


# Create NetworkManager profile — UUID will be generated *at runtime*
cat > /etc/NetworkManager/system-connections/USB0.nmconnection <<NMCONF
[connection]
id=USB0
uuid=$(uuidgen)
type=ethernet
interface-name=usb0
autoconnect=true

[ipv4]
address1=${nm_addr1}
dns=${nm_dns};
method=manual

[ipv6]
addr-gen-mode=default
method=auto
NMCONF

chmod 600 /etc/NetworkManager/system-connections/USB0.nmconnection

grep -q 'dwc_otg.lpm_enable=0' /boot/firmware/cmdline.txt || sed -i 's/$/ dwc_otg.lpm_enable=0/' /boot/firmware/cmdline.txt
grep -q 'modules-load=dwc2,libcomposite' /boot/firmware/cmdline.txt || sed -i 's/$/ modules-load=dwc2,libcomposite/' /boot/firmware/cmdline.txt

grep -qF 'dtoverlay=dwc2,dr_mode=peripheral' /boot/firmware/config.txt || echo "dtoverlay=dwc2,dr_mode=peripheral" | tee --append /boot/firmware/config.txt

ldconfig

EOF
    
    echo -e "\e[0;32m[INFO]\e[1;37m Replace apt source...\e[0m"
    cat <<EOF >"${work_dir}/etc/apt/sources.list"
deb [ arch=armhf ] ${mirror} ${suite} ${components//,/ }
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
#deb-src ${mirror} ${suite} ${components//,/ }
EOF

    echo -e "\e[0;32m[INFO]\e[1;37m Run install script in chroot...\e[0m"

    chroot "$work_dir" /bin/bash -c "/bin/bash /opt/install_rpisdrtx.sh"

    echo -e "\e[0;32m[INFO]\e[1;37m Remove chroot Install script...\e[0m"
    chroot "$work_dir" /bin/bash -c "/bin/rm -f /opt/install_rpisdrtx.sh /opt/install_rpisdrtx_var.sh"

    echo -e "\e[0;32m[INFO]\e[1;37m Restore apt source...\e[0m"
    cat <<EOF >"${work_dir}/etc/apt/sources.list"
deb [ arch=armhf ] ${restore_mirror} ${suite} ${components//,/ }
# Uncomment line below then 'apt-get update' to enable 'apt-get source'
#deb-src ${restore_mirror} ${suite} ${components//,/ }
EOF

    echo -e "\e[0;32m[INFO]\e[1;37m Build success! cleanup and umount img file...\e[0m"

    umount "$work_dir"/{dev/pts,dev,sys,proc,boot/firmware,}
    losetup -d "$loop_device"
}

do_minsize_imgfile() {
    echo -e "\e[0;32m[INFO]\e[1;37m Resize build imgage to MIN_SIZE\e[0m"

    loop_device=$(losetup -Pf --show "$BASE_IMAGE")
    
    ROOT_PART="${loop_device}p2"

    EXTRA_MB=$((free_space))
    # Calculate minimum size
    MIN_SIZE=$(resize2fs -P "$ROOT_PART" | awk '{print $NF}')
    ADD_BLOCKS=$(( EXTRA_MB * 1024 * 1024 / 4096 ))
    NEW_SIZE=$(( MIN_SIZE + ADD_BLOCKS ))

    # Resize filesystem
    resize2fs "$ROOT_PART" "$NEW_SIZE"

    # Get original start sector of rootfs partition
    START_SECTOR=$(fdisk -l "$BASE_IMAGE" | awk '/Linux/ {print $2}')
    SECTOR_SIZE=$(fdisk -l "$BASE_IMAGE" | awk '/Units:/ {print $8}')

    # Detach loop to use parted
    losetup -d "$loop_device"

    # Resize partition table
    parted "$BASE_IMAGE" ---pretend-input-tty <<EOF
unit s
resizepart 2 $(( START_SECTOR + NEW_SIZE * 8 - 1 ))
Yes
quit
EOF

    # Reattach and do a final resize to fill partition
    loop_device=$(losetup -Pf --show "$BASE_IMAGE")
    ROOT_PART="${loop_device}p2"
    resize2fs "$ROOT_PART"
    losetup -d "$loop_device"

    # Truncate image to end of partition
    END_OFFSET=$(( (START_SECTOR + NEW_SIZE * 8) * SECTOR_SIZE ))
    truncate -s "$END_OFFSET" "$BASE_IMAGE"
}

do_xz_compress() {
    echo -e "\e[0;32m[INFO]\e[1;37m Generate base image sha256sum...\e[0m"
    raw_img_sha256sum=$(sha256sum "$BASE_IMAGE" | awk -F' ' '{print $1}')
    echo -e "\e[0;32m[INFO]\e[1;37m Running XZ Compress...\e[0m"
    pixz -p `nproc` "$BASE_IMAGE"
    img="${BASE_IMAGE}.xz"

    chmod 0644 "$img"

    echo -e "\e[0;32m[INFO]\e[1;37m Generate sha256sum: $img"
    xz_img_sha256sum=$(sha256sum "$img" | awk -F' ' '{print $1}')

    mkdir -p "${repo_dir}/build-image"
    BUILD_TIME="$(date +%F_%H-%M-%S)"

    raw_img_name="${BUILD_TIME}_rpi-sdr-tx_pi02w_armhf.img"
    img_name="${raw_img_name}.xz"
    cp "$img" "${repo_dir}/build-image/${img_name}"

    echo "${raw_img_sha256sum}  ${raw_img_name}" > "${repo_dir}/build-image/${raw_img_name}.sha256sum"
    echo "${xz_img_sha256sum}  ${img_name}" > "${repo_dir}/build-image/${img_name}.sha256sum"

    echo -e "\e[0;32m[INFO]\e[1;37m All done! Your image is ${repo_dir}/build-image/${img_name} Have a nice day!\e[0m"
}


do_init
do_init_cleanup
do_apt_update
do_dect_download_exists
do_resize_img_file
do_chroot_to_working
do_minsize_imgfile
do_xz_compress

exit 0


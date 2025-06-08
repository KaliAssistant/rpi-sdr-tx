#!/bin/bash

REPO_PWD=`pwd`

do_init() {
    
echo "    ____  ____  ____    _____ ____  ____      _______  __ ";
echo "   / __ \/ __ \/  _/   / ___// __ \/ __ \    /_  __| |/ / ";
echo "  / /_/ / /_/ // ______\__ \/ / / / /_/ ______/ /  |   /  ";
echo " / _, _/ _____/ /________/ / /_/ / _, _/_____/ /  /   |   ";
echo "/_/ |_/_/   /___/    /____/_____/_/ |_|     /_/  /_/|_|   ";
echo "                                                          ";
echo "--- Raspberry Pi Software Defined Radio * Transmit * ---\n";

echo "Version 1.0 By KaliAssistant <work.kaliassistant.github@gmail.com>\n";
echo "Thanks to F5OEO, linux-usb-gadgets, Mike McCauley, benhoyt";
echo "rpitx   - https://github.com/F5OEO/rpitx";
echo "gt      - https://github.com/linux-usb-gadgets/gt";
echo "bcm2835 - https://www.airspayce.com/mikem/bcm2835";
echo "inih    - https://github.com/benhoyt/inih";
echo "\n[INFO] Start Installation, need internet connection.";
}

do_failexit() {
    echo "[ERROR] Installation failed. Exiting..."
    exit 1
}

do_apt_update() {
    echo "[INFO] Update APT && Install packages"
    sudo apt update || do_failexit
    sudo apt install -y git bc cmake pkg-config libconfig-dev libusbgx-dev || do_failexit
}

do_git_submodule_update() {
    echo "[INFO] Update git submodules"
    cd "$REPO_PWD" || do_failexit
    git submodule update --init || do_failexit
}

do_install_rpitx() {
    echo "[INFO] Build and install rpitx"
    cd "$REPO_PWD"/rpitx || do_failexit
    make || do_failexit
    sudo make install || do_failexit
}

do_install_ws2812rpi_spi() {
    echo "[INFO] Build and install ws2812rpi_spi"
    cd "$REPO_PWD"/ws2812rpi_spi || do_failexit
    ./build.sh || do_failexit
    sudo cp ./bin/ws2812rpi_spi ./bin/ws2812rpi_pipe /usr/local/bin || do_failexit
}

do_install_gt() {
    echo "[INFO] Build and install gt"
    cd "$REPO_PWD"/gt/source || do_failexit
    mkdir build && cd build || do_failexit
    cmake .. || do_failexit
    make || do_failexit
    sudo make install || do_failexit
}

do_enable_systemd_service() {
    echo "[INFO] Install systemd services"
    cd "$REPO_PWD"/src/systemd || do_failexit
    sudo cp ./rpi-gentmpfs.sh /usr/local/bin || do_failexit
    sudo cp ./mnt-rpisdrtx.mount ./rpisdrtx-gentmpfs.service ./rpisdrtx-mktmpdir.service ./rpisdrtx-ws2812rpi_spi.service ./rpisdrtx-usb-gadget.service /etc/systemd/system || do_failexit
    sudo systemctl enable mnt-rpisdrtx.mount rpisdrtx-gentmpfs.service rpisdrtx-mktmpdir.service rpisdrtx-ws2812rpi_spi.service rpisdrtx-usb-gadget.service || do_failexit
}

do_modify_nm_udev_rules() {
    echo "[INFO] Modify NetworkManager udev rules"
    sudo sed -i '/ENV{DEVTYPE}=="gadget", *ENV{NM_UNMANAGED}="1"/s/^/# /' /usr/lib/udev/rules.d/85-nm-unmanaged.rules || do_failexit
}

do_copy_configs() {
    echo "[INFO] Copy configs to system dir"
    cd "$REPO_PWD"/src/usb-gadget || do_failexit
    sudo mkdir -p /usr/local/share/gt && sudo cp rpi-sdr-tx.scheme /usr/local/share/gt || do_failexit
    cd "$REPO_PWD"/src/conf.d || do_failexit
    sudo cp ws2812rpi_spi.conf /etc || do_failexit
}

do_nmcli_add_usb_conn() {
    echo "[INFO] Add usb0 to NetworkManager system connections"
    sudo nmcli con add con-name USB0 type ethernet ifname usb0 ipv4.method manual ipv4.address 172.16.48.1/24 ipv4.gateway 172.16.48.254 || do_failexit
}

do_modify_boot_cmdline_config() {
    echo "[INFO] Modify cmdline and config.txt to enable usb-gadget"
    echo "\n"
    echo -n "[WARN] To enable usb-gadget, rpi-sdr-tx need to modify /boot/firmware/config.txt and /boot/firmware/cmdline.txt. Are you sure (y/n) "
    read -r USERINPUT
    if [ "$USERINPUT" = "y" ]; then
        echo "[INFO] Add dwc_otg.lpm_enable=0 modules-load=dwc2,libcomposite to /boot/firmware/cmdline.txt"
        grep -q 'dwc_otg.lpm_enable=0' /boot/firmware/cmdline.txt || \
        sudo sed -i 's/$/ dwc_otg.lpm_enable=0/' /boot/firmware/cmdline.txt || do_failexit
        grep -q 'modules-load=dwc2,libcomposite' /boot/firmware/cmdline.txt || \
        sudo sed -i 's/$/ modules-load=dwc2,libcomposite/' /boot/firmware/cmdline.txt || do_failexit

        echo "[INFO] Add dtoverlay=dwc2,dr_mode=peripheral to /boot/firmware/config.txt"

        grep -qF 'dtoverlay=dwc2,dr_mode=peripheral' /boot/firmware/config.txt || echo "dtoverlay=dwc2,dr_mode=peripheral" | sudo tee --append /boot/firmware/config.txt || do_failexit
    else
        echo "[ABORT] Cannot modify boot config, installation abort..."
        do_failexit
    fi
}

do_finish_install() {
    echo "[INFO] Installation completed. You should reboot now."
    echo "[NOTE] Add address 172.16.48.254/24, no gateway (or self 172.16.48.254) to your computer, you should can ssh to the rpi-sdr-tx via USB. Enjoy!"
}


do_init
do_apt_update
do_git_submodule_update
do_install_rpitx
do_install_ws2812rpi_spi
do_install_gt
do_enable_systemd_service
do_modify_nm_udev_rules
do_copy_configs
do_nmcli_add_usb_conn
do_modify_boot_cmdline_config
do_finish_install
exit 0

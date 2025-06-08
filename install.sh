#!/bin/bash

REPO_PWD=`pwd`

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
echo -e "Version 1.0 By KaliAssistant <work.kaliassistant.github@gmail.com>\n";
echo -ne "\e[0m";
echo -e "Thanks to\e[0;36m F5OEO, linux-usb-gadgets, Mike McCauley, benhoyt\e[0m";
echo -e "\e[0;36m rpitx      -\e[0;34m https://github.com/F5OEO/rpitx\e[0m";
echo -e "\e[0;36m libusbgx   -\e[0;34m https://github.com/linux-usb-gadgets/libusbgx\e[0m"
echo -e "\e[0;36m gt         -\e[0;34m https://github.com/linux-usb-gadgets/gt\e[0m";
echo -e "\e[0;36m bcm2835    -\e[0;34m https://www.airspayce.com/mikem/bcm2835\e[0m";
echo -e "\e[0;36m inih       -\e[0;34m https://github.com/benhoyt/inih\e[0m";
echo -e "\n\e[0;32m[INFO]\e[1;37m Start Installation, need internet connection.\e[0m";
}

do_failexit() {
    echo -e "\e[1;31m[ERROR] Installation failed. Exiting...\e[0m"
    exit 1
}

do_apt_update() {
    echo -e "\e[0;32m[INFO]\e[1;37m Update APT && Install packages\e[0m"
    sudo apt update || do_failexit
    sudo apt install -y git bc cmake pkg-config libconfig-dev autoconf m4 libtool || do_failexit
}

do_git_submodule_update() {
    echo -e "\e[0;32m[INFO]\e[1;37m Update git submodules\e[0m"
    cd "$REPO_PWD" || do_failexit
    git submodule update --init || do_failexit
}

do_install_rpitx() {
    echo -e "\e[0;32m[INFO]\e[1;37m Build and install rpitx\e[0m"
    cd "$REPO_PWD"/rpitx || do_failexit
    ./install.sh
}

do_install_ws2812rpi_spi() {
    echo -e "\e[0;32m[INFO]\e[1;37m Build and install ws2812rpi_spi\e[0m"
    cd "$REPO_PWD"/ws2812rpi_spi || do_failexit
    ./build.sh || do_failexit
    sudo cp ./bin/ws2812rpi_spi ./bin/ws2812rpi_pipe /usr/local/bin || do_failexit
}

do_install_libusbgx() {
    echo -e "\e[0;32m[INFO]\e[1;37m Build and install libusbgx(patch)\e[0m"
    cd "$REPO_PWD"/libusbgx || do_failexit

    # autoreconf -i # automake issues: https://github.com/libvips/libvips/issues/305#issuecomment-111844678
    aclocal || do_failexit
    autoconf || do_failexit
    libtoolize --copy --force --automake || do_failexit

    # Move ltmain.sh if libtoolize placed it in the wrong directory
    if [ -f "$REPO_PWD/ltmain.sh" ] && [ ! -f ltmain.sh ]; then
        echo -e "\e[0;32m[INFO]\e[1;37m Moving ltmain.sh to libusbgx/\e[0m"
        mv "$REPO_PWD/ltmain.sh" .
    fi

    automake --add-missing --copy || do_failexit
    ./configure || do_failexit
    make && sudo make install || do_failexit
}


do_install_gt() {
    echo -e "\e[0;32m[INFO]\e[1;37m Build and install gt\e[0m"
    cd "$REPO_PWD"/gt/source || do_failexit
    mkdir build && cd build || do_failexit
    cmake .. || do_failexit
    make || do_failexit
    sudo make install || do_failexit
}

do_enable_systemd_service() {
    echo -e "\e[0;32m[INFO]\e[1;37m Install systemd services\e[0m"
    cd "$REPO_PWD"/src/systemd || do_failexit
    sudo cp ./rpi-gentmpfs.sh /usr/local/bin || do_failexit
    sudo cp ./mnt-rpisdrtx.mount ./rpisdrtx-gentmpfs.service ./rpisdrtx-mktmpdir.service ./rpisdrtx-ws2812rpi_spi.service ./rpisdrtx-usb-gadget.service /etc/systemd/system || do_failexit
    sudo systemctl daemon-reload || do_failexit
    sudo systemctl enable mnt-rpisdrtx.mount rpisdrtx-gentmpfs.service rpisdrtx-mktmpdir.service rpisdrtx-ws2812rpi_spi.service rpisdrtx-usb-gadget.service || do_failexit
}

do_modify_nm_udev_rules() {
    echo -e "\e[0;32m[INFO]\e[1;37m Modify NetworkManager udev rules\e[0m"
    sudo sed -i '/ENV{DEVTYPE}=="gadget", *ENV{NM_UNMANAGED}="1"/s/^/# /' /usr/lib/udev/rules.d/85-nm-unmanaged.rules || do_failexit
}

do_copy_configs() {
    echo -e "\e[0;32m[INFO]\e[1;37m Copy configs to system dir\e[0m"
    cd "$REPO_PWD"/src/usb-gadget || do_failexit
    sudo mkdir -p /usr/local/share/gt && sudo cp rpi-sdr-tx.scheme /usr/local/share/gt || do_failexit
    cd "$REPO_PWD"/src/conf.d || do_failexit
    sudo cp ws2812rpi_spi.conf /etc || do_failexit
}

do_nmcli_add_usb_conn() {
    echo -e "\e[0;32m[INFO]\e[1;37m Add usb0 to NetworkManager system connections\e[0m"
    sudo nmcli con add con-name USB0 type ethernet ifname usb0 ipv4.method manual ipv4.address 172.16.48.1/24 ipv4.gateway 172.16.48.254 || do_failexit
}

do_modify_boot_cmdline_config() {
    echo -e "\e[0;32m[INFO]\e[1;37m Modify cmdline and config.txt to enable usb-gadget\e[0m"
    echo "\n"
    echo -ne "\e[1;33m[WARN]\e[0;33m To enable usb-gadget, rpi-sdr-tx need to modify /boot/firmware/config.txt and /boot/firmware/cmdline.txt. Are you sure (y/n) \e[0m"
    read -r USERINPUT
    if [ "$USERINPUT" = "y" ]; then
        echo -e "\e[0;32m[INFO]\e[1;37m Add dwc_otg.lpm_enable=0 modules-load=dwc2,libcomposite to /boot/firmware/cmdline.txt\e[0m"
        grep -q 'dwc_otg.lpm_enable=0' /boot/firmware/cmdline.txt || \
        sudo sed -i 's/$/ dwc_otg.lpm_enable=0/' /boot/firmware/cmdline.txt || do_failexit
        grep -q 'modules-load=dwc2,libcomposite' /boot/firmware/cmdline.txt || \
        sudo sed -i 's/$/ modules-load=dwc2,libcomposite/' /boot/firmware/cmdline.txt || do_failexit

        echo -e "\e[0;32m[INFO]\e[1;37m Add dtoverlay=dwc2,dr_mode=peripheral to /boot/firmware/config.txt\e[0m"

        grep -qF 'dtoverlay=dwc2,dr_mode=peripheral' /boot/firmware/config.txt || echo "dtoverlay=dwc2,dr_mode=peripheral" | sudo tee --append /boot/firmware/config.txt || do_failexit
    else
        echo -e "\e[0;31m[ABORT] Cannot modify boot config, installation abort...\e[0m"
        do_failexit
    fi
}

do_finish_install() {
    echo -e "\e[0;32m[INFO]\e[1;37m Installation completed. You should reboot now.\e[0m"
    echo -e "\e[1;36m[NOTE]\e[0;36m Add address 172.16.48.254/24, no gateway (or self 172.16.48.254) to your computer, you should can ssh to the rpi-sdr-tx via USB. Enjoy!\e[0m"
}


do_init
do_apt_update
do_git_submodule_update
do_install_rpitx
do_install_ws2812rpi_spi
do_install_libusbgx
do_install_gt
do_enable_systemd_service
do_modify_nm_udev_rules
do_copy_configs
do_nmcli_add_usb_conn
do_modify_boot_cmdline_config
do_finish_install
exit 0


### NOTE
if the NetworkManager always set USB0 unmanaged, enter this command to modify udev rules.

`sudo sed -i '/ENV{DEVTYPE}=="gadget", *ENV{NM_UNMANAGED}="1"/s/^/# /' /usr/lib/udev/rules.d/85-nm-unmanaged.rules`

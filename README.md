# rpi-sdr-tx
#### Raspberry Pi Software Defined Radio for Trasmit

## abuot rpi-sdr-tx

**rpitx** is a general radio frequency transmitter for Raspberry Pi which doesn't require any other hardware unless filter to avoid intererence. It can handle frequencies from 5 KHz up to 1500 MHz.

Rpitx is  a software made for educational on RF system. It has not been tested for compliance with regulations governing transmission of radio signals. You are responsible for using your Raspberry Pi legally.

This repository **rpi-sdr-tx** is included **rpitx**, **usb-gadget**, **image build script**, **3DP cases** ...etc, the build image released on github. see [release](https://github.com/KaliAssistant/rpi-sdr-tx/releases)


## Assembly
- Raspberry pi zero 2w PCB
  
<img src="./doc/IMG_6132.JPG.modified.jpeg"> 
<img src="./doc/IMG_6133.JPG.modified.jpeg">

<img src="./doc/IMG_6143.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_6144.JPG.modified.jpeg" width="400">

<img src="./doc/IMG_6145.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_6146.JPG.modified.jpeg" width="400">

<img src="./doc/IMG_6149.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_6150.JPG.modified.jpeg" width="400">

<img src="./doc/IMG_6151.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_6152.JPG.modified.jpeg" width="400">

<img src="./doc/IMG_6153.JPG.modified.jpeg">
<img src="./doc/IMG_E6198.JPG.modified.jpeg">

<img src="./doc/IMG_E6199.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_E6200.JPG.modified.jpeg" width="400">

<img src="./doc/IMG_E6201.JPG.modified.jpeg" width="400"> <img src="./doc/IMG_E6202.JPG.modified.jpeg" width="400">

### Cirucit
![](./doc/RPI-SDR-TX.svg)


### 3DP/PCB
- PETG BLACK (Recommend)

- usb-c female connector:
  - https://de.aliexpress.com/item/1005005262209302.html?gatewayAdapt=glo2deu
- m2 & m2.5 heat screw inserts
  - https://a.co/d/90MZVNr
- m2 & m2.5 Hex Socket Bolt Countersunk Flat Head Screws 
  - https://a.co/d/fhqFaUB
- ws2812b RGB led
  - https://a.co/d/iXdWQLz
- SMA female PCB side connector
  - https://a.co/d/1QsP954

## Install 
1. Burn Raspbian Bookworm Lite __armhf (32bit)__ to SD card, the rpitx only support 32 bit now. Remember Add your wifi connection config, we need ssh to pi after boot.

![](./doc/2025-06-09_21-12-25.png)

2. Run `sudo apt update && sudo apt -y full-upgrade` and reboot again.

3. Install git `sudo apt install git` and clone this repository `git clone https://github.com/KaliAssistant/rpi-sdr-tx.git`

4. cd to repository `cd rpi-sdr-tx` and run install script `./install.sh` .

5. If install script ask for anything, just enter `y` .

6. When installation completed, script will reboot device, you will see RNDIS ethernet on your NetworkManager. just add `172.16.48.254/24` with no gateway to your computer NetworkManager, and you can `ssh <user>@172.16.48.1` via RNDIS/USB-ETHERNET to your pi. Now you can run rpitx or anything else with your rpi-sdr-tx.

#### Install speedrun

https://github.com/user-attachments/assets/191871f1-86b6-43fb-9782-dcf97c5af731

## Build rpi-sdr-tx image
If you want self build your image file, you can switch to __builder__ branch.

1. Create a __debian / Ubuntu / kali (debian based)__ VM or Docker for build environment. I am using VMware.

2. Clone this repository builder branch `git clone https://github.com/Kaliassistant/rpi-sdr-tx.git -b builder`

![](./doc/Frame-04029.png)


3. cd to repository `cd rpi-sdr-tx` and `cp ./builder.txt.example ./builder.txt` then modify `builder.txt` to change `mirror`, `usb_serial`... etc.

4. run `./rpi02w.sh` as __root__ , script will auto update and download packages

![](./doc/Frame-08963.png)

5. Scripts may take up to ~1 hour to complete. ☕ Grab a coffee (or anything)

6. If build success, the build images and checksum all in the `./build-image/`

![](./doc/Shotcut_00_00_04_000.jpg)

7. Use __rpi-imager (recommend)__ or __balenaEther__ to burn the build image. If you are using rpi-imager, you can change your username, password, wifi settings, ssh...etc.

![](./doc/2025-06-15_10-09-49.png)

![](./doc/2025-06-15_10-10-14.png)

![](./doc/2025-06-15_10-10-35.png)

8. RaspberryPi zero 2w first boot will auto resize SD card part2 and rootfs, so it will reboot again. If you have not add wifi settings, remember add `172.16.48.254` with no gateway (or self) to your computer NetworkManager, and than you can ssh to pi via USB RNDIS/ethernet.
 
https://github.com/user-attachments/assets/7944fcf1-dfa4-4d31-8bf7-d2fa6b348df9


 #### Build speedrun

https://github.com/user-attachments/assets/0cf1e91f-3009-4e01-9d99-45d8bbc2cdbd


## Audio Test
#### rpi-sdr-tx audio files test 
##### [FULL VIDEO ON YOUTUBE](https://www.youtube.com/watch?v=e7_sDhkGPY4) (VOLUME WARNING)
[![FULL VIDEO](https://img.youtube.com/vi/e7_sDhkGPY4/0.jpg)](https://www.youtube.com/watch?v=e7_sDhkGPY4)


https://github.com/user-attachments/assets/4219b572-6db6-4b58-8dff-92a529460f64




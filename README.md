# rpi-sdr-tx
Raspberry Pi Software Defined Radio for Trasmit

## Assembly
- Raspberry pi zero 2w PCB
  
<img src="./doc/IMG_6132.JPG.modified.jpeg"> 
<img src="./doc/IMG_6133.JPG.modified.jpeg">

<img src="./doc/IMG_6143.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_6144.JPG.modified.jpeg" width="500">

<img src="./doc/IMG_6145.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_6146.JPG.modified.jpeg" width="500">

<img src="./doc/IMG_6149.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_6150.JPG.modified.jpeg" width="500">

<img src="./doc/IMG_6151.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_6152.JPG.modified.jpeg" width="500">

<img src="./doc/IMG_6153.JPG.modified.jpeg">
<img src="./doc/IMG_E6198.JPG.modified.jpeg">

<img src="./doc/IMG_E6199.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_E6200.JPG.modified.jpeg" width="500">

<img src="./doc/IMG_E6201.JPG.modified.jpeg" width="500"> <img src="./doc/IMG_E6202.JPG.modified.jpeg" width="500">

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





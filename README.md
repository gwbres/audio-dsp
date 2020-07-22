# Audio DSP

This project is an Audio oriented Digital Signal Processing demo project. All processing is performed in FPGA,

all IPs can be used on any Xilinx 7 Series FPGA. Audio codec driver is provided for Zynq Zc702 ('Zedboard'/'Zybo') and Zc706 development platforms (ADAU 1761).

## System

![Bloc Design](https://github.com/gwbres/audio-dsp/blob/master/doc/images/bloc_design.png)

+ CIC decimation and interpolation filters
+ CIC compensation filters (implemented as FIR filters)
+ FIR filters application to signal Equalization & Modulation filters (time domain)
+ Signal Equalization design (frequency to time domain)
+ General signal modulations
+ Spectral analysis
+ Room / Reverb profile emulation
+ FIR/IIR filters: application to stereo delay
+ 'ping pong' stereo delay

## Documentation

Refer to the project documentation

```bash
xpdf $git/doc/documentation.pdf
```

## Getting Started

Building the firmware requires Xilinx 'Vivado' tool. Build is guaranteed for version 2020.1 

```bash
export XILINX_PATH=/opt/Xilinx
source xilinx-env.sh
```

Then build an SD card image with (linux image + ref. design):

```bash
make
```

Open the ref. design with

```bash
vivado $git/design/[...]
```

The firmware may build with other Vivado versions; in any case, it will not build for Vivado versions that do not have support for XPM macros builtin.

The ref. design is embedded in /dev/mmbclkp0 of the SD card, it is automatically loaded at boot time, you can now access the zedboard either by UART over USB, or SSH over ethernet at 192.168.0.10.

You can reflash the default firmware with:

```bash
ssh root@192.168.0.10
mount /dev/mmcblkp1 /mnt
cat /mnt/design.bit > /dev/xdevcfg
```

You can upload any firmware and follow the same process using *scp*

You should now plug at feed an audio stream into the 'Line In' socket, and play the output stream from the 'HPH' socket.

## GUI

Once the zeboad is booted and network is correctly set up to access the LAN/192.168.0.10, you can use the provided Graphical Interface to

- control and modify the time domain filters
- control the input to the spectral analysis
- load a new reverb/room profile to emulate

Launch the GUI with

```bash
source $git/python-env.sh
cd $git/python/gui
./gui.py
```


# Audio DSP

This project is an Audio oriented Digital Signal Processing demo project. All processing is performed in FPGA,

all IPs can be used on any Xilinx 7 Series FPGA. Audio codec driver is provided for Zynq Zc702 ('Zedboard'/'Zybo') and Zc706 

development platforms (ADAU 1761).



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
source $git/xilinx-env.sh
```

Recreate the reference design with

```bash
vivado $git/design/[...]
```

The firmware may build with other Vivado versions; in any case, it will not build for Vivado versions that do not have support for XPM macros builtin.

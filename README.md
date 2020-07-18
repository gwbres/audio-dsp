# Audio DSP

This project is an Audio oriented Digital Signal Processing demo project. All processing is performed in FPGA,

all IPs can be used on any Xilinx 7 Series FPGA. Audio codec driver is provided for Zynq Zc702 and Zc706 

development platforms (ADAU1761).

## Learn from this project

+ CIC decimation filters: what they are, how to implement a CIC filter
+ CIC compensation filter: how to compensate for a CIC filter and implementation in the form of an FIR filter 
+ FIR filters: application to signal equalization & modulation filter
+ Signal Equalization: design the EQ in frequency domain, apply it using an FIR filter
+ General modulation filters (phaser, reverb, delay): applied in time domain using FIR filters
+ Study of Stereo / so called ' ping-pong' delay/reverb algorithms 
+ Room profile emulation using an FIR filter

## Documentation

Refer to the project documentation:

```bash
xpdf $git/doc/documentation.pdf
```

## Getting Started

Install Vivado, this project was developed using Vivado 2020.1, the provided setup script can be used in this case

```bash
export XILINX_PATH=/opt/Xilinx
source $git/xilinx-env.sh
```

The reference design can then be opened with

```bash
vivado $git/design/design.tcl
```

Synthesis & implementation are only guaranteed for Vivado 2020.1. The user may try other versions but

in any case, the design will now synthesize against a version of Vivado where XPM macros are not supported.


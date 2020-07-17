# Audio DSP

This project is an Audio oriented Digital Signal Processing

demo project. All processing is performed in FPGA,

all IPs can be used on any Xilinx 7 Series FPGA.

Audio Codec driver is provided for Zynq Zc702 and Zc706 

development platforms (ADAU1761).

## Learn from this project

+ CIC decimation filters: what they are, how to implement a CIC filter
+ CIC compensation filter: how to compensate for a CIC filter and implementation in the form of an FIR filter 
+ FIR filters: application to signal equalization & modulation filter
+ Signal Equalization: design the EQ in frequency domain, apply it using an FIR filter
+ General modulation filters (Phaser, Reverb, Delay): applied in time domain using FIR filters
+ Study of Stereo / so called ' Ping Pong' delay/reverb algorithms 
+ Room profile emulation using an FIR filter

## Documentation

Refer to the project documentation:

```bash
xpdf $git/doc/documentation.pdf
```

#! /usr/bin/env python3

import sys

import numpy as np
import matplotlib.pyplot as plt

# api
from audio.wav import *

from tools.os_utils import listfile
from tools.xilinx import xlnx_coe_writer

def _parseIntegerValue (self, content):
	integer = 0
	for i in range (0, len(content)):
		integer += int(content[i]) << (8*i)
	return integer

def main (argv):
	if len(argv) == 0:
		profiles = listfile ('../../data/reverb-profiles/')
		string = 'Select one profile among:\n'
		for i in range (0, len(profiles)):
			string += '{:d}: {:s}\n'.format(i, profiles[i])

		id = int(input(string))
		profile =  '../../data/reverb-profiles/' + profiles[id]
	else:
		profile = argv[0]
	
	wav = Wav(profile)
	print(wav) # .wav infos

	data = wav.getData()
	
	# convert impulse response
	# to .coe file

	fig = plt.figure(1)

	# time domain => impulse response
	ax = fig.add_subplot(211)
	ax.set_title("Impulse profile: '{:s}'".format(profile))

	for i in range (0, len(data)):
		ax.plot(data[i], 'x-', label='Audio channel {:d}'.format(i))
	
	ax.grid(True)
	ax.legend(loc='best')

	# frequency domain
	ax = fig.add_subplot(212)
	
	for i in range (0, len(data)):
		# apply a window for fft analysis
		yt = np.blackman(len(data[i])) * data[i]
		yf = np.fft.rfft(yt, n=len(data[0])-1) 
		yf = 10*np.log10(np.abs(yf))
		ax.plot(yf, label='Audio channel {:d}'.format(i))
	
	ax.grid(True)
	ax.legend(loc='best')

	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

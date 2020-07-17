#! /usr/bin/env python3

import sys

import numpy as np
import matplotlib.pyplot as plt

# api
from audio.wav import *

def main (argv):
	#wav = Wav('../../data/reverb-profiles/Deep Space.wav')
	#wav = Wav('../../data/reverb-profiles/Large Wide Echo Hall.wav')
	#wav = Wav('../../data/reverb-profiles/Nice Drum Room.wav')
	wav = Wav('../../data/reverb-profiles/St Nicolaes Church.wav')
	data = wav.getData()

	fig = plt.figure(1)
	ax = fig.add_subplot(111)
	ax.plot(data[0], 'x-', label='Stereo - left')
	ax.plot(data[1], 'x-', label='Stereo - right')
	ax.grid(True)
	ax.legend(loc='best')
	
	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

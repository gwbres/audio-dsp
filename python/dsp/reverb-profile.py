#! /usr/bin/env python3

import sys

import numpy as np
import matplotlib.pyplot as plt

# api
from audio.wav import *
#import wave

def _parseIntegerValue (self, content):
	integer = 0
	for i in range (0, len(content)):
		integer += int(content[i]) << (8*i)
	return integer

def main (argv):
	#wav = Wav('../../data/reverb-profiles/Deep Space.wav')
	#wav = Wav('../../data/reverb-profiles/BIG HALL E001 M2S.wav')
	#wav = Wav('../../data/reverb-profiles/BIG HALL E003 M2S.wav')
	#wav = Wav('../../data/reverb-profiles/WIDE HALL-1.wav')
	#wav = Wav('../../data/reverb-profiles/CORRIDOR FLUTTER ECHO E001 M2S.wav')
	#wav = Wav('../../data/reverb-profiles/Large Wide Echo Hall.wav')
	wav = Wav('../../data/reverb-profiles/Nice Drum Room.wav')
	
	#wav = wave.open('../../data/reverb-profiles/St Nicolaes Church.wav')
	#nframes = wav.getnframes()
	#print(wav.readframes(nframes))
	
	print(wav)
	data = wav.getData()

	fig = plt.figure(1)

	# time domain => impulse response
	ax = fig.add_subplot(211)
	for i in range (0, len(data)):
		ax.plot(data[i], label='Audio channel {:d}'.format(i))
	
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

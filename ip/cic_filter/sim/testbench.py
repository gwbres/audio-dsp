#! /usr/bin/env python3

import sys

import numpy as np
import matplotlib.pyplot as plt

# api
from sim.stimulus import *

def main (argv):

	if len(argv) == 0:
		
		# build stimulus
		stimulus = Stimulus(
			type='sinewave',
			fs=100e6,
			fc=10e6,
			a=0.1,
			phi=0.0,
			nbsymbols=128,
			quantizer='s16.15'
		)

		stimulus.to_text_file()

		print("Stimulus has been generated")
		print("Run simulation with 'make'")
		return 0

	# retrieve stimulus settings
	with open('settings.txt', 'r') as fd:
		content = fd.read()
	settings = eval(content)
	
	# rebuild prev. stimulus
	stimulus = Stimulus(type=settings['type'],
		fs=settings['fs'],
		fc=settings['fc'],
		a=settings['a'],
		phi=settings['phi'],
		nbsymbols=settings['nb-symbols'],
		quantizer=settings['quantizer']
	)

	fig = plt.figure(1)

	# stimulus in time
	ax0 = fig.add_subplot(221) 
	ax0.plot(stimulus.get_data(), label='stimulus')
	ax0.set_xlabel('Symbol')
	ax0.set_ylabel('Amplitude')
	ax0.legend(loc='best')
	ax0.grid(True)
	
	# stimulus in frequency
	ax1 = fig.add_subplot(222) 
	yf = np.fft.rfft(stimulus.get_data())
	yfdB = 10*np.log10(yf)
	yfdB -= max(yfdB)
	
	xf = np.linspace(0, stimulus.params['fs'] / 2, len(yf))

	ax1.plot(xf, yfdB, label='stimulus')
	ax1.set_xlabel('Frequency')
	ax1.set_ylabel('Power')
	ax1.legend(loc='best')
	ax1.grid(True)

	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

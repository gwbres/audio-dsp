#! /usr/bin/env python3

import sys
import numpy as np
import matplotlib.pyplot as plt

def main (argv):
	
	# CIC filter parameters
	R = 1
	M = 1
	N = 2

	for arg in argv:
		key = arg.split('=')[0]
		value = arg.split('=')[1]

		if key == 'R':
			R = int(value)

		elif key == 'N':
			N = int(value)
	
	# plot
	fig, ax = plt.subplots (1,1)
	fig.set_size_inches(8,8)

	# freq axis
	f = np.linspace(0, 1, 1024) - 1/2
	
	# freq response
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	H = np.power(num / denom, N)
	HdB  = 10*np.log10(H)
	HdB -= max(HdB)
	ax.plot(f, HdB)

	# worst spur
	xworst = 3/2/M/R
	num = np.sin(R*M*np.pi*xworst)
	denom = R * M * np.sin(np.pi*xworst)
	Hworst = np.power(num/denom, N)
	HworstdB = 10*np.log10(Hworst)
	ax.plot(xworst, HworstdB, '+', color='black')
	ax.text(xworst, HworstdB+3, 'Worst Alias Rejected by {:.3f} dB'.format(HworstdB))
	
	ax.set_xlabel('Normalized frequency')
	ax.set_ylabel('Magnitude [dB]')
	ax.grid(True)
	ax.set_ylim(-80, 0)
	ax.set_xlim(f[0], f[-1])
	
	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

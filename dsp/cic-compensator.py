#! /usr/bin/env python3

import sys
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

def main (argv):
	
	bw = 30 # FIR cut off in [%] on new nyquist band
	
	R = 1
	M = 1
	N = 2

	for arg in argv:
		key = arg.split('=')[0]
		value = arg.split('=')[1]

		if key == 'R':
			R = int(value)

		elif key == 'M':
			M = int(value)

		elif key == 'N':
			N = int(value)

		elif key == 'BW':
			BW = int(value)
	
	# plot
	fig = plt.figure(1)
	fig.set_size_inches(8,8)
	
	ax0 = fig.add_subplot(221)
	ax0.set_title('CIC filter')
	
	# plot non compensated CIC response (input)
	# along entire frequency axis
	f = np.linspace(0, 1, 1024) -1/2
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	Hcic  = 20 *np.log10(np.power(num/denom, N))
	Hcic -= max(Hcic)
	ax0.plot(f, Hcic, '--', color='black', label='CIC filter')
	
	xworst = 3/2/M/R
	num = np.sin(R*M*np.pi*xworst)
	denom = R * M * np.sin(np.pi*xworst)
	Hworst = np.power(num/denom, N)
	HworstdB = 20*np.log10(Hworst)
	ax0.plot(xworst, HworstdB, 'x', markeredgewidth=2.0, markersize=10, color='black')
	ax0.text(0, HworstdB+3, 'Worst Alias Rejected by {:.3f} dB'.format(HworstdB))
	
	ax0.set_xlabel('Normalized frequency')
	ax0.set_ylabel('Magnitude [dB]')
	ax0.legend(loc='best')
	ax0.grid(True)
	# focus
	ax0.set_ylim(HworstdB-5, 3)
	ax0.set_xlim(-3/2/M/R, 3/2/M/R+0.1)
	
	# designs compensation filter
	# within new nyquist zone only
	
	ax1 = fig.add_subplot(222)
	ax1.set_title('Compensated CIC filter with BW {:d}%'.format(bw))

	# pass band
	fpb = np.linspace(0, bw*1/R/100, int(bw*1024/100))
	# use inverse response
	num = np.sin(2*np.pi*fpb/2)
	denom = np.sin(2*np.pi*fpb*R/2)
	Hpb = 20 *np.log10(np.power(num/denom, N))
	Hpb -= Hpb[1]
	
	# stop band
	fsb = np.linspace(bw*1/R/100, 1/R, int((100-bw)*1024/100))
	# regular response 
	num = np.sin(2*np.pi*fsb*R/2)
	denom = np.sin(2*np.pi*fsb/2)
	Hsb = 20 *np.log10(np.power(num/denom, N))
	Hsb -= max(Hsb)
	Hsb += Hpb[-1]
	
	# Build symmetric frequency response
	# for total FIR filter (ranging from -1/R:1/R, i.e
	# total new Nyquist band
	Hcomp = Hsb[::-1]
	Hcomp = np.concatenate((Hcomp, Hpb[::-1]))
	Hcomp = np.concatenate((Hcomp, Hpb))
	Hcomp = np.concatenate((Hcomp, Hsb))

	# CIC response within new nyquist band
	f = np.linspace(-1/R, 1/R, len(Hcomp))
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	Hcic = 20*np.log10(np.power(num/denom, N))
	Hcic -= max(Hcic)
	
	Htot = Hcic + Hcomp
	
	ax1.plot(f, Hcomp, '--', label='CIC compensation')
	ax1.plot(f, Htot, label='Total response')
	ax1.plot(f, Hcic, '--', color='black', label='CIC filter')
	
	ax1.set_xlabel('Normalized frequency')
	ax1.set_ylabel('Magnitude [dB]')
	ax1.legend(loc='best')
	ax1.grid(True)
	# focus
	ax1.set_ylim(-50, 10)
	ax1.set_xlim(-3/2/M/R, 3/2/M/R+0.1)

	# Impulse Response
	# from FIR system
	ax3 = fig.add_subplot(212)
	f = f+1/R # fir.design requires [0:fnyquist]
	f /= f[-1] # fir.design requires [0:1]
	print(f)
	a = signal.firls(31, f, 10**(Hcomp/20))
	ax3.plot(a,'-x')

	ax3.grid(True)
	ax3.set_ylabel('Impulse response')
	ax3.set_xlabel('tau')
	
	fig.tight_layout()
	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

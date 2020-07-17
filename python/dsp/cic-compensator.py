#! /usr/bin/env python3

import sys
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

def main (argv):
	
	# CIC filter parameters
	R = 1
	M = 1
	N = 2

	# FIR filter designer
	ncoef = 128 # nb of coefficients to be implemented
	bw = 30 # cut off in [%] on new nyquist band
	
	for arg in argv:
		key = arg.split('=')[0]
		value = arg.split('=')[1]

		if key == 'R':
			R = int(value)

		elif key == 'N':
			N = int(value)

		elif key == 'BW':
			bw = int(value)

		elif key == 'ncoef':
			ncoef = int(value)
	
	fig = plt.figure(1)
	fig.set_size_inches(8,8)
	
	# Theoretical CIC filter
	ax0 = fig.add_subplot(221)
	ax0.set_title('CIC filter')
	
	# along entire frequency axis
	f = np.linspace(0, 1/2, 1024) 
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	hcic = np.power(num/denom, N)
	Hcic  = 20 *np.log10(hcic)
	Hcic -= Hcic[1]
	ax0.plot(f, Hcic, '--', color='black', label='CIC filter')
	
	# worst alias indication
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
	ax0.set_xlim(0, 3/2/M/R+0.1)
	ax0.set_ylim(HworstdB-5, 3)
	
	# designs compensation filter
	# within new nyquist zone only

	ax1 = fig.add_subplot(222)
	ax1.set_title('Compensated CIC filter with BW {:d}%'.format(bw))

	# pass band
	fpb = np.linspace(0, bw*1/R/100, int(bw*1024/100))
	# use inverse response
	num = np.sin(2*np.pi*fpb/2)
	denom = np.sin(2*np.pi*fpb*R/2)
	hpb = np.power(np.abs(num/denom), N)

	Hpb = 20*np.log10(hpb)
	Hpb -= Hpb[1]
	
	# stop band
	fsb = np.linspace(bw*1/R/100, 1/R, int((100-bw)*1024/100))
	hsb = np.zeros(len(fsb))
	
	Hsb = np.zeros(len(fsb))
	for i in range (0, len(fsb)):
		Hsb[i] = -200.0
	Hsb += Hpb[-1]
	
	# hfir is [hpb:hsb]
	hfir = np.concatenate((hpb, hsb))
	Hfir = np.concatenate((Hpb, Hsb))

	# CIC response within new nyquist band
	f = np.linspace(0, 1/R, len(hfir)) 
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	hcic = np.power(num/denom, N)
	Hcic = 20*np.log10(hcic)
	Hcic -= Hcic[1]

	Htot = Hcic + Hfir
	
	ax1.plot(f*R, Hcic, '--', color='black', label='CIC filter')
	ax1.plot(f*R, Hfir, label='CIC compensation')
	ax1.plot(f*R, Htot, label='Total response')
	
	ax1.set_xlabel('Normalized frequency')
	ax1.set_ylabel('Magnitude [dB]')
	ax1.legend(loc='best')
	ax1.grid(True)

	# focus
	ax1.set_xlim(0,   bw/100+0.1)
	ax1.set_ylim(-5, 5)

	# FIR designer
	ax3 = fig.add_subplot(223)
	ax3.set_title('Filter design: Impulse Response')

	f /= f[-1] # fir.design requires [0:1]
	hfir[0] = hfir[1] # DC=0 causes problem
	a = signal.firwin2(128, f, hfir) 
	a /= max(a)
	
	delay = np.linspace(-len(a)//2, len(a)//2, len(a))
	ax3.plot(delay, a, '-x', label='h(z) with {:d} coefs'.format(ncoef)) # plot impulse response

	ax3.grid(True)
	ax3.set_ylabel('Impulse response')
	ax3.set_xlabel('Delay')
	ax3.legend(loc='best')
	
	# FIR implementation
	ax4 = fig.add_subplot(224)
	ax4.set_title('Filter design: Implementation')

	f, H = signal.freqz(a)
	HdB = 20*np.log10(np.abs(H))
	HdB -= HdB[0]

	# CIC theoretical response
	f = np.linspace(0, 1/R, len(H)) 
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	hcic = np.power(num/denom, N)
	Hcic = 20*np.log10(hcic)
	Hcic -= Hcic[1]
	
	# implemented total response
	Htot = HdB + Hcic

	ax4.plot(f/f[-1], Hcic, '--', color='black', label='CIC filter')
	ax4.plot(f/f[-1], HdB, label='FIR compensator')
	ax4.plot(f/f[-1], Htot, label='Total response')
	
	ax4.set_xlim(0,   bw/100+0.1)
	ax4.set_ylim(-5,  5)

	ax4.grid(True)
	ax4.legend(loc='best')

	fig.tight_layout()
	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

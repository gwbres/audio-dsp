#! /usr/bin/env python3

import sys
import numpy as np
import matplotlib.pyplot as plt

def main (argv):
	
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
	
	# plot
	fig, ax = plt.subplots (1,1)
	fig.set_size_inches(8,8)

	# designs compensation filter
	# within new nyquist zone only

	bw = 30 # FIR cut off in [%] on new nyquist band
	
	# pass band
	fpb = np.linspace(0, 30*1/R/100, int(30*1024/100))
	# use inverse response
	num = np.sin(2*np.pi*fpb/2)
	denom = np.sin(2*np.pi*fpb*R/2)
	Hpb = 10 *np.log10(np.power(num/denom, N))
	Hpb -= Hpb[1]
	ax.plot(fpb, Hpb, '--', label='Compensator Pass-Band')
	
	# stop band
	fsb = np.linspace(30*1/R/100, 1/R, int(70*1024/100))
	# regular response 
	num = np.sin(2*np.pi*fsb*R/2)
	denom = np.sin(2*np.pi*fsb/2)
	Hsb = 10 *np.log10(np.power(num/denom, N))
	Hsb -= max(Hsb)
	Hsb += Hpb[-1]
	ax.plot(fsb, Hsb, '--', label='Compensator Stop-Band')

	# CIC response within new nyquist band
	f = np.linspace(0, 1/R, len(Hpb)+len(Hsb))
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	Hcic = 10*np.log10(np.power(num/denom, N))
	Hcic -= Hcic[1]

	# plot compensated CIC
	# within new nyquist band
	Hcomp = np.concatenate((Hpb, Hsb))
	Htot = Hcic + Hcomp
	ax.plot(f, Htot, label='Total CIC+FIR response')

	# add non compensated CIC response
	# along entire frequency axis
	f = np.linspace(0, 1, 1024) -1/2
	num = np.sin(2*np.pi*f*R/2)
	denom = np.sin(2*np.pi*f/2)
	Hcic  = 10 *np.log10(np.power(num/denom, N))
	Hcic -= max(Hcic)
	ax.plot(f, Hcic, '--', color='black', label='CIC response')
	
	## worst spur
	#xworst = 3/2/M/R
	#num = np.sin(R*M*np.pi*xworst)
	#denom = R * M * np.sin(np.pi*xworst)
	#Hworst = np.power(num/denom, N)
	#HworstdB = 10*np.log10(Hworst)
	#ax.plot(xworst, HworstdB, '+', color='black')
	#ax.text(xworst, HworstdB+3, 'Worst Alias Rejected by {:.3f} dB'.format(HworstdB))
	
	ax.set_xlabel('Normalized frequency')
	ax.set_ylabel('Magnitude [dB]')
	ax.grid(True)
	ax.set_ylim(-40, 10)
	ax.set_xlim(-3/2/M/R, 3/2/M/R)
	ax.legend(loc='best')
	
	plt.show()

if __name__ == "__main__":
	main(sys.argv[1:])

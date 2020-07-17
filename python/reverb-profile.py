#! /usr/bin/env python3

import sys

# api
from audio.wav import *

def load_profile (wav):
	"""
	Returns binary content
	of given wav file
	should be a properly sampled impulse response
	"""
	with open(wav, 'rb') as fd:
		content = fd.read()
	return content

def main (argv):
	wav = Wav('../data/reverb-profiles/Deep Space.wav')

if __name__ == "__main__":
	main(sys.argv[1:])

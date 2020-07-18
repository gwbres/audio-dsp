import sys
import numpy as np

class Wav (object):

	def __init__ (self, fp):

		content = self._read_raw(fp)

		self.fileName = fp

		fileTypeBlocID = content[0:4]
		if fileTypeBlocID != b'RIFF':
			raise RuntimeError('RIFF TypeBloc ID error!')

		self.fileSize = self._parseUnsignedIntegerValue(content[4:8])

		fileFormatID = content[8:12]
		if fileFormatID != b'WAVE':
			raise RuntimeError('Corrupted .wav file!')

		formatBlocID = content[12:16]
		if formatBlocID != b'fmt ':
			raise RuntimeError('Corrupted .wav format description')

		self.blocSize = self._parseUnsignedIntegerValue(content[16:20])
		
		audioFormat = int(content[20])
		if audioFormat == 1:
			self.audioFormat = 'PCM'
		else:
			self.audioFormat = 'Unknown'
		
		self.nbChannels = self._parseUnsignedIntegerValue(content[22:24])
		self.sampleRate = self._parseUnsignedIntegerValue(content[24:28])
		bytesPerSec = content[28:32]
		bytesPerBloc = content[32:34]
		self.bitsPerSample = self._parseUnsignedIntegerValue(content[34:36])

		dataBlocId = content[36:40]
		if dataBlocId != b'data':
			raise RuntimeError('Corrupted .wav data description')

		self.dataSize = self._parseUnsignedIntegerValue(content[40:44])

		# parsing data
		nbSymbols = int(self.dataSize /8 /self.bitsPerSample /self.nbChannels)
		self.data = np.ones((self.nbChannels,nbSymbols))
		offset = 40
		bytesPerSymbols = self.bitsPerSample //8 
		for i in range (0, self.data.shape[1]):
			for j in range (0, self.nbChannels): 
				c = content[offset:offset+bytesPerSymbols]
				offset += bytesPerSymbols
				self.data[j][i] = self._parseSignedIntegerValue(c, bits=self.bitsPerSample)
    
		# remove DC
		self.data -= np.mean(self.data)

		# normalize data to [-1:1] signed data
		norm = pow(2,self.bitsPerSample-1)
		self.data /= norm

	def numberOfSymbols (self):
		return self.data.shape[1]

	def getData (self):
		"""
		Returns data for all channels
		"""
		return self.data
	
	def getChannelData (self, channel):
		"""
		Returns data for given channel
		"""
		return self.data[channel]
			
	def _read_raw (self, fp):
		"""
		Returns raw binary content
		of given file fp
		"""
		with open(fp, 'rb') as fd:
			return fd.read()

	def __str__ (self):
		string = 'File: {:s}\n'.format(self.fileName)
		string += 'Audio Format: {:s}\n'.format(self.audioFormat)
		string += 'Sample Rate: {:d} Hz\n'.format(self.sampleRate)
		string += 'Nb Channels: {:d}\n'.format(self.nbChannels)
		string += 'Bits per sample: {:d}\n'.format(self.bitsPerSample)
		string += 'File size: {:d} bytes\n'.format(self.fileSize)
		string += 'Bloc size: {:d}\n'.format(self.blocSize)
		string += 'Data size: {:d} bytes\n'.format(self.dataSize)
		return string

	def _parseUnsignedIntegerValue (self, content):
		integer = 0
		for i in range (0, len(content)):
			integer += int(content[i]) << (8*i)
		return integer

	def _parseSignedIntegerValue (self, content, bits=8):
		max_positive = pow(2,bits-1)
		unsigned = self._parseUnsignedIntegerValue (content)
		if unsigned > max_positive: # is negative
			return -pow(2,bits) + unsigned
		else:
			return unsigned 

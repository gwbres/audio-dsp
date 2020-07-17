import numpy as np

class Wav (object):

	def __init__ (self, fp):
		
		content = self._read_raw(fp)

		fileTypeBlocID = content[0:4]
		if fileTypeBlocID != b'RIFF':
			raise RuntimeError('RIFF TypeBloc ID error!')

		self.fileSize = self._parseIntegerValue(content[4:8])

		fileFormatID = content[8:12]
		if fileFormatID != b'WAVE':
			raise RuntimeError('Corrupted .wav file!')

		formatBlocID = content[12:16]
		if formatBlocID != b'fmt ':
			raise RuntimeError('Corrupted .wav format description')

		self.blocSize = self._parseIntegerValue(content[16:20])
		
		audioFormat = int(content[20])
		if audioFormat == 1:
			self.audioFormat = 'PCM'
		else:
			self.audioFormat = 'Unknown'
		
		self.nbChannels = self._parseIntegerValue(content[22:24])
		self.sampleRate = self._parseIntegerValue(content[24:28])
		bytesPerSec = content[28:32]
		bytesPerBloc = content[32:34]
		self.bitsPerSample = self._parseIntegerValue(content[34:36])

		dataBlocId = content[36:40]
		if dataBlocId != b'data':
			raise RuntimeError('Corrupted .wav data description')

		self.dataSize = self._parseIntegerValue(content[40:44])

		# parsing data
		nbSymbols = int(self.dataSize /8 /self.bitsPerSample /self.nbChannels)
		self.data = np.ones((self.nbChannels,nbSymbols))
		offset = 40
		bytesPerSymbols = self.bitsPerSample //8 
		for i in range (0, self.data.shape[1]):
			for j in range (0, self.nbChannels):
				c = content[offset:offset+bytesPerSymbols]
				print(offset, offset+bytesPerSymbols)
				offset += bytesPerSymbols
				self.data[j][i] = self._parseIntegerValue(c)

		# normalize data to [-1:1] signed data
		norm = pow(2,self.bitsPerSample) -1
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
		string  = 'Audio Format: {:s}\n'.format(self.audioFormat)
		string += 'Sample Rate: {:d} Hz\n'.format(self.sampleRate)
		string += 'Nb Channels: {:d}\n'.format(self.nbChannels)
		string += 'Bits per sample: {:d}\n'.format(self.bitsPerSample)
		string += 'File size: {:d} bytes\n'.format(self.fileSize)
		string += 'Bloc size: {:d}\n'.format(self.blocSize)
		string += 'Data size: {:d} bytes\n'.format(self.dataSize)
		return string

	def _parseIntegerValue (self, content):
		integer = 0
		for i in range (0, len(content)):
			integer += int(content[i]) << (8*i)
		return integer
		
"""
[Bloc des données]
DATAS[] : [Octets du Sample 1 du Canal 1] [Octets du Sample 1 du Canal 2] [Octets du Sample 2 du Canal 1] [Octets du Sample 2 du Canal 2]

* Les Canaux :
	1 pour mono,
	2 pour stéréo
	3 pour gauche, droit et centre
	4 pour face gauche, face droit, arrière gauche, arrière droit
	5 pour gauche, centre, droit, surround (ambiant)
	6 pour centre gauche, gauche, centre, centre droit, droit, surround (ambiant)
NOTES IMPORTANTES :  Les octets des mots sont stockés sous la forme Petit-boutiste (c.-à-d., en "little endian")
[87654321][16..9][24..17] [8..1][16..9][24..17] [...
"""

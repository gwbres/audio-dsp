class Wav (object):

	def __init__ (self, fp):
		
		content = self._read_raw(fp)

		fileTypeBlocID = content[0:4]
		if fileTypeBlocID != b'RIFF':
			print('RIFF TypeBloc ID error!')

		self.fileSize = 0
		# fileSize - 8 (RIFF header size)
		for i in range (0, len(content[4:8])):
			self.fileSize += int(content[4:8][i]) << (8*i) 
		print(self.fileSize)

		fileFormatID = content[8:12]
		if fileFormatID != b'WAVE':
			print('Corrupted .wav file!')

		formatBlocID = content[12:16]
		if formatBlocID != b'fmt ':
			print('Corrupted .wav format description')

		self.blocSize = 0
		# bloc size -16
		for i in range (0, len(content[16:20])):
			self.blocSize += int(content[16:20][i]) << (8*i)
		print(self.blocSize)
		

		audioFormat = int(content[20])
		if audioFormat == 1:
			self.audioFormat = 'PCM'
		else:
			self.audioFormat = 'Unknown'
		print(self.audioFormat)
		# drop[22]

		self.nbChannels = 0
		for i in range (0, len(content[22:24])):
			self.nbChannels += int(content[22:24][i])
		print(self.nbChannels)

		self.sampleRate = 0
		for i in range (0, len(content[24:28])):
			self.sampleRate += int(content[24:28][i])
		print('Sample rate: ', self.sampleRate, ' Hz')

		bytesPerSec = content[28:32]
		bytesPerBloc = content[32:34]

		self.bitsPerSample = 0
		for i in range (0, len(content[34:36])):
			self.bitsPerSample += int(content[34:36][i])
		print('Bits per sample: ', self.bitsPerSample)

	def _read_raw (self, fp):
		"""
		Returns raw binary content
		of given file fp
		"""
		with open(fp, 'rb') as fd:
			return fd.read()
		
"""
[Bloc des données]
DataBlocID      (4 octets) : Constante « data »  (0x64,0x61,0x74,0x61)
DataSize        (4 octets) : Nombre d'octets des données (c.-à-d. "Data[]", c.-à-d. taille_du_fichier - taille_de_l'entête  (qui fait 44 octets normalement).
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

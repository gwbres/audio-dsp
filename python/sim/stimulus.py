import numpy as np

# api
from sim.fixed_point_quantizer import *

class Stimulus (object):

	def __init__ (self, fp=None, type='sinewave', **params):

		if fp is None:
			if type == 'sinewave':
				self.make_sinewave(**params)
		else:
			self._from_file(fp)
	
	def get_type (self):
		"""
		Return stimulus type
		"""
		return self.type

	def get_data (self):
		return self.data
	
	def make_sinewave (self, **params):
		self.params = {
			'type': 'sinewave',
			'nb-symbols': 1024, # nb of symbols to be generated
			'quantizer': None,
			'fs': 100E6, # sample rate
			'fc':  10E6, # carrier freq 
			'a':    1.0, # amplitude
			'phi':  0.0, # phi(t=0) in radians
		}

		for key, value in params.items():
			
			if key == 'fs':
				self.params['fs'] = float(value)
			elif key == 'fc':
				self.params['fc'] = float(value)
			elif key == 'a':
				self.params['a'] = float(value)
			elif key == 'phi':
				self.params['phi'] = float(value)
			elif key == 'nbsymbols':
				self.params['nb-symbols'] = int(value)

			elif key == 'quantizer':
				self.params['quantizer'] = FixedPointQuantizer(qmformat=value)

		t = np.linspace(0, self.params['nb-symbols'] / self.params['fs'], self.params['nb-symbols'])
		self.data = self.params['a'] * np.sin(2*np.pi*self.params['fc']*t + self.params['phi'])

	def to_text_file (self):
		"""
		Writes self.stimulus into text file
		to be parsed & used in HDL sim
		"""
		with open ('stimulus.txt', 'w') as fd:
			for i in range (0, len(self.data)):

				quantizer = self.params['quantizer']
				quantized = quantizer.quantize(self.data[i])

				# format for hread() in VHDL
				formatstring = '{:0' +'{:d}x'.format(+quantizer.getQ() // 4) + '}'
				fd.write(formatstring.format(quantized) +'\n')

		self.params['quantizer'] = str(self.params['quantizer'])
		with open ('settings.txt', 'w') as fd:
			fd.write(str(self.params))

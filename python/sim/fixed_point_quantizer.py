class FixedPointQuantizer (object):

	def __init__ (self, qmformat=None, q=0, m=0, is_signed=True):
		
		if qmformat is None:
			self.q = q
			self.m = m
			self.isSigned = is_signed
		
		else:
			# sQ.M
			self.isSigned = ('s' in qmformat)
			self.q = int(qmformat.split('.')[0].strip('s'))
			self.m = int(qmformat.split('.')[1])

	def __str__ (self):
		"""
		Converts self to sQ.M format
		"""
		string = ''
		if self.is_signed():
			string += 's'
		string += '{:d}.{:d}'.format(self.getQ(), self.getM())
		return string

	def getQ (self):
		return self.q
	
	def getM (self):
		return self.m

	def quantize (self, value, toBinary=False):
		"""
		Quantizes given value,
		returns either integer or binary value
		"""

		nbIntegerBits = self.getQ() - self.getM()
		if self.is_signed():
			nbIntegerBits -= 1

		integerValue = int(value * pow(2, self.getM()))

		if self.is_signed():
			# 2s complement
			#print(integerValue)
			if integerValue < 0:
				print(integerValue)
				max_pos = pow(2, self.getQ()-1)
				integerValue = max_pos - integerValue
				print(integerValue)
				print('')
			
			b = bin(integerValue)[2:] # '0b'
				
			# sign extend
			for i in range (0, self.q - len(b)):
				b = b[0] + b
			
			return int('0b'+b,2)
			
		else:
			print(integerValue, '\n')
			integerValue = 0 if (integerValue < 0) else integerValue
			integerValue = self._signExtend(integerValue, self.q)
			b = bin(integerValue)[2:] #'0b'

			# sign extend 
			for i in range (0, self.q - len(b)):
				b = '0'+b

			return int('0b'+b)
		
	def getMaximalValue (self):
		"""
		Returns maximal float value that can be represented
		"""
		nbIntegerBits = self.getQ() - self.getM()
		if self.is_signed():
			nbIntegerBits -= 1

		if self.is_signed():
			return pow(2,self.getQ()-1) / self.getM()
		else:
			return pow(2,self.getQ()) / self.getM()

	def getMinimalValue (self):
		"""
		Returns minimal float value that can be represented
		"""
		if self.is_signed():
			return 1.0 - self.getMaximalValue()
		else:
			return 0.0

	def is_signed (self):
		return self.isSigned
	
	def get_value (self):
		"""
		Returns internal float value
		"""
		return self.value

	def __mul__ (self, fxp):
		"""
		Multiplies self with other fixed point nb
		"""
		v = self.value * fxp.get_value()
		q = self.q + fxp.getQ()
		m = self.m + fpx.getM()
		return FixedPoint(v, q, m, isSigned=self.is_signed())
	
	def __rmul__ (self, fxp):
		"""
		Multiplies self with other fixed point nb
		"""
		v = self.value * fxp.get_value()
		q = self.q + fxp.getQ()
		m = self.m + fpx.getM()
		return FixedPoint(v, q, m, isSigned=self.is_signed())

	def __add__ (self, fxp):
		"""
		Adds given fixed point nb to self
		"""
		v = self.value + fxp.get_value()
		q = max(self.q, fxp.getQ()) +1
		m = min(self.m, fxp.getM())
		return FixedPoint(v,q,m,isSigned=self.is_signed())

	def __sub__ (self, fpx):
		"""
		Substracts given fixed point nb to self
		"""
		v = self.value + fxp.get_value()
		q = max(self.q, fxp.getQ()) +1
		m = min(self.m, fxp.getM())
		return FixedPoint(v,q,m,isSigned=self.is_signed())

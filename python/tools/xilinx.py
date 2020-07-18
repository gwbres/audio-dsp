import numpy as np

def sign_extend (number, bits):
	"""
	Sign extends given number
	for specified amount of bits
	"""
	if number < 0:
		binary = bin(number)[3:] # '-0b'
		if len(binary) < bits: 
			n_stuff = bits - len(binary)
			for i in range (0, n_stuff):
				binary = '1' + binary
			return int(binary,2)
		else:
			return number
	else:
		return number

def xlnx_coe_writer (data, fp, bits=16, signed=True):
	"""
	Converts given 1D data array (float)
	to 1D integer & normalized data
	into xilinx compliant .coe file
	"""
	if signed:
		norm = pow(2,bits-1)
	else:
		norm = pow(2,bits) 

	format_string = '{:0' + str(int(np.log2(bits))) + 'x}'

	with open(fp, "w") as fd:
		fd.write('memory_initialization_radix=16;\n') # hexa
		fd.write('memory_initialization_vector=\n\t') 
		for i in range (0, len(data)-1):
			d = int(data[i] * norm)
			d = sign_extend(d, bits)
			fd.write(format_string.format(d)+',')

			if (i%8) == 7:
				# makes output file more readable
				fd.write('\n\t')

		d = int(data[-1] * norm)
		d = sign_extend(d, bits)
		fd.write(format_string.format(d))
		fd.write(';')

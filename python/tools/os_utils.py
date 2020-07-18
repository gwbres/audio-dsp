import os
import time
import subprocess
import datetime

def subprocess_run (*args, capture_output=False):
	"""
	Launches a child task, from given attributes
	"""
	if (capture_output):
		return subprocess.run( 
			args, 
			capture_output=True
		)

	else:
		return subprocess.run( 
			args, 
			stdout=subprocess.DEVNULL,
		)

def file_name (fp):
	"""
	Returns file name from given path
	"""
	index = fp.rfind('.')
	return fp[:index]

def file_extension (fp):
	"""
	Returns file extension
	of given path
	"""
	index = fp.rfind('.')
	return fp[:index]

def mkdir (fp):
	"""
	Creates given directory
	"""
	os.makedirs(fp, exist_ok=True)

def rm (fp, flags=None):
	"""
	Removes given file or directory 
	flags='-r'
	flags='-rf'
	"""
	args = ['rm']

	if flags is not None:
		args += [flags]
	
	args += [fp]
	subprocess_run(*args, capture_output=False)

def chown_file (fp, user):
	"""
	Launches 'sudo chown' on a single file
	"""
	args = ["sudo", "chown", "{0:s}:{0:s}".format(user), fp]
	return subprocess_run(*args)

def file_exists (fp):
	"""
	Returns True if given file exists
	"""
	return os.path.exists(fp)

def file_size (fp):
	"""
	Returns size of given file in bytes
	"""
	args = ['stat', "--printf='%s'", fp]
	ret = subprocess_run(*args, capture_output=True).stdout.decode('utf-8')
	return int(ret.strip("'").split('%')[0])

def file_modification_date (fp):
	"""
	Returns last modification date of given file 
	as a datetime object
	"""
	args = ['stat', "--printf='%z'", fp]
	ret = subprocess_run(*args, capture_output=True).stdout.decode('utf-8').strip("'")
	string = ret.split(' ')[0] + ' ' + ret.split(' ')[1]
	string = string.split('.')[0] # get rid of microseconds
	format = '%Y-%m-%d %H:%M:%S'
	return datetime.datetime.strptime(string, format)

def touch (fp):
	"""
	Launches touch 'fp'
	"""
	args = ['touch', fp]
	subprocess_run(*args, capture_output=False)

def listfile (folder, sort_by_time=False, extension_filter=None):
	"""
	Returns list of files in given folder
		+ extension_filder: use a filter like 'txt', 'csv'...
		to filter results out
	"""
	args = ['ls', folder]
	if sort_by_time:
		args.append('-t')
	
	ret = subprocess_run(*args, capture_output=True).stdout.decode('utf-8')
	
	files = []
	for r in ret.split('\n')[:-1]:
		if extension_filter is None:
			files.append(r.strip())
		else:
			if file_extension(r) == extension_filter:
				files.append(r.strip())

	return files

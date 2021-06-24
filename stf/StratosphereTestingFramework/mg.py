#!/usr/bin/python
import argparse
import os
import time
import fnmatch
import tempfile
import shutil
import transaction

from stf.common.out import *
from stf.core.dataset import __datasets__
#from stf.core.experiment import __experiments__
from stf.core.database import __database__
from stf.core.connections import __group_of_group_of_connections__
from stf.core.models_constructors import __modelsconstructors__
from stf.core.models import __groupofgroupofmodels__
from stf.core.notes import __notes__
from stf.core.labels import __group_of_labels__ 
from stf.core.plugins import __modules__


if __name__ == "__main__":
	parser = argparse.ArgumentParser(
	    description='Stratosphere Model generator',
	    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
	parser.add_argument("-p", "--pcap-file", help="Read data from this file in libpcap format")
	parser.add_argument("-m", "--model-file", help="Save STF model to this file")
	args = parser.parse_args()
	
	
	if not args.pcap_file:
	    print('some parameters are missing to test. Exiting...')
	    sys.exit(0)
	
	pcap_filename = args.pcap_file
	
	if args.model_file:
		model_filename= args.model_file
	else:
	    model_filename=pcap_filename+".tsv"
	
	
	__datasets__.create(pcap_filename)
	__datasets__.generate_argus_files()
	__group_of_group_of_connections__.create_group_of_connections()
	constructor = __modelsconstructors__.get_default_constructor().get_id()
	__groupofgroupofmodels__.generate_group_of_models(constructor)
	__groupofgroupofmodels__.export_models_in_group("0-1",model_filename)


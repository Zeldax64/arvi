'''
	Regression tests script

	This script runs several tests and report errors when they occur. This script
	uses multithreading to launch verilator simulations as subprocesses.
	TODO: Create a CLI (Command Line Interface) interface.
'''

import subprocess
import sys
import glob
import os
from multiprocessing.dummy import Pool

mt = True
pool = Pool() # Concurrent simulations at a time

sim_path = "./obj_dir/VRISC_V"
tests_folder = "tb/tests"


def launch_sim(prog):
	test_prog = "+loadmem="+prog
	failure = subprocess.call([sim_path, test_prog])
	if failure:
		print("Testing: "+prog+ " FAILED")
		return True
	else:
		return False

def test_loop(progs):
	failed = False
	if mt:
		ret = pool.map(launch_sim, progs)
		if True in ret:
			failed = True

	else:
		for test_prog in progs:
			failure = launch_sim(test_prog)
			failed = failure or failed

	return failed

def get_isa_files(isa_test_folder):
	files_list = []

	files = glob.glob(isa_test_folder+'/*')
	for file in files:
		if '.' not in file:
			files_list.append(file)

	return files_list

def isa():
	print("--- ISA Tests ---")

	# Getting programs list
	rv32ui_dir = tests_folder+"/isa/rv32ui"
	rv32ua_dir = tests_folder+"/isa/rv32ua"
	rv32um_dir = tests_folder+"/isa/rv32um"

	rv32ui_progs = get_isa_files(rv32ui_dir)
	rv32ua_progs = get_isa_files(rv32ua_dir)
	rv32um_progs = get_isa_files(rv32um_dir)

	# Testing
	failed = test_loop(rv32ui_progs)
	failed = test_loop(rv32um_progs) or failed

	# Result
	if not failed: 
		print("--- ISA tests passed! ---")
	else:
		print("--- ISA tests failed! ---")

def compliance():
	print("--- Compliance Tests ---")

	# Testing rv32i programs
	print("*** rv32i tests ***")
	# Getting programs list
	test_folder = tests_folder+"/compliance/rv32i"
	progs = glob.glob(test_folder+'/*.elf')

	# Testing
	failed = test_loop(progs)

	# Compairing references
	os.environ["SUITEDIR"] = test_folder
	compair = subprocess.call(["tb/scripts/verify.sh"])
	compliant = compair or failed

	# Testing rv32mi programs
	print("*** rv32mi tests ***")
	# Getting programs list
	test_folder = tests_folder+"/compliance/rv32mi"
	progs = glob.glob(test_folder+'/*.elf')
	failed = test_loop(progs)

	# Compairing references
	os.environ["SUITEDIR"] = test_folder
	compair = subprocess.call(["tb/scripts/verify.sh"])

	compliant = compair or failed or compliant

	# Result
	if not compliant: 
		print("--- Compliance tests passed! ---")
	else:
		print("--- Compliance tests failed! ---")

def benchmark():
	test_folder = tests_folder+"/benchmark"
	progs = glob.glob(test_folder+'/*.riscv')

	# Testing
	print("--- Benchmark tests ---")
	failed = test_loop(progs)

	# Result
	if not failed: 
		print("--- Benchmark tests passed! ---")
	else:
		print("--- Benchmark tests failed! ---")

def arg_parse():
	args = sys.argv
	run = True

	if "-h" in args:
		print("Regression tests script. This script runs tests in tb/tests folder")
		run = False

	return run

def main():
	if arg_parse():
		#isa()
		#compliance()
		benchmark()

main()

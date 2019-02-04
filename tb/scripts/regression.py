import subprocess
import sys
import glob
import os

sim_path = "./obj_dir/VRISC_V"

def isa():
	# Getting programs list
	test_folder = "tb/tests/isa/rv32ui"
	files = glob.glob(test_folder+'/*')
	progs = []
	for file in files:
		if '.' not in file:
			progs.append(file)

	# Testing
	failed = 0
	print("--- ISA Tests ---")
	for test_prog in progs:
		test_prog = "+loadmem="+test_prog
		failure = subprocess.call([sim_path, test_prog])
		failed = failure or failed
		if failure:
			print("Testing: "+test_prog+ " FAILED")

	# Result
	if not failed: 
		print("--- ISA tests passed! ---")
	else:
		print("--- ISA tests failed! ---")

def compliance():
	# Getting programs list
	test_folder = "tb/tests/compliance/rv32i"
	progs = glob.glob(test_folder+'/*.elf')

	# Testing
	failed = 0
	print("--- Compliance Tests ---")
	for test_prog in progs:
		test_prog = "+loadmem="+test_prog
		failure = subprocess.call([sim_path, test_prog])
		failed = failure or failed
		if failure:
			print("Testing: "+test_prog+ " FAILED")

	# Compairing references
	os.environ["SUITEDIR"] = test_folder
	compair = subprocess.call(["tb/scripts/verify.sh"])
	failed = compair or failed

	# Result
	if not failed: 
		print("--- Compliance tests passed! ---")
	else:
		print("--- Compliance tests failed! ---")

def benchmark():
	test_folder = "tb/tests/benchmark"
	progs = glob.glob(test_folder+'/*.riscv')

	# Testing
	failed = 0
	print("--- Benchmark tests ---")
	for test_prog in progs:
		test_prog = "+loadmem="+test_prog
		failure = subprocess.call([sim_path, test_prog])
		failed = failure or failed
		if failure:
			print("Testing: "+test_prog+ " FAILED")

	# Result
	if not failed: 
		print("--- Benchmark tests passed! ---")
	else:
		print("--- Benchmark tests failed! ---")

def main():
	isa()
	compliance()
	benchmark()

main()

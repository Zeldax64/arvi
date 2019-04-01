import subprocess
import sys
import glob
import os

sim_path = "./obj_dir/VRISC_V"

def test_loop(progs):
	failed = 0
	for test_prog in progs:
		test_prog = "+loadmem="+test_prog
		failure = subprocess.call([sim_path, test_prog])
		failed = failure or failed
		if failure:
			print("Testing: "+test_prog+ " FAILED")
	return failed

def isa():
	print("--- ISA Tests ---")

	# Getting programs list
	test_folder = "tb/tests/isa/rv32ui"
	files = glob.glob(test_folder+'/*')
	progs = []
	for file in files:
		if '.' not in file:
			progs.append(file)

	# Testing
	failed = test_loop(progs)

	# Getting programs list
	test_folder = "tb/tests/isa/rv32ua"
	files = glob.glob(test_folder+'/*')
	progs = []
	for file in files:
		if '.' not in file:
			progs.append(file)

	# Testing
	failed = test_loop(progs) or failed


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
	test_folder = "tb/tests/compliance/rv32i"
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
	test_folder = "tb/tests/compliance/rv32mi"
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
	test_folder = "tb/tests/benchmark"
	progs = glob.glob(test_folder+'/*.riscv')

	# Testing
	print("--- Benchmark tests ---")
	failed = test_loop(progs)

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

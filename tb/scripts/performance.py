import pandas as pd
import sys

report_file = ""
'''
class Performance:

class ISA:

class Cache:
'''
entries = []

def add_entry(line):
	global entries
	name = None
	val = None

	if "<name>" in line:
		l = line[len("\t<name>"):-len("</name>\n")]
		name = l
	if "<counter>" in line:
		l = line[len("\t<counter>"):-len("</counter>\n")]
		val = l

	if "<hits>" in line:
		l = line[len("\t<hits>"):-len("</hits>\n")]
		val = l
		name = "hits"
	if "<misses>" in line:
		l = line[len("\t<misses>"):-len("</misses>\n")]
		val = l
		name = "misses"
	if "<miss_penalty>" in line:
		l = line[len("\t<miss_penalty>"):-len("</miss_penalty>\n")]
		val = l
		name = "miss_penalty"

	if name:
		#print(name)
		entries.append([name])
	if val:
		#print(val)
		entries[-1].append(val)


def read_report():
	file = open(report_file, "r")

	line = file.readline()
	while line: 
		if "\t" in line:
			add_entry(line)
		line = file.readline()
	
	#for entry in entries:
	#	print(entry)
	file.close()
	
	values = [row[1] for row in entries]
	names = [row[0] for row in entries]

	df = pd.DataFrame(values)
	df = df.transpose()
	df.columns = names
	print(df)
	df.to_csv(report_file+".csv")


def arg_parse():
	global report_file
	report_file = sys.argv[1]
	print(report_file)

def main():
	arg_parse()
	read_report()


main()

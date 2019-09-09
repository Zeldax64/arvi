import pandas as pd
import sys

entries = []
prog = []
cycles = []

def add_entry(line):
	global entries, prog, cycles
	name = None
	val = None

	line = line.replace("\t", "")
	if "<path>" in line and len(prog) == 0:
		l = line[len("<path>"):-len("</path>\n")]
		prog.append("program")
		prog.append(l)

	if "<cycles>" in line and len (cycles) == 0:
		l = line[len("<cycles>"):-len("</cycles>\n")]
		cycles.append("cycles")
		cycles.append(l)

	if "<hart" in line:
		l = line.replace("<hart", "")
		l = l.replace(">\n", "")

		name = "hart"
		val = l
		entries.insert(0 ,prog)
		entries.insert(1, cycles)
		
	if "<name>" in line:
		l = line[len("<name>"):-len("</name>\n")]
		name = l
	if "<counter>" in line:
		l = line[len("<counter>"):-len("</counter>\n")]
		val = l

	if "<hits>" in line:
		l = line[len("<hits>"):-len("</hits>\n")]
		val = l
		name = "hits"
	if "<misses>" in line:
		l = line[len("<misses>"):-len("</misses>\n")]
		val = l
		name = "misses"
	if "<miss_penalty>" in line:
		l = line[len("<miss_penalty>"):-len("</miss_penalty>\n")]
		val = l
		name = "miss_penalty"

	if name:
		entries.append([name])
	if val:
		entries[-1].append(val)


def read_report(path):
	global entries
	file = open(path, "r")

	line = file.readline()
	df = None
	while line: 
		#if "\t" in line:
		add_entry(line)
		line = file.readline()
		if "</hart" in line:
			values = [row[1] for row in entries]
			names = [row[0] for row in entries]
			df_entry = pd.DataFrame(values)
			df_entry = df_entry.transpose()
			df_entry.columns = names
			if isinstance(df, pd.DataFrame):
				df = df.append(df_entry, ignore_index = True) 
			else:
				df = df_entry
			entries = []
	
	file.close()
	return df


def arg_parse():
	reports = sys.argv[1:]
	return reports

def main():
	global entries, prog, cycles
	df = None
	report_files = arg_parse()
	for report in report_files:
		report_df = read_report(report)

		if isinstance(df, pd.DataFrame):
			df = df.append(report_df, ignore_index = True) 
		else:
			df = report_df
		entries = []
		prog = []
		cycles = []
	df.to_csv("dataframe.csv")

main()

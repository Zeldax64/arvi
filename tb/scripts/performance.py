import pandas as pd
import sys

entries = []

def add_entry(line):
	global entries
	name = None
	val = None

	line = line.replace("\t", "")

	if "<path>" in line:
		l = line[len("<path>"):-len("</path>\n")]
		val = l
		name = "program"

	if "<cycles>" in line:
		l = line[len("<cycles>"):-len("</cycles>\n")]
		val = l
		name = "cycles"	

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
	file = open(path, "r")

	line = file.readline()
	while line: 
		if "\t" in line:
			add_entry(line)
		line = file.readline()
	
	file.close()
	
	values = [row[1] for row in entries]
	names = [row[0] for row in entries]

	df = pd.DataFrame(values)
	df = df.transpose()
	df.columns = names
	return df


def arg_parse():
	reports = sys.argv[1:]
	return reports

def main():
	global entries
	df = None
	report_files = arg_parse()
	for report in report_files:
		report_df = read_report(report)

		if isinstance(df, pd.DataFrame):
			df = df.append(report_df, ignore_index = True) 
		else:
			df = report_df
		entries = []

	df.to_csv("dataframe.csv")

main()

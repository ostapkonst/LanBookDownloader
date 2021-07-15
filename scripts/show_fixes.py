#!/usr/bin/env python3

import argparse
import os
import sys
from PyPDF2 import PdfFileReader


def create_parser():
	parser = argparse.ArgumentParser(description='Found fixed *.pdf')
	parser.add_argument('--search_dir', default='temp')
	parser.add_argument('--delete', action='store_true')
	return parser


def getListOfFiles(dirName):
	if not os.path.exists(dirName): return []
	if os.path.isfile(dirName): return [dirName]

	listOfFile = os.listdir(dirName)
	allFiles = []
	for entry in listOfFile:
		fullPath = os.path.join(dirName, entry)
		allFiles += getListOfFiles(fullPath)

	return allFiles


def get_info(path, pattern):
	if os.path.splitext(path)[1] != '.pdf': return

	with open(path, 'rb') as f:
		pdf = PdfFileReader(f)
		info = pdf.getDocumentInfo()

	creator = info.producer
	if creator is None: return
	return pattern in creator


def delete_file(path):
	if not os.path.isfile(path): return
	try:
		os.remove(path)
		return True
	except:
		pass


if __name__ == '__main__':
	parser = create_parser()
	ns = parser.parse_args()
	found = 0

	print("START SEARCH")
	try:
		listOfFiles = getListOfFiles(ns.search_dir)
		for path in listOfFiles:
			if get_info(path, 'cairo') == False:
				found += 1
				deleted = ns.delete and delete_file(path)
				if deleted: 
					print("FOUND:", path, "[DELETED]")
				else:
					print("FOUND:", path)
	except KeyboardInterrupt:
		pass
	except Exception as e:
		print("ERROR:", e, file=sys.stderr)
		sys.exit(1)
	finally:
		print("FOUND", found, "FILES")

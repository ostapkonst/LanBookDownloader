#!/usr/bin/env python3

import argparse
import os
import sys
from PyPDF2 import PdfFileMerger
from functools import cmp_to_key

joined_files = 0


def create_parser():
	parser = argparse.ArgumentParser(description='Join *.pdf files to one *.pdf')
	parser.add_argument('--pdf_dir', default='output_pdf')
	parser.add_argument('--pdf_file', default='combined')
	return parser


def file_comp(a, b):
	if a == b: return 0
	if len(a) < len(b): return -1
	return -1 if a < b else 1


def join_pdf(pdf_dir, pdf_file_name):
	global joined_files

	if not os.path.isdir(pdf_dir):
		raise Exception(f"Source path {pdf_dir} doesn't exist")

	dirname = os.path.dirname(pdf_file_name)
	dirname and (os.path.isdir(dirname) or os.makedirs(dirname))

	pdfs = sorted(os.listdir(pdf_dir), key=cmp_to_key(file_comp))

	merger = PdfFileMerger(strict=False)
	try:
		for pdf in pdfs:
			if os.path.splitext(pdf)[1] != '.pdf': continue
			merger.append(os.path.join(pdf_dir, pdf))
			joined_files += 1
			print("APPEND FILE:", pdf)
		merger.write(os.path.splitext(pdf_file_name)[0] + '.pdf')
		return True
	finally:
		merger.close()


if __name__ == '__main__':
	parser = create_parser()
	ns = parser.parse_args()
	merged = False

	print("START JOIN")
	try:
		merged = join_pdf(ns.pdf_dir, ns.pdf_file)
	except KeyboardInterrupt:
		pass
	except Exception as e:
		print("ERROR:", e, file=sys.stderr)
		sys.exit(1)
	finally:
		if merged:
			print("JOINED", joined_files, "FILES")
		else:
			print("FAILED TO MERGE FILES")

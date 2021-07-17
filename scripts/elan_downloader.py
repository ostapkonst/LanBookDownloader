#!/usr/bin/env python3

import argparse
import requests
import os
import sys
import time
import random
import json
from bs4 import BeautifulSoup

pause_timeout = lambda: random.randint(10, 90) # паузы в секундах между загрузками
chunk_size = lambda: random.randint(4, 13) # количество файлов загружаемых подряд
downloaded_files = 0

# Нужно добавить Cookie поле в header.json
header_lan = {
	'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36',
	'Accept': '*/*',
	'Accept-Encoding': 'gzip, deflate, br',
	'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
}


def create_parser():
	parser = argparse.ArgumentParser(description='Download *.svg files from e.lanbook')
	parser.add_argument('--config', default='header.json')
	parser.add_argument('--book_id', type=int, required=True)
	parser.add_argument('--svg_dir', default='output_svg')
	parser.add_argument('--start_page', type=int, default=1)
	parser.add_argument('--stop_page', type=int)
	return parser


def merge_config(config_file):
	global header_lan
	try:
		with open(config_file, 'r') as f:
			json_config = json.loads(f.read())
			header_lan = {**header_lan, **json_config}
	except:
		raise Exception(f"Failed to read config file {config_file} as json")


def get_pages_count(book_id):
	url = f'https://e.lanbook.com/reader/book/{book_id}/'
	rsp = requests.get(url, headers=header_lan)
	if rsp.status_code != requests.codes.ok:
		raise Exception(f"Failed open book: {book_id} with status code: {rsp.status_code}")

	try:
		soup = BeautifulSoup(rsp.text, 'lxml')
		span = soup.find('form', id='page-navigation').find('span')
		return int(span.text[1:])
	except:
		return -1


def download_svg(book_id, start_page, stop_page, svg_dir):
	global downloaded_files

	os.path.isdir(svg_dir) or os.makedirs(svg_dir)
	headers = dict(header_lan)
	headers['Referer'] = 'https://e.lanbook.com/reader/book/{id}/'.format(id=book_id)
	url_pages = 'https://fs2.e.lanbook.com/api/book/{id}/page/{page}/img'.format(id=book_id, page='{page}')

	page = start_page

	while page <= stop_page:
		stop = min(page + chunk_size(), stop_page)

		while page <= stop:
			file_name = f'{page}.svg'
			out_file = os.path.join(svg_dir, file_name)

			if os.path.isfile(out_file):
				stop = min(stop + 1, stop_page)
				print("SKIPPED FILE:", file_name)
				page += 1
				continue

			rsp = requests.get(url_pages.format(page=page), headers=headers)

			if rsp.status_code != requests.codes.ok:
				raise Exception(f"Failed download page: {page} with status code: {rsp.status_code}")

			if rsp.headers.get('content-type') != 'image/svg+xml':
				raise Exception(f"Failed download page: {page} with content-type: {rsp.headers.get('content-type')}")

			with open(out_file, 'wb') as f:
				f.write(rsp.content)
				downloaded_files += 1

			print("SAVED FILE:", file_name)
			page += 1

		if page > stop_page: break

		pause = pause_timeout()
		print("PAUSE:", pause, "SECONDS")
		time.sleep(pause)


def check_cookie():
	headers = dict(header_lan)
	headers['Referer'] = 'https://e.lanbook.com/cabinet/favorites'
	url = 'https://e.lanbook.com/api/v2/cabinet/favorites'

	rsp = requests.get(url, headers=headers)
	return rsp.status_code == requests.codes.ok


if __name__ == '__main__':
	parser = create_parser()
	ns = parser.parse_args()

	print("START DOWNLOAD")
	try:
		merge_config(ns.config)
		if not check_cookie():
			raise Exception("Session is out of date, you need to get a new one")

		ns.start_page = max(1, ns.start_page)
		pages_from_site = get_pages_count(ns.book_id)
		
		if ns.stop_page is None or ns.stop_page < 1:
			ns.stop_page = pages_from_site
			
		if ns.stop_page == -1:
			raise Exception("Failed parsed stop_page from e.lanbook")

		count_files = max(0, ns.stop_page - ns.start_page + 1)
		print("SELECTED", count_files, "FILES")

		download_svg(ns.book_id, ns.start_page, ns.stop_page, ns.svg_dir)
	except KeyboardInterrupt:
		pass
	except Exception as e:
		print("ERROR:", e, file=sys.stderr)
		sys.exit(1)
	finally:
		print("DOWNLOADED", downloaded_files, "FILES")

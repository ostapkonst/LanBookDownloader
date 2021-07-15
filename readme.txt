Кратко:
	Набор скриптов выкачивает выбранную книгу из ЭБС Лань

Описание:
	elan_downloader.py - скачивает листы в формате *.svg из ЭБС Лань
	svg_to_pdf.bat - конвертирует *.svg в *.pdf
	join_pdf.py - объединяет несколько *.pdf в один
	pdf_to_djvu.bat - конвертирует *.pdf в *.djvu
	show_fixes.py - выводит список *.pdf файлов, которые были растеризованы

Подготовка:
	Установить Python 3 и пакеты зависимостей скриптов
	В header.json нужно прописать поле "Cookie" из заголовка запроса

Требования:
	ImageMagick
	pdf2djvu
	rsvg-convert
	
Использование:
	run_all.bat --book_id=<int> [--start_page=<int>] [--stop_page=<int>]
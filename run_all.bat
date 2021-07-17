@setlocal EnableExtensions
@echo off

set config=header.json
set start_page=1
set book_id=
set stop_page=-1

set djvu=false
set paused=true
set force=false
set show_fixes=false
set delete_fixes=false

:cmd_params
if not %1/==/ (
	if not "%__var%"=="" (
		if not "%__var:~0,2%"=="--" (
			endlocal
			goto cmd_params
		)
		endlocal & set %__var:~2%=%~1
	) else (
		setlocal & set __var=%~1
	)
	shift
	goto cmd_params
)

set errors=0
set tmp_dir=temp
set png_dir="%tmp_dir%\png"

if "%*" == "" (
	echo Usage: run_all --book_id [--config] [--start_page] [--stop_page] [--djvu]
	echo               [--paused] [--force] [--show_fixes] [--delete_fixes]
	echo.
	echo Default: run_all --config=^"header.json^" --start_page=1 --stop_page=-1
	echo                  --djvu=false --paused=true --force=false --show_fixes=false
	echo                  --delete_fixes=false
	echo.
	echo Options:
	echo     --book_id=^<number^>
	echo     --config=^<string^>
	echo     --start_page=^<number^>
	echo     --stop_page=^<number^>
	echo     --djvu=[true^|false]
	echo     --paused=[true^|false]
	echo     --force=[true^|false]
	echo     --show_fixes=[true^|false]
	echo     --delete_fixes=[true^|false]

	if /i not "%paused%"=="false" pause > nul
	exit /b %errors%
)

echo START ALL

if /i not "%show_fixes%"=="false" (
	echo.
	scripts\show_fixes.py --search_dir="%tmp_dir%"
	goto finish
)

if /i not "%delete_fixes%"=="false" (
	echo.
	scripts\show_fixes.py --search_dir="%tmp_dir%" --delete
	goto finish
)

if "%book_id%"=="" (
	echo.
	echo Param --book_id must not be empty
	set errors=1
	goto finish
)

set svg_dir="%tmp_dir%\%book_id%_svg"
set pdf_dir="%tmp_dir%\%book_id%_pdf"
set pdf_file="books\%book_id%_book.pdf"
set djvu_file="books\%book_id%_book.djvu"

if /i not "%force%"=="false" goto start
if /i "%djvu%"=="false" (
	if exist %pdf_file% (
		echo.
		echo Result file %pdf_file% already exist
		goto finish
	)
) else (
	if exist %djvu_file% (
		echo.
		echo Result file %djvu_file% already exist
		goto finish
	)
)

:start
@echo on

scripts\elan_downloader.py --config="%config%" --book_id=%book_id% --svg_dir=%svg_dir% --start_page=%start_page% --stop_page=%stop_page%
@set /a errors+=%errorlevel%
cmd /c scripts\svg_to_pdf.bat --svg_dir=%svg_dir% --pdf_dir=%pdf_dir% --png_dir=%png_dir%
@set /a errors+=%errorlevel%
scripts\join_pdf.py --pdf_dir=%pdf_dir% --pdf_file=%pdf_file%
@set /a errors+=%errorlevel%
@if /i "%djvu%"=="false" goto finish
cmd /c scripts\pdf_to_djvu.bat --pdf_file=%pdf_file% --djvu_file=%djvu_file%
@set /a errors+=%errorlevel%

:finish
@echo off
echo.
if %errors%==0 (
	echo FINISHED [OK]
) else (
	echo FINISHED [FAIL]
)
if /i not "%paused%"=="false" pause
exit /b %errors%

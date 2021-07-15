@setlocal EnableExtensions
@echo off

:: Converts all *.pdf files to *.djvu
:: Need to be located next to the pdf2djvu
:: Use 0.9.7 version for rus symbols in path

set pdf2djvu="programs\pdf2djvu\pdf2djvu.exe"
set pdf_file=
set djvu_file=

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

set errors=1

echo START CONVERTING PDF-^>DJVU

if "%pdf_file%"=="" (
	echo Param --pdf_file must not be empty
	goto finish
)

if "%djvu_file%"=="" (
	echo Param --djvu_file must not be empty
	goto finish
)

if not exist %pdf2djvu% (
	echo pdf2djvu not found in path: %pdf2djvu%
	goto finish
)

if not exist "%pdf_file%" (
	echo File "%pdf_file%" does not exist
	goto finish
)

set errors=0
%pdf2djvu% -o "%djvu_file%" -d300 --bg-slices=76+16+16+16 --bg-subsample=3 --page-id-template=nb{dpage:04*}.djvu "%pdf_file%"
if not %errorlevel%==0 set errors=1

:finish
echo STOP CONVERTING [%errors%]
exit /b %errors%

@setlocal EnableExtensions EnableDelayedExpansion
@echo off

:: Converts all *.svg files to *.pdf (one by one)
:: Need to be located next to the rsvg-convert and ImageMagick

set rsvgconvert="programs\rsvg-convert\rsvg-convert.exe"
set imagemagik="programs\ImageMagick\convert.exe"
set svg_dir=
set pdf_dir=
set png_dir=
set rastr=false

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

echo START CONVERTING SVGs-^>PDFs

if "%svg_dir%"=="" (
	echo Param --svg_dir must not be empty
	goto finish
)

if "%pdf_dir%"=="" (
	echo Param --pdf_dir must not be empty
	goto finish
)

if "%png_dir%"=="" (
	echo Param --png_dir must not be empty
	goto finish
)

if not exist %rsvgconvert% (
	echo rsvgconvert not found in path: %rsvgconvert%
	goto finish
)

if not exist %imagemagik% (
	echo imagemagik not found in path: %imagemagik%
	echo WARNING: Rasterization disabled
)

set errors=0
set cnt=0
for /r "%svg_dir%" %%f in (*.svg) do set /a cnt+=1
if !cnt!==0 (
	echo NO FILES TO CONVERT ^(CREATE "%svg_dir%" FOLDER^)
	goto finish
)

mkdir "%png_dir%" >nul 2>&1
mkdir "%pdf_dir%" >nul 2>&1

set curr=0
for /r "%svg_dir%" %%f in (*.svg) do (
	set /a curr+=1
	echo | set /p=!curr!/!cnt!^) FILE: %%~nxf
	if exist "%pdf_dir%\%%~nf.pdf" (
		echo. [SKIPED]
	) else (
		if /i "%rastr%"=="false" (
			%rsvgconvert% -f pdf -d 144 -p 144 -o "%pdf_dir%\%%~nf.pdf" "%%f" >nul 2>&1
		) else (
			(call)
		)
		if !errorlevel!==0 (
			echo. [OK]
		) else (
			if exist %imagemagik% (
				%imagemagik% -density 144 "%%f" "%png_dir%\%%~nf.png" >nul 2>&1
				if !errorlevel!==0 (
					%imagemagik% -density 72 "%png_dir%\%%~nf.png" "%pdf_dir%\%%~nf.pdf" >nul 2>&1
					if !errorlevel!==0 (
						echo. [RASTR]
					) else (
						set /a errors+=1
						echo. [FAIL]
					)
				) else (
					set /a errors+=1
					echo. [FAIL]
				)
			) else (
				set /a errors+=1
				echo. [FAIL]
			)
		)
	)
)

:finish
echo STOP CONVERTING [%errors%]
exit /b %errors%

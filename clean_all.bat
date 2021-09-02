@setlocal EnableExtensions
@echo off

set tmp_dir=temp
set paused=true
set errors=1

rmdir /s /q "%tmp_dir%" > nul 2> nul
if not exist "%tmp_dir%" (
	set errors=0
)

if %errors%==0 (
	echo TEMP CLEAN
) else (
	echo ERRORS FOUND
)

if /i not "%paused%"=="false" pause
exit /b %errors%
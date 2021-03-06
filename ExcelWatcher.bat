@echo off

::Get excel file name and logfile from parameters
Set fileName=%1
Set logFile=%2
Set frequency=%3
Set interval=%4
Set updateFrequency=%5

Set fileNameHelper=ExcelHelper.xls
Set excelProgramPath="C:\Program Files\Microsoft Office\Office11\excel.exe"
set retryLimits=2
set retryAttempts=0
set isOpen=0
title Monitoring: %fileName%, Log File: %logFile%, Checking Frequency: %frequency% s, Interval: %interval% s, updateFrequency: %updateFrequency% s

if %1.==. (
	ECHO %date% %time% : Parameters missing.
	ECHO %date% %time% : You have to pass parameters to this batch file.
	ECHO %date% %time% : The expected format is:
	ECHO %date% %time% : ExcelWatcher.bat @targetFileName @logFileName @CheckingFrequency^(in sec^) @Interval^(in sec^) @UpdateFrequency^(in sec^).
	pause
	goto :eof
)

if %2.==. (
	ECHO %date% %time% : Parameter2 ^(Log file name^) missing.
	goto :eof
)

if %3.==. (
	ECHO %date% %time% : Parameter3 ^(Checking frequency^) missing.
	goto :eof
)

if %4.==. (
	ECHO %date% %time% : Parameter4 ^(Interval^) missing.
	goto :eof
)

if %5.==. (
	ECHO %date% %time% : Parameter5 ^(Update Frequency^) missing.
	goto :eof
)


set /A updateFrequencyH=%updateFrequency% / 3600
set /A updateFrequencyM=(%updateFrequency% - %updateFrequencyH%*3600) / 60
set /A updateFrequencyS=(%updateFrequency% - %updateFrequencyH%*3600 - %updateFrequencyM%*60)

if %updateFrequencyH% LSS 10 set updateFrequencyH=0%updateFrequencyH%
if %updateFrequencyM% LSS 10 set updateFrequencyM=0%updateFrequencyM%
if %updateFrequencyS% LSS 10 set updateFrequencyS=0%updateFrequencyS%

set updateFrequencyTime=%updateFrequencyH%:%updateFrequencyM%:%updateFrequencyS%

:Check
::Check whether excel file exists
cscript ExcelHelper.vbs CheckFileExist %fileName% //nologo
if %ERRORLEVEL%	EQU 13 (
	ECHO %date% %time% : The file %fileName% does not exits. 
	goto :eof
)

::Check whether the log file exists
cscript ExcelHelper.vbs CheckFileExist %logFile% //nologo
if %ERRORLEVEL%	EQU 13 (
	ECHO %date% %time% : The log file %logFile% does not exits. 
	goto :eof
)

cscript ExcelHelper.vbs CheckFileExist %fileName% //nologo

::First check if excel file is being opened or not
start /MIN "" %excelProgramPath% %fileNameHelper% /%fileName%/CheckOpen
cscript ExcelHelper.vbs delay 5 //nologo
for /F "delims=" %%i in (temp.txt) do set "isOpen=%%i"

::File is not opened
if %isOpen% EQU 0 (
	ECHO %date% %time% : %fileName% is not opened.
	ECHO %date% %time% : Now trying to open %fileName%.
	set /A retryAttempts=%retryAttempts%+1
	start /MIN "" %excelProgramPath% %fileName% /%updateFrequencyTime%
	cscript ExcelHelper.vbs delay 5 //nologo
	%0 %fileName% %logFile% %frequency% %interval% %updateFrequency%
) 
::File is opened
if %isOpen% EQU 1 (
	ECHO %date% %time% : %fileName% has already been opened.
	ECHO %date% %time% : Now monitor the log file.
	cscript ExcelHelper.vbs delay 5 //nologo
)


:Monitor
::SETLOCAL enabledelayedexpansion 
for /F "delims=" %%i in (%logFile%) do set "lastLine=%%i"
for /F "tokens=2 delims= " %%i in ("%lastLine%") do set "lastLogTime=%%i"
echo %date% %time% : Last Updated Time: %lastLogTime%.

for /f "delims=" %%i in ('"forfiles /m %logFile% /c "cmd /c echo @fdate @ftime" "') do set ModifiedDateTime=%%i
For /f "tokens=2 delims= " %%i in ("%ModifiedDateTime%") do set "lastLogTime=%%i"
For /f "tokens=3 delims= " %%i in ("%ModifiedDateTime%") do set "AMPM=%%i"

::Convert 12 Hour Time to 24 Hour Time
For /f "tokens=1,2,3 delims=:" %%a in ("%lastLogTime%") do set modifiedHour=%%a& set modifiedMin=%%b& set modifiedSec=%%c

IF "%AMPM%" == "AM" (
	IF %modifiedHour% LSS 10 set modifiedHour=0%modifiedHour%
)
IF "%AMPM%" == "PM" (
	if %modifiedHour% NEQ 12  Set /A modifiedHour=%modifiedHour%+12
)

Set modifiedTime=%modifiedHour%:%modifiedMin%:%modifiedSec%

set currentTime=%TIME%
::adjust the time format
for /F "tokens=1 delims=:/ " %%i in ("%currentTime%") do (
	if %%i LSS 10 set currentTime=%currentTime: =0%
)

::calculate the days
for /F "tokens=2 delims=/" %%i in ("%ModifiedDateTime%") do set "lastLogDay=%%i"
for /f "tokens=3 delims=/ " %%i in ('date /t') do set "currentDay=%%i"
::calculate the difference in days
set /A days=%currentDay%-%lastLogDay%

IF %days% LSS 0 set /A days=0



set /A modifiedTime=(1%modifiedTime:~0,2%-100)*3600+(1%modifiedTime:~3,2%-100)*60+(1%modifiedTime:~6,2%-100)
set /A currentTime=(1%currentTime:~0,2%-100)*3600+(1%currentTime:~3,2%-100)*60+(1%currentTime:~6,2%-100)

::ECHO %days%
::calculating duration (in seconds)
set /A duration=%currentTime%-%modifiedTime%+(%days%*24*60*60)
if %currentTime% LSS %modifiedTime% set /A duration=%modifiedTime%-%currentTime%

::now break the seconds down to hours, minutes
set /A durationH=%duration% / 3600
set /A durationM=(%duration% - %durationH%*3600) / 60
set /A durationS=(%duration% - %durationH%*3600 - %durationM%*60)

set /A intervalH=%interval% / 3600
set /A intervalM=(%interval% - %intervalH%*3600) / 60
set /A intervalS=(%interval% - %intervalH%*3600 - %intervalM%*60)

set /A frequencyH=%frequency% / 3600
set /A frequencyM=(%frequency% - %frequencyH%*3600) / 60
set /A frequencyS=(%frequency% - %frequencyH%*3600 - %frequencyM%*60)


if %durationH% LSS 10 set durationH=0%durationH%
if %durationM% LSS 10 set durationM=0%durationM%
if %durationS% LSS 10 set durationS=0%durationS%

if %intervalH% LSS 10 set intervalH=0%intervalH%
if %intervalM% LSS 10 set intervalM=0%intervalM%
if %intervalS% LSS 10 set intervalS=0%intervalS%

if %frequencyH% LSS 10 set frequencyH=0%frequencyH%
if %frequencyM% LSS 10 set frequencyM=0%frequencyM%
if %frequencyS% LSS 10 set frequencyS=0%frequencyS%

ECHo %date% %time% : The database update frequency: %updateFrequencyH%:%updateFrequencyM%:%updateFrequencyS%
echo %date% %time% : It has been %durationH%:%durationM%:%durationS% since last update.
ECHO %date% %time% : The alert interval time: %intervalH%:%intervalM%:%intervalS%

::Time exceeded limitation
if %duration% GTR %interval% (
	ECHO %date% %time% : The excel file may not work normally.	
	ECHO %date% %time% : Now trying to reopen %fileName%.
	set /A retryAttempts=%retryAttempts%+1
	cscript ExcelHelper.vbs delay 5 //nologo
	if %retryAttempts% LSS %retryLimits% (
		start /MIN "" %excelProgramPath% %fileNameHelper% /%fileName%/CloseFile
		cscript ExcelHelper.vbs delay 5 //nologo
		start /MIN "" %excelProgramPath% %fileName% /%updateFrequencyTime
		cscript ExcelHelper.vbs delay 5 //nologo
		goto Check
	) else (
		ECHO %date% %time% : Fatal Error. Retry limit exceeded.
		::cscript ExcelHelper.vbs EmailSender "Fatal Error. Retry limit exceeded." //nologo
		goto :eof
	)
) else (
	ECHO %date% %time% : Everything is fine.
	ECHO %date% %time% : The next check will be in %frequencyH%:%frequencyM%:%frequencyS%.
	cscript ExcelHelper.vbs delay %frequency% //nologo
	%0 %fileName% %logFile% %frequency% %interval% %updateFrequency%
)
::endlocal

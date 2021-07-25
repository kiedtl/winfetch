@echo off
setlocal enabledelayedexpansion

set usecolor=no
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set E=%%b

:: Argument Parser
:args
if "%1" == "/?" goto :credits
if "%1" == "/c" (
  set usecolor=yes
	shift
	goto :args
)
if "%1" == "" goto :main
shift
goto :args

:main
echo.

:: Get GPU details
set count=1
for /f "tokens=* usebackq" %%f in (`wmic path Win32_VideoController get caption^,CurrentVerticalResolution^,CurrentHorizontalResolution /format:list`) do (
  set tempvar!count!=%%f
  set /a count=!count!+1
)
for /f "tokens=1,* delims==" %%a in ("%tempvar3%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar4%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar5%") do set %%a=%%b
set gpu=%Caption%
set caption=
set gpu=%gpu:(tm) =%
set gpu=%gpu:(r) =%
set gpu=%gpu:(c) =%
set gpu=%gpu:~0,35%

:: Get CPU details
set count=1
for /f "tokens=* usebackq" %%f in (`wmic cpu get name^,AddressWidth /format:list`) do (
  set tempvar!count!=%%f
  set /a count=!count!+1
)
for /f "tokens=1,* delims==" %%a in ("%tempvar3%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar4%") do set %%a=%%b
set cpu=%name%
set cpu=%cpu:(tm)=%
set cpu=%cpu:(r)=%
set cpu=%cpu:(c)=%
set cpu=%cpu:~0,35%

:: Get OS details
set count=1
for /f "tokens=* usebackq" %%f in (`wmic os get Caption^,Version^,FreePhysicalMemory^,TotalVisibleMemorySize /format:list`) do (
  set tempvar!count!=%%f
  set /a count=!count!+1
)
for /f "tokens=1,* delims==" %%a in ("%tempvar3%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar4%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar5%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar6%") do set %%a=%%b
set osname=%Caption%
set osname=%osname:VistaT=Vista%
if "%osname:~10%" == " Windows Vista Home Premium " set osname=%osname:~0,9%%osname:~10%
set osname=%osname:~0,33%
set /a totalram=%TotalVisibleMemorySize% / 1024
set /a freeram=%FreePhysicalMemory% / 1024
set /a usedram=%totalram% - %freeram%
for /f "tokens=1-2 delims=. " %%i in ("%Version%") do set OSVERSION=%%i.%%j

:: Get disk details
set count=1
for /f "tokens=* usebackq" %%f in (`wmic logicaldisk %SystemDrive% get Freespace^,Size /format:list`) do (
  set tempvar!count!=%%f
  set /a count=!count!+1
)
for /f "tokens=1,* delims==" %%a in ("%tempvar3%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar4%") do set %%a=%%b
set /a all=%Size:~0,-6% / 1074
set /a free=%Freespace:~0,-6% / 1074
set /a used=%all%-%free%

:: System Uptime
for /F "tokens=1,* delims==" %%v in ('wmic path Win32_PerfFormattedData_PerfOS_System get SystemUptime /format:list ^| findstr "[0-9]"') do set "%%v=%%w"

:: Theme information - good luck!
if "%OSVERSION%" == "5.1" goto :XP
if "%AddressWidth%" == "64" goto :theme64

:theme86
if "%OSVERSION%" == "6.0" (
  set Theme_RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\LastTheme
  set Theme_RegVal=ThemeFile
) else (
  set Theme_RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\Themes
  set Theme_RegVal=CurrentTheme
)
reg query %Theme_RegKey% /v %Theme_RegVal% >nul || (set Theme_NAME="No_Theme_Name_Found" & goto :endTheme)
set Theme_NAME=
for /f "tokens=2,*" %%a in ('reg query %Theme_RegKey% /v %Theme_RegVal% ^| findstr %Theme_RegVal%') do set Theme_NAME=%%b
call :label "%Theme_NAME%"
goto :endTheme

:theme64
set Theme_RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager
set Theme_RegVal=DllName
reg query %Theme_RegKey% /v %Theme_RegVal% >nul || (set Theme_NAME="No_Theme_Name_Found" & goto :endTheme)
set Theme_NAME=
for /f "tokens=2,*" %%a in ('reg query %Theme_RegKey% /v %Theme_RegVal% ^| findstr %Theme_RegVal%') do set Theme_NAME=%%b
goto :endTheme

:endTheme
call :label "%Theme_NAME%"
goto :endXP

:XP
for /f "tokens=2,*" %%a in ('reg query HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ThemeManager  /v ThemeActive ^| findstr ThemeActive') do set Theme_active=%%b

if "%Theme_active%" == "0" (
  set themename="Windows Classic"
  goto :endXPTheme
)

:XPtheme
set Theme_RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager
set Theme_RegVal=DllName
reg query %Theme_RegKey% /v %Theme_RegVal% >NUL || (set Theme_NAME="No_Theme_Name_Found" & goto :endXPTheme)
set Theme_NAME=
for /f "tokens=2,*" %%a in ('reg query %Theme_RegKey% /v %Theme_RegVal% ^| findstr %Theme_RegVal%') do set Theme_NAME=%%b
call :label "%Theme_NAME%"
)
:endXPTheme
:endXP

set themename=%themename:~0,35%
if "%themename%" == "aero" (
  if "%OSVERSION%" == "6.2" set themename=metro
  if "%OSVERSION%" == "6.3" set themename=metro
  if "%OSVERSION%" == "6.4" set themename=fluent
  if "%OSVERSION%" == "10.0" set themename=fluent
)

:: Physical host details
for /f "usebackq tokens=1,* delims==" %%a in (`wmic computersystem get model /format:list ^| findstr "^Model="`) do set %%a=%%b

:: Get Shell
set shell_var=%COMSPEC%
set var1=%shell_var%
set i=0
:loopprocess
for /F "tokens=1* delims=\" %%A in ("%var1%") do (
  set /A i+=1
  set var1=%%B
  goto loopprocess
)
for /F "tokens=%i% delims=\" %%G in ("%shell_var%") do set last=%%G
set shell_NAME=%last%

:: Get Window Manager
set WM_RegKey="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
set WM_RegVal=Shell
reg query %WM_RegKey% /v %WM_RegVal% >NUL || (set WM_NAME="Explorer.exe" & goto :endWM)
for /f "tokens=2,*" %%a in ('reg query %WM_RegKey% /v %WM_RegVal% ^| findstr %WM_RegVal%') do set WM_NAME=%%b
:endWM

:: Get motherboard
set count=1
for /f "tokens=* usebackq" %%f in (`wmic baseboard get product^,manufacturer /format:list`) do (
  set tempvar!count!=%%f
  set /a count=!count!+1
)
for /f "tokens=1,* delims==" %%a in ("%tempvar3%") do set %%a=%%b
for /f "tokens=1,* delims==" %%a in ("%tempvar4%") do set %%a=%%b
set MOBO_NAME=%Manufacturer:  =%
set MOBO_NAME=%MOBO_NAME:~0,20%
set MOBO_MODEL=%Product:~0,10%

:: Constructing dashed-string based on user information's length
set "s=%username%"
set "len=1"
for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
  if "!s:~%%N,1!" neq "" (
    set /a "len+=%%N"
    set "s=!s:~%%N!"
  )
)
set userlength=%len%
set "s=%COMPUTERNAME%"
set "len=1"
for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
  if "!s:~%%N,1!" neq "" (
    set /a "len+=%%N"
    set "s=!s:~%%N!"
  )
)
set machinelength=%len%
set /a totallength=%userlength% + 1 + %machinelength%
set dashstring=
for /l %%x in (1, 1, %totallength%) do set "dashstring=!dashstring!-"


:: Printing info
if "%usecolor%" == "yes" (
  echo. %E%[1;31m        ,.=:^^!^^!t3Z3z.,                 %E%[1;33m%username%%E%[0m@%E%[1;33m%COMPUTERNAME%%E%[0m
  echo. %E%[1;31m       :tt:::tt333EE3                 %E%[0m%dashstring%
  echo. %E%[1;31m       Et:::ztt33EEE  %E%[1;32m@Ee.,      ..,  %E%[1;33mOS%E%[0m: %osname%%AddressWidth%-bit
  echo. %E%[1;31m      ;tt:::tt333EE7 %E%[1;32m;EEEEEEttttt33#  %E%[1;33mHost%E%[0m: %Model%
  echo. %E%[1;31m     :Et:::zt333EEQ. %E%[1;32mSEEEEEttttt33QL  %E%[1;33mKernel%E%[0m: %Version%
  echo. %E%[1;31m     it::::tt333EEF %E%[1;32m@EEEEEEttttt33F   %E%[1;33mUptime%E%[0m: %SystemUptime%s
  echo. %E%[1;31m    ;3=*^^```'*4EEV %E%[1;32m:EEEEEEttttt33@.   %E%[1;33mResolution%E%[0m: %CurrentHorizontalResolution%x%CurrentVerticalResolution%
  echo. %E%[1;34m    ,.=::::it=., %E%[1;31m` %E%[1;32m@EEEEEEtttz33QF    %E%[1;33mMotherboard%E%[0m: %MOBO_NAME% - %MOBO_MODEL%
  echo. %E%[1;34m   ;::::::::zt33^)   %E%[1;32m'4EEEtttji3P*     %E%[1;33mShell%E%[0m: %shell_NAME%
  echo. %E%[1;34m  :t::::::::tt33 %E%[1;33m:Z3z..  %E%[1;32m`` %E%[1;33m,..g.     %E%[1;33mTheme%E%[0m: %themename%
  echo. %E%[1;34m  i::::::::zt33F %E%[1;33mAEEEtttt::::ztF      %E%[1;33mWM%E%[0m: %WM_NAME%
  echo. %E%[1;34m ;:::::::::t33V %E%[1;33m;EEEttttt::::t3       %E%[1;33mCPU%E%[0m: %cpu%
  echo. %E%[1;34m E::::::::zt33L %E%[1;33m@EEEtttt::::z3F       %E%[1;33mGPU%E%[0m: %gpu%
  echo. %E%[1;34m{3=*^^```'*4E3^) %E%[1;33m;EEEtttt:::::tZ`       %E%[1;33mMemory%E%[0m: %E%[33m%usedram% MB%E%[0m / %totalram% MB
  echo. %E%[1;34m            ` %E%[1;33m:EEEEtttt::::z7         %E%[1;33mDisk%E%[0m: [%SYSTEMDRIVE%] %E%[32m%used% GB%E%[0m / %all% GB
  echo. %E%[1;33m                'VEzjt:;;z^>*`         %E%[40m  %E%[41m  %E%[42m  %E%[43m  %E%[44m  %E%[45m  %E%[46m  %E%[47m  %E%[100m  %E%[101m  %E%[102m  %E%[103m  %E%[104m  %E%[105m  %E%[106m  %E%[107m  %E%[0m
) else (
  echo.         ,.=:^^!^^!t3Z3z.,                 %username%@%COMPUTERNAME%
  echo.        :tt:::tt333EE3                 %dashstring%
  echo.        Et:::ztt33EEE  @Ee.,      ..,  OS: %osname%%AddressWidth%-bit
  echo.       ;tt:::tt333EE7 ;EEEEEEttttt33#  Host: %Model%
  echo.      :Et:::zt333EEQ. SEEEEEttttt33QL  Kernel: %Version%
  echo.      it::::tt333EEF @EEEEEEttttt33F   Uptime: %SystemUptime%s
  echo.     ;3=*^^```'*4EEV :EEEEEEttttt33@.   Resolution: %CurrentHorizontalResolution%x%CurrentVerticalResolution%
  echo.     ,.=::::it=., ` @EEEEEEtttz33QF    Motherboard: %MOBO_NAME% - %MOBO_MODEL%
  echo.    ;::::::::zt33^)   '4EEEtttji3P*     Shell: %shell_NAME%
  echo.   :t::::::::tt33 :Z3z..  `` ,..g.     Theme: %themename%
  echo.   i::::::::zt33F AEEEtttt::::ztF      WM: %WM_NAME%
  echo.  ;:::::::::t33V ;EEEttttt::::t3       CPU: %cpu%
  echo.  E::::::::zt33L @EEEtttt::::z3F       GPU: %gpu%
  echo. {3=*^^```'*4E3^) ;EEEtttt:::::tZ`       Memory: %usedram% MB / %totalram% MB
  echo.             ` :EEEEtttt::::z7         Disk: [%SYSTEMDRIVE%] %used% GB / %all% GB
  echo.                 'VEzjt:;;z^>*`
)
goto :EnOF

:label
set themename=%~n1
goto :EOF

:EnOF
exit /b
goto :EOF

:credits
echo.Usage: winfetch [/c] [/?]
echo.
echo.Options:
echo.    /c             Show colors (using ANSI escape sequences).
echo.    /?             Display this text.
echo.
echo.Thanks to:
echo.    anonymous
echo.    Arashi ^^!1IXzW.VjDs (Zanthas)
echo.    SaladFingers ^^!SpOONsgtAo
echo.    Jz9 ^^!//QwUWqnYY
echo.    Sk8rjwd
echo.    rashil2000
echo.

goto :EOF

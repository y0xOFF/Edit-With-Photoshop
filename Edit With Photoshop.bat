@echo off
setlocal enabledelayedexpansion

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as an Administrator.
    pause
    exit /b
)

cls
echo                  Edit With Photoshop
echo.
echo  1. Add Photoshop to Context Menu
echo  2. Remove Photoshop from Context Menu
echo  3. Exit
echo.

:Menu
set /p choice="Select: "
echo.

if "%choice%"=="1" goto AddPS
if "%choice%"=="2" goto RestoreOld
if "%choice%"=="3" exit /b
goto Menu

:AddPS
echo Select your "Photoshop.exe".
echo.

set "psCmd=Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Photoshop.exe|Photoshop.exe'; $f.Title = 'Select Photoshop.exe'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "%psCmd%" > "%temp%\ps_path.txt"
set /p psPath= < "%temp%\ps_path.txt"
del "%temp%\ps_path.txt"

if "%psPath%"=="" (
    echo ERROR: No file was selected.
    echo.
    goto Menu
)

set "tempReg=%temp%\ps_add.reg"
set "escapedPath=!psPath:\=\\!"

echo Windows Registry Editor Version 5.00 > "%tempReg%"
for %%E in (image .psd .psb .webp .heic .heif .pdf .eps .raw .dng .cr2 .nef .tga .pcx .iff) do (
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\%%E\shell\EditWithPhotoshop] >> "%tempReg%"
    echo "MUIVerb"="Edit with Photoshop" >> "%tempReg%"
    echo "Icon"="\"!escapedPath!\",0" >> "%tempReg%"
    echo [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\%%E\shell\EditWithPhotoshop\command] >> "%tempReg%"
    echo @="\"!escapedPath!\" \"%%1\"" >> "%tempReg%"
)

regedit.exe /s "%tempReg%"
del "%tempReg%"
echo Photoshop added to the context menu.
echo.
goto Menu

:RestoreOld
set "found=0"
for %%E in (image .psd .psb .webp .heic .heif .pdf .eps .raw .dng .cr2 .nef .tga .pcx .iff) do (
    reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\%%E\shell\EditWithPhotoshop" >nul 2>&1
    if !errorLevel! equ 0 set "found=1"
)

if !found! equ 0 (
    echo No Photoshop Context Menu entries found to remove.
    echo.
    goto Menu
)

set "restoreReg=%temp%\ps_restore.reg"

echo Windows Registry Editor Version 5.00 > "%restoreReg%"
:: Loop through the same extensions and delete only the Photoshop key
for %%E in (image .psd .psb .webp .heic .heif .pdf .eps .raw .dng .cr2 .nef .tga .pcx .iff) do (
    echo [-HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\%%E\shell\EditWithPhotoshop] >> "%restoreReg%"
)

regedit.exe /s "%restoreReg%"
del "%restoreReg%"
echo Photoshop context menu entries have been removed.
echo.
goto Menu
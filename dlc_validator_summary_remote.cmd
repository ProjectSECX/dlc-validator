@echo off
REM ============================================================
REM DLC Validator Summary - Launcher v1.0
REM InternalName: DLC_Validator_Summary
REM Author: Mauricio Guti�rrez
REM Department: Seguridad / QA / DeviceLock Integration
REM ProductVersion: 1.0
REM FileVersion: 1.0.0
REM Trademark: TRUSTONIC
REM Copyright: � 2026 TRUSTONIC � All rights reserved.
REM Comments: Client Summary Version � Internal Use Only.
REM Requiere: Windows 10/11 + PowerShell + ADB en el PATH.
REM ============================================================

color 0B
SETLOCAL

REM URL RAW del script remoto Summary (repositorio)
set "SCRIPT_URL=https://raw.githubusercontent.com/ProjectSECX/dlc-validator/main/dlc_validator_summary_remote.cmd"

REM Ubicacion temporal guarda el script descargado
set "TEMP_SCRIPT=%TEMP%\dlc_validator_summary_remote.cmd"

echo ============================================
echo     DLC Validator Summary - Launcher v1.0
echo     Descargando script remoto...
echo ============================================

REM Descargar el script remoto con PowerShell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    -Command "Invoke-WebRequest -UseBasicParsing '%SCRIPT_URL%' -OutFile '%TEMP_SCRIPT%'" 2>nul

REM Verificar si el archivo se descargo
if not exist "%TEMP_SCRIPT%" (
    echo [ERROR] No se pudo descargar el script remoto.
    echo        Verifica tu conexion a Internet o restricciones de red.
    echo        URL utilizada:
    echo        %SCRIPT_URL%
    echo.
    echo Presiona ENTER para salir...
    pause >nul
    exit /b
)

echo [OK] Script descargado correctamente.
echo.

REM Ejecutar el script descargado en un nuevo proceso CMD
echo Ejecutando DLC Validator Summary...
echo.
cmd /C "%TEMP_SCRIPT%"
echo --------------------------------------------
echo Ejecucion finalizada.
echo.

ENDLOCAL
exit /b

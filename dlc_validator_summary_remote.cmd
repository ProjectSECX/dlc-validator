@echo off
REM ============================================================
REM DLC_Validator Summary
REM InternalName: DLC_Validator_Summary
REM Author: Mauricio Gutierrez
REM Department: Security / QA / DeviceLock Integration
REM Output: DLC_Validator_Report.txt
REM Trademark: TRUSTONIC
REM Copyright: � 2026 TRUSTONIC � All rights reserved.
REM Requiere: Windows 10/11 + PowerShell + ADB en el PATH.
REM ============================================================

chcp 65001 >nul
color 0B
setlocal EnableDelayedExpansion

set "SUMMARY=DLC_Validator_Report.txt"
set "TMP=%TEMP%\dlc_validator_summary_tmp.txt"

set OK_COUNT=0
set INFO_COUNT=0
set REVIEW_COUNT=0

if exist "%SUMMARY%" del "%SUMMARY%" >nul 2>&1
if exist "%TMP%" del "%TMP%" >nul 2>&1

call :HEADER

REM ============================================================
REM 0. CONNECTED DEVICE
REM ============================================================
echo [0] DISPOSITIVO CONECTADO >> "%SUMMARY%"
echo. >> "%SUMMARY%"

adb devices > "%TMP%" 2>&1
findstr /R /C:"device$" "%TMP%" >nul

if errorlevel 1 (
    call :REVIEW "No se detect� ning�n dispositivo autorizado por ADB."
    echo Recomendacion: Conectar el dispositivo por USB, habilitar Depuracion USB y aceptar la autorizacion ADB en el telefono. >> "%SUMMARY%"
    echo. >> "%SUMMARY%"
    goto END_REPORT
) else (
    call :OK "Dispositivo detectado correctamente mediante ADB."
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 1. DEVICE INFORMATION
REM ============================================================
call :SECTION "[1] INFORMACION DEL DISPOSITIVO"

for /f "delims=" %%A in ('adb shell getprop ro.product.vendor.manufacturer 2^>nul') do set "MANUFACTURER=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.product.vendor.model 2^>nul') do set "MODEL=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.version.release 2^>nul') do set "ANDROID_VERSION=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.version.sdk 2^>nul') do set "SDK_VERSION=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.type 2^>nul') do set "BUILD_TYPE=%%A"

echo Fabricante: %MANUFACTURER% >> "%SUMMARY%"
echo Modelo: %MODEL% >> "%SUMMARY%"
echo Version Android: %ANDROID_VERSION% >> "%SUMMARY%"
echo SDK Version: %SDK_VERSION% >> "%SUMMARY%"
echo Tipo de compilacion: %BUILD_TYPE% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

if "%SDK_VERSION%"=="" (
    call :REVIEW "No fue posible obtener el SDK Version del dispositivo."
    echo Recomendacion: Validar manualmente que el dispositivo use Android 14 / SDK 34 o superior. >> "%SUMMARY%"
) else (
    if %SDK_VERSION% GEQ 34 (
        call :OK "SDK compatible para DLC v2. Android 14 / SDK 34 o superior."
    ) else (
        call :REVIEW "SDK inferior al recomendado para DLC v2."
        echo Recomendacion: El dispositivo debe utilizar Android 14 / SDK 34 o superior para validaciones DLC v2. >> "%SUMMARY%"
    )
)

if /I "%BUILD_TYPE%"=="user" (
    call :OK "Software de producci�n detectado (USER)."
) else (
    call :REVIEW "Tipo de compilacion no corresponde a USER. Valor detectado: %BUILD_TYPE%"
    echo Recomendacion: Para validaciones de produccion se recomienda utilizar software tipo USER. Valores como userdebug o eng corresponden normalmente a entornos de laboratorio o desarrollo. >> "%SUMMARY%"
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 2. VERIFIED BOOT / BOOTLOADER
REM ============================================================
call :SECTION "[2] ESTADO DE SEGURIDAD ANDROID"

for /f "delims=" %%A in ('adb shell getprop ro.boot.verifiedbootstate 2^>nul') do set "AVB_STATE=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.boot.flash.locked 2^>nul') do set "BOOT_LOCKED=%%A"

if /I "%AVB_STATE%"=="green" (
    call :OK "Android Verified Boot: GREEN."
    call :OK "GREEN corresponde al estado esperado para dispositivos de produccion."
) else (
    call :REVIEW "Android Verified Boot no se encuentra en GREEN. Valor detectado: %AVB_STATE%"
    echo Recomendaci�n: El OEM debe entregar equipos comerciales con Verified Boot en estado GREEN. >> "%SUMMARY%"
)

if "%BOOT_LOCKED%"=="1" (
    call :OK "Bootloader: LOCKED estado esperado para dispositivos de produccion."
) else (
    call :REVIEW "Bootloader no se encuentra bloqueado. Valor detectado: %BOOT_LOCKED%"
    echo Recomendacion: El bootloader debe estar bloqueado antes de distribucion o validacion comercial. >> "%SUMMARY%"
)

echo. >> "%SUMMARY%"
echo Referencia AVB: >> "%SUMMARY%"
echo GREEN  - Software OEM verificado. Estado esperado en produccion. >> "%SUMMARY%"
echo YELLOW - Imagen v�lida firmada con clave alternativa. >> "%SUMMARY%"
echo ORANGE - Bootloader desbloqueado. Sistema no confiable para produccion. >> "%SUMMARY%"
echo RED    - Imagen invalida o corrupta. >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 3. DLC PACKAGES / TRUSTONIC
REM ============================================================
call :SECTION "[3] INTEGRACION DLC / TRUSTONIC"

adb shell pm list packages 2>nul | findstr /I "dlc devicelock trustonic carrier telecoms telcelam teeservice tee" > "%TMP%"

if errorlevel 1 (
    call :REVIEW "No se detectaron paquetes relacionados con DLC, DeviceLock o Trustonic."
    echo Recomendacion: Validar que el OEM haya integrado los componentes DLC conforme a la gu�a de integracion correspondiente. >> "%SUMMARY%"
) else (
    call :OK "Paquetes relacionados con DLC / DeviceLock detectados."
)

adb shell pm list packages -f 2>nul | findstr /I "devicelock.apex com.android.devicelock" > "%TMP%"

if errorlevel 1 (
    call :INFO "No se detecto modulo DeviceLock APEX."
    echo Nota: Algunos dispositivos pueden integrar componentes DLC como APK de sistema y no necesariamente como modulo APEX. >> "%SUMMARY%"
) else (
    call :OK "Modulo DeviceLock APEX detectado."
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 4. DLC SERVICES
REM ============================================================
call :SECTION "[4] SERVICIOS DLC"

adb shell dumpsys activity services 2>nul | findstr /I "dlc devicelock DeviceLockService DeviceLockController" > "%TMP%"

if errorlevel 1 (
    call :INFO "No se detectaron servicios DLC visibles mediante diagn�stico Android."
echo. >> "%SUMMARY%"
    echo Nota: Algunos fabricantes restringen o no exponen esta informacion mediante Activity Manager. Esto no representa necesariamente un problema de integracion DLC y no impide continuar con el proceso de validacion. >> "%SUMMARY%"
) else (
    call :OK "Servicios relacionados con DLC o DeviceLock detectados."
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 5. CARRIERCONFIG
REM ============================================================
REM --- Propiedades SIM (pueden venir multi-SIM) ---
for /f "delims=" %%A in ('adb shell getprop gsm.sim.state 2^>nul') do set "SIM_STATE_RAW=%%A"
for /f "delims=" %%A in ('adb shell getprop gsm.sim.operator.numeric 2^>nul') do set "SIM_MCCMNC_RAW=%%A"
for /f "delims=" %%A in ('adb shell getprop gsm.sim.operator.iso-country 2^>nul') do set "SIM_ISO_RAW=%%A"

REM --- Tomar primer slot si hay multi-SIM ---
for /f "tokens=1 delims=," %%A in ("%SIM_STATE_RAW%") do set "SIM_STATE=%%A"
for /f "tokens=1 delims=," %%A in ("%SIM_MCCMNC_RAW%") do set "SIM_OPERATOR=%%A"
for /f "tokens=1 delims=," %%A in ("%SIM_ISO_RAW%") do set "ISO_COUNTRY=%%A"

REM --- Valores por defecto ---
if "%SIM_STATE%"=="" set "SIM_STATE=N/A"
if "%SIM_OPERATOR%"=="" set "SIM_OPERATOR=N/A"
if "%ISO_COUNTRY%"=="" set "ISO_COUNTRY=N/A"

echo Estado SIM: %SIM_STATE% >> "%SUMMARY%"
echo Operador SIM MCC/MNC: %SIM_OPERATOR% >> "%SUMMARY%"
echo Pa�s ISO: %ISO_COUNTRY% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

echo %SIM_STATE% | findstr /I "ABSENT NOT_READY N/A" >nul
if errorlevel 1 (
    call :OK "SIM detectada o informacion SIM disponible."
) else (
    call :INFO "SIM no detectada o informacion SIM no disponible."
    REM echo Nota: Algunos fabricantes activan par�metros CarrierConfig �nicamente cuando existe una SIM v�lida o una personalizaci�n asociada al operador. >> "%SUMMARY%"
)

REM echo. >> "%SUMMARY%"
adb shell dumpsys carrier_config 2>nul | findstr /I "call_screening_app" > "%TMP%"
findstr /I "trustonic" "%TMP%" >nul

if errorlevel 1 (
    call :INFO "CALL SCREENING no detectado o no asociado a DLC."
    REM echo Nota: En dispositivos Open Market o implementaciones que no utilizan gesti�n de llamadas, este par�metro puede no estar presente y no debe considerarse un bloqueo para continuar la validaci�n. >> "%SUMMARY%"
) else (
    call :OK "CALL SCREENING asociado a DLC detectado."
)

REM echo. >> "%SUMMARY%"
adb shell dumpsys carrier_config 2>nul | findstr /I "call_redirection_service_component_name_string" > "%TMP%"
findstr /I "trustonic" "%TMP%" >nul

if errorlevel 1 (
    call :INFO "CALL REDIRECTION no detectado o no asociado a DLC."
    REM echo Nota: En dispositivos Open Market o implementaciones que no utilizan gesti�n de llamadas, este par�metro puede no estar presente y no debe considerarse un bloqueo para continuar la validaci�n. >> "%SUMMARY%"
) else (
    call :OK "CALL REDIRECTION asociado a DLC detectado."
)

REM echo. >> "%SUMMARY%"
adb shell dumpsys carrier_config 2>nul | findstr /I "carrier_certificate_string_array" > "%TMP%"

findstr /I "com.trustonic.telecoms.standard.dlc" "%TMP%" >nul
if errorlevel 1 (
    call :INFO "CERTIFICADO DLC no detectado en CarrierConfig."
) else (
    call :OK "CERTIFICADO DLC detectado en CarrierConfig."
)

findstr /I "com.trustonic.telecoms.standard.dpc" "%TMP%" >nul
if errorlevel 1 (
    call :INFO "CERTIFICADO DPC no detectado en CarrierConfig."
) else (
    call :OK "CERTIFICADO DPC detectado en CarrierConfig."
)

findstr /I "co.sitic.pp" "%TMP%" >nul
if errorlevel 1 (
    call :INFO "CERTIFICADO co.sitic.pp no detectado en CarrierConfig."
) else (
    call :OK "CERTIFICADO co.sitic.pp detectado en CarrierConfig."
)

echo. >> "%SUMMARY%"
echo Nota CarrierConfig: >> "%SUMMARY%"
echo Algunas validaciones dependen de la implementacion del fabricante, la presencia de SIM activa y la configuracion espec�fica del operador. En dispositivos Open Market o configuraciones que no utilizan funcionalidades avanzadas de CarrierConfig, algunos parametros pueden no estar disponibles. >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 6. DEVELOPER MODE AND ADB
REM ============================================================
call :SECTION "[6] MODO DESARROLLADOR Y DEPURACION USB"

for /f "delims=" %%A in ('adb shell settings get global development_settings_enabled 2^>nul') do set "DEV_MODE=%%A"
for /f "delims=" %%A in ('adb shell settings get global adb_enabled 2^>nul') do set "ADB_ENABLED=%%A"

if "%DEV_MODE%"=="" set "DEV_MODE=N/A"
if "%ADB_ENABLED%"=="" set "ADB_ENABLED=N/A"

echo Estado detectado: >> "%SUMMARY%"
echo Opciones de desarrollador: %DEV_MODE% >> "%SUMMARY%"
echo Depuracion USB: %ADB_ENABLED% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

if "%DEV_MODE%"=="1" if "%ADB_ENABLED%"=="1" (
    call :INFO "Opciones de desarrollador y Depuracion USB habilitadas. Esto es esperado para ejecutar la herramienta en un entorno controlado."
) else if "%DEV_MODE%"=="0" if "%ADB_ENABLED%"=="0" (
    call :OK "Opciones de desarrollador y Depuraci�n USB deshabilitadas. Estado esperado para dispositivos comerciales."
) else if "%DEV_MODE%"=="1" if "%ADB_ENABLED%"=="0" (
    call :INFO "Opciones de desarrollador habilitadas, pero Depuracion USB deshabilitada."
    echo Nota: Para ejecutar DLC_Validator se requiere Depuracion USB habilitada y autorizacion ADB. >> "%SUMMARY%"
) else if "%DEV_MODE%"=="0" if "%ADB_ENABLED%"=="1" (
    call :INFO "Depuracion USB habilitada con Opciones de desarrollador no reportadas como activas."
    echo Nota: Algunos fabricantes pueden reportar estos valores de forma diferente. Validar el estado directamente en el dispositivo si es necesario. >> "%SUMMARY%"
) else (
    call :INFO "Estado de Opciones de desarrollador o Depuracion USB no disponible. El fabricante puede no reportar estos valores de forma estandar."
)

REM echo. >> "%SUMMARY%"
REM echo Nota: En dispositivos comerciales destinados a producci�n, normalmente se espera que Opciones de desarrollador y Depuraci�n USB permanezcan deshabilitadas. Durante pruebas de laboratorio o validaci�n t�cnica pueden estar habilitadas de forma controlada. >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 7. CARRIER ID
REM ============================================================
call :SECTION "[7] INFORMACION COMPLEMENTARIA DE CARRIER"

for /f "delims=" %%A in ('adb shell getprop persist.radio.carrier_id 2^>nul') do set "CARRIER_ID=%%A"

if "%CARRIER_ID%"=="" (
    call :INFO "Carrier ID no disponible."
    echo Nota: Algunos fabricantes no exponen esta informacion. La ausencia de Carrier ID no debe interpretarse como una falla de integracion DLC. >> "%SUMMARY%"
) else (
    call :OK "Carrier ID detectado."
)

echo. >> "%SUMMARY%"

REM ============================================================
REM FINAL RESULT
REM ============================================================
:END_REPORT

call :SECTION "RESULTADO GENERAL"

echo OK: %OK_COUNT% >> "%SUMMARY%"
echo INFO: %INFO_COUNT% >> "%SUMMARY%"
echo REVIEW: %REVIEW_COUNT% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

if %REVIEW_COUNT% GTR 0 (
    echo Estado general: VALIDACION COMPLETADA CON PUNTOS PARA REVISION >> "%SUMMARY%"
    echo Recomendacion general: Revisar los puntos marcados como [REVIEW] antes de considerar el dispositivo listo para validacion final. >> "%SUMMARY%"
) else (
    echo Estado general: VALIDACION COMPLETADA >> "%SUMMARY%"
    echo Resultado: No se identificaron puntos cr�ticos para revision en el resumen generado. >> "%SUMMARY%"
)

echo. >> "%SUMMARY%"
echo Archivo generado: %SUMMARY% >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"

if exist "%TMP%" del "%TMP%" >nul 2>&1

echo.
echo Proceso completado.
echo Archivo generado: %SUMMARY%
echo.
pause
exit /b

REM ============================================================
REM FUNCTIONS
REM ============================================================

:HEADER
echo ============================================================ >> "%SUMMARY%"
echo DLC VALIDATION REPORT >> "%SUMMARY%"
echo Versi�n de herramienta: 8.0.0 >> "%SUMMARY%"
echo Formato de reporte: Summary v1.0 >> "%SUMMARY%"
echo Fecha de ejecuci�n: %DATE% >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"
goto :eof

:SECTION
echo ============================================================ >> "%SUMMARY%"
echo %~1 >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"
goto :eof

:OK
set /a OK_COUNT+=1
echo [OK] %~1 >> "%SUMMARY%"
goto :eof

:INFO
set /a INFO_COUNT+=1
echo [INFO] %~1 >> "%SUMMARY%"
goto :eof

:REVIEW
set /a REVIEW_COUNT+=1
echo [REVIEW] %~1 >> "%SUMMARY%"
goto :eof

@echo off
REM ============================================================
REM DLC_Validator Summary
REM InternalName: DLC_Validator_Summary
REM Author: Mauricio Gutierrez
REM Department: Security / QA / DeviceLock Integration
REM ProductVersion: 2.0
REM FileVersion: 2.0.0
REM Output: DLC_Validator_Report.txt
REM ============================================================

chcp 65001 >nul
color 0B
setlocal EnableDelayedExpansion

set "SUMMARY=DLC_Validator_Report.txt"
set "TMP=%TEMP%\dlc_validator_summary_tmp.txt"

set /a OK_COUNT=0
set /a INFO_COUNT=0
set /a REVIEW_COUNT=0

if exist "%SUMMARY%" del "%SUMMARY%" >nul 2>&1
if exist "%TMP%" del "%TMP%" >nul 2>&1

echo ============================================================ >> "%SUMMARY%"
echo DLC VALIDATION REPORT >> "%SUMMARY%"
echo Version de herramienta: 2.0 >> "%SUMMARY%"
echo Formato de reporte: Summary v2.0 >> "%SUMMARY%"
echo Fecha de ejecucion: %DATE% >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 0. CONNECTED DEVICE
REM ============================================================
echo [0] DISPOSITIVO CONECTADO >> "%SUMMARY%"
echo. >> "%SUMMARY%"

adb devices > "%TMP%" 2>&1
findstr /R /C:"device$" "%TMP%" >nul

if errorlevel 1 (
    echo [REVIEW] No se detecto ningun dispositivo autorizado por ADB. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Conectar el dispositivo por USB, habilitar Depuracion USB y aceptar la autorizacion ADB en el telefono. >> "%SUMMARY%"
    echo. >> "%SUMMARY%"
    goto FINAL_REPORT
)

echo [OK] Dispositivo detectado correctamente mediante ADB. >> "%SUMMARY%"
set /a OK_COUNT+=1
echo. >> "%SUMMARY%"

REM ============================================================
REM 1. DEVICE INFORMATION
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [1] INFORMACION DEL DISPOSITIVO >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

for /f "delims=" %%A in ('adb shell getprop ro.product.vendor.manufacturer 2^>nul') do set "MANUFACTURER=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.product.vendor.model 2^>nul') do set "MODEL=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.version.release 2^>nul') do set "ANDROID_VERSION=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.version.sdk 2^>nul') do set "SDK_VERSION=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.build.type 2^>nul') do set "BUILD_TYPE=%%A"

if "%MANUFACTURER%"=="" set "MANUFACTURER=N/A"
if "%MODEL%"=="" set "MODEL=N/A"
if "%ANDROID_VERSION%"=="" set "ANDROID_VERSION=N/A"
if "%SDK_VERSION%"=="" set "SDK_VERSION=N/A"
if "%BUILD_TYPE%"=="" set "BUILD_TYPE=N/A"

echo Fabricante: %MANUFACTURER% >> "%SUMMARY%"
echo Modelo: %MODEL% >> "%SUMMARY%"
echo Version Android: %ANDROID_VERSION% >> "%SUMMARY%"
echo SDK Version: %SDK_VERSION% >> "%SUMMARY%"
echo Tipo de compilacion: %BUILD_TYPE% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

if "%SDK_VERSION%"=="N/A" (
    echo [REVIEW] No fue posible obtener el SDK Version del dispositivo. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Validar manualmente que el dispositivo use Android 14 / SDK 34 o superior. >> "%SUMMARY%"
) else (
    if %SDK_VERSION% GEQ 34 (
        echo [OK] SDK compatible para DLC v2. Android 14 / SDK 34 o superior. >> "%SUMMARY%"
        set /a OK_COUNT+=1
    ) else (
        echo [REVIEW] SDK inferior al recomendado para DLC v2. >> "%SUMMARY%"
        set /a REVIEW_COUNT+=1
        echo Recomendacion: El dispositivo debe utilizar Android 14 / SDK 34 o superior para validaciones DLC v2. >> "%SUMMARY%"
    )
)

if /I "%BUILD_TYPE%"=="user" (
    echo [OK] Software de produccion detectado - USER. >> "%SUMMARY%"
    set /a OK_COUNT+=1
) else (
    echo [REVIEW] Tipo de compilacion no corresponde a USER. Valor detectado: %BUILD_TYPE% >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Para validaciones de produccion se recomienda utilizar software tipo USER. Valores como userdebug o eng corresponden normalmente a entornos de laboratorio o desarrollo. >> "%SUMMARY%"
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 2. VERIFIED BOOT / BOOTLOADER
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [2] ESTADO DE SEGURIDAD ANDROID >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

for /f "delims=" %%A in ('adb shell getprop ro.boot.verifiedbootstate 2^>nul') do set "AVB_STATE=%%A"
for /f "delims=" %%A in ('adb shell getprop ro.boot.flash.locked 2^>nul') do set "BOOT_LOCKED=%%A"

if "%AVB_STATE%"=="" set "AVB_STATE=N/A"
if "%BOOT_LOCKED%"=="" set "BOOT_LOCKED=N/A"

if /I "%AVB_STATE%"=="green" (
    echo [OK] Android Verified Boot: GREEN. >> "%SUMMARY%"
    echo [OK] GREEN corresponde al estado esperado para dispositivos de produccion. >> "%SUMMARY%"
    set /a OK_COUNT+=2
) else (
    echo [REVIEW] Android Verified Boot no se encuentra en GREEN. Valor detectado: %AVB_STATE% >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: El OEM debe entregar equipos comerciales con Verified Boot en estado GREEN. >> "%SUMMARY%"
)

if "%BOOT_LOCKED%"=="1" (
    echo [OK] Bootloader: LOCKED estado esperado para dispositivos de produccion. >> "%SUMMARY%"
    set /a OK_COUNT+=1
) else (
    echo [REVIEW] Bootloader no se encuentra bloqueado. Valor detectado: %BOOT_LOCKED% >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: El bootloader debe estar bloqueado antes de distribucion o validacion comercial. >> "%SUMMARY%"
)

echo. >> "%SUMMARY%"
echo Referencia AVB: >> "%SUMMARY%"
echo GREEN  - Software OEM verificado. Estado esperado en produccion. >> "%SUMMARY%"
echo YELLOW - Imagen valida firmada con clave alternativa. >> "%SUMMARY%"
echo ORANGE - Bootloader desbloqueado. Sistema no confiable para produccion. >> "%SUMMARY%"
echo RED    - Imagen invalida o corrupta. >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 3. DLC PACKAGES / TRUSTONIC
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [3] INTEGRACION DLC / TRUSTONIC >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

adb shell pm list packages 2>nul | findstr /I "dlc devicelock trustonic carrier telecoms telcelam teeservice tee" > "%TMP%"

if errorlevel 1 (
    echo [REVIEW] No se detectaron paquetes relacionados con DLC, DeviceLock o Trustonic. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Validar que el OEM haya integrado los componentes DLC conforme a la guia de integracion correspondiente. >> "%SUMMARY%"
) else (
    echo [OK] Paquetes relacionados con DLC / DeviceLock detectados. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

adb shell pm list packages -f 2>nul | findstr /I "devicelock.apex com.android.devicelock" > "%TMP%"

if errorlevel 1 (
    echo [INFO] No se detecto modulo DeviceLock APEX. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
    echo Nota: Algunos dispositivos pueden integrar componentes DLC como APK de sistema y no necesariamente como modulo APEX. >> "%SUMMARY%"
) else (
    echo [OK] Modulo DeviceLock APEX detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 4. DLC SERVICES
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [4] SERVICIOS DLC >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

adb shell dumpsys activity services 2>nul | findstr /I "dlc devicelock DeviceLockService DeviceLockController" > "%TMP%"

if errorlevel 1 (
    echo [INFO] No se detectaron servicios DLC visibles mediante diagnostico Android. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
    echo Nota: Algunos fabricantes restringen o no exponen esta informacion mediante Activity Manager. Esto no representa necesariamente un problema de integracion DLC y no impide continuar con el proceso de validacion. >> "%SUMMARY%"
) else (
    echo [OK] Servicios relacionados con DLC o DeviceLock detectados. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 5. CARRIERCONFIG
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [5] CARRIERCONFIG >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

for /f "delims=" %%A in ('adb shell getprop gsm.sim.state 2^>nul') do set "SIM_STATE_RAW=%%A"
for /f "delims=" %%A in ('adb shell getprop gsm.sim.operator.numeric 2^>nul') do set "SIM_MCCMNC_RAW=%%A"
for /f "delims=" %%A in ('adb shell getprop gsm.sim.operator.iso-country 2^>nul') do set "SIM_ISO_RAW=%%A"

for /f "tokens=1 delims=," %%A in ("%SIM_STATE_RAW%") do set "SIM_STATE=%%A"
for /f "tokens=1 delims=," %%A in ("%SIM_MCCMNC_RAW%") do set "SIM_OPERATOR=%%A"
for /f "tokens=1 delims=," %%A in ("%SIM_ISO_RAW%") do set "ISO_COUNTRY=%%A"

if "%SIM_STATE%"=="" set "SIM_STATE=N/A"
if "%SIM_OPERATOR%"=="" set "SIM_OPERATOR=N/A"
if "%ISO_COUNTRY%"=="" set "ISO_COUNTRY=N/A"

echo Estado SIM: %SIM_STATE% >> "%SUMMARY%"
echo Operador SIM MCC/MNC: %SIM_OPERATOR% >> "%SUMMARY%"
echo Pais ISO: %ISO_COUNTRY% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

echo %SIM_STATE% | findstr /I "ABSENT NOT_READY N/A" >nul
if errorlevel 1 (
    echo [OK] SIM detectada o informacion SIM disponible. >> "%SUMMARY%"
    set /a OK_COUNT+=1
) else (
    echo [INFO] SIM no detectada o informacion SIM no disponible. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
)

adb shell dumpsys carrier_config 2>nul | findstr /I "call_screening_app" > "%TMP%"
findstr /I "trustonic" "%TMP%" >nul

if errorlevel 1 (
    echo [INFO] CALL SCREENING no detectado o no asociado a DLC. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CALL SCREENING asociado a DLC detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

adb shell dumpsys carrier_config 2>nul | findstr /I "call_redirection_service_component_name_string" > "%TMP%"
findstr /I "trustonic" "%TMP%" >nul

if errorlevel 1 (
    echo [INFO] CALL REDIRECTION no detectado o no asociado a DLC. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CALL REDIRECTION asociado a DLC detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

adb shell dumpsys carrier_config 2>nul | findstr /I "carrier_certificate_string_array" > "%TMP%"

findstr /I "com.trustonic.telecoms.standard.dlc" "%TMP%" >nul
if errorlevel 1 (
    echo [INFO] CERTIFICADO DLC no detectado en CarrierConfig. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CERTIFICADO DLC detectado en CarrierConfig. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

findstr /I "com.trustonic.telecoms.standard.dpc" "%TMP%" >nul
if errorlevel 1 (
    echo [INFO] CERTIFICADO DPC no detectado en CarrierConfig. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CERTIFICADO DPC detectado en CarrierConfig. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

findstr /I "co.sitic.pp" "%TMP%" >nul
if errorlevel 1 (
    echo [INFO] CERTIFICADO co.sitic.pp no detectado en CarrierConfig. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CERTIFICADO co.sitic.pp detectado en CarrierConfig. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

echo. >> "%SUMMARY%"
echo Nota CarrierConfig: >> "%SUMMARY%"
echo Algunas validaciones dependen de la implementacion del fabricante, la presencia de SIM activa y la configuracion especifica del operador. En dispositivos Open Market o configuraciones que no utilizan funcionalidades avanzadas de CarrierConfig, algunos parametros pueden no estar disponibles. >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 6. DEVELOPER MODE AND ADB
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [6] MODO DESARROLLADOR Y DEPURACION USB >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

for /f "delims=" %%A in ('adb shell settings get global development_settings_enabled 2^>nul') do set "DEV_MODE=%%A"
for /f "delims=" %%A in ('adb shell settings get global adb_enabled 2^>nul') do set "ADB_ENABLED=%%A"

if "%DEV_MODE%"=="" set "DEV_MODE=N/A"
if "%ADB_ENABLED%"=="" set "ADB_ENABLED=N/A"

echo Estado detectado: >> "%SUMMARY%"
echo Opciones de desarrollador: %DEV_MODE% >> "%SUMMARY%"
echo Depuracion USB: %ADB_ENABLED% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

set "DEV_ADB_STATE=%DEV_MODE%_%ADB_ENABLED%"

if "%DEV_ADB_STATE%"=="1_1" (
    echo [INFO] Opciones de desarrollador y Depuracion USB habilitadas. Esto es esperado para ejecutar la herramienta en un entorno controlado. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    if "%DEV_ADB_STATE%"=="0_0" (
        echo [OK] Opciones de desarrollador y Depuracion USB deshabilitadas. Estado esperado para dispositivos comerciales. >> "%SUMMARY%"
        set /a OK_COUNT+=1
    ) else (
        echo [INFO] Estado de Opciones de desarrollador o Depuracion USB no disponible o reportado de forma diferente por el fabricante. >> "%SUMMARY%"
        set /a INFO_COUNT+=1
    )
)

echo. >> "%SUMMARY%"

REM ============================================================
REM 7. CARRIER ID
REM ============================================================
echo ============================================================ >> "%SUMMARY%"
echo [7] INFORMACION COMPLEMENTARIA DE CARRIER >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

for /f "delims=" %%A in ('adb shell getprop persist.radio.carrier_id 2^>nul') do set "CARRIER_ID=%%A"

if "%CARRIER_ID%"=="" (
    echo [INFO] Carrier ID no disponible. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
    echo Nota: Algunos fabricantes no exponen esta informacion. La ausencia de Carrier ID no debe interpretarse como una falla de integracion DLC. >> "%SUMMARY%"
) else (
    echo [OK] Carrier ID detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

echo. >> "%SUMMARY%"

REM ============================================================
REM FINAL RESULT
REM ============================================================
:FINAL_REPORT

echo ============================================================ >> "%SUMMARY%"
echo RESULTADO GENERAL >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

echo OK: %OK_COUNT% >> "%SUMMARY%"
echo INFO: %INFO_COUNT% >> "%SUMMARY%"
echo REVIEW: %REVIEW_COUNT% >> "%SUMMARY%"
echo. >> "%SUMMARY%"

if %REVIEW_COUNT% GTR 0 (
    echo Estado general: VALIDACION COMPLETADA CON PUNTOS PARA REVISION >> "%SUMMARY%"
    echo Recomendacion general: Revisar los puntos marcados como [REVIEW] antes de considerar el dispositivo listo para validacion final. >> "%SUMMARY%"
) else (
    echo Estado general: VALIDACION COMPLETADA >> "%SUMMARY%"
    echo Resultado: No se identificaron puntos criticos para revision en el resumen generado. >> "%SUMMARY%"
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

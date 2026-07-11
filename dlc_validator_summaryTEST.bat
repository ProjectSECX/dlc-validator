@echo off
REM ============================================================
REM DLC_Validator Summary
REM InternalName: DLC_Validator_Summary
REM Author: Mauricio Gutierrez
REM Department: Security / QA / DeviceLock Integration
REM ProductVersion: 3.0
REM FileVersion: 3.0.0
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
echo Version de herramienta: 3.0 >> "%SUMMARY%"
echo Formato de reporte: Summary v3.0 >> "%SUMMARY%"
echo Fecha de ejecucion: %DATE% >> "%SUMMARY%"
echo ============================================================ >> "%SUMMARY%"
echo. >> "%SUMMARY%"

REM ============================================================
REM 0. CONNECTED DEVICE
REM ============================================================
echo [0] DISPOSITIVO CONECTADO >> "%SUMMARY%"
echo. >> "%SUMMARY%"

adb start-server >nul 2>&1
adb devices > "%TMP%" 2>&1

findstr /I "unauthorized" "%TMP%" >nul
if not errorlevel 1 (
    echo [REVIEW] Dispositivo conectado pero no autorizado para ADB. >> "%SUMMARY%"
    echo Accion: Acepte la clave RSA en el telefono y vuelva a ejecutar DLC Validator Summary. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1

    echo.
    echo Dispositivo no autorizado para ADB.
    echo Acepte la clave RSA en el telefono.
    echo Luego vuelva a ejecutar DLC Validator Summary.
    echo.
    pause
    exit /b 10
)

findstr /I "offline" "%TMP%" >nul
if not errorlevel 1 (
    echo [REVIEW] Dispositivo detectado en estado OFFLINE mediante ADB. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Reconectar el cable USB, verificar la Depuracion USB y ejecutar nuevamente la herramienta. >> "%SUMMARY%"
    echo. >> "%SUMMARY%"
    goto FINAL_REPORT
)

findstr /R /C:"device$" "%TMP%" >nul
if errorlevel 1 (
    echo [REVIEW] No se detecto ningun dispositivo autorizado por ADB. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Conectar el dispositivo por USB, habilitar Depuracion USB y aceptar la autorizacion ADB en el telefono. >> "%SUMMARY%"
    echo. >> "%SUMMARY%"
    goto FINAL_REPORT
)

echo [OK] Dispositivo detectado y autorizado correctamente mediante ADB. >> "%SUMMARY%"
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

adb shell pm list packages 2>nul | findstr /I "com.google.android.devicelockcontroller" > "%TMP%"

if errorlevel 1 (
    echo [REVIEW] Google Device Lock Controller no detectado. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Recomendacion: Validar que el OEM haya integrado Google Device Lock Controller conforme a la guia de integracion DLC. >> "%SUMMARY%"
) else (
    echo [OK] Google Device Lock Controller detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

adb shell pm list packages -f 2>nul | findstr /I "devicelock.apex com.android.devicelock" > "%TMP%"

if errorlevel 1 (
    echo [INFO] No se detecto modulo DeviceLock APEX. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
    echo Nota: Algunos dispositivos pueden integrar componentes DeviceLock como APK de sistema y no necesariamente como modulo APEX. >> "%SUMMARY%"
) else (
    echo [OK] Modulo DeviceLock APEX detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

adb shell pm list packages -d 2>nul | findstr /I "com.google.android.devicelockcontroller com.trustonic.telecoms.standard.dlc com.trustonic.telecoms.standard.dpc" > "%TMP%"

if errorlevel 1 (
    echo [OK] Paquetes DLC relacionados habilitados. >> "%SUMMARY%"
    set /a OK_COUNT+=1
) else (
    echo [REVIEW] Se detectaron paquetes DLC relacionados deshabilitados. >> "%SUMMARY%"
    set /a REVIEW_COUNT+=1
    echo Paquetes deshabilitados detectados: >> "%SUMMARY%"
    type "%TMP%" >> "%SUMMARY%"
    echo Accion: Inserte una SIM activa, reinicie el dispositivo y repita la prueba. Algunas configuraciones pueden habilitarse despues de cargar el perfil del operador. >> "%SUMMARY%"
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

set "SIM_AVAILABLE=1"
echo %SIM_STATE% | findstr /I "ABSENT NOT_READY UNKNOWN N/A" >nul
if not errorlevel 1 set "SIM_AVAILABLE=0"

if "%SIM_AVAILABLE%"=="1" (
    echo [OK] SIM detectada e informacion disponible. >> "%SUMMARY%"
    set /a OK_COUNT+=1
) else (
    echo [INFO] SIM no detectada o informacion SIM no disponible. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
)

adb shell dumpsys carrier_config 2>nul > "%TMP%"

findstr /I "call_screening_app" "%TMP%" | findstr /I "com.trustonic.telecoms.standard.dlc" >nul
if errorlevel 1 (
    if "%SIM_AVAILABLE%"=="1" (
        echo [REVIEW] CALL SCREENING no detectado o no asociado a DLC. >> "%SUMMARY%"
        set /a REVIEW_COUNT+=1
    ) else (
        echo [INFO] CALL SCREENING no detectado o no asociado a DLC. >> "%SUMMARY%"
        set /a INFO_COUNT+=1
    )
) else (
    echo [OK] CALL SCREENING asociado a DLC detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

findstr /I "call_redirection_service_component_name_string" "%TMP%" | findstr /I "com.trustonic.telecoms.standard.dlc" >nul
if errorlevel 1 (
    if "%SIM_AVAILABLE%"=="1" (
        echo [REVIEW] CALL REDIRECTION no detectado o no asociado a DLC. >> "%SUMMARY%"
        set /a REVIEW_COUNT+=1
    ) else (
        echo [INFO] CALL REDIRECTION no detectado o no asociado a DLC. >> "%SUMMARY%"
        set /a INFO_COUNT+=1
    )
) else (
    echo [OK] CALL REDIRECTION asociado a DLC detectado. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

findstr /I "carrier_config call_screening_app call_redirection_service_component_name_string" "%TMP%" >nul
if errorlevel 1 (
    echo [INFO] CarrierConfig no expuso informacion suficiente mediante diagnostico Android. >> "%SUMMARY%"
    set /a INFO_COUNT+=1
) else (
    echo [OK] CarrierConfig disponible y consultado correctamente. >> "%SUMMARY%"
    set /a OK_COUNT+=1
)

echo. >> "%SUMMARY%"
echo Nota CarrierConfig: >> "%SUMMARY%"
En equipos Open Market o sin SIM, algunos datos pueden no estar disponibles. Si faltan resultados esperados, inserte una SIM activa de operador, reinicie el dispositivo y repita la prueba. >> "%SUMMARY%"
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
    echo [OK] Opciones de desarrollador y Depuracion USB habilitadas para la ejecucion de la herramienta. >> "%SUMMARY%"
    set /a OK_COUNT+=1
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
    echo [OK] Carrier ID no disponible - parametro no critico. >> "%SUMMARY%"
    set /a OK_COUNT+=1
    echo Nota: Algunos fabricantes no exponen esta informacion. La ausencia de Carrier ID no representa una falla de integracion DLC. >> "%SUMMARY%"
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
) else (
    echo Estado general: VALIDACION COMPLETADA >> "%SUMMARY%"
)

echo Revise los elementos marcados como INFO y REVIEW en las secciones anteriores. >> "%SUMMARY%"

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

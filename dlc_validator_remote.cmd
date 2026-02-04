@echo off
REM ==== DeviceLock Validation Tool ====
REM CompanyName: TRUSTONIC
REM ProductName: TRUSTONIC DeviceLock Validation Tool
REM FileDescription: Internal tool for auditing DLC v2 carrier integration in Android devices.
REM OriginalFileName: DLC Validator.bat/exe
REM InternalName: DLC Validator
REM Author: Mauricio Gutiérrez
REM Department: Seguridad / QA / DeviceLock Integration
REM ProductVersion: 1.0
REM FileVersion: 7.0.0
REM Trademark: TRUSTONIC
REM Copyright: © 2025 TRUSTONIC – All rights reserved.
REM Comments: Internal Use Only – Do Not Redistribute.
REM ExeType: console
REM Architecture: x64
REM ==== DeviceLock Validation Tool ====

set LOG=dlc_check_log.txt

echo ================================================ > "%LOG%"
echo VERIFICATION DLC / CARRIERCONFIG / SECURITY >> "%LOG%"
echo Fecha de ejecucion: %DATE% >> "%LOG%"
echo ================================================ >> "%LOG%"
echo. >> "%LOG%"

echo ================================================
echo VERIFICATION DLC / CARRIERCONFIG / SECURITY
echo Fecha de ejecucion: %DATE%
echo ================================================
echo.

REM -------------------------------------------------
REM 0. DISPOSITIVO CONECTADO
REM -------------------------------------------------
echo [0] CONNECTED DEVICE
echo [0] CONNECTED DEVICE >> "%LOG%"

adb devices >> "%LOG%"
echo. >> "%LOG%"
echo.

REM -------------------------------------------------
REM 1. VERSION DE ANDROID / FABRICANTE / MODELO
REM -------------------------------------------------
echo ========================================================================================= >> "%LOG%"
echo [1] ANDROID VERSION / MANUFACTURER / MODEL
echo [1] ANDROID VERSION / MANUFACTURER / MODEL >> "%LOG%"
echo. >> "%LOG%"
echo MANUFACTURER: >> "%LOG%"
adb shell getprop ro.product.vendor.manufacturer >> "%LOG%"
echo MODEL: >> "%LOG%"
adb shell getprop ro.product.vendor.model >> "%LOG%"
echo ANDROID VERSION: >> "%LOG%"
adb shell getprop ro.build.version.release >> "%LOG%"
echo SDK VERSION: >> "%LOG%"
adb shell getprop ro.build.version.sdk >> "%LOG%"
echo SECURITY BUILD TYPE USER-ENG-USERDEBUG: >> "%LOG%"
adb shell getprop ro.build.type >> "%LOG%"
echo. >> "%LOG%"
echo Nota: SDK 34 corresponde a Android 14, oficialmente requerido para DLC v2. >> "%LOG%"
echo Solucion: Si el SDK es inferior a 34, el fabricante de equipos originales debe actualizar la ROM a Android 14 o superior. >> "%LOG%"
echo. >> "%LOG%"
echo Nota: ro.build.type Normalmente deberia ser ((user)) en los dispositivos de produccion. >> "%LOG%"
echo Solucion: Si el valor es ((eng)) o ((userdebug)), es solo para uso no comercial en laboratorio. >> "%LOG%"
echo. >> "%LOG%"
echo.
echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 2. VERIFIED BOOT Y BOOTLOADER
REM -------------------------------------------------
echo [2] VERIFIED BOOT Y BOOTLOADER
echo [2] VERIFIED BOOT Y BOOTLOADER >> "%LOG%"
echo. >> "%LOG%"
echo ANDROID VERIFIED BOOT - AVB AUTHENTIC ROM: >> "%LOG%"
adb shell getprop ro.boot.verifiedbootstate >> "%LOG%"
echo. >> "%LOG%"
echo Nota: green  = Arranque verificado con clave OEM (estado esperado en produccion). >> "%LOG%"
echo Nota: yellow = Imagen valida pero no firmada con la clave principal del OEM. >> "%LOG%"
echo Nota: orange = Bootloader desbloqueado; el sistema no es confiable para produccion. >> "%LOG%"
echo Nota: red    = Imagen corrupta o firma invalida (no arranca normalmente). >> "%LOG%"
echo. >> "%LOG%"
echo Solucion:    El OEM debe entregar equipos comerciales con verifiedbootstate en "green". >> "%LOG%"
echo. >> "%LOG%"

echo BOOTLOADER STATUS: >> "%LOG%"
adb shell getprop ro.boot.flash.locked >> "%LOG%"
echo Nota: 1 = bootloader bloqueado (locked). >> "%LOG%"
echo Nota: 0 = bootloader desbloqueado (unlocked). >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: Si el valor es 0 en dispositivos de produccion, el OEM debe bloquear el bootloader antes de la distribucion final. >> "%LOG%"
echo. >> "%LOG%"
echo.

echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 3. DLC PACKAGES / TRUSTONIC INSTALLED
REM -------------------------------------------------
echo [3] DLC PACKAGES / TRUSTONIC
echo [3] DLC PACKAGES / TRUSTONIC >> "%LOG%"
echo. >> "%LOG%"
echo TRUSTONIC STANDARD DLC PACKAGES LIST >> "%LOG%"
adb shell pm list packages | findstr /I "dlc devicelock trustonic standard telecoms teeservice" >> "%LOG%"
echo. >> "%LOG%"
REM --------------------------------------------------------------------------------------
REM 2. OBTENCION DE RUTAS (PATHS) DE PAQUETES CRITICOS Y CONOCIDOS
REM    Obtiene las rutas solo de los paquetes que son fundamentales para el DLC/Bloqueo
REM    (No requiere que el paquete exista, el comando solo devolvera el path si lo encuentra).
REM --------------------------------------------------------------------------------------
echo TRUSTONIC - DLC - PACKAGE PATH: >> "%LOG%"
adb shell pm path com.google.android.devicelockcontroller >> "%LOG%"
adb shell pm path com.google.android.overlay.devicelockcontroller >> "%LOG%"
adb shell pm path com.trustonic.telecoms.standard.dlc >> "%LOG%"
adb shell pm path com.trustonic.teeservice >> "%LOG%"
adb shell pm path com.telcelam.lockscreen >> "%LOG%"
adb shell pm path com.trustonic.telecoms.standard.dlc >> "%LOG%"
adb shell pm path com.trustonic.teeservice >> "%LOG%"

echo. >> "%LOG%"
echo DEVICELOCK APEX MODULES >> "%LOG%"
adb shell pm list packages -f --apex-only --show-versioncode | findstr /I "devicelock dlc trustonic" >> "%LOG%"
echo. >> "%LOG%"
echo Nota: Esta seccion valida la correcta integracion de DLC por parte del OEM, tanto a nivel de aplicacion de sistema (APK) como modulos de sistema (APEX). >> "%LOG%"
echo       Si no se detectan paquetes Trustonic/DLC, el cliente DLC no esto instalado como aplicacion de sistema. >> "%LOG%"
echo       Si no hay salida en la lista de modulos APEX, significa que no existen componentes DLC integrados como APEX en el dispositivo. >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: El OEM debe integrar DLC conforme a la guia de Trustonic, como aplicacion de sistema (APK) o como modulo APEX, asegurando su presencia en las rutas de sistema correspondientes. >> "%LOG%"
echo           /system/priv-app/ - /system_ext/priv-app/ - /apex/com.android.devicelock/ >> "%LOG%"
echo. >> "%LOG%"
echo.

echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 4. DLC SERVICES IN ACTIVITY MANAGER
REM -------------------------------------------------
echo [4] DLC SERVICES IN ACTIVITY MANAGER
echo [4] DLC SERVICES IN ACTIVITY MANAGER >> "%LOG%"
echo. >> "%LOG%"
echo DLC SERVICE STATUS >> "%LOG%"
adb shell dumpsys activity services | findstr /I "dlc devicelock DeviceLock DeviceLockController" >> "%LOG%"
REM Solo busqueda para evaluar si hubo coincidencias
adb shell dumpsys activity services | findstr /I "dlc devicelock DeviceLock DeviceLockController" >nul
echo. >> "%LOG%"
IF ERRORLEVEL 1 (
	echo [ADVERTENCIA] No se encontraron servicios relacionados con DLC o DeviceLock. >> "%LOG%"
) ELSE (
	echo [OK] Se detectaron servicios relacionados con DLC o DeviceLock ver listado. >> "%LOG%"
)
echo. >> "%LOG%"
echo Nota: Si no se muestra ningun servicio, DLC puede no estar corriendo o no estar registrado en System Server. >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: El OEM debe verificar el manifest de DLC, los permisos y la integracion en el arranque del sistema (system_server). >> "%LOG%"
echo. >> "%LOG%"
echo.

echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 5. CARRIERCONFIG - CALL SCREENING / REDIRECTION / CERTS
REM -------------------------------------------------
echo [5] CARRIERCONFIG - CRITICAL PARAMETERS
echo [5] CARRIERCONFIG - CRITICAL PARAMETERS >> "%LOG%"
echo. >> "%LOG%"
echo FILTRADO DE LLAMADAS DLC Call_Screening: >> "%LOG%"
adb shell dumpsys carrier_config | findstr /I "call_screening_app" >> "%LOG%"
echo. >> "%LOG%"
echo Nota: El parametro call_screening_app debe apuntar al servicio CallScreeningService de DLC. Este servicio gestiona las llamadas entrantes (IC), permitiendo aplicar politicas en estado de bloqueo por DLC. >> "%LOG%"
echo. >> "%LOG%"
echo Ejemplo esperado: >> "%LOG%"
echo App y servicio - com.trustonic.telecoms.standard.dlc/com.trustonic.telecoms.entrypoint.carrier.CallScreeningService >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: Si el valor esta vacio o no contiene "trustonic", el OEM debe actualizar los XML de CarrierConfig para asignar correctamente el componente de CallScreeningService. >> "%LOG%"
echo. >> "%LOG%"

echo CALL REDIRECTION CONFIG: >> "%LOG%"
adb shell dumpsys carrier_config | findstr /I "call_redirection_service_component_name_string" >> "%LOG%"
echo. >> "%LOG%"
echo Nota: El parámetro debe apuntar a CallRedirectionService, que gestiona llamadas salientes y permite a DLC, redirigir o bloquear segun el estado del dispositivo. >> "%LOG%"
echo. >> "%LOG%"
echo Ejemplo esperado: >> "%LOG%"
echo App y servicio - com.trustonic.telecoms.standard.dlc/com.trustonic.telecoms.entrypoint.carrier.CallRedirectionService >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: Si el valor es "null", vacio o no contiene "trustonic", el OEM debe configurar el componente CallRedirectionService en los XML de CarrierConfig. >> "%LOG%"
echo. >> "%LOG%"

echo CARRIER CERTIFICATES 1913-T: >> "%LOG%"
adb shell dumpsys carrier_config | findstr /I "carrier_certificate_string_array" >> "%LOG%"
echo. >> "%LOG%"

echo PATH CARRIERCONFIG >> "%LOG%"
adb shell pm list packages | findstr /I "carrierconfig" >> "%LOG%"
adb shell pm path com.android.carrierconfig >> "%LOG%"
echo. >> "%LOG%"

REM ====== VALIDACION DE CERTIFICADOS (VC valida si existe o no) ======

REM --- Certificado DLC ---
adb shell dumpsys carrier_config | findstr /I "carrier_certificate_string_array" | findstr /I "com.trustonic.telecoms.standard.dlc" >nul
IF ERRORLEVEL 1 (
    echo [ADVERTENCIA] Falta certificado de com.trustonic.telecoms.standard.dlc >> "%LOG%"
) ELSE (
    echo [OK] Certificado DLC encontrado en carrier_certificate_string_array >> "%LOG%"
)

REM --- Certificado DPC ---
adb shell dumpsys carrier_config | findstr /I "carrier_certificate_string_array" | findstr /I "com.trustonic.telecoms.standard.dpc" >nul
IF ERRORLEVEL 1 (
    echo [ADVERTENCIA] Falta certificado de com.trustonic.telecoms.standard.dpc >> "%LOG%"
) ELSE (
    echo [OK] Certificado DPC encontrado en carrier_certificate_string_array >> "%LOG%"
)

REM --- Certificado co.sitic.pp ---
adb shell dumpsys carrier_config | findstr /I "carrier_certificate_string_array" | findstr /I "co.sitic.pp" >nul
IF ERRORLEVEL 1 (
    echo [ADVERTENCIA] Falta certificado de co.sitic.pp (si este aplica para AMX) >> "%LOG%"
) ELSE (
    echo [OK] Certificado co.sitic.pp encontrado en carrier_certificate_string_array >> "%LOG%"
)

echo. >> "%LOG%"
echo Nota: El parametro carrier_certificate debe contener certificados del carrier y de las apps autorizadas (DLC/DPC/co.sitic.pp). Si el valor es [] o vacio, no hay certificados de carrier configurados. >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: El OEM debe integrar los archivos XML de CarrierConfig correctos e incluir los certificados SHA1/SHA256 requeridos para DLC y las apps de carrier. >> "%LOG%"
echo. >> "%LOG%"
echo.
echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 6. DEVELOPER MODE AND ADB
REM -------------------------------------------------
echo [6] DEVELOPER MODE AND ADB STATUS
echo [6] DEVELOPER MODE AND ADB STATUS >> "%LOG%"
echo. >> "%LOG%"
echo DEVELOPER MODE CHECK: >> "%LOG%"
adb shell settings get global development_settings_enabled >> "%LOG%"
echo Nota: 1 = opciones de desarrollador activadas. >> "%LOG%"
echo Nota: 0 = opciones de desarrollador desactivadas. >> "%LOG%"
echo. >> "%LOG%"
echo USB DEBUGGING STATE: >> "%LOG%"
adb shell settings get global adb_enabled >> "%LOG%"
echo Nota: 1 = depuracion USB activada. >> "%LOG%"
echo Nota: 0 = depuracion USB desactivada. >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: En dispositivos de produccion con MDM/DLC activos, ambos valores deben permanecer en 0 para evitar vectores de ataque por ADB. Si alguno esta en 1, debe justificarse unicamente en entornos de prueba controlados. >> "%LOG%"
echo. >> "%LOG%"
echo.
echo ========================================================================================= >> "%LOG%"
REM -------------------------------------------------
REM 7. CARRIER ID (CARRIERCONFIG PROFILE)
REM -------------------------------------------------
echo [7] CARRIER ID
echo [7] CARRIER ID >> "%LOG%"
echo. >> "%LOG%"
echo ACTIVE CARRIER CHECK: >> "%LOG%"
adb shell getprop persist.radio.carrier_id >> "%LOG%"
echo. >> "%LOG%"
echo Nota: El carrier_id define que perfil de CarrierConfig se aplica al dispositivo. >> "%LOG%"
echo. >> "%LOG%"
echo Ejemplo: para TELCEL suele ser 1913. >> "%LOG%"
echo. >> "%LOG%"
echo Solucion: Si el carrier_id no coincide con el operador esperado, el OEM debe revisar el mapeo de carrier y los XML de CarrierConfig para asegurar que se aplique el perfil correcto. >> "%LOG%"
echo. >> "%LOG%"
echo.

echo ================================================ >> "%LOG%"
echo End of verification >> "%LOG%"
echo Generated file: %LOG% >> "%LOG%"
echo ================================================ >> "%LOG%"

echo.
echo Process completed. File generated.: %LOG%
set /p dummy="Press ENTER to close this window.... "

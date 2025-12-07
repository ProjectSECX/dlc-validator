# dlc-validator
Internal tool for auditing DLC v2 carrier integration in Android devices.

DLC Validator
Herramienta interna para la validación técnica de DLC v2, CarrierConfig, y parámetros de seguridad en dispositivos Android para entornos de prueba y certificación OEM/Carrier.

Uso exclusivo interno. No distribuir fuera de la organización.
🔍 Descripción
DLC Validator es una herramienta automatizada que ejecuta una serie de verificaciones ADB para validar la correcta integración de:
- Device Lock Controller (DLC v2)
- Componentes CarrierConfig requeridos por Trustonic y AMX
- Certificados del carrier y apps autorizadas
- Servicios activos del módulo DLC
- Propiedades de Verified Boot / Bootloader
- Estado de depuración y opciones de desarrollador
- Presencia del paquete DLC y funcionamiento básico

El objetivo es identificar de forma rápida y estandarizada si un dispositivo cumple o no con los requerimientos técnicos establecidos en la documentación de integración OEM.

El repositorio contiene siempre la versión más reciente del script maestro utilizado por el bootstrap del analizador.

⚙️ Cómo usar DLC Validator En el PC (Windows 10/11)

Instalar ADB Platform Tools (o tenerlas en el PATH del sistema).
Conectar el dispositivo Android con Depuración USB activada.
Ejecutar:

DLC_Validator.bat

Este archivo:
Descarga automáticamente la última versión del script maestro desde este repositorio.

Ejecuta el análisis.
Genera un archivo de reporte dlc_check_log.txt con resultados detallados.

Actualización automática
El archivo principal del análisis se almacena en este repositorio como:

dlc_validator_remote.cmd

El mini-lanzador (DLC_Validator.bat):

Descarga este archivo desde GitHub en cada ejecución.
Garantiza que todos los usuarios siempre ejecuten la versión más reciente.

No requiere reinstalar ni reenviar scripts actualizados.

📄 Archivos principales en el repositorio
Archivo	Descripción
dlc_validator_remote.cmd	Script maestro con toda la lógica de validación DLC/CarrierConfig.
README.md	Documentación del proyecto.

El script genera un archivo:

dlc_check_log.txt

Este archivo contiene:

- Resultado individual por parámetro validado
- Interpretación técnica
- Alertas y diagnósticos
- Sugerencias de solución para OEM/Carrier
- Información del estado del dispositivo, bootloader y Verified Boot

🔒 Seguridad y confidencialidad

Este repositorio es privado y contiene herramientas destinadas únicamente a:

- Procesos internos de certificación
- Validación técnica con OEM\
- Auditoría de integración DLC v2

Queda estrictamente prohibido:
- Copiar, distribuir o publicar el contenido
- Ejecutarlo en dispositivos ajenos a entornos internos autorizados
- Modificar el script sin autorización del equipo responsable

🧩 Requisitos técnicos

Windows 10 o Windows 11
PowerShell (incluido por defecto)
ADB Platform Tools
Acceso a Internet para descargar el script maestro
Depuración USB habilitada en el dispositivo Android

Roadmap / Mejoras futuras

Integración con dashboard web
Validación extendida de certificados SHA1/SHA256
Reportes en JSON/HTML
Módulo opcional para pruebas de SIM Lock / Network Lock
Validación automática de XML CarrierConfig contra plantilla estándar

Autor
Mauricio Gutiérrez.
Proyecto: DLC Validator
Roles: Security and Test Engineer Investigación técnica, automatización ADB


⚠️ Aviso legal
© 2025 – Uso interno únicamente.
Queda prohibida su distribución externa, parcial o total.
El uso de esta herramienta debe realizarse únicamente en entornos autorizados.

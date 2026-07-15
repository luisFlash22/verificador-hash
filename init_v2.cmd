@echo off
TITLE Lanzador del Verificador de Integridad
REM Cambiar al directorio donde está guardado este archivo .bat
cd /d "%~dp0"

REM Comprobar si existe el script de PowerShell en la misma ruta
if not exist "verificar_v2.ps1" (
    color 0C
    echo [ERROR] No se encuentra el archivo 'verificar_v2.ps1' en esta carpeta.
    echo Asegurate de que 'verificar_v2.ps1' este al lado de este archivo .bat.
    echo.
    pause
    exit
)

echo Lanzando el verificador seguro desde CMD...
echo.

REM Ejecutar PowerShell de forma ultra-compatible usando la ruta exacta del archivo
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0verificar_v2.ps1'"

REM Si PowerShell falla o se cierra con error, esto evitara que la ventana de CMD se cierre de golpe
if %errorlevel% neq 0 (
    color 0E
    echo.
    echo -----------------------------------------------------------------
    echo [AVISO] PowerShell devolvio un codigo de error: %errorlevel%
    echo Si ves un mensaje de restriccion arriba, tu antivirus o las
    echo directivas de grupo de Windows podrian estar bloqueando PowerShell.
    echo -----------------------------------------------------------------
    echo.
    pause
)
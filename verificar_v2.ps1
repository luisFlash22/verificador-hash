# ====================================================================
# GESTOR DE INTEGRIDAD UNIVERSAL (MODO BUCLE CONTINUO - PRO)
# ====================================================================

while ($true) {
    try { Clear-Host } catch {}

    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "      GESTOR DE INTEGRIDAD DE ARCHIVOS       " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    # --------------------------------------------------------------------
    # MENÚ PRINCIPAL
    # --------------------------------------------------------------------
    Write-Host "[1] Obtener/Extraer HASH SHA-256 de un archivo" -ForegroundColor White
    Write-Host "[2] Verificar integridad de un archivo (Comparar hashes)" -ForegroundColor White
    Write-Host "[3] Salir del programa" -ForegroundColor Red
    Write-Host ""
    
    $Opcion = Read-Host "Selecciona una opcion (1, 2 o 3)"
    $Opcion = $Opcion.Trim()

    if ($Opcion -eq "3") {
        Write-Host "`nSaliendo del programa. ¡Hasta luego!" -ForegroundColor Cyan
        Start-Sleep -Seconds 1
        exit
    }

    if ($Opcion -ne "1" -and $Opcion -ne "2") {
        Write-Host "`n[ERROR] Opcion no valida. Intenta de nuevo." -ForegroundColor Red
        Start-Sleep -Seconds 2
        continue
    }

    try { Clear-Host } catch {}

    # --------------------------------------------------------------------
    # SECCIÓN COMÚN: PEDIR EL ARCHIVO
    # --------------------------------------------------------------------
    Write-Host "=============================================" -ForegroundColor Cyan
    if ($Opcion -eq "1") {
        Write-Host "         EXTRACTOR DE HASH SHA-256           " -ForegroundColor Cyan
    } else {
        Write-Host "        VERIFICADOR DE INTEGRIDAD            " -ForegroundColor Cyan
    }
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "[!] TIP: Puedes arrastrar el archivo directamente a esta ventana o escribir 'atras' para volver." -ForegroundColor Yellow
    $RutaArchivo = Read-Host "-> Pega la ruta del archivo"
    $RutaArchivo = $RutaArchivo.Trim('"').Trim("'")

    if ($RutaArchivo.ToLower() -eq "atras") { continue }

    # Validar existencia del archivo
    if (-not (Test-Path $RutaArchivo)) {
        Write-Host "`n[ERROR] La ruta no es valida o el archivo no existe." -ForegroundColor Red
        Read-Host "`nPresiona Enter para volver al menu..."
        continue
    }

    # Si eligió la opción 2, pedir el hash esperado antes de procesar
    $HashEsperado = ""
    if ($Opcion -eq "2") {
        Write-Host ""
        $HashEsperado = Read-Host "-> Pega el HASH SHA-256 esperado (o escribe 'atras')"
        $HashEsperado = $HashEsperado.Trim()
        if ($HashEsperado.ToLower() -eq "atras") { continue }
    }

    Write-Host ""
    Write-Host "Calculando el hash SHA-256 del archivo..." -ForegroundColor Yellow
    Write-Host "Por favor espera, procesando datos..." -ForegroundColor DarkGray

    # --------------------------------------------------------------------
    # CALCULO DEL HASH REAL CON BARRA DE PROGRESO DINÁMICA
    # --------------------------------------------------------------------
    try {
        $File = [System.IO.File]::OpenRead($RutaArchivo)
        $Length = $File.Length
        $Sha256Object = [System.Security.Cryptography.SHA256]::Create()
        
        # Buffer de lectura de 4MB para ir rápido
        $Buffer = New-Object Byte[] 4194304
        $TotalRead = 0
        
        # Simular lectura por bloques para mostrar progreso real en pantalla
        while (($BytesRead = $File.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
            $Sha256Object.TransformBlock($Buffer, 0, $BytesRead, $Buffer, 0) | Out-Null
            $TotalRead += $BytesRead
            $Porcentaje = [Math]::Round(($TotalRead / $Length) * 100)
            
            # Dibujar un indicador simple en la misma línea
            Write-Progress -Activity "Calculando SHA-256" -Status "Progreso: $Porcentaje%" -PercentComplete $Porcentaje
        }
        
        $Sha256Object.TransformFinalBlock($Buffer, 0, 0) | Out-Null
        $HashBytes = $Sha256Object.Hash
        $File.Close()
        $File.Dispose()
        Write-Progress -Activity "Calculando SHA-256" -Completed
        
        $ResultadoHash = ""
        foreach ($Byte in $HashBytes) {
            $ResultadoHash += $Byte.ToString("x2")
        }
    } catch {
        if ($File) { $File.Close(); $File.Dispose() }
        Write-Progress -Activity "Calculando SHA-256" -Completed
        Write-Host "`n[ERROR] Hubo un problema al calcular el Hash." -ForegroundColor Red
        Read-Host "`nPresiona Enter para volver al menu..."
        continue
    }

    # --------------------------------------------------------------------
    # EL TRUCO: LIMPIAR EL TECLADO (IGNORAR ENTERS ACCIDENTALES)
    # --------------------------------------------------------------------
    while ($Host.UI.RawUI.KeyAvailable) {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    # --------------------------------------------------------------------
    # RENDERIZADO DE RESULTADOS
    # --------------------------------------------------------------------
    Write-Host ""
    Write-Host "-> Nombre: $(Split-Path $RutaArchivo -Leaf)" -ForegroundColor Cyan

    if ($Opcion -eq "1") {
        # OPCIÓN 1: Solo mostrar el Hash obtenido
        Write-Host "---------------------------------------------" -ForegroundColor DarkGray
        Write-Host "HASH SHA-256 GENERADO:" -ForegroundColor Green
        Write-Host "$ResultadoHash" -ForegroundColor White
        Write-Host "---------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Puedes copiar este codigo y guardarlo para el futuro." -ForegroundColor Yellow
    } else {
        # OPCIÓN 2: Comparar firmas
        Write-Host "-> Esperado: $($HashEsperado.ToLower())" -ForegroundColor DarkGray
        Write-Host "-> Obtenido: $ResultadoHash" -ForegroundColor DarkGray
        Write-Host ""
        
        if ($ResultadoHash -eq $HashEsperado.ToLower()) {
            Write-Host "=============================================" -ForegroundColor Green
            Write-Host "       [ OK ] EL ARCHIVO ESTA PERFECTO        " -ForegroundColor Green
            Write-Host "=============================================" -ForegroundColor Green
            Write-Host "La firma coincide al 100%. El archivo esta integro." -ForegroundColor Green
        } else {
            Write-Host "=============================================" -ForegroundColor Red
            Write-Host "   [ERROR] EL ARCHIVO ESTA CORROMPIDO        " -ForegroundColor Red
            Write-Host "=============================================" -ForegroundColor Red
            Write-Host "CUIDADO: Las firmas NO coinciden." -ForegroundColor Red
            Write-Host "El archivo esta danado, incompleto o fue modificado." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Read-Host "Presiona Enter para volver al menu principal..."
}
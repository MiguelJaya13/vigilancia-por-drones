# Copia el código fuente a la carpeta de Google Drive.
# Copia sin borrar (/E): los archivos que agregues del lado de Drive se respetan.
# node_modules y dist NO se copian: Google Drive no soporta node_modules
# (npm install falla con EBADF sobre la unidad G:).

$origen  = $PSScriptRoot
$destino = "G:\Mi unidad\sistema de seguridad\sistema de monitoreo"

robocopy $origen $destino /E /XD node_modules dist .git /XF package-lock.json /NFL /NDL /NJH /NJS /R:1 /W:1

if ($LASTEXITCODE -lt 8) {
    Write-Host "Sincronizado en $destino" -ForegroundColor Green
} else {
    Write-Host "Fallo la sincronizacion (codigo $LASTEXITCODE)" -ForegroundColor Red
}

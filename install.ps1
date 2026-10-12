# Windows bootstrap: installs Nushell, then runs windows.nu (which installs everything else)
# Usage: powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.ps1)"

$RAW = 'https://raw.githubusercontent.com/mahbubzulkarnain/setup/master'

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    return
}

if (Get-Command nu -ErrorAction SilentlyContinue) {
    Write-Host "Nushell already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "Install Nushell..." -ForegroundColor Cyan
    winget install --id Nushell.Nushell --exact --silent --accept-package-agreements --accept-source-agreements
    Update-SessionPath
}

$nuScript = Join-Path $env:TEMP 'windows.nu'
Invoke-RestMethod "$RAW/windows.nu" -OutFile $nuScript

& nu $nuScript
Remove-Item $nuScript -ErrorAction SilentlyContinue

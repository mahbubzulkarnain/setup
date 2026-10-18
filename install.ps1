# Windows bootstrap: installs Git for Windows (which provides Git Bash), then runs windows.sh in Git Bash
# Usage: powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.ps1)"

$RAW = 'https://raw.githubusercontent.com/mahbubzulkarnain/setup/master'
$GitBash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Red
    return
}

if (Test-Path $GitBash) {
    Write-Host "Git for Windows already installed, skipping." -ForegroundColor Green
} else {
    Write-Host "Install Git for Windows (Git Bash)..." -ForegroundColor Cyan
    winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements
    Update-SessionPath
}

if (-not (Test-Path $GitBash)) {
    Write-Host "Git Bash not found at $GitBash. Install Git for Windows, then re-run." -ForegroundColor Red
    return
}

# Git Bash takes forward slashes most reliably
$script = Join-Path $env:TEMP 'windows.sh'
Invoke-RestMethod "$RAW/windows.sh" -OutFile $script

& $GitBash ($script -replace '\\', '/')
Remove-Item $script -ErrorAction SilentlyContinue

# GitHub CLI installation for Windows (PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.ps1)"

function Test-Command {
    param([string]$Command)
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

function Install-GH {
    if (Test-Command "gh") {
        Write-Host "gh already installed, skipping." -ForegroundColor Green
        return
    }

    Write-Host "Installing GitHub CLI for Windows..."

    # Try scoop first
    if (Test-Command "scoop") {
        Write-Host "Installing via scoop..."
        scoop install gh
        return
    }

    # Try choco second
    if (Test-Command "choco") {
        Write-Host "Installing via chocolatey..."
        choco install gh -y
        return
    }

    # Try winget third
    if (Test-Command "winget") {
        Write-Host "Installing via winget..."
        winget install --id GitHub.cli --source winget
        return
    }

    # Fallback: direct PowerShell installer
    Write-Host "Using official PowerShell installer..."
    try {
        irm https://cli.github.com/install.ps1 | iex
    } catch {
        Write-Host "Error: Could not install gh. Please try one of:" -ForegroundColor Red
        Write-Host "  winget install GitHub.cli"
        Write-Host "  choco install gh"
        Write-Host "  scoop install gh"
        Write-Host "  irm https://cli.github.com/install.ps1 | iex"
        exit 1
    }
}

Write-Host "GitHub CLI Installation Script for Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Install-GH

Write-Host ""
Write-Host "GitHub CLI installed successfully!" -ForegroundColor Green
gh --version

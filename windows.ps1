$ErrorActionPreference = "Stop"

$msys2Bash = "C:\msys64\usr\bin\bash.exe"
$zshProfileGuid = "{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}"
$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (-not (Test-Path $msys2Bash)) {
    Write-Host "Installing MSYS2..."
    winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "MSYS2 already installed, skipping."
}

if (Test-Path $terminalSettingsPath) {
    $settings = Get-Content $terminalSettingsPath -Raw | ConvertFrom-Json
    $existingProfile = $settings.profiles.list | Where-Object { $_.guid -eq $zshProfileGuid }

    if (-not $existingProfile) {
        Write-Host "Adding Zsh (MSYS2) Windows Terminal profile..."
        $zshProfile = [ordered]@{
            commandline       = "C:\msys64\msys2_shell.cmd -defterm -no-start -msys2 -shell zsh"
            guid              = $zshProfileGuid
            hidden            = $false
            icon              = "C:\msys64\msys2.ico"
            name              = "Zsh (MSYS2)"
            startingDirectory = "%USERPROFILE%"
        }
        $settings.profiles.list = @($zshProfile) + @($settings.profiles.list)
    } else {
        Write-Host "Zsh (MSYS2) Windows Terminal profile already present, skipping."
    }

    $settings.defaultProfile = $zshProfileGuid
    $settings | ConvertTo-Json -Depth 10 | Set-Content $terminalSettingsPath -Encoding utf8
} else {
    Write-Host "Windows Terminal settings.json not found, skipping terminal profile setup."
}

Write-Host "Running windows.sh inside MSYS2 bash..."
& $msys2Bash -lc "bash <(curl -s https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/windows.sh)"

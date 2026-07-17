$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script installs system-wide tools (winget, Chocolatey packages) and needs Administrator rights."
    Write-Host "Re-run PowerShell as Administrator, then run this script again."
    exit 1
}

$msys2Bash = "C:\msys64\usr\bin\bash.exe"
$zshProfileGuid = "{c0f7f34e-1234-5f8a-9a2b-7d9f2b1a0e01}"
$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (-not (Test-Path $msys2Bash)) {
    Write-Host "Installing MSYS2..."
    winget install --id MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "MSYS2 already installed, skipping."
}

$vscodeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
if (-not (Test-Path $vscodeExe)) {
    Write-Host "Installing VS Code..."
    winget install --id Microsoft.VisualStudioCode -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "VS Code already installed, skipping."
}

$dockerDesktopExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerDesktopExe)) {
    Write-Host "Installing Docker Desktop..."
    winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements
} else {
    Write-Host "Docker Desktop already installed, skipping."
}

function Update-SessionPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey already installed, skipping."
} else {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Update-SessionPath
}

if (Get-Command fvm -ErrorAction SilentlyContinue) {
    Write-Host "FVM already installed, skipping."
} else {
    Write-Host "Installing FVM..."
    choco install fvm -y
    Update-SessionPath
}

if ((fvm list 2>$null) -match "stable") {
    Write-Host "Flutter (FVM stable) already installed, skipping."
} else {
    Write-Host "Install Flutter (stable) via FVM..."
    fvm install stable
    fvm global stable
    fvm flutter config --enable-windows-desktop
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasVCTools = (Test-Path $vswhere) -and (& $vswhere -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath)
if ($hasVCTools) {
    Write-Host "Visual Studio C++ Build Tools already installed, skipping."
} else {
    Write-Host "Installing Visual Studio Build Tools (C++ desktop workload, needed for 'flutter build windows')..."
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
}

function ConvertFrom-JsonC {
    param([Parameter(Mandatory)][string]$Json)

    function Convert-JsonElement($element) {
        switch ($element.ValueKind) {
            'Object' {
                $obj = [ordered]@{}
                foreach ($prop in $element.EnumerateObject()) {
                    $obj[$prop.Name] = Convert-JsonElement $prop.Value
                }
                return [PSCustomObject]$obj
            }
            'Array' {
                $arr = @()
                foreach ($item in $element.EnumerateArray()) {
                    $arr += , (Convert-JsonElement $item)
                }
                return , $arr
            }
            'String' { return $element.GetString() }
            'Number' {
                $asLong = 0L
                if ($element.TryGetInt64([ref]$asLong)) { return $asLong }
                return $element.GetDouble()
            }
            'True' { return $true }
            'False' { return $false }
            default { return $null }
        }
    }

    $options = New-Object System.Text.Json.JsonDocumentOptions
    $options.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
    $options.AllowTrailingCommas = $true

    $doc = [System.Text.Json.JsonDocument]::Parse($Json, $options)
    try {
        return Convert-JsonElement $doc.RootElement
    } finally {
        $doc.Dispose()
    }
}

if (Test-Path $terminalSettingsPath) {
    try {
        $settings = ConvertFrom-JsonC (Get-Content $terminalSettingsPath -Raw)
    } catch {
        $settings = $null
    }

    if ($null -eq $settings) {
        Write-Host "Could not parse Windows Terminal settings.json (it may contain comments) - skipping terminal profile setup. Add manually: 'Zsh (MSYS2)' profile running 'C:\msys64\msys2_shell.cmd -defterm -no-start -msys2 -shell zsh'."
    } else {
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
        Copy-Item $terminalSettingsPath "$terminalSettingsPath.bak" -Force
        $settings | ConvertTo-Json -Depth 10 | Set-Content $terminalSettingsPath -Encoding utf8
    }
} else {
    Write-Host "Windows Terminal settings.json not found, skipping terminal profile setup."
}

$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
$msys2ZshProfileName = "Zsh (MSYS2)"

if (-not (Test-Path $vscodeSettingsPath)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $vscodeSettingsPath) | Out-Null
    "{}" | Set-Content $vscodeSettingsPath -Encoding utf8
}

try {
    $vscodeSettings = ConvertFrom-JsonC (Get-Content $vscodeSettingsPath -Raw)
} catch {
    $vscodeSettings = $null
}

if ($null -eq $vscodeSettings) {
    Write-Host "Could not parse VS Code settings.json (it may contain comments) - skipping default terminal setup. Add manually: MSYS2 zsh profile named '$msys2ZshProfileName'."
} else {
    $msys2Profile = [PSCustomObject]@{
        path = "C:\msys64\usr\bin\zsh.exe"
        args = @("--login", "-i")
        env  = [PSCustomObject]@{
            MSYSTEM        = "MSYS"
            CHERE_INVOKING = "1"
        }
        icon = "terminal-bash"
    }

    if (-not $vscodeSettings.PSObject.Properties['terminal.integrated.profiles.windows']) {
        $vscodeSettings | Add-Member -NotePropertyName 'terminal.integrated.profiles.windows' -NotePropertyValue ([PSCustomObject]@{})
    }
    if ($vscodeSettings.'terminal.integrated.profiles.windows'.PSObject.Properties[$msys2ZshProfileName]) {
        Write-Host "VS Code MSYS2 zsh terminal profile already present, skipping."
    } else {
        Write-Host "Adding MSYS2 zsh terminal profile to VS Code..."
    }
    $vscodeSettings.'terminal.integrated.profiles.windows' | Add-Member -NotePropertyName $msys2ZshProfileName -NotePropertyValue $msys2Profile -Force

    if ($vscodeSettings.PSObject.Properties['terminal.integrated.defaultProfile.windows']) {
        $vscodeSettings.'terminal.integrated.defaultProfile.windows' = $msys2ZshProfileName
    } else {
        $vscodeSettings | Add-Member -NotePropertyName 'terminal.integrated.defaultProfile.windows' -NotePropertyValue $msys2ZshProfileName
    }

    Copy-Item $vscodeSettingsPath "$vscodeSettingsPath.bak" -Force
    $vscodeSettings | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettingsPath -Encoding utf8
    Write-Host "VS Code default terminal set to $msys2ZshProfileName."
}

Write-Host "Handing off to install.sh inside MSYS2 bash..."
& $msys2Bash -lc "curl -fsSL https://raw.githubusercontent.com/mahbubzulkarnain/setup/master/install.sh -o /tmp/install.sh && bash /tmp/install.sh; rm -f /tmp/install.sh"
if ($LASTEXITCODE -ne 0) {
    throw "install.sh inside MSYS2 bash failed with exit code $LASTEXITCODE"
}

# Make Nushell the default VS Code terminal and apply best-practice settings (managed by setup).
# Inputs via environment: VSCODE_SETTINGS (settings.json path), VSCODE_OS (osx | linux | windows)
# Keys already in settings.json (including ones synced from VS Code Settings Sync) are kept.
# Sources: VS Code docs, "Terminal profiles", "Telemetry" FAQ, and "Workspace Trust".

let file = $env.VSCODE_SETTINGS
let os_key = $env.VSCODE_OS
let profiles_key = $"terminal.integrated.profiles.($os_key)"
let default_key = $"terminal.integrated.defaultProfile.($os_key)"

# Profile path is just "nu" (found on PATH), not an absolute path, so the setting works on every machine it syncs to
let nu_profile = { path: "nu" }

# Best-practice keys. telemetry: "off" silences all VS Code telemetry, including crash reports.
let best_practice = {
    "telemetry.telemetryLevel": "off"
    "workbench.enableExperiments": false
    "files.trimTrailingWhitespace": true
    "files.insertFinalNewline": true
    "editor.formatOnSave": true
    "security.workspace.trust.enabled": true
}

mkdir ($file | path dirname)

# VS Code allows comments and trailing commas (JSONC); rewriting such a file would drop them, so leave it alone
let raw = (if ($file | path exists) { open --raw $file } else { "{}" })
# Blank out string literals first, so "https://..." isn't mistaken for a comment
let outside_strings = ($raw | str replace -a -r '"(\\.|[^"\\])*"' '""')
let is_jsonc = ($outside_strings =~ '//|/\*|,\s*[}\]]')
let current = (try { if $is_jsonc { null } else { $raw | from json } } catch { null })

if $current == null {
    print $"Skipped ($file): it has comments or trailing commas. Add these keys by hand:"
    print $"  \"($default_key)\": \"Nushell\","
    print $"  \"($profiles_key)\": { \"Nushell\": { \"path\": \"nu\" } },"
    for key in ($best_practice | columns) {
        print $"  \"($key)\": ($best_practice | get $key | to json --raw),"
    }
} else {
    let profiles = ($current | get -o $profiles_key | default {})
    let updated = (
        $current
        | merge $best_practice
        | upsert $profiles_key ($profiles | upsert Nushell $nu_profile)
        | upsert $default_key "Nushell"
    )
    $updated | to json --indent 4 | save -f $file
    print $"Updated VS Code settings: Nushell terminal and best-practice keys in ($file)"
}

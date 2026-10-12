# env.nu: loaded before config.nu (managed by setup, see nushell.sh / windows.nu)
# PATH, environment variables, and the init files of mise, starship, and zoxide.

let home = if ($env.HOME? | is-not-empty) { $env.HOME } else { $env.USERPROFILE }
let os = $nu.os-info.name

# Extra PATH entries per OS. Only directories that exist are added.
let extra_paths = if $os == "macos" {
    [
        ($home | path join ".local" "bin")
        ($home | path join ".pub-cache" "bin")
        ($home | path join "Library" "Android" "sdk" "cmdline-tools" "latest" "bin")
        "/opt/homebrew/bin"
        "/usr/local/bin"
        ($home | path join "bin")
    ]
} else if $os == "linux" {
    [
        ($home | path join ".local" "bin")
        ($home | path join ".pub-cache" "bin")
        "/home/linuxbrew/.linuxbrew/bin"
        ($home | path join "fvm" "bin")
        ($home | path join ".fvm_flutter" "bin")
    ]
} else {
    [
        ($home | path join "fvm" "default" "bin")
        ($home | path join ".local" "bin")
        ($env.LOCALAPPDATA | path join "Pub" "Cache" "bin")
        ($env.LOCALAPPDATA | path join "Microsoft" "WinGet" "Links")
        ($env.LOCALAPPDATA | path join "Plaesy" "bin")
    ]
}

let current_path = ($env.PATH)
load-env {
    PATH: ($extra_paths | where {|p| $p | path exists } | append $current_path | uniq)
}

# Android SDK (installed by windows.nu / flutter setup without Android Studio)
let android_home = if $os == "macos" {
    ($home | path join "Library" "Android" "sdk")
} else if $os == "linux" {
    ($home | path join "Android" "Sdk")
} else {
    ($env.LOCALAPPDATA | path join "Android" "Sdk")
}
load-env { ANDROID_HOME: $android_home }

# JDK from mise (Android tools and Gradle read JAVA_HOME)
if (which mise | is-not-empty) {
    load-env { JAVA_HOME: (^mise where java | str trim) }
}
load-env {
    PATH: ([($android_home | path join "platform-tools") ($android_home | path join "cmdline-tools" "latest" "bin")] | where {|p| $p | path exists } | append $env.PATH | uniq)
}

load-env {
    FZF_DEFAULT_COMMAND: "fd --hidden --strip-cwd-prefix --exclude .git"
    FZF_CTRL_T_COMMAND: "fd --hidden --strip-cwd-prefix --exclude .git"
    FZF_ALT_C_COMMAND: "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
}

# Init files are regenerated on every start, so tool upgrades apply without editing config.
# A missing tool gets an empty file, so the `source`/`use` lines in config.nu still parse.
let inits = [
    { file: "mise.nu", cmd: "mise", args: ["activate", "nu"] }
    { file: "starship.nu", cmd: "starship", args: ["init", "nu"] }
    { file: "zoxide.nu", cmd: "zoxide", args: ["init", "nushell"] }
]

for init in $inits {
    let target = ($nu.default-config-dir | path join $init.file)
    if (which $init.cmd | is-not-empty) {
        ^$init.cmd ...$init.args | save -f $target
    } else {
        "" | save -f $target
    }
}

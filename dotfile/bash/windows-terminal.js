// Make the Git Bash profile the Windows Terminal default (managed by setup).
// Usage: node windows-terminal.js <settings.json> [theme.json]
// The file is JSONC (has comments). Only the Git Bash profile, the Nushell profile removal, and the defaultProfile line change.
const fs = require('fs');

const file = process.argv[2];
let text = fs.readFileSync(file, 'utf8');

// Windows Terminal makes Git Bash a dynamic profile, so it is often missing from settings.json.
// Write it with the GUID and source Windows Terminal uses for Git, so the default resolves.
const GIT_BASH_GUID = '{2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b}';
const gitBashProfile = `{
                "guid": "${GIT_BASH_GUID}",
                "name": "Git Bash",
                "commandline": "%PROGRAMFILES%\\\\Git\\\\bin\\\\bash.exe -i -l",
                "startingDirectory": "%USERPROFILE%",
                "hidden": false,
                "source": "Git"
            },`;

let changed = false;

// Nushell is gone from this setup. Drop its profile so no entry points at a missing shell.
const nuProfile = /\{\s*"guid":\s*"\{[^"]+\}",\s*"hidden":\s*false,\s*"name":\s*"Nushell",\s*"source":\s*"nu"\s*\},?\s*/;
if (nuProfile.test(text)) {
    text = text.replace(nuProfile, '');
    changed = true;
}

if (!text.includes(GIT_BASH_GUID)) {
    text = text.replace(/("list":\s*\[)/, `$1\n            ${gitBashProfile}`);
    changed = true;
}

if (!text.includes(`"defaultProfile": "${GIT_BASH_GUID}"`)) {
    text = text.replace(/"defaultProfile":\s*"\{[^"]+\}"/, `"defaultProfile": "${GIT_BASH_GUID}"`);
    changed = true;
}

// Color scheme from dotfile/terminal/theme.json (same keys as a Windows Terminal scheme, except cursor)
const themeFile = process.argv[3];
if (themeFile) {
    const theme = JSON.parse(fs.readFileSync(themeFile, 'utf8'));
    const { cursor, ...colors } = theme;
    const scheme = JSON.stringify({ ...colors, cursorColor: cursor }, null, 4)
        .split('\n')
        .map((line, i) => (i === 0 ? line : `        ${line}`))
        .join('\n');

    if (!text.includes(`"name": "${theme.name}"`)) {
        const emptySchemes = /"schemes":\s*\[\s*\]/.test(text);
        text = text.replace(/"schemes":\s*\[/, `"schemes": [\n        ${scheme}${emptySchemes ? '' : ','}`);
        changed = true;
    }

    // Make it the default for every profile, replacing any colorScheme already in profiles.defaults
    if (!text.includes(`"colorScheme": "${theme.name}"`)) {
        if (/"colorScheme":\s*"[^"]*"/.test(text) && /"defaults":\s*\{[^}]*"colorScheme"/.test(text)) {
            text = text.replace(/("defaults":\s*\{[^}]*)"colorScheme":\s*"[^"]*"/, `$1"colorScheme": "${theme.name}"`);
        } else if (/"defaults":\s*\{\s*\}/.test(text)) {
            text = text.replace(/"defaults":\s*\{\s*\}/, `"defaults": {\n            "colorScheme": "${theme.name}"\n        }`);
        } else {
            text = text.replace(/("defaults":\s*\{)/, `$1\n            "colorScheme": "${theme.name}",`);
        }
        changed = true;
    }
}

if (!changed) {
    console.log('Windows Terminal default is already Git Bash, skipping.');
    process.exit(0);
}
fs.writeFileSync(file, text);
console.log('Updated Windows Terminal: Git Bash default profile and the Setup Dark color scheme.');

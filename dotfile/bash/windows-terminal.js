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

    const nameAt = text.indexOf(`"name": "${theme.name}"`);
    if (nameAt !== -1) {
        // Replace the existing scheme so a changed palette takes effect. A scheme has no nested braces.
        const start = text.lastIndexOf('{', nameAt);
        const end = text.indexOf('}', start) + 1;
        if (text.slice(start, end) !== scheme) {
            text = text.slice(0, start) + scheme + text.slice(end);
            changed = true;
        }
    } else {
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

// Optional font size (points) for every profile, from the third argument. Set it in profiles.defaults.font.size.
const fontSize = process.argv[4];
if (fontSize) {
    // Only inside profiles.defaults: its own members, with one level of nested braces (the font object)
    const sizeRe = /("defaults":\s*\{(?:[^{}]|\{[^{}]*\})*?"font":\s*\{[^}]*?"size":\s*)\d+/;
    if (sizeRe.test(text)) {
        const before = text;
        text = text.replace(sizeRe, `$1${Number(fontSize)}`);
        if (text !== before) changed = true;
    } else if (!/"defaults":\s*\{\s*\}/.test(text)) {
        text = text.replace(/("defaults":\s*\{)/, `$1\n            "font": {\n                "size": ${Number(fontSize)}\n            },`);
        changed = true;
    }
}

if (!changed) {
    console.log('Windows Terminal is already up to date with the theme, nothing changed.');
    process.exit(0);
}
fs.writeFileSync(file, text);
console.log('Updated Windows Terminal: Git Bash default profile and the theme color scheme.');

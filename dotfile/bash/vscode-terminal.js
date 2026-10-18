// Make bash the VS Code terminal and apply best-practice settings (managed by setup).
// Usage: node vscode-terminal.js <settings.json> <windows|osx|linux> <bash path> <theme.json>
// Keys already in settings.json (including ones synced from Settings Sync) are kept.
// A file with comments or trailing commas (JSONC) is left alone, so nothing is lost.
const fs = require('fs');
const path = require('path');

const [file, osKey, bashPath, themeFile] = process.argv.slice(2);
const profilesKey = `terminal.integrated.profiles.${osKey}`;
const defaultKey = `terminal.integrated.defaultProfile.${osKey}`;
// Git Bash is the built-in "Git Bash" profile name on Windows; elsewhere the profile is just "Bash"
const profileName = osKey === 'windows' ? 'Git Bash' : 'Bash';

const bestPractice = {
    'telemetry.telemetryLevel': 'off',
    'workbench.enableExperiments': false,
    'files.trimTrailingWhitespace': true,
    'files.insertFinalNewline': true,
    'editor.formatOnSave': true,
    'security.workspace.trust.enabled': true,
};

fs.mkdirSync(path.dirname(file), { recursive: true });
const raw = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '{}';
// Blank out string literals first, so "https://..." is not mistaken for a comment
const outsideStrings = raw.replace(/"(\\.|[^"\\])*"/g, '""');
const isJsonc = /\/\/|\/\*|,\s*[}\]]/.test(outsideStrings);

let current = null;
if (!isJsonc) {
    try {
        current = JSON.parse(raw);
    } catch (err) {
        current = null;
    }
}

if (current === null || typeof current !== 'object') {
    console.log(`Skipped ${file}: it has comments or trailing commas. Add these keys by hand:`);
    console.log(`  "${defaultKey}": "${profileName}",`);
    console.log(`  "${profilesKey}": { "${profileName}": { "path": ${JSON.stringify(bashPath)} } },`);
    for (const [key, value] of Object.entries(bestPractice)) {
        console.log(`  "${key}": ${JSON.stringify(value)},`);
    }
    process.exit(0);
}

// Terminal colors from dotfile/terminal/theme.json, mapped to VS Code's terminal color keys.
// Colors the user already set in workbench.colorCustomizations win over the theme.
function terminalColors(theme) {
    const ansi = ['Black', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White'];
    const names = ['black', 'red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'white'];
    const colors = {
        'terminal.background': theme.background,
        'terminal.foreground': theme.foreground,
        'terminalCursor.foreground': theme.cursor,
        'terminal.selectionBackground': theme.selectionBackground,
    };
    ansi.forEach((name, i) => {
        colors[`terminal.ansi${name}`] = theme[names[i]];
        colors[`terminal.ansiBright${name}`] = theme[`bright${names[i][0].toUpperCase()}${names[i].slice(1)}`];
    });
    return colors;
}

const customizations = { ...(current['workbench.colorCustomizations'] || {}) };
if (themeFile) {
    const theme = JSON.parse(fs.readFileSync(themeFile, 'utf8'));
    Object.assign(customizations, { ...terminalColors(theme), ...customizations });
}

const updated = {
    ...current,
    ...bestPractice,
    [profilesKey]: { ...(current[profilesKey] || {}), [profileName]: { path: bashPath } },
    [defaultKey]: profileName,
    ...(themeFile ? { 'workbench.colorCustomizations': customizations } : {}),
};
fs.writeFileSync(file, JSON.stringify(updated, null, 4) + '\n');
console.log(`Updated VS Code settings: ${profileName} terminal and best-practice keys in ${file}`);

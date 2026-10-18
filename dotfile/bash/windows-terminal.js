// Make the Git Bash profile the Windows Terminal default (managed by setup).
// Usage: node windows-terminal.js <settings.json>
// The file is JSONC (has comments), so only the defaultProfile line is rewritten; the rest stays byte-for-byte.
const fs = require('fs');

const file = process.argv[2];
const text = fs.readFileSync(file, 'utf8');

const match = /"guid":\s*"(\{[^"]+\})"[^{}]*"name":\s*"Git Bash"/.exec(text);
if (!match) {
    console.log('Warning: no Git Bash profile in Windows Terminal; default profile unchanged.');
    process.exit(0);
}
const guid = match[1];

if (text.includes(`"defaultProfile": "${guid}"`)) {
    console.log('Windows Terminal default is already Git Bash, skipping.');
    process.exit(0);
}

const updated = text.replace(/"defaultProfile":\s*"\{[^"]+\}"/, `"defaultProfile": "${guid}"`);
fs.writeFileSync(file, updated);
console.log('Set Windows Terminal default profile to Git Bash.');

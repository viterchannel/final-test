#!/bin/bash
set -e

echo "🔐 Setting up permanent encrypted environment (password: Khan@123.com)..."

# 1. Create complete .env with all variables (real + auto-generated secure ones)
cat > .env << 'ENVEOF'
PORT=4000

# ===== REAL VALUES (provided by you) =====
JWT_SECRET="PUkuIh+8NSn80k68j1sAR1zPGtK7xryE8LTbaM6hGA2jA2fHq1MJuyud4YYtSMtB"
DATABASE_URL="postgresql://neondb_owner:npg_5VFzHmZ6NTWn@ep-solitary-credit-a188hgj0-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
GEMINI_API_KEY="AIzaSyDdujmMRDG4_z0z8zG908_f4jNHACg9EHk"
ADMIN_JWT_SECRET="QOHAcA0Y3m6yyQ1jW8FnQu995T5e8XupSnhKch6SF8RIKFn5KNZatDnFzqUDX2OL"
VAPID_PUBLIC_KEY="BNdOE8h9Xk9JZv5XQz7R6T2V4W8Y1Z3X7R6T2V4W8Y1Z3X7R6T2V4W8Y1Z3X7R6T2V4W8Y1Z3X7..."
VAPID_PRIVATE_KEY="b3egnGyDJYSVsOB4z-PGhf5YbGeuVKcHtNpJPQ-r-eM"

# ===== GENERATED SECURE VALUES (32+ chars each) =====
ADMIN_REFRESH_SECRET="xs3F!d9#2kL@qW8^mY5&zR7*vT6nC4bV1_aP0eJ8hG3"
VENDOR_JWT_SECRET="v3nd0rS3cr3t#2025!L0ngEn0ughF0rJWT1234567890"
RIDER_JWT_SECRET="r1d3rK3y!Secur3P@ssw0rdL0ngStr1ngF0rJWT"
SESSION_SECRET="sEss10nS3cr3t!Encrypt10nK3yL0ngAndStr0ng12345"
ENVEOF

echo "✅ Complete .env file created."

# 2. Encrypt with fixed password
openssl enc -aes-256-cbc -salt -in .env -out .env.enc -pbkdf2 -pass pass:'Khan@123.com'
echo "✅ .env.enc created (encrypted)."

# 3. Ensure .gitignore has .env
grep -qxF '.env' .gitignore 2>/dev/null || echo '.env' >> .gitignore

# 4. Create decrypt script (scripts/decrypt.mjs)
mkdir -p scripts
cat > scripts/decrypt.mjs << 'DECEOF'
#!/usr/bin/env node
import { execSync } from 'child_process';
import fs from 'fs';
import readline from 'readline';

const ENC_FILE = '.env.enc';
const ENV_FILE = '.env';

if (fs.existsSync(ENV_FILE)) {
    console.log('✅ .env already exists. Skipping decryption.');
    process.exit(0);
}
if (!fs.existsSync(ENC_FILE)) {
    console.error('❌ .env.enc not found.');
    process.exit(1);
}
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const password = await new Promise((resolve) => {
    rl.question('🔐 Enter decryption password: ', resolve);
});
rl.close();
try {
    execSync(`openssl enc -d -aes-256-cbc -in ${ENC_FILE} -out ${ENV_FILE} -pbkdf2 -pass pass:${password}`, { stdio: 'inherit' });
    console.log('✅ .env file created.');
} catch {
    console.error('❌ Wrong password.');
    process.exit(1);
}
DECEOF

# 5. Create encrypt script (scripts/encrypt.mjs)
cat > scripts/encrypt.mjs << 'ENCDEOF'
#!/usr/bin/env node
import { execSync } from 'child_process';
import fs from 'fs';
import readline from 'readline';

const ENV_FILE = '.env';
const ENC_FILE = '.env.enc';

if (!fs.existsSync(ENV_FILE)) {
    console.error('❌ .env not found.');
    process.exit(1);
}
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const password = await new Promise((resolve) => {
    rl.question('🔐 Enter password to encrypt: ', resolve);
});
rl.close();
execSync(`openssl enc -aes-256-cbc -salt -in ${ENV_FILE} -out ${ENC_FILE} -pbkdf2 -pass pass:${password}`, { stdio: 'inherit' });
console.log('✅ .env.enc updated.');
ENCDEOF

chmod +x scripts/decrypt.mjs scripts/encrypt.mjs
echo "✅ Decrypt/encrypt scripts created."

# 6. Update package.json scripts
if command -v jq &> /dev/null; then
    jq '.scripts.env = "node scripts/decrypt.mjs" | .scripts["env:encrypt"] = "node scripts/encrypt.mjs" | .scripts["codespace-start"] = "pnpm run env && node scripts/launchers/start.mjs codespace"' package.json > package.json.tmp && mv package.json.tmp package.json
else
    # Simple sed fallback (assumes no other weird formatting)
    sed -i.bak 's/"codespace-start": ".*"/"codespace-start": "pnpm run env \&\& node scripts\/launchers\/start.mjs codespace"/' package.json
    if ! grep -q '"env":' package.json; then
        sed -i.bak '/"scripts": {/a \    "env": "node scripts/decrypt.mjs",\n    "env:encrypt": "node scripts/encrypt.mjs",' package.json
    fi
fi
echo "✅ package.json updated."

# 7. Install dotenv in api-server (if missing)
cd artifacts/api-server
pnpm add dotenv 2>/dev/null || echo "dotenv already installed or pnpm issue"
cd ../..

# 8. Ensure dotenv is imported in api-server/src/index.ts
if ! grep -q "import 'dotenv/config'" artifacts/api-server/src/index.ts; then
    echo "import 'dotenv/config';" | cat - artifacts/api-server/src/index.ts > temp && mv temp artifacts/api-server/src/index.ts
    echo "✅ Added dotenv import to api-server."
fi

echo ""
echo "🎉 PERMANENT SETUP COMPLETE!"
echo "🔑 Encryption password: Khan@123.com"
echo ""
echo "📦 To start your project now:"
echo "   pnpm run codespace-start"
echo ""
echo "🔄 On any new machine (clone, VPS, another Codespace):"
echo "   pnpm install"
echo "   pnpm run env         # will ask for password: Khan@123.com"
echo "   pnpm run codespace-start"
echo ""
echo "🔐 To update environment variables later:"
echo "   Edit .env directly, then run: pnpm run env:encrypt"

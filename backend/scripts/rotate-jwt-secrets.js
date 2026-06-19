const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '..', '.env');
const jwtSecret = crypto.randomBytes(32).toString('base64url');
const refreshSecret = crypto.randomBytes(32).toString('base64url');

let content = fs.readFileSync(envPath, 'utf8');
content = content.replace(
  /JWT_SECRET="[^"]*"/,
  `JWT_SECRET="${jwtSecret}"`
);
if (!/JWT_REFRESH_SECRET=/.test(content)) {
  content += `\nJWT_REFRESH_SECRET="${refreshSecret}"`;
} else {
  content = content.replace(
    /JWT_REFRESH_SECRET="[^"]*"/,
    `JWT_REFRESH_SECRET="${refreshSecret}"`
  );
}
fs.writeFileSync(envPath, content);
console.log('Updated JWT_SECRET and JWT_REFRESH_SECRET');

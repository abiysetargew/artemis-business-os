const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const log = fs.createWriteStream(path.join(__dirname, '..', 'backend-stable.log'), { flags: 'a' });
log.write(`\n--- Backend starting at ${new Date().toISOString()} ---\n`);

const child = spawn('node', ['dist/main.js'], {
  cwd: path.join(__dirname, '..'),
  env: { ...process.env, PORT: '4040' },
  detached: false,
  stdio: ['ignore', 'pipe', 'pipe'],
});

child.stdout.pipe(log);
child.stderr.pipe(log);

child.on('exit', (code, signal) => {
  log.write(`--- Backend exited at ${new Date().toISOString()} code=${code} signal=${signal} ---\n`);
});

console.log(`Backend started, PID=${child.pid}`);

const dns = require('dns');
const { Client } = require('pg');

// Force IPv4 lookup
dns.setDefaultResultOrder('ipv4first');

const connectionString = 'postgresql://postgres:Pagumen@321@db.cbxtgnqrkfictettevae.supabase.co:5432/postgres?sslmode=require';
console.log('Testing connection with forced IPv4...');

const client = new Client({
  connectionString,
  ssl: { rejectUnauthorized: false },
});

client
  .connect()
  .then(() => {
    console.log('SUCCESS: Connected to Supabase!');
    return client.query('SELECT NOW()');
  })
  .then((res) => {
    console.log('Query result:', res.rows[0]);
    return client.end();
  })
  .catch((e) => {
    console.log('ERROR:', e.message);
    process.exit(1);
  });

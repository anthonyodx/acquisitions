import 'dotenv/config';

// In production (default), use Neon serverless HTTP driver.
// In development with Neon Local, use node-postgres (tcp) via the local proxy.
// Toggle via NEON_LOCAL=true in your environment (set in docker-compose.dev.yml).

import { drizzle as drizzleNeon } from 'drizzle-orm/neon-http';
import { neon, neonConfig } from '@neondatabase/serverless';

import { drizzle as drizzlePg } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

if (process.env.NODE_ENV === 'development') {
  neonConfig.fetchEndpoint = 'http://neon-local:5432/sql';
  neonConfig.useSecureWebSocket = false;
  neonConfig.poolQueryViaFetch = true;
}

const useNeonLocal = String(process.env.NEON_LOCAL).toLowerCase() === 'true';

let db;
let sql;

if (useNeonLocal) {
  // Connect through Neon Local proxy (postgres protocol on port 5432)
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  db = drizzlePg(pool);
  sql = null; // not used in pg mode
} else {
  // Connect directly to Neon serverless (HTTP driver)
  sql = neon(process.env.DATABASE_URL);
  db = drizzleNeon(sql);
}

export { db, sql };

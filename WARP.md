# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview

- Stack: Node.js (ESM) + Express 5, Drizzle ORM, Neon serverless Postgres or node-postgres (via Neon Local), Zod validation, Winston + Morgan logging, ESLint + Prettier, Arcjet (bot protection + rate limiting).
- Entry points: src/index.js loads environment and starts the HTTP server via src/server.js, which boots the Express app defined in src/app.js.
- Import aliases: package.json defines Node ESM import maps for internal modules: #config/_, #controllers/_, #middleware/_, #models/_, #routes/_, #services/_, #utils/_, #validations/_.

Essential commands

- Install dependencies

```sh path=null start=null
npm install
```

- Start the API in watch mode (loads .env via dotenv)

```sh path=null start=null
npm run dev
```

- Start locally in production mode

```sh path=null start=null
npm start
```

- Lint and fix

```sh path=null start=null
npm run lint
npm run lint:fix
```

- Format and check formatting

```sh path=null start=null
npm run format:check
npm run format
```

- Database (Drizzle)
  Requires DATABASE_URL to be set. Migrations output to ./drizzle/ per drizzle.config.js.

```sh path=null start=null
# Generate SQL from schema in src/models/*.js
npm run db:generate

# Apply pending migrations to the database in DATABASE_URL
npm run db:migrate

# Explore schema and migrations in a local UI
npm run db:studio
```

- Docker workflows (from README)
  Development with Neon Local:

```sh path=null start=null
# Start dev stack (app + Neon Local proxy) and follow logs
npm run dev:docker
# or directly
docker compose -f docker-compose.dev.yml up --build
```

Apply Drizzle actions inside the container:

```sh path=null start=null
docker compose -f docker-compose.dev.yml run --rm app npm run db:generate
docker compose -f docker-compose.dev.yml run --rm app npm run db:migrate
docker compose -f docker-compose.dev.yml run --rm --service-ports app npm run db:studio
```

Stop dev stack:

```sh path=null start=null
docker compose -f docker-compose.dev.yml down
```

Production (Neon Cloud):

```sh path=null start=null
# Build and run
npm run prod:docker
# or
docker compose -f docker-compose.prod.yml up --build -d

# Apply pending migrations in prod
docker compose -f docker-compose.prod.yml run --rm app npm run db:migrate
```

- Tests
  A test runner is not configured in this repository (no test scripts or config were found). Running a “single test” is not applicable until a test framework (e.g., Jest, Vitest) is added and wired into package.json scripts.

Environment and configuration

- Copy env template and provide values

```sh path=null start=null
cp .env.example .env
# Set DATABASE_URL for Neon/Postgres, and JWT_SECRET (overriding the default in src/utils/jwt.js)
```

- Environment files used by Docker (see README):
  - .env.development for docker-compose.dev.yml (includes NEON_LOCAL=true, DATABASE_URL to neon-local, Neon credentials for the proxy)
  - .env.production for docker-compose.prod.yml (DATABASE_URL to Neon Cloud; do not set NEON_LOCAL)
- Database driver selection:
  - When NEON_LOCAL=true, src/config/database.js uses node-postgres (tcp) via the Neon Local proxy.
  - Otherwise it uses Neon serverless HTTP driver with @neondatabase/serverless.
- Security:
  - Arcjet is configured in src/config/arcjet.js; set ARCJET_KEY to enable bot protection and shielding in LIVE mode.
  - Rate limiting is also enforced in src/middleware/security.middleware.js with per-role sliding windows.
- Default port: 3000 (configurable via PORT).
- Health checks (after starting the server):
  - GET / -> "Hello from Acquisitions!"
  - GET /health -> JSON status + uptime
  - GET /api -> JSON API status

High-level architecture

- src/index.js: Bootstraps environment (import 'dotenv/config') and starts the server.
- src/server.js: Reads PORT and calls app.listen().
- src/app.js: Builds the Express app.
  - Middleware: helmet, express.json, cors, urlencoded, cookie-parser, morgan (logs to Winston), security middleware (Arcjet).
  - Routes: mounts /api/auth and /api/users.
  - Basic endpoints: /, /health, /api.
- Auth flow:
  - Routes: src/routes/auth.routes.js defines POST /api/auth/sign-up, /sign-in, /sign-out.
  - Controller: src/controllers/auth.controller.js validates with Zod, delegates to service, issues JWT via src/utils/jwt.js, sets cookie via src/utils/cookies.js.
  - Service: src/services/auth.service.js hashes passwords (bcrypt), queries via Drizzle, returns sanitized user.
- Data access layer:
  - Drizzle config in drizzle.config.js points schema to src/models/\*.js and out folder to drizzle/.
  - Example model: src/models/user.model.js defines users table (id, name, email unique, password, role, timestamps).
  - DB connection: src/config/database.js switches between Neon HTTP and node-postgres per NEON_LOCAL; exports db (and sql in Neon mode).
- Utilities and configuration:
  - JWT utility: src/utils/jwt.js wraps sign/verify with jsonwebtoken and a default expiry; errors logged via Winston.
  - Cookies helper: src/utils/cookies.js standardizes secure HttpOnly cookie options.
  - Logging: src/config/logger.js configures Winston (file transports + console in non-production); Morgan streams to Winston.
  - Arcjet: src/config/arcjet.js defines rules (shield, detectBot, slidingWindow) in LIVE mode; used in src/middleware/security.middleware.js.

Conventions and tooling

- ESLint: eslint.config.js uses @eslint/js recommended config with formatting-related rules; node_modules, coverage, logs, drizzle are ignored.
- Prettier: .prettierrc.json aligns with 2-space indentation, single quotes, 80 char width, LF EOL.
- Import aliases use Node’s "imports" field; use paths like import foo from '#utils/foo.js'.

Notes for future changes

- If a test framework is introduced, add scripts to package.json (e.g., test, test:watch) and document how to run a single test (e.g., via a pattern or path). Update ESLint globals or overrides if needed.

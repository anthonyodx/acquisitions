# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

Project overview
- Stack: Node.js (ESM) + Express 5, Drizzle ORM, Neon serverless Postgres, Zod validation, Winston + Morgan logging, ESLint + Prettier.
- Entry points: src/index.js loads environment and starts the HTTP server via src/server.js, which boots the Express app defined in src/app.js.
- Import aliases: package.json defines Node ESM import maps for internal modules: #config/*, #controllers/*, #middleware/*, #models/*, #routes/*, #services/*, #utils/*, #validations/*.

Essential commands
- Install dependencies
```sh path=null start=null
npm install
```

- Start the API in watch mode (loads .env via dotenv)
```sh path=null start=null
npm run dev
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
Requires DATABASE_URL to be set in .env. Migrations output to ./drizzle/ per drizzle.config.js.
```sh path=null start=null
# Generate SQL from schema in src/models/*.js
npm run db:generate

# Apply pending migrations to the database in DATABASE_URL
npm run db:migrate

# Explore schema and migrations in a local UI
npm run db:studio
```

- Tests
A test runner is not configured in this repository (no test scripts or config were found). Running a “single test” is not applicable until a test framework (e.g., Jest, Vitest) is added and wired into package.json scripts.

Environment and configuration
- Copy env template and provide values
```sh path=null start=null
cp .env.example .env
# Set DATABASE_URL for Neon/Postgres, and JWT_SECRET (overriding the default in src/utils/jwt.js)
```
- Default port: 3000 (configurable via PORT).
- Health checks (after starting the server):
  - GET / -> "Hello from Acquisitions!"
  - GET /health -> JSON status + uptime
  - GET /api -> JSON API status

High-level architecture
- src/index.js: Bootstraps environment (import 'dotenv/config') and starts the server.
- src/server.js: Reads PORT and calls app.listen().
- src/app.js: Builds the Express app.
  - Middleware: helmet, express.json, cors, urlencoded, cookie-parser, morgan (logs to Winston).
  - Routes: mounts /api/auth via src/routes/auth.routes.js.
  - Basic endpoints: /, /health, /api.
- Routing and request flow (auth example):
  - Route: src/routes/auth.routes.js defines POST /api/auth/sign-up (and placeholders for sign-in/sign-out).
  - Controller: src/controllers/auth.controller.js
    - Validates req.body with Zod (src/validations/auth.validation.js).
    - Delegates to service createUser, signs a JWT token, sets it as a cookie, returns user payload.
  - Service: src/services/auth.service.js
    - Hashes password with bcrypt; checks for existing user; inserts new user via Drizzle; returns selected fields.
- Data access layer:
  - Drizzle config in drizzle.config.js points schema to src/models/*.js and out folder to drizzle/.
  - Example model: src/models/user.model.js defines users table with id, name, email (unique), password, role, timestamps.
  - DB connection: src/config/database.js creates a Neon HTTP client and Drizzle instance, exporting db and sql.
- Utilities and configuration:
  - JWT: src/utils/jwt.js wraps sign/verify with jsonwebtoken and a default expiry; logs errors via Winston.
  - Logging: src/config/logger.js configures Winston (file transports + console in non-production); Morgan streams to Winston.
  - Other helpers live under src/utils and src/middleware.

Conventions and tooling
- ESLint: eslint.config.js uses @eslint/js recommended config with formatting-related rules; node_modules, coverage, logs, drizzle are ignored.
- Prettier: .prettierrc.json aligns with 2-space indentation, single quotes, 80 char width, LF EOL.
- Import aliases use Node’s "imports" field; use paths like import foo from '#utils/foo.js'.

Notes for future changes
- If a test framework is introduced, add scripts to package.json (e.g., test, test:watch) and document how to run a single test (e.g., via a pattern or path). Update ESLint globals or overrides if needed.

# Acquisitions – Dockerized with Neon Database

This project is containerized for both local development with Neon Local and production with Neon Cloud. The application uses Drizzle ORM and automatically switches DB drivers based on environment.

- Development: App + Neon Local proxy in Docker Compose. App connects to `postgres://…@neon-local:5432/...` and uses the Postgres (pg) driver via Drizzle.
- Production: App connects directly to your Neon Cloud `DATABASE_URL` and uses the Neon serverless HTTP driver.

## Prerequisites

- Docker and Docker Compose v2+
- A Neon account and project
- Neon values for development with Neon Local:
  - NEON_API_KEY
  - NEON_PROJECT_ID
  - PARENT_BRANCH_ID (recommended; Neon Local creates ephemeral branches from this)

## Environment files

Two separate env files are provided. Do not commit real secrets.

- .env.development – used by docker-compose.dev.yml
  - DATABASE_URL=postgres://user:password@neon-local:5432/postgres
  - NEON_LOCAL=true (tells the app to use pg driver)
  - NEON_API_KEY, NEON_PROJECT_ID, PARENT_BRANCH_ID for Neon Local
- .env.production – used by docker-compose.prod.yml
  - DATABASE_URL=postgres://…neon.tech…?sslmode=require
  - NEON_LOCAL should NOT be set in production

The app also loads env via `dotenv` in `src/index.js`.

## How it works

- In development, `NEON_LOCAL=true` causes `src/config/database.js` to use the Postgres driver (`drizzle-orm/node-postgres`) connecting to `neon-local:5432`.
- In production (default), it uses Neon serverless HTTP driver (`drizzle-orm/neon-http` with `@neondatabase/serverless`).

## Development – run with Neon Local

1. Configure Neon Local environment

- Copy and edit .env.development

2. Start the stack

```sh
docker compose -f docker-compose.dev.yml up --build
```

- App: http://localhost:3000
- Neon Local: listens on localhost:5432 and service name `neon-local` inside the network
- Neon Local will create an ephemeral branch when the container starts and delete it when it stops (when PARENT_BRANCH_ID is set)

3. Run Drizzle migrations inside the container (optional)

```sh
# Generate SQL from schema
docker compose -f docker-compose.dev.yml run --rm app npm run db:generate

# Apply migrations to the ephemeral branch
docker compose -f docker-compose.dev.yml run --rm app npm run db:migrate

# Explore with Drizzle Studio
docker compose -f docker-compose.dev.yml run --rm --service-ports app npm run db:studio
```

4. Stop

```sh
docker compose -f docker-compose.dev.yml down
```

This also removes the ephemeral Neon branch created by Neon Local.

## Production – run against Neon Cloud

1. Configure .env.production with your Neon Cloud `DATABASE_URL` and secrets

- Example: `postgres://<user>:<password>@<your-host>.neon.tech/<db>?sslmode=require`

2. Build and run

```sh
# Build image
docker compose -f docker-compose.prod.yml build

# Start
docker compose -f docker-compose.prod.yml up -d
```

- App: http://localhost:3000
- There is no Neon Local in production; the app connects directly to Neon Cloud.

3. Migrations in production

```sh
# Apply pending migrations to the Neon Cloud database
docker compose -f docker-compose.prod.yml run --rm app npm run db:migrate
```

## Files added

- Dockerfile – multi-stage build with `dev` and `prod` targets
- docker-compose.dev.yml – app + Neon Local proxy
- docker-compose.prod.yml – app only (no Neon Local proxy)
- .env.development – dev variables including Neon Local config
- .env.production – prod variables (no Neon Local)

## Security and secrets

- Do not hardcode secrets. Use environment variables. In CI/CD or your orchestrator, inject `DATABASE_URL` and other secrets securely.
- For local development, you may populate `.env.development`. For production, prefer secret stores to `.env.production` files.

## Troubleshooting

- `pg`/native modules: The image uses Debian slim for better native module compatibility (e.g., bcrypt). If you switch base images, ensure `bcrypt` remains functional.
- Connection errors in dev: Confirm `NEON_API_KEY`, `NEON_PROJECT_ID`, and `PARENT_BRANCH_ID` are set and valid. Ensure `NEON_LOCAL=true` and `DATABASE_URL` points to `neon-local:5432`.
- Migrations: Drizzle CLI reads `DATABASE_URL` from env; make sure you run it in the same container environment as the app or provide `DATABASE_URL` explicitly.

## TESTS
Testing CI/CD Pipelines

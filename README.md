# PostgreSQL & Flyway with Docker Compose

This project provides a ready-to-use template for managing a PostgreSQL database schema using [Flyway](https://flywaydb.org/) for migrations, all orchestrated with [Docker Compose](https://docs.docker.com/compose/).

This setup is ideal for local development and CI/CD environments, ensuring that your database schema is version-controlled, consistent, and can be recreated or updated automatically and reliably.

## Key Features

-   **Version Controlled Schema:** Your database schema is defined in plain SQL files and can be versioned alongside your application code in Git.
-   **Automated Migrations:** Simply run `docker-compose up`, and Flyway will automatically apply any pending migrations to your database.
-   **Consistent Environments:** Ensures every developer and every environment (development, testing, CI) is running on the exact same database schema.
-   **Persistent Data:** Uses a Docker volume to persist PostgreSQL data between container restarts.

## Prerequisites

Before you begin, ensure you have the following installed:
-   **Docker:** [Installation Guide](https://docs.docker.com/get-docker/)
-   **Docker Compose:** Typically included with Docker Desktop. [Installation Guide](https://docs.docker.com/compose/install/)

## Project Structure

The project is organized to keep database-related files separate and clear.

```
.
├── docker-compose.yml      # Defines the services (PostgreSQL and Flyway)
├── database/
│   ├── flyway.conf         # Flyway configuration (DB connection details)
│   └── sql/
│       ├── V1__create_users_table.sql
│       └── V2__alter_users_to_use_full_name.sql
└── README.md               # This file
```

## Getting Started

Getting your version-controlled database up and running is as simple as a single command.

1.  Clone the repository or create the files as described in the tutorial.
2.  From the root directory of the project, run:

    ```sh
    docker-compose up
    ```

This command will:
1.  Build and start the PostgreSQL (`db`) container.
2.  Wait for the PostgreSQL database to be healthy and ready for connections.
3.  Start the `flyway` container, which will scan the `database/sql` directory and apply any new SQL migrations.
4.  The `flyway` container will exit after successfully applying the migrations, while the `db` container continues to run.

To run the services in the background, use the `-d` (detached) flag:
```sh
docker-compose up -d
```

## The Core Workflow: Managing Migrations

This is the main development loop you will use to evolve your database schema. The key principle of Flyway is that **migrations are immutable**. Once a migration has been applied, you should **never edit it**. Instead, you create a new migration file to make further changes.

### How to Create a New Migration

Let's say you need to add a new `is_active` column to the `users` table.

**1. Understand the Naming Convention**

Flyway discovers migrations by scanning for files that follow a specific naming pattern: `V<VERSION>__<DESCRIPTION>.sql`.

-   `V`: The required prefix (stands for Version).
-   `<VERSION>`: The version number. This can be `1`, `2`, `3.1`, etc. Migrations are applied in numerical order.
-   `__`: Two underscores separate the version from the description.
-   `<DESCRIPTION>`: A human-readable description of what the migration does. Use underscores instead of spaces.
-   `.sql`: The file extension.

**2. Create the New SQL File**

Since our last migration was `V2`, our new one will be `V3`.

Navigate to the `database/sql` directory and create a new file named `V3__add_is_active_to_users.sql`.

**`database/sql/V3__add_is_active_to_users.sql`**
```sql
ALTER TABLE users
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
```

Your `sql` directory now contains the full history of your schema evolution:
```
sql/
├── V1__create_users_table.sql
├── V2__alter_users_to_use_full_name.sql
└── V3__add_is_active_to_users.sql
```

### How to Apply the Changes

With your new `V3` migration file created, applying it is simple.

**1. Run `docker-compose up`**

If your containers are already running, you don't need to stop them. Just run the `up` command again from your project's root directory:

```sh
docker-compose up
```

**2. What Happens Behind the Scenes**

-   Docker Compose sees that the `db` container is already running and leaves it alone.
-   It notices the `flyway` container's task is complete, so it starts a **new** `flyway` container to satisfy the `docker-compose.yml` definition.
-   This new container connects to the database, checks the `flyway_schema_history` table, and sees that the latest version applied is `2`.
-   It scans the `database/sql` directory and finds `V3__...` which has not yet been applied.
-   It executes the `V3` script, updating the database schema.
-   Finally, it records the successful application of version `3` in the `flyway_schema_history` table and exits.

## Verifying Database Changes

You can easily connect to your database to verify that changes have been applied correctly using the `psql` client inside the container.

1.  Execute a `psql` session inside the running `postgres_db` container:
    ```sh
    docker exec -it postgres_db psql -U myuser -d mydatabase
    ```    *(You will be prompted for the password, which is `mypassword`)*

2.  List all tables to see `users` and `flyway_schema_history`:
    ```sql
    \dt
    ```

3.  Inspect the structure of your `users` table to see the new column:
    ```sql
    \d users
    ```

4.  Check the migration history:
    ```sql
    SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;
    ```
    This will show you a complete, ordered list of all migrations that have been applied.

5.  Type `\q` to exit the `psql` session.

## Useful Docker Compose Commands

-   **Start services and apply migrations:**
    `docker-compose up`

-   **Start services in the background:**
    `docker-compose up -d`

-   **Stop and remove containers:**
    `docker-compose down`

-   **Stop, remove containers, AND delete database data:**
    *Use this for a complete reset of your development environment.*
    `docker-compose down -v`

-   **View logs for all services:**
    `docker-compose logs -f`

-   **View logs for a specific service (e.g., Flyway):**
    `docker-compose logs -f flyway`
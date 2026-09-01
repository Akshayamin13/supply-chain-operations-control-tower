# Decision 001 — Local-first SQL foundation

## Status

Accepted for the SQL and data-modelling phases.

## Context

The project is being built on a 2019 Intel MacBook Air. Power BI Desktop is not native to macOS, but PostgreSQL, SQL, Python, Git, and VS Code are available locally.

## Decision

Use local PostgreSQL 16 for the database, Python for reproducible synthetic-data generation, and Git for version history. Defer Power BI until the SQL model is complete and validated.

## Reason

This keeps the early work reproducible on the existing Mac, allows direct SQL practice, and prevents dashboard design from hiding data-quality or modelling problems.

## Consequence

The later Power BI phase will use Power BI Service, a temporary Windows environment, or another compatible workflow chosen according to the features actually required.

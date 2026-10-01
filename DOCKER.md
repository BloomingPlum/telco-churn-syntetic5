# Containerized pipeline (Docker, multi-stage, Compose)

## What runs
| Service | Image | Type | Purpose |
|---|---|---|---|
| generator | `Dockerfile` | one-shot | writes `data/telco_customers.csv` |
| mlflow | `Dockerfile.mlflow` | long-running, :5000 | tracking server + model registry |
| trainer | `Dockerfile.train` | one-shot | trains model, logs + registers `ChurnModel`, writes `models/churn_model.pkl` |
| api | `Dockerfile.api` | long-running, :8000 | FastAPI `/health`, `/predict`, `/docs` |
| jupyter | public image | optional (`--profile jupyter`) | exploration |

Order is enforced by `depends_on` conditions: `generator` must **complete**, `mlflow` must be **healthy**, then `trainer` runs; `api` starts only after `trainer` **completes successfully**.

## Multi-stage builds
Each image has a `builder` stage (venv + any compilers) and a slim `runtime` stage that copies only `/opt/venv` and the code. The API image also:
- drops `xgboost` and `mlflow` (unused by the sklearn model; `predict.py` falls back to the local `.pkl`),
- runs as a non-root user,
- does not bake the model in — it is mounted read-only from `./models`,
- uses a stdlib health check (python-slim has no `curl`).

## Auto-start
- `restart: unless-stopped` on `mlflow` and `api` (Docker restarts them after crashes and reboots).
- `deploy/telco-churn.service` (systemd) runs `docker compose up -d --build` at boot, so the whole pipeline reruns.

## Run
```bash
docker compose up -d --build
docker compose logs -f trainer     # watch training
./scripts/smoke_test.sh            # end-to-end test
```

## Fixes vs. the original setup
- `mlflow_db/mlflow.db` was created by MLflow 3.x; the MLflow 2.x server cannot open it → the server now uses a fresh named volume.
- MLflow 2.17 crashes with SQLAlchemy 2.1 → pinned `sqlalchemy==2.0.36`.
- The API health check used `curl`, which is absent in python-slim → always "unhealthy".
- No training step existed in Compose, so the API had no model on a fresh clone (`*.pkl` is git-ignored).

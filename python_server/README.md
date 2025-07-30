To run this server, install the dependencies in requirements.txt and then run uvicorn app.main:app --reload

## Setup

Make sure to re-install dependencies after pulling changes:

```bash
pip install -r requirements.txt
```

## Run locally

```bash
uvicorn app.main:app --reload --port ${PORT:-8000}
```

#!/usr/bin/env bash
set -e

echo "Activating virtual environment…"
# adjust path if you used a different venv name
source /home/site/wwwroot/antenv/bin/activate

echo "Launching Gunicorn…"
exec gunicorn app.backend.app:app --bind 0.0.0.0:8000 --workers 4 --timeout 120

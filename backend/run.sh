#!/bin/bash
# Run FastAPI backend
cd "$(dirname "$0")"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate
pip install -r requirements.txt -q

if [ "$1" = "--host" ]; then
    echo "Starting server (0.0.0.0:8000)..."
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
else
    echo "Starting server (localhost:8000)..."
    uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
fi

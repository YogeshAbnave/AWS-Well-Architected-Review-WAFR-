# ---------------------------------------------------------
# Stage 1: Builder image (installs deps in isolated layer)
# ---------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements first (to leverage Docker layer caching)
COPY requirements.txt .

# Create a virtual environment and install deps
RUN python -m venv /opt/venv \
 && . /opt/venv/bin/activate \
 && pip install --upgrade pip setuptools wheel \
 && pip install -r requirements.txt

# ---------------------------------------------------------
# Stage 2: Final image (lightweight runtime)
# ---------------------------------------------------------
FROM python:3.11-slim

WORKDIR /app

# Copy venv and app files from builder
COPY --from=builder /opt/venv /opt/venv
COPY . .

# Use virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Streamlit env vars for ECS
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_SERVER_ENABLECORS=false
ENV STREAMLIT_SERVER_ENABLEXSRFPROTECTION=false
ENV STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
ENV PYTHONUNBUFFERED=1

# Health check (ECS-friendly)
HEALTHCHECK CMD curl --fail http://localhost:8502/_stcore/health || exit 1

# Expose port 8502
EXPOSE 8502

# Non-root user for security
RUN useradd -m appuser
USER appuser

# Start Streamlit
CMD ["streamlit", "run", "ui_code/WAFR_Accelerator.py", "--server.port", "8502", "--server.address", "0.0.0.0"]

FROM python:3.12-slim

# Tools the server shells out to (apt/dpkg inspection, general utilities).
# docker-cli provides the `docker` CLI so execute_command can run docker
# commands against the host daemon via the bind-mounted docker.sock (Debian
# splits docker.io into a daemon-only package + this CLI-only package).
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps \
    docker-cli \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /usr/sbin/nologin mcp
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Nested one level below /app so the server's own path-protection logic
# (which blocks dirname(script_dir)) doesn't resolve to "/"
COPY main.py config.py check_disk_space.py ./server/

USER mcp

# Override MCP_PORT (and publish the matching -p host:container mapping) to
# avoid clashing with other services on the host.
ENV MCP_TRANSPORT=streamable-http \
    MCP_HOST=0.0.0.0 \
    MCP_PORT=8000
EXPOSE 8000

ENTRYPOINT ["python", "server/main.py"]
CMD ["--policy", "secure"]

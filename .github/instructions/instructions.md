# Ubuntu MCP Server Agent Instructions

This is a security-first Model Context Protocol server giving AI assistants
secure, controlled access to Ubuntu system operations: file read/write/list
with path-traversal protection, sanitized command execution with
whitelist/blacklist filtering, system information, and APT package
search/listing. It uses defense-in-depth controls and comprehensive audit
logging.

On this host it runs in Docker as container `metis-ubuntu-controller`
(compose service `ubuntu-controller` in `/opt/metis-router/docker-compose.yml`,
image `ubuntu-mcp-server:latest`) on the shared `metis-network`, and is
registered as a metis-router upstream (`ubuntu-controller:` tool namespace).
It acts as the host execution bridge, agent skill loader, and job harness for
the Metis stack. It is internal-only and not published through Traefik.

## Tool execution rule

All tool calls that invoke `python`, `node`, `vite`, or `php` MUST run inside
Docker — never on the host. The host has no project runtimes installed.

- Python runs in the controller container, e.g.
  `docker exec metis-ubuntu-controller python3 ...` or
  `docker compose -f /opt/metis-router/docker-compose.yml exec ubuntu-controller python3 ...`
- For ad-hoc Node tooling, use
  `docker run --rm -v /opt/ubuntu_mcp_server:/srv -w /srv node:22-alpine ...`

## Conventions

- Keep the security model intact: path allowlists, command sanitization,
  resource limits, and audit logging are load-bearing, not optional.
- The container mounts `/opt` and `/tmp/metis-jobs`; paths inside the
  container mirror the host layout.

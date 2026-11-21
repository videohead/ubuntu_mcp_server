# ubuntu_mcp_server - Docker-Only Deployment Guide

## ⚠️ Critical Rule: Docker-Only

**Ubuntu MCP Server MUST run exclusively in Docker.** Do not attempt to run this service on the host machine.

## Why Docker-Only?

- **Isolation**: Dependencies and configuration are contained and won't conflict with the host
- **Resource Management**: CPU, memory, and GPU resources are properly allocated and limited
- **Port Management**: All ports are mapped consistently through Docker networking
- **Easy Restart**: Clean stop/start cycles through Docker Compose
- **Consistency**: Ensures the entire stack behaves identically across environments
- **Security**: Containerization provides boundaries between services

## Stack Architecture

ubuntu_mcp_server is part of the larger AI Agent Stack. All services coordinate through Docker networking:

```
┌─────────────────────────────────────────────┐
│          AI Agent Stack (All Docker)         │
├─────────────────────────────────────────────┤
│ • Chatbot (port 3000)                       │
│ • LiteLLM Proxy (port 4200)                 │
│ • Agent Framework Service                   │
│ • Switchyard                                │
│ • Ubuntu MCP Server (port 8001)             │
│ • ComfyUI (port 8188)                       │
│ • VideoBrain (port 8936)                    │
│ • Morphazoid (port 8935)                    │
│ • AudioBrain (port 8937)                    │
│ • vLLM Model Servers (port 11434)           │
│ • PostgreSQL Databases                      │
│ • Traefik Reverse Proxy                     │
└─────────────────────────────────────────────┘

HOST OS (Ubuntu)
├─ System Services (SSH, DNS, etc.)
└─ Docker Engine
   └─ Docker Network Bridge
      └─ All Application Services (NEVER on host)
```

## Startup

**Always use the main stack startup script (recommended):**
```bash
bash /opt/chatbot/scripts/stack start
```

This ensures proper dependency ordering and health checks.

**Alternative - start just this service's Docker Compose:**
```bash
cd /opt/ubuntu_mcp_server
docker-compose up -d
docker-compose logs -f
```

## Shutdown

**Use the main stack shutdown script:**
```bash
bash /opt/chatbot/scripts/stack stop
```

**Or stop just this service:**
```bash
cd /opt/ubuntu_mcp_server
docker-compose down
```

## Verification

Check that the service is running in Docker (not on host):
```bash
# Should show the container running
docker ps --filter "name=Ubuntu MCP Server"

# Should show port mappings
docker ps --filter "name=Ubuntu MCP Server" --format "{{.Ports}}"

# Check health
docker ps --filter "name=Ubuntu MCP Server" --format "{{.Status}}"
```

## Configuration

### Environment Variables

Configuration is managed through:
- `.env` file in the project directory (gitignored)
- `docker-compose.yml` or `compose.yaml` for Docker configuration
- Mounted config volumes in the container

**Do not edit these on the host.** To change configuration:

1. Edit `.env` or docker-compose file
2. Rebuild: `docker-compose build`
3. Restart: `docker-compose up -d`

### Secrets & Credentials

**Security rule**: Never commit secrets to git.

- Secrets are stored in `/opt/ubuntu_mcp_server/.env` (gitignored)
- Reference with `env_file` in `docker-compose.yml`
- File permissions should be `600` (owner read/write only)

## Troubleshooting

### Service won't start

1. Check Docker is running: `docker ps`
2. Check compose file is valid: `docker-compose config`
3. Review logs: `docker-compose logs -f`
4. Check port conflicts: `ss -tuln | grep <PORT>`

### Service crashed

1. Check container logs: `docker logs <container-name>`
2. Verify resource availability: `docker stats`
3. Check environment variables: `docker inspect <container-name>`
4. Restart: `docker-compose restart`

### Port already in use

If port conflicts occur:
1. Identify conflicting process: `ss -tuln | grep <PORT>`
2. If it's another Docker container: stop it via compose
3. If it's a host process: **this is a misconfiguration** — the service should be in Docker
4. Update port in `.env` if needed: `PORT=XXXXX`

## Logs

View real-time logs:
```bash
docker-compose logs -f
```

View specific container:
```bash
docker logs -f <container-name>
```

## Maintenance

### Updating the Service

```bash
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build

# Check status
docker-compose ps
```

### Cleaning Up

```bash
# Stop and remove containers
docker-compose down

# Remove images (if needed)
docker rmi <image-name>

# Clean up unused Docker resources
docker system prune
```

## References

For detailed deployment guidance for the entire stack, see:
- [`/opt/litellm/AGENTS.md`](../../litellm/AGENTS.md) - Quick reference guide
- [`/opt/litellm/.github/instructions/instructions.md`](../../litellm/.github/instructions/instructions.md) - Comprehensive deployment guide
- [`/opt/README.md`](../../README.md) - Main project documentation

## Support

If this service needs to run on the host (outside Docker):
1. **Document why** in this file with specific requirements
2. **Get approval** from the project maintainer
3. **Update all documentation** to reflect the exception
4. **Monitor** for port conflicts and dependency issues

Default expectation: **Docker-only, all services, always.**

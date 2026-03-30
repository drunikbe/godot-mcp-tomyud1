# Godot MCP — Claude Code Guidelines

## Project Overview

MCP server + Godot plugin that gives AI assistants (Claude, Cursor, etc.) full access to the Godot 4.x editor via WebSocket.

## Repository Structure

- **Upstream**: `tomyud1/godot-mcp` — the original repo, published to npm and Godot Asset Library
- **This fork**: `drunikbe/godot-mcp` — our development fork (owner: Andrei Lavrenov / elfensky)
- We develop features here, then open PRs on `tomyud1/godot-mcp` to contribute upstream
- The upstream author (tomyud1) typically re-implements our suggestions with tweaks rather than merging our PRs directly, crediting us in changelogs

## Branching

- `main` — tracks `upstream/main` (currently v0.2.8)
- `develop` — our active development branch (v0.3.0-drunik.1), 9 commits ahead of main
- `pr/*` branches — isolated feature branches for upstream PRs

## Key Paths

- `addons/godot_mcp/` — Godot plugin (GDScript)
- `mcp-server/src/` — MCP server (TypeScript/Node.js)
- `mcp-server/src/index.ts` — main server entry point, tool registrations
- `addons/godot_mcp/tools/` — GDScript tool implementations

## Upstream Tool Conventions (match these when contributing)

- **Descriptions**: 1-2 sentences, action-oriented. Use CAPS for critical constraints (NEVER, ONLY). Cross-reference related tools in descriptions so the AI discovers workflows naturally.
- **Input validation**: Always validate before executing — `FileAccess.file_exists()`, `ClassDB.class_exists()`, etc. Return `{&"ok": false, &"error": "..."}` on failure, never fail silently.
- **Virtual methods**: Keep well-known virtuals (`_ready`, `_process`, `_physics_process`, `_input`) — don't filter all `_` prefixed methods.
- **Workflow hints**: Encode multi-step workflows in tool descriptions (e.g., "run → is_playing → get_errors → stop → fix → repeat").

## Git Remotes

```
origin    https://github.com/drunikbe/godot-mcp.git
upstream  https://github.com/tomyud1/godot-mcp.git
```

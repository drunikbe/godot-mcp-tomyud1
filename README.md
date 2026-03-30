# Godot MCP

**Give your AI assistant full access to the Godot editor.**

Build games faster with Claude, Cursor, or any MCP-compatible AI — no copy-pasting, no context switching. AI reads, writes, and manipulates your scenes, scripts, nodes, and project settings directly.

> Godot 4.x · 42 tools · Multi-session HTTP daemon · Interactive project visualizer · MIT license

---

## Quick Start

### 0. Install Node.js (one-time setup)

Download and run the installer from **[nodejs.org](https://nodejs.org/en/download)** (LTS version). It's a standard installer — no terminal needed.

### 1. Install the Godot plugin

Inside the Godot editor, click the **AssetLib** tab at the top → search **"mcp"** → find **"Godot AI Assistant tools MCP"** → Install.

Then go to **Project → Project Settings → Plugins** and enable the **Godot MCP** plugin.

### 2. Add the server config to your AI client

**Claude Desktop** — Settings → Developer → Edit Config → open the config file and paste:

Mac / Linux:
```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "godot-mcp-server"]
    }
  }
}
```

Windows:
```json
{
  "mcpServers": {
    "godot": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "godot-mcp-server"]
    }
  }
}
```

**Cursor** — Settings → MCP → Add Server:

Mac / Linux:
```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "godot-mcp-server"]
    }
  }
}
```

Windows:
```json
{
  "mcpServers": {
    "godot": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "godot-mcp-server"]
    }
  }
}
```

**Claude Code** — run in terminal:
```bash
claude mcp add godot -- npx -y godot-mcp-server
```

Works with any MCP-compatible client (Cline, Windsurf, etc.)

### 3. Restart your AI client

Close and reopen Claude Desktop / Cursor / your client so it picks up the new config.

### 4. Restart your Godot project

Hit **Restart Project** in the Godot editor. Check the **top-right corner** — you should see **MCP Connected** in green. You're ready to go.

---

## What Can It Do?

### 42 Tools Across 6 Categories

| Category | Tools | Examples |
|----------|-------|---------|
| **File Operations** | 5 | Browse directories, read files, search project, create scripts, delete/rename files |
| **Scene Operations** | 11 | Create scenes, add/remove/move nodes, set properties, attach scripts, assign collision shapes and textures |
| **Script Operations** | 6 | Apply code edits, validate syntax, rename/move files with reference updates |
| **Project Tools** | 16 | Project settings, input map, collision layers, console/debugger errors, run/stop scenes, ClassDB queries, scene tree dumps, autoloads |
| **Asset Generation** | 1 | Generate 2D sprites from SVG |
| **Visualization** | 2 | Interactive browser-based project map, scene dependency map |

### Interactive Visualizer

Run `map_project` and get a browser-based explorer at `localhost:6510`:
- Force-directed graph of all scripts and their relationships
- Click any script to see variables, functions, signals, and connections
- Edit code directly in the visualizer — changes sync to Godot in real time
- Scene view with node property editing
- Find usages before refactoring
<img width="1710" height="1107" alt="image" src="https://github.com/user-attachments/assets/a9faf163-8b8b-43da-93ec-c7a651e8ac60" />

### Limitations

AI cannot create 100% of a game by itself — it struggles with complex UI layouts, compositing scenes, and some node property manipulation. It's still in active development, so feedback is very welcome!

---

## Architecture

**stdio mode** (default — one AI client per server):
```
┌─────────────┐    MCP (stdio)    ┌─────────────┐   WebSocket    ┌──────────────┐
│  AI Client   │◄────────────────►│  MCP Server  │◄─────────────►│ Godot Editor │
│  (Claude,    │                  │  (Node.js)   │   port 6505   │  (Plugin)    │
│   Cursor)    │                  └─────────────┘               └──────────────┘
└─────────────┘
```

**HTTP daemon mode** (`--http` — multiple AI clients):
```
┌─────────────┐                   ┌─────────────┐   WebSocket    ┌──────────────┐
│  Claude A    │◄─── HTTP ───────►│             │◄─────────────►│ Godot Editor │
└─────────────┘    :6506          │  MCP Daemon  │   port 6505   │  (Plugin)    │
┌─────────────┐                   │  (Node.js)   │               │              │
│  Claude B    │◄─── HTTP ───────►│             │               │  42 tool     │
└─────────────┘                   └─────────────┘               │  handlers    │
                                                                └──────────────┘
```

Start the daemon: `npm run daemon` (or `node dist/index.js --http`)

Client config for daemon mode:
```json
{
  "mcpServers": {
    "godot": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:6506/mcp"
    }
  }
}
```

---

## Current Limitations

- **Local only** — runs on localhost, no remote connections
- **Single Godot instance** — one Godot editor at a time (multiple AI clients supported in daemon mode)
- **No undo** — changes save directly (use version control)
- **AI is still limited in Godot knowledge** — it can't create 100% of the game alone, but it can help debug, write scripts, and tag along for the journey

---

## Development

To build from source instead of using npm:

```bash
cd mcp-server
npm install
npm run build
```

Then point your AI client at `mcp-server/dist/index.js` instead of using `npx`.

---

## License

MIT

---

**[npm package](https://www.npmjs.com/package/godot-mcp-server)** · **[Report Issues](https://github.com/tomyud1/godot-mcp/issues)**

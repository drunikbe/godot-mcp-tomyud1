@tool
extends EditorPlugin
## Godot MCP Plugin
##
## Connects to the godot-mcp-server via WebSocket and executes tools.
## On load, the plugin auto-starts the MCP daemon (HTTP mode) if the built
## server is found in the godot-mcp repo. The daemon auto-exits when Godot
## disconnects and no clients reconnect within the idle timeout.
##
## When installed from a release (not the dev repo), the daemon must be
## started manually — the auto-start gracefully skips if dist/index.js
## is not found at the expected path.

const MCPClientScript = preload("res://addons/godot_mcp/mcp_client.gd")
const ToolExecutorScript = preload("res://addons/godot_mcp/tool_executor.gd")

var _mcp_client: Node  # MCPClient
var _tool_executor: Node  # ToolExecutor
var _status_label: Label

func _enter_tree() -> void:
	print("[Godot MCP] Plugin loading...")

	# Ensure the MCP daemon is running before we try to connect
	_ensure_daemon_running()

	# Create MCP client
	_mcp_client = MCPClientScript.new()
	_mcp_client.name = "MCPClient"
	add_child(_mcp_client)

	# Create tool executor
	_tool_executor = ToolExecutorScript.new()
	_tool_executor.name = "ToolExecutor"
	add_child(_tool_executor)  # _ready() runs here, creating child tools
	_tool_executor.set_editor_plugin(self)  # Now _visualizer_tools exists

	# Connect signals
	_mcp_client.connected.connect(_on_connected)
	_mcp_client.disconnected.connect(_on_disconnected)
	_mcp_client.tool_requested.connect(_on_tool_requested)

	# Add status indicator to editor
	_setup_status_indicator()

	# Start connection
	_mcp_client.connect_to_server()

	print("[Godot MCP] Plugin loaded - connecting to MCP server...")

## Auto-start the MCP daemon if running from the dev repo.
##
## Path resolution: the addon directory is typically symlinked from game projects
## into the godot-mcp repo (e.g. snake/addons/godot_mcp -> godot-mcp/addons/godot_mcp).
## ProjectSettings.globalize_path("res://...") returns the project-side path without
## following symlinks, so we resolve via realpath (macOS/Linux) or PowerShell (Windows)
## to find the actual repo location and derive the mcp-server path from there.
func _ensure_daemon_running() -> void:
	var addon_path := ProjectSettings.globalize_path("res://addons/godot_mcp")
	var real_addon_dir := _resolve_symlink(addon_path)
	var server_dir := real_addon_dir.path_join("../../mcp-server").simplify_path()
	var index_path := server_dir.path_join("dist/index.js")

	if not FileAccess.file_exists(index_path):
		# Expected when plugin is installed from release (not the dev repo).
		# The MCP server must be started separately in that case.
		print("[Godot MCP] No local daemon found — start the MCP server manually or via npx")
		return

	# Check if the daemon is already listening on port 6505.
	if _is_port_in_use(6505):
		print("[Godot MCP] Daemon already running (port 6505 in use)")
		return

	# Spawn the daemon detached — it will outlive Godot if needed.
	print("[Godot MCP] Starting MCP daemon from %s" % server_dir)
	var pid: int
	if OS.get_name() == "Windows":
		pid = OS.create_process("cmd.exe", [
			"/c", "cd /d \"%s\" && node dist/index.js --http --no-force" % server_dir
		])
	else:
		# Use login shell (-l) so PATH includes mise/nvm/homebrew managed node.
		var shell := OS.get_environment("SHELL")
		if shell == "":
			shell = "/bin/sh"
		pid = OS.create_process(shell, [
			"-l", "-c",
			"cd '%s' && node dist/index.js --http --no-force" % server_dir
		])
	if pid > 0:
		print("[Godot MCP] Daemon started (PID %d)" % pid)
	else:
		push_warning("[Godot MCP] Failed to start daemon")

## Resolve a filesystem path through symlinks to its real location.
## Returns the original path if resolution fails or no symlink exists.
func _resolve_symlink(path: String) -> String:
	var output: Array = []
	if OS.get_name() == "Windows":
		# PowerShell resolves symlinks/junctions
		var exit_code := OS.execute("powershell", [
			"-NoProfile", "-Command",
			"(Get-Item '%s').Target ?? '%s'" % [path, path]
		], output, true, false)
		if exit_code == 0 and output.size() > 0:
			var resolved := (output[0] as String).strip_edges()
			if resolved != "":
				return resolved
	else:
		var exit_code := OS.execute("realpath", [path], output, true, false)
		if exit_code == 0 and output.size() > 0:
			var resolved := (output[0] as String).strip_edges()
			if resolved != "":
				return resolved
	return path

## Check if a TCP port is already in use (to avoid spawning duplicate daemons).
## Uses lsof on macOS/Linux, netstat on Windows.
func _is_port_in_use(port: int) -> bool:
	var output: Array = []
	if OS.get_name() == "Windows":
		var exit_code := OS.execute("cmd.exe", [
			"/c", "netstat -ano | findstr :%d | findstr LISTENING" % port
		], output, true, false)
		return exit_code == 0 and output.size() > 0 and output[0].strip_edges() != ""
	else:
		var exit_code := OS.execute("lsof", ["-ti", ":%d" % port], output, true, false)
		return exit_code == 0 and output.size() > 0 and output[0].strip_edges() != ""

func _exit_tree() -> void:
	print("[Godot MCP] Plugin unloading...")

	if _mcp_client:
		_mcp_client.disconnect_from_server()
		_mcp_client.queue_free()

	if _tool_executor:
		_tool_executor.queue_free()

	if _status_label:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _status_label)
		_status_label.queue_free()

	print("[Godot MCP] Plugin unloaded")

func _setup_status_indicator() -> void:
	"""Add a small status label to the editor toolbar."""
	_status_label = Label.new()
	_status_label.text = "MCP: Connecting..."
	_status_label.add_theme_color_override("font_color", Color.YELLOW)
	_status_label.add_theme_font_size_override("font_size", 12)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _status_label)

func _on_connected() -> void:
	print("[Godot MCP] Connected to MCP server")
	if _status_label:
		_status_label.text = "MCP: Connected"
		_status_label.add_theme_color_override("font_color", Color.GREEN)

func _on_disconnected() -> void:
	print("[Godot MCP] Disconnected from MCP server")
	if _status_label:
		_status_label.text = "MCP: Disconnected"
		_status_label.add_theme_color_override("font_color", Color.RED)

func _on_tool_requested(request_id: String, tool_name: String, args: Dictionary) -> void:
	"""Handle incoming tool request from MCP server."""
	print("[Godot MCP] Executing tool: ", tool_name)

	# Execute the tool
	var result: Dictionary = _tool_executor.execute_tool(tool_name, args)

	var success: bool = result.get(&"ok", false)
	if success:
		result.erase(&"ok")
		_mcp_client.send_tool_result(request_id, true, result)
	else:
		var error: String = result.get(&"error", "Unknown error")
		_mcp_client.send_tool_result(request_id, false, null, error)

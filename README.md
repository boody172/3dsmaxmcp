# 3dsmaxmcp

Claude Code MCP config for the **max-ultra-mcp** 3ds Max 2024 server (`archviz` tool profile, port `47635`).

## Use

1. On the Windows PC running 3ds Max 2024, start 3ds Max with the max-ultra-mcp plugin loaded.
2. Clone this repo and run `claude` from its folder. Claude Code reads `.mcp.json` and asks you to approve `max-ultra-mcp`.
3. Check it with `/mcp` inside Claude Code.

## Note

The paths in `.mcp.json` point into 3ds Max's `ENU\temp\<id>\` folder. If 3ds Max regenerates that folder, update both paths in `.mcp.json` to the new location.

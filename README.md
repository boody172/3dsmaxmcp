# 3dsmaxmcp

Claude Code MCP config for the **max-ultra-mcp** 3ds Max 2024 server (`archviz` tool profile, port `47635`).

## Use

1. On the Windows PC running 3ds Max 2024, start 3ds Max with the max-ultra-mcp plugin loaded.
2. Clone this repo and run `claude` from its folder. Claude Code reads `.mcp.json` and asks you to approve `max-ultra-mcp`.
3. Check it with `/mcp` inside Claude Code.

## Note

The paths in `.mcp.json` point into 3ds Max's `ENU\temp\<id>\` folder. If 3ds Max regenerates that folder, update both paths in `.mcp.json` to the new location.

## Booth models (`Booth_Models.ms`)

MAXScript that builds two booth models in real meters (3ds Max 2024, Physical Materials):

| | Booth A – White (as built) | Booth B – Merged |
|---|---|---|
| Footprint | 3.00 × 4.00 m | same |
| Height | 4.20 m (walls 3.60 + cornice 0.60) | same + 1.0 m roof-terrace railing |
| Arch opening | 2.10 m wide, crown 3.45 m, black steel frame | same + warm LED line |
| Walls | white cement board, rounded corners R0.30, fluted front corners | front stays white; sides/back black corrugated container steel |
| Inside | steel mezzanine @ 2.20 m, counter 1.04 m | + wood-slat counter, pendants, menu board, planter with vines |
| Extras | side window + roller-shutter box, steel side swoop | green wall, roof deck + planters + lamp, COFFEE sign, bar stools, potted tree |

Run: **Scripting → Run Script… → `Booth_Models.ms`**. Model A sits at X=0, Model B at X=7 m, each on its own layer with its own camera.

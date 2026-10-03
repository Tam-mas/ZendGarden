"""Rebuild the same MCP-authored assets sequentially in a background Blender.

The initial overhaul was built through Blender MCP. This is its reproducible
maintenance entry point; it never resets Blender preferences or other scenes.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import structures,animals,scenery,mcp_run
mcp_run.run('structures',structures.OLD+structures.NEW)
mcp_run.run('animals',animals.MAMMALS+animals.BIRDS+['frog','fish','bee','butterfly','dragonfly','firefly','lady_beetle','blue_banded_bee','hoverfly','mantis','leaf_insect','emperor_gum_moth'])
mcp_run.run('scenery',['garden_shed','footbridge','lakeside_cottage','environment'])
print('OVERHAUL_BUILD: PASS')

#!/usr/bin/env python3
"""Export an isolated browser benchmark; personal saves stay in ignored build/.

Usage: GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/build_dense_benchmark.py /absolute/save.json
Serve build/web on localhost, open Chrome and press Enter the garden. Results
appear in the page and console. Run tools/build_web.py again for a normal build.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('save',type=Path)
    parser.add_argument('--baseline-ref',help='Optional local Git commit/ref for the original runtime scripts')
    args=parser.parse_args()
    data=json.loads(args.save.read_text())
    if not isinstance(data,dict) or not isinstance(data.get('plants'),list):
        raise ValueError('Supply a garden save JSON file')
    data.setdefault('settings',{}).update(intro_seen=True,updates_seen=999999,pause_menus=False,volume=0)
    project=ROOT/'project.godot'
    original=project.read_text()
    entry='run/main_scene="res://main.tscn"'
    if entry not in original:
        raise RuntimeError('Expected normal game entry scene; refusing to change the project')
    paths=['scripts/garden.gd','scripts/garden_art.gd','scripts/garden_care.gd','scripts/garden_sculpt.gd','scripts/plant_growth.gd','scripts/plant_inspector.gd','scripts/touch_controls.gd','shaders/leaf_wind.gdshader','shaders/plant_shape.gdshaderinc']
    backups={}
    try:
        if args.baseline_ref:
            for name in paths:
                path=ROOT/name
                baseline=subprocess.check_output(['git','show',f'{args.baseline_ref}:{name}'],cwd=ROOT)
                backups[path]=path.read_bytes()
                path.write_bytes(baseline)
        project.write_text(original.replace(entry,'run/main_scene="res://tests/benchmark_web.tscn"'))
        subprocess.run([sys.executable,str(ROOT/'tools/build_web.py')],cwd=ROOT,check=True)
    finally:
        project.write_text(original)
        for path,content in backups.items():path.write_bytes(content)
    folder=ROOT/'build/web'
    (folder/'benchmark-save.js').write_text('window.gardenBenchmarkSave='+json.dumps(json.dumps(data))+';\n')
    page=folder/'index.html'
    html=page.read_text().replace('<script src="loader.js"></script>','<script src="benchmark-save.js"></script>\n<script src="loader.js"></script>')
    html=html.replace('</body>','<pre id="benchmark-report" style="position:fixed;bottom:10px;left:10px;color:white;z-index:9999">Benchmark running…</pre></body>')
    page.write_text(html)

if __name__=='__main__':main()

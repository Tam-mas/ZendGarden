"""Append-only low plant IDs, realistic stature, assets and compact portrait coverage."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
profiles=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
for index in range(136,148):
    assert specs[index][1]=='Grasses' and specs[index][3]==0
    assert 0<profiles[index]['height']<=.32,(index,'Low grass is too tall')
    assert any((ROOT/f'assets/ui/plants/{index}.{suffix}').exists() for suffix in ['png','webp'])
    assert (ROOT/f'assets/plants/plant_{index}.glb').is_file()
    assert (ROOT/f'assets/plants/growth/growth_{index}.glb').is_file()
assert len(set(row[0] for row in specs))==218
print('LOW_GRASSES_CHECK: PASS — twelve distinct short, creeping and grass-like plants')

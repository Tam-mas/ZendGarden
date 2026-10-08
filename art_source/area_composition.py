"""Composed planting for the ten habitats, using the garden's native flora.

Install after the construction/material passes. This changes decorative planting
only: authored height fields, saved fixtures, collection slots and paving retain
their established contracts. Broad, repeated drifts replace isolated speckles;
the central growing space and every working approach remain open.
"""
import math
import random

import bpy
import area_cohesion


# x, z, half-width, half-depth, number, dominant species, companion, scale.
# Numeric species are existing catalogue assets; strings are habitat collections.
# Keep plant counts close to the former scatter while making the silhouettes
# visible: low grasses knit the base, a few taller plants define each drift.
DRIFTS = {
    0: [
        (-5.7, -2.0, 1.0, 1.8, 13, 'reed', 147, .76),
        (-3.5, -4.25, 1.9, .7, 14, 16, 147, 1.0),
        (.8, -4.2, 1.35, .7, 11, 'reed', 146, .78),
        (3.25, .4, .65, 1.55, 12, 16, 147, .95),
        (-5.5, 2.5, 1.1, .65, 10, 146, 16, 1.25),
        (-8.25, -5.7, 1.7, 1.5, 15, 112, 146, .70),
        (7.9, -6.4, 1.5, 1.8, 15, 16, 146, .88),
        (-8.1, 7.55, 1.7, .7, 12, 146, 147, 1.5),
        (2.3, 7.9, 2.5, .65, 16, 146, 16, 1.3),
    ],
    1: [
        (-6.65, -5.2, 1.8, 1.8, 17, 'maidenhair', 136, .73),
        (-5.5, -.9, 2.1, 1.3, 17, 'maidenhair', 145, .68),
        (-5.7, 4.0, 1.8, 1.3, 14, 109, 'maidenhair', .88),
        (6.6, -4.8, 1.7, 1.9, 18, 'maidenhair', 136, .75),
        (6.6, .6, 1.3, 1.9, 16, 109, 'maidenhair', .87),
        (5.3, 5.6, 1.7, 1.0, 14, 'maidenhair', 145, .70),
        (-3.0, -8.6, 2.3, .7, 12, 136, 145, 1.75),
        (-8.75, 1.3, .65, 2.0, 12, 145, 'maidenhair', 1.1),
    ],
    2: [
        (-5.25, 3.05, .65, .60, 8, 124, 142, 1.15),
        (4.45, 3.0, .72, .58, 8, 126, 144, 1.45),
        (-5.1, -1.6, .75, .62, 8, 126, 142, 1.55),
        (4.6, -1.7, .55, .62, 8, 124, 144, 1.15),
        (-4.9, -6.1, .65, .65, 8, 124, 142, 1.18),
        (3.5, -5.8, 1.0, .45, 9, 126, 144, 1.55),
        (-7.5, -3.9, .85, 1.8, 14, 14, 142, .96),
        (-7.75, 2.6, .7, 1.65, 14, 142, 12, 1.7),
        (8.8, -3.75, .60, 1.75, 14, 14, 142, .94),
        (1.0, -8.7, 2.6, .60, 16, 142, 12, 1.7),
        (-2.2, 8.7, 2.1, .65, 13, 142, 12, 1.65),
    ],
    3: [
        (-5.2, -4.8, 2.1, 1.4, 19, 164, 113, .92),
        (2.9, -5.0, 1.65, 1.5, 18, 163, 113, .97),
        (5.8, -1.15, 1.5, 1.5, 17, 164, 113, .92),
        (-5.6, -.3, 1.35, 1.7, 17, 163, 113, .96),
        (-3.9, 3.45, 1.6, 1.3, 16, 164, 113, .92),
        (6.6, 2.9, 1.0, .65, 9, 163, 141, .92),
        (-6.0, 5.4, 1.8, .65, 12, 141, 113, 1.45),
        (7.9, -6.45, 1.15, 1.3, 13, 113, 141, 1.02),
        (-1.65, -8.7, 2.2, .55, 12, 141, 164, 1.45),
    ],
    4: [
        (-7.1, -4.7, .48, 1.75, 13, 19, 141, 1.18),
        (-7.1, .4, .5, 1.9, 13, 19, 141, 1.18),
        (7.0, -4.7, .48, 1.75, 13, 19, 141, 1.18),
        (7.0, .4, .5, 1.9, 13, 19, 141, 1.18),
        (-4.6, -8.75, 2.0, .45, 13, 113, 141, .98),
        (3.1, -8.75, 2.25, .45, 14, 113, 141, .98),
        (-8.95, 3.5, .55, 1.4, 11, 141, 19, 1.6),
        (8.95, -1.5, .55, 1.5, 11, 141, 19, 1.6),
        (-3.5, 8.6, 1.25, .60, 12, 19, 141, 1.25),
        (2.25, 8.6, 1.15, .6, 10, 19, 141, 1.25),
    ],
    5: [
        (-8.2, -3.7, .72, 1.5, 15, 1, 12, .73),
        (-8.2, 1.5, .70, 1.6, 15, 22, 12, .56),
        (8.2, -3.3, .72, 1.6, 15, 1, 12, .73),
        (8.2, 2.3, .72, 1.6, 15, 22, 12, .56),
        (-3.6, -8.05, 1.8, .62, 15, 1, 12, .72),
        (2.2, -8.05, 1.8, .62, 15, 1, 12, .72),
        (4.5, 7.9, 1.4, .5, 12, 1, 12, .7),
        (-5.9, 4.0, .4, 1.15, 9, 12, 19, 1.45),
        (5.9, 1.7, .4, 1.35, 10, 12, 19, 1.45),
    ],
    6: [
        (-5.7, -3.4, .8, 1.45, 16, 109, 136, .93),
        (-5.7, .1, .8, 1.2, 14, 'maidenhair', 136, .72),
        (-5.7, 3.6, .8, 1.3, 15, 109, 136, .93),
        (5.7, -3.4, .8, 1.45, 16, 109, 136, .93),
        (5.7, .1, .8, 1.2, 14, 'maidenhair', 136, .72),
        (5.7, 3.6, .8, 1.3, 15, 109, 136, .93),
        (-2.8, 6.6, 1.0, .65, 13, 136, 145, 1.75),
        (-2.7, -6.6, 1.6, .65, 13, 136, 145, 1.7),
        (2.65, -6.6, 1.6, .65, 13, 136, 145, 1.7),
    ],
    7: [
        (-3.6, -7.9, 1.35, .55, 12, 16, 146, .90),
        (1.4, -6.6, .7, 1.45, 14, 16, 146, .86),
        (-4.1, -2.8, .65, 1.65, 13, 146, 'maidenhair', 1.4),
        (4.0, -2.2, .65, 1.55, 13, 146, 16, 1.35),
        (-2.4, 5.7, .7, 1.25, 14, 'maidenhair', 146, .70),
        (3.9, 5.6, .7, 1.5, 14, 16, 146, .86),
        (-7.2, -5.9, 1.5, 1.5, 15, 'maidenhair', 146, .76),
        (7.5, -6.3, 1.6, 1.65, 17, 16, 146, .96),
        (7.3, 6.4, 1.4, 1.1, 14, 146, 'maidenhair', 1.4),
    ],
    8: [
        (-5.9, -4.2, 1.55, 1.25, 15, 143, 144, 1.6),
        (4.9, -5.8, 1.55, 1.1, 15, 143, 144, 1.6),
        (-5.2, 1.2, 1.4, 1.5, 17, 143, 14, 1.55),
        (5.8, 1.75, 1.4, 1.55, 17, 144, 143, 1.5),
        (-7.6, 5.6, 1.5, 1.25, 15, 14, 143, .92),
        (7.5, -5.9, 1.2, 1.9, 15, 144, 143, 1.55),
        (-3.8, 7.3, 1.7, .75, 13, 143, 144, 1.55),
        (4.2, 6.35, .65, 1.0, 10, 144, 143, 1.5),
        (2.4, -8.75, 1.45, .45, 10, 143, 144, 1.55),
    ],
    9: [
        (-6.6, -3.5, .85, 1.45, 15, 137, 146, 1.6),
        (-6.5, .1, .72, 1.3, 13, 146, 137, 1.65),
        (5.55, -2.9, .75, 1.7, 16, 146, 137, 1.7),
        (5.9, 1.4, .85, 1.35, 14, 146, 137, 1.7),
        (-3.4, -5.6, 1.45, .7, 15, 'nightphlox', 146, .90),
        (1.4, -5.2, 1.1, .7, 13, 'nightphlox', 137, .90),
        (1.1, 5.1, .9, .58, 12, 'nightphlox', 146, .9),
        (-7.9, -7.5, 1.5, 1.1, 14, 146, 137, 1.8),
        (7.7, -6.9, 1.4, 1.3, 15, 146, 137, 1.8),
    ],
}

KINDS = ['wet', 'shade', 'dry', 'meadow', 'herb', 'herb', 'shade', 'wet', 'dry', 'silver']
BENCHES = [(6, 3), (-5, 7), (2, 6.5), (6, 5), (-6, 6),
           (5.5, -5.8), (0, -4.6), (-5, 5), (-2, -7), (3.8, 6)]
SIGNS = [(6.3, 8), (-8, 5.8), (9.1, 5.2), (-8, 5.5), (9.1, 5.6),
         (-8.5, 6.2), (7.8, 5.8), (-5.9, 7.4), (9.3, 5.9), (-8, 5.4)]


def reserved(index, x, z, radius=.25):
    """Keep new foliage out of paths, editable beds and functional furniture."""
    if max(abs(x), abs(z)) > 10.7:
        return True
    if area_cohesion.on_route(index, x, z, .94 + radius):
        return True
    if any(math.hypot(x - a, z - c) < 1.3 + radius for a, c in [BENCHES[index], SIGNS[index]]):
        return True
    if index == 0:
        return math.hypot((x + 1.4) / 4.25, z / 3.8) < 1.06 or (abs(x) < 7.6 and 3.98 < z < 6.25) or math.hypot(x - 5, z + 3) < 1.1
    if index == 1:
        creek = math.sin(z * .42) + .30 * math.sin(z * .83)
        return abs(x - creek) < .85 + radius or abs(x - creek - 1.55) < .66 + radius
    if index == 2:
        pots = [(-4.5, 6), (4.1, -6.8), (3.3, 1.5), (-4.4, -2.8)]
        return (abs(x - 6.5) < 1.0 + radius and -7 < z < 7) or any(math.hypot(x - a, z - c) < .9 + radius for a, c in pots) or (abs(x) < 6.4 and min(abs(z - row) for row in [-5, -.5, 4]) < .42 + radius) or (abs(x + 3) < 1.45 and min(abs(z - row) for row in [3.1, -1.4, -5.7]) < 1.0)
    if index == 3:
        return abs(x - 3 * math.sin(z * .4)) < .90 + radius or abs(z + 8) < .40
    if index == 4:
        return (abs(x) < 6.3 and abs(z) < 6.2) or abs(abs(x) - 8) < .30 or abs(z + 8) < .32 or math.hypot(x, z - 6) < 1.7
    if index == 5:
        return (abs(x) < 5.2 and abs(z) < 5.25) or abs(abs(x) - 7) < .5 or abs(z + 7) < .5 or (abs(z - 7) < .55 and abs(x) > 1.25) or (abs(x) < 1.9 and z > 5) or (abs(x) < 6.5 and -7 < z < -5.2) or any(math.hypot(x - a, z - 5) < .9 for a in [-6, 6])
    if index == 6:
        return abs(x) < 4.9 and abs(z) < 5.95
    if index == 7:
        creek = 1.5 * math.sin(z * .4)
        return abs(x - creek) < 1.12 + radius or (abs(z - 3) < .95 + radius and abs(x) < 3.9) or (abs(z + 3.3) < .65 and abs(x) < 2.7) or (abs(abs(x) - 3) < .62 + radius and -7.5 < z < .6)
    if index == 8:
        return abs(x - 2.4 * math.sin(z * .45)) < .85 + radius or math.hypot(x + 6, z + 5) < .75 or any(abs(x - a) < 1.5 and abs(z - c) < .55 for a, c in [(-4, -2), (2, -5), (4, 1)])
    return math.hypot(x + 1, z) < 3.6 + radius or (-6.1 < x < -3.3 and -4.8 < z < 1.4) or any(math.hypot(x - a, z - c) < .7 + radius for a, c in [(-5, 5), (5, 4), (4, -5)])


def install(b):
    previous_rock = b.rock

    def rock(G, parent, index, x, z, size, seed=0, moss=True):
        # Replace the regular alpine ring with embedded geological outcrops.
        # Functional windbreak stones retain their exact pivot and footprint.
        if index == 8 and parent.get('area_kind') == 'alpine':
            centers = [(-6.5, -4.7), (4.9, -6.3), (-5.5, 1.0), (6.4, 1.7),
                       (-7.3, 5.9), (7.6, -5.1), (-3.5, 6.1), (4.5, 5.6)]
            cx, cz = centers[seed // 4 % len(centers)]
            rng = random.Random(8074 + seed)
            angle = (seed % 4) * 2.4 + .4
            radius = [.0, .82, 1.35, 1.8][seed % 4]
            x, z = cx + math.cos(angle) * radius, cz + math.sin(angle) * radius
            scale = [1.05, .68, .47, .34][seed % 4] * rng.uniform(.9, 1.1)
            size = (1.8 * scale, .95 * scale, 1.5 * scale)
            moss = False
        return previous_rock(G, parent, index, x, z, size, seed, moss)

    b.rock = rock
    previous_borders = b.borders

    def borders(G, root, index):
        previous_borders(G, root, index)
        # Retain the moving canopy's existing trees; rebuild decorative low
        # plants as one designed layer rather than adding to the old scatter.
        for node in list(root.children_recursive):
            if node.get('area_species') is not None and node.get('area_species') != 'treefern':
                bpy.data.objects.remove(node, do_unlink=True)

        footprints = [tuple(node['footprint']) for node in root.children_recursive if node.get('footprint')]
        slots = b.layout()[index]['slots']
        occupied = []
        for node in root.children_recursive:
            if node.get('area_species') == 'treefern':
                occupied.append((node.location.x, -node.location.y, .4))
        dusk = next((node for node in root.children if node.name.startswith('DuskFlowers')), root)
        detail = b.pivot('Planted margin mineral detail', root, ground_detail=True)
        count = 0

        for group, (cx, cz, rx, rz, total, dominant, companion, scale) in enumerate(DRIFTS[index]):
            # These oval guides also inform the native ground shader. Empty
            # parent transforms let all anchors keep ordinary area coordinates.
            margin = b.pivot('Planted margin %02d' % group, root,
                             composition_bed=[cx, cz, rx, rz], composition_kind=KINDS[index])
            rng = random.Random(62103 + index * 1031 + group * 67)

            def clear(x, z, radius):
                if reserved(index, x, z, radius):
                    return False
                if any(((x - a) / (rw + radius)) ** 2 + ((z - c) / (rd + radius)) ** 2 < 1 for a, c, rw, rd in footprints):
                    return False
                if any(math.hypot(x - slot['pos'][0], z - slot['pos'][1]) < .85 + radius for slot in slots):
                    return False
                return not any(math.hypot(x - a, z - c) < radius + r for a, c, r in occupied)

            planted = 0
            for attempt in range(total * 18):
                if planted >= total:
                    break
                angle = rng.random() * math.tau
                spread = math.sqrt(rng.random())
                x, z = cx + math.cos(angle) * rx * spread, cz + math.sin(angle) * rz * spread
                species = companion if planted % 4 == 3 else dominant
                # Lower grass companions remain full enough to join the drift.
                size = scale * rng.uniform(.82, 1.16)
                if isinstance(species, int) and species >= 136 and species <= 147:
                    size = max(size, 1.3)
                radius = .16 if isinstance(species, int) and (136 <= species <= 147 or species in [12, 19, 124, 126]) else .24
                if not clear(x, z, radius):
                    continue
                parent = dusk if species == 'nightphlox' else margin
                node = b.pivot('BotanicalAnchor', parent, b.at(index, x, z),
                               area_species=species if isinstance(species, str) else '',
                               area_plant_id=-1 if isinstance(species, str) else species,
                               terrain_anchor=True, composed_planting=True)
                node.scale = (size, size, size)
                node.rotation_euler.z = rng.random() * math.tau
                occupied.append((x, z, radius))
                planted += 1
                count += 1

            # Low, partly buried scree makes dry planting sit in crevices. It
            # carries no extra walking obstacle and cannot cover a plant root.
            if index in [2, 8]:
                for k in range(12):
                    angle = rng.random() * math.tau
                    spread = math.sqrt(rng.random())
                    x, z = cx + math.cos(angle) * rx * spread, cz + math.sin(angle) * rz * spread
                    if not clear(x, z, .035):
                        continue
                    size = rng.uniform(.075, .17)
                    G.ell(detail, b.MATS['stone'], (x, b.height(index, x, z) + .038, z),
                          (size, size * .28, size * .74), group * 19 + k,
                          sectors=7, rings=4, rough=.18)
            margin['composition_count'] = planted
        root['composition_version'] = 1
        root['composed_plant_count'] = count

    b.borders = borders

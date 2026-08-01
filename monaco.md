# Monaco-Inspired Biking Game — Environment & Landmark Plan

Core idea: Monaco reads as "Monaco" through elevation and density, not sheer size — the whole principality is ~2 km² but climbs roughly 200m from harbor to the upper Corniche. If the map is flat, none of the landmarks below will save it. Treat terracing as content, not backdrop.

## 1. Route-anchoring landmarks (checkpoints / sightline anchors)

Loosely mapped to the real Grand Prix circuit shape — useful because it's already a proven "interesting loop" through this terrain:

- **Sainte-Dévote** — sharp right-hander at the base of the first climb. Natural start/finish or first-gate trigger.
- **Beau Rivage climb → Massenet** — steady uphill drag, good place for a stamina/gear mechanic to bite.
- **Casino Square (Place du Casino)** — open plaza, Belle Époque casino facade, palm-lined. Best mid-route scenic overlook, low elevation change so good for a breather.
- **Mirabeau / Fairmont Hairpin** — tightest corner in the game (real radius is ~10m), switchback overlooking the harbor. High-value photo-moment corner.
- **Portier** — fast right before the tunnel entrance.
- **Tunnel** (runs through the Fairmont building) — dark section, use for a lighting/audio transition (engine echo equivalent = wind/chain noise reverb for a bike).
- **Harbor-front straight** — flat, waterfront, superyachts as constant backdrop. Good high-speed recovery section.
- **Tabac corner**
- **Piscine (swimming pool) chicane** — modern chicane by Stade Louis II's pool, sharp direction changes.
- **La Rascasse → Anthony Noghès** — final corners back onto the straight.

## 2. Standalone landmarks (non-route, backdrop/vista value)

- **Prince's Palace (Palais Princier)** — on Le Rocher, elevated rock promontory. Best used as a distant silhouette visible from multiple climb sections, not something you route through.
- **Monaco Cathedral** — white stone, twin towers, adjacent to the palace on the Rock.
- **Oceanographic Museum** — cliff-face facade dropping straight to the sea; strong vertical landmark if visible from a lower coastal section.
- **Jardin Exotique** — terraced cliffside cactus/succulent garden. Great as a mid-distance textured hillside rather than a walkable set piece.
- **Port Hercules** — main harbor, superyachts, the big "wealth" visual.
- **Port de Fontvieille** — secondary, quieter harbor if you want route variety away from the main marina.
- **Stade Louis II** — modern stadium roof structure, useful as a hard modern-architecture contrast point.
- **Grimaldi Forum** — glass-facade convention center near Larvotto.
- **Larvotto Beach** — artificial beach, palm promenade, flat coastal stretch.

## 3. Architecture — building/house treatment

Three distinct facade languages, don't blend them into one generic "Mediterranean" style:

- **Belle Époque residential** (dominant along most of the route): cream/ochre/pale-pink stucco, wrought-iron Juliet balconies, green or navy shutters, mansard roofs with dormer windows, terracotta tile roofs.
- **Old Town / Le Rocher**: ochre stone, narrow lanes, arched doorways, tighter street width — use this to force a slower, twistier section if you want a gameplay pacing change.
- **Modern towers** (e.g. skyline pieces like Odéon Tower): glass curtain walls, used sparingly as skyline punctuation, not street-level filler — they should read as background silhouettes, not buildings you ride past closely.
- Street-level accents: striped café awnings (red/white or navy/white), wrought-iron lamp posts, small wall-mounted balcony planters.

## 4. Vegetation (Mediterranean flora — be specific, generic "palm tree" reads as Miami, not Monaco)

- **Washingtonia robusta** — tall, thin trunk, small crown. Primary avenue/street-lining palm.
- **Phoenix canariensis** (Canary palm) — fuller crown, used at plazas/focal points rather than continuous rows.
- **Pinus pinea** (umbrella pine) — flat-topped canopy, defines the hillside silhouette from a distance.
- **Bougainvillea** — magenta/orange, climbing over walls and balcony railings. Highest color-impact decoration for houses, use it deliberately rather than everywhere.
- **Agave / Aloe** — terraced garden accents, concentrate near Jardin Exotique-style hillside sections.
- **Cupressus sempervirens** (cypress) — vertical accent near villas, good for framing driveway/gate entrances.
- **Nerium oleander** — pink/white flowering hedge, good median/roadside planting.
- **Olive trees** — gray-green, gnarled, terraced groves on hillside sections away from the harbor.
- **Lavender / rosemary** — low border planting, cheap detail for terrace edges.
- **Citrus (lemon/orange)** — courtyard accents, not street-facing.

**Godot note:** don't place these as unique instances — a route this long with continuous avenue planting will wreck your draw calls. Bake 2–3 mesh variants per species and drive placement through `MultiMeshInstance3D` with randomized rotation/scale per instance. Same applies to lamp posts and any repeated barrier/railing geometry.

## 5. Street-level decoration & clutter

- Moored superyachts in the harbor — static is fine, a subtle bob animation sells it further. This is the single strongest "Monaco" visual cue, weight it accordingly.
- Parked luxury/sports cars curbside — visual shorthand, doesn't need to be interactive.
- Monaco flag (red/white bicolor) on poles and balconies.
- Café terraces — umbrellas, wicker chairs, clustered at plazas not scattered along the whole route.
- If you want racing flavor layered on top: Armco barriers and tire walls at hairpins, red/white painted curbing at corner apexes.
- Cobblestone texture in Old Town sections vs. smooth asphalt on the main route — use this as a tactile/audio cue for a road-surface-feel change, not just visual.

## 6. Terrain & elevation

Suggest terracing the landmass into 3–4 tiers connected by switchback climbs:

1. Harbor level (sea level, flat)
2. Casino Square / mid-town level
3. Upper Corniche level (~150–200m up)
4. Tunnel as a "flat relief" section cutting through the climb — gives players a breather between tiers without flattening the overall elevation profile.

This tiering also gives you natural LOD boundaries — lower tiers don't need to render full detail on upper-tier geometry and vice versa.

## 7. Godot implementation notes

- **Terrain**: heightmap-based (Terrain3D addon, or a manually sculpted mesh) rather than flat ground + CSG bumps — elevation is the core identity here, don't fake it with props.
- **Vegetation/repeated props**: `MultiMeshInstance3D`, as above. This is non-optional given avenue-length palm rows.
- **Buildings**: modular kit, 3–4 facade variants per architecture style with a texture atlas for color variation, rather than unique meshes per building. You have three style buckets (Belle Époque, Old Town stone, modern tower) — don't blend them into a fourth "compromise" style.
- **Harbor water**: shader-based water plane (Godot's ocean/water shader or a simple animated normal-map plane) — it's a constant backdrop across multiple route sections so it's worth the shader budget.
- **Lighting**: warm, fairly low sun angle (`DirectionalLight3D` + `WorldEnvironment`, ~5500K warm white) to sell the Mediterranean look; combine with SDFGI or baked GI specifically for the tunnel's dark→light transition, which is one of the most recognizable beats of the real circuit.
- **LOD**: elevated corners (Mirabeau-equivalent) give long sightlines down to the harbor — use billboards or low-poly LOD for distant skyline/harbor geometry so those vistas stay cheap.

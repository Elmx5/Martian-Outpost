#!/usr/bin/env python3
"""Descarga fotos REALES de la NASA Image and Video Library (images.nasa.gov) para los eventos del juego.

Guarda:
    assets/sprites/event_images/nasa/<id_evento>.jpg
    data/nasa_images.json   (credito, titulo y pagina de cada foto)

Uso (desde la raiz del proyecto):
    python tools/fetch_nasa_images.py            # solo las que faltan
    python tools/fetch_nasa_images.py --force    # vuelve a descargar todas
    python tools/fetch_nasa_images.py rover shield   # solo esos eventos

No necesita clave de API. Solo usa la libreria estandar de Python.
Despues abre el proyecto en Godot para que importe las imagenes.
"""
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMG_DIR = ROOT / "assets" / "sprites" / "event_images" / "nasa"
MANIFEST = ROOT / "data" / "nasa_images.json"
API = "https://images-api.nasa.gov"

# id de evento (igual que en events_data.gd) -> busqueda en la libreria de la NASA.
# solar_flare, reactor_risk y meteor_rain ya tienen foto propia en el juego (assets/sprites/event_images): no estan aqui.
QUERIES = {
    # tutorial (mensajes pregrabados)
    "build_farm": "Veggie plant growth chamber ISS",
    "build_panels": "Mars rover solar panels Opportunity",
    "build_water": "Water Recovery System space station ECLSS",
    "build_antenna": "Deep Space Network antenna dish",
    # expediciones
    "cave": "Mars cave skylight pit",
    "ice": "Phoenix Mars lander ice trench",
    "cliff": "Underground Martian Ice Deposit Exposed at Scarp",
    "old_base": "Viking 1 lander Mars surface",
    # granja y ciencia
    "new_crops": "chile peppers Plant Habitat space station",
    "greenhouse": "Mars greenhouse habitat concept",
    "rake": "astronaut harvesting lettuce space station Veggie",
    "protect_plants": "Advanced Plant Habitat radish ISS",
    "research_veg": "astronaut lettuce Veggie space station",
    "rad_plants": "radiation experiment plants space station",
    "water_fluids": "Urine Processor Assembly space station",
    # NASA en directo (con antena)
    "fission_power": "Fission Surface Power concept Moon Mars",
    "sat_ice": "Mars Reconnaissance Orbiter spacecraft",
    "sat_cave": "Mars lava tube skylight HiRISE",
    "panel_tip": "Mars InSight lander solar panels dust",
    "storm_warning": "Mars global dust storm 2018 Mars Reconnaissance Orbiter",
    "flare_warning": "coronal mass ejection SOHO STEREO",
    "report": "Deep Space Network antenna Goldstone",
    "more_oxygen": "MOXIE oxygen Mars Perseverance",
    # sucesos de la base
    "toxins": "Phoenix lander soil sample Mars",
    "water_dig": "Phoenix scoop icy soil Mars",
    "oxygen_leak": "International Space Station interior module",
    # alertas del dia
    "bright_sun": "Solar Dynamics Observatory Sun",
    "dust_storm": "Mars dust storm Opportunity darkening sky",
    "bad_harvest": "plants growing space station Veggie",
}


def get_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": "martial-outpost/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def https(url: str) -> str:
    url = url.replace("http://", "https://")
    return urllib.parse.quote(url, safe=":/%?=&~")


def pick_file(urls):
    """Prefiere ~medium (unos 1000 px), luego ~small, luego cualquier jpg."""
    jpgs = [u for u in urls if u.lower().endswith(".jpg")]
    for tag in ("~medium", "~small", "~large"):
        for u in jpgs:
            if tag in u:
                return u
    return jpgs[0] if jpgs else None


def find_photo(query: str):
    q = urllib.parse.urlencode({"q": query, "media_type": "image", "page_size": 10})
    items = get_json(f"{API}/search?{q}")["collection"]["items"]
    for it in items:
        data = it["data"][0]
        try:
            url = pick_file(get_json(https(it["href"])))
        except Exception:
            continue
        if not url:
            continue
        center = data.get("center", "")
        credit = "NASA" + (f"/{center}" if center else "")
        return url, {
            "credit": credit,
            "title": data.get("title", ""),
            "nasa_id": data.get("nasa_id", ""),
            "page": f"https://images.nasa.gov/details/{data.get('nasa_id', '')}",
        }
    return None, None


def main() -> None:
    args = sys.argv[1:]
    force = "--force" in args
    only = [a for a in args if not a.startswith("--")]
    ids = only or list(QUERIES)

    IMG_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {}
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    for eid in ids:
        if eid not in QUERIES:
            print(f"{eid}: no hay busqueda definida")
            continue
        dest = IMG_DIR / f"{eid}.jpg"
        if dest.exists() and not force and eid in manifest:
            print(f"{eid}: ya existe")
            continue
        try:
            url, info = find_photo(QUERIES[eid])
            if not url:
                print(f"{eid}: sin resultados para '{QUERIES[eid]}'")
                continue
            req = urllib.request.Request(https(url), headers={"User-Agent": "martial-outpost/1.0"})
            with urllib.request.urlopen(req, timeout=120) as r:
                dest.write_bytes(r.read())
            manifest[eid] = info
            print(f"{eid}: OK  {info['credit']}  {info['title'][:60]}")
        except Exception as ex:
            print(f"{eid}: FALLO ({ex})")

    MANIFEST.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n{len(manifest)} fotos en el manifiesto -> {MANIFEST}")


if __name__ == "__main__":
    main()

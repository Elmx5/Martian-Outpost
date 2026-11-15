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
# dust_devil, solar_flare, meteor_rain y reactor ya tienen foto propia en el juego: no estan aqui.
QUERIES = {
    "farm1": "Veggie plant growth chamber ISS",
    "farm2": "lettuce grown on space station Veggie",
    "farm3": "astronaut watering plants space station",
    "farm4": "Mars greenhouse habitat concept",
    "seeds": "Veggie plant pillows seeds",
    "for_science": "astronaut laboratory plant research",
    "science2": "radiation plant experiment space station",
    "water_production": "water recovery system space station",
    "send_report": "Deep Space Network antenna",
    "expedition1": "Mars lava tube cave",
    "expedition2": "Phoenix lander Mars ice trench",
    "expedition3": "Mars water ice exposed scarp",
    "expedition4": "Mars Desert Research Station habitat",
    "suit": "spacewalk spacesuit astronaut repair",
    "panels": "Mars rover solar panels dust cleaning",
    "rover": "Perseverance rover rock sample",
    "lack_of_oxygen": "MOXIE oxygen Mars Perseverance",
    "shield": "radiation shielding spacecraft habitat",
    "bright_sun": "Solar Dynamics Observatory Sun",
    "bad_harvest": "plants growing space station",
    "toxins": "Phoenix lander Mars soil sample",
    "oxygen_leak": "International Space Station interior module",
    "hard_ground": "Phoenix lander scoop icy soil",
    "quiet_sun": "Sun Solar Dynamics Observatory calm",
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

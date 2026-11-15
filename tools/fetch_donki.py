#!/usr/bin/env python3
"""Descarga llamaradas solares REALES de la base de datos DONKI de la NASA
y genera data/donki_flares.json, que el juego usa en lugar de la lista fija de nasa_facts.json.

Uso (desde la raiz del proyecto):
    python tools/fetch_donki.py
    NASA_API_KEY=tu_clave python tools/fetch_donki.py   # recomendado (gratis en https://api.nasa.gov)

Solo usa la libreria estandar de Python.
"""
import json
import os
import re
import urllib.parse
import urllib.request
from datetime import date, timedelta
from pathlib import Path

KEY = os.environ.get("NASA_API_KEY", "DEMO_KEY")
START = date(2024, 1, 1)
END = date.today()
CHUNK_DAYS = 120
TOP = 40  # cuantas llamaradas guardar (las mas fuertes)
OUT = Path(__file__).resolve().parent.parent / "data" / "donki_flares.json"

CLASS_RX = re.compile(r"^([ABCMX])(\d+(?:\.\d+)?)$")
RANK = {"A": 0, "B": 1, "C": 2, "M": 3, "X": 4}


def strength(cls: str) -> float:
    m = CLASS_RX.match(cls or "")
    if not m:
        return -1.0
    return RANK[m.group(1)] * 1000 + float(m.group(2))


def fetch(start: date, end: date):
    q = urllib.parse.urlencode({"startDate": start, "endDate": end, "api_key": KEY})
    url = f"https://api.nasa.gov/DONKI/FLR?{q}"
    req = urllib.request.Request(url, headers={"User-Agent": "martial-outpost/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r) or []


def main() -> None:
    found = {}
    cur = START
    while cur <= END:
        nxt = min(cur + timedelta(days=CHUNK_DAYS), END)
        try:
            for f in fetch(cur, nxt):
                cls = f.get("classType")
                when = (f.get("peakTime") or f.get("beginTime") or "")[:10]
                if cls and when and strength(cls) >= strength("M5.0"):
                    found[f["flrID"]] = {"date": when, "class": cls, "source": "donki"}
            print(f"{cur} -> {nxt}: ok")
        except Exception as ex:
            print(f"{cur} -> {nxt}: FALLO ({ex})")
        cur = nxt + timedelta(days=1)

    flares = sorted(found.values(), key=lambda f: strength(f["class"]), reverse=True)[:TOP]
    flares.sort(key=lambda f: f["date"])
    if not flares:
        print("No se obtuvo ninguna llamarada; no se escribe nada (el juego usa nasa_facts.json).")
        return
    OUT.write_text(json.dumps({"flares": flares}, indent=2), encoding="utf-8")
    print(f"{len(flares)} llamaradas guardadas en {OUT}")


if __name__ == "__main__":
    main()

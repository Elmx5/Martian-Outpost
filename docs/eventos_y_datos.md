# Eventos y datos de la NASA

Documentación de los eventos del juego (basados en `Tabla eventos de decisión.xlsx`), de los datos reales de la NASA que se muestran con cada uno y de las imágenes.

- Eventos: `scripts/events_data.gd` (función `_ready()`)
- Datos de la NASA y fuentes: `data/nasa_facts.json`
- Fotos de la NASA: `tools/fetch_nasa_images.py` → `assets/sprites/event_images/nasa/<id>.jpg` y `data/nasa_images.json`
- Llamaradas solares reales: `tools/fetch_donki.py` → `data/donki_flares.json`
- Balance (producción, gasto, dificultad): constantes al principio de `scenes/mainGame/game.gd`

## 1. Reglas que afectan a los eventos

**Edificios.** La producción de cada noche solo funciona si el edificio está construido: paneles solares (energía), granja (comida), planta de agua (agua) y antena (comunicaciones). Construir **cuesta recursos** y **solo da mejoras pasivas**: nunca da recursos al momento.

**Mensajes pregrabados y antena.** El día 1 los mensajes de la radio de la NASA son **pregrabados** (cabecera `NASA · PRE-RECORDED` y `● REC` en el monitor). Hasta que se construya la antena **no puede salir ningún evento de comunicaciones con la NASA** (solo los tutoriales de construcción). Con la antena la cabecera pasa a `NASA · LIVE` y se desbloquean los eventos de la sección 3.3. Si rechazas un tutorial de construcción ("Not now"), vuelve al día siguiente.

**Avisos de la NASA.** `storm_warning` y `flare_warning` predicen un desastre para **mañana** (siempre ocurre). Con la opción 1 ("Prepare" / "Shelter up") pagas un coste pequeño y al día siguiente el desastre llega, pero **no pierdes recursos**. Con "Ignore" llega con todo su efecto. El panel de arriba a la izquierda muestra `🛰️ Tomorrow: … (ready)` o `(NOT ready)`.

**Efectos con duración.** Una opción puede tener: efecto instantáneo; efecto que **llega dentro de N días** (`_later`); efecto **cada noche durante N noches** (`_mod`) o **permanente** (`_mod` con -1).

**Convención aplicada a la tabla del Excel.**

| Excel | Se implementa como |
|---|---|
| Instant | Se aplica al decidir |
| N days later / In N days | Todo el paquete llega después de N días (si la opción tiene prob. de éxito y falla, no llega nada) |
| Next N days | Efecto cada noche durante N noches |
| Permanent | Efecto cada noche, para siempre |
| Instant Permanent | Primera parte al decidir, segunda cada noche para siempre |
| Prob. éxito | Solo afecta a la opción 1. Si falla: pagas los costes, no recibes nada (más `FAIL_PENALTY` y `FAIL_EXTRA` en `game.gd`) |

**Suavizado.** `NEG_SCALE = 0.6` en `game.gd` multiplica los efectos **negativos instantáneos** de las opciones. Los costes que aparecen abajo son los valores del código antes de multiplicar. No afecta a los efectos por noche ni a los retrasados.

## 2. Balance de la base (por noche)

Con todo construido, la base ahora **pierde** recursos cada noche: hay que mejorarla con eventos para aguantar.

| Recurso | Producción | Gasto | Antes (neto) | Ahora (neto) |
|---|---|---|---|---|
| Energía | +8 paneles | -11 | +2 | **-3** |
| Comida | +6 granja | -9 | 0 | **-3** |
| Agua | +6 planta | -9 | 0 | **-3** |
| Radiación (mala si sube) | +12 espacio | -9 escudo | -1 | **+3** |

Mejoras pasivas de los eventos (también reducidas): invernadero +4 comida/noche, planta resistente a la radiación +2 comida, verduras resistentes +2 comida, fisión +8 energía, refugio en cueva -3 radiación.

## 3. Catálogo de eventos

Los costes/efectos están en el orden energía, comida, agua, radiación. "Éxito" = probabilidad de la opción 1.

### 3.1 Tutorial del día 1 (radio, mensajes pregrabados)

| id | Opción 1 (instantáneo) | Mejora pasiva que da | Opción 2 |
|---|---|---|---|
| `build_farm` | -15 energía, -10 agua | Granja: +6 comida/noche | Vuelve mañana |
| `build_panels` | -10 comida, -15 agua | Paneles: +8 energía/noche | Vuelve mañana |
| `build_water` | -10 energía, -15 comida | Planta de agua: +6 agua/noche | Vuelve mañana |
| `build_antenna` | -20 energía, -10 comida | Desbloquea los eventos de la NASA en directo | Vuelve mañana |
| `rake` (John Rake) | -10 energía | Arregla el rastrillo | -10 comida cada noche hasta repararlo (el problema vuelve cada día) |

### 3.2 Visitantes y sucesos de la base

| id | Quién | Opción 1 | Opción 2 | Éxito |
|---|---|---|---|---|
| `cave` | Anthony Clark | Llega en 1 día: +10 agua, +5 radiación | Nada | 80% |
| `ice` | Anthony Clark | Llega en 2 días: +20 agua, +10 radiación | Nada | 60% |
| `cliff` | Anthony Clark | Llega en 2 días: +20 energía, +30 agua, +15 radiación | Nada | 40% |
| `old_base` | Anthony Clark | +10 radiación ahora; +15 energía 1 noche | Nada | 80% |
| `new_crops` | John Rake | -5 energía; +6 comida 3 noches | -10 comida 2 noches | 70% |
| `greenhouse` | John Rake | -20 energía, -10 agua; +4 comida/noche para siempre | Nada | 70% |
| `protect_plants` | John Rake | -15 agua | -15 comida | |
| `research_veg` | Sandra Hawkins | -20 comida; +2 comida/noche para siempre | Nada | 65% |
| `rad_plants` | Sandra Hawkins | -10 energía; +2 comida/noche para siempre | -5 comida | 50% |
| `water_fluids` | Sandra Hawkins | -15 energía, +10 agua | +10 radiación | |
| `reactor_risk` | (aviso de la base) | -20 comida, +20 agua (lo arregla) | -15 energía; -10 energía/noche para siempre (el problema sigue abierto) | |
| `toxins` | (aviso de la base) | +15 agua (si falla: +20 radiación) | -20 agua | 30% |
| `water_dig` | (aviso de la base) | -10 energía, +20 agua (si falla solo pierdes la energía) | -20 energía, +10 agua | 65% |
| `meteor_rain` | (aviso de la base) | -20 agua | -20 energía | |
| `oxygen_leak` | (aviso de la base) | -10 energía, -5 agua | Fin de partida en 3 días si no lo arreglas | 90% |

### 3.3 NASA en directo (solo con la antena construida)

| id | Opción 1 | Opción 2 | Éxito |
|---|---|---|---|
| `fission_power` | -10 energía, -15 agua; +8 energía/noche para siempre | Nada | |
| `sat_ice` | -10 energía; llega en 2 días +25 agua (satélite encontró hielo) | Nada | 90% |
| `sat_cave` | -15 energía, -5 agua; -3 radiación/noche para siempre (túnel de lava como refugio) | Nada | 80% |
| `panel_tip` | -8 agua; +3 energía 3 noches (limpiar paneles). Requiere paneles | Nada | |
| `storm_warning` | -10 energía; **mañana la tormenta de polvo no te quita nada** | Mañana tormenta completa | |
| `flare_warning` | -10 energía; **mañana la llamarada no te sube la radiación** | Mañana llamarada completa | |
| `report` | -10 energía | Llega en 2 días: -20 energía | |
| `more_oxygen` | -15 agua | Llega en 2 días: -25 agua | |

### 3.4 Alertas del día (no hay que decidir)

| id | Efecto | Duración |
|---|---|---|
| `solar_flare` | La producción de radiación se duplica (x2). Usa una llamarada real de DONKI | 2 noches |
| `bright_sun` | +20 energía. Requiere paneles | 1 noche |
| `dust_storm` | No se produce energía ni comida | 1 noche |
| `bad_harvest` | No se produce comida | 1 noche |

## 4. Eventos del Excel que NO están o cambian

- **Probabilidad de éxito de los avisos** (`solar_flare` 0,8, `bright_sun`, tormenta, etc.): se ignora, porque en las alertas del día no hay nada que decidir.
- **"Antenna required"** en el informe periódico: ahora lo exige `report` y, además, **todos** los eventos de comunicaciones salvo los tutoriales.
- **Reactor (`reactor_risk`):** la fila del Excel mezcla tiempos con "/" ("Instant Permanent / Instant"). Se ha leído como: -20 comida ahora, -10 energía permanente (solo si eliges la opción 2) y +20 agua ahora.
- **Fisión (`fission_power`):** el Excel solo pone "Permanent" para "-10 agua, 20 energía". Se ha leído como coste de construcción único (-10 energía, -15 agua) más energía permanente.

## 5. Datos reales de la NASA por evento

Cada evento muestra en el monitor una línea `NASA DATA ▸` con el dato, y al pasar el ratón sale la fuente. Fuentes y textos exactos en `data/nasa_facts.json`.

| Evento(s) | Dato mostrado | Fuente |
|---|---|---|
| `build_farm`, `rake`, `protect_plants`, `research_veg`, `bad_harvest` | En 2015 los astronautas de la ISS comieron lechuga cultivada en la caja Veggie de la NASA (33 días) | CBS News, 2015 |
| `build_panels`, `panel_tip` | La sonda InSight terminó su misión en diciembre de 2022 porque el polvo cubrió sus paneles solares | Brown University / NASA, 2024 |
| `build_water`, `water_fluids` | En 2023 la ISS reciclaba el 98% del agua de la tripulación, incluidos orina y sudor | Comunicado de la NASA (20 jun 2023), vía Space.com |
| `build_antenna`, `report` | Un mensaje entre la Tierra y Marte tarda de unos 4 a 24 minutos | NASA, "Space Communications: 7 things to know" |
| `cave`, `greenhouse`, `sat_cave` | La roca gruesa de los túneles de lava podría proteger de radiación, rocas y temperaturas extremas | NASA Science, 2025 |
| `ice`, `water_dig` | Phoenix encontró hielo a unos 5 cm bajo el suelo y hielo duro como roca | NASA/JPL, 2008 · Science, 2009 |
| `cliff` | El orbitador MRO encontró acantilados con láminas de hielo de más de 100 m de grosor (2018) | NASA/JPL, 11 ene 2018 |
| `sat_ice` | Hay hielo poco profundo bajo cerca de un tercio de la superficie de Marte | NASA/JPL, 11 ene 2018 |
| `old_base` | Viking 1 aterrizó en 1976 y funcionó unos 6 años, muy por encima de los 90 días previstos | Universe Today (datos NASA) |
| `new_crops` | En 2021 los astronautas cultivaron chiles Hatch en la ISS por primera vez (unos 4 meses) | NASA, ficha Plant Habitat-04 |
| `rad_plants` | Curiosity midió unos 0,67 mSv diarios de radiación en Marte | Hassler et al., Science, 2013 |
| `reactor_risk`, `fission_power` | El reactor de prueba Kilopower funcionó 28 h a plena potencia; cuatro unidades podrían alimentar un puesto avanzado | NASA, 2018 |
| `toxins` | Phoenix encontró percloratos en el suelo de Marte | NASA/JPL, 2008 |
| `meteor_rain` | InSight estima de 280 a 360 impactos al año que dejan cráteres de más de 8 m | Brown University / NASA, 2024 |
| `oxygen_leak`, `more_oxygen` | MOXIE produjo 122 g de oxígeno en 16 pruebas en Marte | NASA, nota 2023-127 |
| `solar_flare` | Llamarada real al azar (fecha y clase) de la base de datos DONKI | DONKI / Space.com / NASA Solar Cycle 25 |
| `flare_warning` | Una tormenta solar tarda normalmente de 1 a 3 días en llegar a la Tierra | NASA vía UPI, 2013 |
| `storm_warning` | El orbitador MRO detectó la tormenta global de 2018 el 30 de mayo y la siguió desde órbita | Astronomy.com (datos NASA) |
| `dust_storm` | En 2018 una tormenta cubrió todo Marte y el rover Opportunity dejó de comunicarse el 10 de junio | NASA, vía Space.com |
| `bright_sun` | Opportunity generaba unos 700 Wh al día con sus paneles | NASA, vía Space.com, 2007 |

Los datos que ya no usa ningún evento (`meda`, `iss_dose`, `gcr_cycle`, `moxie`…) se conservan en el JSON como reserva.

**Nota sobre las fuentes.** Varios datos de la NASA están recogidos por medios (Space.com, UPI, Universe Today) que citan comunicados de la NASA. Si quieres dejar solo páginas de nasa.gov, cada URL se cambia en `sources` de `data/nasa_facts.json`.

## 6. Imágenes

El juego busca `assets/sprites/event_images/nasa/<id_evento>.jpg` para cada evento y, si existe, la muestra enmarcada en el bocadillo con su crédito (por ejemplo `NASA/JPL-Caltech`). Si un evento ya trae foto propia, esa tiene prioridad.

1. Desde la raíz del proyecto: `python tools/fetch_nasa_images.py` (sin clave de API; solo Python estándar).
2. Abre el proyecto en Godot para que importe las imágenes.
3. El script guarda título, crédito y página de cada foto en `data/nasa_images.json`.

Fotos propias que ya hay: `solar_flare` (`solar_flare_cabron.png`), `reactor_risk` (`Nuclear_reactor.jpg`) y `meteor_rain` (`mars_meteorite.png`).

Las búsquedas de cada evento están en `QUERIES` dentro de `tools/fetch_nasa_images.py`. Antes de publicar el juego conviene revisar las fotos descargadas y su crédito: el material de la NASA suele ser de uso libre, pero algunas imágenes de la biblioteca son de terceros.

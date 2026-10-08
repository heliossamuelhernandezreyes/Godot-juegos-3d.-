# FISURA — El Crisol

Prototipo 3D de **acción y extracción** para Godot 4.7.2, en revisión industrial/táctica 0.3. Proyecto independiente concebido como una prueba real de **ARCONT**.

## El bucle de juego

1. Entra al Crisol y busca **tres núcleos turquesa** distribuidos por el escenario.
2. Esquiva a los perseguidores, dispárales y usa el impulso para escapar.
3. Evita el pulso de daño que se activa **cada 12 segundos** en la zona central (el suelo rojo avisa).
4. Recoge los tres núcleos para abrir el portal situado al norte.
5. Cruza el portal antes de perder toda la salud. Puedes reiniciar para mejorar tu tiempo.

## Controles

| Plataforma | Mover | Disparar | Impulso |
|---|---|---|---|
| Teclado + ratón | WASD / flechas | Clic izquierdo: apuntado al cursor; Espacio: autoapuntar al enemigo próximo | Mayús |
| Android / pantalla táctil | Arrastrar dedo desde zona inferior izquierda | Mantener **DISPARAR** (autoapuntar al perseguidor más cercano) | Botón **IMPULSO** |

Clic/R y botón REINICIAR al terminar.

> **Importante:** La compatibilidad Android es un objetivo de diseño, **todavía no está validada en un APK ni en un teléfono físico**.

## Ejecutar

1. Descargar o clonar este repositorio.
2. Abrir la carpeta del proyecto en Godot **4.7.2-stable**.
3. Ejecutar **F6/F5** o la escena `scenes/main.tscn`. El proyecto incluye mallas originales y los modelos CC0 con texturas ya vendorizados; no requiere conectarse a Poly Haven.
4. Para una prueba automatizada: `godot --headless --path . --editor --import --quit` y luego `godot --headless --path . --quit-after 120`.

## Cómo utiliza ARCONT

La escena consume **`maps/crisol_01.json`**, un contrato semántico compatible con los conceptos de ARCONT Map Forge: `bounds`, `anchors`, `routes`, `regions` y `authoring`. Los spawns de jugador/enemigos, las ubicaciones de núcleos y el punto de extracción proceden de `anchors`. Las coberturas se construyen a partir de `authoring.structure_guides`.

La integración continua descarga una revisión **fijada** de `heliossamuelhernandezreyes/Arcont`, ejecuta **su validador real `tools/map_forge_contract.py`** y prueba Godot en modo headless. La metodología y los hallazgos de ARCONT se pueden reutilizar sin copiar su laboratorio al juego.

| Eje de prueba | Qué prueba FISURA v0.2 | Qué sigue sin demostrar |
|---|---|---|
| Diseño de niveles | Contrato semántico y materialización básica | Editor físico con Terrain3D/Cyclops/Scatter |
| Movimiento | Desplazamiento, impulsos, colisiones | Animación esquelética, salto y parkour |
| IA | Persecución y ataque por contacto | Navmesh real, evasión avanzada y flanqueos |
| Combate | Rifle hitscan, daño, muertes, barras de salud | Recoil, feedback, pooling y sonido |
| UX móvil | Joystick táctil elemental y botones | Ergonomía multi-resolución/60 FPS sostenidos |
| Pipeline | Validación ARCONT + smoke Godot | Exportación APK, playtest y perfil térmico |

## Principios

- **ARCONT permanece como banco de conocimiento y laboratorio.** Todo código de juego vive en este repositorio.
- Los assets provisionales son geometría y materiales nativos generados en runtime. No se da por hecho que el Asset Vault contenga binarios reutilizables.
- No confundir una importación limpia del editor con una prueba jugable, ni el FPS instantáneo con una medición de frame pacing.
- Esta versión es una **vertical slice gris**, no un juego AAA terminado. La prioridad es verificar el ciclo completo antes de ampliar arte, animaciones y sonido.

Revisa `fisura.manifest.json`, `.github/workflows/fisura-smoke.yml` y `LICENSE_ASSETS.md`.


## Versión artística 0.2

- **10 mallas 3D originales** Wavefront OBJ + materiales, con protagonista Vanguard articulado y rifle, enemigo Reaver, equipamiento de arquitectura y portón.
- **2 modelos PBR de Poly Haven CC0** importados en glTF 1K con texturas: barril industrial y lámpara mural industrial.
- **121 módulos de suelo instanciados**, mejoras de iluminación, cámara cercana y HUD de telemetría.
- Integración CI de ARCONT con validación del nivel, inspección de mallas OBJ y glTF, prueba de partida y **captura renderizada real** accesible en artefactos de GitHub Actions.
- Auditoría de calidad y limitaciones: [docs/ARCONT_EVALUATION.md](docs/ARCONT_EVALUATION.md). Las capturas son pruebas del renderer, no ilustraciones simuladas.
- Registro de licencias y hashes: [LICENSE_ASSETS.md](LICENSE_ASSETS.md).

**Estado de madurez:** vertical slice experimental, todavía muy lejos de la calidad AAA de un producto terminado. Pendientes: personajes riggeados/animación avanzada, audio, VFX, navegación de IA, materiales completos para arquitectura, exportación y perfilado Android.


## Actualización 0.3 — industrial, PBR, navegación y combate

- Escenario industrial ampliado mediante un generador visual determinista: pasarelas, grandes paredes, vigas, canales de refrigeración, conducciones, máquinas y señalización luminosa.
- **Tres materiales PBR 1K reales** seleccionados desde el catálogo CC0 de Arcont: hormigón de pared, suelo gastado y metal oxidado. Se incorporaron en `assets/vendor/polyhaven_materials/` con manifiestos de procedencia y SHA-256.
- **IA con visión directa y rutas alternativas** a través de `scripts/tactical_grid.gd`, usando obstáculos definidos por el mapa canónico; también se evita daño de contacto a través de paredes.
- Audiovisuales de combate: sonidos sintetizados de arma, impactos, impulso, salud y victoria; fogonazos al impacto y señalización de daño.
- La cámara mantiene la misma distancia tanto al comenzar como durante el seguimiento.
- Pruebas de navegación específicas en `tests/tactical_validation.gd`.

**[Auditoría técnica 0.3](docs/ARCONT_FIELD_REPORT_V03.md):** expone qué capacidades de ARCONT se han validado y qué falta para lograr estándares visuales o jugables cercanos a AAA. Aún no es un producto AAA y su rendimiento Android es desconocido.

## Actualización 0.4 — IA animada de verdad (Quaternius CC0)

- **QuadShell:** perseguidor de combate cercano, piel esquelética + animaciones Idle/Walk/Run/Attack/Hit. Utiliza navegación y colisiones desacopladas del mesh gracias al contrato ARCONT.
- **EyeDrone:** enemigo más veloz, modelo skinned con animaciones Idle/Charging/Attack/Hit; añade disparo de energía a distancia con línea de visión, tiempo de recarga y bloqueo por coberturas.
- **Arma del protagonista:** rifle 3D texturizado importado desde Quaternius.
- **Activos probados:** `tests/quaternius_import.gd` comprueba esqueletos, animaciones y geometría; `tests/animated_combat.gd` prueba Idle→Hit; `tests/ranged_drone.gd` comprueba ataque y cobertura.
- **Evidencia visual:** captura generada ejecutando el juego en Godot Linux bajo Xvfb, con ambos enemigos en el campo de visión (GitHub Actions).
- **Licencias y reproducibilidad:** archivos CC0 del paquete Standard de Quaternius con source SHA fijado y hashes SHA-256 en `assets/vendor/quaternius/scifi_essentials/PROVENANCE.json`, sin descargas durante el juego.

**Límite técnico:** aún no se han implementado animaciones esqueléticas humanoides completas para Vanguard, ni retargeting/IK, perfiles Android, VFX de alta fidelidad o escenarios de producción AAA.


## FISURA 0.5 — Vanguard humanoide, animación esquelética y cámara al hombro

- Vanguard usa **Spacesuit**, un personaje humanoide completo de Quaternius Ultimate Modular Men CC0, en lugar del torso y las extremidades OBJ segmentados.
- Su fuente contiene **1 Skeleton3D y 24 clips nativos**: Idle_Gun, Run/Run_Back/Run_Left/Run_Right, Run_Shoot, Gun_Shoot, Roll, HitRecieve, Death y otros. No se presupone retargeting automático: se usan sus propios clips.
- El cuerpo físico `CharacterBody3D` y sus estadísticas permanecen separados de `Skeleton3D` para no romper salud, impulsos ni colisiones. El arma PBR preexistente se monta en la mano derecha solo cuando encontramos un hueso compatible.
- La cámara ahora sigue al personaje **más cerca y con desplazamiento lateral**, con estrechamiento suave del campo visual al apuntar/disparar. Conserva el límite de seguridad dentro del escenario cerrado.
- `tests/vanguard_import.gd` inspecciona clip, huesos y Skeleton3D; `tests/vanguard_gameplay.gd` exige transiciones Idle→Run→Run_Shoot→Roll→HitRecieve→Death y que la cámara quede cerca.
- Los recursos y la licencia tienen hashes SHA-256 y origen fijado a `agentkaerf/FreeModels@db3df04d1e4714298a09510b26fb6de6645138a2`. Ver `assets/vendor/quaternius/vanguard_spacesuit/PROVENANCE.json`.
- Como antes, cada CI genera **una captura real de Godot**. Android no está probado.

**No se afirma animación AAA:** son clips CC0 funcionales con transiciones sencillas, sin retargeting humanoide avanzado, IK de pies/manos, motion matching, cámara libre ni animaciones contextuales de cobertura.

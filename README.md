# FISURA — El Crisol

Prototipo 3D de **acción y extracción** para Godot 4.7.2. Proyecto independiente concebido como una prueba real de **ARCONT**.

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
3. Ejecutar **F6/F5** o la escena `scenes/main.tscn`. No hay dependencias de assets ni plugins privados.
4. Para una prueba automatizada: `godot --headless --path . --editor --import --quit` y luego `godot --headless --path . --quit-after 120`.

## Cómo utiliza ARCONT

La escena consume **`maps/crisol_01.json`**, un contrato semántico compatible con los conceptos de ARCONT Map Forge: `bounds`, `anchors`, `routes`, `regions` y `authoring`. Los spawns de jugador/enemigos, las ubicaciones de núcleos y el punto de extracción proceden de `anchors`. Las coberturas se construyen a partir de `authoring.structure_guides`.

La integración continua descarga una revisión **fijada** de `heliossamuelhernandezreyes/Arcont`, ejecuta **su validador real `tools/map_forge_contract.py`** y prueba Godot en modo headless. La metodología y los hallazgos de ARCONT se pueden reutilizar sin copiar su laboratorio al juego.

| Eje de prueba | Qué prueba FISURA v0.1 | Qué sigue sin demostrar |
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

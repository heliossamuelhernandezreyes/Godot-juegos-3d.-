# FISURA — Auditoría aplicada con estándares ARCONT

**Fecha:** 2026-10-07 (Monterrey) · **Juego:** FISURA v0.2 · **Motor:** Godot 4.7.2-stable · **Fuente:** `heliossamuelhernandezreyes/Arcont`

## Veredicto

FISURA 0.1 era un *greybox* funcional: sistema de extracción, tres objetivos, disparos hitscan, dash y enemigos de persecución sencilla. **No era una experiencia visual ni jugable AAA**. La revisión 0.2 introduce geometría 3D authored en .obj, articulación ligera de la armadura, modularidad con MultiMesh, luces, encuadre más cercano, HUD y assets PBR importados de fuente CC0. La mejora visual no implica madurez AAA; faltan animación profesional, soundscape, navegación sobre coberturas, geometría de entorno compleja, VFX y QA real en móvil.

## Fuentes canónicas ARCONT utilizadas

| Disciplina | Documento o utilidad de ARCONT | Aplicación concreta |
|---|---|---|
| Semántica del nivel | `docs/knowledge/MAP_FORGE_STANDARD.md` + `tools/map_forge_contract.py` | Spawns, objetivos, zonas y estructuras desde `maps/crisol_01.json`, validados en CI |
| Geometría e instancing | `docs/knowledge/GRAPHICS_ASSET_FOUNDATIONS.md` | Malla OBJ independiente del gameplay y suelo repetido por MultiMesh |
| Integridad de licencias | `docs/knowledge/ASSET_LICENSE_POLICY.md` | Kit original separado de los modelos Poly Haven CC0 con manifest, hash y URL |
| Animación | `docs/knowledge/PROCEDURAL_ANIMATION.md` | Jerarquía separada de pivotes de extremidades en Vanguard; sin pretender equivalencia con retargeting skeletal |
| Navegación | `docs/knowledge/AI_NAVIGATION.md` | Se detectó ausencia de navmesh + local steering: la IA actual intenta seguir al jugador directamente |
| Calidad Android | `docs/knowledge/MOBILE_PERFORMANCE_FOUNDATIONS.md` | Restricción conservadora de luces, necesidad de muestrear p50/p95/p99 y ensayo térmico sostenido |

## Matriz de evaluación: evidencia vs supuestos

| Componente | 0.1 | 0.2 | Evidencia / límite |
|---|---|---|---|
| Núcleo jugable | Completo en tests automatizados | Conservado | `tests/playthrough.gd` ejecuta recolección, salud y victoria |
| Map contract | Configuración JSON y validador ARCONT | Conservado | CI invoca el validador real de ARCONT, con SHA fijado |
| Visuales personaje | Cápsula | 4 mallas OBJ y jerarquía de brazos/piernas | Importación verificada; no existe motion capture ni retargeting |
| Enemigo | Cápsula | Malla Reaver con oscilación sutil | No se ha certificado navmesh, flanqueos, estados tácticos o animaciones profesionales |
| Escenario | Plano gris + cubos | Módulos, pilares, crates, arquitectura y pórtico | Captura Godot real vía Xvfb; aún no hay nivel AAA |
| Iluminación | Luz única sin sombra | Sombra direccional + luces de acento, encuadre ajustado | Render real comprobable; coste térmico Android desconocido |
| Texturas 3D | Colores planos | Materiales OBJ y modelos glTF PBR de Poly Haven | Sus binarias deben pasar auditoría de importación y licencia |
| Optimización | Sin perfil | Instancing 121 módulos de piso | No inferir FPS por recuento de vértices/instancias |
| Sonido | Ausente | Ausente | Bloqueador de sensación de impacto |
| Construcción Android | No probada | No probada | Se requiere export APK, pruebas touch, térmicas, p95/p99 y reporte de memoria |

## Hallazgos críticos y acciones

1. **Inmersión / cámara:** el primer render mostraba todo el mundo muy pequeño, con gran espacio vacío. Ajustada cámara de 55º a 49º y seguimiento cercano, con captura repetible como evidencia.
2. **Legibilidad / interfaz:** las etiquetas invadían la arena. Incorporado HUD táctico de panel oscuro y barra de vida; falta revisar escalado en móviles.
3. **Arte:** los assets importados correctamente no garantizan silueta ni estética AAA. El kit custom OBJ es blocky como referencia técnica; necesario avanzar a modelos PBR, animación skeletal, efectos y diseño deliberado de arquitectura.
4. **IA sin navegación:** los enemigos atraviesan un algoritmo de persecución vectorial y se bloquean con obstáculos. Requiere navegación, steering local, estados de combate y tests de no-atasco.
5. **Balance:** tres núcleos cerca de enemigos y zona de pulso. Requiere playtests reales, tiempo medio de ronda, métricas de supervivencia y accesibilidad.
6. **Rendimiento:** hay sombras, varios emisores y assets glTF; no se conoce rendimiento de ningún teléfono. Perfil con métricas distribucionales, no promesas de 60/120 FPS.
7. **Licencias:** registros Poly Haven CC0 verificados en ARCONT; glTF 1K adquirido desde su API oficial con manifiesto y sha256 por componente. La compatibilidad debe verificarse con el motor antes de promocionar cada asset.

## Puertas de salida, no marketing

- **Gate A:** contrato y scripts válidos + CI verde (automático).
- **Gate B:** screenshot real desde Godot (automático, cualitativo pendiente).
- **Gate C:** partida jugada con movimientos, daños, IA y balance creíbles (manual).
- **Gate D:** Godot Android export con teclado/touch, sin caídas de frames críticas y sin errores GPU (dispositivo físico).
- **Gate E:** validación visual, audio y arte con referencias detalladas y comparativas antes/después.

**Interpretación ARCONT:** FISURA es una prueba positiva de *integración documental/contrato + herramientas de test*, pero **no** demuestra aún que ARCONT automatice producción AAA, seleccione assets por sí solo o dirija y utilice todas las herramientas visuales de Godot.

## Arte y procedencia

- `assets/models/`: modelos OBJ originales elaborados para FISURA, usados como bloques modulares sin recursos descargados.
- `assets/vendor/polyhaven/`: material PBR de proveedor externo, con `PROVENANCE.json` por asset, licencia CC0 y hashes de contenido.
- La URL del activo original y versión de file list se conservan en el manifest. No se infiere redistribución de ningún recurso que no haya sido clasificado.


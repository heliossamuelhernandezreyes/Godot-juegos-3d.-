# FISURA 0.7 — Reactivo-13, implementación y evidencia

**Estado:** prototipo jugable en Godot (Linux CI), pendiente prueba humana y Android físico.  
**Fecha:** 2026-10-08 · **Motor:** Godot 4.7.2-stable.  
**Contrato ARCONT:** `e10c51bc00bce8f5856d84b90ddee5696d0ca35f`. No se introdujo juego ejecutable en Arcont.

## Código y escenas que sí existen

- La escena de inicio de Godot apunta a **`scenes/reactivo_13.tscn`**. La escena anterior `scenes/main.tscn` permanece para tests de regresión y comparación.
- `maps/reactivo_13.json`: arena independiente 84×66 con rutas laterales, 7 cubiertas, 9 piezas de geometría estática, objetivos y zonas semánticas. El arte conserva modelos/PBR de procedencia ya verificada.
- `scripts/reactivo_mission_director.gd`: director de cinco fases, objetivos obligatorios y transiciones con señales, idempotencia de interacción, contención de saltos, defensa durante 75 s y terminales de éxito/fallo.
- `scripts/reactivo_13_game.gd`: juego de disparos reutilizando cuerpo/rig de Vanguard, sonidos, IA táctica A*, QuadShell y EyeDrone. Consolas A/B, núcleo, compuerta, estabilizador, plataforma de salida y HUD de fase y progreso. Teclado `E` o interacción táctil sostenida.
- `scripts/reactivo_bulwark.gd`: tercer rol con armadura frontal y daño total por flanco. **Malla geométrica provisional**, sin animación esquelética de producción. No describir como enemigo AAA terminado.
- `tests/reactivo_playthrough.gd`: ejecuta una extracción completa automática, obligando a activar B→A, verificar cierre/apertura de puerta, sostener núcleo y extracción, esperar 75 s lógicos sin adelantar la fase.
- `tests/reactivo_navigation.gd`: verifica la alcanzabilidad **estática** de cinco rutas de misión y rechaza celdas sólidas. No prueba seguimiento humano ni multitudes.
- `tests/reactivo_bulwark.gd`: valida el coeficiente de armadura frontal, el daño por la espalda y que el combate no modifique el estado de misión.
- `tests/capture_reactivo.gd`: genera un PNG auténtico de Godot bajo Xvfb en Linux, separado de renders del Crisol antiguo.

## Descubrimientos / mejoras reutilizables de ARCONT

1. El **validador de misión** `tools/vertical_slice_contract.py`, incorporado previamente en Arcont, detecta integridad referencial del GDD, pero no compara ese GDD con las anclas del mapa.
2. El nuevo puente agnóstico de motor `tools/mission_map_bridge.py` compara ambos documentos, rechaza divergencia de coordenadas, dimensiones o equipo de spawn y se ejecuta por SHA fijado desde FISURA.
3. **CI verde no implica calidad de encuadre.** La primera captura real mostró Vanguard pequeño, una tubería atravesando la composición y puerta sin tratamiento. Se ajustó cámara y lectura visual, pero la escena sigue siendo un prototipo visual.
4. Una prueba headless que teletransporta al jugador y acelera un temporizador demuestra que la FSM acepta una solución, **no** demuestra duración natural de 8–12 minutos ni balance, ergonomía o supervivencia justa.
5. Los contratos pueden definir `telegraph_seconds` pero la implementación actual de encuentros genera actores inmediatamente al entrar a la fase. La **telegrafía temporal, orden de oleadas y persistencia del ritmo del encuentro** siguen pendientes.
6. La compuerta impide avanzar por el corredor central hasta activar A/B, pero la geometría todavía ofrece rodeos a través de la arena. El director prohíbe adelantar objetivos; una puerta físicamente hermética requiere rediseño del layout y una nueva prueba con colisión real.
7. Exportar un APK solo certifica empaquetado, no FPS, temperatura, legibilidad de HUD ni tacto de dos dedos sobre Android físico.

## Estado por puertas de calidad

| Gate | Estado técnico | Razón |
|---|---|---|
| G0 — contrato | Verificado por CI | Arcont Mission Contract + Map Forge + puente de anclas |
| G1 — ruta estática | Verificado por CI | Godot AStarGrid2D, 5 recorridos |
| G2 — ciclo jugable | Verificado automatizado | Partida determinista de cinco fases sin saltos |
| G3 — combate | En progreso | Quad/Eye + Bulwark mecánico; sin telegrafía y balance humano |
| G4 — audiovisual | En progreso | Render real disponible; requiere pulido visual y crítica de encuadre |
| G5 — Android físico | Pendiente | Se puede compilar APK, falta instalar/medir |
| G6 — experiencia | Pendiente | Mínimo 3 playtests, tiempo natural, claridad de objetivos y sensación de disparo |

**No se afirma nivel AAA.** Tampoco se afirma interacción real sin el usuario jugando en su hardware. El siguiente sprint debe introducir ataques avisados, cierre físico del reactor, animación Bulwark, iluminación/VFX y telemetría física Android.

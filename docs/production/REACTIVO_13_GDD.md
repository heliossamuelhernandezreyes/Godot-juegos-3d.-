# FISURA 0.7 — Documento de diseño de juego (GDD)
## Operación REACTIVO-13 · vertical slice, revisión de diseño 1.0

**Estado:** diseño aprobado para prototipado técnico; **no implementado aún**.  
**Fecha:** 2026-10-07 · **Motor previsto:** Godot 4.7.2 · **Criterios técnicos:** ARCONT.  
**Duración objetivo:** 8–12 minutos para un jugador que ya conoce los controles.  
**Plataformas objetivo:** PC y Android ARM64; toda cifra de FPS es un **objetivo a medir**, no un rendimiento demostrado.

> **Límite importante:** FISURA 0.6 es una arena de 44 × 44, con 3 núcleos recogibles y extracción al norte. REACTIVO-13 es una nueva misión propuesta; no confundir este GDD ni su contrato JSON con una misión ya jugable. El código anterior y sus pruebas deben mantenerse hasta que un vertical slice nuevo supere pruebas propias.

### 1. Premisa y experiencia del jugador

Vanguard ingresa en una refinería industrial de contención fracturada para recuperar el **Núcleo Reactivo-13** antes de que el sello de emergencia destruya el recinto. La tensión cambia de *exploración controlada* a *asalto táctico* y finalmente a *extracción bajo presión*. El protagonista debe poder disparar mientras corre, usar esquivas/rodadas, leer coberturas y decidir qué amenaza eliminar primero.

**Tres pilares:** (1) movilidad precisa y rápida, (2) enemigos de roles distinguibles y con ataques anunciados, (3) legibilidad visual del objetivo incluso en pantalla móvil. No introducir árbol de progresión, inventario, mundo abierto ni contenido online en 0.7.

### 2. Bucle y reglas fundamentales

**Bucle primario:** leer indicio → escoger aproximación/cobertura → desplazar y combatir → activar objetivo → reaccionar a nueva amenaza.  
**Victoria:** ambos nodos energizados, núcleo recuperado, defensa superada, y el jugador realiza una interacción de extracción en el pórtico.  
**Derrota:** salud de Vanguard llega a cero o termina la cuenta atrás de evacuación después de activar el núcleo (tiempo por ajustar en playtest). El jugador puede reiniciar la misión.  
**Objetivos rastreables:** cada interacción tiene identificador, señal visual y textual, estado [pendiente, disponible, completo], y lógica de desbloqueo reproducible.

La salud, el dash, el disparo hitscan, el personaje con animaciones Quaternius, los dos tipos de enemigos actuales y los controles táctiles se **reutilizan**, sujeto a regresión. El pulso actual del Crisol puede reutilizarse como una mecánica de riesgo del reactor, pero **no** debe dañar arbitrariamente durante la inserción.

### 3. Guion jugable por fases

| Fase | Minutos de referencia | Objetivo y detonador de salida | Combate / enseñanza | Momento audiovisual |
|---|---:|---|---|---|
| **01 — Inserción** | 0:00–1:15 | Alcanzar el taller de acceso | 2 QuadShell; probar movimiento, disparo y dash | Ambiente frío, ventiladores, luces cian |
| **02 — Penetración** | 1:15–3:45 | Activar Nodo A y Nodo B (en cualquier orden) y abrir compuerta | QuadShell a ras de suelo, EyeDrone en flanco descubierto; cobertura media y rutas laterales | Consolas ámbar pasan a cian; portón abierto |
| **03 — Cámara del núcleo** | 3:45–5:00 | Interactuar con el núcleo en el pedestal; iniciar sellado | Encuentro corto de guardianes, no oleada interminable | Cambio de iluminación, alarma escalonada, pantalla "EXTRACCIÓN" |
| **04 — Defensa** | 5:00–7:30 | Defender estabilizador durante **75 s de objetivo**; eliminar enemigos restantes y desbloquear salida | 1 Bulwark blindado + 2 QuadShell + 2 EyeDrone, con entradas escalonadas y límite de simultáneos | Reactor naranja/rojo, sonido de pulso que anuncia peligro |
| **05 — Extracción** | 7:30–10:30 | Llegar a la plataforma y **mantener interacción 2 s** | 1–3 perseguidores según estado; no oleadas que impidan terminar | Luces verdes, portón final, pantalla de resultados |

Estos tiempos son **presupuestos de diseño**, no tiempos medidos. Objetivo total 8–12 minutos; margen de exploración y errores previsto. Si el balance se aleja, ajustar primero spawns/recorridos y solo después salud o daño.

### 4. Mapa: planta de contención 84 × 66 unidades (propuesta)

La nueva escena se llamará **reactivo_13**; no sobrescribir `maps/crisol_01.json` ni las pruebas de 0.6 hasta validar la nueva. El mundo tiene origen central (x,z), y=0 para suelos. El trayecto describe **un anillo alrededor del reactor**, con dos accesos laterales, puntos de referencia altos y extracción por una ruta visible, no un laberinto.

```text
                              NORTE (z negativo)
                     ┌──────── EXTRACCIÓN ────────┐
                     │       plataforma           │
     ┌── NODO A ─────┤   CÁMARA DEL REACTOR       ├───── NODO B ──┐
     │ consola cian  │    altar central / defensa │ consola ámbar │
     │ cobertura     │    pasarelas no invasivas  │ flanqueo      │
     └──────┬────────┴──────────┬─────────────────┴────────┬─────┘
            └──────── TALLER / ACCESO Y PORTÓN ────────────┘
                             INSERCIÓN
                               SUR
```

**Zonas contractuales:** inserción al sur, taller de acceso entre sur y centro, Nodo A al oeste, Nodo B al este, cámara del reactor en el centro-norte, ruta y plataforma de extracción al norte. La propuesta JSON usa zonas rectangulares para validación semántica, no asegura todavía geometría Godot ni navegación real.

**Métricas iniciales de diseño (a validar jugando):** 2 rutas por nodo, 3–5 coberturas útiles por enfrentamiento, ancho libre preferido ≥ 3 unidades en rutas principales, puntos de reaparición fuera de visión inmediata a distancia ≥ 7 unidades, y línea visual hasta una señal clara del próximo objetivo. Al menos una posición de flanqueo al Bulwark; no colocar coberturas decorativas sobre rutas de paso.

**Propuesta de alturas:** suelo principal único para 0.7-A; pasarelas elevadas visuales sin acceso hasta demostrar navegación y vaulting vertical. No fingir verticalidad jugable que el prototipo aún no soporta.

### 5. Sistemas y contrato de estados

La misión debe tener un **director de fases** desacoplado de UI y geometría. Fuente de verdad: `missions/reactivo_13.slice.json` (referencias, dependencias, encuentros). Los disparadores se convierten en eventos explícitos:
- `zone_enter`, `interact`, `encounter_cleared`, `timer_complete`, `objective_completed`, `mission_fail`, `mission_win`;
- secuencia prevista: `insertion → penetration → core_chamber → defense → extraction → victory`; la muerte conduce a `failed`;
- activar un nodo es idempotente (no da recompensa doble); dos nodos completados desbloquean compuerta;
- coger el núcleo no puede preceder a abrir la compuerta; defensa no comienza dos veces; extracción no se puede activar antes de la defensa;
- guardar eventos y tiempos de cada fase para reproducción y diagnóstico.

**Persistencia 0.7:** partida de sesión y reinicio completo, sin guardados intermedios ni red.

### 6. Diseño de enemigos y encuentros

| Rol | Patrón deseado | Contrajuego obligatorio | Estado actual |
|---|---|---|---|
| **QuadShell / Asaltante** | Persecución cercana, entrada por pasillos, anticipación breve del golpe | Dash lateral, obstáculo, disparo sostenido | Existe; mejorar animación/rutas |
| **EyeDrone / Hostigador** | Mantiene distancia, daño lineal anunciado, alterna dos puntos de ataque | Cubrirse, priorizar, romper línea de visión | Existe; aumentar legibilidad y decisión de reposición |
| **Bulwark / Guardián** | Frente blindado, avance lento, golpe de presión en defensa del estabilizador | Flanquear o atacar punto débil tras telegrafía | **Nuevo, no implementado** |

Para el Bulwark, el daño frontal reducido es un **modificador de zona de impacto**, no invulnerabilidad absoluta. Evitar choques de física excesivos con otros enemigos. Añadir asset propio/proveniencia de licencia antes de integrar. Se prefiere una primera versión con collider y malla temporal al bloqueo de la misión.

**Composición objetivo del clímax:** 1 Bulwark + 2 QuadShell + 2 EyeDrone, aparición escalonada, al menos un segundo de aviso visible por grupo. **Tope de diseño:** 8 hostiles simultáneos; si se excede, no generar nuevos. Ajustar ese límite mediante pruebas de Android, nunca extrapolar FPS desde Linux CI.

**Reglas de justicia:** no infligir daño a través de cobertura opaca; sin spawn dentro de colisionadores; indicador visible de proyectil/ataque; al menos una ruta física hacia el objetivo sin atravesar un enemigo imposible de evitar.

### 7. Vanguard: sensación y accesibilidad

Preservar locomoción y animaciones nativas de 0.6, movimiento lateral, ataque mientras corre y evasión. Priorizar transiciones de cámara/torso, hit confirmation, dirección del disparo y manejo del input por sobre motion matching. Las opciones de movilidad y cobertura de estilo más avanzado son **candidatas posteriores** cuando existan pruebas de clip, colisión y disponibilidad de obstáculos.

**HUD mínimo:** fase y próximo objetivo, vida, retícula, indicador de dash listo/en recarga, núcleos/nodos, temporizador solo cuando aplica, salida marcada; feedback de daño de origen claro. En Android, permitir múltiples dedos, botones no solapados y escalado a diversas relaciones de aspecto. Evitar retícula coincidiendo con botones; mostrar tutorial contextual de máximo una línea por acción al primer uso.

**Calidad de respuesta:** evitar "parada completa" al disparar; permitir apuntar en movimiento; cámara debe evitar paredes sin saltos de encuadre bruscos. Los criterios de feel exigen observación manual, nunca se dan por aprobados con CI.

### 8. Dirección artística y sonido

**Identidad:** catedral industrial dañada por energía inestable, aleaciones envejecidas, cables y refrigeración visible, reactor flotante como hito espacial. Cian = tecnología utilizable; ámbar = máquinas y advertencias; rojo = sellado/alarma; verde = extracción abierta. El color no debe ser la única señal.

**Tres vistas de referencia para revisión:** (1) inserción con silueta heroica de Vanguard, (2) nodo A con EyeDrone visible y cobertura legible, (3) defensa con Bulwark y reactor encendido. Capturas reales Godot a 1280×720, misma cámara y posición registrada; etiquetar como *render in-engine*, no como concepto.

**VFX:** destello de boca/impactos, señales de alarma no invasivas, humo moderado y partículas presupuestadas; **audio:** motor, ambiente, disparos, estados de nodo, alarma y llegada del Bulwark. Reutilizar SFX sintetizados temporales; registrar origen de sonidos comerciales antes de importar.

**Rendimiento:** luces limitadas, instancias compartidas, materiales trazados con hash/licencia, sombras seleccionadas. El hecho de que un asset sea CC0 o se importe sin error no implica coste aceptable.

### 9. Criterios de aceptación y método de prueba

| Gate | Qué exige | Evidencia requerida | Estado inicial |
|---|---|---|---|
| **G0 Contrato** | IDs únicos, fases alcanzables, referencias correctas, límites de encuentros | Validador de misión ARCONT + prueba negativa | Pendiente hasta crear la herramienta |
| **G1 Mapa** | Rutas válidas, objetivo A/B accesible, altura/cobertura sin bloqueos | Validator Map Forge + test Godot de navegación | Pendiente de crear mapa 0.7 |
| **G2 Secuencia** | No saltar fases; fallos, reintentos e interacción correctos | Playthrough headless con reloj controlado | Pendiente |
| **G3 Combate** | 3 roles distinguibles, ataques anunciados, sin daño a través de cobertura | Test de IA + vídeo de sesión | Pendiente (Bulwark nuevo) |
| **G4 Arte/UI** | Cámara libre de obstrucciones, objetivos visibles, HUD a distintas resoluciones | 3 capturas auténticas + auditoría visual | Pendiente |
| **G5 Android** | Instala, corre, controles simultáneos; p50/p95/p99 de frame pacing en sesión prolongada | APK + informe dispositivo 15 min | **No probado** |
| **G6 Experiencia** | Objetivo entendido por jugadores y duración real dentro de rango | 3–5 playtests con observaciones | Pendiente |

**Objetivos orientativos de rendimiento** para decidir arquitectura: intentar 60 FPS estables a 720p en un Android objetivo; registrar 30 FPS como fallback de diseño si el rendimiento exige demasiada reducción visual. No presentar 60/120 FPS como hechos medidos.

### 10. Backlog priorizado (no promesas)

**P0 — Construir una misión verificable:** contrato ARCONT reutilizable; director FSM; gates para nodos A/B; mapa compacto de 0.7 y navegación básica; victoria/derrota; tests de ciclo.  
**P1 — Darle calidad al combate:** Bulwark temporal, spawns dirigidos por fase, telegrafía y cobertura; HUD de objetivos; audio diferenciado y mejoras de cámara.  
**P2 — Arte de producción:** reactor protagonista, assets PBR adicionales, iluminación y sonido, QA visual; optimizar antes de subir geometría.  
**P3 — QA móvil:** APK del nuevo mapa, prueba táctil física, métricas térmicas y ajustes.  
**Fuera de alcance:** multijugador, generación automática irrestricta del mapa, cinemáticas largas, sistema de progresión persistente y marketing como AAA terminado.

### 11. Dependencias que Arcont debe demostrar

ARCONT debe proveer o permitir validar un contrato reusable de misión, integridad de dependencias, mapa, encounters y evidencias; sus guías de navegación/animación/activos deben orientar decisiones técnicas, pero **el código de juego vive en este repositorio**. Toda carencia se registra como hallazgo comprobable en `docs/production/ARCONT_GAP_AUDIT_07.md` con prioridad y criterio de cierre.

**Próxima decisión de desarrollo al concluir este documento:** implementar `missions/reactivo_13.slice.json` → pruebas de FSM → bloqueo de geometría 0.7. No declarar jugable la misión basándose solo en el GDD.

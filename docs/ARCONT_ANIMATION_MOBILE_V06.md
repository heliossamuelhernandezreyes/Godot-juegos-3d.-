# FISURA 0.6 — ARCONT ANIM-004 + Android export QA

**Motor:** Godot 4.7.2-stable (misma versión de importación y exportación)  
**Código del juego:** solo en este repositorio  
**Herramientas ARCONT:** conocimiento `PROCEDURAL_ANIMATION.md`, `MOBILE_PERFORMANCE_FOUNDATIONS.md`, contrato de mapa fijado en CI.

## Problema detectado tras FISURA 0.5

El protagonista disponía de 24 clips nativos, pero el sistema no tenía una capa de corrección de apuntado y el disparo no aportaba retroceso óseo. El gesto táctil de mirar estaba acoplado a apuntar automáticamente al enemigo al pulsar disparar. Además, el método de seguimiento de cámara miraba a una posición distinta a la del primer fotograma, provocando cambios visibles de encuadre.

## Implementación experimental

1. `vanguard_aim_modifier.gd` extiende `SkeletonModifier3D` para introducir rotaciones locales acotadas al torso **después** de reproducir `AnimationPlayer`. Solo selecciona hasta tres huesos cuyos nombres contengan `spine` o `chest`; ninguna posición de hueso se inventa. Añade una oscilación muy pequeña de retroceso al disparar.
2. El protagonista conserva el esqueleto, los clips nativos, `CharacterBody3D`, impactos, movimiento y rodada; el modificador nunca toca físicas.
3. Input táctil de dos zonas independientes: dedo de movimiento en la mitad inferior izquierda; dedo de orientación en el área derecha central. Los botones de disparo e impulso se conservan.
4. La cámara usa un único objetivo en `_ready` y `_process`, FOV suave al disparar, test de límites y un rayo antiobstrucción contra objetos.
5. Nueva exportación de depuración **arm64 Android**, con herramientas Godot/export templates de la misma versión, clave temporal de depuración, firma solo para pruebas y artefacto APK en GitHub Actions.

## Evidencia y límites exactos

La prueba `tests/vanguard_aim_mobile.gd` comprueba estructura ósea del modificador, procesamiento después de animación, retroceso y dos identificadores de contacto independientes. Se ejecuta en **Godot Linux headless con eventos de pantalla simulados**. No garantiza ergonomía en hardware ni medición táctil real.

El modificador es una **capa aditiva de torso, NO un solucionador IK real**. Todavía se necesitan dos-huesos IK de pies y manos, contacto dinámico con escaleras/coberturas, apuntado vertical auténtico basado en raycast, refinamiento de peso de animación, pruebas de motion quality y distribución de frames.

La compilación APK solo verifica el empaquetado y firma cuando CI termina correctamente; **no** implica que el juego haya corrido en un dispositivo Android. La validación física requiere APK, instalación, captura de frame-time p50/p95/p99, GPU/CPU/temperatura y pruebas sostenidas según el protocolo ARCONT para móvil.

## Métricas siguientes

- Tasa de acciones fallidas al mover/disparar simultáneamente en pantalla táctil.
- Diferencia entre trayectoria física del proyectil y eje visual del arma.
- Tiempos p50/p95/p99 de fotogramas, y temperatura de dispositivo tras 15 min de combate.
- Alteración de silueta del torso con ángulos máximos y discontinuidades al rodar.
- Coste de un `SkeletonModifier3D` frente a tres huesos y un solucionador IK específico.

**Estado del juego:** prototipo avanzado de acción y extracción; no es un AAA terminado.

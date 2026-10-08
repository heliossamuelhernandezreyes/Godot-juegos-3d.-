# ARCONT — Auditoría de cobertura para FISURA 0.7: REACTIVO-13

**Versión:** diseño 1.0 · **fecha:** 2026-10-07  
**Fuentes observadas:** ARCONT `tools/map_forge_contract.py`, `docs/knowledge/{GAME_DEV_ATLAS,MAP_FORGE_STANDARD,AI_NAVIGATION,PROCEDURAL_ANIMATION,MOBILE_PERFORMANCE_FOUNDATIONS}.md`, catálogo de assets y los registros de FISURA v0.3–0.6.  
**Enfoque:** distinguir conocimiento/documentación, validación automatizada, funcionamiento real de Godot, evidencia visual y dispositivo físico. Los requisitos de REACTIVO-13 son **diseño**, no resultados medidos.

## Dictamen

Arcont ha sido útil como **banco técnico y verificador de contratos concretos**. Sin embargo, el salto de un único mapa de extracción a una misión con cinco fases necesita una capa nueva de especificación/consistencia y herramientas de QA de gameplay. El laboratorio contiene guías generales de navegación, animación, activos y rendimiento, pero no demuestra que pueda generar por sí solo una misión AAA ni abrir el editor y dirigir todos sus sistemas.

### Matriz de trazabilidad de necesidades

| ID | Requisito REACTIVO-13 | Evidencia Arcont antes de 0.7 | Brecha comprobable | Acción recomendada | Puerta para considerarlo resuelto |
|---|---|---|---|---|---|
| ARC-GAP-01 | Definir 5 fases, objetivos, gates y dependencias | `MAP_FORGE_STANDARD.md` valida geometría semántica, **no secuencias de misión** | Sin contrato de FSM/objetivos/encuentros | **P0:** `schemas/vertical-slice-contract.schema.json` + `tools/vertical_slice_contract.py` genéricos (cambio propuesto en Arcont) | G0: ejemplo positivo y pruebas negativas + contrato REACTIVO-13 aceptado |
| ARC-GAP-02 | Nodos A/B accesibles, rutas y cobertura útiles | `tools/map_forge_contract.py` verifica campos y tipos; `AI_NAVIGATION.md` ofrece estrategia | No comprueba **alcanzabilidad física** de rutas Godot ni altura | **P0:** comprobar nueva escena y navegación, sin fingir que el JSON la demuestra | G1: rutas a objetivos + colisiones + corredores abiertos en Godot |
| ARC-GAP-03 | Encuentros justos y jerarquía de enemigos | IA experimental existente en juego; ARCONT tiene ideas de navegación | Sin pruebas de telegráfico, colocación, presión o daño a través de paredes para misión 0.7 | **P0:** contrato de encounter + auditoría de spawn y fairness con métricas | G3: 3 roles demostrables; ningún spawn dentro del jugador; raycasts de cobertura |
| ARC-GAP-04 | Diseño visual identificable, no simples cajas | Reglas genéricas de gráficos y assets + capturas de 0.3–0.6 | Ningún criterio reproducible de composición/legibilidad y continuidad de iluminación | **P1:** referencias y captura 3 puntos + revisión humana estructurada | G4: 3 imágenes reales comparables revisadas y fallos registrados |
| ARC-GAP-05 | Combate y movilidad que se sientan bien | Rig Quaternius + prueba de animación y raycast existentes | Pass CI no mide sensación de disparo, transiciones o inputs simultáneos reales | **P1:** heurística de game feel y prueba observacional | G6: resultados de playtest sobre claridad, controles, recoil y frustración |
| ARC-GAP-06 | Distribuir y medir en Android | CI de export APK existente, fundamentos de frame pacing de ARCONT | **Exportar APK ≠ usar Android físico**; no hay datos de p50/p95/p99 del nuevo mapa | **P0 antes de prometer FPS:** protocolo dispositivo/15 min | G5: telemetría documentada y capturas de hardware |
| ARC-GAP-07 | Asset profesional para Bulwark | Asset Vault + políticas de licencia y SHA; modelos originales/reutilizados | No existe Bulwark importado, licenciado y animado para REACTIVO-13 | **P1:** prop/enemigo con procedencia + import/test | G3/G4: modelo fiable, colisión y animación de combate |
| ARC-GAP-08 | Herramientas abiertas operables por una IA de extremo a extremo | Map Forge y toolchain **catalogados**; juego usa llamadas propias a Godot | Los estándares no son una orquestación verificable de editor, escena, arte y pruebas | **P2:** adaptadores controlados por contrato + permisos acotados | pipeline reproducible crea escena, valida Godot, registra pruebas |
| ARC-GAP-09 | Conservar evidencia sin sobredeclarar AAA | Estándares de provenance, experiments y QA | Riesgo de marcar diseño aprobado como implementación | **P0:** estados explícitos, IDs de gate y artifact hashes | G0 exige estado `design_only`; más adelante reportes de ejecución real |

### Estado concreto de las capacidades hoy

**Comprobado en fuentes:** Arcont dispone de `tools/map_forge_contract.py`, una plantilla y JSON Schema de mapas, corpus técnico Godot, catálogo de assets con control de licencia y evidencias de experiencias anteriores. FISURA 0.6 conserva un escenario de 44×44, una cadena de 3 núcleos, dos tipos de enemigos y pruebas automatizadas Linux.

**Implementado en este cambio de diseño:** el GDD y `missions/reactivo_13.slice.json` con fases, roles, encounters, anchors, dependencia A/B, gates y estado `design_only`. Una propuesta genérica de validación se desarrolla en una **rama separada de Arcont**: no se confunde con una capacidad presente en `main` hasta que supere tests y se integre.

**No implementado en el juego:** director 0.7, Bulwark, mapa nuevo, nodos interactivos A/B, supervivencia temporizada de 75 segundos, final de fase, tres capturas de arte 0.7 y prueba real Android. No se debe etiquetar ninguna de esas funciones como jugable sin pasar el gate correspondiente.

### Orden de implementación guiado por brechas

1. **G0 — cerrar contrato:** validador genérico Arcont; ejecutar ejemplo reusable con mutaciones inválidas; validar `missions/reactivo_13.slice.json` desde CI del juego usando SHA Arcont fijado. Esta es una mejora real de Arcont, no simplemente una nota.
2. **G1/G2 — construir primer ciclo jugable:** mapa con bloqueo y navegación comprobados + FSM separado + nodos A/B. Mantener 0.6 operativo como rama principal hasta que la misión 0.7 tenga extracción completa.
3. **G3 — combate:** añadir Bulwark, spawns justos, exclusión de oleadas no terminantes; prueba de raycasts y límites de hostiles.
4. **G4/G6 — percepción:** cámara de combate, HUD, VFX y tres capturas bajo geometría reproducible; prueba humana sobre comprensión de objetivo.
5. **G5 — dispositivo:** APK de la nueva misión y telemetría real de rendimiento y controles, no solo exportación.

### Protocolo de hallazgos a reutilizar en Arcont

Por cada brecha registrar: requisito, herramienta consultada, acción intentada, prueba/archivo de salida, resultado (PASS/FAIL/NOT_TESTED), versión de motor/plataforma, causa y aprendizaje reusable. **No** copiar escenas, GDScript de juego ni assets a Arcont. Compartir principios, esquemas neutrales, validadores y resultados negativos comprobados.

### Decisión de alcance

El siguiente cambio no debe reemplazar ciegamente `crisol_01.json`. Se diseña y valida primero un contrato nuevo; luego se crea un mapa nuevo con una misión de inicio a fin. **FISURA 0.7 aún está en etapa de diseño.**

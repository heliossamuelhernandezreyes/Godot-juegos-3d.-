# FISURA — Registro de assets 3D, licencias y evidencia

## Geometría original
`assets/models/` contiene diez mallas Wavefront OBJ y su `fisura_materials.mtl`, creados para este prototipo. Se usan en el protagonista articulado, rifle, enemigo Reaver, pilares, coberturas, reactor, suelo y portal. No proceden de terceros.

## Material fotogramétrico importado desde Poly Haven (CC0 1.0)
El inventario `ARCONT Asset Vault` nos permitió preseleccionar activos CC0. El catálogo **no contenía sus binarios**: el juego incorporó las copias glTF 1K directamente desde la API oficial del proveedor mediante `tools/vendor_polyhaven.py`.

| Archivo local | Página oficial | Licencia | Evidencia |
|---|---|---|---|
| `assets/vendor/polyhaven/barrel_03/barrel_03_1k.gltf` | https://polyhaven.com/a/barrel_03 | CC0-1.0 | `assets/vendor/polyhaven/barrel_03/PROVENANCE.json` |
| `assets/vendor/polyhaven/industrial_wall_lamp/industrial_wall_lamp_1k.gltf` | https://polyhaven.com/a/industrial_wall_lamp | CC0-1.0 | `assets/vendor/polyhaven/industrial_wall_lamp/PROVENANCE.json` |

Cada `PROVENANCE.json` contiene versión de la lista de archivos de Poly Haven, URL de origen, tamaño y SHA-256 de cada archivo incorporado. El juego no necesita descargar assets al ejecutarse. Godot debe confirmar que los glTF y sus materiales/téxturas se importan correctamente antes de que la versión se considere verificable.

Fuente de licencia oficial: https://polyhaven.com/license

## Obligaciones y restricciones

- **Assets originales:** formas geométricas para prototipado, no se presentan como arte externo ni como animaciones profesionales.
- **Assets Poly Haven:** CC0 permite uso comercial, modificación y redistribución. Las páginas del proveedor se conservan como referencia de procedencia.
- **No se asume compatibilidad Android:** la importación de editor no es una medición GPU/termal del dispositivo.
- **Materiales de terceros futuros:** solo integrar con manifest verificable, licencia exacta y prueba reproducible de importación.

## Materiales PBR incorporados en FISURA 0.3

Los siguientes activos vienen de Poly Haven y estaban clasificados CC0 en ARCONT Asset Vault. Los binarios fueron adquiridos desde URLs oficiales con manifiestos locales de fuente, licencia y SHA-256:

| Material | Procedencia | Manifiesto |
|---|---|---|
| Concrete Wall 007 | https://polyhaven.com/a/concrete_wall_007 | `assets/vendor/polyhaven_materials/concrete_wall_007/PROVENANCE.json` |
| Concrete Floor Worn 02 | https://polyhaven.com/a/concrete_floor_worn_02 | `assets/vendor/polyhaven_materials/concrete_floor_worn_02/PROVENANCE.json` |
| Green Metal Rust | https://polyhaven.com/a/green_metal_rust | `assets/vendor/polyhaven_materials/green_metal_rust/PROVENANCE.json` |

Archivos: diffuse 1K, OpenGL normal 1K y ARM 1K para cada superficie. Ningún archivo se descarga en runtime. Licencia original: https://polyhaven.com/license.

## Quaternius Sci-Fi Essentials Kit Standard — CC0

Autor: **Quaternius**. Kit original: https://quaternius.com/packs/scifiessentialskit.html  
Licencia: CC0 1.0 (copia de `License_Standard.txt` en `assets/vendor/quaternius/scifi_essentials/SOURCE_LICENSE.txt`).  
Repositorio de redistribución identificado: `agentkaerf/FreeModels`, commit **db3df04d1e4714298a09510b26fb6de6645138a2**.

Se incorporaron únicamente las mallas y dependencias de **Enemy_QuadShell**, **Enemy_EyeDrone** y **Gun_Rifle** en glTF + BIN + PNG PBR. El archivo `PROVENANCE.json` conserva por cada componente: URL exacta fijada al commit, tamaño, SHA-256. Quaternius es el creador; el repositorio fuente de descarga es un espejo de terceros, no el alojamiento oficial.

Comprobado: glTF importable en Godot 4.7.2, dos mallas skin con Skeleton3D y AnimationPlayer y rifle PBR. **No inferir** compatibilidad de FPS Android ni calidad comercial AAA por esos resultados.

## Vanguard Spacesuit (Ultimate Modular Men — Quaternius CC0)

- Creador original: Quaternius (Ultimate Modular Men, 2022). Licencia CC0 1.0 Universal; archivada en `assets/vendor/quaternius/vanguard_spacesuit/SOURCE_LICENSE.txt`.
- Modelo seleccionado: `Spacesuit.gltf`, con esqueleto y **24 clips nativos**. Descarga reproducible desde el espejo `agentkaerf/FreeModels` fijado al commit `db3df04d1e4714298a09510b26fb6de6645138a2`.
- `PROVENANCE.json` conserva el URL exacto de origen, hash SHA-256, tamaño y evidencia de licencia. El juego no efectúa descargas al abrirse.
- Resultado verificado exclusivamente en Godot 4.7.2 Linux mediante importación, activación de Run y transiciones de gameplay. No confundir con QA visual riguroso, certificación de rendimiento Android ni nivel AAA.

## FISURA 0.8 — ampliación de arte industrial CC0 sobre `main`

- **Poly Haven industrial_storage_cart**: https://polyhaven.com/a/industrial_storage_cart, modelo fotogramétrico 1K, `assets/vendor/polyhaven_cinematic/industrial_storage_cart/PROVENANCE.json`.
- **Poly Haven industrial_pastic_container**: https://polyhaven.com/a/industrial_pastic_container (ortografía del identificador original), modelo PBR 1K, `assets/vendor/polyhaven_cinematic/industrial_pastic_container/PROVENANCE.json`.
- **Quaternius Enemy_Trilobite**: personaje animado distinto del QuadShell, 9 clips nativos, del Sci-Fi Essentials Kit Standard CC0. Copia del paquete fijado al commit `agentkaerf/FreeModels@db3df04d1e4714298a09510b26fb6de6645138a2`. `assets/vendor/quaternius/scifi_essentials/BULWARK_PROVENANCE.json`.

Todos los recursos se alojan únicamente en FISURA y cuentan con una cadena local de procedencia de binarios/texturas. Los modelos PBR se colocan como decoración sin modificar colisiones. La prueba de Godot exige su importación real, y la mecánica del Bulwark debe continuar superando el test del escudo frontal y la espalda.

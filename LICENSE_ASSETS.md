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

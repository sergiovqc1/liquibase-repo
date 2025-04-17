#!/usr/bin/env python3
import re, sys, pathlib, collections

if len(sys.argv) != 2:
    print("Uso: clean_changelog.py <ruta_al_diff.snowflake.sql>")
    sys.exit(1)

entrada = pathlib.Path(sys.argv[1])
if not entrada.exists():
    print(f"❌ Archivo no encontrado: {entrada}")
    sys.exit(1)

# Salida con sufijo .clean.snowflake.sql
salida = entrada.with_name(entrada.stem + '.clean.snowflake.sql')

# Regex para detectar cabeceras y tablas
pat_header = re.compile(r'^(--\s*changeset\s+\S+)', re.I | re.M)
pat_tabla  = re.compile(r'\b(?:CREATE TABLE|ALTER TABLE|DROP TABLE|CREATE VIEW|DROP VIEW)\s+([A-Za-z0-9_\.]+)', re.I)

texto = entrada.read_text()

# 1. Partir el texto en [_, header1, body1, header2, body2, ...]
parts = pat_header.split(texto)
# parts[0] es lo que hay antes del primer header (puede ser "-- liquibase formatted sql\n\n")
# Luego cada par (parts[1],parts[2]), (parts[3],parts[4]), …

# 2. Agrupar por objeto
grupos = collections.OrderedDict()
for i in range(1, len(parts), 2):
    header = parts[i].strip()
    body   = parts[i+1]
    m = pat_tabla.search(body)
    obj = m.group(1) if m else 'ZZZ_MISC'
    grupos.setdefault(obj, []).append((header, body))

# 3. Reordenar cada grupo internamente
orden = ('CREATE TABLE', 'ALTER TABLE', 'DROP TABLE', 'CREATE VIEW', 'DROP VIEW')
def key_fn(item):
    b = item[1].upper()
    for idx, clave in enumerate(orden):
        if clave in b:
            return idx
    return len(orden)

# 4. Escribir el .clean.snowflake.sql
with salida.open('w') as f:
    # IMPORTANTE: esto permite a Liquibase reconocer el archivo como changelog SQL
    f.write("-- liquibase formatted sql\n\n")
    for obj, bloques in grupos.items():
        for header, body in sorted(bloques, key=key_fn):
            f.write(header + '\n' + body + '\n')

print(f"✅ Changelog limpio generado en {salida}")

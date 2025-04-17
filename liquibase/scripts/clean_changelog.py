#!/usr/bin/env python3
import re
import sys
from pathlib import Path
from collections import defaultdict

if len(sys.argv) != 2:
    print("Uso: clean_changelog.py <raw_diff_file>")
    sys.exit(1)

raw_file = Path(sys.argv[1])
if not raw_file.exists():
    print(f"No existe el archivo {raw_file}")
    sys.exit(1)

# Lee todo el raw diff
texto = raw_file.read_text()

# Partes divididas por changeset
pattern = re.compile(r'(--\s*changeset[^\r\n]+)', re.IGNORECASE)
partes = pattern.split(texto)

# Agrupa por objeto (tabla/vista) y tipo
grupos = defaultdict(list)
for i in range(1, len(partes), 2):
    header = partes[i].strip()
    body = partes[i+1].strip()
    # Detecta el objeto: busca la tabla en CREATE/DROP/ALTER TABLE
    m = re.search(r'(?:CREATE|DROP|ALTER)\s+TABLE\s+([A-Za-z0-9_\.]+)', body, re.IGNORECASE)
    obj = m.group(1) if m else "_otros"
    grupos[obj].append((header, body))

# Archivo de salida
salida = raw_file.with_name(raw_file.stem + ".clean.snowflake.sql")

with salida.open('w') as f:
    f.write("-- liquibase formatted sql\n\n")
    for obj, bloques in grupos.items():
        for header, body in sorted(bloques, key=lambda x: x[0]):
            f.write(header + "\n")
            f.write(body + "\n")

            # Calcula un rollback básico
            rollback_sql = ""
            tokens = body.strip().split()
            ddl = tokens[0].upper()
            tbl = obj.split('.')[-1]

            if ddl == "CREATE":
                rollback_sql = f"DROP TABLE {tbl};"
            elif ddl == "ALTER" and "ADD CONSTRAINT" in body.upper():
                m2 = re.search(r'ADD CONSTRAINT\s+([A-Za-z0-9_]+)', body, re.IGNORECASE)
                if m2:
                    rollback_sql = f"ALTER TABLE {tbl} DROP CONSTRAINT {m2.group(1)};"
            elif ddl == "DROP":
                rollback_sql = f"-- rollback NOT IMPLEMENTED for DROP TABLE {tbl}"

            if rollback_sql:
                f.write(f"-- rollback {rollback_sql}\n")

            f.write("\n")

print(f"✅ Changelog limpio generado en {salida}")

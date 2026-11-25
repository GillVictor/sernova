#!/usr/bin/env python3
"""Génère docs/reference/openapi.yaml (OpenAPI 3.1) à partir du contrat et du dictionnaire.

Sources (seules sources de vérité) :
  docs/reference/api-contract.xlsx    feuilles Endpoints, Schémas, Erreurs
  docs/reference/data-dictionary.xlsx feuille Enumerations

Usage :
  python docs/reference/tools/generate_openapi.py            # réécrit openapi.yaml
  python docs/reference/tools/generate_openapi.py --check    # échoue si openapi.yaml n'est pas à jour

Ne jamais modifier openapi.yaml à la main : corriger le contrat puis régénérer.
Les routes dont la feuille Schémas ne décrit pas les objets gardent des schémas « indicatifs »
(`x-schema-status: indicative`) : ils sont précisés tranche par tranche.
"""
import re
import sys
from pathlib import Path

import openpyxl
import yaml

REF = Path(__file__).resolve().parent.parent
OUT = REF / "openapi.yaml"

# --- Routes dont la réponse ou la requête est décrite dans la feuille Schémas -------------
RESPONSE_SCHEMA = {
    "EP-002": "tokenPair", "EP-004": "tokenPair", "EP-005": "tokenPair",
    "EP-009": "account",
    "EP-011": "providerProfile", "EP-014": "providerProfile", "EP-015": "providerProfile",
    "EP-018": ("array", "verification"),
    "EP-021": ("array", "category"),
    "EP-022": ("array", "attributeDefinition"),
    "EP-023": ("array", "location"),
    "EP-030": ("page", "offerSummary"),
    "EP-035": ("page", "offerSearchItem"),
    "EP-037": "offerDetail",
    "EP-038": "requestCreated",
    "EP-043": ("page", "requestFeedItem"),
    "EP-065": ("page", "transactionSummary"),
    "EP-109": ("page", "notification"),
    "EP-110": "unreadCount",
}
REQUEST_SCHEMA = {"EP-038": "requestInput"}
# Convention « Idempotence » : en-tête Idempotency-Key obligatoire (conservé 24 h)
IDEMPOTENT = {"EP-038", "EP-044", "EP-050", "EP-051", "EP-055"}
# Réponses qui ne sont pas du JSON
BINARY = {"EP-114"}


def load():
    c = openpyxl.load_workbook(REF / "api-contract.xlsx")
    d = openpyxl.load_workbook(REF / "data-dictionary.xlsx")
    ep = [r for r in c["Endpoints"].iter_rows(min_row=2, values_only=True) if r[0]]
    schemas = [r for r in c["Schémas"].iter_rows(min_row=2, values_only=True) if r[0]]
    errors = [r for r in c["Erreurs"].iter_rows(min_row=2, values_only=True) if r[0]]
    enums = {}
    for r in d["Enumerations"].iter_rows(min_row=2, values_only=True):
        if r[0]:
            # « N0 non vérifié ; N1 … » : la valeur est le premier mot de chaque élément
            enums[r[0]] = [v.strip().split()[0] for v in str(r[1]).split(";") if v.strip()]
    version = "0.2"
    return ep, schemas, errors, enums, version


def ref(name):
    return {"$ref": f"#/components/schemas/{name}"}


def nullable(schema):
    if "$ref" in schema:
        return {"oneOf": [schema, {"type": "null"}]}
    t = schema.get("type")
    out = dict(schema)
    out["type"] = [t, "null"] if isinstance(t, str) else t
    return out


def parse_type(t, objs, enums):
    t = str(t).strip()
    if t.endswith("[]"):
        return {"type": "array", "items": parse_type(t[:-2], objs, enums)}
    m = re.fullmatch(r"string\((\d+)\)", t)
    if m:
        return {"type": "string", "maxLength": int(m.group(1))}
    simple = {
        "string": {"type": "string"},
        "uuid": {"type": "string", "format": "uuid"},
        "int": {"type": "integer"},
        "number": {"type": "number"},
        "boolean": {"type": "boolean"},
        "datetime": {"type": "string", "format": "date-time"},
        "date": {"type": "string", "format": "date"},
        "Money": ref("Money"),
    }
    if t in simple:
        return dict(simple[t])
    if t in enums or t in objs:
        return ref(t)
    return {"type": "object", "description": t}  # forme libre décrite en texte


def build_components(schemas, errors, enums):
    objs = {r[0] for r in schemas if r[0] != "page<T>"}
    comps = {
        "Money": {
            "type": "object",
            "required": ["amount", "currency"],
            "properties": {
                "amount": {"type": "integer", "description": "Plus petite unité monétaire entière (pas de décimales en XAF et XOF)"},
                "currency": {"type": "string", "pattern": "^[A-Z]{3}$", "description": "ISO 4217 (XAF ou XOF en V1)"},
            },
        },
        "Problem": {
            "type": "object",
            "description": "Erreur au format problem+json (RFC 9457). Les clients n'affichent jamais `detail` tel quel.",
            "required": ["type", "title", "status", "code", "traceId"],
            "properties": {
                "type": {"type": "string"}, "title": {"type": "string"}, "status": {"type": "integer"},
                "code": {"type": "string", "description": "Code stable, voir x-error-codes"},
                "detail": {"type": "string"}, "traceId": {"type": "string"},
                "errors": {"type": "array", "items": {"type": "object", "properties": {"field": {"type": "string"}, "code": {"type": "string"}}}},
            },
        },
    }
    for name, values in enums.items():
        comps[name] = {"type": "string", "enum": values}
    by_obj = {}
    for obj, field, typ, oblig, desc, routes, status in schemas:
        if obj == "page<T>":
            continue
        by_obj.setdefault(obj, []).append((field, typ, oblig, desc))
    for obj, fields in by_obj.items():
        props, required = {}, []
        for field, typ, oblig, desc in fields:
            s = parse_type(typ, objs, enums)
            if oblig == "Nullable":
                s = nullable(s)
            if desc:
                if "$ref" in s:
                    s = {"allOf": [s], "description": desc}
                else:
                    s["description"] = (s.get("description", "") + (" : " if s.get("description") else "") + desc)
            props[field] = s
            if oblig in ("Oui", "Nullable"):
                required.append(field)
        comps[obj] = {"type": "object", "required": required, "properties": props}
    return comps, objs


def page_schema(item):
    return {
        "type": "object",
        "required": ["items", "nextCursor"],
        "properties": {
            "items": {"type": "array", "items": ref(item)},
            "nextCursor": {"type": ["string", "null"], "description": "Opaque ; null = dernière page"},
        },
    }


def op_id(method, path):
    parts = []
    for seg in path.strip("/").split("/"):
        m = re.fullmatch(r"\{(\w+)\}", seg)
        parts.append("By" + m.group(1)[0].upper() + m.group(1)[1:] if m else seg[0].upper() + seg[1:])
    base = "".join(re.sub(r"[^A-Za-z0-9]", "", p) for p in parts)
    return method.lower() + base


def split_top(text):
    """Découpe sur les virgules qui ne sont ni entre parenthèses, ni entre crochets, ni entre accolades."""
    parts, depth, cur = [], 0, ""
    for ch in str(text):
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


REQUIRED_QUERY = {("EP-036", "bbox")}


def query_params(ep_id, text, path_params):
    """Paramètres de requête d'une route GET ou DELETE, d'après le texte de la colonne Entrée.
    Formes reconnues : `nom`, `nom?`, `nom (a, b, c)` (valeurs permises), `a ou lat+lng`."""
    params = []
    for token in split_top(text):
        token = re.sub(r"\s*\(réservé à [^)]*\)", "", token)  # remarque d'accès, pas une valeur
        names, values = [], None
        m = re.fullmatch(r"([A-Za-z][A-Za-z0-9]*)\??\s*\(([^)]*)\)", token)
        if m:
            names, values = [m.group(1)], [v.strip() for v in m.group(2).split(",") if v.strip()]
        elif " ou " in token or "+" in token:
            names = re.findall(r"[A-Za-z][A-Za-z0-9]*", token.replace(" ou ", " "))
            names = [n for n in names if n != "ou"]
        elif re.fullmatch(r"[A-Za-z][A-Za-z0-9]*\??", token):
            names = [token.rstrip("?")]
        for name in names:
            if name in path_params:
                continue
            sch = query_schema(name)
            if values:
                sch = {"type": "string", "enum": values}
            params.append({"name": name, "in": "query", "required": (ep_id, name) in REQUIRED_QUERY, "schema": sch})
    return params


def query_schema(name):
    if name in ("limit", "priceMin", "priceMax", "page"):
        return {"type": "integer"}
    if name in ("lat", "lng"):
        return {"type": "number"}
    if name in ("includeInactive", "coverageOnly", "unread"):
        return {"type": "boolean"}
    if name in ("from", "to"):
        return {"type": "string", "format": "date-time"}
    if name.endswith("Id"):
        return {"type": "string", "format": "uuid"}
    return {"type": "string"}


def body_schema(ep_id, text):
    if ep_id in REQUEST_SCHEMA:
        return ref(REQUEST_SCHEMA[ep_id])
    props, required, extra = {}, [], []
    for token in split_top(text):
        m = re.fullmatch(r"([A-Za-z][A-Za-z0-9]*)(\?)?", token)
        if m:
            name = m.group(1)
            props[name] = ({"type": "string", "format": "uuid"} if name.endswith("Id") else {})
            if not m.group(2):
                required.append(name)
        elif token and token != "—":
            extra.append(token)
    s = {"type": "object", "properties": props, "x-schema-status": "indicative"}
    if required:
        s["required"] = required
    if extra:
        s["description"] = "Autres éléments de l'entrée (forme libre) : " + " ; ".join(extra)
    return s


def build():
    ep, schemas, errors, enums, version = load()
    comps, objs = build_components(schemas, errors, enums)
    schemas_cmp = comps
    pages = {v[1] for v in RESPONSE_SCHEMA.values() if isinstance(v, tuple) and v[0] == "page"}
    for item in sorted(pages):
        schemas_cmp["PageOf_" + item] = page_schema(item)

    err_http = {r[0]: int(r[1]) for r in errors}
    doc = {
        "openapi": "3.1.0",
        "info": {
            "title": "ServNova API",
            "version": version,
            "description": "Généré depuis docs/reference/api-contract.xlsx et data-dictionary.xlsx (ne pas modifier à la main). "
                           "Les schémas marqués `x-schema-status: indicative` ne sont pas encore fixés (voir la feuille Schémas).",
        },
        "servers": [{"url": "/api/v1"}],
        "tags": [],
        "paths": {},
        "components": {
            "securitySchemes": {"bearerAuth": {"type": "http", "scheme": "bearer", "bearerFormat": "JWT"}},
            "schemas": schemas_cmp,
            "responses": {
                "Unauthorized": {"description": "Jeton absent, expiré ou révoqué (UNAUTHENTICATED, TOKEN_EXPIRED, TOKEN_REVOKED)",
                                 "content": {"application/problem+json": {"schema": ref("Problem")}}},
                "Forbidden": {"description": "Droit manquant (FORBIDDEN)",
                              "content": {"application/problem+json": {"schema": ref("Problem")}}},
                "ValidationFailed": {"description": "Entrée invalide (VALIDATION_FAILED), détail dans `errors`",
                                     "content": {"application/problem+json": {"schema": ref("Problem")}}},
            },
            "x-error-codes": {r[0]: {"status": int(r[1]), "title": r[2], "when": r[3]} for r in errors},
        },
    }
    tags = []
    seen_ops = set()
    for (eid, uc, tranche, method, path, summary, access, inp, out, errs, notes) in ep:
        tag = path.strip("/").split("/")[0]
        if tag not in tags:
            tags.append(tag)
        method_l = method.lower()
        oid = op_id(method, path)
        assert oid not in seen_ops, f"operationId en double : {oid}"
        seen_ops.add(oid)

        op = {
            "operationId": oid,
            "summary": summary,
            "tags": [tag],
            "x-ep": eid, "x-useCase": uc, "x-tranche": tranche, "x-access": access,
        }
        notes_txt = " ".join(x for x in [f"Entrée : {inp}." if inp and inp != "—" else "", f"Réponse : {out}." if out else "", f"Notes : {notes}" if notes else ""] if x)
        if notes_txt:
            op["description"] = notes_txt
        params = []
        for pname in re.findall(r"\{(\w+)\}", path):
            sch = {"type": "string"} if pname in ("token", "key", "operator") else {"type": "string", "format": "uuid"}
            params.append({"name": pname, "in": "path", "required": True, "schema": sch})
        has_body = method in ("POST", "PATCH", "PUT")
        if method in ("GET", "DELETE") and inp and inp.strip() != "—":
            params += query_params(eid, inp, set(re.findall(r"\{(\w+)\}", path)))
        if eid in IDEMPOTENT:
            params.append({"name": "Idempotency-Key", "in": "header", "required": True, "schema": {"type": "string"},
                           "description": "Même clé avec un corps différent : 422 IDEMPOTENCY_KEY_REUSED"})
        if params:
            op["parameters"] = params
        if has_body and inp and inp.strip() != "—":
            op["requestBody"] = {"required": True, "content": {"application/json": {"schema": body_schema(eid, inp)}}}

        # Réponse de succès
        code = re.match(r"\s*(\d{3})", str(out)).group(1)
        responses = {code: {"description": str(out)}}
        target = RESPONSE_SCHEMA.get(eid)
        if eid in BINARY:
            responses[code]["content"] = {"application/octet-stream": {"schema": {"type": "string", "format": "binary"}}}
        elif code != "204" and target:
            if isinstance(target, tuple):
                kind, name = target
                schema = {"type": "array", "items": ref(name)} if kind == "array" else ref("PageOf_" + name)
            else:
                schema = ref(target)
            responses[code]["content"] = {"application/json": {"schema": schema}}
        elif code not in ("204", "202") and not target:
            responses[code]["content"] = {"application/json": {"schema": {"type": "object", "description": str(out), "x-schema-status": "indicative"}}}

        # Erreurs métier par statut
        by_status = {}
        for m in re.finditer(r"([A-Z][A-Z_]{3,})\s+(\d{3})", str(errs or "")):
            by_status.setdefault(m.group(2), []).append(m.group(1))
        generic = {"401": "Jeton absent, expiré ou révoqué", "403": "Droit manquant", "422": "VALIDATION_FAILED, détail dans `errors`"}
        authenticated = not str(access).startswith("Public") and not str(access).startswith("Partenaire")
        wants = set()
        if authenticated:
            op["security"] = [{"bearerAuth": []}]
            wants.add("401")
            if str(access).startswith("Admin") or "admin" in str(access) or access not in ("Authentifié", "Client (authentifié)"):
                wants.add("403")
        else:
            op["security"] = []
        if has_body:
            wants.add("422")
        for status in sorted(set(by_status) | wants):
            codes = sorted(set(by_status.get(status, [])))
            if status in wants and not codes:
                responses[status] = {"$ref": {"401": "#/components/responses/Unauthorized", "403": "#/components/responses/Forbidden", "422": "#/components/responses/ValidationFailed"}[status]}
                continue
            text = ("Codes : " + ", ".join(codes)) if codes else ""
            if status in wants:
                text = generic[status] + (" ; " + text if text else "")
            responses[status] = {"description": text, "content": {"application/problem+json": {"schema": ref("Problem")}}}
        op["responses"] = responses
        doc["paths"].setdefault(path, {})[method_l] = op
    doc["tags"] = [{"name": t} for t in tags]
    return doc, len(ep)


def dump(doc):
    return yaml.dump(doc, sort_keys=False, allow_unicode=True, width=120, default_flow_style=False)


def main():
    doc, n = build()
    text = dump(doc)
    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("openapi.yaml n'est pas à jour : relancer docs/reference/tools/generate_openapi.py")
            sys.exit(1)
        print(f"openapi.yaml à jour ({n} opérations)")
        return
    OUT.write_text(text, encoding="utf-8")
    print(f"{OUT.relative_to(REF.parent.parent)} écrit : {n} opérations")


if __name__ == "__main__":
    main()

"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { AddAttributeForm, CreateCategoryForm, EditCategoryForm, flatten } from "@/components/CategoryForms";
import { t } from "@/i18n";
import type { Category } from "@/lib/api/client";
import { errorMessage } from "@/lib/api/messages";
import { useCategoryAttributes } from "@/lib/useCategoryAttributes";
import { useSession } from "@/lib/session";

function Tree({ nodes, selectedId, onSelect }: { nodes: Category[]; selectedId?: string; onSelect: (c: Category) => void }) {
  return (
    <ul className="tree">
      {nodes.map((c) => (
        <li key={c.id}>
          <div className="tree__row">
            <button type="button" aria-current={c.id === selectedId} onClick={() => onSelect(c)}>
              {c.name}
            </button>
            <span className="muted">{c.active ? c.family : `${c.family}, ${t("category.inactive")}`}</span>
          </div>
          {c.children?.length ? <Tree nodes={c.children} selectedId={selectedId} onSelect={onSelect} /> : null}
        </li>
      ))}
    </ul>
  );
}

export default function CategoriesPage() {
  const { client, authenticated } = useSession();
  const router = useRouter();
  const [tree, setTree] = useState<Category[] | null>(null);
  const [selectedId, setSelectedId] = useState<string>();
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const reload = useCallback(async () => {
    try {
      setTree(await client.listCategories()); // EP-021
      setError(null);
    } catch (e) {
      setError(errorMessage(e));
    }
  }, [client]);

  useEffect(() => {
    if (!authenticated) {
      router.replace("/login");
      return;
    }
    void reload();
  }, [authenticated, reload, router]);

  // EP-022
  const { attributes, error: attributesError, loading: attributesLoading, reload: reloadAttributes } =
    useCategoryAttributes(client, selectedId);

  if (!authenticated) return null;

  const selected = tree ? flatten(tree).find((x) => x.category.id === selectedId)?.category : undefined;

  return (
    <main className="page">
      <p><Link href="/">{t("category.back")}</Link></p>
      <h1>{t("category.title")}</h1>
      {error && <p className="field__error" role="alert">{error}</p>}
      {notice && <p className="notice" role="status">{notice}</p>}

      <section className="panel">
        {tree === null ? (
          <p>{t("common.loading")}</p>
        ) : tree.length === 0 ? (
          <p>{t("category.empty")}</p>
        ) : (
          <Tree nodes={tree} selectedId={selectedId} onSelect={(c) => {
              setNotice(null);
              setSelectedId(c.id);
            }} />
        )}
      </section>

      <section className="panel">
        <CreateCategoryForm
          tree={tree ?? []}
          onCreate={async (input) => {
            setNotice(null);
            await client.createCategory(input); // EP-089
            setNotice(t("category.created"));
            await reload();
          }}
        />
      </section>

      {selected && (
        <section className="panel">
          <EditCategoryForm
            key={`${selected.id}-${selected.name}-${selected.order}-${selected.active}-${selected.minVerificationLevel}`}
            category={selected}
            onSave={async (id, input) => {
              setNotice(null);
              await client.updateCategory(id, input); // EP-090
              setNotice(t("category.saved"));
              await reload();
            }}
          />
          <h2>{t("attribute.title")}</h2>
          {attributesError && <p className="field__error" role="alert">{attributesError}</p>}
          {attributesLoading ? (
            <p className="muted">{t("common.loading")}</p>
          ) : attributes.length === 0 && !attributesError ? (
            <p className="muted">{t("attribute.empty")}</p>
          ) : attributes.length === 0 ? null : (
            <ul>
              {attributes.map((a) => (
                <li key={a.id}>
                  {a.name} <span className="muted">({a.valueType}{a.required ? `, ${t("attribute.required")}` : ""})</span>
                </li>
              ))}
            </ul>
          )}
          <AddAttributeForm
            onAdd={async (input) => {
              setNotice(null);
              await client.addAttribute(selected.id, input); // EP-091
              setNotice(t("attribute.added"));
              reloadAttributes();
            }}
          />
        </section>
      )}
    </main>
  );
}

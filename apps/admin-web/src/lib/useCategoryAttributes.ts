"use client";

import { useCallback, useEffect, useState } from "react";
import type { ApiClient, AttributeDefinition } from "./api/client";
import { errorMessage } from "./api/messages";

type AttributeSource = Pick<ApiClient, "categoryAttributes">;

interface Loaded {
  /** Category the list belongs to. */
  id: string;
  list: AttributeDefinition[];
}

/**
 * Attributes of a category (EP-022). Safe against fast switching: an answer for a category
 * that is no longer selected is ignored, and the list of another category is never shown.
 */
export function useCategoryAttributes(client: AttributeSource, categoryId: string | undefined) {
  const [loaded, setLoaded] = useState<Loaded | null>(null);
  const [failure, setFailure] = useState<{ id: string; message: string } | null>(null);
  const [version, setVersion] = useState(0);

  useEffect(() => {
    if (!categoryId) return;
    let cancelled = false;
    client
      .categoryAttributes(categoryId)
      .then((list) => {
        if (cancelled) return;
        setLoaded({ id: categoryId, list });
        setFailure(null);
      })
      .catch((e: unknown) => {
        if (!cancelled) setFailure({ id: categoryId, message: errorMessage(e) });
      });
    return () => {
      cancelled = true;
    };
  }, [client, categoryId, version]);

  const current = categoryId !== undefined && loaded?.id === categoryId ? loaded : null;
  const error = categoryId !== undefined && failure?.id === categoryId ? failure.message : null;

  return {
    attributes: current?.list ?? [],
    error,
    loading: categoryId !== undefined && current === null && error === null,
    /** Fetch the same category again (after adding an attribute), keeping the current list meanwhile. */
    reload: useCallback(() => setVersion((v) => v + 1), []),
  };
}

import { act, renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { ApiError } from "./api/errors";
import type { AttributeDefinition } from "./api/client";
import { useCategoryAttributes } from "./useCategoryAttributes";

const attr = (id: string, name: string): AttributeDefinition => ({ id, name, valueType: "Texte", required: false });

/** A promise the test resolves or rejects by hand, to control the order of answers. */
function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (reason: unknown) => void;
  const promise = new Promise<T>((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
}

describe("useCategoryAttributes", () => {
  it("loads the attributes of the selected category", async () => {
    const client = { categoryAttributes: vi.fn().mockResolvedValue([attr("a1", "Marque")]) };
    const { result } = renderHook(() => useCategoryAttributes(client, "cat-1"));
    expect(result.current.loading).toBe(true);
    await waitFor(() => expect(result.current.attributes).toEqual([attr("a1", "Marque")]));
    expect(result.current.loading).toBe(false);
    expect(client.categoryAttributes).toHaveBeenCalledWith("cat-1");
  });

  it("returns nothing when no category is selected", () => {
    const client = { categoryAttributes: vi.fn() };
    const { result } = renderHook(() => useCategoryAttributes(client, undefined));
    expect(result.current.attributes).toEqual([]);
    expect(result.current.loading).toBe(false);
    expect(client.categoryAttributes).not.toHaveBeenCalled();
  });

  it("never shows the previous category's attributes while the next one loads", async () => {
    const first = deferred<AttributeDefinition[]>();
    const second = deferred<AttributeDefinition[]>();
    const client = { categoryAttributes: vi.fn().mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise) };
    const { result, rerender } = renderHook(({ id }) => useCategoryAttributes(client, id), { initialProps: { id: "A" } });

    await act(async () => first.resolve([attr("a", "Of A")]));
    await waitFor(() => expect(result.current.attributes).toHaveLength(1));

    rerender({ id: "B" });
    expect(result.current.attributes).toEqual([]); // not A's list
    expect(result.current.loading).toBe(true);

    await act(async () => second.resolve([attr("b", "Of B")]));
    await waitFor(() => expect(result.current.attributes).toEqual([attr("b", "Of B")]));
  });

  it("ignores a late answer for a category that is no longer selected (race)", async () => {
    const slowA = deferred<AttributeDefinition[]>();
    const fastB = deferred<AttributeDefinition[]>();
    const client = { categoryAttributes: vi.fn().mockReturnValueOnce(slowA.promise).mockReturnValueOnce(fastB.promise) };
    const { result, rerender } = renderHook(({ id }) => useCategoryAttributes(client, id), { initialProps: { id: "A" } });

    rerender({ id: "B" });
    await act(async () => fastB.resolve([attr("b", "Of B")]));
    await waitFor(() => expect(result.current.attributes).toEqual([attr("b", "Of B")]));

    await act(async () => slowA.resolve([attr("a", "Of A")])); // arrives last, must be ignored
    expect(result.current.attributes).toEqual([attr("b", "Of B")]);
  });

  it("reports a French error and clears it when another category is selected", async () => {
    const client = {
      categoryAttributes: vi
        .fn()
        .mockRejectedValueOnce(new ApiError(404, "NOT_FOUND"))
        .mockResolvedValueOnce([attr("b", "Of B")]),
    };
    const { result, rerender } = renderHook(({ id }) => useCategoryAttributes(client, id), { initialProps: { id: "A" } });
    await waitFor(() => expect(result.current.error).toBe("Élément introuvable."));
    expect(result.current.attributes).toEqual([]);

    rerender({ id: "B" });
    await waitFor(() => expect(result.current.attributes).toEqual([attr("b", "Of B")]));
    expect(result.current.error).toBeNull();
  });

  it("reload fetches the same category again and keeps the current list meanwhile", async () => {
    const reloaded = deferred<AttributeDefinition[]>();
    const client = {
      categoryAttributes: vi.fn().mockResolvedValueOnce([attr("a1", "Marque")]).mockReturnValueOnce(reloaded.promise),
    };
    const { result } = renderHook(() => useCategoryAttributes(client, "cat-1"));
    await waitFor(() => expect(result.current.attributes).toHaveLength(1));

    act(() => result.current.reload());
    expect(result.current.attributes).toHaveLength(1); // no flicker
    await act(async () => reloaded.resolve([attr("a1", "Marque"), attr("a2", "Taille")]));
    await waitFor(() => expect(result.current.attributes).toHaveLength(2));
    expect(client.categoryAttributes).toHaveBeenCalledTimes(2);
  });
});

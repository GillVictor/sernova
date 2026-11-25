import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { AddAttributeForm, CreateCategoryForm, EditCategoryForm } from "./CategoryForms";
import { ApiError } from "@/lib/api/errors";
import type { Category } from "@/lib/api/client";
import { messages } from "@/i18n";

const tree: Category[] = [
  {
    id: "dom", name: "Domicile", order: 1, active: true, family: "Domicile", minVerificationLevel: "N0",
    children: [{ id: "plomb", name: "Plomberie", order: 1, active: true, family: "Domicile", minVerificationLevel: "N1" }],
  },
];

describe("CreateCategoryForm", () => {
  it("has a help tooltip button on every field", () => {
    render(<CreateCategoryForm tree={tree} onCreate={vi.fn()} />);
    // root category by default: name, parent, family, order, level
    expect(screen.getAllByRole("button", { name: /^Aide sur le champ/ })).toHaveLength(5);
  });

  it("shows French help text for the family field", async () => {
    const user = userEvent.setup();
    render(<CreateCategoryForm tree={tree} onCreate={vi.fn()} />);
    await user.click(screen.getByRole("button", { name: "Aide sur le champ « Famille »" }));
    expect(screen.getByRole("tooltip")).toHaveTextContent(messages.category.fields.family.help);
  });

  it("validates locally and does not call the API", async () => {
    const onCreate = vi.fn();
    const user = userEvent.setup();
    render(<CreateCategoryForm tree={tree} onCreate={onCreate} />);
    await user.clear(screen.getByLabelText("Ordre d'affichage"));
    await user.click(screen.getByRole("button", { name: "Créer la catégorie" }));
    expect(screen.getByText("Ce champ est obligatoire.")).toBeInTheDocument();
    expect(screen.getByText("Saisissez un nombre entier.")).toBeInTheDocument();
    expect(onCreate).not.toHaveBeenCalled();
  });

  it("sends family for a root category and parentId (no family) for a child", async () => {
    const onCreate = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<CreateCategoryForm tree={tree} onCreate={onCreate} />);

    await user.type(screen.getByLabelText("Nom"), "Services");
    await user.selectOptions(screen.getByLabelText("Famille"), "Vente");
    await user.click(screen.getByRole("button", { name: "Créer la catégorie" }));
    await waitFor(() => expect(onCreate).toHaveBeenCalledTimes(1));
    expect(onCreate).toHaveBeenLastCalledWith({ family: "Vente", name: "Services", order: 0, minVerificationLevel: "N0" });

    await user.type(screen.getByLabelText("Nom"), "Jardinage");
    await user.selectOptions(screen.getByLabelText("Catégorie parente"), "dom");
    expect(screen.queryByLabelText("Famille")).toBeNull(); // inherited from the parent
    await user.click(screen.getByRole("button", { name: "Créer la catégorie" }));
    await waitFor(() => expect(onCreate).toHaveBeenCalledTimes(2));
    expect(onCreate).toHaveBeenLastCalledWith({ parentId: "dom", name: "Jardinage", order: 0, minVerificationLevel: "N0" });
  });

  it("maps server errors to French messages and field errors", async () => {
    const onCreate = vi
      .fn()
      .mockRejectedValueOnce(new ApiError(422, "VALIDATION_FAILED", [{ field: "name", code: "INVALID" }]))
      .mockRejectedValueOnce(new ApiError(409, "DUPLICATE_NAME"));
    const user = userEvent.setup();
    render(<CreateCategoryForm tree={tree} onCreate={onCreate} />);
    await user.type(screen.getByLabelText("Nom"), "X");
    await user.click(screen.getByRole("button", { name: "Créer la catégorie" }));
    expect(await screen.findByText("Valeur invalide.")).toBeInTheDocument();
    expect(screen.getByText("Certaines informations sont invalides.")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: "Créer la catégorie" }));
    expect(await screen.findByText("Ce nom existe déjà dans cette catégorie parente.")).toBeInTheDocument();
  });
});

describe("EditCategoryForm", () => {
  const category = tree[0].children![0];

  it("sends only the fields that changed (PATCH)", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<EditCategoryForm category={category} onSave={onSave} />);
    await user.click(screen.getByLabelText("Catégorie active"));
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    await waitFor(() => expect(onSave).toHaveBeenCalledWith("plomb", { active: false }));
  });

  it("does nothing when nothing changed", async () => {
    const onSave = vi.fn();
    const user = userEvent.setup();
    render(<EditCategoryForm category={category} onSave={onSave} />);
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    expect(onSave).not.toHaveBeenCalled();
  });

  it("explains CATEGORY_IN_USE", async () => {
    const onSave = vi.fn().mockRejectedValue(new ApiError(409, "CATEGORY_IN_USE"));
    const user = userEvent.setup();
    render(<EditCategoryForm category={category} onSave={onSave} />);
    await user.click(screen.getByLabelText("Catégorie active"));
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    expect(await screen.findByText("Cette catégorie est utilisée : elle ne peut pas être désactivée.")).toBeInTheDocument();
  });
});

describe("EditCategoryForm: reactivation (D35)", () => {
  const inactive: Category = { id: "plomb", name: "Plomberie", order: 1, active: false, family: "Domicile", minVerificationLevel: "N1" };

  it("shows an inactive category unchecked and reactivates it by sending only active: true", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<EditCategoryForm category={inactive} onSave={onSave} />);
    expect(screen.getByLabelText("Catégorie active")).not.toBeChecked();
    await user.click(screen.getByLabelText("Catégorie active"));
    await user.click(screen.getByRole("button", { name: "Enregistrer" }));
    await waitFor(() => expect(onSave).toHaveBeenCalledWith("plomb", { active: true }));
  });
});

describe("CreateCategoryForm: parents offered (D35)", () => {
  const mixed: Category[] = [
    {
      id: "dom", name: "Domicile", order: 1, active: true, family: "Domicile", minVerificationLevel: "N0",
      children: [{ id: "plomb", name: "Plomberie", order: 1, active: false, family: "Domicile", minVerificationLevel: "N1" }],
    },
    {
      id: "trav", name: "Travaux", order: 2, active: false, family: "Travaux", minVerificationLevel: "N0",
      children: [{ id: "mac", name: "Maçonnerie", order: 1, active: true, family: "Travaux", minVerificationLevel: "N0" }],
    },
  ];

  it("does not offer an inactive category, nor anything under it, as a parent", () => {
    render(<CreateCategoryForm tree={mixed} onCreate={vi.fn()} />);
    const parent = screen.getByRole("combobox", { name: messages.category.fields.parent.label });
    const offered = within(parent).getAllByRole("option").map((o) => o.textContent ?? "");
    expect(offered.some((l) => l.includes("Domicile"))).toBe(true);
    for (const hidden of ["Plomberie", "Travaux", "Maçonnerie"]) {
      expect(offered.some((l) => l.includes(hidden))).toBe(false);
    }
  });
});

describe("AddAttributeForm", () => {
  it("asks for options only for the List type and requires them", async () => {
    const onAdd = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<AddAttributeForm onAdd={onAdd} />);
    expect(screen.queryByLabelText("Valeurs possibles")).toBeNull();

    await user.type(screen.getByLabelText("Nom"), "Etat");
    await user.selectOptions(screen.getByLabelText("Type de valeur"), "Liste");
    await user.click(screen.getByRole("button", { name: "Ajouter" }));
    expect(screen.getByText("Indiquez au moins une valeur pour une liste.")).toBeInTheDocument();
    expect(onAdd).not.toHaveBeenCalled();

    await user.type(screen.getByLabelText("Valeurs possibles"), "Neuf, Occasion");
    await user.click(screen.getByLabelText("Obligatoire"));
    await user.click(screen.getByRole("button", { name: "Ajouter" }));
    await waitFor(() =>
      expect(onAdd).toHaveBeenCalledWith({ name: "Etat", valueType: "Liste", required: true, options: "Neuf, Occasion" }),
    );
  });

  async function fillList(user: ReturnType<typeof userEvent.setup>, values: string) {
    await user.type(screen.getByLabelText("Nom"), "Etat");
    await user.selectOptions(screen.getByLabelText("Type de valeur"), "Liste");
    await user.type(screen.getByLabelText("Valeurs possibles"), values);
    await user.click(screen.getByRole("button", { name: "Ajouter" }));
  }

  it("cleans the spaces around each option before sending (D34)", async () => {
    const onAdd = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<AddAttributeForm onAdd={onAdd} />);
    await fillList(user, "  Neuf ,Occasion ");
    await waitFor(() =>
      expect(onAdd).toHaveBeenCalledWith({ name: "Etat", valueType: "Liste", required: false, options: "Neuf, Occasion" }),
    );
  });

  it("refuses an empty value and does not call the API", async () => {
    const onAdd = vi.fn();
    const user = userEvent.setup();
    render(<AddAttributeForm onAdd={onAdd} />);
    await fillList(user, "Neuf,,Occasion");
    expect(screen.getByText(messages.validation.optionsEmptyItem)).toBeInTheDocument();
    expect(onAdd).not.toHaveBeenCalled();
  });

  it("refuses a duplicate and names it", async () => {
    const onAdd = vi.fn();
    const user = userEvent.setup();
    render(<AddAttributeForm onAdd={onAdd} />);
    await fillList(user, "Neuf, Occasion, neuf");
    expect(screen.getByText("La valeur « neuf » est en double.")).toBeInTheDocument();
    expect(onAdd).not.toHaveBeenCalled();
  });

  it("never sends options for a type other than Liste", async () => {
    const onAdd = vi.fn().mockResolvedValue(undefined);
    const user = userEvent.setup();
    render(<AddAttributeForm onAdd={onAdd} />);
    await user.type(screen.getByLabelText("Nom"), "Marque");
    await user.selectOptions(screen.getByLabelText("Type de valeur"), "Liste");
    await user.type(screen.getByLabelText("Valeurs possibles"), "A, B");
    await user.selectOptions(screen.getByLabelText("Type de valeur"), "Texte");
    await user.click(screen.getByRole("button", { name: "Ajouter" }));
    await waitFor(() => expect(onAdd).toHaveBeenCalledWith({ name: "Marque", valueType: "Texte", required: false }));
  });
});


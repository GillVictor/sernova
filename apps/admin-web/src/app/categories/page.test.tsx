import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import type { ApiClient, AttributeDefinition, Category } from "@/lib/api/client";
import { SessionProvider } from "@/lib/session";
import CategoriesPage from "./page";

vi.mock("next/navigation", () => ({ useRouter: () => ({ replace: vi.fn() }) }));
vi.mock("next/link", () => ({
  default: ({ href, children }: { href: string; children: React.ReactNode }) => <a href={href}>{children}</a>,
}));

const tree: Category[] = [
  {
    id: "dom", name: "Domicile", order: 1, active: true, family: "Domicile", minVerificationLevel: "N0",
    children: [
      { id: "plomb", name: "Plomberie", order: 1, active: true, family: "Domicile", minVerificationLevel: "N0" },
      { id: "menage", name: "Ménage", order: 2, active: true, family: "Domicile", minVerificationLevel: "N0" },
    ],
  },
];
const attr = (id: string, name: string): AttributeDefinition => ({ id, name, valueType: "Texte", required: false });

type AttributesLoader = (id: string) => Promise<AttributeDefinition[]>;

const defaultAttributes: AttributesLoader = async (id) =>
  id === "plomb" ? [attr("a1", "Diamètre")] : [attr("a2", "Surface")];

function setup(loader: AttributesLoader = defaultAttributes) {
  const client = {
    listCategories: vi.fn().mockResolvedValue(tree),
    categoryAttributes: vi.fn<AttributesLoader>(loader),
    createCategory: vi.fn().mockResolvedValue({}),
    updateCategory: vi.fn().mockResolvedValue({}),
    addAttribute: vi.fn().mockResolvedValue({}),
  };
  render(
    <SessionProvider client={client as unknown as ApiClient} initialAuthenticated>
      <CategoriesPage />
    </SessionProvider>,
  );
  return client;
}

describe("categories page", () => {
  it("shows the attributes of the selected category and not those of the previous one", async () => {
    const user = userEvent.setup();
    let release!: (list: AttributeDefinition[]) => void;
    const client = setup();
    await screen.findByText("Plomberie");

    await user.click(screen.getByRole("button", { name: "Plomberie" }));
    expect(await screen.findByText(/Diamètre/)).toBeInTheDocument();

    // The next category answers late: meanwhile the old list must be gone.
    client.categoryAttributes.mockImplementationOnce(() => new Promise<AttributeDefinition[]>((resolve) => (release = resolve)));
    await user.click(screen.getByRole("button", { name: "Ménage" }));
    expect(screen.queryByText(/Diamètre/)).toBeNull();
    expect(screen.getByText("Chargement…")).toBeInTheDocument();

    release([attr("a2", "Surface")]);
    expect(await screen.findByText(/Surface/)).toBeInTheDocument();
  });

  it("clears the success message when another category is selected", async () => {
    const user = userEvent.setup();
    setup();
    await screen.findByText("Plomberie");

    const form = screen.getByRole("form", { name: "Nouvelle catégorie" });
    await user.type(within(form).getByLabelText("Nom"), "Jardinage");
    await user.click(within(form).getByRole("button", { name: "Créer la catégorie" }));
    expect(await screen.findByRole("status")).toHaveTextContent("Catégorie créée.");

    await user.click(screen.getByRole("button", { name: "Plomberie" }));
    await waitFor(() => expect(screen.queryByRole("status")).toBeNull());
  });

  it("shows a French error when the attributes cannot be loaded", async () => {
    const user = userEvent.setup();
    setup(() => Promise.reject(new TypeError("offline")));
    await screen.findByText("Plomberie");
    await user.click(screen.getByRole("button", { name: "Plomberie" }));
    expect(await screen.findByText("Une erreur est survenue. Réessayez.")).toBeInTheDocument();
  });
});

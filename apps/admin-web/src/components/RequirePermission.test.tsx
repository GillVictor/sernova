import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { RequirePermission } from "./RequirePermission";
import { messages } from "@/i18n";

describe("RequirePermission", () => {
  it("shows the content when the permission is granted", () => {
    render(<RequirePermission permissions={["categories.manage"]} code="categories.manage">contenu</RequirePermission>);
    expect(screen.getByText("contenu")).toBeInTheDocument();
  });

  it("shows a French denial instead of the content when the permission is missing", () => {
    render(<RequirePermission permissions={["journal.read"]} code="categories.manage">contenu</RequirePermission>);
    expect(screen.queryByText("contenu")).toBeNull();
    expect(screen.getByRole("alert")).toHaveTextContent(messages.permissions.denied);
  });

  it("shows a loading message, not the content, while permissions are not loaded", () => {
    render(<RequirePermission permissions={null} code="categories.manage">contenu</RequirePermission>);
    expect(screen.queryByText("contenu")).toBeNull();
    expect(screen.queryByRole("alert")).toBeNull();
    expect(screen.getByText(messages.permissions.loading)).toBeInTheDocument();
  });
});

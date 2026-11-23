import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { TextField } from "./TextField";
import { messages } from "@/i18n";

describe("help tooltip on every input", () => {
  it("shows the French help on keyboard focus and hides it when focus leaves", async () => {
    const user = userEvent.setup();
    render(<TextField form="login" name="phone" />);
    expect(screen.queryByRole("tooltip")).toBeNull();

    await user.tab(); // the help button comes first in the tab order (label row)
    expect(screen.getByRole("tooltip")).toHaveTextContent(messages.login.fields.phone.help);

    await user.tab(); // focus moves to the input
    expect(screen.queryByRole("tooltip")).toBeNull();
  });

  it("Escape dismisses the tooltip while focus stays on the button (WCAG 1.4.13)", async () => {
    const user = userEvent.setup();
    render(<TextField form="login" name="phone" />);
    await user.tab();
    expect(screen.getByRole("tooltip")).toBeInTheDocument();

    await user.keyboard("{Escape}");
    expect(screen.queryByRole("tooltip")).toBeNull();
    expect(screen.getByRole("button", { name: /Aide sur le champ/ })).toHaveFocus();
  });

  it("reopens after Escape when focus leaves and comes back", async () => {
    const user = userEvent.setup();
    render(<TextField form="login" name="phone" />);
    await user.tab();
    await user.keyboard("{Escape}");
    await user.tab(); // to the input
    await user.tab({ shift: true }); // back to the button
    expect(screen.getByRole("tooltip")).toBeInTheDocument();
  });

  it("Escape also closes a tooltip opened by a click", async () => {
    const user = userEvent.setup();
    render(<TextField form="login" name="phone" />);
    await user.click(screen.getByRole("button", { name: /Aide sur le champ/ }));
    expect(screen.getByRole("tooltip")).toBeInTheDocument();
    await user.keyboard("{Escape}");
    expect(screen.queryByRole("tooltip")).toBeNull();
  });

  it("opens on click for touch screens and links the tooltip with aria-describedby", async () => {
    const user = userEvent.setup();
    render(<TextField form="login" name="password" type="password" />);
    const button = screen.getByRole("button", { name: /Aide sur le champ « Mot de passe »/ });
    await user.click(button);
    expect(button).toHaveAttribute("aria-expanded", "true");
    expect(button.getAttribute("aria-describedby")).toBe(screen.getByRole("tooltip").id);
  });

  it("displays the field error accessibly", () => {
    render(<TextField form="login" name="phone" error="Ce champ est obligatoire." />);
    expect(screen.getByRole("textbox")).toHaveAccessibleDescription("Ce champ est obligatoire.");
  });
});

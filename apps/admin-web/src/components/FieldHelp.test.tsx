import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { TextField } from "./TextField";
import { messages } from "@/i18n";

describe("help tooltip on every input", () => {
  it("shows the French help on focus and hides it on Escape", async () => {
    const user = userEvent.setup();
    render(<TextField name="phone" />);
    expect(screen.queryByRole("tooltip")).toBeNull();

    await user.tab(); // the help button comes first in the tab order (label row)
    expect(screen.getByRole("tooltip")).toHaveTextContent(messages.login.fields.phone.help);

    await user.keyboard("{Escape}");
    // still focused: tooltip stays available through focus, so blur to close it
    await user.tab();
    expect(screen.queryByRole("tooltip")).toBeNull();
  });

  it("opens on click for touch screens and links the tooltip with aria-describedby", async () => {
    const user = userEvent.setup();
    render(<TextField name="password" type="password" />);
    const button = screen.getByRole("button", { name: /Aide sur le champ « Mot de passe »/ });
    await user.click(button);
    expect(button).toHaveAttribute("aria-expanded", "true");
    expect(button.getAttribute("aria-describedby")).toBe(screen.getByRole("tooltip").id);
  });

  it("displays the field error accessibly", () => {
    render(<TextField name="phone" error="Ce champ est obligatoire." />);
    expect(screen.getByRole("textbox")).toHaveAccessibleDescription("Ce champ est obligatoire.");
  });
});

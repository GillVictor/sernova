"use client";

import { useEffect, useId, useRef, useState } from "react";
import { t } from "@/i18n";

interface FieldHelpProps {
  /** Field label, used for the accessible name of the button. */
  fieldLabel: string;
  /** Help text (already translated). */
  text: string;
}

/**
 * Help tooltip for an input. Opens on hover, focus or click/tap (touch),
 * closes on Escape or outside click. Reachable by keyboard and screen reader.
 */
export function FieldHelp({ fieldLabel, text }: FieldHelpProps) {
  const [pinned, setPinned] = useState(false);
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const tooltipId = useId();
  const root = useRef<HTMLSpanElement>(null);
  const open = pinned || hovered || focused;

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setPinned(false);
        setHovered(false);
      }
    };
    const onPointer = (e: PointerEvent) => {
      if (root.current && !root.current.contains(e.target as Node)) setPinned(false);
    };
    document.addEventListener("keydown", onKey);
    document.addEventListener("pointerdown", onPointer);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("pointerdown", onPointer);
    };
  }, [open]);

  return (
    <span
      ref={root}
      className="field-help"
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
    >
      <button
        type="button"
        className="field-help__button"
        aria-label={t("common.helpButtonLabel", { field: fieldLabel })}
        aria-describedby={open ? tooltipId : undefined}
        aria-expanded={open}
        onClick={() => setPinned((p) => !p)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
      >
        ?
      </button>
      {open && (
        <span role="tooltip" id={tooltipId} className="field-help__bubble">
          {text}
        </span>
      )}
    </span>
  );
}

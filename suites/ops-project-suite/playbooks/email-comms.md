# Playbook — Email & Comms

Version: 0.2 (kit copy 2026-09-16) · Last updated: 2026-09-16

## Non-negotiables

- **Nothing is ever sent without the owner's explicit OK on the final text.** Draft → the
  owner reviews → send. Create drafts, never send directly, even when a send tool is
  available.
- **Drafts sound like the owner's voice** — learn it from the About me section of their
  rules file and any samples they give: plain, direct, no corporate filler, short
  paragraphs. If a writing-style skill/profile exists, use it; otherwise mirror their
  emails in `supporting-evidence/` before drafting.

## Audience patterns

Organisation-specific audience mappings live in the domain layer (e.g.
`~/developer/playbooks/<organisation>-comms-patterns.md` — an optional domain-layer note
the project may name) — load the one the project names. The generic shapes:

- **Internal actioners** (staff who must do something): lead with the decision and the
  date it takes effect, then the one-line rationale, then exactly what the recipient must
  do and by when (deadline + the default if they don't respond). Attach or link the
  source doc — don't restate its contents.
- **External recipients** (clients, families, counterparties): lead with reassurance and
  the practical effect, plain numbers, no internal jargon, a named contact for questions.
- **Escalations/reminders:** reference the original ask + deadline, state the default
  about to apply, keep it two sentences.

## Evidence handling

- Inbound mail that justifies a decision is evidence: save as `.eml` (or PDF) to
  `supporting-evidence/` under `<who>-<what>-<n>`, and cite the filename wherever the
  decision is recorded (sheet comment, proposals register).
- Quotes pulled from emails into registers are **verbatim** — square-bracket any edits.

## Mass/comms exercises

- One master text per audience, per-recipient variables in a table, spot-check 2–3
  renders before the owner's sign-off on the batch.
- Log the send (who, when, what version) in the project changelog.

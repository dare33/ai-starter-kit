# Playbook — Excel / Word Operations

Version: 0.6 (kit copy 2026-09-16) · Last updated: 2026-09-16
Gotcha detail lives in `<projects folder>/lessons/excel.md` and
`<projects folder>/lessons/office-files.md` — read those when something breaks.

## Safety card (the 5 lines projects inline into their CLAUDE.md)

1. **Back up first** — dated copy to `working-docs/temp/` before touching any Office file.
2. **Edit on a sandbox-local copy**, never in place on a cloud-synced mount.
3. **Normalise after programmatic edits:** if LibreOffice is installed
   (`/Applications/LibreOffice.app` or `soffice` on PATH), `soffice --headless
   --convert-to xlsx` — raw openpyxl saves strip dropdowns/CF and can break Table-bearing
   files. If not installed, ask once before the first edit whether to install it
   (`brew install --cask libreoffice`); if declined, don't script edits to workbooks —
   work through a copy opened and saved in Excel/Numbers, and note it in `prompt.md`.
4. **Verify before delivering:** formulas, values, charts, validation survived; 0 errors.
5. **"BadZipFile" on a Drive mount = cold read mid-sync, NOT corruption** — hydrate
   (`cat file > /dev/null`), wait, retry; never overwrite from a snapshot.

## Core workflow

- **Declare sources read-only.** Anything returned by someone else (per-owner or per-unit
  workbooks) is never edited or re-saved; values are read out and written into the master.
  Name both in the project's KEY RULES.
- **Once a user has begun editing a workbook** (approvals, dropdowns, CF, charts present):
  no openpyxl round-trips — edit cells by surgical XML (unzip → edit `sheetN.xml` → rezip).
- **Rebuild scripts must read-and-preserve user columns.** Never re-run a builder that
  clears a user-filled column.
- **Confirm the target workbook** (source vs rollup vs master) before building anything.

## Merge / consolidation protocol

Two sanctioned modes — the owner picks per instruction. (A forbidding rule that's
routinely violated breeds drift; define the safe version instead.)

- **Unit mode (default):** merge one unit at a time (one owner or entity — whatever the
  exercise's natural unit is), each on the owner's explicit confirmation in chat naming
  the authoritative file.
- **Bulk mode (on explicit instruction, e.g. "merge all"):** allowed, with mandatory
  safeguards — pre-merge master backup; per-unit QA line in `verification-log.md` (rows
  in vs out, formula errors, anomalies — bulk mode switches verification logging ON at
  **any** stakes level; create it on first bulk instruction if absent);
  anomalies **flagged, never silently fixed**; everything bulk-merged is **review-pending**
  until reviewed (surface an approval column or exceptions tab).
- **In-flight state during a bulk run lives in the verification-log ONLY.** At bulk start,
  `prompt.md` "Where we are" gets one line — "bulk run in flight since <when>;
  authoritative progress: `verification-log.md` tail" — and is NOT rewritten per unit.
  A resumed session reads the ledger tail for where the run stopped (one fact, one home).
- Sequence either way: back up master → migrate only the agreed columns, matched on a
  stable key → recalc → verify summaries → one changelog line with backup path and
  verification result.
- **Parallelize checks, never writes.** Per-unit QA checks are independent — fan out via
  subagents on large runs. Writes to the master stay strictly serial: one writer, ever.
- Anything merged before confirmation carries a **PROVISIONAL** flag that only the
  owner's confirmation removes.

## File discipline

- Pre-named files from day one: `<exercise>-<who>-v<n>.xlsx`; a superseded version moves
  to `temp/superseded/` the moment its successor is authoritative — the folder must never
  contain two plausible candidates.
- Evidence to `working-docs/supporting-evidence/` named `<who>-<what>-<n>.<ext>`; check
  returned docs for **embedded images** (screenshots don't extract as text).
- Roll-up weighting, baseline cell, and cap rules →
  `playbooks/financial-analysis.md`.

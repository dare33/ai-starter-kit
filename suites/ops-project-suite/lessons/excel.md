# Excel lessons

What this is: cross-project Excel/openpyxl gotchas, appended as they're learned.

Office-file internals (ZIP recovery, docx/pdf extraction) — see office-files.md.

## Editing workbooks with Tables (ListObjects) can make Excel refuse to open the file
Libraries like `openpyxl` re-serialise the package in a way Excel rejects - especially when
you *add a sheet* - even though `openpyxl` and LibreOffice still open it (which hides the
problem). Prevention: after any programmatic edit, normalise through LibreOffice, which
rewrites a clean, Excel-valid package:
`soffice --headless --convert-to xlsx --outdir <out> <file>`, then verify formulas survived.

## LibreOffice headless is a great "repair + convert" tool
The same `--convert-to xlsx` normalises a broken file; `--convert-to pdf` renders for visual
QA. First reach for "why won't Excel open this."

## External workbook links fail silently
`=VLOOKUP(...,[1]Sheet!...)` keeps its last cached values, so the file *looks* fine until
someone edits/refreshes - then #REF or an "update links?" prompt. Detect by scanning formulas
for `[n]` references; fix by repointing to an internal sheet or hard-coding stable identifiers.

## Join on stable IDs, never on names
Names drift across sheets ("Riverside" appears as "Rvrside", "Hillcrest" as "Hill Crest"),
silently breaking VLOOKUP/INDEX-MATCH. Match on codes/IDs. If a lookup only has the name and
the name isn't reliable, hard-code the immutable ID instead.

## openpyxl drops cached formula results on save
Reading back with `data_only=True` then returns `None` until Excel/LibreOffice recalculates.
Set recalc-on-open (`wb.calculation.fullCalcOnLoad = True`) and verify the formula logic
*independently* (e.g. replicate the AVERAGEIFS in Python) rather than trusting cached values.

## Manually-set row heights clip wrapped text
Excel won't auto-grow a row whose height you set explicitly, so wrapped cells get cut off.
Either leave height unset (auto-fit) or compute it from content
(~ `ceil(len(text)/chars_per_col_width) * ~13pt`).

## Back up + visually render before delivering
Always back up before a programmatic edit, and do a visual render (xlsx -> PDF -> image) to
catch layout/clipping before delivering.

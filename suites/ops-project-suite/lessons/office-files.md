# Office & PDF file-handling lessons

What this is: cross-project lessons on Office/PDF file internals — ZIP recovery,
sync-artifact detection, and text/table extraction, appended as they're learned.

Excel editing/formula gotchas — see excel.md.

## Office files are ZIP archives
`.xlsx` / `.docx` / `.pptx` are ZIPs - unzip to inspect/modify the raw XML; embedded images
live in `word/media/`, `xl/media/`, etc.

## A truncated ZIP missing its central directory is often recoverable
If the local file headers (`PK\x03\x04`) are intact, walk them, inflate each member with
`zlib.decompress(data, -15)`, and repack with `zipfile` - rebuilt a "corrupt" xlsx this way
with zero data loss. (`zip -FF` also fixes truncated archives but prompts interactively -
script-unfriendly.)

## Stable checksum + the user sees a working file = sync artifact, not real corruption
If your copy is byte-identical every read but the user opens it fine, the file-sync layer
served a stale/partial copy. Ask the user to re-save (or Save As a new name) to force a fresh
sync.

## Intermittent "BadZipFile / not a zip file" on a Google Drive file = a cold read mid-sync
Files under Google Drive for Desktop reach a sandbox via a `fuse` mount as cloud-backed
placeholders (tell: `alloc_blocks=0`, byte size changing between turns with no write). At a turn
boundary the mount re-syncs; a *cold* read landing mid-sync returns a truncated stream that
openpyxl rejects as "not a zip file". It is intermittent and self-heals - the same file opens
fine seconds later. Do **not** assume the user has the file open in Excel, and do **not**
overwrite from a snapshot (risks clobbering real edits). Fix: force-hydrate (full read /
`cat file > /dev/null`), wait ~1-2s, retry a few times before concluding anything; edit on a
sandbox-local copy and copy the verified result back. (Distinct from the stable-checksum sync
artifact above: there the read is *consistent* but stale; here it's an *intermittent* truncation.)

## `~$filename` lock files are harmless
A leftover `~$filename` (Office lock file) usually just holds a username; it can be deleted if
the app is closed.

## Text extraction misses images
Survey screenshots / forwarded emails pasted as pictures won't come out of `python-docx`
paragraph text. Extract them from the archive's media folder and view/transcribe - always
check for embedded images when "capturing everything."

## Text extraction misses TABLES too - and it fails silently
A paragraph-only `.docx` read walks `w:p` and never enters `w:tbl`, so anything the author put
in a table vanishes with no error. Costly when the table is where the *numbers* are: in a 2026
questionnaire return, every dollar figure and date sat in a table while the prose held only
narrative, so a paragraph read would have produced a confident, complete-looking extract with
all the evidence missing. Iterate `w:tbl` -> `w:tr` -> `w:tc` as well as `w:p`
(`xml.etree` on `word/document.xml`, no Word process needed). **Tell for this class of bug:**
an extract that reads fluently but contains no figures - check the source for tables before
concluding the author didn't give you any.

## PDF text vs image
`pdfplumber` pulls text from digital PDFs; scans, charts, and screenshot-based pages are
images - render the page (`pdftoppm -jpeg`) and read it visually. Big file size is a tell that
a PDF is mostly images.

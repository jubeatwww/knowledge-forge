# AGENTS

## Vault Role
This vault is a local knowledge layer built from Notion-originated material.

## Reading Priority
When answering questions or building context, prefer reading in this order:
1. `06_skills/`
2. `07_context-packs/`
3. `04_playbooks/`
4. `03_notes/`
5. `01_hubs/`
6. `02_sources/`
7. `90_cache/`

## Source Rules
- Notion is the source of truth for raw material.
- Files under `90_cache/` are generated snapshots and should not be edited manually.
- Files under `02_sources/` are indexes/stubs, not final knowledge.
- Files under `03_notes/` and `04_playbooks/` are curated knowledge and should be preferred.

## Writing Rules
- Do not overwrite generated cache.
- When creating a new knowledge file, place it in the narrowest correct folder.
- Prefer small, single-purpose notes.
- Link related notes explicitly.

## Navigation Hints
- Use `INDEX.md` for the high-level map.
- Use files in `01_hubs/` to enter a domain.
- Use `06_skills/` when a focused topic pack is needed.

## Sync Model
- Some source files only contain metadata and source links.
- Full content may exist only in `90_cache/` or upstream Notion.
- When context is insufficient, identify the related source file first, then hydrate or sync on demand.
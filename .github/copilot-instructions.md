# TriWallet – Project Rules

## Stack
- Flutter, Dart 3.x, Riverpod 2.x, Isar (offline-first), csv, pdf, printing, path_provider, share_plus

## Non-negotiable rules
- Currencies LAK, THB, USD are fully isolated. NEVER convert or calculate cross-rates.
- Money is stored as int (minor units). Never use double for money.
- Layers: UI -> Riverpod providers -> Repository -> Isar. UI must not access Isar directly.
- UI labels and PDF text are in Lao. Keep the exact strings from docs/SPEC.md.
- Lao PDF text needs a bundled Lao-capable TTF font (NotoSansLao).

## Working style
- Read docs/SPEC.md and PROGRESS.md before writing code.
- Only implement the current step in PROGRESS.md. Do not touch unrelated files.
- Don't rename or restructure existing files unless asked.
- After finishing a step, update PROGRESS.md and stop. Do not start the next step.
- After model changes, remind me to run: dart run build_runner build
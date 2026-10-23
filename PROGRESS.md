# Progress

## Current step
Step 8: CSV + PDF export

## Done
- [x] Step 1: project setup, pubspec.yaml, folder structure
- [x] Step 2: Isar model + repository (currency-filtered queries)
- [x] Step 3: Riverpod providers
- [x] Step 4: Dashboard (3 wallet cards + filter)
- [x] Step 5: Quick Add
- [x] Step 6: History (free-text categories)
- [x] Step 7: Analytics charts (currency-filtered)

## Todo
- [ ] Step 8: CSV + PDF export
- [ ] Step 9: Unit tests

## Notes / decisions
- Amount stored as int (satang / cents / kip)
- Added required Flutter dependencies and a minimal app entry point because the
  Step 1 setup files were missing from the workspace.
- WalletTransaction indexes currency and date; summaries use only the selected
  currency and integer arithmetic.
- Isar code generation and Flutter analysis completed successfully.
- Added period-based summaries using Isar integer aggregates and Riverpod
  family stream providers; the Isar repository is overridden in main.
- Added LAK, THB, and USD summary cards with period-specific balances and a
  currency visibility filter. Summary values remain isolated per currency.
- Added Quick Add with currency/type selection, integer-only amount parsing,
  required category validation, date/note fields, and repository-backed saving.
- Dashboard summary cards continue watching Isar changes and update after saves.
- Added newest-first transaction history with currency filters and confirmed
  swipe-to-delete.
- categories removed per user decision, category is free text.
- Completed CSV and PDF export with currency/range selection, dashboard
  navigation, per-currency PDF balances, and debug sample generation.
- Confirmed all font assets declared in pubspec.yaml exist. Step 9 has not been
  started.
- Switched the app UI and PDF export to the bundled Phetsarath OT font at the
  user's request.
- Reworked PDF pages to rasterized Flutter widgets for Lao shaping; Step 8
  awaits the user's screenshot confirmation.
- Configured the legacy Isar Android library with a namespace and compatible
  compile SDK; disabled Kotlin incremental compilation to avoid Windows
  cross-drive cache failures between the project and Pub cache.
# TriWallet

TriWallet is an offline-first Flutter wallet for LAK, THB, and USD. Currency
balances are kept separate; the app does not perform currency conversion.

## Development

The project uses Flutter and Dart 3. Generate Isar model code after changing
the persisted models:

```sh
flutter pub get
dart run build_runner build
flutter test
```
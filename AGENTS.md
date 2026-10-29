# AGENTS.md

Flutter (Android) marketplace + gig app. Package name is `marketplace_gig` (imports use `package:marketplace_gig/...`).

Full architecture notes: read `CLAUDE.md`. Trust code and `README.md` over `docs/` — `docs/` describes an obsolete Supabase backend.

## Commands

```bash
flutter analyze                                   # must stay clean
flutter test                                      # all tests, run fully offline
flutter test test/radial_menu_test.dart           # single file
flutter test --plain-name "expands a branch"      # single test
dart run build_runner build --delete-conflicting-outputs   # after editing lib/data/local/tables.dart
dart format lib test

flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy  # uploads fail without these
flutter run -t lib/previews/preview_main.dart     # design previews, no Firebase needed
firebase deploy --only firestore:rules,firestore:indexes
```

Verify with `flutter analyze` → `flutter test`. There is no CI; run both yourself before claiming done. `.vscode/launch.json` already carries the Cloudinary dart-defines.

## Testing

Widget tests must not touch Firebase. Follow `test/widget_test.dart`: override `appDatabaseProvider` (in-memory Drift), `firebaseInitProvider`, `authGatewayProvider`, and repository providers with `Local*Repository`. Find semantics-only nodes with `find.semantics.byLabel`, not `find.bySemanticsLabel`.

call flutter pub get
call flutter pub run intl_utils:generate
mkdir lib\generated\l10n
dir .\lib\*.dart /b/s > lib\generated\l10n\file-list.txt
dir .\assets\l10n\*.arb /b/s > lib\generated\l10n\translations-list.txt
call flutter pub run intl_translation:generate_from_arb --sources-list-file .\lib\generated\l10n\file-list.txt --translations-list-file .\lib\generated\l10n\translations-list.txt --output-dir=lib/generated/l10n
call flutter pub run build_runner build
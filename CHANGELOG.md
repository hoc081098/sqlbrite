## 2.6.0 - Jan 28, 2023

*   Update dependencies: `sqflite: ^2.2.4`. Because `sqflite` does not follow semantic versioning, this is a breaking change.

## 2.5.1 - Jan 25, 2023

*   Update dependencies
    * `sqflite: ^2.2.3` (implements `Batch.length`).

## 2.5.0 - Nov 2, 2022

*   Update dependencies
    * `sqflite: ^2.2.0+3` (implements `Database.queryCursor()` and `Database.rawQueryCursor()`).

## 2.4.0 - Oct 1, 2022

*   Update dependencies
    * `sqflite: ^2.1.0`.

*   Update `Dart SDK` constraint to `'>=2.18.0 <3.0.0'` and `Flutter` constraint to `'>=3.3.0'`.

## 2.3.0 - Jul 31, 2022

*   Update dependencies
    * `rxdart_ext: ^0.2.5` (~ `rxdart: ^0.27.5`).
    * `sqflite: ^2.0.3`.

*   Update `Dart SDK` constraint to `'>=2.16.0 <3.0.0'` and `Flutter` constraint to `'>=3.0.0'`.

## 2.2.0 - Sep 22, 2021

*   Update dependencies
    * `rxdart_ext` to `0.1.2`
    * `sqflite` to `2.0.0+4`
    * `meta` to `1.7.0`
    * `rxdart` to `0.27.2`

*   Change sdk constraint `>=2.14.0 <3.0.0` and flutter constraint `>=2.5.0`.
*   Migrated from `pedantic` to `flutter_lints`.
*   Updated example.

## 2.1.0 - May 13, 2021

*   Update `rxdart` to `0.27.0`.

## 2.0.0 - Apr 01, 2021

*   Stable release for null safety.

## 2.0.0-nullsafety.0 - Feb 28, 2021

*   **Breaking**
    -   Opt into _nullsafety_.
    -   Set Dart SDK constraints to `>=2.12.0-0 <3.0.0`.
    -   `mapToOne` now emits a `StateError` when result sets has 0 rows.
    -   `BriteDatabase constructor` now accepts `BriteDatabaseLogger? logger` instead of `bool isLoggerEnabled`.

## 1.4.0 - July 6, 2020

*   **Breaking change**: returned stream is a **_single-subscription_** stream.
*   Allow disable/enable logger (via `_isLoggerEnabled` optional parameter in `BriteDatabase` constructor).

## 1.3.0 - Apr 29, 2020

*   Breaking change: support for `rxdart` 0.24.x.
*   Breaking change: support for `sqflite` 1.3.x
*   Now, returned query stream is a broadcast stream.
*   Internal implementation refactor.

## 1.2.0 - Feb 04, 2020

*   Update dependencies: `rxdart`, `sqflite`.

*   Add more documents for public API.

*   Fix some bugs.

*   Upgrade dart `minsdk` to `2.6.0` with extension method feature.

*   Refactor internal implementations.

## 1.1.0 - May 04, 2019

*   Add document for public API.

*   Fix error when call method `mapToOne` and `mapToList`.

*   Minor changes.

## 1.0.1 - May 03, 2019

*   Update `rxdart` dependency, fix error when call method `mapToOne` and `mapToList`.

## 1.0.0 - May 03, 2019

*   Initial release.

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

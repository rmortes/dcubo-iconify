# DCubo Iconify

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

Main package needed to use all other Iconify icons in your project

## Installation 💻

**❗ In order to start using Dcubo Iconify you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Install via `flutter pub add`:

```sh
dart pub add dcubo_iconify
```

## Companion Packages

To use any icon set, you need to install a companion package. For example:

```sh
dart pub add dcubo_iconify_academicons
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:dcubo_iconify/dcubo_iconify.dart';
import 'package:dcubo_iconify_material_symbols/dcubo_iconify_material_symbols.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Iconify Example'),
        ),
        body: const Center(
          child: Iconify(
            IconifyMaterialSymbolsIconSet.thumbUpRounded,
            color: Colors.blue,
            size: 48,
          ),
        ),
      ),
    );
  }
}
```
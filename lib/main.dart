import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  // Necesario antes de usar plugins (como camera, image_picker) al arrancar.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RumbaApp());
}

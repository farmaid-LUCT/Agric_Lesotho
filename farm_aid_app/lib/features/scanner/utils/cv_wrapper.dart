import 'package:flutter/foundation.dart';
// We'll create these two files next
import 'cv_stub.dart' 
  if (dart.library.io) 'cv_desktop_mobile.dart' 
  if (dart.library.html) 'cv_web.dart';

abstract class CVProcessor {
  void processImage(String path);
}
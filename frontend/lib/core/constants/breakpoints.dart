import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double mobile = 768.0;
  static const double tablet = 1024.0;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile;
  }
}

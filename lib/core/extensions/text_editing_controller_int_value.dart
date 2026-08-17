import 'package:flutter/widgets.dart';

extension TextEditingControllerIntValue on TextEditingController {
  int? get intValue => int.tryParse(text.trim());
}

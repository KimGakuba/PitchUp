import 'package:intl/intl.dart';

final _rwfFormat = NumberFormat.decimalPattern('en_US');

/// Formats an integer RWF amount, e.g. `20000` -> `"20,000 RWF"`.
/// RWF has no minor unit — every amount in this app is a whole integer.
String formatRwf(int amount) => '${_rwfFormat.format(amount)} RWF';

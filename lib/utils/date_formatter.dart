import 'package:timeago/timeago.dart' as timeago;
 
class DateFormatter {
  static String format(DateTime date) {
    return timeago.format(date);
  }
} 
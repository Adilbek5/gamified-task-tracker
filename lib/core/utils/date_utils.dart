class AppDateUtils {
  static bool isOverdue(DateTime d) => DateTime.now().isAfter(d);
  static bool isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
  static bool isUpcoming(DateTime d) => !isToday(d) && !isOverdue(d);
}
class _timeMaths {
  String shortFormatDuration(int durationMilliseconds) {
    var duration = Duration(milliseconds: durationMilliseconds);
    if (duration.inDays >= 365) {
      return "${(duration.inDays / 365).floor()}y";
    } else if (duration.inDays >= 1) {
      return "${duration.inDays}d";
    } else if (duration.inHours >= 1) {
      return "${duration.inHours}h";
    } else if (duration.inMinutes >= 1) {
      return "${duration.inMinutes}m";
    } else {
      return "${duration.inSeconds}s";
    }
  }
}

_timeMaths timeMaths = _timeMaths();

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

  String SingleLongFormatDuration(int durationMilliseconds) {
    var duration = Duration(milliseconds: durationMilliseconds);
    if (duration.inDays >= 365) {
      final years = (duration.inDays / 365).floor();
      if (years < 2) {
        return "${years} year";
      } else {
        return "${years} years";
      }
    } else if (duration.inDays >= 1) {
      if (duration.inDays < 2) {
        return "${duration.inDays} day";
      } else {
        return "${duration.inDays} days";
      }
    } else if (duration.inHours >= 1) {
      if (duration.inHours < 2) {
        return "${duration.inHours} hour";
      } else {
        return "${duration.inHours} hours";
      }
    } else if (duration.inMinutes >= 1) {
      if (duration.inMinutes < 2) {
        return "${duration.inMinutes} minute";
      } else {
        return "${duration.inMinutes} minutes";
      }
    } else {
      if (duration.inSeconds < 2) {
        return "${duration.inSeconds} second";
      } else {
        return "${duration.inSeconds} seconds";
      }
    }
  }
}

_timeMaths timeMaths = _timeMaths();

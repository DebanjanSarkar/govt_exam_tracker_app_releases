enum ApplicationStatus {
  notApplied('Not Applied'),
  applied('Applied'),
  admitCardOut('Admit Card Out'),
  examGiven('Exam Given'),
  resultOut('Result Out'),
  archived('Archived');

  final String displayName;
  const ApplicationStatus(this.displayName);

  static ApplicationStatus fromString(String? status) {
    if (status == null) return ApplicationStatus.notApplied;
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('result')) return ApplicationStatus.resultOut;
    if (normalized.contains('given')) return ApplicationStatus.examGiven;
    if (normalized.contains('admit')) return ApplicationStatus.admitCardOut;
    if (normalized.contains('applied') && !normalized.contains('not')) {
      return ApplicationStatus.applied;
    }
    if (normalized.contains('archive')) return ApplicationStatus.archived;
    return ApplicationStatus.notApplied;
  }
}
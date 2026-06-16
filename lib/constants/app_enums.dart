enum ClassMode {
  onsite,
  synchronous,
  asynchronous,
}

extension ClassModeLabel on ClassMode {
  String get label {
    switch (this) {
      case ClassMode.onsite:
        return 'Onsite';
      case ClassMode.synchronous:
        return 'Synchronous';
      case ClassMode.asynchronous:
        return 'Asynchronous';
    }
  }

  String get value {
    switch (this) {
      case ClassMode.onsite:
        return 'onsite';
      case ClassMode.synchronous:
        return 'synchronous';
      case ClassMode.asynchronous:
        return 'asynchronous';
    }
  }

  static ClassMode fromValue(String value) {
    switch (value) {
      case 'onsite':
        return ClassMode.onsite;
      case 'synchronous':
        return ClassMode.synchronous;
      case 'asynchronous':
        return ClassMode.asynchronous;
      default:
        return ClassMode.onsite;
    }
  }
}

enum CourseType {
  lecture,
  lab,
  seminar,
  workshop,
}

extension CourseTypeLabel on CourseType {
  String get label {
    switch (this) {
      case CourseType.lecture:
        return 'Lecture';
      case CourseType.lab:
        return 'Lab';
      case CourseType.seminar:
        return 'Seminar';
      case CourseType.workshop:
        return 'Workshop';
    }
  }

  static CourseType? fromValue(String? value) {
    switch (value) {
      case 'Lecture':
        return CourseType.lecture;
      case 'Lab':
        return CourseType.lab;
      case 'Seminar':
        return CourseType.seminar;
      case 'Workshop':
        return CourseType.workshop;
      default:
        return null;
    }
  }
}

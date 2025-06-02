enum IncidentCategory {
  all,
  healthSafety,
  maintenance,
  it,
}

extension IncidentCategoryExtension on IncidentCategory {
  int get value {
    switch (this) {
      case IncidentCategory.all:
        return 1;
      case IncidentCategory.healthSafety:
        return 2;
      case IncidentCategory.maintenance:
        return 3;
      case IncidentCategory.it:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case IncidentCategory.all:
        return 'Non Applicable';
      case IncidentCategory.healthSafety:
        return 'Health & Safety';
      case IncidentCategory.maintenance:
        return 'Maintenance';
      case IncidentCategory.it:
        return 'IT';
    }
  }

  static IncidentCategory fromValue(int value) {
    switch (value) {
      case 1:
        return IncidentCategory.all;
      case 2:
        return IncidentCategory.healthSafety;
      case 3:
        return IncidentCategory.maintenance;
      case 4:
        return IncidentCategory.it;
      default:
        throw Exception('Invalid IncidentCategory value: $value');
    }
  }

  static IncidentCategory fromString(String value) {
    switch (value) {
      case 'None':
        return IncidentCategory.all;
      case 'healthSafety':
        return IncidentCategory.healthSafety;
      case 'maintenance':
        return IncidentCategory.maintenance;
      case 'it':
        return IncidentCategory.it;
      default:
        throw Exception('Invalid IncidentCategory string: $value');
    }
  }
}
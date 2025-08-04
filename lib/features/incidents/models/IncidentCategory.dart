enum IncidentCategory {
  all,
  healthSafety,
  maintenance,
  it,
  retail,
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
      case IncidentCategory.retail:
        return 5;

      default:
        throw Exception('Invalid IncidentCategory value: $value');
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
      case IncidentCategory.retail:
        return 'Retail';
      default:
        throw Exception('Invalid IncidentCategory value: $value');
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
      case 5:
        return IncidentCategory.retail;
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
      case 'retail':
        return IncidentCategory.retail;
      default:
        throw Exception('Invalid IncidentCategory string: $value');
    }
  }
}
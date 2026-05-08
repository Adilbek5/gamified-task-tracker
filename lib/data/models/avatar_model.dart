class AvatarModel {
  final int level;

  AvatarModel({required this.level});

  int get stage {
    if (level >= 10) return 3;
    if (level >= 5) return 2;
    return 1;
  }

  String get stageName {
    switch (stage) {
      case 3:
        return 'Code Wizard';
      case 2:
        return 'Code Knight';
      default:
        return 'Code Apprentice';
    }
  }

  String get emoji {
    switch (stage) {
      case 3:
        return '🧙';
      case 2:
        return '🧑‍💻';
      default:
        return '👶';
    }
  }
}
class XpConstants {
  static int calculateXp(int difficulty) => difficulty * 10;

  static int levelFromXp(int xp) {
    int level = 1, required = 100, accumulated = 0;
    while (xp >= accumulated + required) {
      accumulated += required;
      level++;
      required = 100 + (level - 1) * 50;
    }
    return level;
  }

  static int xpForNextLevel(int currentLevel) =>
      100 + (currentLevel - 1) * 50;

  static int xpProgressInCurrentLevel(int totalXp) {
    int level = 1, required = 100, accumulated = 0;
    while (totalXp >= accumulated + required) {
      accumulated += required;
      level++;
      required = 100 + (level - 1) * 50;
    }
    return totalXp - accumulated;
  }
}
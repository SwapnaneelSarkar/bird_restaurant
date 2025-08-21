import '../constants/enums.dart';

class CuisineMapper {
  static CuisineType? toCuisineType(String name) {
    final key = name.trim().toLowerCase();
    switch (key) {
      case 'bakery':
        return CuisineType.bakery;
      case 'italian':
        return CuisineType.italian;
      case 'chinese':
        return CuisineType.chinese;
      case 'indian':
        return CuisineType.indian;
      case 'mexican':
        return CuisineType.mexican;
      case 'japanese':
        return CuisineType.japanese;
      case 'thai':
        return CuisineType.thai;
      case 'american':
        return CuisineType.american;
      case 'french':
        return CuisineType.french;
      case 'mediterranean':
        return CuisineType.mediterranean;
      case 'korean':
        return CuisineType.korean;
      case 'vietnamese':
        return CuisineType.vietnamese;
      default:
        return null;
    }
  }
}


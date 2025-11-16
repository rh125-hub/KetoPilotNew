import '../database/database_service.dart';
import '../database/models/food_model.dart';
import '../database/models/food_portion_model.dart';
import '../database/daos/food_dao.dart';
import '../database/daos/food_portion_dao.dart';
import '../services/food_creation_service.dart';

/// Repository for food data access
class FoodRepository {
  final DatabaseService _dbService = DatabaseService();
  final FoodDao _foodDao = FoodDao();
  final FoodPortionDao _portionDao = FoodPortionDao();
  final FoodCreationService _creationService = FoodCreationService();

  /// Search foods
  Future<List<FoodModel>> searchFoods(String query, {int limit = 20}) async {
    return await _foodDao.searchFoods(query, limit: limit);
  }

  /// Get food by ID with portions
  Future<FoodDetail> getFoodDetail(int foodId) async {
    final food = await _foodDao.getFoodById(foodId);
    if (food == null) {
      throw Exception('Food not found');
    }

    final portions = await _portionDao.getPortionsByFoodId(foodId);
    return FoodDetail(
      food: food,
      portions: portions,
    );
  }

  /// Get food by barcode
  Future<FoodModel?> getFoodByBarcode(String barcode) async {
    return await _foodDao.getFoodByBarcode(barcode);
  }

  /// Create custom food with rate limiting
  Future<int> createFood({
    required FoodModel food,
    required int userId,
  }) async {
    return await _creationService.createFood(
      food: food,
      userId: userId,
    );
  }

  /// Check if user can create food
  Future<FoodCreationResult> canCreateFood(int userId) async {
    return await _creationService.canCreateFood(userId);
  }

  /// Get keto-friendly foods
  Future<List<FoodModel>> getKetoFriendlyFoods({int limit = 50}) async {
    return await _foodDao.getKetoFriendlyFoods(limit: limit);
  }
}

/// Food detail with portions
class FoodDetail {
  final FoodModel food;
  final List<FoodPortionModel> portions;

  FoodDetail({
    required this.food,
    required this.portions,
  });
}

/// Re-export for convenience
export '../services/food_creation_service.dart' show FoodCreationResult, FoodCreationLimitException;


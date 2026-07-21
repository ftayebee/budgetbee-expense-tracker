import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/dashboard_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../../features/analytics/domain/analytics_models.dart';

class Repositories {
  Repositories(ApiClient client)
    : auth = AuthRepository(client),
      dashboard = DashboardRepository(client),
      accounts = AccountRepository(client),
      categories = CategoryRepository(client),
      transactions = TransactionRepository(client),
      budgets = BudgetRepository(client),
      savingsGoals = SavingsGoalRepository(client),
      reports = ReportRepository(client);

  final AuthRepository auth;
  final DashboardRepository dashboard;
  final AccountRepository accounts;
  final CategoryRepository categories;
  final TransactionRepository transactions;
  final BudgetRepository budgets;
  final SavingsGoalRepository savingsGoals;
  final ReportRepository reports;
}

class AuthResult {
  AuthResult(this.user, this.token);
  final UserModel user;
  final String token;
}

class AuthRepository {
  AuthRepository(this.client);
  final ApiClient client;

  Future<AuthResult> login(String email, String password) async {
    final data = await client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResult(UserModel.fromJson(data['user']), data['token']);
  }

  Future<AuthResult> register(
    String name,
    String email,
    String? phone,
    String password,
    String confirmation,
  ) async {
    dynamic data;
    try {
      data = await client.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'password': password,
          'password_confirmation': confirmation,
        },
      );
    } on ApiException catch (exception) {
      if ((exception.statusCode ?? 0) >= 500 ||
          exception.message ==
              'The request could not be completed. Please try again.') {
        throw ApiException(
          'Registration could not be completed. Please try again.',
          errors: exception.errors,
          statusCode: exception.statusCode,
        );
      }
      rethrow;
    }
    if (data is! Map ||
        data['user'] is! Map ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty) {
      throw ApiException(
        'Registration could not be completed. Please try again.',
      );
    }
    final userJson = Map<String, dynamic>.from(data['user'] as Map);
    if (userJson['id'] == null ||
        userJson['name'] == null ||
        userJson['email'] == null) {
      throw ApiException(
        'Registration could not be completed. Please try again.',
      );
    }
    return AuthResult(UserModel.fromJson(userJson), data['token'] as String);
  }

  Future<UserModel> me() async =>
      UserModel.fromJson(await client.get('/auth/me'));
  Future<UserModel> updateProfile(Map<String, dynamic> data) async =>
      UserModel.fromJson(await client.put('/profile', data: data));
  Future<void> changePassword(Map<String, dynamic> data) =>
      client.put('/profile/password', data: data);
  Future<void> forgotPassword(String email) =>
      client.post('/auth/forgot-password', data: {'email': email});
  Future<void> logout() => client.post('/auth/logout');
}

class DashboardRepository {
  DashboardRepository(this.client);
  final ApiClient client;
  Future<DashboardModel> fetch() async =>
      DashboardModel.fromJson(await client.get('/dashboard'));
}

class AccountRepository {
  AccountRepository(this.client);
  final ApiClient client;
  Future<List<AccountModel>> all() async =>
      _collection(await client.get('/accounts'), AccountModel.fromJson);
  Future<AccountModel> create(Map<String, dynamic> data) async =>
      AccountModel.fromJson(await client.post('/accounts', data: data));
  Future<AccountModel> update(int id, Map<String, dynamic> data) async =>
      AccountModel.fromJson(await client.put('/accounts/$id', data: data));
  Future<void> delete(int id) => client.delete('/accounts/$id');
}

class CategoryRepository {
  CategoryRepository(this.client);
  final ApiClient client;
  Future<List<CategoryModel>> all({String? type}) async => _collection(
    await client.get('/categories', query: {'type': type}),
    CategoryModel.fromJson,
  );
  Future<CategoryModel> create(Map<String, dynamic> data) async =>
      CategoryModel.fromJson(await client.post('/categories', data: data));
  Future<CategoryModel> update(int id, Map<String, dynamic> data) async =>
      CategoryModel.fromJson(await client.put('/categories/$id', data: data));
  Future<void> delete(int id) => client.delete('/categories/$id');
}

class TransactionRepository {
  TransactionRepository(this.client);
  final ApiClient client;
  Future<TransactionPage> page([Map<String, dynamic>? filters]) async {
    final response = await client.get('/transactions', query: filters);
    if (response is Map && response['data'] is List) {
      final meta = response['meta'] is Map
          ? Map<String, dynamic>.from(response['meta'] as Map)
          : const <String, dynamic>{};
      return TransactionPage(
        items: (response['data'] as List)
            .map(
              (item) => TransactionModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        currentPage: _int(meta['current_page'], 1),
        lastPage: _int(meta['last_page'], 1),
        total: _int(meta['total'], 0),
      );
    }
    return TransactionPage(
      items: _collection(response, TransactionModel.fromJson),
      currentPage: 1,
      lastPage: 1,
      total: 0,
    );
  }

  Future<List<TransactionModel>> all([Map<String, dynamic>? filters]) async =>
      (await page(filters)).items;
  Future<TransactionModel> create(Map<String, dynamic> data) async =>
      TransactionModel.fromJson(await client.post('/transactions', data: data));
  Future<TransactionModel?> update(int id, Map<String, dynamic> data) async {
    final response = await client.put('/transactions/$id', data: data);
    return response is Map
        ? TransactionModel.fromJson(Map<String, dynamic>.from(response))
        : null;
  }

  Future<void> delete(int id) => client.delete('/transactions/$id');
}

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<TransactionModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
}

class BudgetRepository {
  BudgetRepository(this.client);
  final ApiClient client;
  Future<List<BudgetModel>> all() async =>
      _collection(await client.get('/budgets'), BudgetModel.fromJson);
  Future<BudgetModel> create(Map<String, dynamic> data) async =>
      BudgetModel.fromJson(await client.post('/budgets', data: data));
  Future<BudgetModel> update(int id, Map<String, dynamic> data) async =>
      BudgetModel.fromJson(await client.put('/budgets/$id', data: data));
  Future<void> delete(int id) => client.delete('/budgets/$id');
}

class SavingsGoalRepository {
  SavingsGoalRepository(this.client);
  final ApiClient client;

  Future<List<SavingsGoalModel>> all() async => _collection(
    await client.get('/savings-goals'),
    SavingsGoalModel.fromJson,
  );

  Future<SavingsGoalModel> create(Map<String, dynamic> data) async =>
      SavingsGoalModel.fromJson(
        await client.post('/savings-goals', data: data),
      );

  Future<SavingsGoalModel> update(int id, Map<String, dynamic> data) async =>
      SavingsGoalModel.fromJson(
        await client.put('/savings-goals/$id', data: data),
      );

  Future<SavingsGoalModel> contribute(
    int id,
    Map<String, dynamic> data,
  ) async => SavingsGoalModel.fromJson(
    await client.post('/savings-goals/$id/contributions', data: data),
  );

  Future<void> delete(int id) => client.delete('/savings-goals/$id');
}

class ReportRepository {
  ReportRepository(this.client);
  final ApiClient client;
  Future<List<dynamic>> monthly() async =>
      List<dynamic>.from(await client.get('/reports/monthly-summary'));
  Future<List<dynamic>> categories() async =>
      List<dynamic>.from(await client.get('/reports/category-summary'));
  Future<List<dynamic>> accounts() async =>
      List<dynamic>.from(await client.get('/reports/account-summary'));
  Future<List<dynamic>> yearly() async =>
      List<dynamic>.from(await client.get('/reports/yearly-summary'));
  Future<AnalyticsDataset> analytics(AnalyticsFilter filter) async =>
      AnalyticsDataset.fromJson(
        Map<String, dynamic>.from(
          await client.get('/reports/analytics', query: filter.toQuery())
              as Map,
        ),
      );
}

List<T> _collection<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is Map && data['data'] is List) data = data['data'];
  return data is List
      ? data.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList()
      : [];
}

int _int(dynamic value, int fallback) =>
    value is int ? value : int.tryParse('$value') ?? fallback;

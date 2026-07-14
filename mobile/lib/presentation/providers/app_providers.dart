import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/account_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/savings_goal_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/repositories.dart';

class Loadable extends ChangeNotifier {
  bool loading = false;
  String? error;
  Future<T?> run<T>(Future<T> Function() task) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      return await task();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong';
    } finally {
      loading = false;
      notifyListeners();
    }
    return null;
  }
}

class AuthProvider extends Loadable {
  AuthProvider(this.repo, this.storage);
  final AuthRepository repo;
  final TokenStorage storage;
  UserModel? user;
  bool get isAuthenticated => user != null;

  Future<bool> checkSession() async {
    final token = await storage.read();
    if (token == null) return false;
    final result = await run(repo.me);
    user = result;
    if (result == null) await storage.clear();
    notifyListeners();
    return result != null;
  }

  Future<bool> login(String email, String password) async {
    final result = await run(() => repo.login(email, password));
    if (result == null) return false;
    user = result.user;
    await storage.save(result.token);
    notifyListeners();
    return true;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirmation,
  ) async {
    final result = await run(
      () => repo.register(name, email, password, confirmation),
    );
    if (result == null) return false;
    user = result.user;
    await storage.save(result.token);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await run(repo.logout);
    user = null;
    await storage.clear();
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final result = await run(() => repo.updateProfile(data));
    if (result == null) return false;
    user = result;
    notifyListeners();
    return true;
  }

  Future<bool> changePassword(Map<String, dynamic> data) async {
    final result = await run(() async {
      await repo.changePassword(data);
      return true;
    });
    return result == true;
  }

  Future<bool> forgotPassword(String email) async {
    final result = await run(() async {
      await repo.forgotPassword(email);
      return true;
    });
    return result == true;
  }
}

class DashboardProvider extends Loadable {
  DashboardProvider(this.repo);
  final DashboardRepository repo;
  DashboardModel? dashboard;
  Future<void> load() async => dashboard = await run(repo.fetch);
}

class AccountProvider extends Loadable {
  AccountProvider(this.repo);
  final AccountRepository repo;
  List<AccountModel> accounts = [];
  Future<void> load() async => accounts = await run(repo.all) ?? accounts;
  Future<void> save(Map<String, dynamic> data, [int? id]) async {
    await run(() => id == null ? repo.create(data) : repo.update(id, data));
    await load();
  }

  Future<void> remove(int id) async {
    await run(() => repo.delete(id));
    await load();
  }
}

class CategoryProvider extends Loadable {
  CategoryProvider(this.repo);
  final CategoryRepository repo;
  List<CategoryModel> categories = [];
  Future<void> load({String? type}) async =>
      categories = await run(() => repo.all(type: type)) ?? categories;
  List<CategoryModel> byType(String type) =>
      categories.where((c) => c.type == type).toList();
  Future<void> save(Map<String, dynamic> data, [int? id]) async {
    await run(() => id == null ? repo.create(data) : repo.update(id, data));
    await load();
  }

  Future<void> remove(int id) async {
    await run(() => repo.delete(id));
    await load();
  }
}

class TransactionProvider extends Loadable {
  TransactionProvider(this.repo);
  final TransactionRepository repo;
  List<TransactionModel> transactions = [];
  int revision = 0;
  Future<void> load([Map<String, dynamic>? filters]) async =>
      transactions = await run(() => repo.all(filters)) ?? transactions;
  Future<void> save(Map<String, dynamic> data, [int? id]) async {
    final result = await run(
      () => id == null ? repo.create(data) : repo.update(id, data),
    );
    if (result != null) revision++;
    await load();
  }

  Future<void> remove(int id) async {
    final result = await run(() async {
      await repo.delete(id);
      return true;
    });
    if (result == true) revision++;
    await load();
  }
}

class BudgetProvider extends Loadable {
  BudgetProvider(this.repo);
  final BudgetRepository repo;
  List<BudgetModel> budgets = [];
  Future<void> load() async => budgets = await run(repo.all) ?? budgets;
  Future<void> save(Map<String, dynamic> data) async {
    await run(() => repo.create(data));
    await load();
  }

  Future<void> remove(int id) async {
    await run(() => repo.delete(id));
    await load();
  }
}

class ReportProvider extends Loadable {
  ReportProvider(this.repo);
  final ReportRepository repo;
  List<dynamic> monthly = [], categories = [], accounts = [], yearly = [];
  Future<void> load() async {
    await run(() async {
      monthly = await repo.monthly();
      categories = await repo.categories();
      accounts = await repo.accounts();
      yearly = await repo.yearly();
      return true;
    });
  }
}

class SavingsGoalProvider extends Loadable {
  SavingsGoalProvider(this.repo);
  final SavingsGoalRepository repo;
  List<SavingsGoalModel> goals = [];

  double get totalTarget => goals.fold(0, (sum, g) => sum + g.targetAmount);
  double get totalSaved => goals.fold(0, (sum, g) => sum + g.currentAmount);

  Future<void> load() async => goals = await run(repo.all) ?? goals;

  Future<bool> save(Map<String, dynamic> data, {int? id}) async {
    final result = await run(
      () => id == null ? repo.create(data) : repo.update(id, data),
    );
    if (result == null) return false;
    await load();
    return true;
  }

  Future<bool> contribute(int id, Map<String, dynamic> data) async {
    final result = await run(() => repo.contribute(id, data));
    if (result == null) return false;
    await load();
    return true;
  }

  Future<void> remove(int id) async {
    await run(() => repo.delete(id));
    await load();
  }
}

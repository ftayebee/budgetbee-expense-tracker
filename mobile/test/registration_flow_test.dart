import 'dart:async';

import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_exception.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:expense_tracker/data/models/user_model.dart';
import 'package:expense_tracker/data/repositories/repositories.dart';
import 'package:expense_tracker/presentation/providers/app_providers.dart';
import 'package:expense_tracker/presentation/screens/auth/light_auth_form_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MemoryTokenStorage extends TokenStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}

class _RegistrationRepository extends AuthRepository {
  _RegistrationRepository() : super(ApiClient(_MemoryTokenStorage()));

  final calls = <Map<String, Object?>>[];
  Completer<AuthResult>? completer;
  ApiException? failure;

  @override
  Future<AuthResult> register(
    String name,
    String email,
    String? phone,
    String password,
    String confirmation,
  ) {
    calls.add({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': confirmation,
    });
    if (failure != null) throw failure!;
    return (completer ??= Completer<AuthResult>()).future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(AuthProvider, _RegistrationRepository, _MemoryTokenStorage)> pump(
    WidgetTester tester,
  ) async {
    final repository = _RegistrationRepository();
    final storage = _MemoryTokenStorage();
    final provider = AuthProvider(repository, storage);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: const LightRegisterScreen(),
          routes: {
            '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
          },
        ),
      ),
    );
    return (provider, repository, storage);
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Jane Doe  ');
    await tester.enterText(fields.at(1), '  JANE@example.com  ');
    await tester.enterText(fields.at(2), '+880 1712345678');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'secret123');
  }

  testWidgets('registration sends normalized fields and blocks double submit', (
    tester,
  ) async {
    final (_, repository, storage) = await pump(tester);
    await fillValidForm(tester);

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single['name'], 'Jane Doe');
    expect(repository.calls.single['email'], 'JANE@example.com');
    expect(repository.calls.single['phone'], '+880 1712345678');

    repository.completer!.complete(
      AuthResult(
        const UserModel(id: 1, name: 'Jane Doe', email: 'jane@example.com'),
        'secret-token',
      ),
    );
    await tester.pumpAndSettle();
    expect(storage.value, 'secret-token');
  });

  testWidgets('field-specific Laravel errors render under matching fields', (
    tester,
  ) async {
    final (_, repository, _) = await pump(tester);
    repository.failure = ApiException(
      'Validation failed',
      statusCode: 422,
      errors: {
        'email': ['The email has already been taken.'],
        'phone': ['The phone number has already been taken.'],
      },
    );
    await fillValidForm(tester);

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('The email has already been taken.'), findsOneWidget);
    expect(
      find.text('The phone number has already been taken.'),
      findsOneWidget,
    );
    expect(find.text('Validation failed'), findsNothing);
  });

  testWidgets('invalid email, weak password, and mismatch stay client-side', (
    tester,
  ) async {
    final (_, repository, _) = await pump(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jane');
    await tester.enterText(fields.at(1), 'invalid');
    await tester.enterText(fields.at(3), 'short');
    await tester.enterText(fields.at(4), 'different');

    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repository.calls, isEmpty);
  });
}

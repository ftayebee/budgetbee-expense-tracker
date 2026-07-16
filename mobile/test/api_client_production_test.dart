import 'package:dio/dio.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_error_mapper.dart';
import 'package:expense_tracker/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'shared Dio client attaches bearer and JSON headers to PUT and DELETE',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'production-token',
      });
      final client = ApiClient(TokenStorage());
      final requests = <RequestOptions>[];
      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': null},
              ),
            );
          },
        ),
      );

      await client.put('/transactions/42', data: {'amount': 25});
      await client.delete('/transactions/42');

      expect(requests.map((request) => request.method), ['PUT', 'DELETE']);
      for (final request in requests) {
        expect(request.headers['Authorization'], 'Bearer production-token');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.uri.path, endsWith('/api/v1/transactions/42'));
      }
    },
  );

  test('production errors array does not hide the 401 server response', () {
    final exception = _responseError(401, {
      'success': false,
      'message': 'Unauthenticated.',
      'errors': [],
    });

    final mapped = ApiErrorMapper.fromDio(exception);

    expect(mapped.statusCode, 401);
    expect(mapped.errors, isEmpty);
    expect(mapped.message, 'Your session has expired. Please sign in again.');
  });

  test('422 exposes the first safe validation message', () {
    final mapped = ApiErrorMapper.fromDio(
      _responseError(422, {
        'message': 'Validation failed',
        'errors': {
          'amount': ['The amount must be greater than zero.'],
        },
      }),
    );

    expect(mapped.statusCode, 422);
    expect(mapped.message, 'The amount must be greater than zero.');
  });

  test('HTML and server errors return safe status-specific messages', () {
    expect(
      ApiErrorMapper.fromDio(
        _responseError(405, '<html>Method Not Allowed</html>'),
      ).message,
      'This operation is not supported by the server.',
    );
    expect(
      ApiErrorMapper.fromDio(
        _responseError(500, '<html>Internal Server Error</html>'),
      ).message,
      'The server could not complete the request. Please try again.',
    );
  });

  test('404 and 403 preserve safe Laravel messages', () {
    expect(
      ApiErrorMapper.fromDio(
        _responseError(404, {'message': 'Resource not found.', 'errors': {}}),
      ).message,
      'Resource not found.',
    );
    expect(
      ApiErrorMapper.fromDio(
        _responseError(403, {'message': 'This action is unauthorized.'}),
      ).message,
      'This action is unauthorized.',
    );
  });
}

DioException _responseError(int statusCode, dynamic data) {
  final options = RequestOptions(path: '/transactions/42', method: 'PUT');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}

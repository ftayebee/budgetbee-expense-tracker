import 'package:expense_tracker/presentation/screens/transactions/transaction_filter_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transaction filter serializes every server-backed option', () {
    final filter = TransactionFilter(
      type: 'transfer',
      datePreset: TransactionDatePreset.custom,
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 17),
      accountId: 4,
      categoryId: 9,
      minimumAmount: 10,
      maximumAmount: 500,
      sort: 'amount_desc',
    );

    expect(filter.activeCount, 6);
    expect(filter.toQuery(search: 'gift'), {
      'search': 'gift',
      'type': 'transfer',
      'from': '2026-07-01',
      'to': '2026-07-17',
      'account_id': 4,
      'category_id': 9,
      'min_amount': 10,
      'max_amount': 500,
      'sort': 'amount_desc',
    });
  });

  test('reset filter has no active badge and restores newest sort', () {
    const filter = TransactionFilter();

    expect(filter.isActive, isFalse);
    expect(filter.activeCount, 0);
    expect(filter.toQuery()['sort'], 'date_desc');
  });
}

// Round-trip coverage for the Zakat inputs table (ZakatDao) — the calculator
// screen restores its form from the last saved row, so every field it writes
// has to survive the insert, including the direct gold/silver values added by
// R1 of docs/specs/zakat-calculator.md.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takwa/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('a value-only gold entry round-trips through the saved record', () async {
    await db.zakatDao.save(
      ZakatCalculationsCompanion.insert(
        cashAmount: const Value(1000),
        goldValue: const Value(900),
        silverValue: const Value(100),
        currencyLabel: const Value('DZD'),
      ),
    );

    final saved = await db.zakatDao.getLatest();
    expect(saved!.cashAmount, 1000);
    expect(saved.goldValue, 900);
    expect(saved.silverValue, 100);
    // Weight/price left unset stay 0 rather than null, so the form restores
    // them as blank fields.
    expect(saved.goldGrams, 0);
    expect(saved.goldPricePerGram, 0);
  });

  test('older rows without value columns default to zero', () async {
    await db.zakatDao.save(
      ZakatCalculationsCompanion.insert(
        goldGrams: const Value(10),
        goldPricePerGram: const Value(70),
      ),
    );

    final saved = await db.zakatDao.getLatest();
    expect(saved!.goldValue, 0);
    expect(saved.silverValue, 0);
  });
}

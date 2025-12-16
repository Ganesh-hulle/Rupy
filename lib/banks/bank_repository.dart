import 'package:morpheus/data/banks_db.dart';

/// Thin abstraction over the bundled banks SQLite table so the UI can swap
/// implementations (e.g., remote search) without touching widgets.
class BankRepository {
  /// Initial top picks to show before the user types.
  Future<List<String>> loadTopBanks({int limit = 5}) =>
      BanksDb.fetchBankNames(limit: limit);

  /// Search by prefix and keep the result set intentionally tiny for perf.
  Future<List<String>> searchBanks(String query, {int limit = 5}) =>
      BanksDb.fetchBankNames(startsWith: query.trim(), limit: limit);

  Future<String?> findIconByName(String name) async {
    final db = await BanksDb.instance();
    final rows = await db.query(
      'banks',
      columns: ['icon'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['icon'] as String?;
  }
}

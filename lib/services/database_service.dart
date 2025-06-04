import '../db/database.dart';

class DatabaseService {
  Future<List<String>> getTableNames() async {
    return await DatabaseHelper.instance.getTableNames();
  }

  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    return await DatabaseHelper.instance.getTableData(tableName);
  }

  Future<List<Map<String, String>>> getTableStructure(String tableName) async {
    return await DatabaseHelper.instance.getTableStructure(tableName);
  }

  Future<int> delete(String tableName, {String? where, List<dynamic>? whereArgs}) async {
    return await DatabaseHelper.instance.delete(tableName, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String tableName, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    return await DatabaseHelper.instance.update(tableName, data, where: where, whereArgs: whereArgs);
  }
}
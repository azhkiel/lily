import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DatabaseViewerProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, String>> _tableStructure = [];
  bool _isLoading = false;
  int? _editingId;
  final Map<String, TextEditingController> _editControllers = {};

  // Getter methods
  List<String> get tables => _tables;
  String? get selectedTable => _selectedTable;
  List<Map<String, dynamic>> get tableData => _tableData;
  List<Map<String, String>> get tableStructure => _tableStructure;
  bool get isLoading => _isLoading;
  int? get editingId => _editingId;
  Map<String, TextEditingController> get editControllers => _editControllers;

  Future<void> loadTables() async {
    _setLoading(true);
    try {
      _tables = await _dbService.getTableNames();
      if (_tables.isNotEmpty) {
        _selectedTable = _tables.first;
        await _loadTableData();
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Error loading tables: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadTableData() async {
    if (_selectedTable == null) return;
    
    _setLoading(true);
    _clearEditControllers();
    
    try {
      _tableData = await _dbService.getTableData(_selectedTable!);
      _tableStructure = await _dbService.getTableStructure(_selectedTable!);
      notifyListeners();
    } catch (e) {
      throw Exception('Error loading table data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _clearEditControllers() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    _editControllers.clear();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Tambahkan method lainnya (delete, update, dll) sesuai kebutuhan
}
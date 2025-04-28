import 'package:flutter/material.dart';
import '../db/database.dart';

class DatabaseViewer extends StatefulWidget {
  const DatabaseViewer({Key? key}) : super(key: key);

  @override
  _DatabaseViewerState createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  List<String> _tables = [];
  String? _selectedTable;
  int? _editingId; // Tambahkan ini untuk melacak baris yang sedang diedit
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, String>> _tableStructure = [];
  bool _isLoading = false;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _clearEditControllers();
    super.dispose();
  }

  void _clearEditControllers() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    _editControllers.clear();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await DatabaseHelper.instance.getTableNames();
      setState(() {
        _tables = tables;
        if (tables.isNotEmpty) {
          _selectedTable = tables.first;
          _loadTableData();
        }
      });
    } catch (e) {
      _showError('Error loading tables: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTableData() async {
    if (_selectedTable == null) return;

    setState(() => _isLoading = true);
    _clearEditControllers();

    try {
      final data = await DatabaseHelper.instance.getTableData(_selectedTable!);
      final structure = await DatabaseHelper.instance.getTableStructure(
        _selectedTable!,
      );

      setState(() {
        _tableData = data;
        _tableStructure = structure;
      });
    } catch (e) {
      _showError('Error loading table data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    if (_selectedTable == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this row?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final id = row['id'];
        await DatabaseHelper.instance.delete(
          _selectedTable!,
          where: 'id = ?',
          whereArgs: [id],
        );
        _loadTableData(); // Refresh data
        _showSuccess('Row deleted successfully');
      } catch (e) {
        _showError('Error deleting row: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startEditing(Map<String, dynamic> row) {
    _clearEditControllers();
    setState(() {
      _editingId = row['id'] as int?;
    });
    for (var key in row.keys) {
      _editControllers[key] = TextEditingController(
        text: row[key]?.toString() ?? '',
      );
    }
  }

  Future<void> _saveEditing() async {
    if (_selectedTable == null || _editingId == null) return;

    final updates = <String, dynamic>{};
    for (var entry in _editControllers.entries) {
      // Skip kolom id dan kolom yang tidak boleh diupdate
      if (entry.key != 'id' && entry.value.text != '') {
        updates[entry.key] = entry.value.text;
      }
    }

    if (updates.isEmpty) {
      _showError('No changes to save');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final rowsAffected = await DatabaseHelper.instance.update(
        _selectedTable!,
        updates,
        where: 'id = ?',
        whereArgs: [_editingId],
      );

      if (rowsAffected > 0) {
        _showSuccess('Successfully updated $rowsAffected row(s)');
        _clearEditControllers();
        setState(() => _editingId = null);
        await _loadTableData();
      } else {
        _showError('No rows were updated');
      }
    } catch (e) {
      _showError('Failed to update: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEditing() {
    _clearEditControllers();
    setState(() => _editingId = null);
  }

  void _selectTable(String tableName) {
    setState(() {
      _selectedTable = tableName;
      _tableData = [];
      _tableStructure = [];
    });
    _loadTableData();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTableData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Table Selection
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final tableName = _tables[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ChoiceChip(
                            label: Text(tableName),
                            selected: _selectedTable == tableName,
                            onSelected: (selected) => _selectTable(tableName),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),

                  // Table Structure
                  if (_selectedTable != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Structure of $_selectedTable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Column')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Not Null')),
                          DataColumn(label: Text('Default')),
                          DataColumn(label: Text('Primary Key')),
                        ],
                        rows:
                            _tableStructure.map((column) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(column['name'] ?? 'N/A')),
                                  DataCell(Text(column['type'] ?? 'N/A')),
                                  DataCell(Text(column['notnull'] ?? 'N/A')),
                                  DataCell(Text(column['dflt_value'] ?? 'N/A')),
                                  DataCell(Text(column['pk'] ?? 'N/A')),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                    const Divider(),

                    // Table Data with Edit/Delete
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: [
                              if (_tableData.isNotEmpty)
                                ..._tableData.first.keys.map((key) {
                                  return DataColumn(
                                    label: Text(key.toString()),
                                  );
                                }).toList(),
                              const DataColumn(label: Text('Actions')),
                            ],
                            rows:
                                _tableData.map((row) {
                                  final rowId = row['id'];
                                  final isEditing = _editingId == rowId;

                                  return DataRow(
                                    cells: [
                                      ...row.entries.map((entry) {
                                        if (isEditing && entry.key != 'id') {
                                          return DataCell(
                                            TextField(
                                              controller:
                                                  _editControllers[entry.key],
                                              decoration: InputDecoration(
                                                border:
                                                    const OutlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.all(8),
                                                filled: true,
                                                fillColor: Colors.yellow[50],
                                              ),
                                            ),
                                          );
                                        } else {
                                          return DataCell(
                                            Text(
                                              entry.value?.toString() ?? 'NULL',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }
                                      }).toList(),
                                      DataCell(
                                        isEditing
                                            ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.save,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: _saveEditing,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: _cancelEditing,
                                                ),
                                              ],
                                            )
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      () => _startEditing(row),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      () => _deleteRow(row),
                                                ),
                                              ],
                                            ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(child: Text('No tables found in database')),
                    ),
                  ],
                ],
              ),
    );
  }
}

class ChoiceChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const ChoiceChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
    );
  }
}

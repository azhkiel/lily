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
  int? _editingId; // Baris yang sedang diedit
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
    for (final controller in _editControllers.values) {
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
        if (_tables.isNotEmpty) {
          _selectedTable = _tables.first;
        } else {
          _selectedTable = null;
          _tableData = [];
          _tableStructure = [];
        }
      });
      if (_selectedTable != null) await _loadTableData();
    } catch (e) {
      _showError('Error loading tables: $e');
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
      final structure = await DatabaseHelper.instance.getTableStructure(_selectedTable!);

      setState(() {
        _tableData = data;
        _tableStructure = structure;
        _editingId = null;
      });
    } catch (e) {
      _showError('Error loading table data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRow(Map<String, dynamic> row) async {
    if (_selectedTable == null) return;

    final id = row['id'];
    if (id == null) {
      _showError('Selected row does not have a valid id');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this row?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseHelper.instance.delete(
          _selectedTable!,
          where: 'id = ?',
          whereArgs: [id],
        );
        await _loadTableData();
        _showSuccess('Row deleted successfully');
      } catch (e) {
        _showError('Error deleting row: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startEditing(Map<String, dynamic> row) {
    _clearEditControllers();
    final id = row['id'];
    if (id == null) {
      _showError('Cannot edit row without id');
      return;
    }
    for (final key in row.keys) {
      _editControllers[key] = TextEditingController(text: row[key]?.toString() ?? '');
    }
    setState(() => _editingId = id as int);
  }

  Future<void> _saveEditing() async {
    if (_selectedTable == null || _editingId == null) return;

    final updates = <String, dynamic>{};
    for (final entry in _editControllers.entries) {
      if (entry.key == 'id') continue;
      if (entry.value.text.isNotEmpty) updates[entry.key] = entry.value.text;
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
      _showError('Failed to update: $e');
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
      _editingId = null;
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

  // Widget untuk bagian struktur tabel
  Widget _buildTableStructureSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table Structure',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_selectedTable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                columns: const [
                  DataColumn(label: Text('Column', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Not Null', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Default', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Primary Key', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _tableStructure.map((column) {
                  return DataRow(cells: [
                    DataCell(Text(column['name'] ?? 'N/A')),
                    DataCell(Text((column['type'] ?? 'N/A').toString().toUpperCase())),
                    DataCell(Text((column['notnull'] == '1' || column['notnull'] == 1).toString())),
                    DataCell(Text(column['dflt_value']?.toString() ?? 'NULL')),
                    DataCell(Text((column['pk'] == '1' || column['pk'] == 1).toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk bagian data tabel
  Widget _buildTableDataSection(BuildContext context) {
    final theme = Theme.of(context);
    if (_tableData.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('No data available for this table.', style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Table Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 16,
                        headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceContainerHighest),
                        columns: [
                          ..._tableData.first.keys.map(
                            (key) => DataColumn(
                              label: Text(
                                key.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _tableData.map((row) {
                          final rowId = row['id'];
                          final isEditing = _editingId == rowId;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                                if (isEditing) {
                                  return Colors.yellow.withOpacity(0.1);
                                }
                                if (rowId != null && rowId is int && rowId % 2 == 0) {
                                  return theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
                                }
                                return Colors.transparent;
                              },
                            ),
                            cells: [
                              ...row.entries.map((entry) {
                                if (isEditing && entry.key != 'id') {
                                  return DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: _editControllers[entry.key],
                                        decoration: InputDecoration(
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.all(12),
                                          filled: true,
                                          fillColor: Colors.yellow[50],
                                          hintText: 'Enter ${entry.key}',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return DataCell(
                                  Tooltip(
                                    message: entry.value?.toString() ?? 'NULL',
                                    child: Text(
                                      entry.value?.toString() ?? 'NULL',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }),
                              DataCell(
                                isEditing
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Tooltip(
                                            message: 'Save',
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.save,
                                                color: theme.colorScheme.primary,
                                              ),
                                              onPressed: _saveEditing,
                                            ),
                                          ),
                                          Tooltip(
                                            message: 'Cancel',
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.cancel,
                                                color: theme.colorScheme.error,
                                              ),
                                              onPressed: _cancelEditing,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Tooltip(
                                            message: 'Edit',
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: theme.colorScheme.primary,
                                              ),
                                              onPressed: () => _startEditing(row),
                                            ),
                                          ),
                                          Tooltip(
                                            message: 'Delete',
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: theme.colorScheme.error,
                                              ),
                                              onPressed: () => _deleteRow(row),
                                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Database Viewer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Tooltip(
            message: 'Refresh Data',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTableData,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table selector
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 50,
                        child: _tables.isEmpty
                            ? const Center(
                                child: Text('No tables found'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tables.length,
                                itemBuilder: (context, index) {
                                  final tableName = _tables[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ChoiceChip(
                                      label: Text(
                                        tableName,
                                        style: TextStyle(
                                          color: _selectedTable == tableName
                                              ? theme.colorScheme.onPrimary
                                              : null,
                                        ),
                                      ),
                                      selected: _selectedTable == tableName,
                                      onSelected: (_) => _selectTable(tableName),
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor: theme.colorScheme.surface,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    const Divider(height: 1),

                    if (_selectedTable != null) ...[
                      _buildTableStructureSection(context),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _buildTableDataSection(context),
                    ] else ...[
                      Expanded(
                        child: Center(
                          child: Text(
                            'Select a table to view data',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Selection
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      child: ListView.builder(
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
                                  color:
                                      _selectedTable == tableName
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                          : null,
                                ),
                              ),
                              selected: _selectedTable == tableName,
                              onSelected: (selected) => _selectTable(tableName),
                              selectedColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  if (_selectedTable != null) ...[
                    // Table Structure Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table Structure',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_selectedTable',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          headingRowColor:
                              WidgetStateProperty.resolveWith<Color>(
                                (states) =>
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Column',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Type',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Not Null',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Default',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Primary Key',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              _tableStructure.map((column) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(column['name'] ?? 'N/A')),
                                    DataCell(
                                      Text(
                                        column['type']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'N/A',
                                      ),
                                    ),
                                    DataCell(
                                      Text((column['notnull'] == 1).toString()),
                                    ),
                                    DataCell(
                                      Text(
                                        column['dflt_value']?.toString() ??
                                            'NULL',
                                      ),
                                    ),
                                    DataCell(
                                      Text((column['pk'] == 1).toString()),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Table Data Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Table Data',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin: 16,
                                      headingRowColor:
                                          WidgetStateProperty.resolveWith<
                                            Color
                                          >(
                                            (states) =>
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surfaceContainerHighest,
                                          ),
                                      columns: [
                                        if (_tableData.isNotEmpty)
                                          ..._tableData.first.keys.map((key) {
                                            return DataColumn(
                                              label: Text(
                                                key.toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        const DataColumn(
                                          label: Text(
                                            'Actions',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                      rows:
                                          _tableData.map((row) {
                                            final rowId = row['id'];
                                            final isEditing =
                                                _editingId == rowId;

                                            return DataRow(
                                              color:
                                                  WidgetStateProperty.resolveWith<
                                                    Color
                                                  >(
                                                    (states) =>
                                                        isEditing
                                                            ? Colors.yellow
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : (rowId != null &&
                                                                rowId % 2 == 0)
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .surfaceContainerHighest
                                                                .withOpacity(
                                                                  0.3,
                                                                )
                                                            : Colors
                                                                .transparent,
                                                  ),
                                              cells: [
                                                ...row.entries.map((entry) {
                                                  if (isEditing &&
                                                      entry.key != 'id') {
                                                    return DataCell(
                                                      SizedBox(
                                                        width: 150,
                                                        child: TextField(
                                                          controller:
                                                              _editControllers[entry
                                                                  .key],
                                                          decoration: InputDecoration(
                                                            border:
                                                                const OutlineInputBorder(),
                                                            contentPadding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            filled: true,
                                                            fillColor:
                                                                Colors
                                                                    .yellow[50],
                                                            hintText:
                                                                'Enter ${entry.key}',
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return DataCell(
                                                      Tooltip(
                                                        message:
                                                            entry.value
                                                                ?.toString() ??
                                                            'NULL',
                                                        child: Text(
                                                          entry.value
                                                                  ?.toString() ??
                                                              'NULL',
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }).toList(),
                                                DataCell(
                                                  isEditing
                                                      ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Tooltip(
                                                            message: 'Save',
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.save,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .primary,
                                                              ),
                                                              onPressed:
                                                                  _saveEditing,
                                                            ),
                                                          ),
                                                          Tooltip(
                                                            message: 'Cancel',
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.cancel,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .error,
                                                              ),
                                                              onPressed:
                                                                  _cancelEditing,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                      : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Tooltip(
                                                            message: 'Edit',
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.edit,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .primary,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      _startEditing(
                                                                        row,
                                                                      ),
                                                            ),
                                                          ),
                                                          Tooltip(
                                                            message: 'Delete',
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .error,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      _deleteRow(
                                                                        row,
                                                                      ),
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
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tables found in database',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}
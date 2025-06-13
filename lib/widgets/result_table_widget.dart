import 'package:flutter/material.dart';

class ResultTableWidget extends StatefulWidget {
  final List<Map<String, String>> data;
  final List<String> columns;

  const ResultTableWidget({super.key, required this.data, required this.columns});

  @override
  State<ResultTableWidget> createState() => _ResultTableWidgetState();
}

class _ResultTableWidgetState extends State<ResultTableWidget> {
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  String? _selectedExpansion;
  String? _selectedCondition;

  List<String> get _expansions => widget.data.map((row) => row['Espansione'] ?? '').toSet().where((e) => e.isNotEmpty).toList();
  List<String> get _conditions => widget.data.map((row) => row['Condizione'] ?? '').toSet().where((e) => e.isNotEmpty).toList();

  List<Map<String, String>> get _filteredData {
    var filtered = widget.data;
    if (_selectedExpansion != null) {
      filtered = filtered.where((row) => row['Espansione'] == _selectedExpansion).toList();
    }
    if (_selectedCondition != null) {
      filtered = filtered.where((row) => row['Condizione'] == _selectedCondition).toList();
    }
    return filtered;
  }

  List<Map<String, String>> get _pagedData {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage) > _filteredData.length ? _filteredData.length : (start + _rowsPerPage);
    return _filteredData.sublist(start, end);
  }

  int get _totalPages => (_filteredData.length / _rowsPerPage).ceil();

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Espansione:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedExpansion,
                    hint: const Text('Tutte'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tutte')),
                      ..._expansions.map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedExpansion = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Condizione:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCondition,
                    hint: const Text('Tutte'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tutte')),
                      ..._conditions.map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCondition = value;
                        _currentPage = 0;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: widget.columns.map((col) => DataColumn(label: Text(col))).toList(),
                rows: _pagedData.map((row) => DataRow(
                  cells: widget.columns.map((col) => DataCell(Text(row[col] ?? ''))).toList(),
                )).toList(),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            ),
            Text('Pagina ${_currentPage + 1} di ${_totalPages == 0 ? 1 : _totalPages}'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: (_currentPage < _totalPages - 1) ? () => _goToPage(_currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

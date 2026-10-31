/// Comma-separated values as RFC 4180 writes them: fields with a comma, a
/// quote or a line break are quoted, and quotes inside are doubled.
abstract final class Csv {
  static String encode(List<String> header, Iterable<List<Object?>> rows) {
    final out = StringBuffer()..writeln(header.map(_field).join(','));
    for (final row in rows) {
      out.writeln(row.map(_field).join(','));
    }
    return out.toString();
  }

  static String _field(Object? value) {
    final text = switch (value) {
      null => '',
      final double d => d == d.roundToDouble() ? d.toInt().toString() : '$d',
      _ => '$value',
    };
    if (text.contains(RegExp('[",\r\n]'))) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  /// Rows as maps from the header's names, blank lines skipped.
  static List<Map<String, String>> decode(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var i = 0;
    // A byte-order mark from a spreadsheet is not part of the first name.
    if (text.startsWith('﻿')) i = 1;
    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
      row = <String>[];
    }

    while (i < text.length) {
      final c = text[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ',') {
        endField();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      } else {
        field.write(c);
      }
      i++;
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();
    if (rows.isEmpty) return const [];
    final header = rows.first.map((h) => h.trim()).toList();
    return [
      for (final r in rows.skip(1))
        {
          for (var c = 0; c < header.length; c++)
            header[c]: c < r.length ? r[c] : '',
        },
    ];
  }
}

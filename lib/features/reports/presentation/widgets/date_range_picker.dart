import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Mode pemilihan tanggal pada bottom sheet.
enum DatePickerMode { custom, week, month }

/// Hasil yang dikembalikan oleh [DateRangePicker].
class DateRangeResult {
  final DateTime start;
  final DateTime end;

  const DateRangeResult({required this.start, required this.end});

  int get dayCount => end.difference(start).inDays + 1;
}

/// Menampilkan bottom sheet date range picker dan mengembalikan [DateRangeResult].
Future<DateRangeResult?> showDateRangePicker(
  BuildContext context, {
  DateRangeResult? initialRange,
}) {
  return showModalBottomSheet<DateRangeResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DateRangePicker(initialRange: initialRange),
  );
}

class DateRangePicker extends StatefulWidget {
  final DateRangeResult? initialRange;

  const DateRangePicker({super.key, this.initialRange});

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  // -- Color palette (sesuai tema app: light, blue primary, Inter font) --
  static const _bgColor = Color(0xFFFFFFFF);
  static const _surfaceColor = Color(0xFFF1F5F9);
  static const _primaryColor = Color(0xFF0F62FE);
  static const _textPrimary = Color(0xFF1E293B);
  static const _textSecondary = Color(0xFF64748B);
  static const _textMuted = Color(0xFF94A3B8);
  static const _borderColor = Color(0xFFCBD5E1);
  static const _rangeHighlight = Color(0xFFDBEAFE);

  // -- State --
  DatePickerMode _mode = DatePickerMode.custom;
  late DateTime _viewMonth;
  late int _viewYear;

  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
    _viewYear = now.year;

    if (widget.initialRange != null) {
      _selectedStart = _dateOnly(widget.initialRange!.start);
      _selectedEnd = _dateOnly(widget.initialRange!.end);
      _viewMonth = DateTime(_selectedStart!.year, _selectedStart!.month, 1);
      _viewYear = _selectedStart!.year;
    } else {
      _selectedStart = _dateOnly(now);
      _selectedEnd = _dateOnly(now);
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  DateTime get _today => _dateOnly(DateTime.now());

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildModeTabs(),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: _mode == DatePickerMode.month
                  ? _buildMonthPicker()
                  : _buildCalendarView(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Handle ─────────────────────────────────────────────────────────────────
  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _borderColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pilih Rentang Tanggal',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: _textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mode Tabs ──────────────────────────────────────────────────────────────
  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTabChip('Kustom', DatePickerMode.custom),
              const SizedBox(width: 10),
              _buildTabChip('Minggu', DatePickerMode.week),
              const SizedBox(width: 10),
              _buildTabChip('Bulan', DatePickerMode.month),
            ],
          ),
          if (_mode != DatePickerMode.month) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hari',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, DatePickerMode mode) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  CALENDAR VIEW  (Custom / Week)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 8),
          _buildWeekdayLabels(),
          const SizedBox(height: 4),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_viewMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
          }),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: _textSecondary, size: 22),
          ),
        ),
        Text(
          monthLabel,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
          }),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right, color: _textSecondary, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: days
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = _viewMonth;
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;

    // weekday: 1 = Monday … 7 = Sunday
    final startWeekday = firstDayOfMonth.weekday;
    final leadingBlanks = startWeekday - 1;

    final cells = <Widget>[];

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_viewMonth.year, _viewMonth.month, day);
      cells.add(_buildDayCell(date));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = date == _today;
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isFuture = date.isAfter(_today);

    Color bgColor;
    if (isSelected) {
      bgColor = _primaryColor;
    } else if (isInRange) {
      bgColor = _rangeHighlight;
    } else {
      bgColor = Colors.transparent;
    }

    Color textColor;
    if (isFuture) {
      textColor = _textMuted.withValues(alpha: 0.35);
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = _primaryColor;
    } else {
      textColor = _textPrimary;
    }

    return GestureDetector(
      onTap: isFuture ? null : () => _onDayTapped(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          shape: isSelected ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isSelected ? null : BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: _primaryColor.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedStart == null) return false;
    return date == _selectedStart || date == _selectedEnd;
  }

  bool _isDateInRange(DateTime date) {
    if (_selectedStart == null || _selectedEnd == null) return false;
    return date.isAfter(_selectedStart!) && date.isBefore(_selectedEnd!);
  }

  void _onDayTapped(DateTime date) {
    setState(() {
      if (_mode == DatePickerMode.week) {
        final weekday = date.weekday;
        _selectedStart = date.subtract(Duration(days: weekday - 1));
        _selectedEnd = _selectedStart!.add(const Duration(days: 6));
        if (_selectedEnd!.isAfter(_today)) {
          _selectedEnd = _today;
        }
      } else {
        if (_selectedStart == null || _selectedEnd != _selectedStart) {
          _selectedStart = date;
          _selectedEnd = date;
        } else {
          if (date.isBefore(_selectedStart!)) {
            _selectedEnd = _selectedStart;
            _selectedStart = date;
          } else {
            _selectedEnd = date;
          }
        }
      }
    });
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  MONTH PICKER
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMonthGrid(),
          const SizedBox(height: 16),
          _buildYearSelector(),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'Mei', 'Jun', 'Jul', 'Agu',
      'Sep', 'Okt', 'Nov', 'Des',
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: List.generate(12, (index) {
        final month = index + 1;
        final isSelected =
            _selectedStart != null &&
            _selectedStart!.year == _viewYear &&
            _selectedStart!.month == month &&
            _mode == DatePickerMode.month;

        final isFuture =
            DateTime(_viewYear, month + 1, 0).isAfter(_today) &&
            DateTime(_viewYear, month, 1).isAfter(_today);

        return GestureDetector(
          onTap: isFuture
              ? null
              : () {
                  setState(() {
                    final firstDay = DateTime(_viewYear, month, 1);
                    final lastDay = DateTime(_viewYear, month + 1, 0);
                    _selectedStart = firstDay;
                    _selectedEnd = lastDay.isAfter(_today) ? _today : lastDay;
                  });
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _primaryColor : _borderColor.withValues(alpha: 0.5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              monthNames[index],
              style: TextStyle(
                color: isFuture
                    ? _textMuted.withValues(alpha: 0.35)
                    : isSelected
                        ? Colors.white
                        : _textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _viewYear--),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_left, color: _textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            '$_viewYear',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: _viewYear < currentYear
                ? () => setState(() => _viewYear++)
                : null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _viewYear < currentYear
                    ? _surfaceColor
                    : _surfaceColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                color: _viewYear < currentYear
                    ? _textSecondary
                    : _textMuted.withValues(alpha: 0.3),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  //  FOOTER
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
    String rangeText = '';
    String daysText = '';

    if (_selectedStart != null && _selectedEnd != null) {
      if (_selectedStart == _selectedEnd) {
        rangeText = dateFormat.format(_selectedStart!);
      } else {
        rangeText =
            '${dateFormat.format(_selectedStart!)} - ${dateFormat.format(_selectedEnd!)}';
      }
      final days = _selectedEnd!.difference(_selectedStart!).inDays + 1;
      daysText = '($days hari)';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(
          top: BorderSide(color: _borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rangeText.isNotEmpty) ...[
              Text(
                '$rangeText $daysText',
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedStart != null && _selectedEnd != null
                    ? () {
                        Navigator.of(context).pop(
                          DateRangeResult(
                            start: _selectedStart!,
                            end: _selectedEnd!,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: _primaryColor.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

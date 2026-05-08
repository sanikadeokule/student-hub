import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _shouldReplace = true;
  bool isScientific = false;

  void _onButton(String val) {
    setState(() {
      final num = double.tryParse(_display) ?? 0;
      if (val == 'C') {
        _display = '0'; _expression = ''; _firstOperand = 0;
        _operator = ''; _shouldReplace = true;
      } else if (val == '⌫') {
        _display = _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      } else if (val == 'sin') { _display = sin(num).toStringAsFixed(4); }
        else if (val == 'cos') { _display = cos(num).toStringAsFixed(4); }
        else if (val == 'tan') { _display = tan(num).toStringAsFixed(4); }
        else if (val == 'log') { _display = log(num).toStringAsFixed(4); }
        else if (val == '√')   { _display = sqrt(num).toStringAsFixed(4); }
        else if (val == 'x²')  { _display = (num * num).toString(); }
      else if (['+', '-', '×', '÷'].contains(val)) {
        _firstOperand = num; _operator = val;
        _expression = '$_display $val'; _shouldReplace = true;
      } else if (val == '=') {
        double result = 0;
        switch (_operator) {
          case '+': result = _firstOperand + num; break;
          case '-': result = _firstOperand - num; break;
          case '×': result = _firstOperand * num; break;
          case '÷': result = num != 0 ? _firstOperand / num : 0; break;
        }
        _expression = '$_expression $_display =';
        _display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(4);
        _shouldReplace = true; _operator = '';
      } else if (val == '%') {
        _display = (num / 100).toString();
      } else if (val == '+/-') {
        if (_display != '0') _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
      } else if (val == '.') {
        if (!_display.contains('.')) {
          _display = _shouldReplace ? '0.' : '$_display.';
          _shouldReplace = false;
        }
      } else {
        if (_shouldReplace) { _display = val; _shouldReplace = false; }
        else { _display = _display == '0' ? val : _display + val; }
      }
    });
  }

  // Button types
  static const _typeNumber   = 0;
  static const _typeOperator = 1;
  static const _typeAction   = 2; // C, ⌫
  static const _typeEquals   = 3;
  static const _typeScience  = 4;

  Widget _btn(String label, {int type = _typeNumber, int flex = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    switch (type) {
      case _typeOperator:
        bg = kPrimary.withOpacity(isDark ? 0.35 : 0.15);
        fg = kPrimary;
        break;
      case _typeAction:
        bg = kCoral.withOpacity(isDark ? 0.30 : 0.12);
        fg = kCoral;
        break;
      case _typeEquals:
        bg = kPrimary;
        fg = Colors.white;
        break;
      case _typeScience:
        bg = kMint.withOpacity(isDark ? 0.30 : 0.12);
        fg = kMint;
        break;
      default:
        bg = isDark ? kDarkSurface : Colors.white;
        fg = isDark ? Colors.white : const Color(0xFF2A2A3D);
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onButton(label),
            child: Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kDarkBg : kLightBg;
    final displayBg = isDark ? kDarkCard : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: Icon(isScientific ? Icons.calculate_rounded : Icons.science_rounded),
            color: kPrimary,
            onPressed: () => setState(() => isScientific = !isScientific),
            tooltip: isScientific ? 'Basic' : 'Scientific',
          ),
        ],
      ),
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Display ────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: displayBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : kPrimary.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(isDark ? 0.1 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2A2A3D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Buttons ────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
              child: Column(
                children: [
                  if (isScientific) ...[
                    Row(children: [
                      _btn('sin', type: _typeScience),
                      _btn('cos', type: _typeScience),
                      _btn('tan', type: _typeScience),
                      _btn('log', type: _typeScience),
                    ]),
                    Row(children: [
                      _btn('√',   type: _typeScience),
                      _btn('x²',  type: _typeScience),
                      _btn('%',   type: _typeAction),
                      _btn('÷',   type: _typeOperator),
                    ]),
                  ],
                  Row(children: [
                    _btn('C',   type: _typeAction),
                    _btn('+/-', type: _typeAction),
                    _btn('⌫',   type: _typeAction),
                    _btn('×',   type: _typeOperator),
                  ]),
                  Row(children: [
                    _btn('7'), _btn('8'), _btn('9'),
                    _btn('-', type: _typeOperator),
                  ]),
                  Row(children: [
                    _btn('4'), _btn('5'), _btn('6'),
                    _btn('+', type: _typeOperator),
                  ]),
                  Row(children: [
                    _btn('1'), _btn('2'), _btn('3'),
                    _btn('=', type: _typeEquals),
                  ]),
                  Row(children: [
                    _btn('0', flex: 2),
                    _btn('.'),
                    if (!isScientific) _btn('÷', type: _typeOperator),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

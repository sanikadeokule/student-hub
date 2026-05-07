import 'package:flutter/material.dart';
import 'dart:math';

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

  bool isScientific = false; // 🔥 NEW

  void _onButton(String val) {
    setState(() {
      double num = double.tryParse(_display) ?? 0;

      if (val == 'C') {
        _display = '0';
        _expression = '';
        _firstOperand = 0;
        _operator = '';
        _shouldReplace = true;
      } else if (val == '⌫') {
        _display =
            _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      }

      // 🔥 SCIENTIFIC FUNCTIONS
      else if (val == 'sin') {
        _display = sin(num).toStringAsFixed(4);
      } else if (val == 'cos') {
        _display = cos(num).toStringAsFixed(4);
      } else if (val == 'tan') {
        _display = tan(num).toStringAsFixed(4);
      } else if (val == 'log') {
        _display = log(num).toStringAsFixed(4);
      } else if (val == '√') {
        _display = sqrt(num).toStringAsFixed(4);
      } else if (val == 'x²') {
        _display = (num * num).toString();
      }

      // BASIC OPERATORS
      else if (['+', '-', '×', '÷'].contains(val)) {
        _firstOperand = num;
        _operator = val;
        _expression = '$_display $val';
        _shouldReplace = true;
      } else if (val == '=') {
        final second = num;
        double result = 0;

        switch (_operator) {
          case '+':
            result = _firstOperand + second;
            break;
          case '-':
            result = _firstOperand - second;
            break;
          case '×':
            result = _firstOperand * second;
            break;
          case '÷':
            result = second != 0 ? _firstOperand / second : 0;
            break;
        }

        _expression = '$_expression $_display =';
        _display = result % 1 == 0
            ? result.toInt().toString()
            : result.toStringAsFixed(4);

        _shouldReplace = true;
        _operator = '';
      } else if (val == '%') {
        _display = (num / 100).toString();
      } else if (val == '+/-') {
        if (_display != '0') {
          _display =
              _display.startsWith('-') ? _display.substring(1) : '-$_display';
        }
      } else if (val == '.') {
        if (!_display.contains('.')) {
          _display = _shouldReplace ? '0.' : _display + '.';
          _shouldReplace = false;
        }
      } else {
        if (_shouldReplace) {
          _display = val;
          _shouldReplace = false;
        } else {
          _display = _display == '0' ? val : _display + val;
        }
      }
    });
  }

  Widget _btn(String label,
      {Color? bg, Color? fg, int flex = 1, double font = 18}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? Colors.white.withOpacity(0.1),
            foregroundColor: fg ?? Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 5,
          ),
          onPressed: () => _onButton(label),
          child: Text(label,
              style:
                  TextStyle(fontSize: font, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        actions: [
          IconButton(
            icon: Icon(isScientific ? Icons.calculate : Icons.science),
            onPressed: () {
              setState(() {
                isScientific = !isScientific;
              });
            },
          )
        ],
      ),

      // 🔥 MODERN UI
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // DISPLAY
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_expression,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(_display,
                        style: const TextStyle(
                            fontSize: 56,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // BUTTONS
            Expanded(
              flex: 5,
              child: Column(
                children: [

                  // 🔥 SCIENTIFIC ROW
                  if (isScientific)
                    Row(children: [
                      _btn('sin'),
                      _btn('cos'),
                      _btn('tan'),
                      _btn('log'),
                    ]),

                  if (isScientific)
                    Row(children: [
                      _btn('√'),
                      _btn('x²'),
                      _btn('%'),
                      _btn('÷', bg: Colors.orange),
                    ]),

                  // BASIC
                  Row(children: [
                    _btn('C', bg: Colors.red),
                    _btn('+/-'),
                    _btn('⌫'),
                    _btn('×', bg: Colors.orange),
                  ]),
                  Row(children: [
                    _btn('7'),
                    _btn('8'),
                    _btn('9'),
                    _btn('-', bg: Colors.orange),
                  ]),
                  Row(children: [
                    _btn('4'),
                    _btn('5'),
                    _btn('6'),
                    _btn('+', bg: Colors.orange),
                  ]),
                  Row(children: [
                    _btn('1'),
                    _btn('2'),
                    _btn('3'),
                    _btn('=', bg: Colors.green),
                  ]),
                  Row(children: [
                    _btn('0', flex: 2),
                    _btn('.'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
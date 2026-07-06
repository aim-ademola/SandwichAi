import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_screen.dart';
import 'package:sandwich_ai/src/features/pos/presentation/session_manager.dart';

class OrderSessionEntryScreen extends StatefulWidget {
  const OrderSessionEntryScreen({super.key});

  @override
  State<OrderSessionEntryScreen> createState() =>
      _OrderSessionEntryScreenState();
}

class _OrderSessionEntryScreenState extends State<OrderSessionEntryScreen> {
  bool _showSessionManager = false;

  @override
  Widget build(BuildContext context) {
    if (_showSessionManager) {
      return SessionManagerScreen(
        onClose: () => setState(() => _showSessionManager = false),
        onResumeSession: (context, session) {
          setState(() => _showSessionManager = false);
        },
      );
    }

    return OrderScreen(
      onOpenSessionManager: () async {
        setState(() => _showSessionManager = true);
      },
    );
  }
}

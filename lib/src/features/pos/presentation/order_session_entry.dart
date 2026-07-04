import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/features/pos/presentation/order_screen.dart';
import 'package:sandwich_ai/src/features/pos/presentation/session_manager.dart';

class OrderSessionEntryScreen extends StatelessWidget {
  const OrderSessionEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionManagerScreen(
      onResumeSession: (context, session) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OrderScreen()));
      },
    );
  }
}

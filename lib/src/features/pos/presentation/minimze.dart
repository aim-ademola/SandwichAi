import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/features/pos/bloc/oder_session/order_session_cubit.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';

class MinimizeButton extends StatelessWidget {
  final String? sessionId;
  final MinimizedScreen screen;

  const MinimizeButton({
    super.key,
    required this.sessionId,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Minimize — switch session',
      icon: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.minimize_rounded, color: kPrimary, size: 18),
      ),
      onPressed: () => _minimize(context),
    );
  }

  void _minimize(BuildContext context) {
    if (sessionId != null) {
      context.read<OrderSessionCubit>().minimizeSession(
        sessionId: sessionId!,
        screen: screen,
      );
    }
    // Pop all the way back to OrderScreen so the cashier
    // can pick another session or create a new one.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

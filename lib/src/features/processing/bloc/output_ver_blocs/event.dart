// bloc/output_verification_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/processing/data/model/output_verfification_model.dart';

abstract class OutputVerificationEvent extends Equatable {
  const OutputVerificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuItems extends OutputVerificationEvent {
  const LoadMenuItems();
}

class LoadRecipe extends OutputVerificationEvent {
  final String menuItemId;

  const LoadRecipe({required this.menuItemId});

  @override
  List<Object?> get props => [menuItemId];
}

class CreateOutputVerification extends OutputVerificationEvent {
  final CreateOutputVerificationRequest request;

  const CreateOutputVerification({required this.request});

  @override
  List<Object?> get props => [request];
}

class LoadOutputVerifications extends OutputVerificationEvent {
  const LoadOutputVerifications();
}

class RefreshOutputVerifications extends OutputVerificationEvent {
  const RefreshOutputVerifications();
}

class SelectMenuItem extends OutputVerificationEvent {
  final MenuItem menuItem;

  const SelectMenuItem({required this.menuItem});

  @override
  List<Object?> get props => [menuItem];
}

class ResetForm extends OutputVerificationEvent {
  const ResetForm();
}

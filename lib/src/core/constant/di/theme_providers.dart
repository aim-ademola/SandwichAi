import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/bloc/theme_cubit.dart';

class ThemeProviders {
  static List<BlocProvider> providers = [
    BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()..initialize()),
  ];
}

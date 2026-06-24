import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/chnage_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/forgot_pwd_repo.dart';
import 'package:sandwich_ai/src/features/auth/data/repo/login_repo.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/cnage_pwd_blocs/bloc.dart';
import 'package:sandwich_ai/src/features/auth/forgot_pwd/reset_pwd_bloc/bloc.dart';
import 'package:sandwich_ai/src/features/auth/login_bloc/login_bloc.dart';

class AuthProviders {
  static List<BlocProvider> providers = [
    BlocProvider<LoginBloc>(
      create: (context) =>
          LoginBloc(loginRepository: context.read<LoginRepositoryInterface>()),
    ),
    BlocProvider<ForgotPasswordBloc>(
      create: (context) => ForgotPasswordBloc(
        repository: context.read<ForgotPasswordRepositoryInterface>(),
      ),
    ),
    BlocProvider<ResetPasswordBloc>(
      create: (context) => ResetPasswordBloc(
        repository: context.read<ForgotPasswordRepositoryInterface>(),
      ),
    ),
    BlocProvider<ChangePasswordBloc>(
      create: (context) => ChangePasswordBloc(
        repository: context.read<ChangePasswordRepositoryInterface>(),
      ),
    ),
  ];
}

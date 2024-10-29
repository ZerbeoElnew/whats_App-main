import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:our_whatsapp/Features/Auth/presentation/manager/cubit/Login/login_cubit.dart';
import 'package:our_whatsapp/Features/Chats/presentation/manager/GetUserDataCubit/get_user_data_cubit.dart';
import 'package:our_whatsapp/Features/Auth/presentation/view/login/Signup.dart';
import 'package:our_whatsapp/Features/Auth/presentation/view/login/verification_page.dart';
import 'package:our_whatsapp/Root.dart';
import '../../Features/Chats/presentation/view/Chat.dart';

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!'));
        } else if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          if (!user.emailVerified) {
            return const VerificationPage();
          }
          context.read<GetUserDataCubit>().getData();
          return BlocBuilder<GetUserDataCubit, GetUserDataState>(
            builder: (context, state) {
              if (state is GetUserDatasuccess) {
                return RootPage(
                  user: state.user,
                );
              } else if (state is GetUserDataloading) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return const SignupPage();
              }
            },
          );
        } else {
          return BlocListener<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.err),
                  ),
                );
              }
            },
            child: const SignupPage(),
          );
        }
      },
    );
  }
}

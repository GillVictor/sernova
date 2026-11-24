import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import 'login_page.dart';
import 'session_controller.dart';

/// Shows the login page until there is a session, then [signedInBuilder].
/// Signing out drops the signed-in area completely, so the next account never
/// sees the previous one's screens or data.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.session, required this.signedInBuilder});

  final SessionController session;
  final WidgetBuilder signedInBuilder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          switch (session.status) {
            case SessionStatus.restoring:
              return Scaffold(
                body: Center(
                  child: Semantics(
                    label: Strings.t('common.loading'),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              );
            case SessionStatus.signedOut:
              return LoginPage(session: session);
            case SessionStatus.signedIn:
              return signedInBuilder(context);
          }
        },
      );
}

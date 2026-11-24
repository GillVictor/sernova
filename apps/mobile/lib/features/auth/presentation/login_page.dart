import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/field_label.dart';
import 'session_controller.dart';

/// "Connexion" (UC01, EP-004). The tokens never reach this widget: it only
/// hands the phone and password to the [SessionController].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _submitted = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _phoneIssue => _submitted && _phone.text.trim().isEmpty
      ? Strings.t('auth.login.validation.phoneRequired')
      : null;

  String? get _passwordIssue => _submitted && _password.text.isEmpty
      ? Strings.t('auth.login.validation.passwordRequired')
      : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) return;
    // On success the gate replaces this page, which drops the typed password.
    await widget.session.login(phone: _phone.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.session,
                builder: (context, _) {
                  final s = widget.session;
                  final failure = s.failure;
                  return AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandLogo(size: 48, color: AppColors.primary)),
                        const SizedBox(height: 16),
                        Text(
                          Strings.t('auth.login.title'),
                          textAlign: TextAlign.center,
                          style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Strings.t('auth.login.subtitle'),
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),
                        FieldLabel(
                          label: Strings.t('auth.login.fields.phone.label'),
                          help: Strings.t('auth.login.fields.phone.help'),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          key: const Key('login-phone'),
                          controller: _phone,
                          enabled: !s.busy,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: InputDecoration(
                            hintText: Strings.t('auth.login.fields.phone.placeholder'),
                            errorText: _phoneIssue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FieldLabel(
                          label: Strings.t('auth.login.fields.password.label'),
                          help: Strings.t('auth.login.fields.password.help'),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          key: const Key('login-password'),
                          controller: _password,
                          enabled: !s.busy,
                          obscureText: !_showPassword,
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            errorText: _passwordIssue,
                            suffixIcon: IconButton(
                              tooltip: Strings.t(_showPassword
                                  ? 'auth.login.fields.password.hide'
                                  : 'auth.login.fields.password.show'),
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        if (failure != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              Strings.error(failure.code,
                                  retryAfterSeconds: failure.retryAfterSeconds),
                              style: t.bodyMedium?.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('login-submit'),
                          onPressed: s.busy ? null : _submit,
                          child: s.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(Strings.t('auth.login.submit')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

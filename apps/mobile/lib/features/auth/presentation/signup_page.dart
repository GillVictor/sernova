import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/field_label.dart';
import '../domain/phone_number.dart';
import 'signup_controller.dart';
import 'verify_phone_page.dart';

/// "Créer un compte" (UC01, EP-001). On success the SMS code page opens.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.controller});

  final SignupController controller;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.clearFailure();
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _v(String key) => Strings.t('auth.signup.validation.$key');

  // Local checks (only after the first submit), then what the server rejected.
  String? get _phoneLocalIssue {
    final p = PhoneNumber.normalize(_phone.text);
    if (p.isEmpty) return _v('phoneRequired');
    if (!PhoneNumber.isE164(p)) return _v('phoneFormat');
    return null;
  }

  String? get _nameLocalIssue => _name.text.trim().isEmpty ? _v('displayNameRequired') : null;

  String? get _emailLocalIssue {
    final e = _email.text.trim();
    if (e.isEmpty) return null;
    return (e.contains('@') && !e.contains(RegExp(r'\s'))) ? null : _v('emailFormat');
  }

  String? get _passwordLocalIssue => _password.text.isEmpty ? _v('passwordRequired') : null;

  String? get _confirmLocalIssue =>
      (_password.text.isNotEmpty && _confirm.text != _password.text) ? _v('passwordMismatch') : null;

  bool get _hasLocalIssue =>
      _phoneLocalIssue != null ||
      _nameLocalIssue != null ||
      _emailLocalIssue != null ||
      _passwordLocalIssue != null ||
      _confirmLocalIssue != null;

  String? _serverIssue(String field) {
    final rejected = widget.controller.failure?.fieldErrors
            .any((e) => e.field.toLowerCase() == field.toLowerCase()) ??
        false;
    return rejected ? _v('fieldRejected') : null;
  }

  String? _issue(String? local, String field) => _submitted ? (local ?? _serverIssue(field)) : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_hasLocalIssue) return;
    final phone = PhoneNumber.normalize(_phone.text);
    final ok = await widget.controller.register(
      phone: phone,
      password: _password.text,
      displayName: _name.text,
      email: _email.text,
    );
    if (ok && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => VerifyPhonePage(controller: widget.controller, phone: phone),
      ));
    }
  }

  Widget _field({
    required String name,
    required Key fieldKey,
    required TextEditingController controller,
    required String? error,
    bool optional = false,
    bool busy = false,
    TextInputType? keyboardType,
    TextInputAction action = TextInputAction.next,
    Iterable<String>? autofill,
    int? maxLength,
    bool password = false,
    Widget? suffix,
    TextCapitalization capitalization = TextCapitalization.none,
    VoidCallback? onSubmitted,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label: Strings.t('auth.signup.fields.$name.label'),
            help: Strings.t('auth.signup.fields.$name.help'),
            optional: optional,
          ),
          const SizedBox(height: 4),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: !busy,
            keyboardType: keyboardType,
            textInputAction: action,
            textCapitalization: capitalization,
            autofillHints: autofill,
            obscureText: password && !_showPassword,
            enableSuggestions: !password,
            autocorrect: !password,
            inputFormatters: maxLength == null ? null : [LengthLimitingTextInputFormatter(maxLength)],
            onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
            decoration: InputDecoration(
              hintText: Strings.t('auth.signup.fields.$name.placeholder'),
              errorText: error,
              suffixIcon: suffix,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(Strings.t('auth.signup.title'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final c = widget.controller;
                  final failure = c.failure;
                  return AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          Strings.t('auth.signup.subtitle'),
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                        const SizedBox(height: 24),
                        _field(
                          name: 'phone',
                          fieldKey: const Key('signup-phone'),
                          controller: _phone,
                          error: _issue(_phoneLocalIssue, 'phone'),
                          busy: c.busy,
                          keyboardType: TextInputType.phone,
                          autofill: const [AutofillHints.telephoneNumber],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          name: 'displayName',
                          fieldKey: const Key('signup-name'),
                          controller: _name,
                          error: _issue(_nameLocalIssue, 'displayName'),
                          busy: c.busy,
                          maxLength: 60,
                          capitalization: TextCapitalization.words,
                          autofill: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          name: 'email',
                          fieldKey: const Key('signup-email'),
                          controller: _email,
                          error: _issue(_emailLocalIssue, 'email'),
                          optional: true,
                          busy: c.busy,
                          maxLength: 254,
                          keyboardType: TextInputType.emailAddress,
                          autofill: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          name: 'password',
                          fieldKey: const Key('signup-password'),
                          controller: _password,
                          error: _issue(_passwordLocalIssue, 'password'),
                          busy: c.busy,
                          password: true,
                          autofill: const [AutofillHints.newPassword],
                          suffix: IconButton(
                            tooltip: Strings.t(_showPassword
                                ? 'auth.signup.fields.password.hide'
                                : 'auth.signup.fields.password.show'),
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          name: 'confirmPassword',
                          fieldKey: const Key('signup-confirm'),
                          controller: _confirm,
                          error: _issue(_confirmLocalIssue, 'confirmPassword'),
                          busy: c.busy,
                          password: true,
                          action: TextInputAction.done,
                          autofill: const [AutofillHints.newPassword],
                          onSubmitted: _submit,
                        ),
                        if (failure != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              Strings.error(failure.code, retryAfterSeconds: failure.retryAfterSeconds),
                              style: t.bodyMedium?.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const Key('signup-submit'),
                          onPressed: c.busy ? null : _submit,
                          child: c.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(Strings.t('auth.signup.submit')),
                        ),
                        TextButton(
                          key: const Key('signup-to-login'),
                          onPressed: c.busy ? null : () => Navigator.of(context).maybePop(),
                          child: Text(Strings.t('auth.signup.toLogin')),
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

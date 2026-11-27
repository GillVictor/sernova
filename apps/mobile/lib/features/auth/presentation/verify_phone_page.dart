import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/field_label.dart';
import 'signup_controller.dart';

/// "Confirmer mon numéro" (UC01, EP-002 and EP-003): the SMS code sent at
/// registration, or at a login refused with PHONE_NOT_VERIFIED. When the code is
/// accepted the user is signed in and the sign-up pages are removed from the
/// navigation stack.
class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key, required this.controller, required this.phone});

  final SignupController controller;

  /// The normalized (E.164) number the code was sent to.
  final String phone;

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final _code = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.clearFailure();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String? get _codeIssue =>
      _submitted && _code.text.trim().isEmpty ? Strings.t('auth.verify.validation.codeRequired') : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_code.text.trim().isEmpty) return;
    final ok = await widget.controller.verifyPhone(phone: widget.phone, code: _code.text);
    // Signed in: the gate now shows the app; drop the sign-up pages above it.
    if (ok && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(Strings.t('auth.verify.title'))),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Strings.t('auth.verify.intro', params: {'phone': widget.phone}),
                        textAlign: TextAlign.center,
                        style: t.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FieldLabel(
                        label: Strings.t('auth.verify.fields.code.label'),
                        help: Strings.t('auth.verify.fields.code.help'),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: const Key('verify-code'),
                        controller: _code,
                        enabled: !c.busy,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: Strings.t('auth.verify.fields.code.placeholder'),
                          errorText: _codeIssue,
                        ),
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
                      if (c.codeResent) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(Strings.t('auth.verify.resent'), style: t.bodyMedium),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('verify-submit'),
                        onPressed: c.busy ? null : _submit,
                        child: c.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(Strings.t('auth.verify.submit')),
                      ),
                      TextButton(
                        key: const Key('verify-resend'),
                        onPressed: c.busy ? null : () => c.resendCode(widget.phone),
                        child: Text(Strings.t('auth.verify.resend')),
                      ),
                    ],
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

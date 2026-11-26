import 'package:flutter/foundation.dart';

import '../../../core/api/api_failure.dart';
import '../data/provider_repository.dart';
import '../domain/provider_activation.dart';

/// State of "Devenir prestataire" (EP-011).
class BecomeProviderController extends ChangeNotifier {
  BecomeProviderController(this._provider);

  final ProviderRepository _provider;

  bool busy = false;
  ApiFailure? failure;
  bool _disposed = false;

  /// Sends the activation; true when the provider capacity is now on. A second
  /// call while one is running does nothing.
  Future<bool> activate(ProviderActivation activation) async {
    if (busy) return false;
    busy = true;
    failure = null;
    _notify();
    try {
      await _provider.activate(activation);
      busy = false;
      _notify();
      return true;
    } catch (e) {
      failure = ApiFailure.from(e);
      busy = false;
      _notify();
      return false;
    }
  }

  void clearFailure() {
    failure = null; // silent: called while a page is being built
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

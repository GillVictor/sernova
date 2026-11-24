import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../data/catalog_repository.dart';
import '../domain/offer_models.dart';
import 'offer_search_controller.dart' show SearchFailure;

enum DetailStatus { loading, ready, notFound, error }

/// State of the offer detail screen (EP-037).
class OfferDetailController extends ChangeNotifier {
  OfferDetailController({required CatalogRepository repository, required this.offerId})
      : _repo = repository;

  final CatalogRepository _repo;
  final String offerId;

  DetailStatus _status = DetailStatus.loading;
  OfferDetail? _detail;
  SearchFailure? _failure;
  int _generation = 0;
  bool _disposed = false;

  DetailStatus get status => _status;
  OfferDetail? get detail => _detail;
  SearchFailure? get failure => _failure;

  Future<void> load() async {
    final gen = ++_generation;
    _status = DetailStatus.loading;
    _failure = null;
    _notify();
    try {
      final d = await _repo.fetchOffer(offerId);
      if (gen != _generation) return;
      _detail = d;
      _status = DetailStatus.ready;
    } on ApiException catch (e) {
      if (gen != _generation) return;
      // 404: unknown, withdrawn or no longer "valable" (hidden from the public).
      _status = e.status == 404 ? DetailStatus.notFound : DetailStatus.error;
      _failure = SearchFailure.from(e);
    } catch (e) {
      if (gen != _generation) return;
      _status = DetailStatus.error;
      _failure = SearchFailure.from(e);
    }
    _notify();
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

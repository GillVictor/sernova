import 'enums.dart';

/// Parameters of EP-035 `GET /offers`. Only the fields that are set are sent.
class OfferSearchQuery {
  const OfferSearchQuery({
    this.q,
    this.categoryId,
    this.locationId,
    this.latitude,
    this.longitude,
    this.coverageOnly,
    this.priceMin,
    this.priceMax,
    this.sort,
    this.limit = 20,
    this.cursor,
  });

  final String? q;
  final String? categoryId;
  final String? locationId; // contract: locationId OR lat+lng
  final double? latitude;
  final double? longitude;
  final bool? coverageOnly;
  final int? priceMin; // smallest currency unit
  final int? priceMax;
  final OfferSort? sort;
  final int limit; // default 20, max 100 (contract)
  final String? cursor;

  OfferSearchQuery withCursor(String? cursor) => OfferSearchQuery(
        q: q,
        categoryId: categoryId,
        locationId: locationId,
        latitude: latitude,
        longitude: longitude,
        coverageOnly: coverageOnly,
        priceMin: priceMin,
        priceMax: priceMax,
        sort: sort,
        limit: limit,
        cursor: cursor,
      );

  Map<String, String> toQueryParameters() => {
        if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
        if (categoryId != null) 'categoryId': categoryId!,
        if (locationId != null) 'locationId': locationId!,
        if (latitude != null && longitude != null) ...{
          'lat': '$latitude',
          'lng': '$longitude',
        },
        if (coverageOnly != null) 'coverageOnly': '$coverageOnly',
        if (priceMin != null) 'priceMin': '$priceMin',
        if (priceMax != null) 'priceMax': '$priceMax',
        if (sort != null) 'sort': sort!.name,
        'limit': '${limit.clamp(1, 100)}',
        if (cursor != null) 'cursor': cursor!,
      };
}

enum PromotionType { percentage, fixedAmount }

int? _parseInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.salePrice,
    required this.thresholdPrice,
    required this.percentage,
    required this.isReservedStock,
    required this.maxReservedStock,
    required this.isLimitedTime,
    required this.startAt,
    required this.endAt,
    required this.isDeleted,
    required this.isDisabled,
  });

  final String id;
  final String name;
  final PromotionType type;
  final double? salePrice;
  final double? thresholdPrice;
  final double? percentage;
  final bool isReservedStock;
  final int? maxReservedStock;
  final bool isLimitedTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isDeleted;
  final bool isDisabled;

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final type = _enumValue(json['promotionType'] ?? json['PromotionType']);
    return Promotion(
      id: (json['promotionId'] ?? json['PromotionId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      type: type.toInt() == 1
          ? PromotionType.fixedAmount
          : PromotionType.percentage,
      salePrice: _double(json['salePrice'] ?? json['SalePrice']),
      thresholdPrice: _double(json['thresholdPrice'] ?? json['ThresholdPrice']),
      percentage: _double(json['percentage'] ?? json['Percentage']),
      isReservedStock: _bool(
        json['isReservedStock'] ?? json['IsReservedStock'],
      ),
      maxReservedStock: _int(
        json['maxReservedStock'] ?? json['MaxReservedStock'],
      ),
      isLimitedTime: _bool(json['isLimitedTime'] ?? json['IsLimitedTime']),
      startAt: _date(json['startAt'] ?? json['StartAt']),
      endAt: _date(json['endAt'] ?? json['EndAt']),
      isDeleted: _bool(json['isDeleted'] ?? json['IsDeleted']),
      isDisabled: _bool(json['isDisabled'] ?? json['IsDisabled']),
    );
    
  }

  static int _enumValue(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      return value.toLowerCase() == 'fixedamount' ? 1 : 0;
    }
    return 0;
  }

  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static bool _bool(Object? value) =>
      value is bool ? value : value?.toString().toLowerCase() == 'true';

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    if (value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value)) {
      return parsed.toLocal();
    }
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  String get status {
    if (isDeleted) return 'Deleted';
    if (isDisabled) return 'Disabled';
    final now = DateTime.now();
    if (isLimitedTime && startAt != null && now.isBefore(startAt!)) {
      return 'Upcoming';
    }
    if (isLimitedTime && endAt != null && now.isAfter(endAt!)) {
      return 'Expired';
    }
    if (isReservedStock && (maxReservedStock ?? 0) <= 0) return 'Out of stock';
    return 'Active';
  }
}

class PromotionInput {
  const PromotionInput({
    required this.name,
    required this.type,
    required this.salePrice,
    required this.thresholdPrice,
    required this.percentage,
    required this.isReservedStock,
    required this.maxReservedStock,
    required this.isLimitedTime,
    required this.startAt,
    required this.endAt,
    required this.isDisable,
  });

  final String name;
  final PromotionType type;
  final double? salePrice;
  final double? thresholdPrice;
  final double? percentage;
  final bool isReservedStock;
  final int? maxReservedStock;
  final bool isLimitedTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isDisable;

  factory PromotionInput.fromPromotion(
    Promotion promotion, {
    required bool isDisable,
  }) {
    return PromotionInput(
      name: promotion.name,
      type: promotion.type,
      salePrice: promotion.salePrice,
      thresholdPrice: promotion.thresholdPrice,
      percentage: promotion.percentage,
      isReservedStock: promotion.isReservedStock,
      maxReservedStock: promotion.maxReservedStock,
      isLimitedTime: promotion.isLimitedTime,
      startAt: promotion.startAt,
      endAt: promotion.endAt,
      isDisable: isDisable,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'promotionType': type == PromotionType.fixedAmount ? 1 : 0,
    'salePrice': salePrice,
    'thresholdPrice': thresholdPrice,
    'percentage': percentage,
    'isReservedStock': isReservedStock,
    'maxReservedStock': maxReservedStock,
    'isLimitedTime': isLimitedTime,
    'startAt': startAt?.toUtc().toIso8601String(),
    'endAt': endAt?.toUtc().toIso8601String(),
    'isDisable': isDisable,
  };
}

class PromotionListResult {
  const PromotionListResult({
    required this.items,
    required this.totalCount,
    required this.activeCount,
    required this.upcomingCount,
    required this.expiredCount,
    required this.page,
    required this.totalPages,
  });

  final List<Promotion> items;
  final int totalCount;
  final int activeCount;
  final int upcomingCount;
  final int expiredCount;
  final int page;
  final int totalPages;

  factory PromotionListResult.fromJson(Map<String, dynamic> json) {
    final pagination = (json['pagination'] ?? json['Pagination']) as Map;
    final items = (pagination['items'] ?? pagination['Items'] ?? []) as List;
    return PromotionListResult(
      items: items
          .map(
            (item) =>
                Promotion.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      totalCount:
          _parseInt(pagination['totalCount'] ?? pagination['TotalCount']) ?? 0,
      activeCount: _parseInt(json['activeCount'] ?? json['ActiveCount']) ?? 0,
      upcomingCount: _parseInt(json['upcoming'] ?? json['Upcoming']) ?? 0,
      expiredCount:
          _parseInt(
            json['expiredOrDisabledCount'] ?? json['ExpiredOrDisabledCount'],
          ) ??
          0,
      page: _parseInt(pagination['page'] ?? pagination['Page']) ?? 1,
      totalPages:
          _parseInt(pagination['totalPages'] ?? pagination['TotalPages']) ?? 0,
    );
  }
}

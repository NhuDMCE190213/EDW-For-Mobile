enum PromotionType { percentage, fixedAmount }

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
    final type = (json['promotionType'] ?? json['PromotionType']) as num? ?? 0;
    return Promotion(
      id: (json['promotionId'] ?? json['PromotionId']) as String,
      name: (json['name'] ?? '') as String,
      type: type.toInt() == 1 ? PromotionType.fixedAmount : PromotionType.percentage,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      thresholdPrice: (json['thresholdPrice'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
      isReservedStock: (json['isReservedStock'] as bool?) ?? true,
      maxReservedStock: (json['maxReservedStock'] as num?)?.toInt(),
      isLimitedTime: (json['isLimitedTime'] as bool?) ?? false,
      startAt: _date(json['startAt']),
      endAt: _date(json['endAt']),
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      isDisabled: (json['isDisabled'] as bool?) ?? false,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

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
          .map((item) => Promotion.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      totalCount: (pagination['totalCount'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      upcomingCount: (json['upcoming'] as num?)?.toInt() ?? 0,
      expiredCount: (json['expiredOrDisabledCount'] as num?)?.toInt() ?? 0,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

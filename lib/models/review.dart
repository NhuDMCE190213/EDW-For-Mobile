class ReviewItem {
  final int id;
  final int productId;
  final String productName;
  final int customerId;
  final String customerName;
  final String customerEmail;
  final int rating;
  final String comment;
  final bool isFlagged;
  final bool isHidden;
  final bool isLockedByAdmin;
  final String status;
  final bool canEdit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.rating,
    required this.comment,
    required this.isFlagged,
    required this.isHidden,
    required this.isLockedByAdmin,
    required this.status,
    required this.canEdit,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    final idVal =
        json['id'] ?? json['Id'] ?? json['reviewId'] ?? json['ReviewId'] ?? 0;
    final productIdVal = json['productId'] ?? json['ProductId'] ?? 0;
    final customerIdVal = json['customerId'] ?? json['CustomerId'] ?? 0;
    final ratingVal = json['rating'] ?? json['Rating'] ?? 5;
    final commentVal =
        json['comment'] ??
        json['Comment'] ??
        json['content'] ??
        json['Content'] ??
        '';
    final isFlaggedVal = json['isFlagged'] ?? json['IsFlagged'] ?? false;
    final isHiddenVal = json['isHidden'] ?? json['IsHidden'] ?? false;
    final isLockedVal =
        json['isLockedByAdmin'] ?? json['IsLockedByAdmin'] ?? isHiddenVal;
    final statusVal =
        json['status'] ??
        json['Status'] ??
        (isHiddenVal
            ? 'Hidden'
            : (isFlaggedVal ? 'Flagged' : 'Published'));
    final canEditVal = json['canEdit'] ?? json['CanEdit'] ?? (!isHiddenVal);
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    final updatedAtRaw = json['updatedAt'] ?? json['UpdatedAt'];

    return ReviewItem(
      id: idVal is num ? idVal.toInt() : int.tryParse(idVal.toString()) ?? 0,
      productId:
          productIdVal is num
              ? productIdVal.toInt()
              : int.tryParse(productIdVal.toString()) ?? 0,
      productName:
          (json['productName'] ?? json['ProductName'] ?? '') as String,
      customerId:
          customerIdVal is num
              ? customerIdVal.toInt()
              : int.tryParse(customerIdVal.toString()) ?? 0,
      customerName:
          (json['customerName'] ?? json['CustomerName'] ?? '') as String,
      customerEmail:
          (json['customerEmail'] ?? json['CustomerEmail'] ?? '') as String,
      rating:
          ratingVal is num
              ? ratingVal.toInt()
              : int.tryParse(ratingVal.toString()) ?? 5,
      comment: commentVal.toString(),
      isFlagged: isFlaggedVal == true,
      isHidden: isHiddenVal == true,
      isLockedByAdmin: isLockedVal == true,
      status: statusVal.toString(),
      canEdit: canEditVal == true,
      createdAt:
          DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now(),
      updatedAt:
          updatedAtRaw != null
              ? DateTime.tryParse(updatedAtRaw.toString())
              : null,
    );
  }
}

class CreateReviewInput {
  final int customerId;
  final int productId;
  final String? orderId;
  final int? orderItemId;
  final int rating;
  final String content;

  CreateReviewInput({
    required this.customerId,
    required this.productId,
    this.orderId,
    this.orderItemId,
    required this.rating,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'productId': productId,
    if (orderId != null) 'orderId': orderId,
    if (orderItemId != null) 'orderItemId': orderItemId,
    'rating': rating,
    'content': content,
    'comment': content,
  };
}

class UpdateReviewInput {
  final int customerId;
  final int rating;
  final String content;

  UpdateReviewInput({
    required this.customerId,
    required this.rating,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'rating': rating,
    'content': content,
    'comment': content,
  };
}

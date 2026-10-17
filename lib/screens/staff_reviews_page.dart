import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/api_exception.dart';
import '../services/review_api.dart';

class StaffReviewsPage extends StatefulWidget {
  const StaffReviewsPage({
    super.key,
    required this.api,
    this.userRole = 'Staff',
  });

  final ReviewApi api;
  final String userRole;

  @override
  State<StaffReviewsPage> createState() => StaffReviewsPageState();
}

class StaffReviewsPageState extends State<StaffReviewsPage> {
  List<ReviewItem> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  int? _selectedRating;
  bool _onlyFlagged = false;

  bool get _isAdmin =>
      widget.userRole.toLowerCase() == 'admin' || widget.userRole == '0';

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refresh() => _fetchReviews();

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reviews = await widget.api.getStaffReviews(
        searchTerm: _searchController.text.trim(),
        rating: _selectedRating,
        onlyFlagged: _onlyFlagged ? true : null,
      );

      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Lỗi tải danh sách đánh giá: $e';
        _isLoading = false;
      });
    }
  }

  // UC-06.2: Flag Review Dialog & API call
  Future<void> _handleFlag(ReviewItem review) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Gắn cờ vi phạm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn muốn gắn cờ đánh giá của "${review.customerName}" cho sản phẩm "${review.productName}"?',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do gắn cờ (tùy chọn)',
                    hintText: 'Ví dụ: Ngôn từ không phù hợp, spam...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.amber[800]),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gắn cờ'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.api.flagReview(
        review.id,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gắn cờ đánh giá thành công.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchReviews();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gắn cờ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Unflag Review
  Future<void> _handleUnflag(ReviewItem review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Gỡ cờ đánh giá'),
            content: Text(
              'Xác nhận gỡ cờ cho đánh giá của "${review.customerName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Gỡ cờ'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.api.unflagReview(review.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gỡ cờ đánh giá.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gỡ cờ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // UC-06.3: Moderate Review (Admin Only - Rule FR-01)
  Future<void> _handleModerate(ReviewItem review) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quy tắc FR-01: Chỉ Quản trị viên (Admin) mới có quyền kiểm duyệt ẩn/hiển thị đánh giá.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final willHide = !review.isHidden;
    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              willHide ? 'Ẩn đánh giá khỏi cửa hàng' : 'Hiển thị lại đánh giá',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  willHide
                      ? 'Đánh giá này sẽ bị ẩn và khách hàng không thể nhìn thấy hoặc chỉnh sửa.'
                      : 'Đánh giá này sẽ được công khai hiển thị lại trên sản phẩm.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú kiểm duyệt (tùy chọn)',
                    hintText: 'Nhập lý do kiểm duyệt...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: willHide ? Colors.red : Colors.green,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(willHide ? 'Xác nhận ẩn' : 'Hiển thị lại'),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    try {
      await widget.api.moderateReview(
        review.id,
        isHidden: willHide,
        note: noteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willHide
                ? 'Đã ẩn đánh giá thành công.'
                : 'Đã hiển thị lại đánh giá thành công.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _fetchReviews();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kiểm duyệt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildStatusChip(ReviewItem review) {
    if (review.isHidden) {
      return Chip(
        label: const Text('Đã ẩn (Hidden)'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(
          color: Colors.red.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
    if (review.isFlagged) {
      return Chip(
        label: const Text('Bị gắn cờ (Flagged)'),
        backgroundColor: Colors.amber.shade100,
        labelStyle: TextStyle(
          color: Colors.amber.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }
    return Chip(
      label: const Text('Hiển thị (Published)'),
      backgroundColor: Colors.green.shade100,
      labelStyle: TextStyle(
        color: Colors.green.shade900,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thanh tìm kiếm và bộ lọc (UC-06.1)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm, khách hàng, nội dung...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchReviews();
                            },
                          )
                          : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _fetchReviews(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả sao'),
                      selected: _selectedRating == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRating = null);
                          _fetchReviews();
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ...List.generate(5, (idx) {
                      final star = 5 - idx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          avatar: const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          label: Text('$star★'),
                          selected: _selectedRating == star,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRating = selected ? star : null;
                            });
                            _fetchReviews();
                          },
                        ),
                      );
                    }),
                    FilterChip(
                      avatar: const Icon(
                        Icons.flag,
                        color: Colors.amber,
                        size: 16,
                      ),
                      label: const Text('Bị gắn cờ'),
                      selected: _onlyFlagged,
                      onSelected: (selected) {
                        setState(() => _onlyFlagged = selected);
                        _fetchReviews();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Danh sách đánh giá
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _fetchReviews,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                  : _reviews.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reviews_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy đánh giá nào.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _fetchReviews,
                    child: ListView.builder(
                      itemCount: _reviews.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final formattedDate =
                            '${review.createdAt.day.toString().padLeft(2, '0')}/${review.createdAt.month.toString().padLeft(2, '0')}/${review.createdAt.year}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hàng đầu: Tên sản phẩm & Status
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStatusChip(review),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Thông tin khách hàng & ngày
                                Row(
                                  children: [
                                    Text(
                                      review.customerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (review.customerEmail.isNotEmpty)
                                      Text(
                                        ' (${review.customerEmail})',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Số sao đánh giá
                                _buildStarRating(review.rating),
                                const SizedBox(height: 8),

                                // Nội dung đánh giá
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    review.comment.isNotEmpty
                                        ? review.comment
                                        : '(Không có lời bình luận)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Nút hành động
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // UC-06.2: Gắn cờ / Gỡ cờ
                                    if (!review.isFlagged && !review.isHidden)
                                      OutlinedButton.icon(
                                        onPressed: () => _handleFlag(review),
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        label: const Text(
                                          'Gắn cờ',
                                          style: TextStyle(color: Colors.amber),
                                        ),
                                      ),
                                    if (review.isFlagged)
                                      OutlinedButton.icon(
                                        onPressed: () => _handleUnflag(review),
                                        icon: const Icon(
                                          Icons.outlined_flag,
                                          size: 16,
                                        ),
                                        label: const Text('Gỡ cờ'),
                                      ),

                                    const SizedBox(width: 8),

                                    // UC-06.3: Kiểm duyệt (Admin Only - Rule FR-01)
                                    if (_isAdmin)
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              review.isHidden
                                                  ? Colors.green
                                                  : Colors.red.shade700,
                                        ),
                                        onPressed:
                                            () => _handleModerate(review),
                                        icon: Icon(
                                          review.isHidden
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 16,
                                        ),
                                        label: Text(
                                          review.isHidden
                                              ? 'Hiện lại'
                                              : 'Ẩn đánh giá',
                                        ),
                                      )
                                    else
                                      Tooltip(
                                        message:
                                            'Quy tắc FR-01: Chỉ Quản trị viên (Admin) mới có quyền ẩn/hiển thị đánh giá.',
                                        child: Text(
                                          'Chỉ Admin kiểm duyệt (FR-01)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

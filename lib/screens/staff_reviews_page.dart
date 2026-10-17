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

        // Danh sách đánh giá (UC-06.1)
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
                                _buildStarRating(review.rating),
                                const SizedBox(height: 8),
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

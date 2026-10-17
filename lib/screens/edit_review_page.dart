import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/api_exception.dart';
import '../services/review_api.dart';

class EditReviewPage extends StatefulWidget {
  const EditReviewPage({
    super.key,
    required this.api,
    required this.review,
    required this.customerId,
  });

  final ReviewApi api;
  final ReviewItem review;
  final int customerId;

  @override
  State<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends State<EditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late int _rating;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _commentController = TextEditingController(text: widget.review.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final input = UpdateReviewInput(
        customerId: widget.customerId,
        rating: _rating,
        content: _commentController.text.trim(),
      );

      await widget.api.updateReview(widget.review.id, input);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật đánh giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildStarPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: _submitting ? null : () => setState(() => _rating = starValue),
          icon: Icon(
            starValue <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 38,
          ),
          tooltip: '$starValue sao',
        );
      }),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Tuyệt vời (5/5)';
      case 4:
        return 'Rất tốt (4/5)';
      case 3:
        return 'Bình thường (3/5)';
      case 2:
        return 'Chưa hài lòng (2/5)';
      case 1:
        return 'Rất tệ (1/5)';
      default:
        return '$rating sao';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa đánh giá'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin sản phẩm đang sửa
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đang chỉnh sửa đánh giá cho:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.review.productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Chọn số sao
              const Text(
                'Mức độ hài lòng của bạn:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _buildStarPicker(),
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Sửa nội dung
              const Text(
                'Nội dung nhận xét (tối đa 1000 ký tự):',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLength: 1000,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung nhận xét của bạn...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập nội dung nhận xét.';
                  }
                  if (val.trim().length < 5) {
                    return 'Nội dung nhận xét phải có ít nhất 5 ký tự.';
                  }
                  if (val.trim().length > 1000) {
                    return 'Nội dung nhận xét không được vượt quá 1000 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Báo lỗi
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Nút lưu thay đổi
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_submitting ? 'Đang lưu...' : 'Lưu Thay Đổi'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFE24B4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Định dạng tiền tệ dùng chung toàn app: 1,250,000 VND
String formatVnd(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '${amount < 0 ? '-' : ''}$grouped VND';
}

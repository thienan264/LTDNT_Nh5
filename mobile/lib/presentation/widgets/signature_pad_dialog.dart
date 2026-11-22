import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SignaturePadDialog extends StatefulWidget {
  final String title;
  final String logType; // 'DELIVERY' | 'RETURN'
  final String defaultSignerName;

  const SignaturePadDialog({
    super.key,
    required this.title,
    required this.logType,
    this.defaultSignerName = '',
  });

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<Offset?> _points = [];
  late TextEditingController _signerController;
  late TextEditingController _handlerController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _signerController = TextEditingController(text: widget.defaultSignerName);
    _handlerController = TextEditingController(text: 'Nhân viên quản lý kho');
    _notesController = TextEditingController(
      text: widget.logType == 'DELIVERY'
          ? 'Máy đầy đủ phụ kiện, hoạt động bình thường, không nứt vỡ.'
          : 'Đã kiểm tra thu hồi máy, vận hành ổn định.',
    );
  }

  @override
  void dispose() {
    _signerController.dispose();
    _handlerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _exportSvgPath() {
    if (_points.isEmpty) return '';
    final buffer = StringBuffer();
    bool isNewPath = true;

    for (final point in _points) {
      if (point == null) {
        isNewPath = true;
      } else {
        if (isNewPath) {
          buffer.write(
            'M${point.dx.toStringAsFixed(1)},${point.dy.toStringAsFixed(1)} ',
          );
          isNewPath = false;
        } else {
          buffer.write(
            'L${point.dx.toStringAsFixed(1)},${point.dy.toStringAsFixed(1)} ',
          );
        }
      }
    }
    return buffer.toString().trim();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_points.where((p) => p != null).length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng ký tên vào khung trước khi xác nhận!'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
      return;
    }

    final svgPath = _exportSvgPath();
    Navigator.pop(context, {
      'log_type': widget.logType,
      'handled_by': _handlerController.text.trim(),
      'signer_name': _signerController.text.trim(),
      'signature_data': svgPath,
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.logType == 'DELIVERY'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFF0D9488).withValues(alpha: 0.1),
                      child: Icon(
                        widget.logType == 'DELIVERY'
                            ? Icons.draw
                            : Icons.assignment_turned_in,
                        color: widget.logType == 'DELIVERY'
                            ? AppColors.primary
                            : const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Signer Name
                TextFormField(
                  controller: _signerController,
                  decoration: InputDecoration(
                    labelText: 'Người ký đại diện bên thuê *',
                    hintText: 'Họ và tên người ký nhận',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Vui lòng nhập tên người ký'
                      : null,
                ),
                const SizedBox(height: 12),

                // Handler Name
                TextFormField(
                  controller: _handlerController,
                  decoration: InputDecoration(
                    labelText: 'Nhân viên phụ trách *',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Vui lòng nhập người phụ trách'
                      : null,
                ),
                const SizedBox(height: 12),

                // Notes / Condition
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Hiện trạng thiết bị & Ghi chú',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Signature Canvas Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ký tên bằng tay vào ô bên dưới:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _points.clear()),
                      icon: const Icon(
                        Icons.refresh,
                        size: 16,
                        color: AppColors.statusBroken,
                      ),
                      label: const Text(
                        'Xóa chữ ký',
                        style: TextStyle(
                          color: AppColors.statusBroken,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Signature Canvas
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.blueGrey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final localPos = details.localPosition;
                        setState(() {
                          _points.add(localPos);
                        });
                      },
                      onPanEnd: (details) => setState(() => _points.add(null)),
                      child: CustomPaint(
                        painter: _SignaturePainter(points: _points),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Lưu biên bản'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.logType == 'DELIVERY'
                              ? AppColors.primary
                              : const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Widget hiển thị lại chữ ký đã lưu từ chuỗi đường dẫn vector
class SignaturePreviewWidget extends StatelessWidget {
  final String svgPath;
  final double height;

  const SignaturePreviewWidget({
    super.key,
    required this.svgPath,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (svgPath.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '(Chưa có chữ ký)',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    final points = _parseSvgPath(svgPath);

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(painter: _SignaturePainter(points: points)),
    );
  }

  List<Offset?> _parseSvgPath(String path) {
    final List<Offset?> points = [];
    final tokens = path.trim().split(' ');
    for (final token in tokens) {
      if (token.startsWith('M') || token.startsWith('L')) {
        final coords = token.substring(1).split(',');
        if (coords.length == 2) {
          final x = double.tryParse(coords[0]);
          final y = double.tryParse(coords[1]);
          if (x != null && y != null) {
            if (token.startsWith('M') && points.isNotEmpty) {
              points.add(null);
            }
            points.add(Offset(x, y));
          }
        }
      }
    }
    return points;
  }
}

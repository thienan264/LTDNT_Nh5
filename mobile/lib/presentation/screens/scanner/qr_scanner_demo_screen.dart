import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/device_repository.dart';
import '../devices/device_detail_screen.dart';

class QrScannerDemoScreen extends StatefulWidget {
  const QrScannerDemoScreen({super.key});

  @override
  State<QrScannerDemoScreen> createState() => _QrScannerDemoScreenState();
}

class _QrScannerDemoScreenState extends State<QrScannerDemoScreen> {
  final TextEditingController _codeController = TextEditingController(
    text: 'QR-TB-DL-001',
  );
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isLoading = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isLoading) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _codeController.text = code;
        _lookupDevice(code);
        break;
      }
    }
  }

  void _lookupDevice(String code) async {
    if (code.trim().isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    final device = await DeviceRepository.lookupDevice(code.trim());
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (device != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: device)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy thiết bị với mã: $code'),
          backgroundColor: AppColors.statusBroken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quét mã QR / Serial kiểm kê'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: AppColors.primary,
            ),
            tooltip: 'Bật/Tắt Flash',
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cameraswitch_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Đổi Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Camera Scanner View
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 320,
                width: double.infinity,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.no_photography_outlined,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Không thể mở Camera: ${error.errorDetails?.message ?? error.errorCode.name}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Viewfinder Target Frame
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    if (_isLoading)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),

                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Text(
                          'Hướng camera vào mã QR thiết bị',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Manual Code Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoặc nhập mã Serial / QR thủ công:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Mã QR hoặc Serial',
                      hintText: 'VD: QR-TB-DL-001 hoặc TB-DL-001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _lookupDevice(_codeController.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mã mẫu để thử nhanh:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('QR-TB-DL-001'),
                        onPressed: () {
                          _codeController.text = 'QR-TB-DL-001';
                          _lookupDevice('QR-TB-DL-001');
                        },
                      ),
                      ActionChip(
                        label: const Text('QR-TB-CT-001'),
                        onPressed: () {
                          _codeController.text = 'QR-TB-CT-001';
                          _lookupDevice('QR-TB-CT-001');
                        },
                      ),
                      ActionChip(
                        label: const Text('QR-TB-VP-001'),
                        onPressed: () {
                          _codeController.text = 'QR-TB-VP-001';
                          _lookupDevice('QR-TB-VP-001');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

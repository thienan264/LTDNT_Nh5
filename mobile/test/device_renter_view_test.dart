import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/device_model.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/data/repositories/member_repository.dart';
import 'package:mobile/presentation/screens/devices/device_detail_screen.dart';
import 'package:mobile/presentation/widgets/device_card.dart';

DeviceModel device({
  DeviceStatus status = DeviceStatus.rented,
  bool mine = false,
  String? rentalStatus,
}) => DeviceModel(
  id: 12,
  serialNumber: 'EPSON-001',
  name: 'Máy chiếu Epson',
  categoryName: 'Thiết bị văn phòng',
  status: status,
  rentalPricePerDay: 250000,
  qrCode: 'DEV-EPSON-001',
  isRentedByMe: mine,
  myRentalStatus: rentalStatus,
);

void main() {
  void login(String role) {
    MemberRepository.currentUserNotifier.value = UserModel(
      id: 2,
      username: 'tester',
      email: 'tester@rental.com',
      fullName: 'Tester',
      phoneNumber: '',
      role: role,
    );
  }

  setUp(() => login('MEMBER'));
  tearDown(MemberRepository.logout);

  testWidgets('Thẻ phân biệt chủ thuê ở màn hình hẹp', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in [
      (device(mine: true, rentalStatus: 'Renting'), 'Bạn đang thuê'),
      (device(mine: true, rentalStatus: 'Pending'), 'Bạn đã đặt thuê'),
      (device(), 'Đã có khách thuê'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceCard(device: entry.$1, onTap: () {}),
          ),
        ),
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Người thuê không thấy thu hồi, vị trí nội bộ hoặc đổi trạng thái',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DeviceDetailScreen(device: device())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thu hồi thiết bị (Nhập lại vào kho)'), findsNothing);
      expect(find.text('Vị trí & Đơn vị đang sử dụng'), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(find.text('Lịch sử thuê của bạn'), findsOneWidget);
      expect(
        find.text(
          'Thiết bị đã có khách khác thuê. Vui lòng chọn thiết bị sẵn sàng.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Không tải được lịch sử. Nhấn để thử lại'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Máy sẵn sàng không hiện bàn giao hoặc bảo trì cho người thuê', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceDetailScreen(
          device: device(status: DeviceStatus.available),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bàn giao ngay'), findsNothing);
    expect(find.text('Bảo trì'), findsNothing);
    expect(find.text('Báo hỏng'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin vẫn thấy thao tác thu hồi máy', (tester) async {
    login('ADMIN');
    await tester.pumpWidget(
      MaterialApp(home: DeviceDetailScreen(device: device())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thu hồi thiết bị (Nhập lại vào kho)'), findsOneWidget);
    expect(find.text('Vị trí & Đơn vị đang sử dụng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

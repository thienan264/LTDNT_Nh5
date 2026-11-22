import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/rental_model.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/data/repositories/member_repository.dart';
import 'package:mobile/presentation/screens/rentals/rental_detail_screen.dart';

void main() {
  for (final status in [RentalStatus.approved, RentalStatus.returned]) {
    testWidgets('Chi tiết hợp đồng ${status.name} không tràn ở màn hình hẹp', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MemberRepository.currentUserNotifier.value = UserModel(
        id: 1,
        username: 'admin',
        email: 'admin@rental.com',
        fullName: 'Admin',
        phoneNumber: '',
        role: 'ADMIN',
      );
      addTearDown(MemberRepository.logout);
      final rental = RentalModel(
        id: 1,
        contractCode: 'HD-2CCDDACED45A',
        unitName: 'Kho trung tâm',
        unitAddress: 'Địa chỉ công trình dài để kiểm tra xuống dòng',
        contactPerson: 'Thành viên có tên liên hệ dài',
        phoneNumber: '0901234567',
        startDate: DateTime(2026, 11, 13),
        expectedEndDate: DateTime(2026, 11, 20),
        totalDeposit: 315000,
        status: status,
        estimatedTotalCost: 1050000,
        deviceNames: ['Máy thủy bình Sokkia B40A'],
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: RentalDetailScreen(rental: rental),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('HD-2CCDDACED45A'), findsOneWidget);
    });
  }
}

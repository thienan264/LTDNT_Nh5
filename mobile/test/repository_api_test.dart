import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/repositories/member_repository.dart';
import 'package:mobile/data/repositories/category_repository.dart';
import 'package:mobile/data/repositories/device_repository.dart';
import 'package:mobile/data/repositories/unit_repository.dart';
import 'package:mobile/data/repositories/rental_repository.dart';
import 'package:mobile/data/models/device_model.dart';

void main() {
  test(
    'Repository Flutter đọc và ghi API C# thật',
    () async {
      HttpOverrides.global = null;
      MemberRepository.logout();
      final invalid = await MemberRepository.login('admin', 'wrong');
      expect(invalid['success'], false);
      expect(MemberRepository.currentUser, isNull);
      final login = await MemberRepository.login('admin', 'Admin@123');
      expect(login['success'], true);
      expect(MemberRepository.isAdmin, true);
      expect(MemberRepository.currentUser!.token, isNotEmpty);
      final page = await DeviceRepository.getDevicesPaged(limit: 1);
      expect((page['devices'] as List<DeviceModel>).length, 1);
      expect(page['total_pages'], greaterThanOrEqualTo(1));
      expect(await UnitRepository.getUnits(), isNotEmpty);
      expect(await RentalRepository.getRentals(), isA<List>());
      final name = 'AUDIT Flutter ${DateTime.now().microsecondsSinceEpoch}';
      final category = await CategoryRepository.createCategory(
        name: name,
        description: 'Kiểm thử repository Flutter',
      );
      expect(category, isNotNull);
      final updated = await CategoryRepository.updateCategory(
        id: category!.id,
        name: '$name edited',
        description: 'Updated',
      );
      expect(updated!.name, '$name edited');
      final deleted = await CategoryRepository.deleteCategory(category.id);
      expect(deleted['success'], true);
      MemberRepository.logout();
      expect(MemberRepository.currentUser, isNull);
    },
    skip: !const bool.fromEnvironment('LIVE_API'),
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

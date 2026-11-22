import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/main.dart';
import 'package:mobile/data/repositories/member_repository.dart';
import 'package:mobile/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('Khởi động yêu cầu đăng nhập, không tự cấp quyền Admin', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    MemberRepository.logout();
    await tester.pumpWidget(const EquipmentRentalApp());
    expect(MemberRepository.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/admin_context/domain/admin_current_context.dart';
import 'package:vidxon_admin/features/admin_context/presentation/admin_context_scope.dart';
import 'package:vidxon_admin/features/audit/data/admin_audit_repository.dart';
import 'package:vidxon_admin/features/audit/domain/admin_audit_entry.dart';
import 'package:vidxon_admin/features/audit/presentation/admin_audit_page.dart';

const _actorId = '11111111-1111-1111-1111-111111111111';

AdminCurrentContext _adminContext() {
  return AdminCurrentContext.fromMap({
    'user_id': _actorId,
    'role': 'admin',
    'is_super_admin': false,
  });
}

class _FakeAuditRepository extends AdminAuditRepository {
  _FakeAuditRepository() : super(client: null);

  int listCallCount = 0;
  String? lastActionType;
  String? lastTargetUserId;

  @override
  Future<List<AdminAuditEntry>> listAuditLog({
    String? actionType,
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    listCallCount += 1;
    lastActionType = actionType;
    lastTargetUserId = targetUserId;
    return const [];
  }
}

Widget _wrapAuditPage({
  required AdminAuditRepository repository,
  AdminContextLoadResult? contextResult,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181818),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
      ),
    ),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child ?? const SizedBox.shrink(),
      );
    },
    home: AdminContextScope(
      contextResult:
          contextResult ?? AdminContextLoadResult.loaded(_adminContext()),
      child: Scaffold(body: AdminAuditPage(repository: repository)),
    ),
  );
}

Future<void> _pumpAuditPage(
  WidgetTester tester, {
  required Size surfaceSize,
  AdminAuditRepository? repository,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final fakeRepository = repository ?? _FakeAuditRepository();
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _wrapAuditPage(repository: fakeRepository, textScaler: textScaler),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminAuditPage filters layout', () {
    testWidgets(
      'renders action type dropdown at desktop width without overflow',
      (tester) async {
        await _pumpAuditPage(tester, surfaceSize: const Size(1400, 900));

        expect(find.text('İşlem türü'), findsOneWidget);
        expect(find.text('Tümü'), findsOneWidget);
        expect(find.text('Yenile'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders filters at 1200px without overflow', (tester) async {
      await _pumpAuditPage(tester, surfaceSize: const Size(1200, 900));

      expect(find.text('İşlem türü'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders filters at 900px without overflow', (tester) async {
      await _pumpAuditPage(tester, surfaceSize: const Size(900, 900));

      expect(find.text('İşlem türü'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps filters on narrow width without overflow', (
      tester,
    ) async {
      await _pumpAuditPage(tester, surfaceSize: const Size(480, 900));

      expect(find.text('İşlem türü'), findsOneWidget);
      expect(find.text('Hedef kullanıcı ID'), findsOneWidget);
      expect(find.text('Yenile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports large text scale without overflow', (tester) async {
      await _pumpAuditPage(
        tester,
        surfaceSize: const Size(1200, 900),
        textScaler: const TextScaler.linear(1.4),
      );

      expect(find.text('İşlem türü'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropdown selection keeps filter behavior', (tester) async {
      final repository = _FakeAuditRepository();
      await _pumpAuditPage(
        tester,
        surfaceSize: const Size(1400, 900),
        repository: repository,
      );

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jeton Yükleme').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yenile'));
      await tester.pumpAndSettle();

      expect(repository.listCallCount, greaterThan(1));
      expect(repository.lastActionType, AdminAuditActionType.walletCredit);
    });

    testWidgets('refresh button triggers reload', (tester) async {
      final repository = _FakeAuditRepository();
      await _pumpAuditPage(
        tester,
        surfaceSize: const Size(1400, 900),
        repository: repository,
      );

      final initialCalls = repository.listCallCount;
      await tester.tap(find.text('Yenile'));
      await tester.pumpAndSettle();

      expect(repository.listCallCount, greaterThan(initialCalls));
    });
  });
}

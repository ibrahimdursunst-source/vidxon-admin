import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidxon_admin/features/content_rating/presentation/synopsis_preview.dart';

void main() {
  testWidgets('shows synopsis when present', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SynopsisPreview(synopsis: 'Kısa özet metni'),
        ),
      ),
    );

    expect(find.text('Kısa özet metni'), findsOneWidget);
  });

  testWidgets('renders nothing when synopsis empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Başlık'),
              SynopsisPreview(synopsis: '   '),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SynopsisPreview), findsOneWidget);
    expect(find.text('   '), findsNothing);
    expect(find.textContaining('özet'), findsNothing);
  });
}

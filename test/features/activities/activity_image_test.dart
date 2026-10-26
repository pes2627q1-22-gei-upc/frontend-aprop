import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aprop/app/theme/app_theme.dart';
import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/activities/presentation/widgets/activity_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'activity_filter_test_data.dart';

class _Client extends Fake implements HttpClient {
  _Client(this.bytes, {this.status = 200});
  final Uint8List bytes;
  final int status;
  final requested = <Uri>[];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _Request(_Response(bytes, status));
  }
}

class _Request extends Fake implements HttpClientRequest {
  _Request(this.response);
  final HttpClientResponse response;
  @override
  Future<HttpClientResponse> close() async => response;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.bytes, this.statusCode);
  final Uint8List bytes;
  @override
  final int statusCode;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => PaintingBinding.instance.imageCache.clear());
  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Activity remote(String url) => Activity(
    id: '1',
    title: 'Concert',
    category: 'Música',
    municipality: 'Girona',
    startsAt: DateTime(2026, 11, 14),
    imageAsset: '',
    imageUrl: url,
    source: ActivitySource.culturalAgenda,
  );
  Future<void> pump(WidgetTester tester, Activity activity) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: ActivityImage(activity: activity, width: 112, height: 112),
            ),
          ),
        ),
      );

  testWidgets('Remote covers decode and replace their loading placeholder', (
    tester,
  ) async {
    final png = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 2, 2),
        Paint()..color = Colors.green,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(2, 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    });
    final client = _Client(png!);
    debugNetworkImageHttpClientProvider = () => client;
    await tester.runAsync(() async {
      await pump(tester, remote('https://images.example.test/concert.png'));
      final provider = tester.widget<Image>(find.byType(Image)).image;
      final stream = provider.resolve(ImageConfiguration.empty);
      final ready = Completer<void>();
      final listener = ImageStreamListener(
        (image, synchronous) {
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? trace) {
          if (!ready.isCompleted) ready.completeError(error, trace);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
    expect(
      client.requested.single.toString(),
      'https://images.example.test/concert.png',
    );
    debugNetworkImageHttpClientProvider = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed remote images display an accessible fallback', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () =>
        _Client(Uint8List(0), status: 404);
    final semantics = tester.ensureSemantics();
    await pump(tester, remote('https://images.example.test/missing.png'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('Concert'), findsOneWidget);
    debugNetworkImageHttpClientProvider = null;
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Existing demo assets retain their image provider', (
    tester,
  ) async {
    await pump(tester, event('Demo', DateTime(2026, 11)));
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

# Plantilles (pantalla-flutter)

Substitueix `Thing`/`things`/`<f>` pel nom real (glossari: `docs/ai/70-glossari.md`). Segueixen el patró de
`ActivityDetailsViewModel` i `ActivityDetailsScreen`.

## Contracte

```dart
import '../models/thing.dart';

abstract interface class ThingRepository {
  Future<List<Thing>> getThings();
}
```

## ViewModel

```dart
import 'package:flutter/foundation.dart';

import '../../models/thing.dart';
import '../../repositories/thing_repository.dart';

class ThingsViewModel extends ChangeNotifier {
  ThingsViewModel({required ThingRepository repository}) : _repository = repository;

  final ThingRepository _repository;

  List<Thing> _things = const [];
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  List<Thing> get things => _things;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _errorMessage == null && _things.isEmpty;

  Future<void> load() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getThings();
      if (_isDisposed) return;
      _things = List.unmodifiable(result);
    } catch (_) {
      if (_isDisposed) return;
      _errorMessage = 'No hem pogut carregar les dades. Torna-ho a provar.';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
```

## Pantalla

```dart
import 'package:flutter/material.dart';

import '../../repositories/thing_repository.dart';
import '../view_models/things_view_model.dart';

class ThingsScreen extends StatefulWidget {
  const ThingsScreen({super.key, required this.repository, required this.onThingSelected});

  final ThingRepository repository;
  final ValueChanged<String> onThingSelected;

  @override
  State<ThingsScreen> createState() => _ThingsScreenState();
}

class _ThingsScreenState extends State<ThingsScreen> {
  late ThingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ThingsViewModel(repository: widget.repository)..load();
  }

  @override
  void didUpdateWidget(covariant ThingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _viewModel.dispose();
      _viewModel = ThingsViewModel(repository: widget.repository)..load();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = _viewModel.errorMessage;
        if (error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _viewModel.load, child: const Text('Torna-ho a provar')),
              ],
            ),
          );
        }
        if (_viewModel.isEmpty) {
          return const Center(child: Text('Encara no hi ha res per mostrar.'));
        }
        return ListView.builder(
          itemCount: _viewModel.things.length,
          itemBuilder: (context, index) {
            final thing = _viewModel.things[index];
            return ListTile(
              title: Text(thing.title),
              onTap: () => widget.onThingSelected(thing.id),
            );
          },
        );
      },
    );
  }
}
```

## Fake i proves

```dart
// test/features/<f>/fake_thing_repository.dart
class FakeThingRepository implements ThingRepository {
  Future<List<Thing>> Function() onGetThings = () async => const [];
  int requests = 0;

  @override
  Future<List<Thing>> getThings() {
    requests++;
    return onGetThings();
  }
}
```

```dart
test('Ignora una segona càrrega mentre la primera és en curs', () async {
  final pending = Completer<List<Thing>>();
  repository.onGetThings = () => pending.future;
  final first = viewModel.load();
  await viewModel.load();
  pending.complete(const []);
  await first;
  expect(repository.requests, 1);
});

testWidgets('Mostra l\'error i torna a carregar', (tester) async {
  repository.onGetThings = () async => throw Exception();
  await tester.pumpWidget(MaterialApp(home: Scaffold(
    body: ThingsScreen(repository: repository, onThingSelected: (_) {}),
  )));
  await tester.pump();
  expect(find.text('Torna-ho a provar'), findsOneWidget);
  repository.onGetThings = () async => [thing];
  await tester.tap(find.text('Torna-ho a provar'));
  await tester.pump();
  expect(find.text(thing.title), findsOneWidget);
});
```

Si el projecte ja té un tema de prova (`AppTheme.light`), embolcalla el `MaterialApp` amb `theme: AppTheme.light`.

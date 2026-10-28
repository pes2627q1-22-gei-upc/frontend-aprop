/// Shape returned by api-aprop's event_model.Event (kebab-case).
Map<String, Object?> backendEvent(int id) => {
  'id': id,
  'title': 'Activitat $id',
  'description': 'Descripció de prova del servidor.',
  'start-date': '2026-11-14T00:00:00Z',
  'is-official': true,
  'categories': ['agenda:categories/musica', 'agenda:ambits/concerts'],
  'municipality': 'agenda:ubicacions/girona/girones/girona',
  'free': null,
  'images': '',
};

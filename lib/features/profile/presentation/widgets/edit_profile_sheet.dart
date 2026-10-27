import 'package:flutter/material.dart';

import '../view_models/profile_view_model.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.viewModel});
  final ProfileViewModel viewModel;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _biography = TextEditingController(
    text: widget.viewModel.profile!.biography,
  );
  late final _municipality = TextEditingController(
    text: widget.viewModel.profile!.municipality,
  );
  late final _name = TextEditingController(
    text: widget.viewModel.profile!.displayName,
  );
  late final _username = TextEditingController(
    text: widget.viewModel.profile!.username,
  );

  @override
  void dispose() {
    _biography.dispose();
    _municipality.dispose();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, child) {
      final saving = widget.viewModel.isSaving;
      return PopScope(
        canPop: !saving,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Editar perfil',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tancar',
                        onPressed: saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.viewModel.capabilities.editIdentity) ...[
                    TextFormField(
                      controller: _name,
                      enabled: !saving,
                      validator: ProfileViewModel.validateName,
                      maxLength: 100,
                      onChanged: (_) => widget.viewModel.clearSaveError(),
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _username,
                      enabled: !saving,
                      autocorrect: false,
                      validator: ProfileViewModel.validateUsername,
                      maxLength: 30,
                      onChanged: (_) => widget.viewModel.clearSaveError(),
                      decoration: const InputDecoration(
                        labelText: 'Nom d’usuari',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _biography,
                    enabled: !saving,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => widget.viewModel.clearSaveError(),
                    validator: ProfileViewModel.validateBiography,
                    decoration: const InputDecoration(labelText: 'Biografia'),
                  ),
                  const SizedBox(height: 12),
                  if (widget.viewModel.capabilities.editMunicipality)
                    TextFormField(
                      controller: _municipality,
                      enabled: !saving,
                      maxLength: 80,
                      validator: ProfileViewModel.validateMunicipality,
                      decoration: const InputDecoration(labelText: 'Municipi'),
                    )
                  else
                    const Text(
                      'L’edició del municipi estarà disponible properament.',
                    ),
                  if (widget.viewModel.saveError case final error?) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final saved = await widget.viewModel.saveDetails(
                              biography: _biography.text,
                              municipality: _municipality.text,
                              name: widget.viewModel.capabilities.editIdentity
                                  ? _name.text
                                  : null,
                              username:
                                  widget.viewModel.capabilities.editIdentity
                                  ? _username.text
                                  : null,
                            );
                            if (context.mounted && saved) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: Text(saving ? 'Desant…' : 'Desar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

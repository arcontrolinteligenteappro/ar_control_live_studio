import 'package:ar_control_live_studio/core/macro_engine.dart';
import 'package:ar_control_live_studio/core/switcher_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ar_control_live_studio/core/theme/cyberpunk_theme.dart';

class MacroEditorView extends ConsumerStatefulWidget { 
  final Macro? macro;
  const MacroEditorView({super.key, this.macro});

  @override
  ConsumerState<MacroEditorView> createState() => _MacroEditorViewState();
}

class _MacroEditorViewState extends ConsumerState<MacroEditorView> {
  late List<MacroAction> _actions;
  late TextEditingController _nameController;
  late String _originalName;
  bool get _isCreating => widget.macro == null;

  @override
  void initState() {
    super.initState();
    _actions = List<MacroAction>.from(widget.macro?.actions ?? []);
    _nameController = TextEditingController(text: widget.macro?.name ?? 'NEW_MACRO');
    _originalName = widget.macro?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _actions.removeAt(oldIndex);
      _actions.insert(newIndex, item);
    });
  }

  void _addAction() async {
    final newAction = await showDialog<MacroAction>(
      context: context,
      builder: (_) => const _ActionEditorDialog(),
    );
    if (newAction != null) {
      setState(() => _actions.add(newAction));
    }
  }

  void _editAction(int index) async {
    final updatedAction = await showDialog<MacroAction>(
      context: context,
      builder: (_) => _ActionEditorDialog(actionToEdit: _actions[index]),
    );
    if (updatedAction != null) {
      setState(() => _actions[index] = updatedAction);
    }
  }

  void _saveMacro() {
    final macroNotifier = ref.read(macroEngineProvider.notifier);
    final newMacro = Macro(name: _nameController.text, actions: _actions);

    if (_isCreating) {
      macroNotifier.addMacro(newMacro);
    } else {
      macroNotifier.updateMacro(_originalName, newMacro);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CyberpunkTheme.panel,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: CyberpunkTheme.cyanNeon, width: 2),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: CyberpunkTheme.panel,
          title: Text(_isCreating ? 'CREATE_MACRO' : 'EDIT_MACRO', style: CyberpunkTheme.terminalStyle),
          actions: [
            TextButton(onPressed: _saveMacro, child: const Text('SAVE')),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style: CyberpunkTheme.terminalStyle,
                decoration: const InputDecoration(
                  labelText: 'Macro Name',
                  labelStyle: TextStyle(color: CyberpunkTheme.magentaNeon),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CyberpunkTheme.magentaNeon)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: _actions.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final action = _actions[index]; 
                    return Card(
                      key: ObjectKey(action),
                      color: CyberpunkTheme.background,
                      child: ListTile(
                        title: Text(action.type.name, style: CyberpunkTheme.terminalStyle),
                        subtitle: Text(
                          '${action.sourceId ?? ''} ${action.duration != null ? '${action.duration!.inMilliseconds}ms' : ''}',
                          style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton( 
                              icon: const Icon(Icons.edit, color: CyberpunkTheme.cyanNeon),
                              onPressed: () => _editAction(index),
                            ),
                            IconButton( 
                              icon: const Icon(Icons.delete, color: CyberpunkTheme.errorRed), 
                              onPressed: () => setState(() => _actions.removeAt(index)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addAction,
          backgroundColor: CyberpunkTheme.magentaNeon,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ActionEditorDialog extends ConsumerStatefulWidget {
  final MacroAction? actionToEdit; 
  const _ActionEditorDialog({this.actionToEdit});

  @override
  ConsumerState<_ActionEditorDialog> createState() => _ActionEditorDialogState();
}

class _ActionEditorDialogState extends ConsumerState<_ActionEditorDialog> {
  late MacroActionType _selectedType;
  String? _selectedSourceId;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.actionToEdit?.type ?? MacroActionType.wait;
    _selectedSourceId = widget.actionToEdit?.sourceId;
    _durationController = TextEditingController(
      text: widget.actionToEdit?.duration?.inMilliseconds.toString() ?? '1000',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _save() {
    final duration = Duration(milliseconds: int.tryParse(_durationController.text) ?? 0);
    final action = MacroAction(
      type: _selectedType,
      sourceId: _selectedSourceId,
      duration: duration,
    );
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(switcherEngineProvider.select((s) => s.sources.keys.toList()));

    return AlertDialog(
      backgroundColor: CyberpunkTheme.panel, 
      title: Text('Edit Action', style: CyberpunkTheme.terminalStyle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<MacroActionType>(
              value: _selectedType,
              isExpanded: true,
              dropdownColor: CyberpunkTheme.panel,
              style: CyberpunkTheme.terminalStyle, 
              onChanged: (type) => setState(() => _selectedType = type!),
              items: MacroActionType.values.map((type) {
                return DropdownMenuItem(value: type, child: Text(type.name));
              }).toList(),
            ),
            if (_selectedType == MacroActionType.selectForPreview)
              DropdownButton<String>(
                value: _selectedSourceId,
                hint: Text('Select Source', style: CyberpunkTheme.terminalStyle.copyWith(color: Colors.grey)),
                isExpanded: true,
                dropdownColor: CyberpunkTheme.panel,
                style: CyberpunkTheme.terminalStyle, 
                onChanged: (id) => setState(() => _selectedSourceId = id),
                items: sources.map((id) {
                  return DropdownMenuItem(value: id, child: Text(id));
                }).toList(),
              ),
            if (_selectedType == MacroActionType.wait || _selectedType == MacroActionType.executeAuto)
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                style: CyberpunkTheme.terminalStyle,
                decoration: const InputDecoration(
                  labelText: 'Duration (ms)',
                  labelStyle: TextStyle(color: CyberpunkTheme.magentaNeon),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CANCEL')),
        TextButton(onPressed: _save, child: const Text('SAVE')),
      ],
    );
  }
}
import 'package:flutter/foundation.dart';

/// Multi-select state for list screens (long-press to enter, tap to toggle).
class ListSelectionController extends ChangeNotifier {
  final Set<String> _ids = {};
  bool _active = false;

  bool get isActive => _active;
  int get count => _ids.length;
  Set<String> get selectedIds => Set.unmodifiable(_ids);

  bool isSelected(String id) => _ids.contains(id);

  void beginWith(String id) {
    _active = true;
    _ids.add(id);
    notifyListeners();
  }

  void toggle(String id) {
    if (!_active) return;
    if (_ids.contains(id)) {
      _ids.remove(id);
      if (_ids.isEmpty) _active = false;
    } else {
      _ids.add(id);
    }
    notifyListeners();
  }

  /// First long-press enters selection with [id]; further long-presses toggle membership.
  void onLongPress(String id) {
    if (!_active) {
      _active = true;
      _ids.add(id);
    } else {
      toggle(id);
    }
    notifyListeners();
  }

  void clear() {
    _ids.clear();
    _active = false;
    notifyListeners();
  }
}

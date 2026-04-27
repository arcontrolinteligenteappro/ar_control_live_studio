import 'dart:async';
import 'package:ar_control_live_studio/core/node_discovery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveNodesNotifier extends StateNotifier<Map<String, NodeInfo>> {
  final Ref _ref;
  StreamSubscription? _subscription;
  Timer? _cleanupTimer;

  ActiveNodesNotifier(this._ref) : super({}) {
    _subscription = _ref.read(nodeDiscoveryProvider).discoveredNodes.listen(_addOrUpdateNode);
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), _cleanupStaleNodes);
  }

  void _addOrUpdateNode(NodeInfo nodeInfo) {
    state = {...state, nodeInfo.ipAddress: nodeInfo};
  }

  void _cleanupStaleNodes(Timer timer) {
    final now = DateTime.now();
    final Map<String, NodeInfo> activeNodes = {};
    state.forEach((ip, node) {
      if (now.difference(node.lastSeen).inSeconds < 5) {
        activeNodes[ip] = node;
      }
    });

    if (activeNodes.length != state.length) {
      state = activeNodes;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cleanupTimer?.cancel();
    super.dispose();
  }
}

final activeNodesProvider = StateNotifierProvider<ActiveNodesNotifier, Map<String, NodeInfo>>((ref) {
  return ActiveNodesNotifier(ref);
});
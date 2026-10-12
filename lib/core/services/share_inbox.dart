import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../providers/dock_provider.dart';

class ShareInbox {
  ShareInbox._();

  static StreamSubscription<List<SharedMediaFile>>? _sub;
  static var _started = false;

  static void listen(Future<void> Function(List<SharedPiece> pieces) onShare) {
    if (_started) return;
    _started = true;
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => onShare(_pieces(files)),
      onError: (_) {},
    );
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isEmpty) return;
      onShare(_pieces(files));
      ReceiveSharingIntent.instance.reset();
    });
  }

  static List<SharedPiece> _pieces(List<SharedMediaFile> files) {
    return [
      for (final file in files)
        SharedPiece(
          text: file.type == SharedMediaType.text || file.type == SharedMediaType.url
              ? file.path
              : null,
          path: file.type == SharedMediaType.text || file.type == SharedMediaType.url
              ? null
              : file.path,
          mime: file.mimeType,
        ),
    ];
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}

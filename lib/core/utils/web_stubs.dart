import 'dart:async';

// JS STUBS
final context = JsContext();
dynamic allowInterop(Function f) => f;

class JsContext {
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
  dynamic operator [](Object? key) => null;
  void operator []=(Object key, dynamic value) {}
  void deleteProperty(Object key) {}
}

class JsObject {
  dynamic operator [](Object? key) => null;
}

class JsArray {
  int get length => 0;
  dynamic operator [](int index) => null;
}

// HTML STUBS
final window = null;
dynamic DivElement() => null;

// UI_WEB STUBS
final platformViewRegistry = PlatformViewRegistryProxy();

class PlatformViewRegistryProxy {
  void registerViewFactory(String viewId, dynamic Function(int viewId) viewFactory) {}
}

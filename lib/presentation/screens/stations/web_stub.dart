// This file satisfies the compiler for Android builds
// ignore_for_file: camel_case_types, non_constant_identifier_names

final context = _FakeContext();
dynamic allowInterop(Function f) => f;

class ui {
  static _FakeRegistry platformViewRegistry = _FakeRegistry();
}

class _FakeRegistry {
  void registerViewFactory(String id, Function cb) {}
}

class html {
  static _FakeElement DivElement() => _FakeElement();
}

class _FakeElement {
  _FakeStyle style = _FakeStyle();
  void append(dynamic el) {}
  set id(String val) {}
}

class _FakeStyle {
  set width(String v) {}
  set height(String v) {}
  set position(String v) {}
}

class _FakeContext {
  dynamic callMethod(String m, [List? a]) => null;
  void deleteProperty(String p) {}
  operator [](String k) => null;
  operator []=(String k, dynamic v) {}
}

class JsObject {
  dynamic operator [](Object? property) => null;
  void operator []=(Object? property, dynamic value) {}
}

class JsArray<E> {
  int get length => 0;
  E operator [](int index) => throw UnimplementedError();
}
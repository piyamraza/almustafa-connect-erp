import '../../domain/entities/document_element_type.dart';
import 'renderers/element_renderer.dart';

class DocumentRendererRegistry {
  DocumentRendererRegistry();

  final Map<DocumentElementType, ElementRenderer>
      _renderers = <DocumentElementType, ElementRenderer>{};

  void register(
    DocumentElementType type,
    ElementRenderer renderer,
  ) {
    _renderers[type] = renderer;
  }

  void registerAll(
    Map<DocumentElementType, ElementRenderer> renderers,
  ) {
    _renderers.addAll(renderers);
  }

  ElementRenderer? rendererFor(
    DocumentElementType type,
  ) {
    return _renderers[type];
  }

  ElementRenderer rendererForOrThrow(
    DocumentElementType type,
  ) {
    final renderer = rendererFor(type);

    if (renderer == null) {
      throw StateError(
        'No renderer registered for document element type "${type.name}".',
      );
    }

    return renderer;
  }

  bool isRegistered(
    DocumentElementType type,
  ) {
    return _renderers.containsKey(type);
  }

  Set<DocumentElementType> get registeredTypes =>
      Set<DocumentElementType>.unmodifiable(
        _renderers.keys,
      );
}

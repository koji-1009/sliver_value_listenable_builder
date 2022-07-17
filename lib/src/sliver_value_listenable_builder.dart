import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builds a [RenderObjectWidget] when given a concrete value of a [ValueListenable<T>].
///
/// If the `child` parameter provided to the [SliverValueListenableBuilder] is not
/// null, the same `child` widget is passed back to this [SliverValueListenableBuilder]
/// and should typically be incorporated in the returned widget tree.
typedef ValueRenderObjectWidgetBuilder<T> = RenderObjectWidget Function(
  BuildContext context,
  T value,
  Widget? child,
);

class SliverValueListenableBuilder<T> extends StatefulWidget {
  const SliverValueListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.builder,
    this.child,
  });

  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [ValueListenable] itself must not be null.
  final ValueListenable<T> valueListenable;

  /// A [ValueRenderObjectWidgetBuilder] which builds a widget depending on the
  /// [valueListenable]'s value.
  ///
  /// Must not be null.
  final ValueRenderObjectWidgetBuilder<T> builder;

  /// A [valueListenable]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree
  /// the [builder] builds depends on the value of the [valueListenable]. For
  /// example, if the [valueListenable] is a [String] and the [builder] simply
  /// returns a [Text] widget with the [String] value.
  final Widget? child;

  @override
  State<StatefulWidget> createState() =>
      _SliverValueListenableBuilderState<T>();
}

class _SliverValueListenableBuilderState<T>
    extends State<SliverValueListenableBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(SliverValueListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      value = widget.valueListenable.value;
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, value, widget.child);
}

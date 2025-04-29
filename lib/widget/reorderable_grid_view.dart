import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'; // For haptic feedback

class ReorderableGridView extends StatefulWidget {
  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final void Function(int oldIndex, int newIndex) onReorder;
  final EdgeInsetsGeometry? padding;

  const ReorderableGridView({
    Key? key,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.onReorder,
    this.padding,
  }) : super(key: key);

  static ReorderableGridView builder({
    required SliverGridDelegate gridDelegate,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    required Function(int, int) onReorder,
    EdgeInsetsGeometry? padding,
  }) {
    return ReorderableGridView(
      gridDelegate: gridDelegate,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      onReorder: onReorder,
      padding: padding,
    );
  }

  @override
  _ReorderableGridViewState createState() => _ReorderableGridViewState();
}

class _ReorderableGridViewState extends State<ReorderableGridView> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = List.generate(
      widget.itemCount,
      (index) => widget.itemBuilder(context, index),
    );

    return ReorderableWrap(
      spacing: 0.0,
      runSpacing: 0.0,
      padding: widget.padding ?? EdgeInsets.zero,
      onReorder: widget.onReorder,
      children: children,
      buildDraggableFeedback: (context, constraints, child) {
        return Material(
          elevation: 6.0,
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: constraints,
            child: Opacity(opacity: 0.7, child: child),
          ),
        );
      },
      controller: ScrollController(),
      gridDelegate: widget.gridDelegate,
    );
  }
}

class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Widget Function(BuildContext, BoxConstraints, Widget child)
  buildDraggableFeedback;
  final EdgeInsetsGeometry padding;
  final ScrollController controller;
  final SliverGridDelegate gridDelegate;

  const ReorderableWrap({
    Key? key,
    required this.children,
    required this.onReorder,
    required this.buildDraggableFeedback,
    required this.controller,
    required this.gridDelegate,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  _ReorderableWrapState createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate crossAxisCount based on SliverGridDelegateWithFixedCrossAxisCount
    final SliverGridDelegateWithFixedCrossAxisCount gridDelegate =
        widget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final int crossAxisCount = gridDelegate.crossAxisCount;

    return Scrollbar(
      controller: _scrollController,
      child: Padding(
        padding: widget.padding,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: ReorderableGridViewContent(
            controller: _scrollController,
            onReorder: widget.onReorder,
            children: widget.children,
            buildDraggableFeedback: widget.buildDraggableFeedback,
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridDelegate.crossAxisSpacing,
            mainAxisSpacing: gridDelegate.mainAxisSpacing,
            childAspectRatio: gridDelegate.childAspectRatio,
          ),
        ),
      ),
    );
  }
}

class ReorderableGridViewContent extends StatefulWidget {
  final List<Widget> children;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Widget Function(BuildContext, BoxConstraints, Widget)
  buildDraggableFeedback;
  final ScrollController controller;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const ReorderableGridViewContent({
    Key? key,
    required this.children,
    required this.onReorder,
    required this.buildDraggableFeedback,
    required this.controller,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    this.childAspectRatio = 1.0,
  }) : super(key: key);

  @override
  _ReorderableGridViewContentState createState() =>
      _ReorderableGridViewContentState();
}

class _ReorderableGridViewContentState
    extends State<ReorderableGridViewContent> {
  int? _dragIndex;
  int? _dropIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on constraints and crossAxisCount
        final double itemWidth =
            (constraints.maxWidth -
                (widget.crossAxisSpacing * (widget.crossAxisCount - 1))) /
            widget.crossAxisCount;

        // Calculate height based on aspect ratio
        final double itemHeight = itemWidth / widget.childAspectRatio;

        return GridView.builder(
          controller: widget.controller,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
          ),
          itemCount: widget.children.length,
          itemBuilder: (context, index) {
            return _buildDraggableItem(
              context,
              index,
              widget.children[index],
              Size(itemWidth, itemHeight),
              constraints,
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableItem(
    BuildContext context,
    int index,
    Widget child,
    Size itemSize,
    BoxConstraints constraints,
  ) {
    return LongPressDraggable<int>(
      key: ValueKey('draggable-$index'),
      data: index,
      axis: null, // Allow dragging in any direction
      // Set a lower delay for long press to make it more responsive
      delay: Duration(milliseconds: 150),
      // Set feedback scale to make the dragged item slightly larger
      feedbackOffset: Offset(0, -20), // Lift the feedback slightly above the finger
      hapticFeedbackOnStart: true, // Provide haptic feedback when drag starts
      feedback: widget.buildDraggableFeedback(
        context,
        BoxConstraints(
          minWidth: itemSize.width,
          maxWidth: itemSize.width,
          minHeight: itemSize.height,
          maxHeight: itemSize.height,
        ),
        child,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      onDragStarted: () {
        // Provide haptic feedback when drag starts
        HapticFeedback.mediumImpact();
        setState(() {
          _dragIndex = index;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _dragIndex = null;
          _dropIndex = null;
        });
      },
      onDraggableCanceled: (_, __) {
        setState(() {
          _dragIndex = null;
          _dropIndex = null;
        });
      },
      child: DragTarget<int>(
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            // Add an empty onTap to ensure the GestureDetector doesn't interfere
            // with touch events but still processes the gestures
            onTap: () {},
            // Use a subtle highlight to indicate where an item can be dropped
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _dropIndex == index ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
                // Add a subtle shadow when this is a drop target
                boxShadow: _dropIndex == index
                    ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
                    : null,
              ),
              child: child,
            ),
          );
        },
        onWillAccept: (dragIndex) {
          return dragIndex != index;
        },
        onAccept: (dragIndex) {
          widget.onReorder(dragIndex, index);
          setState(() {
            _dropIndex = null;
          });
        },
        onMove: (_) {
          if (_dropIndex != index) {
            setState(() {
              _dropIndex = index;
            });
          }
        },
        onLeave: (_) {
          if (_dropIndex == index) {
            setState(() {
              _dropIndex = null;
            });
          }
        },
      ),
    );
  }
}
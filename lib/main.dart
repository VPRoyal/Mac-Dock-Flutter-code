// Packages for basic UI & Math constants
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

// Main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(), // Sets the [HomePage] widget.
      debugShowCheckedModeBanner: false, // Hides the debug banner.
    );
  }
}

/// HomePage widget with a Dock widget in the center.
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Dock(
          /// Icons data to be displayed as items of Dock
          /// More icons can be added or customised.
          items: const [
            Icons.person,
            Icons.message,
            Icons.call,
            Icons.camera,
            Icons.photo,
          ],

          /// Builder function to create [DockItem] widget.
          /// Neccessary data can be passed to child widget through the parameters.
          builder: (index, icon, widgetKey, dockState) => DockItem(
              itemIndex: index, // Index to each item of the Dock item list.
              icon: icon,
              widgetKey: widgetKey, // Unique key assigned to each Dock item.
              dockState:
                  dockState), // Dock's state passed to Dock Items to access it's methods & variables.
        ),
      ),
    );
  }
}

/// Dock Item widget class.
class DockItem extends StatefulWidget {
  final GlobalKey<_DockItemState> widgetKey;
  final IconData icon;
  final _DockState dockState;
  final int itemIndex;

  /// Constructor function to initialize/ bind the passed data.
  /// Assigning/ Binding unique [GlobalKey] to Dock Item.
  /// Using the key, internal state & context of Dock Item can be accessed.
  const DockItem(
      {required this.itemIndex,
      required this.icon,
      required this.widgetKey,
      required this.dockState})
      : super(key: widgetKey);

  @override
  State<DockItem> createState() => _DockItemState();
}

/// Dock Widget Class
/// Intializing the passed list items and builder function.
class Dock<T> extends StatefulWidget {
  const Dock({this.items = const [], required this.builder});
  final List<T> items;
  final Widget Function(int, T, GlobalKey<_DockItemState>, _DockState) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// DockItem State class to implement neccessary business logic.
/// [TickerProviderStateMixin] template used to access [Tickers] - Animation controller functions.
/// There are three Components/Containers of the Dock Item widget-
/// 1. Base Component: Transparent parent component which used in resizing and reordering the item.
/// 2. Overlay Component: Visible overlay component which is used for dragging.
/// 3. Child Component: Visible non-movable component which is used to display item when there is no dragging.

class _DockItemState extends State<DockItem> with TickerProviderStateMixin {
  /// Initializing the Default Size and Margin.
  /// Can be used to changed the base size of Dock Items.
  static const double _standSize = 48, _standMargin = 10;

  /// Initializing size & margin variables for each component of the item widget.
  Size _parentSize = Size(_standSize, _standSize),
      _childSize = Size(_standSize, _standSize),
      _overlaySize = Size(_standSize + _standMargin, _standSize + _standMargin);
  double _marginTop = _standMargin, _marginHorizontal = _standMargin;
  Size parentBoxSize = Size.zero;

  /// Defining cursor & component position variables.
  Offset cursor = Offset.zero;
  Offset parentPosition = Offset.zero,
      _overlayPosition = Offset.zero,
      parentCenter = Offset.zero;
  Offset dragEndInitialPosition = Offset.zero,
      dragEndFinalPosition = Offset.zero;

  /// Intializing the Dock and Dock Item state constants.
  late final GlobalKey widgetKey = widget.widgetKey;
  late final _DockState dockState = widget.dockState;

  /// Various useful flags.
  bool isDragging = false;
  bool isResizeAnimation = false, isDragEndAnimation = false;
  bool isShrinked = false;

  /// Defining various animations & Controllers.
  final _overlayController = OverlayPortalController();
  late AnimationController _sizeController;
  late Animation<double> _widthAnimation;
  late Animation<double> _horizontalMarginAnimation;
  late AnimationController _positionController;
  late Animation<double> _positionAnimation;

  /// Cosine resize algorithm: Resize items to show cosine wave effect on hovering.
  double _reSize(Offset cursor) {
    double effectWidth = 5 * _standSize;
    double minX = cursor.dx - (effectWidth / 2);
    double theta = ((parentCenter.dx - minX) / effectWidth) * 2 * pi;
    theta = min(max(theta, 0), 2 * pi);
    double newDimension = _standSize + ((1 - cos(theta)) / 2) * (_standMargin);
    return newDimension;
  }

  /// Resets overlay to it's parent position.
  Offset _resetOverlayPosition() {
    return parentPosition + Offset(_standMargin, _marginTop);
  }

  /// Updates the parent position variable when position changes are in effect.
  void _updatePosition() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset widgetPosition = renderBox.localToGlobal(Offset.zero);
    parentPosition = widgetPosition;
    parentBoxSize = renderBox.size;
    parentCenter = parentPosition +
        Offset(parentBoxSize.width / 2, parentBoxSize.height / 2);
  }

  /// Shrink Animation for the item.
  Future<void> shrinkAnimation() async {
    isResizeAnimation = true;
    await _sizeController.forward();
    isResizeAnimation = false;
  }

  /// Grow Animation for the item.
  Future<void> growAnimation() async {
    isResizeAnimation = true;
    await _sizeController.reverse();
    isResizeAnimation = false;
  }

  /// Reszing setter function for Cosine hovering effect.
  void startHoverEvent(Offset cursor) {
    setState(() {
      double resizedSize = _reSize(cursor);
      _updatePosition();
      _parentSize = Size(resizedSize, resizedSize);
      _marginTop = _standMargin - (_parentSize.height - _standSize);
    });
  }

  /// Resets the item size following the end of Hovering effect.
  endHoverEvent() {
    setState(() {
      _parentSize = Size(_standSize, _standSize);
      _marginTop = _standMargin;
    });
  }

  /// Handles the drag start event.
  void _onDragStart(DragStartDetails details) {
    setState(() {
      isDragging = true;
      _updatePosition();
      _overlayPosition = _resetOverlayPosition();
      cursor = details.globalPosition;
    });
    _overlayController.show();
    dockState.dragStart(widget.itemIndex);
  }

  /// Handles the drag update event.
  void _onDragUpdate(DragUpdateDetails details) {
    cursor = details.globalPosition;
    setState(() {
      _overlayPosition += details.delta;
    });
    dockState.dragUpdate(cursor);
  }

  /// Handles the drag end event.
  void _onDragEnd(DragEndDetails details) async {
    isDragEndAnimation = true;
    _sizeController.reset();
    await growAnimation();
    _updatePosition();
    dragEndInitialPosition = _overlayPosition;
    dragEndFinalPosition = parentPosition;

    if (dockState.isInside) {
      dragEndFinalPosition += Offset(_marginHorizontal, _marginTop);
    } else {
      dragEndFinalPosition +=
          Offset(-(_standMargin + _standMargin + _standMargin), 0);
    }

    _positionController.reset();
    await _positionController.forward();
    isDragEndAnimation = false;
    setState(() {
      isDragging = false;
      cursor = Offset.zero;
    });
    _overlayController.hide();
    dockState.dragEnd();
  }

  /// Handles the drag cancel event.
  /// ToDo: Needs to implement this method for future cases.
  void _onDragCancel() {
    isDragging = false;
  }

  /// Core Initialization function.
  @override
  void initState() {
    super.initState();

    /// Handles business logic after first build completed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
      _overlayPosition = _resetOverlayPosition();
    });

    /// Initialized animation controllers and their Tween animations.

    /// To handle item's shrink and grow animations.
    _sizeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _widthAnimation =
        Tween<double>(begin: _standSize + _standMargin / 2, end: 0).animate(
      CurvedAnimation(
        parent: _sizeController,
        curve: Curves.ease,
      ),
    );
    _horizontalMarginAnimation =
        Tween<double>(begin: _standMargin, end: 0).animate(
      CurvedAnimation(
        parent: _sizeController,
        curve: Curves.ease,
      ),
    );

    _sizeController.addListener(() {
      setState(() {
        _parentSize = Size(_widthAnimation.value, _standMargin + _standSize);
        _marginHorizontal = _horizontalMarginAnimation.value;
      });
    });

    /// To handle overlay's reposition animation on drag ends.
    _positionController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _positionAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _positionController, curve: Curves.decelerate));
    _positionController.addListener(() {
      setState(() {
        _overlayPosition = dragEndInitialPosition +
            (dragEndFinalPosition - dragEndInitialPosition) *
                _positionAnimation.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    /// GestureDectector widget to detect Pan events for dragging.
    return GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onPanCancel: _onDragCancel,

        /// Parent Component.
        /// Animated Container - To handle resizing animation on hovering effect.
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          width: _parentSize.width,
          height: _parentSize.height,
          margin: EdgeInsets.fromLTRB(
              _marginHorizontal, _marginTop, _marginHorizontal, _standMargin),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),

          /// Overlay Component.
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (BuildContext context) {
              /// AnimatedPositioned - To handle overlay dragging animation.
              return AnimatedPositioned(
                  top: _overlayPosition.dy,
                  left: _overlayPosition.dx,
                  width: _overlaySize.width,
                  height: _overlaySize.height,
                  duration: Duration(milliseconds: 50),
                  child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 48),
                        padding: EdgeInsets.all(_standMargin),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.primaries[
                              widget.icon.hashCode % Colors.primaries.length],
                        ),
                        child: Center(
                          child: Icon(widget.icon, color: Colors.white),
                        ),
                      )));
            },

            /// Child component - Appears when there is no dragging.
            child: !isDragging
                ? Container(
                    width: _childSize.width,
                    height: _childSize.height,
                    // constraints: const BoxConstraints(minWidth: 48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.primaries[
                          widget.icon.hashCode % Colors.primaries.length],
                    ),
                    child: Center(
                      child: Icon(widget.icon, color: Colors.white),
                    ),
                  )
                : Container(),
          ),
        ));
  }
}

/// Dock state  class
/// Center Positioned widget containing a list of Dock Item widgets.
class _DockState<T> extends State<Dock<T>> {
  /// Defined list variable to store Items.
  List<T> _items = [];
  late final int _totalItems = widget.items.length;

  /// Generating [GlobalKey]s for Dock and Dock Items widgets to assign.
  late final GlobalKey<_DockState> dockKey = GlobalKey();
  List<GlobalKey<_DockItemState>> _itemKeys = [];

  /// Useful flag checks.
  bool isHovering = false,
      isInside = false,
      isDragging = false,
      isAnimating = false;

  /// Definings neccessary variables related to drag & reordering operations.
  Offset cursor = Offset.zero;
  int dragIndex = -1, nearestIndex = -1;
  GlobalKey<_DockItemState>? draggingItem, indexOutKey;
  T? indexOutItem;

  /// Helper function to create [Rect] object for containers.
  Rect _createRectangle(GlobalKey key, [Offset offset = Offset.zero]) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(offset);
    return position & renderBox.size;
  }

  /// To check if cursor is Inside a particular rectangle container.
/*
  bool checkInside(Offset cursor) {
    Rect box = _createRectangle(dockKey);
    return box.contains(cursor);
  }
*/

  /// To find closest new index when item is dragged near others.
  int _findNearestIndex(Offset cursor) {
    Rect firstRect = _createRectangle(_itemKeys[0]);
    if (firstRect.center.dx > cursor.dx) {
      return 0;
    }
    Rect lastRect = _createRectangle(_itemKeys[_totalItems - 1]);
    if (lastRect.center.dx < cursor.dx) {
      return _totalItems - 1;
    }
    for (int i = 0; i < _totalItems - 1; i++) {
      Rect leftRect = _createRectangle(_itemKeys[i]);
      Rect rightRect = _createRectangle(_itemKeys[i + 1]);
      if (cursor.dx >= leftRect.center.dx && cursor.dx <= rightRect.center.dx) {
        return (i >= dragIndex ? i : i + 1);
      }
    }
    return dragIndex;
  }

  /// To remove item from the list.
  void removeIndex(int removeIndex) {
    indexOutItem = _items.removeAt(removeIndex);
    indexOutKey = _itemKeys.removeAt(removeIndex);
  }

  /// To add item in to the list.
  void addIndex(int addIndex) {
    _items.insert(addIndex, indexOutItem!);
    _itemKeys.insert(addIndex, indexOutKey!);
  }

  /// To perform reindexing operation.
  void reIndexing() {
    setState(() {
      removeIndex(dragIndex);
      addIndex(nearestIndex);
      dragIndex = nearestIndex;
    });
  }

  /// To handle complete Reordering operation.
  /// Operation invloves:
  /// 1. Finding new closest available index.
  /// 2. If new [nearestIndex] is suitable to reorder.
  /// 3. Perform the shrink animation for previous list position.
  /// 4. Reindex the list position with the new Index.
  /// 5. Perform the grow animation for new list position.

  void _repositionItem() async {
    if (isAnimating) return;
    nearestIndex = _findNearestIndex(cursor);
    if ((nearestIndex == dragIndex) || (nearestIndex == -1)) return;
    isAnimating = true;
    await draggingItem!.currentState!.shrinkAnimation();
    reIndexing();
    await draggingItem!.currentState!.growAnimation();
    isAnimating = false;
  }

  /// To handle Hovering In event.
  void onHoverInEvent() async {
    isHovering = true;
    isInside = true;
    if (isDragging) {
      isAnimating = true;
      nearestIndex = _findNearestIndex(cursor);
      if ((nearestIndex != dragIndex) && (nearestIndex != -1)) reIndexing();
      await draggingItem!.currentState!.growAnimation();
      isAnimating = false;
    }
  }

  /// To handle Hovering End effect.
  void hoverEndEvent() {
    for (var keys in _itemKeys) {
      keys.currentState!.endHoverEvent();
    }
  }

  /// To handle Hovering Out event.
  void onHoverOutEvent() async {
    isHovering = false;
    isInside = false;
    if (isDragging) {
      isAnimating = true;
      await draggingItem!.currentState!.shrinkAnimation();
      isAnimating = false;
      return;
    }
    hoverEndEvent();
  }

  /// To handle On Hovering event.
  void onHoverEvent(cursor) {
    this.cursor = cursor;
    for (var keys in _itemKeys) {
      keys.currentState!.startHoverEvent(cursor);
    }
  }

  /// To handle Drag Start event.
  void dragStart(int dragIndex) {
    isDragging = true;
    this.dragIndex = dragIndex;
    draggingItem = _itemKeys[dragIndex];
  }

  /// To handle Drag Update event.
  void dragUpdate(Offset cursor) {
    this.cursor = cursor;
    if (isInside) {
      _repositionItem();
      onHoverEvent(cursor);
    }
  }

  /// To handle Drag End effects.
  void dragEndEvent() async {
    if (!isInside) {
      hoverEndEvent();
    }
  }

  /// To handle Drag End event.
  void dragEnd() async {
    isDragging = false;
    dragIndex = -1;
    dragEndEvent();
    draggingItem = null;
  }

  @override
  void initState() {
    super.initState();

    /// Intialize the passed items to [_items] list variable.
    _items = widget.items.toList();

    /// Intialize the [GlobalKey]s list for each item.
    _itemKeys
        .addAll(List.generate(_totalItems, (_) => GlobalKey<_DockItemState>()));
  }

  @override
  Widget build(BuildContext context) {
    /// MouseRegion Widget - To listen hovering events.
    return MouseRegion(
      onHover: (event) {
        onHoverEvent(event.position);
      },
      onEnter: (event) {
        onHoverInEvent();
      },
      onExit: (event) {
        onHoverOutEvent();
      },

      /// Dock Container having list of Dock Items in a Row.
      child: Container(
          key: dockKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
                _totalItems,
                (index) => widget.builder(
                    index, _items[index], _itemKeys[index], this)),
          )),
    );
  }
}

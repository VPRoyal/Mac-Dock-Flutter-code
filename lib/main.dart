import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

/// The entry point for the application.
/// Main widget that sets up the [MaterialApp].
class MyApp extends StatelessWidget {
  /// Creates a [MyApp] widget.
  const MyApp({super.key});

  /// Builds the [MaterialApp] widget.
  ///
  /// This method returns a [MaterialApp] configured with the [HomePage]
  /// as its home screen and disables the debug banner.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// The home page of the application that hosts the [Dock] widget.
///
/// This class provides the main user interface for the application,
/// displaying a centered dock with interactive items.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage] widget.
  const HomePage({super.key});

  /// Builds the [Scaffold] widget containing the [Dock].
  ///
  /// This method returns a [Scaffold] with a centered [Dock] widget
  /// containing a list of predefined icons.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Dock(items: const [
          Icons.person,
          Icons.message,
          Icons.call,
          Icons.camera,
          Icons.photo,
        ]),
      ),
    );
  }
}

/// A widget that represents a dock containing multiple interactive items.
///
/// The [Dock] widget is a customizable container that holds a list of
/// [DockItem] widgets, providing drag-and-drop functionality.
class Dock extends StatefulWidget {
  /// The list of icons to be displayed in the dock.
  final List<IconData> items;

  /// Creates a [Dock] widget with the specified list of [items].
  const Dock({super.key, required this.items});

  /// This method returns an instance of [_DockState] to manage the
  /// state of the dock.
  @override
  State<Dock> createState() => _DockState();
}

/// A class that manages the state of drag operations for dock items,
/// including flags for dragging, hovering, and sliding, as well as
/// indices and offsets related to the drag operation.
class DragState {
  // Flags indicating the current state of the drag operation.
  bool _isDragging = false;
  bool _isHovering = false;
  bool _isAnimating = false;
  bool _isSliding = false;
  bool _cancelSliding = false;

  // Completer for managing asynchronous sliding operations.
  Completer<void>? _slideCompleter;

  // Timers for debouncing drag and sliding events.
  Timer? _slidingDebounce;
  Timer? _dragInDebounce;
  Timer? _dragOutDebounce;

  // Indices for tracking the original and new positions of the dragged item.
  int _dragIndex = -1;
  int _newIndex = -1;

  // Offsets for tracking the drag position and cursor location.
  Offset _dragOffset = Offset.zero;
  Offset _cursor = Offset.zero;

  /// Creates a [DragState] with default values.
  DragState();

  /// Gets the current dragging state.
  bool get isDragging => _isDragging;

  /// Sets the dragging state.
  set setDragging(bool value) => _isDragging = value;

  /// Gets the current hovering state.
  bool get isHovering => _isHovering;

  /// Sets the hovering state.
  set setHovering(bool value) => _isHovering = value;

  /// Gets the current animating state.
  bool get isAnimating => _isAnimating;

  /// Sets the animating state.
  set setAnimating(bool value) => _isAnimating = value;

  /// Gets the current drag index.
  int get dragIndex => _dragIndex;

  /// Sets the drag index.
  set setDragIndex(int value) => _dragIndex = value;

  /// Gets the new index for the dragged item.
  int get newIndex => _newIndex;

  /// Sets the new index for the dragged item.
  set setNewIndex(int value) => _newIndex = value;

  /// Gets the current cursor position.
  Offset get cursor => _cursor;

  /// Sets the current cursor position.
  set setCursor(Offset value) => _cursor = value;

  /// Gets the current drag offset.
  Offset get offset => _dragOffset;

  /// Sets the current drag offset.
  set setOffset(Offset value) => _dragOffset = value;

  /// Gets the current sliding state.
  bool get isSliding => _isSliding;

  /// Sets the sliding state.
  set setSliding(bool value) => _isSliding = value;

  /// Gets the current cancel sliding state.
  bool get cancelSliding => _cancelSliding;

  /// Sets the cancel sliding state.
  set setCancelSliding(bool value) => _cancelSliding = value;

  /// Gets the completer for sliding operations.
  Completer<void>? get slidingCompleter => _slideCompleter;

  /// Sets the completer for sliding operations.
  set setSlidingCompleter(Completer<void>? value) => _slideCompleter = value;

  /// Gets the debounce timer for sliding operations.
  Timer? get slidingDebounce => _slidingDebounce;

  /// Sets the debounce timer for sliding operations.
  set setSlidingDebounce(Timer value) => _slidingDebounce = value;

  /// Gets the debounce timer for drag-in events.
  Timer? get dragInDebounce => _dragInDebounce;

  /// Sets the debounce timer for drag-in events.
  set setDragInDebounce(Timer value) => _dragInDebounce = value;

  /// Gets the debounce timer for drag-out events.
  Timer? get dragOutDebounce => _dragOutDebounce;

  /// Sets the debounce timer for drag-out events.
  set setDragOutDebounce(Timer value) => _dragOutDebounce = value;
}

/// The state class for the [Dock] widget, managing the drag-and-drop functionality
/// and animations for dock items.
/// It listens for drag and hover event and had methods to handle them.
class _DockState extends State<Dock> with TickerProviderStateMixin {
  // List of icons representing the items in the dock.
  List<IconData> _items = [];

  // List of keys associated with each dock item for state management.
  List<GlobalKey<_DockItemState>> _keys = [];

  // Key for the currently dragged item.
  GlobalKey<_DockItemState>? _dragItemKey;

  // Instance of DragState to manage the state of drag operations.
  DragState drag = DragState();

  /// Initializes the list of items and their corresponding keys.
  @override
  void initState() {
    _items = widget.items.toList();
    _keys = List.generate(_items.length, (_) => GlobalKey());
    super.initState();
  }

  /// Finds the index of the item being dragged based on the cursor position.
  ///
  /// Iterates through the list of keys to determine which item's bounding
  /// rectangle contains the cursor.
  ///
  /// Returns the index of the item if found, otherwise returns -1.
  int findDragIndex(Offset cursor) {
    for (int i = 0; i < _keys.length; i++) {
      GlobalKey<_DockItemState> key = _keys[i];
      Rect? item = key.currentState?.childWidget.rect(key.currentContext!);
      if (item != null && item.contains(cursor)) {
        return i;
      }
    }
    return -1;
  }

  /// Finds the nearest index for the dragged item based on its current position.
  ///
  /// Compares the center of the dragged item's rectangle with the centers of
  /// other items to determine the closest position.
  ///
  /// Returns the new index for the dragged item.
  int findNearestIndex(Rect draggedRect) {
    int totalItems = _items.length;
    Rect firstRect =
        _keys[0].currentState!.childWidget.rect(_keys[0].currentContext!);
    if (firstRect.center.dx > draggedRect.center.dx) {
      return 0;
    }
    Rect lastRect = _keys[totalItems - 1]
        .currentState!
        .childWidget
        .rect(_keys[totalItems - 1].currentContext!);
    if (lastRect.center.dx <= draggedRect.center.dx) {
      return totalItems - 1;
    }
    for (int i = 0; i < totalItems - 1; i++) {
      Rect leftRect =
          _keys[i].currentState!.childWidget.rect(_keys[i].currentContext!);
      Rect rightRect = _keys[i + 1]
          .currentState!
          .childWidget
          .rect(_keys[i + 1].currentContext!);
      if (draggedRect.center.dx >= leftRect.center.dx &&
          draggedRect.center.dx <= rightRect.center.dx) {
        return (i >= drag.dragIndex ? i : i + 1);
      }
    }
    return -1;
  }

  /// Reindexes the items in the dock after a drag operation.
  ///
  /// Moves the item from the `dragIndex` to the `newIndex` in both the
  /// `_items` and `_keys` lists.
  void reindexing(int dragIndex, int newIndex) {
    setState(() {
      IconData indexOutItem = _items.removeAt(dragIndex);
      GlobalKey<_DockItemState> indexOutKey = _keys.removeAt(dragIndex);
      _items.insert(newIndex, indexOutItem);
      _keys.insert(newIndex, indexOutKey);
    });
  }

  /// Handles the sliding animation of items during a drag operation.
  ///
  /// Animates the translation of the item at `newIndex` to the position of
  /// the dragged item, then reindexes the items.
  Future<void> slideEvent(int dragIndex, int newIndex) async {
    GlobalKey<_DockItemState> translateItem = _keys[newIndex];
    Rect dragRect = _dragItemKey!.currentState!.childWidget
        .rect(_dragItemKey!.currentContext!);
    Offset traslationPosition = dragRect.topLeft;
    await translateItem.currentState!.translateAnimation(traslationPosition);
    reindexing(dragIndex, newIndex);
    await translateItem.currentState!.resetTranslationAnimation();
  }

  /// Repositions the dragged item to its nearest index within the dock.
  ///
  /// This asynchronous method calculates the new index for the dragged item
  /// based on its current position and performs a sliding animation to
  /// reposition the item within the dock. It ensures that the item is moved
  /// to the correct position smoothly, updating the dock's state accordingly.
  ///
  /// It uses a [Completer] to enable wait for the reposition to complete,
  /// if any dragIn or dragOut events fired at the same moment.
  ///
  /// It cancenl the sliding if any other event is fired up and reposition has
  /// not been started, to prevent unsual glitches to happen.
  Future<void> repositionItem() async {
    drag.setSliding = true;
    Rect draggedRect = _dragItemKey!.currentState!.overlay.rect;
    drag.setNewIndex = findNearestIndex(draggedRect);
    if ((drag.newIndex == drag.dragIndex) || (drag.newIndex == -1)) {
      drag.setSliding = false;
      return;
    }
    if (drag.cancelSliding || !drag.isHovering) return;
    drag.setSlidingCompleter = Completer<void>();
    int start = drag.dragIndex, end = drag.newIndex;
    int moveFactor = (end - start) > 0 ? 1 : -1;
    while (start != end) {
      await slideEvent(start, start + moveFactor);
      start += moveFactor;
    }
    drag.setDragIndex = drag.newIndex;
    drag.setSliding = false;
    drag.slidingCompleter?.complete();
    drag.setSlidingCompleter = null;
  }

  /// Handles hover events by updating the cursor position and triggering
  /// hover animations on all items.
  void onHoverEvent(Offset cursor) {
    if (!drag.isHovering) return;
    drag.setCursor = cursor;
    for (var keys in _keys) {
      keys.currentState!.startHovering(cursor);
    }
  }

  /// Initiates hover-in events, triggering animations if dragging is active.
  Future<void> onHoverInEvent() async {
    if (drag.isDragging && !drag.isHovering) {
      await dragInEvent();
    }
    drag.setHovering = true;
  }

  /// Handles the drag-in event, updating the index and triggering animations.
  ///
  /// It uses a debounce [Timer] to prevent multiple dragInEvents to call up
  /// simulataneously and only run the last fired event.
  ///
  /// It waits for sliding animation to complete, if it's in between.
  Future<void> dragInEvent() async {
    drag.dragInDebounce?.cancel();
    drag._dragInDebounce = Timer(Duration(milliseconds: 500), () async {
      if (drag.isSliding) {
        await drag.slidingCompleter?.future;
      }
      Rect draggedRect = _dragItemKey!.currentState!.overlay.rect;
      drag.setNewIndex = findNearestIndex(draggedRect);
      if (drag.newIndex != drag.dragIndex && drag.newIndex != -1) {
        reindexing(drag.dragIndex, drag.newIndex);
        drag.setDragIndex = drag.newIndex;
      }
      // await Future.delayed(Duration(milliseconds: 200));
      await _dragItemKey!.currentState!.growAnimation();
    });
  }

  /// Handles the drag-out event, canceling sliding and triggering animations.
  ///
  /// Uses the same debounce [Timer] and waiting functionality as for
  /// [dragInEvent]
  Future<void> dragOutEvent() async {
    drag.dragOutDebounce?.cancel();
    drag.setSlidingDebounce = Timer(Duration(milliseconds: 300), () async {
      if (drag.isSliding) {
        await drag.slidingCompleter?.future;
      }
      drag.setCancelSliding = true;
      // await Future.delayed(Duration(milliseconds: 200));
      await _dragItemKey!.currentState!.shrinkAnimation();
      drag.setCancelSliding = false;
    });
  }

  /// Handles hover-out events, ending hover animations and managing drag state.
  Future<void> onHoverOutEvent() async {
    drag.setHovering = false;

    if (drag.isDragging) {
      await dragOutEvent();
    } else {
      for (var keys in _keys) {
        keys.currentState!.endHovering();
      }
    }
  }

  /// Initiates the drag start event, setting up the drag state and animations.
  ///
  /// This method is triggered when a drag gesture starts. It determines the
  /// index of the item being dragged and initializes the drag state.
  void onDragStart(DragStartDetails details) {
    if (drag.isDragging) return;
    drag.setCursor = details.globalPosition;
    drag.setDragIndex = findDragIndex(drag.cursor);
    if (drag.dragIndex == -1) return;
    _dragItemKey = _keys[drag.dragIndex];
    drag.setDragging = true;
    _dragItemKey!.currentState!.dragStart();
  }

  /// Updates the drag event, managing cursor position and triggering animations.
  ///
  /// This method is called during a drag gesture update. It updates the cursor
  /// position and triggers hover and sliding animations as needed.
  ///
  /// It uses a sliding debounce [Timer] to prevent mutiple sliding operations
  /// from firing up.
  void onDragUpdate(DragUpdateDetails details) async {
    drag.setCursor = details.globalPosition;
    onHoverEvent(drag.cursor);
    if (!drag.isDragging) return;
    if (drag.isHovering && !drag.isSliding) {
      drag.slidingDebounce?.cancel();
      drag.setSlidingDebounce = Timer(Duration(milliseconds: 300), () async {
        await repositionItem();
      });
    }

    _dragItemKey!.currentState!.dragUpdate(details.delta);
  }

  /// Ends the drag event, resetting the drag state and triggering animations.
  ///
  /// This method is called when a drag gesture ends. It finalizes the drag
  /// operation, resets the drag state, and triggers any necessary animations.
  void onDragEnd(DragEndDetails details) async {
    if (!drag.isDragging) return;
    await _dragItemKey!.currentState!.dragEnd();
    drag.setDragging = false;
    if (!drag.isHovering) await onHoverOutEvent();
    _dragItemKey = null;
    drag.setDragIndex = -1;
  }

  /// Builds the Dock widget, setting up gesture and mouse region handlers.
  ///
  /// This method constructs the UI for the Dock, including gesture detection
  /// for drag operations and mouse region handling for hover effects.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onDragStart,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: MouseRegion(
        onHover: (event) {
          onHoverEvent(event.position);
        },
        onEnter: (event) {
          onHoverInEvent();
        },
        onExit: (event) {
          onHoverOutEvent();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                _items.length,
                (index) => DockItem(
                    itemIndex: index,
                    icon: _items[index],
                    widgetKey: _keys[index])),
          ),
        ),
      ),
    );
  }
}

/// A widget that represents an individual item within the [Dock].
///
/// The [DockItem] widget is an interactive element that can be dragged
/// and reordered within the dock.

class DockItem extends StatefulWidget {
  final int itemIndex;
  final IconData icon;
  final GlobalKey widgetKey;

  /// Creates a [DockItem] widget with the specified [itemIndex], [icon],
  /// and [widgetKey].
  ///
  /// The [itemIndex] parameter is the index of the item within the dock.
  /// The [icon] parameter is the icon to be displayed for this item.
  /// The [widgetKey] parameter is used for managing the state of the item.
  const DockItem({
    required this.widgetKey,
    required this.itemIndex,
    required this.icon,
  }) : super(key: widgetKey);

  /// This method returns an instance of [_DockItemState] to manage the
  /// state of the dock item.
  @override
  State<DockItem> createState() => _DockItemState();
}

/// It manages the base state of a dock item, including its size,
/// margin, and scale factor. This class extends [ChangeNotifier] to allow
/// for reactive updates in the UI when properties change.
class BaseState extends ChangeNotifier {
  // The size of the dock item.
  Size _size;

  // The margin around the dock item.
  EdgeInsets _margin;

  // The scale factor applied to the dock item, used for animations.
  double _scaleFactor = 1;

  /// Creates a [BaseState] with the specified [size] and [margin].
  ///
  /// The [size] parameter defines the initial size of the dock item, and
  /// the [margin] parameter defines the initial margin around the item.
  BaseState(Size size, double margin)
      : _size = size,
        _margin = EdgeInsets.fromLTRB(margin, margin, margin, margin);

  /// Gets the current size of the dock item.
  Size get size => _size;

  /// Gets the current margin around the dock item.
  EdgeInsets get margin => _margin;

  /// Gets the current scale factor applied to the dock item.
  double get scaleFactor => _scaleFactor;

  /// Sets a new scale factor for the dock item and notifies listeners.
  set setScaleFactor(double value) {
    _scaleFactor = value;
    notifyListeners();
  }

  /// Sets a new size for the dock item and notifies listeners.
  set setSize(Size value) {
    _size = value;
    notifyListeners();
  }

  /// Sets a new side margin for the dock item and updates the margin.
  set setSideMargin(double value) {
    _margin = EdgeInsets.fromLTRB(value, _margin.top, value, _margin.bottom);
  }

  /// Calculates and returns the bounding rectangle of the dock item.
  Rect rect(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset basePosition = renderBox.localToGlobal(Offset.zero) +
        Offset(_margin.left, _margin.top);
    return (basePosition & _size);
  }
}

/// It manages the state of a child widget within a dock item,
/// including its size, margin, translation, and visibility. This class
/// extends [ChangeNotifier] to allow for reactive updates in the UI when
/// properties change.
class ChildState extends ChangeNotifier {
  // The size of the child widget.
  Size _size;

  // The margin around the child widget.
  EdgeInsets _margin;

  // The current translation offset applied to the child widget.
  Offset _translation = Offset.zero;

  // The position to which the child widget should be translated.
  Offset _translatePosition = Offset.zero;

  // The alignment offset for the child widget.
  Offset _alignment = Offset.zero;

  // The visibility state of the child widget.
  bool _visibility = true;

  /// Creates a [ChildState] with the specified [size], [margin], and [alignment].
  ///
  /// The [size] parameter defines the initial size of the child widget, the
  /// [margin] parameter defines the initial margin around the widget, and the
  /// [alignment] parameter defines the alignment offset for the widget.
  ChildState(Size size, double margin, Offset alignment)
      : _size = size,
        _margin = EdgeInsets.fromLTRB(margin, margin, margin, margin),
        _alignment = alignment;

  /// Gets the current size of the child widget.
  Size get size => _size;

  /// Gets the current margin around the child widget.
  EdgeInsets get margin => _margin;

  /// Gets the current translation offset applied to the child widget.
  Offset get translation => _translation;

  /// Gets the current translation position for the child widget.
  Offset get translatePosition => _translatePosition;

  /// Gets the current visibility state of the child widget.
  bool get visibility => _visibility;

  /// Sets a new size for the child widget and notifies listeners.
  set setSize(Size value) {
    _size = value;
    notifyListeners();
  }

  /// Sets a new top margin for the child widget and updates the margin.
  set setTopMargin(double value) {
    _margin =
        EdgeInsets.fromLTRB(_margin.left, value, _margin.right, _margin.bottom);
  }

  /// Sets a new translation offset for the child widget and notifies listeners.
  set setTranslation(Offset offset) {
    _translation = offset;
    notifyListeners();
  }

  /// Sets the visibility state of the child widget and notifies listeners.
  set setVisibility(bool value) {
    _visibility = value;
    notifyListeners();
  }

  /// Sets a new translation position for the child widget.
  set setTranslationPosition(Offset offset) => _translatePosition = offset;

  /// Calculates and returns the bounding rectangle of the child widget.
  Rect rect(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset basePosition = renderBox.localToGlobal(Offset(_alignment.dx, 0));
    return (basePosition & _size);
  }
}

/// A class that manages the state of an overlay for a dock item, including
/// its size, position, visibility, and drag positions. This class extends
/// [ChangeNotifier] to allow for reactive updates in the UI when properties
/// change.
class OverlayState extends ChangeNotifier {
  // The size of the overlay.
  Size _size;

  // The current position of the overlay.
  Offset _position = Offset.zero;

  // The visibility state of the overlay.
  bool _isShown = false;

  // The initial and final positions for drag end animations.
  Offset _dragEndInitialPosition = Offset.zero,
      _dragEndFinalPosition = Offset.zero;

  // Controller for managing the overlay's visibility.
  final OverlayPortalController _controller = OverlayPortalController();

  /// Creates an [OverlayState] with the specified [size].
  ///
  /// The [size] parameter defines the initial size of the overlay.
  OverlayState(Size size) : _size = size;

  /// Gets the current size of the overlay.
  Size get size => _size;

  /// Gets the controller for managing the overlay's visibility.
  OverlayPortalController get controller => _controller;

  /// Gets the current position of the overlay.
  Offset get position => _position;

  /// Gets the current visibility state of the overlay.
  bool get isShown => _isShown;

  /// Sets a new size for the overlay.
  set setSize(Size size) => _size = size;

  /// Sets a new position for the overlay and notifies listeners.
  set setPosition(Offset pos) {
    _position = pos;
    notifyListeners();
  }

  /// Updates the overlay's position based on a drag delta and notifies listeners.
  set setDrag(Offset delta) {
    _position += delta;
    notifyListeners();
  }

  /// Gets the bounding rectangle of the overlay.
  Rect get rect => _position & size;

  /// Shows the overlay by using the controller and updates the visibility state.
  void show() {
    _controller.show();
    _isShown = true;
  }

  /// Hides the overlay by using the controller and updates the visibility state.
  void hide() {
    _controller.hide();
    _isShown = false;
  }

  /// Sets the initial and final positions for drag end animations.
  void setDragEndPosition(Offset start, Offset end) {
    _dragEndInitialPosition = start;
    _dragEndFinalPosition = end;
  }

  /// Gets the initial and final positions for drag end animations.
  List<Offset> get dragEndPosition =>
      [_dragEndInitialPosition, _dragEndFinalPosition];
}

/// A class that manages the animation state for a dock item, including
/// animations for dragging, translation, and scaling. This class is used
/// to control the visual feedback during interactions with dock items.
class AnimationState {
  // Indicates whether the item is currently being dragged.
  bool _isDragging;

  // The current cursor position.
  Offset _cursor = Offset.zero;

  // The TickerProvider for managing animation controllers.
  final TickerProvider vsync;

  // Animation controllers and animations for different interactions.
  late AnimationController _dragController;
  late Animation<double> _dragAnimation;

  late AnimationController _translationController;
  late Animation<double> _translationAnimation;

  late AnimationController _scalingController;
  late Animation<double> _scalingAnimation;

  /// Creates an [AnimationState] with the specified [vsync] provider.
  ///
  /// The [vsync] parameter is used to manage the lifecycle of animation
  /// controllers.
  AnimationState({required this.vsync}) : _isDragging = false;

  /// Gets the current dragging state of the item.
  bool get isDragging => _isDragging;

  /// Sets the dragging state of the item.
  set setDragging(bool isDragging) => _isDragging = isDragging;

  /// Gets the current cursor position.
  Offset get cursor => _cursor;

  /// Sets the current cursor position.
  set setCursor(Offset value) => _cursor = value;

  /// Initializes the animation controllers and animations.
  ///
  /// This method sets up the animation controllers and defines the
  /// animations for dragging, translation, and scaling interactions.
  void initialize() {
    _dragController = AnimationController(
        vsync: vsync, duration: const Duration(milliseconds: 350));
    _dragAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _dragController, curve: Curves.decelerate));

    _translationController = AnimationController(
        vsync: vsync, duration: const Duration(milliseconds: 300));
    _translationAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _translationController, curve: Curves.decelerate));

    _scalingController = AnimationController(
        vsync: vsync, duration: const Duration(milliseconds: 300));
    _scalingAnimation = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _scalingController, curve: Curves.easeInBack));
  }

  /// Gets the animation controller for dragging interactions.
  AnimationController get dragController => _dragController;

  /// Gets the animation for dragging interactions.
  Animation<double> get dragAnimation => _dragAnimation;

  /// Gets the animation controller for translation interactions.
  AnimationController get translationController => _translationController;

  /// Gets the animation for translation interactions.
  Animation<double> get translationAnimation => _translationAnimation;

  /// Gets the animation controller for scaling interactions.
  AnimationController get scalingController => _scalingController;

  /// Gets the animation for scaling interactions.
  Animation<double> get scalingAnimation => _scalingAnimation;

  /// Sets the range for the drag animation.
  void setDragAnimationRange(double begin, double end) {
    _dragAnimation = Tween<double>(begin: begin, end: end).animate(
        CurvedAnimation(parent: _dragController, curve: Curves.decelerate));
  }

  /// This method is called when the animation state is no longer needed.
  /// It ensures that all animation controllers are properly disposed to
  /// prevent memory leaks.
  void dispose() {
    _dragController.dispose();
    _translationController.dispose();
    _scalingController.dispose();
  }
}

/// The state class for the [DockItem] widget, managing the animations and
/// interactions for individual dock items.
class _DockItemState extends State<DockItem> with TickerProviderStateMixin {
  // Constants defining the standard size and margin for dock items.
  static const double _standSize = 48, _standMargin = 10;
  static const double _maxSize = _standSize + _standMargin;
  static const Offset _alignment = Offset(_standMargin, 0);

  // State objects for managing the base, child, and overlay states of the item.
  final BaseState base = BaseState(Size(_standSize, _standSize), _standMargin);
  final ChildState childWidget =
      ChildState(Size(_standSize, _standSize), _standMargin, _alignment);
  final OverlayState overlay = OverlayState(Size(_standSize, _standSize));

  // Animation state for managing animations related to the dock item.
  late AnimationState anim;

  /// Calculates the new size of the dock item based on the cursor position.
  ///
  /// Uses a [Cosine] function to determine the size effect based on the cursor's
  /// proximity to the item's center, creating a smooth scaling effect.
  ///
  /// Returns the new dimension for the dock item.
  double calcSize(Offset cursor) {
    Rect childRect = base.rect(context);

    double effectWidth = 5 * _standSize;
    double minX = cursor.dx - (effectWidth / 2);
    double theta = ((childRect.center.dx + childWidget.translation.dx - minX) /
            effectWidth) *
        2 *
        pi;
    theta = min(max(theta, 0), 2 * pi);
    double newDimension =
        _standSize + ((1 - cos(theta)) / 2) * (_maxSize - _standSize);
    return newDimension;
  }

  /// Calculates the position for the overlay based on the current item position.
  Offset calcOverlayPosition() {
    return childWidget.rect(context).topLeft;
  }

  /// Animates the growth of the dock item, making it visible.
  Future<void> growAnimation() async {
    await anim.scalingController.reverse();
    childWidget.setVisibility = true;
  }

  /// Animates the shrinkage of the dock item, making it invisible.
  Future<void> shrinkAnimation() async {
    childWidget.setVisibility = false;
    await anim.scalingController.forward();
  }

  /// Animates the translation of the dock item to a new position.
  Future<void> translateAnimation(Offset translatePosition) async {
    childWidget.setTranslationPosition = translatePosition;
    await anim._translationController.forward(from: 0);
    Rect rect = childWidget.rect(context);
    overlay.setSize = rect.size;
    overlay.setPosition = rect.topLeft +
        childWidget.translation +
        Offset(0, childWidget.margin.top);
    overlay.show();
    childWidget.setTranslation = Offset.zero;
  }

  /// Resets the translation animation, hiding the overlay.
  ///
  /// Waits for a short delay before hiding the overlay to ensure smooth transition.
  Future<void> resetTranslationAnimation() async {
    await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      overlay.hide();
    });
  }

  /// Starts the hover animation, adjusting the size based on cursor position.
  void startHovering(Offset cursor) {
    anim.setCursor = cursor;
    double size = calcSize(cursor);
    childWidget.setSize = Size(size, size);
    childWidget.setTopMargin = _standMargin - (size - _standSize);
  }

  /// Ends the hover animation, resetting the item to its standard size.
  void endHovering() {
    childWidget.setSize = Size(_standSize, _standSize);
    childWidget.setTopMargin = _standMargin;
  }

  /// Initiates the drag start event, setting up the overlay and animations.
  void dragStart() {
    base.setSideMargin =
        (childWidget.size.width - base.size.width) / 2 + _standMargin;
    overlay.setSize = childWidget.size;
    overlay.setPosition = calcOverlayPosition();
    overlay.show();
    setState(() {
      anim.setDragging = true;
    });
  }

  /// Updates the drag event, moving the overlay based on the drag delta.
  void dragUpdate(Offset delta) {
    overlay.setDrag = delta;
  }

  /// Ends the drag event, resetting the item and hiding the overlay.
  Future<void> dragEnd() async {
    base.setSideMargin = _standMargin;
    await growAnimation();
    Offset initialPosition = overlay.position;
    Offset finalPosition = calcOverlayPosition();
    overlay.setDragEndPosition(initialPosition, finalPosition);
    await anim.dragController.forward(from: 0);
    setState(() {
      anim.setDragging = false;
      overlay.hide();
    });
    anim.dragController.reset();
    anim.scalingController.reset();
    anim.translationController.reset();
  }

  /// This method is called when the state is created. It initializes the
  /// animation controllers and sets up listeners for animation updates.
  @override
  void initState() {
    super.initState();

    anim = AnimationState(vsync: this);
    anim.initialize();
    anim.dragController.addListener(() {
      List<Offset> dragEnd = overlay.dragEndPosition;
      overlay.setPosition =
          dragEnd[0] + (dragEnd[1] - dragEnd[0]) * anim.dragAnimation.value;
    });
    anim.translationController.addListener(() {
      double size = calcSize(anim.cursor);
      childWidget.setSize = Size(size, size);
      childWidget.setTopMargin = _standMargin - (size - _standSize);
      childWidget.setTranslation =
          (childWidget.translatePosition - childWidget.rect(context).topLeft) *
              anim.translationAnimation.value;
    });

    anim.scalingController.addListener(() {
      base.setScaleFactor = anim.scalingAnimation.value;
    });
  }

  /// Disposes of the animation controllers to free up resources.
  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }

  /// Builds the UI for the dock item, including animations and overlays.
  ///
  /// This method constructs the visual representation of the dock item,
  /// including the base, overlay, and child widgets with their respective
  /// animations and transformations.
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.bottomCenter, children: [
      AnimatedBuilder(
        animation: base,
        builder: (context, child) {
          return Container(
              alignment: Alignment.bottomCenter,
              width: base.size.width * base.scaleFactor,
              height: base.size.height,
              margin: base.margin * base.scaleFactor,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ));
        },
      ),
      AnimatedBuilder(
        animation: overlay,
        builder: (context, child) {
          return OverlayPortal(
              controller: overlay.controller,
              overlayChildBuilder: (BuildContext context) {
                return Positioned(
                    top: overlay.position.dy,
                    left: overlay.position.dx,
                    width: overlay.size.width,
                    height: overlay.size.height,
                    child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          constraints:
                              const BoxConstraints(minWidth: _standSize),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.primaries[
                                widget.icon.hashCode % Colors.primaries.length],
                          ),
                          child: Center(
                            child: Icon(widget.icon, color: Colors.white),
                          ),
                        )));
              });
        },
      ),
      AnimatedBuilder(
        animation: childWidget,
        builder: (context, child) {
          return Visibility(
            visible: !overlay.isShown,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 50),
              transform: Matrix4.translationValues(
                  childWidget.translation.dx, childWidget.translation.dy, 0),
              alignment: Alignment.bottomCenter,
              width: childWidget.size.width,
              height: childWidget.size.height,
              margin: childWidget.margin,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors
                    .primaries[widget.icon.hashCode % Colors.primaries.length],
              ),
              child: Center(
                child: Icon(widget.icon, color: Colors.white),
              ),
            ),
          );
        },
      )
    ]);
  }
}

# Flutter Dock Application
<p align="center">
  <img src="https://github.com/VPRoyal/Mac-Dock-Flutter-code/blob/main/dock-image" alt="Dock Image">
</p>

This README file provides an overview and explanation of the Flutter application code provided, which implements a draggable and animated Dock, similar to that seen in dockable UI frameworks such as macOS. The application allows users to drag and organize icons, providing intuitive interactions with visual feedback.

## Table of Contents

1. [Introduction](#introduction)
2. [Class Overview](#class-overview)
3. [Detailed Documentation of Each Section](#detailed-documentation-of-each-section)
   - [Main Application Setup](#main-application-setup)
   - [Home Page Implementation](#home-page-implementation)
   - [Dock Widget Implementation](#dock-widget-implementation)
   - [DragState Class](#dragstate-class)
   - [DockState Implementation](#dockstate-implementation)
   - [DockItem Class](#dockitem-class)
     - [Base Widget](#)
     - [Child Widget](#)
     - [Overlay Widget](#)
   - [Animation and State Management](#animation-and-state-management)
     - [Base State Class](#base-state-class)
     - [Child State Class](#child-state-class)
     - [Overlay State Class](#overlay-state-class)
     - - [Animation State Class](#animation-state-class)
    - [Application Logic Implementation](#)
4. [Dart Documentation Guidelines](#dart-documentation-guidelines)

## Introduction

The Flutter application demonstrates a custom widget called `Dock` which mimics the behavior of a typical desktop dock interface. The dock is interactive, allowing elements (icons) to be dragged and rearranged with smooth animations and user feedback. As a Flutter application, it leverages stateful widgets, gestures, and animations to provide a rich user experience.

## Class Overview

- **MyApp**: The root of the application, setting up the MaterialApp.
- **HomePage**: Hosts the `Dock` widget.
- **Dock**: A customizable widget that contains multiple `DockItem` widgets, offering drag and drop functionality.
- **DockItem**: Individual item representation within the Dock.
- **DragState**: Manages and stores various states related to dragging operations.
- **Animation and Base Classes**: Classes like `BaseState`, `ChildState`, etc., manage different aspects of animation and positioning.

## Detailed Documentation of Each Section

### Main Application Setup

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- **Functionality**: The `main` function is the entry point for the application. It initializes and runs the `MyApp` widget.
- **MyApp Class**: Extends `StatelessWidget` and sets up the MaterialApp with `HomePage` as the home screen. Configured without the debug banner.

### Home Page Implementation

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
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
```

- **Functionality**: Constructs a basic home page with a centered `Dock` widget that contains multiple predefined icons.
- **UI Layout**: Uses a `Scaffold` for basic app structure and centers the Dock widget within the `body`.

### Dock Widget Implementation

```dart
class Dock extends StatefulWidget {
  const Dock({super.key, required this.items});
  final List<IconData> items;

  @override
  State<Dock> createState() => _DockState();
}
```

- **Properties**: Accepts a list of `IconData` to be used as items within the dock.
- **State Management**: Utilizes a stateful widget to handle the dynamic nature of dragging and reordering icons.

### DragState Class

```dart
class DragState {
  // Properties and State flags
  bool _isDragging = false, _isHovering = false, _isAnimating = false;
  bool _isSliding = false, _cancelSliding = false;
  Completer<void>? _slideCompleter;
  Timer? _slidingDebounce, _dragInDebounce, _dragOutDebounce;
  int _dragIndex = -1, _newIndex = -1;
  Offset _dragOffset = Offset.zero, _cursor = Offset.zero;

  DragState();
  
  // Getters and setters for properties
  bool get isDragging => _isDragging;
  set setDragging(bool value) => _isDragging = value;

  // Additional getters and setters omitted for brevity
}
```

- **Purpose**: Encapsulates the state related to drag operations.
- **States Managed**: Includes dragging, hovering, animating states, and helper objects like `Timer` and `Completer` for async operations.

### DockState Implementation

```dart
class _DockState extends State<Dock> with TickerProviderStateMixin {
  // Internal variables for managing the state

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Gesture detection setup for drag and hover events
      
      child: MouseRegion(
        // Mouse hover setup
        
        child: Container(
          // UI rendering the dock and items within
        ),
      ),
    );
  }
  
  // Methods to handle drag and hover events are included
}
```

- **Gesture Handling**: Sets up handlers for mouse and drag gestures, managing updates and animations.
- **UI Composition**: Uses `GestureDetector` and `MouseRegion` to enhance interactivity with the dock items.
- **Class Methods**: Implements various methods to provide drag and hovering functionalities.
    - **Drag Event Handlers**: `onDragStart`, `onDragUpdate`, `onDragEnd` executes dragging logic for events `onPanStart`, `onPanUpdate`, `onPanEnd` respectively.
    - **Hover Event Handlers**: `onHoverInEvent`, `onHoverEvent`, `onHoverOutEvent` executes hovering logic for events `onEnter`, `onHover`, `onExit` respectively.
    - **DragIn-DragOut**: `dragInEvent` and `dragOutEvent` handle business logic for cursor entry and exit from the dock during dragging.
    - **Method-*repositionItem***: Handles the sliding animation and reordering of dock items during movement of dragged item inside the Dock.
    - **Method-*slideEvent***: Animates the movement of a dock item to a new position and updates its index.
    - **Method-*reindexing***: Adjusts the order of dock items by moving the dragged item to a new index.
    - **Method-*findNearestIndex***: Calculates the nearest dock item index to arrange based on the dragged item's position.
    - **Method-*findDragIndex***: Determines the index of the dock item under the cursor when dragStart event is fired up.
### DockItem Class

```dart
class DockItem extends StatefulWidget {
  final int itemIndex;
  final IconData icon;
  final GlobalKey widgetKey;
  
  const DockItem({
    required this.widgetKey, 
    required this.itemIndex, 
    required this.icon
  }) : super(key: widgetKey);

  @override
  State<DockItem> createState() => _DockItemState();
}
```

- **Functionality**: Represents individual items in the `Dock`. Each item is interactive and draggable.
- **Properties**: Each `DockItem` takes an icon, an index and a `GlobalKey` for identification.
- **UI Composition**: Contains three different widgets [`Base Widget`, `Overlay Widget`, `Child Widget`] to apply animating drag and reorder functionalities.
  - **Base Widget**: Offers a transparent base for other widgets and facilitates shrink and grow animations.
  - **Overlay Widget**: Provides visual feedback during dragging by dynamically updating the position on the screen.
  - **Child Widget**: Enables sliding and resizing animations during drag-and-hover interactions.
- **Class Methods**: Implements various methods to provide drag and hovering animations.
  - **Drag Event Handlers**: `dragStart`, `dragUpdate`, `dragEnd` executes dragging operations on various dragging events as triggered by the parent class.
  - **Hover Event Handlers**: `startHovering`, `endHoverng` starts and ends the hovering effect and associated animations over the icon as tirggered by the parent class.
  - **Method-*shrinkAnimation***: Hides the widget and plays a forward scaling animation to simulate the shrinking effect.
  - **Method-*growAnimation***: Plays a reverse scaling animation to simulate the growth of the widget and makes the widget visible once the animation completes.
  - **Method-*translateAnimation***: Animates the translation of the widget to a specified position, updating the overlay's size and position accordingly. This creates a smooth transition effect during drag events.
  - **Method-*resetTranslationAnimation***: Resets the translation state of the widget after a delay, ensuring the overlay is hidden and the widget returns to its original state.
  - **Method-*calcOverlayPosition***: Computes the topLeft position of the overlay widget relative to its child widget. This ensures proper positioning of the overlay during drag and hover operations.
  - **Method-*calcSize***: Calculates the size of the widget dynamically based on the cursor's position relative to the widget's center. The size transitions smoothly using a cosine-based function, with boundaries set by _standSize (default size) and _maxSize (maximum size). This is used to create visual effects during hover or drag events.

### Animation and State Management

```dart
class class BaseState extends ChangeNotifier {
  // Base widget state's logic --->
}
class class ChildState extends ChangeNotifier {
  // Child widget state's logic --->
}
class class OverlayState extends ChangeNotifier {
  // Overlay's state's logic --->
}
class AnimationState {
  // Animation State's logic --->
}
```

- **Purpose**: Manages Item's state and animation related logic, to perform resizing and translation effects during hover and drag operations.
- **Components**: Consists of multiple state classes to manage various state change operations and their data.
- animation controllers for orchestrating complex multi-step animations.
#### Base State Class
   - **Purpose**: Manages the base widget's state, including its size, margins, and scaling factor, and provides utility methods for determining its position on the screen.
   - **Key Properties**:
     - `_size`: The current size of the base widget.
     - `_margin`: The margins around the base widget.
     - `_scaleFactor`: Scale factor applied to the widget.
   - **Key Methods**:
     - **`size`**: Getter for the widget's size.
     - **`margin`**: Getter for the widget's margins.
     - **`scaleFactor`**: Getter for the scale factor.
     - **`setScaleFactor(double value)`**: Updates the scale factor and notifies listeners.
     - **`setSize(Size size)`**: Updates the widget's size and notifies listeners.
     - **`setSideMargin(double sideMargin)`**: Adjusts the left and right margins.
     - **`rect(BuildContext context)`**: Calculates and returns the widget's rectangle on the screen, adjusted for its margins.

#### Child State Class
   - **Purpose**: 
     Manages the state of a child widget, including size, margins, visibility, and translation properties, allowing for dynamic behavior during interactions.
   - **Key Properties**:
     - `_size`: The current size of the child widget.
     - `_margin`: The margins around the child widget.
     - `_translation`: Current translation offset.
     - `_translatePosition`: Target translation position.
     - `_alignment`: Alignment of the widget relative to its parent.
     - `_visibility`: Visibility status of the widget.
   - **Key Methods**:
     - **`size`**: Getter for the widget's size.
     - **`margin`**: Getter for the widget's margins.
     - **`translation`**: Getter for the current translation offset.
     - **`visibility`**: Getter for the visibility status.
     - **`setSize(Size size)`**: Updates the widget's size and notifies listeners.
     - **`setTopMargin(double topMargin)`**: Adjusts the top margin.
     - **`setTranslation(Offset offset)`**: Updates the translation offset and notifies listeners.
     - **`setVisibility(bool value)`**: Updates the visibility status and notifies listeners.
     - **`rect(BuildContext context)`**: Calculates and returns the widget's rectangle on the screen, adjusted for its alignment.

#### Overlay State Class
   - **Purpose**: 
     Handles the state of an overlay widget, including its size, position, visibility, and drag-related properties, providing methods to show, hide, and move the overlay dynamically.
   - **Key Properties**:
     - `_size`: The current size of the overlay.
     - `_position`: The current position of the overlay.
     - `_isShown`: Visibility status of the overlay.
     - `_dragEndInitialPosition`: Initial position for drag end animation.
     - `_dragEndFinalPosition`: Final position for drag end animation.
     - `_controller`: Controls the overlay's display state.
   - **Key Methods**:
     - **`size`**: Getter for the overlay's size.
     - **`position`**: Getter for the overlay's position.
     - **`isShown`**: Getter for the overlay's visibility status.
     - **`setSize(Size size)`**: Updates the overlay's size.
     - **`setPosition(Offset pos)`**: Updates the overlay's position and notifies listeners.
     - **`setDrag(Offset delta)`**: Updates the overlay's position based on a drag delta and notifies listeners.
     - **`rect`**: Calculates and returns the overlay's rectangle on the screen.
     - **`show()`**: Makes the overlay visible using the controller.
     - **`hide()`**: Hides the overlay using the controller.
     - **`setDragEndPosition(Offset start, Offset end)`**: Sets the initial and final positions for drag end animations.
     - **`dragEndPosition`**: Returns a list containing the initial and final positions for drag animations.

#### Animation State Class
   - **Purpose**: 
     Manages animation controllers and states for drag, translation, and scaling animations. Provides methods to initialize, configure, and dispose of animations.
   - **Key Properties**:
     - `_isDragging`: Indicates whether a drag operation is active.
     - `_cursor`: Current cursor position.
     - `vsync`: Ticker provider for managing animations.
     - `_dragController`, `_translationController`, `_scalingController`: Animation controllers for managing drag, translation, and scaling animations.
     - `_dragAnimation`, `_translationAnimation`, `_scalingAnimation`: Corresponding animations for the controllers.
   - **Key Methods**:
     - **`initialize()`**: Initializes animation controllers and their corresponding animations with predefined durations and curves.
     - **`setDragAnimationRange(double begin, double end)`**: Configures the range for the drag animation.
     - **`dispose()`**: Disposes all animation controllers to free resources.
     - **`dragController`**: Getter for the drag animation controller.
     - **`translationController`**: Getter for the translation animation controller.
     - **`scalingController`**: Getter for the scaling animation controller.
     - **`dragAnimation`**: Getter for the drag animation.
     - **`translationAnimation`**: Getter for the translation animation.
     - **`scalingAnimation`**: Getter for the scaling animation.

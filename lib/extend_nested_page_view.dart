

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nestedpageview/nested_page_view.dart';

typedef ScrollActivityCreator = ScrollActivity Function(ChildPageScrollPosition position);

class NestedPageViewCoordinator implements ScrollActivityDelegate,ScrollHoldController{

  //外层的pageController
  NestedPageController _outerController = NestedPageController();
  //当前处于接收触摸事件的子页面controller的position
  ChildPageScrollPosition _currentPosition;
  //当前滑动控制
  ScrollDragController _currentDrag;
  ///获取外层的pageController
  NestedPageController get outController => _outerController;
  ///获取外层对应的PageController的position
  ChildPageScrollPosition get outPosition => _outerController.position;
  ///获取新的子controller
  NestedPageController newChildPageController() => NestedPageController(coordinator: this);

  ///接管用户触摸事件
  ScrollHoldController hold(ChildPageScrollPosition position,VoidCallback holdCancelCallback) {
    _currentPosition = position;
    beginActivity(
        HoldScrollActivity(
          delegate: outPosition,
          onHoldCanceled: holdCancelCallback,
        ),(ChildPageScrollPosition innerPosition) => HoldScrollActivity(delegate: innerPosition)
    );
    return this;
  }

  ///接管用户drag事件
  Drag drag(ChildPageScrollPosition position,DragStartDetails details, VoidCallback dragCancelCallback) {
    final ScrollDragController drag = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
    );
    beginActivity(DragScrollActivity(outPosition, drag),
            (ChildPageScrollPosition innerPosition) => DragScrollActivity(innerPosition, drag)
    );
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  ///开启用户触摸后的pageView活动
  void beginActivity(ScrollActivity newOuterActivity,ScrollActivityCreator creator) {
    bool scrolling = true;
    outPosition.beginActivity(newOuterActivity);
    scrolling = scrolling && newOuterActivity.isScrolling;
    var innerActivity = creator(_currentPosition);
    _currentPosition?.beginActivity(innerActivity);
    scrolling = scrolling && innerActivity.isScrolling;
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!scrolling){
      outPosition.updateUserDirection(ScrollDirection.idle);
      _currentPosition?.updateUserDirection(ScrollDirection.idle);
    }
  }

  @override
  void cancel() {
    goBallistic(0.0);
  }

  @override
  AxisDirection get axisDirection => _outerController.position.axisDirection;

  @override
  void goIdle() {
    beginActivity(
      IdleScrollActivity(outPosition),
          (ChildPageScrollPosition innerPosition) => IdleScrollActivity(innerPosition),
    );
  }

  @override
  double setPixels(double pixels) {
    return 0.0;
  }

  @override
  void applyUserOffset(double delta) {
    outPosition.updateUserDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    _currentPosition?.updateUserDirection(delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    if (_currentPosition != null && !_currentPosition.isOverScroll(delta)){
      _currentPosition.applyFullDrag(delta);
    }else {
      outPosition.applyFullDrag(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    ///结束触摸时必须重置外层滑动状态，因为开启活动时内外状态都已改变
    if (outPosition.isInDragScrolling()){
      outPosition.goBallistic(velocity);
    } else {
      outPosition.goIdle();
    }
    if (_currentPosition != null){
      ///如果是内存滑动则需处理
      if (_currentPosition.isInDragScrolling()){
        _currentPosition.goBallistic(velocity);
      }
      _currentPosition = null;
    }
    ///停止drag状态
    _currentDrag?.dispose();
    _currentDrag = null;
  }

}

class ChildPageScrollPosition extends CustomPagePosition implements ScrollActivityDelegate,ScrollHoldController{

  final NestedPageViewCoordinator coordinator;

  ChildPageScrollPosition({
    this.coordinator,
    ScrollPhysics physics,
    ScrollContext context,
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
    ScrollPosition oldPosition,
  }) :super(
      physics: physics,
      context: context,
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      oldPosition:oldPosition);

  ///包装updateUserScrollDirection
  void updateUserDirection(ScrollDirection direction){
    updateUserScrollDirection(direction);
  }

  ///通过滑动page范围判断当前是否有页面滑动
  bool isInDragScrolling() {
    if (pixels == null || maxScrollExtent == null || minScrollExtent == null){
      return false;
    }
    return page?.toStringAsFixed(2) != page?.toInt()?.toStringAsFixed(2);
  }

  ///全全处理滑动
  double applyFullDrag(double delta){
    var newPixels = pixels - physics.applyPhysicsToUserOffset(this, delta);
    if (newPixels != pixels) {
      final double overscroll = applyBoundaryConditions(newPixels);
      final double oldPixels = pixels;
      correctPixels(newPixels - overscroll);
      if (pixels != oldPixels) {
        notifyListeners();
        didUpdateScrollPositionBy(pixels - oldPixels);
      }
      if (overscroll != 0.0) {
        didOverscrollBy(overscroll);
        return overscroll;
      }
    }
    return 0.0;
  }

  ///判断是否过度滑动了
  bool isOverScroll(double delta){
    var newPixels = pixels - physics.applyPhysicsToUserOffset(this, delta);
    if (newPixels != pixels){
      final double overscroll = applyBoundaryConditions(newPixels);
      return overscroll != 0;
    }
    return false;
  }

  ///去除自带用户移动操作
  @override
  double applyUserOffset(double delta) {
    return 0.0;
  }

  ///手指触摸到屏幕时
  @override
  ScrollHoldController hold(holdCancelCallback) {
    if (coordinator != null){
      return coordinator.hold(this,holdCancelCallback);
    }
    return super.hold(holdCancelCallback);
  }

  ///手指滑动时交于协调器控制
  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    if (coordinator != null){
      return coordinator.drag(this,details, dragCancelCallback);
    }
    return super.drag(details, dragCancelCallback);
  }

  ///调用父类解决继续滑动
  @override
  void goBallistic(double velocity) {
    super.goBallistic(velocity);
  }

  @override
  void cancel() {
    goBallistic(0.0);
  }

}

class NestedPageController extends CustomPageController {

  final NestedPageViewCoordinator coordinator;

  NestedPageController({
    this.coordinator,
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
  }):super(initialPage:initialPage,keepPage:keepPage,viewportFraction:viewportFraction);

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition oldPosition) {
    return ChildPageScrollPosition(
      coordinator: coordinator,
      physics: physics,
      context: context,
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      oldPosition: oldPosition,
    );
  }

}
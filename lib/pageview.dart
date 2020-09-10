import 'package:flutter/material.dart';
import 'dart:io';

class PageViewRoute extends StatefulWidget {
  PageViewRoute(
      {Key key,
      this.imagelist,
      this.index,
      this.height,
      this.firstindex,
      this.controller,
      this.grid});
  final List<File> imagelist;
  final int index;
  final int firstindex;
  final double height;
  final bool grid;
  final ScrollController controller;
  _PageViewRouteState createState() => _PageViewRouteState();
}

class _PageViewRouteState extends State<PageViewRoute>
    with SingleTickerProviderStateMixin {
  int quitindex;
  PageController _controller;
  AnimationController _anicontroller;
  Animation<Offset> _animation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;
  double _kMinFlingVelocity = 600.0;

  @override
  void initState() {
    _controller = PageController(initialPage: widget.index);
    _anicontroller = AnimationController(vsync: this);
    _anicontroller.addListener(() {
      setState(() {
        _offset = _animation.value;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _anicontroller.dispose();
    super.dispose();
  }

  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // 计算图片放大后的位置
      _anicontroller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 3.0);
      // 限制放大倍数 1~3倍
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      // 更新当前位置
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    // 计算当前的方向
    final double distance = (Offset.zero & context.size).shortestSide;
    // 计算放大倍速，并相应的放大宽和高，比如原来是600*480的图片，放大后倍数为1.25倍时，宽和高是同时变化的
    _animation = _anicontroller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _anicontroller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _handleonDoubleTap() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
            onScaleStart: _handleOnScaleStart,
            onScaleUpdate: _handleOnScaleUpdate,
            onScaleEnd: _handleOnScaleEnd,
            onDoubleTap: _handleonDoubleTap,
            onTap: () {
              Navigator.pop(context);
              if (quitindex != null && quitindex != widget.firstindex)
                widget.controller.animateTo(
                    widget.grid
                        ? widget.height * (quitindex ~/ 3 - 1) - 30
                        : widget.height * quitindex - 150,
                    duration: Duration(milliseconds: 100),
                    curve: Curves.ease);
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) {
                quitindex = value;
              },
              itemBuilder: (context, index) {
                return ConstrainedBox(
                    constraints: BoxConstraints.expand(),
                    child: ClipRect(
                        child: Transform(
                            transform: Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                            child: Image.file(widget.imagelist[index]))));
              },
              itemCount: widget.imagelist.length,
            )));
  }
}

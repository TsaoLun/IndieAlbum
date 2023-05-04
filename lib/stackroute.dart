//自定义浏览页部分
import 'package:serious_album/main.dart';
import 'pageview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'album_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StackRoute extends StatefulWidget {
  StackRoute(
      {Key key,
      @required this.imagelist,
      this.dropmode: false,
      this.droplist,
      this.album})
      : super(key: key);
  final imagelist;
  final dropmode;
  final droplist;
  final album;

  @override
  _StackRouteState createState() => _StackRouteState();
}

class _StackRouteState extends State<StackRoute> {
  bool grid = false;
  //透明化AppBar
  bool _hidebar = false;
  //监听滚动
  ScrollController _controller = ScrollController(initialScrollOffset: -1);

//注意是getBool不是get
  Future<void> getGrid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('grid') != null) {
      grid = prefs.getBool('grid');
    }
    Provider.of<AppInfoProvider>(context, listen: false).setGrid(grid);
  }

  setGrid() async {
    await SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('grid', !grid));
  }

  @override
  void initState() {
    getGrid();
    _controller.addListener(() {
      //监听滚动高度以打开透明模式
      if (_controller.offset < 50 && _hidebar) {
        setState(() {
          _hidebar = false;
        });
      } else if (_controller.offset >= 50 && _hidebar == false) {
        setState(() {
          _hidebar = true;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  showHelpDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("帮助"),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
                padding: EdgeInsets.only(left: 15),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Row(children: <Widget>[Icon(Icons.check_box), Text("管理照片")]),
                  Row(children: <Widget>[
                    Icon(Icons.add_photo_alternate),
                    Text("添加照片")
                  ]),
                  Row(children: <Widget>[Icon(Icons.grid_on), Text("网格浏览")]),
                  Row(children: <Widget>[
                    Icon(Icons.arrow_forward),
                    Text('右滑退出')
                  ]),
                  Row(children: <Widget>[
                    Text("相册支持载入 60 张照片", style: TextStyle(fontSize: 10))
                  ]),
                ])),
            actions: [
              MaterialButton(
                  child: Text("知道了",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    //获取grid高度以返回时跳转到相应位置
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    double _height = grid ? width / 3 : width * 0.65;
    double _left = 0.0;
    //设置堆叠，透过AppBar看到图片
    return Stack(children: <Widget>[
      //先布局下层图片
      Positioned(
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) {
                _left = details.delta.dx;
                if (_left > 10.0) {
                  Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (context, animation, animation2) =>
                              MyHomePage(
                                album: widget.album,
                              ),
                          transitionsBuilder:
                              (context, animation, animation2, child) {
                            var begin = Offset(-1.0, 0.0);
                            var end = Offset.zero;
                            var curve = Curves.ease;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          }));
                }
              },
              child: Consumer<AppInfoProvider>(builder: (context, appInfo, _) {
                grid = appInfo.gridmode;
                return GridView.builder(
                    controller: _controller,
                    padding: EdgeInsets.only(top: 0.22 * width),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        //间距以及不同模式宽高，列数
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                        childAspectRatio: grid == false ? 1 / 0.65 : 1,
                        crossAxisCount: grid == false ? 1 : 3),
                    //itemCount最小为1
                    itemCount: widget.imagelist.length == 0
                        ? 1
                        : widget.imagelist.length,
                    itemBuilder: (context, index) {
                      //图片列表为空时提示，存在直接则加载
                      return widget.imagelist.length == 0
                          ? Container(
                              alignment: Alignment.bottomCenter,
                              padding: EdgeInsets.only(top: 0.25 * height),
                              child: Text('尚未选择任何照片',
                                  style: TextStyle(fontSize: 24)))
                          : GestureDetector(
                              //套上一层GDetector，dropmode下为选择，否则实现点击加载
                              onTap: () => widget.dropmode
                                  ? setState(
                                      () => !widget.droplist.contains(index + 1)
                                          //dropmode下判断点击图片index在不在list中
                                          ? widget.droplist.add(index + 1)
                                          : widget.droplist.remove(index + 1))
                                  : Navigator.push(
                                      //非dropmode下点击进入全屏模式
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PageViewRoute(
                                              imagelist: widget.imagelist,
                                              index: index,
                                              firstindex: index,
                                              controller: _controller,
                                              grid: grid,
                                              height: _height))),
                              child: Opacity(
                                  opacity: widget.droplist.contains(index + 1)
                                      ? 0.6
                                      : 1,
                                  child: ClipRect(
                                      //不同预览图裁剪模式
                                      child: Image.file(
                                    widget.imagelist[index],
                                    cacheHeight: grid ? 500 : null,
                                    scale: grid == false ? 0.3 : 0.01,
                                    filterQuality: FilterQuality.low,
                                    fit: grid == false
                                        ? BoxFit.fitWidth
                                        : BoxFit.cover,
                                  ))));
                    });
              }))),
      Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0.8 * height,
          child: AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.help,
                  size: 18,
                ),
                onPressed: showHelpDialog,
              ),
              //点击切换两种浏览模式以及根据上面的监听变量决定AppBar是否透明
              title: widget.dropmode
                  ? Text('已选图片 ${widget.droplist.length} 张: ' +
                      widget.droplist.toString())
                  : Text("相册图片 ${widget.imagelist.length} 张"),
              backgroundColor: _hidebar
                  ? Colors.transparent
                  : Theme.of(context).primaryColor,
              actions: [
                Consumer<AppInfoProvider>(builder: (context, appInfo, _) {
                  return IconButton(
                      icon: Icon(grid ? Icons.collections : Icons.grid_on),
                      onPressed: () {
                        appInfo.changeGrid();
                        setGrid();
                        _hidebar = false;
                        imageCache.clear();
                      });
                })
              ]))
    ]);
  }
}

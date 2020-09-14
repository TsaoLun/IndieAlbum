//首页
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:serious_album/album_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'albumroute.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pth;
import 'package:gesture_recognition/gesture_view.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final appInfo = AppInfoProvider();
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [ChangeNotifierProvider.value(value: AppInfoProvider())],
        child: Consumer<AppInfoProvider>(builder: (context, appInfo, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '独立相册',
            theme: ThemeData(
              primaryColor:
                  themeColorMap[appInfo.themeColor] ?? Colors.blueGrey,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: themeColorMap[appInfo.themeColor]),
            home: MyHomePage(album: 1),
          );
        }));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.album}) : super(key: key);
  final int album;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<GestureState> gestureStateKey = GlobalKey();
  int status = 0;
  List<int> result;
  bool lockmode = false;
  bool unlocking = false;
  bool _namemode = false;
  bool _settingmode = false;
  bool _keymode = false;
  String albumname = "";
  TextEditingController _namecontroller = TextEditingController();
  SharedPreferences prefs;
  int maxalbum = 1;
  int existmax;
  List<String> dropalbum = [];
  File backimage;
  String _colorKey;

  void changeAlbumName() {
    _namemode = !_namemode;
    setState(() {});
  }

  void getName() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("album${widget.album}") == null) {
      albumname = "独立相册 No.${widget.album}";
    } else {
      albumname = prefs.getString("album${widget.album}");
    }
    setState(() {});
  }

  Future setName(v) async {
    prefs = await SharedPreferences.getInstance();
    prefs.setString("album${widget.album}", v);
  }

  Future setMaxAlbum() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setInt('maxalbum', maxalbum);
  }

  getexistMax(int i) async {
    //这里很重要！
    if (dropalbum.contains(i.toString())) {
      i = i - 1;
      return getexistMax(i);
    } else {
      existmax = i;
    }
  }

  //删除相册
  void dropAlbum() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList('dropalbum') == null) {
      prefs.setStringList('dropalbum', [widget.album.toString()]);
      dropalbum = prefs.getStringList('dropalbum');
    } else {
      dropalbum = prefs.getStringList('dropalbum');
      dropalbum.add(widget.album.toString());
      prefs.setStringList('dropalbum', dropalbum);
    }
    dropAlbumFile();
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
            pageBuilder: (context, animation, animation2) =>
                MyHomePage(album: 1),
            transitionsBuilder: (context, animation, animation2, child) {
              var begin = Offset(-1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.ease;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            }));
  }

  //清除删除相册后的缓存
  void dropAlbumFile() async {
    if (prefs.get('${widget.album}number') != null) {
      await getApplicationDocumentsDirectory().then((value) {
        int _number = prefs.get('${widget.album}number');
        for (var i = 0; i < _number; i++) {
          File(pth.join(value.path, prefs.get('${widget.album}index${i + 1}')))
              .delete();
        }
        prefs.setInt('${widget.album}number', 0);
        prefs.remove('back${widget.album}');
        if (prefs.get('back${widget.album}') != null)
          File(pth.join(value.path, prefs.get('back${widget.album}'))).delete();
      });
    }
  }

  void getAlbum() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList('dropalbum') != null)
      dropalbum = prefs.getStringList('dropalbum');
    if (prefs.getInt('maxalbum') != null) maxalbum = prefs.getInt('maxalbum');
  }

  changeAlbum(bool nextalbum, int album) {
    if (nextalbum == true && !dropalbum.contains((album + 1).toString())) {
      return MyHomePage(album: album + 1);
    } else if (nextalbum == true &&
        dropalbum.contains((album + 1).toString())) {
      return changeAlbum(true, album + 1);
    } else if (nextalbum == false &&
        !dropalbum.contains((album - 1).toString())) {
      return MyHomePage(album: album - 1);
    } else if (nextalbum == false &&
        dropalbum.contains((album - 1).toString())) {
      return changeAlbum(false, album - 1);
    }
  }

  //设置背景图片
  Future setbackImage() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String number = DateTime.now().second.toString();
    List<Asset> resultList;
    resultList = await MultiImagePicker.pickImages(
      cupertinoOptions: CupertinoOptions(),
      maxImages: 1,
    );
    if (resultList != null) {
      await resultList[0].getByteData().then((e) {
        File(pth.join(appDocDir.path, '${number}back${widget.album}.jpg'))
            .writeAsBytes(e.buffer.asUint8List());
        if (prefs.get('back${widget.album}') != null) {
          File(pth.join(appDocDir.path, prefs.get('back${widget.album}')))
              .delete();
        }
        prefs.setString(
            'back${widget.album}', '${number}back${widget.album}.jpg');
      });
    }
    //这里不需要setState，只需在get方法中获得backimage时更新即可
    getBackImage();
    _settingmode = false;
  }

  //得到背景图片，注意backimage存在缓存问题
  getBackImage() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('back${widget.album}') != null)
        backimage =
            File(pth.join(appDocPath, prefs.getString('back${widget.album}')));
    });
  }

  //首页手势
  void getDetector(details) {
    double _left = 0.0;
    _left = details.delta.dx;
    getexistMax(maxalbum);
    if (_left < -5.0 && widget.album < existmax) {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
              pageBuilder: (context, animation, animation2) =>
                  changeAlbum(true, widget.album),
              transitionsBuilder: (context, animation, animation2, child) {
                var begin = Offset(1.0, 0.0);
                var end = Offset.zero;
                var curve = Curves.ease;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              }));
    } else if (_left > 5.0 && widget.album > 1) {
      Navigator.pushReplacement(
          context,
          PageRouteBuilder(
              pageBuilder: (context, animation, animation2) =>
                  changeAlbum(false, widget.album),
              transitionsBuilder: (context, animation, animation2, child) {
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
  }

  Future<bool> showDeleteDialog() {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("提示"),
            content: Text("您确定要删除当前相册吗？"),
            actions: <Widget>[
              FlatButton(
                  child: Text("点错了",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context)),
              FlatButton(
                  child: Text("删除",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context, true))
            ],
          );
        });
  }

  Future<bool> showDeleteDialog1() {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("提示"),
            content: Text("您确定要清空首页相册吗？"),
            actions: <Widget>[
              FlatButton(
                  child: Text("点错了",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context)),
              FlatButton(
                  child: Text("清空",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context, true))
            ],
          );
        });
  }

  showHelpDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: GestureDetector(
                child: Text("帮助"),
                onTap: () {
                  showSecrectDialog();
                }),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
                padding: EdgeInsets.only(left: 15),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Row(children: <Widget>[
                    Icon(Icons.add_circle_outline),
                    Text("新建相册")
                  ]),
                  Row(children: <Widget>[
                    Icon(Icons.delete_forever),
                    Text("删除相册")
                  ]),
                  Row(children: <Widget>[
                    Icon(Icons.compare_arrows),
                    Text("切换相册")
                  ]),
                  Row(children: <Widget>[Icon(Icons.create), Text("相册改名")]),
                  Row(children: <Widget>[
                    Icon(Icons.unfold_more),
                    Text("切换模式")
                  ]),
                  Row(children: <Widget>[
                    Icon(Icons.lock),
                    Text("上锁解锁"),
                  ]),
                ])),
            actions: [
              FlatButton(
                  child: Text("知道了",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context))
            ],
          );
        });
  }

  showSecrectDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("悄悄帮助"),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Padding(
              padding: EdgeInsets.only(left: 15),
              child: Row(children: <Widget>[
                Icon(Icons.lock),
                Text("忘记密码了？\n在设置中点解锁图标\n按 123546879 顺序解锁",
                    textAlign: TextAlign.center)
              ]),
            ),
            actions: [
              FlatButton(
                  child: Text("小声:知道了",
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  onPressed: () => Navigator.pop(context))
            ],
          );
        });
  }

  //点击进入存在key时或在设置中点击设置key做完手势后进入这个模式_keymode
  inputKey(List<int> result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String correctResult = prefs.getString("key${widget.album}");
    //点击设置且key为null，设置密码
    if (correctResult == null) {
      prefs.setString("key${widget.album}", result.toString());
      lockmode = true;
      _keymode = false;
    } else if (correctResult == result.toString() && unlocking == false) {
      _keymode = false;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PickerPage(album: widget.album)));
    } else if (correctResult == result.toString() ||
        //紧急解锁密码机制
        result.toString() == [0, 1, 2, 4, 3, 5, 7, 6, 8].toString() &&
            unlocking == true) {
      prefs.remove("key${widget.album}");
      _keymode = false;
      unlocking = false;
      lockmode = false;
    } else {
      _keymode = false;
      unlocking = false;
    }
  }

  checkKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String correctResult = prefs.getString("key${widget.album}");
    if (correctResult == null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PickerPage(album: widget.album)));
    } else {
      setState(() {
        _keymode = true;
      });
    }
  }

  checkLocked() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String correctResult = prefs.getString("key${widget.album}");
    if (correctResult != null) {
      lockmode = true;
    }
  }

  Future<void> getColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.get('key_theme_color') != null) {
      _colorKey = prefs.get('key_theme_color');
    } else {
      _colorKey = 'bluegrey';
    }
    Provider.of<AppInfoProvider>(context, listen: false).setTheme(_colorKey);
  }

  Future<void> setColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('key_theme_color', _colorKey);
  }

  changeColor() {
    var _list = ['bluegrey', 'red'];
    _colorKey = _list[(_list.indexOf(_colorKey) + 1) % 2];
  }

  @override
  void initState() {
    getAlbum();
    getColor();
    getName();
    getexistMax(maxalbum);
    getBackImage();
    checkLocked();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double height = size.height;
    double width = size.width;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: _settingmode
              ? Text("点击图片更换背景", style: TextStyle(color: Colors.white))
              : null,
          automaticallyImplyLeading: false,
          toolbarHeight:
              _namemode || _settingmode ? 0.3 * height : 0.5 * height,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: _keymode
              ? Container(
                  padding: EdgeInsets.only(top: 0.1 * height),
                  child: Center(
                      child: GestureView(
                    showUnSelectRing: false,
                    unSelectColor: Colors.white,
                    selectColor: Theme.of(context).primaryColor,
                    immediatelyClear: true,
                    size: 0.8 * width,
                    onPanUp: (List<int> items) {
                      setState(() {
                        result = items;
                        inputKey(result);
                      });
                    },
                  )),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.zero, bottom: Radius.circular(12)),
                  
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _colorKey == 'bluegrey'
                              ? [Colors.blueGrey[900], Colors.blueGrey[200]]
                              : [Colors.red[900], Colors.red[200]])))
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) {
                    getDetector(details);
                  },
                  onTap: _settingmode ? setbackImage : () {},
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.zero, bottom: Radius.circular(12)),
                        image: backimage == null
                            ? null
                            : DecorationImage(
                                image: FileImage(backimage), fit: BoxFit.cover),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _colorKey == 'bluegrey'
                                ? [Colors.blueGrey[900], Colors.blueGrey[200]]
                                : [Colors.red[900], Colors.red[200]])),
                  )),
        ),
        body: GestureDetector(
            //设置属性实现空白区域监测
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              getDetector(details);
            },
            onTap: () {
              setState(() {
                _settingmode = false;
                _keymode = false;
                unlocking = false;
              });
            },
            onVerticalDragUpdate: (details) {
              double _top = 0.0;
              _top = details.delta.dy;
              if (_top < -5.0) {
                setState(() {
                  _settingmode = true;
                  _keymode = false;
                  unlocking = false;
                });
              } else if (_top > 5.0) {
                setState(() {
                  _settingmode = false;
                });
              }
            },
            child: ConstrainedBox(
                constraints: BoxConstraints.expand(),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                          child: GestureDetector(
                        child: _namemode
                            ? Padding(
                                padding: EdgeInsets.fromLTRB(0.25 * width,
                                    0.04 * height, 0.25 * width, 0),
                                child: TextField(
                                  onChanged: (v) {
                                    setState(() {
                                      if (v != null && v != "") {
                                        setName(v);
                                      }
                                    });
                                  },
                                  onSubmitted: (v) {
                                    setState(() {
                                      if (v != null && v != "") {
                                        setName(v);
                                        getName();
                                      }
                                      _namemode = false;
                                    });
                                  },
                                  controller: _namecontroller,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.photo_album),
                                      border: OutlineInputBorder()),
                                ))
                            : Padding(
                                padding: EdgeInsets.only(top: 0.1 * height),
                                child: Text(_settingmode ? '' : albumname,
                                    style: TextStyle(fontSize: 25))),
                        onTap: _settingmode||lockmode||unlocking ? () {} : changeAlbumName,
                      )),
                      Padding(
                          padding: _namemode
                              ? EdgeInsets.all(0)
                              : EdgeInsets.only(bottom: 0.05 * height),
                          child: _settingmode
                              ? Column(children: <Widget>[
                                  Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 0.025 * height),
                                    child: widget.album == 1
                                        ? FlatButton(
                                            shape: CircleBorder(),
                                            child: Icon(Icons.color_lens,
                                                color: Colors.white, size: 30),
                                            color:
                                                Theme.of(context).primaryColor,
                                            padding:
                                                EdgeInsets.all(0.04 * width),
                                            onPressed: () {
                                              changeColor();
                                              setColor();
                                              Provider.of<AppInfoProvider>(
                                                      context,
                                                      listen: false)
                                                  .setTheme(_colorKey);
                                            })
                                        : Container(),
                                  ),
                                  Padding(
                                      padding: EdgeInsets.only(
                                          bottom: 0.025 * height),
                                      child: FlatButton(
                                        child: Icon(
                                            lockmode
                                                ? Icons.lock_open
                                                : Icons.lock_outline,
                                            size: 30,
                                            color: Colors.white),
                                        color: Colors.grey,
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.all(0.04 * width),
                                        onPressed: () {
                                          setState(() {
                                            _settingmode = false;
                                            _keymode = true;
                                            if (lockmode == true) {
                                              unlocking = true;
                                            }
                                          });
                                        },
                                      )),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 0.025 * height),
                                    child: FlatButton(
                                        shape: CircleBorder(),
                                        child: Icon(Icons.add,
                                            color: Colors.white, size: 30),
                                        color: Theme.of(context).primaryColor,
                                        padding: EdgeInsets.all(0.04 * width),
                                        onPressed: () {
                                          maxalbum = maxalbum + 1;
                                          setMaxAlbum();
                                          getexistMax(maxalbum);
                                          return Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MyHomePage(
                                                          album: maxalbum)));
                                        }),
                                  ),
                                  FlatButton(
                                      color: widget.album == 1
                                          ? Colors.grey
                                          : Colors.orange[800],
                                      shape: CircleBorder(),
                                      child: Icon(
                                          widget.album == 1
                                              ? Icons.cached
                                              : Icons.delete_forever,
                                          color: Colors.white,
                                          size: 30),
                                      padding: EdgeInsets.all(0.04 * width),
                                      onPressed: widget.album == 1
                                          ? () async {
                                              bool delete =
                                                  await showDeleteDialog1();
                                              if (delete == true) {
                                                prefs = await SharedPreferences
                                                    .getInstance();
                                                if (prefs.getInt(
                                                        '${widget.album}number') ==
                                                    null) {
                                                  prefs.setInt(
                                                      '${widget.album}number',
                                                      0);
                                                } else {
                                                  dropAlbumFile();
                                                }
                                              }
                                              setState(() {
                                                _settingmode = false;
                                              });
                                            }
                                          : () async {
                                              bool delete =
                                                  await showDeleteDialog();
                                              if (delete == true) {
                                                dropAlbum();
                                                getexistMax(maxalbum);
                                              }
                                            })
                                ])
                              : FlatButton(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    _namemode ? '确认' : '进入相册',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  color: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28)),
                                  onPressed: () {
                                    _namemode
                                        ? setState(() {
                                            _namemode = false;
                                            getName();
                                          })
                                        : checkKey();
                                  })),
                      _namemode
                          ? Container(
                              padding: EdgeInsets.fromLTRB(
                                  0, 0, 0.075 * width, 0.05 * height))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Container(
                                      padding: EdgeInsets.fromLTRB(0.1 * width,
                                          0, 0.075 * width, 0.05 * height),
                                      child: GestureDetector(
                                        child: Icon(
                                          Icons.help,
                                          color: _settingmode
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                        ),
                                        onTap: () {
                                          showHelpDialog();
                                        },
                                      )),
                                  Container(
                                      padding: EdgeInsets.fromLTRB(
                                          0.075 * width,
                                          0,
                                          0.1 * width,
                                          0.05 * height),
                                      child: GestureDetector(
                                        child: Icon(
                                          Icons.settings,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _settingmode = !_settingmode;
                                            _keymode = false;
                                            unlocking = false;
                                          });
                                        },
                                      ))
                                ])
                    ]))));
  }
}

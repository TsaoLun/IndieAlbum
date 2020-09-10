//相册页
import 'package:flutter/material.dart';
import 'package:serious_album/stackroute.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pth;
import 'stackroute.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class PickerPage extends StatefulWidget {
  @override
  PickerPage({Key key, @required this.album});
  final int album;
  _PickerPageState createState() => _PickerPageState();
}

//该State管理数据存储，图片列表，底部菜单(选择图片)
class _PickerPageState extends State<PickerPage> {
  SharedPreferences prefs;
  List<File> imagelist = [];
  bool dropmode = false;
  List<int> droplist = [];

  //从本地获得数据
  Future getPrefs() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    prefs = await SharedPreferences.getInstance();
    setState(() {
      //KEY number 对应相册照片数量
      if (prefs.getInt('${widget.album}number') == null) {
        prefs.setInt('${widget.album}number', 0);
      } else {
        int _number = prefs.get('${widget.album}number');
        //将KEY index1~N对应的本地图片文件路径添加到临时列表
        for (var i = 0; i < _number; i++) {
          print(prefs.get('${widget.album}index${i + 1}'));
          imagelist.add(File(
              pth.join(appDocPath, prefs.get('${widget.album}index${i + 1}'))));
        }
      }
      droplist = [];
    });
  }

  //删除数据
  Future dropPrefs() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getInt('${widget.album}number') == null) {
        prefs.setInt('${widget.album}number', 0);
      } else {
        int _number = prefs.get('${widget.album}number');
        int _lastnumber = _number - droplist.length;
        //整理新的index
        for (var i = 0, j = 0; i < _number; i++) {
          if (droplist.contains(i + 1)) {
            File(pth.join(
                    appDocPath, prefs.get('${widget.album}index${i + 1}')))
                .delete();
          } else {
            prefs.setString('${widget.album}index${j + 1}',
                prefs.get('${widget.album}index${i + 1}'));
            j++;
          }
        }
        //删除多余的index
        for (var i = _lastnumber; i < _number; i++) {
          prefs.remove('${widget.album}index${i + 1}');
        }
        prefs.setInt('${widget.album}number', _number - droplist.length);
      }
    });
  }

  void dropImage() {
    dropPrefs();
    dropmode = false;
    imagelist = [];
    getPrefs();
  }

  //从相册获取图片保存至应用目录
  Future getImage() async {
    //给待处理图片编号(已有编号+1)，创建目标存储文件
    int _number = prefs.getInt('${widget.album}number') + 1;

    List<Asset> resultList;
    //选择相册图片读取为字节并解码为image，写入目标存储文件中
    resultList = await MultiImagePicker.pickImages(
      cupertinoOptions: CupertinoOptions(),
      maxImages: 61 - _number,
    );

    if (resultList != null) {
      prefs.setInt('${widget.album}number', _number + resultList.length - 1);
      resultList.forEach((element) async {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        await element.getByteData().then((e) {
          File(pth.join(appDocDir.path,
                  '${widget.album}index${_number}i${DateTime.now().second.toString()}.jpg'))
              .writeAsBytes(e.buffer.asUint8List());
        });
        //储存图片编号,位置,number并刷新
        setState(() {
          imagelist.add(File(pth.join(appDocDir.path,
              '${widget.album}index${_number}i${DateTime.now().second.toString()}.jpg')));
          prefs.setString('${widget.album}index$_number',
              '${widget.album}index${_number}i${DateTime.now().second.toString()}.jpg');
          _number = _number + 1;
        });
      });
    }
  }

  //将图片从应用目录保存到相册
  void _saveImage(File file, String name) async {
    final bytes = await file.readAsBytes();
    final result = await ImageGallerySaver.saveImage(bytes.buffer.asUint8List(),
        quality: 100, name: name);
    print('result:$result');
  }

  @override
  void initState() {
    if (imagelist.isEmpty) {
      getPrefs();
    }
    super.initState();
  }

  //界面(底部菜单)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //浏览页由Stack构建，传入imagelist
      body: StackRoute(
          imagelist: imagelist,
          dropmode: dropmode,
          droplist: droplist,
          album: widget.album),
      bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          child: Row(
            children: [
              IconButton(
                  icon: dropmode
                      ? Icon(Icons.save, size: 34, color: Colors.blueGrey[300])
                      : Icon(Icons.insert_photo,
                          size: 30, color: Colors.blueGrey[300]),
                  onPressed: () => dropmode
                      ? setState(() {
                          droplist.forEach((element) {
                            _saveImage(imagelist[element - 1],
                                '${widget.album.toString()}album$element');
                          });
                          dropmode = false;
                          droplist = [];
                        })
                      : () {}),
              SizedBox(),
              IconButton(
                icon: dropmode
                    ? Icon(Icons.check_box,
                        size: 34, color: Colors.blueGrey[300])
                    : Icon(Icons.check_box,
                        size: 28, color: Colors.blueGrey[300]),
                onPressed: () => setState(() {
                  dropmode = !dropmode;
                  droplist = [];
                }),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceAround,
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: dropmode ? Colors.orange[800] : Colors.blueGrey,
        onPressed: dropmode ? dropImage : getImage,
        tooltip: 'Pick Image',
        child: dropmode
            ? Icon(Icons.delete_forever, size: 30)
            : Icon(Icons.add_photo_alternate),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
    );
  }
}

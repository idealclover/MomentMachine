import 'package:dio/dio.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/DrawerComponent.dart';
import '../Components/CommentComponent.dart';
import './SettingPage.dart';
import './EditPage.dart';

class SendCrossPage extends StatefulWidget {
  SendCrossPage() : super();

  final String title = 'Moment Machine';

  @override
  _SendCrossPageState createState() => _SendCrossPageState();
}

class _SendCrossPageState extends State<SendCrossPage> {
  final TextEditingController _textController = new TextEditingController();
  List<CommentComponent> _comments = <CommentComponent>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Null> _loadData() async {
    String url, cid, username, password;
    List<String> strList = ['url', 'cid', 'username', 'password'];
    Future<Map> rst = _get(strList);
    rst.then((Map rstList) {
      if (rstList[strList[0]] == null)
        url = '';
      else
        url = rstList[strList[0]] + '/action/xmlrpc';
      cid = rstList[strList[1]];
      username = rstList[strList[2]];
      password = rstList[strList[3]];
      xml_rpc.call(url, 'wp.getComments', [
        1,
        username,
        password,
        {
          'post_id': int.parse(cid),
          'number': 20,
        }
      ]).then((result) {
        print(result.toString());
        for (var comment in result) {
          Map map = {
            'author': comment['author'],
            'time': comment['date_created_gmt'],
            'data': comment['content'],
          };
          CommentComponent component =
          new CommentComponent(name: map['author'], text: map['data']);
          _comments.add(component);
        }
        setState(() {
          _comments = _comments;
        });
      }).catchError((error) => print(error));
    });
  }

  Future<Null> _refresh() async {
    _comments.clear();
    await _loadData();
    return;
  }

  Future<Map> _get(List<String> strList) async {
    Map rst = new Map();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (String str in strList) {
      rst[str] = prefs.getString(str);
    }
    return rst;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        drawer: Drawer(
          child: DrawerComponent(),
        ),
        body: Builder(builder: (BuildContext context) {
          send() async {
            String url, cid, username, password;
            List<String> strList = ['url', 'cid', 'username', 'password'];
            Future<Map> rst = _get(strList);
            rst.then((Map rstList) {
              if (rstList[strList[0]] == null)
                url = '';
              else
                url = rstList[strList[0]] + '/action/xmlrpc';
              cid = rstList[strList[1]];
              username = rstList[strList[2]];
              password = rstList[strList[3]];
              xml_rpc.call(url, 'wp.newComment', [
                1,
                username,
                password,
                int.parse(cid),
                {
                  'author': 'clover',
                  'author_email': 'idealclover@163.com',
                  'author_url': 'https://idealclover.top',
                  'content': _textController.value.text.toString(),
                }
              ]).then((result) {
                print(result.toString());
                _textController.clear();
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("发送成功")));
                _refresh();
              }).catchError((error) => print(error));
            });
          }

          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(children: <Widget>[
                Flexible(
                    child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemBuilder: (_, int index) => _comments[index],
                          itemCount: _comments.length,
                        ))),
                Row(children: <Widget>[
                  Flexible(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration.collapsed(
                            hintText: "说点什么吧"),
                        onTap:()=> Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => EditPage())),
                      )),
                  Container(
                      margin: new EdgeInsets.symmetric(horizontal: 4.0),
                      child: new IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () => send(),
                      ))
                ])
              ]));
        }));
  }
}

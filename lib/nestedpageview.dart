library nestedpageview;

import 'package:flutter/material.dart';
import 'package:nestedpageview/extend_nested_page_view.dart';
import 'package:nestedpageview/nested_page_view.dart';

///测试例子
class Test1 extends StatefulWidget {

  const Test1({Key key}) : super(key: key);

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test1> {

  final NestedPageViewCoordinator coordinator = NestedPageViewCoordinator();

  @override
  Widget build(BuildContext context) {
    return NestedPageView(
      children: <Widget>[
        NestedPageView(
          children: <Widget>[
            Container(
              color: Colors.yellow,
            ),
            Container(
              color: Colors.blue,
            ),
            Container(
              color: Colors.orange,
            ),
          ],
        ),
        NestedPageView(
          children: <Widget>[
            Container(
              color: Colors.black,
            ),
            Container(
              color: Colors.red,
            ),
            Container(
              color: Colors.brown,
            ),
          ],
        )
      ],
    );
  }
}

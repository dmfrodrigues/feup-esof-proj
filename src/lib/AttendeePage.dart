import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';
import 'package:com_4_all/database/Database.dart';
import 'package:com_4_all/database/DatabaseFirebase.dart';
import 'package:com_4_all/messaging/Messaging.dart';
import 'package:com_4_all/messaging/MessagingFirebase.dart';


class AttendeePage extends StatefulWidget {
  AttendeePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _AttendeePageState createState() => _AttendeePageState();
}

class _AttendeePageState extends State<AttendeePage> {
  TextField questionMessage;
  TextFormField sessionIDForm;
  var questionMessageController = new TextEditingController();
  var sessionIDController = new TextEditingController();
  List<DropdownMenuItem> languagesDropDownList = new List();
  String receivedText = "";
  int index = 0;
  List<dynamic> sentList = new List();
  double splitWeight = 0.7;

  Messaging messaging;

  Database database = new DatabaseFirebase();
  String sessionID = "";
  String localToken;
  String talkTitle = "";
  ScrollController transcriptScrollController =
  new ScrollController(initialScrollOffset: 50.0);
  ScrollController messagesScrollController =
  new ScrollController(initialScrollOffset: 50.0);

  Text receivedTextField() {
    return Text(
      receivedText,
      textAlign: TextAlign.left,
    );
  }

  SingleChildScrollView scrollView = SingleChildScrollView(
    scrollDirection: Axis.vertical, //.horizontal
    child: Text(""),
  );

  void getMessage(dynamic r) {
    print("received: "+r['message'].toString());
    String message = r['message'];
    if (receivedText.length > 0) message = " " + message;
    else{
      message = "${message[0].toUpperCase()}${message.substring(1)}";
    }
    setState(() {
      receivedText += message;
    });
    transcriptScrollController.animateTo(
        transcriptScrollController.position.maxScrollExtent.ceilToDouble() +
            receivedText.length,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease);
  }

  Future setupMessaging() async {
    messaging = new MessagingFirebase(getMessage);
    localToken = await messaging.getToken();
  }

  @override
  void initState() {
    super.initState();
    setupMessaging();

    questionMessage = TextField(
      controller: questionMessageController,
      decoration: InputDecoration(
        hintText: "Enter a Question to ask",
      ),
      expands: false,
      maxLines: 5,
      minLines: 1,
    );
    sessionIDForm = TextFormField(
      controller: sessionIDController,
      decoration: InputDecoration(
        labelText: "Enter the session ID",
      ),
      expands: false,
      maxLines: 1,
      minLines: 1,
    );
  }

  Future checkSession() async {
    sessionID = sessionIDController.text;
    if (sessionID != "") {
      database.subscribeTalk(sessionID, localToken).then((status) async {
        String talkTitleTmp = await database.getTalkTitle(sessionID);
        setState(() {
          index = 1;
          talkTitle = talkTitleTmp;
        });
      }).catchError((error) {
        showDialog(
          context: context,
          builder: (_) => new AlertDialog(
            title: new Text("No such talk ID"),
            content: new Text("There is no registered talk with that ID."),
          ),
        );
      }, test: (e) => e is NoSuchTalkException);
    } else {
      setState(() {
        sessionIDController.clear();
        sessionIDForm = TextFormField(
          controller: sessionIDController,
          decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: "Enter the session ID",
              errorText: "Not a valid session ID"),
          expands: false,
          maxLines: 1,
          minLines: 1,
        );
      });
    }
  }

  void sendMessage() async {
    messaging.sendMessage(
        await database.getToken(sessionID), questionMessageController.text);
    setState(() {
      var now = new DateTime.now();
      var time = now.hour.toString()+":"+now.toLocal().toString().substring(14,16);
      sentList.add({"message": questionMessageController.text,"timestamp": time});
      messagesScrollController.animateTo(
          messagesScrollController.position.maxScrollExtent.ceilToDouble() +
              questionMessageController.text.length * 100,
          duration: Duration(milliseconds: 500),
          curve: Curves.ease);
      questionMessageController.clear();
    });
  }

  AppBar getAppBar() {
    return AppBar(
      leading: GestureDetector(
        onTap: () {
          database.unsubscribeTalk(sessionID, localToken);
          setState(() {
            index = 0;
          });
        },
        child: Icon(Icons.exit_to_app),
      ),
      title: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Chat",
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              talkTitle,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  AppBar getAppBarSession() {
    return AppBar(
      title: Text(widget.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    scrollView = SingleChildScrollView(
      controller: transcriptScrollController,
      scrollDirection: Axis.vertical, //.horizontal
      child: receivedTextField(),
    );
    return Scaffold(
      appBar: (index != 0 ? getAppBar() : getAppBarSession()),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return new Stack(
            children: <Widget>[
              new Offstage(
                offstage: index != 0,
                child: new TickerMode(
                  enabled: index == 0,
                  child: new Scaffold(
                      body: new Center(
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              child: sessionIDForm,
                              width: 150,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            FlatButton(
                              minWidth: 150,
                              disabledTextColor: Colors.white,
                              disabledColor: Colors.white,
                              color: Colors.blue,
                              child: Text("Enter the Session"),
                              onPressed: checkSession,
                            ),
                          ],
                        ),
                      )),
                ),
              ),
              new Offstage(
                offstage: index != 1,
                child: new TickerMode(
                  enabled: index == 1,
                  child: new Scaffold(
                    body: Column(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight,
                              maxWidth: constraints.maxWidth,
                            ),
                            child: SplitView(
                              initialWeight: splitWeight,
                              view1: Container(
                                padding:
                                EdgeInsets.all(16.0),
                                child: scrollView,
                              ),
                              view2: ListView.builder(
                                  controller: messagesScrollController,
                                  itemCount: sentList.length,
                                  itemBuilder: (BuildContext context, int idx) {
                                    return Column(
                                      children: [
                                        Row(
                                            children: [
                                              Expanded(
                                                child: Text('John Doe',textAlign: TextAlign.right),
                                              ),
                                              SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: const Icon(Icons.account_circle_rounded)),
                                            ]
                                        ),
                                        Container(
                                          padding: EdgeInsets.fromLTRB(2.0, 0.2, 0.2, 0.2),
                                          child: Text(sentList[idx]['timestamp'],
                                              textAlign: TextAlign.right,
                                              style: DefaultTextStyle.of(context)
                                                  .style
                                                  .apply(fontSizeFactor: 0.8)),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 10.0, right: 10.0, bottom: 5.0),
                                          padding: EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
                                          decoration: new BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius: new BorderRadius.only(
                                                  topLeft: const Radius.circular(30.0),
                                                  topRight: const Radius.circular(30.0),
                                                  bottomLeft: const Radius.circular(30.0),
                                                  bottomRight: const Radius.circular(30.0))),
                                          child: Row(children: [
                                            Expanded(
                                              child: Text(sentList[idx]['message'],
                                                  textAlign: TextAlign.left,
                                                  style: DefaultTextStyle.of(context)
                                                      .style
                                                      .apply(fontSizeFactor: 1.2)),
                                            ),
                                          ]),
                                        )
                                      ],
                                    );
                                  }
                              ),
                              viewMode: SplitViewMode.Vertical,
                              onWeightChanged: (w) => splitWeight = w,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.fromLTRB(5.0, 0, 5.0, 0),
                                decoration: new BoxDecoration(
                                  color: Colors.black12,
                                ),
                                child: questionMessage,
                              ),
                            ),
                            IconButton(
                              color: Colors.black,
                              splashColor: Colors.blue,
                              icon: Icon(Icons.send),
                              onPressed: sendMessage,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
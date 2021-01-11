import 'dart:convert';

import 'package:call1friend/firebase_topic_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jokrey_utilities/jokrey_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  var notifications = FirebaseTopicSubscribeHelper()
    ..init();

  BuildContext withinSafeAreaContext = null;
  _MyAppState() {
    notifications.addMessageCallback((title, body) =>
      Scaffold.of(withinSafeAreaContext)
      ..removeCurrentSnackBar()
      ..showSnackBar(
          SnackBar(
              content: Text(body),
              duration: Duration(seconds: 10)
          )
      )
    );
  }

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _enterProtocol = TextEditingController()..text = "https";
  final _enterHost = TextEditingController();
  final _enterPort = TextEditingController();
  final _enterRoomName = TextEditingController();
  final _enterOwnName = TextEditingController();
  final _enterFriendName = TextEditingController();

  _attemptConnect() async {
    if(notifications.isSubscribed()) {
      //TODO - the following cannot work without api key - technically this would require another server
      var response = await http.post(
        'https://fcm.googleapis.com/fcm/send',
        headers: {
          'AUTHORIZATION': 'key=<API_ACCESS_KEY>',
          'Content-Type': 'application/json',
        },
        body:
          '{\"message\": '+
            '{\"topic\": '+notifications.currentTopic+','+
              '\"notification\": {'+
                '\"title\": \"Your Friend Joined\",'+
                '\"body\": \"Background message body\"'+
              '}'+
            '}'+
          '}',
      );
      print('notification response: '+response.toString());
  }

    var initialConnectSuccessful = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) {
              return VCall1to1Widget(
                call: VCall1to1(_enterOwnName.text, _enterFriendName.text,
                    RoomSignalerImpl(
                        _enterRoomName.text, _enterOwnName.text,
                        _enterProtocol.text != 'http',
                        _enterHost.text, int.parse(_enterPort.text)
                    )
                ),
              );
            }
        )
    );

    if(!initialConnectSuccessful) {
      Scaffold.of(withinSafeAreaContext)
        ..removeCurrentSnackBar()
        ..showSnackBar(
            SnackBar(
                content: Text("Could not connect to signaling server"),
                duration: Duration(seconds: 25)
            )
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call1Friend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: SafeArea( child: Builder(
          builder: (context) {
            withinSafeAreaContext = context;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Text("Enter server: ", textScaleFactor: 1.1),
                    Flexible(
                      flex: 15,
                      child: TextField(
                        controller: _enterProtocol,
                        textAlign: TextAlign.right,
                        enabled: false,
                        decoration: InputDecoration(hintText: 'http/https'),
                      ),
                    ),
                    Text("://"),
                    Flexible(
                      flex: 60,
                      child: TextField(
                        controller: _enterHost,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(hintText: 'address'),
                      ),
                    ),
                    Text(":"),
                    Flexible(
                      flex: 25,
                      child: TextField(
                        controller: _enterPort,
                        decoration: InputDecoration(hintText: 'port'),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ],
                ),
                WidthFillingTextButton("Configure Ice Servers ("+iceServers['iceServers'].length.toString()+")",
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder:
                        (context) => IceServersConfigurationWidget()
                    ));
                    setState(() {}); //rebuild to rebuild ice server count in text field above
                  }
                ),
                Row(
                  children: [
                    Flexible(flex: 70, child: TextField(
                      controller: _enterRoomName,
                      decoration: InputDecoration(
                        labelText: "Room",
                        hintText: 'Enter server \'room\''
                      ),
                    ),),
                    Flexible(flex: 30, child: Row(children: [
                      Flexible(flex: 70, child: RaisedButton(
                        child: Text(notifications.isSubscribed()?"Stop\nNotify":"Notify\nMe"),
                        onPressed: () async {
                          if(!notifications.isSubscribed()) {
                            var subscription = _enterHost.text + "-" +
                                _enterRoomName.text;
                            notifications.subscribeTo(subscription)
                                .then((value) => setState(() {}));
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Subscribed"),
                                  content: Text("You will now receive notifications if someone enters:\n" +
                                      _enterRoomName.text + " at "+_enterHost.text),
                                )
                            );
                          } else {
                            notifications.unsubscribeFromCurrent()
                                .then((value) => setState(() {}));
                          }
                        },
                        color: DEFAULT_BUTTON_BG_COLOR,
                        textColor: Colors.white,
                      )),
                      Flexible(flex: 30, child: RaisedButton(
                        child: Text("?"),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Firebase Call Notification"),
                                content: Text("The button allows you to be notified when your friend enters the room.\n"
                                    "You will only be notified if your friend has also pressed that button.\n"
                                    "If you share this room with multiple friends, they will all be notified.\n"
                                    "However you can only talk to 1."),
                              )
                          );
                        },
                        color: DEFAULT_BUTTON_BG_COLOR,
                        textColor: Colors.white,
                      )),
                    ]),),
                  ],
                ),
                TextField(
                  controller: _enterOwnName,
                  decoration: InputDecoration(
                    labelText: "Name",
                    hintText: 'Enter your name'
                  ),
                ),
                TextField(
                  controller: _enterFriendName,
                  decoration: InputDecoration(
                    labelText: "Friend's Name",
                    hintText: 'Enter your friend\'s name'
                  ),
                ),
                WidthFillingTextButton("Connect",
                  onPressed: () => _attemptConnect()
                ),
              ],
            );
          }
        ))
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _restoreEnteredData();
    WidgetsBinding.instance.addObserver(this);

    //this is how you would add certificates:
    // addCertificateFromAssets("self_signed_certificates/jokrey-manj-lap.fritz.box_cert.pem");
    // addCertificateFromAssets("self_signed_certificates/localhost_chrome_cert.pem");
  }
  _restoreEnteredData() {
    _prefs.then((prefs) {
      setState(() {
        restoreIfPossible(prefs, _enterProtocol,    "_enterProtocol");
        restoreIfPossible(prefs, _enterHost,        "_enterHost");
        restoreIfPossible(prefs, _enterPort,        "_enterPort");
        restoreIfPossible(prefs, _enterRoomName,    "_enterRoomName");
        restoreIfPossible(prefs, _enterOwnName,     "_enterOwnName");
        restoreIfPossible(prefs, _enterFriendName,  "_enterFriendName");
        if(prefs.containsKey("iceServers")) {
          iceServers['iceServers'] = jsonDecode(prefs.getString("iceServers"));
        } else {
          iceServers['iceServers'] = [
            {'url': 'stun:stun.l.google.com:19302'},
            // {
            //   'url': 'turn:classified.net:classified',
            //   'username': 'classified',
            //   'credential': 'classified'
            // },
          ];
        }
      });
    });
  }
  void restoreIfPossible(
      SharedPreferences prefs, TextEditingController textController, String k) {
    if(prefs.containsKey(k)) textController.text = prefs.getString(k);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _saveEnteredData();
    }
  }
  _saveEnteredData() {
    _prefs.then((prefs) {
      prefs.setString("_enterProtocol",   _enterProtocol.text);
      prefs.setString("_enterHost",       _enterHost.text);
      prefs.setString("_enterPort",       _enterPort.text);
      prefs.setString("_enterRoomName",   _enterRoomName.text);
      prefs.setString("_enterOwnName",    _enterOwnName.text);
      prefs.setString("_enterFriendName", _enterFriendName.text);
      prefs.setString("iceServers", jsonEncode(iceServers['iceServers']));
    });
  }
}



class IceServersConfigurationWidget extends StatefulWidget {
  @override
  _IceServersConfigurationWidgetState createState() => _IceServersConfigurationWidgetState();
}

class _IceServersConfigurationWidgetState extends State<IceServersConfigurationWidget> {
  final serverConfigurators = List<IceServerConfigurationWidget>();
  _IceServersConfigurationWidgetState() {
    print(iceServers);
    print(iceServers['iceServers']);
    for(var iceS in iceServers['iceServers']) {
      var url = iceS['url'];
      var username = iceS['username'] ?? "";
      var credential = iceS['credential'] ?? "";
      if(url != null) {
        serverConfigurators.add(IceServerConfigurationWidget(url, username, credential));
      }
    }
  }

  _applyChangesAndPop() {
    var jsonListOfIceServers = List<dynamic>();
    for(var iceConfigW in serverConfigurators) {
      String url = iceConfigW.urlC.text;
      if(iceConfigW.representsTurnServer) {
        jsonListOfIceServers.add(
            {
              'url': url.startsWith('turn:') ? url : 'turn:' + url,
              'username': iceConfigW.turnUsernameC.text,
              'credential': iceConfigW.turnCredentialC.text
            }
        );
      } else {
        jsonListOfIceServers.add(
            {
              'url': url.startsWith('stun:') ? url : 'stun:' + url
            }
        );
      }
    }
    iceServers['iceServers'] = jsonListOfIceServers;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: serverConfigurators.map((e) {
                return Card(child: Column(
                  children: [
                    Text(
                      "Ice Server: ",
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    e,
                    WidthFillingTextButton("Remove", bg: Color(0xffA71D31),
                      onPressed: () => setState((){
                        serverConfigurators.remove(e);
                      })
                    ),
                  ],
                ));
              }).toList(),
            ),
          ),
          WidthFillingTextButton("Add Ice Server", bg: Color(0xffA71D31),
            onPressed: () => setState(() {
              serverConfigurators.add(IceServerConfigurationWidget("", "", ""));
            })
          ),
          WidthFillingTextButton("Apply Changes",
            onPressed: _applyChangesAndPop,
          ),
        ],
      ))
    );
  }
}

const DEFAULT_BUTTON_BG_COLOR = Color(0xff5000e6);

class WidthFillingTextButton extends SizedBox {
  WidthFillingTextButton(String text,
        {VoidCallback onPressed, Color bg=DEFAULT_BUTTON_BG_COLOR}) :
    super(width: double.infinity, // match_parent
      child: RaisedButton(
        child: Text(text),
        onPressed: onPressed,
        color: bg,
        textColor: Colors.white,
      ));
}

//stun or turn
class IceServerConfigurationWidget extends StatefulWidget {
  final urlC = TextEditingController();
  final turnUsernameC = TextEditingController();
  final turnCredentialC = TextEditingController();


  bool get representsTurnServer =>
      turnUsernameC.text.isNotEmpty && turnCredentialC.text.isNotEmpty;

  IceServerConfigurationWidget(String url, username, credential) {
    urlC.text = url;
    turnUsernameC.text = username;
    turnCredentialC.text = credential;
  }

  @override
  _IceServerConfigurationWidgetState createState() => _IceServerConfigurationWidgetState();
}
class _IceServerConfigurationWidgetState extends State<IceServerConfigurationWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.urlC,
          decoration: InputDecoration(
              labelText: "URL (Stun/Turn)", hintText: "enter a url"
          )
        ),
        TextField(
          controller: widget.turnUsernameC,
          decoration: InputDecoration(
              labelText: "Username (Turn only)", hintText: "enter the username or leave it blank"
          )
        ),
        TextField(
          controller: widget.turnCredentialC,
          decoration: InputDecoration(
              labelText: "Credential (Turn only)", hintText: "enter the credential or leave it blank"
          )
        )
      ],
    );
  }
}

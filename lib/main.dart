import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jokrey_utilities/jokrey_utilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _enterIceServers = IceServersConfigurationController()
    ..iceServers = defaultIceServers;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _enterBaseUrl = TextEditingController();
  final _enterRoomName = TextEditingController();
  final _enterOwnName = TextEditingController();
  final _enterFriendName = TextEditingController();

  _attemptConnect(BuildContext context) async {
    var initialConnectSuccessful = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return VCall1to1Widget(
            call: VCall1to1(_enterOwnName.text, _enterFriendName.text,
              RoomSignalerImpl(
                _enterRoomName.text,
                _enterOwnName.text,
                _enterBaseUrl.text,
              ),
              _enterIceServers.iceServers,
            ),
          );
        }
      )
    );

    if(!initialConnectSuccessful) {
      Scaffold.of(context)
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
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _enterBaseUrl,
                decoration: InputDecoration(
                  labelText: "Signaling URL (using wsclientable)",
                  hintText:
                  'Enter base server url {ex: http(s)://dns(:port)/route}',
                ),
              ),
              WidthFillingTextButton(
                "Configure Ice Servers(${_enterIceServers.iceServers.length})",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          IceServersConfigurationWidget(_enterIceServers),
                    ),
                  );
                  setState(() {}); //rebuild ice server count in text above
                }
              ),
              TextField(
                controller: _enterRoomName,
                decoration: InputDecoration(
                  labelText: "Room",
                  hintText: 'Enter server \'room\''
                ),
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
                onPressed: () => _attemptConnect(context)
              ),
            ],
          )
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
        restoreIfPossible(prefs, _enterBaseUrl,    "_enterBaseUrl");
        restoreIfPossible(prefs, _enterRoomName,    "_enterRoomName");
        restoreIfPossible(prefs, _enterOwnName,     "_enterOwnName");
        restoreIfPossible(prefs, _enterFriendName,  "_enterFriendName");
        if(prefs.containsKey("iceServers")) {
          _enterIceServers.iceServers = [];
          for (var decoded in jsonDecode(prefs.getString("iceServers"))) {
            _enterIceServers.iceServers += [
              (decoded as Map<String, dynamic>).cast<String, String>()
            ];
          }
        } else {
          _enterIceServers.iceServers = defaultIceServers;
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
      prefs.setString("_enterBaseUrl",   _enterBaseUrl.text);
      prefs.setString("_enterRoomName",   _enterRoomName.text);
      prefs.setString("_enterOwnName",    _enterOwnName.text);
      prefs.setString("_enterFriendName", _enterFriendName.text);
      prefs.setString("iceServers", jsonEncode(_enterIceServers.iceServers));
    });
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
      )
    );
}
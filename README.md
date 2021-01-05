# Call1Friend

This is a flutter application capable of connecting you to 1 friend via a WebRTC video call.

Does NOT provide a 'calling' feature (with a notification or something similar).

This application should be seen as an example of how to utilize the signaling environment build upon webrtc in the github.com/jokrey/utility-algorithms-flutter repository (and not a app of type 'product').

## Getting Started

To use this app you need access to a 'wsclientable' server as defined in the github.com/jokrey/utility-algorithms-flutter repository. A simple instance which is defined in example_mains/ is sufficient.
Both participants also need to know a room(shared secret) and each others names.
Additionally a turn server might be required (to setup your own very simply refer to 'coturn').


## Based on code in:

- github.com/flutter-webrtc/flutter-webrtc
- github.com/jokrey/utility-algorithms-flutter
- github.com/jokrey/utility-algorithms-golang

## App Version

This app will soon be available as an app version in common places (once it has matured past the likely initial kinks).

If you'd like an App Store version please let me know and also I'll need some money in that case. On the upside I may give you access to a turn server in return.
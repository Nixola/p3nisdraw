## UI
* menu:
* * Top-left red "disconnected" indicator

* game:
* * Top-left latency counter; if too high ?, be red
* * Tilde opens a messagebox on bottom showing logs and providing not-printed chat
* * On crash/disconnect, return to connect screen; blur/grey the canvas and put it on background
* * ~~Holding right-click displays a color picker, releasing chooses a colour;~~ might want to toggle instead of hold


## Small roadmap
* Add support to brushes (Branched):
* * Clients send a png and possibly data for every brush
* * Server renders the png and caches the data, along with the provided name
* * If server receives a brush with the same name it compares it to the cached one:
* * * If it's equal it accepts it
* * * If it's not equal it assigns a new name, relaying it to the client which sent it.
* * Clients receive a list of brushes on connect, plus every brush that's been sent to the server;
* * Possibly allow clients to paint with remote brushes, when provided by the server or one of the client

* Reduce unnecessary data exchange:
* * Text objects should only send an update when moved and/or edited
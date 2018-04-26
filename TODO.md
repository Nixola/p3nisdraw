## UI
* connection screen:
* * ~~Textbox asking for nick~~
* * ~~Textbox asking for address~~
* * Top-right red "disconnected" indicator

* game:
* * Top-right latency counter; if too high, be red
* * If tab is held shows a list of nicks+latencies
* * ~~Enter opens a cursor-position textbox to write commands and print text~~
* * Escape removes any open textbox, sends an empty text and then deletes it
* * Tilde opens a messagebox on bottom showing logs and providing not-printed chat
* * On crash/disconnect, return to connect screen; blur/grey the canvas and put it on background
* * ~~Holding right-click displays a color picker, releasing chooses a colour;~~ might want to toggle instead of hold
* * ~~Add brushes~~
* * Include actual size and stepping information on brushes, maybe random/sequential rotation as well? might be cool
* * Make brushes scale on client
* * Make brushes scale on server

## makebrush
* rework cli arguments; png file is mandatory, everything else is ``--option value``
* make tool check/convert png file automatically
* have it prompt for missing info
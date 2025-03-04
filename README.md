# Symantec Endpoint Protection and Eset Endpoint Security

* 1.Code->Download Zip
* 2.Unpack
* 3.Install
* These port blocks are only recommended for browsing the Internet in a web browser, 
* if you want to play other games, you need to adjust the port blocks accordingly, 
* there is an added config related to the game Counter-Strike 2 where you can play freely, 
* if you want to play something else online, use the eset.xml rule or create your own for a given game. 
* Rules related to port blocking can be found in the settings of the Symantec or Eset program, 
* I recommend using eset because it is a better application when it comes to importing or exporting program settings, 
* including the firewall that is built into the program.

* These are rules only for browsing the Internet in a web browser:

* Block Port Localhost UP/DOWN - TCP:
```bash
0-65535
```
* Block Port Remote UP/DOWN - TCP:
```bash
0-79,81-442,444-65535
```
* Block Port Localhost UP/DOWN - UDP:
```bash
0-65535
```
* Block Port Remote UP/DOWN - UDP:
```bash
0-52,54-65535
```
* Incomming Block - All

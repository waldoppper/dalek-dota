# dalek-dota
                    Exterminate!
                   /
              ___
      D>=G==='   '.
           |======|
           |======|
       )--/]IIIIII]
           |_______|
           C O O O D
          C O  O  O D
         C  O  O  O  D
         C__O__O__O__D
        [_____________]

---
# Dev Quick Start
1. Locate your DotA2 install on disk
2. Place the contents of this repository into ..game\dota\scripts\vscripts\bots
3. Modify your DotA2 launcher to include `-console`. (for debugging)
4. Start DotA2
5. Host a local game
  1. Click "Play DotA"
  2. Click "Create Lobby"
  3. Edit Settings
    1. Radiant Bots -> Local Dev Script
    2. Dire Bots -> Local Dev Script
  4. Click "Start Game"
5. Observe results
5. Modify lua scripts, saving them to disk
6. Open the console and type: `dota_bot_reload_scripts`
7. Iterate from step 5

# Helpful Links
* [Scripting in DotA 2](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting)
* [Dota Bot Scripting](https://developer.valvesoftware.com/wiki/Dota_Bot_Scripting)
* [API Details - 3rd party, since valves are so bad](http://docs.moddota.com/lua_bots/)
* [Learn Lua](https://learnxinyminutes.com/docs/lua/)
* [Sharing State](http://dev.dota2.com/showthread.php?t=275238)
* [StateMachine usage for bot Think() override](https://github.com/lenLRX/dota2Bots/blob/master/bot_lina.lua)


# Known Issues
* Electing to play on Dire seems to cause half the bots to not pick and for most of them to be naked
* Using GetUnitToUnitDistance() as a way to measure ability to use physical attack based on published attack range numbers is not sufficient. Alchemist seems to be able to attack from a range of 187.3, rather than 150, which is his declared attack range. See [dev forum pos](http://dev.dota2.com/showthread.php?t=275597t)
* No way to upgrade the new special tree skills

# Tips
* To speed up time in your game, open console and type:
    1. `sv_cheats 1`
    2. `host_timescale <float>`
* To reload scripts mid-match, open the console and type: `dota_bot_reload_scripts`

# Bot Status

##Alchemist
Learning to last hit while not dying to creeps. Very good progress using the State Machine model authored 
by [lenRX](https://github.com/lenLRX/dota2Bots/blob/master/bot_lina.lua).

**TODO**
* Secret Shop Purchasing
* Skill Usage
* Item Usage
* HAM state

**BUGS**
* creep HP status via environment.lua needs some love. regression over last 3 seconds isnt good enough to determine future HP
* bot won't return the crow when he's done with it
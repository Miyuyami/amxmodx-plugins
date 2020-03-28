#### amx_transfer
Simple transfer plugin that allows you to change a player team, swap players and swap the whole team.

Multiple of this kind of plugin already exists, this was made to specifically not allow moving to the spectator as a workaround to combat a Counter-Strike 1.6 bug that crashes the server.

Commands:
* amx_t <player> - move player to the Terrorists
* amx_ct <player> - move player to the Counter-Terrorists
* amx_spec <player> - move player to Spectators
* amx_team <player> <T|CT|SPEC/1|2|3> - move player to a given team
* amx_swap <player1> <player2> - swap the teams of 2 given players
* amx_teamswap - swaps the Terrorists and Counter-Terrorists with each other
* say /teamswap - same as amx_teamswap

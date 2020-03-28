#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <fakemeta_util>

const targetFlags = CMDTARGET_ALLOW_SELF;
const targetFlags2 = CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE; // use ONLY ALIVE as a workaround for a cs 1.6 bug that can crash the server

public plugin_init() 
{
	register_plugin("AMX Transfer", "1.0", "X")
	
	register_concmd("amx_t", "cmd_teamt", ADMIN_LEVEL_A, "<name>")
	register_concmd("amx_ct", "cmd_teamct", ADMIN_LEVEL_A, "<name>")
	register_concmd("amx_spec", "cmd_teamspec", ADMIN_LEVEL_A, "<name>")
	register_concmd("amx_team", "cmd_transfer", ADMIN_LEVEL_A, "<name> <T|CT|Spec>")
	register_concmd("amx_swap", "cmd_swap", ADMIN_LEVEL_A, "<name> <name>")
	register_concmd("amx_teamswap", "cmd_teamswap", ADMIN_RCON, "Swaps two teams with eachother")
	register_clcmd("say /teamswap", "cmd_teamswap", ADMIN_RCON, "Swaps two teams with eachother")
}

// cmd handles
public cmd_teamt(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;
	
	new username[33];
	read_argv(1, username, 32);
	new target = cmd_target(id, username, targetFlags);
	if (!target)
		return PLUGIN_HANDLED;
	
	if (TryTransferInternal(id, target, CS_TEAM_T))
	{
		PrintPlayerTransfer(id, target, CS_TEAM_T);
	}
	
	return PLUGIN_HANDLED;
}

public cmd_teamct(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;
	
	new username[33];
	read_argv(1, username, 32);
	new target = cmd_target(id, username, targetFlags);
	if (!target)
		return PLUGIN_HANDLED;
	
	if (TryTransferInternal(id, target, CS_TEAM_CT))
	{
		PrintPlayerTransfer(id, target, CS_TEAM_CT);
	}
	
	return PLUGIN_HANDLED;
}

public cmd_teamspec(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;
	
	new username[33];
	read_argv(1, username, 32);
	new target = cmd_target(id, username, targetFlags2);
	if (!target)
		return PLUGIN_HANDLED;
	
	if (TryTransferInternal(id, target, CS_TEAM_SPECTATOR))
	{
		PrintPlayerTransfer(id, target, CS_TEAM_SPECTATOR);
	}
	
	return PLUGIN_HANDLED;
}

public cmd_transfer(id, level, cid)
{	
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;
	
	new username[33];
	read_argv(1, username, 32);
	new target = cmd_target(id, username, targetFlags);
	if (!target)
		return PLUGIN_HANDLED;
	
	new teamcmd[33];
	read_argv(2, teamcmd, 32);
	
	if (!strlen(teamcmd))
	{
		new CsTeams:team = cs_get_user_team(target);
		
		if (team == CS_TEAM_T)
		{
			if (TryTransferInternal(id, target, CS_TEAM_CT))
			{
				PrintPlayerTransfer(id, target, CS_TEAM_CT);
			}
		}
		else if (team == CS_TEAM_CT)
		{
			if (TryTransferInternal(id, target, CS_TEAM_T))
			{
				PrintPlayerTransfer(id, target, CS_TEAM_T);
			}
		}
		else
		{
			PrintInvalidTeam(id);
		}
	}
	else
	{
		if (equali(teamcmd, "T") || equali(teamcmd, "1"))
		{
			if (TryTransferInternal(id, target, CS_TEAM_T))
			{
				PrintPlayerTransfer(id, target, CS_TEAM_T);
			}
		}
		else if (equali(teamcmd, "CT") || equali(teamcmd, "2"))
		{
			if (TryTransferInternal(id, target, CS_TEAM_CT))
			{
				PrintPlayerTransfer(id, target, CS_TEAM_CT);
			}
		}
		else if (equali(teamcmd, "SPEC") || equali(teamcmd, "3"))
		{
			new target = cmd_target(id, username, targetFlags2);
			if (!target)
				return PLUGIN_HANDLED;
			
			if (TryTransferInternal(id, target, CS_TEAM_SPECTATOR))
			{
				PrintPlayerTransfer(id, target, CS_TEAM_SPECTATOR);
			}
		}
		else
		{
			PrintInvalidTeam(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public cmd_swap(id, level, cid) 
{
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;
	
	new username1[33];
	new username2[33];
	
	read_argv(1, username1, 32);
	read_argv(2, username2, 32);
	
	new player1 = cmd_target(id, username1, targetFlags);
	new player2 = cmd_target(id, username2, targetFlags);
	if (!player1 || !player2)
		return PLUGIN_HANDLED;
	
	new CsTeams:team1 = cs_get_user_team(player1);
	new CsTeams:team2 = cs_get_user_team(player2);
	
	if (team1 == team2)
	{
		console_print(id, "[TeamTransfer] You cannot swap the given players because they are on the same team.");
		return PLUGIN_HANDLED;
	}
	
	if (team1 == CS_TEAM_UNASSIGNED || team2 == CS_TEAM_UNASSIGNED)
	{
		console_print(id, "[TeamTransfer] You cannot swap the given players because one of them is not assigned to a team.");
		return PLUGIN_HANDLED;
	}
	
	if (team1 == CS_TEAM_SPECTATOR || team2 == CS_TEAM_SPECTATOR)
	{
		console_print(id, "[TeamTransfer] You cannot swap the given players because one of them is a spectator.");
		return PLUGIN_HANDLED;
	}
	
	if (TryTransferInternal(id, player1, team2) &&
		TryTransferInternal(id, player2, team1))
	{
		PrintPlayerSwap(id, player1, player2);
	}
	
	return PLUGIN_HANDLED;
}

public cmd_teamswap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED;
	
	new players[32], num;
	get_players(players, num);
	
	new player, CsTeams:team;
	for (new i = 0; i < num; i++)
	{
		player = players[i];
		team = cs_get_user_team(player);
		
		if (team == CS_TEAM_T || team == CS_TEAM_CT)
		{
			add_delay(player, "TaskChangeTeam");
		}
	}
	
	console_print(id, "[TeamTransfer] Successfully swapped the teams.")
	print(0, "^1* ^4[TeamTransfer]^1: The teams were ^4swapped^1.")
	
	return PLUGIN_HANDLED
}
// end cmd handles

// internal functions
bool:TryTransferInternal(id, target, CsTeams:team)
{	
	if (team == CS_TEAM_UNASSIGNED)
	{
		PrintInvalidTeam(id);
		return false;
	}
	
	new CsTeams:currentTeam = cs_get_user_team(target);
	if (currentTeam == team)
	{
		PrintPlayerAleadyInTeam(id);
		return false;
	}
	
	if (currentTeam == CS_TEAM_UNASSIGNED)
	{
		PrintPlayerUnassigned(id);
		return false;
	}
	
	TransferInternal(target, team);
	
	return true;
}

TransferInternal(target, CsTeams:team, bool:transferBomb = true)
{
	if (transferBomb && fm_find_ent_by_owner(-1, "weapon_c4", target))
	{
		fm_transfer_user_gun(target, FindTeammate(target), CSW_C4);
	}
	
	cs_set_user_team(target, team);
	user_silentkill(target);
	
	switch (team)
	{
		case CS_TEAM_T:
			setScreenFlash(target, 255, 0, 0, 100);
		case CS_TEAM_CT:
			setScreenFlash(target, 0, 0, 255, 100);
		default:
			setScreenFlash(target, 255, 255, 255, 100);
	}
}

TeamIndexToString(CsTeams:team)
{
	new teamname[32];
	
	switch (team)
	{
		case CS_TEAM_UNASSIGNED:
			teamname = "Unassigned";
		case CS_TEAM_T:
			teamname = "Terrorists";
		case CS_TEAM_CT:
			teamname = "Counter-Terrorists";
		case CS_TEAM_SPECTATOR:
			teamname = "Spectators";
	}
	
	return teamname;
}

PrintInvalidTeam(id)
{
	console_print(id, "[TeamTransfer] Invalid team specified! Valid teams are: T|1, CT|2 or Spec|3.");
}

PrintPlayerAleadyInTeam(id)
{
	console_print(id, "[TeamTransfer] The player is already in the given team.");
}

PrintPlayerUnassigned(id)
{
	console_print(id, "[TeamTransfer] The player is not currently assigned to any team.");
}

PrintPlayerTransfer(id, player, CsTeams:team)
{
	new username[33];
	get_user_name(player, username, 32);
	
	console_print(id, "[TeamTransfer] You have Successfully transfered %s to the %s.", username, TeamIndexToString(team));
	print(player, "^1* ^4[TeamTransfer]^1: You have been transfered to the ^4%s^1.", TeamIndexToString(team));
}

PrintPlayerSwap(id, player1, player2)
{
	new username1[33];
	new username2[33];
	
	get_user_name(player1, username1, 32);
	get_user_name(player2, username2, 32);
	
	console_print(id, "[TeamTransfer] Successfully swapped %s with %s.", username1, username2);
	print(player1, "^1* ^4[TeamTransfer]^1: You have been swapped with ^4%s^1.", username2);
	print(player2, "^1* ^4[TeamTransfer]^1: You have been swapped with ^4%s^1.", username1);
}

FindTeammate(id)
{
	new Float: fOriginBomb1[3];
	new Float: fOriginBomb2[3];
	new Float: fMinDist = 99999.0;
	new Float: fDist;
	new iTeammate;
	
	new iPlayers[32];
	new iPlayersNum;
	new iPlayer;
	
	pev(id, pev_origin, fOriginBomb1);
	get_players(iPlayers, iPlayersNum);
	if (!iPlayersNum)
		return 0;
	
	for(new i = 0; i < iPlayersNum; i++)
	{
		iPlayer = iPlayers[i];
		
		if ((get_user_team(iPlayer) == 1) && is_user_alive(iPlayer) && (iPlayer != id))
		{
			pev(iPlayer, pev_origin, fOriginBomb2);
			fDist = get_distance_f(fOriginBomb1 , fOriginBomb2);
			
			if(fDist < fMinDist)
			{
				fMinDist = fDist;
				iTeammate = iPlayer;
			}
		}
	}
	
	return iTeammate;
}

print(id, const message[], {Float, Sql, Result, _}:...)
{
	static g_msgSayText;
	g_msgSayText = get_user_msgid("SayText");
	
	new Buffer[191];
	vformat(Buffer, sizeof Buffer - 1, message, 3);
	
	if(id) {
		if(!is_user_connected(id))
			return;
		
		message_begin(MSG_ONE, g_msgSayText, _, id);
		write_byte(id);
		write_string(Buffer);
		message_end();
	} else {
		static players[32], count, index;
		get_players(players, count);
		
		for(new i = 0; i < count; i++) {
			index = players[i];
			
			if(!is_user_connected(index))
				continue;
			
			message_begin(MSG_ONE, g_msgSayText, _, index);
			write_byte(index);
			write_string(Buffer);
			message_end();
		}
	}
}
// end internal functions

// tasks
public TaskChangeTeam(id)
{
	switch (cs_get_user_team(id))
	{
		case CS_TEAM_T: TransferInternal(id, CS_TEAM_CT);
		case CS_TEAM_CT: TransferInternal(id, CS_TEAM_T);
	}
}
// end tasks

// stock functions
stock setScreenFlash(id, r, g, b, alpha)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0, 0, 0}, id)
	write_short(1<<10)
	write_short(1<<10)
	write_short(1<<12)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(alpha)
	message_end()
}

stock add_delay(id, const task[])
{
	switch (id)
	{
		case 1..7: set_task(0.1, task, id)
		case 8..15: set_task(0.2, task, id)
		case 16..23: set_task(0.3, task, id)
		case 24..32: set_task(0.4, task, id)
	}
}
// end stock functions

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

Handle g_hTimer;

ConVar g_hDisplayTime;

int g_iRoundStart;
int g_iPlayerSpawn;

int g_iSIDmgs;
int g_iSIKills;
int g_iCIKills;
int g_iTeamFFs;
int g_iTeamRFs;

int g_iSIDmg[MAXPLAYERS + 1];
int g_iSIKill[MAXPLAYERS + 1];
int g_iCIKill[MAXPLAYERS + 1];
int g_iSIHead[MAXPLAYERS + 1];
int g_iCIHead[MAXPLAYERS + 1];
int g_iTeamFF[MAXPLAYERS + 1];
int g_iTeamRF[MAXPLAYERS + 1];

float g_fDisplayTime;

bool g_bHasAnySurvivorLeftSafeArea;

public Plugin myinfo =
{
	name = "击杀排行统计",
	description = "击杀排行统计",
	author = "白色幽灵 WhiteGT",
	version = "0.6",
	url = ""
};

public void OnPluginStart()
{
	g_hDisplayTime = CreateConVar("sm_mvp_time", "120.0", "轮播时间间隔", FCVAR_NOTIFY, true, 0.0, true, 360.0);

	//AutoExecConfig(true,"l4d_mvp");

	g_hDisplayTime.AddChangeHook(vConVarChanged);

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("player_left_checkpoint", Event_PlayerLeftStartArea);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("infected_death", Event_InfectedDeath);
	
	RegConsoleCmd("sm_mvp", CmdDisplay, "Show Mvp");
}

public void OnConfigsExecuted()
{
	g_fDisplayTime = g_hDisplayTime.FloatValue;
}

public void vConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_fDisplayTime = g_hDisplayTime.FloatValue;
	
	delete g_hTimer;
	if(g_fDisplayTime > 0.0 && g_bHasAnySurvivorLeftSafeArea == true)
		g_hTimer = CreateTimer(g_fDisplayTime, Timer_Display);
}

public Action CmdDisplay(int client, int args)
{
	if(client == 0 || !IsClientInGame(client))
		return Plugin_Handled;

	vDisplay();
	return Plugin_Handled;
}

public Action Timer_Display(Handle timer)
{
	g_hTimer = null;

	vDisplay();

	if(g_fDisplayTime > 0.0)
		g_hTimer = CreateTimer(g_fDisplayTime, Timer_Display);
}

public void OnClientDisconnect(int client)
{
	g_iSIDmgs -= g_iSIDmg[client];
	g_iSIKills -= g_iSIKill[client];
	g_iCIKills -= g_iCIKill[client];
	g_iTeamFFs -= g_iTeamFF[client];
	g_iTeamRFs -= g_iTeamRF[client];
	
	g_iSIDmg[client] = 0;
	g_iSIKill[client] = 0;
	g_iCIKill[client] = 0;
	g_iSIHead[client] = 0;
	g_iCIHead[client] = 0;
	g_iTeamFF[client] = 0;
	g_iTeamRF[client] = 0;
}

public void OnMapEnd()
{
	delete g_hTimer;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_bHasAnySurvivorLeftSafeArea = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapEnd();

	vDisplay();
	vClearData();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimer;

	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	g_iPlayerSpawn = 1;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTimer;
	vDisplay();
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{ 
	if(g_bHasAnySurvivorLeftSafeArea || !bIsRoundStarted())
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		CreateTimer(0.1, Timer_PlayerLeftStartArea, _, TIMER_FLAG_NO_MAPCHANGE);
}

bool bIsRoundStarted()
{
	return g_iRoundStart && g_iPlayerSpawn;
}

public Action Timer_PlayerLeftStartArea(Handle timer)
{
	if(!g_bHasAnySurvivorLeftSafeArea && bIsRoundStarted() && bHasAnySurvivorLeftSafeArea())
	{
		g_bHasAnySurvivorLeftSafeArea = true;

		delete g_hTimer;
		if(g_fDisplayTime > 0.0)
			g_hTimer = CreateTimer(g_fDisplayTime, Timer_Display);
	}
}

bool bHasAnySurvivorLeftSafeArea()
{
	int entity = GetPlayerResourceEntity();
	if(entity == INVALID_ENT_REFERENCE)
		return false;

	return !!GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea");
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	if(victim == 0 || killer == 0 || victim == killer || GetClientTeam(killer) != 2)
		return;

	int dmg = event.GetInt("dmg_health");
	switch(GetClientTeam(victim))
	{
		case 2:
		{
			g_iTeamFF[killer] += dmg;
			g_iTeamFFs += dmg;

			g_iTeamRF[victim] += dmg;
			g_iTeamRFs += dmg;
		}
		
		case 3:
		{
			if(0 < GetEntProp(victim, Prop_Send, "m_zombieClass") < 7)
			{
				g_iSIDmg[killer] += dmg;
				g_iSIDmgs += dmg;
			}
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(killer == 0 || victim == 0 || GetClientTeam(killer) != 2 || GetClientTeam(victim) != 3)
		return;

	switch(GetEntProp(victim, Prop_Send, "m_zombieClass"))
	{
		case 1, 2, 3, 4, 5, 6:
		{
			g_iSIKill[killer]++;
			g_iSIKills++;
		}
		
		case 8:
			g_iSIKill[killer]++;
	}

	if(event.GetBool("headshot"))
		g_iSIHead[killer]++;
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	if(killer == 0 || GetClientTeam(killer) != 2)
		return;

	g_iCIKill[killer] += 1;
	g_iCIKills += 1;

	if(event.GetBool("headshot"))
		g_iCIHead[killer]++;
}

void vDisplay()
{
	int client;
	int iCount;
	int[] iClients = new int[MaxClients + 1];
	for(client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && (GetClientTeam(client) == 2 || ((GetClientTeam(client) == 1 || GetClientTeam(client) == 3) && !IsFakeClient(client))))
			iClients[iCount++] = client;
	}

	if(iCount == 0)
		return;

	int iSIDmg;
	int iSIKill;
	int iSIHead;
	int iCIKill;
	int iCIHead;
	int iTeamFF;
	int iTeamRF;

	PrintToChatAll("\x01[MVP] 击杀排名统计\n");

	SortCustom1D(iClients, iCount, iSortSIKill);
	int iPlayer = iCount < 4 ? iCount : 4;
	for(int i; i < iPlayer; i++)
	{
		client = iClients[i];
		iSIKill = g_iSIKill[client];
		iCIKill = g_iCIKill[client];
		iSIHead = g_iSIHead[client];
		iTeamFF = g_iTeamFF[client];
		iTeamRF = g_iTeamRF[client];
		iSIDmg = g_iSIDmg[client];
		
		PrintToChatAll("\x04★ \x01特感: \x05%d \x01丧尸: \x05%d \x01友伤: \x05%d \x01被黑: \x05%d \x01伤害: \x05%d \x01；\x05%N ", iSIKill, iCIKill, iTeamFF, iTeamRF, iSIDmg, client);
	}

	SortCustom1D(iClients, iCount, iSortSIDamage);
	client = iClients[0];
	iSIDmg = g_iSIDmg[client];
	iSIKill = g_iSIKill[client];
	if(iSIKill > 0)
		PrintToChatAll("\x01特感杀手: \x05%N \x01伤害: \x05%d \x01(\x04%.0f%%\x01) 击杀: \x05%d \x01(\x04%.0f%%\x01)", client, iSIDmg, float(iSIDmg) / float(g_iSIDmgs) * 100, iSIKill, float(iSIKill) / float(g_iSIKills) * 100);

	SortCustom1D(iClients, iCount, iSortCIKill);
	client = iClients[0];
	iCIKill = g_iCIKill[client];
	iCIHead = g_iCIHead[client];
	if(iCIKill > 0)
		PrintToChatAll("\x01清尸狂人: \x05%N \x01击杀: \x05%d \x01(\x04%.0f%%\x01) 爆头: \x05%d \x01(\x04%.0f%%\x01)", client, iCIKill, float(iCIKill) / float(g_iCIKills) * 100, iCIHead, float(iCIHead) / float(iCIKill) * 100, client);

	SortCustom1D(iClients, iCount, iSortTeamFF);
	client = iClients[0];
	iTeamFF = g_iTeamFF[client];
	if(iTeamFF > 0)
		PrintToChatAll("\x01黑枪之王: \x05%N \x01友伤: \x05%d \x01(\x04%.0f%%\x01)", client, iTeamFF, float(iTeamFF) / float(g_iTeamFFs) * 100);
		
	//SortCustom1D(iClients, iCount, iSortTeamRF);
	//client = iClients[0];
	//iTeamRF = g_iTeamRF[client];
	//if(iTeamRF > 0)
		//PrintToChatAll("\x01挨枪之王: \x05%N \x01被黑: \x05%d \x01(\x04%.0f%%\x01)", client, iTeamRF, float(iTeamRF) / float(g_iTeamRFs) * 100);
}

public int iSortSIDamage(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_iSIDmg[elem2] < g_iSIDmg[elem1])
		return -1;
	else if(g_iSIDmg[elem1] < g_iSIDmg[elem2])
		return 1;

	if(elem1 > elem2)
		return -1;
	else if(elem2 > elem1)
		return 1;

	return 0;
}

public int iSortSIKill(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_iSIKill[elem2] < g_iSIKill[elem1])
		return -1;
	else if(g_iSIKill[elem1] < g_iSIKill[elem2])
		return 1;

	if(elem1 > elem2)
		return -1;
	else if(elem2 > elem1)
		return 1;

	return 0;
}

public int iSortCIKill(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_iCIKill[elem2] < g_iCIKill[elem1])
		return -1;
	else if(g_iCIKill[elem1] < g_iCIKill[elem2])
		return 1;

	if(elem1 > elem2)
		return -1;
	else if(elem2 > elem1)
		return 1;

	return 0;
}

public int iSortTeamFF(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_iTeamFF[elem2] < g_iTeamFF[elem1])
		return -1;
	else if(g_iTeamFF[elem1] < g_iTeamFF[elem2])
		return 1;

	if(elem1 > elem2)
		return -1;
	else if(elem2 > elem1)
		return 1;

	return 0;
}

public int iSortTeamRF(int elem1, int elem2, const int[] array, Handle hndl)
{
	if(g_iTeamRF[elem2] < g_iTeamRF[elem1])
		return -1;
	else if(g_iTeamRF[elem1] < g_iTeamRF[elem2])
		return 1;

	if(elem1 > elem2)
		return -1;
	else if(elem2 > elem1)
		return 1;

	return 0;
}

void vClearData()
{
	g_iSIDmgs = 0;
	g_iSIKills = 0;
	g_iCIKills = 0;
	g_iTeamFFs = 0;
	g_iTeamRFs = 0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iSIDmg[i] = 0;
		g_iSIKill[i] = 0;
		g_iCIKill[i] = 0;
		g_iSIHead[i] = 0;
		g_iCIHead[i] = 0;
		g_iTeamFF[i] = 0;
		g_iTeamRF[i] = 0;
	}
}
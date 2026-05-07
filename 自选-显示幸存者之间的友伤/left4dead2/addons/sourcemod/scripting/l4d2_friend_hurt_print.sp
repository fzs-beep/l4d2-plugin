#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <colors>

int FF_RoundDamageSum[MAXPLAYERS + 1];
int FF_Damage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int FF_HurtCount[MAXPLAYERS + 1][MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("round_start",		Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_hurt",		Event_PlayerHurt);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients ; i++)
	{
		FF_RoundDamageSum[i] = 0;
		for (int j = 1; j <= MaxClients ; j++)
		{
			FF_Damage[i][j] = 0;
			FF_HurtCount[i][j] = 0;
		}
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsSurvivor(client))
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsSurvivor(attacker))
		return;

	int Damage = event.GetInt("dmg_health");

	if (Damage <= 0)
		return;

	FF_HurtCount[attacker][client] ++;
	FF_Damage[attacker][client] += Damage;
	if (client != attacker)
		FF_RoundDamageSum[attacker] += Damage;

	DataPack FF_Info = CreateDataPack();
	FF_Info.WriteCell(attacker);
	FF_Info.WriteCell(client);
	FF_Info.WriteCell(FF_HurtCount[attacker][client]);
	CreateTimer(1.0, Timer_ToPrintFFInformations, FF_Info, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ToPrintFFInformations(Handle timer, DataPack data)
{
	data.Reset();

	int attacker = data.ReadCell();
	int victim = data.ReadCell();
	int hurtCount = data.ReadCell();

	delete data;

	if (!IsSurvivor(attacker) || !IsSurvivor(victim) || hurtCount != FF_HurtCount[attacker][victim])
		return Plugin_Stop;

	bool IsSelfHurt = attacker == victim;

	if (IsSelfHurt)
		CPrintToChat(attacker, "{default}* \x05你 {blue}误伤了 \x04你自己 {default}@ {orange}%dHP", FF_Damage[attacker][victim]);
	else
	{
		CPrintToChat(attacker, "{default}* \x05你 {blue}误伤了 \x04%N {default}@ {orange}%dHP \x05Σ {orange}%d", victim, FF_Damage[attacker][victim], FF_RoundDamageSum[attacker]);
		CPrintToChat(victim, "{default}* \x05%N {blue}误伤了 \x04你 {default}@ {orange}%dHP \x05Σ {orange}%d", attacker, FF_Damage[attacker][victim], FF_RoundDamageSum[attacker]);
	}

	for (int i = 1; i <= MaxClients ; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || i == attacker || i == victim)
			continue;
		
		if (IsSelfHurt)
			CPrintToChat(i, "{default}* \x05%N {blue}误伤了 \x04ta自己 {default}@ {orange}%dHP", attacker, FF_Damage[attacker][victim]);
		else
			CPrintToChat(i, "{default}* \x05%N {blue}误伤了 \x04%N {default}@ {orange}%dHP \x05Σ {orange}%d", attacker, victim, FF_Damage[attacker][victim], FF_RoundDamageSum[attacker]);
	}
	FF_Damage[attacker][victim] = 0;
	FF_HurtCount[attacker][victim] = 0;
	return Plugin_Stop;
}

public bool IsValidClient(int client) { return client > 0 && client <= MaxClients && IsClientInGame(client); }
public bool IsSurvivor(int client) { return IsValidClient(client) && GetClientTeam(client) == 2; }
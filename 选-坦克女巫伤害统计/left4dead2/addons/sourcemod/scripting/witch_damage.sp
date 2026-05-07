/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.
	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.
	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Witch Announce++",
	author = "CanadaRox",
	description = "Prints damage done to witches!",
	version = "1",
	url = ""
};

enum clientDamageEnum
{
	CDE_client,
	CDE_damage
};

new Handle:z_witch_health;
new Handle:witchTrie;
new bool:g_bLateLoad;

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], errMax)
{
	g_bLateLoad = late;
}

public OnPluginStart()
{
	witchTrie = CreateTrie();

	HookEvent("witch_spawn", WitchSpawn_Event);
	HookEvent("witch_killed", WitchKilled_Event);

	z_witch_health = FindConVar("z_witch_health");

	if (g_bLateLoad)
	{
		for (new client = 1; client < MaxClients + 1; client++)
		{
			if (IsClientInGame(client))
			{
				//SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public WitchSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	SDKHook(witch, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);

	new witch_dmg_array[MAXPLAYERS+2];
	decl String:witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	witch_dmg_array[MAXPLAYERS+1] = GetConVarInt(z_witch_health);
	SetTrieArray(witchTrie, witch_key, witch_dmg_array, MAXPLAYERS+2, false);
}

public WitchKilled_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new witch = GetEventInt(event, "witchid");
	SDKUnhook(witch, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);
	PrintWitchDamageAndRemove(witch);
}

public OnEntityDestroyed(entity)
{
	SDKUnhook(entity, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);
	decl String:witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", entity);
	RemoveFromTrie(witchTrie, witch_key);
}

public OnTakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype)
{
	decl String:classname[64];
	GetEdictClassname(victim, classname, sizeof(classname));
	if (StrEqual(classname, "witch"))
	{
		decl String:witch_key[10];
		FormatEx(witch_key, sizeof(witch_key), "%x", victim);
		decl witch_dmg_array[MAXPLAYERS+2]; /* index 0: infected damage, index MAXPLAYERS+1: witch health */
		if (!GetTrieArray(witchTrie, witch_key, witch_dmg_array, MAXPLAYERS+2))
		{
			for (new i = 0; i <= MAXPLAYERS; i++)
			{
				witch_dmg_array[i] = 0;
			}
			witch_dmg_array[MAXPLAYERS+1] = GetConVarInt(z_witch_health);
			SetTrieArray(witchTrie, witch_key, witch_dmg_array, MAXPLAYERS+2, false);
		}
		if (attacker > 0 && attacker <= MAXPLAYERS && IsClientInGame(attacker))
		{
			witch_dmg_array[GetClientTeam(attacker) == 3 ? 0 : attacker] += RoundToFloor(damage);
			witch_dmg_array[MAXPLAYERS+1] -= RoundToFloor(damage);
			SetTrieArray(witchTrie, witch_key, witch_dmg_array, MAXPLAYERS+2, true);
		}
	}
}

PrintWitchDamageAndRemove(witch)
{
	decl witch_dmg_array[MAXPLAYERS+2];
	new Handle:damage_array = CreateArray(2);
	decl clientDamageEnum:current_client[clientDamageEnum];

	decl String:witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	if (GetTrieArray(witchTrie, witch_key, witch_dmg_array, MAXPLAYERS+2))
	{
		for (new client = 1; client <= MAXPLAYERS; client++)
		{
			if (witch_dmg_array[client] > 0)
			{
				current_client[CDE_client] = client;
				current_client[CDE_damage] = witch_dmg_array[client];
				PushArrayArray(damage_array, current_client[0]);
			}
		}
		SortADTArrayCustom(damage_array, sortFunc);
		new array_size = GetArraySize(damage_array);
		new witch_health = GetConVarInt(z_witch_health);
		new witch_remaining_health = witch_dmg_array[MAXPLAYERS+1];
		if (witch_remaining_health > 0)
		{
			PrintToChatAll("\x04[提示] \x05对女巫造成的伤害");
			//PrintToChatAll("\x03Witch \x05还剩余 \x03%d \x01(\x04%d%%\x01)\x05血", witch_remaining_health, witch_remaining_health*100/witch_health);
		}
		else
		{
			//PrintToChatAll("\x04[SM] \x03Witch \x05已经死亡");
		}
		for (new i = 0; i < array_size; i++)
		{
			GetArrayArray(damage_array, i, current_client);
			if (IsClientInGame(current_client[CDE_client]))
			{
				PrintToChatAll("\x04★ \x03%d \x01(\x04%d%%\x01) \x05%N", current_client[CDE_damage], current_client[CDE_damage]*100/witch_health, current_client[CDE_client]);
			}
			else
			{
				//PrintToChatAll("\x03Unknown: \x05%d\x01 [\x05%d%%\x01]", current_client[CDE_damage], current_client[CDE_damage]*100/witch_health);
			}
		}
		if (witch_dmg_array[0])
		{
			//PrintToChatAll("\x03Infected: \x05%d\x01 [\x05%d%%\x01]", witch_dmg_array[0], witch_dmg_array[0]*100/witch_health);
		}
	}
	SDKUnhook(witch, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);
	RemoveFromTrie(witchTrie, witch_key);
	ClearArray(damage_array);
}

public sortFunc(index1, index2, Handle:array, Handle:hndl)
{
	decl item1[2];
	GetArrayArray(array, index1, item1, 2);

	decl item2[2];
	GetArrayArray(array, index2, item2, 2);

	if (item1[1] > item2[1])
		return -1;
	else if (item1[1] < item2[1])
		return 1;
	else
		return 0;
}

stock bool:IsPlayerIncap(client) return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
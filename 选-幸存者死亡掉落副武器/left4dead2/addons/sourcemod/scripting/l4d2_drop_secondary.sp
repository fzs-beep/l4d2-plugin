#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new g_PlayerSecondaryWeapons[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name        = "L4D2 Drop Secondary",
	author      = "Jahze, Visor, NoBody",
	version     = "1.1",
	description = "Survivor players will drop their secondary weapon when they die",
	url         = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart() 
{
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Post);
	HookEvent("player_bot_replace", OnBotSwap);
	HookEvent("bot_player_replace", OnBotSwap);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public OnRoundStart() 
{
	for (new i = 0; i <= MAXPLAYERS; i++) 
	{
		new weapon = IsValidWeapon(weapon);
		{
			g_PlayerSecondaryWeapons[i] = weapon == -1;
		}
	}
}

public Action:OnPlayerUse(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client)) 
	{
        return;
    }
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidWeapon(weapon)) 
	{
		g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
	}
}

public Action:OnBotSwap(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new bot = GetClientOfUserId(GetEventInt(event, "bot"));
    new player = GetClientOfUserId(GetEventInt(event, "player"));
    if (IsSurvivor(bot) && IsSurvivor(player))
	{
        return;
    }

    if (StrEqual(name, "player_bot_replace")) 
	{
        g_PlayerSecondaryWeapons[bot] = g_PlayerSecondaryWeapons[player];
        g_PlayerSecondaryWeapons[player] = -1;
    }
	
    else 
	{
        g_PlayerSecondaryWeapons[player] = g_PlayerSecondaryWeapons[bot];
        g_PlayerSecondaryWeapons[bot] = -1;
    }
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client)) 
	{
        return;
    }
	
	new weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	if (IsValidWeapon(weapon)) 
	{
		DropSecondaryWeapon(client, weapon);
	}
}

stock bool:IsSurvivor(client) 
{
	if (client <= 0 || client > MaxClients) 
	{
		return false;
	}

	if (!IsClientInGame(client) || GetClientTeam(client) == 2) 
	{
		return false;
	}

	return true;
}

stock bool:IsValidWeapon(weapon)
{
	if (weapon > 2048 && weapon != INVALID_ENT_REFERENCE) 
	{
		weapon = EntRefToEntIndex(weapon);
	}
	
	if (!IsValidEdict(weapon) || !IsValidEntity(weapon) || weapon == -1) 
	{
		return false;
	}
	
	new String:sWeapon[64];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	return StrContains(sWeapon, "weapon_") == 0;
}

stock DropSecondaryWeapon(client, weapon)
{
	new OwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if (OwnerEntity != client) 
	{
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	}

	weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);

	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
	
	if (OwnerEntity != -1) 
	{
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", OwnerEntity);
	}
	
	if (!IsPlayerAlive(client)) 
	{
		return;
	}
	
	RemovePlayerItem(client, weapon);
	
	new SecondaryWeapon = GetPlayerWeaponSlot(client, 1);
	
	if (!IsValidWeapon(SecondaryWeapon)) 
	{
		return;
	}
	
	static String:sWeapon[64]; GetEdictClassname(SecondaryWeapon, sWeapon, sizeof(sWeapon));
	FakeClientCommandEx(client, "use %s", sWeapon);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SecondaryWeapon);
}

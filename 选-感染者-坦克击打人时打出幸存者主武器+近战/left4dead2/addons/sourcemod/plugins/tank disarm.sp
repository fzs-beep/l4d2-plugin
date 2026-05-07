
 PlVers __version = 5;
 float NULL_VECTOR[3];
 char NULL_STRING[1];
 Extension __ext_core = 64;
 int MaxClients;
 Extension __ext_sdktools = 180;
public Plugin myinfo =
{
	name = "[L4D2] Drop weapon when punched",
	description = "Survivors will drop their weapon w",
	author = "cheewongken",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};
 int TanksInGame;
 int GivenGun[65];
 Handle c_dwp_enabled;
 Handle c_dwp_drop_incapped;
 Handle c_dwp_drop_melee;
 Handle c_dwp_give_pistol;
 Handle c_dwp_drop_chainsaw;
public int __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

float operator+(Float:,_:)(float oper1, int oper2)
{
	return FloatAdd(oper1, float(oper2));
}

bool StrEqual(char str1[], char str2[], bool caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

public int OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, 64);
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("[SM] Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_dwp_version", "1.0", "Version of [L4D2] Drop weapon when punched", 270656, false, 0, false, 0);
	HookEvent("round_start", EventHook 17, EventHookMode 0);
	HookEvent("round_end", EventHook 17, EventHookMode 0);
	HookEvent("tank_spawn", EventHook 21, EventHookMode 1);
	HookEvent("player_hurt", EventHook 13, EventHookMode 1);
	HookEvent("tank_killed", EventHook 19, EventHookMode 1);
	HookEvent("player_incapacitated_start", EventHook 15, EventHookMode 1);
	HookEvent("item_pickup", EventHook 5, EventHookMode 1);
	c_dwp_enabled = CreateConVar("l4d2_dwp_enabled", "1", "Is plugin enabled? 1=Yes, 0=No", 270656, false, 0, false, 0);
	c_dwp_drop_incapped = CreateConVar("l4d2_dwp_drop_when_incapped", "0", "Will you drop weapon if you get incapped? 1=Yes, 0=No", 270656, false, 0, false, 0);
	c_dwp_drop_melee = CreateConVar("l4d2_dwp_drop_melee", "1", "Will you drop melee weapon if you get hit? 1=Yes, 0=No", 270656, false, 0, false, 0);
	c_dwp_give_pistol = CreateConVar("l4d2_dwp_give_pistol", "1", "Will you get a pistol if you drop your melee weapon? 1=Yes, 0=No", 270656, false, 0, false, 0);
	c_dwp_drop_chainsaw = CreateConVar("l4d2_dwp_drop_chainsaw", "1", "Will you drop chainsaw if you get hit? 1=Yes, 0=No", 270656, false, 0, false, 0);
	AutoExecConfig(true, "l4d2_drop_when_punched", "sourcemod");
	return 0;
}

public Action RoundR(Handle event, char event_name[], bool dontBroadcast)
{
	TanksInGame = 0;
	return Action 0;
}

public Action TankSpawned(Handle event, char event_name[], bool dontBroadcast)
{
	TanksInGame += 1;
	return Action 0;
}


/* ERROR! Unrecognized opcode dec */
 函数 "TankKilled" (数量 6)
int Misc_GetAnyClient()
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			return i;
		}
		i++;
	}
	return 0;
}

public Action PlayerHit(Handle event, char event_name[], bool dontBroadcast)
{
	if (TanksInGame)
	{
		if (GetConVarBool(c_dwp_enabled))
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			int var1;
			if (IsValidClient(attacker))
			{
				if (!GetEntProp(client, PropType 0, "m_isIncapacitated", 1))
				{
					DropWep(client);
				}
			}
		}
	}
	return Action 0;
}

public Action PlayerIncapped(Handle event, char event_name[], bool dontBroadcast)
{
	if (TanksInGame)
	{
		if (GetConVarBool(c_dwp_enabled))
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			int var1;
			if (IsValidClient(attacker))
			{
				if (GetConVarBool(c_dwp_drop_incapped))
				{
					DropWep(client);
				}
			}
		}
	}
	return Action 0;
}

public Action Event_Pickup(Handle event, char name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GivenGun[client][0][0] == 1)
	{
		char weapon[32];
		GetClientWeapon(client, weapon, 32);
		int var1;
		if (StrEqual(weapon, "weapon_melee", true))
		{
			int ent22 = -1;
			int prev22 = 0;
			int var2 = FindEntityByClassname(ent22, "weapon_pistol");
			ent22 = var2;
			while (var2 != -1)
			{
				if (prev22)
				{
					RemoveEdict(prev22);
				}
				prev22 = ent22;
			}
			if (prev22)
			{
				RemoveEdict(prev22);
			}
			GivenGun[client] = 0;
		}
	}
	return Action 0;
}

public Action GivePistol(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & -16385);
	FakeClientCommand(client, "give pistol");
	SetCommandFlags("give", flags | 16384);
	GivenGun[client] = 1;
	return Action 0;
}

public Action DropWep(int client)
{
	int var1;
	if (client)
	{
		return Action 3;
	}
	char weapon[32];
	GetClientWeapon(client, weapon, 32);
	int var2;
	if (StrEqual(weapon, "weapon_pumpshotgun", true))
	{
		DropSlot(client, 0);
	}
	else
	{
		if (!GetEntProp(client, PropType 0, "m_isIncapacitated", 1))
		{
			if (GetConVarBool(c_dwp_drop_melee))
			{
				if (StrEqual(weapon, "weapon_melee", true))
				{
					DropSlot(client, 1);
					if (GetConVarBool(c_dwp_give_pistol))
					{
						GivePistol(client);
					}
				}
			}
			if (GetConVarBool(c_dwp_drop_chainsaw))
			{
				if (StrEqual(weapon, "weapon_chainsaw", true))
				{
					DropSlot(client, 1);
					if (GetConVarBool(c_dwp_give_pistol))
					{
						GivePistol(client);
					}
				}
			}
		}
	}
	return Action 3;
}

public int DropSlot(int client, int slot)
{
	if (0 < GetPlayerWeaponSlot(client, slot))
	{
		char weapon[32];
		int ammo = 0;
		int clip = 0;
		int upgrade = 0;
		int upammo = 0;
		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo", 0, 0, 0);
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), weapon, 32);
		if (!slot)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), PropType 0, "m_iClip1", 4);
			upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), PropType 0, "m_upgradeBitVec", 4);
			upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), PropType 0, "m_nUpgradedPrimaryAmmoLoaded", 4);
			int var1;
			if (StrEqual(weapon, "weapon_rifle", true))
			{
				ammo = GetEntData(client, ammoOffset + 12, 4);
				SetEntData(client, ammoOffset + 12, any 0, 4, false);
			}
			int var2;
			if (StrEqual(weapon, "weapon_smg", true))
			{
				ammo = GetEntData(client, ammoOffset + 20, 4);
				SetEntData(client, ammoOffset + 20, any 0, 4, false);
			}
			int var3;
			if (StrEqual(weapon, "weapon_pumpshotgun", true))
			{
				ammo = GetEntData(client, ammoOffset + 28, 4);
				SetEntData(client, ammoOffset + 28, any 0, 4, false);
			}
			int var4;
			if (StrEqual(weapon, "weapon_autoshotgun", true))
			{
				ammo = GetEntData(client, ammoOffset + 32, 4);
				SetEntData(client, ammoOffset + 32, any 0, 4, false);
			}
			if (StrEqual(weapon, "weapon_hunting_rifle", true))
			{
				ammo = GetEntData(client, ammoOffset + 36, 4);
				SetEntData(client, ammoOffset + 36, any 0, 4, false);
			}
			int var5;
			if (StrEqual(weapon, "weapon_sniper_scout", true))
			{
				ammo = GetEntData(client, ammoOffset + 40, 4);
				SetEntData(client, ammoOffset + 40, any 0, 4, false);
			}
			if (StrEqual(weapon, "weapon_grenade_launcher", true))
			{
				ammo = GetEntData(client, ammoOffset + 68, 4);
				SetEntData(client, ammoOffset + 68, any 0, 4, false);
			}
		}
		int index = CreateEntityByName(weapon, -1);
		float origin[3];
		GetEntPropVector(client, PropType 0, "m_vecOrigin", origin);
		origin[8] += 20;
		TeleportEntity(index, origin, NULL_VECTOR, NULL_VECTOR);
		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_melee", true))
			{
				char item[152];
				GetEntPropString(GetPlayerWeaponSlot(client, 1), PropType 1, "m_ModelName", item, 150);
				if (StrEqual(item, "models/weapons/melee/v_fireaxe.mdl", true))
				{
					DispatchKeyValue(index, "model", "models/weapons/melee/v_fireaxe.mdl");
					DispatchKeyValue(index, "melee_script_name", "fireaxe");
				}
				else
				{
					if (StrEqual(item, "models/weapons/melee/v_frying_pan.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_frying_pan.mdl");
						DispatchKeyValue(index, "melee_script_name", "frying_pan");
					}
					if (StrEqual(item, "models/weapons/melee/v_machete.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_machete.mdl");
						DispatchKeyValue(index, "melee_script_name", "machete");
					}
					if (StrEqual(item, "models/weapons/melee/v_bat.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_bat.mdl");
						DispatchKeyValue(index, "melee_script_name", "baseball_bat");
					}
					if (StrEqual(item, "models/weapons/melee/v_crowbar.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_crowbar.mdl");
						DispatchKeyValue(index, "melee_script_name", "crowbar");
					}
					if (StrEqual(item, "models/weapons/melee/v_cricket_bat.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_cricket_bat.mdl");
						DispatchKeyValue(index, "melee_script_name", "cricket_bat");
					}
					if (StrEqual(item, "models/weapons/melee/v_tonfa.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_tonfa.mdl");
						DispatchKeyValue(index, "melee_script_name", "tonfa");
					}
					if (StrEqual(item, "models/weapons/melee/v_katana.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_katana.mdl");
						DispatchKeyValue(index, "melee_script_name", "katana");
					}
					if (StrEqual(item, "models/weapons/melee/v_electric_guitar.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_electric_guitar.mdl");
						DispatchKeyValue(index, "melee_script_name", "electric_guitar");
					}
					if (StrEqual(item, "models/weapons/melee/v_golfclub.mdl", true))
					{
						DispatchKeyValue(index, "model", "models/weapons/melee/v_golfclub.mdl");
						DispatchKeyValue(index, "melee_script_name", "golfclub");
					}
				}
			}
			if (StrEqual(weapon, "weapon_chainsaw", true))
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), PropType 0, "m_iClip1", 4);
			}
		}
		DispatchSpawn(index);
		ActivateEntity(index);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));
		if (!slot)
		{
			SetEntProp(index, PropType 0, "m_iExtraPrimaryAmmo", ammo, 4);
			SetEntProp(index, PropType 0, "m_iClip1", clip, 4);
			SetEntProp(index, PropType 0, "m_upgradeBitVec", upgrade, 4);
			SetEntProp(index, PropType 0, "m_nUpgradedPrimaryAmmoLoaded", upammo, 4);
		}
		if (slot == 1)
		{
			if (StrEqual(weapon, "weapon_chainsaw", true))
			{
				SetEntProp(index, PropType 0, "m_iClip1", clip, 4);
			}
		}
	}
	return 0;
}

public int IsValidClient(int i)
{
	if (i)
	{
		if (!IsClientConnected(i))
		{
			return 0;
		}
		if (!IsClientInGame(i))
		{
			return 0;
		}
		if (!IsPlayerAlive(i))
		{
			return 0;
		}
		if (!IsValidEntity(i))
		{
			return 0;
		}
		return 1;
	}
	return 0;
}

bool IsPlayerTank(int i)
{
	char model[128];
	GetClientModel(i, model, 128);
	if (0 >= StrContains(model, "hulk", false))
	{
		return false;
	}
	return true;
}


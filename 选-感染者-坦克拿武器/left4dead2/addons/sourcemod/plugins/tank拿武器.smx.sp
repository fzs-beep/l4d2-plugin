/*
** [Ezrealik]提醒你：
** 反编译的代码是无法直接进行编译的！
** 反编译器只是给你一个大概,帮助你了解别人是如何编写插件的!
** 了解插件是如何工作的,是否有可能拥有恶意代码。
** 所有的转换仅仅是一种可能性,它很多都是错误的转换！例如：
** SetEntityRenderFx(client, RenderFx 0);
→  SetEntityRenderFx(client, view_as<RenderFx>0);
→  SetEntityRenderFx(client, RENDERFX_NONE);
*/

 PlVers __version = 5;
 float NULL_VECTOR[3];
 char NULL_STRING[1];
 Extension __ext_core = 68;
 int MaxClients;
 Extension __ext_sdktools = 188;
 Extension __ext_sdkhooks = 232;
 int Min_Index;
 int Max_Index;
 char WeaponName[40][25];
 char WeaponClass[40][25];
 int ZOMBIECLASS_TANK = 5;
 int MeleeEnt[65];
 bool MeleeViewOn[65];
 float WeaponScale[65];
 int MeleeWeapon[65];
 int GameMode;
 int L4D2Version;
public Plugin myinfo =
{
	name = "Melee Infected",
	description = "",
	author = "Pan XiaoHai",
	version = "1.6",
	url = "<- URL ->"
};
 Handle l4d_melee_tank_chance;
 Handle l4d_melee_tank_chance_witch;
 Handle l4d_melee_tank_weaponsize;
 Handle l4d_melee_tank_chance_drop;
 Handle l4d_melee_tank_chance_fullclip;
public int __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

bool operator<(Float:,Float:)(float oper1, float oper2)
{
	return FloatCompare(oper1, oper2) < 0;
}

bool StrEqual(char str1[], char str2[], bool caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

int PrintToChatAll(char format[])
{
	char buffer[192];
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, 192, format, 2);
			PrintToChat(i, "%s", buffer);
			i++;
		}
		i++;
	}
	return 0;
}

public int OnPluginStart()
{
	GameCheck();
	l4d_melee_tank_chance = CreateConVar("l4d_melee_tank_chance", "100", "chance of melee tank[0.0, 100.0]", 0, false, 0, false, 0);
	l4d_melee_tank_chance_witch = CreateConVar("l4d_melee_tank_chance_witch", "30", "chance of take witch[0.0, 100.0]", 0, false, 0, false, 0);
	l4d_melee_tank_weaponsize = CreateConVar("l4d_melee_tank_weaponsize", "1.0", "weapon size [1.0, 2.0]", 0, false, 0, false, 0);
	l4d_melee_tank_chance_drop = CreateConVar("l4d_melee_tank_chance_drop", "100", "chance of drop weapon when tank dead  [0.0, 100.0]", 0, false, 0, false, 0);
	l4d_melee_tank_chance_fullclip = CreateConVar("l4d_melee_tank_chance_fullclip", "100", "chance of full clip[0.0, 100.0]", 0, false, 0, false, 0);
	AutoExecConfig(true, "l4d_melee_infected", "sourcemod");
	HookEvent("player_spawn", EventHook 17, EventHookMode 1);
	HookEvent("player_death", EventHook 15, EventHookMode 1);
	HookEvent("player_bot_replace", EventHook 13, EventHookMode 1);
	HookEvent("bot_player_replace", EventHook 11, EventHookMode 1);
	HookEvent("round_start", EventHook 19, EventHookMode 1);
	HookEvent("round_end", EventHook 19, EventHookMode 1);
	HookEvent("finale_win", EventHook 19, EventHookMode 1);
	HookEvent("mission_lost", EventHook 19, EventHookMode 1);
	HookEvent("map_transition", EventHook 19, EventHookMode 1);
	RegConsoleCmd("sm_melee", sm_melee, "", 0);
	ResetAllState();
	Init();
	return 0;
}

int GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, 16);
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else
	{
		int var1;
		if (StrEqual(GameName, "versus", false))
		{
			GameMode = 2;
		}
		int var2;
		if (StrEqual(GameName, "coop", false))
		{
			GameMode = 1;
		}
		GameMode = 0;
	}
	GameMode = GameMode + 0;
	GetGameFolderName(GameName, 16);
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version = 1;
		ZOMBIECLASS_TANK = 8;
	}
	else
	{
		L4D2Version = 0;
		ZOMBIECLASS_TANK = 5;
	}
	return 0;
}

public Action player_spawn(Handle hEvent, char strName[], bool DontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (0 < client)
	{
		CreateMeleeTank(client);
	}
	return Action 0;
}

public Action sm_melee(int client, int args)
{
	if (0 < client)
	{
		MeleeViewOn[client] = !MeleeViewOn[client][0][0];
	}
	return Action 0;
}

public Action player_death(Handle hEvent, char strName[], bool DontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int var1;
	if (client > 0)
	{
		int var2;
		if (IsMelee(MeleeEnt[client][0][0]))
		{
			float pos[3];
			float angle[3];
			GetClientEyePosition(client, pos);
			GetClientAbsAngles(client, angle);
			int weapon = MeleeWeapon[client][0][0];
			if (0 <= StrContains(WeaponClass[weapon][0][0], "weapon", true))
			{
				int ent = CreateEntityByName(WeaponClass[weapon][0][0], -1);
				DispatchSpawn(ent);
				TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
				if (L4D2Version)
				{
					SetEntPropFloat(ent, PropType 0, "m_flModelScale", WeaponScale[client][0][0]);
				}
				int ammo = 0;
				int clip = 0;
				if (0 <= StrContains(WeaponClass[weapon][0][0], "shotgun", true))
				{
					if (L4D2Version)
					{
						ammo = GetConVarInt(FindConVar("ammo_autoshotgun_max"));
					}
					else
					{
						ammo = GetConVarInt(FindConVar("ammo_buckshot_max"));
					}
				}
				else
				{
					if (0 <= StrContains(WeaponClass[weapon][0][0], "hunting", true))
					{
						ammo = GetConVarInt(FindConVar("ammo_huntingrifle_max"));
					}
					int var3;
					if (StrContains(WeaponClass[weapon][0][0], "rifle", true) >= 0)
					{
						ammo = GetConVarInt(FindConVar("ammo_assaultrifle_max"));
					}
					if (0 <= StrContains(WeaponClass[weapon][0][0], "grenade_launcher", true))
					{
						ammo = GetConVarInt(FindConVar("ammo_grenadelauncher_max"));
					}
					if (0 <= StrContains(WeaponClass[weapon][0][0], "sniper", true))
					{
						ammo = GetConVarInt(FindConVar("ammo_sniperrifle_max"));
					}
				}
				if (GetRandomFloat(0, 100) < GetConVarFloat(l4d_melee_tank_chance_fullclip))
				{
					clip = ammo;
				}
				int var4;
				if (ammo > 0)
				{
					if (0 < clip)
					{
						SetEntProp(ent, PropType 0, "m_iClip1", clip, 4);
					}
					if (0 < ammo)
					{
						SetEntProp(ent, PropType 0, "m_iExtraPrimaryAmmo", ammo, 4);
					}
					PrintToChatAll("%s AMMO ammo %d, clip %d", WeaponClass[weapon][0][0], ammo, clip);
				}
			}
			else
			{
				if (0 <= StrContains(WeaponClass[weapon][0][0], "witch", true))
				{
					int ent = CreateEntityByName("witch", -1);
					DispatchSpawn(ent);
					TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
				}
				int ent = CreateEntityByName("weapon_melee", -1);
				DispatchKeyValue(ent, "melee_script_name", WeaponClass[weapon][0][0]);
				DispatchSpawn(ent);
				TeleportEntity(ent, pos, angle, NULL_VECTOR);
				if (L4D2Version)
				{
					SetEntPropFloat(ent, PropType 0, "m_flModelScale", WeaponScale[client][0][0]);
				}
			}
		}
		DeleteMelee(client);
	}
	return Action 0;
}

public int player_bot_replace(Handle Spawn_Event, char Spawn_Name[], bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	int bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	if (0 < client)
	{
		DeleteMelee(client);
	}
	if (0 < bot)
	{
		DeleteMelee(bot);
		CreateMeleeTank(bot);
	}
	return 0;
}

public int bot_player_replace(Handle Spawn_Event, char Spawn_Name[], bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	int bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	if (0 < bot)
	{
		DeleteMelee(bot);
	}
	if (0 < client)
	{
		DeleteMelee(client);
		CreateMeleeTank(client);
	}
	return 0;
}

public Action round_end(Handle event, char name[], bool dontBroadcast)
{
	ResetAllState();
	return Action 0;
}

int ResetAllState()
{
	int i = 1;
	while (i <= MaxClients)
	{
		MeleeEnt[i] = 0;
		i++;
	}
	return 0;
}

bool IsMelee(int ent)
{
	int var1;
	if (ent > 0)
	{
		return true;
	}
	return false;
}

int DeleteMelee(int client)
{
	if (IsMelee(MeleeEnt[client][0][0]))
	{
		AcceptEntityInput(MeleeEnt[client][0][0], "ClearParent", -1, -1, 0);
		AcceptEntityInput(MeleeEnt[client][0][0], "kill", -1, -1, 0);
		SDKUnhook(MeleeEnt[client][0][0], SDKHookType 6, SDKHookCB 1);
	}
	MeleeEnt[client] = 0;
	return 0;
}

public int OnMapStart()
{
	Init();
	int i = Min_Index;
	while (i <= Max_Index)
	{
		PrecacheModel(WeaponName[i][0][0], false);
		i++;
	}
	if (L4D2Version)
	{
		PrecacheModel("models/weapons/melee/v_bat.mdl", true);
		PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
		PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
		PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
		PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
		PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);
		PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);
		PrecacheModel("models/weapons/melee/v_katana.mdl", true);
		PrecacheModel("models/weapons/melee/v_machete.mdl", true);
		PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);
		PrecacheModel("models/weapons/melee/w_bat.mdl", true);
		PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
		PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
		PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
		PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
		PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
		PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
		PrecacheModel("models/weapons/melee/w_katana.mdl", true);
		PrecacheModel("models/weapons/melee/w_machete.mdl", true);
		PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);
		PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
		PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
		PrecacheGeneric("scripts/melee/crowbar.txt", true);
		PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
		PrecacheGeneric("scripts/melee/fireaxe.txt", true);
		PrecacheGeneric("scripts/melee/frying_pan.txt", true);
		PrecacheGeneric("scripts/melee/golfclub.txt", true);
		PrecacheGeneric("scripts/melee/katana.txt", true);
		PrecacheGeneric("scripts/melee/machete.txt", true);
		PrecacheGeneric("scripts/melee/tonfa.txt", true);
		PrecacheModel("models/v_models/weapons/v_rifle_ak47.mdl", true);
		PrecacheModel("models/v_models/weapons/v_m60.mdl", true);
		PrecacheModel("models/v_models/weapons/v_autoshot_m4super.mdl", true);
		PrecacheModel("models/v_models/weapons/v_shotgun_spas.mdl", true);
		PrecacheModel("models/v_models/weapons/w_sniper_military.mdl", true);
	}
	return 0;
}

int Init()
{
	SetRandomSeed(GetSysTickCount());
	if (L4D2Version)
	{
		Min_Index = 1;
		Max_Index = 14;
	}
	else
	{
		Min_Index = 1;
		Max_Index = 4;
	}
	return 0;
}

int CreateMeleeTank(int client)
{
	int var1;
	if (client > 0)
	{
		float c = GetConVarFloat(l4d_melee_tank_chance);
		if (GetRandomFloat(0, 100) < c)
		{
			CreateTimer(1, TimerCreateMelee, client, 2);
		}
	}
	return 0;
}

int CreateMelee(int client)
{
	DeleteMelee(client);
	int weapon = 0;
	float chanceOfWitch = GetConVarFloat(l4d_melee_tank_chance_witch);
	if (GetRandomFloat(0, 100) < chanceOfWitch)
	{
		if (L4D2Version)
		{
			weapon = 8;
		}
		else
		{
			weapon = 4;
		}
	}
	else
	{
		weapon = GetRandomInt(Min_Index, Max_Index);
	}
	int positon = 1;
	if (GetRandomInt(1, 3) < 3)
	{
		positon = 1;
	}
	else
	{
		positon = 2;
	}
	float scale = 0;
	int melee = CreateEntityByName("prop_dynamic_override", -1);
	SetEntityModel(melee, WeaponName[weapon][0][0]);
	DispatchSpawn(melee);
	char tname[60];
	Format(tname, 60, "target%d", client);
	DispatchKeyValue(client, "targetname", tname);
	DispatchKeyValue(melee, "parentname", tname);
	float pos[3];
	float ang[3];
	SetVariantString(tname);
	AcceptEntityInput(melee, "SetParent", melee, melee, 0);
	char strPositon[32];
	if (!(positon == 2))
	{
	}
	SetVariantString(strPositon);
	AcceptEntityInput(melee, "SetParentAttachment", -1, -1, 0);
	if (L4D2Version)
	{
		GetPosAng(weapon, pos, ang, positon, scale);
	}
	else
	{
		GetPosAng_l4d1(weapon, pos, ang, positon, scale);
	}
	TeleportEntity(melee, pos, ang, NULL_VECTOR);
	SetEntProp(melee, PropType 0, "m_CollisionGroup", any 2, 4);
	if (L4D2Version)
	{
		SetEntPropFloat(melee, PropType 0, "m_flModelScale", scale);
	}
	MeleeEnt[client] = melee;
	MeleeWeapon[client] = weapon;
	WeaponScale[client] = scale;
	MeleeViewOn[client] = 0;
	SDKHook(MeleeEnt[client][0][0], SDKHookType 6, SDKHookCB 1);
	return 0;
}

int GetPosAng_l4d1(int weapon, float pos[3], float ang[3], int position, &float scale)
{
	if (weapon == 4)
	{
		if (position == 1)
		{
			SetVector(pos, -3, 15, 3);
			SetVector(ang, -90, 0, 90);
		}
		if (position == 2)
		{
			SetVector(pos, 3, 15, -3);
			SetVector(ang, 90, 0, 90);
		}
	}
	else
	{
		if (position == 1)
		{
			SetVector(pos, 1, -5, 3);
			SetVector(ang, 0, -90, 90);
		}
		if (position == 2)
		{
			SetVector(pos, 4, -5, -3);
			SetVector(ang, 0, -90, 90);
		}
	}
	return 0;
}

int GetPosAng(int weapon, float pos[3], float ang[3], int position, &float scale)
{
	if (weapon == 7)
	{
		if (position == 1)
		{
			SetVector(pos, -23, -30, -5);
			SetVector(ang, 0, 60, 180);
		}
		if (position == 2)
		{
			SetVector(pos, -9, -32, -1);
			SetVector(ang, 0, 60, 180);
		}
	}
	else
	{
		if (weapon == 8)
		{
			if (position == 1)
			{
				SetVector(pos, -3, 15, 3);
				SetVector(ang, -90, 0, 90);
			}
			if (position == 2)
			{
				SetVector(pos, 3, 15, -3);
				SetVector(ang, 90, 0, 90);
			}
		}
		if (weapon >= 9)
		{
			if (position == 1)
			{
				SetVector(pos, 1, -5, 3);
				SetVector(ang, 0, -90, 90);
			}
			if (position == 2)
			{
				SetVector(pos, 4, -5, -3);
				SetVector(ang, 0, -90, 90);
			}
		}
		if (position == 1)
		{
			SetVector(pos, -4, 0, 3);
			SetVector(ang, 0, -11, 100);
		}
		if (position == 2)
		{
			SetVector(pos, 4, 0, -3);
			SetVector(ang, 0, -11, 100);
		}
	}
	if (weapon != 8)
	{
		scale = 1075838976;
		if (weapon == 4)
		{
			scale = 1082130432;
		}
		if (weapon == 2)
		{
			scale = 1071225242;
		}
		if (weapon == 6)
		{
			scale = 1080033280;
		}
		if (weapon == 5)
		{
			scale = 1075000115;
		}
		if (weapon == 7)
		{
			scale = 1073741824;
		}
		if (weapon == 3)
		{
			scale = 1077936128;
		}
		scale = FloatMul(scale, GetConVarFloat(l4d_melee_tank_weaponsize));
	}
	else
	{
		scale = 1065353216;
	}
	return 0;
}

public Action TimerCreateMelee(Handle timer, any client)
{
	int var1;
	if (client > any 0)
	{
		CreateMelee(client);
	}
	return Action 0;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if (MeleeEnt[client][0][0] == entity)
	{
		if (MeleeViewOn[client][0][0])
		{
			return Action 0;
		}
		return Action 3;
	}
	return Action 0;
}

int SetVector(float target[3], float x, float y, float z)
{
	target[0] = x;
	target[4] = y;
	target[8] = z;
	return 0;
}

int IsInfected(int client, int type)
{
	int class = GetEntProp(client, PropType 0, "m_zombieClass", 4);
	if (class == type)
	{
		return 1;
	}
	return 0;
}


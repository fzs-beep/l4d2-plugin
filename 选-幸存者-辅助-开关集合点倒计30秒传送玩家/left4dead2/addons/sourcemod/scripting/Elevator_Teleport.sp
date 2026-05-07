#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6"
#define SOUND_COUNTDOWN "buttons/blip1.wav"

/* =============================================================================================================== *
 *									Plugin Variables - Float, Int, Bool, ConVars			   					   *
 *================================================================================================================ */

float g_fDuration;

int g_iElevatorButton;
int g_iMapType;

bool g_bLeft4Dead2;
bool g_bLockedButtonPressed;
bool g_bUnlockedButtonPressed;

ConVar g_Cvar_PluginEnable;
ConVar g_Cvar_TeleportTime;
ConVar g_Cvar_MapsIncluded;
ConVar g_Cvar_RescueClient;

enum
{
	C1M1 = 1,
	C1M4,
	C3M1,
	C4M2,
	C4M3,
	C5M2,
	C6M3,
	C7M3,
	C8M4,
	L4D_C8M4
}

/* =============================================================================================================== *
 *                                		 		 	Plugin Info													   *
 *================================================================================================================ */

public Plugin myinfo =
{
	name = "L4D Elevator Teleport",
	version = PLUGIN_VERSION,
	description = "Teleport Survivors To The Elevator After Time Passes",
	author = "alasfourom",
	url = "https://forums.alliedmods.net/showthread.php?t=338961"
}

/* =============================================================================================================== *
 *                     		 		 	 	Plugin Support L4D 1 & 2											   *
 *================================================================================================================ */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) g_bLeft4Dead2 = false;
	else if (test == Engine_Left4Dead2) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

/* =============================================================================================================== *
 *                     		 		 			 Plugin Start													   *
 *================================================================================================================ */

public void OnPluginStart()
{
	CreateConVar ("l4d_elevator_teleport_version", PLUGIN_VERSION, "L4D Elevator Teleport" ,FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_PluginEnable = CreateConVar("l4d_elevator_teleport_enable", "1.0", "启用电梯传送插件(0=禁用, 1=启用)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_TeleportTime = CreateConVar("l4d_elevator_teleport_time", "30.0", "设置电梯传送倒计时时间,达到零时将传送幸存者", FCVAR_NOTIFY);
	g_Cvar_MapsIncluded = CreateConVar("l4d_elevator_teleport_maps", "all", "插件将在这些地图中被激活,用逗号分隔(没有空格) (all=所有地图)", FCVAR_NOTIFY);
	g_Cvar_RescueClient = CreateConVar("l4d_elevator_teleport_entire", "1", "插件将传送所有幸存者,包括被控制的幸存者", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//AutoExecConfig (true, "Elevator_Teleport");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

/* =============================================================================================================== *
 *                                 			  Silver's Method From Lift Plugin									   *
 *================================================================================================================ */

public void OnMapStart()
{
	g_bLockedButtonPressed = false;
	g_bUnlockedButtonPressed = false;
	PrecacheSound(SOUND_COUNTDOWN);
	
	char sCurrentMap[32];
	char sMap[32];
	char sCvarMaps[512];
	
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	Format(sMap, sizeof(sMap), ",%s,", sCurrentMap);
	
	g_Cvar_MapsIncluded.GetString(sCvarMaps, sizeof(sCvarMaps));
	
	int entity = -1;
	
	g_iElevatorButton = -1;
	g_iMapType = 0;
	
	bool bValidTeleportMap = false;
	
	if (strcmp(sCvarMaps, "all", false) == 0) bValidTeleportMap = true;
	else
	{
		Format(sCvarMaps, sizeof(sCvarMaps), ",%s,", sCvarMaps);
		if(StrContains(sCvarMaps, sMap, false) != -1) bValidTeleportMap = true;
	}
	
	if (g_bLeft4Dead2 && bValidTeleportMap)
	{
		if (strcmp(sCurrentMap, "c1m1_hotel") == 0 && (entity = FindByClassTargetName("func_button", "elevator_button")) != -1)
		{
			g_iMapType = C1M1;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c1m4_atrium") == 0 && (entity = FindByClassTargetName("func_button", "button_elev_3rdfloor")) != -1)
		{
			g_iMapType = C1M4;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c3m1_plankcountry") == 0 && (entity = FindByClassTargetName("func_button", "ferry_tram_button")) != -1)
		{
			g_iMapType = C3M1;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c4m2_sugarmill_a") == 0 && (entity = FindByClassTargetName("func_button", "button_inelevator")) != -1)
		{
			g_iMapType = C4M2;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c4m3_sugarmill_b") == 0 && (entity = FindByClassTargetName("func_button", "button_inelevator")) != -1)
		{
			g_iMapType = C4M3;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c5m2_park") == 0 && (entity = FindByClassTargetName("trigger_multiple", "finale_decon_trigger")) != -1)
		{
			g_iMapType = C5M2;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnStartTouch", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnEntireTeamStartTouch", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c6m3_port") == 0 && (entity = FindByClassTargetName("func_button", "generator_elevator_button")) != -1)
		{
			g_iMapType = C6M3;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "c7m3_port") == 0 && (entity = FindByClassTargetName("func_button", "bridge_start_button")) != -1)
		{
			g_iMapType = C7M3;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
		
		else if (strcmp(sCurrentMap, "l4d_vs_hospital04_interior") == 0 || strcmp(sCurrentMap, "l4d_hospital04_interior") == 0
		|| strcmp(sCurrentMap, "c8m4_interior") == 0 && (entity = FindByClassTargetName("func_button", "elevator_button")) != -1)
		{
			g_iMapType = C8M4;
			g_iElevatorButton = EntIndexToEntRef(entity);
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
	}
	else
	{
		if (strcmp(sCurrentMap, "l4d_hospital04_interior") == 0 || strcmp(sCurrentMap, "l4d_vs_hospital04_interior") == 0 
		&& (entity = FindByClassTargetName("func_button", "elevator_button")) != -1 && bValidTeleportMap)
		{
			g_iMapType = L4D_C8M4;
			HookSingleEntityOutput(entity, "OnUseLocked", OnElevatorLocked);
			HookSingleEntityOutput(entity, "OnPressed", OnElevatorUnlocked);
		}
	}
}

/* =============================================================================================================== *
 *                     		 				 Round Start and Round End											   *
 *================================================================================================================ */

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	OnMapStart();
}

void EmitSoundToSurvivor(const char[] sample,
				 int entity = SOUND_FROM_PLAYER,
				 int channel = SNDCHAN_AUTO,
				 int level = SNDLEVEL_NORMAL,
				 int flags = SND_NOFLAGS,
				 float volume = SNDVOL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int speakerentity = -1,
				 const float origin[3] = NULL_VECTOR,
				 const float dir[3] = NULL_VECTOR,
				 bool updatePos = true,
				 float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			clients[total++] = i;
	}

	if (total) {
		EmitSound(clients, total, sample, entity, channel,
			level, flags, volume, pitch, speakerentity,
			origin, dir, updatePos, soundtime);
	}
}

/* =============================================================================================================== *
 *                     		 	 Activator: Pressing The Elevator Button While Locked							   *
 *================================================================================================================ */
 
void OnElevatorLocked(const char[] output, int caller, int activator, float delay)
{
	if (!g_Cvar_PluginEnable.BoolValue) return;
	
	else if (!g_bLockedButtonPressed && !g_bUnlockedButtonPressed) 
	{
		g_bLockedButtonPressed = true;
		g_fDuration = g_Cvar_TeleportTime.FloatValue;
		int time = RoundToNearest(g_fDuration);
		
		PrintHintTextToAll("%d 秒后传送未进入集合区域的生还者", time);
		CreateTimer (1.0, Timer_CountDown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/* =============================================================================================================== *
 *                     		 	Activator: Pressing The Elevator Button While Unlocked							   *
 *================================================================================================================ */
 
void OnElevatorUnlocked(const char[] output, int caller, int activator, float delay)
{
	if (!g_Cvar_PluginEnable.BoolValue) return;
	g_bUnlockedButtonPressed = true;
	PrintHintTextToAll("自动启动开关");
}

/* =============================================================================================================== *
 *                     				 	Timer: Countdown Before Teleporting										   *
 *================================================================================================================ */

Action Timer_CountDown(Handle timer)
{
	int timeleft = RoundToNearest(g_fDuration--);
	
	if (g_bUnlockedButtonPressed || !g_bLockedButtonPressed) return Plugin_Stop;
	
	else if (timeleft <= 0)
	{
		Release_HeldSurvivors();
		ReviveHangedSurvivors();
		Activate_ElevatorTeleport();
		return Plugin_Stop;
	}
	
	PrintHintTextToAll("%d 秒后传送未进入集合区域的生还者", timeleft);
	EmitSoundToSurvivor(SOUND_COUNTDOWN, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	return Plugin_Continue;
}

/* =============================================================================================================== *
 *             	 	Timer: After Countdown Reaches 0, Teleport Survivors and Unlock Elevator					   *
 *================================================================================================================ */
 
void Activate_ElevatorTeleport()
{
	float vPos[3];
	
	if (g_bLeft4Dead2)
	{
		if (g_iMapType == C1M1)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = 2171.0;
			vPos[1] = 5810.0; 
			vPos[2] = 2529.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C1M4)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = -4039.0;
			vPos[1] = -3402.0; 
			vPos[2] = 598.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
		}
		
		else if (g_iMapType == C3M1)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = -5246.0;
			vPos[1] = 6060.0; 
			vPos[2] = 50.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
		}
		
		else if (g_iMapType == C4M2)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = -1475.0;
			vPos[1] = -9558.0; 
			vPos[2] = 660.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C4M3)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = -1479.0;
			vPos[1] = -9558.0; 
			vPos[2] = 175.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C5M2)
		{
			int entity = -1;
			if ((entity = FindByClassTargetName("prop_door_rotating", "finale_cleanse_entrance_door")) != -1)
				AcceptEntityInput(entity, "close");
				
			if ((entity = FindByClassTargetName("prop_door_rotating", "finale_cleanse_exit_door")) != -1)
			{
				AcceptEntityInput(entity, "unlock");
				AcceptEntityInput(entity, "use");
			}
				
			vPos[0] = -9667.0;
			vPos[1] = -5970.0; 
			vPos[2] = -170.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C6M3)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = -744.0;
			vPos[1] = -575.0; 
			vPos[2] = 360.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C7M3)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
				AcceptEntityInput(g_iElevatorButton, "use");
			
			vPos[0] = 0.0;
			vPos[1] = -1730.0; 
			vPos[2] = 355.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
		
		else if (g_iMapType == C8M4)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(g_iElevatorButton, "unlock");
				AcceptEntityInput(g_iElevatorButton, "use");
			}
			
			vPos[0] = 13427.0;
			vPos[1] = 15225.0; 
			vPos[2] = 475.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
	}
	
	else 
	{
		if (g_iMapType == L4D_C8M4)
		{
			if (EntRefToEntIndex(g_iElevatorButton) != INVALID_ENT_REFERENCE)
				AcceptEntityInput(g_iElevatorButton, "unlock");
			
			vPos[0] = 13427.0;
			vPos[1] = 15225.0; 
			vPos[2] = 475.0;
			
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR); 
		}
	}
}

/* =============================================================================================================== *
 *                     					  		Release Held Players											   *
 *================================================================================================================ */

void Release_HeldSurvivors()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsRescueClientValid(i) && GetClientTeam(i) == 3)
		{
			if(GetEntProp(i, Prop_Send, "m_carryVictim", 1) || GetEntProp(i, Prop_Send, "m_pummelVictim", 1) ||
			GetEntProp(i, Prop_Send, "m_jockeyVictim ", 1)  || GetEntProp(i, Prop_Send, "m_pounceVictim", 1) ||
			GetEntProp(i, Prop_Send, "m_tongueVictim", 1)) ForcePlayerSuicide(i);
		}
	}
}

void ReviveHangedSurvivors()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsRescueClientValid(i) && GetClientTeam(i) == 2 && GetEntProp(i, Prop_Send, "m_isHangingFromLedge", 1))
		{
			int CmdFlags = GetCommandFlags("give");
			SetCommandFlags("give", CmdFlags & ~FCVAR_CHEAT);
			FakeClientCommand(i, "give health");
			SetCommandFlags("give", CmdFlags);
			
			int TempHealth = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
			int iMaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
			float fBuffer = (float(iMaxHealth) * 30.0) / 100.0;
			
			SetEntDataFloat(i, TempHealth, fBuffer, true);
			SetEntityHealth(i, 1);
		}
	}
}

bool IsRescueClientValid(int client)
{
	if (g_Cvar_RescueClient.BoolValue && client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) return true;
	return false;
}

/* =============================================================================================================== *
 *                     					  Silver's Method FindByClassTargetName									   *
 *================================================================================================================ */
 
int FindByClassTargetName(const char[] sClass, const char[] sTarget)
{
	char sName[64];
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, sClass)) != INVALID_ENT_REFERENCE)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
		if (strcmp(sTarget, sName) == 0) return entity;
	}
	return -1;
}
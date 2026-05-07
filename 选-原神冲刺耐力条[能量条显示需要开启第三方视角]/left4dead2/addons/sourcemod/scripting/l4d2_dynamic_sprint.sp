#define PLUGIN_VERSION		"1.0"
#define PLUGIN_NAME			"l4d2_dynamic_sprint"
#define PLUGIN_NAME_FULL	"[L4D2] Sprint with stamina bar"
#define PLUGIN_DESCRIPTION	"hold double tap move key to sprint. display dynamic stamina bar"
#define PLUGIN_AUTHOR		"yora"
#define PLUGIN_LINK			""

/*
	该插件的实现参考了 The implementation of this plugin refers to：
	[L4D1 & L4D2] HP Sprite                 https://forums.alliedmods.net/showthread.php?t=330370
	[L4D & L4D2] Costly Sprint / Dash v2.2  https://forums.alliedmods.net/showthread.php?t=340323	
*/

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define MAXENTITIES   2048
#define CVAR_FLAGS				FCVAR_NOTIFY
#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsAliveHumanSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2 && !IsFakeClient(%1) && IsPlayerAlive(%1))

bool bIsLeft4Dead2;
bool bLaggedMovementExists;
bool bLateLoad;

native any L4D_LaggedMovement(int client, float value, bool force = false);
forward Action L4D_OnGetWalkTopSpeed(int client, float &retVal);
native float L4D_GetTempHealth(int client);
forward Action L4D_OnGetRunTopSpeed(int target, float &retVal);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	bLateLoad = late;

	bIsLeft4Dead2 = GetEngineVersion() == Engine_Left4Dead2;

	MarkNativeAsOptional("L4D_LaggedMovement");
	MarkNativeAsOptional("L4D_GetTempHealth");

	return APLRes_Success;

}

public void OnLibraryAdded(const char[] name) {
	if (strcmp(name, "LaggedMovement") == 0) {
		bLaggedMovementExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if (strcmp(name, "LaggedMovement") == 0) {
		bLaggedMovementExists = false;
	}
}
public void OnAllPluginsLoaded() {
	// Require Left4DHooks
	if( !LibraryExists("left4dhooks") ) {
		LogMessage	("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
		SetFailState("\n==========\nError: You must install \"[L4D & L4D2] Left 4 DHooks Direct\" to run this plugin: https://forums.alliedmods.net/showthread.php?t=321696\n==========\n");
	}

	bLaggedMovementExists = LibraryExists("LaggedMovement");
}

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cAcheInterval;		float flAcheInterval;
ConVar cAcheAmount;			float flAcheAmount;
ConVar cAcheAdren;			bool bAcheAdren;
ConVar cLimp;				float flLimp;
ConVar cBoost;				float flBoost;
ConVar cSurvivorSpeed;		float flSurvivorSpeed;
ConVar cMode;				int iMode;
ConVar cTapinterval;		float flTapInterval;
ConVar cStaminaMax;			float flStaminaMax;
ConVar cStaminaPenaltyRate;	float flStaminaPenaltyRate;
ConVar cStaminaRecoveryRate;float flStaminaRecoveryRate;
ConVar g_hCvar_frame;
ConVar g_hCvar_Axis_X;
ConVar g_hCvar_Axis_Y;
ConVar g_hCvar_Axis_Z;
ConVar g_hCvar_AliveScale;
ConVar g_hCvar_CustomModelVMT;
ConVar g_hCvar_CustomModelVTF;

int g_fCvar_frame;
float g_fCvar_Axis_X;
float g_fCvar_Axis_Y;
float g_fCvar_Axis_Z;
float flMultiplierWalk;
float g_fCvar_AliveScale;
char g_sCvar_AliveScale[5];
int ge_iOwner[MAXENTITIES+1];
int gc_iSpriteEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
int gc_iSpriteFrameEntRef[MAXPLAYERS+1] = { INVALID_ENT_REFERENCE, ... };
char g_sCvar_CustomModelVMT[PLATFORM_MAX_PATH];
char g_sCvar_CustomModelVTF[PLATFORM_MAX_PATH];

public void OnPluginStart() {

	cAcheInterval =			CreateConVar("l4d2_ache_interval", "0.1",			"冲刺时耐力消耗的时间间隔（秒）", CVAR_FLAGS);
	cAcheAmount =			CreateConVar("l4d2_ache_amount", "1.0",				"冲刺时每个时间间隔消耗的耐力", CVAR_FLAGS);
	cAcheAdren =			CreateConVar("l4d2_ache_adren", "0",				"使用肾上腺素后是否仍消耗耐力（不建议修改）", CVAR_FLAGS);
	cLimp =					CreateConVar("l4d2_limp", "10.0",					"血量低于此值则无法冲刺", CVAR_FLAGS);
	cBoost =				CreateConVar("l4d2_boost", "1.6",					"冲刺的速度倍数", CVAR_FLAGS);
	cSurvivorSpeed =		FindConVar	("survivor_speed");
	cMode =					CreateConVar("l4d2_mode", "1",						"置0时更兼容，置1时更丝滑（冲刺时）", CVAR_FLAGS);
	cTapinterval =			CreateConVar("l4d2_tap_interval", "0.3",			"双击移动键按钮的时间间隔", CVAR_FLAGS);
	cStaminaMax =			CreateConVar("l4d2_stamina", "50.0",				"耐力值", CVAR_FLAGS);
	cStaminaPenaltyRate =	CreateConVar("l4d2_stamina_penalty_rate", "0.5",	"耗尽耐力的速度惩罚", CVAR_FLAGS);
	cStaminaRecoveryRate =	CreateConVar("l4d2_stamina_recovery_rate", "0.5",	"耐力值恢复速率", CVAR_FLAGS);
	g_hCvar_AliveScale =    CreateConVar("l4d2_sprite_alive_scale", "0.125",     "耐力条的大小", CVAR_FLAGS);
	g_hCvar_Axis_X =        CreateConVar("l4d2_sprite_X_axis", "15.0",           "耐力条离角色实体X轴的距离", CVAR_FLAGS);
	g_hCvar_Axis_Y =        CreateConVar("l4d2_sprite_Y_axis", "2.0",           "耐力条离角色实体Y轴的距离", CVAR_FLAGS);
	g_hCvar_Axis_Z =        CreateConVar("l4d2_sprite_Z_axis", "40.0",          "耐力条离角色实体Z轴的距离", CVAR_FLAGS);
	g_hCvar_frame  =        CreateConVar("l4d2_sprite_frame", "50.0",           "耐力条vtf有多少帧", CVAR_FLAGS);
	g_hCvar_CustomModelVMT= CreateConVar("l4d2_custom_model_vmt",               "materials/sprint/sprint_custombar.vmt", "耐力条vmt位置");
	g_hCvar_CustomModelVTF= CreateConVar("l4d2_custom_model_vtf",               "materials/sprint/sprint_custombar.vtf", "耐力条vtf位置");

	AutoExecConfig(true, PLUGIN_NAME);

	cAcheInterval.AddChangeHook(OnConVarChanged);
	cAcheAmount.AddChangeHook(OnConVarChanged);
	cAcheAdren.AddChangeHook(OnConVarChanged);
	cLimp.AddChangeHook(OnConVarChanged);
	cBoost.AddChangeHook(OnConVarChanged);
	cSurvivorSpeed.AddChangeHook(OnConVarChanged);
	cMode.AddChangeHook(OnConVarChanged);
	cTapinterval.AddChangeHook(OnConVarChanged);
	cStaminaMax.AddChangeHook(OnConVarChanged);
	cStaminaPenaltyRate.AddChangeHook(OnConVarChanged);
	cStaminaRecoveryRate.AddChangeHook(OnConVarChanged);
	g_hCvar_AliveScale.AddChangeHook(OnConVarChanged);
	g_hCvar_Axis_X.AddChangeHook(OnConVarChanged);
	g_hCvar_Axis_Y.AddChangeHook(OnConVarChanged);
	g_hCvar_Axis_Z.AddChangeHook(OnConVarChanged);
	g_hCvar_frame.AddChangeHook(OnConVarChanged);
	g_hCvar_CustomModelVMT.AddChangeHook(OnConVarChanged);
	g_hCvar_CustomModelVTF.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	// lateload
	if (bLateLoad) {
		for (int client = 1; client <= MaxClients; client++)
			if (IsClientInGame(client))
				OnClientPutInServer(client);
	}
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

void ApplyCvars() {

	flAcheInterval = cAcheInterval.FloatValue;
	flAcheAmount = cAcheAmount.FloatValue;
	bAcheAdren = cAcheAdren.BoolValue;
	flLimp = cLimp.FloatValue;
	flSurvivorSpeed = cSurvivorSpeed.FloatValue;
	flBoost = cBoost.FloatValue
	g_fCvar_Axis_X = g_hCvar_Axis_X.FloatValue;
	g_fCvar_Axis_Y = g_hCvar_Axis_Y.FloatValue;
	g_fCvar_Axis_Z = g_hCvar_Axis_Z.FloatValue;
	g_fCvar_frame =  g_hCvar_frame.IntValue;
	g_fCvar_AliveScale = g_hCvar_AliveScale.FloatValue;
	FloatToString(g_fCvar_AliveScale, g_sCvar_AliveScale, sizeof(g_sCvar_AliveScale));
	flMultiplierWalk = flSurvivorSpeed / 85.0;
	// walking 85, crouch 75
	iMode = cMode.IntValue;
	flTapInterval = cTapinterval.FloatValue;

	flStaminaMax = cStaminaMax.FloatValue;
	flStaminaPenaltyRate = cStaminaPenaltyRate.FloatValue;
	flStaminaRecoveryRate = cStaminaRecoveryRate.FloatValue;

	g_hCvar_CustomModelVMT.GetString(g_sCvar_CustomModelVMT, sizeof(g_sCvar_CustomModelVMT));
	TrimString(g_sCvar_CustomModelVMT);
	g_hCvar_CustomModelVTF.GetString(g_sCvar_CustomModelVTF, sizeof(g_sCvar_CustomModelVTF));
	TrimString(g_sCvar_CustomModelVTF);
	
	AddFileToDownloadsTable(g_sCvar_CustomModelVMT);
	AddFileToDownloadsTable(g_sCvar_CustomModelVTF);
	PrecacheModel(g_sCvar_CustomModelVMT, true);
	
}
 
bool bBoostActivated [MAXPLAYERS + 1];
int iButtonsLast [MAXPLAYERS + 1];
bool bStaminaPenalty [MAXPLAYERS + 1]
float flStamina [MAXPLAYERS + 1];
Handle timer[MAXPLAYERS + 1];

public Action L4D_OnGetWalkTopSpeed(int client, float &retVal) {

	if (bStaminaPenalty[client])
		return Plugin_Continue;

	if (bBoostActivated[client]) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// Fix movement speed bug when jumping or staggering
		if( iMode == 1 && GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 ) {
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 ) {
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return Plugin_Continue;
		}
		// ==========

		if (flLimp && GetClientHealth(client) + L4D_GetTempHealth(client) < flLimp && !(bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive")))

			StopDash(client);

		else {

			switch (iMode) {
				case 0 : {
					retVal *= flMultiplierWalk * flBoost;
					return Plugin_Handled;
				}
				case 1 : {
					SetTerrorMovement(client, flMultiplierWalk * flBoost);
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action L4D_OnGetRunTopSpeed(int client, float &retVal) {

	if (bStaminaPenalty[client]) {
	
		if(GetEntProp(client, Prop_Send, "m_bAdrenalineActive"))
		{
			SetTerrorMovement(client, 1.0);
			bStaminaPenalty[client] = false;
			return Plugin_Continue;
		}		
		SetTerrorMovement(client, flStaminaPenaltyRate);
		return Plugin_Continue;
	}

	if (bBoostActivated[client] && !(iButtonsLast[client] & IN_SPEED)) {

		// ==========
		// Code taken from "Weapons Movement Speed" by "Silvers"
		// Fix movement speed bug when jumping or staggering
		if( iMode == 1 && GetEntProp(client, Prop_Send, "m_hGroundEntity") == -1 || GetEntPropFloat(client, Prop_Send, "m_staggerTimer", 1) > -1.0 ) {
			// Fix jumping resetting velocity to default
			float value = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
			if( value != 1.0 ) {
				float vVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVec);
				float height = vVec[2];

				ScaleVector(vVec, value);
				vVec[2] = height; // Maintain default jump height

				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVec);
			}

			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(client, 1.0, true) : 1.0);
			return Plugin_Continue;
		}
		// ==========


		if (flLimp && GetClientHealth(client) + L4D_GetTempHealth(client) < flLimp && !(bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive")))

			StopDash(client);

		else {

			switch (iMode) {
				case 0 : {
					retVal *= flBoost;
					return Plugin_Handled;
				}
				case 1 : {
					SetTerrorMovement(client, flBoost);
				}
			}
		}
	}

	return Plugin_Continue;
}

void SetTerrorMovement(int entity, float rate) {
	SetEntPropFloat(entity, Prop_Send, "m_flLaggedMovementValue", bLaggedMovementExists ? L4D_LaggedMovement(entity, rate) : rate);
}

public void OnClientPutInServer(int client) {
	flStamina[client] = flStaminaMax;
	bBoostActivated[client] = false;
	bStaminaPenalty[client] = false;
	iButtonsLast[client] = 0;
	if (timer[client]) 
		delete timer[client];
}

public void OnClientDisconnect_Post(int client) {
	iButtonsLast[client] = 0;
	if (timer[client])
		delete timer[client];
	gc_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
	gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
}

public void OnMapStart() {
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			flStamina[client] = flStaminaMax;
			bBoostActivated[client] = false;
			bStaminaPenalty[client] = false;
			iButtonsLast[client] = 0;
			if (timer[client])
				delete timer[client];
		}
	}
}

public void OnPluginEnd()
{
    int entity;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (gc_iSpriteEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iSpriteEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
        }

        if (gc_iSpriteFrameEntRef[client] != INVALID_ENT_REFERENCE)
        {
            entity = EntRefToEntIndex(gc_iSpriteFrameEntRef[client]);

            if (entity != INVALID_ENT_REFERENCE)
                AcceptEntityInput(entity, "Kill");

            gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
        }
    }
}

bool TryDash(int client) {

	if (!bStaminaPenalty[client] && !bBoostActivated[client]) {
		
		int health = GetClientHealth(client);
		float temp = L4D_GetTempHealth(client);

		if (health + temp > flLimp) {
			
			bBoostActivated[client] = true;

			if (!timer[client])
				timer[client] = CreateTimer(flAcheInterval, TimerStamina, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			return true;
		}
	}

	return false;
}

void StopDash(int client) {
	
	bBoostActivated[client] = false;

	if (timer[client] && flStaminaMax <= 0)
		delete timer[client];

	if (iMode == 1)
		SetTerrorMovement(client, 1.0);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	if (IsAliveHumanSurvivor(client) && !bStaminaPenalty[client]) {

		bool moved_left = buttons & IN_MOVELEFT && !(iButtonsLast[client] & IN_MOVELEFT),
			 moved_right = buttons & IN_MOVERIGHT && !(iButtonsLast[client] & IN_MOVERIGHT),
			 moved_forward = buttons & IN_FORWARD && !(iButtonsLast[client] & IN_FORWARD),
			 moved_back = buttons & IN_BACK && !(iButtonsLast[client] & IN_BACK);

		static float moved_last_left [MAXPLAYERS + 1],
					 moved_last_right [MAXPLAYERS + 1],
					 moved_last_forward [MAXPLAYERS + 1],
					 moved_last_back [MAXPLAYERS + 1];

		float time = GetEngineTime();

		if ( !(iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) &&
			 (
				(moved_left && time - moved_last_left[client] < flTapInterval) || 
				 (moved_right && time - moved_last_right[client] < flTapInterval) ||
				 (moved_forward && time - moved_last_forward[client] < flTapInterval) ||
				 (moved_back && time - moved_last_back[client] < flTapInterval)
			 )) 
		{
			TryDash(client);
		}

		if ( !(buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) && iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) )
			StopDash(client);

		if (moved_left)
			moved_last_left[client] = time;

		if (moved_right)
			moved_last_right[client] = time;

		if (moved_forward)
			moved_last_forward[client] = time;

		if (moved_back)
			moved_last_back[client] = time;
	}

	iButtonsLast[client] = buttons;
}

Action TimerStamina(Handle self, int client) {

	client = GetClientOfUserId(client);

	if (IsAliveHumanSurvivor(client)) {
		int moving = iButtonsLast[client] & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT);

		// actived stamina mode
		if (flStaminaMax > 0) {

			// has stamina and not during penalty
			if (flStamina[client] >= 0 && !bStaminaPenalty[client] && moving && bBoostActivated[client]) {

				if (bIsLeft4Dead2 && !bAcheAdren && GetEntProp(client, Prop_Send, "m_bAdrenalineActive"))
					return Plugin_Continue;

				// reduce stamina
				flStamina[client] -= flAcheAmount;
				DisplayStamina(client);

				return Plugin_Continue;
			}
			// not enough stamina or during penalty
			if (flStamina[client] < 0 && !bStaminaPenalty[client]) {

				// using Adrenaline
				if(GetEntProp(client, Prop_Send, "m_bAdrenalineActive")){
					
					bBoostActivated[client] = true;
					bStaminaPenalty[client] = false;					
					return Plugin_Continue;
				}

				// enter penalty if not yet 
				bBoostActivated[client] = false;
				bStaminaPenalty[client] = true;
					
				return Plugin_Continue;

			} else if (flStamina[client] < flStaminaMax) {

				// recovery stamina
				flStamina[client] += flAcheAmount * flStaminaRecoveryRate;
				DisplayStamina(client);

				// stop recovery when stamina fulled, and cancel penalty
				if (flStamina[client] >= flStaminaMax) {

					flStamina[client] = flStaminaMax;

					bStaminaPenalty[client] = false;

					timer[client] = null;
					
					KillSprite(client);

					if (iMode == 1)
						SetTerrorMovement(client, 1.0);

					return Plugin_Stop;

				} else

					return Plugin_Continue;
			}
		}
	}

	flStamina[client] = flStaminaMax;
	bBoostActivated[client] = false;
	bStaminaPenalty[client] = false;
	timer[client] = null;
	return Plugin_Stop;
}

void DisplayStamina(int client) {  
	char targetname[17];
	FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_sprint_sprite", client);

	int entity = INVALID_ENT_REFERENCE;

	if (gc_iSpriteEntRef[client] != INVALID_ENT_REFERENCE)
		entity = EntRefToEntIndex(gc_iSpriteEntRef[client]);

	if (entity == INVALID_ENT_REFERENCE)
	{
		float targetPos[3];
		GetClientAbsOrigin(client, targetPos);
		
		float angles[3];
		GetClientAbsAngles(client, angles);
		
		// Convert angles to radians
		float rad = DegToRad(angles[1]);
		
		// Calculate the offset for the right side
		float offsetX = g_fCvar_Axis_Y * Cosine(rad) + g_fCvar_Axis_X * Sine(rad);
		float offsetY = g_fCvar_Axis_Y * Sine(rad) - g_fCvar_Axis_X * Cosine(rad);
		
		targetPos[0] += offsetX;
		targetPos[1] += offsetY;
		targetPos[2] += g_fCvar_Axis_Z;

		entity = CreateEntityByName("env_sprite");
		gc_iSpriteEntRef[client] = EntIndexToEntRef(entity);
		ge_iOwner[entity] = client;
		DispatchKeyValue(entity, "targetname", targetname);
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValueVector(entity, "origin", targetPos);
	}

	DispatchKeyValue(entity, "model", g_sCvar_CustomModelVMT);
	DispatchKeyValue(entity, "scale", g_sCvar_AliveScale);
	DispatchSpawn(entity);

	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	AcceptEntityInput(entity, "ShowSprite");

	int entityFrame = INVALID_ENT_REFERENCE;

	if (gc_iSpriteFrameEntRef[client] != INVALID_ENT_REFERENCE)
		entityFrame = EntRefToEntIndex(gc_iSpriteFrameEntRef[client]);

	if (entityFrame == INVALID_ENT_REFERENCE)
	{
		entityFrame = CreateEntityByName("env_texturetoggle");
		gc_iSpriteFrameEntRef[client] = EntIndexToEntRef(entityFrame);
		DispatchKeyValue(entityFrame, "targetname", targetname);
		DispatchKeyValue(entityFrame, "target", targetname);
		DispatchSpawn(entityFrame);

		SetVariantString("!activator");
		AcceptEntityInput(entityFrame, "SetParent", entity);
	}

	float staminaRatio = flStamina[client] / flStaminaMax;
	int frame = RoundFloat(staminaRatio * g_fCvar_frame);

	char input[38];
	FormatEx(input, sizeof(input), "OnUser1 !self:SetTextureIndex:%i:0:1", frame);
	SetVariantString(input);
	AcceptEntityInput(entityFrame, "AddOutput");
	AcceptEntityInput(entityFrame, "FireUser1");
}

void KillSprite(int client)
{
    if (gc_iSpriteFrameEntRef[client] != INVALID_ENT_REFERENCE)
    {
        int entityFrame = EntRefToEntIndex(gc_iSpriteFrameEntRef[client]);

        if (entityFrame != INVALID_ENT_REFERENCE)
            AcceptEntityInput(entityFrame, "Kill");

        gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
    }

    if (gc_iSpriteEntRef[client] == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(gc_iSpriteEntRef[client]);

    if (entity != INVALID_ENT_REFERENCE)
        AcceptEntityInput(entity, "Kill");

    gc_iSpriteEntRef[client] = INVALID_ENT_REFERENCE;
    gc_iSpriteFrameEntRef[client] = INVALID_ENT_REFERENCE;
}
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1"

char g_aGraveModels[][] = {
	// graves
	"models/props_cemetery/grave_07.mdl",

	"models/props_cemetery/gibs/grave_07a_gibs.mdl",
	"models/props_cemetery/gibs/grave_07b_gibs.mdl",
	"models/props_cemetery/gibs/grave_07c_gibs.mdl",
	"models/props_cemetery/gibs/grave_07d_gibs.mdl",
	"models/props_cemetery/gibs/grave_07e_gibs.mdl",
	"models/props_cemetery/gibs/grave_07f_gibs.mdl"
};
char g_candy[][] = {
	"models/lighthouse/candle.mdl",
	"models/lighthouse/candle_fire.mdl"
};

//userinfo
int grave[MAXPLAYERS + 1] = {0, ...};
int IsGraveNum[MAXPLAYERS + 1];
int respawnCount[MAXPLAYERS + 1] = {0, ...};//重生次数
//复活
#define GAMEDATA	"L4D2_GraveKiller"
Handle g_hSDKRoundRespawn,g_hSDKGoAwayFromKeyboard;
Address g_pStatsCondition;
//cvar
Handle CvarWitchPercent, CvarButtonDelayTimer, CvarRespawnCount, CvarGraveGlowColor;

public Plugin myinfo =
{
	name = "刨祖坟",
	author = "CD意识(kazya3) && ヾ藤野深月ゞ",
	description = "你我皆是摸金校尉",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("L4D2_GraveKiller_Version", PLUGIN_VERSION, "当前 刨祖坟 插件版本");
	CvarWitchPercent			=	CreateConVar("L4D2_GraveKiller_WitchPercent", 			"30",							"设置刨祖坟转化Witch的几率 [0=禁用]", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	CvarButtonDelayTimer	=	CreateConVar("L4D2_GraveKiller_ButtonDelayTimer", 	"10.0",						"设置刨祖坟所需的时间 [0=禁用]", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	CvarRespawnCount			=	CreateConVar("L4D2_GraveKiller_RespawnCount", 			"1",							"设置刨祖坟能复活的次数 [0=禁用]", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	CvarGraveGlowColor		=	CreateConVar("L4D2_GraveKiller_GraveGlowColor", 		"255 255 255",		"设置玩家死亡后产生的墓碑光环轮廓");
	vLoadGameData();
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	/* 生成CFG */
	AutoExecConfig(true, GAMEDATA);
}

public void OnMapStart()
{
	//载入模型缓存
	PrecacheModel("sprites/glow03.vmt", true);
	for ( int i = 0; i < sizeof(g_aGraveModels); i++ )
		PrecacheModel(g_aGraveModels[i]);
	for ( int i = 0; i < sizeof(g_candy); i++ )
		PrecacheModel(g_candy[i]);
}

//public OnClientConnected(Client)
public OnClientPutInServer(Client)
{
	if (IsClientConnected(Client) || IsClientInGame(Client))
	{
		grave[Client] = 0;
		IsGraveNum[Client] = 0;
		respawnCount[Client] = GetConVarInt(CvarRespawnCount);
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontbroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (isSurvivor(i))
		{
			grave[i] = 0;
			IsGraveNum[i] = 0;
			respawnCount[i] = GetConVarInt(CvarRespawnCount);
		}
	}
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (isSurvivor(victim) && IsGraveNum[victim] != 0)
	{
		int graveIndex = EntIndexToEntRef(IsGraveNum[victim]);
		if ( IsValidEntity(graveIndex) )
		{
			AcceptEntityInput(graveIndex, "Kill");
			grave[victim] = 0;
			IsGraveNum[victim] = 0;
		}
	}
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (isSurvivor(victim) && respawnCount[victim] > 0)
	{
		float origin[3];
		GetClientAbsOrigin(victim, origin);
		grave[victim] =  CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(grave[victim], "model", "models/props_cemetery/grave_07.mdl");
		// DispatchKeyValue(grave[victim], "health", "500");
		DispatchKeyValue(grave[victim], "solid", "0");
		DispatchSpawn(grave[victim]);
		IsGraveNum[victim] = grave[victim];
		TeleportEntity(grave[victim], origin, NULL_VECTOR, NULL_VECTOR);
		// PrintToChatAll("grave: %d client: %d", grave[victim], victim);
		//button
		int buttonIndex =  CreateEntityByName("func_button_timed");
		DispatchSpawn(buttonIndex);
		char UseTimer[16], Colors[56];
		Format(UseTimer, sizeof(UseTimer), "%f", GetConVarFloat(CvarButtonDelayTimer));
		DispatchKeyValue(buttonIndex, "use_time", UseTimer);
		//设置光环轮廓
		DispatchKeyValue(grave[victim], "glowrange", "0");
		DispatchKeyValue(grave[victim], "glowrangemin", "190");
		GetConVarString(CvarGraveGlowColor, Colors, sizeof(Colors));
		DispatchKeyValue(grave[victim], "glowcolor", Colors);
		AcceptEntityInput(grave[victim], "StartGlowing");
		//光环轮廓END
		DispatchKeyValue(buttonIndex, "auto_disable", "0");
		origin[2] += 42;
		TeleportEntity(buttonIndex, origin, NULL_VECTOR, NULL_VECTOR);
		SetEntPropVector(buttonIndex, Prop_Send, "m_vecMins", {16.0, 16.0, 22.0});
		SetEntPropVector(buttonIndex, Prop_Send, "m_vecMaxs", {-16.0, -16.0, -42.0});
		SetEntProp(buttonIndex, Prop_Send, "m_nSolidType", 2);
		SetEntPropEnt(buttonIndex, Prop_Send, "m_hOwnerEntity", grave[victim]);
		SetVariantString("!activator");
		AcceptEntityInput(buttonIndex, "SetParent", grave[victim]);
		SetVariantString("OnTimeUp !self:Lock::0.0:-1");
		AcceptEntityInput(buttonIndex, "AddOutput");
		SetVariantString("OnTimeUp !self:Unlock::1.0:-1");
		AcceptEntityInput(buttonIndex, "AddOutput");
		HookSingleEntityOutput(buttonIndex, "OnTimeUp", ButtonPress)
		//candy
		float origin2[3];
		GetClientAbsOrigin(victim, origin2);
		int candyIndex =  CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(candyIndex, "model", g_candy[0]);
		DispatchKeyValue(candyIndex, "solid", "0");
		DispatchSpawn(candyIndex);
		origin2[0] += 20;
		TeleportEntity(candyIndex, origin2, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(candyIndex, Prop_Send, "m_hOwnerEntity", grave[victim]);
		SetVariantString("!activator");
		AcceptEntityInput(candyIndex, "SetParent", grave[victim]);
		//candyFire
		int candyFireIndex =  CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(candyFireIndex, "model", "models/lighthouse/candle_fire.mdl");
		DispatchKeyValue(candyFireIndex, "solid", "0");
		DispatchSpawn(candyFireIndex);
		origin2[2] += 9;
		TeleportEntity(candyFireIndex, origin2, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(candyFireIndex, Prop_Send, "m_hOwnerEntity", candyIndex);
		SetVariantString("!activator");
		AcceptEntityInput(candyFireIndex, "SetParent", candyIndex);
		//sprite
		int sprite = CreateEntityByName("env_sprite");
		DispatchKeyValueVector(sprite, "origin", origin2);
		DispatchKeyValue(sprite, "model", "sprites/glow03.vmt");
		DispatchKeyValue(sprite, "rendermode", "9");
		DispatchKeyValue(sprite, "scale", "0.25");
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "GlowProxySize", "6");
		DispatchKeyValue(sprite, "HDRColorScale", ".5");
		DispatchKeyValue(sprite, "renderamt", "200");
		DispatchSpawn(sprite);
		SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", candyIndex);
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", candyIndex);
		SetVariantString("235 141 109");
		AcceptEntityInput(sprite, "Color");
		//light_dy
		// int light = CreateEntityByName("light_dynamic");
		// DispatchKeyValue(light, "_light", "219 113 43 15");
		// DispatchKeyValue(light, "brightness", "3");
		// DispatchKeyValueFloat(light, "spotlight_radius", 32.0);
		// DispatchKeyValueFloat(light, "distance", 5.0);
		// DispatchKeyValue(light, "style", "5");
		// DispatchSpawn(light);
		// TeleportEntity(light, origin2, NULL_VECTOR, NULL_VECTOR);
		// SetEntPropEnt(light, Prop_Send, "m_hOwnerEntity", candyIndex);
		// SetVariantString("!activator");
		// AcceptEntityInput(light, "SetParent", candyIndex);
		// AcceptEntityInput(light, "TurnOn");

		DataPack pack;
		CreateDataTimer(1.0, Timer_RemoveGrave, pack, TIMER_REPEAT);
		pack.WriteCell(victim);
		pack.WriteCell(EntIndexToEntRef(grave[victim]));
	}
	return Plugin_Handled;
}

public ButtonPress(const char[] name, caller, activator, float delay)
{
	// PrintToChatAll("按钮按下..");
	if(!IsValidEntity(caller) || !IsValidEntity(activator)){return;}
	char targetname[128];
	GetEdictClassname(activator, targetname, sizeof(targetname));
	if(!StrEqual(targetname,"player")){return;}
	// PrintToChatAll("按钮检测成功..");
	int graveIndex = GetEntPropEnt(caller, Prop_Data, "m_hMoveParent")
	if(!IsValidEntity(graveIndex)){return;}
	int client;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(grave[i] == 0) continue;
		if(grave[i] == graveIndex) client = i;
	}
	// PrintToChatAll("grave:%d client:%d", graveIndex, client);
	//respawn
	float VecOrigin[3], VecAngles[3];
	GetEntPropVector(graveIndex, Prop_Send, "m_vecOrigin", VecOrigin);
	GetEntPropVector(graveIndex, Prop_Send, "m_angRotation", VecAngles);

	int witchPercent = GetConVarInt(CvarWitchPercent),
		ItemNum = GetRandomInt(0, 100);
	int ent = -1;
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && !IsPlayerAlive(client))
	{
		respawnCount[client] --;
		IsGraveNum[client] = 0;
		if(ItemNum < witchPercent)
		{
			//生成witch并传送
			ent = CreateEntityByName("witch");
			if (ent == -1) return;
			TeleportEntity(ent, VecOrigin, VecAngles, NULL_VECTOR);
			DispatchSpawn(ent);
			//SetRemoveGrave(client);
			// SetEntityRenderColor(ent, 0, 0, 0, 255);// 染色
			PrintToChatAll("\x04%N \x03倒斗失败!\n\x04%N \x03戾气过重诈尸成了\x04非洲野婊子!", activator, client);
		}
		else
		{
			vRoundRespawn(client);
			TeleportEntity(client, VecOrigin, NULL_VECTOR, NULL_VECTOR);
			//SetRemoveGrave(client);
			PrintHintText(client, "剩余重生次数: %d", respawnCount[client]);
			PrintToChatAll("\x04%N \x03坟头蹦迪还偷吃贡品! 活活气醒了 \x04%N !", activator, client);
		}
	}
}

public Action Timer_RemoveGrave(Handle timer, DataPack entities)
{
	entities.Reset();
	int client = entities.ReadCell();
	int graveIndex = EntRefToEntIndex(entities.ReadCell());
	//   修改原版未复活不删除墓碑
	//if ( !IsClientConnected(client) || !IsClientInGame(client) || IsPlayerAlive(client) )
	if ( !IsClientConnected(client) || !IsClientInGame(client) || respawnCount[client] <= 0)
	{
		if ( IsValidEntity(graveIndex) )
		{
			AcceptEntityInput(graveIndex, "Kill");
			grave[client] = 0;
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
/*********************************************************************
*
*								去除尸体
*
*********************************************************************/
public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntityIndex(entity)){return;}
	switch (classname[0])
	{
		case 's':
		{
			if (strcmp(classname , "survivor_death_model") == 0)
			{
				RequestFrame (OnNextFrame, EntIndexToEntRef(entity));
			}
		}
	}
}

public void OnNextFrame(int entityRef)
{
	int entity = EntRefToEntIndex(entityRef);
	if (entity == INVALID_ENT_REFERENCE) return;
	AcceptEntityInput(entity, "kill");
}

// public void L4D2_OnSurvivorDeathModelCreated(int iClient, int iDeathModel)
// {
//	 AcceptEntityInput(iDeathModel, "kill");
//	 // RemoveEntity(iDeathModel);
// }
/*********************************************************************
*
*								复活相关
*
*********************************************************************/
void vRoundRespawn(int client)
{
	vStatsConditionPatch(true);
	SDKCall(g_hSDKRoundRespawn, client);
	vStatsConditionPatch(false);
}

//https://forums.alliedmods.net/showthread.php?t=323220
void vStatsConditionPatch(bool bPatch)
{
	static bool bPatched;
	if(!bPatched && bPatch)
	{
		bPatched = true;
		StoreToAddress(g_pStatsCondition, 0x79, NumberType_Int8);
	}
	else if(bPatched && !bPatch)
	{
		bPatched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
	g_hSDKRoundRespawn = EndPrepSDKCall();
	if(g_hSDKRoundRespawn == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::GoAwayFromKeyboard");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKGoAwayFromKeyboard = EndPrepSDKCall();
	if(g_hSDKGoAwayFromKeyboard == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::GoAwayFromKeyboard");

	vRegisterStatsConditionPatch(hGameData);

	delete hGameData;
}

void vRegisterStatsConditionPatch(GameData hGameData = null)
{
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if(iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if(iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	g_pStatsCondition = hGameData.GetAddress("CTerrorPlayer::RoundRespawn");
	if(!g_pStatsCondition)
		SetFailState("Failed to find address: CTerrorPlayer::RoundRespawn");

	g_pStatsCondition += view_as<Address>(iOffset);

	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if(iByteOrigin != iByteMatch)
		SetFailState("Failed to load 'CTerrorPlayer::RoundRespawn', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}
/*********************************************************************
*
*								stock
*
*********************************************************************/
stock bool IsValidEntityIndex(int entity)
{
	return (MaxClients+1 <= entity <= GetMaxEntities());
}
stock bool isAliveSurvivor(int client)
{
	return isSurvivor(client) && IsPlayerAlive(client);
}
stock bool isSurvivor(int client)
{
	return isClientValid(client) && GetClientTeam(client) == 2;
}
stock bool isClientValid(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	// if (IsFakeClient(client)) return false;
	return true;
}
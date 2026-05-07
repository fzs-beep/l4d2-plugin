#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

#define RGB_RED 	 {255,0,0}
#define RGB_GREEN	 {0,255,0}

new Handle:TankHealthHUD;
new Handle:TankHUDTimer;
new String:Message[128];

public Plugin:myinfo =
{
	name = "[L4D2]Tank HUD血量显示",
	description = "感染者HUD血量显示",
	author = "藤野深月",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	/* 插件参数 */
	CreateConVar("L4D2_TankHealthHUD_Version", PLUGIN_VERSION, "[L4D2]Tank HUD血量显示 插件版本");
	
	TankHealthHUD = CreateConVar("L4D2_TankHealth_HUD", "1", 	 "显示Tank血量HUD提示(需要打开游戏提示)[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	TankHUDTimer 	= CreateConVar("L4D2_TankHUD_Timer", 	"0.5", "Tank血量HUD多久后消失？(不攻击情况下)[0=立刻消失]", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	/*
	HookEvent("tank_spawn",  Event_Tank_Spawn);
	HookEvent("tank_killed", Event_Tank_killed);
	*/
	/* 创建Config */
	AutoExecConfig(true, "L4D2_TankHealthHUD");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClient(victim) && GetClientTeam(victim) == 3)
	{
		if (GetEntProp(victim, Prop_Send, "m_zombieClass") == 8 && GetConVarInt(TankHealthHUD) == 1)// && TankHUDNumber == 0)
		{
			if (!IsPlayerIncapped(victim))
			{
				new health = GetEntProp(victim, Prop_Data, "m_iHealth");
				Format(Message, sizeof(Message), "%d", health);
				DisplayInstructorHint(victim, 0.0, 60.0, 800.0, true, false, "icon_skull", "", "", false, RGB_RED, Message);
			}else
			{
				Format(Message, sizeof(Message), "我日啊！！我一定会再回来的！");
				DisplayInstructorHint(victim, 0.0, 60.0, 800.0, true, false, "icon_skull", "", "", false, RGB_GREEN, Message);
			}
		}
	}
}

/* 提示参数 */
stock void DisplayInstructorHint(int target, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char[] sText)
{
	int entity =  CreateEntityByName("env_instructor_hint");
	static char sBuffer[32];
	float vPos[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
	DispatchKeyValueVector(entity, "origin", vPos);
	GetEntPropString(target, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));
	if(strlen(sBuffer) == 0)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "targethint%d", target);
		DispatchKeyValue(target, "targetname", sBuffer);
	}
	DispatchKeyValue(entity, "hint_target", sBuffer);
	DispatchKeyValue(entity, "hint_name", sBuffer);
	DispatchKeyValue(entity, "hint_replace_key", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(entity, "hint_static", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));
	DispatchKeyValue(entity, "hint_timeout", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(entity, "hint_icon_offset", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(entity, "hint_range", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(entity, "hint_nooffscreen", sBuffer);
	DispatchKeyValue(entity, "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(entity, "hint_icon_offscreen", sIconOffScreen);
	DispatchKeyValue(entity, "hint_binding", sCmd);
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(entity, "hint_forcecaption", sBuffer);
	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(entity, "hint_color", sBuffer);
	DispatchKeyValue(entity, "hint_caption", sText);
	DispatchKeyValue(entity, "hint_activator_caption", sText);
	DispatchKeyValue(entity, "hint_flags", "0");
	DispatchKeyValue(entity, "hint_display_limit", "0");
	DispatchKeyValue(entity, "hint_suppress_rest", "1");// no show in face
	DispatchKeyValue(entity, "hint_auto_start", "1");
	DispatchKeyValue(entity, "hint_allow_nodraw_target", "true");
	DispatchKeyValue(entity, "hint_instance_type", "2");//2
	DispatchSpawn(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target, entity);
	AcceptEntityInput(entity, "ShowHint");
	
	if (IsValidEntRef(entity))
		CreateTimer(GetConVarFloat(TankHUDTimer), RemoveInstructorHint, entity);
}

public Action:RemoveInstructorHint(Handle:h_Timer, any:entity)
{
	if (IsValidEntRef(entity))
	{
		AcceptEntityInput(entity, "stop");
		AcceptEntityInput(entity, "kill");
		RemoveEdict(entity);
	}
}

/* 其他参数 */
bool:IsValidClient(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool:IsValidEntRef(iEntRef)
{
	static iEntity;
	iEntity = EntRefToEntIndex(iEntRef);
	return iEntRef && iEntity != -1 && IsValidEntity(iEntity);
}

stock bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated") > 0)
		return true;
	else
		return false;
}

/* Hook 
public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(Client))
	{
		CreateHintEntity(Client);
	}
}

public Action:Event_Tank_killed(Event:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(Client))
	{
		DestroyHintEntity(Client);
	}
}
*/

/*
CreateHintEntity(Client)
{
	if (IsValidClient(Client))
	{
		new HintEnt = CreateEntityByName("env_instructor_hint");
		if (HintEnt == -1) return;
		DispatchSpawn(HintEnt);
		if (IsValidEntRef(HintEnt))
		{
			AcceptEntityInput(HintEnt, "Kill");
			HintEnt = -1;
		}
		HintEnt = EntIndexToEntRef(HintEnt);
	}
}

DestroyHintEntity(Client)
{
	if (IsValidClient(Client))
	{
		new HintEnt = CreateEntityByName("env_instructor_hint");
		if (HintEnt == -1) return;
		if (IsValidEntRef(HintEnt))
		{
			AcceptEntityInput(HintEnt, "Kill");
			RemoveEdict(HintEnt);
			HintEnt = -1;
		}
		HintEnt = EntIndexToEntRef(HintEnt);
	}
}
*/

/********************************************************************************************

////////////////////////////////////////////////////
********************原版参考文本********************
////////////////////////////////////////////////////

new String:Message[128];
new HintIndex[2049];
new HintEntity[2049];
new ConVar:show_tank;
public Plugin:myinfo =
{
	name = "坦克|HUD显示血量",
	description = "Infected Hud",
	author = "MasterMind420，24の节气",
	version = "1.2.2",
	url = ""
};

void:DisplayInstructorHint(target, Float:fTime, Float:fHeight, Float:fRange, bool:bFollow, bool:bShowOffScreen, String:sIconOnScreen[], String:sIconOffScreen[], String:sCmd[], bool:bShowTextAlways, iColor[3], String:sText[128])
{
	if (!IsValidEntRef(target))
	{
		CreateHintEntity(target);
	}
	new String:sBuffer[128];
	FormatEx(sBuffer, 32, "si_%d", target);
	DispatchKeyValue(target, "targetname", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_target", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_name", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_replace_key", sBuffer);
	FormatEx(sBuffer, 32, "%d", !bFollow);
	DispatchKeyValue(target << 2 + 10596, "hint_static", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_timeout", "0.0");
	FormatEx(sBuffer, 32, "%d", RoundToFloor(fHeight));
	DispatchKeyValue(target << 2 + 10596, "hint_icon_offset", sBuffer);
	FormatEx(sBuffer, 32, "%d", RoundToFloor(fRange));
	DispatchKeyValue(target << 2 + 10596, "hint_range", sBuffer);
	FormatEx(sBuffer, 32, "%d", !bShowOffScreen);
	DispatchKeyValue(target << 2 + 10596, "hint_nooffscreen", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_icon_onscreen", sIconOnScreen[0]);
	DispatchKeyValue(target << 2 + 10596, "hint_icon_offscreen", sIconOffScreen[0]);
	DispatchKeyValue(target << 2 + 10596, "hint_binding", sCmd[0]);
	FormatEx(sBuffer, 32, "%d", bShowTextAlways);
	DispatchKeyValue(target << 2 + 10596, "hint_forcecaption", sBuffer);
	FormatEx(sBuffer, 32, "%d %d %d", iColor[0], iColor[0] + 4, iColor[0] + 8);
	DispatchKeyValue(target << 2 + 10596, "hint_color", sBuffer);
	DispatchKeyValue(target << 2 + 10596, "hint_caption", sText[0]);
	DispatchKeyValue(target << 2 + 10596, "hint_activator_caption", sText[0]);
	DispatchKeyValue(target << 2 + 10596, "hint_flags", "0");
	DispatchKeyValue(target << 2 + 10596, "hint_display_limit", "0");
	DispatchKeyValue(target << 2 + 10596, "hint_suppress_rest", "1");
	DispatchKeyValue(target << 2 + 10596, "hint_instance_type", "2");
	DispatchKeyValue(target << 2 + 10596, "hint_auto_start", "false");
	DispatchKeyValue(target << 2 + 10596, "hint_local_player_only", "true");
	DispatchKeyValue(target << 2 + 10596, "hint_allow_nodraw_target", "true");
	DispatchSpawn(target << 2 + 10596);
	AcceptEntityInput(target << 2 + 10596, "ShowHint", -1, -1, 0);
	target << 2 + 2400 = EntIndexToEntRef(target << 2 + 10596);
	return 0;
}

void:DestroyHintEntity(client)
{
	if (IsValidEntRef(client << 2 + 2400))
	{
		AcceptEntityInput(client << 2 + 2400, "Kill", -1, -1, 0);
		client << 2 + 2400 = -1;
	}
	return 0;
}

void:CreateHintEntity(client)
{
	if (IsValidEntRef(client << 2 + 2400))
	{
		AcceptEntityInput(client << 2 + 2400, "Kill", -1, -1, 0);
		client << 2 + 2400 = -1;
	}
	client << 2 + 10596 = CreateEntityByName("env_instructor_hint", -1);
	if (client << 2 + 10596 < 0)
	{
		return 0;
	}
	DispatchSpawn(client << 2 + 10596);
	client << 2 + 2400 = EntIndexToEntRef(client << 2 + 10596);
	return 0;
}

bool:IsValidClient(client)
{
	new var1;
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool:IsValidEntRef(iEntRef)
{
	static iEntity;
	iEntity = EntRefToEntIndex(iEntRef);
	new var1;
	return iEntRef && iEntity != -1 && IsValidEntity(iEntity);
}

public void:OnClientPutInServer(client)
{
	SDKHook(client, 3, 17);
	return 0;
}

public void:OnPluginStart()
{
	show_tank = CreateConVar("l4d2_show_tank", "1", "[1 = Enable][0 = Disable] Show Instuctor Hint For Tank", 0, false, 0.0, false, 0.0);
	HookEvent("tank_spawn", 23, 1);
	HookEvent("tank_killed", 21, 0);
	return 0;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new var1;
	if (IsValidClient(victim) && GetClientTeam(victim) == 3 && !IsIncapped(victim))
	{
		new health = GetEntProp(victim, 1, "m_iHealth", 4, 0);
		Format(Message, 32, "%d", health);
		new var2;
		if (GetEntProp(victim, 0, "m_zombieClass", 4, 0) == 8 && ConVar.IntValue.get(show_tank) == 1)
		{
			DisplayInstructorHint(victim, 0.0, 60.0, 800.0, true, false, "icon_skull", "", "", false, 19028, Message);
		}
	}
	return 4;
}

public Action:eTankKilled(Event:event, String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(Event.GetInt(event, "userid", 0));
	if (IsValidClient(tank))
	{
		DestroyHintEntity(tank);
	}
	return 0;
}

public void:eTankSpawn(Event:event, String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(Event.GetInt(event, "userid", 0));
	if (IsValidClient(tank))
	{
		CreateHintEntity(tank);
	}
	return 0;
}

 
********************************************************************************************/
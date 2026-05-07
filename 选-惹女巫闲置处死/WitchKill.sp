#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define	IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))

new timers;
public Plugin:myinfo =
{
	name = "",
	author = "",
	description = "惊扰女巫闲置处死",
	version = PLUGIN_VERSION,
	url = ""
} 
public OnPluginStart()
{
	
	HookEvent("witch_harasser_set",		Event_WitchHarasserSet);
	
}

public OnMapStart()
{
	PrecacheSound("ui/critical_event_1.wav");
}

public Action:Event_WitchHarasserSet(Handle: event, const String: name[], bool: dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "witchid");
	EmitSoundToAll("ui/critical_event_1.wav");
	EmitSoundToAll("ui/critical_event_1.wav");
	EmitSoundToAll("ui/critical_event_1.wav");
	EmitSoundToAll("ui/critical_event_1.wav");
	EmitSoundToAll("ui/critical_event_1.wav");
	PrintToChatAll("\x04%N \x03惊扰了Witch妹子...嘿嘿嘿",userid);
	PrintToChatAll("\x04%N \x03惊扰了Witch妹子...嘿嘿嘿",userid);
	PrintToChatAll("\x04%N \x03惊扰了Witch妹子...嘿嘿嘿",userid);
	new Handle:pack;
	CreateDataTimer(0.1, CannonmissTimerFunction, pack,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(pack, userid);
	WritePackCell(pack, entity);
	return Plugin_Continue;
}

public Action:CannonmissTimerFunction(Handle:timer, Handle:pack)
{
	new userid,entity;
	ResetPack(pack);
	userid = ReadPackCell(pack);
	entity = ReadPackCell(pack);
	timers++;
	if(timers==600) 
	{
		timers=0;
		KillTimer(timer);
		return Plugin_Stop;
	}
	if(IsValidClient(userid) && GetClientTeam(userid)==1)
	{
		ChangeClientTeam(userid,2);
		if(IsPlayerAlive(userid))
		{
			ForcePlayerSuicide(userid);
		}
		new health = GetEntProp(entity, Prop_Data, "m_iHealth");
		if (health > 0)
		{
			DealDamage(entity, entity, health + 1, -2130706430);
		}
		PrintToChat(userid,"\x03检测到你惊扰witch后\x04闲置\x01,需要用死亡作为代价!");
		PrintToChat(userid,"\x03检测到你惊扰witch后\x04闲置\x01,需要用死亡作为代价!");
		PrintToChat(userid,"\x03检测到你惊扰witch后\x04闲置\x01,需要用死亡作为代价!");
		timers=0;
		KillTimer(timer);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock DealDamage(attacker=0,victim,damage,dmg_type=0,String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt = CreateEntityByName("point_hurt");
		if(PointHurt)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt,"Damage",float(damage));
			DispatchKeyValue(PointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(PointHurt,"classname",weapon);
			}
			DispatchSpawn(PointHurt);
			if(IsValidClient(attacker))
				AcceptEntityInput(PointHurt, "Hurt", attacker);
			else 	
				AcceptEntityInput(PointHurt, "Hurt", -1);
				
			RemoveEdict(PointHurt);
		}
	}
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock SetHint(client, String:sBuffer[256])
{
	
	decl Handle:h_RemovePack;
	decl String:sTemp[32];
	
	new entity = CreateEntityByName("env_instructor_hint");
	FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
	ReplaceString(sBuffer, sizeof(sBuffer), "\n", " ");

	DispatchKeyValue(client, "targetname", sTemp);
	DispatchKeyValue(entity, "hint_target", sTemp);
	DispatchKeyValue(entity, "hint_timeout", "5");
	DispatchKeyValue(entity, "hint_range", "0.01");
	DispatchKeyValue(entity, "hint_color", "255, 255, 255");
	DispatchKeyValue(entity, "hint_icon_onscreen", "icon_skull");
	DispatchKeyValue(entity, "hint_caption", sBuffer);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "ShowHint");

	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, client);
	WritePackCell(h_RemovePack, entity);
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack);
}

public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent;
	
	ResetPack(h_Pack, false);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (IsValidEntity(i_Ent))
	RemoveEdict(i_Ent);
	
	return Plugin_Continue;
}

stock bool:IsValidPlayer(Client, bool:AllowBot = true, bool:AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	
	return true;
}
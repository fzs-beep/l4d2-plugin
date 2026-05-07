#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.6"

new Handle:HunterDamage;
new Handle:HunterPounce;
new Handle:HunterIncapp;
new Handle:HunterEnabled;
new Handle:BoomerDamage;
new Handle:BoomerIncapp;
new Handle:BoomerEnabled;
new Handle:SmokerDamage;
new Handle:SmokerTongue;
new Handle:SmokerIncapp;
new Handle:SmokerEnabled;
new Handle:SpitterDamage;
new Handle:SpitterSplat;
new Handle:SpitterIncapp;
new Handle:SpitterEnabled;
new Handle:JockeyDamage;
new Handle:JockeyInRide;
new Handle:JockeyIncapp;
new Handle:JockeyEnabled;
new Handle:ChargerDamage;
new Handle:ChargerPummel;
new Handle:ChargerIncapp;
new Handle:ChargerEnabled;
new Handle:TankClawDamage;
new Handle:TankRockDamage;
new Handle:TankClawIncapp;
new Handle:TankEnabled;
new Handle:ControlTimer;
new bool:IsControl[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "L4D2 特感伤害控制",
	author = "ヾ藤野深月ゞ",
	description = "控制特感伤害插件",
	version = PLUGIN_VERSION,
	url = "--"
}

public OnPluginStart()
{
	CreateConVar("L4D2_InfectedDamage_Version", PLUGIN_VERSION, "特感伤害控制 插件版本");
	ControlTimer			=	CreateConVar("L4D2_ControlTimer",		"0.5", 		"幸存者被控制后多久处于无敌状态(秒)？[0=关]", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	
	HunterEnabled			=	CreateConVar("L4D2_HunterEnabled",	"1", 			"是否启用 Hunter 伤害控制？[0=关 1=开]");
	HunterDamage			=	CreateConVar("L4D2_HunterDamage",		"20", 		"设置 Hunter 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	HunterPounce			=	CreateConVar("L4D2_HunterPounce",		"25", 		"设置 Hunter 控制玩家后每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	HunterIncapp			=	CreateConVar("L4D2_HunterIncapp",		"3", 			"设置 Hunter 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	BoomerEnabled			=	CreateConVar("L4D2_BoomerEnabled",	"1", 			"是否启用 Boomer 伤害控制？[0=关 1=开]");
	BoomerDamage			=	CreateConVar("L4D2_BoomerDamage",		"20", 		"设置 Boomer 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	BoomerIncapp			=	CreateConVar("L4D2_BoomerIncapp",		"3", 			"设置 Boomer 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	SmokerEnabled			=	CreateConVar("L4D2_SmokerEnabled",	"1", 			"是否启用 Smoker 伤害控制？[0=关 1=开]");
	SmokerDamage			=	CreateConVar("L4D2_SmokerDamage",		"20", 		"设置 Smoker 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	SmokerTongue			=	CreateConVar("L4D2_SmokerTongue",		"25", 		"设置 Smoker 控制玩家后每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	SmokerIncapp			=	CreateConVar("L4D2_SmokerIncapp",		"3", 			"设置 Smoker 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	SpitterEnabled		=	CreateConVar("L4D2_SpitterEnabled",	"1", 			"是否启用 Spitter 伤害控制？[0=关 1=开]");
	SpitterDamage			=	CreateConVar("L4D2_SpitterDamage",	"20", 		"设置 Spitter 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	SpitterSplat			=	CreateConVar("L4D2_SpitterSplat",		"3", 			"设置 Spitter口水 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	SpitterIncapp			=	CreateConVar("L4D2_SpitterIncapp",	"3", 			"设置 Spitter 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	JockeyEnabled			=	CreateConVar("L4D2_JockeyEnabled",	"1", 			"是否启用 Jockey 伤害控制？[0=关 1=开]");
	JockeyDamage			=	CreateConVar("L4D2_JockeyDamage",		"20", 		"设置 Jockey 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	JockeyInRide			=	CreateConVar("L4D2_JockeyInRide",		"25", 		"设置 Jockey 控制玩家后每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	JockeyIncapp			=	CreateConVar("L4D2_JockeyIncapp",		"3", 			"设置 Jockey 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	ChargerEnabled		=	CreateConVar("L4D2_ChargerEnabled",	"1", 			"是否启用 Charger 伤害控制？[0=关 1=开]");
	ChargerDamage			=	CreateConVar("L4D2_ChargerDamage",	"20", 		"设置 Charger 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	ChargerPummel			=	CreateConVar("L4D2_ChargerPummel",	"25", 		"设置 Charger 控制玩家后每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	ChargerIncapp			=	CreateConVar("L4D2_ChargerIncapp",	"3", 			"设置 Charger 攻击倒地玩家的伤害系数补偿(伤害*该系数)  \n注：设置结算伤害超过300将会直接秒杀\n0=基础伤害 [基础伤害+每次造成伤害*该系数]", FCVAR_NOTIFY, true, 0.0, true, 999.0);
	
	TankEnabled				=	CreateConVar("L4D2_TankEnabled",		"1", 			"是否启用 Tank 伤害控制？[0=关 1=开]");
	TankClawDamage		=	CreateConVar("L4D2_TankClawDamage",	"75", 		"设置 Tank 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	TankRockDamage		=	CreateConVar("L4D2_TankRockDamage",	"100", 		"设置 Tank石头 对玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	TankClawIncapp		=	CreateConVar("L4D2_TankClawIncapp",	"150",	 	"设置 Tank拳头 对倒地玩家每次造成的伤害  \n注：设置数值超过300将会直接秒杀");
	
	/* Hook */
	HookEvent("lunge_pounce",					Event_ControlStart);
	HookEvent("pounce_stopped",				Event_ControlEnd);
	HookEvent("tongue_grab",					Event_ControlStart);
	HookEvent("tongue_release",				Event_ControlEnd);
	HookEvent("jockey_ride",					Event_ControlStart);
	HookEvent("jockey_ride_end",			Event_ControlEnd);
	HookEvent("charger_pummel_start",	Event_ControlStart);
	HookEvent("charger_pummel_end",		Event_ControlEnd);
	HookEvent("round_start", 					Event_RoundDelet);
	HookEvent("round_end", 						Event_RoundDelet);
	HookEvent("player_hurt",					Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_PlayerHurt);
	/* 生成CFG */
	AutoExecConfig(true, "L4D2_InfectedDamage");
}

public Action:Event_RoundDelet(Handle:event, String:name[], bool:dontBroadcast)
{
	for (new Client = 1; Client <= MaxClients; Client++)
	{
		if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
			IsControl[Client] = false;
	}
}

public Action:Event_ControlStart(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
	{
		IsControl[Client] = true;
		if(GetConVarFloat(ControlTimer) != 0.0)
		{
			SetEntProp(Client, Prop_Data, "m_takedamage", 0, 1);
			CreateTimer(GetConVarFloat(ControlTimer), DeleteTakeDamage, Client);
		}
	}
}

/* 无敌时间设置 */
public Action:DeleteTakeDamage(Handle:timer, any:Client)
{
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
	{
		SetEntProp(Client, Prop_Data, "m_takedamage", 2, 1);
		//PrintToChat(Client, "\x04[提示]\x03无敌时间已结束！");
	}
}

public Action:Event_ControlEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
		IsControl[Client] = false;
}

public OnClientPutInServer(Client)
{
	if (IsValidPlayer(Client))
		SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/* 特感攻击幸存者 */
public Action:OnTakeDamage(Victim, &Attacker, &iInflictor, &Float:fDamage, &iDamagetype)
{
	if (IsValidPlayer(Victim) && IsValidPlayer(Attacker))
	{
		if(GetConVarInt(TankEnabled) == 1 && GetClientTeam(Victim) == 2)
		{
			new Float:GetTankRockDamage = GetConVarFloat(TankRockDamage);
			new Float:GetTankClawDamage = GetConVarFloat(TankClawDamage);
			new Float:GetTankClawIncapp = GetConVarFloat(TankClawIncapp);
			if(IsTankRock(iInflictor))
			{
				if(GetTankRockDamage > 300) ForcePlayerSuicide(Victim);
				else												fDamage = GetTankRockDamage;
			}
			else if(GetEntProp(Attacker, Prop_Send, "m_zombieClass") == 8)
			{
				if (!IsPlayerIncapped(Victim))
				{
					if(GetTankClawDamage > 300) ForcePlayerSuicide(Victim);
					else												fDamage = GetTankClawDamage;
				}else
				{
					if(GetTankClawIncapp > 300) ForcePlayerSuicide(Victim);
					else												fDamage = GetTankClawIncapp;
				}
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damageDone = GetEventInt(event, "dmg_health");
	new damageType = GetEventInt(event, "type");
	new eventhealth = GetEventInt(event, "health");
	new fDamage, Float:healthbuffer = GetEntPropFloat( Victim, Prop_Send, "m_healthBuffer" );
	//友军伤害返回
	if (IsValidPlayer(Attacker) && IsValidPlayer(Victim) && GetClientTeam(Attacker) != GetClientTeam(Victim)) 
	{
		//PrintToChat(Attacker, "\x04[提示]\x03你攻击 %N 伤害类型：%d", Victim, damageType);
		//PrintToChat(Victim, "\x04[提示]\x03你遭到 %N 攻击 伤害类型：%d", Attacker, damageType);
		if (GetClientTeam(Attacker) == 3 && GetClientTeam(Victim) == 2)
		{
			//重设幸存者血量
			new steelhealth = eventhealth + damageDone;
			new SetHealth, Float:HealthBuff;
			if (!IsPlayerIncapped(Victim))
			{
				if(steelhealth > 0)
				{
					if(healthbuffer > 0.0)
					{
						new damagehealth = eventhealth - damageDone;
						if(damagehealth > 0) SetHealth = steelhealth;
						if(damagehealth <= 0)
						{
							new BufferNum = damageDone - eventhealth;
							if(eventhealth > BufferNum) SetHealth = steelhealth;
							else 
							{
								SetHealth = damageDone - BufferNum;
								HealthBuff = healthbuffer + BufferNum + 1;
							}
						}
					}
					else SetHealth = steelhealth;
				}
			}else SetHealth = 0, HealthBuff = 0.0;
			//重建玩家伤害
			new iClass = GetEntProp(Attacker, Prop_Send, "m_zombieClass");
			if(iClass != 8)
			{
				switch (iClass)
				{
					case 1: //Smoker
					{
						if(GetConVarInt(SmokerEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim))
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(SmokerDamage);
								else fDamage = GetConVarInt(SmokerTongue);
							}
							else
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(SmokerDamage) * GetConVarInt(SmokerIncapp);
								else fDamage = GetConVarInt(SmokerTongue) * GetConVarInt(SmokerIncapp);
							}
						}else fDamage = damageDone;
					}
					case 2: 
					{
						if(GetConVarInt(BoomerEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim)) fDamage = GetConVarInt(BoomerDamage);
							else fDamage = GetConVarInt(BoomerDamage) * GetConVarInt(BoomerIncapp);
						}else fDamage = damageDone;
					}
					case 3: //Hunter
					{
						if(GetConVarInt(HunterEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim))
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(HunterDamage);
								else fDamage = GetConVarInt(HunterPounce);
							}
							else
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(HunterDamage) * GetConVarInt(HunterIncapp);
								else fDamage = GetConVarInt(HunterPounce) * GetConVarInt(HunterIncapp);
							}
						}else fDamage = damageDone;
					}
					case 4: //Spitter
					{
						if(GetConVarInt(SpitterEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim))
							{
								if (damageType & DMG_CLUB) fDamage = GetConVarInt(SpitterDamage);
								else if(damageType & DMG_RADIATION) fDamage = GetConVarInt(SpitterSplat);
							}
							else
							{
								if (damageType & DMG_CLUB) fDamage = GetConVarInt(SpitterDamage) * GetConVarInt(SpitterIncapp);
								else if(damageType & DMG_RADIATION) fDamage = GetConVarInt(SpitterSplat) * GetConVarInt(SpitterIncapp);
							}
						}else fDamage = damageDone;
					}
					case 5: //Jockey
					{
						if(GetConVarInt(JockeyEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim))
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(JockeyDamage);
								else fDamage = GetConVarInt(JockeyInRide);
							}
							else
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(JockeyDamage) * GetConVarInt(JockeyIncapp);
								else fDamage = GetConVarInt(JockeyInRide) * GetConVarInt(JockeyIncapp);
							}
						}else fDamage = damageDone;
					}
					case 6: 
					{
						if(GetConVarInt(ChargerEnabled) == 1)
						{
							if (!IsPlayerIncapped(Victim))
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(ChargerDamage);
								else fDamage = GetConVarInt(ChargerPummel);
							}
							else
							{
								if(!IsControl[Victim]) fDamage = GetConVarInt(ChargerDamage) * GetConVarInt(ChargerIncapp);
								else fDamage = GetConVarInt(ChargerPummel) * GetConVarInt(ChargerIncapp);
							}
						}else fDamage = damageDone;
					}
				}
				//创建伤害
				RePlayerHealth(Victim, SetHealth, HealthBuff)
				CreateDamage(Attacker, Victim, fDamage);
			}
		}
	}
	return Plugin_Handled;
}

public CreateDamage(attacker, Client, Damage)
{
	if (IsValidPlayer(attacker) && IsValidPlayer(Client)) 
	{
		if(Damage <= 300) DealDamage(attacker, Client, Damage, 0, "");
		else
		{
			DealDamage(attacker, Client, (Damage * 2), 0, "");
			ForcePlayerSuicide(Client);
		}
	}
}

public RePlayerHealth(Client, SetHealth, Float:HealthBuff)
{
	if (IsValidPlayer(Client) && IsPlayerAlive(Client)) 
	{
		if (SetHealth != 0)		SetEntProp(Client, Prop_Data, "m_iHealth", SetHealth);
		if (HealthBuff != 0)	SetEntPropFloat(Client, Prop_Send, "m_healthBuffer", HealthBuff);
	}
}

/* 检测玩家是否有效 */
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

//检测玩家是否倒地
stock bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated") == 1) return true;
	else return false;
}

stock bool:IsTankRock(entity)
{
	if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
	{
		decl String:classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		return StrEqual(classname, "tank_rock");
	}
	return false;
}

stock bool:IsTank(client)
{
	return (IsValidPlayer(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client));
}

/******************************************************
*	制造伤害Functions
*******************************************************/
stock DealDamage(attacker=0, victim, damage, dmg_type=0, String:weapon[]="")
{
	if(IsValidEdict(victim) && damage>0)
	{
		new String:victimid[64];
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new PointHurt1 = CreateEntityByName("point_hurt");
		if(PointHurt1)
		{
			Format(victimid, 64, "victim%d", victim);
			DispatchKeyValue(victim,"targetname",victimid);
			DispatchKeyValue(PointHurt1,"DamageTarget",victimid);
			DispatchKeyValueFloat(PointHurt1,"Damage",float(damage));
			DispatchKeyValue(PointHurt1,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
				DispatchKeyValue(PointHurt1,"classname",weapon);
			DispatchSpawn(PointHurt1);
			AcceptEntityInput(PointHurt1, "Hurt", -1);
			RemoveEdict(PointHurt1);
		}
	}
}

			/*
			new steelhealth = eventhealth + damageDone;
			if (steelhealth > 0)
			{
				if(healthbuffer != 0.0)
				{
					new damagehealth = eventhealth - damageDone;
					if(damagehealth > 0) SetEntProp(Victim, Prop_Data, "m_iHealth", steelhealth);
					if(damagehealth <= 0)
					{
						new BufferNum = damageDone - eventhealth;
						if(eventhealth > BufferNum) SetEntProp(Victim, Prop_Data, "m_iHealth", steelhealth);
						else 
						{
							SetEntProp(Victim, Prop_Data, "m_iHealth", (damageDone - BufferNum));
							SetEntPropFloat(Victim, Prop_Send, "m_healthBuffer", (healthbuffer + BufferNum + 1));
						}
					}
				}
				else SetEntProp(Victim, Prop_Data, "m_iHealth", steelhealth);
			}
			*/
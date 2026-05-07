#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "2.3"

new Handle:RewardPlugin;
new Handle:RewardHealth;
new Handle:RewardMessage;
new Handle:ReviveMessage;
new Handle:ReviveHealth;
new Handle:HealMessage;
new Handle:HealHealth;
new Handle:DefibrMessage;
new Handle:DefibrHealth;
new Handle:RandomHealMax;
new Handle:RandomHealMin;
new Handle:HealthDanger;
new Handle:HealthWarn;
new Handle:HealthDangerNum;
new Handle:HealthWarnNum;

new Handle:KillInfected;
new Handle:KillInfectedNum;
new Handle:KillInfected1;
new Handle:KillHeadShot;
new Handle:RewardHealthMax;
new Handle:KillDistance_Pistol;
new Handle:KillDistance_SMG;
new Handle:KillDistance_Rifle;
new Handle:KillDistance_Sniper;
new Handle:KillDistance_Shotgun;
new Handle:KillDisInfected;
new Handle:KillDisHeadShot;
new Handle:KillWitchHeal;
new Handle:KillTankHeal;

new Handle:KillHunterDrop;
new Handle:KillBoomerDrop;
new Handle:KillSmokerDrop;
new Handle:KillSpitterDrop;
new Handle:KillJockeyDrop;
new Handle:KillChargerDrop;
new Handle:KillTankDrop;
new Handle:KillHeadShotDrop;

new Handle:KillHunterNum;
new Handle:KillBoomerNum;
new Handle:KillSmokerNum;
new Handle:KillSpitterNum;
new Handle:KillJockeyNum;
new Handle:KillChargerNum;
new Handle:KillTankNum;

new Handle:KillHunterAmmo;
new Handle:KillBoomerAmmo;
new Handle:KillSmokerAmmo;
new Handle:KillSpitterAmmo;
new Handle:KillJockeyAmmo;
new Handle:KillChargerAmmo
new Handle:SMGAmmoMultiple;
new Handle:RifleAmmoMultiple;
new Handle:SniperAmmoMultiple;
new Handle:ShotgunAmmoMultiple;

new Handle:TankGiveAmmo;
new Handle:KillHeadShotAmmo;

new Handle:KillWeaponDrop;
new Handle:KillMeleesDrop;
new Handle:KillHealthDrop;
new Handle:KillUpgradePack;
new Handle:KillThrowsDrop;

new KillCount[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[L4D2]血量奖励",
	author = "ヾ藤野深月ゞ",
	description = "幸存者帮助队友，击杀特感 奖励生命值",
	version = PLUGIN_VERSION,
	url = "--"
};

public OnPluginStart()
{
	/* 插件参数 */
	CreateConVar("L4D2_CoverRewards_Version", PLUGIN_VERSION, "[L4D2] 血量奖励 插件版本");
	RewardPlugin						=	CreateConVar("L4D2_Reward_Plugin",						"1", 		"是否启用奖励插件？[0=关闭 1=开启]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RewardMessage						=	CreateConVar("L4D2_Reward_Message",						"0", 		"保护队友奖励模式[0=固定 1=随机]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	ReviveMessage						=	CreateConVar("L4D2_Revive_Message",						"0",  	"拉起倒地队友奖励模式[0=固定 1=随机]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HealMessage							=	CreateConVar("L4D2_Heal_Message",							"0",  	"治疗队友奖励模式[0=固定 1=随机]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	DefibrMessage						=	CreateConVar("L4D2_Defibr_Message",						"0",  	"电击队友奖励模式[0=固定 1=随机]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RewardHealth						=	CreateConVar("L4D2_Reward_Health",						"2",  	"保护队友固定奖励的血量值");
	ReviveHealth						=	CreateConVar("L4D2_Revive_Health",						"3",  	"拉起倒地固定奖励的血量值");
	HealHealth							=	CreateConVar("L4D2_Heal_Health",							"5",  	"治疗队友固定奖励的血量值");
	DefibrHealth						=	CreateConVar("L4D2_Defibr_Health",						"10",  	"电击队友固定奖励的血量值");
	RandomHealMin						=	CreateConVar("L4D2_Random_HealMin",						"1",	 	"[随机模式]设置随机奖励模式的最小值");
	RandomHealMax						=	CreateConVar("L4D2_Random_HealMax",						"10", 	"[随机模式]设置随机奖励模式的最大值");
	
	HealthDanger						=	CreateConVar("L4D2_HealthDanger_Multiple",		"2.0", 	"设置 [仅击杀特感]红血状态下回血倍数(结果四舍五入)");
	HealthWarn							=	CreateConVar("L4D2_HealthWarn_Multiple",			"1.5", 	"设置 [仅击杀特感]黄血状态下回血倍数(结果四舍五入)");
	HealthDangerNum					=	CreateConVar("L4D2_HealthDanger_Number",			"25", 	"设置 多少生命值以下处于红血状态");
	HealthWarnNum						=	CreateConVar("L4D2_HealthWarn_Number",				"40", 	"设置 多少生命值以下处于黄血状态");
	
	KillInfected						=	CreateConVar("L4D2_Kill_Infected",						"1", 		"击杀特感奖励的血量值");
	KillHeadShot						=	CreateConVar("L4D2_Kill_HeadShot",						"5", 		"爆头击杀特感奖励的血量值");
	KillDistance_Pistol			=	CreateConVar("L4D2_KillDistance_Pistol",			"1500", "设置 手枪类武器 远距离击杀要求");
	KillDistance_SMG				=	CreateConVar("L4D2_KillDistance_SMG",					"1500", "设置 微冲类武器 远距离击杀要求");
	KillDistance_Rifle			=	CreateConVar("L4D2_KillDistance_Rifle",				"1500", "设置 步枪类武器 远距离击杀要求");
	KillDistance_Sniper			=	CreateConVar("L4D2_KillDistance_Sniper",			"1500", "设置 狙击枪武器 远距离击杀要求");
	KillDistance_Shotgun		=	CreateConVar("L4D2_KillDistance_Shotgun",			"1500", "设置 霰弹枪武器 远距离击杀要求");
	KillDisInfected					=	CreateConVar("L4D2_Kill_DisInfected",					"2", 		"远距离击杀特感奖励倍数(奖励血量 * 当前值)");
	KillDisHeadShot					=	CreateConVar("L4D2_Kill_DisHeadShot",					"5", 		"远距离爆头击杀特感奖励倍数(奖励血量 * 当前值)");
	KillInfected1						=	CreateConVar("L4D2_Kill_Infected1",						"1", 		"击杀普通感染者奖励的血量值[达到击杀数触发]");
	KillInfectedNum					=	CreateConVar("L4D2_KillInfected_Num",					"20", 	"击杀多少普通感染者可触发奖励？");
	KillWitchHeal						=	CreateConVar("L4D2_KillWitch_Heal",						"200", 	"击杀 Wtich 可恢复多少血量值？");
	KillTankHeal						=	CreateConVar("L4D2_KillTank_Heal",						"200", 	"击杀 Tank 可恢复多少血量值");
	
	RewardHealthMax					=	CreateConVar("L4D2_Reward_HealthMax",					"200", 	"设置幸存者获得血量奖励的最高上限", FCVAR_NOTIFY, true, 100.0, true, 999.0);
	/* 武器掉落相关 */
	KillHunterDrop					=	CreateConVar("L4D2_KillHunter_Drop",					"2", 		"设置击杀 Hunter 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillBoomerDrop					=	CreateConVar("L4D2_KillBoomer_Drop",					"2", 		"设置击杀 Boomer 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillSmokerDrop					=	CreateConVar("L4D2_KillSmoker_Drop",					"2", 		"设置击杀 Smoker 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillSpitterDrop					=	CreateConVar("L4D2_KillSpitter_Drop",					"2", 		"设置击杀 Spitter 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillJockeyDrop					=	CreateConVar("L4D2_KillJockey_Drop",					"2", 		"设置击杀 Jockey 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillChargerDrop					=	CreateConVar("L4D2_KillCharger_Drop",					"2", 		"设置击杀 Charger 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillTankDrop						=	CreateConVar("L4D2_KillTank_Drop",						"100",	"设置击杀 Tank 掉落物品的概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillHeadShotDrop				=	CreateConVar("L4D2_KillHeadShot_Drop",				"5",		"设置爆头击杀特感增加多少概率", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	KillWeaponDrop					=	CreateConVar("L4D2_KillWeapon_Drop",					"10",		"设置掉落 武器 的概率\n注：与其他四项共计勿超过100% 不然按比重计算", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillMeleesDrop					=	CreateConVar("L4D2_KillMelees_Drop",					"20",		"设置掉落 近战 的概率\n注：与其他四项共计勿超过100% 不然按比重计算", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillHealthDrop					=	CreateConVar("L4D2_KillHealth_Drop",					"40",		"设置掉落 医疗品 的概率\n注：与其他四项共计勿超过100% 不然按比重计算", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillUpgradePack					=	CreateConVar("L4D2_KillUpgrade_Pack",					"20",		"设置掉落 升级包 的概率\n注：与其他四项共计勿超过100% 不然按比重计算", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	KillThrowsDrop					=	CreateConVar("L4D2_KillThrows_Drop",					"30",		"设置掉落 投掷物 的概率\n注：与其他四项共计勿超过100% 不然按比重计算", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	KillHunterNum						=	CreateConVar("L4D2_KillHunter_Num",						"1", 		"设置击杀 Hunter 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillBoomerNum						=	CreateConVar("L4D2_KillBoomer_Num",						"1", 		"设置击杀 Boomer 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillSmokerNum						=	CreateConVar("L4D2_KillSmoker_Num",						"1", 		"设置击杀 Smoker 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillSpitterNum					=	CreateConVar("L4D2_KillSpitter_Num",					"1", 		"设置击杀 Spitter 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillJockeyNum						=	CreateConVar("L4D2_KillJockey_Num",						"1", 		"设置击杀 Jockey 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillChargerNum					=	CreateConVar("L4D2_KillCharger_Num",					"1", 		"设置击杀 Charger 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	KillTankNum							=	CreateConVar("L4D2_KillTank_Num",							"10",	 	"设置击杀 Tank 掉落物品的数量", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	
	KillHunterAmmo					=	CreateConVar("L4D2_KillHunter_Ammo",					"3", 		"设置击杀 Hunter 奖励多少后备弹药");
	KillBoomerAmmo					=	CreateConVar("L4D2_KillBoomer_Ammo",					"3", 		"设置击杀 Boomer 奖励多少后备弹药");
	KillSmokerAmmo					=	CreateConVar("L4D2_KillSmoker_Ammo",					"3", 		"设置击杀 Smoker 奖励多少后备弹药");
	KillSpitterAmmo					=	CreateConVar("L4D2_KillSpitter_Ammo",					"3", 		"设置击杀 Spitter 奖励多少后备弹药");
	KillJockeyAmmo					=	CreateConVar("L4D2_KillJockey_Ammo",					"3", 		"设置击杀 Jockey 奖励多少后备弹药");
	KillChargerAmmo					=	CreateConVar("L4D2_KillCharger_Ammo",					"3", 		"设置击杀 Charger 奖励多少后备弹药");
	
	SMGAmmoMultiple					=	CreateConVar("L4D2_SetSMGAmmo_Multiple",			"5", 		"设置 微冲类武器 奖励后备弹药系数(奖励数量 * 当前值)");
	RifleAmmoMultiple				=	CreateConVar("L4D2_SetRifleAmmo_Multiple",		"3", 		"设置 步枪类武器 奖励后备弹药系数(奖励数量 * 当前值)");
	SniperAmmoMultiple			=	CreateConVar("L4D2_SetSniperAmmo_Multiple",		"2", 		"设置 狙击枪武器 奖励后备弹药系数(奖励数量 * 当前值)");
	ShotgunAmmoMultiple			=	CreateConVar("L4D2_SetShotgunAmmo_Multiple",	"1", 		"设置 霰弹枪武器 奖励后备弹药系数(奖励数量 * 当前值)");
	KillHeadShotAmmo				=	CreateConVar("L4D2_KillHeadShot_Ammo",				"3", 		"设置爆头击杀特感奖励后备弹药倍数(奖励总和量 * 当前值)");
	TankGiveAmmo						=	CreateConVar("L4D2_TankGive_Ammo",						"1", 		"设置 Tank 生成和死亡 是否给全体幸存者补充弹药？[0=关闭 1=开启]");
	//RegConsoleCmd("sm_show", Command_Show, "插件信息显示");
	/* HOOK */
	HookEvent("award_earned", 			Achievement_Earned);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("heal_success",				Event_HealSuccess);
	HookEvent("defibrillator_used",	Event_DefibrillatorUsed);
	HookEvent("player_death",				Event_PlayerDeath);
	HookEvent("player_death",				Event_PlayerDeath2);
	HookEvent("infected_death", 		Event_KillInfected);
	HookEvent("witch_killed",				Event_WitchKilled);
	HookEvent("tank_spawn",					Event_TankSpawn);
	HookEvent("tank_killed",				Event_TankKilled);
	/* Config */
	AutoExecConfig(true, "L4D2_KillRewards_Health");
}

/* Witch死亡 */
public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new eventhealth = GetEntProp(attacker, Prop_Data, "m_iHealth");
	
	if(IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
	{
		new Rewards = GetConVarInt(KillWitchHeal);
		if (!IsPlayerIncapped(attacker))
		{
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(attacker, "\x04[提示]\x03击杀 Witch 奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(attacker, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		else
			SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
		
		Health(attacker);
	}
	return Plugin_Continue;
}

/* 坦克产生事件 */
public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* 给予幸存者子弹 */
	if(GetConVarInt(TankGiveAmmo) == 1)
	{
		if(IsValidPlayer(Client) && IsValidEntity(Client))
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsValidPlayer(i) && GetClientTeam(i) == 2)
					CheatCommand(i, "give", "ammo");
			}
			PrintHintTextToAll("[提示] Tank 已产生全体幸存者获得弹药补给！");
		}
	}
	return Plugin_Continue;
}

/* Tank死亡 */
public Action:Event_TankKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new eventhealth = GetEntProp(attacker, Prop_Data, "m_iHealth");
	
	/* 给予幸存者子弹 */
	if(GetConVarInt(TankGiveAmmo) == 1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsValidPlayer(i) && GetClientTeam(i) == 2)
				CheatCommand(i, "give", "ammo");
		}
		PrintHintTextToAll("[提示] Tank 已死亡全体幸存者获得弹药补给！");
	}
	
	if(IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
	{
		new Rewards = GetConVarInt(KillTankHeal);
		if (!IsPlayerIncapped(attacker))
		{
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(attacker, "\x04[提示]\x03击杀 Tank 奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(attacker, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		else
			SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
		Health(attacker);
	}
	return Plugin_Continue;
}

/* 击杀普感 */
public Action:Event_KillInfected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new eventhealth = GetEntProp(attacker, Prop_Data, "m_iHealth");
	
	if(GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(attacker) && GetClientTeam(attacker) == 2)
	{
		KillCount[attacker] += 1;
		//触发奖励
		new Rewards = GetConVarInt(KillInfected1);
		new KillNum = GetConVarInt(KillInfectedNum);
		
		if( KillNum == KillCount[attacker] && Rewards > 0 )
		{
			KillCount[attacker] -= KillNum;
			if (!IsPlayerIncapped(attacker))
			{
				if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
				{
					SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
					PrintToChat(attacker, "\x04[提示]\x03击杀 %d 普通感染者 奖励 %d 点生命值", KillNum, Rewards);
				}
				else
					SetEntProp(attacker, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
			}
			else
				SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + Rewards);
			
			Health(attacker);
		}
	}
	return Plugin_Continue;
}

/* 玩家死亡（回血） */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	bool headshot = GetEventBool(event, "headshot");
	new eventhealth = GetEntProp(attacker, Prop_Data, "m_iHealth");
	
	/* 计算武器加成 */
	decl String:weapon[128], Float:GetDistance, Rewards, AddRewards, Multiple, Float:AddHealth;
	GetEventString(event, "weapon", weapon,sizeof(weapon));
	if(StrContains(weapon, "pistol"))	GetDistance = GetConVarFloat(KillDistance_Pistol);
	else if(StrContains(weapon, "smg"))	GetDistance = GetConVarFloat(KillDistance_SMG);
	else if(StrContains(weapon, "rifle"))	GetDistance = GetConVarFloat(KillDistance_Rifle);
	else if(StrContains(weapon, "hunting_rifle")>=0 || StrContains(weapon, "sniper"))	GetDistance = GetConVarFloat(KillDistance_Sniper);
	else if(StrContains(weapon, "shotgun"))	GetDistance = GetConVarFloat(KillDistance_Shotgun);
	
	/* 计算回血加成 */
	if(eventhealth < GetConVarInt(HealthWarnNum))
		AddHealth = GetConVarFloat(HealthWarn);
	else if(eventhealth < GetConVarInt(HealthDangerNum))
		AddHealth = GetConVarFloat(HealthDanger);
	
	if(GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(victim) && IsValidPlayer(attacker))
	{
		new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if(GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3 && iClass <= 6)
		{
			/* 计算距离 */
			new Float:PlayerPos[3], Float:ClientPos[3];
			GetClientAbsOrigin(victim, PlayerPos);
			GetClientAbsOrigin(attacker, ClientPos);
			new Float:Distance = GetVectorDistance(PlayerPos, ClientPos);
			if (Distance > GetDistance)
			{
				if(headshot)	Multiple = GetConVarInt(KillDisHeadShot);
				else					Multiple = GetConVarInt(KillDisInfected);
			}else Multiple = 1;
			
			//检测玩家是否倒地
			if (!IsPlayerIncapped(attacker))
			{
				if(headshot)
				{
					Rewards = GetConVarInt(KillHeadShot) * Multiple;
					AddRewards = RoundToNearest(AddHealth * Rewards);
					if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
						SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + (Rewards + AddRewards) );
					else
						SetEntProp(attacker, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
				}
				if(!headshot)
				{
					Rewards = GetConVarInt(KillInfected) * Multiple;
					AddRewards = RoundToNearest(AddHealth * Rewards);
					if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
						SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + (Rewards + AddRewards) );
					else
						SetEntProp(attacker, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
				}
			}
			else
			{
				if(headshot)
				{
					Rewards = GetConVarInt(KillHeadShot) * Multiple;
					AddRewards = RoundToNearest(AddHealth * Rewards);
					SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + (Rewards + AddRewards) );
				}
				if(!headshot)
				{
					Rewards = GetConVarInt(KillInfected) * Multiple;
					AddRewards = RoundToNearest(AddHealth * Rewards);
					SetEntProp(attacker, Prop_Data, "m_iHealth", GetEntProp(attacker, Prop_Data, "m_iHealth") + (Rewards + AddRewards) );
				}
			}
			Health(attacker);
		}
	}
	return Plugin_Handled;
}

/* 玩家死亡（掉落&子弹） */
public Action:Event_PlayerDeath2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	bool headshot = GetEventBool(event, "headshot");
	
	decl String:weapon[128], AddProbability, AddAmmoMultiple;
	GetEventString(event, "weapon", weapon,sizeof(weapon));
	if(headshot)
	{
		if(StrContains(weapon, "pistol") >= 0)
			AddAmmoMultiple = 0;
		
		else if(StrContains(weapon, "smg") >= 0)
			AddAmmoMultiple = GetConVarInt(SMGAmmoMultiple) * GetConVarInt(KillHeadShotAmmo);
		
		else if(StrContains(weapon, "hunting_rifle") < 0 && StrContains(weapon, "rifle") >= 0)
			AddAmmoMultiple = GetConVarInt(RifleAmmoMultiple) * GetConVarInt(KillHeadShotAmmo);
		
		else if(StrContains(weapon, "hunting_rifle") >= 0 || StrContains(weapon, "sniper") >= 0)
			AddAmmoMultiple = GetConVarInt(SniperAmmoMultiple) * GetConVarInt(KillHeadShotAmmo);
		
		else if(StrContains(weapon, "shotgun") >= 0)
			AddAmmoMultiple = GetConVarInt(ShotgunAmmoMultiple) * GetConVarInt(KillHeadShotAmmo);
		
		AddProbability = GetConVarInt(KillHeadShotDrop);
	}
	else
	{
		if(StrContains(weapon, "pistol") >= 0)
			AddAmmoMultiple = 0;
		
		else if(StrContains(weapon, "smg") >= 0)
			AddAmmoMultiple = GetConVarInt(SMGAmmoMultiple);
		
		else if(StrContains(weapon, "hunting_rifle") < 0 && StrContains(weapon, "rifle") >= 0)
			AddAmmoMultiple = GetConVarInt(RifleAmmoMultiple);
		
		else if(StrContains(weapon, "hunting_rifle") >= 0 || StrContains(weapon, "sniper") >= 0)
			AddAmmoMultiple = GetConVarInt(SniperAmmoMultiple);
		
		else if(StrContains(weapon, "shotgun") >= 0)
			AddAmmoMultiple = GetConVarInt(ShotgunAmmoMultiple);
		
		AddProbability = 0;
	}
	
	if(GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(victim) && IsValidPlayer(attacker))
	{
		new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		if(GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
		{
			//设置掉落
			switch (iClass)
			{
				case 1: //smoker
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillSmokerAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillSmokerDrop) + AddProbability), GetConVarInt(KillSmokerNum));
				}
				case 2: //boomer
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillBoomerAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillBoomerDrop) + AddProbability), GetConVarInt(KillBoomerNum));
				}
				case 3: //hunter
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillHunterAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillHunterDrop) + AddProbability), GetConVarInt(KillHunterNum));
				}
				case 4: //spitter
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillSpitterAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillSpitterDrop) + AddProbability), GetConVarInt(KillSpitterNum));
				}
				case 5: //jockey
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillJockeyAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillJockeyDrop) + AddProbability), GetConVarInt(KillJockeyNum));
				}
				case 6: //charger
				{
					SetWeaponAmmoResult(attacker, (GetConVarInt(KillChargerAmmo) * AddAmmoMultiple));
					SpawnItemFromDieResult(victim, (GetConVarInt(KillChargerDrop) + AddProbability), GetConVarInt(KillChargerNum));
				}
				case 8: //Tank
				{
					SpawnItemFromDieResult(victim, (GetConVarInt(KillTankDrop) + AddProbability), GetConVarInt(KillTankNum));
				}
			}
		}
	}
	return Plugin_Handled;
}

/* 保护队友 */
public Action:Achievement_Earned(Handle:event, String:name[], bool:Broadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new achievementid = GetEventInt(event, "award");
	new eventhealth = GetEntProp(Client, Prop_Data, "m_iHealth");
	
	if (GetConVarInt(RewardPlugin) == 1)
	{
		if (achievementid == 67)
		{
			if (GetConVarInt(RewardMessage) == 1)
			{
				new Rewards = GetRandomInt(GetConVarInt(RandomHealMin), GetConVarInt(RandomHealMax));
				//检测玩家是否倒地
				if (!IsPlayerIncapped(Client))
				{
					if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
					{
						SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
						PrintToChat(Client, "\x04[提示]\x03保护队友奖励 %d 点生命值", Rewards);
					}
					else
						SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
				}
				else
					SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
			}
			else
			{
				new Rewards = GetConVarInt(RewardHealth);
				//检测玩家是否倒地
				if (IsPlayerIncapped(Client))
				{
					if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
					{
						SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
						PrintToChat(Client, "\x04[提示]\x03保护队友奖励 %d 点生命值", Rewards);
					}
					else
						SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
				}
				else
					SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
			}
			Health(Client);
		}
	}
	return Plugin_Continue;
}

/* 拉起队友 */
public Action:Event_ReviveSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new eventhealth = GetEntProp(Client, Prop_Data, "m_iHealth");
	
	if (GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(Client) && Client != Subject && !IsFakeClient(Client))
	{
		if(GetConVarInt(ReviveMessage) == 1)
		{
			new Rewards = GetRandomInt(GetConVarInt(RandomHealMin), GetConVarInt(RandomHealMax));
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03拉起队友随机奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		else
		{
			new Rewards = GetConVarInt(ReviveHealth);
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03拉起队友奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		Health(Client);
	}
	return Plugin_Continue;
}

/* 电击队友 */
public Action:Event_DefibrillatorUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new eventhealth = GetEntProp(Client, Prop_Data, "m_iHealth");
	
	if (GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(Client) && GetClientTeam(Client) == 2 && !IsFakeClient(Client))
	{
		if(GetConVarInt(DefibrMessage) == 1)
		{
			new Rewards = GetRandomInt(GetConVarInt(RandomHealMin), GetConVarInt(RandomHealMax));
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03电击队友随机奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		else
		{
			new Rewards = GetConVarInt(DefibrHealth);
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03电击队友奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		Health(Client);
	}
	return Plugin_Continue;
}

/* 治疗幸存者 */
public Action:Event_HealSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Target = GetClientOfUserId(GetEventInt(event, "subject"));
	new eventhealth = GetEntProp(Client, Prop_Data, "m_iHealth");
	
	if (GetConVarInt(RewardPlugin) == 1 && IsValidPlayer(Client) && GetClientTeam(Client) == 2  && Client != Target)
	{
		if(GetConVarInt(HealMessage) == 1)
		{
			new Rewards = GetRandomInt(GetConVarInt(RandomHealMin), GetConVarInt(RandomHealMax));
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03治疗队友随机奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		else
		{
			new Rewards = GetConVarInt(HealHealth);
			if ( (eventhealth + Rewards) <= GetConVarInt(RewardHealthMax) )
			{
				SetEntProp(Client, Prop_Data, "m_iHealth", GetEntProp(Client, Prop_Data, "m_iHealth") + Rewards);
				PrintToChat(Client, "\x04[提示]\x03治疗队友奖励 %d 点生命值", Rewards);
			}
			else
				SetEntProp(Client, Prop_Data, "m_iHealth", GetConVarInt(RewardHealthMax));
		}
		Health(Client);
	}
	return Plugin_Continue;
}

public Health(Client)
{
	if(IsValidPlayer(Client) && IsValidEntity(Client))
	{
		SetEntProp(Client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(Client, Prop_Send, "m_bFlashing", 1);
		SetEntProp(Client, Prop_Send, "m_glowColorOverride", 119911);
		CreateTimer(1.0, Timer_He, Client);
	}
}

public Action:Timer_He(Handle:timer, any:Client)
{
	if(IsValidPlayer(Client) && IsValidEntity(Client))
	{
		new RGB_GLOW = RGB_TO_INT(255, 255, 255);
		SetEntProp(Client, Prop_Send, "m_iGlowType", 0);
		SetEntProp(Client, Prop_Send, "m_bFlashing", 0);
		SetEntProp(Client, Prop_Send, "m_glowColorOverride", RGB_GLOW);
	}
	return Plugin_Handled;
}

RGB_TO_INT(red, green, blue)
{
	return green * 256 + blue * 65536 + red;
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

//检测玩家是否倒地
stock bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated") == 1)
		return true;
	else
		return false;
}

/* 执行修改命令 */
stock CheatCommand(Client, const String:command[], const String:arguments[])
{
	if (!Client) return;
	new admindata = GetUserFlagBits(Client);
	SetUserFlagBits(Client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(Client, admindata);
}

/*********************************************************************
*
*								其余参数
*
*********************************************************************/
//武器数组
new String:WeaponCommand[][] = {"smg", "smg_silenced", "smg_mp5", "pumpshotgun", "shotgun_chrome", "rifle", "rifle_ak47", "rifle_desert", "rifle_sg552", "autoshotgun", "shotgun_spas", "hunting_rifle", "sniper_military", "sniper_scout", "sniper_awp", "rifle_m60", "grenade_launcher"};
// 近战数组
new String:MeleesCommand[][] = {"knife", "cricket_bat", "crowbar", "electric_guitar", "fireaxe", "frying_pan", "golfclub", "baseball_bat", "katana", "machete","tonfa", "riotshield", "pitchfork", "shovel", "weapon_chainsaw" };
// 医疗品数组
new String:HealthCommand[][] = {"pain_pills", "adrenaline", "first_aid_kit", "defibrillator"};
// 升级包数组
new String:UpgradeCommand[][] = {"weapon_upgradepack_incendiary", "weapon_upgradepack_explosive"};
// 投掷物数组
new String:ThrowsCommand[][] = {"vomitjar", "pipe_bomb", "molotov"};

/*
public OnClientPutInServer(Client)
{
	if (IsValidPlayer(Client))
	{
		SDKHook(Client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action OnWeaponCanUse(Client, WeaponEnt)
{
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2 && IsPlayerAlive(Client))
	{
		CreateTimer(1.0, Weaponr_AddUpgrade, Client);
	}
	return Plugin_Continue;
}

public Action:Weaponr_AddUpgrade(Handle:timer, any:Client)
{
	decl String:WeaponName[64];
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2 && IsPlayerAlive(Client))
	{
		new gun1 = GetPlayerWeaponSlot(Client, 0);
		if( gun1 != -1)
		{
			GetEdictClassname(gun1, WeaponName, sizeof(WeaponName));
			if(StrEqual(WeaponName, "weapon_smg") || StrEqual(WeaponName, "weapon_smg_silenced") || 
			StrEqual(WeaponName, "weapon_smg_mp5") || StrEqual(WeaponName, "weapon_pumpshotgun") || 
			StrEqual(WeaponName, "weapon_shotgun_chrome"))
				CheatCommand(Client, "upgrade_add", "laser_sight");
		}
	}
}
*/

/* 掉落客户端，几率，数量 */
public SpawnItemFromDieResult(Client, Random, Number)
{
	if(GetRandomInt(0, 100) < Random)
	{
		new a = GetConVarInt(KillWeaponDrop), b = GetConVarInt(KillMeleesDrop), c = GetConVarInt(KillHealthDrop), d = GetConVarInt(KillUpgradePack), e = GetConVarInt(KillThrowsDrop);
		new ItemMax = (a+b+c+d+e), ItemCommand;
		for(new i = 0; i < Number; i++)
    {
	  	new ItemNum = GetRandomInt(0, ItemMax);
	  	if(ItemNum < a)
	  	{
	  		ItemCommand = GetRandomInt(0, 16)
	  		CheatCommand(Client, "give", WeaponCommand[ItemCommand]);
	  	}
	  	else if(ItemNum < (a+b))
	  	{
	  		ItemCommand = GetRandomInt(0, 14)
	  		CheatCommand(Client, "give", MeleesCommand[ItemCommand]);
	  	}
	  	else if(ItemNum < (a+b+c))
	  	{
	  		ItemCommand = GetRandomInt(0, 3)
	  		CheatCommand(Client, "give", HealthCommand[ItemCommand]);
	  	}
	  	else if(ItemNum < (a+b+c+d))
	  	{
	  		ItemCommand = GetRandomInt(0, 1)
	  		CheatCommand(Client, "give", UpgradeCommand[ItemCommand]);
	  	}
	  	else
	  	{
	  		ItemCommand = GetRandomInt(0, 2)
	  		CheatCommand(Client, "give", ThrowsCommand[ItemCommand]);
	  	}
	  }
		PrintHintTextToAll("特感 %N 被击杀掉落了战利品！", Client);
	}
}

public SetWeaponAmmoResult(Client, Number)
{
	decl String:GunName[64];
	new gun1 = GetPlayerWeaponSlot(Client, 0);
	if( gun1 != -1)
	{
		GetEdictClassname(gun1, GunName, sizeof(GunName));
		if(Number <= 0 && StrContains(GunName, "rifle_m60") >= 0 || StrContains(GunName, "grenade_launcher") >= 0) return;
		new PrimType = GetEntProp(gun1, Prop_Send, "m_iPrimaryAmmoType");
		new ammo = GetEntProp(Client, Prop_Send, "m_iAmmo", _, PrimType);
		SetEntProp(Client, Prop_Send, "m_iAmmo", ammo + Number, _, PrimType);
	}
}


/*
public Action:Command_Show(client, args)
{
	PrintToChatAll("\x03==========================\x09\x09\x09\x09\x03");
	PrintToChatAll("\x04|插件名稱:保護玩家\x09\x09\x09\x09\x09\x09\x04");
	PrintToChatAll("\x04|插件作者:奇奈cheryl\x09\x09\x09\x04");
	PrintToChatAll("\x03==========================\x09\x09\x09\x09\x03");
	return Plugin_Handled;
}
*/

//new Handle:HealMaxNum;
//HealMaxNum		=		CreateConVar("L4D2_Heal_MaxNum",			"30",  	"治疗队友奖励触发生效的血量(低于此值才可触发)");
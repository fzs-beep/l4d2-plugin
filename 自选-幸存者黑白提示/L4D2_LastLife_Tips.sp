#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

/*	
颜色表示	
红、橙、黄、绿、青、蓝、紫、银白、粉红、品红、亮绿
*/
new RedColor[4]					= {255, 0, 0, 255};
new OrangeColor[4]			= {255, 128, 0, 255};
new YellowColor[4]			= {255, 255, 0, 255};
new GreenColor[4]				= {0, 255, 0, 255};
new CyanColor[4]				= {0, 255, 255, 255};
new BlueColor[4]				= {0, 0, 255, 255};
new PurpleColor[4]			= {160, 32, 240, 255};
new GainsColor[4]				= {220, 220, 220, 255};
new PinkColor[4]				= {255, 192, 203, 255};
new MagentaColor[4]			= {255, 0, 255, 255};
new LightGreenColor[4]	= {144, 238, 144, 255};
new SetLoadColor[4];
new SetLoadOutline[4];

/* CFG参数设置 */
new Handle:LastLife_Enabled;
new Handle:SetTips_Mode;
new Handle:SetColors_Player;
new Handle:SetOutlines_Player;
new Handle:SetOutlines_Range;
new bool:LastLife[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "L4D2 LastLife Tips",
	author = "藤野深月",
	description = "对黑白玩家进行提示",
	version = PLUGIN_VERSION,
	url = "--"
}

public OnPluginStart()
{
	CreateConVar("L4D2_LastLife_Tips_Version", PLUGIN_VERSION, " L4D2 黑白玩家提示 插件版本 ");
	LastLife_Enabled		=	CreateConVar("L4D2_LastLife_Enabled",			"1",		 "是否启用玩家黑白提示？[0=禁用]");
	SetTips_Mode				=	CreateConVar("L4D2_SetTips_Mode",					"1",		 "设置玩家提示模式[1=聊天框 2=提示框 3=中间]");
	SetColors_Player		=	CreateConVar("L4D2_SetColors_Player",			"4",		 "设置玩家黑白时身体显示颜色\n0=关闭 1=红 2=橙 3=黄 4=绿 5=青 6=蓝 \n7=紫 8=银白 9=粉红 10=品红 11=亮绿");
	SetOutlines_Player	=	CreateConVar("L4D2_SetOutlines_Player",		"8",		 "设置玩家黑白时身体显示轮廓颜色\n0=关闭 1=红 2=橙 3=黄 4=绿 5=青 6=蓝 \n7=紫 8=银白 9=粉红 10=品红 11=亮绿");
	SetOutlines_Range		=	CreateConVar("L4D2_SetOutlines_Range",		"150",	 "设置轮廓显示范围[0=常亮(无论多远)]");
	/* Hook */
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_hurt",			Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("heal_success",			Event_HealSuccess);
	HookEvent("revive_success",		Event_ReviveSuccess);
	HookEvent("round_start",			Event_RoundStart);
	/* Config */
	AutoExecConfig(true, "L4D2_LastLife_Tips");
	LoadSettings();
}

/* 回合开始 */
public Action:Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	LoadSettings();
}

/* 拉起队友 */
public Action:Event_ReviveSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
		CreateTimer(0.1, CheckPlayerStatus, Client);
	return Plugin_Handled;
}

/* 玩家受伤 */
public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
		CreateTimer(0.1, CheckPlayerStatus, Client);
	return Plugin_Handled;
}

/* 治疗幸存者 */
public Action:Event_HealSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
		CreateTimer(0.1, CheckPlayerStatus, Client);
	return Plugin_Handled;
}

/* 玩家死亡 */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
	{
		SetEntProp(Client, Prop_Send, "m_bIsOnThirdStrike", 0);
		PerformOutline(Client, 0, 0);
		SetEntityRenderMode(Client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Client, 255, 255, 255, 255);
	}
	return Plugin_Handled;
}

public Action:CheckPlayerStatus( Handle:timer, any:Client )
{
	if(GetConVarInt(LastLife_Enabled) == 0) return Plugin_Stop;
	if ( GetEntProp( Client, Prop_Send, "m_bIsOnThirdStrike" ) > 0)
	{
		SetPlayerColors(Client);
		SetPlayerOutline(Client);
		if(!LastLife[Client])
		{
			LastLife[Client] = true;
			InformationPrompt(Client, GetConVarInt(SetTips_Mode), 2, "\x04[提示]\x03玩家: \x04%N \x03处于黑白状态!!")
		}
	}else
	{
		LastLife[Client] = false;
		PerformOutline(Client, 0, 0);
		SetEntityRenderMode(Client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Client, 255, 255, 255, 255);
	}
	return Plugin_Handled;
}

public InformationPrompt(Client, Type, Mode, String:OutPutText[])
{
	if(Mode == 1)
	{
		if(Type == 1) PrintToChat(Client, OutPutText);
		if(Type == 2) PrintHintText(Client, OutPutText);
		if(Type == 3) PrintCenterText(Client, OutPutText);
	}else
	{
		if(Type == 1) PrintToChatAll(OutPutText, Client );
		if(Type == 2) PrintHintTextToAll(OutPutText, Client );
		if(Type == 3) PrintCenterTextAll(OutPutText, Client );
	}
}

public LoadSettings()
{
	/* 设置颜色 */
	if(GetConVarInt(SetColors_Player) != 0)
	{
		switch(GetConVarInt(SetColors_Player))
		{
			case 1: SetLoadColor = RedColor;
			case 2: SetLoadColor = OrangeColor;
			case 3: SetLoadColor = YellowColor;
			case 4: SetLoadColor = GreenColor;
			case 5: SetLoadColor = CyanColor;
			case 6: SetLoadColor = BlueColor;
			case 7: SetLoadColor = PurpleColor;
			case 8: SetLoadColor = GainsColor;
			case 9: SetLoadColor = PinkColor;
			case 10: SetLoadColor = MagentaColor;
			case 11: SetLoadColor = LightGreenColor;
		}
	}
	/* 设置轮廓色 */
	if(GetConVarInt(SetOutlines_Player) != 0)
	{
		switch(GetConVarInt(SetOutlines_Player))
		{
			case 1: SetLoadOutline = RedColor;
			case 2: SetLoadOutline = OrangeColor;
			case 3: SetLoadOutline = YellowColor;
			case 4: SetLoadOutline = GreenColor;
			case 5: SetLoadOutline = CyanColor;
			case 6: SetLoadOutline = BlueColor;
			case 7: SetLoadOutline = PurpleColor;
			case 8: SetLoadOutline = GainsColor;
			case 9: SetLoadOutline = PinkColor;
			case 10: SetLoadOutline = MagentaColor;
			case 11: SetLoadOutline = LightGreenColor;
		}
	}
}

public SetPlayerColors(Client)
{
	if(GetConVarInt(SetColors_Player) != 0)
	{
		new SetColor[4];
		if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
		{
			SetColor[0] = SetLoadColor[0];
			SetColor[1] = SetLoadColor[1];
			SetColor[2] = SetLoadColor[2];
			SetColor[3] = SetLoadColor[3];
			SetEntityRenderMode(Client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(Client, SetColor[0], SetColor[1], SetColor[2], SetColor[3]);
		}
	}
}

public SetPlayerOutline(Client)
{
	if(GetConVarInt(SetOutlines_Player) != 0)
	{
		new SetOutline[3];
		SetOutline[0] = SetLoadOutline[0];
		SetOutline[1] = SetLoadOutline[1];
		SetOutline[2] = SetLoadOutline[2];
		if (IsValidPlayer(Client) && GetClientTeam(Client) == 2)
			PerformOutline(Client, 3, GetConVarInt(SetOutlines_Range), SetOutline[0], SetOutline[1], SetOutline[2]);
	}
}

/* 实体轮廓设置 */
stock PerformOutline(Client, Type, Range = 0, Red = 0, Green = 0, Blue = 0)
{
	decl Color;
	Color = Red + Green * 256 + Blue * 65536;
	SetEntProp(Client, Prop_Send, "m_iGlowType", Type);
	SetEntProp(Client, Prop_Send, "m_nGlowRange", Range);
	SetEntProp(Client, Prop_Send, "m_glowColorOverride", Color);
}

/* 检测玩家是否有效 */
stock bool:IsValidPlayer(Client)
{
	if (Client < 1 || Client > MaxClients) return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client)) return false;
	return true;
}
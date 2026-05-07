#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_NAME				"Server Message System"
#define PLUGIN_AUTHOR			"sorallll"
#define PLUGIN_DESCRIPTION		""
#define PLUGIN_VERSION			"1.0.1"
#define PLUGIN_URL				""

/*****************************************************************************************************/
// ====================================================================================================
// colors.inc
// ====================================================================================================
#define SERVER_INDEX 0
#define NO_INDEX 	-1
#define NO_PLAYER 	-2
#define BLUE_INDEX 	 2
#define RED_INDEX 	 3
#define MAX_COLORS 	 6
#define MAX_MESSAGE_LENGTH 254
static const char CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
static const char CTagCode[][] = {"\x01", "\x04", "\x03", "\x03", "\x03", "\x05"};
static const bool CTagReqSayText2[] = {false, false, true, true, true, false};
static const int CProfile_TeamIndex[] = {NO_INDEX, NO_INDEX, SERVER_INDEX, RED_INDEX, BLUE_INDEX, NO_INDEX};

/**
 * @note Prints a message to a specific client in the chat area.
 * @note Supports color tags.
 *
 * @param client	Client index.
 * @param szMessage	Message (formatting rules).
 * @return			No return
 * 
 * On error/Errors:	If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] szMessage, any ...) {
	if (client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);
	
	if (!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);
	
	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);
	FormatEx(szBuffer, sizeof szBuffer, "\x01%s", szMessage);
	VFormat(szCMessage, sizeof szCMessage, szBuffer, 3);
	
	int index = CFormat(szCMessage, sizeof szCMessage);
	if (index == NO_INDEX)
		PrintToChat(client, "%s", szCMessage);
	else
		CSayText2(client, index, szCMessage);
}

/**
 * @note Prints a message to all clients in the chat area.
 * @note Supports color tags.
 *
 * @param client	Client index.
 * @param szMessage	Message (formatting rules)
 * @return			No return
 */
stock void CPrintToChatAll(const char[] szMessage, any ...) {
	char szBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof szBuffer, szMessage, 2);
			CPrintToChat(i, "%s", szBuffer);
		}
	}
}

/**
 * @note Replaces color tags in a string with color codes
 *
 * @param szMessage	String.
 * @param maxlength	Maximum length of the string buffer.
 * @return			Client index that can be used for SayText2 author index
 * 
 * On error/Errors:	If there is more then one team color is used an error will be thrown.
 */
stock int CFormat(char[] szMessage, int maxlength) {	
	int iRandomPlayer = NO_INDEX;
	
	for (int i; i < MAX_COLORS; i++) {													//	Para otras etiquetas de color se requiere un bucle.
		if (StrContains(szMessage, CTag[i], false) == -1)								//	Si no se encuentra la etiqueta, omitir.
			continue;
		else if (!CTagReqSayText2[i])
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);			//	Si la etiqueta no necesita Saytext2 simplemente reemplazará.
		else {																			//	La etiqueta necesita Saytext2.	
			if (iRandomPlayer == NO_INDEX) {											//	Si no se especificó un cliente aleatorio para la etiqueta, reemplaca la etiqueta y busca un cliente para la etiqueta.
				iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);			//	Busca un cliente válido para la etiqueta, equipo de infectados oh supervivientes.
				if (iRandomPlayer == NO_PLAYER)
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[5], false);	//	Si no se encuentra un cliente valido, reemplasa la etiqueta con una etiqueta de color verde.
				else 
					ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);	// 	Si el cliente fue encontrado simplemente reemplasa.
			}
			else																		//	Si en caso de usar dos colores de equipo infectado y equipo de superviviente juntos se mandará un mensaje de error.
				ThrowError("Using two team colors in one message is not allowed");		//	Si se ha usadó una combinación de colores no validad se registrara en la carpeta logs.
		}
	}

	return iRandomPlayer;
}

/**
 * @note Founds a random player with specified team
 *
 * @param color_team	Client team.
 * @return				Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam(int color_team) {
	if (color_team == SERVER_INDEX)
		return 0;
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == color_team)
				return i;
		}
	}

	return NO_PLAYER;
}

/**
 * @note Sends a SayText2 usermessage to a client
 *
 * @param szMessage	Client index
 * @param maxlength	Author index
 * @param szMessage	Message
 * @return			No return.
 */
stock void CSayText2(int client, int author, const char[] szMessage) {
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(author);
	bf.WriteByte(true);
	bf.WriteString(szMessage);
	EndMessage();
}
/*****************************************************************************************************/

#define SOUND_CONNECT	"buttons/button11.wav"
#define SOUND_DISCONNECT "doors/default_locked.wav"

Address
	g_pServer;

ConVar
	g_cvBlackWhite,
	g_cvConnected,
	g_cvPlayerDeath,
	g_cvWitchstartled,
	g_cvGameIdle,
	g_cvCvarChange,
	g_cvSMNotity,
	g_cvGameDisconnect,
	g_cvFallSpeedSafe,
	g_cvFallSpeedFatal,
	g_cvSurvivorMaxInc;

bool
	g_bLateLoad,
	g_bBlackWhite,
	g_bConnected,
	g_bPlayerDeath,
	g_bWitchstartled,
	g_bGameIdle,
	g_bCvarChange,
	g_bSMNotity,
	g_bGameDisconnect;

int
	g_iSurvivorMaxInc,
	g_iInstructorEntRef[MAXPLAYERS + 1][MAXPLAYERS + 1];

float
	g_fFallSpeedSafe,
	g_fFallSpeedFatal;

static const char
	g_sZombieClass[][] = {
		"Smoker",
		"Boomer",
		"Hunter",
		"Spitter",
		"Jockey",
		"Charger",
		"Witch",
		"Tank"
	};

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	
	AddCommandListener(Listener_give, "give");
	HookUserMessage(GetUserMessageId("TextMsg"), umTextMsg, true);

	g_cvBlackWhite = CreateConVar("sms_bw_notify", "0", "黑白提示.");
	g_cvConnected = CreateConVar("sms_connected_notify", "0", "连接退出提示.");
	g_cvPlayerDeath = CreateConVar("sms_playerdeath_notify", "0", "死亡提示.");
	g_cvWitchstartled = CreateConVar("sms_witchstartled_notify", "0", "Witch惊扰提示.");
	g_cvGameIdle = CreateConVar("sms_game_idle_notify_block", "1", "屏蔽游戏自带的玩家闲置提示.");
	g_cvCvarChange = CreateConVar("sms_cvar_change_notify_block", "1", "屏蔽游戏自带的ConVar更改提示.");
	g_cvSMNotity = CreateConVar("sms_sourcemod_sm_notify_admin", "1", "屏蔽sourcemod平台自带的SM提示？(1-只向管理员显示,0-对所有人屏蔽).");
	g_cvGameDisconnect = CreateConVar("sms_game_disconnect_notify_block", "1", "屏蔽游戏自带的玩家离开提示.");

	//AutoExecConfig(true, "sms");

	g_cvFallSpeedSafe = FindConVar("fall_speed_safe");
	g_cvFallSpeedFatal = FindConVar("fall_speed_fatal");
	g_cvSurvivorMaxInc = FindConVar("survivor_max_incapacitated_count");
	g_cvFallSpeedSafe.AddChangeHook(CvarChanged);
	g_cvFallSpeedFatal.AddChangeHook(CvarChanged);
	g_cvSurvivorMaxInc.AddChangeHook(CvarChanged);

	g_cvBlackWhite.AddChangeHook(CvarChanged);
	g_cvConnected.AddChangeHook(CvarChanged);
	g_cvPlayerDeath.AddChangeHook(CvarChanged);
	g_cvWitchstartled.AddChangeHook(CvarChanged);
	g_cvGameIdle.AddChangeHook(CvarChanged);
	g_cvCvarChange.AddChangeHook(CvarChanged);
	g_cvSMNotity.AddChangeHook(CvarChanged);
	g_cvGameDisconnect.AddChangeHook(CvarChanged);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnAllPluginsLoaded() {
	g_pServer = L4D_GetPointer(POINTER_SERVER);
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_bBlackWhite = g_cvBlackWhite.BoolValue;
	g_bConnected = g_cvConnected.BoolValue;
	g_bPlayerDeath = g_cvPlayerDeath.BoolValue;
	g_bWitchstartled = g_cvWitchstartled.BoolValue;
	g_bGameIdle = g_cvGameIdle.BoolValue;
	g_bCvarChange = g_cvCvarChange.BoolValue;
	g_bSMNotity = g_cvSMNotity.BoolValue;
	g_bGameDisconnect = g_cvGameDisconnect.BoolValue;
	g_fFallSpeedSafe = g_cvFallSpeedSafe.FloatValue;
	g_fFallSpeedFatal = g_cvFallSpeedFatal.FloatValue;
	g_iSurvivorMaxInc = g_cvSurvivorMaxInc.IntValue;
}

Action Listener_give(int client, const char[] command, int argc) {
	if (!argc || !client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Continue;

	char sArg[7];
	GetCmdArg(1, sArg, sizeof sArg);
	if (strcmp(sArg, "health") == 0)
		RequestFrame(NextFrame_give, GetClientUserId(client));

	return Plugin_Continue;
}

void NextFrame_give(int client) {
	if ((client = GetClientOfUserId(client)) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_currentReviveCount") < g_iSurvivorMaxInc)
		EndInstructorHint(client);
}

public void OnMapStart() {
	PrecacheSound(SOUND_CONNECT);
	PrecacheSound(SOUND_DISCONNECT);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

// ------------------------------------------------------------------------
// 死亡提示
// ------------------------------------------------------------------------
void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype) {
	if (!g_bPlayerDeath)
		return;

	if (victim < 1 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || GetEntProp(victim, Prop_Data, "m_iHealth") > 0)
		return;

	EndInstructorHint(victim);

	int idlePlayer = GetIdlePlayerOfBot(victim);
	if (bIsValidClient(attacker)) {
		if (IsClientInGame(attacker)) {
			switch (GetClientTeam(attacker)) {
				case 2: {
					if (!idlePlayer)
						CPrintToChatAll("{green}★ {blue}%N {default}死亡 {green}| {olive}%N {green}| {default}伤害:{olive}%.1f", victim, attacker, damage);
					else
						CPrintToChatAll("{green}★ {blue}%N {default}死亡 {green}| {default}[{olive}闲置{default}]{blue}%N {green}| {default}伤害:{olive}%.1f", victim, idlePlayer, damage);
				}
			
				case 3: {
					if (IsFakeClient(attacker))
						CPrintToChatAll("{green}★ {olive}%N {default}死亡 {green}| {red}%N {green}| {default}伤害:{olive}%.1f", victim, attacker, damage);
					else
						CPrintToChatAll("{green}★ {olive}%N {default}死亡 {green}| {red}%N{default}({olive}%s{default}) {green}| {default}伤害:{olive}%.1f", victim, attacker, g_sZombieClass[GetEntProp(attacker, Prop_Send, "m_zombieClass") - 1], damage);
				}
			}
		}
	}
	else if (IsValidEntity(attacker)) {
		static char classname[32];
		GetEntityClassname(attacker, classname, sizeof classname);

		if (damagetype & DMG_DROWN && GetEntProp(victim, Prop_Data, "m_nWaterLevel") > 1)
			strcopy(classname, sizeof classname, "溺水");
		else if (damagetype & DMG_FALL && RoundToFloor(Pow(GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity") / (g_fFallSpeedFatal - g_fFallSpeedSafe), 2.0) * 100.0) == damage)
			strcopy(classname, sizeof classname, "坠落");
		else if (strcmp(classname, "worldspawn") == 0 && damagetype == 131072)
			strcopy(classname, sizeof classname, "流血");
		else if (strcmp(classname, "infected") == 0)
			strcopy(classname, sizeof classname, "僵尸");
		else if (strcmp(classname, "insect_swarm") == 0)
			strcopy(classname, sizeof classname, "spitterの痰");

		if (!idlePlayer)
			CPrintToChatAll("{green}★ {blue}%N {default}死亡 {green}| {olive}%s {green}| {default}伤害:{olive}%.1f", victim, classname, damage);
		else
			CPrintToChatAll("{green}★ {default}[{olive}闲置{default}]{blue}%N {default}死亡 {green}| {olive}%s {green}| {default}伤害:{olive}%.1f", idlePlayer, classname, damage);
	}
}

bool bIsValidClient(int client) {
	return 0 < client <= MaxClients;
}

//玩家连接文字+声音提示
public void OnClientConnected(int client) {
	if (!g_bConnected)
		return;

	if (IsFakeClient(client))
		return;

	int maxPlayers = GetMaxPlayers();
	if (maxPlayers < 1)
		return;

	int players = GetRealPlayers(-1);
	if (players < 1)
		return;

	PlaySound(SOUND_CONNECT);
	CPrintToChatAll("{green}★ {blue}%N {default}正在连接...{olive}(%d/%d)", client, players, maxPlayers);
}

// ------------------------------------------------------------------------
// 游戏自带的玩家离开游戏提示(聊天栏提示：XXX 离开了游戏。) -- 玩家断开连接文字+声音提示
// ------------------------------------------------------------------------
void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (g_bGameDisconnect)
		event.BroadcastDisabled = true;
	
	if (!g_bConnected)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client))
		return;

	int maxPlayers = GetMaxPlayers();
	if (maxPlayers < 1)
		return;
	
	int players = GetRealPlayers(client);
	if (players < 1)
		return;

	char sName[MAX_NAME_LENGTH], sReason[254];
	event.GetString("name", sName, sizeof sName);
	event.GetString("reason", sReason, sizeof sReason);

	PlaySound(SOUND_DISCONNECT);
	CPrintToChatAll("{green}☆ {blue}%s {default}离开了游戏{default}({green}%s{default})...{olive}(%d/%d)", sName, sReason, players, maxPlayers);
}

// ------------------------------------------------------------------------
// 游戏自带的闲置提示和sourcemod平台自带的[SM]提示
// ------------------------------------------------------------------------
Action umTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
	static char sMsg[254];
	msg.ReadString(sMsg, sizeof sMsg);

	if (g_bGameIdle && strcmp(sMsg, "\x03#L4D_idle_spectator") == 0) //聊天栏提示：XXX 现已闲置。
		return Plugin_Handled;
	else if (StrContains(sMsg, "\x03[SM]") == 0) {//聊天栏以[SM]开头的消息。
		if (g_bSMNotity) {
			DataPack dPack = new DataPack();
			dPack.WriteCell(playersNum);
			for (int i; i < playersNum; i++)
				dPack.WriteCell(players[i]);

			dPack.WriteString(sMsg);
			RequestFrame(NextFrame_SMMessage, dPack);
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//https://forums.alliedmods.net/showthread.php?t=187570
void NextFrame_SMMessage(DataPack dPack) {
	dPack.Reset();
	int playersNum = dPack.ReadCell();
	int[] players = new int[playersNum];

	int client, count;
	for (int i; i < playersNum; i++) {
		client = dPack.ReadCell();
		if (IsClientInGame(client) && !IsFakeClient(client) && CheckCommandAccess(client, "", ADMFLAG_ROOT))
			players[count++] = client;
	}
	
	if (!count) {
		delete dPack;
		return;
	}
	
	char sMsg[254];
	dPack.ReadString(sMsg, sizeof sMsg);
	delete dPack;

	ReplaceStringEx(sMsg, sizeof sMsg, "[SM]", "\x04[SM]\x05");
	BfWrite bf = view_as<BfWrite>(StartMessage("SayText2", players, count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(-1);
	bf.WriteByte(true);
	bf.WriteString(sMsg);
	EndMessage();
}

// ------------------------------------------------------------------------
// Witch惊扰提示
// ------------------------------------------------------------------------
void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bWitchstartled)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;

	switch (GetClientTeam(client)) {
		case 2: {
			int idlePlayer = GetIdlePlayerOfBot(client);
			if (!idlePlayer)
				CPrintToChatAll("{green}★ {blue}%N {default}惊扰了 {olive}witch", client);
			else
				CPrintToChatAll("{green}★ {default}[{olive}闲置{default}]{blue}%N {default}惊扰了 {olive}witch", idlePlayer);
		}
		
		case 3:
			CPrintToChatAll("{green}★ {red}%N {default}惊扰了 {olive}witch", client);
	}
}

// ------------------------------------------------------------------------
// ConVar更改提示
// ------------------------------------------------------------------------
Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast) {
	if (g_bCvarChange)
		return Plugin_Handled;

	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// 黑白提示
// ------------------------------------------------------------------------
void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bBlackWhite)
		return;

	if (event.GetBool("lastlife"))
		RequestFrame(NextFrame_LastLife, event.GetInt("subject"));
}

void NextFrame_LastLife(int client) {
	if ((client = GetClientOfUserId(client)) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_iSurvivorMaxInc) {
		char sText[254];
		int idlePlayer = GetIdlePlayerOfBot(client);
		if (!idlePlayer)
			FormatEx(sText, sizeof sText, "%N 已经黑白了", client);
		else
			FormatEx(sText, sizeof sText, "[闲置]%N 已经黑白了", idlePlayer);

		for (int i = 1; i <= MaxClients; i++) {
			if (i == client || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(client) != 2)
				continue;

			if (!idlePlayer)
				CPrintToChat(i, "{green}★ {blue}%N {default}进入 {olive}黑白状态", client);	
			else
				CPrintToChat(i, "{green}★ {default}[{blue}闲置{default}]{blue}%N {default}进入 {olive}黑白状态", idlePlayer);

			ShowHint(i, client, sText, "139 183 221", "icon_shield", "2", "25.0", "2000.0", "0");
		}
	}
}

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return;

	EndInstructorHint(client);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return;

	EndInstructorHint(client);
}

void ShowHint(int client, int target, const char[] sHintCaption, const char[] sHintColor = "255 255 255", const char[] sHintIconOn, const char[] sPulse = "0", const char[] sTimeout = "5.0", const char[] sHintRange = "2000.0", const char[] sHintType = "0") {
	int iEnt = CreateEntityByName("env_instructor_hint");
	if (iEnt == -1)
		return;

	g_iInstructorEntRef[client][target] = EntIndexToEntRef(iEnt);

	static char sTemp[64];
	if (target > -1) {
		FormatEx(sTemp, sizeof sTemp, "hint_target_%d", GetClientUserId(target));
		DispatchKeyValue(target, "targetname", sTemp);
	}
	else {
		FormatEx(sTemp, sizeof sTemp, "hint_target_%d", EntIndexToEntRef(iEnt));
		DispatchKeyValue(client, "targetname", sTemp);
	}

	DispatchKeyValue(iEnt, "hint_target", sTemp);
	DispatchKeyValue(iEnt, "hint_allow_nodraw_target", "1");
	DispatchKeyValue(iEnt, "hint_caption", sHintCaption);
	DispatchKeyValue(iEnt, "hint_color", sHintColor);
	DispatchKeyValue(iEnt, "hint_forcecaption", "1");
	DispatchKeyValue(iEnt, "hint_icon_onscreen", sHintIconOn);
	DispatchKeyValue(iEnt, "hint_nooffscreen", "0");
	DispatchKeyValue(iEnt, "hint_pulseoption", sPulse);
	DispatchKeyValue(iEnt, "hint_timeout", sTimeout);
	DispatchKeyValue(iEnt, "hint_range", sHintRange);
	DispatchKeyValue(iEnt, "hint_display_limit", "0");
	DispatchKeyValue(iEnt, "hint_instance_type", sHintType);

	DispatchSpawn(iEnt);
	AcceptEntityInput(iEnt, "ShowHint", client);

	FormatEx(sTemp, sizeof sTemp, "OnUser1 !self:Kill::%s:-1", sTimeout);
	SetVariantString(sTemp);
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}

void EndInstructorHint(int client) {
	int iEnt;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsValidEntRef(g_iInstructorEntRef[i][client]))
			continue;

		iEnt = g_iInstructorEntRef[i][client];
		g_iInstructorEntRef[i][client] = 0;

		RemoveEntity(iEnt);
	}
}

bool IsValidEntRef(int iEnt) {
	return iEnt && EntRefToEntIndex(iEnt) != -1;
}

int GetMaxPlayers() {
	static ConVar hndl;
	if (!hndl)
		hndl = FindConVar("sv_maxplayers");

	int maxPlayers;
	if (hndl) {
		maxPlayers = hndl.IntValue;
		return maxPlayers != -1 ? maxPlayers : GetModePlayers();
	}
	
	return GetModePlayers();
}

int GetModePlayers() {
	return !g_pServer ? 0 : LoadFromAddress(g_pServer + view_as<Address>(380), NumberType_Int32);
}

int GetRealPlayers(int client) {
	int players;
	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientConnected(i) && !IsFakeClient(i))
			players++;
	}
	return players;
}

void PlaySound(const char[] sSound) {
	EmitSoundToAll(sSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

int GetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}
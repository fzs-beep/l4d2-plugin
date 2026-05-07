//fdxx, BHaType	@ 2021
//Harry @ 2022

#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#undef REQUIRE_PLUGIN

#define MAXENTITIES 2048
#define MODEL_MARK_FIELD 	"materials/sprites/laserbeam.vmt"
#define CLASSNAME_INFO_TARGET         "info_target"
#define CLASSNAME_ENV_SPRITE          "env_sprite"
#define ENTITY_WORLDSPAWN             0
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ENTITY_SAFE_LIMIT 2000

// 1. 物品提示
ConVar 	g_hItemHintCoolDown, g_hItemUseSound, g_hItemAnnounceType,
       	g_hItemGlowTimer, g_hItemGlowRange, g_hItemCvarColor, g_hItemInstructorHint,
       	g_hItemInstructorColor, g_hItemInstructorIcon;
int 	g_iItemAnnounceType, g_iItemGlowRange, g_iItemCvarColor;
float 	g_fItemHintCoolDown, g_fItemGlowTimer, g_fItemHintCoolDownTime[MAXPLAYERS + 1];
char 	g_sItemUseSound[100], g_sItemInstructorColor[12], g_sItemInstructorIcon[16];
bool 	g_bItemInstructorHint;

// 2. 标记设置
ConVar	g_hSpotMarkCoolDown, g_hSpotMarkUseRange, g_hSpotMarkUseSound, g_hSpotAnnounceType,
      	g_hSpotMarkGlowTimer, g_hSpotMarkCvarColor, g_hSpotMarkSpriteModel, g_hSpotMarkInstructorHint,
      	g_hSpotMarkInstructorColor, g_hSpotMarkInstructorIcon;
int 	g_iSpotAnnounceType, g_iSpotMarkCvarColorArray[3];
float 	g_fSpotMarkCoolDown, g_fSpotMarkUseRange, g_fSpotMarkGlowTimer, g_fSpotMarkCoolDownTime[MAXPLAYERS + 1];
char 	g_sSpotMarkUseSound[100], g_sSpotMarkCvarColor[12], g_sSpotMarkInstructorColor[12],
     	g_sSpotMarkInstructorIcon[16], g_sSpotMarkSpriteModel[PLATFORM_MAX_PATH];
bool 	g_bSpotMarkInstructorHint;

// 3. 标记感染者
ConVar 	g_hInfectedMarkCoolDown, g_hInfectedMarkUseRange, g_hInfectedMarkUseSound, g_hInfectedMarkAnnounceType,
       	g_hInfectedMarkGlowTimer, g_hInfectedMarkGlowRange, g_hInfectedMarkCvarColor, g_hInfectedMarkWitch;
int 	g_iInfectedMarkAnnounceType, g_iInfectedMarkGlowRange, g_iInfectedMarkCvarColor;
float 	g_fInfectedMarkCoolDown, g_fInfectedMarkUseRange, g_fInfectedMarkGlowTimer, g_fInfectedMarkCoolDownTime[MAXPLAYERS + 1];
char 	g_sInfectedMarkUseSound[100];
bool 	g_bInfectedMarkWitch = false;

// 4. 标记队友
ConVar 	g_hSakiko_TeammateMarkEnable, g_hSakiko_TeammateMarkCoolDown, g_hSakiko_TeammateMarkUseSound, g_hSakiko_TeammateMarkAnnounceType,
       	g_hSakiko_TeammateMarkGlowTimer, g_hSakiko_TeammateMarkCvarColor;
int 	Sakiko_TeammateMarkAnnounceType, Sakiko_TeammateMarkCvarColor;
float 	Sakiko_TeammateMarkCoolDown, Sakiko_TeammateMarkGlowTimer, Sakiko_TeammateMarkCoolDownTime[MAXPLAYERS + 1];
char 	Sakiko_TeammateMarkUseSound[100];
bool 	Sakiko_TeammateMarkEnable = false;

// 5. 标记实体
ConVar 	g_hSakiko_EntityMarkEnable, g_hSakiko_EntityMarkUseSound, g_hSakiko_EntityMarkAnnounceType,
       	g_hSakiko_EntityMarkGlowTimer, g_hSakiko_EntityMarkCvarColor, g_hSakiko_EntityMarkGlowRange,
       	g_hSakiko_EntityMarkTest;
int 	Sakiko_EntityMarkCvarColor, Sakiko_EntityMarkAnnounceType, Sakiko_EntityMarkGlowRange;
float 	Sakiko_EntityMarkGlowTimer;
char 	Sakiko_EntityMarkUseSound[100];
bool 	Sakiko_EntityMarkEnable, Sakiko_EntityMarkTest;

// 其他
char g_sKillDelay[32];

static bool   	ge_bMoveUp[MAXENTITIES+1];
int       		g_iModelIndex[MAXENTITIES+1] = {0};
Handle    		g_iModelTimer[MAXENTITIES+1] = {null};
int       		g_iInstructorIndex[MAXENTITIES+1] = {0};
Handle    		g_iInstructorTimer[MAXENTITIES+1] = {null};
int       		g_iTargetInstructorIndex[MAXENTITIES+1] = {0};
Handle    		g_iTargetInstructorTimer[MAXENTITIES+1] = {null};
StringMap 		g_smModelToName;
StringMap 		g_smModelHeight;

enum struct GlowData
{
	int GlowType;
	int GlowColor;
	bool IsGlowing;
	bool IsManagedByPlugin;
}
GlowData g_OriginalGlowState[MAXENTITIES+1];

bool g_bMapStarted;

enum EHintType {
	eItemHint,
	eSpotMarker,
	eInfectedMaker,
	eTeammateMarker,
	eEntityMarker,
}

static char randomPrefixes[][] = {
    "MyGO!!!!!", "Tomori", "Anon", "Rāna", "Soyo", "Taki", "AveMujica", "Sakiko",
    "Oblivionis", "Uika", "Doloris", "Mutsumi", "Mortis", "Umiri", "Timoris", "Nyamu", "Amoris"
};

public Plugin myinfo =
{
	name        = "L4D2 Item hint",
	author      = "BHaType, fdxx, HarryPotter, TogawaSakiko",
	description = "When using 'Look' in vocalize menu, print corresponding item to chat area and make item glow or create spot marker/infeced maker like back 4 blood.",
	version     = "3.0",
	url         = "https://forums.alliedmods.net/showpost.php?p=2765332&postcount=30"
};

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hGameData = new GameData("l4d2_item_hint");
	if (hGameData != null)
	{
		int iOffset = hGameData.GetOffset("FindUseEntity");
		if (iOffset != -1)
		{
			// https://forums.alliedmods.net/showpost.php?p=2753773&postcount=2
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetVirtual(iOffset);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		}
		else SetFailState("Failed to load offset");
	}
	else SetFailState("Failed to load l4d2_item_hint.txt file");
	delete hGameData;
	// g_hItemUseHintRange = FindConVar("player_use_radius");
	AddCommandListener(Vocalize_Listener, "vocalize");
    // 物品提示
    g_hItemHintCoolDown         	= CreateConVar("l4d2_item_hint_cooldown_time", 		"1.5", 					"玩家再次物品提示的冷却时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hItemUseSound             	= CreateConVar("l4d2_item_hint_use_sound", 			"buttons/blip1.wav", 	"物品提示音效（sound/下相关目录，空 = 关闭）", FCVAR_NOTIFY);
    g_hItemAnnounceType         	= CreateConVar("l4d2_item_hint_announce_type", 		"1", 					"物品提示显示方式（0: 关闭, 1: 聊天框, 2: 提示框, 3: 屏幕中央文字）", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    g_hItemGlowTimer            	= CreateConVar("l4d2_item_hint_glow_timer", 		"30.0", 				"物品发光持续时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hItemGlowRange            	= CreateConVar("l4d2_item_hint_glow_range", 		"1300", 				"物品发光范围", FCVAR_NOTIFY, true, 0.0);
    g_hItemCvarColor            	= CreateConVar("l4d2_item_hint_glow_color", 		"119 153 204", 			"物品发光颜色（空 = 关闭物品发光）", FCVAR_NOTIFY);
    g_hItemInstructorHint       	= CreateConVar("l4d2_item_instructorhint_enable", 	"1", 					"如果为1，在标记的物品上创建指引提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hItemInstructorColor      	= CreateConVar("l4d2_item_instructorhint_color", 	"119 153 204", 			"标记物品的指引提示颜色", FCVAR_NOTIFY);
    g_hItemInstructorIcon       	= CreateConVar("l4d2_item_instructorhint_icon", 	"icon_interact", 		"标记物品的指引图标名称（更多图标参考：https://developer.valvesoftware.com/wiki/Env_instructor_hint）", FCVAR_NOTIFY);
			
    // 标记设置						
    g_hSpotMarkCoolDown         	= CreateConVar("l4d2_spot_marker_cooldown_time", 	"2.5", 					"玩家再次标记点的冷却时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hSpotMarkUseRange         	= CreateConVar("l4d2_spot_marker_use_range", 		"1600", 				"玩家标记点的距离范围", FCVAR_NOTIFY, true, 1.0);
    g_hSpotMarkUseSound         	= CreateConVar("l4d2_spot_marker_use_sound", 		"buttons/blip1.wav", 	"标记点音效（sound/下相关目录，空 = 关闭）", FCVAR_NOTIFY);
    g_hSpotAnnounceType         	= CreateConVar("l4d2_spot_marker_announce_type", 	"1", 					"标记点提示显示方式（0: 关闭, 1: 聊天框, 2: 提示框, 3: 屏幕中央文字）", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    g_hSpotMarkGlowTimer        	= CreateConVar("l4d2_spot_marker_duration", 		"15.0", 				"标记点持续时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hSpotMarkCvarColor        	= CreateConVar("l4d2_spot_marker_color", 			"0 255 255", 			"标记点发光颜色（空 = 关闭标记点）", FCVAR_NOTIFY);
    g_hSpotMarkSpriteModel      	= CreateConVar("l4d2_spot_marker_sprite_model", 	"materials/vgui/icon_download.vmt", 	"标记点上方箭头路径（空 = 关闭）", FCVAR_NOTIFY);
    g_hSpotMarkInstructorHint   	= CreateConVar("l4d2_spot_marker_instructorhint_enable", "1", 					"如果为1，在标记点上创建指引提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSpotMarkInstructorColor  	= CreateConVar("l4d2_spot_marker_instructorhint_color", "200 200 200", 			"标记点的指引提示颜色", FCVAR_NOTIFY);
    g_hSpotMarkInstructorIcon   	= CreateConVar("l4d2_spot_marker_instructorhint_icon", 	"", 					"标记点的指引图标名称（更多图标参考：https://developer.valvesoftware.com/wiki/Env_instructor_hint）", FCVAR_NOTIFY);

    // 标记感染者	
    g_hInfectedMarkCoolDown     	= CreateConVar("l4d2_infected_marker_cooldown_time", 	"1.0", 					"玩家再次标记感染者的冷却时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hInfectedMarkUseRange     	= CreateConVar("l4d2_infected_marker_use_range", 		"1800", 					"玩家标记感染者的距离范围", FCVAR_NOTIFY, true, 1.0);
    g_hInfectedMarkUseSound     	= CreateConVar("l4d2_infected_marker_use_sound", 		"items/suitchargeok1.wav", 	"标记感染者音效（sound/下相关目录，空 = 关闭）", FCVAR_NOTIFY);
    g_hInfectedMarkAnnounceType 	= CreateConVar("l4d2_infected_marker_announce_type", 	"1", 						"标记感染者提示显示方式（0: 关闭, 1: 聊天框, 2: 提示框, 3: 屏幕中央文字）", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    g_hInfectedMarkGlowTimer    	= CreateConVar("l4d2_infected_marker_glow_timer", 		"10.0", 					"标记感染者发光持续时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hInfectedMarkGlowRange    	= CreateConVar("l4d2_infected_marker_glow_range", 		"2500", 					"标记感染者发光范围", FCVAR_NOTIFY, true, 0.0);
    g_hInfectedMarkCvarColor    	= CreateConVar("l4d2_infected_marker_glow_color", 		"255 50 50", 				"标记感染者发光颜色（空 = 关闭标记感染者）", FCVAR_NOTIFY);
    g_hInfectedMarkWitch        	= CreateConVar("l4d2_infected_marker_witch_enable", 	"1", 						"是否允许标记Witch", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	// 标记队友
	g_hSakiko_TeammateMarkEnable     	= CreateConVar("sakiko_teammate_marker_enable", 		"1", 					"是否启用标记队友功能?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSakiko_TeammateMarkCoolDown   	= CreateConVar("sakiko_teammate_marker_cooldown_time", 	"2.0", 					"玩家再次标记队友的冷却时间（秒）", FCVAR_NOTIFY, true, 0.0);
	g_hSakiko_TeammateMarkUseSound   	= CreateConVar("sakiko_teammate_marker_use_sound", 		"buttons/blip1.wav", 	"标记队友音效（sound/下相关目录，空 = 关闭）", FCVAR_NOTIFY);
	g_hSakiko_TeammateMarkAnnounceType  = CreateConVar("sakiko_teammate_marker_announce_type", 	"1", 					"标记队友提示显示方式（0: 关闭, 1: 聊天框, 2: 提示框, 3: 屏幕中央文字）", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hSakiko_TeammateMarkGlowTimer  	= CreateConVar("sakiko_teammate_marker_glow_timer", 	"10.0", 				"标记队友发光持续时间（秒）", FCVAR_NOTIFY, true, 0.0);
	g_hSakiko_TeammateMarkCvarColor  	= CreateConVar("sakiko_teammate_marker_glow_color", 	"119 153 119", 			"标记队友发光颜色（空 = 关闭发光）", FCVAR_NOTIFY);

	// 标记实体
    g_hSakiko_EntityMarkEnable        	= CreateConVar("sakiko_entity_marker_enable", 			"1", 					"是否启用标记实体功能", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hSakiko_EntityMarkUseSound      	= CreateConVar("sakiko_entity_marker_use_sound", 		"buttons/blip1.wav", 	"标记实体音效（sound/下相关目录，空 = 关闭）", FCVAR_NOTIFY);
    g_hSakiko_EntityMarkAnnounceType  	= CreateConVar("sakiko_entity_marker_announce_type", 	"1", 					"标记实体提示显示方式（0: 关闭, 1: 聊天框, 2: 提示框, 3: 屏幕中央文字）", FCVAR_NOTIFY, true, 0.0, true, 3.0);
    g_hSakiko_EntityMarkGlowTimer     	= CreateConVar("sakiko_entity_marker_glow_timer", 		"15.0", 				"标记实体发光持续时间（秒）", FCVAR_NOTIFY, true, 0.0);
    g_hSakiko_EntityMarkCvarColor     	= CreateConVar("sakiko_entity_marker_glow_color", 		"187 153 85", 			"标记实体发光颜色（空 = 关闭发光）", FCVAR_NOTIFY);
    g_hSakiko_EntityMarkGlowRange     	= CreateConVar("sakiko_entity_marker_glow_range", 		"8000", 				"标记实体发光可见距离", FCVAR_NOTIFY, true, 0.0);
	g_hSakiko_EntityMarkTest          	= CreateConVar("sakiko_entity_marker_test", 			"0", 					"是否开启标记实体时显示完整模型路径", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GetCvars();
	g_hItemHintCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hItemUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hItemAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hItemGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hItemGlowRange.AddChangeHook(ConVarChanged_Cvars);
	g_hItemCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hItemInstructorHint.AddChangeHook(ConVarChanged_Cvars);
	g_hItemInstructorColor.AddChangeHook(ConVarChanged_Cvars);
	g_hItemInstructorIcon.AddChangeHook(ConVarChanged_Cvars);

	g_hSpotMarkCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkUseRange.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkSpriteModel.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkInstructorHint.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkInstructorColor.AddChangeHook(ConVarChanged_Cvars);
	g_hSpotMarkInstructorIcon.AddChangeHook(ConVarChanged_Cvars);

	g_hInfectedMarkCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkUseRange.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkGlowRange.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hInfectedMarkWitch.AddChangeHook(ConVarChanged_Cvars);

	g_hSakiko_TeammateMarkEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_TeammateMarkCoolDown.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_TeammateMarkUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_TeammateMarkAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_TeammateMarkGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_TeammateMarkCvarColor.AddChangeHook(ConVarChanged_Cvars);
	
	g_hSakiko_EntityMarkEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_EntityMarkUseSound.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_EntityMarkGlowTimer.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_EntityMarkCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hSakiko_EntityMarkAnnounceType.AddChangeHook(ConVarChanged_Cvars);
    g_hSakiko_EntityMarkGlowRange.AddChangeHook(ConVarChanged_Cvars);
    g_hSakiko_EntityMarkTest.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_Round_End);
	HookEvent("map_transition", Event_Round_End);            //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", Event_Round_End);              //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_Round_End);    //救援載具離開之時  (沒有觸發round_end)
	HookEvent("spawner_give_item", Event_SpawnerGiveItem);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_killed", Event_WitchKilled);

	CreateStringMap();

	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	delete g_smModelToName;
	delete g_smModelHeight;
	RemoveAllGlow_Timer();
	RemoveAllSpotMark();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	// 物品提示
	g_fItemHintCoolDown = g_hItemHintCoolDown.FloatValue;
	g_hItemUseSound.GetString(g_sItemUseSound, sizeof(g_sItemUseSound));
	if (strlen(g_sItemUseSound) > 0 && g_bMapStarted) PrecacheSound(g_sItemUseSound);
	g_iItemAnnounceType = g_hItemAnnounceType.IntValue;
	g_fItemGlowTimer = g_hItemGlowTimer.FloatValue;
	g_iItemGlowRange = g_hItemGlowRange.IntValue;
	char sColor[16];
	g_hItemCvarColor.GetString(sColor, sizeof(sColor));
	g_iItemCvarColor = GetColor(sColor);
	g_bItemInstructorHint = g_hItemInstructorHint.BoolValue;
	g_hItemInstructorColor.GetString(g_sItemInstructorColor, sizeof(g_sItemInstructorColor));
	TrimString(g_sItemInstructorColor);
	g_hItemInstructorIcon.GetString(g_sItemInstructorIcon, sizeof(g_sItemInstructorIcon));

	// 标记设置
	g_fSpotMarkCoolDown = g_hSpotMarkCoolDown.FloatValue;
	g_fSpotMarkUseRange = g_hSpotMarkUseRange.FloatValue;
	g_hSpotMarkUseSound.GetString(g_sSpotMarkUseSound, sizeof(g_sSpotMarkUseSound));
	if (strlen(g_sSpotMarkUseSound) > 0 && g_bMapStarted) PrecacheSound(g_sSpotMarkUseSound);
	g_iSpotAnnounceType = g_hSpotAnnounceType.IntValue;
	g_fSpotMarkGlowTimer = g_hSpotMarkGlowTimer.FloatValue;
	FormatEx(g_sKillDelay, sizeof(g_sKillDelay), "OnUser1 !self:Kill::%.2f:-1", g_fSpotMarkGlowTimer);
	g_hSpotMarkCvarColor.GetString(g_sSpotMarkCvarColor, sizeof(g_sSpotMarkCvarColor));
	TrimString(g_sSpotMarkCvarColor);
	g_iSpotMarkCvarColorArray = ConvertRGBToIntArray(g_sSpotMarkCvarColor);
	g_hSpotMarkSpriteModel.GetString(g_sSpotMarkSpriteModel, sizeof(g_sSpotMarkSpriteModel));
	TrimString(g_sSpotMarkSpriteModel);
	if (strlen(g_sSpotMarkSpriteModel) > 0 && g_bMapStarted) PrecacheModel(g_sSpotMarkSpriteModel, true);
	g_bSpotMarkInstructorHint = g_hSpotMarkInstructorHint.BoolValue;
	g_hSpotMarkInstructorColor.GetString(g_sSpotMarkInstructorColor, sizeof(g_sSpotMarkInstructorColor));
	TrimString(g_sSpotMarkInstructorColor);
	g_hSpotMarkInstructorIcon.GetString(g_sSpotMarkInstructorIcon, sizeof(g_sSpotMarkInstructorIcon));

	// 标记感染者
	g_fInfectedMarkCoolDown = g_hInfectedMarkCoolDown.FloatValue;
	g_fInfectedMarkUseRange = g_hInfectedMarkUseRange.FloatValue;
	g_hInfectedMarkUseSound.GetString(g_sInfectedMarkUseSound, sizeof(g_sInfectedMarkUseSound));
	if (strlen(g_sInfectedMarkUseSound) > 0 && g_bMapStarted) PrecacheSound(g_sInfectedMarkUseSound);
	g_iInfectedMarkAnnounceType = g_hInfectedMarkAnnounceType.IntValue;
	g_fInfectedMarkGlowTimer = g_hInfectedMarkGlowTimer.FloatValue;
	g_iInfectedMarkGlowRange = g_hInfectedMarkGlowRange.IntValue;
	g_hInfectedMarkCvarColor.GetString(sColor, sizeof(sColor));
	g_iInfectedMarkCvarColor = GetColor(sColor);
	g_bInfectedMarkWitch = g_hInfectedMarkWitch.BoolValue;

	// 标记队友
	Sakiko_TeammateMarkEnable = g_hSakiko_TeammateMarkEnable.BoolValue;
	Sakiko_TeammateMarkCoolDown = g_hSakiko_TeammateMarkCoolDown.FloatValue;
	g_hSakiko_TeammateMarkUseSound.GetString(Sakiko_TeammateMarkUseSound, sizeof(Sakiko_TeammateMarkUseSound));
	if (strlen(Sakiko_TeammateMarkUseSound) > 0 && g_bMapStarted) PrecacheSound(Sakiko_TeammateMarkUseSound);
	Sakiko_TeammateMarkAnnounceType = g_hSakiko_TeammateMarkAnnounceType.IntValue;
	Sakiko_TeammateMarkGlowTimer = g_hSakiko_TeammateMarkGlowTimer.FloatValue;
	g_hSakiko_TeammateMarkCvarColor.GetString(sColor, sizeof(sColor));
	Sakiko_TeammateMarkCvarColor = GetColor(sColor);

	// 标记实体
	Sakiko_EntityMarkEnable = g_hSakiko_EntityMarkEnable.BoolValue;
	g_hSakiko_EntityMarkUseSound.GetString(Sakiko_EntityMarkUseSound, sizeof(Sakiko_EntityMarkUseSound));
	if (strlen(Sakiko_EntityMarkUseSound) > 0 && g_bMapStarted) PrecacheSound(Sakiko_EntityMarkUseSound);
	Sakiko_EntityMarkAnnounceType = g_hSakiko_EntityMarkAnnounceType.IntValue;
	Sakiko_EntityMarkGlowTimer = g_hSakiko_EntityMarkGlowTimer.FloatValue;
	g_hSakiko_EntityMarkCvarColor.GetString(sColor, sizeof(sColor));
	Sakiko_EntityMarkCvarColor = GetColor(sColor);
    Sakiko_EntityMarkGlowRange = g_hSakiko_EntityMarkGlowRange.IntValue;
    Sakiko_EntityMarkTest = g_hSakiko_EntityMarkTest.BoolValue;
}

void CreateStringMap()
{
	g_smModelToName = new StringMap();

	// Case-sensitive
	g_smModelToName.SetString("models/w_models/weapons/w_eq_medkit.mdl", "这里有包包!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_defibrillator.mdl", "电击器!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_painpills.mdl", "筑基丹");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_adrenaline.mdl", "这里有针!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_bile_flask.mdl", "这绿绿的东西能喝喵~");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_molotov.mdl", "燃烧瓶!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_pipebomb.mdl", "这里有‘滴-滴-滴-嘣’!");
	g_smModelToName.SetString("models/w_models/weapons/w_laser_sights.mdl", "激光瞄准器!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_incendiary_ammopack.mdl", "燃烧弹药盒!");
	g_smModelToName.SetString("models/w_models/weapons/w_eq_explosive_ammopack.mdl", "高爆弹药盒!");
	g_smModelToName.SetString("models/props/terror/ammo_stack.mdl", "子弹补给!");
	g_smModelToName.SetString("models/props_unique/spawn_apartment/coffeeammo.mdl", "子弹补给!");
	g_smModelToName.SetString("models/props/de_prodigy/ammo_can_02.mdl", "子弹补给!");
	g_smModelToName.SetString("models/weapons/melee/w_chainsaw.mdl", "电锯!");
	g_smModelToName.SetString("models/w_models/weapons/w_pistol_b.mdl", "手枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_pistol_a.mdl", "手枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_eagle.mdl", "马格南!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun.mdl", "木喷!");
	g_smModelToName.SetString("models/w_models/weapons/w_pumpshotgun_a.mdl", "铁喷!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_uzi.mdl", "UZI冲锋枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_a.mdl", "Mac消音冲锋枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_smg_mp5.mdl", "MP5冲锋枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_m16a2.mdl", "M16步枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_sg552.mdl", "SG552步枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_rifle_ak47.mdl", "AK47步枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_desert_rifle.mdl", "SCAR三连发!");
	g_smModelToName.SetString("models/w_models/weapons/w_shotgun_spas.mdl", "二代连喷!");
	g_smModelToName.SetString("models/w_models/weapons/w_autoshot_m4super.mdl", "一代连喷!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_mini14.mdl", "15发木狙!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_military.mdl", "30发军狙!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_scout.mdl", "Scout!");
	g_smModelToName.SetString("models/w_models/weapons/w_sniper_awp.mdl", "AWP!");
	g_smModelToName.SetString("models/w_models/weapons/w_grenade_launcher.mdl", "榴弹发射器!");
	g_smModelToName.SetString("models/w_models/weapons/w_m60.mdl", "M60!");
	g_smModelToName.SetString("models/props_junk/gascan001a.mdl", "汽油桶!");
	g_smModelToName.SetString("models/props_junk/explosive_box001.mdl", "烟花盒!");
	g_smModelToName.SetString("models/props_junk/propanecanister001a.mdl", "丙烷罐!");
	g_smModelToName.SetString("models/props_equipment/oxygentank01.mdl", "氧气罐!");
	g_smModelToName.SetString("models/props_junk/gnome.mdl", "侏儒!");
	g_smModelToName.SetString("models/w_models/weapons/w_cola.mdl", "百事可乐!");
	g_smModelToName.SetString("models/w_models/weapons/50cal.mdl", ".50cal重机枪!");
	g_smModelToName.SetString("models/w_models/weapons/w_minigun.mdl", "加特林机枪!");
	g_smModelToName.SetString("models/props/terror/exploding_ammo.mdl", "高爆弹!");
	g_smModelToName.SetString("models/props/terror/incendiary_ammo.mdl", "燃烧弹!");
	g_smModelToName.SetString("models/w_models/weapons/w_knife_t.mdl", "小刀!");
	g_smModelToName.SetString("models/weapons/melee/w_bat.mdl", "棒球棍!");
	g_smModelToName.SetString("models/weapons/melee/w_cricket_bat.mdl", "板球拍!");
	g_smModelToName.SetString("models/weapons/melee/w_crowbar.mdl", "撬棍!");
	g_smModelToName.SetString("models/weapons/melee/w_electric_guitar.mdl", "电吉他!");
	g_smModelToName.SetString("models/weapons/melee/w_fireaxe.mdl", "消防斧!");
	g_smModelToName.SetString("models/weapons/melee/w_frying_pan.mdl", "平底锅!");
	g_smModelToName.SetString("models/weapons/melee/w_katana.mdl", "武士刀!");
	g_smModelToName.SetString("models/weapons/melee/w_machete.mdl", "砍刀!");
	g_smModelToName.SetString("models/weapons/melee/w_tonfa.mdl", "警棍!");
	g_smModelToName.SetString("models/weapons/melee/w_golfclub.mdl", "高尔夫球棍!");
	g_smModelToName.SetString("models/weapons/melee/w_pitchfork.mdl", "干草叉!");
	g_smModelToName.SetString("models/weapons/melee/w_shovel.mdl", "铲子!");
	g_smModelToName.SetString("models/weapons/melee/w_riotshield.mdl", "无敌的盾牌!");
	g_smModelToName.SetString("models/infected/boomette.mdl", "Boomer!");
	g_smModelToName.SetString("models/infected/boomer.mdl", "Boomer!");
	g_smModelToName.SetString("models/infected/boomer_l4d1.mdl", "傻逼Boomer!");
	g_smModelToName.SetString("models/infected/hulk.mdl", "妈耶！大块头，我要上去干它!");
	g_smModelToName.SetString("models/infected/hulk_l4d1.mdl", "妈耶！大块头，我要上去干它!");
	g_smModelToName.SetString("models/infected/hulk_dlc3.mdl", "妈耶！大块头，我要上去干它!");
	g_smModelToName.SetString("models/infected/smoker.mdl", "舌头!");
	g_smModelToName.SetString("models/infected/smoker_l4d1.mdl", "舌头!");
	g_smModelToName.SetString("models/infected/hunter.mdl", "Hunter!");
	g_smModelToName.SetString("models/infected/hunter_l4d1.mdl", "Hunter!");
	g_smModelToName.SetString("models/infected/witch.mdl", "有妹子！退后，我要开始装B了!");
	g_smModelToName.SetString("models/infected/witch_bride.mdl", "有妹子！退后，我要开始装B了!");
	g_smModelToName.SetString("models/infected/spitter.mdl", "口水!");
	g_smModelToName.SetString("models/infected/jockey.mdl", "猴子!");
	g_smModelToName.SetString("models/infected/charger.mdl", "蛮牛冲撞!");
    g_smModelToName.SetString("models/props_doors/checkpoint_door_02.mdl", "安全门!");
    g_smModelToName.SetString("models/props/terror/hamradio.mdl", "过来开救援!");
    g_smModelToName.SetString("models/props_unique/generator_switch_01.mdl", "过来开机关!");

	g_smModelHeight = CreateTrie();

	// Case-sensitive
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_medkit.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_defibrillator.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_painpills.mdl", 5.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_adrenaline.mdl", 5.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_bile_flask.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_molotov.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_pipebomb.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_laser_sights.mdl", 18.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_incendiary_ammopack.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_eq_explosive_ammopack.mdl", 10.0);
	g_smModelHeight.SetValue("models/props/terror/ammo_stack.mdl", 5.0);
	g_smModelHeight.SetValue("models/props_unique/spawn_apartment/coffeeammo.mdl", 15.0);
	g_smModelHeight.SetValue("models/props/de_prodigy/ammo_can_02.mdl", 10.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_chainsaw.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_pistol_b.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_pistol_a.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_desert_eagle.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_shotgun.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_pumpshotgun_a.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_smg_uzi.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_smg_a.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_smg_mp5.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_rifle_m16a2.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_rifle_sg552.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_rifle_ak47.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_desert_rifle.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_shotgun_spas.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_autoshot_m4super.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_sniper_mini14.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_sniper_military.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_sniper_scout.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_sniper_awp.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_grenade_launcher.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_m60.mdl", 10.0);
	g_smModelHeight.SetValue("models/props_junk/gascan001a.mdl", 5.0);
	g_smModelHeight.SetValue("models/props_junk/explosive_box001.mdl", 5.0);
	g_smModelHeight.SetValue("models/props_junk/propanecanister001a.mdl", 5.0);
	g_smModelHeight.SetValue("models/props_equipment/oxygentank01.mdl", 5.0);
	g_smModelHeight.SetValue("models/props_junk/gnome.mdl", 10.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_cola.mdl", 5.0);
	g_smModelHeight.SetValue("models/w_models/weapons/50cal.mdl", 55.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_minigun.mdl", 55.0);
	g_smModelHeight.SetValue("models/props/terror/exploding_ammo.mdl", 15.0);
	g_smModelHeight.SetValue("models/props/terror/incendiary_ammo.mdl", 15.0);
	g_smModelHeight.SetValue("models/w_models/weapons/w_knife_t.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_bat.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_cricket_bat.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_crowbar.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_electric_guitar.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_fireaxe.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_frying_pan.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_katana.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_machete.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_tonfa.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_golfclub.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_pitchfork.mdl", 5.0);
	g_smModelHeight.SetValue("models/weapons/melee/w_shovel.mdl", 5.0);
}

int g_iFieldModelIndex;
public void OnMapStart()
{
	g_bMapStarted = true;
	if (strlen(g_sItemUseSound) > 0) PrecacheSound(g_sItemUseSound);
	if (strlen(g_sSpotMarkUseSound) > 0) PrecacheSound(g_sSpotMarkUseSound);
	if (strlen(g_sInfectedMarkUseSound) > 0) PrecacheSound(g_sInfectedMarkUseSound);
	if (strlen(Sakiko_TeammateMarkUseSound) > 0) PrecacheSound(Sakiko_TeammateMarkUseSound);
	if (strlen(Sakiko_EntityMarkUseSound) > 0) PrecacheSound(Sakiko_EntityMarkUseSound);
	g_iFieldModelIndex = PrecacheModel(MODEL_MARK_FIELD, true);
	if ( strlen(g_sSpotMarkSpriteModel) > 0 ) PrecacheModel(g_sSpotMarkSpriteModel, true);

}

public void OnMapEnd()
{
	g_bMapStarted = false;
	RemoveAllGlow_Timer();
}

public void OnClientPutInServer(int client)
{
	Clear(client);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if (!IsValidEntity(weapon))
		return;

	RemoveEntityModelGlow(weapon);
	delete g_iModelTimer[weapon];

	RemoveInstructor(weapon);
	delete g_iInstructorTimer[weapon];

	RemoveTargetInstructor(weapon);
	delete g_iTargetInstructorTimer[weapon];
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Clear();
}

public void Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	RemoveAllGlow_Timer();
	RemoveAllSpotMark();
}

public void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("spawner");
	int count  = GetEntProp(entity, Prop_Data, "m_itemCount");

	if (count <= 1)
	{
		RemoveEntityModelGlow(entity);
		delete g_iModelTimer[entity];

		RemoveInstructor(entity);
		delete g_iInstructorTimer[entity];

		RemoveTargetInstructor(entity);
		delete g_iTargetInstructorTimer[entity];
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	RemoveEntityModelGlow(GetClientOfUserId(event.GetInt("userid")));
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	RemoveEntityModelGlow(GetClientOfUserId(event.GetInt("userid")));
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	RemoveEntityModelGlow(GetClientOfUserId(event.GetInt("userid")));
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
	RemoveEntityModelGlow(event.GetInt("witchid"));
}		

public Action Vocalize_Listener(int client, const char[] command, int argc)
{
    if (IsRealSur(client) && !IsHandingFromLedge(client) && GetInfectedAttacker(client) == -1)
    {
        static char sCmdString[32];
        if (GetCmdArgString(sCmdString, sizeof(sCmdString)) > 1)
        {
            if (strncmp(sCmdString, "smartlook #", 11, false) == 0)
            {
                float vPos[3], vAng[3];
                GetClientEyePosition(client, vPos);
                GetClientEyeAngles(client, vAng);
                Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilterEntities, client);
                if (TR_DidHit(trace))
                {
                    int hitEntity = TR_GetEntityIndex(trace);

                    if (hitEntity > 0 && IsValidEntity(hitEntity))
                    {
                        if ((1 <= hitEntity <= MaxClients && IsClientInGame(hitEntity) && GetClientTeam(hitEntity) == TEAM_INFECTED && IsPlayerAlive(hitEntity) && !IsPlayerGhost(hitEntity)) || IsWitch(hitEntity))
                        {
                            if (CreateInfectedMarker(client, hitEntity, IsWitch(hitEntity))) {
                                delete trace;
                                return Plugin_Continue;
                            }
                        }
                        if (Sakiko_TeammateMarkEnable && 1 <= hitEntity <= MaxClients && IsClientInGame(hitEntity) && GetClientTeam(hitEntity) == TEAM_SURVIVOR && IsPlayerAlive(hitEntity) && hitEntity != client)
                        {
                            if (CreateTeammateMarker(client, hitEntity)) {
                                delete trace;
                                return Plugin_Continue;
                            }
                        }
                        static char sEntModelName[PLATFORM_MAX_PATH];
                        GetEntPropString(hitEntity, Prop_Data, "m_ModelName", sEntModelName, sizeof(sEntModelName));
                        static char sClassName[64];
                        GetEdictClassname(hitEntity, sClassName, sizeof(sClassName));
                        static char sItemName[64];
                        StringToLowerCase(sEntModelName);
                        bool bIsKnownItem = g_smModelToName.GetString(sEntModelName, sItemName, sizeof(sItemName));
                        if (!bIsKnownItem)
                        {
                            if (StrContains(sEntModelName, "checkpoint_door") != -1)
                            {
                                FormatEx(sItemName, sizeof sItemName, "安全门!");
                                bIsKnownItem = true;
                            }
                            else if (StrContains(sEntModelName, "/melee/") != -1 || StrContains(sEntModelName, "/weapons/") != -1)
                            {
                                FormatEx(sItemName, sizeof sItemName, "剧本之外的武器！");
                                bIsKnownItem = true;
                            }
                        }

                        if (bIsKnownItem)
                        {
                            if (GetEngineTime() > g_fItemHintCoolDownTime[client])
                            {
                                float fHeight = 10.0;
                                g_smModelHeight.GetValue(sEntModelName, fHeight);
                                
                                NotifyMessage(client, sItemName, view_as<EHintType>(eItemHint));
                                if (strlen(g_sItemUseSound) > 0) EmitSoundToAllSurvivors(g_sItemUseSound, client);
                                
                                g_fItemHintCoolDownTime[client] = GetEngineTime() + g_fItemHintCoolDown;
                                CreateEntityModelGlow(hitEntity);
                                
                                if (g_bItemInstructorHint)
                                {
                                    float vEndPos[3];
                                    GetEntPropVector(hitEntity, Prop_Send, "m_vecOrigin", vEndPos);
                                    vEndPos[2] += fHeight;
                                    CreateInstructorHint(client, vEndPos, sItemName, hitEntity, view_as<EHintType>(eItemHint));
                                }
                            }
                            delete trace;
                            return Plugin_Continue;
                        }
                        if (CreateEntityMarker(client, hitEntity))
                        {
                            delete trace;
                            return Plugin_Continue;
                        }
                    }
                }
                CreateSpotMarker(client, 0, false);
                delete trace;
            }
        }
    }
    return Plugin_Continue;
}
public bool TraceFilterEntities(int entity, int contentsMask, int client)
{
    if (entity == client) return false;
    if (entity > MaxClients && IsValidEntity(entity))
    {
        char sClassName[64];
        GetEdictClassname(entity, sClassName, sizeof(sClassName));

        if (StrContains(sClassName, "trigger_") != -1 || 
            StrContains(sClassName, "logic_") != -1 || 
            StrEqual(sClassName, "info_target") ||
            StrEqual(sClassName, "info_survivor_position")) 
        {
            return false;
        }
    }

    return true;
}

void EmitSoundToAllSurvivors(const char[] sound, int EmitterClient)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
        {
            EmitSoundToClient(i, sound, EmitterClient);
        }
    }
}

public Action Timer_ItemGlow(Handle timer, int iEntity)
{
	RestoreEntityGlowState(iEntity);
	g_iModelTimer[iEntity] = null;
	return Plugin_Continue;
}

void RestoreEntityGlowState(int iEntity)
{
    if (!g_OriginalGlowState[iEntity].IsManagedByPlugin)
        return;
    bool bCanRestore = IsValidEntity(iEntity);
    if (bCanRestore && iEntity > 0 && iEntity <= MaxClients && !IsClientInGame(iEntity))
    {
        bCanRestore = false;
    }

    if (bCanRestore)
    {
        SetEntProp(iEntity, Prop_Send, "m_iGlowType", g_OriginalGlowState[iEntity].GlowType);
        SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", g_OriginalGlowState[iEntity].GlowColor);

        if (!g_OriginalGlowState[iEntity].IsGlowing)
        {
            AcceptEntityInput(iEntity, "StopGlowing");
        }
    }
    g_OriginalGlowState[iEntity].GlowType = 0;
    g_OriginalGlowState[iEntity].GlowColor = 0;
    g_OriginalGlowState[iEntity].IsGlowing = false;
    g_OriginalGlowState[iEntity].IsManagedByPlugin = false;
	int glowentity = g_iModelIndex[iEntity];
	if (IsValidEntRef(glowentity))
	{
		RemoveEntity(glowentity);
	}
	g_iModelIndex[iEntity] = 0;
}

void RemoveEntityModelGlow(int iEntity)
{
	RestoreEntityGlowState(iEntity);
}

bool IsRealSur(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client) && !IsFakeClient(client));
}

void Clear(int client = -1)
{
	if (client == -1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			g_fItemHintCoolDownTime[i] = 0.0;
			g_fSpotMarkCoolDownTime[i] = 0.0;
			g_fInfectedMarkCoolDownTime[i] = 0.0;
			Sakiko_TeammateMarkCoolDownTime[i] = 0.0;
		}
	}
	else
	{
		g_fItemHintCoolDownTime[client] = 0.0;
		g_fSpotMarkCoolDownTime[client] = 0.0;
		g_fInfectedMarkCoolDownTime[client] = 0.0;
		Sakiko_TeammateMarkCoolDownTime[client] = 0.0;
	}
}

int GetColor(char[] sTemp)
{
	if (StrEqual(sTemp, ""))
		return 0;

	char sColors[3][4];
	int  color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (color != 3)
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
    color += 16777216 * 255;

	return color;
}

bool IsValidEntRef(int entity)
{
	if (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && entity != -1)
		return true;
	return false;
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntityIndex(entity))
		return;

	RemoveEntityModelGlow(entity);
	delete g_iModelTimer[entity];

	RemoveInstructor(entity);
	delete g_iInstructorTimer[entity];

	RemoveTargetInstructor(entity);
	delete g_iTargetInstructorTimer[entity];

	ge_bMoveUp[entity] = false;
}

void RemoveAllGlow_Timer()
{
	for (int entity = 1; entity < MAXENTITIES; entity++)
	{
		RemoveEntityModelGlow(entity);
		delete g_iModelTimer[entity];

		RemoveInstructor(entity);
		delete g_iInstructorTimer[entity];

		RemoveTargetInstructor(entity);
		delete g_iTargetInstructorTimer[entity];
	}
}

void RemoveAllSpotMark()
{
    int entity;
    char targetname[16];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFO_TARGET)) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_mark_hint"))
            AcceptEntityInput(entity, "Kill");
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_ENV_SPRITE)) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_mark_hint"))
            AcceptEntityInput(entity, "Kill");
    }
}

bool IsValidEntityIndex(int entity)
{
	return (MaxClients + 1 <= entity <= GetMaxEntities());
}

void CreateEntityModelGlow(int iEntity, int color = 0, float timer = 0.0, int range = 0)
{
	if (color == 0) color = g_iItemCvarColor;
	if (timer == 0.0) timer = g_fItemGlowTimer;
	if (range == 0) range = g_iItemGlowRange;

	if (color == 0 || !IsValidEntity(iEntity)) return;

	if (g_iModelTimer[iEntity] != null)
	{
		KillTimer(g_iModelTimer[iEntity]);
		g_iModelTimer[iEntity] = null;
	}
    else
    {
        g_OriginalGlowState[iEntity].GlowType = GetEntProp(iEntity, Prop_Send, "m_iGlowType");
        g_OriginalGlowState[iEntity].GlowColor = GetEntProp(iEntity, Prop_Send, "m_glowColorOverride");
        g_OriginalGlowState[iEntity].IsGlowing = HasEntProp(iEntity, Prop_Send, "m_bIsGlowing") && GetEntProp(iEntity, Prop_Send, "m_bIsGlowing") == 1;
		g_OriginalGlowState[iEntity].IsManagedByPlugin = true;
    }

	SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", range);
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", color);
	AcceptEntityInput(iEntity, "StartGlowing");
	g_iModelTimer[iEntity] = CreateTimer(timer, Timer_ItemGlow, iEntity);
}

bool CreateInfectedMarker(int client, int infected, bool bIsWitch = false)
{
    if( GetEngineTime() < g_fInfectedMarkCoolDownTime[client]) return true; // cool down not yet 
    if (g_iInfectedMarkCvarColor == 0) return false; // disable infected mark
    if (bIsWitch && g_bInfectedMarkWitch == false) return false; // disable infected mark on witch

    float vStartPos[3], vEndPos[3];
    GetEntPropVector(client, Prop_Data, "m_vecOrigin", vStartPos);
    GetEntPropVector(infected, Prop_Data, "m_vecOrigin", vEndPos);
    if (GetVectorDistance(vStartPos, vEndPos, true) > g_fInfectedMarkUseRange * g_fInfectedMarkUseRange)    // over distance
        return false;
        
    if (g_iModelTimer[infected] != null)
	{
		KillTimer(g_iModelTimer[infected]);
		g_iModelTimer[infected] = null;
	}
    else
    {
        g_OriginalGlowState[infected].GlowType = GetEntProp(infected, Prop_Send, "m_iGlowType");
        g_OriginalGlowState[infected].GlowColor = GetEntProp(infected, Prop_Send, "m_glowColorOverride");
        g_OriginalGlowState[infected].IsGlowing = HasEntProp(infected, Prop_Send, "m_bIsGlowing") && GetEntProp(infected, Prop_Send, "m_bIsGlowing") == 1;
        g_OriginalGlowState[infected].IsManagedByPlugin = true;
    }
	SetEntProp(infected, Prop_Send, "m_iGlowType", 3);
	SetEntProp(infected, Prop_Send, "m_nGlowRange", g_iInfectedMarkGlowRange);
	SetEntProp(infected, Prop_Send, "m_glowColorOverride", g_iInfectedMarkCvarColor);
	AcceptEntityInput(infected, "StartGlowing");

    g_iModelTimer[infected] = CreateTimer(g_fInfectedMarkGlowTimer, Timer_ItemGlow, infected);

    g_fInfectedMarkCoolDownTime[client] = GetEngineTime() + g_fInfectedMarkCoolDown;

    if (strlen(g_sInfectedMarkUseSound) > 0)
    {
        for (int target = 1; target <= MaxClients; target++)
        {
            if (IsClientInGame(target) && !IsFakeClient(target) && GetClientTeam(target) != TEAM_INFECTED)
            {
                EmitSoundToClient(target, g_sInfectedMarkUseSound, client);
            }
        }
    }
    
    static char sModelName[64], sItemName[64];
    GetEntPropString(infected, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
    StringToLowerCase(sModelName);
    if (!g_smModelToName.GetString(sModelName, sItemName, sizeof(sItemName)))
    {
        FormatEx(sItemName, sizeof sItemName, "%s", "三方地图自定义特感！");
    }
    NotifyMessage(client, sItemName, view_as<EHintType>(eInfectedMaker));
    
    return true;
}

bool CreateTeammateMarker(int client, int target)
{
	if( GetEngineTime() < Sakiko_TeammateMarkCoolDownTime[client]) return true; // cool down not yet 
	if (Sakiko_TeammateMarkCvarColor == 0) return false; // disable teammate mark

	if (g_iModelTimer[target] != null)
	{
		KillTimer(g_iModelTimer[target]);
		g_iModelTimer[target] = null;
	}
    else
    {
        g_OriginalGlowState[target].GlowType = GetEntProp(target, Prop_Send, "m_iGlowType");
        g_OriginalGlowState[target].GlowColor = GetEntProp(target, Prop_Send, "m_glowColorOverride");
        g_OriginalGlowState[target].IsGlowing = HasEntProp(target, Prop_Send, "m_bIsGlowing") && GetEntProp(target, Prop_Send, "m_bIsGlowing") == 1;
        g_OriginalGlowState[target].IsManagedByPlugin = true;
    }
	SetEntProp(target, Prop_Send, "m_iGlowType", 3);
	SetEntProp(target, Prop_Send, "m_nGlowRange", g_iInfectedMarkGlowRange);
	SetEntProp(target, Prop_Send, "m_glowColorOverride", Sakiko_TeammateMarkCvarColor);
	AcceptEntityInput(target, "StartGlowing");

	g_iModelTimer[target] = CreateTimer(Sakiko_TeammateMarkGlowTimer, Timer_ItemGlow, target);
	Sakiko_TeammateMarkCoolDownTime[client] = GetEngineTime() + Sakiko_TeammateMarkCoolDown;
	if (strlen(Sakiko_TeammateMarkUseSound) > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
				EmitSoundToClient(i, Sakiko_TeammateMarkUseSound, client);
		}
	}
	
	static char sMessage[64];
	FormatEx(sMessage, sizeof(sMessage), "正在标记：\x05%N", target);
	NotifyMessage(client, sMessage, view_as<EHintType>(eTeammateMarker));
	
	return true;
}

// 标记实体
bool CreateEntityMarker(int client, int entity)
{
    if (!Sakiko_EntityMarkEnable) return false;
    if (Sakiko_EntityMarkCvarColor == 0) return false;

    static char sModelName[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

    if (sModelName[0] == '\0' || sModelName[0] == '*')
    {
        return false;
    }

    char sClassName[64];
    GetEdictClassname(entity, sClassName, sizeof(sClassName));

    // 过滤掉一些不需要的实体
    if (StrEqual(sClassName, "infected", false) || StrContains(sClassName, "weapon_") != -1 || StrContains(sClassName, "_ragdoll") != -1 || StrEqual(sClassName, "prop_dynamic_override") || StrEqual(sClassName, "prop_dynamic_ornament"))
    {
        return false;
    }
    CreateEntityModelGlow(entity, Sakiko_EntityMarkCvarColor, Sakiko_EntityMarkGlowTimer, Sakiko_EntityMarkGlowRange);

    if (strlen(Sakiko_EntityMarkUseSound) > 0)
    {
        EmitSoundToAllSurvivors(Sakiko_EntityMarkUseSound, client);
    }
    
    char sDisplayName[PLATFORM_MAX_PATH];
    
    if (Sakiko_EntityMarkTest)
    {
        Format(sDisplayName, sizeof(sDisplayName), "%s", sModelName);
    }
    else
    {
        int iLastSlash = -1;
        int iLen = strlen(sModelName);
        for (int i = 0; i < iLen; i++)
        {
            if (sModelName[i] == '/' || sModelName[i] == '\\')
                iLastSlash = i;
        }
        strcopy(sDisplayName, sizeof(sDisplayName), sModelName[iLastSlash + 1]);
        ReplaceString(sDisplayName, sizeof(sDisplayName), ".mdl", "", false);
    }
    char sMessage[PLATFORM_MAX_PATH];
    Format(sMessage, sizeof(sMessage), "标记了: \x05%s", sDisplayName);
    NotifyMessage(client, sMessage, view_as<EHintType>(eEntityMarker));
    
    return true;
}

void CreateSpotMarker(int client, int clientAim = 0, bool bIsAimInfeced)
{
	if (bIsAimInfeced) return;
	if (GetEngineTime() < g_fSpotMarkCoolDownTime[client]) return; // cool down not yet

	bool  hit;
	float vStartPos[3], vEndPos[3];
	GetClientAbsOrigin(client, vStartPos);

	if (clientAim == 0) clientAim = GetClientAimTarget(client, true);

	if (1 <= clientAim <= MaxClients && IsClientInGame(clientAim))
	{
		hit = true;
		GetClientAbsOrigin(clientAim, vEndPos);
	}
	else
	{
		float vPos[3];
		GetClientEyePosition(client, vPos);

		float vAng[3];
		GetClientEyeAngles(client, vAng);

		Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SOLID, RayType_Infinite, TraceFilter, client);

		if (TR_DidHit(trace))
		{
			hit = true;
			TR_GetEndPosition(vEndPos, trace);
		}

		delete trace;
	}

	if (!hit)    // not hit
		return;

	if ( g_bSpotMarkInstructorHint ) CreateInstructorHint(client, vEndPos, "", 0, view_as<EHintType>(eSpotMarker));

	if ( strlen(g_sSpotMarkCvarColor) == 0 ) return; //disable spot mark glow

	if (GetVectorDistance(vStartPos, vEndPos, true) > g_fSpotMarkUseRange * g_fSpotMarkUseRange)    // over distance
		return;

	float vBeamPos[3];
	vBeamPos = vEndPos;
	vBeamPos[2] += (2.0 + 1.0);    // Change the Z pos to go up according with the width for better looking

	int color[4];
	color[0] = g_iSpotMarkCvarColorArray[0];
	color[1] = g_iSpotMarkCvarColorArray[1];
	color[2] = g_iSpotMarkCvarColorArray[2];
	color[3] = 255;

	float timeLimit = GetGameTime() + g_fSpotMarkGlowTimer;

	DataPack pack;
	CreateDataTimer(1.0, TimerField, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(color[0]);
	pack.WriteCell(color[1]);
	pack.WriteCell(color[2]);
	pack.WriteCell(color[3]);
	pack.WriteFloat(timeLimit);
	pack.WriteFloat(vBeamPos[0]);
	pack.WriteFloat(vBeamPos[1]);
	pack.WriteFloat(vBeamPos[2]);

	float fieldDuration = (timeLimit - GetGameTime() < 1.0 ? timeLimit - GetGameTime() : 1.0);

	if (fieldDuration < 0.11)    // Prevent rounding to 0 which makes the beam don't disappear
		fieldDuration = 0.11;    // less than 0.11 reads as 0 in L4D1

	int targets[MAXPLAYERS+1];
	int targetCount;
	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsClientInGame(target))
			continue;

		if (IsFakeClient(target))
			continue;

		if (GetClientTeam(target) == TEAM_INFECTED)
			continue;

		targets[targetCount++] = target;
	}

	TE_SetupBeamRingPoint(vBeamPos, 75.0, 100.0, g_iFieldModelIndex, 0, 0, 0, fieldDuration, 2.0, 0.0, color, 0, 0);
	TE_Send(targets, targetCount);

	float vSpritePos[3];
	vSpritePos = vEndPos;
	vSpritePos[2] += 50.0;

	char targetname[19];
	FormatEx(targetname, sizeof(targetname), "%s-%02i", "l4d_mark_hint", client);

	g_fSpotMarkCoolDownTime[client] = GetEngineTime() + g_fSpotMarkCoolDown;

	if (strlen(g_sSpotMarkUseSound) > 0)
	{
		for (int target = 1; target <= MaxClients; target++)
		{
			if (!IsClientInGame(target))
				continue;

			if (IsFakeClient(target))
				continue;

			if (GetClientTeam(target) == TEAM_INFECTED)
				continue;

			EmitSoundToClient(target, g_sSpotMarkUseSound, client);
		}
	}

	if ( strlen(g_sSpotMarkSpriteModel) == 0 ) return; //disable spot marker info target

	int infoTarget = CreateEntityByName(CLASSNAME_INFO_TARGET);
	if( CheckIfEntityMax(infoTarget) )
	{
		DispatchKeyValue(infoTarget, "targetname", targetname);

		TeleportEntity(infoTarget, vSpritePos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(infoTarget);
		ActivateEntity(infoTarget);

		SetEntPropEnt(infoTarget, Prop_Send, "m_hOwnerEntity", client);

		SetVariantString(g_sKillDelay);
		AcceptEntityInput(infoTarget, "AddOutput");
		AcceptEntityInput(infoTarget, "FireUser1");

		int sprite       = CreateEntityByName(CLASSNAME_ENV_SPRITE);
		if( CheckIfEntityMax(sprite) )
		{
			DispatchKeyValue(sprite, "targetname", targetname);
			DispatchKeyValue(sprite, "spawnflags", "1");
			SDKHook(sprite, SDKHook_SetTransmit, Hook_SetTransmit);

			DispatchKeyValue(sprite, "model", g_sSpotMarkSpriteModel);
			DispatchKeyValue(sprite, "rendercolor", g_sSpotMarkCvarColor);
			DispatchKeyValue(sprite, "renderamt", "255");    // If renderamt goes before rendercolor, it doesn't render
			DispatchKeyValue(sprite, "scale", "0.25");
			DispatchKeyValue(sprite, "fademindist", "-1");

			TeleportEntity(sprite, vSpritePos, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(sprite);
			ActivateEntity(sprite);

			SetVariantString("!activator");
			AcceptEntityInput(sprite, "SetParent", infoTarget);    // We need parent the entity to an info_target, otherwise SetTransmit won't work

			SetEntPropEnt(sprite, Prop_Send, "m_hOwnerEntity", client);
			AcceptEntityInput(sprite, "ShowSprite");
			SetVariantString(g_sKillDelay);
			AcceptEntityInput(sprite, "AddOutput");
			AcceptEntityInput(sprite, "FireUser1");
			
			CreateTimer(0.1, TimerMoveSprite, EntIndexToEntRef(sprite), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	NotifyMessage(client, "这里！！", view_as<EHintType>(eSpotMarker));
}

public Action TimerField(Handle timer, DataPack pack)
{
	int color[4];
	float timeLimit;
	float vBeamPos[3];

	pack.Reset();
	color[0] = pack.ReadCell();
	color[1] = pack.ReadCell();
	color[2] = pack.ReadCell();
	color[3] = pack.ReadCell();
	timeLimit = pack.ReadFloat();
	vBeamPos[0] = pack.ReadFloat();
	vBeamPos[1] = pack.ReadFloat();
	vBeamPos[2] = pack.ReadFloat();

	if (timeLimit < GetGameTime())
		return Plugin_Continue;

	float fieldDuration = (timeLimit - GetGameTime() < 1.0 ? timeLimit - GetGameTime() : 1.0);

	if (fieldDuration < 0.11) // Prevent rounding to 0 which makes the beam don't disappear
		fieldDuration = 0.11; // less than 0.11 reads as 0 in L4D1

	int targets[MAXPLAYERS+1];
	int targetCount;
	for (int target = 1; target <= MaxClients; target++)
	{
		if (!IsClientInGame(target))
			continue;

		if (IsFakeClient(target))
			continue;

		if (GetClientTeam(target) == TEAM_INFECTED)
			continue;

		targets[targetCount++] = target;
	}

	TE_SetupBeamRingPoint(vBeamPos, 75.0, 100.0, g_iFieldModelIndex, 0, 0, 0, fieldDuration, 2.0, 0.0, color, 0, 0);
	TE_Send(targets, targetCount);

	DataPack pack2;
	CreateDataTimer(1.0, TimerField, pack2, TIMER_FLAG_NO_MAPCHANGE);
	pack2.WriteCell(color[0]);
	pack2.WriteCell(color[1]);
	pack2.WriteCell(color[2]);
	pack2.WriteCell(color[3]);
	pack2.WriteFloat(timeLimit);
	pack2.WriteFloat(vBeamPos[0]);
	pack2.WriteFloat(vBeamPos[1]);
	pack2.WriteFloat(vBeamPos[2]);
	
	return Plugin_Continue;
}

public Action TimerMoveSprite(Handle timer, int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return Plugin_Stop;

    float vPos[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

    if (ge_bMoveUp[entity])
    {
        vPos[2] += 1.0;

        if (vPos[2] >= 4.0)
            ge_bMoveUp[entity] = false;
    }
    else
    {
        vPos[2] -= 1.0;

        if (vPos[2] <= -4.0)
            ge_bMoveUp[entity] = true;
    }

    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    return Plugin_Continue;
}

int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

public bool TraceFilter(int entity, int contentsMask, int client)
{
	if (entity == client)
		return false;

	if (entity == ENTITY_WORLDSPAWN || 1 <= entity <= MaxClients)
		return true;

	return false;
}

void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

void NotifyMessage(int client, const char[] sItemName, EHintType eType)
{
    int randomIndex = GetRandomInt(0, sizeof(randomPrefixes) - 1);
    char prefix[32];
    strcopy(prefix, sizeof(prefix), randomPrefixes[randomIndex]);

    if (eType == view_as<EHintType>(eItemHint))
    {
        switch(g_iItemAnnounceType)
        {
            case 0: {/*nothing*/}
            case 1: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintToChat(i, "\x05%N\x01: \x01%s", client, sItemName);
                    }
                }
            }
            case 2: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintHintText(i, "\x05%N\x01: \x01%s", client, sItemName);
                    }
                }
            }
            case 3: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintCenterText(i, "\x05%N\x01: \x01%s", client, sItemName);
                    }
                }
            }
        }
    }
    else if (eType == view_as<EHintType>(eInfectedMaker))
    {
        switch(g_iInfectedMarkAnnounceType)
        {
            case 0: {/*nothing*/}
            case 1: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintToChat(i, "\x05%N\x01: \x02%s", client, sItemName);
                    }
                }
            }
            case 2: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintHintText(i, "\x05%N\x01: \x02%s", client, sItemName);
                    }
                }
            }
            case 3: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintCenterText(i, "\x05%N\x01: \x02%s", client, sItemName);
                    }
                }
            }
        }	
    }
    else if (eType == view_as<EHintType>(eSpotMarker))
    {
        switch(g_iSpotAnnounceType)
        {
            case 0: {/*nothing*/}
            case 1: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintToChat(i, " \x05%N\x01: \x04%s", client, sItemName);
                    }
                }
            }
            case 2: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintHintText(i, " \x05%N\x01: \x04%s", client, sItemName);
                    }
                }
            }
            case 3: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintCenterText(i, " \x05%N\x01: \x04%s", client, sItemName);
                    }
                }
            }
        }
    }
    else if (eType == view_as<EHintType>(eTeammateMarker))
    {
        switch(Sakiko_TeammateMarkAnnounceType)
        {
            case 0: {/*nothing*/}
            case 1: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintToChat(i, "\x05%N\x01: \x03%s", client, sItemName);
                    }
                }
            }
            case 2: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintHintText(i, "\x05%N\x01: \x03%s", client, sItemName);
                    }
                }
            }
            case 3: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintCenterText(i, "\x05%N\x01: \x03%s", client, sItemName);
                    }
                }
            }
        }
    }
    else if (eType == view_as<EHintType>(eEntityMarker))
    {
        switch(Sakiko_EntityMarkAnnounceType)
        {
            case 0: {/*nothing*/}
            case 1: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintToChat(i, "\x05%N\x01: \x04%s", client, sItemName);
                    }
                }
            }
            case 2: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintHintText(i, "%N: %s！", client, sItemName);
                    }
                }
            }
            case 3: {
                for (int i=1; i <= MaxClients; i++)
                {
                    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_INFECTED)
                    {
                        PrintCenterText(i, "%N: %s！", client, sItemName);
                    }
                }
            }
        }
    }
}

stock bool IsHandingFromLedge(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

int GetInfectedAttacker(int client)
{
	int attacker;

	/* Charger */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0)
	{
		return attacker;
	}
	/* Jockey */
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0)
	{
		return attacker;
	}

	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0)
	{
		return attacker;
	}

	return -1;
}

bool IsWitch(int entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        char strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return strcmp(strClassName, "witch", false) == 0;
    }
    return false;
}

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( GetClientTeam(client) == TEAM_INFECTED)
		return Plugin_Handled;
		
	return Plugin_Continue;
}

bool CheckIfEntityMax(int entity)
{
	if(entity == -1) return false;

	if(	entity > ENTITY_SAFE_LIMIT)
	{
		AcceptEntityInput(entity, "Kill");
		return false;
	}
	return true;
}

// by BHaType: https://forums.alliedmods.net/showthread.php?p=2709810#post2709810
void CreateInstructorHint(int client, const float vOrigin[3], const char[] sMessage, int iEntity, EHintType type)
{
	static char sTargetName[64], sCaption[128];
	Format(sTargetName, sizeof sTargetName, "%i_%.0f", client, GetEngineTime());
	
	switch(type)
	{
		case view_as<EHintType>(eItemHint):
		{
			if( Create_info_target(iEntity, vOrigin, sTargetName, g_fItemGlowTimer) )
			{
				FormatEx(sCaption, sizeof sCaption, "%s", sMessage);
				Create_env_instructor_hint(iEntity, view_as<EHintType>(eItemHint), vOrigin, sTargetName, g_sItemInstructorIcon, sCaption, g_sItemInstructorColor, g_fItemGlowTimer, float(g_iItemGlowRange));
			}
		}
		case view_as<EHintType>(eSpotMarker):
		{
			if( Create_info_target(iEntity, vOrigin, sTargetName, g_fSpotMarkGlowTimer) )
			{
				FormatEx(sCaption, sizeof sCaption, "%N 标记了一处位置", client);
				Create_env_instructor_hint(iEntity, view_as<EHintType>(eSpotMarker), vOrigin, sTargetName, g_sSpotMarkInstructorIcon, sCaption, g_sSpotMarkInstructorColor, g_fSpotMarkGlowTimer, g_fSpotMarkUseRange);
			}
		}
	}
}

bool Create_info_target(int iEntity, const float vOrigin[3], const char[] sTargetName, float duration)
{
	int entity = CreateEntityByName(CLASSNAME_INFO_TARGET);
	if (!CheckIfEntityMax(entity)) return false;
	
	DispatchKeyValue(entity, "targetname", sTargetName);
	DispatchKeyValue(entity, "spawnflags", "1"); //Only visible to survivors
	DispatchSpawn(entity);
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", iEntity);    // We need parent the entity to an info_target_instructor_hint, otherwise it won't follow moveable item such as gascan
	
	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

	if (iEntity > 0)
	{
		//delete previous info_target_instructor_hint first
		RemoveTargetInstructor(iEntity);
		delete g_iTargetInstructorTimer[iEntity];

		g_iTargetInstructorIndex[iEntity] = EntIndexToEntRef(entity);
		g_iTargetInstructorTimer[iEntity] = CreateTimer(duration, Timer_target_instructor_hint, iEntity);
	}
	else
	{
		char szBuffer[36];
		Format(szBuffer, sizeof szBuffer, "OnUser1 !self:Kill::%f:-1", duration);

		SetVariantString(szBuffer); 
		AcceptEntityInput(entity, "AddOutput"); 
		AcceptEntityInput(entity, "FireUser1");
	}

	return true;
}

void Create_env_instructor_hint(int iEntity, EHintType eType, const float vOrigin[3], const char[] sTargetName, const char[] icon_name, const char[] caption, const char[] hint_color, float duration, float range)
{
	int entity = CreateEntityByName("env_instructor_hint");
	if (!CheckIfEntityMax(entity)) return;

	char sDuration[4];
	IntToString(RoundFloat(duration), sDuration, sizeof sDuration);
	char sRange[8];
	IntToString(RoundFloat(range), sRange, sizeof sRange);

	DispatchKeyValue(entity, "hint_timeout", sDuration);
	DispatchKeyValue(entity, "hint_allow_nodraw_target", "1");
	DispatchKeyValue(entity, "hint_target", sTargetName);
	DispatchKeyValue(entity, "hint_auto_start", "1");
	DispatchKeyValue(entity, "hint_color", hint_color);
	DispatchKeyValue(entity, "hint_icon_offscreen", icon_name);
	DispatchKeyValue(entity, "hint_instance_type", "0");
	DispatchKeyValue(entity, "hint_icon_onscreen", icon_name);
	DispatchKeyValue(entity, "hint_caption", caption);
	DispatchKeyValue(entity, "hint_static", "0");
	DispatchKeyValue(entity, "hint_nooffscreen", "0");
	if (eType == view_as<EHintType>(eSpotMarker)) DispatchKeyValue(entity, "hint_icon_offset", "10");
	else if (eType == view_as<EHintType>(eItemHint)) DispatchKeyValue(entity, "hint_icon_offset", "0");
	else if (eType == view_as<EHintType>(eEntityMarker)) DispatchKeyValue(entity, "hint_icon_offset", "20");
	DispatchKeyValue(entity, "hint_range", sRange);
	DispatchKeyValue(entity, "hint_forcecaption", "1");
	DispatchSpawn(entity);
	TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
	//AcceptEntityInput(entity, "ShowHint"); //double hint

	if (iEntity > 0)
	{
		//delete previous env_instructor_hint first
		RemoveInstructor(iEntity);
		delete g_iInstructorTimer[iEntity];

		g_iInstructorIndex[iEntity] = EntIndexToEntRef(entity);
		g_iInstructorTimer[iEntity] = CreateTimer(duration, Timer_instructor_hint, iEntity);
	}
	else
	{
		char szBuffer[36];
		Format(szBuffer, sizeof szBuffer, "OnUser1 !self:Kill::%f:-1", duration);

		SetVariantString(szBuffer); 
		AcceptEntityInput(entity, "AddOutput"); 
		AcceptEntityInput(entity, "FireUser1");
	}
}


public Action Timer_instructor_hint(Handle timer, int iEntity)
{
	RemoveInstructor(iEntity);
	g_iInstructorTimer[iEntity] = null;
	
	return Plugin_Continue;
}

void RemoveInstructor(int iEntity)
{
	int instructor_hint = g_iInstructorIndex[iEntity];
	g_iInstructorIndex[iEntity] = 0;

	if (IsValidEntRef(instructor_hint))
		RemoveEntity(instructor_hint);
}

public Action Timer_target_instructor_hint(Handle timer, int iEntity)
{
	RemoveTargetInstructor(iEntity);
	g_iTargetInstructorTimer[iEntity] = null;
	
	return Plugin_Continue;
}

void RemoveTargetInstructor(int iEntity)
{
	int target_instructor_hint = g_iTargetInstructorIndex[iEntity];
	g_iTargetInstructorIndex[iEntity] = 0;

	if (IsValidEntRef(target_instructor_hint))
		RemoveEntity(target_instructor_hint);
}
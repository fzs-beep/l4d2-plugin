#pragma semicolon 1;
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define CLASS_SPITTER		4

int g_bLateLoad;
int g_bMapStarted;
int g_bModInProgress;

char clientName[32];

Handle g_iGascans;
Handle g_iLasthits;

ConVar l4d_burners;

int g_bWasSpitter[ MAXPLAYERS + 1 ];

public Plugin myinfo = 
{

    name = "L4D2 纵火提示",
    author = "Jim丶黑子(汉化)",
    description = "当有人引燃汽油桶或者投掷燃烧瓶的时候给予所有玩家提示",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
	CreateConVar( "l4d_burners_announce_version", PLUGIN_VERSION, "纵火提示插件版本.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	l4d_burners = CreateConVar("l4d_burners_announce", "1", "启用幸存者纵火提示? 0=禁用, 1=启用.", FCVAR_NOTIFY);
	
	//AutoExecConfig(true, "l4d2_burners_announce");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("molotov_thrown", Event_MolotovThrown );
	HookEvent("player_team", Event_PlayerTeam );
	HookEvent("player_spawn", Event_PlayerSpawn );
	HookEvent("break_prop", Event_BreakProp );
	
	g_iGascans = CreateArray( );
	g_iLasthits = CreateArray( );

	if ( g_bLateLoad )
	{
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientAndInGame( i ) )
			{
				OnClientDisconnect_Post( i );
				OnClientPutInServer( i );
			}
		}
	}
	ModifyGascans( );
	RefreshGascans( );
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void Event_MolotovThrown(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d_burners)) { return; }
	{
		if (GetConVarInt(l4d_burners) == 1)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			
			if(IsValidClient(client))
			{
				GetTrueName(client, clientName);
				PrintToChatAll("\x04★ \x05%s \x01投掷了燃烧瓶.", clientName );
			}
		}
	}
}

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("entindex");
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsClientAndInGame(client))
		return;
	if (!IsValidEdict(entity))
		return;
		
	char EdictClassName[128], EdictModelName[128];
	GetEdictClassname( entity, EdictClassName, sizeof( EdictClassName ) );
	GetEntPropString( entity, Prop_Data, "m_ModelName", EdictModelName, sizeof( EdictModelName ) );
	
	if( StrEqual( EdictClassName, "prop_physics" ) )
	{
		if ( StrContains( EdictModelName, "explosive_box001" ) != -1) 
		{
			GetTrueName(client, clientName);
			PrintToChatAll("\x04★ \x05%s \x01点燃了烟花盒.", clientName );
		}
		if ( StrContains( EdictModelName, "propanecanister001a" ) != -1) 
		{
			GetTrueName(client, clientName);
			PrintToChatAll("\x04★ \x05%s \x01打爆了煤气罐.", clientName );
		}
		if ( StrContains( EdictModelName, "oxygentank01" ) != -1) 
		{
			GetTrueName(client, clientName);
			PrintToChatAll("\x04★ \x05%s \x01打爆了氧气瓶.", clientName );
		}
	}
}

public void OnClientPutInServer( int client )
{
	SDKHook( client, SDKHook_WeaponEquipPost, OnWeaponEquip );
}

public void OnClientDisconnect_Post( int client )
{
	SDKUnhook( client, SDKHook_WeaponEquipPost, OnWeaponEquip );
}

public void OnMapStart( )
{
	g_bMapStarted = true;
	ModifyGascans( );
	RefreshGascans( );
}

public void OnMapEnd( )
{
	g_bMapStarted = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_bMapStarted )
	{
		ModifyGascans( );
		RefreshGascans( );
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bWasSpitter[ client ] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_bWasSpitter[ client ] = false;
	if( GetClientTeam( client ) == TEAM_INFECTED )
	{
		if( GetEntProp( client, Prop_Send, "m_zombieClass" ) == CLASS_SPITTER ) 
		{
			g_bWasSpitter[ client ] = true;
		}
	}
}

public void OnWeaponEquip(int client, int weapon)
{
	int index = -1;
	if( IsValidEdict( weapon ) )
	{
		index = FindValueInArray( g_iGascans, weapon );	
		if( index > -1 )
		{
			SetArrayCell( g_iLasthits, index, -1 );
	
		}
	}
}

public void OnEntityCreated( int entity, const char[] classname )
{
	// made for weaponspawners and auto respawning gascans (e.g. c1m4_atrium).
	if ( StrEqual( classname, "weapon_gascan" ) )
	{
		RefreshGascans();
	}
	//胆汁罐
	if(StrEqual(classname, "vomitjar_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost_Grenade_vomitjar);
	}
	//土制炸弹
	if(StrEqual(classname, "pipe_bomb_projectile"))
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost_Grenade_pipe_bomb);
	}
} 

//胆汁罐
public void SpawnPost_Grenade_vomitjar(int entity)
{
	SDKUnhook(entity, SDKHook_SpawnPost, SpawnPost_Grenade_vomitjar);
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(client && IsClientInGame(client))
	{
		GetTrueName(client, clientName);
		PrintToChatAll("\x04★ \x05%s \x01投掷了胆汁瓶.", clientName);
	}
}

//土制炸弹
public void SpawnPost_Grenade_pipe_bomb(int entity)
{
	if (IsValidEdict(entity))
	{
		SDKUnhook(entity, SDKHook_SpawnPost, SpawnPost_Grenade_pipe_bomb);
		
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			
			if(weapon != -1)
			{
				char EdictClassName[128];
				GetEntityClassname(weapon, EdictClassName, sizeof(EdictClassName));
				
				if(StrEqual(EdictClassName, "weapon_pipe_bomb"))
				{
					char EdictModelName[128];
					GetEntPropString(weapon, Prop_Data, "m_ModelName", EdictModelName, sizeof(EdictModelName));
					
					if (StrContains(EdictModelName, "v_pipebomb") != -1) 
					{
						GetTrueName(client, clientName);
						PrintToChatAll("\x04★ \x05%s \x01投掷了土制炸弹.", clientName);
					}
				}
			}
		}
	}
}

public void OnEntityDestroyed( int entity )
{
	if (!GetConVarInt(l4d_burners)) { return; }
	{
		if (GetConVarInt(l4d_burners) == 1)
		{
			int killer = -1;
			int index = -1;
			if ( IsValidEdict( entity ) )
			{
				index = FindValueInArray( g_iGascans, entity );	
				
				if( index > -1 )
				{
					killer = GetArrayCell( g_iLasthits, index );
					
					if( IsClientAndInGame( killer ) && GetClientTeam( killer ) == 2)
					{
						char killername[32];
						GetTrueName(killer, killername);
						PrintToChatAll("\x04★ \x05%s \x01引燃了汽油桶.", killername );
					}
					SDKUnhook( entity, SDKHook_OnTakeDamage, OnTakeDamageGascan );			
					SetArrayCell( g_iGascans, index, -1 );
				}
			}
		}
	}
}

public Action OnTakeDamageGascan(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int index = -1;
	if ( 
		IsValidEdict( victim ) && 
		IsClientAndInGame( attacker ) && 
		( 
			( 
				GetClientTeam( attacker ) == TEAM_INFECTED && 
				GetEntProp( attacker, Prop_Send, "m_zombieClass" ) == CLASS_SPITTER
			) 
			|| 
			( 
				GetClientTeam( attacker ) == TEAM_SURVIVORS 
			)
		)
	)
	{
		index = FindValueInArray( g_iGascans, victim );
		if( index > -1 )
		{
			SetArrayCell( g_iLasthits, index, attacker );
		}
	}	
}  

public void UnhookGascans( )
{
	int entity = -1;

	for ( int i = 0; i < GetArraySize( g_iGascans ); i++ )
	{
		entity = GetArrayCell( g_iGascans, i );
		if( entity != -1 )
		{
			SDKUnhook( entity, SDKHook_OnTakeDamage, OnTakeDamageGascan );
		}
	}
}

public void RefreshGascans( )
{
	if( g_bModInProgress )
		return;
	UnhookGascans( );
	ClearArray( g_iGascans );
	ClearArray( g_iLasthits );
	char EdictClassName[ 32 ];
	for ( int i = 0; i <= GetMaxEntities( ); i++ )
	{
		if ( IsValidEdict( i ) )
		{
			GetEdictClassname( i, EdictClassName, sizeof( EdictClassName ) );
			if ( !StrEqual( EdictClassName, "weapon_gascan" ) ) 
			{
				continue;
			}
			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamageGascan );
			PushArrayCell( g_iGascans, i );
			PushArrayCell( g_iLasthits, -1 );
		}
	}
}

public void  ModifyGascans( )
{
	g_bModInProgress = true;
	char EdictModelName[ 128 ];
	char EdictClassName[ 32 ];
	for ( int i = 0; i <= GetMaxEntities( ); i++ )
	{
		if ( IsValidEdict( i ) )
		{
			EdictModelName[ 0 ] = '\0';
			GetEdictClassname( i, EdictClassName, sizeof( EdictClassName ) );
			if( StrEqual( EdictClassName, "prop_physics" ) )
			{
				GetEntPropString( i, Prop_Data, "m_ModelName", EdictModelName, sizeof( EdictModelName ) );
				if ( StrEqual( EdictModelName, "models/props_junk/gascan001a.mdl" ) )
				{	
					int entity = CreateEntityByName("weapon_gascan");
					SetEntityModel( entity, EdictModelName );
					float vPos[ 3 ], vAng[ 3 ];
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", vPos );
					GetEntPropVector( i, Prop_Send, "m_angRotation", vAng );
					DispatchKeyValueVector( entity, "origin", vPos );
					DispatchKeyValueVector( entity, "angles", vAng );
					DispatchSpawn( entity );
					AcceptEntityInput( i, "Kill" );
				}
			}
		}
	}
	g_bModInProgress = false;
}

bool IsClientAndInGame(int index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

void GetTrueName(int bot, char[] savename)
{
	int tbot = IsClientIdle(bot);
	
	if(tbot != 0)
	{
		Format(savename, 32, "★闲置:%N★", tbot);
	}
	else
	{
		GetClientName(bot, savename, 32);
	}
}

int IsClientIdle(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client))
			{
				return client;
			}
		}
	}
	return 0;
}
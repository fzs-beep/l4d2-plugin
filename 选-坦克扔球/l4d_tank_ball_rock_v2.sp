#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//ConVar's
ConVar cvarTimeExplode;
// ConVar cvarBallNum;

//Int's
// int BallNum;
int TankAlive[MAXPLAYERS+1];

//Float's
float TimeExplode;

//pragma's
#pragma semicolon 1
#pragma newdecls required

//Entity's And Sound's
#define SOUND_SPAWN1    "animation/bombing_run_01.wav"
#define EXPLOSION 1

public Plugin myinfo = {
    name        = "[L4D2]坦克扔球",
    author      = "CD意识.",
    description = "",
    version     = "1.0",
    url         = ""
};

public void OnPluginStart()
{
    cvarTimeExplode       = CreateConVar("l4d2_timer_explode", "15.0", "球爆炸延迟时间", FCVAR_NOTIFY);
    // cvarBallNum       = CreateConVar("l4d2_ball_number", "2", "一次丢几个球", FCVAR_NOTIFY);
    TimeExplode    =  cvarTimeExplode.FloatValue;
    
    cvarTimeExplode.AddChangeHook(OnTPRCVarsChanged);
    // cvarBallNum.AddChangeHook(OnTPRCVarsChanged);

    HookEvent("player_hurt", Player_Hurt);
    HookEvent("tank_spawn", Tank_Spawn);//tank 出生时候的外观初始化
    HookEvent("player_death", Player_Death);//tank 死亡时后的重置
    AutoExecConfig(true, "l4d2_tank_props");
}

public void OnTPRCVarsChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    TimeExplode    =  cvarTimeExplode.FloatValue;
    // BallNum        =  cvarBallNum.IntValue;
}

public void OnMapStart()
{
    //Models 
    CheckModelPreCache("models/props_unique/airport/atlas_break_ball.mdl");
    
    //Sound's
    PrecacheSound(SOUND_SPAWN1, true);
    
    //Particle's
    PrecacheParticle("explosion_huge_b");
    PrecacheParticle("weapon_grenade_explosion");
    PrecacheParticle("electrical_arc_01_system");
}

stock void CheckModelPreCache(const char[] Modelfile)
{
    if (!IsModelPrecached(Modelfile))
    {
        PrecacheModel(Modelfile, true);
        PrintToServer("Precaching Model:%s",Modelfile);
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tank_rock", false))
        RequestFrame(OnTankRockNextFrame, EntIndexToEntRef(entity));
}

void OnTankRockNextFrame(int iEntRef)
{
    if (!IsValidEntRef(iEntRef))
        return;
    
    int entity = EntRefToEntIndex(iEntRef);
    
    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    
    if (!IsValidClient(client))
        return;
    
    if (!IsPlayerAlive(client))
        return;

    if (GetClientTeam(client) != 3)
        return;

    CreateTimer(0.1, Car, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Player_Hurt(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    char weapon[64];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    if (StrEqual(weapon, "tank_rock", true))
    {
        float Pos[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", Pos);
        LittleFlower(Pos, EXPLOSION);
    }
}

public Action Car(Handle timer, int entity)
{
    float velocity[3];
    if (IsValidEntity(entity))
    {
        int g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");    
        GetEntDataVector(entity, g_iVelocity, velocity);
        float v = GetVectorLength(velocity);
        if (v > 500.0)
        {
            float Pos[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
            //更加精准的抛物线
            Pos[2] -= 120.0;
            // PrintToChatAll("%f %f %f",Pos[0],Pos[1],Pos[2]);
            int physics = CreateEntityByName("prop_physics_override");
            if (IsValidEntity(physics) && IsValidEdict(physics)){
                DispatchKeyValue(physics,"model", "models/props_unique/airport/atlas_break_ball.mdl");
                //删除石头
                AcceptEntityInput(entity, "kill");

                CreateTimer(TimeExplode, Explosion, physics);

                DispatchSpawn(physics);
                SetEntityRenderMode(physics, RENDER_TRANSCOLOR);
                SetEntityRenderColor(physics, 0, 0, 0, 255);
                NormalizeVector(velocity, velocity);
                float speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
                ScaleVector(velocity, speed*2.0);

                TeleportEntity(physics, Pos, NULL_VECTOR, velocity);
            }
            return Plugin_Stop;
        }        
    }
    else
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public Action Explosion(Handle timer, int physics)
{
    if (IsValidEntity(physics) && IsValidEdict(physics))
    {
    AcceptEntityInput(physics, "kill");
    float Pos[3];
    GetEntPropVector(physics, Prop_Send, "m_vecOrigin", Pos);
    ExplodeMain(Pos, physics);
    }
}

void ExplodeMain(float Pos[3], int physics)
{
    int particle = CreateEntityByName("info_particle_system");
    if( particle != -1 )
    {
        DispatchKeyValue(particle, "effect_name", "explosion_huge_b");
        
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");

        TeleportEntity(particle, Pos, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("OnUser1 !self:Kill::20.0:-1");
        AcceptEntityInput(particle, "AddOutput");
        AcceptEntityInput(particle, "FireUser1"); 
    }
    
    LittleFlower(Pos, EXPLOSION);
    EmitSoundToAll(SOUND_SPAWN1, physics);
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if( table == INVALID_STRING_TABLE )
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

public Action LittleFlower(float Pos[3], int type)
{
    int explosion = CreateEntityByName("prop_physics");
    if (IsValidEntity(explosion))
    {
        Pos[2] += 10.0;
        if (type == 1)
        {
            DispatchKeyValue(explosion, "model", "models/props_junk/propanecanister001a.mdl");
        }
        DispatchSpawn(explosion);
        SetEntData(explosion, GetEntSendPropOffs(explosion, "m_CollisionGroup"), 1, 1, true);
        TeleportEntity(explosion, Pos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(explosion, "break");
    }
}

/**
 * Validates if is a valid entity reference.
 *
 * @param client        Entity reference.
 * @return              True if entity reference is valid, false otherwise.
 */
bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}


///////////坦克装扮//////////////////
public Action Tank_Spawn( Event hEvent, const char[] sEvent_Name, bool bDontBroadcast )
{
    int client =  GetClientOfUserId( hEvent.GetInt( "userid" ) );
    if (client > 0 && IsClientInGame(client)){
        TankAlive[client] = 1;
        CreateTimer(0.1, TankSpawnTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE);
        // 染色
        SetEntityRenderColor(client, 0, 0, 0, 255);
    }
}

public Action TankSpawnTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if (client > 0)
	{
		if (IsTank(client))
		{
            // CreateTimer(0.1, BallTankTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE);
            if (IsFakeClient(client))
            {
            SetClientInfo(client, "name", "Ball King");
            }
		}
	}
}

// public Action BallTankTimer(Handle hTimer, any UserID)
// {
// 	int client = GetClientOfUserId( UserID );
// 	if (client > 0 && IsTank(client))
// 	{
//         float Origin[3], Angles[3];
//         GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
//         Origin[0] -= 10500;
//         Origin[1] -= 8350;
//         Origin[2] += 1500;
//         PrintToChatAll("%f %f %f",Origin[0],Origin[1],Origin[2]);

//         GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
//         Angles[0] += 90.0;
//         int ent[5];
//         for (int count=0; count<1; count++)
//         {
//             ent[count] = CreateEntityByName("prop_dynamic_override");
//             if (IsValidEntity(ent[count]))
//             {
//                 char tName[64];
//                 Format(tName, sizeof(tName), "Tank%d", client);
//                 DispatchKeyValue(client, "targetname", tName);
//                 GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

//                 DispatchKeyValue(ent[count], "model", "models/props_unique/airport/atlas_break_ball.mdl");
//                 DispatchKeyValue(ent[count], "targetname", "TireEntity");
//                 DispatchKeyValue(ent[count], "parentname", tName);
//                 DispatchKeyValueVector(ent[count], "origin", Origin);
//                 DispatchKeyValueVector(ent[count], "angles", Angles);
//                 SetEntPropFloat(ent[count], Prop_Send, "m_flModelScale", 0.5);
//                 DispatchSpawn(ent[count]);
//                 SetVariantString(tName);
//                 AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
//                 // switch(count)
//                 // {
//                 //     case 0:SetVariantString("mouth");
//                 //     case 1:SetVariantString("rfoot");
//                 //     case 2:SetVariantString("lfoot");
//                 //     case 3:SetVariantString("rhand");
//                 //     case 4:SetVariantString("lhand");
//                 // }
//                 SetVariantString("mouth");
//                 AcceptEntityInput(ent[count], "SetParentAttachment");

//                 // float Pos[3];
//                 // GetEntPropVector(ent[count], Prop_Send, "m_vecOrigin", Pos);
//                 // Pos[2] -= 200;
//                 // PrintToChatAll("%f %f %f",Pos[0],Pos[1],Pos[2]);

//                 AcceptEntityInput(ent[count], "Enable");
//                 AcceptEntityInput(ent[count], "DisableCollision");
//                 SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);
//                 TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
//             }
//         }
// 	}
// }

public Action Player_Death( Event hEvent, const char[] sEvent_Name, bool bDontBroadcast )
{
    int client = GetClientOfUserId( hEvent.GetInt( "userid" ) );
    if (client > 0 && IsClientInGame(client))
    {
        if (IsTank(client))
        {
            ExecTankDeath(client);		
        }	
    }
}

stock bool IsTank(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && !IsPlayerIncap(client) && TankAlive[client] == 1)
	{
		char classname[32];
		GetEntityNetClass(client, classname, sizeof(classname));
		if (StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

stock bool IsPlayerIncap( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isIncapacitated", 1 ) ){
		return true;
    }
	return false;
}

stock void ExecTankDeath(int client)
{
    TankAlive[client] = 0;
    // int entity = -1;
    // while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
    // {
    //     char model[128];
    //     GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
    //     if (StrEqual(model, "models/props_unique/airport/atlas_break_ball.mdl"))
    //     {
    //         int owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");
    //         if (owner == client)
    //         {
    //             AcceptEntityInput(entity, "Kill");
    //         }
    //     }
    // }
}


// bool ParentOverlay(int witch) // adds additional layer since witch itself does not have attachment point on spine
// {
//     // prevent double overlay
//     if ( IsValidEntRef(g_iOverlay[witch]) )
//         return true;
    
//     int entity = CreateEntityByName("prop_dynamic_ornament");
//     if( entity != -1 )
//     {
//         MoveType mt = GetEntityMoveType(witch);
//         SetEntityMoveType(witch, MOVETYPE_NONE);
//         DispatchKeyValue(entity, "spawnflags", "256");
//         DispatchKeyValue(entity, "solid", "0");
//         DispatchKeyValue(entity, "rendermode", "1");
//         DispatchKeyValue(entity, "renderfx", "6");
//         DispatchKeyValue(entity, "renderamt", "0");
//         DispatchKeyValue(entity, "rendercolor", "255 255 255");
//         DispatchKeyValue(entity, "disablereceiveshadows", "1");
//         DispatchKeyValue(entity, "model", "models/survivors/survivor_teenangst.mdl");
//         DispatchSpawn(entity);
//         ActivateEntity(entity);
//         SetVariantString("!activator");
//         AcceptEntityInput(entity, "SetParent", witch);
//         SetVariantString("!activator");
//         AcceptEntityInput(entity, "SetAttached", witch);
//         AcceptEntityInput(entity, "TurnOn");
//         SetEntityMoveType(witch, mt);
//         g_iOverlay[witch] = EntIndexToEntRef(entity);
//         return true;
//     }
//     return false;
// } 


//     int overlay = g_iOverlay[witch];
    
//     SetEntProp(weapon, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
//     SetVariantString("!activator");
//     AcceptEntityInput(weapon, "SetParent", overlay);
//     //...
//     sAttach = "medkit";
//     SetVariantString(sAttach);
//     AcceptEntityInput(weapon, "SetParentAttachment");
//     TeleportEntity(weapon, pos, ang, NULL_VECTOR);
//     SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", witch); 
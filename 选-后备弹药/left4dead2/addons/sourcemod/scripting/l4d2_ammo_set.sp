#include <sourcemod>
#include <sdktools>

new bool:Theammoset;
new bool:Rloadammoset;

public OnPluginStart()
{
	RegAdminCmd("sm_onammo", Onammosets, ADMFLAG_ROOT, "双倍弹药");
	RegAdminCmd("sm_offammo", Offammosets, ADMFLAG_ROOT, "关闭弹药");
	RegAdminCmd("sm_onammo1", Onammosets2, ADMFLAG_ROOT, "更多弹药");
	HookEvent("round_start", ammoEvent_RoundStart);
	Theammoset = false;
	Rloadammoset = false;
}

public Action:Onammosets(client, args)
{
	Rloadammoset = false;
	Theammoset = true;
	CreateTimer(0.1, ammosetStartDelays, client);
}

public Action:Offammosets(client, args)
{
	Theammoset = false;
	Rloadammoset = false;
	CreateTimer(0.1, ammosetStartDelays, client);
}

public Action:Onammosets2(client, args)
{
	Theammoset = false;
	Rloadammoset = true;
	CreateTimer(0.1, ammosetStartDelays, client);
}

public Action:ammoEvent_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, ammosetStartDelays);
}

public Action:ammosetStartDelays(Handle:timer)
{
	if (Theammoset)
	{
		SetConVarInt(FindConVar("ammo_smg_max"), 1674, false, false);
		SetConVarInt(FindConVar("ammo_shotgun_max"), 150, false, false);
		SetConVarInt(FindConVar("ammo_autoshotgun_max"), 180, false, false);
		SetConVarInt(FindConVar("ammo_assaultrifle_max"), 720, false, false);
		SetConVarInt(FindConVar("ammo_huntingrifle_max"), 300, false, false);
		SetConVarInt(FindConVar("ammo_sniperrifle_max"), 360, false, false);
		SetConVarInt(FindConVar("ammo_grenadelauncher_max"), 60, false, false);
		PrintToChatAll("\x04[提示]\x03已开启\x04双倍\x05后备弹药.");
	}
	if (Rloadammoset)
	{
		SetConVarInt(FindConVar("ammo_smg_max"), 3047, false, false);
		SetConVarInt(FindConVar("ammo_shotgun_max"), 300, false, false);
		SetConVarInt(FindConVar("ammo_autoshotgun_max"), 400, false, false);
		SetConVarInt(FindConVar("ammo_assaultrifle_max"), 2023, false, false);
		SetConVarInt(FindConVar("ammo_huntingrifle_max"), 750, false, false);
		SetConVarInt(FindConVar("ammo_sniperrifle_max"), 750, false, false);
		SetConVarInt(FindConVar("ammo_grenadelauncher_max"), 150, false, false);
		PrintToChatAll("\x04[提示]\x03已开启\x04更多\x05后备弹药.");
	}
	if (!Rloadammoset && !Theammoset)
	{
		SetConVarInt(FindConVar("ammo_smg_max"), 650, false, false);
		SetConVarInt(FindConVar("ammo_shotgun_max"), 72, false, false);
		SetConVarInt(FindConVar("ammo_autoshotgun_max"), 90, false, false);
		SetConVarInt(FindConVar("ammo_assaultrifle_max"), 360, false, false);
		SetConVarInt(FindConVar("ammo_huntingrifle_max"), 150, false, false);
		SetConVarInt(FindConVar("ammo_sniperrifle_max"), 180, false, false);
		SetConVarInt(FindConVar("ammo_grenadelauncher_max"), 30, false, false);
		PrintToChatAll("\x04[提示]\x03已关闭\x04更多\x05后备弹药.");
	}
	return;
}
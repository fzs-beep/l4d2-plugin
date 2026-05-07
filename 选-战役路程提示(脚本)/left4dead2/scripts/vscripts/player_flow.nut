local iIterPoint	= 0;
local aReachedPoint	= array(3, false);

function AnnouncePlayerProggress(iProgress)
{
	local hPlayer = null;

	while (hPlayer = Entities.FindByClassname(hPlayer, "player"))
	{
		if (IsPlayerABot(hPlayer))
		{
			continue;
		}
		
		ClientPrint(hPlayer, DirectorScript.HUD_PRINTTALK, "\x01生还者已经完成了 " + "\x03" + iProgress+ "%" + "\x01" + " 的路程！");
		
		EmitSoundOnClient("Survival.team_record", hPlayer);
	}
}

function Update()
{
	local szGameModeBase = Director.GetGameModeBase();
	switch (szGameModeBase[0])
	{
		case 's':
		case 'v':
		{			
			return;
		}
	}
	
	local iFurthestFlow = (Director.GetFurthestSurvivorFlow() / GetMaxFlowDistance() * 100).tointeger();

	if (!aReachedPoint[0] && iFurthestFlow >= 25)
	{
		AnnouncePlayerProggress(25);
		aReachedPoint[iIterPoint] = true;
		iIterPoint++;
	}
	else if (!aReachedPoint[1] && iFurthestFlow >= 50)
	{
		AnnouncePlayerProggress(50);
		aReachedPoint[iIterPoint] = true;
		iIterPoint++;
	}
	else if (!aReachedPoint[2] && iFurthestFlow >= 75)
	{
		AnnouncePlayerProggress(75);
		aReachedPoint[iIterPoint] = true;
	}
}

function OnGameEvent_player_say(tParams)
{
	local iFurthestFlow
	local iClient;
	local szMessage;
	
	if ("userid" in tParams && tParams.userid == 0)
	{
		return;
	}
	
	szMessage = strip(tParams["text"].tolower())
	
	if (szMessage.len() == 0)
	{
		return;
	}
	
	iClient = GetPlayerFromUserID(tParams["userid"]);
	
	if (szMessage == "!p")
	{
		iFurthestFlow = (Director.GetFurthestSurvivorFlow() / GetMaxFlowDistance() * 100).tointeger();
		
		ClientPrint(iClient, DirectorScript.HUD_PRINTTALK, "\x01当前进度 " + "\x03" + iFurthestFlow+ "%")
	}
}

__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
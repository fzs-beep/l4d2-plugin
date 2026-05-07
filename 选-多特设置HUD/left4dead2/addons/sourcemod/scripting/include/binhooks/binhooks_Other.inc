enum SurvivorSet
{
	DEf = -3,
	DESC,
	RANDOM,
	NICK,     
	ROCHELLE,       
	COACH,        
	ELLIS,     
	BILL,       
	ZOEY,        
	FRANCIS,     
	LOUIS,               
};

/**
 * Create Survivor Bot.(windows zoey no longer crash.You feel free to create zoey)
 *
 *
 * @return	 		SurvivorBot index;
 * @error			map no running(-1).
 */
native int CreateSurvivorBot(SurvivorSet survivor,bool istatic = false);

/**
 * Get All Infected Ladder Count.
 *
 *
 * @return	 		Ladders Max Count,-1 error;
 * @error			map no running(-1).
 */
native int GetAllInfectedLadderCount();

/**
 * Get All Infected Ladder pos.
 *
 *
 * @serial	 		from 0 to GetAllInfectedLadderCount();
 * @vec	 		    from 0 to GetAllInfectedLadderCount();
 * @error			map no running(-1).
 */
native bool GetInfectedLadderPos(int serial,float vec[3]);

/**
 * get Bot Client attack target.
 *
 *
 * @no return	 
 * @error			invalid client.
 */
native int GetClientAttackTarget(int client);

/**
 * control Bot to attack target.
 *
 *
 * @no return	 
 * @error			invalid bot or invalid target.
 */
native void SetFakeClientAimTarget(int bot, int target);

/**
 * cancel Bot to attack target.
 *
 *
 * @no return	 
 * @error			invalid bot.
 */
native void ResetFakeClient(int bot);

/**
 * By Defib Revive Client.(通过电击效果复活，但必须有尸体才能复活，有电击特效)
 *
 *
 * @no return	 
 * @error			invalid Client.
 */
native void ReviveClientByDefib(int client);

/**
 * Respawn Client.(任何时候皆可以复活，无尸体都可以，这是无签名版本，不会随着服务器更新而导致崩服)
 *
 *
 * @no return	 
 * @error			invalid Client.
 */
native void RespawnClient(int client);

/**
 * From Incap Revive Client.
 *
 *
 * @no return	 
 * @error			invalid Client.
 */
native void ReviveClientFromIncap(int client);

/**
 * whether Client Has Visible Threats.
 *
 *
 * @return	 		if Has Visible Threats for true,false otherwise;
 * @error			invalid cleint.
 */
stock bool IsClientHasVisibleThreats(int client)
{
	return HasEntProp(client, Prop_Send, "m_hasVisibleThreats") && !!GetEntProp(client, Prop_Send, "m_hasVisibleThreats");
}

/**
 * whether Has Any Client Recently Be Hurt.
 *
 *
 * @return	 		if Has Any Client Recently Be Hurt for true,false otherwise;
 * @error			no error.
 */
#pragma deprecated invaild.
native bool HasAnyClientRecentlyBeHurt();

/**
 * whether Client currently in combat.
 *
 *
 * @return	 		if Has Any Client Recently Be Hurt for true,false otherwise;
 * @error			no error.
 */
native bool IsClientInCombat(int client);


/**
 * whether Client Has Mess Around.
 *
 *
 * @return	 		if Has Mess Around for true,false otherwise;
 * @error			no error.
 */
stock bool IsClientHasMessAround(int client)
{
	return !IsClientHasVisibleThreats(client);
}

/**
 * whether Has Any Survivor Left Safe Area.
 *
 *
 * @return	 		if Has Any Survivor Left Safe Area for true,false otherwise;
 * @error			no error.
 */
#pragma deprecated invaild.
native bool HasAnySurvivorLeftSafeArea();

/**
 * whether Client Be Held.
 *
 *
 * @return	 		if Client Be Held for true,false otherwise;
 * @error			no error.
 */
/* stock bool IsClientHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (jockey > 0 || charger > 0 || hunter > 0 || smoker > 0)
	{
		return true;
	}
	return false;
} */

/**
 * @brief Returns the victim when a Survivor is Controled by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int GetInfectedBySurvivorControled(int client)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	int victim;

	switch( class )
	{
		case 1:		victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
		case 3:		victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
		case 5:		victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		case 6:
		{
			victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
			if( victim < 1 ) victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
		}
	}

	if( victim > 0 )
		return victim;

	return 0;
}

/**
 * @brief Returns the attacker when a Survivor is Controled by a Special Infected
 *
 * @param client			Client ID of the player to check
 *
 * @return Attacker client index, or 0 if none
 */
stock int GetSurvivorByInfectedControl(int client)
{
	int attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker")) > 0 )
		return attacker;

	if( (attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker")) > 0 )
		return attacker;

	return 0;
}

/**
 * whether Entity Be Biled.
 *
 *
 * @return	 		if Entity Be Biled for true,false otherwise;
 * @error			invalid entity.
 */
 
stock bool IsEntityBiled(int entity)
{
	float specialisbiled = GetEntPropFloat(entity, Prop_Send, "m_vomitFadeStart");
	if (specialisbiled != 0.0 && specialisbiled - GetGameTime() <= 5.0 && specialisbiled >= GetGameTime())
	{
		 return true;
	}
	return false;
} 

/**
 * Get the distance between the lead and trailing survivors.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetAveragedSurvivorDistance();

/**
 * Get Averaged Survivor Speed along the flow.
 *
 *
 * @return	 		Survivor Speed;
 * @error			invalid cleint.
 */
native float GetAveragedSurvivorSpeed();

/**
 * Get the Survivor with the highest flow.
 *
 *
 * @return	 		Survivor distance;
 * @error			invalid cleint.
 */
native int GetHighestFlowSurvivor();

/**
 * Get the Survivor with the lowest flow.
 *
 *
 * @return	 		Survivor distance;
 * @error			invalid cleint.
 */
native int GetLowestFlowSurvivor();

/**
 * Get the distance along the flow that the Furthest survivors have reached.
 *
 *
 * @return	 		Survivor distance;
 * @error			invalid cleint.
 */
native float GetFurthestSurvivorFlow();

/**
 * Get the navigation flow distance from the start to the end of the level.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetMaxFlowDistance();

/**
 * Get the navigation flow distance from the start to the Average survivors position.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetAverageSurvivorFlowDistance();

/**
 * Get the navigation flow distance from the start to the specified player.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetCurrentFlowDistanceForPlayer(int client);

/**
 * Get how far in the Percent navigation flow from the start to the end the player is.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetCurrentFlowPercentForPlayer(int client);

/**
 * Get the navigation flow distance from the start to the specified point.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetFlowDistanceForPosition(float pos[3]);

/**
 * Get how far in the Percent navigation flow from the start to the end the position is.
 *
 *
 * @return	 		distance;
 * @error			invalid cleint.
 */
native float GetFlowPercentForPosition(float pos[3]);

/**
 * @brief Removes lobby reservation from a server
 * @remarks Sets the reservation cookie to 0,
 *			it is safe to call this even if it's unreserved.
 */
native void BinHook_LobbyUnreserve();

/**
 * @brief Returns whether or not a map is currently running.
 *
 * @return			True if a map is currently running, otherwise false.
 */
native bool IsMapRunning();

/**
 * @brief Returns whether or not a map is currently Intro.
 *
 * @return			True if a map is currently Intro, otherwise false.
 */
native bool IsMapInIntro();

/**
 * @brief pushing an entity in the given direction.
 * 
 * @error				invalid entity.
 * @noreturn			
 */
native void PushEntity(int entity, float vec[3]);

/**
 * @brief Spining an entity in the given direction.
 * 
 * @error				invalid entity.
 * @noreturn			
 */
native void SpinEntity(int entity, float vec[3]);

/**
 * Adds two Bign int or float string together.
 *
 * Note:  This is the same as the '+' operator.
 *
 * @param str1         First value.
 * @param str2         Second value.
 * @param strResult    str1 + str2.
 * @param maxlength    Maximum length of strResult buffer.
 * @return             if value>0 return 1;if value==0 return 0;if value<0 return -1.
 */
native int BignAdd(const char[] str1, const char[] str2, char[] strResult, int maxlength);

/**
 * Subtracts str2 from str1(int or float string).
 *
 * Note:  This is the same as the '-' operator.
 *
 * @param str1         First value.
 * @param str2         Second value.
 * @param strResult    str1 - str2.
 * @param maxlength    Maximum length of strResult buffer.
 * @return             if value>0 return 1;if value==0 return 0;if value<0 return -1.
 */
native int BignSub(const char[] str1, const char[] str2, char[] strResult, int maxlength);

/**
 * Called when the player or client  was stucked.
 *
 *
 * @return  Plugin_Continue or Plugin_Handled.
 * @error			invalid client or player isn't alive.
 */
forward Action OnPlayerStuck(int client);

/**
 * Called when the player or client manual freedom speaking.(检测玩家是否用了自由麦，hook检测，效率高)
 *
 *
 * @return  Plugin_Continue.
 * @error			invalid client.
 */
#pragma deprecated invaild.
forward Action OnPlayerVoice(int client);
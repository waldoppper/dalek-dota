
----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "mode_defend_ally_generic", package.seeall )

----------------------------------------------------------------------------------------------------

function OnStart()

    SetTarget()

end

----------------------------------------------------------------------------------------------------

function OnEnd()

    local npcBot = GetBot();
    npcBot:Action_Chat("Explain!", true)

end

----------------------------------------------------------------------------------------------------

function Think()

    local me = GetBot();
    local myTarget = me:GetAttackTarget()
    if (myTarget:IsAlive())
    then
--        me:Action_Chat("Target Eleminated!", true)
    else
        SetTarget()
    end

end

function SetTarget()

    local me = GetBot();
    local tableNearbyRetreatingEnemyHeroes = me:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
    local fBestAttackScore = 0;
    local bestRetreatingEnemy;
    -- Who is the best enemy to attack?
    for _, npcEnemy in pairs(tableNearbyRetreatingEnemyHeroes)
    do
        local fAttackScore = GetAttackScore( me, npcEnemy );
        if ( fAttackScore > fBestAttackScore)
        then
            fBestAttackScore = fAttackScore;
            bestRetreatingEnemy = npcEnemy;
        end
    end
    local myTargetsName = bestRetreatingEnemy:GetUnitName()
    me:Action_Chat(string.format("Exterminate %s", myTargetsName), true)
    me:Action_AttackUnit(bestRetreatingEnemy, false)

end

----------------------------------------------------------------------------------------------------

function GetDesire()

	local npcBot = GetBot();
	local nearbyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE);
	if ( #nearbyHeroes == 0 )
	then
		return BOT_MODE_DESIRE_NONE;
    else
        return 0.99
    end

end

----------------------------------------------------------------------------------------------------

function GetAttackScore( me, npcEnemy )

    local nEstimatedDamageToHim = npcEnemy:GetEstimatedDamageToTarget( false, me, 6.0, DAMAGE_TYPE_ALL );
	return nEstimatedDamageToHim;

end

----------------------------------------------------------------------------------------------------

for k,v in pairs( mode_defend_ally_generic ) do	_G._savedEnv[k] = v end

----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "mode_defend_ally_generic", package.seeall )

----------------------------------------------------------------------------------------------------

function OnStart()
    local me = GetBot();
    me:Action_Chat("EXTERMINATE!", true)

    local tableNearbyRetreatingEnemyHeroes = me:GetNearbyHeroes( 1000, true, BOT_MODE_RETREAT );
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

    me:Action_AttackUnit(bestRetreatingEnemy, false)

end

----------------------------------------------------------------------------------------------------

function OnEnd()
    local npcBot = GetBot();
    npcBot:Action_Chat("Explain!", true)
end

----------------------------------------------------------------------------------------------------
--
--function Think()
--	--print( "mode_defend_ally_generic.Think" );
--end

----------------------------------------------------------------------------------------------------

function GetDesire()

	local npcBot = GetBot();

	local tableNearbyRetreatingEnemyHeroes = npcBot:GetNearbyHeroes( 1000, true, BOT_MODE_RETREAT );
	if ( #tableNearbyRetreatingEnemyHeroes == 0 )
	then
		return BOT_MODE_DESIRE_NONE;
    else
        return 1.0
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

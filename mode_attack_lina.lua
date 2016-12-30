
----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "mode_attack_lina", package.seeall )
require( GetScriptDirectory().."/bot_utils" )

----------------------------------------------------------------------------------------------------
BOT_MODE_DESIRE_HAM = 0.99 -- HARD AS A MOTHER
----------------------------------------------------------------------------------------------------

function OnStart()
    print("entering OnStart")
    bot_utils.Yell("Searching for target!")
end

----------------------------------------------------------------------------------------------------

function OnEnd()
    print("entering OnEmd")
    bot_utils.Yell("Explain!")
end

----------------------------------------------------------------------------------------------------

function Think()
    print("entering Think")
    SetTarget()
end

function SetTarget()
    print("entering SetTarget")
    -- if target is no longer valid, get a new one
    if not bot_utils:CanExterminateTarget()
    then
        local me = GetBot();
        local tableNearbyEnemyHeroes = me:GetNearbyHeroes( 1500, true, BOT_MODE_NONE );
        local fBestAttackScore = 0;
        local bestTarget;
        -- Who is the best enemy to attack?
        for _, npcEnemy in pairs(tableNearbyEnemyHeroes)
        do

            local fAttackScore = GetAttackScore( me, npcEnemy );
            if ( fAttackScore > fBestAttackScore)
            then
                fBestAttackScore = fAttackScore;
                bestTarget = npcEnemy;
            end
        end


        if (bestTarget == nil)
        then
            return
        else
            local myTargetsName = bestTarget:GetUnitName()
            bot_utils.Yell(string.format("Exterminate %s", myTargetsName))
            me:Action_AttackUnit(bestTarget, false)
        end
    end

end

----------------------------------------------------------------------------------------------------

function GetDesire()
    local me = GetBot();
    local nearbyEnemies = me:GetNearbyHeroes( 1000, true, BOT_MODE_NONE);

    -- if we've got a target, keep desire HAM
    if ((not bot_utils:CanExterminateTarget()) and #nearbyEnemies == 0)
    then
        print("No attack desire")
        return BOT_MODE_DESIRE_NONE;
    else
        print("HAM MODE ENGAGE")
        return BOT_MODE_DESIRE_HAM
    end

end

----------------------------------------------------------------------------------------------------

function GetAttackScore( me, npcEnemy )

    local nEstimatedDamageToHim = npcEnemy:GetEstimatedDamageToTarget( false, me, 6.0, DAMAGE_TYPE_ALL );
	return nEstimatedDamageToHim;

end

----------------------------------------------------------------------------------------------------

for k,v in pairs( mode_attack_lina ) do	_G._savedEnv[k] = v end

----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------

_G._savedEnv = getfenv()
module( "bot_utils", package.seeall )

----------------------------------------------------------------------------------------------------

function Yell(something)
    local npcBot = GetBot();
    npcBot:Action_Chat(something, true)
end

-- test active target's state for targetability
function CanExterminateTarget()
    local me = GetBot();
    local myTarget = me:GetAttackTarget()
    if (myTarget ~= nil and myTarget:IsAlive())
    then
        local targetStaleness = myTarget:GetTimeSinceLastSeen()
        return targetStaleness <= 5.0
    else
        return false
    end
end

----------------------------------------------------------------------------------------------------

for k,v in pairs( bot_utils ) do	_G._savedEnv[k] = v end

----------------------------------------------------------------------------------------------------

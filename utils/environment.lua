ENEMY_CREEP_STATUS = "enemy-creep-status"
COUNT_ENEMY_CREEEP_STATUS = "count-enemy-creep-status"
HP_TICKS = "HP-ticks"
iDPS = "incoming-dps"
TIME_BEFORE_DIES_NATURALLY = "time-b4-dies-naturally"
TIME_BEFORE_KILLABLE = "time-b4-hero-killable"
KILLABLE_BY_HERO = "killable-by-hero?"
SOME_DILUTION_CONST = 12 -- TODO HOW TO FIX
HP_HISTORY_WINDOW = 3

local M = {}
M[ENEMY_CREEP_STATUS]={}
M[COUNT_ENEMY_CREEEP_STATUS]=0

function table.removekey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function M:CreepGC(currentCreeps)
    local trackedCreepTable = self[ENEMY_CREEP_STATUS];
    for creep, _ in pairs(trackedCreepTable) do
        if creep and not table.contains(currentCreeps, creep) then
            table.removekey(trackedCreepTable, creep)
            self[COUNT_ENEMY_CREEEP_STATUS] = self[COUNT_ENEMY_CREEEP_STATUS]-1
        end
    end
end

function M:GetCreepHealthDeltaPerSec(creep)
    if(self[ENEMY_CREEP_STATUS][creep] == nil) then
        return 0;
    else
        local dataPoints = 0
        for _time,_health in pairsByKeys(self[ENEMY_CREEP_STATUS][creep][HP_TICKS],sortFunc)
        do
            dataPoints = dataPoints + 1;
            -- Consider HP at around 3 seconds ago and calculate based on that -- TODO this can be improved
            if(GameTime() - _time < HP_HISTORY_WINDOW and dataPoints > 1) then
                local e = (creep:GetHealth() - _health) / (GameTime() - _time);
                return e;
            end
        end
        return 0;
    end
end

local function GetFriendlyCreepName(creep)
    return string.gsub(
        string.gsub(creep:GetUnitName(), "npc_dota_creep_badguys_", ""),
        "npc_dota_badguys_", "")
end

function M:UpdateCreepsStatus(hero, creeps)

    local creepStatusCount = self[COUNT_ENEMY_CREEEP_STATUS]

    --
    --debugging
    local debugLines = "\n---Enemy Creep Status Table---"..
            "\n-----------------------------------------------------\n"..
            "name\tiDPS\tHP\tTb4K\tCan Kill?"..
            "\n-----------------------------------------------------\n"
    --debugging
    --

    for _, creep in pairs(creeps) do

        --
        --debugging
        debugLines = debugLines.."\n"..GetFriendlyCreepName(creep).."\t"
        --debugging
        --

        local creepStatus = self[ENEMY_CREEP_STATUS][creep]
        if(creepStatus == nil) then
            creepStatus = {};
            creepStatusCount = creepStatusCount+1
            self[ENEMY_CREEP_STATUS][creep] = creepStatus
            self[COUNT_ENEMY_CREEEP_STATUS] = creepStatusCount
        end

        local creepHealth = creep:GetHealth();
        local creepHealthMax = creep:GetMaxHealth();
        if(creepHealth < creepHealthMax) then
            if (creepStatus[HP_TICKS] == nil) then creepStatus[HP_TICKS] = {} end
            creepStatus[HP_TICKS][GameTime()] = creep:GetHealth();

            -- update the state of this creep's incoming damage
            local idps = self:GetCreepHealthDeltaPerSec(creep)
            local projectedPhysDmg = creep:GetActualDamage(hero:GetBaseDamage() - SOME_DILUTION_CONST, DAMAGE_TYPE_PHYSICAL)
            local timeBeforeDiesNaturally = self:TimeBeforeCreepDies(creepHealth, idps)
            local timeBeforHeroKillable = self:TimeBeforeKillableByHero(hero, 187, creep, creepHealth, idps)
            local isKillableByHero = (timeBeforHeroKillable < 1) or (creepHealth < projectedPhysDmg)

            creepStatus[iDPS] = idps
            creepStatus[TIME_BEFORE_DIES_NATURALLY] = timeBeforeDiesNaturally
            creepStatus[TIME_BEFORE_KILLABLE] = timeBeforHeroKillable
            creepStatus[KILLABLE_BY_HERO] = isKillableByHero

            --
            -- debugging
            debugLines = debugLines..string.format("%.1f", idps).."\t"..
                    string.format("%i", creepHealth).."\t"..
                    string.format("%.1f", timeBeforHeroKillable).."\t"..
                    tostring(isKillableByHero).."\t"
            -- debugging
            --
        end

        --
        -- debugging
        if creepStatus[HP_TICKS] then
--            for _, hp in pairs(creepStatus[HP_TICKS]) do
--                debugLines = debugLines .."\t"..hp
--            end
        end
        -- debugging
        --
    end

    -- debugging
    if(true) then
        print(debugLines)
        print(string.format("keeping track of %i creep status", creepStatusCount))
    end
    -- debugging

--    if(creepStatusCount > 15) then -- TODO change back to 500 or something
        self:CreepGC(creeps);
--    end
end


-- Note attack range is actually larger than what is published. See http://dev.dota2.com/showthread.php?t=275597
function M:TimeBeforeCreepDies(creepHP, creepsIDPS)
    return (creepHP*-1) / creepsIDPS
end

function M:TimeBeforeKillableByHero(hero, hisAttackRange, creep, creepHP, creepsIDPS)
    local projectedPhysDmg = creep:GetActualDamage(hero:GetBaseDamage() - SOME_DILUTION_CONST, DAMAGE_TYPE_PHYSICAL)
    local creepHPAfterHeroHits = creepHP - projectedPhysDmg

    local heroMS = hero:GetCurrentMovementSpeed()
    local distanceToTarget = GetUnitToUnitDistance(hero, creep)
    local distanceToClose = math.max(0, distanceToTarget - hisAttackRange)
    local timeToApproachTarget = distanceToClose / heroMS
    local heroAttackPoint = hero:GetAttackPoint()

    local damageWhileApproaching = (timeToApproachTarget + heroAttackPoint) * creepsIDPS * -1

    if creepsIDPS>=0 then
        return 10000
    else
        return (-1* (creepHPAfterHeroHits - damageWhileApproaching) / creepsIDPS)
    end
end


function M:FindCreepToKill()
    for creep,creepStatus in pairs(self[ENEMY_CREEP_STATUS]) do
        if creepStatus[KILLABLE_BY_HERO] then
            return creep
        end
    end

end

return M
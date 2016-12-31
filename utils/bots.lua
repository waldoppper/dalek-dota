-- This was taken from https://raw.githubusercontent.com/lenLRX/dota2Bots/master/utility.lua
local M = {}

M["PointsOnLane"] = {}

local function InitPointsOnLane(PointsOnLane)
    for lane = 1, 3, 1 do
        PointsOnLane[lane] = {};
        for j = 0, 100, 1 do
            PointsOnLane[lane][j] = GetLocationAlongLane(lane,j / 100.0);
        end
    end
end

InitPointsOnLane(M["PointsOnLane"]);


function M.NilOrDead(Unit)
    return Unit == nil or not Unit:IsAlive();
end

function M.AbilityOutOfRange4Unit(Ability,Unit)
    return GetUnitToUnitDistance(GetBot(),Unit) > Ability:GetCastRange();
end

function M.AbilityOutOfRange4Location(Ability,Location)
    return GetUnitToLocationDistance(GetBot(),Location) > Ability:GetCastRange();
end

--TODO I don't think this works for DIRE
function M:GetNearByPrecursorPointOnLane(Lane,Location)
    local npcBot = GetBot();
    local Pos = npcBot:GetLocation();
    if Location ~= nil then
        Pos = Location;
    end

    local PointsOnLane =  self["PointsOnLane"][Lane];
    local prevDist = (Pos - PointsOnLane[1]):Length2D();
    for i = 1,100,1 do
        local d = (Pos - PointsOnLane[i]):Length2D();
        if(d > prevDist) then
            -- Presumably this is so that units don't try to move to the same spot in the fountain??
            if i >= 4 then
                return PointsOnLane[i - 4] + RandomVector(50);
            else
                return PointsOnLane[i - 1];
            end
        else
            prevDist = d;
        end
    end

    return PointsOnLane[100];
end

function M:GetNearBySuccessorPointOnLane(Lane,Location)
    local npcBot = GetBot();
    local Pos = npcBot:GetLocation();
    if Location ~= nil then
        Pos = Location;
    end

    local PointsOnLane =  self["PointsOnLane"][Lane];
    local prevDist = (Pos - PointsOnLane[100]):Length2D();
    for i = 100,0,-1 do
        local d = (Pos - PointsOnLane[i]):Length2D();
        if(d > prevDist) then
            if i <= 96 then
                return PointsOnLane[i + 4] + RandomVector(100);
            else
                return PointsOnLane[i + 1];
            end
        else
            prevDist = d;
        end
    end

    return PointsOnLane[1];
end

function M.IsItemAvailable(item_name)
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
        if(item and item:GetName() == item_name) then
            return item;
        end
    end
    return nil;
end

function M:GetComfortPoint(creeps,LANE)
    local npcBot = GetBot();
    local _ = npcBot:GetLocation();
    local x_pos_sum = 0;
    local y_pos_sum = 0;
    local count = 0;
    local meele_coefficient = 5;-- Consider meele creeps first
    local coefficient = 1;
    for _,creep in pairs(creeps)
    do
        local creep_name = creep:GetUnitName();
        local meleepos = string.find( creep_name,"melee");
        if(meleepos ~= nil) then
            coefficient = meele_coefficient;
        else
            coefficient = 1;
        end

        local creep_pos = creep:GetLocation();
        x_pos_sum = x_pos_sum + coefficient * creep_pos[1];
        y_pos_sum = y_pos_sum + coefficient * creep_pos[2];
        count = count + coefficient;
    end

    local avg_pos_x = x_pos_sum / count;
    local avg_pos_y = y_pos_sum / count;

    -- with centroid located, get a semi-random safe point behind it
    if(count > 0) then
        return self:GetNearByPrecursorPointOnLane(LANE,Vector(avg_pos_x,avg_pos_y)) + RandomVector(20);
    else
        return nil;
    end;
end

function M:HasEmptySlot()
    local npcBot = GetBot();
    -- query item code by Hewdraw
    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
        if(item == nil) then
            return true;
        end
    end
    return false;
end

function M:CourierThink()
    local npcBot = GetBot();
    for i = 9, 15, 1 do
        local item = npcBot:GetItemInSlot(i);
        if((item ~= nil or npcBot:GetCourierValue() > 0) and IsCourierAvailable()) then
            --print("got item");
            npcBot:Action_CourierDeliver();
            return;
        end
    end
end

function M:GetFrontTowerAt(LANE)
    local T1 = -1;
    local T2 = -1;
    local T3 = -1;

    if(LANE == LANE_TOP) then
        T1 = TOWER_TOP_1;
        T2 = TOWER_TOP_2;
        T3 = TOWER_TOP_3;
    elseif(LANE == LANE_MID) then
        T1 = TOWER_MID_1;
        T2 = TOWER_MID_2;
        T3 = TOWER_MID_3;
    elseif(LANE == LANE_BOT) then
        T1 = TOWER_BOT_1;
        T2 = TOWER_BOT_2;
        T3 = TOWER_BOT_3;
    end

    local tower = GetTower(GetTeam(),T1);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end

    tower = GetTower(GetTeam(),T2);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end

    tower = GetTower(GetTeam(),T3);
    if(tower ~= nil and tower:IsAlive())then
        return tower;
    end
    return nil;
end

function M:CreepGC()
    -- does it works? i don't know
    print("CreepGC");
    local swp_table = {}
    for handle,time_health in pairs(self["creeps"])
    do
        local rm = false;
        for t,_ in pairs(time_health)
        do
            if(GameTime() - t > 60) then
                rm = true;
            end
            break;
        end
        if not rm then
            swp_table[handle] = time_health;
        end
    end

    self["creeps"] = swp_table;
end

function M:UpdateCreepHealth(creep)
    if self["creeps"] == nil then
        self["creeps"] = {};
    end

    if(self["creeps"][creep] == nil) then
        self["creeps"][creep] = {};
    end
    if(creep:GetHealth() < creep:GetMaxHealth()) then
        self["creeps"][creep][GameTime()] = creep:GetHealth();
    end

    if(#self["creeps"] > 1000) then
        self:CreepGC();
    end
end

function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0                 -- iterator variable
    local iter = function ()    -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

function sortFunc(a , b)
    if a < b then
        return true
    end
end

function M:GetCreepHealthDeltaPerSec(creep)
    if self["creeps"] == nil then
        self["creeps"] = {};
    end

    if(self["creeps"][creep] == nil) then
        return 10000000;
    else
        for _time,_health in pairsByKeys(self["creeps"][creep],sortFunc)
        do
            -- only Consider very recent datas
            if(GameTime() - _time < 3) then
                local e = (_health - creep:GetHealth()) / (GameTime() - _time);
                return e;
            end
        end
        return 10000000;
    end
end

MAX_HP_LOG_ENTRIES = 50
function M:LogVitals()
    local ix;
    local hpLog;
    if self["hp-log"] == nil then
        hpLog = {}
        ix = 1
        self["hp-log"] = hpLog;
        self["next-hp-log-index"] = ix
    else
        hpLog = self["hp-log"]
        ix = self["next-hp-log-index"]
    end
    hpLog[ix]=GetBot():GetHealth();
    if(ix == MAX_HP_LOG_ENTRIES) then
        ix = 1
    end
    self["next-hp-log-index"] = ix+1

--    for key,value in pairs(hpLog) do print(key,value) end
end

function M:IsTakingDamage()
    if self["hp-log"] == nil then return false;
    else
        local hpLog = self["hp-log"]
        local oldestLogIX = self["next-hp-log-index"]
        local newestLogIX
        if (oldestLogIX == 1) then newestLogIX = MAX_HP_LOG_ENTRIES;
        else newestLogIX = oldestLogIX-1 end
        local takingDamage = hpLog[oldestLogIX] > hpLog[newestLogIX]
        print(string.format("taking damage: %s", tostring(takingDamage)));
        return takingDamage
    end
end

function M:ConsiderRunAway()
    local npcBot = GetBot();
    local enemy = npcBot:GetNearbyHeroes( 600, true, BOT_MODE_NONE );
    if(#enemy > 1 and DotaTime() > 360) then
        return true;
    end
    return false;
end

function M:GetEnemyBots()
    local myteam = GetTeam();
    if myteam == TEAM_DIRE then
        return GetTeamPlayers(TEAM_RADIANT);
    else
        return GetTeamPlayers(TEAM_DIRE);
    end
end

function M:GetEnemyTeam()
    local myteam = GetTeam();
    if myteam == TEAM_DIRE then
        return TEAM_RADIANT;
    else
        return TEAM_DIRE;
    end
end


-- This stuff is mine
function M:Yell(something)
    local npcBot = GetBot();
    npcBot:Action_Chat(something, true)
end

-- test active target's state for targetability
-- TODO REMOVE
function M:CanExterminateTarget()
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

function M:IsTowerAThreat()
    local npcBot = GetBot();
    local nearbyTowers = npcBot:GetNearbyTowers(800,true);
    local allyCreeps = npcBot:GetNearbyCreeps(650,false);

    local friendlyCreepHP = 0
    for _,creep in pairs(allyCreeps)
    do
        friendlyCreepHP = friendlyCreepHP + creep:GetHealth()
    end

    if(#nearbyTowers > 0) then
        for _,tower in pairs(nearbyTowers)
        do
            if(GetUnitToUnitDistance(tower,npcBot) < 900 and tower:IsAlive() and friendlyCreepHP <= 500) then
                print("Tower danger!");
                return true;
            end
        end
    end
    return false;
end

--Perry's code from http://dev.dota2.com/showthread.php?t=274837]
function M:PerryGetHeroLevel()
    local npcBot = GetBot();
    local respawnTable = {8, 10, 12, 14, 16, 26, 28, 30, 32, 34, 36, 46, 48, 50, 52, 54, 56, 66, 70, 74, 78,  82, 86, 90, 100};
    local nRespawnTime = npcBot:GetRespawnTime() +1 -- It gives 1 second lower values.
    for k,v in pairs (respawnTable) do
        if v == nRespawnTime then
            return k
        end
    end
end

return M;
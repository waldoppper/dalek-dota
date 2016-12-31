local DotaBotUtility = require(GetScriptDirectory().."/utils/bots");
local Constant = require(GetScriptDirectory().."/utils/constants");

local STATE_IDLE = "STATE_IDLE";
local STATE_CSING = "STATE_CSING";
local STATE_HEALING = "STATE_HEALING";
local STATE_FIND_LANE_SAFETY = "FIND_LANE_SAFETY";
local STATE_RUN_AWAY = "STATE_RUN_AWAY";

local RetreatHPThresh = 0.3;
local RetreatMPThresh = 0.1;

local STATE = STATE_IDLE;
local LANE = LANE_MID

ATTACK_RANGE = 150

local function ShouldHeal()
    local me = GetBot();
    return me:GetHealth() / me:GetMaxHealth() < RetreatHPThresh
           or me:GetMana() / me:GetMaxMana() < RetreatMPThresh;
end

local function FarmACreep(StateMachine)
    local me = GetBot();
    if ( me:IsUsingAbility() ) then return end;

    local EnemyCreeps = me:GetNearbyCreeps(1000,true);
    -- Check if we're already using an ability

    -- TODO Consider using each ability

    --If we dont cast ability, just try to last hit.

    local weakest_creeps_hp = 100000;
    local weakest_creep
    for _,creep in pairs(EnemyCreeps)
    do
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        if(creep:IsAlive()) then
            local creep_hp = creep:GetHealth()
            if(weakest_creeps_hp > creep_hp) then
                weakest_creeps_hp = creep_hp
                weakest_creep = creep
            end
        end
    end

    local myMovementSpeed = me:GetCurrentMovementSpeed()
    if(weakest_creep ~= nil and weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
        local distanceToTarget = GetUnitToUnitDistance(me,weakest_creep)
        local timeToApproachTarget = distanceToTarget / myMovementSpeed
        local projectedPhysDmg = weakest_creep:GetActualDamage(me:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL)
        local interpolatedDoT = (DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep) * (timeToApproachTarget +me:GetAttackPoint()))
        local projectedDamageAtAttackTime = (projectedPhysDmg * 0.85) + interpolatedDoT

        if(weakest_creeps_hp < projectedDamageAtAttackTime) then
--            print(string.format("Weakest creep's HP: %f <= Incoming phys dmg: %f + Interpolated DoT: %f", weakest_creeps_hp, incomingPhysDmg, interpolatedDoT ))
            if(me:GetAttackTarget() == nil) then
                me:Action_AttackUnit(weakest_creep,true);
                return;
            end
        elseif (distanceToTarget < ATTACK_RANGE) then
            -- simulation of human attack and stop
            if(me:GetCurrentActionType() == BOT_ACTION_TYPE_ATTACK) then
                me:Action_ClearActions(true);
                return;
            else
                me:Action_AttackUnit(weakest_creep,false);
                return;
            end
        else
            return;
        end
        weakest_creep = nil;

    end
    -- nothing to do , try to attack heros

    -- return

    -- hit creeps to push
    local TimeNow = DotaTime();
    for _,creep in pairs(EnemyCreeps)
    do
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        if(creep:IsAlive()) then
            if(TimeNow > 600) then
                me:Action_AttackUnit(creep,false);
                return;
            end
            local creep_hp = creep:GetHealth();
            if(weakest_creeps_hp > creep_hp) then
                weakest_creeps_hp = creep_hp;
                weakest_creep = creep;
            end
        end
    end

end


-------------------local states-----------------------------------------------------

local function StateIdle(StateMachine)
    local hero = GetBot();
    if(hero:IsAlive() == false) then
        return;
    end

    local creeps = hero:GetNearbyCreeps(1000,true);

    for _, creep in pairs(creeps)
        do DotaBotUtility:UpdateCreepHealth(creep) end

    if ( hero:IsUsingAbility() or hero:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(#creeps > 0) then
        if(DotaBotUtility:IsTakingDamage()) then StateMachine.State = STATE_FIND_LANE_SAFETY;
        else StateMachine.State = STATE_CSING; end
        return;
    end

    -- buy a tp and get out
    if(hero:DistanceFromFountain() < 100 and DotaTime() > 0) then
        local tpscroll = DotaBotUtility.IsItemAvailable("item_tpscroll");
        if(tpscroll == nil and DotaBotUtility:HasEmptySlot() and hero:GetGold() >= GetItemCost("item_tpscroll")) then
            print("buying tp");
            hero:Action_PurchaseItem("item_tpscroll");
            return;
        elseif(tpscroll ~= nil and tpscroll:IsFullyCastable()) then
            local tower = DotaBotUtility:GetFrontTowerAt(LANE);
            if(tower ~= nil) then
                hero:Action_UseAbilityOnEntity(tpscroll,tower);
                return;
            end
        end
    end

--    local NearbyTowers = hero:GetNearbyTowers(1000,true);
--    local AllyCreeps = hero:GetNearbyCreeps(800,false);

    --TODO tower attack state
--    for _,tower in pairs(NearbyTowers)
--    do
--        local myDistanceToTower = GetUnitToUnitDistance(hero,tower);
--        if(tower:IsAlive() and #AllyCreeps >= 1 and #creeps == 0) then
--            for _,creep in pairs(AllyCreeps)
--            do
--                if(myDistanceToTower > GetUnitToUnitDistance(creep,tower) + 300) then
--                    print("Attack tower!!!");
--                    hero:Action_AttackUnit(tower,false);
--                    return;
--                end
--            end
--        end
--    end

    if(DotaTime() < 20) then --TODO RUNE HUNTING
        local tower = DotaBotUtility:GetFrontTowerAt(LANE);
        hero:Action_MoveToLocation(tower:GetLocation());
        return;
    else
        local target = DotaBotUtility:GetNearBySuccessorPointOnLane(LANE);
        hero:Action_AttackMove(target);
        return;
    end
end

local function StateHealing(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;
    --[[
            I don't know how to Create a object of Location so I borrow one from GetLocation()

            Got Vector from marko.polo at http://dev.dota2.com/showthread.php?t=274301
    ]]

    me:Action_MoveToLocation(Constant.HomePosition());

    if(me:GetHealth() == me:GetMaxHealth() and me:GetMana() == me:GetMaxMana()) then
        StateMachine.State = STATE_IDLE;
        return;
    end
end

local function StateFindLaneSafety(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = me:GetNearbyCreeps(1000,true);
    local comfortPoint = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;

    -- if i made it, change state
    elseif(comfortPoint ~= nil and GetUnitToLocationDistance(me, comfortPoint) < 10) then
        StateMachine.State = STATE_IDLE;
        return;
    elseif(#creeps > 0 and comfortPoint ~= nil) then
            me:Action_MoveToLocation(comfortPoint);
        return;
    else print("WAT!?")
    end
end

local function StateRunAway(StateMachine)
    local me = GetBot();

    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        StateMachine["RunAwayFromLocation"] = nil;
        return;
    end

    local mypos = me:GetLocation();

    if(StateMachine["RunAwayFromLocation"] == nil) then
        --set the target to go back
        StateMachine["RunAwayFromLocation"] = mypos;
        me:Action_MoveToLocation(DotaBotUtility:GetNearByPrecursorPointOnLane(LANE));
        return;
    else
        if(GetUnitToLocationDistance(me,StateMachine["RunAwayFromLocation"]) > 400) then
            -- we are far enough from tower,return to normal state.
            StateMachine["RunAwayFromLocation"] = nil;
            StateMachine.State = STATE_IDLE;
            return;
        else
            me:Action_MoveToLocation(DotaBotUtility:GetNearByPrecursorPointOnLane(LANE));
            return;
        end
    end
end

local function StateCsing(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = me:GetNearbyCreeps(1000,true);
    local comfort = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;


    elseif(#creeps > 0) then
        if(DotaBotUtility:IsTakingDamage()) then StateMachine.State = STATE_FIND_LANE_SAFETY;
        else
            FarmACreep(StateMachine);
        end
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

local StateMachine = {};
StateMachine["State"] = STATE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_CSING] = StateCsing;
StateMachine[STATE_HEALING] = StateHealing;
StateMachine[STATE_FIND_LANE_SAFETY] = StateFindLaneSafety;
StateMachine[STATE_RUN_AWAY] = StateRunAway;


local AbilityMap = {
    [1] = "alchemist_goblins_greed",
    [2] = "alchemist_acid_spray",
    [3] = "alchemist_goblins_greed",
    [4] = "alchemist_acid_spray",
    [5] = "alchemist_goblins_greed",
    [6] = "alchemist_chemical_rage",
    [7] = "alchemist_goblins_greed",
    [8] = "alchemist_acid_spray",
    [9] = "alchemist_acid_spray",
    [10] = "special", --TODO
    [11] = "alchemist_chemical_rage",
    [12] = "alchemist_unstable_concoction",
    [13] = "alchemist_unstable_concoction",
    [14] = "alchemist_unstable_concoction",
    [15] = "special",
    [16] = "alchemist_chemical_rage",
    [18] = "alchemist_unstable_concoction",
    [20] = "special",
    [25] = "special"
};

local NeedsLeveling = {};
for lvl,_ in pairs(AbilityMap)
do
    NeedsLeveling[lvl] = true;
end

local function TryLeveling()
    -- Is there a bug? http://dev.dota2.com/showthread.php?t=274436
    local npcBot = GetBot();
    local heroLevel = DotaBotUtility:PerryGetHeroLevel();
    local abilityName = AbilityMap[heroLevel]
    if(NeedsLeveling[heroLevel]) then
        print(string.format("Leveling to %i. Picking %s", heroLevel, abilityName ))
        npcBot:Action_LevelAbility(abilityName);
        NeedsLeveling[heroLevel] = false;
    end
end

local PrevState = "none";
function Think(  )
    local _ = GetBot();
    -- TODO CROW
    TryLeveling();
    -- TOOD ITEMS

    DotaBotUtility:LogVitals()

    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end

    if(DotaTime() > 2500) then
        LANE = LANE_MID;
    end

end
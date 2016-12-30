local DotaBotUtility = require(GetScriptDirectory().."/utils/bots");
local Constant = require(GetScriptDirectory().."/utils/constants");

local STATE_IDLE = "STATE_IDLE";
local STATE_ATTACKING_CREEP = "STATE_ATTACKING_CREEP";
local STATE_HEALING = "STATE_HEALING";
local STATE_GOTO_COMFORT_POINT = "STATE_GOTO_COMFORT_POINT";
local STATE_FIGHTING = "STATE_FIGHTING";
local STATE_RUN_AWAY = "STATE_RUN_AWAY";

local RetreatHPThresh = 0.3;
local RetreatMPThresh = 0.1;

local STATE = STATE_IDLE;
local LANE = LANE_MID

local function ShouldHeal()
    local me = GetBot();
    return me:GetHealth() / me:GetMaxHealth() < RetreatHPThresh
           or me:GetMana() / me:GetMaxMana() < RetreatMPThresh;
end





local function ConsiderAttackCreeps(StateMachine)
    -- there are creeps try to attack them --
    --print("ConsiderAttackCreeps");
    local npcBot = GetBot();

    local EnemyCreeps = npcBot:GetNearbyCreeps(1000,true);
    local AllyCreeps = npcBot:GetNearbyCreeps(1000,false);

    -- Check if we're already using an ability
    if ( npcBot:IsUsingAbility() ) then return end;
--
--    local abilityLSA = npcBot:GetAbilityByName( "lina_light_strike_array" );
--    local abilityDS = npcBot:GetAbilityByName( "lina_dragon_slave" );
--    local abilityLB = npcBot:GetAbilityByName( "lina_laguna_blade" );

    -- Consider using each ability

    --TODO

    --print("desires: " .. castLBDesire .. " " .. castLSADesire .. " " .. castDSDesire);

    --If we dont cast ability, just try to last hit.

    local lowest_hp = 100000;
    local weakest_creep;
    for _,creep in pairs(EnemyCreeps)
    do
--        npcBot:GetEstimatedDamageToTarget
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        DotaBotUtility:UpdateCreepHealth(creep);
        if(creep:IsAlive()) then
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                lowest_hp = creep_hp;
                weakest_creep = creep;
            end
        end
    end

    if(weakest_creep ~= nil and weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
        if(lowest_hp < weakest_creep:GetActualDamage(
            npcBot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL)
                + DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep)
                * (npcBot:GetAttackPoint() / npcBot:GetAttackSpeed()
                + GetUnitToUnitDistance(npcBot,weakest_creep) / 1000)) then
            if(npcBot:GetAttackTarget() == nil) then --StateMachine["attcking creep"]
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            elseif(weakest_creep ~= StateMachine["attcking creep"]) then
                StateMachine["attcking creep"] = weakest_creep;
                npcBot:Action_AttackUnit(weakest_creep,true);
                return;
            end
        else
            -- simulation of human attack and stop
            if(npcBot:GetCurrentActionType() == BOT_ACTION_TYPE_ATTACK) then
                npcBot:Action_ClearActions(true);
                return;
            else
                npcBot:Action_AttackUnit(weakest_creep,false);
                return;
            end
        end
        weakest_creep = nil;

    end

    for _,creep in pairs(AllyCreeps)
    do
--        npcBot:GetEstimatedDamageToTarget
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        DotaBotUtility:UpdateCreepHealth(creep);
        if(creep:IsAlive()) then
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                lowest_hp = creep_hp;
                weakest_creep = creep;
            end
        end
    end

    if(weakest_creep ~= nil) then
        -- if creep's hp is lower than 70(because I don't Know how much is my damadge!!), try to last hit it.
        if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget()) and
                lowest_hp < weakest_creep:GetActualDamage(
            npcBot:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL) + DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep)
                * (npcBot:GetAttackPoint() / npcBot:GetAttackSpeed()
                + GetUnitToUnitDistance(npcBot,weakest_creep) / 1000)
                and
                weakest_creep:GetHealth() / weakest_creep:GetMaxHealth() < 0.5) then
            local Attacking_creep = weakest_creep;
            npcBot:Action_AttackUnit(Attacking_creep,true);
            return;
        end
        weakest_creep = nil;

    end

    -- nothing to do , try to attack heros

    local NearbyEnemyHeroes = npcBot:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
    if(NearbyEnemyHeroes ~= nil) then
        for _,npcEnemy in pairs( NearbyEnemyHeroes )
        do
            if(DotaBotUtility.NilOrDead(npcBot:GetAttackTarget())) then
                npcBot:Action_AttackUnit(npcEnemy,false);
                return;
            end
        end
    end

    -- hit creeps to push
    local TimeNow = DotaTime();
    for _,creep in pairs(EnemyCreeps)
    do
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        if(creep:IsAlive()) then
            if(TimeNow > 600) then
                npcBot:Action_AttackUnit(creep,false);
                return;
            end
            local creep_hp = creep:GetHealth();
            if(lowest_hp > creep_hp) then
                lowest_hp = creep_hp;
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
    local comfortPoint = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if ( hero:IsUsingAbility() or hero:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(#creeps > 0 and comfortPoint ~= nil) then
        local _ = hero:GetLocation();

        local d = GetUnitToLocationDistance(hero, comfortPoint);
        if(d > 250) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            StateMachine.State = STATE_ATTACKING_CREEP;
        end
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

    local NearbyTowers = hero:GetNearbyTowers(1000,true);
    local AllyCreeps = hero:GetNearbyCreeps(800,false);

    for _,tower in pairs(NearbyTowers)
    do
        local myDistanceToTower = GetUnitToUnitDistance(hero,tower);
        if(tower:IsAlive() and #AllyCreeps >= 1 and #creeps == 0) then
            for _,creep in pairs(AllyCreeps)
            do
                if(myDistanceToTower > GetUnitToUnitDistance(creep,tower) + 300) then
                    print("Lina attack tower!!!");
                    hero:Action_AttackUnit(tower,false);
                    return;
                end
            end
        end
    end

    if(DotaTime() < 20) then
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

local function StateGotoComfortPoint(StateMachine)
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = npcBot:GetNearbyCreeps(1000,true);
    local comfortPoint = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if ( npcBot:IsUsingAbility() or npcBot:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(#creeps > 0 and comfortPoint ~= nil) then

        local d = (npcBot:GetLocation() - comfortPoint):Length2D();
        if (d < 200) then
            StateMachine.State = STATE_ATTACKING_CREEP;
        else
            npcBot:Action_MoveToLocation(comfortPoint);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
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

local function StateAttackingCreep(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local creeps = me:GetNearbyCreeps(1000,true);
    local pt = DotaBotUtility:GetComfortPoint(creeps,LANE);

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAttackingMe()) then
        StateMachine.State = STATE_RUN_AWAY;
    elseif(#creeps > 0 and pt ~= nil) then

        local d = GetUnitToLocationDistance(me,pt);
        if(d > 250) then
            StateMachine.State = STATE_GOTO_COMFORT_POINT;
        else
            ConsiderAttackCreeps(StateMachine);
        end
        return;
    else
        StateMachine.State = STATE_IDLE;
        return;
    end
end

local StateMachine = {};
StateMachine["State"] = STATE;
StateMachine[STATE_IDLE] = StateIdle;
StateMachine[STATE_ATTACKING_CREEP] = StateAttackingCreep;
StateMachine[STATE_HEALING] = StateHealing;
StateMachine[STATE_GOTO_COMFORT_POINT] = StateGotoComfortPoint;
StateMachine[STATE_RUN_AWAY] = StateRunAway;
StateMachine["totalLevelOfAbilities"] = 0;


local PrevState = "none";
function Think(  )
    local _ = GetBot();
    -- TODO CROW
    -- TODO LVL UP
    -- TOOD ITEMS
    StateMachine[StateMachine.State](StateMachine);

    if(PrevState ~= StateMachine.State) then
        print("STATE: "..StateMachine.State);
        PrevState = StateMachine.State;
    end

    if(DotaTime() > 2500) then
        LANE = LANE_MID;
    end

end
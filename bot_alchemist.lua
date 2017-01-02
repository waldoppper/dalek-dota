local DotaBotUtility = dofile(GetScriptDirectory().."/utils/bots");
local Constant = require(GetScriptDirectory().."/utils/constants");

local STATE_IDLE = "STATE_IDLE";
local STATE_MOVING_TO_LANE = "MOVING_TO_LANE";
local STATE_CSING = "STATE_CSING";
local STATE_FOUNTAIN_HEALING = "STATE_HEALING";
local STATE_FRESHENING_UP = "STATE_FRESHENING";
local STATE_FIND_LANE_SAFETY = "FIND_LANE_SAFETY";
local STATE_RUN_AWAY = "STATE_RUN_AWAY";

local RetreatHPThresh = 0.3;
local RetreatMPThresh = 0.1;

local STATE = STATE_IDLE;
local LANE = LANE_MID

ATTACK_RANGE = 188 --TODO FIX THIS, ITS ACTUALLY 150, but something else is involved in allowing a physical attack on a unit

local function ShouldHeal()
    local me = GetBot();
    return me:GetHealth() / me:GetMaxHealth() < RetreatHPThresh
           or me:GetMana() / me:GetMaxMana() < RetreatMPThresh;
end

local function KillCreep(StateMachine)
    local me = GetBot();
    if ( me:IsUsingAbility() ) then return end;

    local enemyCreeps = me:GetNearbyCreeps(1000,true);
    -- Check if we're already using an ability

    -- TODO Consider using each ability

    --If we dont cast ability, just try to last hit.

    local weakest_creeps_hp = 100000;
    local weakest_creep
    for _,creep in pairs(enemyCreeps)
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
    local weakestCreepPctHP = weakest_creep:GetHealth() / weakest_creep:GetMaxHealth();
    if(weakest_creep ~= nil and weakestCreepPctHP < 0.5 ) then
        local distanceToTarget = GetUnitToUnitDistance(me,weakest_creep)
        local distanceToClose = math.max(0, (GetUnitToUnitDistance(me,weakest_creep) - ATTACK_RANGE))
        local timeToApproachTarget = distanceToClose / myMovementSpeed
        local myAttackPoint = me:GetAttackPoint()
        -- dampen this by base attack dmg variability --TODO don't hardcode it
        local projectedPhysDmg = weakest_creep:GetActualDamage(me:GetBaseDamage(),DAMAGE_TYPE_PHYSICAL) - 12
        local creepsIncomingDPS = DotaBotUtility:GetCreepHealthDeltaPerSec(weakest_creep)
        local interpolatedDoT = creepsIncomingDPS * (timeToApproachTarget + myAttackPoint)
        local projectedDamageAtAttackTime = projectedPhysDmg + interpolatedDoT

--        print(string.format(
--            "MS: %f. My Attack Point: %f. Distance to target: %f, Distance to close: %f. My dmg: %f. Approach time: %f. Creeps iDPS: %f, Interpolated DoT: %f. Final Total After My Attack: %f. Target HP: %f",
--            myMovementSpeed, myAttackPoint, distanceToTarget, distanceToClose, projectedPhysDmg, timeToApproachTarget, creepsIncomingDPS, interpolatedDoT, projectedDamageAtAttackTime, weakest_creeps_hp ))

        -- LAST HIT THE SUCKER
        if(weakest_creeps_hp < projectedDamageAtAttackTime) then
--            print(string.format("Weakest creep's HP: %f <= Incoming phys dmg: %f + Interpolated DoT: %f", weakest_creeps_hp, projectedPhysDmg, interpolatedDoT ))
            if(me:GetAttackTarget() == nil) then --StateMachine["attcking creep"]
--                print ("1")
                me:Action_AttackUnit(weakest_creep,false);
                return;
            elseif(weakest_creep ~= StateMachine["attcking creep"]) then
--                print ("2")
                StateMachine["attcking creep"] = weakest_creep;
                me:Action_AttackUnit(weakest_creep,true);
                return;
            end

--        -- OTHERWISE, PUMP FAKE.
--        elseif (distanceToTarget <= ATTACK_RANGE) then
--            -- simulation of human attack and stop
--            if(me:GetCurrentActionType() == BOT_ACTION_TYPE_ATTACK) then
--                print ("Cancel")
--                me:Action_ClearActions(true);
--                return;
--            else
--                print ("Swing")
--                me:Action_AttackUnit(weakest_creep,false);
--                return;
--            end
        else
            return;
        end
        weakest_creep = nil;

    end
    -- nothing to do , try to attack heros

    -- return

    -- hit creeps to push
    local currentTime = DotaTime();
    for _,creep in pairs(enemyCreeps)
    do
--        local creep_name = creep:GetUnitName();
--        print(creep_name);
        if(creep:IsAlive()) then
            if(currentTime > 1800) then
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

    if ( hero:IsUsingAbility() or hero:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_FOUNTAIN_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    end

    local creeps = hero:GetNearbyCreeps(1000,true);
    local allyCreeps = hero:GetNearbyCreeps(1000,false);

    DotaBotUtility:UpdateCreepsHealth(creeps)

    if(false) then
        StateMachine.State = STATE_CSING
        return
    elseif (#allyCreeps > 0) then
        StateMachine.State = STATE_FIND_LANE_SAFETY;
        return;
    else
        StateMachine.State = STATE_MOVING_TO_LANE
        return
    end
end

local function StateMoveToLane(StateMachine)
    local hero = GetBot();
    if(hero:IsAlive() == false) then
        return;
    end

    if ( hero:IsUsingAbility() or hero:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_FOUNTAIN_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    end

    -- buy a tp and get out
    local tower = DotaBotUtility:GetFrontTowerAt(LANE);
    local towersLocation = tower:GetLocation()
    if(hero:DistanceFromFountain() < 100 and DotaTime() > 0) then
        local tpscroll = DotaBotUtility:GetInventoryItem("item_tpscroll");
        if(tpscroll == nil and DotaBotUtility:HasEmptySlot() and hero:GetGold() >= GetItemCost("item_tpscroll")) then
            print("buying tp");
            hero:Action_PurchaseItem("item_tpscroll");
            return;
        elseif(tpscroll ~= nil and tpscroll:IsFullyCastable()) then
            if(tower ~= nil) then
                hero:Action_UseAbilityOnEntity(tpscroll,tower);
                return;
            end
        end
    elseif(GetUnitToLocationDistance(hero, towersLocation) > 400) then
        hero:Action_MoveToLocation(towersLocation);
        return;
    else
        StateMachine.State = STATE_IDLE;
    end
end

local function StateFountainHealing(StateMachine)
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

-- either healing with a potion or turning on my ult
local function StateFresheningUp(StateMachine)
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

    StateMachine.State = STATE_IDLE;
end

local function StateFindLaneSafety(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        StateMachine.State = STATE_IDLE;
        return;
    end

    local allyCreeps = me:GetNearbyCreeps(1000,false);
    local comfortPoint = DotaBotUtility:GetLaneComfortPoint(allyCreeps,LANE);
--    if (StateMachine["comfort-point"]~=nil) then
--        comfortPoint = StateMachine["comfort-point"]
--    else
--        comfortPoint = DotaBotUtility:GetLaneComfortPoint(allyCreeps,LANE);
--        StateMachine["comfort-point"] = comfortPoint
--    end

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_FOUNTAIN_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat() or DotaBotUtility:IsTakingDamage()) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_RUN_AWAY;
        return;
    elseif(comfortPoint ~= nil and GetUnitToLocationDistance(me, comfortPoint) < 100) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    elseif(#allyCreeps > 0 and comfortPoint ~= nil) then
        me:Action_MoveToLocation(comfortPoint);
        return;
    else print(string.format("How Did I get Here?? CreepCount %i or comfyPoint nil? %s", #allyCreeps, tostring(comfortPoint==nil)))
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
        StateMachine.State = STATE_FOUNTAIN_HEALING;
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
    DotaBotUtility:UpdateCreepsHealth(creeps);

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_FOUNTAIN_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;


    elseif(#creeps > 0) then
        if(DotaBotUtility:IsTakingDamage()) then StateMachine.State = STATE_FIND_LANE_SAFETY;
        else
            KillCreep(StateMachine);
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
StateMachine[STATE_FOUNTAIN_HEALING] = StateFountainHealing;
StateMachine[STATE_FIND_LANE_SAFETY] = StateFindLaneSafety;
StateMachine[STATE_RUN_AWAY] = StateRunAway;
StateMachine[STATE_FRESHENING_UP] = StateFresheningUp;
StateMachine[STATE_MOVING_TO_LANE] = StateMoveToLane;


local AbilityMap = {
    [1] = "alchemist_goblins_greed",
    [2] = "alchemist_acid_spray",
    [3] = "alchemist_goblins_greed", --TODO this doesn't seem to get leveled here
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
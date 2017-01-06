local DotaBotUtility = dofile(GetScriptDirectory().."/utils/bot");
local EnvironmentUtil = dofile(GetScriptDirectory().."/utils/environment");
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

local ULT_NAME = "alchemist_chemical_rage"

local STATE = STATE_IDLE;
local LANE = LANE_MID

ATTACK_RANGE = 188 --TODO FIX THIS, ITS ACTUALLY 150, but something else is involved in allowing a physical attack on a unit

local function ShouldHeal()
    local me = GetBot();
    return me:GetHealth() / me:GetMaxHealth() < RetreatHPThresh
           or me:GetMana() / me:GetMaxMana() < RetreatMPThresh;
end

-------------------local states-----------------------------------------------------

local function StateIdle(StateMachine)
    local me = GetBot();
    if(me:IsAlive() == false) then
        return;
    end

    if ( me:IsUsingAbility() or me:IsChanneling()) then return end;

    if(ShouldHeal()) then
        StateMachine.State = STATE_FOUNTAIN_HEALING;
        return;
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    end

    local creeps = me:GetNearbyCreeps(1400,true);
    local allyCreeps = me:GetNearbyCreeps(1000,false);

    EnvironmentUtil:UpdateCreepsStatus(me, creeps)

    local creepToKill = EnvironmentUtil:FindCreepToKill()

    if(creepToKill) then
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
        else
            hero:Action_MoveToLocation(towersLocation);
            return;
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
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_RUN_AWAY;
        return;
    end

    local creeps = me:GetNearbyCreeps(1400,true);
    EnvironmentUtil:UpdateCreepsStatus(me, creeps);
    local creepToKill = EnvironmentUtil:FindCreepToKill()
    if(creepToKill) then
        StateMachine.State = STATE_CSING
        return
    elseif(comfortPoint ~= nil and GetUnitToLocationDistance(me, comfortPoint) < 100) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_IDLE;
        return;
    elseif(#allyCreeps > 0 and comfortPoint ~= nil) then
        me:Action_MoveToLocation(comfortPoint);
        return;
    else
        StateMachine.State = STATE_IDLE;
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

    if ( me:IsUsingAbility() or me:IsChanneling()) then return
    elseif(DotaBotUtility:IsTowerAThreat()) then
        StateMachine.State = STATE_RUN_AWAY;
        return;
    end

    local creeps = me:GetNearbyCreeps(1400,true);
    EnvironmentUtil:UpdateCreepsStatus(me, creeps);

    local creepTarget = EnvironmentUtil:FindCreepToKill()
    if(creepTarget and creepTarget:IsAlive()) then
        me:Action_AttackUnit(creepTarget,true);
    else -- the HP status changed and we shouldn't continue hitting
        me:Action_ClearActions(true);
    end

    if(DotaBotUtility:IsTakingDamage()) then
        StateMachine["comfort-point"] = nil;
        StateMachine.State = STATE_RUN_AWAY;
        return;
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
    [6] = ULT_NAME,
    [7] = "alchemist_goblins_greed",
    [8] = "alchemist_acid_spray",
    [9] = "alchemist_acid_spray",
    [10] = "special", --TODO
    [11] = ULT_NAME,
    [12] = "alchemist_unstable_concoction",
    [13] = "alchemist_unstable_concoction",
    [14] = "alchemist_unstable_concoction",
    [15] = "special",
    [16] = ULT_NAME,
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
    local me = GetBot();
    local myLevel = DotaBotUtility:PerryGetHeroLevel();
    local abilityName = AbilityMap[myLevel]
    if(NeedsLeveling[myLevel]) then
        print(string.format("Leveling to %i. Picking %s", myLevel, abilityName ))
        me:Action_LevelAbility(abilityName);
        NeedsLeveling[myLevel] = false;
    end
end

local function TryUseCrow()
    local me = GetBot();
    if(IsCourierAvailable()) then
        me:Action_CourierDeliver()
    end
end

local function TryUseUlt()
    local me = GetBot();
    local myUlt = me:GetAbilityByName(ULT_NAME)
    if(myUlt:IsFullyCastable()) then
        me:Action_UseAbility(myUlt)
    end
end

local PrevState = "none";
function Think(  )

    TryLeveling();
    TryUseCrow();
    -- Always-on Ult
    TryUseUlt();

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
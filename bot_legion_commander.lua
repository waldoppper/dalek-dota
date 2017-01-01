local DotaBotUtility = require(GetScriptDirectory().."/utils/bots");
local Constant = require(GetScriptDirectory().."/utils/constants");
local Locs = require(GetScriptDirectory().."/utils/locations");

local STATE_GET_RUNE = "STATE_GET_RUNE";
local STATE_JUNGLE_FARM = "STATE_JUNGLE_FARM";


local AbilityMap = {
    [1] = "legion_commander_moment_of_courage",
    [2] = "legion_commander_press_the_attack",
    [3] = "legion_commander_moment_of_courage",
    [4] = "legion_commander_press_the_attack",
    [5] = "legion_commander_moment_of_courage",
    [6] = "legion_commander_press_the_attack",
    [7] = "legion_commander_moment_of_courage",
    [8] = "legion_commander_press_the_attack",
    [9] = "legion_commander_overwhelming_odds",
    [10] = "special", --TODO
    [11] = "legion_commander_overwhelming_odds",
    [12] = "legion_commander_overwhelming_odds",
    [13] = "legion_commander_overwhelming_odds",
    [14] = "legion_commandert_duel",
    [15] = "special",
    [16] = "legion_commander_duel",
    [18] = "legion_commander_duel",
    [20] = "special",
    [25] = "special"
};

local ItemBuyList = {
  [1] = "iron_talon",
  [2] = "tango"
};

local function StateGetRune(State)
  
end

local function StateJungleFarm(State)
  
end


local State = {};
State["State"] = STATE;
State[STATE_GET_RUNE] = StateGetRune;
State[STATE_JUNGLE_FARM] = StateJungleFarm;


local PrevState = "none";

function Think(  )
  
    -- Get the bot on which script is currently being run.
    local _ = GetBot();
    
    -- Buy Items
    -- Crow Items
    -- Level Abilities
    
    -- Not sure what this does
    --DotaBotUtility:LogVitals()

    
    State[State.State](State);

    if(PrevState ~= State.State) then
        print("STATE: "..State.State);
        PrevState = State.State;
    end

    
end
local DotaBotUtility = require(GetScriptDirectory().."/utils/bots");
local Constant = require(GetScriptDirectory().."/utils/constants");
local Locs = require(GetScriptDirectory().."/utils/locations");

local STATE_GET_RUNE = "STATE_GET_RUNE";
local STATE_JUNGLE_FARM = "STATE_JUNGLE_FARM";


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
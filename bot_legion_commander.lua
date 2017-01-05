local DotaBotUtility = dofile(GetScriptDirectory().."/utils/bot");
local Constant = dofile(GetScriptDirectory().."/utils/constants");
local Locs = dofile(GetScriptDirectory().."/utils/locations");

local STATE_IDLE = "STATE_IDLE";
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

-- Can't pick up runes atm
local function TimeToGetRune()
    return false;
end


local function StateIdle(State)
    
    local npcBot = GetBot();
    if(npcBot:IsAlive() == false) then
        return;
    end
    
    -- If time to get rune
    if(TimeToGetRune()) then
      State.State = STATE_GET_RUNE;
    else
      State.State = STATE_JUNGLE_FARM;
    end
    
    return;
end


local function StateGetRune(State)
  
  local bot = GetBot();
  
  -- Always check if alive
  if(bot:IsAlive() == false) then
    State.State = STATE_IDLE;
    return;
  end
  
  -- Head to rune spot
  bot:Action_MoveToLocation(Locs.RAD_BOUNTY_RUNE_SAFE);
  
  -- Pick up rune
--  bot:Action_PickUpRune(???);
  
  -- If rune is picked up
  State.State = STATE_JUNGLE_FARM;
  
end

local function StateJungleFarm(State)
  
  local bot = GetBot();
  
  if(bot:IsAlive() == false) then
    State.State = STATE_IDLE;
    return;
  end
  
  -- Check if rune will be spawning to enter StateGetRune
  if(TimeToGetRune()) then
    State.State = STATE_GET_RUNE;
    return;
  end
  
end




local State = {};
State["State"] = STATE_IDLE;
State[STATE_IDLE] = StateIdle;
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
--    DotaBotUtility:LogVitals()

    -- Call state function
    State[State.State](State);

    -- Log state changes, reset prev
    if(PrevState ~= State.State) then
        print("STATE: "..State.State);
        PrevState = State.State;
    end
    
end
local DotaBotUtility = require(GetScriptDirectory().."/utils/bots");

local tableItemsToBuy = {
    "item_stout_shield",
    "item_quelling_blade",
    "item_boots",
    "item_belt_of_strength",
    "item_gloves",
    "item_maelstrom",
    "item_butterfly",
--    "item_recipe_force_staff",
--    "item_point_booster",
--    "item_staff_of_wizardry",
--    "item_ogre_axe",
--    "item_blade_of_alacrity",
--    "item_mystic_staff",
--    "item_ultimate_orb",
--    "item_void_stone",`
--    "item_staff_of_wizardry",
--    "item_void_stone",
--    "item_recipe_cyclone",
--    "item_cyclone",
};

----------------------------------------------------------------------------------------------------

POT_NAME = "item_flask"
function ItemPurchaseThink()
	local me = GetBot();
    local currentTime = DotaTime();
    local heroLevel = 1;

    -- always have an HP pot early game
--    if ((GetInventoryItem(POT_NAME) == nil) and (me:GetGold() >= GetItemCost(POT_NAME)))
    if (heroLevel < 6
        and (DotaBotUtility:GetInventoryItem(POT_NAME) == nil)
        and DotaBotUtility:HasEmptySlot()
        and (me:GetGold() >= GetItemCost(POT_NAME))) then
            me:Action_PurchaseItem(POT_NAME);
    end

    if ( #tableItemsToBuy == 0 )
    then
        me:SetNextItemPurchaseValue( 0 );
        return;
    end

	local sNextItem = tableItemsToBuy[1];
	me:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );

	if ( me:GetGold() >= GetItemCost( sNextItem ) )
	then
		me:Action_PurchaseItem( sNextItem );
		table.remove( tableItemsToBuy, 1 );
	end

end

----------------------------------------------------------------------------------------------------

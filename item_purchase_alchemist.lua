require(GetScriptDirectory().."/utils/locations");

local DotaBotUtility = dofile(GetScriptDirectory().."/utils/bot");

local tableItemsToBuy = {
    "item_stout_shield",
    "item_quelling_blade",
    "item_boots",
    "item_belt_of_strength",
    "item_gloves",
    "item_gloves",
    "item_mithril_hammer",
    "item_recipe_maelstrom",
    "item_relic",
    "item_recipe_radiance",
    "item_eagle",
    "item_talisman_of_evasion",
    "item_quarterstaff",
};

local tableItemsToSell = {
    "item_flask",
    "item_stout_shield",
    "item_quelling_blade",
};

------------------------------------------------`       ----------------------------------------------------

POT_NAME = "item_flask"
function ItemPurchaseThink()
	local me = GetBot();
    local myLocation = me:GetLocation()
    local currentTime = DotaTime();
    local heroLevel = 1; -- TODO
    local slotsFilled = DotaBotUtility:NumInventorySlotsUsed()

    -- always have an HP pot early game
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

    local nextSellItemName = tableItemsToSell[1];
    local nextItemName = tableItemsToBuy[1];

    me:SetNextItemPurchaseValue( GetItemCost(nextItemName) );

	if ( me:GetGold() >= GetItemCost(nextItemName) ) then

        -- sell (drop) if we're 6 slotted
        if (IsItemPurchasedFromSecretShop(nextItemName) or slotsFilled > 5 ) then
            -- go to shop
            local shopLoc
            if(GetTeam() == TEAM_DIRE) then
                shopLoc = DIRE_SHRINE_OFF
            else
                shopLoc = RAD_SHRINE_OFF
            end
            me:Action_MoveToLocation(shopLoc);
        end

        if(slotsFilled > 5) then
            print(string.format("selling %s", nextSellItemName))
            local itemToDrop = DotaBotUtility:GetInventoryItem(nextSellItemName)
            if(itemToDrop) then
                me:Action_SellItem(itemToDrop)
            else
                table.remove( tableItemsToSell, 1 );
            end
        end

        if(me:Action_PurchaseItem(nextItemName) < 0 ) then
            table.remove( tableItemsToBuy, 1 );
        end



	end

end

----------------------------------------------------------------------------------------------------

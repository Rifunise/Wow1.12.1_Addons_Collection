BINDING_HEADER_PETFEED = "Rauen's PetFeed";
BINDING_NAME_PETFEED = "Feed Pet";

-- Configuration
PetFeed_Config = { };
PetFeed_Config.Enabled = true;
PetFeed_Config.Alert = true;
PetFeed_Config.Level = "content";

-- Foods Lists
PetFeed_Foods_Meat = { };
PetFeed_Foods_Fish = { };
PetFeed_Foods_Bread = { };
PetFeed_Foods_Cheese = { };
PetFeed_Foods_Fruit = { };
PetFeed_Foods_Fungus = { };

-- Variables
PetFeed_Var = { };
PetFeed_Var.InCombat = false;
PetFeed_Var.Searching = false;
PetFeed_Var.IsAFK = false;

function PetFeed_OnLoad()

	-- Register for Events
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PET_ATTACK_START");
	this:RegisterEvent("PET_ATTACK_STOP");
	this:RegisterEvent("UNIT_HAPPINESS");
	this:RegisterEvent("CHAT_MSG_SYSTEM");

	-- Register Slash Commands
	SLASH_PetFeed1 = "/PetFeed";
	SLASH_PetFeed2 = "/pf";
	SlashCmdList["PetFeed"] = function(msg)
		PetFeed_ChatCommandHandler(msg);
	end
	
	ChatMessage("Rauen's PetFeed Loaded.");

end

function PetFeed_OnEvent(event, arg1)

	-- Save Variables
		
	if ( event == "CHAT_MSG_SYSTEM") then
	
		local msg = arg1;
		
		if ( string.sub(msg, 1, 16) == "You are now AFK:" ) then
			PetFeed_Var.IsAFK = true;
		end
		
		if ( string.sub(msg, 1, 22) == "You are no longer AFK." ) then
			PetFeed_Var.IsAFK = false;
		end
		
	elseif ( event == "PET_ATTACK_START" ) then
	
		-- Set Flag
		PetFeed_Var.InCombat = true;
		
	elseif ( event == "PET_ATTACK_STOP" ) then
	
		-- Remove Flag
		PetFeed_Var.InCombat = false;
	
	
	elseif ( event == "UNIT_HAPPINESS" ) and ( arg1 == "pet" ) then
	
		-- Check for Pet
		if not ( UnitExists("pet") ) then
			return;
		end
		
		-- Check if AFK
		if ( PetFeed_Var.IsAFK ) then
			return;
		end
		
		-- Check if in Combat
		if ( PetFeed_Var.InCombat ) or ( PlayerFrame.inCombat ) then
			return;
		end
		
		-- Check if Has Feed Effect
		if ( PetFeed_HasFeedEffect() ) then
			return;
		end
	
		-- Check Happiness
		if ( PetFeed_Config.Enabled ) then
			PetFeed_CheckHappiness();
		end
		
	end
	
end

function PetFeed_ChatCommandHandler(msg)

	-- Check for Pet
	if not ( UnitExists("pet") ) then
		ChatMessage("You do not currently have a pet.");
		return;
	end
	
	-- Assign Variables
	local pet = UnitName("pet");

	-- Print Help
	if ( msg == "help" ) or ( msg == "" ) then
		ChatMessage("PetFeed:");
		ChatMessage("/PetFeed /pf <command>");
		ChatMessage("- help - Print this helplist.");
		ChatMessage("- on|off - Turn PetFeed on or off.");
		ChatMessage("- status - Check current settings.");
		ChatMessage("- reset - Reset to default settings.");
		ChatMessage("- alert - Toggle alerting when feeding.");
		ChatMessage("- level content/happy - Set happiness level.");
		ChatMessage("- feed - Feed your pet.");
		ChatMessage("- add <diet> <name> - Add food to list.");
		ChatMessage("- remove <diet> <name> - Remove food from list.");
		ChatMessage("- show <diet> - Show food list.");
		return;
	end
	
	-- Check Status
	if ( msg == "status" ) then
		if not ( PetFeed_Config.Enabled ) then
			ChatMessage("PetFeed is disabled.");
			return;
		end
		ChatMessage("You are letting "..pet.." eat food in your pack.");
		ChatMessage(pet.." will eat food when less than "..PetFeed_Config.Level..".");
		if ( PetFeed_Config.Alert ) then
			ChatMessage(pet.." is alerting you when feeding.");
		end
		return;
	end

	-- Turn PetFeed On
	if ( msg == "on" ) then
		PetFeed_Config.Enabled = true;
		ChatMessage("PetFeed is enabled.");
		return;
	end
	
	-- Turn PetFeed Off
	if ( msg == "off" ) then
		PetFeed_Config.Enabled = false;
		ChatMessage("PetFeed is disabled.");
		return;
	end
	
	-- Reset Variables
	if ( msg == "reset" ) then
		PetFeed_Config.Enabled = true;
		PetFeed_Config.Alert = true;
		PetFeed_Config.Level = "content";
		ChatMessage("PetFeed configuration reset.");
		ChatMessage("You are letting "..pet.." eat food in your pack.");
		ChatMessage(pet.." will eat food when less than "..PetFeed_Config.Level..".");
		return;
	end
	
	-- Toggle Alert
	if ( msg == "alert" ) then
		if ( PetFeed_Config.Alert ) then
			PetFeed_Config.Alert = false;
			ChatMessage(pet.." will no longer alert you when feeding.");
		else
			PetFeed_Config.Alert = true;
			ChatMessage(pet.." will now alert you when feeding.");
		end
	end
	
	-- Set Happiness Level
	if ( string.sub(msg, 1, 5) == "level" ) then
		if ( string.find( msg, "content" ) ) then
			PetFeed_Config.Level = "content" ;
		elseif ( string.find( msg, "happy" ) ) then
			PetFeed_Config.Level = "happy" ;
		else
			return;
		end
		ChatMessage(pet.." will now eat when less than "..PetFeed_Config.Level..".");
		return;
	end
	
	-- Feed Pet
	if ( msg == "feed" ) then
		PetFeed_Feed();
	end
	
	-- Add Food to List
	if ( string.sub(msg, 1, 3) == "add" ) then
	
		local food;
		if ( string.sub(msg, 5, 8) == "meat" ) then
		
			food = PetFeed_ParseFood(msg, "add", "meat");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Meat", food) == 0 ) then
					table.insert( PetFeed_Foods_Meat, food );
					table.sort( PetFeed_Foods_Meat );
					ChatMessage("Added "..food.." to Meat list.");
				else
					ChatMessage(food.." already in Meat list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end
			
		elseif ( string.sub(msg, 5, 8) == "fish" ) then
		
			food = PetFeed_ParseFood(msg, "add", "fish");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Fish", food) == 0 ) then
					table.insert( PetFeed_Foods_Fish, food );
					table.sort( PetFeed_Foods_Fish );
					ChatMessage("Added "..food.." to Fish list.");
				else
					ChatMessage(food.." already in Fish list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end
		
		elseif ( string.sub(msg, 5, 9) == "bread" ) then
		
			food = PetFeed_ParseFood(msg, "add", "bread");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Bread", food) == 0 ) then
					table.insert( PetFeed_Foods_Bread, food );
					table.sort( PetFeed_Foods_Bread );
					ChatMessage("Added "..food.." to Bread list.");
				else
					ChatMessage(food.." already in Bread list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end

		elseif ( string.sub(msg, 5, 10) == "cheese" ) then

			food = PetFeed_ParseFood(msg, "add", "cheese");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Cheese", food) == 0 ) then
					table.insert( PetFeed_Foods_Cheese, food );
					table.sort( PetFeed_Foods_Cheese );
					ChatMessage("Added "..food.." to Cheese list.");
				else
					ChatMessage(food.." already in Cheese list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end

		elseif ( string.sub(msg, 5, 9) == "fruit" ) then

			food = PetFeed_ParseFood(msg, "add", "fruit");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Fruit", food) == 0 ) then
					table.insert( PetFeed_Foods_Fruit, food );
					table.sort( PetFeed_Foods_Fruit );
					ChatMessage("Added "..food.." to Fruit list.");
				else
					ChatMessage(food.." already in Fruit list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end
		
		elseif ( string.sub(msg, 5, 10) == "fungus" ) then

			food = PetFeed_ParseFood(msg, "add", "fungus");
			if ( PetFeed_IsInPack(food) ) and not ( food == nil ) then
				if ( PetFeed_GetIndex("Fungus", food) == 0 ) then
					table.insert( PetFeed_Foods_Fungus, food );
					table.sort( PetFeed_Foods_Fungus );
					ChatMessage("Added "..food.." to Fungus list.");
				else
					ChatMessage(food.." already in Fungus list.");
				end
			else
				ChatMessage("Could not find "..food.." in your pack.");
			end
		else
			ChatMessage("Usage: /pf add <meat|fish|bread|cheese|fruit|fungus> <food>.");
		end
		return;
	end
	
	-- Remove Food from List
	if ( string.sub(msg, 1, 6) == "remove" ) then
	
		local food;
		if ( string.sub(msg, 8, 11) == "meat" ) then
		
			food = PetFeed_ParseFood(msg, "remove", "meat");
			if not ( PetFeed_GetIndex("Meat", food) == 0 ) then
				table.remove( PetFeed_Foods_Meat, PetFeed_GetIndex("Meat", food) );
				table.sort( PetFeed_Foods_Meat );
				ChatMessage("Removed "..food.." from Meat list.");
			else
				ChatMessage("Could not find "..food.." in Meat list.");
			end
			
		elseif ( string.sub(msg, 8, 11) == "fish" ) then
		
			food = PetFeed_ParseFood(msg, "remove", "fish");
			if not ( PetFeed_GetIndex("Fish", food) == 0 ) then
				table.remove( PetFeed_Foods_Fish, PetFeed_GetIndex("Fish", food) );
				table.sort( PetFeed_Foods_Fish );
				ChatMessage("Removed "..food.." from Fish list.");
			else
				ChatMessage("Could not find "..food.." in Fish list.");
			end
		
		elseif ( string.sub(msg, 8, 12) == "bread" ) then

			food = PetFeed_ParseFood(msg, "remove", "bread");
			if not ( PetFeed_GetIndex("Bread", food) == 0 ) then
				table.remove( PetFeed_Foods_Bread, PetFeed_GetIndex("Bread", food) );
				table.sort( PetFeed_Foods_Bread );
				ChatMessage("Removed "..food.." from Bread list.");
			else
				ChatMessage("Could not find "..food.." in Bread list.");
			end

		elseif ( string.sub(msg, 8, 13) == "cheese" ) then

			food = PetFeed_ParseFood(msg, "remove", "cheese");
			if not ( PetFeed_GetIndex("Cheese", food) == 0 ) then
				table.remove( PetFeed_Foods_Cheese, PetFeed_GetIndex("Cheese", food) );
				table.sort( PetFeed_Foods_Cheese );
				ChatMessage("Removed "..food.." from Cheese list.");
			else
				ChatMessage("Could not find "..food.." in Cheese list.");
			end
			
		elseif ( string.sub(msg, 8, 12) == "fruit" ) then

			food = PetFeed_ParseFood(msg, "remove", "fruit");
			if not ( PetFeed_GetIndex("Fruit", food) == 0 ) then
				table.remove( PetFeed_Foods_Fruit, PetFeed_GetIndex("Fruit", food) );
				table.sort( PetFeed_Foods_Fruit );
				ChatMessage("Removed "..food.." from Fruit list.");
			else
				ChatMessage("Could not find "..food.." in Fruit list.");
			end
			
		elseif ( string.sub(msg, 8, 13) == "fungus" ) then

			food = PetFeed_ParseFood(msg, "remove", "fungus");
			if not ( PetFeed_GetIndex("Fungus", food) == 0 ) then
				table.remove( PetFeed_Foods_Fungus, PetFeed_GetIndex("Fungus", food) );
				table.sort( PetFeed_Foods_Fungus );
				ChatMessage("Removed "..food.." from Fungus list.");
			else
				ChatMessage("Could not find "..food.." in Fungus list.");
			end
		else
			ChatMessage("Usage: /pf remove <meat|fish|bread|cheese|fruit|fungus> <food>.");
			
		end
		return;
	end

	-- Show Lists
	if ( string.sub(msg, 1, 4) == "show" ) then

		if ( string.sub(msg, 6, 9) == "meat" ) then
			ChatMessage("PetFeed Meat List:");
			for i=1, table.getn(PetFeed_Foods_Meat) do
				ChatMessage(" - "..PetFeed_Foods_Meat[i]);
			end
		elseif ( string.sub(msg, 6, 9) == "fish" ) then
			ChatMessage("PetFeed Fish List:");
			for i=1, table.getn(PetFeed_Foods_Fish) do
				ChatMessage(" - "..PetFeed_Foods_Fish[i]);
			end
		elseif ( string.sub(msg, 6, 10) == "bread" ) then
			ChatMessage("PetFeed Bread List:");
			for i=1, table.getn(PetFeed_Foods_Bread) do
				ChatMessage(" - "..PetFeed_Foods_Bread[i]);
			end
		elseif ( string.sub(msg, 6, 11) == "cheese" ) then
			ChatMessage("PetFeed Cheese List:");
			for i=1, table.getn(PetFeed_Foods_Cheese) do
				ChatMessage(" - "..PetFeed_Foods_Cheese[i]);
			end
		elseif ( string.sub(msg, 6, 10) == "fruit" ) then
			ChatMessage("PetFeed Fruit List:");
			for i=1, table.getn(PetFeed_Foods_Fruit) do
				ChatMessage(" - "..PetFeed_Foods_Fruit[i]);
			end
		elseif ( string.sub(msg, 6, 11) == "fungus" ) then
			ChatMessage("PetFeed Fungus List:");
			for i=1, table.getn(PetFeed_Foods_Fungus) do
				ChatMessage(" - "..PetFeed_Foods_Fungus[i]);
			end
		elseif ( string.sub(msg, 6, 8) == "all" ) then
			PetFeed_ChatCommandHandler("show meat");
			PetFeed_ChatCommandHandler("show fish");
			PetFeed_ChatCommandHandler("show bread");
			PetFeed_ChatCommandHandler("show cheese");
			PetFeed_ChatCommandHandler("show fruit");
			PetFeed_ChatCommandHandler("show fungus");
		else
			ChatMessage("Usage: /pf show <meat|fish|bread|cheese|fruit|fungus|all>.");
		end
		return;
	
	end
	
end

-- Check Happiness
function PetFeed_CheckHappiness()

	-- Get Pet Info
	local pet = UnitName("pet");
	local happiness, damage, loyalty = GetPetHappiness();
	
	local level;
	if ( PetFeed_Config.Level == "content" ) then
		level = 2;
	elseif ( PetFeed_Config.Level == "happy" ) then
		level = 3;
	end
	
	-- Check No Happiness
	if ( happiness == 0 ) or ( happiness == nil ) then
		return;
	end
	
	-- Check if Need Feeding
	if ( happiness < level ) then
		if ( PetFeed_Var.Searching ) or not ( PetFeed_Config.Alert ) then
			PetFeed_Var.Searching = false;
			PetFeed_Feed();
		else
			PetFeed_Var.Searching = true;
			ChatMessage(pet.." begins searching through your pack...");
		end
	end
	
end

-- Feed Pet
function PetFeed_Feed()
	
	-- Assign Variable
	local pet = UnitName("pet");
	
	-- Look for Food
	for m = 0, 4 do
		for n = 1, 16 do
	
			if ( PetFeed_IsInDiet(PetFeed_GetItemName(m, n)) ) then
		
				-- Feed Item
				PickupContainerItem(m, n);
				if ( CursorHasItem() ) then
					DropItemOnUnit("pet");
				end
				if ( CursorHasItem() ) then
					PickupContainerItem(m, n);
				else
				
					-- Alert
					if ( PetFeed_Config.Alert ) then
						ChatMessage(pet.." eats a "..PetFeed_GetItemName(m, n).." from your pack.");
					end
					
				end
				
				return;
				
			end
		
		end
	end
	
	-- No Food Could be Found
	ChatMessage(pet.." could not find any food in your pack.");
	
end

-- Parse Food
function PetFeed_ParseFood(msg, action, diet)
	local _, _, food = string.find(msg, "^.*%[(.*)%].*$");
	if not ( food ) then
		food = string.sub( msg, string.len(action) + 1 + string.len(diet) + 2 );
	end
	return food;
end

-- Check Feed Effect
function PetFeed_HasFeedEffect()

	local i = 1;
	local buff;
	buff = UnitBuff("pet", i);
	while buff do
		if ( string.find(buff, "Ability_Hunter_BeastTraining") ) then
			return true;
		end
		i = i + 1;
		buff = UnitBuff("pet", i);
	end
	return false;

end

-- Check Food Types
function PetFeed_IsInDiet(food)

	local diet = BuildListString(GetPetFoodTypes());
	if ( diet == nil ) then
		return false;
	end
	
	-- Check for Meat
	if ( string.find(diet, "Meat") ) then
		for i=1, table.getn(PetFeed_Foods_Meat) do
			if ( food == PetFeed_Foods_Meat[i] ) then
				return true;
			end
		end
	end
	
	-- Check for Fish
	if ( string.find(diet, "Fish") ) then
		for i=1, table.getn(PetFeed_Foods_Fish) do
			if ( food == PetFeed_Foods_Fish[i] ) then
				return true;
			end
		end
	end
	
	-- Check for Cheese
	if (string.find(diet, "Cheese") ) then
		for i=1, table.getn(PetFeed_Foods_Cheese) do
			if ( food == PetFeed_Foods_Cheese[i] ) then
				return true;
			end
		end
	end
	
	-- Check for Bread
	if ( string.find(diet, "Bread") ) then
		for i=1, table.getn(PetFeed_Foods_Bread) do
			if ( food == PetFeed_Foods_Bread[i] ) then
				return true;
			end
		end
	end
	
	-- Check for Fungus
	if ( string.find(diet, "Fungus") ) then
		for i=1, table.getn(PetFeed_Foods_Fungus) do
			if ( food == PetFeed_Foods_Fungus[i] ) then
				return true;
			end
		end
	end
	
	-- Check for Fruit
	if ( string.find(diet, "Fruit") ) then
		for i=1, table.getn(PetFeed_Foods_Fruit) do
			if ( food == PetFeed_Foods_Fruit[i] ) then
				return true;
			end
		end
	end
	
	return false;

end

-- Check for Food
function PetFeed_IsInPack(food)

	for m = 0, 4 do
		for n = 1, 16 do
			if ( PetFeed_GetItemName(m, n) == food ) then
				return true;
			end
		end
	end
	return false;
end

-- Get List Index
function PetFeed_GetIndex(diet, food)

	if ( diet == "Meat" ) then
		for i=1, table.getn(PetFeed_Foods_Meat) do
			if ( food == PetFeed_Foods_Meat[i] ) then
				return i;
			end
		end
	elseif ( diet == "Fish" ) then
		for i=1, table.getn(PetFeed_Foods_Fish) do
			if ( food == PetFeed_Foods_Fish[i] ) then
				return i;
			end
		end
	elseif ( diet == "Bread" ) then
		for i=1, table.getn(PetFeed_Foods_Bread) do
			if ( food == PetFeed_Foods_Bread[i] ) then
				return i;
			end
		end
	elseif ( diet == "Cheese" ) then
		for i=1, table.getn(PetFeed_Foods_Cheese) do
			if ( food == PetFeed_Foods_Cheese[i] ) then
				return i;
			end
		end
	elseif ( diet == "Fruit" ) then
		for i=1, table.getn(PetFeed_Foods_Fruit) do
			if ( food == PetFeed_Foods_Fruit[i] ) then
				return i;
			end
		end
	elseif ( diet == "Fungus" ) then
		for i=1, table.getn(PetFeed_Foods_Fungus) do
			if ( food == PetFeed_Foods_Fungus[i] ) then
				return i;
			end
		end
	end
	return 0;

end

-- Get Item Name
function PetFeed_GetItemName(bag, slot)
	
	local name;
	getglobal("GameTooltipTextLeft1"):SetText("");
	GameTooltip:SetBagItem( bag, slot );
	name = getglobal("GameTooltipTextLeft1"):GetText();
	if ( name == nil ) then
		name = "";
	end
	return name;
	
end

-- Send Message to Chat Frame
function ChatMessage(message)
	DEFAULT_CHAT_FRAME:AddMessage(message);
end

-- Send Message to Channel
function ChannelMessage(message, channel)
	SendChatMessage(message, channel);
end

-- Send Message to Error Frame
function ErrorMessage(message)
	UIErrorsFrame:AddMessage(message, 1.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME);
end
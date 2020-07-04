local playerMeta = FindMetaTable("Player")

-- Player data (outside of characters) handling.
do
	util.AddNetworkString("ixData")
	util.AddNetworkString("ixDataSync")

	function playerMeta:LoadData(callback)
		local name = self:SteamName()
		local steamID64 = self:SteamID64()
		local timestamp = math.floor(os.time())
		local ip = self:IPAddress():match("%d+%.%d+%.%d+%.%d+")

		local query = mysql:Select("ix_players")
			query:Select("data")
			query:Select("play_time")
			query:Where("steamid", steamID64)
			query:Callback(function(result)
				if (IsValid(self) and istable(result) and #result > 0 and result[1].data) then
					local updateQuery = mysql:Update("ix_players")
						updateQuery:Update("last_join_time", timestamp)
						updateQuery:Update("address", ip)
						updateQuery:Where("steamid", steamID64)
					updateQuery:Execute()

					self.ixPlayTime = tonumber(result[1].play_time) or 0
					self.ixData = util.JSONToTable(result[1].data)

					if (callback) then
						callback(self.ixData)
					end
				else
					local insertQuery = mysql:Insert("ix_players")
						insertQuery:Insert("steamid", steamID64)
						insertQuery:Insert("steam_name", name)
						insertQuery:Insert("play_time", 0)
						insertQuery:Insert("address", ip)
						insertQuery:Insert("last_join_time", timestamp)
						insertQuery:Insert("data", util.TableToJSON({}))
					insertQuery:Execute()

					if (callback) then
						callback({})
					end
				end
			end)
		query:Execute()
	end

	function playerMeta:SaveData()
		local name = self:SteamName()
		local steamID64 = self:SteamID64()

		local query = mysql:Update("ix_players")
			query:Update("steam_name", name)
			query:Update("play_time", math.floor((self.ixPlayTime or 0) + (RealTime() - (self.ixJoinTime or RealTime() - 1))))
			query:Update("data", util.TableToJSON(self.ixData))
			query:Where("steamid", steamID64)
		query:Execute()
	end

	function playerMeta:SetData(key, value, bNoNetworking)
		self.ixData = self.ixData or {}
		self.ixData[key] = value

		if (!bNoNetworking) then
			net.Start("ixData")
				net.WriteString(key)
				net.WriteType(value)
			net.Send(self)
		end
	end
end

-- Whitelisting information for the player.
do
	function playerMeta:SetWhitelisted(faction, whitelisted)
		if (!whitelisted) then
			whitelisted = nil
		end

		local data = ix.faction.indices[faction]

		if (data) then
			local whitelists = self:GetData("whitelists", {})
			whitelists[Schema.folder] = whitelists[Schema.folder] or {}
			whitelists[Schema.folder][data.uniqueID] = whitelisted and true or nil

			self:SetData("whitelists", whitelists)
			self:SaveData()

			return true
		end

		return false
	end
end

do
	playerMeta.ixGive = playerMeta.ixGive or playerMeta.Give

	function playerMeta:Give(className, bNoAmmo)
		local weapon

		self.ixWeaponGive = true
			weapon = self:ixGive(className, bNoAmmo)
		self.ixWeaponGive = nil

		return weapon
	end
end

do
    --- Transfers item to a specified inventory of the player.
    -- Takes item only from the specified inventory.
    -- @param itemObj [Table]
    -- @param inventory_type [String]
	function playerMeta:TransferItem(itemObj, inventory_type)
		local new_inventory = 0
		
		if (inventory_type) then
			new_inventory = inventory_type ~= "NULL" and self:GetInventory(inventory_type) or self:GetCharacter():GetInventory(true)[1]:GetID()
		else
			new_inventory = self:GetCharacter():GetInventory(true)[1]:GetID()
		end
		
		if (inventory_type and new_inventory <= 0) then
			new_inventory = self:GetInventoryID(inventory_type)
		end
		
		if (new_inventory > 0) then
			itemObj:Transfer(new_inventory)
		end
    end
	
	function playerMeta:CreateEquippableInventory(inventory_type, character, should_reset)
		character = character or self:GetCharacter()
		local equip_inv = ix.item.equippable_inventories[inventory_type]
		
		if character and equip_inv then
			local w, h = equip_inv[1], equip_inv[2]
			ix.item.RegisterInv(inventory_type, w, h)
			
			local restoreInv = self:GetInventory(inventory_type)
			
			if (not should_reset and restoreInv > 0) then
				ix.item.RestoreInv(restoreInv, w, h, function(inventory)
					inventory.vars.equippable_slot = {w, h}
					inventory.vars.inventory_type = inventory_type
					
					inventory:SetOwner(character:GetID())
					
					if (IsValid(self)) then
						inventory:AddReceiver(self)
						inventory:Sync(self)
						
						self:RegisterInventories(character)
					end
				end, true)
			else
				ix.item.NewInv(character:GetID(), inventory_type, function(inventory)
					inventory.vars.equippable_slot = {w, h}
					
					table.insert(character.vars.inv, inventory)
					
					if (IsValid(self)) then
						inventory:AddReceiver(self)
						inventory:Sync(self)
						
						self:RegisterInventories(character)
					end
				end, true)
			end
		end
	end
end
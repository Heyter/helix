ITEM.name = "Equipment Base"
ITEM.description = "An item that can be equipped."
ITEM.category = "Equipment"
ITEM.equip_slot = 'slot_accessory'
ITEM.equip_inventory = 'hand'

ITEM.action_sounds = {
	['equip'] = 'items/battery_pickup.wav',
	['unequip'] = 'items/battery_pickup.wav'
}

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:IsEquipped()) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	function ITEM:PopulateTooltip(tooltip)
		if (self:IsEquipped()) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end
	end
end

ITEM.functions.EquipUn = {
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	OnRun = function(item)
		local invID = item.player:GetCharacter():GetInventory(true)[1]:GetID()
		
		if (invID ~= 0) then
			item:Transfer(invID)
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:CanUnequip(client) ~= false and item:IsEquipped()
	end
}

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		local invID = item.player:GetInventoryID(item.equip_inventory)
		
		if invID and invID ~= 0 then
			item:Transfer(invID)
		end
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:CanEquip(client) ~= false and not item:IsEquipped()
	end
}

function ITEM:IsEquipped()
	return self:GetData("inventory_type", "") == self.equip_inventory
end

function ITEM:CanEquip(client)
end

function ITEM:CanUnequip(client)
end

function ITEM:PostEquipped(client)
end

function ITEM:PostUnequipped(client)
end

function ITEM:EquipItem(client, should_equip)
	if (should_equip) then
		self:PostEquipped(client)
		self:SetData("inventory_type", self.equip_inventory)
		hook.Run('OnItemEquipped', client, self)
	else
		self:PostUnequipped(client)
		self:SetData("inventory_type", nil)
		hook.Run('OnItemUnequipped', client, self)
	end
end

function ITEM:CanTransfer(oldInventory, newInventory)
	if (newInventory and newInventory.vars) then
		local inv_type = newInventory.vars.type
		if (inv_type == self.equip_inventory) then
			if self:CanEquip(player) == false then
				return false
			end
			
			for _, v in pairs(newInventory:GetItems()) do
				if v.equip_slot and v:IsEquipped() and v.id != self.id then
					local itemTable = ix.item.instances[v.id]
					if (not itemTable) then
						return false
					end
					
					if v.equip_slot == self.equip_slot then
						return false
					end
				end
			end
		elseif inv_type ~= self.equip_inventory and self:IsEquipped() then
		--elseif (oldInventory and oldInventory.vars and oldInventory.vars.type == self.equip_inventory and self:IsEquipped()) then
			if self:CanUnequip(self:GetOwner()) == false then
				return false
			end
		end
	end
end

function ITEM:OnSendData()
	-- local index = self.player:GetInventoryID(self.equip_inventory)
	-- if index and index ~= 0 and self:IsEquipped() then
	if (self:IsEquipped()) then
		self:EquipItem(self.player, true)
	end
end

function ITEM:OnLoadout()
	if (self:IsEquipped()) then
		self:EquipItem(self.player, true)
	end
end

function ITEM:OnTransferred(curInv, newInventory)
	if newInventory and newInventory.vars and newInventory.vars.type == self.equip_inventory and isfunction(newInventory.GetOwner) then
		local owner = newInventory:GetOwner()
		if (IsValid(owner)) then
			owner:EmitSound(self.action_sounds['equip'])
			self:EquipItem(owner, true)
		end
	end
	
	if curInv and curInv.vars and curInv.vars.type == self.equip_inventory and isfunction(curInv.GetOwner) then
		local owner = curInv:GetOwner()
		if (IsValid(owner)) then
			owner:EmitSound(self.action_sounds['unequip'])
			self:EquipItem(owner, false)
		end
	end
end
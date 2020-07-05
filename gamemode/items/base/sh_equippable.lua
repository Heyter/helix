ITEM.name = "Equipment Base"
ITEM.description = "An item that can be equipped."
ITEM.category = "Equipment"
ITEM.equip_slot = 'slot_accessory'
ITEM.equip_inventory = 'inventory_hand'

ITEM.action_sounds = {
	['equip'] = 'items/battery_pickup.wav',
	['unequip'] = 'items/battery_pickup.wav'
}

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:IsEquip()) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	function ITEM:PopulateTooltip(tooltip)
		if (item:IsEquip()) then
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
		item.player:TransferItem(item, 'NULL')
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:CanUnequip(client) ~= false and item:IsEquip() and
			hook.Run("CanPlayerUnequipItem", client, item) ~= false
	end
}

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		item.player:TransferItem(item, item.equip_inventory)
		
		return false
	end,
	OnCanRun = function(item)
		local client = item.player

		return !IsValid(item.entity) and IsValid(client) and item:CanEquip(client) ~= false and not item:IsEquip() and
			hook.Run("CanPlayerEquipItem", client, item) ~= false
	end
}

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
		self:SetData("equip", true)
		hook.Run('OnItemEquipped', client, self)
	else
		self:PostUnequipped(client)
		self:SetData("equip", nil)
		hook.Run('OnItemUnequipped', client, self)
	end
end

function ITEM:OnRemoved()
	if (self.invID ~= 0 and self:IsEquip()) then
		local inventory = ix.item.inventories[self.invID]
		local owner = self:GetOwner() or inventory.GetOwner() and inventory:GetOwner()
		
		if (IsValid(owner)) then
			self:EquipItem(owner, false)
		end
	end
end

function ITEM:CanTransfer(oldInventory, newInventory)
	if (newInventory and newInventory.vars) then
		local client = self:GetOwner()
		local inv_type = newInventory.vars.inventory_type

		if (inv_type == self.equip_inventory) then
			if self:CanEquip(client) == false then
				return false
			end
			
			for _, v in pairs(newInventory:GetItems()) do
				if v.equip_slot and v.equip_inventory == self.equip_inventory and v:IsEquip() and v.id ~= self.id then
					if (not ix.item.instances[v.id]) then
						return false
					end
					
					if v.equip_slot == self.equip_slot then
						if (IsValid(client)) then
							client:NotifyLocalized("slotOccupied")
						end
						
						return false
					end
				end
			end
		elseif inv_type ~= self.equip_inventory and self:IsEquip() and self:CanUnequip(client) == false then
			return false
		end
	end
end

function ITEM:OnLoadout()
	if (self:IsEquip()) then
		self:EquipItem(self.player, true)
	end
end

function ITEM:OnTransferred(curInv, newInventory)
	if curInv and curInv.vars and curInv.vars.inventory_type == self.equip_inventory and isfunction(curInv.GetOwner) then
		local owner = curInv:GetOwner()
		if (IsValid(owner)) then
			owner:EmitSound(self.action_sounds['unequip'])
			self:EquipItem(owner, false)
		end
	end
	
	if newInventory and newInventory.vars and newInventory.vars.inventory_type == self.equip_inventory and isfunction(newInventory.GetOwner) then
		local owner = newInventory:GetOwner()
		if (IsValid(owner)) then
			owner:EmitSound(self.action_sounds['equip'])
			self:EquipItem(owner, true)
		end
	end
end
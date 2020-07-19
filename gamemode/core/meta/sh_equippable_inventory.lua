local META = {}
META.__index = META

function META:New(inventory_type)
	local newObject = setmetatable({}, META)
	
	newObject[1] = 1 -- width inventory
	newObject[2] = 1 -- height inventory
	newObject[3] = inventory_type -- Inventory type
	newObject[4] = {} -- Inventory Vars
	newObject[5] = {} -- Derma data
	
	return newObject
end

function META:SetData(key, value, data_type)
	if (data_type == "derma") then
		self[5][key] = value
	else
		self[4][key] = value
	end
end

function META:GetData(key, default, data_type)
	local value = self[4][key]
	
	if (data_type == "derma") then
		value = self[5][key]
	end
	
	return value ~= nil and value or default
end

function META:GetType()
	return self[3]
end

function META:SetSize(w, h)
	self[1] = w
	self[2] = h
	
	self[4].equippable_slot = {1, 1}
end

function META:GetSize()
	return self[1], self[2]
end

function META:SetTitle(title)
	self[5].title = title
end

function META:GetTitle(default)
	return self[5].title or default
end

function META:SetIcon(icon)
	self[5].icon = icon
end

function META:GetIcon(default)
	return self[5].icon or default or "icon16/box.png"
end

function META:PaintSlot(w, h, slot_panel)
end

function ix.item.RegisterEquippableInv(inventory_type)
	if not inventory_type then return end
	
	local inventory = META:New(inventory_type)
	ix.item.equippable_inventories[inventory_type] = inventory
	
	return inventory
end
ITEM.base = "base_equippable"
ITEM.description = "A weapon that can be equipped."
ITEM.category = "Weapons"
ITEM.model = "models/weapons/w_pistol.mdl"
ITEM.class = "weapon_pistol"
ITEM.width = 2
ITEM.height = 2
ITEM.isWeapon = true
ITEM.isGrenade = false

ITEM.equip_slot = 'slot_weapon'

-- Inventory drawing
if (CLIENT) then
	function ITEM:PaintOver(item, w, h)
		if (item:IsEquip()) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end

	function ITEM:PopulateTooltip(tooltip)
		if (self:IsEquip()) then
			local name = tooltip:GetRow("name")
			name:SetBackgroundColor(derma.GetColor("Success", tooltip))
		end
	end
end

function ITEM:PostEquipped(client)
	if (client:HasWeapon(self.class)) then
		client:StripWeapon(self.class)
	end
	
	local weapon = client:Give(self.class, !self.isGrenade)
	
	if (IsValid(weapon)) then
		local ammoType = weapon:GetPrimaryAmmoType()
		client:SelectWeapon(weapon:GetClass())
		
		-- Remove default given ammo.
		if (client:GetAmmoCount(ammoType) == weapon:Clip1() and self:GetData("ammo", 0) == 0) then
			client:RemoveAmmo(weapon:Clip1(), ammoType)
		end
		
		-- assume that a weapon with -1 clip1 and clip2 would be a throwable (i.e hl2 grenade)
		-- TODO: figure out if this interferes with any other weapons
		if (weapon:GetMaxClip1() == -1 and weapon:GetMaxClip2() == -1 and client:GetAmmoCount(ammoType) == 0) then
			client:SetAmmo(1, ammoType)
		end
		
		if (self.isGrenade) then
			weapon:SetClip1(1)
			client:SetAmmo(0, ammoType)
		else
			weapon:SetClip1(self:GetData("ammo", 0))
		end

		weapon.ixItem = self

		if (self.OnEquipWeapon) then
			self:OnEquipWeapon(client, weapon)
		end
	else
		print(Format("[Helix] Cannot equip weapon - %s does not exist!", self.class))
	end
end

function ITEM:PostUnequipped(client, bRemoveItem)
	local weapon = client:GetWeapon(self.class)
	
	if (IsValid(weapon)) then
		weapon.ixItem = nil

		self:SetData("ammo", weapon:Clip1())
		client:StripWeapon(self.class)
	else
		print(Format("[Helix] Cannot unequip weapon - %s does not exist!", self.class))
	end
	
	self:RemovePAC(client)
	
	if (self.OnUnequipWeapon) then
		self:OnUnequipWeapon(client, weapon)
	end
	
	if (bRemoveItem) then
		self:Remove()
	end
end

function ITEM:OnSave()
	local weapon = self.player:GetWeapon(self.class)

	if (IsValid(weapon) and weapon.ixItem == self and self:IsEquip()) then
		self:SetData("ammo", weapon:Clip1())
	end
end

function ITEM:OnRemoved()
	local inventory = ix.item.inventories[self.invID]
	local owner = inventory.GetOwner and inventory:GetOwner()

	if (IsValid(owner) and owner:IsPlayer()) then
		local weapon = owner:GetWeapon(self.class)

		if (IsValid(weapon)) then
			weapon:Remove()
		end

		self:RemovePAC(owner)
	end
end

function ITEM:WearPAC(client)
	if (ix.pac and self.pacData) then
		client:AddPart(self.uniqueID, self)
	end
end

function ITEM:RemovePAC(client)
	if (ix.pac and self.pacData) then
		client:RemovePart(self.uniqueID)
	end
end

hook.Add("PlayerDeath", "ixStripEquippableClip", function(client)
	for _, v in pairs(client:GetEquippableItems()) do
		if (v.isWeapon and v:IsEquip() and self:CanUnequip(client) ~= false) then
			v:SetData("ammo", nil)
			client:TransferItem(v, 'NULL')

			if (v.pacData) then
				v:RemovePAC(client)
			end
		end
	end
end)

hook.Add("EntityRemoved", "ixRemoveEquippableGrenade", function(entity)
	-- hack to remove hl2 grenades after they've all been thrown
	if (entity:GetClass() == "weapon_frag") then
		local client = entity:GetOwner()

		if (IsValid(client) and client:IsPlayer() and client:GetCharacter()) then
			local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())

			if (isstring(ammoName) and ammoName:lower() == "grenade" and client:GetAmmoCount(ammoName) < 1 and entity.ixItem) then
				entity.ixItem:PostUnequipped(client, true)
			end
		end
	end
end)
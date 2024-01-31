﻿---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function MODULE:CharacterPreSave(character)
    local client = character:getPlayer()
    if not IsValid(client) then return end
    if self.SaveCharacterAmmo then
        local ammoTable = {}
        for _, ammoType in pairs(game.GetAmmoTypes()) do
            if ammoType and ammoType then
                local ammoCount = client:GetAmmoCount(ammoType)
                if isnumber(ammoCount) and ammoCount > 0 then ammoTable[ammoType] = ammoCount end
            end
        end

        character:setData("ammo", ammoTable)
    end
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function MODULE:PlayerLoadedChar(client)
    local character = client:getChar()
    local ammoTable = character:getData("ammo", {})
    if not self.SaveCharacterAmmo or table.IsEmpty(ammoTable) then return end
    timer.Simple(0.25, function()
        for ammoType, ammoCount in pairs(ammoTable) do
            client:GiveAmmo(ammoCount, ammoType, true)
        end

        character:setData("ammo", nil)
    end)
end

---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------
function MODULE:PlayerDeath(client, _, _)
    if not client:getChar() then return end
    local char = client:getChar()
    local inventory = char:getInv()
    local items = inventory:getItems()
    if inventory and not self.KeepAmmoOnDeath then
        for _, v in pairs(items) do
            if (v.isWeapon or v.isCW) and v:getData("equip") then v:setData("ammo", nil) end
        end
    end
end
---------------------------------------------------------------------------[[//////////////////]]---------------------------------------------------------------------------

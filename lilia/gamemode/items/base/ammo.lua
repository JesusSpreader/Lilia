﻿ITEM.name = "Ammo Base"
ITEM.model = "models/Items/BoxSRounds.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.isStackable = true
ITEM.maxQuantity = 45
ITEM.ammo = "pistol"
ITEM.desc = "A Box that contains %s of Pistol Ammo"
ITEM.category = "Ammunition"
ITEM.RequiredSkillLevels = nil
ITEM.functions.use = {
    name = "load",
    tip = "useTip",
    icon = "icon16/add.png",
    isMulti = true,
    multiOptions = function(item)
        local options = {}
        table.insert(options, {
            name = L("ammoLoadAll"),
            data = 0,
        })

        for _, amount in pairs({5, 10, 30, 45, 90, 150, 300}) do
            if amount <= item:getQuantity() then
                table.insert(options, {
                    name = L("ammoLoadAmount", amount),
                    data = amount,
                })
            end
        end

        table.insert(options, {
            name = L("ammoLoadCustom"),
            data = -1,
        })
        return options
    end,
    onClick = function(_, data) if data == -1 then return false end end,
    onRun = function(item, data)
        data = data or 0
        if data > 0 then
            local num = tonumber(data)
            item:addQuantity(-num)
            item.player:GiveAmmo(num, item.ammo)
            item.player:EmitSound(item.useSound or "items/ammo_pickup.wav", 110)
        elseif data == 0 then
            item.player:GiveAmmo(item:getQuantity(), item.ammo)
            item.player:EmitSound(item.useSound or "items/ammo_pickup.wav", 110)
            return true
        end
        return item:getQuantity() <= 0
    end,
}

function ITEM:getDesc()
    return Format(self.ammoDesc or self.desc, self:getQuantity())
end

function ITEM:paintOver(item)
    local quantity = item:getQuantity()
    lia.util.drawText(quantity, 8, 5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, "liaChatFont")
end

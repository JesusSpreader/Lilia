﻿local MODULE = MODULE
lia.command.add("spawnadd", {
    privilege = "Manage Spawns",
    adminOnly = true,
    desc = "spawnAddDesc",
    syntax = "[faction Faction]",
    onRun = function(client, arguments)
        local factionName = arguments[1]
        if not factionName then return L("invalidArg") end
        local factionInfo = lia.faction.indices[factionName:lower()]
        if not factionInfo then
            for _, v in ipairs(lia.faction.indices) do
                if lia.util.stringMatches(v.uniqueID, factionName) or lia.util.stringMatches(L(v.name), factionName) then
                    factionInfo = v
                    break
                end
            end
        end

        if factionInfo then
            MODULE:FetchSpawns():next(function(spawns)
                spawns[factionInfo.uniqueID] = spawns[factionInfo.uniqueID] or {}
                table.insert(spawns[factionInfo.uniqueID], {
                    pos = client:GetPos(),
                    ang = client:EyeAngles()
                })
                MODULE:StoreSpawns(spawns)
                lia.log.add(client, "spawnAdd", factionInfo.name)
                client:notifyLocalized("spawnAdded", L(factionInfo.name))
            end)
        else
            client:notifyLocalized("invalidFaction")
        end
    end
})

lia.command.add("spawnremoveinradius", {
    privilege = "Manage Spawns",
    adminOnly = true,
    desc = "spawnRemoveInRadiusDesc",
    syntax = "[number Radius optional]",
    onRun = function(client, arguments)
        local position = client:GetPos()
        local radius = tonumber(arguments[1]) or 120
        MODULE:FetchSpawns():next(function(spawns)
            local removedCount = 0
            for faction, list in pairs(spawns) do
                for i = #list, 1, -1 do
                    local spawn = list[i].pos or list[i]
                    if not isvector(spawn) then
                        spawn = lia.data.decodeVector(spawn)
                    end
                    if isvector(spawn) and spawn:Distance(position) <= radius then
                        table.remove(list, i)
                        removedCount = removedCount + 1
                    end
                end
                if #list == 0 then spawns[faction] = nil end
            end

            if removedCount > 0 then MODULE:StoreSpawns(spawns) end
            lia.log.add(client, "spawnRemoveRadius", radius, removedCount)
            client:notifyLocalized("spawnDeleted", removedCount)
        end)
    end
})

lia.command.add("spawnremovebyname", {
    privilege = "Manage Spawns",
    adminOnly = true,
    desc = "spawnRemoveByNameDesc",
    syntax = "[faction Faction]",
    onRun = function(client, arguments)
        local factionName = arguments[1]
        local factionInfo = lia.faction.indices[factionName:lower()]
        if not factionInfo then
            for _, v in ipairs(lia.faction.indices) do
                if lia.util.stringMatches(v.uniqueID, factionName) or lia.util.stringMatches(L(v.name), factionName) then
                    factionInfo = v
                    break
                end
            end
        end

        if factionInfo then
            MODULE:FetchSpawns():next(function(spawns)
                if spawns[factionInfo.uniqueID] then
                    local removedCount = #spawns[factionInfo.uniqueID]
                    spawns[factionInfo.uniqueID] = nil
                    MODULE:StoreSpawns(spawns)
                    lia.log.add(client, "spawnRemoveByName", factionInfo.name, removedCount)
                    client:notifyLocalized("spawnDeletedByName", L(factionInfo.name), removedCount)
                else
                    client:notifyLocalized("noSpawnsForFaction")
                end
            end)
        else
            client:notifyLocalized("invalidFaction")
        end
    end
})

lia.command.add("returnitems", {
    superAdminOnly = true,
    privilege = "Return Items",
    desc = "returnItemsDesc",
    syntax = "[player Name]",
    AdminStick = {
        Name = "returnItemsName",
        Category = "characterManagement",
        SubCategory = "items",
        Icon = "icon16/arrow_refresh.png"
    },
    onRun = function(client, arguments)
        local target = lia.util.findPlayer(client, arguments[1])
        if not target or not IsValid(target) then
            client:notifyLocalized("targetNotFound")
            return
        end

        if lia.config.get("LoseItemsonDeathHuman", false) or lia.config.get("LoseItemsonDeathNPC", false) then
            if not target.LostItems or table.IsEmpty(target.LostItems) then
                client:notifyLocalized("returnItemsTargetNoItems")
                return
            end

            local character = target:getChar()
            if not character then return end
            local inv = character:getInv()
            if not inv then return end
            for _, item in pairs(target.LostItems) do
                inv:add(item)
            end

            target.LostItems = nil
            target:notifyLocalized("returnItemsReturnedToPlayer")
            client:notifyLocalized("returnItemsAdminConfirmed")
            lia.log.add(client, "returnItems", target:Name())
        else
            client:notifyLocalized("returnItemsNotEnabled")
        end
    end
})

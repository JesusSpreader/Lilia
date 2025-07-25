﻿function MODULE:isSuitableForTrunk(entity)
    return IsValid(entity) and entity:IsVehicle()
end

function MODULE:InitializeStorage(entity)
    if not IsValid(entity) then return end
    local existingID = entity:getNetVar("inv")
    if existingID then
        local d = deferred.new()
        d:resolve(lia.inventory.instances[existingID])
        return d
    end

    if entity.liaStorageInitPromise then return entity.liaStorageInitPromise end
    local model = entity:GetModel()
    if not model then return end
    local key = entity:IsVehicle() and "vehicle" or model:lower()
    local def = self.StorageDefinitions[key]
    if not def then return end
    self.Vehicles[entity] = true
    if SERVER then
        entity.receivers = {}
        entity.liaStorageInitPromise = lia.inventory.instance(def.invType, def.invData):next(function(inv)
            inv.isStorage = true
            entity:setNetVar("inv", inv:getID())
            hook.Run("StorageInventorySet", self, inv, entity:IsVehicle())
            return inv
        end)
        return entity.liaStorageInitPromise
    end
end

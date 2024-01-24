﻿ModulesLoaded = false
DeriveGamemode("sandbox")
GM.Name = "Lilia"
GM.Author = "Leonheart"
GM.Website = "https://discord.gg/jjrhyeuzYV"
function GM:Initialize()
    hook.Run("LoadLiliaFonts", "Arial", "Segoe UI")
    lia.module.initialize()
end

function GM:OnReloaded()
    if not ModulesLoaded then
        lia.module.initialize()
        ModulesLoaded = true
    end

    lia.faction.formatModelData()
    hook.Run("LoadLiliaFonts", lia.config.Font, lia.config.GenericFont)
end

if game.IsDedicated() then
    concommand.Remove("gm_save")
    concommand.Add("gm_save", function() end)
end
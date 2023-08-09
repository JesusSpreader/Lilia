--------------------------------------------------------------------------------------------------------
function GM:OnContextMenuOpen()
    self.BaseClass:OnContextMenuOpen()
    vgui.Create("liaQuick")
end
--------------------------------------------------------------------------------------------------------
function GM:OnContextMenuClose()
    self.BaseClass:OnContextMenuClose()

    if IsValid(lia.gui.quick) then
        lia.gui.quick:Remove()
    end
end
--------------------------------------------------------------------------------------------------------
function GM:NetworkEntityCreated(entity)
    if entity == LocalPlayer() then return end
    if not entity:IsPlayer() then return end
    hook.Run("PlayerModelChanged", entity, entity:GetModel())
end

--------------------------------------------------------------------------------------------------------
function GM:CharacterListLoaded()
    timer.Create(
        "liaWaitUntilPlayerValid",
        0.5,
        0,
        function()
            if not IsValid(LocalPlayer()) then return end
            timer.Remove("liaWaitUntilPlayerValid")
            if IsValid(lia.gui.loading) then lia.gui.loading:Remove() end
            RunConsoleCommand("stopsound")
            hook.Run("LiliaLoaded")
        end
    )
end



--------------------------------------------------------------------------------------------------------
function GM:CalcView(client, origin, angles, fov)
    local view = self.BaseClass:CalcView(client, origin, angles, fov)
    local entity = Entity(client:getLocalVar("ragdoll", 0))
    local ragdoll = client:GetRagdollEntity()
    if client:GetViewEntity() ~= client then return view end
    if (not client:ShouldDrawLocalPlayer() and IsValid(entity) and entity:IsRagdoll()) or (not LocalPlayer():Alive() and IsValid(ragdoll)) then
        local ent = LocalPlayer():Alive() and entity or ragdoll
        local index = ent:LookupAttachment("eyes")
        if index then
            local data = ent:GetAttachment(index)
            if data then
                view = view or {}
                view.origin = data.Pos
                view.angles = data.Ang
            end
            return view
        end
    end
    return view
end

--------------------------------------------------------------------------------------------------------
local blurGoal = 0
local blurValue = 0
local mathApproach = math.Approach
function GM:HUDPaintBackground()
    local localPlayer = LocalPlayer()
    local frameTime = FrameTime()
    local scrW, scrH = ScrW(), ScrH()
    blurGoal = localPlayer:getLocalVar("blur", 0) + (hook.Run("AdjustBlurAmount", blurGoal) or 0)
    if blurValue ~= blurGoal then blurValue = mathApproach(blurValue, blurGoal, frameTime * 20) end
    if blurValue > 0 and not localPlayer:ShouldDrawLocalPlayer() then lia.util.drawBlurAt(0, 0, scrW, scrH, blurValue) end
    self.BaseClass.PaintWorldTips(self.BaseClass)
    lia.menu.drawAll()
end

--------------------------------------------------------------------------------------------------------
function GM:ShouldDrawEntityInfo(entity)
    if entity:IsPlayer() or IsValid(entity:getNetVar("player")) then return entity == LocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer() end
    return false
end

--------------------------------------------------------------------------------------------------------
function GM:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()
    if (bind:find("use") or bind:find("attack")) and pressed then
        local menu, callback = lia.menu.getActiveMenu()
        if menu and lia.menu.onButtonPressed(menu, callback) then
            return true
        elseif bind:find("use") and pressed then
            local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 96
            data.filter = client
            local trace = util.TraceLine(data)
            local entity = trace.Entity
            if IsValid(entity) and (entity:GetClass() == "lia_item" or entity.hasMenu == true) then hook.Run("ItemShowEntityMenu", entity) end
        end
    elseif bind:find("jump") then
        lia.command.send("chargetup")
    end
    if lia.config.AntiBunnyHopEnabled then
        if client:GetMoveType() == MOVETYPE_NOCLIP or not client:getChar() or client:InVehicle() then return end
        bind = bind:lower()
        if bind:find("jump") and (client:getLocalVar("stamina", 0) < lia.config.BHOPStamina) then return true end
    end
end

--------------------------------------------------------------------------------------------------------
function GM:ItemShowEntityMenu(entity)
    for k, v in ipairs(lia.menu.list) do
        if v.entity == entity then table.remove(lia.menu.list, k) end
    end

    local options = {}
    local itemTable = entity:getItemTable()
    if not itemTable then return end
    local function callback(index)
        if IsValid(entity) then netstream.Start("invAct", index, entity) end
    end

    itemTable.player = LocalPlayer()
    itemTable.entity = entity
    if input.IsShiftDown() then callback("take") end
    for k, v in SortedPairs(itemTable.functions) do
        if k == "combine" then continue end
        if (hook.Run("onCanRunItemAction", itemTable, k) == false or isfunction(v.onCanRun)) and (not v.onCanRun(itemTable)) then continue end
        options[L(v.name or k)] = function()
            local send = true
            if v.onClick then send = v.onClick(itemTable) end
            if v.sound then surface.PlaySound(v.sound) end
            if send ~= false then callback(k) end
        end
    end

    if table.Count(options) > 0 then entity.liaMenuIndex = lia.menu.add(options, entity) end
    itemTable.player = nil
    itemTable.entity = nil
end

--------------------------------------------------------------------------------------------------------
function GM:SetupQuickMenu(menu)
    menu:addCheck(
        L"cheapBlur",
        function(panel, state)
            if state then
                RunConsoleCommand("lia_cheapblur", "1")
            else
                RunConsoleCommand("lia_cheapblur", "0")
            end
        end,
        CreateClientConVar("lia_cheapblur", 0, true):GetBool()
    )

    menu:addSpacer()
    local current
    LIA_CVAR_LANG = CreateClientConVar("lia_language", lia.config.Language or "english", true, true)
    for k, v in SortedPairs(lia.lang.stored) do
        local name = lia.lang.names[k]
        local name2 = k:sub(1, 1):upper() .. k:sub(2)
        local enabled = LIA_CVAR_LANG:GetString():match(k)
        if name then
            name = name .. " (" .. name2 .. ")"
        else
            name = name2
        end

        local button = menu:addCheck(
            name,
            function(panel)
                panel.checked = true
                if IsValid(current) then
                    if current == panel then return end
                    current.checked = false
                end

                current = panel
                RunConsoleCommand("lia_language", k)
            end,
            enabled
        )

        if enabled and not IsValid(current) then current = button end
    end
end

--------------------------------------------------------------------------------------------------------
function GM:DrawLiliaModelView(panel, ent)
    if IsValid(ent.weapon) then ent.weapon:DrawModel() end
end

--------------------------------------------------------------------------------------------------------
function GM:ScreenResolutionChanged(oldW, oldH)
    RunConsoleCommand("fixchatplz")
    hook.Run("LoadLiliaFonts", lia.config.Font, lia.config.GenericFont)
end


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------

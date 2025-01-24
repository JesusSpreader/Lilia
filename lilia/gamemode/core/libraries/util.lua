﻿function lia.util.FindPlayersInBox(mins, maxs)
    local entsList = ents.FindInBox(mins, maxs)
    local plyList = {}
    for _, v in pairs(entsList) do
        if IsValid(v) and v:IsPlayer() then plyList[#plyList + 1] = v end
    end
    return plyList
end

function lia.util.FindPlayersInSphere(origin, radius)
    local plys = {}
    local r2 = radius ^ 2
    for _, client in player.Iterator() do
        if client:GetPos():DistToSqr(origin) <= r2 then plys[#plys + 1] = client end
    end
    return plys
end

function lia.util.findPlayer(identifier, allowPatterns)
    if string.match(identifier, "STEAM_(%d+):(%d+):(%d+)") then return player.GetBySteamID(identifier) end
    if not allowPatterns then identifier = string.PatternSafe(identifier) end
    for _, v in player.Iterator() do
        if lia.util.stringMatches(v:Name(), identifier) then return v end
    end
end

function lia.util.findPlayerItems(client)
    local items = {}
    for _, item in ents.Iterator() do
        if IsValid(item) and item:isItem() and item:GetCreator() == client then table.insert(items, item) end
    end
    return items
end

function lia.util.findPlayerItemsByClass(client, class)
    local items = {}
    for _, item in ents.Iterator() do
        if IsValid(item) and item:isItem() and item:GetCreator() == client and item:getNetVar("id") == class then table.insert(items, item) end
    end
    return items
end

function lia.util.findPlayerEntities(client, class)
    local entities = {}
    for _, entity in ents.Iterator() do
        if IsValid(entity) and (not class or entity:GetClass() == class) and (entity:GetCreator() == client or (entity.client and entity.client == client)) then table.insert(entities, entity) end
    end
    return entities
end

function lia.util.stringMatches(a, b)
    if a and b then
        local a2, b2 = a:lower(), b:lower()
        if a == b then return true end
        if a2 == b2 then return true end
        if a:find(b) then return true end
        if a2:find(b2) then return true end
    end
    return false
end

function lia.util.getAdmins()
    local staff = {}
    for _, client in player.Iterator() do
        local hasPermission = client:isStaff()
        if hasPermission then staff[#staff + 1] = client end
    end
    return staff
end

function lia.util.findPlayerBySteamID64(SteamID64)
    for _, client in player.Iterator() do
        if client:SteamID64() == SteamID64 then return client end
    end
    return nil
end

function lia.util.findPlayerBySteamID(SteamID)
    for _, client in player.Iterator() do
        if client:SteamID() == SteamID then return client end
    end
    return nil
end

function lia.util.canFit(pos, mins, maxs, filter)
    mins = mins ~= nil and mins or Vector(16, 16, 0)
    local tr = util.TraceHull({
        start = pos + Vector(0, 0, 1),
        mask = MASK_PLAYERSOLID,
        filter = filter,
        endpos = pos,
        mins = mins.x > 0 and mins * -1 or mins,
        maxs = maxs ~= nil and maxs or mins
    })
    return not tr.Hit
end

function lia.util.playerInRadius(pos, dist)
    dist = dist * dist
    local t = {}
    for _, client in player.Iterator() do
        if IsValid(client) and client:GetPos():DistToSqr(pos) < dist then t[#t + 1] = client end
    end
    return t
end

function lia.util.formatStringNamed(format, ...)
    local arguments = {...}
    local bArray = false
    local input
    if istable(arguments[1]) then
        input = arguments[1]
    else
        input = arguments
        bArray = true
    end

    local i = 0
    local result = format:gsub("{(%w-)}", function(word)
        i = i + 1
        return tostring(bArray and input[i] or input[word] or word)
    end)
    return result
end

function lia.util.getMaterial(materialPath, materialParameters)
    lia.util.cachedMaterials = lia.util.cachedMaterials or {}
    lia.util.cachedMaterials[materialPath] = lia.util.cachedMaterials[materialPath] or Material(materialPath, materialParameters)
    return lia.util.cachedMaterials[materialPath]
end

if SERVER then
    function lia.util.CreateTableUI(client, title, columns, data, options, characterID)
        if not IsValid(client) or not client:IsPlayer() then return end
        local tableData = util.Compress(util.TableToJSON({
            title = title or "Table List",
            columns = columns,
            data = data,
            options = options or {},
            characterID = characterID
        }))

        if not tableData then return end
        net.Start("CreateTableUI")
        net.WriteUInt(#tableData, 32)
        net.WriteData(tableData, #tableData)
        net.Send(client)
    end

    function lia.util.findEmptySpace(entity, filter, spacing, size, height, tolerance)
        spacing = spacing or 32
        size = size or 3
        height = height or 36
        tolerance = tolerance or 5
        local position = entity:GetPos()
        local mins = Vector(-spacing * 0.5, -spacing * 0.5, 0)
        local maxs = Vector(spacing * 0.5, spacing * 0.5, height)
        local output = {}
        for x = -size, size do
            for y = -size, size do
                local origin = position + Vector(x * spacing, y * spacing, 0)
                local data = {}
                data.start = origin + mins + Vector(0, 0, tolerance)
                data.endpos = origin + maxs
                data.filter = filter or entity
                local trace = util.TraceLine(data)
                data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
                data.endpos = origin + Vector(mins.x, mins.y, height)
                local trace2 = util.TraceLine(data)
                if trace.StartSolid or trace.Hit or trace2.StartSolid or trace2.Hit or not util.IsInWorld(origin) then continue end
                output[#output + 1] = origin
            end
        end

        table.sort(output, function(a, b) return a:Distance(position) < b:Distance(position) end)
        return output
    end
else
    function lia.util.ShadowText(text, font, x, y, colortext, colorshadow, dist, xalign, yalign)
        surface.SetFont(font)
        local _, h = surface.GetTextSize(text)
        if yalign == TEXT_ALIGN_CENTER then
            y = y - h / 2
        elseif yalign == TEXT_ALIGN_BOTTOM then
            y = y - h
        end

        draw.DrawText(text, font, x + dist, y + dist, colorshadow, xalign)
        draw.DrawText(text, font, x, y, colortext, xalign)
    end

    function lia.util.DrawTextOutlined(text, font, x, y, colour, xalign, outlinewidth, outlinecolour)
        local steps = (outlinewidth * 2) / 3
        if steps < 1 then steps = 1 end
        for _x = -outlinewidth, outlinewidth, steps do
            for _y = -outlinewidth, outlinewidth, steps do
                draw.DrawText(text, font, x + _x, y + _y, outlinecolour, xalign)
            end
        end
        return draw.DrawText(text, font, x, y, colour, xalign)
    end

    function lia.util.DrawTip(x, y, w, h, text, font, textCol, outlineCol)
        draw.NoTexture()
        local rectH = 0.85
        local triW = 0.1
        local verts = {
            {
                x = x,
                y = y
            },
            {
                x = x + w,
                y = y
            },
            {
                x = x + w,
                y = y + h * rectH
            },
            {
                x = x + w / 2 + w * triW,
                y = y + h * rectH
            },
            {
                x = x + w / 2,
                y = y + h
            },
            {
                x = x + w / 2 - w * triW,
                y = y + h * rectH
            },
            {
                x = x,
                y = y + h * rectH
            }
        }

        surface.SetDrawColor(outlineCol)
        surface.DrawPoly(verts)
        draw.SimpleText(text, font, x + w / 2, y + h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function lia.util.drawText(text, x, y, color, alignX, alignY, font, alpha)
        color = color or color_white
        return draw.TextShadow({
            text = text,
            font = font or "liaGenericFont",
            pos = {x, y},
            color = color,
            xalign = alignX or 0,
            yalign = alignY or 0
        }, 1, alpha or color.a * 0.575)
    end

    function lia.util.drawTexture(material, color, x, y, w, h)
        surface.SetDrawColor(color or color_white)
        surface.SetMaterial(lia.util.getMaterial(material))
        surface.DrawTexturedRect(x, y, w, h)
    end

    function lia.util.skinFunc(name, panel, a, b, c, d, e, f, g)
        local skin = ispanel(panel) and IsValid(panel) and panel:GetSkin() or derma.GetDefaultSkin()
        if not skin then return end
        local func = skin[name]
        if not func then return end
        return func(skin, panel, a, b, c, d, e, f, g)
    end

    function lia.util.wrapText(text, width, font)
        font = font or "liaChatFont"
        surface.SetFont(font)
        local exploded = string.Explode("%s", text, true)
        local line = ""
        local lines = {}
        local w = surface.GetTextSize(text)
        local maxW = 0
        if w <= width then
            text, _ = text:gsub("%s", " ")
            return {text}, w
        end

        for i = 1, #exploded do
            local word = exploded[i]
            line = line .. " " .. word
            w = surface.GetTextSize(line)
            if w > width then
                lines[#lines + 1] = line
                line = ""
                if w > maxW then maxW = w end
            end
        end

        if line ~= "" then lines[#lines + 1] = line end
        return lines, maxW
    end

    function lia.util.drawBlur(panel, amount, passes)
        amount = amount or 5
        surface.SetMaterial(lia.util.getMaterial("pp/blurscreen"))
        surface.SetDrawColor(255, 255, 255)
        local x, y = panel:LocalToScreen(0, 0)
        for i = -(passes or 0.2), 1, 0.2 do
            lia.util.getMaterial("pp/blurscreen"):SetFloat("$blur", i * amount)
            lia.util.getMaterial("pp/blurscreen"):Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        end
    end

    function lia.util.drawBlurAt(x, y, w, h, amount, passes)
        amount = amount or 5
        surface.SetMaterial(lia.util.getMaterial("pp/blurscreen"))
        surface.SetDrawColor(255, 255, 255)
        local scrW, scrH = ScrW(), ScrH()
        local x2, y2 = x / scrW, y / scrH
        local w2, h2 = (x + w) / scrW, (y + h) / scrH
        for i = -(passes or 0.2), 1, 0.2 do
            lia.util.getMaterial("pp/blurscreen"):SetFloat("$blur", i * amount)
            lia.util.getMaterial("pp/blurscreen"):Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRectUV(x, y, w, h, x2, y2, w2, h2)
        end
    end

    function lia.util.notifQuery(question, option1, option2, manualDismiss, notifType, callback)
        if not callback or not isfunction(callback) then Error("A callback function must be specified") end
        if not question or not isstring(question) then Error("A question string must be specified") end
        if not option1 then option1 = "Yes" end
        if not option2 then option2 = "No" end
        if not manualDismiss then manualDismiss = false end
        local notice = CreateNoticePanel(10, manualDismiss)
        local i = table.insert(lia.notices, notice)
        notice.isQuery = true
        notice.text:SetText(question)
        notice:SetPos(0, (i - 1) * (notice:GetTall() + 4) + 4)
        notice:SetTall(36 * 2.3)
        notice:CalcWidth(120)
        notice:CenterHorizontal()
        notice.notifType = notifType or 7
        if manualDismiss then notice.start = nil end
        notice.opt1 = notice:Add("DButton")
        notice.opt1:SetAlpha(0)
        notice.opt2 = notice:Add("DButton")
        notice.opt2:SetAlpha(0)
        notice.oh = notice:GetTall()
        OrganizeNotices(false)
        notice:SetTall(0)
        notice:SizeTo(notice:GetWide(), 36 * 2.3, 0.2, 0, -1, function()
            notice.text:SetPos(0, 0)
            local function styleOpt(o)
                o.color = Color(0, 0, 0, 30)
                AccessorFunc(o, "color", "Color")
                function o:Paint(w, h)
                    if self.left then
                        draw.RoundedBoxEx(4, 0, 0, w + 2, h, self.color, false, false, true, false)
                    else
                        draw.RoundedBoxEx(4, 0, 0, w + 2, h, self.color, false, false, false, true)
                    end
                end
            end

            if notice.opt1 and IsValid(notice.opt1) then
                notice.opt1:SetAlpha(255)
                notice.opt1:SetSize(notice:GetWide() / 2, 25)
                notice.opt1:SetText(option1 .. " (F8)")
                notice.opt1:SetPos(0, notice:GetTall() - notice.opt1:GetTall())
                notice.opt1:CenterHorizontal(0.25)
                notice.opt1:SetAlpha(0)
                notice.opt1:AlphaTo(255, 0.2)
                notice.opt1:SetTextColor(color_white)
                notice.opt1.left = true
                styleOpt(notice.opt1)
                function notice.opt1:keyThink()
                    if input.IsKeyDown(KEY_F8) and CurTime() - notice.lastKey >= 0.5 then
                        self:ColorTo(Color(24, 215, 37), 0.2, 0)
                        notice.respondToKeys = false
                        callback(1, notice)
                        timer.Simple(1, function() if notice and IsValid(notice) then RemoveNotices(notice) end end)
                        notice.lastKey = CurTime()
                    end
                end
            end

            if notice.opt2 and IsValid(notice.opt2) then
                notice.opt2:SetAlpha(255)
                notice.opt2:SetSize(notice:GetWide() / 2, 25)
                notice.opt2:SetText(option2 .. " (F9)")
                notice.opt2:SetPos(0, notice:GetTall() - notice.opt2:GetTall())
                notice.opt2:CenterHorizontal(0.75)
                notice.opt2:SetAlpha(0)
                notice.opt2:AlphaTo(255, 0.2)
                notice.opt2:SetTextColor(color_white)
                styleOpt(notice.opt2)
                function notice.opt2:keyThink()
                    if input.IsKeyDown(KEY_F9) and CurTime() - notice.lastKey >= 0.5 then
                        self:ColorTo(Color(24, 215, 37), 0.2, 0)
                        notice.respondToKeys = false
                        callback(2, notice)
                        timer.Simple(1, function() if notice and IsValid(notice) then RemoveNotices(notice) end end)
                        notice.lastKey = CurTime()
                    end
                end
            end

            notice.lastKey = CurTime()
            notice.respondToKeys = true
            function notice:Think()
                if not self.respondToKeys then return end
                local queries = {}
                for _, v in pairs(lia.notices) do
                    if v.isQuery then queries[#queries + 1] = v end
                end

                for k, v in pairs(queries) do
                    if v == self and k > 1 then return end
                end

                if self.opt1 and IsValid(self.opt1) then self.opt1:keyThink() end
                if self.opt2 and IsValid(self.opt2) then self.opt2:keyThink() end
            end
        end)
        return notice
    end

    function lia.util.CreateTableUI(title, columns, data, options, charID)
        local screenW, screenH = ScrW(), ScrH()
        local frameWidth, frameHeight = screenW * 0.8, screenH * 0.8
        local frame = vgui.Create("DFrame")
        frame:SetTitle(title or "Table List")
        frame:SetSize(frameWidth, frameHeight)
        frame:Center()
        frame:MakePopup()
        local listView = vgui.Create("DListView", frame)
        listView:Dock(FILL)
        local totalFixedWidth = 0
        local dynamicColumns = 0
        for _, colInfo in ipairs(columns) do
            if colInfo.width then
                totalFixedWidth = totalFixedWidth + colInfo.width
            else
                dynamicColumns = dynamicColumns + 1
            end
        end

        local availableWidth = frame:GetWide() - totalFixedWidth
        local dynamicWidth = dynamicColumns > 0 and math.max(availableWidth / dynamicColumns, 50) or 0
        for _, colInfo in ipairs(columns) do
            local columnName = colInfo.name or "N/A"
            local columnWidth = colInfo.width or dynamicWidth
            listView:AddColumn(columnName):SetFixedWidth(columnWidth)
        end

        for _, row in ipairs(data) do
            local lineData = {}
            for _, colInfo in ipairs(columns) do
                local fieldName = colInfo.field or "N/A"
                table.insert(lineData, row[fieldName] or "N/A")
            end

            local line = listView:AddLine(unpack(lineData))
            line.rowData = row
        end

        listView.OnRowRightClick = function(_, _, line)
            if not IsValid(line) or not line.rowData then return end
            local rowData = line.rowData
            local menu = DermaMenu()
            menu:AddOption("Copy Row", function()
                local rowString = ""
                for key, value in pairs(rowData) do
                    value = tostring(value or "N/A")
                    rowString = rowString .. key:gsub("^%l", string.upper) .. " " .. value .. " | "
                end

                rowString = rowString:sub(1, -4)
                SetClipboardText(rowString)
            end)

            for _, option in ipairs(options or {}) do
                menu:AddOption(option.name, function()
                    if not option.net then return end
                    if option.ExtraFields then
                        local inputPanel = vgui.Create("DFrame")
                        inputPanel:SetTitle(option.name .. " Options")
                        inputPanel:SetSize(300, 300 + #table.GetKeys(option.ExtraFields) * 35)
                        inputPanel:Center()
                        inputPanel:MakePopup()
                        local form = vgui.Create("DForm", inputPanel)
                        form:Dock(FILL)
                        form:SetName("")
                        form.Paint = function() end
                        local inputs = {}
                        for fName, fType in pairs(option.ExtraFields) do
                            local label = vgui.Create("DLabel", form)
                            label:SetText(fName)
                            label:Dock(TOP)
                            label:DockMargin(5, 10, 5, 0)
                            form:AddItem(label)
                            if isstring(fType) and fType == "text" then
                                local entry = vgui.Create("DTextEntry", form)
                                entry:Dock(TOP)
                                entry:DockMargin(5, 5, 5, 0)
                                entry:SetPlaceholderText("Type " .. fName)
                                form:AddItem(entry)
                                inputs[fName] = {
                                    panel = entry,
                                    ftype = "text"
                                }
                            elseif isstring(fType) and fType == "combo" then
                                local combo = vgui.Create("DComboBox", form)
                                combo:Dock(TOP)
                                combo:DockMargin(5, 5, 5, 0)
                                combo:SetValue("Select " .. fName)
                                form:AddItem(combo)
                                inputs[fName] = {
                                    panel = combo,
                                    ftype = "combo"
                                }
                            elseif istable(fType) then
                                local combo = vgui.Create("DComboBox", form)
                                combo:Dock(TOP)
                                combo:DockMargin(5, 5, 5, 0)
                                combo:SetValue("Select " .. fName)
                                for _, choice in ipairs(fType) do
                                    combo:AddChoice(choice)
                                end

                                form:AddItem(combo)
                                inputs[fName] = {
                                    panel = combo,
                                    ftype = "combo"
                                }
                            end
                        end

                        local submitButton = vgui.Create("DButton", form)
                        submitButton:SetText("Submit")
                        submitButton:Dock(TOP)
                        submitButton:DockMargin(5, 10, 5, 0)
                        form:AddItem(submitButton)
                        submitButton.DoClick = function()
                            local values = {}
                            for fName, info in pairs(inputs) do
                                if not IsValid(info.panel) then continue end
                                if info.ftype == "text" then
                                    values[fName] = info.panel:GetValue() or ""
                                elseif info.ftype == "combo" then
                                    values[fName] = info.panel:GetSelected() or ""
                                end
                            end

                            net.Start(option.net)
                            net.WriteInt(charID, 32)
                            net.WriteTable(rowData)
                            for _, fVal in pairs(values) do
                                if isnumber(fVal) then
                                    net.WriteInt(fVal, 32)
                                else
                                    net.WriteString(fVal)
                                end
                            end

                            net.SendToServer()
                            inputPanel:Close()
                            frame:Remove()
                        end
                    else
                        net.Start(option.net)
                        net.WriteInt(charID, 32)
                        net.WriteTable(rowData)
                        net.SendToServer()
                        frame:Remove()
                    end
                end)
            end

            menu:Open()
        end
    end
end
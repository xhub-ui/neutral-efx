-- helpers.lua
-- Game data helpers for Fish It

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local EnchantModule = ReplicatedStorage.Enchants
local BaitModule = ReplicatedStorage.Baits
local ItemsModule = ReplicatedStorage.Items
local WeatherModule = ReplicatedStorage.Events
local TiersModule = ReplicatedStorage.Tiers
local Replion = require(ReplicatedStorage.Packages.Replion)
local QuestUtility = require(ReplicatedStorage.Shared.Quests.QuestUtility)
local QuestList = require(ReplicatedStorage.Shared.Quests.QuestList)

local Helpers = {}

--- Enchant Names
function Helpers.getEnchantName()
    local names = {}
    for _, ms in ipairs(EnchantModule:GetChildren()) do
        if ms:IsA("ModuleScript") then
            local ok, mod = pcall(require, ms)
            if ok and type(mod)=="table" and mod.Data then
                local id   = tonumber(mod.Data.Id)
                local name = tostring(mod.Data.Name or ms.Name)
                if id and name then
                    table.insert(names, name)
                end
            end
        end
    end
    table.sort(names)
    return names
end

--- Bait Names
function Helpers.getBaitNames()
    local baitName = {}
    for _, item in pairs(BaitModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Baits" and moduleData.Price then
                table.insert(baitName, item.Name)
            end
        end
    end
    return baitName
end

--- Fishing Rod Names
function Helpers.getFishingRodNames()
    local rodNames = {}
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data then
                if moduleData.Data.Type == "Fishing Rods" and moduleData.Price and moduleData.Data.Name then
                    table.insert(rodNames, moduleData.Data.Name)
                end
            end
        end
    end
    table.sort(rodNames)
    return rodNames
end

--- Weather Names (Buyable)
function Helpers.getWeatherNames()
    local weatherName = {}
    for _, weather in pairs(WeatherModule:GetChildren()) do
        if weather:IsA("ModuleScript") then
            local success, moduleData = pcall(require, weather)
            if success and moduleData and moduleData.WeatherMachine == true and moduleData.WeatherMachinePrice then
                table.insert(weatherName, weather.Name)
            end
        end
    end
    table.sort(weatherName)
    return weatherName
end

--- Event Names
function Helpers.getEventNames()
    local eventNames = {}
    for _, event in pairs(WeatherModule:GetChildren()) do
        if event:IsA("ModuleScript") then
            local success, moduleData = pcall(require, event)
            if success and moduleData and moduleData.Coordinates and moduleData.Name then
                table.insert(eventNames, moduleData.Name)
            end
        end
    end
    table.sort(eventNames)
    return eventNames
end

--- Tier Names (Rarity)
function Helpers.getTierNames()
    local tierNames = {}
    local success, tiersData = pcall(require, TiersModule)
    if success and tiersData then
        for _, tierInfo in pairs(tiersData) do
            if tierInfo.Name then
                table.insert(tierNames, tierInfo.Name)
            end
        end
    end
    return tierNames
end

--- Fish Names
function Helpers.getFishNames()
    local fishNames = {}
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Fishes" and moduleData.Data.Name then
                table.insert(fishNames, moduleData.Data.Name)
            end
        end
    end
    table.sort(fishNames)
    return fishNames
end

--- Fish Names for Trade
function Helpers.getFishNamesForTrade()
    local fishNames = {}
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Fishes" and moduleData.Data.Name then
                table.insert(fishNames, moduleData.Data.Name)
            end
        end
    end
    table.sort(fishNames)
    return fishNames
end

--- Enchant Stones for Trade
function Helpers.getEnchantStonesForTrade()
    local enchantStoneNames = {}
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "EnchantStones" and moduleData.Data.Name then
                table.insert(enchantStoneNames, moduleData.Data.Name)
            end
        end
    end
    table.sort(enchantStoneNames)
    return enchantStoneNames
end

--- Player List
function Helpers.listPlayers(excludeSelf)
    local me = LocalPlayer and LocalPlayer.Name
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if not excludeSelf or (me and p.Name ~= me) then
            table.insert(t, p.Name)
        end
    end
    table.sort(t, function(a, b) return a:lower() < b:lower() end)
    return t
end

--- Normalize dropdown option
function Helpers.normalizeOption(opt)
    if type(opt) == "string" then return opt end
    if type(opt) == "table" then
        return opt.Value or opt.value or opt[1] or opt.Selected or opt.selection
    end
    return nil
end

--- Normalize dropdown list
function Helpers.normalizeList(opts)
    local out = {}
    local function push(v)
        if v ~= nil then table.insert(out, tostring(v)) end
    end
    if type(opts) == "string" or type(opts) == "number" then
        push(opts)
    elseif type(opts) == "table" then
        if #opts > 0 then
            for _, v in ipairs(opts) do
                if type(v) == "table" then
                    push(v.Value or v.value or v.Name or v.name or v[1] or v.Selected or v.selection)
                else
                    push(v)
                end
            end
        else
            for k, v in pairs(opts) do
                if type(k) ~= "number" and v then
                    push(k)
                else
                    if type(v) == "table" then
                        push(v.Value or v.value or v.Name or v.name or v[1] or v.Selected or v.selection)
                    else
                        push(v)
                    end
                end
            end
        end
    end
    return out
end

--- Get Rod Price
function Helpers.getRodPrice(rodName)
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data then
                if moduleData.Data.Type == "Fishing Rods" and moduleData.Data.Name == rodName then
                    return moduleData.Price or 0
                end
            end
        end
    end
    return 0
end

--- Get Bait Price
function Helpers.getBaitPrice(baitName)
    for _, item in pairs(BaitModule:GetChildren()) do
        if item:IsA("ModuleScript") and item.Name == baitName then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Baits" then
                return moduleData.Price or 0
            end
        end
    end
    return 0
end

--- Format price with comma
function Helpers.formatPrice(price)
    local formatted = tostring(price)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

--- Calculate total price
function Helpers.calculateTotalPrice(selectedItems, priceFunction)
    local total = 0
    for _, itemName in ipairs(selectedItems) do
        total = total + priceFunction(itemName)
    end
    return total
end

--- Abbreviate number (12.3K, 7.5M, etc)
function Helpers.abbreviateNumber(n, maxDecimals)
    if not n then return "0" end
    maxDecimals = (maxDecimals == nil) and 1 or math.max(0, math.min(2, maxDecimals))
    local neg = n < 0
    n = math.abs(n)

    local units = {
        {1e12, "T"},
        {1e9,  "B"},
        {1e6,  "M"},
        {1e3,  "K"},
    }

    for _, u in ipairs(units) do
        local div, suf = u[1], u[2]
        if n >= div then
            local v = n / div
            local fmt = "%." .. tostring(maxDecimals) .. "f"
            local s = string.format(fmt, v):gsub("%.0+$", ""):gsub("%.(%d-)0+$", ".%1")
            return (neg and "-" or "") .. s .. suf
        end
    end

    local s = string.format("%." .. tostring(maxDecimals) .. "f", n):gsub("%.0+$", ""):gsub("%.(%d-)0+$", ".%1")
    return (neg and "-" or "") .. s
end

--- Get player stats
function Helpers.getCaughtValue()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local caught = leaderstats:FindFirstChild("Caught")
        if caught and caught:IsA("IntValue") then
            return caught.Value
        end
    end
    return 0
end

function Helpers.getRarestValue()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local rarest = leaderstats:FindFirstChild("Rarest Fish")
        if rarest and rarest:IsA("StringValue") then
            return rarest.Value
        end
    end
    return 0
end

--- SECRET Fish Names
function Helpers.getSecretFishNames()
    local secretFishNames = {}
    for _, item in pairs(ItemsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Fishes" and moduleData.Data.Name and moduleData.Data.Tier == 7 then
                table.insert(secretFishNames, moduleData.Data.Name)
            end
        end
    end
    table.sort(secretFishNames)
    return secretFishNames
end

--- Boat Names
function Helpers.getBoatNames()
    local boatNames = {}
    local BoatsModule = ReplicatedStorage:FindFirstChild("Boats")
    if not BoatsModule then return boatNames end
    
    for _, item in pairs(BoatsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Type == "Boats" and moduleData.Data.Name then
                table.insert(boatNames, moduleData.Data.Name)
            end
        end
    end
    table.sort(boatNames)
    return boatNames
end

--- Get Boat ID by Name
function Helpers.getBoatIdByName(boatName)
    local BoatsModule = ReplicatedStorage:FindFirstChild("Boats")
    if not BoatsModule then return nil end
    
    for _, item in pairs(BoatsModule:GetChildren()) do
        if item:IsA("ModuleScript") then
            local success, moduleData = pcall(require, item)
            if success and moduleData and moduleData.Data and moduleData.Data.Name == boatName then
                return moduleData.Data.Id
            end
        end
    end
    return nil
end

--- Get DeepSea Quest Progress
function Helpers.getDeepSeaQuestProgress()
    local playerData = Replion.Client:WaitReplion("Data")
    if not playerData then return "No quest data" end
    
    local questData = playerData:Get({"DeepSea", "Available", "Forever", "Quests"})
    if not questData then return "No DeepSea quests" end
    
    local deepSeaQuests = QuestList.DeepSea.Forever
    local lines = {}
    local completed = 0
    local total = 0
    
    for index, quest in ipairs(questData) do
        local questInfo = deepSeaQuests[quest.QuestId]
        if questInfo then
            total = total + 1
            local required = QuestUtility.GetQuestValue(playerData, questInfo)
            local current = quest.Progress or 0
            local done = current >= required
            
            if done then completed = completed + 1 end
            
            local status = done and "✓" or "○"
            local percentage = math.floor((current / required) * 100)
            
            table.insert(lines, string.format(
                "%s [%d] %s: %.0f/%.0f (%d%%)",
                status, index, questInfo.DisplayName, current, required, percentage
            ))
        end
    end
    
    table.insert(lines, 1, string.format("Progress: %d/%d (%d%%)", completed, total, total > 0 and math.floor((completed/total)*100) or 0))
    table.insert(lines, 2, "")
    
    return table.concat(lines, "\n")
end

return Helpers
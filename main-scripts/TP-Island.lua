-- ===========================
-- AUTO TELEPORT ISLAND FEATURE (STATIC VERSION)
-- Keeps the same API as the original module so it plugs into the main GUI.
-- Uses static CFrame targets (provided below), hard teleport, and Y-offset = 6.
-- If an island isn’t in the static table, it falls back to the old workspace lookup.
-- ===========================

local AutoTeleportIsland = {}
AutoTeleportIsland.__index = AutoTeleportIsland

local logger = _G.Logger and _G.Logger.new("AutoTeleportIsland") or {
    debug = function() end,
    info = function() end,
    warn = function() end,
    error = function() end
}

-- Services
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Feature state
local isInitialized = false
local controls      = {}
local currentIsland = "Fisherman Island"

-- ===== Static CFrame targets (provided) =====
local STATIC_ISLAND_CFRAMES = {
    ["Fisherman Island"] = CFrame.new(33.4889145, 9.78529263, 2808.38818, 0.999970615, 0, 0.00766801229, 0, 1, 0, -0.00766801229, 0, 0.999970615),
    ["Esoteric Depths"]  = CFrame.new(2023.6178, 27.3971195, 1395.06812, 0.385756761, 1.05182835e-07, -0.922600508, -1.02617278e-07, 1, 7.11006791e-08, 0.922600508, 6.72471856e-08, 0.385756761),
    ["Enchant Altar"]    = CFrame.new(3232.21899, -1302.85486, 1400.52661, 0.435549557, -5.62926949e-08, -0.900164723, -1.01161399e-08, 1, -6.74307401e-08, 0.900164723, 3.84756227e-08, 0.435549557),
    ["Kohana"]           = CFrame.new(-641.098267, 16.0354462, 611.625916, 0.999887645, 1.07221638e-07, -0.0149896732, -1.06285079e-07, 1, 6.32765662e-08, 0.0149896732, -6.16762748e-08, 0.999887645),
    ["Kohana Volcano"]   = CFrame.new(-530.639709, 24.0000591, 169.182816, 0.60094595, -1.06010241e-07, 0.799289644, 6.39355164e-08, 1, 8.45606465e-08, -0.799289644, 2.86618757e-10, 0.60094595),
    ["Tropical Grove"]   = CFrame.new(-2096.33252, 6.2707715, 3699.2312, 0.870488882, -2.185838e-08, -0.492188066, 1.7358655e-08, 1, -1.37099292e-08, 0.492188066, 3.39061867e-09, 0.870488882),
    ["Crater Island"]    = CFrame.new(1012.39233, 22.8119335, 5079.95361, 0.224941075, -5.15924121e-08, -0.974372387, -1.26314745e-08, 1, -5.58654492e-08, 0.974372387, 2.48741934e-08, 0.224941075),
    ["Coral Reefs"]      = CFrame.new(-3201.69507, 4.62324762, 2108.83252, 0.961145103, 1.20140157e-07, 0.276043564, -1.19486756e-07, 1, -1.91855563e-08, -0.276043564, -1.45434447e-08, 0.961145103),
    ["Sisyphus Statue"]  = CFrame.new(-3741.66113, -135.074417, -1013.1358, -0.957978785, 1.63582214e-08, -0.286838979, 9.84434312e-09, 1, 2.41513547e-08, 0.286838979, 2.03127435e-08, -0.957978785),
    ["Treasure Room"]    = CFrame.new(-3599.24976, -266.57373, -1580.3894, 0.997320652, 8.38383407e-09, -0.0731537938, -5.83303805e-09, 1, 3.50825857e-08, 0.0731537938, -3.45618787e-08, 0.997320652),
    ["Enchant Temple"]   = CFrame.new(1478.08643, 127.59996, -597.433228, 0.984567702, -2.26607261e-10, 0.17500402, 4.36489067e-10, 1, -1.16080645e-09, -0.17500402, 1.2192799e-09, 0.984567702),
    ["Ancient Jungle"]   = CFrame.new(1280.93726, 7.79084349, -197.774475, -0.930740535, 7.9645629e-10, 0.365680248, 1.70329961e-09, 1, 2.15727725e-09, -0.365680248, 2.6307283e-09, -0.930740535),
    ["Winter Island"]    = CFrame.new(1820.50842, 5.7885952, 3306.21802, -0.320553631, -4.65642032e-08, -0.947230399, 2.44332448e-08, 1, -5.74267567e-08, 0.947230399, -4.15522656e-08, -0.320553631),
    ["Ice Lake"]         = CFrame.new(2155.76392, 4.67548752, 3251.14722, -0.986612737, -1.45733403e-09, 0.163080797, 3.49655138e-10, 1, 1.10516281e-08, -0.163080797, 1.09606981e-08, -0.986612737),
    ["Weather Machine"]  = CFrame.new(-1506.67224, 2.93639493, 1911.50708, -0.993045032, 2.60577231e-08, -0.117734931, 2.1651422e-08, 1, 3.87046271e-08, 0.117734931, 3.5886309e-08, -0.993045032),
   --[["Sacred Temple"]    = CFrame.new(1524.3443603515625, 5.312545299530029, -635.730712890625)
    ["Underground Cellar"] = CFrame.new(2139.254638671875, -91.39814758300781, -765.86126953125)]] -- Placeholder; add actual CFrame if needed
}

-- For fallback lookup (optional; names map to themselves by default)
local ISLAND_MAPPING = {
    ["Fisherman Island"]  = "Fisherman Island",
    ["Kohana"]            = "Kohana",
    ["Kohana Volcano"]    = "Kohana Volcano",
    ["Coral Reefs"]       = "Coral Reefs",
    ["Esoteric Depths"]   = "Esoteric Depths",
    ["Tropical Grove"]    = "Tropical Grove",
    ["Crater Island"]     = "Crater Island",
    ["Lost Isle"]         = "Lost Isle",
    ["Enchant Altar"]     = "Enchant Altar",
    ["Sisyphus Statue"]   = "Sisyphus Statue",
    ["Treasure Room"]     = "Treasure Room",
    ["Enchant Temple"]    = "Enchant Temple",
    ["Ancient Jungle"]    = "Ancient Jungle",
    ["Winter Island"]     = "Winter Island",
    ["Ice Lake"]          = "Ice Lake",
    ["Weather Machine"]   = "Weather Machine",
    --[["Sacred Temple"]     = "Sacred Temple",
    ["Underground Cellar"] = "Underground Cellar"]]
}

-- Resolve destination CFrame:
-- 1) static table (preferred), 2) dynamic fallback in Workspace.
function AutoTeleportIsland:GetIslandCFrame(islandName)
    local cf = STATIC_ISLAND_CFRAMES[islandName]
    if cf then
        return cf
    end

    local islandLocations = Workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
    if not islandLocations then
        logger:warn("Island locations folder not found")
        return nil
    end

    local actualName = ISLAND_MAPPING[islandName] or islandName
    local island = islandLocations:FindFirstChild(actualName)
    if not island then
         logger:warn("Island not found:", actualName)
        return nil
    end

    local transform = island:FindFirstChild("Transform")
    if transform and transform:IsA("CFrameValue") then
        return transform.Value
    end

    local part = island:FindFirstChildOfClass("Part")
    if part then
        return part.CFrame
    end

    if island:IsA("Model") and island.PrimaryPart then
        return island.PrimaryPart.CFrame
    end

     logger:warn("Could not find CFrame for island:", actualName)
    return nil
end

-- Hard teleport with fixed Y-offset = 6.
function AutoTeleportIsland:TeleportToPosition(cframe)
    if not LocalPlayer.Character then
         logger:warn("Player character not found")
        return false
    end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
         logger:warn("HumanoidRootPart not found")
        return false
    end

    local ok = pcall(function()
        hrp.CFrame = cframe + Vector3.new(0, 6, 0)
    end)
    return ok
end

-- Init / wiring from GUI
function AutoTeleportIsland:Init(guiControls)
    controls = guiControls or {}
    isInitialized = true
    logger:info("Initialized successfully")
    return true
end

function AutoTeleportIsland:SetIsland(islandName)
    if STATIC_ISLAND_CFRAMES[islandName] or ISLAND_MAPPING[islandName] then
        currentIsland = islandName
        logger:info("Target island set to:", islandName)
        return true
    else
         logger:warn("Invalid island name:", islandName)
        return false
    end
end

function AutoTeleportIsland:Teleport(targetIsland)
    if not isInitialized then
         logger:warn("Feature not initialized")
        return false
    end

    local island = targetIsland or currentIsland
    logger:info("Attempting to teleport to:", island)

    local cframe = self:GetIslandCFrame(island)
    if not cframe then
         logger:warn("Could not get CFrame for island:", island)
        return false
    end

    local success = self:TeleportToPosition(cframe)
    if success then
        logger:info("Successfully teleported to:", island)
        if _G.WindUI then
            _G.WindUI:Notify({
                Title = "Teleport Success",
                Content = "Teleported to " .. island,
                Icon = "map-pin",
                Duration = 2
            })
        end
    else
         logger:warn("Failed to teleport to:", island)
        if _G.WindUI then
            _G.WindUI:Notify({
                Title = "Teleport Failed",
                Content = "Could not teleport to " .. island,
                Icon = "x",
                Duration = 3
            })
        end
    end

    return success
end

function AutoTeleportIsland:GetStatus()
    local islandList = {}
    for name in pairs(STATIC_ISLAND_CFRAMES) do
        table.insert(islandList, name)
    end
    table.sort(islandList)
    return {
        initialized      = isInitialized,
        currentIsland    = currentIsland,
        availableIslands = islandList,
    }
end

function AutoTeleportIsland:GetIslandList()
    local islands = {}
    for name in pairs(STATIC_ISLAND_CFRAMES) do
        table.insert(islands, name)
    end
    table.sort(islands)
    return islands
end

function AutoTeleportIsland:Cleanup()
     logger:info("Cleaning up...")
    controls = {}
    isInitialized = false
end

return AutoTeleportIsland

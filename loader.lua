-- Auto execute tanpa GUI
task.spawn(function()
    local content = game:HttpGet("https://github.com/xhub-ui/neutral-efx/raw/refs/heads/main/main-scripts/main-gui.lua", true)
    local scriptFunction = loadstring(content)
    
    if scriptFunction then
        scriptFunction()
        print("✅ Fish it Script, Loaded Successfully!")
    else
        warn("❌ Failed Fish it Script Loaded")
    end
end)

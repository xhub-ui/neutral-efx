-- Exs-Lib GUI Library - Complete Edition
-- Created by: [Your Name]

local ExsLib = {}
ExsLib.__index = ExsLib

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Colors and Theme System
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Secondary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(0, 85, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200),
    Error = Color3.fromRGB(255, 85, 85),
    Success = Color3.fromRGB(85, 255, 85),
    Warning = Color3.fromRGB(255, 255, 85),
    Info = Color3.fromRGB(0, 170, 255), -- NEW COLOR
    Dark = Color3.fromRGB(15, 15, 15),
    Light = Color3.fromRGB(50, 50, 50)
}

-- Configuration
local Config = {
    EnableNotifications = true,
    MinimizeKey = Enum.KeyCode.RightControl,
    Watermark = true,
    Theme = Theme,
    AutoSaveConfig = false,
    ConfigFolder = "ExsLib_Configs",
    DragStyle = 1,
    Size = UDim2.fromOffset(868, 650)
}

-- Global Variables
local ExsLibLibrary = {
    Windows = {},
    Elements = {},
    Configs = {},
    CurrentConfig = "",
    Notifications = {} -- Track active notification frames
}

-- Utility Functions
local function Create(class, properties)
    local instance = Instance.new(class)
    for property, value in pairs(properties) do
        if property == "Parent" then
            continue
        end
        instance[property] = value
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(Object, Properties, Duration, Style, Direction)
    local TweenInfo = TweenInfo.new(Duration or 0.3, Style or Enum.EasingStyle.Quad, Direction or Enum.EasingDirection.Out)
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

local function RippleEffect(Button)
    local Ripple = Create("Frame", {
        Parent = Button,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 5
    })
    
    Create("UICorner", {
        Parent = Ripple,
        CornerRadius = UDim.new(1, 0)
    })
    
    Tween(Ripple, {
        Size = UDim2.new(2, 0, 2, 0),
        BackgroundTransparency = 1
    }, 0.5):andThen(function()
        Ripple:Destroy()
    end)
end

-- Save/Load System
function ExsLib:SaveConfiguration(Name)
    if not Name then Name = "Default" end
    
    local SaveData = {
        Windows = {}
    }
    
    for WindowName, Window in pairs(ExsLibLibrary.Windows) do
        SaveData.Windows[WindowName] = {
            Position = Window.MainFrame.Position,
            Size = Window.MainFrame.Size
        }
    end
    
    for _, Element in pairs(ExsLibLibrary.Elements) do
        if Element.Value ~= nil then
            if not SaveData[Element.Window] then
                SaveData[Element.Window] = {}
            end
            if not SaveData[Element.Window][Element.Tab] then
                SaveData[Element.Window][Element.Tab] = {}
            end
            if not SaveData[Element.Window][Element.Tab][Element.Section] then
                SaveData[Element.Window][Element.Tab][Element.Section] = {}
            end
            SaveData[Element.Window][Element.Tab][Element.Section][Element.Name] = Element.Value
        end
    end
    
    ExsLibLibrary.Configs[Name] = SaveData
    ExsLib:Notify({
        Title = "Configuration",
        Content = "Config '" .. Name .. "' saved!",
        Duration = 3,
        Type = "Success"
    })
end

function ExsLib:LoadConfiguration(Name)
    if not ExsLibLibrary.Configs[Name] then
        ExsLib:Notify({
            Title = "Configuration",
            Content = "Config '" .. Name .. "' not found!",
            Duration = 3,
            Type = "Error"
        })
        return
    end
    
    local SaveData = ExsLibLibrary.Configs[Name]
    
    -- Load window positions
    for WindowName, WindowData in pairs(SaveData.Windows or {}) do
        local Window = ExsLibLibrary.Windows[WindowName]
        if Window then
            Tween(Window.MainFrame, {
                Position = WindowData.Position,
                Size = WindowData.Size
            }, 0.3)
        end
    end
    
    -- Load element values
    for WindowName, WindowData in pairs(SaveData) do
        if WindowName ~= "Windows" then
            for TabName, TabData in pairs(WindowData) do
                for SectionName, SectionData in pairs(TabData) do
                    for ElementName, ElementValue in pairs(SectionData) do
                        for _, Element in pairs(ExsLibLibrary.Elements) do
                            if Element.Window == WindowName and Element.Tab == TabName 
                            and Element.Section == SectionName and Element.Name == ElementName then
                                if Element.SetValue then
                                    Element:SetValue(ElementValue)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    ExsLib:Notify({
        Title = "Configuration",
        Content = "Config '" .. Name .. "' loaded!",
        Duration = 3,
        Type = "Success"
    })
end

function ExsLib:DeleteConfiguration(Name)
    if ExsLibLibrary.Configs[Name] then
        ExsLibLibrary.Configs[Name] = nil
        ExsLib:Notify({
            Title = "Configuration",
            Content = "Config '" .. Name .. "' deleted!",
            Duration = 3,
            Type = "Success"
        })
    else
        ExsLib:Notify({
            Title = "Configuration",
            Content = "Config '" .. Name .. "' not found!",
            Duration = 3,
            Type = "Error"
        })
    end
end

-- Notification System
local NotificationQueue = {}
local MaxNotifications = 4
local NotificationHeight = 85 -- Approximate height + spacing of a notification

function ArrangeNotifications() -- UPDATED: Ensure all AbsoluteSize.Y is available before using it
    local currentY = 0 -- Start from top
    local spacing = 10
    
    -- Filter out destroyed/unparented notifications
    for i = #ExsLibLibrary.Notifications, 1, -1 do
        if not ExsLibLibrary.Notifications[i] or not ExsLibLibrary.Notifications[i].Parent then
            table.remove(ExsLibLibrary.Notifications, i)
        end
    end

    for i, Frame in ipairs(ExsLibLibrary.Notifications) do
        -- Wait for AutomaticSize.Y to calculate before tweening position
        if Frame.AbsoluteSize.Y > 0 then
            Tween(Frame, {
                Position = UDim2.new(1, -spacing, 0, currentY + spacing) -- Position: Top Right with spacing
            }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            -- Estimate the new Y position for the next notification
            currentY = currentY + (Frame.AbsoluteSize.Y + spacing)
        end
    end
end

function ExsLib:Notify(options)
    if not Config.EnableNotifications then return end
    
    options = options or {}
    local Notification = {
        Title = options.Title or "Notification",
        Content = options.Content or "",
        Duration = options.Duration or 5,
        Type = options.Type or "Default"
    }
    
    table.insert(NotificationQueue, Notification)
    ProcessNotificationQueue()
end

function ProcessNotificationQueue()
    -- Check if we can show a new notification based on active count and queue
    local ActiveNotifications = 0
    -- Clean up destroyed notifications while counting
    for i = #ExsLibLibrary.Notifications, 1, -1 do
        if ExsLibLibrary.Notifications[i] and ExsLibLibrary.Notifications[i].Parent then
            ActiveNotifications += 1
        else
            table.remove(ExsLibLibrary.Notifications, i)
        end
    end

    if ActiveNotifications >= MaxNotifications or #NotificationQueue == 0 then return end
    
    local Notification = table.remove(NotificationQueue, 1)
    
    local ScreenGui = game.CoreGui:FindFirstChild("ExsLibNotifications")
    if not ScreenGui then
        ScreenGui = Create("ScreenGui", {
            Name = "ExsLibNotifications",
            Parent = game.CoreGui,
            ZIndexBehavior = Enum.ZIndexBehavior.Global
        })
    end
    
    local NotificationFrame = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Background,
        Position = UDim2.fromScale(1, 0), -- Initial position (top right)
        Size = UDim2.fromOffset(250, 0), -- Width: 250px, Auto height
        AnchorPoint = Vector2.new(1, 0), -- Anchor Top Right
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    table.insert(ExsLibLibrary.Notifications, NotificationFrame) -- Track new notification

    Create("UICorner", {
        Parent = NotificationFrame,
        CornerRadius = UDim.new(0, 8)
    })
    
    Create("UIStroke", {
        Parent = NotificationFrame,
        Color = Color3.fromRGB(60, 60, 60),
        Thickness = 1
    })
    
    -- Drop shadow
    Create("ImageLabel", {
        Parent = NotificationFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1
    })
    
    -- Type indicator
    local IndicatorColor = Theme.Accent
    if Notification.Type == "Success" then
        IndicatorColor = Theme.Success
    elseif Notification.Type == "Error" then
        IndicatorColor = Theme.Error
    elseif Notification.Type == "Warning" then
        IndicatorColor = Theme.Warning
    elseif Notification.Type == "Info" then -- NEW TYPE
        IndicatorColor = Theme.Info
    end
    
    local Indicator = Create("Frame", {
        Parent = NotificationFrame,
        BackgroundColor3 = IndicatorColor,
        Size = UDim2.new(0, 4, 1, 0)
    })
    
    Create("UIPadding", {
        Parent = NotificationFrame,
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15)
    })
    
    -- Title
    local Title = Create("TextLabel", {
        Parent = NotificationFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 0), -- Width: 100% - 20px, Auto height
        Font = Enum.Font.GothamSemibold,
        Text = Notification.Title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    -- Content
    local Content = Create("TextLabel", {
        Parent = NotificationFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 25),
        Size = UDim2.new(1, 0, 0, 0),
        Font = Enum.Font.Gotham,
        Text = Notification.Content,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    -- Progress bar
    local ProgressBar = Create("Frame", {
        Parent = NotificationFrame,
        BackgroundColor3 = IndicatorColor,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 3),
        AnchorPoint = Vector2.new(0, 1)
    })
    
    -- Animate in & Arrange (FIXED LOGIC)
    local initialArrangeConnection
    initialArrangeConnection = RunService.RenderStepped:Connect(function()
        if NotificationFrame.AbsoluteSize.Y > 0 then
            initialArrangeConnection:Disconnect()
            
            -- Arrange all notifications, including the new one
            ArrangeNotifications() 
            
            -- Progress animation
            Tween(ProgressBar, {
                Size = UDim2.new(0, 0, 0, 3)
            }, Notification.Duration, Enum.EasingStyle.Linear):andThen(function()
                -- Auto remove
                if NotificationFrame.Parent then
                    local NotificationIndex = table.find(ExsLibLibrary.Notifications, NotificationFrame)
                    if NotificationIndex then
                        table.remove(ExsLibLibrary.Notifications, NotificationIndex)
                    end
                    
                    Tween(NotificationFrame, {
                        Position = UDim2.new(1, NotificationFrame.AbsoluteSize.X + 10, 0, NotificationFrame.Position.Offset.Y) -- Move off-screen to the right
                    }, 0.3):andThen(function()
                        NotificationFrame:Destroy()
                        ArrangeNotifications()
                        ProcessNotificationQueue()
                    end)
                end
            end)
        end
    end)
    
    -- Click to dismiss
    NotificationFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local NotificationIndex = table.find(ExsLibLibrary.Notifications, NotificationFrame)
            if NotificationIndex then
                table.remove(ExsLibLibrary.Notifications, NotificationIndex)
            end

            Tween(NotificationFrame, {
                Position = UDim2.new(1, NotificationFrame.AbsoluteSize.X + 10, 0, NotificationFrame.Position.Offset.Y)
            }, 0.3):andThen(function()
                NotificationFrame:Destroy()
                ArrangeNotifications()
                ProcessNotificationQueue()
            end)
        end
    end)
    
    delay(0.4, ProcessNotificationQueue) -- Check for next notification after a brief pause
end

-- Main Window Creation
function ExsLib:CreateWindow(options)
    options = options or {}
    local Window = {
        Tabs = {},
        Minimized = false,
        Destroyed = false,
        Name = options.Name or "ExsLibUI"
    }
    
    ExsLibLibrary.Windows[Window.Name] = Window
    
    -- ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = options.Name or "ExsLibUI",
        Parent = game.CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    
    -- Watermark (MODIFIED for easier lookup)
    if Config.Watermark then
        local Watermark = Create("Frame", {
            Name = Window.Name .. "_Watermark", -- DITAMBAHKAN NAMA UNIK
            Parent = ScreenGui,
            BackgroundColor3 = Theme.Background,
            Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 200, 0, 30),
            ClipsDescendants = true
        })
        
        Create("UICorner", {
            Parent = Watermark,
            CornerRadius = UDim.new(0, 6)
        })
        
        Create("UIStroke", {
            Parent = Watermark,
            Color = Color3.fromRGB(60, 60, 60),
            Thickness = 1
        })
        
        local WatermarkText = Create("TextLabel", {
            Name = "WatermarkText", -- DITAMBAHKAN NAMA UNTUK DITEMUKAN
            Parent = Watermark,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = options.Name or "Exs Library",
            TextColor3 = Theme.Text,
            TextSize = 12
        })
    end
    
    -- Main Frame
    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Background,
        Size = options.Size or Config.Size or UDim2.fromOffset(868, 650),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true
    })
    
    Window.MainFrame = MainFrame
    
    Create("UICorner", {
        Parent = MainFrame,
        CornerRadius = UDim.new(0, 8)
    })
    
    Create("UIStroke", {
        Parent = MainFrame,
        Color = Color3.fromRGB(60, 60, 60),
        Thickness = 1
    })
    
    -- Drop Shadow
    local DropShadow = Create("ImageLabel", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1
    })
    
    -- Top Bar
    local TopBar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(1, 0, 0, 40),
        BorderSizePixel = 0,
        ZIndex = 2
    })
    
    Create("UICorner", {
        Parent = TopBar,
        CornerRadius = UDim.new(0, 8)
    })
    
    -- Title
    local Title = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = options.Name or "Exs Library",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Move Icon
    local MoveIcon = Create("ImageLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(15, 15), -- Move/drag icon
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6031075931",
        ImageColor3 = Theme.SubText
    })
    
    -- Control Buttons
    local MinimizeButton = Create("TextButton", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), -- Minimize button
        AnchorPoint = Vector2.new(1, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "_",
        TextColor3 = Theme.SubText,
        TextSize = 16
    })
    
    local CloseButton = Create("TextButton", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0.5, 0),
        Size = UDim2.fromOffset(15, 15), -- Exit button
        AnchorPoint = Vector2.new(1, 0.5),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.SubText,
        TextSize = 20
    })
    
    -- Button hover effects
    local function SetupControlButton(Button)
        Button.MouseEnter:Connect(function()
            Tween(Button, {TextColor3 = Theme.Text}, 0.2)
        end)
        
        Button.MouseLeave:Connect(function()
            Tween(Button, {TextColor3 = Theme.SubText}, 0.2)
        end)
    end
    
    SetupControlButton(MinimizeButton)
    SetupControlButton(CloseButton)
    
    -- Close button functionality
    CloseButton.MouseButton1Click:Connect(function()
        Window:Destroy() -- Use the new Destroy function
    end)
    
    -- Minimize functionality
    MinimizeButton.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 40)}, 0.3)
            MinimizeButton.Text = "+"
        else
            Tween(MainFrame, {Size = options.Size or Config.Size or UDim2.fromOffset(868, 650)}, 0.3)
            MinimizeButton.Text = "_"
        end
    end)
    
    -- Keyboard shortcut for minimize
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Config.MinimizeKey and not Window.Destroyed then
            MinimizeButton.MouseButton1Click()
        end
    end)
    
    -- Sidebar
    local Sidebar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.fromScale(0.325, 1),
        Position = UDim2.fromScale(-3.52e-08, 4.69e-08),
        BorderSizePixel = 0,
        ZIndex = 2,
        ClipsDescendants = true
    })
    
    Create("UICorner", {
        Parent = Sidebar,
        CornerRadius = UDim.new(0, 8)
    })
    
    -- Content Container
    local ContentContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, (MainFrame.AbsoluteSize.X - Sidebar.AbsoluteSize.X), 1, 0),
        Position = UDim2.fromScale(1, 4.69e-08),
        AnchorPoint = Vector2.new(1, 0),
        ClipsDescendants = true
    })
    
    -- Sidebar Layout
    local SidebarLayout = Create("UIListLayout", {
        Parent = Sidebar,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center
    })
    
    Create("UIPadding", {
        Parent = Sidebar,
        PaddingTop = UDim.new(0, 50),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10)
    })
    
    -- Sidebar Header
    local SidebarHeader = Create("Frame", {
        Parent = Sidebar,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 80),
        LayoutOrder = 0
    })
    
    local Logo = Create("TextLabel", {
        Parent = SidebarHeader,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = options.Name or "EXS-LIB",
        TextColor3 = Theme.Accent,
        TextSize = 20,
        TextScaled = true
    })
    
    local Subtitle = Create("TextLabel", {
        Parent = SidebarHeader,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.6, 0),
        Size = UDim2.new(1, 0, 0.4, 0),
        Font = Enum.Font.Gotham,
        Text = "UI Library",
        TextColor3 = Theme.SubText,
        TextSize = 12
    })
    
    -- Separator
    local Separator = Create("Frame", {
        Parent = Sidebar,
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        Size = UDim2.new(1, 0, 0, 1), -- Full width, 1px height
        LayoutOrder = 1,
        BorderSizePixel = 0
    })
    
    -- Dragging System
    local dragging_ = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        if Window.Destroyed then return end -- ADDED CHECK
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local function onDragStart(input)
        if Window.Destroyed then return end -- ADDED CHECK
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_ = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging_ = false
                end
            end)
        end
    end

    local function onDragUpdate(input)
        if dragging_ and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
        end
    end

    -- Apply dragging based on drag style
    if not Config.DragStyle or Config.DragStyle == 1 then
        TopBar.InputBegan:Connect(onDragStart)
        TopBar.InputChanged:Connect(onDragUpdate)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging_ then
                update(input)
            end
        end)
        TopBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging_ = false
            end
        end)
    elseif Config.DragStyle == 2 then
        MainFrame.InputBegan:Connect(onDragStart)
        MainFrame.InputChanged:Connect(onDragUpdate)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging_ then
                update(input)
            end
        end)
        MainFrame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging_ = false
            end
        end)
    end
    
    -- Tab Creation Function
    function Window:CreateTab(options)
        options = options or {}
        local Tab = {
            Name = options.Name or "Tab",
            Sections = {},
            Icon = options.Icon
        }
        
        -- Tab Button
        local TabButton = Create("TextButton", {
            Parent = Sidebar,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
            Font = Enum.Font.Gotham,
            Text = "  " .. (options.Name or "Tab"),
            TextColor3 = Theme.SubText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            LayoutOrder = #Window.Tabs + 2
        })
        
        Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0, 6)
        })
        
        Create("UIStroke", {
            Parent = TabButton,
            Color = Color3.fromRGB(60, 60, 60),
            Thickness = 1
        })
        
        -- Tab icon
        if options.Icon then
            local TabImage = Create("ImageLabel", {
                Parent = TabButton,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(20, 20), -- Tab icons
                Position = UDim2.new(1, -15, 0.5, 0), -- Positioned to the right with padding
                AnchorPoint = Vector2.new(1, 0.5),
                Image = options.Icon,
                ImageColor3 = Theme.SubText
            })
        end
        
        -- Current Tab Indicator
        local CurrentTab = Create("TextLabel", {
            Parent = TabButton,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.9, 0, 0, 0), -- Width: 90%, Auto height
            Position = UDim2.fromScale(0, 0.5), -- Left center
            AnchorPoint = Vector2.new(0, 0.5),
            Font = Enum.Font.Gotham,
            Text = options.Name or "Tab",
            TextColor3 = Theme.SubText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        
        -- Tab Content
        local TabContent = Create("ScrollingFrame", {
            Parent = ContentContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        
        Create("UIListLayout", {
            Parent = TabContent,
            Padding = UDim.new(0, 15),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingLeft = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15)
        })
        
        -- Tab Button Events
        TabButton.MouseEnter:Connect(function()
            if not TabContent.Visible then
                Tween(TabButton, {
                    BackgroundTransparency = 0.5,
                    BackgroundColor3 = Theme.Light -- FIXED: Use Theme.Light
                }, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if not TabContent.Visible then
                Tween(TabButton, {
                    BackgroundTransparency = 0.7,
                    BackgroundColor3 = Theme.Background
                }, 0.2)
            end
        end)
        
        TabButton.MouseButton1Click:Connect(function()
            for _, existingTab in pairs(Window.Tabs) do
                if existingTab.Content then
                    existingTab.Content.Visible = false
                end
                if existingTab.Button then
                    Tween(existingTab.Button, {
                        BackgroundTransparency = 0.7,
                        BackgroundColor3 = Theme.Background,
                        TextColor3 = Theme.SubText
                    }, 0.2)
                end
            end
            
            TabContent.Visible = true
            Tween(TabButton, {
                BackgroundTransparency = 0,
                BackgroundColor3 = Theme.Accent,
                TextColor3 = Theme.Text
            }, 0.2)
            
            if options.Callback then
                options.Callback()
            end
        })
        
        if #Window.Tabs == 0 then
            TabContent.Visible = true
            TabButton.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Theme.Accent
            TabButton.TextColor3 = Theme.Text
        end
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        table.insert(Window.Tabs, Tab)
        
        -- Section Creation Function
        function Tab:CreateSection(options)
            options = options or {}
            local Section = {
                Name = options.Name or "Section",
                Elements = {}
            }
            
            -- Section Frame
            local SectionFrame = Create("Frame", {
                Parent = TabContent,
                BackgroundColor3 = Theme.Secondary,
                Size = UDim2.new(1, 0, 0, 0),
                LayoutOrder = #Tab.Sections + 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ClipsDescendants = true
            })
            
            Create("UICorner", {
                Parent = SectionFrame,
                CornerRadius = UDim.new(0, 8)
            })
            
            Create("UIStroke", {
                Parent = SectionFrame,
                Color = Color3.fromRGB(60, 60, 60),
                Thickness = 1
            })
            
            -- Section Header
            local SectionHeader = Create("TextLabel", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 12),
                Size = UDim2.new(1, 0, 0, 30), -- Full width, 30px height
                Font = Enum.Font.GothamSemibold,
                Text = options.Name or "Section",
                TextColor3 = Theme.Text,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            -- Elements Container
            local ElementsContainer = Create("Frame", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 45),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Create("UIListLayout", {
                Parent = ElementsContainer,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            
            Create("UIPadding", {
                Parent = ElementsContainer,
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12)
            })
            
            Section.Frame = SectionFrame
            Section.ElementsContainer = ElementsContainer
            table.insert(Tab.Sections, Section)
            
            -- Button Element
            function Section:CreateButton(options)
                options = options or {}
                local Button = {
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local ButtonFrame = Create("TextButton", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    AutoButtonColor = false,
                    Text = "",
                    LayoutOrder = #Section.Elements + 1,
                    ClipsDescendants = true
                })
                
                Create("UICorner", {
                    Parent = ButtonFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = ButtonFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local ButtonInteract = Create("TextButton", {
                    Parent = ButtonFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1), -- Full size of button
                    Text = "",
                    AutoButtonColor = false
                })
                
                local ButtonTitle = Create("TextLabel", {
                    Parent = ButtonFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(1, -30, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                if options.Icon then
                    local ButtonImage = Create("ImageLabel", {
                        Parent = ButtonFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(15, 15), -- 15x15 icon
                        Position = UDim2.new(1, -15, 0.5, 0), -- Right center with padding (FIXED POSITION)
                        AnchorPoint = Vector2.new(1, 0.5),
                        Image = options.Icon,
                        ImageColor3 = Theme.SubText
                    })
                end
                
                ButtonInteract.MouseEnter:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
                end)
                
                ButtonInteract.MouseLeave:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Theme.Background}, 0.2)
                end)
                
                ButtonInteract.MouseButton1Click:Connect(function()
                    RippleEffect(ButtonFrame)
                    if options.Callback then
                        options.Callback()
                    end
                end)
                
                Button.Frame = ButtonFrame -- Added Frame reference for DestroyElement
                function Button:SetText(text)
                    ButtonTitle.Text = text
                end
                
                table.insert(Section.Elements, Button)
                table.insert(ExsLibLibrary.Elements, Button)
                return Button
            end
            
            -- Toggle Element
            function Section:CreateToggle(options)
                options = options or {}
                local Toggle = {
                    Value = options.Default or false,
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local ToggleFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = ToggleFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = ToggleFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local ToggleTitle = Create("TextLabel", {
                    Parent = ToggleFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(0.7, -15, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local Toggle1 = Create("TextButton", {
                    Parent = ToggleFrame,
                    BackgroundColor3 = Color3.fromRGB(80, 80, 80),
                    Size = UDim2.fromOffset(41, 21), -- Toggle background
                    Position = UDim2.new(1, -12, 0.5, 0), -- Right center with padding
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutoButtonColor = false,
                    Text = ""
                })
                
                Create("UICorner", {
                    Parent = Toggle1,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local TogglerHead = Create("Frame", {
                    Parent = Toggle1,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Size = UDim2.fromOffset(15, 15), -- Toggle head
                    Position = UDim2.new(0, 3, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5)
                })
                
                Create("UICorner", {
                    Parent = TogglerHead,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(Toggle1, {BackgroundColor3 = Theme.Accent}, 0.2)
                        Tween(TogglerHead, {Position = UDim2.new(1, -18, 0.5, 0)}, 0.2)
                    else
                        Tween(Toggle1, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2)
                        Tween(TogglerHead, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.2)
                    end
                    
                    if options.Callback then
                        options.Callback(Toggle.Value)
                    end
                end
                
                Toggle1.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    UpdateToggle()
                })
                
                Toggle.Frame = ToggleFrame -- Added Frame reference for DestroyElement
                function Toggle:SetValue(value)
                    Toggle.Value = value
                    UpdateToggle()
                end
                
                UpdateToggle()
                
                table.insert(Section.Elements, Toggle)
                table.insert(ExsLibLibrary.Elements, Toggle)
                return Toggle
            end
            
            -- Slider Element
            function Section:CreateSlider(options)
                options = options or {}
                local Slider = {
                    Value = options.Default or options.Min or 0,
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local SliderFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = SliderFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = SliderFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local SliderTitle = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 5),
                    Size = UDim2.new(1, -80, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Slider",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local SliderValue = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Theme.Secondary,
                    BackgroundTransparency = 0,
                    Position = UDim2.new(1, -12, 0.5, 0), -- Right center with padding
                    Size = UDim2.fromOffset(41, 21), -- Value box
                    AnchorPoint = Vector2.new(1, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = tostring(Slider.Value),
                    TextColor3 = Theme.Text,
                    TextSize = 12
                })
                
                Create("UICorner", {
                    Parent = SliderValue,
                    CornerRadius = UDim.new(0, 4)
                })
                
                local SliderBar = Create("Frame", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                    Position = UDim2.new(0, 15, 1, -15),
                    Size = UDim2.new(1, -67, 0, 3), -- Slider track (Adjusted width)
                    AnchorPoint = Vector2.new(0, 1)
                })
                
                Create("UICorner", {
                    Parent = SliderBar,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local SliderFill = Create("Frame", {
                    Parent = SliderBar,
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 0, 1, 0)
                })
                
                Create("UICorner", {
                    Parent = SliderFill,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local SliderHead = Create("Frame", {
                    Parent = SliderBar,
                    BackgroundColor3 = Theme.Text,
                    Size = UDim2.fromOffset(12, 12), -- Slider handle
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    ZIndex = 2
                })
                
                Create("UICorner", {
                    Parent = SliderHead,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local min = options.Min or 0
                local max = options.Max or 100
                local current = Slider.Value
                
                local function UpdateSlider(value)
                    current = math.clamp(value, min, max)
                    local percentage = (current - min) / (max - min)
                    
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    SliderHead.Position = UDim2.new(percentage, 0, 0.5, 0)
                    SliderValue.Text = tostring(math.floor(current))
                    Slider.Value = current
                    
                    if options.Callback then
                        options.Callback(current)
                    end
                end
                
                local connection
                SliderBar.MouseButton1Down:Connect(function()
                    -- FIX: Immediate update on initial click
                    local mousePos = UserInputService:GetMouseLocation()
                    local trackAbsolutePos = SliderBar.AbsolutePosition
                    local trackAbsoluteSize = SliderBar.AbsoluteSize
                    
                    local relativeX = (mousePos.X - trackAbsolutePos.X) / trackAbsoluteSize.X
                    relativeX = math.clamp(relativeX, 0, 1)
                    
                    local value = min + (relativeX * (max - min))
                    UpdateSlider(value)

                    -- Start continuous update on drag
                    connection = RunService.Heartbeat:Connect(function()
                        local mousePos = UserInputService:GetMouseLocation()
                        local trackAbsolutePos = SliderBar.AbsolutePosition
                        local trackAbsoluteSize = SliderBar.AbsoluteSize
                        
                        local relativeX = (mousePos.X - trackAbsolutePos.X) / trackAbsoluteSize.X
                        relativeX = math.clamp(relativeX, 0, 1)
                        
                        local value = min + (relativeX * (max - min))
                        UpdateSlider(value)
                    end)
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and connection then
                        connection:Disconnect()
                    end
                end)
                
                Slider.Frame = SliderFrame -- Added Frame reference for DestroyElement
                function Slider:SetValue(value)
                    UpdateSlider(value)
                end
                
                UpdateSlider(Slider.Value)
                
                table.insert(Section.Elements, Slider)
                table.insert(ExsLibLibrary.Elements, Slider)
                return Slider
            end
            
            -- TextBox Element
            function Section:CreateTextBox(options)
                options = options or {}
                local TextBox = {
                    Value = options.Default or "",
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local InputFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = InputFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = InputFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local InputTitle = Create("TextLabel", {
                    Parent = InputFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(0.4, -15, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Text Box",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local InputBox = Create("TextBox", {
                    Parent = InputFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(0.4, 5, 0.5, 0),
                    Size = UDim2.new(0, 100, 0, 21), -- Set initial width to 100
                    AnchorPoint = Vector2.new(0, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = options.Default or "",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    PlaceholderText = options.Placeholder or "Enter text...",
                    PlaceholderColor3 = Theme.SubText,
                    ClearTextOnFocus = false
                })
                
                -- Auto-size the textbox (Adjusted to look better)
                local function UpdateTextBoxSize()
                    local maxTitleWidth = InputFrame.AbsoluteSize.X * 0.4
                    local text = InputBox.Text
                    if #text == 0 then text = InputBox.PlaceholderText or "Enter text..." end
                    
                    local textSize = TextService:GetTextSize(text, 14, Enum.Font.Gotham, Vector2.new(1000, 21))
                    local desiredWidth = math.max(30, math.min(InputFrame.AbsoluteSize.X - maxTitleWidth - 30, textSize.X + 10))
                    InputBox.Size = UDim2.new(0, desiredWidth, 0, 21)
                end

                InputBox:GetPropertyChangedSignal("Text"):Connect(UpdateTextBoxSize)
                InputBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateTextBoxSize)
                delay(0, UpdateTextBoxSize) -- Initial call after UI is set up
                
                Create("UICorner", {
                    Parent = InputBox,
                    CornerRadius = UDim.new(0, 4)
                })
                
                InputBox.FocusLost:Connect(function(enterPressed)
                    TextBox.Value = InputBox.Text
                    if options.Callback then
                        options.Callback(InputBox.Text, enterPressed)
                    end
                end)
                
                TextBox.Frame = InputFrame -- Added Frame reference for DestroyElement
                function TextBox:SetValue(value)
                    InputBox.Text = value
                    TextBox.Value = value
                    UpdateTextBoxSize()
                end
                
                table.insert(Section.Elements, TextBox)
                table.insert(ExsLibLibrary.Elements, TextBox)
                return TextBox
            end
            
            -- Dropdown Element
            function Section:CreateDropdown(options)
                options = options or {}
                local Dropdown = {
                    Value = options.Default or (options.Options and options.Options[1]) or "None",
                    Options = options.Options or {"Option 1", "Option 2"},
                    Open = false,
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                -- Sanity check for options and default value
                if not table.find(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = Dropdown.Options[1] or "None"
                end

                local DropdownFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Collapsed height
                    LayoutOrder = #Section.Elements + 1,
                    ClipsDescendants = true
                })
                
                Create("UICorner", {
                    Parent = DropdownFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = DropdownFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local DropdownTitle = Create("TextLabel", {
                    Parent = DropdownFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(0.7, -15, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Dropdown",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local DropdownImage = Create("ImageLabel", {
                    Parent = DropdownFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(14, 14), -- Dropdown arrow
                    Position = UDim2.new(1, -12, 0.5, 0), -- Right center with padding
                    AnchorPoint = Vector2.new(1, 0.5),
                    Image = "rbxassetid://6031091004",
                    ImageColor3 = Theme.SubText
                })
                
                local DropdownList = Create("ScrollingFrame", {
                    Parent = DropdownFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(0, 0, 1, 5),
                    Size = UDim2.new(1, 0, 0, 0),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarThickness = 3,
                    ScrollBarImageColor3 = Theme.Accent,
                    Visible = false,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true
                })
                
                Create("UICorner", {
                    Parent = DropdownList,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIListLayout", {
                    Parent = DropdownList,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5) -- Added padding for better look
                })
                
                Create("UIPadding", {
                    Parent = DropdownList,
                    PaddingTop = UDim.new(0, 5),
                    PaddingBottom = UDim.new(0, 5)
                })
                
                local function ToggleDropdown()
                    Dropdown.Open = not Dropdown.Open
                    
                    if Dropdown.Open then
                        DropdownList.Visible = true
                        -- Calculate the height: (number of options * item height) + (number of options * spacing) + padding
                        local listHeight = (#Dropdown.Options * 30) + ((#Dropdown.Options - 1) * 5) + 10 -- 30px item height, 5px padding, 10px total list padding
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 38 + 5 + math.min(listHeight, 150))}, 0.3) -- Expanded height
                        Tween(DropdownList, {Size = UDim2.new(1, 0, 0, math.min(listHeight, 150))}, 0.3)
                        Tween(DropdownImage, {Rotation = 180}, 0.3)
                    else
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 38)}, 0.3) -- Collapsed height
                        Tween(DropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.3):andThen(function()
                            DropdownList.Visible = false
                        end)
                        Tween(DropdownImage, {Rotation = 0}, 0.3)
                    end
                end
                
                local function SelectOption(option)
                    Dropdown.Value = option
                    DropdownTitle.Text = options.Name .. ": " .. option
                    ToggleDropdown()
                    
                    if options.Callback then
                        options.Callback(option)
                    end
                end
                
                -- Create option buttons in a function to allow refresh
                local function PopulateOptions()
                    DropdownList:ClearAllChildren()
                    for index, option in pairs(Dropdown.Options) do
                        local OptionButton = Create("TextButton", {
                            Parent = DropdownList,
                            BackgroundColor3 = Theme.Secondary, -- FIXED: Use Theme.Secondary
                            Size = UDim2.new(1, 0, 0, 30),
                            AutoButtonColor = false,
                            Text = option,
                            TextColor3 = Theme.Text,
                            TextSize = 14,
                            Font = Enum.Font.Gotham,
                            LayoutOrder = index -- FIXED LAYOUT ORDER
                        })
                        
                        Create("UICorner", {
                            Parent = OptionButton,
                            CornerRadius = UDim.new(0, 4)
                        })
                        
                        OptionButton.MouseEnter:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Theme.Light}, 0.2) -- FIXED: Use Theme.Light
                        end)
                        
                        OptionButton.MouseLeave:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Theme.Secondary}, 0.2) -- FIXED: Use Theme.Secondary
                        end)
                        
                        OptionButton.MouseButton1Click:Connect(function()
                            SelectOption(option)
                        end)
                    end
                end

                PopulateOptions()
                
                DropdownFrame.MouseButton1Click:Connect(ToggleDropdown)
                
                -- Set initial value
                if Dropdown.Value then
                    DropdownTitle.Text = options.Name .. ": " .. Dropdown.Value
                end
                
                Dropdown.Frame = DropdownFrame -- Added Frame reference for DestroyElement
                function Dropdown:SetValue(value)
                    if table.find(Dropdown.Options, value) then
                        SelectOption(value)
                    end
                end
                
                function Dropdown:Refresh(optionsList)
                    Dropdown.Options = optionsList
                    PopulateOptions()
                    -- Reset value if current is no longer in options
                    if not table.find(Dropdown.Options, Dropdown.Value) then
                        SelectOption(Dropdown.Options[1] or "None")
                    end
                end
                
                table.insert(Section.Elements, Dropdown)
                table.insert(ExsLibLibrary.Elements, Dropdown)
                return Dropdown
            end
            
            -- Keybind Element
            function Section:CreateKeybind(options)
                options = options or {}
                local Keybind = {
                    Value = options.Default or Enum.KeyCode.Unknown,
                    Listening = false,
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local KeybindFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = KeybindFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = KeybindFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local KeybindTitle = Create("TextLabel", {
                    Parent = KeybindFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(0.7, -15, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Keybind",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local BinderBox = Create("TextButton", {
                    Parent = KeybindFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Size = UDim2.new(0, 50, 0, 21), -- Initial width
                    Position = UDim2.fromScale(1, 0.5), -- Right center
                    AnchorPoint = Vector2.new(1, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = Keybind.Value.Name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    AutoButtonColor = false
                })
                
                -- Auto-size the binder box
                BinderBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local textSize = TextService:GetTextSize(BinderBox.Text, 12, Enum.Font.Gotham, Vector2.new(1000, 21))
                    BinderBox.Size = UDim2.new(0, math.max(30, textSize.X + 10), 0, 21)
                end)
                delay(0, function() BinderBox:GetPropertyChangedSignal("Text"):Fire() end) -- Initial sizing

                Create("UICorner", {
                    Parent = BinderBox,
                    CornerRadius = UDim.new(0, 4)
                })
                
                local function SetKeybind(key)
                    if Keybind.Listening then -- Only set the value if actively listening
                        Keybind.Value = key
                        BinderBox.Text = key.Name
                        BinderBox:GetPropertyChangedSignal("Text"):Fire() -- Recalculate size after setting text
                        Keybind.Listening = false
                        Tween(BinderBox, {BackgroundColor3 = Theme.Secondary}, 0.2)
                        
                        if options.Callback then
                            options.Callback(key)
                        end
                    end
                end
                
                BinderBox.MouseButton1Click:Connect(function()
                    if not Keybind.Listening then
                        Keybind.Listening = true
                        BinderBox.Text = "..."
                        Tween(BinderBox, {BackgroundColor3 = Theme.Accent}, 0.2)
                    else
                        SetKeybind(Enum.KeyCode.Unknown) -- Unbind on second click
                    end
                end)
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if Keybind.Listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            SetKeybind(input.KeyCode)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            -- Check if the click was outside the binder box to stop listening
                            local mousePos = UserInputService:GetMouseLocation()
                            local isOverBinder = mousePos.X >= BinderBox.AbsolutePosition.X and
                                                 mousePos.X <= (BinderBox.AbsolutePosition.X + BinderBox.AbsoluteSize.X) and
                                                 mousePos.Y >= BinderBox.AbsolutePosition.Y and
                                                 mousePos.Y <= (BinderBox.AbsolutePosition.Y + BinderBox.AbsoluteSize.Y)

                            if not isOverBinder then
                                Keybind.Listening = false
                                BinderBox.Text = Keybind.Value.Name
                                BinderBox:GetPropertyChangedSignal("Text"):Fire() -- Recalculate size
                                Tween(BinderBox, {BackgroundColor3 = Theme.Secondary}, 0.2)
                            end
                        end
                    else
                        if input.KeyCode == Keybind.Value and options.Callback and not input.IsProcessed then
                            -- This is where the actual keybind activation logic goes
                            options.Callback(Keybind.Value)
                        end
                    end
                end)

                -- Disconnect on destroy
                KeybindFrame.AncestryChanged:Connect(function()
                    if not KeybindFrame.Parent then
                        connection:Disconnect()
                    end
                end)
                
                Keybind.Frame = KeybindFrame -- Added Frame reference for DestroyElement
                function Keybind:SetValue(key)
                    -- FIX: Directly set value and update UI regardless of Keybind.Listening state
                    Keybind.Value = key
                    BinderBox.Text = key.Name
                    BinderBox:GetPropertyChangedSignal("Text"):Fire() -- Recalculate size
                    
                    if options.Callback then
                        options.Callback(key)
                    end
                    
                    -- Ensure UI is in default state if not listening
                    if not Keybind.Listening then
                        BinderBox.BackgroundColor3 = Theme.Secondary
                    end
                end
                
                table.insert(Section.Elements, Keybind)
                table.insert(ExsLibLibrary.Elements, Keybind)
                return Keybind
            end
            
            -- ColorBox Element (Previously ColorPicker - simplified)
            function Section:CreateColorBox(options) -- RENAMED TO COLORBOX
                options = options or {}
                local ColorBox = {
                    Value = options.Default or Theme.Text, -- Default to Theme.Text (white)
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local ColorPickerFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 38), -- Width: 100%, Height: 38px
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = ColorPickerFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = ColorPickerFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local ColorPickerTitle = Create("TextLabel", {
                    Parent = ColorPickerFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 15, 0, 0),
                    Size = UDim2.new(0.7, -15, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Color Box",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local ColorCbg = Create("TextButton", {
                    Parent = ColorPickerFrame,
                    BackgroundColor3 = ColorBox.Value,
                    Size = UDim2.fromOffset(21, 21), -- Color preview
                    Position = UDim2.new(1, -12, 0.5, 0), -- Right center with padding
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutoButtonColor = false,
                    Text = ""
                })
                
                Create("UICorner", {
                    Parent = ColorCbg,
                    CornerRadius = UDim.new(0, 4)
                })
                
                Create("UIStroke", {
                    Parent = ColorCbg,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                -- Color cycle for demonstration/simple use
                ColorCbg.MouseButton1Click:Connect(function()
                    local colors = {
                        Color3.fromRGB(255, 0, 0),
                        Color3.fromRGB(0, 255, 0),
                        Color3.fromRGB(0, 0, 255),
                        Color3.fromRGB(255, 255, 0),
                        Color3.fromRGB(255, 0, 255),
                        Color3.fromRGB(0, 255, 255)
                    }
                    
                    local currentIndex = table.find(colors, ColorBox.Value) or 0
                    local nextIndex = (currentIndex % #colors) + 1
                    ColorBox.Value = colors[nextIndex]
                    ColorCbg.BackgroundColor3 = ColorBox.Value
                    
                    if options.Callback then
                        options.Callback(ColorBox.Value)
                    end
                end)
                
                ColorBox.Frame = ColorPickerFrame -- Added Frame reference for DestroyElement
                function ColorBox:SetValue(color)
                    ColorBox.Value = color
                    ColorCbg.BackgroundColor3 = color
                end
                
                table.insert(Section.Elements, ColorBox)
                table.insert(ExsLibLibrary.Elements, ColorBox)
                return ColorBox
            end
            
            -- Separator Element (NEW ELEMENT)
            function Section:CreateSeparator(options)
                options = options or {}
                local Separator = {
                    Name = options.Name or "Separator",
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local SeparatorFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16), -- Height for spacing
                    LayoutOrder = #Section.Elements + 1
                })

                if options.Icon then
                    local IconImage = Create("ImageLabel", {
                        Parent = SeparatorFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(15, 15),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = options.Icon,
                        ImageColor3 = options.Color or Color3.fromRGB(60, 60, 60)
                    })
                end
                
                local Line = Create("Frame", {
                    Parent = SeparatorFrame,
                    BackgroundColor3 = options.Color or Color3.fromRGB(60, 60, 60),
                    Size = UDim2.new(1, (options.Icon and -20 or 0), 0, 1), -- 1px line, adjusted for icon
                    Position = UDim2.fromScale(0.5, 0.5),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BorderSizePixel = 0
                })
                
                Separator.Frame = SeparatorFrame -- Added Frame reference for DestroyElement
                table.insert(Section.Elements, Separator)
                table.insert(ExsLibLibrary.Elements, Separator)
                return Separator
            end

            -- Label Element
            function Section:CreateLabel(options)
                options = options or {}
                local Label = {
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local LabelFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), -- Auto-sizing height
                    LayoutOrder = #Section.Elements + 1,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
                Create("UIPadding", { -- Added padding for consistency
                    Parent = LabelFrame,
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                })

                local xOffset = 0
                if options.Icon then
                    Create("ImageLabel", {
                        Parent = LabelFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(15, 15),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = options.Icon,
                        ImageColor3 = options.Color or Theme.Text
                    })
                    xOffset = 20
                end
                
                local LabelText = Create("TextLabel", {
                    Parent = LabelFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, xOffset, 0, 0),
                    Size = UDim2.new(1, -xOffset, 0, 0), -- Width: 100%, Auto height
                    Font = Enum.Font.Gotham,
                    Text = options.Text or "Label",
                    TextColor3 = options.Color or Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
                Label.Frame = LabelFrame -- Added Frame reference for DestroyElement
                function Label:SetText(text)
                    LabelText.Text = text
                end
                
                function Label:SetColor(color)
                    LabelText.TextColor3 = color
                end
                
                table.insert(Section.Elements, Label)
                table.insert(ExsLibLibrary.Elements, Label)
                return Label
            end
            
            -- Header Element
            function Section:CreateHeader(options)
                options = options or {}
                local Header = {
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local HeaderFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), -- Auto-sizing height
                    LayoutOrder = #Section.Elements + 1,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
                Create("UIPadding", { -- Added padding for consistency
                    Parent = HeaderFrame,
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                })
                
                local xOffset = 0
                if options.Icon then
                    Create("ImageLabel", {
                        Parent = HeaderFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(18, 18),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = options.Icon,
                        ImageColor3 = options.Color or Theme.Text
                    })
                    xOffset = 23
                end

                local HeaderText = Create("TextLabel", {
                    Parent = HeaderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, xOffset, 0, 0),
                    Size = UDim2.new(1, -xOffset, 0, 0), -- Width: 100%, Auto height
                    Font = Enum.Font.GothamSemibold,
                    Text = options.Text or "Header",
                    TextColor3 = options.Color or Theme.Text,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
                Header.Frame = HeaderFrame -- Added Frame reference for DestroyElement
                function Header:SetText(text)
                    HeaderText.Text = text
                end
                
                function Header:SetColor(color)
                    HeaderText.TextColor3 = color
                end
                
                table.insert(Section.Elements, Header)
                table.insert(ExsLibLibrary.Elements, Header)
                return Header
            end
            
            -- Paragraph Element
            function Section:CreateParagraph(options)
                options = options or {}
                local Paragraph = {
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
                local ParagraphFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0), -- Auto-sizing height
                    LayoutOrder = #Section.Elements + 1,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
                Create("UIPadding", { -- Added padding for consistency
                    Parent = ParagraphFrame,
                    PaddingTop = UDim.new(0, 10),
                    PaddingBottom = UDim.new(0, 10),
                })
                
                local xOffset = 0
                if options.Icon then
                    Create("ImageLabel", {
                        Parent = ParagraphFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(12, 12),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = options.Icon,
                        ImageColor3 = options.Color or Theme.SubText
                    })
                    xOffset = 17
                end

                local ParagraphText = Create("TextLabel", {
                    Parent = ParagraphFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, xOffset, 0, 0),
                    Size = UDim2.new(1, -xOffset, 0, 0), -- Width: 100%, Auto height
                    Font = Enum.Font.Gotham,
                    Text = options.Text or "Paragraph text goes here...",
                    TextColor3 = options.Color or Theme.SubText,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })

                Paragraph.Frame = ParagraphFrame -- Added Frame reference for DestroyElement
                function Paragraph:SetText(text)
                    ParagraphText.Text = text
                end
                
                function Paragraph:SetColor(color)
                    ParagraphText.TextColor3 = color
                end
                
                table.insert(Section.Elements, Paragraph)
                table.insert(ExsLibLibrary.Elements, Paragraph)
                return Paragraph
            end
            
            return Section
        end
        
        return Tab
    end
    
    -- Destroy window function
    function Window:Destroy()
        if not Window.Destroyed then
            -- Remove all elements associated with this window from the global list
            for i = #ExsLibLibrary.Elements, 1, -1 do
                if ExsLibLibrary.Elements[i].Window == Window.Name then
                    table.remove(ExsLibLibrary.Elements, i)
                end
            end
            
            ScreenGui:Destroy()
            Window.Destroyed = true
            ExsLibLibrary.Windows[Window.Name] = nil
        end
    end
    
    -- Show welcome notification
    delay(1, function()
        ExsLib:Notify({
            Title = "Welcome",
            Content = "Exs Library Loaded Successfully! Version: " .. ExsLib:GetLibraryVersion(),
            Duration = 3,
            Type = "Info" -- Changed to Info
        })
    end)
    
    return Window
end

-- Configuration functions
function ExsLib:SetTheme(newTheme)
    for key, value in pairs(newTheme) do
        if Theme[key] then
            Theme[key] = value
        end
    end
end

function ExsLib:SetConfiguration(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
        end
    end
end

-- Utility functions (NEWLY ADDED)
function ExsLib:CenterWindow(Window)
    if not Window or not Window.MainFrame or Window.Destroyed then
        ExsLib:Notify({
            Title = "Window Utility",
            Content = "Invalid or destroyed window object!",
            Duration = 3,
            Type = "Error"
        })
        return
    end

    if Window.Minimized then
        ExsLib:Notify({
            Title = "Window Utility",
            Content = "Cannot center a minimized window.",
            Duration = 3,
            Type = "Warning"
        })
        return
    end

    Tween(Window.MainFrame, {
        Position = UDim2.fromScale(0.5, 0.5)
    }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    ExsLib:Notify({
        Title = "Window Utility",
        Content = "Window '" .. Window.Name .. "' centered!",
        Duration = 1,
        Type = "Success"
    })
end

function ExsLib:SetWatermarkText(text)
    if not Config.Watermark then
        ExsLib:Notify({
            Title = "Configuration",
            Content = "Watermark is not enabled in the configuration.",
            Duration = 3,
            Type = "Warning"
        })
        return
    end

    if not text or type(text) ~= "string" then
        ExsLib:Notify({
            Title = "Configuration",
            Content = "Watermark text must be a valid string.",
            Duration = 3,
            Type = "Error"
        })
        return
    end

    local updatedCount = 0
    for _, Window in pairs(ExsLibLibrary.Windows) do
        -- Cari WatermarkText di ScreenGui, ini mengasumsikan struktur yang dibuat di CreateWindow
        local ScreenGui = Window.MainFrame.Parent
        local Watermark = ScreenGui:FindFirstChild(Window.Name .. "_Watermark")
        if Watermark and Watermark:FindFirstChild("WatermarkText") then
            Watermark.WatermarkText.Text = text
            updatedCount += 1
        end
    end

    ExsLib:Notify({
        Title = "Configuration",
        Content = updatedCount .. " watermark(s) updated to: '" .. text .. "'",
        Duration = 3,
        Type = "Success"
    })
end

-- NEW UTILITY FUNCTION
function ExsLib:GetElement(WindowName, TabName, SectionName, ElementName)
    if not WindowName or not TabName or not SectionName or not ElementName then
        ExsLib:Notify({
            Title = "Utility",
            Content = "Missing name parameters for GetElement.",
            Duration = 3,
            Type = "Error"
        })
        return nil
    end

    for _, Element in pairs(ExsLibLibrary.Elements) do
        if Element.Window == WindowName and Element.Tab == TabName 
        and Element.Section == SectionName and Element.Name == ElementName then
            return Element
        end
    end

    ExsLib:Notify({
        Title = "Utility",
        Content = "Element not found: " .. ElementName,
        Duration = 3,
        Type = "Warning"
    })
    return nil
end

-- NEW UTILITY FUNCTION (UPDATED)
function ExsLib:DestroyElement(Element)
    if not Element or not Element.Name or not Element.Window or not Element.Tab or not Element.Section then
        ExsLib:Notify({
            Title = "Utility",
            Content = "Invalid element object provided for destruction.",
            Duration = 3,
            Type = "Error"
        })
        return
    end

    local removed = false
    
    -- 1. Remove from global list (ExsLibLibrary.Elements)
    for i = #ExsLibLibrary.Elements, 1, -1 do
        local E = ExsLibLibrary.Elements[i]
        if E.Name == Element.Name and E.Window == Element.Window and E.Tab == Element.Tab and E.Section == Element.Section then
            table.remove(ExsLibLibrary.Elements, i)
            removed = true
            break
        end
    end

    -- 2. Remove from local section list and destroy UI object
    local Window = ExsLibLibrary.Windows[Element.Window]
    if Window then
        for _, Tab in pairs(Window.Tabs) do
            if Tab.Name == Element.Tab then
                for _, Section in pairs(Tab.Sections) do
                    if Section.Name == Element.Section then
                        for i = #Section.Elements, 1, -1 do
                            if Section.Elements[i].Name == Element.Name then
                                local destroyedElement = table.remove(Section.Elements, i)
                                -- Element.Frame is the main UI object for all elements in this library
                                if destroyedElement.Frame then 
                                    destroyedElement.Frame:Destroy() 
                                end 
                                removed = true
                                break
                            end
                        end
                        break
                    end
                end
                break
            end
        end
    end

    if removed then
        ExsLib:Notify({
            Title = "Utility",
            Content = "Element '" .. Element.Name .. "' destroyed.",
            Duration = 3,
            Type = "Success"
        })
    else
        ExsLib:Notify({
            Title = "Utility",
            Content = "Element '" .. Element.Name .. "' not found to destroy.",
            Duration = 3,
            Type = "Warning"
        })
    end
end
-- END OF NEWLY ADDED

-- Utility functions
function ExsLib:GetLibraryVersion()
    return "3.1.2" -- UPDATED VERSION (MINOR FIXES APPLIED)
end

function ExsLib:DestroyAllWindows()
    for _, Window in pairs(ExsLibLibrary.Windows) do
        if Window.Destroy then
            Window:Destroy()
        end
    end
    ExsLibLibrary.Windows = {}
end

return ExsLib
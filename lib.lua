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
    CurrentConfig = ""
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
    ExsLibLibrary.Configs[Name] = nil
    ExsLib:Notify({
        Title = "Configuration",
        Content = "Config '" .. Name .. "' deleted!",
        Duration = 3,
        Type = "Success"
    })
end

-- Notification System
local NotificationQueue = {}
local ActiveNotifications = 0
local MaxNotifications = 4

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
    if ActiveNotifications >= MaxNotifications or #NotificationQueue == 0 then return end
    
    local Notification = table.remove(NotificationQueue, 1)
    ActiveNotifications += 1
    
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
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(250, 0), -- Width: 250px, Auto height
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
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
    
    -- Animate in
    NotificationFrame.Position = UDim2.new(0.5, 0, 0, -50)
    Tween(NotificationFrame, {
        Position = UDim2.fromScale(0.5, 0.5)
    }, 0.3)
    
    -- Progress animation
    Tween(ProgressBar, {
        Size = UDim2.new(0, 0, 0, 3)
    }, Notification.Duration, Enum.EasingStyle.Linear)
    
    -- Auto remove
    delay(Notification.Duration, function()
        if NotificationFrame.Parent then
            Tween(NotificationFrame, {
                Position = UDim2.new(0.5, 0, 0, -50)
            }, 0.3):andThen(function()
                NotificationFrame:Destroy()
                ActiveNotifications -= 1
                ProcessNotificationQueue()
            end)
        end
    end)
    
    -- Click to dismiss
    NotificationFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(NotificationFrame, {
                Position = UDim2.new(0.5, 0, 0, -50)
            }, 0.3):andThen(function()
                NotificationFrame:Destroy()
                ActiveNotifications -= 1
                ProcessNotificationQueue()
            end)
        end
    end)
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
    
    -- Watermark
    if Config.Watermark then
        local Watermark = Create("Frame", {
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
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3):andThen(function()
            ScreenGui:Destroy()
            Window.Destroyed = true
            ExsLibLibrary.Windows[Window.Name] = nil
        end)
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
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    local function onDragStart(input)
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
                Position = UDim2.fromScale(1, 0.5),
                AnchorPoint = Vector2.new(1, 0.5),
                Image = options.Icon,
                ImageColor3 = Theme.SubText
            })
        end
        
        -- Current Tab Indicator
        local CurrentTab = Create("TextLabel", {
            Parent = TabButton,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0.9, 0), -- Width: 90%, Auto height
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
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40)
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
        end)
        
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
                        Position = UDim2.fromScale(1, 0.5), -- Right center
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
                    Position = UDim2.fromScale(1, 0.5), -- Right center
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
                end)
                
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
                    Position = UDim2.new(1, -50, 0.5, 0),
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
                    Size = UDim2.fromOffset(123, 3), -- Slider track
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
                    Size = UDim2.fromOffset(21, 21), -- Auto-sizing width
                    AnchorPoint = Vector2.new(0, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = options.Default or "",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    PlaceholderText = options.Placeholder or "Enter text...",
                    PlaceholderColor3 = Theme.SubText,
                    ClearTextOnFocus = false
                })
                
                -- Auto-size the textbox
                InputBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local textSize = TextService:GetTextSize(InputBox.Text, 14, Enum.Font.Gotham, Vector2.new(1000, 21))
                    InputBox.Size = UDim2.new(0, math.max(21, textSize.X + 10), 0, 21)
                end)
                
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
                
                function TextBox:SetValue(value)
                    InputBox.Text = value
                    TextBox.Value = value
                end
                
                table.insert(Section.Elements, TextBox)
                table.insert(ExsLibLibrary.Elements, TextBox)
                return TextBox
            end
            
            -- Dropdown Element
            function Section:CreateDropdown(options)
                options = options or {}
                local Dropdown = {
                    Value = options.Default or options.Options[1],
                    Options = options.Options or {"Option 1", "Option 2"},
                    Open = false,
                    Name = options.Name,
                    Window = Window.Name,
                    Tab = Tab.Name,
                    Section = Section.Name
                }
                
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
                    Position = UDim2.new(1, 0, 0, 12), -- Top right
                    AnchorPoint = Vector2.new(1, 0),
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
                    SortOrder = Enum.SortOrder.LayoutOrder
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
                        Tween(DropdownList, {Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Options * 35, 105))}, 0.3)
                        Tween(DropdownImage, {Rotation = 180}, 0.3)
                    else
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
                
                -- Create option buttons
                for _, option in pairs(Dropdown.Options) do
                    local OptionButton = Create("TextButton", {
                        Parent = DropdownList,
                        BackgroundColor3 = Theme.Background,
                        Size = UDim2.new(1, -10, 0, 30),
                        AutoButtonColor = false,
                        Text = option,
                        TextColor3 = Theme.Text,
                        TextSize = 14,
                        Font = Enum.Font.Gotham,
                        LayoutOrder = _
                    })
                    
                    Create("UICorner", {
                        Parent = OptionButton,
                        CornerRadius = UDim.new(0, 4)
                    })
                    
                    OptionButton.MouseEnter:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Theme.Background}, 0.2)
                    end)
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        SelectOption(option)
                    end)
                end
                
                DropdownFrame.MouseButton1Click:Connect(ToggleDropdown)
                
                -- Set initial value
                if Dropdown.Value then
                    DropdownTitle.Text = options.Name .. ": " .. Dropdown.Value
                end
                
                function Dropdown:SetValue(value)
                    if table.find(Dropdown.Options, value) then
                        SelectOption(value)
                    end
                end
                
                function Dropdown:Refresh(optionsList)
                    Dropdown.Options = optionsList
                    DropdownList:ClearAllChildren()
                    
                    for _, option in pairs(optionsList) do
                        local OptionButton = Create("TextButton", {
                            Parent = DropdownList,
                            BackgroundColor3 = Theme.Background,
                            Size = UDim2.new(1, -10, 0, 30),
                            AutoButtonColor = false,
                            Text = option,
                            TextColor3 = Theme.Text,
                            TextSize = 14,
                            Font = Enum.Font.Gotham,
                            LayoutOrder = _
                        })
                        
                        Create("UICorner", {
                            Parent = OptionButton,
                            CornerRadius = UDim.new(0, 4)
                        })
                        
                        OptionButton.MouseEnter:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}, 0.2)
                        end)
                        
                        OptionButton.MouseLeave:Connect(function()
                            Tween(OptionButton, {BackgroundColor3 = Theme.Background}, 0.2)
                        end)
                        
                        OptionButton.MouseButton1Click:Connect(function()
                            SelectOption(option)
                        end)
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
                    Size = UDim2.fromOffset(21, 21), -- Auto-sizing width
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
                    BinderBox.Size = UDim2.new(0, math.max(21, textSize.X + 10), 0, 21)
                end)
                
                Create("UICorner", {
                    Parent = BinderBox,
                    CornerRadius = UDim.new(0, 4)
                })
                
                local function SetKeybind(key)
                    Keybind.Value = key
                    BinderBox.Text = key.Name
                    Keybind.Listening = false
                    Tween(BinderBox, {BackgroundColor3 = Theme.Secondary}, 0.2)
                    
                    if options.Callback then
                        options.Callback(key)
                    end
                end
                
                BinderBox.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    BinderBox.Text = "..."
                    Tween(BinderBox, {BackgroundColor3 = Theme.Accent}, 0.2)
                end)
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if Keybind.Listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            SetKeybind(input.KeyCode)
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            SetKeybind(Enum.KeyCode.LeftControl)
                        end
                    else
                        if input.KeyCode == Keybind.Value and options.Callback then
                            options.Callback(Keybind.Value)
                        end
                    end
                end)
                
                function Keybind:SetValue(key)
                    SetKeybind(key)
                end
                
                table.insert(Section.Elements, Keybind)
                table.insert(ExsLibLibrary.Elements, Keybind)
                return Keybind
            end
            
            -- ColorPicker Element
            function Section:CreateColorPicker(options)
                options = options or {}
                local ColorPicker = {
                    Value = options.Default or Color3.fromRGB(255, 255, 255),
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
                    Text = options.Name or "Color Picker",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local ColorCbg = Create("TextButton", {
                    Parent = ColorPickerFrame,
                    BackgroundColor3 = ColorPicker.Value,
                    Size = UDim2.fromOffset(21, 21), -- Color preview
                    Position = UDim2.fromScale(1, 0.5), -- Right center
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
                
                -- Color picker modal (simplified)
                ColorCbg.MouseButton1Click:Connect(function()
                    local colors = {
                        Color3.fromRGB(255, 0, 0),
                        Color3.fromRGB(0, 255, 0),
                        Color3.fromRGB(0, 0, 255),
                        Color3.fromRGB(255, 255, 0),
                        Color3.fromRGB(255, 0, 255),
                        Color3.fromRGB(0, 255, 255)
                    }
                    
                    local currentIndex = table.find(colors, ColorPicker.Value) or 1
                    local nextIndex = (currentIndex % #colors) + 1
                    ColorPicker.Value = colors[nextIndex]
                    ColorCbg.BackgroundColor3 = ColorPicker.Value
                    
                    if options.Callback then
                        options.Callback(ColorPicker.Value)
                    end
                end)
                
                function ColorPicker:SetValue(color)
                    ColorPicker.Value = color
                    ColorCbg.BackgroundColor3 = color
                end
                
                table.insert(Section.Elements, ColorPicker)
                table.insert(ExsLibLibrary.Elements, ColorPicker)
                return ColorPicker
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
                    Size = UDim2.new(1, 0, 0, 38), -- Full width, 38px height
                    LayoutOrder = #Section.Elements + 1
                })
                
                local LabelText = Create("TextLabel", {
                    Parent = LabelFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 0), -- Width: 100% - 20px, Auto height
                    Font = Enum.Font.Gotham,
                    Text = options.Text or "Label",
                    TextColor3 = options.Color or Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
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
                
                local HeaderText = Create("TextLabel", {
                    Parent = HeaderFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 0), -- Width: 100% - 20px, Auto height
                    Font = Enum.Font.GothamSemibold,
                    Text = options.Text or "Header",
                    TextColor3 = options.Color or Theme.Text,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
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
                    Size = UDim2.new(1, 0, 0, 38), -- Full width, 38px height
                    LayoutOrder = #Section.Elements + 1
                })
                
                local ParagraphText = Create("TextLabel", {
                    Parent = ParagraphFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 0), -- Width: 100% - 20px, Auto height
                    Font = Enum.Font.Gotham,
                    Text = options.Text or "Paragraph text goes here...",
                    TextColor3 = options.Color or Theme.SubText,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
                
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
            ScreenGui:Destroy()
            Window.Destroyed = true
            ExsLibLibrary.Windows[Window.Name] = nil
        end
    end
    
    -- Show welcome notification
    delay(1, function()
        ExsLib:Notify({
            Title = "Welcome",
            Content = "Exs Library Loaded Successfully!",
            Duration = 3,
            Type = "Success"
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

-- Utility functions
function ExsLib:GetLibraryVersion()
    return "3.0.0"
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
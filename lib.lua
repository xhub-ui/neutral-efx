-- Rayfield Inspired GUI Library - Extended
-- Created by: [Your Name]

local Rayfield = {}
Rayfield.__index = Rayfield

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Colors and Theme System
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Secondary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(0, 85, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200),
    Error = Color3.fromRGB(255, 85, 85),
    Success = Color3.fromRGB(85, 255, 85),
    Warning = Color3.fromRGB(255, 255, 85)
}

-- Configuration
local Config = {
    EnableNotifications = true,
    MinimizeKey = Enum.KeyCode.RightControl,
    Watermark = true,
    Theme = Theme
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

-- Notification System
local NotificationQueue = {}
local ActiveNotifications = 0
local MaxNotifications = 4

function Rayfield:Notify(options)
    if not Config.EnableNotifications then return end
    
    options = options or {}
    local Notification = {
        Title = options.Title or "Notification",
        Content = options.Content or "",
        Duration = options.Duration or 5,
        Type = options.Type or "Default" -- Default, Success, Error, Warning
    }
    
    table.insert(NotificationQueue, Notification)
    ProcessNotificationQueue()
end

function ProcessNotificationQueue()
    if ActiveNotifications >= MaxNotifications or #NotificationQueue == 0 then return end
    
    local Notification = table.remove(NotificationQueue, 1)
    ActiveNotifications += 1
    
    -- Create notification UI
    local NotificationFrame = Create("Frame", {
        Parent = game.CoreGui,
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(1, 10, 1, -100 - ((ActiveNotifications - 1) * 80)),
        Size = UDim2.new(0, 300, 0, 70),
        AnchorPoint = Vector2.new(1, 1),
        ClipsDescendants = true
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
    
    -- Title
    local Title = Create("TextLabel", {
        Parent = NotificationFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        Font = Enum.Font.GothamSemibold,
        Text = Notification.Title,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Content
    local Content = Create("TextLabel", {
        Parent = NotificationFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 35),
        Size = UDim2.new(1, -30, 0, 25),
        Font = Enum.Font.Gotham,
        Text = Notification.Content,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })
    
    -- Progress bar
    local ProgressBar = Create("Frame", {
        Parent = NotificationFrame,
        BackgroundColor3 = IndicatorColor,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3)
    })
    
    -- Animate in
    Tween(NotificationFrame, {
        Position = UDim2.new(1, -10, 1, -100 - ((ActiveNotifications - 1) * 80))
    }, 0.3)
    
    -- Progress animation
    Tween(ProgressBar, {
        Size = UDim2.new(0, 0, 0, 3)
    }, Notification.Duration, Enum.EasingStyle.Linear)
    
    -- Auto remove
    delay(Notification.Duration, function()
        Tween(NotificationFrame, {
            Position = UDim2.new(1, 10, 1, -100 - ((ActiveNotifications - 1) * 80))
        }, 0.3):andThen(function()
            NotificationFrame:Destroy()
            ActiveNotifications -= 1
            ProcessNotificationQueue()
        end)
    end)
    
    -- Click to dismiss
    NotificationFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(NotificationFrame, {
                Position = UDim2.new(1, 10, 1, -100 - ((ActiveNotifications - 1) * 80))
            }, 0.3):andThen(function()
                NotificationFrame:Destroy()
                ActiveNotifications -= 1
                ProcessNotificationQueue()
            end)
        end
    end)
end

-- Main Window Creation
function Rayfield:CreateWindow(options)
    options = options or {}
    local Window = {
        Tabs = {},
        Minimized = false,
        Destroyed = false
    }
    
    -- ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = options.Name or "RayfieldUI",
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
            Text = options.Name or "Rayfield UI",
            TextColor3 = Theme.Text,
            TextSize = 12
        })
        
        -- FPS Counter
        local FPSLabel = Create("TextLabel", {
            Parent = Watermark,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -40, 0, 0),
            Size = UDim2.new(0, 40, 1, 0),
            Font = Enum.Font.Gotham,
            Text = "0 FPS",
            TextColor3 = Theme.SubText,
            TextSize = 11
        })
        
        local frameCount = 0
        local lastTime = tick()
        
        RunService.Heartbeat:Connect(function()
            frameCount += 1
            local currentTime = tick()
            if currentTime - lastTime >= 1 then
                local fps = math.floor(frameCount / (currentTime - lastTime))
                FPSLabel.Text = fps .. " FPS"
                frameCount = 0
                lastTime = currentTime
            end
        end)
    end
    
    -- Main Frame
    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, -200, 0.5, -150),
        Size = UDim2.new(0, 400, 0, 450),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true
    })
    
    Create("UICorner", {
        Parent = MainFrame,
        CornerRadius = UDim.new(0, 8)
    })
    
    Create("UIStroke", {
        Parent = MainFrame,
        Color = Color3.fromRGB(60, 60, 60),
        Thickness = 1
    })
    
    -- DropShadow (for depth)
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
        Text = options.Name or "Rayfield UI",
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Control Buttons
    local MinimizeButton = Create("TextButton", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 0),
        Size = UDim2.new(0, 35, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "_",
        TextColor3 = Theme.SubText,
        TextSize = 16
    })
    
    local CloseButton = Create("TextButton", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 0),
        Size = UDim2.new(0, 35, 1, 0),
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
        end)
    end)
    
    -- Minimize functionality
    MinimizeButton.MouseButton1Click:Connect(function()
        Window.Minimized = not Window.Minimized
        if Window.Minimized then
            Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 40)}, 0.3)
            MinimizeButton.Text = "+"
        else
            Tween(MainFrame, {Size = UDim2.new(0, 400, 0, 450)}, 0.3)
            MinimizeButton.Text = "_"
        end
    end)
    
    -- Keyboard shortcut for minimize
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Config.MinimizeKey then
            MinimizeButton.MouseButton1Click()
        end
    end)
    
    -- Tabs Container
    local TabsContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = Theme.Secondary,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 120, 1, -40),
        BorderSizePixel = 0,
        ZIndex = 2
    })
    
    -- Content Container
    local ContentContainer = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 120, 0, 40),
        Size = UDim2.new(1, -120, 1, -40),
        ClipsDescendants = true
    })
    
    -- Tabs Layout
    Create("UIListLayout", {
        Parent = TabsContainer,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    -- Make window draggable
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
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
            Parent = TabsContainer,
            BackgroundColor3 = Theme.Secondary,
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, -10, 0, 35),
            Font = Enum.Font.Gotham,
            Text = "  " .. (options.Name or "Tab"),
            TextColor3 = Theme.SubText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        })
        
        Create("UICorner", {
            Parent = TabButton,
            CornerRadius = UDim.new(0, 6)
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
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        
        Create("UIPadding", {
            Parent = TabContent,
            PaddingLeft = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
        
        -- Tab Button Events
        TabButton.MouseEnter:Connect(function()
            if not TabContent.Visible then
                Tween(TabButton, {BackgroundTransparency = 0.3}, 0.2)
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if not TabContent.Visible then
                Tween(TabButton, {BackgroundTransparency = 0.5}, 0.2)
            end
        end)
        
        TabButton.MouseButton1Click:Connect(function()
            -- Hide all tab contents
            for _, existingTab in pairs(Window.Tabs) do
                if existingTab.Content then
                    existingTab.Content.Visible = false
                end
                if existingTab.Button then
                    Tween(existingTab.Button, {
                        BackgroundTransparency = 0.5,
                        TextColor3 = Theme.SubText
                    }, 0.2)
                end
            end
            
            -- Show this tab content
            TabContent.Visible = true
            Tween(TabButton, {
                BackgroundTransparency = 0,
                TextColor3 = Theme.Text
            }, 0.2)
            
            -- Notify tab change
            if options.Callback then
                options.Callback()
            end
        end)
        
        -- Make first tab active by default
        if #Window.Tabs == 0 then
            TabContent.Visible = true
            TabButton.BackgroundTransparency = 0
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
                CornerRadius = UDim.new(0, 6)
            })
            
            Create("UIStroke", {
                Parent = SectionFrame,
                Color = Color3.fromRGB(60, 60, 60),
                Thickness = 1
            })
            
            -- Section Title
            local SectionTitle = Create("TextLabel", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 10),
                Size = UDim2.new(1, -30, 0, 20),
                Font = Enum.Font.GothamSemibold,
                Text = options.Name or "Section",
                TextColor3 = Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            -- Elements Container
            local ElementsContainer = Create("Frame", {
                Parent = SectionFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Create("UIListLayout", {
                Parent = ElementsContainer,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            
            Create("UIPadding", {
                Parent = ElementsContainer,
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10)
            })
            
            Section.Frame = SectionFrame
            Section.ElementsContainer = ElementsContainer
            table.insert(Tab.Sections, Section)
            
            -- Button Element
            function Section:CreateButton(options)
                options = options or {}
                local Button = {}
                
                local ButtonFrame = Create("TextButton", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 35),
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
                
                local ButtonTitle = Create("TextLabel", {
                    Parent = ButtonFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                ButtonFrame.MouseEnter:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}, 0.2)
                end)
                
                ButtonFrame.MouseLeave:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Theme.Background}, 0.2)
                end)
                
                ButtonFrame.MouseButton1Click:Connect(function()
                    RippleEffect(ButtonFrame)
                    if options.Callback then
                        options.Callback()
                    end
                end)
                
                function Button:SetText(text)
                    ButtonTitle.Text = text
                end
                
                table.insert(Section.Elements, Button)
                return Button
            end
            
            -- Toggle Element
            function Section:CreateToggle(options)
                options = options or {}
                local Toggle = {
                    Value = options.Default or false
                }
                
                local ToggleFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 35),
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
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.7, -10, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Toggle",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local ToggleButton = Create("TextButton", {
                    Parent = ToggleFrame,
                    BackgroundColor3 = Color3.fromRGB(80, 80, 80),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    AnchorPoint = Vector2.new(1, 0.5),
                    AutoButtonColor = false,
                    Text = ""
                })
                
                Create("UICorner", {
                    Parent = ToggleButton,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local ToggleDot = Create("Frame", {
                    Parent = ToggleButton,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    AnchorPoint = Vector2.new(0, 0.5)
                })
                
                Create("UICorner", {
                    Parent = ToggleDot,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(ToggleButton, {BackgroundColor3 = Theme.Accent}, 0.2)
                        Tween(ToggleDot, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.2)
                    else
                        Tween(ToggleButton, {BackgroundColor3 = Color3.fromRGB(80, 80, 80)}, 0.2)
                        Tween(ToggleDot, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
                    end
                    
                    if options.Callback then
                        options.Callback(Toggle.Value)
                    end
                end
                
                ToggleButton.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    UpdateToggle()
                end)
                
                function Toggle:SetValue(value)
                    Toggle.Value = value
                    UpdateToggle()
                end
                
                UpdateToggle()
                
                table.insert(Section.Elements, Toggle)
                return Toggle
            end
            
            -- Slider Element
            function Section:CreateSlider(options)
                options = options or {}
                local Slider = {
                    Value = options.Default or options.Min or 0
                }
                
                local SliderFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 60),
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
                    Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(1, -20, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Slider",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local ValueLabel = Create("TextLabel", {
                    Parent = SliderFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0, 5),
                    Size = UDim2.new(0, 50, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = tostring(Slider.Value),
                    TextColor3 = Theme.SubText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Right
                })
                
                local SliderTrack = Create("Frame", {
                    Parent = SliderFrame,
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                    Position = UDim2.new(0, 10, 0, 35),
                    Size = UDim2.new(1, -20, 0, 5)
                })
                
                Create("UICorner", {
                    Parent = SliderTrack,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local SliderFill = Create("Frame", {
                    Parent = SliderTrack,
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 0, 1, 0)
                })
                
                Create("UICorner", {
                    Parent = SliderFill,
                    CornerRadius = UDim.new(1, 0)
                })
                
                local SliderButton = Create("TextButton", {
                    Parent = SliderTrack,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 2, 0),
                    Position = UDim2.new(0, 0, -0.5, 0),
                    Text = "",
                    ZIndex = 2
                })
                
                local min = options.Min or 0
                local max = options.Max or 100
                local current = Slider.Value
                
                local function UpdateSlider(value)
                    current = math.clamp(value, min, max)
                    local percentage = (current - min) / (max - min)
                    
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    ValueLabel.Text = tostring(math.floor(current))
                    Slider.Value = current
                    
                    if options.Callback then
                        options.Callback(current)
                    end
                end
                
                local connection
                SliderButton.MouseButton1Down:Connect(function()
                    connection = RunService.Heartbeat:Connect(function()
                        local mousePos = UserInputService:GetMouseLocation()
                        local trackAbsolutePos = SliderTrack.AbsolutePosition
                        local trackAbsoluteSize = SliderTrack.AbsoluteSize
                        
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
                return Slider
            end
            
            -- Dropdown Element
            function Section:CreateDropdown(options)
                options = options or {}
                local Dropdown = {
                    Value = options.Default or options.Options[1],
                    Options = options.Options or {"Option 1", "Option 2"},
                    Open = false
                }
                
                local DropdownFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 35),
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
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.7, -10, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Dropdown",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local CurrentValue = Create("TextLabel", {
                    Parent = DropdownFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -30, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = "▼",
                    TextColor3 = Theme.SubText,
                    TextSize = 12
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
                    AutomaticCanvasSize = Enum.AutomaticSize.Y
                })
                
                Create("UICorner", {
                    Parent = DropdownList,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIListLayout", {
                    Parent = DropdownList,
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                local function ToggleDropdown()
                    Dropdown.Open = not Dropdown.Open
                    
                    if Dropdown.Open then
                        DropdownList.Visible = true
                        Tween(DropdownList, {Size = UDim2.new(1, 0, 0, math.min(#Dropdown.Options * 35, 105))}, 0.3)
                        Tween(CurrentValue, {Rotation = 180}, 0.3)
                    else
                        Tween(DropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.3):andThen(function()
                            DropdownList.Visible = false
                        end)
                        Tween(CurrentValue, {Rotation = 0}, 0.3)
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
                        Font = Enum.Font.Gotham
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
                            Font = Enum.Font.Gotham
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
                return Dropdown
            end
            
            -- TextBox Element
            function Section:CreateTextBox(options)
                options = options or {}
                local TextBox = {
                    Value = options.Default or ""
                }
                
                local TextBoxFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 35),
                    LayoutOrder = #Section.Elements + 1
                })
                
                Create("UICorner", {
                    Parent = TextBoxFrame,
                    CornerRadius = UDim.new(0, 6)
                })
                
                Create("UIStroke", {
                    Parent = TextBoxFrame,
                    Color = Color3.fromRGB(60, 60, 60),
                    Thickness = 1
                })
                
                local TextBoxTitle = Create("TextLabel", {
                    Parent = TextBoxFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.4, -10, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Text Box",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local InputBox = Create("TextBox", {
                    Parent = TextBoxFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(0.4, 5, 0.5, -12),
                    Size = UDim2.new(0.6, -15, 0, 24),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = options.Default or "",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    PlaceholderText = options.Placeholder or "Enter text...",
                    PlaceholderColor3 = Theme.SubText,
                    ClearTextOnFocus = false
                })
                
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
                return TextBox
            end
            
            -- Keybind Element
            function Section:CreateKeybind(options)
                options = options or {}
                local Keybind = {
                    Value = options.Default or Enum.KeyCode.Unknown,
                    Listening = false
                }
                
                local KeybindFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 35),
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
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.7, -10, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Name or "Keybind",
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local KeybindButton = Create("TextButton", {
                    Parent = KeybindFrame,
                    BackgroundColor3 = Theme.Secondary,
                    Position = UDim2.new(1, -80, 0.5, -12),
                    Size = UDim2.new(0, 70, 0, 24),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Font = Enum.Font.Gotham,
                    Text = Keybind.Value.Name,
                    TextColor3 = Theme.Text,
                    TextSize = 14,
                    AutoButtonColor = false
                })
                
                Create("UICorner", {
                    Parent = KeybindButton,
                    CornerRadius = UDim.new(0, 4)
                })
                
                local function SetKeybind(key)
                    Keybind.Value = key
                    KeybindButton.Text = key.Name
                    Keybind.Listening = false
                    Tween(KeybindButton, {BackgroundColor3 = Theme.Secondary}, 0.2)
                    
                    if options.Callback then
                        options.Callback(key)
                    end
                end
                
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    KeybindButton.Text = "..."
                    Tween(KeybindButton, {BackgroundColor3 = Theme.Accent}, 0.2)
                end)
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if Keybind.Listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            SetKeybind(input.KeyCode)
                            connection:Disconnect()
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
                return Keybind
            end
            
            -- Label Element
            function Section:CreateLabel(options)
                options = options or {}
                local Label = {}
                
                local LabelFrame = Create("Frame", {
                    Parent = ElementsContainer,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 25),
                    LayoutOrder = #Section.Elements + 1
                })
                
                local LabelText = Create("TextLabel", {
                    Parent = LabelFrame,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = options.Text or "Label",
                    TextColor3 = options.Color or Theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                function Label:SetText(text)
                    LabelText.Text = text
                end
                
                function Label:SetColor(color)
                    LabelText.TextColor3 = color
                end
                
                table.insert(Section.Elements, Label)
                return Label
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
        end
    end
    
    -- Show notification example
    delay(1, function()
        Rayfield:Notify({
            Title = "Welcome",
            Content = "Rayfield UI Loaded Successfully!",
            Duration = 3,
            Type = "Success"
        })
    end)
    
    return Window
end

-- Configuration functions
function Rayfield:SetTheme(newTheme)
    for key, value in pairs(newTheme) do
        if Theme[key] then
            Theme[key] = value
        end
    end
end

function Rayfield:GetConfiguration()
    return Config
end

function Rayfield:SetConfiguration(newConfig)
    for key, value in pairs(newConfig) do
        if Config[key] ~= nil then
            Config[key] = value
        end
    end
end

return Rayfield

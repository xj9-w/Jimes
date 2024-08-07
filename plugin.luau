local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

local Gui = script.Parent

local MainFrame = Gui.Frame

local LogsFrame = MainFrame.Logs
local LogsFolder = LogsFrame.LogsFolder
local LogTemplate = LogsFrame.Template

local MaxLogs = 9 -- Maximum amount logs to be displayed to prevent UI overflow

local AutoSave = 60 * 10 -- The time in seconds before auto saving
local IdleTime = 10 -- The time in seconds before going idle, used to avoid over counting 

local PluginName = "Jimes"
local JimeUrl = "https://jime.glitch.me/"
local JimeKey = script.Key.Value

local SourceChanged = nil
local LastScriptChange = nil
local ActiveTimeQueue = 0

local PluginButton = plugin:CreateToolbar(PluginName)
	:CreateButton(
		PluginName,
		PluginName, 
		"http://www.roblox.com/asset/?id=18826342940"
	)

local Widget  = plugin:CreateDockWidgetPluginGui(PluginName, DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false
	)
)

MainFrame.Parent = Widget
Widget.Title = PluginName

PluginButton.Click:Connect(function()
	Widget.Enabled = not Widget.Enabled
end)

local function GetResult(Function)
	local Success, Result = pcall(Function)
	return Result
end

local function FormatValue(Number)
	return string.format("%02i:%02i:%02i", 
		Number / 3600, -- hour
		Number % 3600 / 60, -- minute
		Number % 60 -- seconds
	)
	-- %02s means if the value's length is less than 2, it will fill it with 0's
end

local function AddLog(Value)
	local ListedLogs = LogsFolder:GetChildren()

	if #ListedLogs - 1 >= MaxLogs then
		local Destroyed = false

		for i, ListedLog in ListedLogs do
			if ListedLog.Name ~= "Log" then
				continue
			end

			ListedLog.LayoutOrder += 1
			if not Destroyed and ListedLog.LayoutOrder >= MaxLogs then
				ListedLog:Destroy()
				Destroyed = true
			end
		end
	end

	local StatusColor = Color3.new(1)

	if tonumber(Value) then
		StatusColor = Color3.new(0.25, 0.9)
	elseif Value == "invalid request" then
		StatusColor = Color3.new(1, 0.4, 0.4)
	elseif not Value then
		StatusColor = Color3.new(1, 0.5)
	end

	local NewLog = LogTemplate:Clone()
	NewLog.Value.Text = Value
	NewLog.Time.Text = FormatValue(tick() % 86400)
	NewLog.Status.BackgroundColor3 = StatusColor

	NewLog.Name = "Log"
	NewLog.Visible = true
	NewLog.LayoutOrder = MaxLogs - (#ListedLogs - 1)
	NewLog.Parent = LogsFolder
end

local function SetJimeText(Jime)
	if not tonumber(Jime) then
		PluginButton.Enabled = false
		error(`Error encountered! {Jime}`)
	end

	MainFrame.Time.Text = FormatValue(Jime)
	AddLog(Jime)
end

local function AddJime()
	if ActiveTimeQueue <= 0 then 
		return
	end

	local Result = GetResult(function()
		return HttpService:PostAsync(JimeUrl, 
			`\{"Key":"{JimeKey}","Add":{ActiveTimeQueue}\}`
		)
	end)

	SetJimeText(Result)
	ActiveTimeQueue = 0
end

local function ScriptChanged()
	if not LastScriptChange then
		LastScriptChange = tick()
		return
	end

	ActiveTimeQueue += math.min(IdleTime, tick() - LastScriptChange)
	LastScriptChange = tick()
end

local function ScriptActive()
	if SourceChanged then
		SourceChanged:Disconnect()
		SourceChanged = nil
	end 
	LastScriptChange = nil

	if not StudioService.ActiveScript then
		return 
	end

	SourceChanged = StudioService.ActiveScript.Changed:Connect(ScriptChanged)
end

SetJimeText(GetResult(function()
	return HttpService:GetAsync(JimeUrl)
end))

ScriptActive()
StudioService:GetPropertyChangedSignal("ActiveScript"):Connect(ScriptActive)

MainFrame.Save.MouseButton1Click:Connect(AddJime)
plugin.Unloading:Connect(AddJime)

local AutosaveThread = coroutine.wrap(function()
	while PluginButton.Enabled do
		AddJime()
		task.wait(AutoSave)
	end
end)
AutosaveThread()

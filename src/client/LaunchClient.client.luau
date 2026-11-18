local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local Config = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")
local Audio=require(RS:WaitForChild("IslandAudio"))
local Rules=require(RS:WaitForChild("ExpeditionRules"))
local pullStart,pullDuration
local cam = workspace.CurrentCamera

local S = nil
local running, pending = false, false
local startX = 0
local camPos = nil
local shakeUntil = 0
local fovKick = 0


local WHITE = Color3.new(1,1,1)
local GOLD = Color3.fromRGB(255,220,50)

local function fmt(n)
 if n > 0 and n < 1000 and n % 1 ~= 0 then return string.format("%.2f",n) end
	local units = {"", "K", "M", "B", "T", "Qa"}
	local i = 1
	while n >= 1000 and i < #units do n = n / 1000; i += 1 end
	if i == 1 then return tostring(math.floor(n)) end
	return string.format("%.1f%s", n, units[i])
end

local gui = Instance.new("ScreenGui")
gui.Name = "LaunchGui"; gui.ResetOnSpawn = false; gui.Parent = plr:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 12); c.Parent = o end
local function stroke(o, th, col) local s = Instance.new("UIStroke"); s.Thickness = th or 2; if col then s.Color = col end; s.Parent = o; return s end
local function lbl(parent, name, size, pos, anchor, color, align)
	local l = Instance.new("TextLabel")
	l.Name = name; l.Size = size; l.Position = pos; l.AnchorPoint = anchor or Vector2.new(0,0)
	l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.TextScaled = true
	l.TextColor3 = color or WHITE; l.TextStrokeTransparency = 0.3
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end
local function button(parent, name, text, size, pos, anchor, color)
	local b = Instance.new("TextButton")
	b.Name = name; b.Size = size; b.Position = pos; b.AnchorPoint = anchor or Vector2.new(0,0)
	b.BackgroundColor3 = color; b.Text = ""; b.AutoButtonColor = true; b.Parent = parent
	corner(b, 14); stroke(b, 1.6, Color3.fromRGB(55,64,85))
 local gradient=Instance.new("UIGradient"); gradient.Rotation=85; gradient.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(199,204,218)); gradient.Parent=b
 local scale=Instance.new("UIScale"); scale.Parent=b
 local function hover(value) TS:Create(scale,TweenInfo.new(0.13,Enum.EasingStyle.Quad),{Scale=value}):Play() end
 b.MouseEnter:Connect(function() hover(1.025) end); b.MouseLeave:Connect(function() hover(1) end)
 b.MouseButton1Down:Connect(function() hover(0.965) end); b.Activated:Connect(function() hover(1); Audio.Effect("click") end)
	local t = Instance.new("TextLabel"); t.Name = "T"; t.Size = UDim2.new(1,-10,1,-8); t.Position = UDim2.new(0,5,0,4)
	t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = WHITE; t.Text = text; t.Parent = b
 local cap=Instance.new("UITextSizeConstraint"); cap.MinTextSize=8; cap.MaxTextSize=name=="Launch" and 23 or 16; cap.Parent=t
	return b
end

-- ============ HUD ============
local statusCard=Instance.new("Frame"); statusCard.Name="StatusCard"; statusCard.Size=UDim2.fromOffset(254,120); statusCard.Position=UDim2.fromOffset(12,8)
statusCard.BackgroundColor3=Color3.fromRGB(23,39,46); statusCard.BackgroundTransparency=0.10; statusCard.BorderSizePixel=0; statusCard.Parent=gui
corner(statusCard,13); stroke(statusCard,1,Color3.fromRGB(105,150,142))
local coinsL = lbl(gui, "Coins", UDim2.new(0,300,0,42), UDim2.new(0,16,0,10), nil, GOLD)
local incomeL = lbl(gui, "Income", UDim2.new(0,300,0,26), UDim2.new(0,16,0,54), nil, Color3.fromRGB(150,255,170))
local levelL = lbl(gui, "Level", UDim2.new(0,300,0,30), UDim2.new(0,16,0,84), nil, Color3.fromRGB(255,130,230))
local barBg = Instance.new("Frame"); barBg.Size = UDim2.new(0,260,0,12); barBg.Position = UDim2.new(0,16,0,118)
barBg.BackgroundColor3 = Color3.fromRGB(50,40,80); barBg.Parent = gui; corner(barBg, 6)
local barFill = Instance.new("Frame"); barFill.Size = UDim2.new(0,0,1,0); barFill.BackgroundColor3 = Color3.fromRGB(255,130,230); barFill.Parent = barBg; corner(barFill, 6)
local nextL = lbl(gui, "Next", UDim2.new(0,300,0,22), UDim2.new(0,16,0,134), nil, Color3.fromRGB(200,200,230))
local locL = lbl(gui, "Loc", UDim2.new(0,300,0,24), UDim2.new(0,16,0,158), nil, Color3.fromRGB(165,205,194))

for _,o in ipairs({coinsL,incomeL,levelL,barBg,nextL,locL}) do o.Parent=statusCard end
local function statStyle(label,size,position,fontSize,color)
 label.Size=UDim2.fromOffset(size.X,size.Y); label.Position=UDim2.fromOffset(position.X,position.Y)
 label.TextScaled=false; label.TextSize=fontSize; label.TextColor3=color; label.TextStrokeTransparency=1
end
statStyle(coinsL,Vector2.new(145,30),Vector2.new(12,4),22,Color3.fromRGB(255,218,135))
statStyle(levelL,Vector2.new(86,25),Vector2.new(158,7),13,Color3.fromRGB(183,222,203))
statStyle(incomeL,Vector2.new(230,20),Vector2.new(12,35),13,Color3.fromRGB(217,226,217))
statStyle(nextL,Vector2.new(230,18),Vector2.new(12,59),13,Color3.fromRGB(204,225,222))
statStyle(locL,Vector2.new(230,19),Vector2.new(12,93),12,Color3.fromRGB(166,194,202))
barBg.Position=UDim2.fromOffset(12,83); barBg.Size=UDim2.fromOffset(230,4); barBg.BackgroundColor3=Color3.fromRGB(53,82,87); barFill.BackgroundColor3=Color3.fromRGB(104,223,183)
local runL = lbl(gui, "RunInfo", UDim2.new(0.8,0,0,38), UDim2.new(0.5,0,0,10), Vector2.new(0.5,0), WHITE, Enum.TextXAlignment.Center)
local toast = lbl(gui, "Toast", UDim2.new(0.8,0,0,32), UDim2.new(0.5,0,0.12,0), Vector2.new(0.5,0.5), WHITE, Enum.TextXAlignment.Center)
toast.TextScaled=false; toast.TextSize=18; toast.TextTransparency = 1; toast.TextStrokeTransparency = 1
runL.TextScaled=false; runL.TextSize=24
local popup = lbl(gui, "Popup", UDim2.new(0.8,0,0,100), UDim2.new(0.5,0,0.34,0), Vector2.new(0.5,0.5), WHITE, Enum.TextXAlignment.Center)
local sub = lbl(gui, "Sub", UDim2.new(0.7,0,0,44), UDim2.new(0.5,0,0.34,60), Vector2.new(0.5,0), GOLD, Enum.TextXAlignment.Center)
local sub2 = lbl(gui, "Sub2", UDim2.new(0.7,0,0,38), UDim2.new(0.5,0,0.34,106), Vector2.new(0.5,0), Color3.fromRGB(120,255,160), Enum.TextXAlignment.Center)
for _, l in ipairs({popup, sub, sub2}) do l.TextTransparency = 1; l.TextStrokeTransparency = 1; l.ZIndex = 20 end
local resultCard=Instance.new("Frame"); resultCard.Name="ResultCard"; resultCard.AnchorPoint=Vector2.new(0.5,0.5); resultCard.Position=UDim2.fromScale(0.5,0.36); resultCard.Size=UDim2.new(0.84,0,0,134); resultCard.BackgroundColor3=Color3.fromRGB(22,40,48); resultCard.BackgroundTransparency=0.05; resultCard.BorderSizePixel=0; resultCard.Visible=false; resultCard.ZIndex=19; resultCard.Parent=gui
local resultLimit=Instance.new("UISizeConstraint"); resultLimit.MaxSize=Vector2.new(470,134); resultLimit.Parent=resultCard; corner(resultCard,18); stroke(resultCard,1.5,Color3.fromRGB(126,193,166))
for i,v in ipairs({popup,sub,sub2}) do
 v.Parent=resultCard; v.AnchorPoint=Vector2.zero; v.Position=UDim2.fromOffset(12,({8,62,98})[i]); v.Size=UDim2.new(1,-24,0,i==1 and 50 or 26); v.TextStrokeTransparency=1
 local cap=Instance.new("UITextSizeConstraint"); cap.MinTextSize=9; cap.MaxTextSize=i==1 and 30 or 16; cap.Parent=v
end
local popupToken = 0

local function showToast(text, color)
	toast.Text = text; toast.TextColor3 = color or WHITE
	toast.TextTransparency = 0; toast.TextStrokeTransparency = 0
	toast.Position = UDim2.new(0.5,0,0.2,10)
	TS:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = UDim2.new(0.5,0,0.2,0)}):Play()
	local my = os.clock(); toast:SetAttribute("t", my)
	task.delay(1.1, function()
		if toast:GetAttribute("t") == my then
			TS:Create(toast, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

local function showPopup(title, l1, l2, color, hold)
	popupToken += 1
 resultCard.Visible=true
	local my = popupToken
	popup.Text = title; popup.TextColor3 = color or WHITE
	sub.Text = l1 or ""; sub2.Text = l2 or ""
	for _, l in ipairs({popup, sub, sub2}) do l.TextTransparency = 0; l.TextStrokeTransparency = 0 end
	popup.Rotation = -8
	TS:Create(popup, TweenInfo.new(0.45, Enum.EasingStyle.Elastic), {Rotation = 0}):Play()
	task.delay(hold or 3, function()
		if popupToken ~= my then return end
  task.delay(0.45,function() if popupToken==my then resultCard.Visible=false end end)
		for _, l in ipairs({popup, sub, sub2}) do
			TS:Create(l, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end
	end)
end

-- main buttons
local launchB = button(gui, "Launch", "ЗАПУСК", UDim2.new(0,182,0,54), UDim2.new(0.5,0,1,-22), Vector2.new(0.5,1), Color3.fromRGB(57,135,106))
local shopB = button(gui, "ShopB", "УЛУЧШЕНИЯ", UDim2.new(0,133,0,42), UDim2.new(0,16,0.4,0), nil, Color3.fromRGB(184,137,74))
local zooB = button(gui, "ZooB", "ЗООПАРК", UDim2.new(0,133,0,42), UDim2.new(0,16,0.4,70), nil, Color3.fromRGB(65,134,112))
local mapB = button(gui, "MapB", "МИРЫ", UDim2.new(0,133,0,42), UDim2.new(0,16,0.4,140), nil, Color3.fromRGB(65,105,143))

local journalB=button(gui,"Journal","ДНЕВНИК",UDim2.fromOffset(112,36),UDim2.new(1,-14,0,14),Vector2.new(1,0),Color3.fromRGB(75,88,132))
local settingsB=button(gui,"Settings","ЗВУК",UDim2.fromOffset(100,36),UDim2.new(1,-14,0,61),Vector2.new(1,0),Color3.fromRGB(69,92,108))
local trickB=button(gui,"Trick",UIS.TouchEnabled and "САЛЬТО" or "ПРОБЕЛ • ТРЮК",UDim2.fromOffset(110,52),UDim2.new(0.5,0,1,-22),Vector2.new(0.5,1),Color3.fromRGB(57,135,106))
trickB.Visible=false
trickB.Activated:Connect(function() if running then Remotes.Trick:FireServer() end end)
local leftB = button(gui, "SteerL", "<<", UDim2.new(0,84,0,84), UDim2.new(0,24,1,-24), Vector2.new(0,1), Color3.fromRGB(40,40,70))
local rightB = button(gui, "SteerR", ">>", UDim2.new(0,84,0,84), UDim2.new(1,-24,1,-24), Vector2.new(1,1), Color3.fromRGB(40,40,70))
leftB.BackgroundTransparency = 0.4; rightB.BackgroundTransparency = 0.4
leftB.Visible = false; rightB.Visible = false

-- ============ STEERING ============
local keyL, keyR, btnL, btnR = false, false, false, false
local lastSent = nil
local function pushSteer()
	local s = ((keyR or btnR) and 1 or 0) - ((keyL or btnL) and 1 or 0)
	if s ~= lastSent then lastSent = s; Remotes.Steer:FireServer(s) end
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
UIS.InputBegan:Connect(function(i, gp)
 if running and i.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then Remotes.Trick:FireServer(); return end
 if gp then return end
	if i.KeyCode == Enum.KeyCode.A or i.KeyCode == Enum.KeyCode.Left then keyL = true; pushSteer()
	elseif i.KeyCode == Enum.KeyCode.D or i.KeyCode == Enum.KeyCode.Right then keyR = true; pushSteer() end
end)
UIS.InputEnded:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.A or i.KeyCode == Enum.KeyCode.Left then keyL = false; pushSteer()
	elseif i.KeyCode == Enum.KeyCode.D or i.KeyCode == Enum.KeyCode.Right then keyR = false; pushSteer() end
end)
leftB.InputBegan:Connect(function(i) if isPress(i) then btnL = true; pushSteer() end end)
leftB.InputEnded:Connect(function(i) if isPress(i) then btnL = false; pushSteer() end end)
rightB.InputBegan:Connect(function(i) if isPress(i) then btnR = true; pushSteer() end end)
rightB.InputEnded:Connect(function(i) if isPress(i) then btnR = false; pushSteer() end end)

-- ============ PANEL ============
local panel = Instance.new("Frame")
panel.Name = "Panel"; panel.Size = UDim2.new(0,620,0,440); panel.Position = UDim2.new(0.5,0,0.5,0); panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.BackgroundColor3 = Color3.fromRGB(20,31,39); panel.Visible = false; panel.Parent = gui
local panelScale=Instance.new("UIScale"); panelScale.Parent=panel
 local function resizePanel() panelScale.Scale=math.min(1,(cam.ViewportSize.X-24)/620,(cam.ViewportSize.Y-40)/440) end
 cam:GetPropertyChangedSignal("ViewportSize"):Connect(resizePanel); resizePanel()
 corner(panel, 18); stroke(panel, 3, Color3.fromRGB(165,205,194))
local title = lbl(panel, "Title", UDim2.new(1,-90,0,46), UDim2.new(0,16,0,8), nil, GOLD)
local closeB = button(panel, "Close", "X", UDim2.new(0,46,0,40), UDim2.new(1,-12,0,10), Vector2.new(1,0), Color3.fromRGB(220,60,70))
local list = Instance.new("ScrollingFrame")
list.Name = "List"; list.Size = UDim2.new(1,-24,1,-70); list.Position = UDim2.new(0,12,0,60)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 8
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.CanvasSize = UDim2.new(0,0,0,0); list.Parent = panel
local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0,8); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = list

local currentTab = nil
local currentCase=nil
local selectedPodium=nil
local lastSig = ""

local function row(h)
	local f = Instance.new("Frame"); f.Size = UDim2.new(1,-10,0,h); f.BackgroundColor3 = Color3.fromRGB(34,47,57); f.BorderSizePixel = 0
	f.LayoutOrder = #list:GetChildren(); f.Parent = list; corner(f, 12)
	return f
end
local function header(text)
	local l = lbl(list, "H", UDim2.new(1,-10,0,30), UDim2.new(0,0,0,0), nil, Color3.fromRGB(165,205,194))
	l.Text = text; l.LayoutOrder = #list:GetChildren()
end
local function rowButton(parent, text, color, x, w, enabled, cb)
	local b = button(parent, "B", text, UDim2.new(w,-8,1,-16), UDim2.new(x,0,0,8), nil, color)
	b.BackgroundTransparency = enabled and 0 or 0.55
	b.Activated:Connect(function() if enabled then cb() end end)
	return b
end

local function nowEst() return S.now + (os.clock() - S.t0) end
local function can(cost) return S.coins >= cost end

local function sortedAnimals()
	local out = {}
	for _, a in ipairs(S.animals) do
		local def = Config.AnimalById[a.id]
		if def then table.insert(out, {a = a, def = def}) end
	end
	table.sort(out, function(x, y)
		local rx, ry = Config.RarityIndex[x.def.rarity], Config.RarityIndex[y.def.rarity]
		if rx ~= ry then return rx > ry end
		return x.def.name < y.def.name
	end)
	return out
end

local function signature()
	if not S then return "" end
	local p = {S.music,S.effects,S.theme,tostring(S.glow),S.cupUntil>S.now and 1 or 0,S.totalDistance,S.daily.day,S.daily.runs,S.lastGift or 0,S.cupUntil,can(120) and 1 or 0,tostring(S.daily.claimed.runs),tostring(S.daily.claimed.meters),tostring(S.daily.claimed.tricks),S.slots or 6, currentTab or "-", S.power, S.slide, S.level, S.loc, S.trail, can(Config.PowerCost(S.power)) and 1 or 0, can(Config.SlideCost(S.slide)) and 1 or 0}
	for _,id in ipairs(Rules.TrainingOrder) do local n=S.training[id] or 0; table.insert(p,id..n..tostring(can(Rules.TrainingCost(id,n)))) end
 for _,id in ipairs(Rules.ThemeOrder) do table.insert(p,tostring(can(Rules.Themes[id].cost))) end
 for _,id in ipairs(Rules.CakeOrder) do table.insert(p,tostring(can(Rules.Cakes[id].price))) end
 for _,c in ipairs(Config.Cases[S.loc]) do p[#p+1]=can(c.price) and "yes" or "no" end
 p[#p+1]=can(Config.SlotCost(S.slots or 6)) and "slot" or "-"
 for _, t in ipairs(Config.Trails) do p[#p+1] = (S.trails[t.id] and "o" or (can(t.cost) and "y" or "n")) end
	for _, e in ipairs(sortedAnimals()) do
		local boosted = (e.a.bu or 0) > nowEst()
		p[#p+1] = e.a.id .. ":" .. tostring(e.a.podium) .. ":" .. e.a.lvl .. ":" .. (boosted and "B" or "-") .. (can(Config.AnimalUpCost(e.def, e.a.lvl)) and "u" or "") .. (can(Config.AnimalBoostCost(e.def, e.a.lvl)) and "b" or "")
	end
	return table.concat(p, "|")
end

local function build()
	if not S or not currentTab then return end
	local keep = list.CanvasPosition
	for _, c in ipairs(list:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	if currentTab=="Settings" then
  title.Text="Настройки звука"
  for _,key in ipairs({"music","effects"}) do
   header(key=="music" and "Музыка острова" or "Игровые эффекты")
   local r=row(58)
   for i,vol in ipairs({0,0.35,0.75,1}) do
    rowButton(r,S[key]==vol and ("✓ "..tostring(math.round(vol*100)).."%") or (tostring(math.round(vol*100)).."%"),Color3.fromRGB(75,117,124),(i-1)/4,0.25,S[key]~=vol,function() Remotes.Action:FireServer(key,vol) end)
   end
  end
 elseif currentTab=="Home" then
  title.Text="Мой дом"
  header("Мест "..S.slots.." / "..Config.MAX_SLOTS.."   •   Этажей "..math.ceil(S.slots/10).." / 3")
  rowButton(row(48),"Ко входу",Color3.fromRGB(61,129,115),0,1,true,function() Remotes.Action:FireServer("Home"); panel.Visible=false; currentTab=nil end)
  rowButton(row(45),"Подсветка  •  "..(S.glow and "Вкл" or "Выкл"),Color3.fromRGB(74,120,136),0,1,true,function() Remotes.Action:FireServer("Glow") end)
  for _,id in ipairs(Rules.ThemeOrder) do
   local theme=Rules.Themes[id]
   rowButton(row(46),theme.name.."   •   "..(S.theme==id and "Выбрано" or S.themes[id] and "Применить" or fmt(theme.cost).." монет"),theme.wall,0,1,S.theme~=id and (S.themes[id] or can(theme.cost)),function() Remotes.Action:FireServer("Theme",id) end)
  end
  rowButton(row(46),"Вернуться на площадь",Color3.fromRGB(65,105,143),0,1,true,function() Remotes.Action:FireServer("Spawn"); panel.Visible=false; currentTab=nil end)
  header("Этажи открываются с 11-го и 21-го места")
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=plr and other:GetAttribute("Island")==S.loc then
    rowButton(row(46),"В гости к "..other.DisplayName,Color3.fromRGB(76,106,134),0,1,true,function() Remotes.Action:FireServer("Visit",other.UserId); panel.Visible=false; currentTab=nil end)
   end
  end
 elseif currentTab=="Bakery" then
  title.Text="Кондитерская"
  local active=S.cupUntil>S.now
  header(active and ("Действует кекс • "..Rules.Cakes[S.cake].name) or "Один кекс действует 5 минут")
  for _,id in ipairs(Rules.CakeOrder) do
   local cake=Rules.Cakes[id]
   rowButton(row(58),cake.name.."   •   "..cake.effect.."   •   "..cake.price,cake.color,0,1,can(cake.price) and not active,function() Remotes.Action:FireServer("Cupcake",id) end)
  end
 elseif currentTab=="Journal" then
  title.Text="Дневник экспедиции"
  header("Всего "..fmt(S.totalDistance).." м  •  "..S.tricks.." трюков")
  local claimed=S.lastGift==S.daily.day
  rowButton(row(56),claimed and ("День "..S.streak.." • подарок получен") or "Забрать ежедневный подарок",GOLD,0,1,not claimed,function() Remotes.Action:FireServer("Gift") end)
  header("Задания до полуночи UTC")
  local names={runs="Заезды",meters="Метры",tricks="Трюки"}
  for _,key in ipairs({"runs","meters","tricks"}) do
   local goal=Rules.DailyGoals[key]
   local taken=S.daily.claimed[key]
   local text=names[key].."  "..math.min(S.daily[key],goal).."/"..goal.."   •   "..(taken and "Получено" or ("+"..Rules.DailyPrizes[key].." монет"))
   rowButton(row(48),text,Color3.fromRGB(65,134,112),0,1,not taken and S.daily[key]>=goal,function() Remotes.Action:FireServer("Quest",key) end)
  end
  header("Тайники на трассе • 25/60/140/350 монет × ставка мира")
  header("Шансы: 65% / 25% / 8% / 2%")
  header("Награды за достижения выдаются автоматически")
  for _,entry in ipairs({{"first","Первый запуск"},{"km","Первый километр"},{"explorer","10 000 м"},{"moon","50 000 м"},{"voyager","100 000 м"},{"acrobat","100 трюков"},{"legend","1 000 трюков"}}) do
   header((S.achievements[entry[1]] and "✓  " or "·  ")..entry[2])
  end
 elseif currentTab == "Shop" then
		title.Text = "Мастерская"
		header("УЛУЧШЕНИЯ")
		local r = row(70)
		local t1 = lbl(r, "N", UDim2.new(0.55,0,0.55,0), UDim2.new(0,12,0,4), nil, WHITE)
		t1.Text = "СИЛА РОГАТКИ  •  " .. S.power .. "/" .. Config.MAX_POWER
		local t2 = lbl(r, "D", UDim2.new(0.55,0,0.35,0), UDim2.new(0,12,0.6,0), nil, Color3.fromRGB(200,200,230))
		t2.Text = "+12 к начальной скорости"
		if S.power >= Config.MAX_POWER then rowButton(r, "MAX", Color3.fromRGB(90,90,110), 0.6, 0.38, false, function() end)
		else local c = Config.PowerCost(S.power); rowButton(r, "КУПИТЬ   " .. fmt(c), Color3.fromRGB(184,137,74), 0.6, 0.38, can(c), function() Remotes.Action:FireServer("Power") end) end

		r = row(70)
		t1 = lbl(r, "N", UDim2.new(0.55,0,0.55,0), UDim2.new(0,12,0,4), nil, WHITE)
		t1.Text = "СКОЛЬЖЕНИЕ  •  " .. S.slide .. "/" .. Config.MAX_SLIDE
		t2 = lbl(r, "D", UDim2.new(0.55,0,0.35,0), UDim2.new(0,12,0.6,0), nil, Color3.fromRGB(200,200,230))
		t2.Text = "Меньше трения на трассе"
		if S.slide >= Config.MAX_SLIDE then rowButton(r, "MAX", Color3.fromRGB(90,90,110), 0.6, 0.38, false, function() end)
		else local c = Config.SlideCost(S.slide); rowButton(r, "КУПИТЬ   " .. fmt(c), Color3.fromRGB(255,110,160), 0.6, 0.38, can(c), function() Remotes.Action:FireServer("Slide") end) end

		header("КОНДИТЕРСКАЯ")
  rowButton(row(50),"Выбрать кекс   •   от 100 монет",Color3.fromRGB(172,91,122),0,1,true,function() currentTab="Bakery"; build() end)
  header("ПОСТОЯННЫЕ УЛУЧШЕНИЯ")
  for _,id in ipairs(Rules.TrainingOrder) do
   local def=Rules.Training[id]; local level=S.training[id] or 0; local cost=Rules.TrainingCost(id,level)
   local r=row(72)
   local label=lbl(r,"Training",UDim2.new(0.63,-16,1,-12),UDim2.fromOffset(10,6),nil,WHITE)
   label.Text=def.name.."  "..level.."/"..def.limit.."\n"..def.description
   rowButton(r,level==def.limit and "МАКС" or ("↑ "..fmt(cost)),Color3.fromRGB(67,134,125),0.64,0.36,level<def.limit and can(cost),function() Remotes.Action:FireServer("Train",id) end)
  end
  header("СЛЕДЫ")
		for _, t in ipairs(Config.Trails) do
			local rr = row(60)
			local n = lbl(rr, "N", UDim2.new(0.55,0,0.6,0), UDim2.new(0,12,0.2,0), nil, WHITE)
			n.Text = t.name
			if S.trails[t.id] then
				local eq = S.trail == t.id
				rowButton(rr, eq and "EQUIPPED" or "EQUIP", eq and Color3.fromRGB(65,134,112) or Color3.fromRGB(65,105,143), 0.6, 0.38, true, function() Remotes.Action:FireServer("Trail", t.id) end)
			else
				rowButton(rr, "КУПИТЬ   " .. fmt(t.cost), Color3.fromRGB(184,137,74), 0.6, 0.38, can(t.cost), function() Remotes.Action:FireServer("Trail", t.id) end)
			end
		end
 elseif currentTab == "Case" then
  local case=Config.CaseById[currentCase]
  if not case then return end
  title.Text=case.name
  header("КЕЙС • "..Config.LocById[case.loc].name)
  local info=row(64)
  local t=lbl(info,"Info",UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),nil,WHITE)
  t.Text="Животные этого острова. Дубликат повышает уровень.\nДоход — только после установки на подиум."
  for i,rar in ipairs(Config.Rarities) do
   local r=row(33)
   local n=lbl(r,"Chance",UDim2.new(1,-24,1,-6),UDim2.fromOffset(12,3),nil,rar.color)
   local pool=Config.AnimalsByLoc[case.loc][rar.name]
   local names={}; for _,a in ipairs(pool) do table.insert(names,a.name) end
   n.Text=rar.name.." • "..case.odds[i].."%  |  "..table.concat(names,", ")
  end
  local r=row(62)
  local unlocked=S.level>=case.unlock
  rowButton(r,unlocked and ("ОТКРЫТЬ • "..fmt(case.price).." монет") or ("ДОСТУПНО С УРОВНЯ "..case.unlock),Color3.fromRGB(191,151,85),0,1,unlocked and can(case.price) and #S.animals<S.slots,function() Remotes.Action:FireServer("OpenCase",case.id) end)
  if #S.animals>=S.slots then header("Нет мест: продай животное или расширь зоопарк") end
 elseif currentTab == "Zoo" then
  title.Text="ЗООПАРК  "..#S.animals.."/"..S.slots.."  •  +"..fmt(S.income).."/сек"
  header(selectedPodium and ("ВЫБЕРИ ЖИВОТНОЕ ДЛЯ ПОДИУМА "..selectedPodium) or "Подойди к подиуму и нажми E, чтобы поставить животное")
  if not selectedPodium then
   rowButton(row(44),"МОЙ ДОМ   •   Вход и оформление",Color3.fromRGB(108,88,126),0,1,true,function() currentTab="Home"; build() end)
  end
  local sr=row(50)
  rowButton(sr,S.slots>=Config.MAX_SLOTS and "ВСЕ ПОДИУМЫ ОТКРЫТЫ" or ("+1 МЕСТО И ПОДИУМ • "..fmt(Config.SlotCost(S.slots))),Color3.fromRGB(65,112,115),0,1,S.slots<Config.MAX_SLOTS and can(Config.SlotCost(S.slots)),function() Remotes.Action:FireServer("BuySlot") end)
  local animals=sortedAnimals()
  if #animals==0 then header("Кейсы находятся на площадке рядом со спавном") end
  for _,e in ipairs(animals) do
   local a,def=e.a,e.def; local rar=Config.RarityByName[def.rarity]
   local r=row(144)
   local portrait=Instance.new("ViewportFrame"); portrait.Size=UDim2.fromOffset(96,100); portrait.Position=UDim2.fromOffset(4,4); portrait.BackgroundTransparency=1; portrait.Ambient=Color3.fromRGB(190,190,210); portrait.LightColor=Color3.fromRGB(255,234,206); portrait.Parent=r
   local template=RS.ArtAssets.Pets:FindFirstChild(a.id)
   if template then
    local m=template:Clone(); m.Parent=portrait; local cf=m:GetBoundingBox(); m:PivotTo(CFrame.Angles(0,math.pi,0)*cf:Inverse()*m:GetPivot())
    local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(0,2,12),Vector3.zero); camera.FieldOfView=38; camera.Parent=portrait; portrait.CurrentCamera=camera
   end
   local n=lbl(r,"Name",UDim2.new(1,-120,0,28),UDim2.fromOffset(108,7),nil,rar.color); n.Text=def.name.." • Lv."..a.lvl
   local inc=Config.AnimalIncome(def,a.lvl)*((a.bu or 0)>nowEst() and Config.BOOST_MULT or 1)
   local d=lbl(r,"Income",UDim2.new(1,-120,0,24),UDim2.fromOffset(108,38),nil,WHITE)
   d.Text=a.podium and ("Подиум "..a.podium.." • +"..fmt(inc).."/сек") or ("В коллекции • поставь на подиум: +"..fmt(inc).."/сек")
   local function action(name,text,x,w,color,cb)
    local b=button(r,name,text,UDim2.new(w,-5,0,32),UDim2.new(x,3,1,-37),nil,color); b.Activated:Connect(cb); return b
   end
   action("Place",selectedPodium and ("НА ПОДИУМ "..selectedPodium) or (a.podium and "УБРАТЬ" or "К ПОДИУМУ"),0,0.37,Color3.fromRGB(60,132,106),function()
    if selectedPodium then Remotes.Action:FireServer("PlaceAnimal",{id=a.id,slot=selectedPodium})
    elseif a.podium then Remotes.Action:FireServer("UnplaceAnimal",a.id)
    else showToast("Подойди к свободному подиуму и нажми E",GOLD) end
   end)
   local cost=Config.AnimalUpCost(def,a.lvl)
   action("Upgrade",a.lvl>=Config.MAX_ANIMAL and "MAX" or ("LVL + • "..fmt(cost)),0.37,0.30,Color3.fromRGB(67,100,143),function() if a.lvl<Config.MAX_ANIMAL and can(cost) then Remotes.Action:FireServer("UpAnimal",a.id) end end)
   local sell=action("Sell","ПРОДАТЬ • "..fmt(Config.SellPrice(def,a.lvl)),0.67,0.33,Color3.fromRGB(135,73,76),function() end)
   sell.Activated:Connect(function()
    if sell:GetAttribute("Confirm") then Remotes.Action:FireServer("SellAnimal",a.id)
    else sell:SetAttribute("Confirm",true); sell.T.Text="ПОДТВЕРДИТЬ"; task.delay(3,function() if sell.Parent then sell:SetAttribute("Confirm",nil); sell.T.Text="ПРОДАТЬ • "..fmt(Config.SellPrice(def,a.lvl)) end end) end
   end)
  end
 elseif currentTab == "Map" then
		title.Text = "Карта островов"
		for _, loc in ipairs(Config.Locations) do
			local r = row(76)
			local n = lbl(r, "N", UDim2.new(0.55,0,0.5,0), UDim2.new(0,12,0,4), nil, WHITE)
			n.Text = loc.name
			local d = lbl(r, "D", UDim2.new(0.55,0,0.34,0), UDim2.new(0,12,0.56,0), nil, Color3.fromRGB(200,200,230))
			d.Text = "Best: " .. fmt(S.best[loc.id] or 0) .. " м   •   награда ×" .. Rules.RunRates[loc.id]
			if not Rules.CanTravel(S,loc.id) then
				rowButton(r, fmt(Rules.WorldDistance[loc.id]).." м суммарно", Color3.fromRGB(90,90,110), 0.6, 0.38, false, function() end)
			elseif S.loc == loc.id then
				rowButton(r, "YOU ARE HERE", Color3.fromRGB(65,134,112), 0.6, 0.38, false, function() end)
			else
				rowButton(r, "TRAVEL", Color3.fromRGB(65,105,143), 0.6, 0.38, true, function()
					Remotes.Action:FireServer("Travel", loc.id)
					panel.Visible = false; currentTab = nil
				end)
			end
		end
	end
	list.CanvasPosition = keep
	lastSig = signature()
end

local function openTab(tab)
	if running or not S then return end
	if currentTab == tab and panel.Visible then panel.Visible = false; currentTab = nil return end
	currentTab = tab; panel.Visible = true; build()
 panel.Position=UDim2.fromScale(0.5,0.53); TS:Create(panel,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{Position=UDim2.fromScale(0.5,0.5)}):Play()
end
settingsB.Activated:Connect(function() openTab("Settings") end)
journalB.Activated:Connect(function() openTab("Journal") end)
shopB.Activated:Connect(function() openTab("Shop") end)
zooB.Activated:Connect(function() selectedPodium=nil; openTab("Zoo") end)
mapB.Activated:Connect(function() openTab("Map") end)
closeB.Activated:Connect(function() panel.Visible = false; currentTab = nil end)

-- ============ HUD UPDATE ============
local hudSizes={}
local function fitHUD()
 local viewport=cam.ViewportSize
 local factor=math.clamp(math.min(viewport.X/760,viewport.Y/640),0.58,1)
 for _,o in ipairs({launchB,leftB,rightB,trickB,shopB,zooB,mapB,settingsB,journalB}) do
  hudSizes[o]=hudSizes[o] or o.Size
  local size=hudSizes[o]; o.Size=UDim2.new(size.X.Scale,size.X.Offset*factor,size.Y.Scale,size.Y.Offset*factor)
 end
 local scale=statusCard:FindFirstChildOfClass("UIScale") or Instance.new("UIScale"); scale.Scale=factor; scale.Parent=statusCard
 for i,o in ipairs({shopB,zooB,mapB}) do o.Position=UDim2.new(0,12,0.46,(i-1)*49*factor) end
 settingsB.Position=UDim2.new(1,-14,0,18+40*factor)
end
cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitHUD); fitHUD()
local function updateHUD()
	if not S then return end
	coinsL.Text = fmt(S.coins).." мон."
	incomeL.Text = S.income > 0 and ("+" .. fmt(S.income) .. " /сек с подиумов") or "Подиумы пока пусты"
	levelL.Text = "Ур. "..S.level
 if S.cupUntil>S.now then incomeL.Text=incomeL.Text.."   •   кекс" end
	local nxt
	for _, loc in ipairs(Config.Locations) do if not Rules.CanTravel(S,loc.id) then nxt=loc break end end
 local goal=nxt and Rules.WorldDistance[nxt.id] or Rules.Goal
 barFill.Size=UDim2.fromScale(math.clamp(S.totalDistance/goal,0,1),1)
 nextL.Text=fmt(S.totalDistance).." / "..fmt(goal).." м   •   "..(nxt and nxt.name or "Экспедиция")
 locL.Text = Config.LocById[S.loc].name .. "   •   Рекорд " .. fmt(S.best[S.loc] or 0) .. " м"
end

Remotes.Sync.OnClientEvent:Connect(function(data)
	S = data
	S.t0 = os.clock()
 Audio.Mix(S.music,S.effects); Audio.Scene(S.loc,running)
	updateHUD()
	if panel.Visible and currentTab and signature() ~= lastSig then build() end
end)

Remotes.Wallet.OnClientEvent:Connect(function(coins,income,now)
 if not S then Remotes.Sync:FireServer(); return end
 S.coins=coins; S.income=income; S.now=now; S.t0=os.clock()
 updateHUD()
 if panel.Visible and currentTab and signature()~=lastSig then build() end
end)
Remotes.Sync:FireServer()

-- ============ LAUNCH / FX ============
launchB.Activated:Connect(function()
	if running or pending or not S then return end
	pending = true
	panel.Visible = false; currentTab = nil
	Remotes.Launch:FireServer()
	task.delay(1.3, function()
		if pending and not running and not pullStart then showToast("Подойди к рогатке!", Color3.fromRGB(255,150,150)) end
	end)
	task.delay(2.5, function() pending = false end)
end)

local function setRunUI(on)
 statusCard.Visible=not on
 local head=plr.Character and plr.Character:FindFirstChild("Head")
 local tag=head and head:FindFirstChild("LvTag"); if tag then tag.Enabled=false end
	settingsB.Visible=not on; journalB.Visible=not on; trickB.Visible=on
 launchB.Visible = not on
	shopB.Visible = not on; zooB.Visible = not on; mapB.Visible = not on
	leftB.Visible = on; rightB.Visible = on
	if not on then runL.Text = "" end
end

Remotes.Fx.OnClientEvent:Connect(function(e)
	local t = e.type
 Audio.Effect(t)
	if t == "message" then
  showToast(e.text,GOLD)
 elseif t=="pull" then
  popupToken+=1; resultCard.Visible=false; pending=true; pullStart=os.clock(); pullDuration=e.duration; camPos=nil; panel.Visible=false; setRunUI(true); trickB.Visible=false
 elseif t=="milestone" then
  showToast(e.text,GOLD)
  local head=plr.Character and plr.Character:FindFirstChild("Head")
  if head then
   local badge=Instance.new("BillboardGui"); badge.Size=UDim2.fromOffset(140,28); badge.StudsOffset=Vector3.new(0,4,0); badge.Parent=head
   local label=lbl(badge,"Mark",UDim2.fromScale(1,1),UDim2.new(),nil,GOLD,Enum.TextXAlignment.Center); label.Text=e.text
   TS:Create(badge,TweenInfo.new(0.7),{StudsOffset=Vector3.new(0,6,0)}):Play(); game.Debris:AddItem(badge,0.85)
  end
 elseif t=="combo" then showToast(e.text,Color3.fromRGB(100,255,204))
 elseif t=="gas" then
  showToast(e.text,Color3.fromRGB(160,246,111)); fovKick=22
  local root=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
  if root then
   local puff=Instance.new("ParticleEmitter"); puff.Texture="rbxasset://textures/particles/smoke_main.dds"; puff.Rate=0; puff.Lifetime=NumberRange.new(0.25,0.65); puff.Speed=NumberRange.new(4,10); puff.Size=NumberSequence.new(2.4); puff.Color=ColorSequence.new(Color3.fromRGB(159,225,108)); puff.Parent=root; puff:Emit(9); game.Debris:AddItem(puff,1)
  end
 elseif t == "launch" then
  pullStart=nil; shakeUntil=os.clock()+0.18; fovKick=24
		running = true; pending = false; Audio.Scene(S.loc,true)
		startX = e.startX or 0
		camPos = nil
		setRunUI(true)
		lastSent = nil; pushSteer()
  if e.event=="Gold" then showToast("Золотой заезд • каждый ускоритель даёт монеты",GOLD) end
	elseif t == "hit" then
		showToast(e.text, Color3.fromRGB(255,90,90))
		shakeUntil = os.clock() + 0.35
	elseif t == "boost" then
		showToast(e.text, Color3.fromRGB(255,235,80))
		fovKick = 25
 elseif t == "chest" then
  panel.Visible=false; currentTab=nil
	elseif t == "result" then
		running = false
		setRunUI(false); launchB.Visible = false
		local title2 = e.record and ("НОВЫЙ РЕКОРД   " .. fmt(e.dist) .. " м") or (fmt(e.dist) .. " м")
		local line1 = "Пик "..fmt(e.speed).." м/с   •   +"..fmt(e.coins).." монет" .. (e.recBonus > 0 and ("  +" .. fmt(e.recBonus) .. " за рекорд") or "")
		showPopup(title2,line1,string.format("×%.2f   •   %d трюков   •   +%d XP",e.mult,e.tricks,e.xp),e.record and GOLD or WHITE,2.8)
  if e.unlocked or e.prizes>0 then
   task.delay(2.9,function() showToast((e.unlocked and ("Открыт "..e.unlocked.."   ") or "")..(e.prizes>0 and ("Достижения  +"..e.prizes.." монет") or ""),GOLD) end)
  end
  task.delay(3.4, function() if not running then launchB.Visible = true end end)
	end
end)

-- ============ CAMERA / RUN HUD ============
RunService.RenderStepped:Connect(function(dt)
	
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if pullStart and root then
  local fraction=math.clamp((os.clock()-pullStart)/pullDuration,0,1)
  runL.Text=string.format("Натяжение   %d%%",fraction*100)
  cam.CameraType=Enum.CameraType.Scriptable
  cam.CFrame=CFrame.lookAt(root.Position+Vector3.new(-18,9,22),root.Position+Vector3.new(5,1,0))
  cam.FieldOfView=70-12*fraction
 elseif running and root then
  trickB.Visible=root:GetAttribute("Airborne")==true
  local v = root.AssemblyLinearVelocity
		local speed = root:GetAttribute("RunSpeed") or math.max(0, v.X)
		local meters=math.max(0,root.Position.X-startX)
  runL.Text=string.format("%d м   •   %d м/с   •   ×%.2f",meters,speed,root:GetAttribute("RewardFactor") or Rules.DistanceFactor(meters))
		cam.CameraType = Enum.CameraType.Scriptable
		local target = root.Position
		local loc=Config.LocById[S.loc]
  local forward=(Config.TrackPoint(loc,target.X+4)-Config.TrackPoint(loc,target.X)).Unit
 local desired = target - forward*(28+speed*0.04) + Vector3.new(0,13+speed*0.02,0)
		camPos = camPos and camPos:Lerp(desired, math.min(1, dt * 8)) or desired
		local shake = Vector3.zero
		if os.clock() < shakeUntil then shake = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2.5 end
		cam.CFrame = CFrame.lookAt(camPos + shake, target + forward*25 + Vector3.new(0,2,0))
		fovKick = fovKick * math.max(0, 1 - dt * 3)
		local targetFov = 70 + math.clamp(speed / 16, 0, 16) + fovKick*0.3
		cam.FieldOfView += (targetFov - cam.FieldOfView) * math.min(1, dt * 5)
	elseif cam.CameraType == Enum.CameraType.Scriptable and not running then
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		cam.CameraType = Enum.CameraType.Custom
		if hum then cam.CameraSubject = hum end
		cam.FieldOfView = 70
		camPos = nil
	end
end)

plr.CharacterAdded:Connect(function(char)
	running = false; pending = false; pullStart=nil
	setRunUI(false)
	task.delay(0.3, function() if not running then launchB.Visible = true end end)
end)

local hook = Instance.new("BindableEvent")
hook.Name = "UIHook"; hook.Parent = gui
hook.Event:Connect(function(tab,arg)
 if running or not S then return end
 if tab=="Case" then currentCase=arg; selectedPodium=nil elseif tab=="Zoo" then selectedPodium=arg end
 currentTab=tab; panel.Visible=true; build()
end)


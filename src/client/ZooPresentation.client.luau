local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local PromptService=game:GetService('ProximityPromptService')
local plr=Players.LocalPlayer
local C=require(RS:WaitForChild('GameConfig'))
local R=RS:WaitForChild('Remotes')
local assets=RS:WaitForChild('ArtAssets')
local gui=plr:WaitForChild('PlayerGui'):WaitForChild('LaunchGui')
local hook=gui:WaitForChild('UIHook')
local V,CF=Vector3.new,CFrame.new
local animated={}; local state; local currentWorld
local function centre(m)
 local box=m:GetBoundingBox(); m:PivotTo(box:Inverse()*m:GetPivot()); m.PrimaryPart=nil; m.WorldPivot=CF()
end
local function clonePet(id,parent)
 local template=assets.Pets:FindFirstChild(id)
 if not template then return end
 local m=template:Clone(); m.Parent=parent; centre(m); return m
end
local function format(n) return n%1==0 and tostring(n) or string.format('%.2f',n) end
local function setAtmosphere(id)
 if currentWorld==id then return end; currentWorld=id
 local themes={
  Jungle={Ambient=Color3.fromRGB(120,137,119),OutdoorAmbient=Color3.fromRGB(148,160,138),ClockTime=13.8,Brightness=2.5,ExposureCompensation=0,ColorShift_Top=Color3.fromRGB(255,226,182)},
  Snow={Ambient=Color3.fromRGB(103,129,158),OutdoorAmbient=Color3.fromRGB(160,184,205),ClockTime=10.1,Brightness=2.4,ExposureCompensation=0,ColorShift_Top=Color3.fromRGB(217,238,255)},
  Moon={Ambient=Color3.fromRGB(156,149,190),OutdoorAmbient=Color3.fromRGB(155,149,188),ClockTime=0.5,Brightness=2.1,ExposureCompensation=0.35,ColorShift_Top=Color3.fromRGB(211,202,255)},
 }
 Tween:Create(Lighting,TweenInfo.new(1),themes[id]):Play()
 local at=Lighting:FindFirstChildOfClass('Atmosphere')
 if at then
  local color=id=='Jungle' and Color3.fromRGB(190,210,181) or id=='Snow' and Color3.fromRGB(189,218,246) or Color3.fromRGB(102,80,150)
  Tween:Create(at,TweenInfo.new(1),{Color=color,Density=id=='Moon' and 0.23 or 0.24,Haze=id=='Moon' and 1.5 or 1.1}):Play()
 end
end
local collection=game:GetService("CollectionService")
local function watch(m)
 animated[m]={base=m:GetAttribute("RestPose") or m:GetPivot(),phase=m:GetPivot().Position.X}
end
for _,m in collection:GetTagged("ZooResident") do watch(m) end
collection:GetInstanceAddedSignal("ZooResident"):Connect(watch)
collection:GetInstanceRemovedSignal("ZooResident"):Connect(function(m) animated[m]=nil end)
local function updateZoo(s)
 state=s; setAtmosphere(s.loc)
end
R.Sync.OnClientEvent:Connect(updateZoo)
R.Sync:FireServer()
PromptService.PromptTriggered:Connect(function(prompt)
 if not state then return end
 if prompt.Name=='HubPrompt' then hook:Fire(prompt:GetAttribute('Tab'))
 elseif prompt.Name=='CasePrompt' then
  local m=prompt.Parent
  while m and not m:GetAttribute('CaseId') do m=m.Parent end
  if m then hook:Fire('Case',m:GetAttribute('CaseId')) end
 elseif prompt.Name=='PodiumPrompt' then
  local m=prompt.Parent.Parent; local slot=m:GetAttribute('Slot')
  if m:GetAttribute("Owner")==plr.UserId and slot and slot<=state.slots then hook:Fire('Zoo',slot) end
 end
end)
-- Fullscreen reveal uses the actual server-awarded animal, never a client roll.
local reveal=Instance.new('ScreenGui'); reveal.Name='AnimalReveal'; reveal.DisplayOrder=50; reveal.ResetOnSpawn=false; reveal.IgnoreGuiInset=true; reveal.Parent=plr.PlayerGui; reveal.Enabled=false
local shade=Instance.new('Frame'); shade.Size=UDim2.fromScale(1,1); shade.BackgroundColor3=Color3.fromRGB(9,15,24); shade.BackgroundTransparency=0.08; shade.Active=true; shade.Parent=reveal
local grad=Instance.new('UIGradient'); grad.Color=ColorSequence.new(Color3.fromRGB(37,54,70),Color3.fromRGB(8,12,22)); grad.Rotation=80; grad.Parent=shade
local vp=Instance.new('ViewportFrame'); vp.Size=UDim2.fromScale(0.8,0.62); vp.Position=UDim2.fromScale(0.1,0.15); vp.BackgroundTransparency=1; vp.Ambient=Color3.fromRGB(180,183,205); vp.LightColor=Color3.fromRGB(255,236,205); vp.LightDirection=V(-1,-1,-1); vp.Parent=shade
local camera=Instance.new('Camera'); camera.CFrame=CF(V(0,3,18),V(0,0,0)); camera.FieldOfView=40; camera.Parent=vp; vp.CurrentCamera=camera
local function textLabel(name,pos,size,font)
 local t=Instance.new('TextLabel'); t.Name=name; t.Position=pos; t.Size=size; t.BackgroundTransparency=1; t.TextColor3=Color3.fromRGB(242,239,224); t.Font=font or Enum.Font.GothamBold; t.TextScaled=true; t.Parent=shade; return t
end
local title=textLabel('Title',UDim2.fromScale(0.1,0.06),UDim2.fromScale(0.8,0.08))
local rarity=textLabel('Rarity',UDim2.fromScale(0.1,0.76),UDim2.fromScale(0.8,0.045))
local detail=textLabel('Detail',UDim2.fromScale(0.1,0.82),UDim2.fromScale(0.8,0.04),Enum.Font.Gotham)
local close=Instance.new('TextButton'); close.Size=UDim2.fromScale(0.28,0.065); close.Position=UDim2.fromScale(0.36,0.9); close.BackgroundColor3=Color3.fromRGB(218,184,117); close.TextColor3=Color3.fromRGB(24,29,34); close.Text='ЗАБРАТЬ'; close.Font=Enum.Font.GothamBold; close.TextScaled=true; close.Parent=shade
local round=Instance.new('UICorner'); round.CornerRadius=UDim.new(0,12); round.Parent=close
local token=0; local revealModel; local revealMode; local revealStart; local revealBase
local function clearReveal()
 token+=1; reveal.Enabled=false; revealModel=nil; revealMode=nil
 for _,o in vp:GetChildren() do if not o:IsA('Camera') then o:Destroy() end end
end
close.Activated:Connect(clearReveal)
local function burst(color)
 for i=1,24 do
  local p=Instance.new('Frame'); p.Size=UDim2.fromOffset(5+(i%3)*3,5+(i%3)*3); p.AnchorPoint=Vector2.new(0.5,0.5); p.Position=UDim2.fromScale(0.5,0.48); p.BackgroundColor3=color; p.BorderSizePixel=0; p.Rotation=i*15; p.Parent=shade
  local a=i/24*math.pi*2
  Tween:Create(p,TweenInfo.new(1.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.fromScale(0.5+math.cos(a)*0.38,0.48+math.sin(a)*0.36),BackgroundTransparency=1,Rotation=i*45}):Play()
  task.delay(1.3,function() p:Destroy() end)
 end
end
R.Fx.OnClientEvent:Connect(function(e)
 if e.type~='chest' or not e.purchased or not C.AnimalById[e.id] then return end
 clearReveal(); token+=1; local my=token
 local def=C.AnimalById[e.id]; local col=C.RarityByName[def.rarity].color
 reveal.Enabled=true; close.Visible=false; title.Text='ОТКРЫВАЕМ КЕЙС'; title.TextColor3=Color3.fromRGB(242,239,224); rarity.Text=''; detail.Text=''
 local case=C.CaseById[e.caseId]
 local source=case and workspace.Tracks[case.loc].Cases:FindFirstChild(case.id)
 if source then
  revealModel=source.Visual:Clone(); revealModel.Parent=vp
  for _,o in revealModel:GetDescendants() do if o:IsA('BillboardGui') or o:IsA('ProximityPrompt') then o:Destroy() end end
  centre(revealModel); revealModel:ScaleTo(revealModel:GetScale()*0.85); revealBase=revealModel:GetPivot(); revealMode='case'; revealStart=os.clock()
 end
 task.delay(1.5,function()
  if my~=token then return end
  if revealModel then
   revealMode=nil
   local lid=revealModel:FindFirstChild('Lid')
   if lid then
    local start=lid:GetPivot(); local began=os.clock()
    while os.clock()-began<0.45 and my==token do
     local a=math.min((os.clock()-began)/0.45,1); lid:PivotTo(start*CFrame.Angles(-a*math.rad(110),0,0)); RunService.RenderStepped:Wait()
    end
   end
   if my~=token then return end
   revealModel:Destroy()
  end
  revealModel=clonePet(e.id,vp); revealMode='pet'; revealStart=os.clock()
  if revealModel then revealModel:PivotTo(CFrame.Angles(0,math.pi,0)) end
  title.Text=e.name; title.TextColor3=col; rarity.Text=string.upper(e.rarity)..(e.dup and (' • УРОВЕНЬ '..e.lvl) or ' • НОВОЕ ЖИВОТНОЕ')
  detail.Text='Поставь на подиум: +'..format(C.AnimalIncome(def,e.lvl))..' монет / сек'
  burst(col)
  task.delay(0.7,function() if my==token then close.Visible=true end end)
 end)
end)
RunService.RenderStepped:Connect(function()
 local now=os.clock(); local root=plr.Character and plr.Character:FindFirstChild('HumanoidRootPart')
 for model,a in pairs(animated) do
  if root and model.Parent and (root.Position-a.base.Position).Magnitude<95 then model:PivotTo(a.base*CF(0,math.sin(now*1.8+a.phase)*0.16,0)*CFrame.Angles(0,math.sin(now*0.6+a.phase)*0.15,0)) end
 end
 if revealModel and revealModel.Parent then
  local t=now-(revealStart or now)
  if revealMode=='case' then revealModel:PivotTo(revealBase*CF(0,math.abs(math.sin(t*9))*0.2,0)*CFrame.Angles(0,math.sin(t*15)*0.12,math.sin(t*24)*0.04))
  elseif revealMode=='pet' then revealModel:PivotTo(CF(0,math.sin(t*2)*0.2,0)*CFrame.Angles(0,math.pi+math.sin(t*0.7)*0.4,0)) end
 end
end)
plr.CharacterAdded:Connect(clearReveal)


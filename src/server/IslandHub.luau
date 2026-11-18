local Hub={}
local V=Vector3.new
local function block(parent,name,size,pos,color,material)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=CFrame.new(pos); p.Color=color
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.Material=material or Enum.Material.SmoothPlastic; p.Parent=parent
 return p
end
local function sign(p,text)
 local surface=Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Back; surface.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; surface.PixelsPerStud=35; surface.Parent=p
 local t=Instance.new("TextLabel"); t.Name="Inscription"; t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextColor3=Color3.fromRGB(255,243,212); t.TextScaled=true; t.Text=text; t.Parent=surface
 return t
end
local function interact(p,target,title)
 local prompt=Instance.new("ProximityPrompt"); prompt.Name="HubPrompt"; prompt.ActionText="Открыть"; prompt.ObjectText=title; prompt.RequiresLineOfSight=false; prompt.MaxActivationDistance=12; prompt:SetAttribute("Tab",target); prompt.Parent=p
end
function Hub.Build(folder,loc)
 if folder:FindFirstChild("Market") then return end
 local market=Instance.new("Folder"); market.Name="Market"; market.Parent=folder
 local ink=Color3.fromRGB(47,62,70); local cream=Color3.fromRGB(255,225,175)
 for i,spec in ipairs({{"КЕКСЫ","Bakery",Color3.fromRGB(216,116,142)},{"МАСТЕРСКАЯ","Shop",Color3.fromRGB(60,161,153)},{"ЭКСПЕДИЦИИ","Journal",Color3.fromRGB(111,122,188)}}) do
  local center=V(-63-46*(i-1),0.75,loc.z-28)
  local function part(n,size,off,c,mat) return block(market,n,size,center+off,c,mat) end
  local counter=part("Counter",V(19,4,5),V(0,2,2),ink,Enum.Material.WoodPlanks); counter.CanCollide=true
  part("Worktop",V(20,0.5,6),V(0,4.2,2),cream,Enum.Material.Wood)
  for _,side in ipairs({-1,1}) do part("Upright",V(0.8,12,0.8),V(side*9,6,-2),cream,Enum.Material.Wood) end
  for stripe=-3,3 do
   local awning=part("Awning",V(3,0.45,9),V(stripe*3,11.7,-0.2),stripe%2==0 and spec[3] or cream); awning.CFrame*=CFrame.Angles(0.15,0,0)
   local flap=part("Scallop",V(3,1.5,0.5),V(stripe*3,10.6,4.2),awning.Color); flap.Shape=Enum.PartType.Ball
  end
  local plaque=part("ShopSign",V(13,2.6,0.5),V(0,8.6,1.5),ink); sign(plaque,spec[1]); interact(counter,spec[2],spec[1])
  part("Apron",V(2.5,3.4,1.5),V(0,4.4,-2.4),spec[3])
  local head=part("Vendor",V(2.5,2.5,2.3),V(0,6.9,-2.4),Color3.fromRGB(203,151,109)); head.Shape=Enum.PartType.Ball
  for _,side in ipairs({-1,1}) do local eye=part("Eye",V(0.22,0.32,0.22),V(side*0.48,7.05,-1.36),ink); eye.Shape=Enum.PartType.Ball end
  part("Cap",V(2.8,0.7,2.7),V(0,8,-2.4),cream).Shape=Enum.PartType.Ball
  for j=-1,1 do
   local base=part("Display",V(1.5,1.1,1.5),V(j*4.7,4.95,2),cream)
   local top=part("Sample",V(1.8,1.6,1.8),V(j*4.7,5.7,2),spec[3])
   if i==1 then top.Shape=Enum.PartType.Ball; part("Cherry",V(0.53,0.53,0.53),V(j*4.7,6.55,2),Color3.fromRGB(179,54,85)).Shape=Enum.PartType.Ball
   elseif i==2 then top.Material=Enum.Material.DiamondPlate else top.Material=Enum.Material.Neon end
  end
 end
 local board=block(market,"Records",V(19,10,1.2),V(-208,7,loc.z-26),ink,Enum.Material.WoodPlanks)
 sign(board,"РЕКОРДЫ СЕРВЕРА")
 local gate=block(market,"Transit",V(18,2,2),V(-218,13,loc.z+3),Color3.fromRGB(129,221,213),Enum.Material.Neon); sign(gate,"ПОРТАЛ")
 for _,s in ipairs({-1,1}) do block(market,"Pylon",V(2,13,2),V(-218+8*s,6.5,loc.z+3),ink,Enum.Material.Metal) end
 local pad=block(market,"TransitPad",V(18,0.45,9),V(-218,1,loc.z+3),gate.Color,Enum.Material.Neon); interact(pad,"Map","Острова")
end
function Hub.UpdateBoards(tracks)
 local players=game.Players:GetPlayers()
 table.sort(players,function(a,b) return (a:GetAttribute("TotalMeters") or 0)>(b:GetAttribute("TotalMeters") or 0) end)
 local lines={"РЕКОРДЫ СЕРВЕРА"}
 for i=1,math.min(4,#players) do local p=players[i]; table.insert(lines,i..".  "..p.DisplayName.."   "..(p:GetAttribute("TotalMeters") or 0).." м") end
 for _,track in ipairs(tracks:GetChildren()) do
  local market=track:FindFirstChild("Market")
  if market then market.Records.SurfaceGui.Inscription.Text=table.concat(lines,"\n") end
 end
end
return Hub

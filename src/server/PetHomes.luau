local C=require(game.ReplicatedStorage.GameConfig)
local Rules=require(game.ReplicatedStorage.ExpeditionRules)
local Collection=game:GetService("CollectionService")
local V=Vector3.new
local Homes={}
local plots,occupied={},{}
local function block(parent,name,size,position,color,material,solid)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=CFrame.new(position); p.Color=color; p.Material=material
 p.Anchored=true; p.CanCollide=solid==true; p.CanTouch=false; p.Parent=parent
 return p
end
local function caption(part,title,color,range)
 local gui=Instance.new("BillboardGui"); gui.MaxDistance=range; gui.Size=UDim2.fromOffset(180,38); gui.StudsOffset=V(0,1.7,0); gui.Parent=part
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=title
 label.TextColor3=color; label.Font=Enum.Font.GothamBold; label.TextSize=13; label.TextStrokeTransparency=0.35; label.Parent=gui
end
local function prompt(parent,name,action,object)
 local p=Instance.new("ProximityPrompt"); p.Name=name; p.ActionText=action; p.ObjectText=object
 p.RequiresLineOfSight=false; p.MaxActivationDistance=9; p.Parent=parent
 return p
end
local function plotOrigin(index,loc)
 local k=index-1
 return V(-48-(k%4)*49,1,loc.z+53+math.floor(k%16/4)*34+math.floor(k/16)*165)
end
local function slotOffset(slot)
 local k=slot-1
 return V(((k%5)-2)*6.8,math.floor(k/10)*14+1,math.floor(k%10/5)*10-4)
end
function Homes.Position(player,slot)
 local h=plots[player]
 return h and h.origin+slotOffset(slot)
end
function Homes.Release(player)
 local h=plots[player]; if not h then return end
 occupied[h.index]=nil; h.model:Destroy(); plots[player]=nil
end
function Homes.Door(player)
 local h=plots[player]; return h and h.origin+V(0,4,-14)
end
local function displayPet(m,pos,a)
 local def=C.AnimalById[a.id]
 local original=game.ReplicatedStorage.ArtAssets.Pets:FindFirstChild(a.id)
 if not original or not def then return end
 local pet=original:Clone(); local _,size=pet:GetBoundingBox()
 pet:ScaleTo(pet:GetScale()*math.min(1,(4.1+math.min(a.lvl,12)*0.08)/math.max(size.X,size.Z,size.Y)))
 local box,amount=pet:GetBoundingBox()
 pet:PivotTo(CFrame.new(pos+V(0,amount.Y/2+0.6,0))*pet:GetPivot():ToObjectSpace(box):Inverse())
 for _,part in pet:GetDescendants() do if part:IsA("BasePart") then part.Anchored=true; part.CanCollide=false; part.CanTouch=false end end
 pet.Name="Resident"; pet.Parent=m; pet:SetAttribute("RestPose",pet:GetPivot()); Collection:AddTag(pet,"ZooResident")
 local rare=C.RarityByName[def.rarity]
 if C.RarityIndex[def.rarity]>=3 or a.lvl>=5 then
  local outline=Instance.new("Highlight"); outline.Adornee=pet; outline.FillTransparency=1; outline.OutlineTransparency=0.42; outline.OutlineColor=rare.color; outline.DepthMode=Enum.HighlightDepthMode.Occluded; outline.Parent=pet
 end
 local plaque=block(m,"Nameplate",V(0.2,0.2,0.2),pos+V(0,amount.Y+0.6,0),rare.color,Enum.Material.SmoothPlastic); plaque.Transparency=1
 caption(plaque,def.name.."  •  "..def.rarity.."  •  Lv."..a.lvl,rare.color,24)
end
function Homes.Refresh(player,d)
 local h=plots[player]
 if not h then
  local index=d.plotNumber or 1
  if occupied[index] then index=1; while occupied[index] do index+=1 end end
  occupied[index]=player; d.plotNumber=index
  local model=Instance.new("Model"); model.Name="Home_"..player.UserId; model:SetAttribute("Owner",player.UserId)
  h={index=index,model=model}; plots[player]=h
 end
 local theme=Rules.Themes[d.theme] or Rules.Themes.Cottage
 local signature=table.concat({d.loc,d.slots,d.theme,tostring(d.glow)},"/")
 if h.shell~=signature then
  h.shell=signature; h.residents={}; h.model:ClearAllChildren()
  h.model.Parent=workspace.Tracks[d.loc]; h.origin=plotOrigin(h.index,C.LocById[d.loc])
  local floors=math.ceil(d.slots/10)
  local trim=d.glow and Enum.Material.Neon or Enum.Material.Metal
  for floor=1,floors do
   local center=h.origin+V(0,(floor-1)*14,0)
   block(h.model,"Deck",V(44,1,31),center,theme.wall,theme.material,true)
   block(h.model,"Fascia",V(44,0.45,0.45),center+V(0,0,-15.6),theme.accent,trim)
   block(h.model,"Back",V(44,8,0.8),center+V(0,4,15),theme.wall,theme.material,true)
   for _,x in ipairs({-21,21}) do
    for _,z in ipairs({-14,14}) do block(h.model,"Pillar",V(1,14,1),center+V(x,7,z),theme.accent,Enum.Material.Metal,true) end
   end
   for j=-2,2 do
    local pane=block(h.model,"Clerestory",V(7.4,3.6,0.4),center+V(j*8.2,10.4,15),theme.accent,Enum.Material.Glass,true); pane.Transparency=0.48
   end
   if floors>1 then
    local lift=block(h.model,"Lift",V(6,0.5,7),center+V(17,0.8,-10.5),theme.accent,trim,true)
    local dest=floor%floors+1
    prompt(lift,"HomeLift","На этаж "..dest,"Лифт").Triggered:Connect(function(visitor)
     local root=visitor.Character and visitor.Character:FindFirstChild("HumanoidRootPart")
     if root and not root.Anchored and (root.Position-lift.Position).Magnitude<13 then root.CFrame=CFrame.new(h.origin+V(17,(dest-1)*14+4,-11)) end
    end)
   end
  end
  local roof=h.origin+V(0,floors*14,0)
  block(h.model,"Roof",V(46,1,33),roof,theme.wall,theme.material,true)
  block(h.model,"Cornice",V(46,0.55,0.6),roof+V(0,-0.5,-16.3),theme.accent,Enum.Material.Metal)
  local sign=block(h.model,"Entrance",V(13,2,0.6),h.origin+V(0,10,-15),theme.wall,theme.material)
  caption(sign,player.DisplayName.."  •  "..floors.." эт.",theme.accent,54)
  for i=1,d.slots do
   local m=Instance.new("Model"); m.Name="Slot"..i; m:SetAttribute("Slot",i); m:SetAttribute("Owner",player.UserId); m.Parent=h.model
   local pos=h.origin+slotOffset(i)
   local base=block(m,"Podium",V(5.6,0.7,5.6),pos,theme.wall,Enum.Material.Marble,true)
   block(m,"Inlay",V(5.8,0.15,5.8),pos+V(0,0.40,0),theme.accent,trim)
   prompt(base,"PodiumPrompt","Разместить питомца","Место "..i)
  end
 end
 local placed={}
 for _,a in ipairs(d.animals) do if a.podium then placed[a.podium]=a end end
 for slot=1,d.slots do
  local a=placed[slot]; local key=a and a.id.."/"..a.lvl or ""
  if h.residents[slot]~=key then
   local m=h.model["Slot"..slot]
   for _,name in ipairs({"Resident","Nameplate"}) do local old=m:FindFirstChild(name); if old then old:Destroy() end end
   if a then displayPet(m,h.origin+slotOffset(slot),a) end
   h.residents[slot]=key
  end
 end
end
return Homes

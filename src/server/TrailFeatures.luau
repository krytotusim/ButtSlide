local C=require(game.ReplicatedStorage.GameConfig)
local Features={}
local function marker(model,name,size,position,angle,color)
 local p=Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanTouch=false
 p.Name=name; p.Size=size; p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,angle)
 p.Material=Enum.Material.Neon; p.Color=color; p.Parent=model
 return p
end
local types={"Friend","Ramp","Mire","Secret"}
local function encounter(parent,kind,pos,r,h)
 local m=Instance.new("Model"); m.Name=kind
 for k,v in pairs({Kind=kind,X=pos.X,Y=pos.Y,Z=pos.Z,R=r,H=h}) do m:SetAttribute(k,v) end
 m.Parent=parent
 return m
end
local function challenges(folder,loc)
 if folder:GetAttribute("Challenges")==1 then return end
 local ink=Color3.fromRGB(54,61,84); local gold=Color3.fromRGB(241,185,89)
 local floors={}
 for _,part in ipairs(folder.Structure:GetChildren()) do
  if part.Name=="Floor" then floors[math.round((part.Position.X-44)/24)]=part end
 end
 for k=0,math.floor((loc.length-880)/960) do
  local x=872+k*960
  local pos=C.TrackPoint(loc,x)
  local approach=C.TrackPoint(loc,x-45)
  local ramp=encounter(folder.Pickups,"Ramp",approach+Vector3.new(0,0,-8),10,6)
  marker(ramp,"Takeoff",Vector3.new(16,1,18),approach+Vector3.new(0,2,-8),0.22,Color3.fromRGB(64,209,226))
  for _,center in ipairs({x-12,x+12}) do
   local floor=floors[math.round((center-44)/24)]
   if floor then
    local cf=floor.CFrame
    floor.Name="GorgeBridge"; floor.Size=Vector3.new(floor.Size.X,2,20)
    floor.CFrame=cf*CFrame.new(0,0,23); floor.Color=gold; floor.Material=Enum.Material.WoodPlanks
   end
  end
  local portal=encounter(folder.Pickups,"Chest",C.TrackPoint(loc,x+45)+Vector3.new(0,0,20),7,10)
  local center=Vector3.new(portal:GetAttribute("X"),portal:GetAttribute("Y"),portal:GetAttribute("Z"))
  marker(portal,"Coffer",Vector3.new(5,3.4,4),center+Vector3.new(0,2,0),0,ink).Material=Enum.Material.Metal
  for _,side in ipairs({-1,1}) do marker(portal,"Strap",Vector3.new(0.6,3.7,4.3),center+Vector3.new(side*1.5,2,0),0,gold) end
  for dx=24,96,24 do
   local q=C.TrackPoint(loc,x+dx)+Vector3.new(0,0,21)
   marker(portal,"Canopy",Vector3.new(25,1.3,18),q+Vector3.new(0,14,0),0,ink).Material=Enum.Material.Slate
   marker(portal,"OuterPillar",Vector3.new(1.5,14,1.5),q+Vector3.new(0,7,9),0,gold)
  end
  local trap=encounter(folder.Obstacles,"Sweep",C.TrackPoint(loc,x-165),6,10)
  trap:SetAttribute("Moving",true)
  local q=C.TrackPoint(loc,x-165)
  local head=marker(trap,"Bumper",Vector3.new(8,8,8),q+Vector3.new(0,5,0),0,ink); head.Shape=Enum.PartType.Ball; head.Material=Enum.Material.DiamondPlate
  marker(trap,"Signal",Vector3.new(8.1,1.2,8.1),head.Position,0,Color3.fromRGB(250,109,85)).Shape=Enum.PartType.Ball
 end
 local bossX=math.floor(loc.length*0.71)
 local boss=encounter(folder.Obstacles,"Boss",C.TrackPoint(loc,bossX),10,24)
 boss:SetAttribute("Moving",true)
 local model=game.ReplicatedStorage.ArtAssets["Monster_"..loc.id]:Clone(); model:ScaleTo(model:GetScale()*1.75)
 local box,size=model:GetBoundingBox(); model:PivotTo(CFrame.new(C.TrackPoint(loc,bossX)+Vector3.new(0,size.Y/2,0))*model:GetPivot():ToObjectSpace(box):Inverse()); model.Parent=boss
 folder:SetAttribute("Challenges",1)
end
function Features.InGorge(x,loc)
 if x<848 or x>loc.length then return false end
 return (x-848)%960<48 and math.floor((x-848)/960)<=math.floor((loc.length-880)/960)
end
function Features.Build(folder,loc)
 challenges(folder,loc)
 if folder:GetAttribute("TrailFeatures")==1 then return end
 local templates=game.ReplicatedStorage.ArtAssets.Pets
 for index=1,math.floor((loc.length-145)/160)+1 do
  local x=145+(index-1)*160
  local kind=types[(index-1)%#types+1]
  local lane=kind=="Secret" and 23 or (kind=="Friend" and 0 or (index%3-1)*14)
  local pos=C.TrackPoint(loc,x)+Vector3.new(0,0,lane)
  local m=Instance.new("Model"); m.Name=kind
  for k,v in pairs({Kind=kind,X=x,Y=pos.Y,Z=pos.Z,R=kind=="Friend" and 8 or 7,H=kind=="Friend" and 19 or 8}) do m:SetAttribute(k,v) end
  if kind=="Friend" then
   local pet=templates[loc.id.."_Common_1"]:Clone(); pet:ScaleTo(pet:GetScale()*1.3); pet.Parent=m
   local box,size=pet:GetBoundingBox()
   pet:PivotTo(CFrame.new(pos+Vector3.new(0,size.Y/2+0.5,0))*pet:GetPivot():ToObjectSpace(box):Inverse())
   marker(m,"MintHalo",Vector3.new(7,0.18,7),pos+Vector3.new(0,0.25,0),0,Color3.fromRGB(94,251,165))
  elseif kind=="Ramp" then
   marker(m,"Lip",Vector3.new(15,0.8,12),pos+Vector3.new(0,2.1,0),0.22,Color3.fromRGB(75,188,222))
  elseif kind=="Mire" then
   local mud=marker(m,"Drift",Vector3.new(16,1.0,14),pos+Vector3.new(0,0.28,0),0,loc.id=="Snow" and Color3.fromRGB(237,248,255) or Color3.fromRGB(108,78,99)); mud.Shape=Enum.PartType.Ball; mud.Material=Enum.Material.Sand
  else
   for _,side in ipairs({-1,1}) do marker(m,"Gate",Vector3.new(1.3,12,1.3),pos+Vector3.new(0,6,5*side),0,Color3.fromRGB(234,171,69)) end
   marker(m,"Lintel",Vector3.new(1.3,1.3,11),pos+Vector3.new(0,12,0),0,Color3.fromRGB(255,207,105))
  end
  m.Parent=folder.Pickups
  if index%12==0 then task.wait() end
 end
 folder:SetAttribute("TrailFeatures",1)
end
return Features

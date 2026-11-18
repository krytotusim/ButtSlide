local Scenery={}
local V=Vector3.new
local palettes={
 Jungle={rock=Color3.fromRGB(88,109,93),crest=Color3.fromRGB(74,145,91),light=Color3.fromRGB(106,216,201),tree="JungleTree",sky=Enum.Material.Grass},
 Snow={rock=Color3.fromRGB(100,143,166),crest=Color3.fromRGB(226,245,247),light=Color3.fromRGB(139,223,250),tree="SnowTree",sky=Enum.Material.Snow},
 Moon={rock=Color3.fromRGB(85,73,109),crest=Color3.fromRGB(145,125,169),light=Color3.fromRGB(221,151,247),tree="MoonRock",sky=Enum.Material.Basalt},
}
local function piece(parent,class,name,size,cf,c,mat)
 local p=Instance.new(class); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=c; p.Material=mat
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Parent=parent
 return p
end
local function specimen(parent,key,pos,scale,angle)
 local m=game.ReplicatedStorage.ArtAssets[key]:Clone(); m:ScaleTo(m:GetScale()*scale)
 local box,size=m:GetBoundingBox()
 m:PivotTo(CFrame.new(pos+V(0,size.Y/2,0))*CFrame.Angles(0,angle,0)*m:GetPivot():ToObjectSpace(box):Inverse())
 m.Parent=parent
end
function Scenery.Build(folder,loc)
 if folder:FindFirstChild("IslandVista") then return end
 local decor=Instance.new("Folder"); decor.Name="IslandVista"; decor.Parent=folder
 local st=palettes[loc.id]; local rng=Random.new(#loc.id*71)
 for _,side in ipairs({-1,1}) do
  for index=1,7 do
   local x=20+rng:NextNumber(-9,8)
   local z=loc.z+side*(48+21*index)
   local h=rng:NextNumber(35,68)
   local cf=CFrame.new(x,h/2-2,z)*CFrame.Angles(0,rng:NextNumber(-0.4,0.4),math.rad(rng:NextNumber(-12,8)))
   local cliff=piece(decor,"WedgePart","Crag",V(34,h,31),cf,st.rock,Enum.Material.Slate)
   piece(decor,"WedgePart","Crest",V(34.5,h*0.38,32),cliff.CFrame*CFrame.new(0,h*0.34,7),st.crest,st.sky)
   specimen(decor,st.tree,V(x-12,h*0.70,z+5),rng:NextNumber(0.55,1.20),rng:NextNumber(0,6))
  end
 end
 local center=V(10,0,loc.z-77)
 for j=-2,2 do
  local w=2.5+(j%2)*0.8
  local pos=center+V(-j%2,18+j%2,j*3.3)
  if loc.id=="Jungle" then
   local stream=piece(decor,"Part","Falls",V(w,39,2.2),CFrame.new(pos)*CFrame.Angles(0,math.pi/2,0.06),st.light,Enum.Material.Glass); stream.Transparency=0.26
   local foam=piece(decor,"Part","Foam",V(10,2.8,6),CFrame.new(pos.X-3,1,pos.Z),Color3.fromRGB(212,251,238),Enum.Material.SmoothPlastic); foam.Shape=Enum.PartType.Ball
  elseif loc.id=="Snow" then
   piece(decor,"WedgePart","IceSpire",V(w*2,19+7*(j%3),w*2),CFrame.new(pos)*CFrame.Angles(0,j,0.16*j),st.light,Enum.Material.Glass)
  else
   local stone=piece(decor,"Part","Satellite",V(6,5,7),CFrame.new(pos+V(j,5+j*3,0))*CFrame.Angles(j,0.4,j),st.crest,Enum.Material.Rock); stone.Shape=Enum.PartType.Ball
  end
 end
 for _,side in ipairs({-1,1}) do
  for j=1,5 do
   local pos=V(-18-j*32,0.4,loc.z+side*(151+j%2*9))
   specimen(decor,st.tree,pos,rng:NextNumber(1.1,1.8),rng:NextNumber(0,6))
  end
 end
 -- A low compass rose keeps the takeoff lane clear at avatar eye level.
 local centerPad=V(-14,0.95,loc.z)
 for i=0,19 do
  local angle=i*math.pi/10
  local cf=CFrame.new(centerPad+V(math.cos(angle)*15,0,math.sin(angle)*15))*CFrame.Angles(0,-angle,0)
  piece(decor,"Part","CompassInlay",V(i%5==0 and 3.6 or 1.5,0.13,0.45),cf,st.light,Enum.Material.Metal)
 end
 for i=1,3 do
  for _,side in ipairs({-1,1}) do
   piece(decor,"Part","Arrow",V(3.3,0.14,0.65),CFrame.new(-37+5*i,0.96,loc.z+side*1.05)*CFrame.Angles(0,side*0.60,0),st.light,Enum.Material.Neon)
  end
 end
end
return Scenery

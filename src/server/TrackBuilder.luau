local B={FLOOR_Y=0.3}
local Art=require(game.ServerScriptService:WaitForChild("WorldArt"))
local V,CF=Vector3.new,CFrame.new
local metal,neon=Enum.Material.Metal,Enum.Material.Neon
local function piece(parent,name,size,frame,color,material,solid)
 local p=Instance.new("Part")
 p.Name=name; p.Anchored=true; p.CanCollide=solid==true; p.CanTouch=false
 p.Material=material; p.Size=size; p.CFrame=frame; p.Color=color; p.Parent=parent
 return p
end
local function line(part,a,b,width)
 part.Shape=Enum.PartType.Cylinder
 part.Size=V((a-b).Magnitude,width,width)
 part.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0)
end
function B.Draw(model,draw,power)
 local z=model:GetAttribute("Lane")
 local pouch=V(-3-21*draw,14-4*draw,z)
 model.Cradle.CFrame=CF(pouch)
 model.CradleBack.CFrame=CF(pouch+V(-2,0.85,0))*CFrame.Angles(0,0,0.16)
 for i,side in ipairs({-1,1}) do
  local band=model["Elastic"..i]
  line(band,V(1,19,z+11*side),pouch+V(0,0,2.6*side),1.35-0.32*math.max(draw,0))
  line(model["Cord"..i],V(1.6,19.5,z+11*side),pouch+V(1,0.35,2.6*side),0.46)
  band.Color=Color3.fromHSV((0.12+power*0.012)%1,0.8,0.88+0.12*math.max(draw,0))
 end
 return pouch+V(0,2.3,0)
end
function B.BuildStart(folder,loc)
 local cat=Instance.new("Model"); cat.Name="Slingshot"; cat:SetAttribute("Lane",loc.z)
 local st=Art.Styles[loc.id]; local timber=loc.id=="Jungle" and Enum.Material.Wood or metal
 local function add(name,size,position,color,mat,solid)
  return piece(cat,name,size,CF(position+V(0,0,loc.z)),color,mat,solid)
 end
 add("Foundation",V(20,1.4,30),V(0,0.8,0),st.rock,Enum.Material.Slate,true)
 for i,side in ipairs({-1,1}) do
  local foot=V(0,1.4,loc.z+5*side); local tip=V(1,19,loc.z+11*side)
  local frame=add("Fork",V(1,1,1),V(0,0,0),st.edge,timber)
  line(frame,foot,tip,3.8)
  for _,dx in ipairs({-1,1}) do
   local shoe=add("AnchorShoe",V(1,1,1),V(0,0,0),st.rock,metal)
   line(shoe,V(7*dx,1.2,loc.z+side*7),foot:Lerp(tip,0.38),1.65)
   add("BoltPlate",V(4.3,0.55,3.5),V(7*dx,1.7,side*7),st.edge,metal)
   for _,dz in ipairs({-1,1}) do add("Rivet",V(0.65,0.7,0.65),V(7*dx,2.03,side*7+dz),st.rock,metal).Shape=Enum.PartType.Ball end
  end
  for _,t in ipairs({0.12,0.73,0.81,0.90,0.98}) do
   piece(cat,"Ferrule",V(4.15,4.15,t<0.9 and 0.85 or 1.2),CFrame.lookAt(foot:Lerp(tip,t),tip),t==0.81 and st.accent or st.rock,t==0.81 and neon or metal)
  end
  local cap=piece(cat,"Pin",V(4.6,4.6,4.6),CF(tip),st.accent,neon); cap.Shape=Enum.PartType.Ball
  add("Cord"..i,V(1,1,1),V(0,0,0),st.accent,neon)
  add("Elastic"..i,V(1,1,1),V(0,0,0),st.edge,Enum.Material.SmoothPlastic)
 end
 local cradle=add("Cradle",V(5,1.7,7.5),V(-3,14,0),Color3.fromRGB(110,61,42),Enum.Material.Leather)
 cradle.Shape=Enum.PartType.Ball
 add("CradleBack",V(1.4,2.8,7.0),V(0,0,0),Color3.fromRGB(144,84,53),Enum.Material.Leather).Shape=Enum.PartType.Ball
 local light=Instance.new("PointLight"); light.Color=st.accent; light.Range=28; light.Brightness=1.8; light.Parent=cradle
 local sparks=Instance.new("ParticleEmitter"); sparks.Name="Sparks"; sparks.Rate=0; sparks.Lifetime=NumberRange.new(0.2,0.5); sparks.Speed=NumberRange.new(5,16); sparks.SpreadAngle=Vector2.new(70,70); sparks.Color=ColorSequence.new(st.accent); sparks.LightEmission=0.8; sparks.Size=NumberSequence.new(0.35); sparks.Parent=cradle
 local prompt=Instance.new("ProximityPrompt"); prompt.Name="SlingPrompt"; prompt.ActionText="Натянуть"; prompt.ObjectText="Рогатка"; prompt.MaxActivationDistance=20; prompt.RequiresLineOfSight=false; prompt.Parent=cat.Foundation
 cat:SetAttribute("Revision",2); B.Draw(cat,0,0); cat.Parent=folder
 return cat
end
function B.Build(loc,tracks)
 local folder=Art.Build(loc,tracks)
 B.BuildStart(folder,loc)
 return folder
end
return B

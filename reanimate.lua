--[[
	Fastest's reanimate method
	Optimized network usage for QuickStar
	[Final version]
]]

--/ Prerequisite
local far = CFrame.new((0.5 - math.random()) * 20000000, 1000000, (0.5 - math.random()) * 20000000)
local Player = game:GetService("Players").LocalPlayer
local realchar = Player.Character
local char = Instance.new("Model", workspace)
char.Name = "LPI - Reanimate"
local humanoid = realchar:FindFirstChildOfClass("Humanoid")
local hrp = realchar:FindFirstChild("HumanoidRootPart")

local F3X = Player.Backpack:FindFirstChild("F3X") or
	Player.Character:FindFirstChild("F3X")
humanoid:EquipTool(F3X)

--/ Primitive SyncAPI calls
local SyncAPI = F3X["SyncAPl"]["ServerEndPoint"..utf8.char(0x200C)]
local Prim = {}
Prim.CreatePart = function(cframe: CFrame): Part
	return SyncAPI:InvokeServer("CreatePart", "Normal", cframe)
end
Prim.DestroyParts = function(part: BasePart)
	SyncAPI:InvokeServer("UndoRemove", part)
end
Prim.Weld = function(part1: BasePart, part2: BasePart): {Weld}
	return SyncAPI:InvokeServer("CreateWelds", {part2}, part1)
end
Prim.CreateMeshes = function(parts: {BasePart}): {SpecialMesh}
	local t = {}
	for _, v in parts do
		table.insert(t, {Part = v})
	end
	return SyncAPI:InvokeServer("CreateMeshes", t)
end

--/ Setup
local limb = {
	HumanoidRootPart = realchar["HumanoidRootPart"].CFrame,
	Torso = realchar["Torso"].CFrame,
	Head = realchar["Head"].CFrame,
	RightArm = realchar["Right Arm"].CFrame,
	RightLeg = realchar["Right Leg"].CFrame,
	LeftArm = realchar["Left Arm"].CFrame,
	LeftLeg = realchar["Left Leg"].CFrame
}
hrp.CFrame = far
task.wait()
local welded = Prim.CreatePart(far)
local welds = Prim.Weld(hrp, welded)
for _, weld in welds do
	-- this is clientside!
	-- which means your real characters position wont replicate
	-- on server, you will stay welded and won't move, only the
	-- fake character will move.
	weld:Destroy()
end
task.wait()
hrp.CFrame = limb.HumanoidRootPart

local Torso = Prim.CreatePart(limb.Torso)
local Head = Prim.CreatePart(limb.Head)
local RightArm = Prim.CreatePart(limb.RightArm)
local RightLeg = Prim.CreatePart(limb.RightLeg)
local LeftArm = Prim.CreatePart(limb.LeftArm)
local LeftLeg = Prim.CreatePart(limb.LeftLeg)
Torso.Parent = char; Torso.Name = "Torso"; Torso.BrickColor = BrickColor.new("Black")
Head.Parent = char; Head.Name = "Head"; Head.BrickColor = BrickColor.new("Black")
RightArm.Parent = char; RightArm.Name = "Right Arm"; RightArm.BrickColor = BrickColor.new("Black")
RightLeg.Parent = char; RightLeg.Name = "Right Leg"; RightLeg.BrickColor = BrickColor.new("Black")
LeftArm.Parent = char; LeftArm.Name = "Left Arm"; LeftArm.BrickColor = BrickColor.new("Black")
LeftLeg.Parent = char; LeftLeg.Name = "Left Leg"; LeftLeg.BrickColor = BrickColor.new("Black")

for _, v0 in realchar:GetDescendants() do
	if v0:IsA("BasePart") then
		for _, v1 in char:GetDescendants() do
			if v1:IsA("BasePart") then
				local ncc = Instance.new("NoCollisionConstraint", Torso)
				ncc.Part0 = v0
				ncc.Part1 = v1
				ncc.Name = `{v0.Name} - {v1.Name}`
				v1.CanCollide = false
			end
		end
		v0.CanCollide = false
	end
end

local Limbs = {
	Torso, Head, RightArm, RightLeg, LeftArm, LeftLeg
}

local meshes = Prim.CreateMeshes(Limbs)
SyncAPI:InvokeServer("SyncMesh", { -- easier to do with a direct sync call
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/torso.mesh",
		Part = Torso
	},
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/head.mesh",
		Part = Head
	},
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/rightarm.mesh",
		Part = RightArm
	},
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/rightleg.mesh",
		Part = RightLeg
	},
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/leftarm.mesh",
		Part = LeftArm
	},
	{
		MeshType = Enum.MeshType.FileMesh,
		MeshId = "rbxasset://fonts/leftleg.mesh",
		Part = LeftLeg
	}
})
SyncAPI:InvokeServer("CreateTextures", {{Part = Head, TextureType = "Decal", Face = Enum.NormalId.Front}})
SyncAPI:InvokeServer("SyncTexture", {{Part = Head, TextureType = "Decal", Texture = "rbxasset://textures/face.png"}})

--/ Replication
Prim.SyncPos = function(parts: {BasePart})
	local t = {}
	for _, p in parts do
		if p.Locked then continue end
		table.insert(t, {
			Part = p,
			Surfaces = {
				["CFrame\0"] = realchar[p.Name].CFrame
			}
		})
	end
	SyncAPI:InvokeServer("SyncSurface", t)
end
Prim.InitChar = function(parts: {BasePart})
	local t = {}
	for _, p in parts do
		if p.Locked then continue end
		table.insert(t, {
			Part = p,
			Surfaces = {
				["Size\0"] = realchar[p.Name].Size,
				["Anchored\0"] = true,
				["CanCollide\0"] = p.Name == "Torso",
				["CanTouch\0"] = false,
				["Color\0"] = p.Color,
				["AssemblyLinearVelocity\0"] = Vector3.yAxis * -300
			}
		})
	end
	SyncAPI:InvokeServer("SyncSurface", t)
end

Prim.DestroyParts({F3X.Handle})
for i, v in realchar:GetDescendants() do
	if v:IsA("BasePart") or v:IsA("Decal") then
		v.Transparency = 1
	end
end

Prim.InitChar(Limbs)
local function sync()
	Prim.SyncPos(Limbs)
end
local connection = game:GetService("RunService").Heartbeat:Connect(sync)

humanoid.Died:Connect(function()
	connection:Disconnect()
	local td = Limbs
	table.insert(td, welded)
	Prim.DestroyParts(td)
	char:Destroy()
end)

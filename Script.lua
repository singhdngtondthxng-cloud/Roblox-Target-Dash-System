local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local ATTACK_RANGE = 15 -- ระยะตรวจจับศัตรู
local TAG_NAME = "TargetMarker"

-- ฟังก์ชันหาเป้าหมายที่ใกล้ที่สุด (รวมทั้งผู้เล่น และ Dummy ในแมพ)
local function getClosestTarget()
	local closestTarget = nil
	local shortestDistance = ATTACK_RANGE
	
	-- วนลูปหาทุกอย่างใน Workspace ที่มี Humanoid (รวม Dummy ด้วย)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Parent ~= character and obj.Health > 0 then
			local enemyRoot = obj.Parent:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude
				if distance < shortestDistance then
					closestTarget = obj.Parent
					shortestDistance = distance
				end
			end
		end
	end
	return closestTarget
end

-- 🟥 1. ระบบ Uppercut (กด E)
local function doUppercut()
	local enemy = getClosestTarget()
	if enemy then
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			print("Uppercut โดนเป้าหมาย: " .. enemy.Name)
			
			-- ผลักศัตรูลอยขึ้นฟ้า (ปรับให้แรงขึ้นเพื่อให้เห็นชัด)
			enemyRoot.AssemblyLinearVelocity = Vector3.new(0, 50, 0)
			
			-- 🔴 สร้างแท่งแดงล็อกเป้าลอยเหนือหัว
			local marker = enemyRoot:FindFirstChild(TAG_NAME)
			if not marker then
				local billboard = Instance.new("BillboardGui")
				billboard.Name = TAG_NAME
				billboard.Size = UDim2.new(3, 0, 0.6, 0)
				billboard.AlwaysOnTop = true
				billboard.StudsOffset = Vector3.new(0, 4, 0)
				
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 1, 0)
				frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- แท่งสีแดง
				frame.BorderSizePixel = 0
				frame.Parent = billboard
				
				billboard.Adornee = enemyRoot
				billboard.Parent = enemyRoot
				billboard:SetAttribute("TargetOf", player.Name)
				
				-- ลบแท่งแดงอัตโนมัติใน 3 วินาทีถ้าไม่ได้แดชไปหา
				game.Debris:AddItem(billboard, 3)
			end
		end
	end
end

-- ⚡ 2. ระบบแดชพุ่งหาแท่งแดง (กด Q)
local function doDash()
	local targetEnemyRoot = nil
	
	-- ค้นหาตัวละครในแมพที่มีแท่งแดงของเราติดอยู่
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BillboardGui") and obj.Name == TAG_NAME then
			if obj:GetAttribute("TargetOf") == player.Name then
				targetEnemyRoot = obj.Adornee
				break
			end
		end
	end
	
	-- ถ้ามีเป้าหมายติดแท่งแดง -> พุ่งไปหาประชิดตัว
	if targetEnemyRoot then
		print("แดชล็อกเป้าพุ่งชน!")
		local targetPos = targetEnemyRoot.Position
		-- คำนวณจุดยืนหน้าศัตรูห่างออกมา 3 studs
		local dashDestination = targetPos - (targetEnemyRoot.CFrame.LookVector * 3)
		
		-- พาตัวเราไปหาเป้าหมายและหันหน้าไปหาศัตรู
		rootPart.CFrame = CFrame.new(dashDestination, targetPos)
		
		-- ลบแท่งแดงออกทันที
		local marker = targetEnemyRoot:FindFirstChild(TAG_NAME)
		if marker then marker:Destroy() end
	else
		-- ถ้าไม่มีแท่งแดง -> แดชไปข้างหน้าตัวเอง 15 studs
		print("แดชธรรมดา")
		rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -15)
	end
end

-- ตรวจจับปุ่มกด
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		doUppercut()
	elseif input.KeyCode == Enum.KeyCode.Q then
		doDash()
	end
end)

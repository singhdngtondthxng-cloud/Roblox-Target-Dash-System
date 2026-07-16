local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- พิกัดและระยะตรวจจับ
local ATTACK_RANGE = 10 -- ระยะต่อย Uppercut (studs)
local DASH_SPEED = 75   -- ความเร็วตอนแดช

-- ฟังก์ชันหาศัตรูที่อยู่ตรงหน้าเรา
local function getClosestEnemy()
	local closestEnemy = nil
	local shortestDistance = ATTACK_RANGE
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local enemyRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			local enemyHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
			
			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude
				if distance < shortestDistance then
					closestEnemy = otherPlayer.Character
					shortestDistance = distance
				end
			end
		end
	end
	return closestEnemy
end

-- 🟥 1. ระบบต่อย Uppercut (กดปุ่ม E)
local function doUppercut()
	local enemy = getClosestEnemy()
	if enemy then
		local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			print("Uppercut ใส่: " .. enemy.Name)
			
			-- ส่งแรงเสยศัตรูขึ้นฟ้า (หมายเหตุ: ในเกมจริงควรทำผ่าน Server Script เพื่อความเสถียร)
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = Vector3.new(0, 45, 0)
			bv.MaxForce = Vector3.new(0, 99999, 0)
			bv.Parent = enemyRoot
			game.Debris:AddItem(bv, 0.4)
			
			-- 🔴 สร้างแท่งแดงล็อกเป้า (ถ้าไม่มีใน ReplicatedStorage จะสร้างจำลองขึ้นมา)
			local marker = enemyRoot:FindFirstChild("TargetMarker")
			if not marker then
				local billboard = Instance.new("BillboardGui")
				billboard.Name = "TargetMarker"
				billboard.Size = UDim2.new(2, 0, 0.5, 0)
				billboard.AlwaysOnTop = true
				billboard.StudsOffset = Vector3.new(0, 3, 0)
				
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 1, 0)
				frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- แท่งสีแดง
				frame.Parent = billboard
				
				billboard.Adornee = enemyRoot
				billboard.Parent = enemyRoot
				billboard:SetAttribute("TargetOf", player.Name)
				
				game.Debris:AddItem(billboard, 2.5) -- แท่งแดงอยู่ได้ 2.5 วินาที
			end
		end
	end
end

-- ⚡ 2. ระบบแดชพุ่งหาแท่งแดง (กดปุ่ม Q)
local function doDash()
	local targetEnemyRoot = nil
	
	-- ค้นหาศัตรูที่มีแท่งแดงของเราติดอยู่
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local enemyRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				local marker = enemyRoot:FindFirstChild("TargetMarker")
				if marker and marker:GetAttribute("TargetOf") == player.Name then
					targetEnemyRoot = enemyRoot
					break
				end
			end
		end
	end
	
	-- ถ้ามีเป้าหมายติดแท่งแดงอยู่ -> พุ่งไปหาเลย!
	if targetEnemyRoot then
		print("แดชล็อกเป้าพุ่งหาศัตรู!")
		local targetPos = targetEnemyRoot.Position
		-- คำนวณจุดจอดข้างหน้าศัตรูเล็กน้อย
		local dashDestination = targetPos - (targetEnemyRoot.CFrame.LookVector * 3)
		
		-- เทเลพอร์ตไปหาทันที (หรือเปลี่ยนเป็นใช้แรงผลักถ้าต้องการความนุ่มนวล)
		rootPart.CFrame = CFrame.new(dashDestination, targetPos)
		
		-- ลบแท่งแดงออก
		local marker = targetEnemyRoot:FindFirstChild("TargetMarker")
		if marker then marker:Destroy() end
	else
		-- ถ้าไม่มีแท่งแดง -> แดชไปข้างหน้าตัวเองธรรมดา
		print("แดชธรรมดาไปข้างหน้า")
		rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -15)
	end
end

-- ตรวจจับการกดปุ่มบนคีย์บอร์ด
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		doUppercut()
	elseif input.KeyCode == Enum.KeyCode.Q then
		doDash()
	end
end)

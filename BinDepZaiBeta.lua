function FlyHeight()
        -- Gọi hàm FlyHeight
     local player = game.Players.LocalPlayer
     local character = player.Character or player.CharacterAdded:Wait()

    local FlyHeight_Number = 20 -- Độ cao bay

    -- Biến trạng thái để theo dõi khi nhân vật bắt đầu bay
    local hasStartedFlying = false

    -- Hàm để giữ `HumanoidRootPart` của nhân vật lơ lửng
    function KeepFloating(humanoidRootPart, flyHeight)
        -- Kiểm tra `HumanoidRootPart` hợp lệ
        if not humanoidRootPart then
            warn("HumanoidRootPart không hợp lệ!")
            return
        end

        -- Tạo hoặc sử dụng `BodyPosition` để giữ vị trí ổn định
        local bodyPosition = humanoidRootPart:FindFirstChild("BodyPosition")
        if not bodyPosition then
            -- Tạo BodyPosition chỉ khi chưa có
            bodyPosition = Instance.new("BodyPosition", humanoidRootPart)
            bodyPosition.MaxForce = Vector3.new(100000, 100000, 100000) -- Lực tác động mạnh
            bodyPosition.D = 5 -- Độ giảm dao động (dựng dực) thấp hơn
            bodyPosition.P = 10000 -- Lực giữ lại mạnh
            bodyPosition.Name = "BodyPosition" -- Đặt tên để dễ kiểm tra
        end

        -- Nếu chưa bắt đầu bay, đặt vị trí ngay lập tức mà không dao động
        if not hasStartedFlying then
            -- Đảm bảo không có dao động, đặt vị trí ngay lập tức
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position.X, flyHeight, humanoidRootPart.Position.Z)
            -- Sử dụng BodyPosition sau khi đặt vị trí để giữ nó
            bodyPosition.Position = Vector3.new(humanoidRootPart.Position.X, flyHeight, humanoidRootPart.Position.Z)
            hasStartedFlying = true
        else
            -- Cập nhật vị trí của HumanoidRootPart để giữ nó ở độ cao bay
            bodyPosition.Position = Vector3.new(humanoidRootPart.Position.X, flyHeight, humanoidRootPart.Position.Z)
        end
    end

    -- Giữ nhân vật của người chơi luôn bay
    task.spawn(function()
        while true do
            if character and character:FindFirstChild("HumanoidRootPart") then
                -- Giữ nhân vật bay ở độ cao cố định
                KeepFloating(character.HumanoidRootPart, FlyHeight_Number)
            end
            task.wait(0.1) -- Lặp lại mỗi 0.1 giây để cập nhật vị trí
        end
    end)

    -- Đảm bảo nhân vật không rơi khi bị quái đánh trúng
    character.HumanoidRootPart.Touched:Connect(function(hit)
        -- Kiểm tra đối tượng va chạm
        if hit and hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
            -- Nếu đối tượng là quái vật, giữ lại vị trí lơ lửng
            if character and character:FindFirstChild("HumanoidRootPart") then
                -- Khi quái đánh vào, không làm thay đổi vị trí của người chơi
                KeepFloating(character.HumanoidRootPart, FlyHeight_Number)
            end
        end
    end)

end

function Kill()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local attackRadius = 1000 -- Bán kính tầm đánh hình tròn
    local dame = math.huge -- Số lượng damage gây ra
    local targetTag = "Enemy" -- Nhãn hoặc đối tượng quái vật

    -- Hàm tự động tấn công các quái vật trong phạm vi tấn công
    function AutoAttackInRange()
        -- Kiểm tra nếu nhân vật và HumanoidRootPart tồn tại
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        -- Xác định vị trí của nhân vật
        local characterPosition = character.HumanoidRootPart.Position

        -- Duyệt qua tất cả các đối tượng trong workspace
        for _, obj in pairs(workspace:GetDescendants()) do
            -- Kiểm tra xem đối tượng có phải là một quái vật (có Humanoid)
            if obj:IsA("BasePart") and obj.Parent and obj.Parent:FindFirstChild("Humanoid") then
                -- Kiểm tra nếu quái vật nằm trong phạm vi tấn công
                local distance = (obj.Position - characterPosition).Magnitude
                if distance <= attackRadius then
                    -- Nếu trong phạm vi, thực hiện tấn công quái vật
                    local targetPart = obj.Parent:FindFirstChild("LeftHand") or obj.Parent:FindFirstChild("Head")
                    if targetPart then
                            -- Gửi yêu cầu tấn công quái vật
                            local args = {
                                [1] = targetPart, -- Tấn công vào bộ phận quái vật
                                [2] = {}}
                            game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RE/RegisterHit"):FireServer(unpack(args))
                            -- Gửi yêu cầu sử dụng tấn công thường
                            local attackArgs = {
                                [1] = dame }
                            game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RE/RegisterAttack"):FireServer(unpack(attackArgs))
                    end
                end
            end
        end
    end
    -- Hàm tự động tấn công liên tục
    task.spawn(function()
        while true do
            AutoAttackInRange()
            -- Chờ một chút trước khi kiểm tra lại
            task.wait(0.1) -- Bạn có thể điều chỉnh khoảng thời gian giữa các lần kiểm tra
        end
    end)
end
Kill()

function Teleport()
        
    -- Hàm để teleport quái vật trong thư mục Enemies đến gần nhân vật người chơi
    function TeleportEnemyToPlayer(enemy)
        -- Kiểm tra xem đối tượng có phải là quái vật không và có HumanoidRootPart
        if enemy and enemy:FindFirstChild("HumanoidRootPart") then
            -- Lấy vị trí của nhân vật người chơi và quái vật
            local playerPosition = character.HumanoidRootPart.Position
            local enemyPosition = enemy.HumanoidRootPart.Position

            -- Tính toán vị trí mà quái vật cần đến (đặt lại gần nhân vật)
            local newPosition = playerPosition + (enemyPosition - playerPosition).Unit * 5  -- Quái vật sẽ xuất hiện cách người chơi 5 studs

            -- Kiểm tra và điều chỉnh vị trí Y của quái vật để nó luôn đứng trên mặt đất
            local terrain = workspace:FindFirstChild("Terrain")
            local groundY = terrain and terrain:WorldToCellPreferSolid(newPosition).Y or 0  -- Xác định độ cao của mặt đất tại vị trí mới
            
            -- Đặt vị trí quái vật mới, đảm bảo nó ở trên mặt đất
            newPosition = Vector3.new(newPosition.X, groundY + 2, newPosition.Z)  -- Đảm bảo quái vật đứng trên mặt đất

            -- Teleport quái vật đến vị trí mới
            enemy.HumanoidRootPart.CFrame = CFrame.new(newPosition)

            -- Khôi phục hành động của quái vật
            local humanoid = enemy:FindFirstChild("Humanoid")
            if humanoid then
                -- Đảm bảo quái vật có thể tiếp tục di chuyển bình thường
                humanoid:MoveTo(newPosition)  -- Đảm bảo rằng quái vật di chuyển đến vị trí mới
                
                -- Tăng tốc độ nếu cần (giữ tốc độ di chuyển mặc định)
                humanoid.WalkSpeed = 16 

                -- Giữ nguyên trạng thái di chuyển hoặc hành động
                humanoid:MoveTo(enemy.HumanoidRootPart.Position)  -- Đảm bảo quái vật không bị "đơ" và tiếp tục hành động
            end
        end
    end

    -- Hàm kiểm tra và tự động teleport các quái vật trong thư mục Enemies
    function AutoTeleportEnemies()
        -- Lấy tất cả các quái vật từ thư mục Enemies
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        local teleportCount = 0 -- Biến đếm số lượng quái vật đã teleport
        
        -- Kiểm tra nếu thư mục Enemies tồn tại
        if enemiesFolder then
            -- Duyệt qua tất cả quái vật trong thư mục Enemies
            for _, enemy in pairs(enemiesFolder:GetChildren()) do
                -- Kiểm tra xem đối tượng có phải là quái vật (có HumanoidRootPart và Humanoid)
                if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") then
                    -- Nếu đã teleport 5 quái vật, dừng lại
                    if teleportCount >= 5 then
                        break
                    end
                    
                    -- Gọi hàm teleport quái vật về phía nhân vật
                    TeleportEnemyToPlayer(enemy)

                    -- Tăng biến đếm
                    teleportCount = teleportCount + 1
                end
            end
        end
    end

    -- Hàm tự động kiểm tra và teleport liên tục
    task.spawn(function()
        while true do
            -- Gọi hàm tự động teleport quái vật trong thư mục Enemies
            AutoTeleportEnemies()

            -- Chờ một chút trước khi kiểm tra lại
            task.wait(6) -- Điều chỉnh thời gian giữa các lần kiểm tra (5 giây)
        end
    end)
end

function CheckLevelPlyer()
  local level = tonumber(player.PlayerStats.value)
  print(level)
end
CheckLevelPlyer()
print(CheckLevelPlyer())

-- function Check()
--     if player.level > le
-- end
function fly()
    -- Hàm tải bản đồ (chunks) bất đồng bộ khi bay
    local function loadMapChunksWhileFlying(player, chunkSize, maxDistance, loadDistance)
        -- Kiểm tra nếu nhân vật hợp lệ
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Hàm tạo một mảnh bản đồ (chunk) giả lập (có thể thay thế bằng mô hình hoặc đối tượng game thực tế)
        local function loadChunk(position)
            local chunk = Instance.new("Part")
            chunk.Size = Vector3.new(chunkSize, 1, chunkSize)
            chunk.Position = position
            chunk.Anchored = true
            chunk.Parent = workspace
            chunk.Name = "MapChunk"
            
            -- Giả lập tải dữ liệu mảnh với độ trễ nhỏ để không làm gián đoạn game
            wait(0.05)
        end
    
        -- Hàm để tải các mảnh bản đồ gần người chơi
        local function loadNearbyChunks()
            local playerPosition = humanoidRootPart.Position
            local minX = playerPosition.X - maxDistance
            local maxX = playerPosition.X + maxDistance
            local minZ = playerPosition.Z - maxDistance
            local maxZ = playerPosition.Z + maxDistance
    
            -- Lặp qua các mảnh bản đồ xung quanh người chơi để tải
            for x = minX, maxX, chunkSize do
                for z = minZ, maxZ, chunkSize do
                    loadChunk(Vector3.new(x, playerPosition.Y, z))
                end
            end
        end
    
        -- Tạo sự kiện lắng nghe thay đổi vị trí của người chơi khi bay
        game:GetService("RunService").Heartbeat:Connect(function()
            -- Khi người chơi đang bay, tải các mảnh xung quanh
            loadNearbyChunks()
        end)
    end
    
    -- Gọi hàm tải bản đồ cho người chơi
    local player = game.Players.LocalPlayer
    local chunkSize = 100000000000000000  -- Kích thước mỗi mảnh (chunk)
    local maxDistance = 3000000000000000  -- Khoảng cách tối đa tải mảnh quanh người chơi (300 studs)
    
    -- Gọi hàm tải bản đồ khi người chơi đang bay
    loadMapChunksWhileFlying(player, chunkSize, maxDistance)
    
    
        -- Hàm để nhân vật bay, di chuyển, đứng yên và xuyên qua các vật thể, nhưng không rơi xuống đất
    local function flyAndPassThrough(character, flyHeight, moveSpeed)
        -- Kiểm tra nhân vật và các thành phần cần thiết
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("Nhân vật không hợp lệ!")
            return
        end
    
        -- Lấy HumanoidRootPart
        local rootPart = character:FindFirstChild("HumanoidRootPart")
    
        -- Tạo BodyVelocity để kiểm soát lực di chuyển
        local bodyVelocity = Instance.new("BodyVelocity", rootPart)
        bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5) -- Di chuyển trên trục XZ, không tác động trục Y
        bodyVelocity.Velocity = Vector3.zero -- Ban đầu không di chuyển
    
        -- Tạo BodyPosition để giữ nhân vật ở độ cao cố định
        local bodyPosition = Instance.new("BodyPosition", rootPart)
        bodyPosition.MaxForce = Vector3.new(0, 1e5, 0) -- Chỉ tác động trục Y
        bodyPosition.Position = Vector3.new(rootPart.Position.X, flyHeight, rootPart.Position.Z)
        bodyPosition.D = 10 -- Giảm dao động khi giữ vị trí
    
        -- Bật chế độ xuyên tường cho nhân vật
        -- for _, part in pairs(character:GetDescendants()) do
        --     if part:IsA("BasePart") then
        --         part.CanCollide = false
        --     end
        -- end
    
        -- Bật chế độ xuyên qua tất cả các vật thể trong game, trừ mặt đất
        -- for _, obj in pairs(workspace:GetDescendants()) do
        --     if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
        --         obj.CanCollide = false
        --     end
        -- end
    
        -- Theo dõi hướng di chuyển từ bàn phím (WASD)
        game:GetService("RunService").RenderStepped:Connect(function()
            local moveDirection = game.Players.LocalPlayer.Character.Humanoid.MoveDirection
    
            if moveDirection.Magnitude > 0 then
                -- Di chuyển nếu có input từ người chơi
                bodyVelocity.Velocity = Vector3.new(
                    moveDirection.X * moveSpeed,
                    0, -- Không tác động trục Y
                    moveDirection.Z * moveSpeed
                )
            else
                -- Đứng yên nếu không có input từ người chơi
                bodyVelocity.Velocity = Vector3.zero
            end
        end)
    end
    
    -- Gọi hàm flyAndPassThrough
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Nhân vật bay lên cao 50 đơn vị, di chuyển với tốc độ 20, và xuyên qua tất cả
    flyAndPassThrough(character, 200, 1000)
    end
    fly()
    
    
    function Killl()
        -- Hàm xử lý tấn công nhanh với khả năng điều chỉnh tốc độ tấn công
    local function fastAutoAttack(character, range, damage, attackSpeed)
        -- Kiểm tra nếu nhân vật và quái vật hợp lệ
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("Nhân vật không hợp lệ!")
            return
        end
    
        local lastAttackTime = 0  -- Thời gian của lần tấn công cuối cùng
        local cooldown = 1 / attackSpeed  -- Tính cooldown dựa trên tốc độ tấn công (s)
    
        -- Tạo vùng ảnh hưởng (AoE) quanh nhân vật
        local function createAttackArea()
            local attackArea = Instance.new("Part")
            attackArea.Shape = Enum.PartType.Ball
            attackArea.Size = Vector3.new(range, range, range)  -- Kích thước của vùng tấn công
            attackArea.Transparency = 0.5
            attackArea.CanCollide = false
            attackArea.Position = character.HumanoidRootPart.Position
            attackArea.Parent = workspace
    
            local light = Instance.new("PointLight")
            light.Parent = attackArea
            light.Range = range
            light.Brightness = 5
    
            wait(1)  -- Hiệu ứng tồn tại trong 1 giây
            attackArea:Destroy()  -- Xóa vùng ảnh hưởng sau 1 giây
        end
    
        -- Lắng nghe sự kiện va chạm
        character.HumanoidRootPart.Touched:Connect(function(hit)
            -- Kiểm tra nếu đối tượng va chạm là quái vật
            if hit and hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
                local enemy = hit.Parent
                local currentTime = tick()  -- Thời gian hiện tại
    
                -- Kiểm tra cooldown giữa các lần tấn công
                if currentTime - lastAttackTime >= cooldown then
                    lastAttackTime = currentTime  -- Cập nhật thời gian tấn công mới
    
                    -- Tạo vùng ảnh hưởng (AoE)
                    createAttackArea()
    
                    -- Gửi thông tin tấn công mạnh (RegisterHit)
                    local argsHit = {
                        [1] = enemy:FindFirstChild("RightHand"),  -- Phần cơ thể của quái vật (RightHand)
                        [2] = {}  -- Các thông tin tấn công khác
                    }
                    game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RE/RegisterHit"):FireServer(unpack(argsHit))
                    
                    -- Gửi thông tin tấn công mạnh (RegisterAttack) với lượng damage
                    local argsAttack = {
                        [1] = damage  -- Sát thương mỗi lần tấn công
                    }
                    game:GetService("ReplicatedStorage").Modules.Net:FindFirstChild("RE/RegisterAttack"):FireServer(unpack(argsAttack))
    
                    -- In thông báo tấn công
                    print("Tấn công nhanh vào quái vật: " .. enemy.Name .. " với sát thương " .. damage)
                end
            end
        end)
    end
    
    -- Gọi hàm tự động tấn công nhanh với phạm vi tấn công lớn và sát thương mạnh
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    local attackRange = 1000  -- Phạm vi tấn công (radius của vùng ảnh hưởng)
    local attackDamage = 100000000000000000000000000  -- Sát thương mỗi lần tấn công
    local attackSpeed = 100000   -- Tốc độ tấn công (tấn công mỗi 0.5 giây)
    
    fastAutoAttack(character, attackRange, attackDamage, attackSpeed)
    
    end
    Killl()
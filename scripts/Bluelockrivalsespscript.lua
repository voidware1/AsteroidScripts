--====================================================--
-- VOIDWARE FOOTBALL HUB
-- WINDUI + BALL PREDICTION + PLAYER RACE + HEADER ESP
--====================================================--

--====================================================--
-- WINDUI
--====================================================--

local _version = "1.6.66"

local WindUI = loadstring(
    game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/download/"
            .. _version
            .. "/main.lua"
    )
)()

local Window = WindUI:CreateWindow({
    Title = "Voidware Football",
    Icon = "football",
    Author = "Voidware",
})

local Tab = Window:Tab({
    Title = "Football",
    Icon = "house",
})

--====================================================--
-- SERVICES
--====================================================--

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--====================================================--
-- SETTINGS
--====================================================--

local ballPredictionEnabled = true
local playerRaceEnabled = true
local headerESPEnabled = true

local predictionTime = 3
local stepTime = 0.05

local predictionUpdateRate = 1 / 20
local raceUpdateRate = 1 / 10
local headerUpdateRate = 1 / 15

local bounceDamping = 0.75
local surfaceFriction = 0.85

local playerSpeedFallback = 16

-- Default jump height
local HEADER_HEIGHT = 11

-- Lower number = less transparent
local HEADER_TRANSPARENCY = 0.10

local gravity = Vector3.new(
    0,
    -workspace.Gravity,
    0
)

--====================================================--
-- COLORS
--====================================================--

local LINE_COLOR = Color3.fromRGB(
    0,
    170,
    255
)

local BOUNCE_COLOR = Color3.fromRGB(
    0,
    255,
    0
)

local YOU_COLOR = Color3.fromRGB(
    0,
    255,
    100
)

local THEM_COLOR = Color3.fromRGB(
    255,
    70,
    70
)

local HEADER_COLOR = Color3.fromRGB(
    0,
    255,
    80
)

--====================================================--
-- FOOTBALL
--====================================================--

local ball = nil

local function findBall()

    local found =
        workspace:FindFirstChild("Football")

    if found and found:IsA("BasePart") then

        ball = found

        return true
    end

    ball = nil

    return false
end

--====================================================--
-- FOLDERS
--====================================================--

local predictionFolder =
    Instance.new("Folder")

predictionFolder.Name =
    "BallPrediction"

predictionFolder.Parent =
    workspace


local raceFolder =
    Instance.new("Folder")

raceFolder.Name =
    "BallRaceIndicator"

raceFolder.Parent =
    workspace


local headerFolder =
    Instance.new("Folder")

headerFolder.Name =
    "HeaderESP"

headerFolder.Parent =
    workspace

--====================================================--
-- RAYCAST
--====================================================--

local rayParams =
    RaycastParams.new()

rayParams.FilterType =
    Enum.RaycastFilterType.Exclude

rayParams.FilterDescendantsInstances = {
    predictionFolder,
    raceFolder,
    headerFolder
}

--====================================================--
-- BALL PREDICTION
--====================================================--

local linePool = {}
local pointPool = {}

local function getLine(index)

    local line =
        linePool[index]

    if not line then

        line =
            Instance.new("Part")

        line.Name =
            "TrajectoryLine"

        line.Anchored =
            true

        line.CanCollide =
            false

        line.CanTouch =
            false

        line.CanQuery =
            false

        line.Material =
            Enum.Material.Neon

        line.Color =
            LINE_COLOR

        line.Parent =
            predictionFolder

        linePool[index] =
            line
    end

    line.Transparency =
        0

    return line
end


local function getPoint(index)

    local point =
        pointPool[index]

    if not point then

        point =
            Instance.new("Part")

        point.Name =
            "BouncePoint"

        point.Shape =
            Enum.PartType.Block

        point.Anchored =
            true

        point.CanCollide =
            false

        point.CanTouch =
            false

        point.CanQuery =
            false

        point.Material =
            Enum.Material.Neon

        point.Color =
            BOUNCE_COLOR

        point.Parent =
            predictionFolder

        pointPool[index] =
            point
    end

    point.Transparency =
        0.25

    return point
end


local function hidePrediction()

    for _, line in ipairs(linePool) do

        line.Transparency =
            1
    end

    for _, point in ipairs(pointPool) do

        point.Transparency =
            1
    end
end


local function hideUnused(
    lineCount,
    pointCount
)

    for i =
        lineCount + 1,
        #linePool do

        linePool[i].Transparency =
            1
    end

    for i =
        pointCount + 1,
        #pointPool do

        pointPool[i].Transparency =
            1
    end
end

--====================================================--
-- PREDICT BALL
--====================================================--

local predictedPosition = nil

local function predict()

    if not ballPredictionEnabled then

        hidePrediction()

        predictedPosition = nil

        return
    end

    if not findBall() then

        hidePrediction()

        predictedPosition = nil

        return
    end

    rayParams.FilterDescendantsInstances = {
        ball,
        predictionFolder,
        raceFolder,
        headerFolder
    }

    local position =
        ball.Position

    local velocity =
        ball.AssemblyLinearVelocity

    local radius =
        math.max(
            ball.Size.X,
            ball.Size.Y,
            ball.Size.Z
        ) / 2

    local previousPosition =
        position

    local elapsed = 0

    local lineIndex = 0
    local pointIndex = 0

    while elapsed < predictionTime do

        local dt =
            math.min(
                stepTime,
                predictionTime - elapsed
            )

        velocity +=
            gravity * dt

        local nextPosition =
            position +
            velocity * dt

        local movement =
            nextPosition -
            position

        if movement.Magnitude > 0 then

            local result =
                workspace:Raycast(
                    position,
                    movement.Unit *
                        (
                            movement.Magnitude +
                            radius
                        ),
                    rayParams
                )

            if result then

                local hitPosition =
                    result.Position +
                    result.Normal *
                    radius

                local distance =
                    (
                        hitPosition -
                        previousPosition
                    ).Magnitude

                if distance > 0.01 then

                    lineIndex += 1

                    local line =
                        getLine(lineIndex)

                    line.Size =
                        Vector3.new(
                            0.08,
                            0.08,
                            distance
                        )

                    line.CFrame =
                        CFrame.lookAt(
                            (
                                previousPosition +
                                hitPosition
                            ) / 2,
                            hitPosition
                        )
                end

                pointIndex += 1

                local point =
                    getPoint(pointIndex)

                point.Size =
                    Vector3.new(
                        0.3,
                        0.3,
                        0.3
                    )

                point.CFrame =
                    CFrame.new(
                        hitPosition
                    )

                velocity =
                    velocity -
                    2 *
                    velocity:Dot(
                        result.Normal
                    ) *
                    result.Normal

                velocity *=
                    bounceDamping

                local normalVelocity =
                    result.Normal *
                    velocity:Dot(
                        result.Normal
                    )

                local tangentVelocity =
                    velocity -
                    normalVelocity

                velocity =
                    normalVelocity +
                    tangentVelocity *
                    surfaceFriction

                position =
                    hitPosition +
                    result.Normal *
                    0.01

            else

                position =
                    nextPosition

                local distance =
                    (
                        position -
                        previousPosition
                    ).Magnitude

                if distance > 0.01 then

                    lineIndex += 1

                    local line =
                        getLine(lineIndex)

                    line.Size =
                        Vector3.new(
                            0.08,
                            0.08,
                            distance
                        )

                    line.CFrame =
                        CFrame.lookAt(
                            (
                                previousPosition +
                                position
                            ) / 2,
                            position
                        )
                end
            end

            previousPosition =
                position
        end

        elapsed += dt
    end

    predictedPosition =
        position

    pointIndex += 1

    local finalPoint =
        getPoint(pointIndex)

    finalPoint.Size =
        Vector3.new(
            0.4,
            0.4,
            0.4
        )

    finalPoint.CFrame =
        CFrame.new(position)

    hideUnused(
        lineIndex,
        pointIndex
    )
end

--====================================================--
-- PLAYER RACE
--====================================================--

local raceLine =
    Instance.new("Part")

raceLine.Name =
    "ClosestPlayerLine"

raceLine.Anchored =
    true

raceLine.CanCollide =
    false

raceLine.CanTouch =
    false

raceLine.CanQuery =
    false

raceLine.Material =
    Enum.Material.Neon

raceLine.Transparency =
    1

raceLine.Parent =
    raceFolder

--====================================================--
-- BILLBOARD
--====================================================--

local billboard =
    Instance.new("BillboardGui")

billboard.Name =
    "BallRaceBillboard"

billboard.Size =
    UDim2.new(
        0,
        150,
        0,
        45
    )

billboard.StudsOffset =
    Vector3.new(
        0,
        3,
        0
    )

billboard.AlwaysOnTop =
    true

billboard.MaxDistance =
    120

billboard.Enabled =
    false

billboard.Parent =
    LocalPlayer:WaitForChild(
        "PlayerGui"
    )


local label =
    Instance.new("TextLabel")

label.Size =
    UDim2.fromScale(
        1,
        1
    )

label.BackgroundTransparency =
    1

label.Text =
    ""

label.Font =
    Enum.Font.GothamBold

label.TextScaled =
    true

label.TextStrokeTransparency =
    0.25

label.TextStrokeColor3 =
    Color3.fromRGB(
        0,
        0,
        0
    )

label.Parent =
    billboard

--====================================================--
-- PLAYER ROOT
--====================================================--

local function getRoot(player)

    if not player.Character then
        return nil
    end

    return player.Character:
        FindFirstChild(
            "HumanoidRootPart"
        )
end

--====================================================--
-- ARRIVAL TIME
--====================================================--

local function getArrivalTime(
    player,
    targetPosition
)

    local root =
        getRoot(player)

    if not root then
        return math.huge
    end

    local distance =
        (
            root.Position -
            targetPosition
        ).Magnitude

    local velocity =
        root.AssemblyLinearVelocity

    local horizontalVelocity =
        Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )

    local speed =
        horizontalVelocity.Magnitude

    if speed < 2 then

        speed =
            playerSpeedFallback
    end

    return
        (
            distance /
            math.max(
                speed,
                1
            )
        ) +
        0.12
end

--====================================================--
-- FIRST BOUNCE
--====================================================--

local function getFirstBouncePosition()

    if not ball
        or not ball.Parent then

        return nil
    end

    local position =
        ball.Position

    local velocity =
        ball.AssemblyLinearVelocity

    local radius =
        math.max(
            ball.Size.X,
            ball.Size.Y,
            ball.Size.Z
        ) / 2

    local elapsed = 0

    while elapsed < predictionTime do

        local dt =
            math.min(
                stepTime,
                predictionTime - elapsed
            )

        velocity +=
            gravity * dt

        local nextPosition =
            position +
            velocity * dt

        local movement =
            nextPosition -
            position

        if movement.Magnitude > 0 then

            local result =
                workspace:Raycast(
                    position,
                    movement.Unit *
                        (
                            movement.Magnitude +
                            radius
                        ),
                    rayParams
                )

            if result then

                if result.Normal.Y > 0.6 then

                    return
                        result.Position +
                        result.Normal *
                        radius
                end

                velocity =
                    velocity -
                    2 *
                    velocity:Dot(
                        result.Normal
                    ) *
                    result.Normal

                velocity *=
                    bounceDamping

                local normalVelocity =
                    result.Normal *
                    velocity:Dot(
                        result.Normal
                    )

                local tangentVelocity =
                    velocity -
                    normalVelocity

                velocity =
                    normalVelocity +
                    tangentVelocity *
                    surfaceFriction

                position =
                    result.Position +
                    result.Normal *
                    (radius + 0.01)

            else

                position =
                    nextPosition
            end
        end

        elapsed += dt
    end

    return nil
end

--====================================================--
-- HIDE RACE
--====================================================--

local function hideRace()

    billboard.Enabled =
        false

    raceLine.Transparency =
        1
end

--====================================================--
-- CLOSEST PLAYER
--====================================================--

local function findClosestPlayerToBounce(
    bouncePosition
)

    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        local root =
            getRoot(player)

        if root then

            local distance =
                (
                    root.Position -
                    bouncePosition
                ).Magnitude

            if distance <
                closestDistance then

                closestDistance =
                    distance

                closestPlayer =
                    player
            end
        end
    end

    return closestPlayer
end

--====================================================--
-- UPDATE RACE
--====================================================--

local function updateRaceIndicator()

    if not playerRaceEnabled then

        hideRace()

        return
    end

    if not findBall() then

        hideRace()

        return
    end

    local bouncePosition =
        getFirstBouncePosition()

    if not bouncePosition then

        hideRace()

        return
    end

    local closestPlayer =
        findClosestPlayerToBounce(
            bouncePosition
        )

    if not closestPlayer then

        hideRace()

        return
    end

    local myRoot =
        getRoot(
            LocalPlayer
        )

    if not myRoot then

        hideRace()

        return
    end

    local myTime =
        getArrivalTime(
            LocalPlayer,
            bouncePosition
        )

    local theirTime =
        getArrivalTime(
            closestPlayer,
            bouncePosition
        )

    local targetRoot =
        getRoot(
            closestPlayer
        )

    if targetRoot then

        local start =
            targetRoot.Position

        local finish =
            bouncePosition

        local distance =
            (
                finish -
                start
            ).Magnitude

        if distance > 0.05 then

            raceLine.Size =
                Vector3.new(
                    0.1,
                    0.1,
                    distance
                )

            raceLine.CFrame =
                CFrame.lookAt(
                    (
                        start +
                        finish
                    ) / 2,
                    finish
                )

            if closestPlayer ==
                LocalPlayer then

                raceLine.Color =
                    YOU_COLOR

            else

                raceLine.Color =
                    THEM_COLOR
            end

            raceLine.Transparency =
                0
        end
    end

    billboard.Adornee =
        ball

    billboard.Enabled =
        true

    if myTime <= theirTime then

        label.Text =
            "YOU GET IT"

        label.TextColor3 =
            YOU_COLOR

    else

        label.Text =
            "THEY GET IT"

        label.TextColor3 =
            THEM_COLOR
    end
end

--====================================================--
-- HEADER ESP
--====================================================--

local headerBox =
    Instance.new("Part")

headerBox.Name =
    "HeaderPosition"

headerBox.Size =
    Vector3.new(
        2.5,
        5,
        2.5
    )

headerBox.Anchored =
    true

headerBox.CanCollide =
    false

headerBox.CanTouch =
    false

headerBox.CanQuery =
    false

headerBox.Material =
    Enum.Material.Neon

headerBox.Color =
    HEADER_COLOR

headerBox.Transparency =
    1

headerBox.Parent =
    headerFolder

--====================================================--
-- GROUND HEIGHT
--====================================================--

local function getGroundHeight(position)

    local result =
        workspace:Raycast(
            position +
            Vector3.new(
                0,
                5,
                0
            ),

            Vector3.new(
                0,
                -300,
                0
            ),

            rayParams
        )

    if result then

        return result.Position.Y
    end

    return nil
end

--====================================================--
-- HEADER POSITION
--====================================================--

local function getHeaderPosition()

    if not ball
        or not ball.Parent then

        return nil
    end

    local position =
        ball.Position

    local velocity =
        ball.AssemblyLinearVelocity

    local radius =
        math.max(
            ball.Size.X,
            ball.Size.Y,
            ball.Size.Z
        ) / 2

    local previousPosition =
        position

    local elapsed = 0

    while elapsed < predictionTime do

        local dt =
            math.min(
                stepTime,
                predictionTime - elapsed
            )

        velocity +=
            gravity * dt

        local nextPosition =
            position +
            velocity * dt

        local movement =
            nextPosition -
            position

        local nextValidPosition =
            nextPosition

        if movement.Magnitude > 0 then

            local result =
                workspace:Raycast(
                    position,
                    movement.Unit *
                        (
                            movement.Magnitude +
                            radius
                        ),
                    rayParams
                )

            if result then

                if result.Normal.Y > 0.6 then

                    nextValidPosition =
                        result.Position +
                        result.Normal *
                        radius

                else

                    velocity =
                        velocity -
                        2 *
                        velocity:Dot(
                            result.Normal
                        ) *
                        result.Normal

                    velocity *=
                        bounceDamping

                    local normalVelocity =
                        result.Normal *
                        velocity:Dot(
                            result.Normal
                        )

                    local tangentVelocity =
                        velocity -
                        normalVelocity

                    velocity =
                        normalVelocity +
                        tangentVelocity *
                        surfaceFriction

                    nextValidPosition =
                        result.Position +
                        result.Normal *
                        (radius + 0.01)
                end
            end
        end

        local previousGroundY =
            getGroundHeight(
                previousPosition
            )

        local currentGroundY =
            getGroundHeight(
                nextValidPosition
            )

        if previousGroundY
            and currentGroundY then

            local previousTargetY =
                previousGroundY +
                HEADER_HEIGHT

            local currentTargetY =
                currentGroundY +
                HEADER_HEIGHT

            local previousDifference =
                previousPosition.Y -
                previousTargetY

            local currentDifference =
                nextValidPosition.Y -
                currentTargetY

            if
                previousDifference >= 0
                and currentDifference <= 0
            then

                local denominator =
                    previousDifference -
                    currentDifference

                local alpha = 0

                if math.abs(
                    denominator
                ) > 0.0001 then

                    alpha =
                        previousDifference /
                        denominator
                end

                alpha =
                    math.clamp(
                        alpha,
                        0,
                        1
                    )

                local crossing =
                    previousPosition:Lerp(
                        nextValidPosition,
                        alpha
                    )

                local exactGround =
                    getGroundHeight(
                        crossing
                    )

                if exactGround then

                    crossing =
                        Vector3.new(
                            crossing.X,
                            exactGround +
                                HEADER_HEIGHT,
                            crossing.Z
                        )
                end

                return crossing
            end
        end

        previousPosition =
            nextValidPosition

        position =
            nextValidPosition

        elapsed += dt
    end

    return nil
end

--====================================================--
-- UPDATE HEADER
--====================================================--

local function updateHeaderESP()

    if not headerESPEnabled then

        headerBox.Transparency =
            1

        return
    end

    if not findBall() then

        headerBox.Transparency =
            1

        return
    end

    local headerPosition =
        getHeaderPosition()

    if not headerPosition then

        headerBox.Transparency =
            1

        return
    end

    headerBox.CFrame =
        CFrame.new(
            headerPosition
        )

    headerBox.Transparency =
        HEADER_TRANSPARENCY
end

--====================================================--
-- WINDUI TOGGLES
--====================================================--

Tab:Toggle({
    Title = "Ball Prediction",
    Desc = "Show the predicted football trajectory",
    Value = true,

    Callback = function(state)

        ballPredictionEnabled =
            state

        if not state then
            hidePrediction()
        end
    end
})

Tab:Toggle({
    Title = "Player Race",
    Desc = "Show who reaches the first bounce first",
    Value = true,

    Callback = function(state)

        playerRaceEnabled =
            state

        if not state then
            hideRace()
        end
    end
})

Tab:Toggle({
    Title = "Header ESP",
    Desc = "Show where you need to be to head the ball",
    Value = true,

    Callback = function(state)

        headerESPEnabled =
            state

        if not state then

            headerBox.Transparency =
                1
        end
    end
})

--====================================================--
-- UPDATE LOOP
--====================================================--

local predictionTimer = 0
local raceTimer = 0
local headerTimer = 0

RunService.Heartbeat:Connect(
    function(dt)

        predictionTimer += dt
        raceTimer += dt
        headerTimer += dt

        if predictionTimer >=
            predictionUpdateRate then

            predictionTimer = 0

            predict()
        end

        if raceTimer >=
            raceUpdateRate then

            raceTimer = 0

            updateRaceIndicator()
        end

        if headerTimer >=
            headerUpdateRate then

            headerTimer = 0

            updateHeaderESP()
        end
    end
)

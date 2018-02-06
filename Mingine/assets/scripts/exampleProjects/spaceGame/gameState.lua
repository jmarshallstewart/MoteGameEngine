------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
MAX_ENEMIES = 64
MAX_PROJECTILES = 256
MAX_CARGO = 9
MAX_EXPLOSIONS = 256

SHIELD_BAR_X = 8
SHIELD_BAR_Y = 16
SHIELD_BAR_WIDTH = math.floor(SCREEN_WIDTH * 0.16)
SHIELD_BAR_HEIGHT = math.floor(SCREEN_HEIGHT * 0.01)

HEALTH_BAR_X = 8
HEALTH_BAR_Y = 32
HEALTH_BAR_WIDTH = math.floor(SCREEN_WIDTH * 0.16)
HEALTH_BAR_HEIGHT = math.floor(SCREEN_HEIGHT * 0.01)

ENEMY_STATE_ATTACK = 1
ENEMY_STATE_STEAL = 2
ENEMY_STATE_FLEE = 3

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------
--enemies
enemyPool = nil

--cargo
cargoPool = nil

--explosions
explosionPool = nil

--player
player = nil

--projectiles
projectilePool = nil

--spawner
spawnTimer = 4000.0
spawnDelay = 400

gameInProgress = false

gameState = {}
gameState.notifications = {}
gameState.fontSize = 20
gameState.font = nil
gameState.playTime = 0
gameState.music = nil
gameState.prevDownButton7 = 0

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------
function GameState_AddText(text)
    gameState.notifications[#gameState.notifications + 1] = text
end

function AddScore(points)
    stats.score = stats.score + points * #cargoPool.activeList
end

function GetNearestEnemy(x, y)
    local numEnemies = #enemyPool.activeList
    
    if numEnemies == 0 then
        return nil
    end

    local enemy = enemyPool.activeList[numEnemies]
    local minDistance = DistanceSquared(x, y, enemy.x, enemy.y)
    local nearestEnemy = enemy
    
    for i = numEnemies - 1, 1, -1 do
        enemy = enemyPool.activeList[i]
        local distanceSquared = DistanceSquared(x, y, enemy.x, enemy.y)
        if distanceSquared < minDistance then
            minDistance = distanceSquared
            nearestEnemy = enemy
        end
    end
    
    return nearestEnemy
end

function GetNearestCargo(x, y)
    local numCargo = #cargoPool.activeList
    
    if numCargo == 0 then
        return nil
    end

    local cargo = cargoPool.activeList[numCargo]
    local minDistance = DistanceSquared(x, y, cargo.x, cargo.y)
    local nearestCargo = cargo
    
    for i = numCargo - 1, 1, -1 do
        cargo = cargoPool.activeList[i]
        local distanceSquared = DistanceSquared(x, y, cargo.x, cargo.y)
        if distanceSquared < minDistance then
            minDistance = distanceSquared
            nearestCargo = cargo
        end
    end
    
    return nearestCargo
end

function OnDefeat()
    gameInProgress = false
    GotoState(DEFEAT_STATE)
end

function OnDefeatEnemy(enemy)
    AddScore(enemy.score)
    PlaySound(enemy.defeatSfx)
    stats.enemiesDefeated = stats.enemiesDefeated + 1
    enemyPool.free(enemy)
end

function OnDamagePlayer(damage)
    stats.damageTaken = stats.damageTaken + damage
    player.shieldRechargeTimer = player.shieldRechargeDelay

    player.shields = player.shields - damage
    
    if player.shields < 0 then
        player.health = player.health - player.shields * -1
        player.shields = 0
    end
    
    if player.health <= 0 then
        defeatState.reason = "You took too much damage."
        OnDefeat()
    end
end

function ImproveEnemies()
    enemyParams.frame = math.random(2, 30)
    enemyParams.scale = math.random(1, 4)
    enemyParams.angle = 0
    enemyParams.health = enemyParams.health + math.random(0, 1)
    enemyParams.melee = enemyParams.melee + math.random(2, 5)
    enemyParams.score = enemyParams.score + 1
    enemyParams.target = player
    enemyParams.maxSpeed = enemyParams.maxSpeed + 0.3
    enemyParams.speed = enemyParams.speed + 0.3
    enemyParams.turnRate = math.random(1, 8)
    enemyParams.wobbleLimit = math.random(0, 40)
    enemyParams.wobbleSpeed = math.random(1, 20)
    
    spawnDelay = spawnDelay * 0.9
end

function DrawShieldBar()
    local complete = math.min(player.shields / player.maxShields, 1)
    SetDrawColor(127, 168, 127, 255)
    FillRect(SHIELD_BAR_X, SHIELD_BAR_Y, SHIELD_BAR_WIDTH, SHIELD_BAR_HEIGHT)
    
    SetDrawColor(0, 0, 255, 255)
    FillRect(SHIELD_BAR_X, SHIELD_BAR_Y, SHIELD_BAR_WIDTH * complete, SHIELD_BAR_HEIGHT)
end

function DrawHealthBar()
    local complete = math.min(player.health / player.maxHealth, 1)
    SetDrawColor(127, 168, 127, 255)
    FillRect(HEALTH_BAR_X, HEALTH_BAR_Y, HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
    
    SetDrawColor(0, 255, 0, 255)
    FillRect(HEALTH_BAR_X, HEALTH_BAR_Y, HEALTH_BAR_WIDTH * complete, HEALTH_BAR_HEIGHT)
end

function SpawnProjectile(e, params)
    SetEntity(e, params.image, params.x, params.y, params.frameWidth, params.frameHeight)
    SetEntityScale(e, 4)
    e.angle = params.angle
        
    e.acceleration.x = math.cos(math.rad(e.angle)) * params.speed
    e.acceleration.y = math.sin(math.rad(e.angle)) * params.speed
           
    e.lifeTime = params.lifeTime
    e.frame = params.frame
    e.collisionRadius = params.collisionRadius
    e.damage = params.damage
    e.isHoming = params.isHoming
    e.turnRate = params.turnRate
    e.r = params.r
    e.g = params.g
    e.b = params.b
    e.a = params.a
    e.hitSfx = params.hitSfx
end

function SpawnCargo(e, params)
    SetEntity(e, params.image, params.x, params.y, params.frameWidth, params.frameHeight)
    e.angle = params.angle
    e.collisionRadius = params.collisionRadius
    SetEntityScale(e, params.scale)
       
    e.frame = params.frame
end

function SpawnEnemy(e, params)
    local spawnAngle = math.random() * math.pi * 2
    local length = Magnitude(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2) 
    offset = {}
    SetVector(offset, (SCREEN_WIDTH / 2) + math.cos(spawnAngle) * length, (SCREEN_HEIGHT / 2) + math.sin(spawnAngle) * length)

    SetEntity(e, params.image, offset.x, offset.y, params.frameWidth, params.frameHeight)
    e.angle = params.angle
    SetEntityScale(e, params.scale)
    e.frame = params.frame
    e.health = params.health
    e.melee = params.melee
    e.score = params.score
    e.target = params.target
    e.speed = params.speed
    e.maxSpeed = params.maxSpeed
    e.defeatSfx = params.defeatSfx
    e.collisionRadius = 8 * params.scale
    e.attachedCargo = nil
    e.attachX = 0
    e.attachY = 0
    e.lifeTime = 1
    e.r = 200
    e.g = 32
    e.b = 32
    e.a = 255
    
    local pick = math.random() 
    
    if pick < 0.8 then
        e.state = ENEMY_STATE_ATTACK
    else
        e.state = ENEMY_STATE_STEAL
    end
end

function SpawnExplosion(e, params)
    SetEntity(e, params.image, params.x, params.y, params.frameWidth, params.frameHeight)
    e.angle = math.random(0, 360)
    SetEntityScale(e, 0.5 + math.random() * 2.5)
    e.lifeTime = math.random() * params.lifeTime
    
    local pick = math.random(1, 3)
    
    if pick == 1 then
        e.r = 225
        e.g = 225
        e.b = 0
        e.a = 64
    elseif pick == 2 then
        e.r = 225
        e.g = 140
        e.b = 0
        e.a = 64
    elseif pick == 3 then
        e.r = 225
        e.g = 0
        e.b = 0
        e.a = 64
    end
        
    e.frameDuration = 1000 / math.random(6, 12)
    AddAnimationFrame(e, "idle", 33)
    AddAnimationFrame(e, "idle", 34)
    AddAnimationFrame(e, "idle", 35)
    AddAnimationFrame(e, "idle", 36)
    StartAnimation(e, "idle")
end

function UpdateExplosion(e)
    UpdateEntity(e)
    e.lifeTime = e.lifeTime - GetFrameTime()
end

function CheckEnemyCargoCollisions(e)
    local numCargo = #cargoPool.activeList
    for i = numCargo, 1, -1 do
        local cargo = cargoPool.activeList[i]
        if CirclesOverlap(e.x, e.y, e.collisionRadius, cargo.x, cargo.y, cargo.collisionRadius) then
            e.attachedCargo = cargo
            e.attachX = cargo.x - e.x
            e.attachY = cargo.y - e.y
            e.state = ENEMY_STATE_FLEE
            break;
        end
    end
end

function UpdateEnemy(e)
    if e.state == ENEMY_STATE_ATTACK then
        e.target = player
    elseif e.state == ENEMY_STATE_STEAL then
        e.target = GetNearestCargo(e.x, e.y)
    elseif e.state == ENEMY_STATE_FLEE then
        e.target = {}
        e.target.position = {}
        local dirX = 0
        local dirY = 0
        dirX, dirY = To(player, e)
        e.target.x = e.x + dirX * 100
        e.target.y = e.y + dirY * 100
    end
    
    UpdateWobbleSeek(e)
    CheckEnemyCargoCollisions(e)
    
    if e.state == ENEMY_STATE_FLEE and e.attachedCargo ~= nil then
        e.attachedCargo.x = e.x + e.attachX
        e.attachedCargo.y = e.y + e.attachY
        
        if e.attachedCargo.x > SCREEN_WIDTH or
            e.attachedCargo.y > SCREEN_HEIGHT or
            e.attachedCargo.x < 0 or
            e.attachedCargo.y < 0 then
                cargoPool.free(e.attachedCargo)
                e.lifeTime = 0
        end
    end
end

function UpdateProjectile(e)
    if e.isHoming == true then
        e.target = GetNearestEnemy(e.x, e.y)
        UpdateWobbleSeek(e)
    else
        UpdateEntity(e)
    end
    e.lifeTime = e.lifeTime - GetFrameTime()
end

function UpdateProjectiles(playerWantsFire)

    if player.fireTimer > 0 then 
        player.fireTimer = player.fireTimer - GetFrameTime()
    end
    
    if player.fireTimer <= 0.0 and playerWantsFire and projectilePool.hasFree() then
        PlaySound(player.shootSfx)
    
        projectileParams.x = player.x
        projectileParams.y = player.y
        projectileParams.frame = 32
        projectileParams.collisionRadius = 16
        
        if projectilePool.hasFree() then
            projectileParams.angle = player.angle
            projectilePool.get(projectileParams)
            stats.bulletsFired = stats.bulletsFired + 1
        end
        
        projectileParams.frame = 31
        
        if projectilePool.hasFree() then
            projectileParams.angle = player.angle + 20.0
            projectilePool.get(projectileParams)
            stats.bulletsFired = stats.bulletsFired + 1
        end
        
        if projectilePool.hasFree() then
            projectileParams.angle = player.angle - 20.0
            projectilePool.get(projectileParams)
            stats.bulletsFired = stats.bulletsFired + 1
        end
        
        player.fireTimer = player.fireTimer + player.fireDelay
    end

    projectilePool.each(UpdateProjectile)
end

function UpdateSpawner()
    if spawnTimer > 0 then 
        spawnTimer = spawnTimer - GetFrameTime()
    end
    
    if spawnTimer <= 0.0 and enemyPool.hasFree() then
        w = enemyParams.frameWidth * enemyParams.scale
        h = enemyParams.frameHeight * enemyParams.scale
        
        enemyParams.x = math.random(w / 2, SCREEN_WIDTH - w / 2)
        enemyParams.y = math.random(h / 2, SCREEN_HEIGHT - h / 2)
        enemyPool.get(enemyParams)
        
        spawnTimer = spawnTimer + spawnDelay
    end
end

function CullOldProjectiles()
    local numProjectiles = #projectilePool.activeList
    for i = numProjectiles, 1, -1 do
        if projectilePool.activeList[i].lifeTime <= 0 then
            projectilePool.free(projectilePool.activeList[i])
        end
    end
end

function CullOldExplosions()
    local numExplosions = #explosionPool.activeList
    for i = numExplosions, 1, -1 do
        if explosionPool.activeList[i].lifeTime <= 0 then
            explosionPool.free(explosionPool.activeList[i])
        end
    end
end

function CullEscapedEnemies()
    local numEnemies = #enemyPool.activeList
    for i = numEnemies, 1, -1 do
        if enemyPool.activeList[i].lifeTime <= 0 then
            enemyPool.free(enemyPool.activeList[i])
        end
    end
end

function CheckProjectileEnemyCollisions()
    numProjectiles = #projectilePool.activeList
    for i = numProjectiles, 1, -1 do
        local numEnemies = #enemyPool.activeList
        local projectile = projectilePool.activeList[i]
        for j = numEnemies, 1, -1 do
            local enemy = enemyPool.activeList[j]
            if CirclesOverlap(projectile.x, projectile.y, projectile.collisionRadius, enemy.x, enemy.y, enemy.collisionRadius) then
                enemy.health = enemy.health - projectile.damage
                stats.bulletsHit = stats.bulletsHit + 1
                stats.damageInflicted = stats.damageInflicted + projectile.damage
                PlaySound(projectile.hitSfx)
                explosionParams.x = projectile.x
                explosionParams.y = projectile.y
                explosionPool.get(explosionParams)
                if enemy.health <= 0 then
                    OnDefeatEnemy(enemy)
                end
                projectilePool.free(projectile)
            end
        end
    end
end

function CheckEnemyPlayerCollisions()
    local numEnemies = #enemyPool.activeList
    for i = numEnemies, 1, -1 do
        local enemy = enemyPool.activeList[i]
        if CirclesOverlap(player.x, player.y, player.collisionRadius, enemy.x, enemy.y, enemy.collisionRadius) then
            stats.damageInflicted = stats.damageInflicted + enemy.health
            OnDamagePlayer(enemy.melee)
            OnDefeatEnemy(enemy)
        end
    end
end

function LockPlayerToScreen()
    if player.x < player.width / 2 then player.x = player.width / 2 end
    if player.y < player.height / 2 then player.y = player.height / 2 end
    if player.x > SCREEN_WIDTH - player.width / 2 then player.x = SCREEN_WIDTH - player.width / 2 end
    if player.y > SCREEN_HEIGHT - player.height / 2 then player.y = SCREEN_HEIGHT - player.height / 2 end
end

function UpdatePlayerMovement()
    local x = 0
    local y = 0
    
    x, y = getMoveInput()
    
    player.acceleration.x = x * player.speed
    player.acceleration.y = y * player.speed 
           
    UpdateEntity(player)
    LockPlayerToScreen()
end

function UpdatePlayerAim()
    local aimX = 0
    local aimY = 0
    
    aimX, aimY = getLookInput()
    
    if MagnitudeSquared(aimX, aimY) > 0 then
        player.angle = math.deg(math.atan(aimY, aimX)) 
        return true
    end
    
    return false
end

function InitCargo()
    local w = cargoParams.frameWidth * cargoParams.scale
    local h = cargoParams.frameHeight * cargoParams.scale
    
    local x = SCREEN_WIDTH / 2 - w * 2
    local y = SCREEN_HEIGHT / 2 - h * 2
    
    for i = 1, 3 do
        cargoParams.x = x
        cargoParams.y = y
        cargoPool.get(cargoParams)
        x = x + w * 2
        
        cargoParams.x = x
        cargoParams.y = y
        cargoPool.get(cargoParams)
        x = x + w * 2
        
        cargoParams.x = x
        cargoParams.y = y
        cargoPool.get(cargoParams)
        x = SCREEN_WIDTH / 2 - w * 2
        y = y + h * 2
    end
end

function InitPlayer()
    player = CreateEntity(spaceImage, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 + 128, 16, 16)
    SetEntityScale(player, 2)
    player.collisionRadius = 8 * player.scale
    player.speed = 4
    player.fireTimer = 0.0
    player.fireDelay = 60
    player.maxHealth = 100
    player.maxShields = 100
    player.health = player.maxHealth
    player.shields = player.maxShields
    player.shieldRechargeDelay = 2000
    player.shieldRechargeTimer = 0
    player.shieldRechargeRate = 5
    player.angle = -90
end

function InitPools()
    projectileParams = {}
    projectileParams.image = spaceImage
    projectileParams.speed = 4
    projectileParams.frameWidth = 16
    projectileParams.frameHeight = 16
    projectileParams.lifeTime = 1500
    projectileParams.damage = 1
    projectileParams.isHoming = true
    projectileParams.turnRate = 1
    projectileParams.r = 0
    projectileParams.g = 127
    projectileParams.b = 157
    projectileParams.a = 127
    projectileParams.hitSfx = hitSfx
    
    projectilePool = CreateObjectPool(MAX_PROJECTILES, AllocEntity)
    projectilePool.onGet = SpawnProjectile
    projectilePool.onFree = ResetEntity
    
    cargoParams = {}
    cargoParams.image = spaceImage
    cargoParams.frame = 1
    cargoParams.frameWidth = 16
    cargoParams.frameHeight = 16
    cargoParams.scale = 2
    cargoParams.angle = -90
    cargoParams.collisionRadius = 16
        
    cargoPool = CreateObjectPool(MAX_CARGO, AllocEntity)
    cargoPool.onGet = SpawnCargo
    cargoPool.onFree = ResetEntity
            
    enemyParams = {}
    enemyParams.image = spaceImage
    enemyParams.frame = 3
    enemyParams.frameWidth = 16
    enemyParams.frameHeight = 16
    enemyParams.scale = 2
    enemyParams.angle = 0
    enemyParams.health = 4
    enemyParams.melee = 30
    enemyParams.score = 1
    enemyParams.target = player
    enemyParams.maxSpeed = 3
    enemyParams.speed = 1.5
    enemyParams.defeatSfx = defeatSfx
    enemyParams.turnRate = math.random(1, 8)
    enemyParams.wobbleLimit = math.random(0, 40)
    enemyParams.wobbleSpeed = math.random(1, 20)
        
    enemyPool = CreateObjectPool(MAX_ENEMIES, AllocEntity)
    enemyPool.onGet = SpawnEnemy
    enemyPool.onFree = ResetEntity
    
    explosionParams = {}
    explosionParams.image = spaceImage
    explosionParams.frameWidth = 16
    explosionParams.frameHeight = 16
    explosionParams.lifeTime = 800
    
    explosionPool = CreateObjectPool(MAX_EXPLOSIONS, AllocEntity)
    explosionPool.onGet = SpawnExplosion
    explosionPool.onFree = ResetEntity
end

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function GameState_Start()
    if not gameInProgress then
        defeatSfx = LoadSound("sfx/explosion.wav")
        hitSfx = LoadSound("sfx/hit.wav")
        spaceImage = LoadImage("images/space.png")
        
        InitPlayer()
        InitPools()
        InitCargo()    
            
        gameState.font = LoadFont("fonts/8_bit_pusab.ttf", gameState.fontSize)
        gameInProgress = true
        spawnTimer = 4000.0
        spawnDelay = 400
        gameState.improveEnemiesDelay = 20000
        gameState.improveEnemiesTimer = gameState.improveEnemiesDelay
        gameState.playTime = 0
        
        local pick = math.random(1, 3)
        
        if pick == 1 then
            gameState.music = LoadMusic("music/level1.ogg")
        elseif pick == 2 then
            gameState.music = LoadMusic("music/level2.ogg")
        elseif pick == 3 then
            gameState.music = LoadMusic("music/level3.ogg")
        end
                
        PlayMusic(gameState.music)
        player.shootSfx = LoadSound("sfx/shoot.wav")
        gameState.initialTutorialTimer = 8000
        gameState.tutorialTimer = gameState.initialTutorialTimer
    end
    
    gameState.prevDownButton7 = controller_0_button_7
end

function GameState_Update()
    gameState.playTime = gameState.playTime + GetFrameTime()
    ClearTable(gameState.notifications)
    
    if gameState.tutorialTimer > 0 then
        gameState.tutorialTimer = gameState.tutorialTimer - GetFrameTime()
    end
    
    if gameState.improveEnemiesTimer > 0 then
        gameState.improveEnemiesTimer = gameState.improveEnemiesTimer - GetFrameTime()
        
        if gameState.improveEnemiesTimer <= 0 then
            ImproveEnemies()
            gameState.improveEnemiesTimer = gameState.improveEnemiesTimer + gameState.improveEnemiesDelay
        end
    end

    if (gameState.prevDownButton7 == 0 and controller_0_button_7 == 1) then
        gameState.prevDownButton7 = controller_0_button_7
        GotoState(PAUSE_STATE)
        return
    end
    
    gameState.prevDownButton7 = controller_0_button_7

    if player.shieldRechargeTimer > 0 then
        player.shieldRechargeTimer = player.shieldRechargeTimer - GetFrameTime()
    end
    
    if player.shieldRechargeTimer <= 0 then
        player.shields = player.shields + player.shieldRechargeRate * (GetFrameTime() / 1000.0)
        player.shields = math.min(player.shields, player.maxShields)
    end
    
    UpdatePlayerMovement()
    
    local fire = UpdatePlayerAim()
    UpdateProjectiles(fire)
    
    enemyPool.each(UpdateEnemy)
    
    CullOldExplosions()
    CullOldProjectiles()
    CheckProjectileEnemyCollisions()
    CheckEnemyPlayerCollisions()
    
    UpdateSpawner()
    
    GameState_AddText("Score: " .. stats.score)
    --GameState_AddText("Shields: " .. tonumber(string.format("%.1f", player.shields)))
    --GameState_AddText("Health: " .. tonumber(string.format("%.1f", player.health)))
    --GameState_AddText("Num Enemies: " .. #enemyPool.activeList)
    --GameState_AddText("Num Cargo: " .. #cargoPool.activeList)
    --GameState_AddText("Num Projectiles: " .. #projectilePool.activeList)
    
    -- if all cargo is stolen, game over.
    if #cargoPool.activeList == 0 and gameInProgress then
        defeatState.reason = "You lost all your cargo."
        OnDefeat()
    end
    
    explosionPool.each(UpdateExplosion)
end

function GameState_Draw()
    ClearScreen(8, 8, 16)
    
    cargoPool.each(DrawEntity)
    projectilePool.each(DrawEntity)
    enemyPool.each(DrawEntity)
    explosionPool.each(DrawEntity)
    DrawEntity(player)
        
    local y = math.floor(SCREEN_HEIGHT * 0.055)
    for i = 1, #gameState.notifications do
        local text = gameState.notifications[i]
        DrawText(text, 8, y, gameState.font, 255, 255, 255);
        y = y + 31
    end
    
    DrawShieldBar()
    DrawHealthBar()
    
    local tutorialText = ""
    local drawHint = false
    
    if gameState.tutorialTimer > gameState.initialTutorialTimer / 2 then
        tutorialText = "---------------------Defend cargo from aliens.---------------------"
        drawHint = true
    elseif gameState.tutorialTimer > 0 then
        tutorialText = "---------------------Left stick moves, right stick shoots.---------------------"
        drawHint = true
    end
    
    if drawHint == true then
        DrawText(tutorialText, (SCREEN_WIDTH / 2) - ((string.len(tutorialText) * gameState.fontSize) / 2), SCREEN_HEIGHT * 0.2, gameState.font, 255, 255, 255); 
    end    
end

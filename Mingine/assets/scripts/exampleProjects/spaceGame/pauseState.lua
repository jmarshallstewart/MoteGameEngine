------------------------------------------------------------------------------
-- transient state data
------------------------------------------------------------------------------
pauseState = {}
pauseState.titleText = "Paused"
pauseState.titleTextLength = string.len(pauseState.titleText)
pauseState.fontSize = 20
pauseState.bigFontSize = 120
pauseState.prevDownButton7 = 0
pauseState.stats = {}

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------
function PauseState_AddText(text)
    pauseState.stats[#pauseState.stats + 1] = text
end

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function PauseState_Start()
   pauseState.bigFont = LoadFont("fonts/8_bit_pusab.ttf", pauseState.bigFontSize)
   pauseState.font = LoadFont("fonts/8_bit_pusab.ttf", pauseState.fontSize)
   pauseState.prevDownButton7 = controller_0_button_7
end

function PauseState_Update()
    ClearTable(pauseState.stats)

    if (pauseState.prevDownButton7 == 0 and controller_0_button_7 == 1) or IsKeyPressed(SDL_SCANCODE_SPACE) then
        GotoState(GAME_STATE)
    end
    
    pauseState.prevDownButton7 = controller_0_button_7
    
    local hitPercentage = 0
    if stats.bulletsFired > 0 then
        hitPercentage = stats.bulletsHit / stats.bulletsFired
        hitPercentage = tonumber(string.format("%.3f", hitPercentage))
        hitPercentage = hitPercentage * 100
    end
    
    PauseState_AddText("Score: " .. stats.score)
    PauseState_AddText("Enemies Defeated: " .. stats.enemiesDefeated)
    PauseState_AddText("Bullets Fired: " .. stats.bulletsFired)
    PauseState_AddText("Bullets Hit: " .. stats.bulletsHit)
    PauseState_AddText("Hit %: " .. hitPercentage)
    PauseState_AddText("Damage Taken: " .. stats.damageTaken)
    PauseState_AddText("Damage Inflicted: " .. stats.damageInflicted)
    PauseState_AddText("Cargo Remaining: " .. #cargoPool.activeList)
    PauseState_AddText("Play Time: " .. (gameState.playTime / 1000) .. " seconds")
end

function PauseState_Draw()
    ClearScreen(8, 8, 16)
    
    DrawText(pauseState.titleText, (SCREEN_WIDTH / 2) - ((pauseState.titleTextLength * pauseState.bigFontSize) / 2), SCREEN_HEIGHT / 3, pauseState.bigFont, 255, 255, 255);
    
    local y = math.floor(SCREEN_HEIGHT * 0.55)
    for i = 1, #pauseState.stats do
        local text = pauseState.stats[i]
        DrawText(text, (SCREEN_WIDTH / 2) - ((string.len(text) * pauseState.fontSize) / 2), y, pauseState.font, 255, 255, 255);
        y = y + math.floor(SCREEN_HEIGHT * 0.03)
    end
    
end
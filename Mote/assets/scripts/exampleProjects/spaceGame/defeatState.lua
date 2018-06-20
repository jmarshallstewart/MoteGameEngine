------------------------------------------------------------------------------
-- transient state data
------------------------------------------------------------------------------
defeatState = {}
defeatState.titleText = "GAME OVER"
defeatState.titleTextLength = string.len(defeatState.titleText)
defeatState.fontSize = 20
defeatState.bigFontSize = 120
defeatState.prevDownButton7 = 0
defeatState.stats = {}
defeatState.music = nil
defeatState.reason = nil

------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------
function DefeatState_AddText(text)
    defeatState.stats[#defeatState.stats + 1] = text
end

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function DefeatState_Start()
   defeatState.bigFont = LoadFont("fonts/8_bit_pusab.ttf", defeatState.bigFontSize)
   defeatState.font = LoadFont("fonts/8_bit_pusab.ttf", defeatState.fontSize)
   defeatState.prevDownButton7 = controller_0_button_7
   defeatState.music = LoadMusic("music/ending.ogg")
   PlayMusic(defeatState.music)
end

function DefeatState_Update()
    ClearTable(defeatState.stats)

    if (defeatState.prevDownButton7 == 0 and controller_0_button_7 == 1) or IsKeyPressed(SDL_SCANCODE_SPACE) then
        GotoState(SPLASH_STATE)
    end
    
    defeatState.prevDownButton7 = controller_0_button_7
    
    local hitPercentage = 0
    if stats.bulletsFired > 0 then
        hitPercentage = stats.bulletsHit / stats.bulletsFired
        hitPercentage = tonumber(string.format("%.3f", hitPercentage))
        hitPercentage = hitPercentage * 100
    end
    
    DefeatState_AddText("Score: " .. stats.score)
    DefeatState_AddText("Enemies Defeated: " .. stats.enemiesDefeated)
    DefeatState_AddText("Bullets Fired: " .. stats.bulletsFired)
    DefeatState_AddText("Bullets Hit: " .. stats.bulletsHit)
    DefeatState_AddText("Hit %: " .. hitPercentage)
    DefeatState_AddText("Damage Taken: " .. stats.damageTaken)
    DefeatState_AddText("Damage Inflicted: " .. stats.damageInflicted)
    DefeatState_AddText("Cargo Remaining: " .. #cargoPool.activeList)
    DefeatState_AddText("Play Time: " .. (gameState.playTime / 1000) .. " seconds")
end

function DefeatState_Draw()
    ClearScreen(8, 8, 16)
    
    DrawText(defeatState.reason, (SCREEN_WIDTH / 2) - ((string.len(defeatState.reason) * defeatState.fontSize) / 2), SCREEN_HEIGHT * 0.2, defeatState.font, 255, 255, 255);
    DrawText(defeatState.titleText, (SCREEN_WIDTH / 2) - ((defeatState.titleTextLength * defeatState.bigFontSize) / 2), SCREEN_HEIGHT / 3, defeatState.bigFont, 255, 255, 255);
    
    local y = SCREEN_HEIGHT - 384
    for i = 1, #defeatState.stats do
        local text = defeatState.stats[i]
        DrawText(text, (SCREEN_WIDTH / 2) - ((string.len(text) * defeatState.fontSize) / 2), y, defeatState.font, 255, 255, 255);
        y = y + 31
    end
    
end
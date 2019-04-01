------------------------------------------------------------------------------
-- transient state data
------------------------------------------------------------------------------
splashState = {}
splashState.titleText = "Space Game"
splashState.hintText = "Press START to begin"
splashState.titleTextLength = string.len(splashState.titleText)
splashState.hintTextLength = string.len(splashState.hintText)
splashState.bigFontSize = 120
splashState.fontSize = 20
splashState.prevDownButton7 = 0
splashState.blinkDelay = 500
splashState.blinkTimer = splashState.blinkDelay
splashState.blink = true
splashState.prevDownButton7 = false
splashState.music = nil

------------------------------------------------------------------------------
-- core functions
------------------------------------------------------------------------------
function SplashState_Start()
   splashState.bigFont = LoadFont("fonts/8_bit_pusab.ttf", splashState.bigFontSize)
   splashState.font = LoadFont("fonts/8_bit_pusab.ttf", splashState.fontSize)
   splashState.music = LoadMusic("music/title.ogg")
   
   PlayMusic(splashState.music)
end

function SplashState_Update()
    if splashState.blinkTimer > 0 then
        splashState.blinkTimer = splashState.blinkTimer - GetFrameTime()
    
        if splashState.blinkTimer <= 0 then
            splashState.blink = not splashState.blink
            splashState.blinkTimer = splashState.blinkTimer + splashState.blinkDelay
        end
    end
    
    if (not splashState.prevDownButton7 and ReadControllerButton(0, 7)) or IsKeyPressed(SDL_SCANCODE_SPACE) then
        ResetStats()
        GotoState(GAME_STATE)
    end
    
    splashState.prevDownButton7 = ReadControllerButton(0, 7)
end

function SplashState_Draw()
    ClearScreen(8, 8, 16)
    
    DrawText(splashState.titleText, (SCREEN_WIDTH / 2) - ((splashState.titleTextLength * splashState.bigFontSize) / 2), SCREEN_HEIGHT / 3, splashState.bigFont, 255, 255, 255);
    
    if splashState.blink then
		if IsControllerAttached(0) then
        DrawText(splashState.hintText, (SCREEN_WIDTH / 2) - ((splashState.hintTextLength * splashState.fontSize) / 2), math.floor(SCREEN_HEIGHT * 0.83), splashState.font, 255, 255, 255)
		else
		DrawText("Please attach a controller", (SCREEN_WIDTH / 2) - ((splashState.hintTextLength * splashState.fontSize) / 2), math.floor(SCREEN_HEIGHT * 0.83), splashState.font, 255, 255, 255)
		end
    end
end
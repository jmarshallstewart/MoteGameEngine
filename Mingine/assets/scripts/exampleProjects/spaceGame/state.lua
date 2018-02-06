------------------------------------------------------------------------------
-- constants
------------------------------------------------------------------------------
SPLASH_STATE = 1
MAIN_MENU_STATE = 2
GAME_STATE = 3
PAUSE_STATE = 4
OPTIONS_STATE = 5
DEFEAT_STATE = 6

------------------------------------------------------------------------------
-- transient data
------------------------------------------------------------------------------
state = SPLASH_STATE

function GotoState(targetState)
    if targetState == SPLASH_STATE then SplashState_Start()
    elseif targetState == GAME_STATE then GameState_Start()
    elseif targetState == PAUSE_STATE then PauseState_Start()
    elseif targetState == DEFEAT_STATE then DefeatState_Start()
    end
    
    state = targetState
end

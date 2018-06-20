-- Enter a new state, leaving current state if needed.
function EnterState(owner, state)
    local sm = owner.stateMachine

    if sm.currentState ~= nil then
        sm.currentState.Exit(owner)
    end
    
    sm.currentState = state
    sm.currentState.Enter(owner)
end

function CreateStateMachine(owner, startingState)
    owner.stateMachine = {}
    owner.stateMachine.currentState = nil
    
    if startingState ~= nil then
        EnterState(owner, startingState)
    end
end

function UpdateStateMachine(owner)
    if owner.stateMachine ~= nil then
        if owner.stateMachine.currentState ~= nil then
            if owner.stateMachine.currentState.Update ~= nil then
                owner.stateMachine.currentState.Update(owner)
            end
        end
    end
end
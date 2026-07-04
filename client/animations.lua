Animations = {}

-- Animation abspielen
function Animations.PlayAnim(ped, animDict, animName, flag, blendInSpeed, blendOutSpeed, duration)
    if not DoesEntityExist(ped) then return end
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    TaskPlayAnim(ped, animDict, animName, blendInSpeed or 8.0, blendOutSpeed or -8.0, duration or -1, flag or 49, 0, false, false, false)
end

-- Animation gestoppt
function Animations.StopAnim(ped, animDict, animName)
    StopAnimTask(ped, animDict, animName, 1.0)
end

-- Zufällige Idle-Animation
function Animations.PlayRandomIdle(ped)
    local idleAnims = Config.Animations.idle
    local anim = idleAnims[math.random(1, #idleAnims)]
    Animations.PlayAnim(ped, anim[1], anim[2], 49, 8.0, -8.0, -1)
end

-- Arbeits-Animation
function Animations.PlayWorkAnim(ped, workType)
    if workType == 'construction' then
        Animations.PlayAnim(ped, 'amb@world_human_construction_worker@male@base', 'base', 49, 8.0, -8.0, -1)
    elseif workType == 'farming' then
        Animations.PlayAnim(ped, 'amb@world_human_farmer@male@base', 'base', 49, 8.0, -8.0, -1)
    elseif workType == 'shop' then
        Animations.PlayAnim(ped, 'anim@mp_sit_taxi@rps', 'sit', 49, 8.0, -8.0, -1)
    else
        Animations.PlayRandomIdle(ped)
    end
end

-- Soziale Animation (Gespräch)
function Animations.PlaySocialAnim(ped, talking)
    if talking then
        local socialAnim = Config.Animations.social[math.random(1, #Config.Animations.social)]
        Animations.PlayAnim(ped, socialAnim[1], socialAnim[2], 49, 8.0, -8.0, -1)
    else
        ClearPedTasks(ped)
    end
end

-- Emotes für verschiedene Stimmungen
Animations.Emotes = {
    happy = {'amb@world_human_cheering@female_a', 'cheering_a'},
    angry = {'amb@world_human_yoga@female_a', 'yoga_a'},
    surprised = {'amb@world_human_stargazing@male@idle_a', 'idle_a'},
    thinking = {'amb@world_human_paparazzi@male@base', 'base'}
}

function Animations.PlayEmote(ped, mood)
    if Animations.Emotes[mood] then
        Animations.PlayAnim(ped, Animations.Emotes[mood][1], Animations.Emotes[mood][2], 49, 8.0, -8.0, 5000)
    end
end

exports('PlayAnim', function(animDict, animName, flag, blendInSpeed, blendOutSpeed, duration)
    local ped = PlayerPedId()
    Animations.PlayAnim(ped, animDict, animName, flag, blendInSpeed, blendOutSpeed, duration)
end)

exports('StopAnim', function(animDict, animName)
    local ped = PlayerPedId()
    Animations.StopAnim(ped, animDict, animName)
end)
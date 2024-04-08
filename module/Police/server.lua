CORE.Police = function()
    RegisterServerEvent("police:doCarry")
    AddEventHandler("police:doCarry", function(id,option,extraId)
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(id)
        local tPlayer = ESX.GetPlayerFromId(id)
        if option == 'carry' then
            xPlayer.triggerEvent('police:doCarry', id,'still')
            tPlayer.triggerEvent('police:doCarry', _source,'carried')
        elseif option == 'putin' then
            xPlayer.triggerEvent('police:doCarry', id,'clear')
            tPlayer.triggerEvent('police:doCarry', _source,'getIn',extraId)
        elseif option == 'clear' then
            xPlayer.triggerEvent('police:doCarry', id,'clear')
            tPlayer.triggerEvent('police:doCarry', _source,'detach')
        end
    end)    
end

return CORE.Police
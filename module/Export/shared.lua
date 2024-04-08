CORE.Export = function(exportName, func, resource)
    if resource then
        AddEventHandler(('__cfx_export_%s_%s'):format(resource, exportName), function(setCB)
            setCB(func)
        end)
    else
        AddEventHandler(('__cfx_export_BX_%s'):format(resource, exportName), function(setCB)
            setCB(func)
        end)
    end
end

return CORE.Export
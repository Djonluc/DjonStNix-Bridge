local function InitializeVehicleHelpers()
    -- Use global Core

    -- --- VEHICLE (GENERIC) ---
    Core.Vehicle.MarkVehicleStolen = function(plate)
        -- Integration with Police/MDT registry
        Core.Emit('vehicle:stolen', { plate = plate })
    end
end

InitializeVehicleHelpers()

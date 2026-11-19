-- Positions are model-local. Bounds provide a fallback for models with different
-- origins; explicit per-model offsets take priority over this approximation.
HousingInteractionPosition = {}
function HousingInteractionPosition.Resolve(entity, override, kind)
    if override then
        return {x=override.x or 0.0, y=override.y or 0.0, z=override.z or 0.0, heading=override.heading or 0.0}
    end
    local minimum, maximum = GetModelDimensions(GetEntityModel(entity))
    if not minimum or not maximum then
        return {x=0.0, y=0.0, z=kind == 'bath' and 0.5 or 0.8, heading=0.0}
    end
    local height = math.max(0.1, maximum.z - minimum.z)
    local x, y = (minimum.x + maximum.x) / 2, (minimum.y + maximum.y) / 2
    -- Mattress is typically below the headboard; bathtub pose rests just above
    -- the inner floor, not on top of the rim. Both remain configurable.
    local z = minimum.z + height * (kind == 'bath' and 0.40 or 0.75)
    local heading = (maximum.x - minimum.x) > (maximum.y - minimum.y) and 90.0 or 0.0
    return {x=x, y=y, z=z, heading=heading}
end

-- TaskPlayAnim can displace the skeleton below the ped origin. Align the
-- animated pelvis with the requested surface after the animation starts and
-- during blend-in. Keep the task and IK intact while correcting the ped root.
function HousingInteractionPosition.AlignPose(ped, target, stillActive)
    for _ = 1, 6 do
        Wait(100)
        if not stillActive() then return end
        local pelvis = GetPedBoneCoords(ped, 11816, 0.0, 0.0, 0.0) -- SKEL_Pelvis
        local root = GetEntityCoords(ped)
        if pelvis and root then
            local dz = target.z - pelvis.z
            -- Ignore uninitialised bones and corrupt/out-of-range positions.
            if dz == dz and math.abs(dz) > 0.025 and math.abs(dz) < 3.0 then
                SetEntityCoordsNoOffset(ped, root.x, root.y, root.z + dz, true, true, false)
            end
        end
    end
end

-- Add this entry inside the return table in ox_inventory/data/items.lua.
-- Restart ox_inventory (and then esx_realestate) after editing it.
return {
['property_deed'] = {
    label = 'Property Deed',
    weight = 10,
    stack = false,
    close = true,
    consume = 0,
    description = 'A property deed.',
},
}

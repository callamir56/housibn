Config = Config or {}









Config.Core = "ESX"
Config.CoreExport = function()
    return exports['es_extended']:getSharedObject()
end


Config.PlayerLoaded = Config.Core == "ESX" and "esx:playerLoaded" or "QBCore:Client:OnPlayerLoaded"


Config.PlayerLogoutServer = Config.Core == "ESX" and "esx:playerDropped" or "QBCore:Server:OnPlayerUnload"


Config.PlayerSetJob = Config.Core == "ESX" and "esx:setJob" or "QBCore:Client:OnJobUpdate"











Config.AutoExecuteQuery = true


Config.AutoSeedFurniture = true



Config.Debug = false
Config.DebugTarget = false
Config.DebugPolyZone = false
Config.DebugRegionsZone = false


local function DetectActiveTarget()
    local resources = {
        'ox_target',
        'qb-target',
    }

    for i=1, #resources, 1 do
        if GetResourceState(resources[i]) == 'started' then
            return resources[i]
        end
    end
    return nil
end



Config.TargetResource = DetectActiveTarget()









Config.Blips = {
    ['Motel'] = {
        sprite = 475,
        display = 2,
        scale = 0.9,
        color = 0,
        name = TRANSLATE('blip.motel'),
    },
    ['Building'] = {
        sprite = 475,
        display = 2,
        scale = 0.9,
        color = 0,
        name = TRANSLATE('blip.building'),
    },
    ['HouseOwner'] = {
        sprite = 40,
        display = 2,
        scale = 0.8,
        color = 0,
        blipCategory = 11,
        name = TRANSLATE('blip.house_owner'),
    },
    ['HouseRenter'] = {
        sprite = 40,
        display = 2,
        scale = 0.8,
        color = 0,
        blipCategory = 11,
        name = TRANSLATE('blip.house_renter'),
    },
    ['HouseKeyHolder'] = {
        sprite = 811,
        display = 2,
        scale = 0.9,
        color = 26,
        blipCategory = 11,
        name = TRANSLATE('blip.house_key_holder'),
    },
    ['HouseForSale'] = {
        sprite = 350,
        display = 2,
        scale = 0.6,
        color = 0,
        blipCategory = 10,
        name = TRANSLATE('blip.house_for_sale'),
    },
    ['Marketplace'] = {
        sprite = 476,
        display = 2,
        scale = 1.0,
        color = 2,
        name = TRANSLATE('blip.marketplace'),
    },
}



Config.AreaUnit = "m2"




Config.TeleportToLastPropertyOnJoin = true





Config.FurnitureInteractionAccess = 2





Config.StaticInteractionAccess = 1





Config.AllowChangeStoragePosition = true





Config.AllowChangeWardrobePosition = true



Config.MaxPropertiesPerPlayer = false


Config.RentalCycles = {
    ['weekly'] = true,
    ['monthly'] = true,
}











Config.StarterApartments = {
    Object = 114,
    Name = 'Starting Apartment #%s',
    Type = 'shell',

    Shell = 'standardmotel_shell',
    Ipl = 'apa_v_mp_h_01_a',

    DefaultPurchasePrice = 0,
    DefaultRentPrice = 0,

    AllowFurnitureInside = true,
    AllowChangeTheme = true,
    DefaultThemeIpl = 'modern',

    Delivery = {
        Enabled = true,
        Coords = vector4(2.4304, -2.1917, 498.4416, 79.99999237060547),
    },

    Storage = {
        Enabled = true,
        Coords = vector3(1.5388, -3.0803, 499.7162),
        Slots = 20,
        Weight = 25000,
    },

    Wardrobe = {
        Enabled = true,
        Coords = vector3(1.3227, 2.8945, 500.0726),
    },
}









Config.HousingManagement = {
    Command = 'housemanage',
    Key = 'F6',
    Description = 'Property management menu',
}



Config.AutomaticSell = 50












Config.UseKeysOnItem = false



Config.KeysLimit = 8



Config.KeyPrice = 300



Config.LockReplacementPrice = 1000



Config.RemoveKeysOnRentEnd = true



Config.AutomaticGiveKeyForProperty = true











Config.SaveDoorsState = true





Config.DefaultDoorsLocked = true











Config.DefaultPermissionsForRenter = {
    'garage',
    'furniture',
    'billPayments',
    'keysManage',
    'upgradesManage',
}



Config.PermissionsLimit = 10











Config.CityHallTaxes = {
    PropertyPurchase = {
        Enabled = true,
        Type = 'percentage',
        Value = 3,
        Title = 'Property Purchase - %s %s',
    },
    PropertyResale = {
        Enabled = true,
        Type = 'percentage',
        Value = 12,
        Title = 'Property Resale - %s %s',
    },
    RentalIncome = {
        Enabled = true,
        Type = 'percentage',
        Value = 15,
        Title = 'Property Rental - %s %s',
    },
    PropertyCadastralTax = {
        Enabled = true,
        Type = 'percentage',
        Value = 1,
        Title = 'Property Cadastral Tax - %s %s',
    },
}











Config.UseServiceBills = true



Config.AllowedUnpaidBills = 2



Config.UtilityAccess = {
    BlockEntry = true,
    OverdueBillsToBlock = 2,
    ReminderOnEntry = true,
    AllowPoliceDuringRaid = true,
}





Config.AllowedUnpaidRentBills = 2



Config.RemoveBillsOnRentEnd = true




Config.OptimizeBillsTable = false











Config.Lockpick = {
    Enable = true,

    Item = {
        Required = true,
        Name = 'lockpick',
        Count = 1,
        RemoveOnUse = true
    },
}

Config.Alarm = {
    AlertPoliceOnlyWithUpgrade = true,

    AlarmJobs = { 'police', 'sheriff' },

    AlertPoliceOnLockpickStart = true,
    AlertPoliceOnLockpickSuccess = false,
    AlertPoliceOnLockpickFail = false,
}

Config.PropertyLockdown = {
    Enable = true,

    ObjectModel = 'prop_barrier_work05',




    Placement = {
        Clearance = 0.25,
        RightOffset = 0.0,
        ZOffset = 0.0,
        HeadingOffset = 0.0,

    },

    Jobs = { 'police' },

    Item = {
        Required = true,
        Name = 'police_barrier',
        Count = 1,
        RemoveOnUse = true
    },
}

Config.PropertyRaids = {
    Enable = true,

    Jobs = { 'police' },

    AntiBurglaryDoors = {
        AllowRaid = true,
        RaidChance = 10,




        BreakOnRam = true
    }, 

    Item = {
        Required = true,
        Name = 'police_stormram',
        Count = 1,
        RemoveOnUse = true
    },
}









Config.HousingCreator = {
    Command = 'housing',
    Key = 'F7',
    Description = 'Open Housing Creator',
    RequiredJob = 'unemployed',
    AllowedGroups = { gamemaster = true },
}

Config.HousingCreatorControls = {
    ['SELECT'] = {controlIndex = 24},
    ['BACK'] = {controlIndex = 70},
    ['SCROLL_DOWN'] = {controlIndex = 180},
    ['SCROLL_UP'] = {controlIndex = 181},
    ['LEFT_CTRL'] = {controlIndex = 210},
    ['ENTER'] = {controlIndex = 191},
    ['CANCEL'] = {controlIndex = 202},
}


Config.Shells = {}









Config.Marketplace = {
    Enabled = true,
    AllowTransactionFromMenu = true,

    ShowSecondaryMarketOnly = true,

    Blip = Config.Blips['Marketplace'],
    BlipCoords = vector3(-1082.89, -249.45, 43.98),

    TargetCoords = vector4(-1083.08, -249.66, 44.02, 296.5),
    TargetSize = vec3(2.0, 1.6, 1.8),

    Ped = {
        Model = 'ig_drfriedlander',
        Coords = vector4(-1082.72, -249.5, 43.02, 296.32),
        Animation = {'switch@michael@sitting', 'idle'}
    },
}









Config.HousingFurniture = {
    Command = 'furniture',
    Key = nil,
    Description = 'Property furniture menu',
}




Config.RequirePurchaseFurniture = true



Config.FurnitureSellPercentage = 80



Config.FurnitureLimit = 10



Config.RemoveFurnitureOnRentEnd = true

Config.FurnitureControls = {
    ['CLOSE'] = {controlIndex = 202},

    ['ACCEPT'] = {controlIndex = 38},
    ['UP'] = {controlIndex = 172},
    ['DOWN'] = {controlIndex = 173},
    ['ROTATE_LEFT'] = {controlIndex = 181},
    ['ROTATE_RIGHT'] = {controlIndex = 180},
    ['SPEED_DOWN'] = {controlIndex = 210},

    ['SNAP_TO_GROUND'] = {controlIndex = 19},
    ['ENABLE_CURSOR'] = {controlIndex = 238},
    ['CHANGE_MODE'] = {controlIndex = 58},
    
    ['GIZMO_TRANSLATION'] = {control = 'X'},
    ['GIZMO_ROTATION'] = {control = 'C'},
}

Config.FurnitureSettings = {
    HeightSpeed = 0.01,
    HeightSpeedSlow = 0.005,
    RotateSpeed = 5.0,
    RotateSpeedSlow = 1.0,
}



Config.Cameras = {
    ['prop_cctv_cam_04c'] = true,
    ['prop_cctv_cam_05a'] = true,
    ['prop_cctv_cam_06a'] = true,
}













Config.DeliveryType = 1



Config.DeliveryObject = 'prop_boxpile_01a'

Config.Deliveries = {
    ['1'] = {
        defaultDeliveryCharge = 2000,
        defaultDeliveryTime = 30 * 60 * 1000,
    },
    ['2'] = {
        defaultDeliveryCharge = 2000,
        defaultDeliveryTime = 60 * 60 * 1000,
    },
    ['3'] = {
        defaultDeliveryCharge = 2000,
        defaultDeliveryTime = 180 * 60 * 1000,
    },
}












Config.HousingUpgrades = {
    ['alarm'] = {
        metadata = 'alarm',
        price = 60000,

        icon = 'fa-solid fa-car-on',
        label = "Alarm",

        description = [[
            An advanced alarm system that immediately triggers an alert when unauthorized entry is detected.
            Highly effective against break-ins, especially when you're offline.
        ]],
    },

    ['anti_burglary_doors'] = {
        metadata = 'antiBurglaryDoors',
        price = 80000,

        icon = 'fa-solid fa-door-closed',
        label = "Anti-Burglary Doors",

        description = [[
            Reinforced doors designed to resist forced entry attempts.
            Adds an extra layer of security and delays break-in time significantly.
        ]],
    },

    ['smart_peephole'] = {
        metadata = 'smartPeephole',
        price = 80000,

        icon = 'fa-solid fa-door-closed',
        label = "Smart Peephole",

        description = [[
            Reinforced doors designed to resist forced entry attempts.
            Adds an extra layer of security and delays break-in time significantly.
        ]],
    },

    ['furniture_limit'] = {
        metadata = 'furnitureLimit',

        icon = 'fa-solid fa-couch',
        label = "Furniture Limit",

        description = ([[
            Upgrade to be able to have more furniture in your property.
            Your current furniture limit is %s - after this upgrade, it will increase to 30.
        ]]):format(Config.FurnitureLimit),

        levels = {
            ['1'] = {
                limit = 30,
                price = 60000,
                description = [[
                    Increase your furniture limit from 30 to 50.
                    Useful if you're running out of space in your current setup.
                ]],
            },
            ['2'] = {
                limit = 50,
                price = 80000,
                description = [[
                    Increase your furniture limit from 50 to 100.
                    Great for heavily customized interiors.
                ]],
            },
            ['3'] = {
                limit = 100,
                price = 100000,
                description = [[
                    Increase your furniture limit from 100 to 150.
                    Perfect for large homes with detailed furnishing needs.
                ]],
            },
            ['4'] = {
                limit = 150,
                price = 120000,
                description = [[
                    You've reached the maximum furniture level.
                    No further upgrades are available.
                ]],
            },
        },
    },
}









local function DetectActiveWeather()
    local weathers = {
        'cd_easytime',
        'vSync',
        'qb-weathersync',
        'qbx_weathersync',
        'av_weather',
    }

    for i=1, #weathers, 1 do
        if GetResourceState(weathers[i]) == 'started' then
            return weathers[i]
        end
    end
    return nil
end

Config.Weather = DetectActiveWeather()









local function DetectActiveClothing()
    local resources = {
        'esx_skin',
        'vms_clothestore',
        'qb-clothing',
        'ak47_clothing',
        'rcore_clothing',
        'raid_clothes',
        'bl_appearance',
        'fivem-appearance',
        'illenium-appearance',
        'codem-appearance',
        'qs-appearance',
        '17mov_CharacterSystem',
    }

    for i=1, #resources, 1 do
        if GetResourceState(resources[i]) == 'started' then
            return resources[i]
        end
    end
    return nil
end

Config.Clothing = DetectActiveClothing()









local function DetectActiveGarage()
    local resources = {
        'vms_garagesv2',
        'rcore_garage',
        'cd_garage',
        'loaf_garage',
        'jg-advancedgarages',
        'okokGarage',
        'RxGarages',
    }

    for i=1, #resources, 1 do
        if GetResourceState(resources[i]) == 'started' then
            return resources[i]
        end
    end
    return nil
end

Config.Garages = DetectActiveGarage()










Config.DeedAgencyJob = 'realestateagent'

local function DetectActiveInventory()
    local resources = {
        'codem-inventory',
        'tgiann-inventory',
        'origen_inventory',
        'ak47_inventory',
        'core_inventory',
        'qs-inventory',
        'ox_inventory',
        'qb-inventory',
        'inventory',
    }

    for i=1, #resources, 1 do
        if GetResourceState(resources[i]) == 'started' then
            return resources[i]
        end
    end
    return nil
end

Config.Inventory = DetectActiveInventory()









local function DetectActiveDispatch()
    local resources = {
        'lb-tablet',
        'ps-dispatch',
        'cd_dispatch',
        'qs-dispatch',
        'rcore_dispatch',
        'tk_dispatch',
        'core_dispatch',
    }

    for i=1, #resources, 1 do
        if GetResourceState(resources[i]) == 'started' then
            return resources[i]
        end
    end
    return nil
end

Config.Dispatch = DetectActiveDispatch()


Config.HousingRest = {
    Enabled = true,
    Models = {
        apa_mp_h_bed_double_09 = true,
        apa_mp_h_bed_wide_05 = true,
        apa_mp_h_bed_with_table_02 = true,
        ex_prop_exec_bed_01 = true,
        hei_heist_bed_double_08 = true,
        prop_rub_matress_01 = true, prop_t_sofa_02 = true, p_lestersbed_s = true,
        sum_mp_h_yacht_bed_01 = true, sum_mp_h_yacht_bed_02 = true,
        v_res_d_bed = true, v_res_mbbed = true, v_res_mdbed = true,
        v_res_msonbed = true, v_res_tre_bed1 = true, v_res_tre_bed1_messy = true,
        v_res_tt_bed = true,
    },
    BedOffset = nil,
    BedOffsets = {},
    FixedBeds = true,
    DurationSeconds = 12,
    TickSeconds = 1,
    HealPerTick = 5,
    CooldownSeconds = 300,
    MaxDistance = 3.0,
}



Config.HousingSeats = {
    Enabled = true,
    RequirePermission = false,
    MaxDistance = 3.5,
    LeaseSeconds = 30,
    Types = {
        chair = { slots = {{x=0.0, y=0.0, z=0.45}}, heading = 180.0 },
        sofa = { slots = {{x=-0.45, y=0.0, z=0.45}, {x=0.45, y=0.0, z=0.45}}, heading = 180.0 },
    },
    Models = {},
}



Config.HousingTV = {
    Enabled = true,
    ControlPermission = 'furniture',


    DirectAllowedHosts = nil,
    MaxDistance = 3.5,
    Models = {
        prop_tv_flat_01=true, prop_tv_flat_02=true, prop_tv_flat_02b=true,
        prop_tv_flat_03=true, prop_tv_flat_03b=true, prop_tv_flat_michael=true,
        prop_tv_01=true, prop_tv_02=true, prop_tv_03=true, prop_tv_04=true,
        prop_tv_05=true, prop_tv_06=true, prop_tv_07=true, prop_trev_tv_01=true,
    },
}



Config.HousingBathroom = {
    Enabled = true,
    DurationMs = 10000,
    ToiletModels = { 'prop_toilet_01', 'prop_toilet_02', 'prop_ld_toilet_01' },
    ShowerModels = { 'prop_shower_01', 'v_ilev_mm_shower', 'prop_shower_rack_01' },
    BathModels = { 'v_res_mbath' },
    BathAnimation = {dict='timetable@ron@ig_3_couch', name='base'},
    BathHeadingAdjustment = 180.0,
    BathOffset = nil,
    BathOffsets = {},
    ToiletOffset = {x=0.0, y=0.0, z=0.45, heading=180.0},
    ShowerOffset = {x=0.0, y=-0.4, z=0.0, heading=0.0},
}

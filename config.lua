fd = {}

fd.locale = 'en'
fd.debug = false

fd.dealer = {
    coords = vector4(213.5919, -128.3463, 62.7070, 252.1888),
    model = "s_m_o_busker_01",
    scenario = "WORLD_HUMAN_SMOKING",
    header = "Seller",
    items = {
        { label = 'Access Card', item = 'coke_access', description = "Buy keycard for: $", price = 250000, min = 1, max = 1 },
        { label = 'Empty Bag', item = 'empty_bag', description = "Buy empty bag for: $", price = 500, min = 1, max = 5 },
        { label = 'Trowel', item = 'trowel', description = "Buy trowel for: $", price = 500, min = 1, max = 5 },
    }
}

fd.field = {
    coords = vector3(-1444.3118, 5415.2642, 23.7163),
    radius = 40.0,
    required = { { item = "trowel", count = 1, remove = false } },
    reward = { item = "coke_leaf", min = 1, max = 3 }
}

fd.ipls = {
    "bkr_biker_interior_placement_interior_4_biker_dlc_int_ware03_milo"
}

fd.props = {
    "set_up",
    "equipment_upgrade",
    "production_upgrade",
    "security_high"
}

fd.enter = {
    coords = vector3(1929.9697, 4634.6743, 40.8077),
    radius = 1.2,
    target = vector3(1088.6899, -3187.4062, -38.0883),
    key = "coke_access",
    requestitem = false
}

fd.leave = {
    coords = vector3(1088.6899, -3187.4062, -38.8883),
    radius = 0.8,
    target = vector3(1929.9697, 4634.6743, 41.5077)
}

fd.processing = {
    leaf = {
        coords = vector3(1090.4882, -3195.7686, -39.0810),
        radius = 1.5,
        prop = { coords = vector4(1093.54, -3196.62, 39.18, 90) },
        header = "Process Coke Leaves",
        description = "Ingredients: 5x Coke Leaves",
        required = { { item = "coke_leaf", count = 5, remove = true } },
        reward = { { item = "coke_paste", count = 2 } },
    },
    box = {
        coords = vector4(1098.6561, -3194.1670, -39.0653, 7.4829),
        radius = 1.5,
        target = vector3(1099.7797, -3194.4497, -38.9882),
        heading = 7.7287,
        header = "Process Coke Paste",
        description = "Ingredients: 1x Coke Paste",
        required = { { item = "coke_paste", count = 1, remove = true } },
        reward = { { item = "coke", count = 5 } }
    },
    bag = {
        coords = vector4(1100.4979, -3199.6670, -39.1058, 195.5393),
        radius = 1.5,
        header = "Pack Coke Bag",
        description = "Ingredients: 1x Empty Bag, 5x Coke",
        required = { { item = "coke", count = 5, remove = true }, { item = "empty_bag", count = 1, remove = true } },
        reward = { { item = "coke_bag", count = 1 } }
    }
}

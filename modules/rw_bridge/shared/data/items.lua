RW.DefaultItems = {
    water = {
        label = "Water",
        weight = 500,
        description = "A bottle of water"
    },
    bread = {
        label = "Bread",
        weight = 200,
        description = "A loaf of bread"
    },
    sandwich = {
        label = "Sandwich",
        weight = 300,
        description = "A tasty sandwich"
    },
    phone = {
        label = "Phone",
        weight = 100,
        description = "A mobile phone"
    },
    carkeys = {
        label = "Car Keys",
        weight = 50,
        description = "Vehicle keys"
    },
    housekeys = {
        label = "House Keys",
        weight = 50,
        description = "House keys"
    },
    money = {
        label = "Cash",
        weight = 0,
        description = "Cash money"
    },
    black_money = {
        label = "Dirty Money",
        weight = 0,
        description = "Illegally obtained money"
    },
    id_card = {
        label = "ID Card",
        weight = 0,
        description = "Personal identification card"
    },
    driver_license = {
        label = "Driver License",
        weight = 0,
        description = "Drivers license"
    }
}

function RW.GetDefaultItemLabel(item)
    if RW.DefaultItems[item] and RW.DefaultItems[item].label then
        return RW.DefaultItems[item].label
    end
    return item
end

function RW.GetDefaultItemWeight(item)
    if RW.DefaultItems[item] and RW.DefaultItems[item].weight then
        return RW.DefaultItems[item].weight
    end
    return 0
end

return RW.DefaultItems


return {
    ['testburger'] = {
        label = 'Test Burger',
        weight = 220,
        degrade = 60,
        client = {
            image = 'burger_chicken.png',
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            export = 'ox_inventory_examples.testburger'
        },
        server = {
            export = 'ox_inventory_examples.testburger',
            test = 'what an amazingly delicious burger, amirite?'
        },
        buttons = {
            {
                label = 'Lick it',
                action = function(slot)
                    print('You licked the burger')
                end
            },
            {
                label = 'Squeeze it',
                action = function(slot)
                    print('You squeezed the burger :(')
                end
            },
            {
                label = 'What do you call a vegan burger?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('A misteak.')
                end
            },
            {
                label = 'What do frogs like to eat with their hamburgers?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('French flies.')
                end
            },
            {
                label = 'Why were the burger and fries running?',
                group = 'Hamburger Puns',
                action = function(slot)
                    print('Because they\'re fast food.')
                end
            }
        },
        consume = 0.3
    },
		
		--Bank-Cards
		
    ['bankcard_basic'] = { label = 'Bankcard Basic', weight = 100, stack = false, close = true },
    ['bankcard_gold'] = { label = 'Bankcard Gold', weight = 100, stack = false, close = true },
    ['bankcard_plat'] = { label = 'Bankcard Platinum', weight = 100, stack = false, close = true },
    ['bankcard_black'] = { label = 'Bankcard Black', weight = 100, stack = false, close = true },
    
    --HOUSING
		
	['house_key'] = {
			label = 'Housing Key',
			weight = 10,
			stack = false,
			close = true,
	},
	['police_barrier'] = {
			label = 'Police Barrier',
			weight = 300,
			stack = true,
			close = true,
	},
	['police_stormram'] = {
			label = 'Police Storm Ram',
			weight = 5000,
			stack = true,
			close = true,
	},
	['pliers'] = {
			label = 'Pliers',
			weight = 500,
			stack = true,
			close = true,
	},
	['insulating_tape'] = {
			label = 'Insulating Tape',
			weight = 200,
			stack = true,
			close = true,
	},

    --DRUGS
    ["kq_meth_low"] = {
        label = "Meth (Low grade)",
        description = 'Now thats meffed up',
        weight = 100,
        stack = true,
        close = true,
    },
  
    ["kq_meth_mid"] = {
        label = "Meth (Medium grade)",
        description = 'Medium Grade Meth',
        weight = 100,
        stack = true,
        close = true,
    },
  
    ["kq_meth_high"] = {
        label = "Meth (High grade)",
        description = 'Now thats some good shit',
        weight = 100,
        stack = true,
        close = true,
    },
  
    ["kq_ethanol"] = {
        label = "Ethanol",
        description = 'Fuel for your questionable decisions.',
        weight = 200,
        stack = true,
        close = true,
    },
  
    ["kq_meth_pills"] = {
        label = "Pseudoephedrine",
        description = 'My allergies are acting up, I swear.',
        weight = 300,
        stack = true,
        close = true,
    },
  
    ["kq_lithium"] = {
        label = "Lithium pack",
        description = 'Spicy metal for spicy crystals.',
        weight = 300,
        stack = true,
        close = true,
    },
  
    ["kq_acetone"] = {
        label = "Acetone",
        description = 'Smells like a nail salon, pays like a cartel.',
        weight = 1000,
        stack = true,
        close = true,
    },
  
    ["kq_ammonia"] = {
        label = "Ammonia",
        description = "Don't mix with bleach, unless you want a visit from God.",
        weight = 1000,
        stack = true,
        close = true,
    },
  
    ["kq_meth_lab_kit"] = {
        label = "Meth cooking kit",
        description = 'Time to cook. Everything you need to start a very illegal business.',
        weight = 3000,
        stack = true,
        close = true,
    },
		
		
    ["tow_rope"] = {
        label = "Towing rope",
        weight = 2000,
        stack = true,
        close = true,
        consume = 0,
        server = {
            export = 'kq_towing2.UseTowRope',
        },
    },

    ["winch"] = {
        label = "Car winch",
        weight = 4000,
        stack = true,
        close = true,
        consume = 0,
        server = {
            export = 'kq_towing2.UseWinch',
        },
    },
		
		-- WAIS-OUTFITBAG ITEM:
		["outfit_bag"] = {
		label = "Outfit Bag",
		weight = 500,
		stack = false,
		close = true,
		client = {
			export = "wais-outfitbag.useBag"
		},
		metadata = {}
		},

    ['electronics'] = {
        label = 'Electronics',
        weight = 30,
        stack = true,
        close = false,
        description = 'Salvaged electronic components.',
        client = { image = 'electronics.png' },
    },

    ['crime_tablet'] = {
        label = 'Crime Tablet',
        weight = 1,
        type = 'item',
        image = 'tablet.png', -- Optional, if you want an image for it
        useable = true,
        description = 'A tablet for various crime-related tasks.',
        client = {
            event = 'op-crime:openCrimeTablet'
        }
    },
    ['rope'] = {
        label = "Rope",
        description = "A rope for some SERIOUS applications.",
        weight = 250,
        client = {
            event = "op-crime:openHandcuffsMenu",
        }
    },
    ['spray_remover'] = {
        label = "Spray Remover",
        description = "A remover for gang tags.",
        weight = 250,
        client = {
            event = "op-crime:useRemover",
        }
    },
    ['spray_can'] = {
        label = "Gang Spray Can",
        description = "A spray can for gang tags.",
        weight = 1500,
        client = {
            event = "op-crime:useSpray",
        }
    },
    ['police_bodycam'] = {
        label = 'Police Body Camera',
        weight = 200,
        stack = false,
        close = true,
        description =
        'A compact body-worn camera issued to law enforcement officers for on-duty recording and live surveillance.',
        client = {
            image = 'police_bodycam.png',
            export = 'rw-mdt.police_bodycam',
        },
    },
    -- ====================================
    -- RW-BANK CARD ITEMS
    -- ====================================
    ['debit_card'] = {
        label = 'Debit Card',
        weight = 10,
        stack = false,
        close = true,
        description = 'Pacific Standard Debit Card for ATM access and purchases.',
        client = {
            image = 'debit-card.png'
        }
    },

    ['credit_card'] = {
        label = 'Credit Card',
        weight = 10,
        stack = false,
        close = true,
        description = 'Pacific Standard Premium Credit Card with cashback rewards.',
        client = {
            image = 'credit-card.png'
        }
    },

    ['savings_card'] = {
        label = 'Savings Card',
        weight = 10,
        stack = false,
        close = true,
        description = 'Pacific Standard Savings Account Card for secure deposits.',
        client = {
            image = 'savings-card.png'
        }
    },

    ['business_card'] = {
        label = 'Business Card',
        weight = 10,
        stack = false,
        close = true,
        description = 'Pacific Standard Corporate Business Card for job account access.',
        client = {
            image = 'business-card.png'
        }
    },

    ['bandage'] = {
        label = 'Bandage',
        weight = 115,
        description =
        'A sterile bandage to patch up minor wounds. Not recommended for gunshots but hey, it\'s better than nothing.',
        client = {
            anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
            prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
            disable = { move = true, car = true, combat = true },
            usetime = 2500,
            cancel = true,
        },
    },

    ['grinder'] = {
        label = 'Grinder',
        weight = 1000,
        description =
        'Three angle grinders walk into a bar…',
    },

    ['gold_ingot'] = {
        label = 'Gold Ingot',
        weight = 1000,
        description =
        'Its solid gold baby.',
    },

    ['ls_jackstand'] = {
        label = 'Jack Stand',
        weight = 0,
        stack = false,
        close = true,
        description = 'Jack Stands.. I can use these to lift vehicles.',
        client = {
            image = 'jack_stand.png'
        }
    },

    ['ls_jackstand_alt'] = {
        label = 'Alternative Jack Stand',
        weight = 0,
        stack = false,
        close = true,
        description = 'Jack Stands.. I can use these to lift vehicles.',
        client = {
            image = 'jack_stand.png'
        }
    },

    -- FOOD

    ['frenchfries'] = {
        label = 'French Fries',
        weight = 10,
        stack = true,
        close = true,
        description = 'A plate of crispy, golden-brown french fries.'
    },

    ['frenchfriesbag'] = {
        label = 'French Fries Bag',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh french fries ready for frying.'
    },

    ['burntfrenchfries'] = {
        label = 'Burnt French Fries',
        weight = 10,
        stack = true,
        close = true,
        description = 'A plate of burnt, black french fries.'
    },

    ['rawburgerpatty'] = {
        label = 'Raw Burger Patty',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh beef patty for grilling.'
    },

    ['cookedburgerpatty'] = {
        label = 'Cooked Burger Patty',
        weight = 10,
        stack = true,
        close = true,
        description = 'A cooked burger patty.'
    },

    ['restaurant_ticket'] = {
        label = 'Restaurant Ticket',
        weight = 0,
        stack = false,
        close = true,
        description = 'A receipt from a restaurant order.'
    },

    ['cheese'] = {
        label = 'Cheese',
        weight = 10,
        stack = true,
        close = true,
        description = 'Cheese slices for burgers.'
    },

    ['lettuce'] = {
        label = 'Lettuce',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh lettuce leaves.'
    },

    ['tomato'] = {
        label = 'Tomato',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh tomato slices.'
    },

    ['onion'] = {
        label = 'Onion',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh onion slices.'
    },

    ['avocado'] = {
        label = 'Avocado',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh avocado slices.'
    },

    ['texmex_sauce'] = {
        label = 'TexMex Sauce',
        weight = 10,
        stack = true,
        close = true,
        description = 'Spicy TexMex sauce.'
    },

    --BOOSTING

    ['boostingtablet'] = {
        label = 'Boosting tablet',
        weight = 350,
        description = "Seems like something's installed on this.",
        client = {
            export = 'rahe-boosting.boostingtablet',
        }
    },

    ['hackingdevice'] = {
        label = 'Hacking device',
        weight = 600,
        description = 'Will allow you to bypass vehicle security systems.',
        client = {
            export = 'rahe-boosting.hackingdevice',
        }
    },

    ['gpshackingdevice'] = {
        label = 'GPS hacking device',
        weight = 500,
        description = 'If you wish to disable vehicle GPS systems.',
        client = {
            export = 'rahe-boosting.gpshackingdevice',
        }
    },

    ['burgerbun'] = {
        label = 'Burger Bun',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh burger buns.'
    },


    ['fish'] = {
        label = 'Fresh Fish',
        weight = 150,
        stack = true,
        close = true,
        description = 'Fresh catch. Sell it at the Job Center buyer or cook it later.',
    },
    ['fish_filet'] = {
        label = 'Fish Filet',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh fish filet.'
    },

    ['beaten_egg'] = {
        label = 'Beaten Egg',
        weight = 10,
        stack = true,
        close = true,
        description = 'Beaten egg for cooking.'
    },
    ['double_cheese_burger'] = {
        label = 'Double Cheese Burger',
        weight = 15,
        stack = true,
        close = true,
        description = 'A delicious double cheese burger.'
    },

    ['cheese_burger'] = {
        label = 'Cheese Burger',
        weight = 12,
        stack = true,
        close = true,
        description = 'A classic cheese burger.'
    },

    ['pizza_pepperoni'] = {
        label = 'Pepperoni Pizza',
        weight = 20,
        stack = true,
        close = true,
        description = 'Delicious pepperoni pizza.'
    },

    ['pizza_mushroom'] = {
        label = 'Mushroom Pizza',
        weight = 20,
        stack = true,
        close = true,
        description = 'Fresh mushroom pizza.'
    },
    ['mojito'] = {
        label = 'Mojito',
        weight = 8,
        stack = true,
        close = true,
        description = 'Refreshing mojito cocktail.'
    },

    -- note: store Cola item is defined with snack exports below (was stub here)

    ['water'] = {
        label = 'Water',
        weight = 10,
        stack = true,
        close = true,
        description = 'Fresh drinking water.'
    },

    ['juice'] = {
        label = 'Juice',
        weight = 8,
        stack = true,
        close = true,
        description = 'Fresh fruit juice.'
    },

    ['sunday'] = {
        label = 'Sunday',
        weight = 10,
        stack = true,
        close = true,
        description = 'Delicious sunday dessert.'
    },

    ['sprite'] = {
        label = 'Sprite',
        weight = 8,
        stack = true,
        close = true,
        description = 'Refreshing sprite drink.'
    },

    ['coffee_cup'] = {
        label = 'Coffee Cup',
        weight = 8,
        stack = true,
        close = true,
        description = 'Hot coffee in a cup.'
    },
    ['mayonnaise'] = {
        label = 'Mayonnaise',
        weight = 5,
        stack = true,
        close = true,
        description = 'Creamy mayonnaise sauce.'
    },

    ['ketchup'] = {
        label = 'Ketchup',
        weight = 5,
        stack = true,
        close = true,
        description = 'Ketchup is a condiment made from tomatoes and vinegar.'
    },

    ['french_fries'] = {
        label = 'French Fries',
        weight = 8,
        stack = true,
        close = true,
        description = 'Crispy golden french fries, a classic side dish.'
    },

    ['cooking_oil'] = {
        label = 'Cooking Oil',
        weight = 15,
        stack = true,
        close = true,
        description = 'High-quality cooking oil for frying.'
    },
    ['chicken_nuggets_raw'] = {
        label = 'Chicken Nuggets Raw',
        weight = 10,
        stack = true,
        close = true,
        description = 'Crispy chicken nuggets.'
    },
    ['chicken_nuggets'] = {
        label = 'Chicken Nuggets',
        weight = 10,
        stack = true,
        close = true,
        description = 'Crispy chicken nuggets.'
    },
    ['cola_syrup'] = {
        label = 'Cola Syrup',
        weight = 10,
        stack = true,
        close = true,
        description = 'Cola Syrup'
    },
    ['sprite_syrup'] = {
        label = 'Sprite Syrup',
        weight = 10,
        stack = true,
        close = true,
        description = 'Sprite Syrup'
    },
    ['orange_concentrate'] = {
        label = 'Orange Concentrate',
        weight = 10,
        stack = true,
        close = true,
        description = 'Orange Concentrate'
    },
    ['carbonation'] = {
        label = 'Carbonation',
        weight = 10,
        stack = true,
        close = true,
        description = 'Carbonation'
    },
    ['orange_juice'] = {
        label = 'Orange Juice',
        weight = 10,
        stack = true,
        close = true,
        description = 'Orange Juice'
    },
    ['coffee_beans'] = {
        label = 'Coffee Beans',
        weight = 10,
        stack = true,
        close = true,
        description = 'Coffee Beans'
    },
    ['milk'] = {
        label = 'Milk',
        weight = 10,
        stack = true,
        close = true,
        description = 'Milk'
    },
    ['foam_powder'] = {
        label = 'Foam Powder',
        weight = 10,
        stack = true,
        close = true,
        description = 'Foam Powder'
    },
    ['coffee_black'] = {
        label = 'Coffee Black',
        weight = 10,
        stack = true,
        close = true,
        description = 'Coffee Black'
    },
    ['coffee_latte'] = {
        label = 'Coffee Latte',
        weight = 10,
        stack = true,
        close = true,
        description = 'Coffee Latte'
    },
    ['coffee_cappuccino'] = {
        label = 'Coffee Cappuccino',
        weight = 10,
        stack = true,
        close = true,
        description = 'Coffee Cappuccino'
    },

    ['burger'] = {
        label = 'Burger',
        weight = 220,
        description = 'A greasy, delicious burger. Warning: May contain traces of questionable ingredients.',
        client = {
            status = { hunger = 200000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
            notification = 'You ate a delicious burger'
        },
    },

    ['sprunk'] = {
        label = 'Sprunk',
        weight = 350,
        description = 'The essence of life! Or at least that\'s what the marketing team says.',
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = 'prop_ld_can_01', pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
            usetime = 2500,
            notification = 'You quenched your thirst with a sprunk'
        }
    },

    ["courier_tablet"] = {
        label = "Courier Tablet",
        weight = 1000,
        client = {
            event = "op-courier:openCourierTablet",
        }
    },

    ['parachute'] = {
        label = 'Parachute',
        weight = 8000,
        stack = false,
        description = 'For those moments when you need to exit a situation... vertically.',
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 1500
        }
    },

    ['garbage'] = {
        label = 'Garbage',
        weight = 100,
        description = 'One man\'s trash is another man\'s... still trash.',
    },

    ['police_mdt'] = {
        label = 'Mobile Data Terminal',
        weight = 500,
        stack = false,
        close = true,
        allowArmed = false,
        consume = 0,
        client = { image = 'redutzu_mdt.png' },
        description = 'Real-Wrld MDT'
    },

    ['bodycam'] = {
        label = 'Bodycam',
        weight = 300,
        stack = false,
        close = true,
        allowArmed = true,
        consume = 0,
        client = { image = 'bodycam.png' },
        description = 'Axon Bodycam'
    },

    ['tracker'] = {
        label = 'Tracker',
        description = "The app that lets you track the whereabouts of your fellow mates.",
        weight = 100,
        consume = 0,
        client = {
            remove = function(total)
                if total < 1 then
                    TriggerServerEvent('kartik-mdt:server:removePlayerBlip')
                end
            end
        },
        server = {
            export = 'kartik-mdt.useTracker'
        }
    },

    ['paperbag'] = {
        label = 'Paper Bag',
        weight = 1,
        stack = false,
        close = false,
        consume = 0
    },

    -- Convenience store extras (migrated from cloud-shop)
    ['fries'] = {
        label = 'Fries',
        weight = 150,
        stack = true,
        close = true,
        description = 'Crispy golden fries.',
        client = {
            status = { hunger = 150000 },
            anim = 'eating',
            prop = 'chips',
            usetime = 2500,
        },
    },
    ['burger_chicken'] = {
        label = 'Chicken Burger',
        weight = 220,
        stack = true,
        close = true,
        description = 'Crispy chicken sandwich.',
        client = {
            image = 'burger_chicken.png',
            status = { hunger = 220000 },
            anim = 'eating',
            prop = 'burger',
            usetime = 2500,
        },
    },
    ['ziptie'] = {
        label = 'Zip Tie',
        weight = 50,
        stack = true,
        close = true,
        description = 'Heavy-duty plastic restraints.',
    },
    ['usb_black'] = {
        label = 'USB Drive',
        weight = 50,
        stack = false,
        close = true,
        description = 'Encrypted USB stick.',
    },

    ['weedpowder'] = {
        label = 'Weed Powder',
        weight = 50,
        type = 'item',
        image = 'weedpowder.png',
        description = 'A fine powder made from cannabis leaves.'
    },
    ['weed'] = {
        label = 'Weed',
        description = "One gram of regular home grown",
        weight = 100,
    },
    ['heroinpowder'] = {
        label = 'Heroin Powder',
        weight = 50,
        type = 'item',
        image = 'heroinpowder.png',
        description = 'A fine powder derived from opium poppies.'
    },
    ['cocainepowder'] = {
        label = 'Cocaine Powder',
        weight = 50,
        type = 'item',
        image = 'cocainepowder.png',
        description = 'A fine white powder derived from coca leaves.'
    },
    -- Leaf Items
    ['cocaleaves'] = {
        label = 'Coca Leaves',
        weight = 100,
        type = 'item',
        image = 'cocaleaves.png',
        description = 'Leaves of the coca plant, used to make cocaine.'
    },
    ['weedleaves'] = {
        label = 'Weed Leaves',
        weight = 100,
        type = 'item',
        image = 'weedleaves.png',
        description = 'Raw leaves of the cannabis plant.'
    },
    ['rawopium'] = {
        label = 'Raw Opium',
        weight = 100,
        type = 'item',
        image = 'rawopium.png',
        description = 'Sticky brown substance extracted from poppy pods.'
    },
    -- Pouch Items
    ['cokepouch'] = {
        label = 'Coke Pouch',
        weight = 200,
        type = 'item',
        image = 'cokepouch.png',
        description = 'A small pouch filled with cocaine powder.'
    },
    ['heroinpouch'] = {
        label = 'Heroin Pouch',
        weight = 200,
        type = 'item',
        image = 'heroinpouch.png',
        description = 'A small pouch filled with heroin powder.'
    },
    ['weedpouch'] = {
        label = 'Weed Pouch',
        weight = 200,
        type = 'item',
        image = 'weedpouch.png',
        description = 'A small pouch filled with weed powder.'
    },
    ['plastic_bag'] = {
        label = 'Plastic Bag',
        weight = 50,
        type = 'item',
        image = 'plastic_bag.png',
        description = 'An empty plastic bag for storing items.'
    },

    ["watering_can"] = {
        label = "Watering Can",
        weight = 500,
        stack = false,
        close = false,
        description = "Used for watering crops and cleaning animals.",
        client = {
            image = "watering_can.png",
        }
    },

    ["basic_hoe"] = {
        label = "Basic Hoe",
        weight = 800,
        stack = false,
        close = false,
        description = "A sturdy hoe for planting and harvesting root crops.",
        client = {
            image = "basic_hoe.png",
        }
    },

    ["sickle"] = {
        label = "Sickle",
        weight = 600,
        stack = false,
        close = false,
        description = "A curved blade for harvesting stalk crops like wheat and corn.",
        client = {
            image = "sickle.png",
        }
    },

    ["steel_shears"] = {
        label = "Steel Shears",
        weight = 500,
        stack = false,
        close = false,
        description = "Heavy-duty shears for picking fruit and collecting animal produce.",
        client = {
            image = "steel_shears.png",
        }
    },

    ["fertilizer"] = {
        label = "Fertilizer",
        weight = 300,
        stack = true,
        close = true,
        description = "Plant growth booster. Halves growth time and increases harvest yield by 30%.",
        client = {
            image = "fertilizer.png",
        }
    },

    ["advanced_fertilizer"] = {
        label = "Advanced fertilizer",
        weight = 500,
        stack = false,
        close = false,
        description = "Fertilizer with the litte extra",
        client = {
            image = "advanced_fertilizer.png",
        }
    },

    ["liquid_fertilizer"] = {
        label = "Liquid Fertilizer",
        weight = 200,
        stack = false,
        close = false,
        description = "Basicly Water with nutrations",
        client = {
            image = "liquid_fertilizer.png",
        }
    },

    ["weed_lemonhaze_seed"] = {
        label = "Weed Lemonhaze Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Weed Lemonhaze Seed",
        client = {
            image = "weed_lemonhaze_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_lemonhaze"] = {
        label = "Weed Lemonhaze",
        weight = 20,
        stack = true,
        close = false,
        description = "Weed Lemonhaze",
        client = {
            image = "weed_lemonhaze.png",
        },
    },

    ["weed_og_seed"] = {
        label = "Weed Og Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Weed Og Seed",
        client = {
            image = "weed_og_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_og"] = {
        label = "weed Og",
        weight = 20,
        stack = true,
        close = false,
        description = "weed Og",
        client = {
            image = "weed_og.png",
        },
    },

    ["weed_purple_haze_seed"] = {
        label = "Weed Purple Haze Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Weed Purple Haze Seed",
        client = {
            image = "weed_purple_haze_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_purple_haze"] = {
        label = "weed Purple Haze",
        weight = 20,
        stack = true,
        close = false,
        description = "weed Purple Haze",
        client = {
            image = "weed_purple_haze.png",
        },
    },

    ["weed_white_widow_seed"] = {
        label = "Weed White Widow Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Weed White Widow Seed",
        client = {
            image = "weed_white_widow_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_white_widow"] = {
        label = "weed White Widow",
        weight = 20,
        stack = true,
        close = false,
        description = "weed White Widow",
        client = {
            image = "weed_white_widow.png",
        }
    },

    ["weed_blueberry_seed"] = {
        label = "Weed Blueberry Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Weed Blueberry Seed",
        client = {
            image = "weed_blueberry_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_blueberry"] = {
        label = "weed Blueberry",
        weight = 20,
        stack = true,
        close = false,
        description = "weed Blueberry",
        client = {
            image = "weed_blueberry.png",
        }
    },

    ["coca_seed"] = {
        label = "Coca Seed",
        weight = 20,
        stack = true,
        close = true,
        consume = 0,
        description = "Coca Seed",
        client = {
            image = "coca_seed.png",
        },
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["coca"] = {
        label = "Coca",
        weight = 20,
        stack = true,
        close = false,
        description = "Coca",
        client = {
            image = "coca.png",
        }
    },

    ["paper"] = {
        label = "Paper",
        weight = 50,
        stack = true,
        close = false,
        description = "Paper",
        client = {
            image = "paper.png",
        }
    },

    ["nitrous"] = {
        label = "Nitrous",
        weight = 500,
        stack = false,
        close = false,
        description = "Nitrous",
        client = {
            image = "nitrous.png",
        }
    },

    ["weed_processing_table"] = {
        label = "Weed Processing Table",
        weight = 1000,
        stack = false,
        close = true,
        consume = 0,
        description = "Process some weed",
        client = {
            image = "weed_processing_table.png",
        },
        server = {
            export = "it-drugs.placeProcessingTable"
        }
    },

    ["cocaine_processing_table"] = {
        label = "Cocaine Processing Table",
        weight = 1000,
        stack = false,
        close = true,
        description = "Process some cocaine",
        consume = 0,
        client = {
            image = "cocaine_processing_table.png",
        },
        server = {
            export = "it-drugs.placeProcessingTable"
        }
    },

    ["cocaine"] = {
        label = "Cocaine",
        weight = 20,
        stack = true,
        close = true,
        description = "A little bag of cocaine",
        consume = 0,
        server = {
            export = "it-drugs.takeDrug"
        },
        client = {
            image = "cocaine.png",
        },
    },

    ["joint"] = {
        label = "Joint",
        weight = 10,
        stack = true,
        close = true,
        description = "Joint",
        consume = 0,
        server = {
            export = "it-drugs.takeDrug"
        },
        client = {
            image = "joint.png",
        }
    },

    ['panties'] = {
        label = 'Knickers',
        weight = 10,
        consume = 0,
        client = {
            status = { thirst = -100000, stress = -25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
            usetime = 2500,
        }
    },



    ['pickaxe'] = {
        label = 'Pickaxe',
        weight = 2000,
        stack = false,
        close = true,
        description = 'A sturdy pickaxe for mining.',
        consume = 0, -- don’t remove the item on use (tool)

        client = {
            image = 'pickaxe.png',
            export = 'qbx_pickaxe.usePickaxe',

            -- Optional: progressbar/anim/prop shown while "using" the item
            usetime = 2000,
            cancel = true,
            disable = { move = true, car = true, combat = true },

            anim = {
                dict = 'amb@world_human_hammering@male@base',
                clip = 'base'
            },

            prop = {
                model = 'prop_tool_pickaxe',
                pos = { x = 0.10, y = 0.02, z = -0.02 },
                rot = { x = 80.0, y = 180.0, z = 0.0 },
                bone = 57005
            }
        }
    },


    ['crutch'] = {
        label = 'Crutch',
        weight = 165,
        stack = false,
        close = true,
    },

    ['wheelchair'] = {
        label = 'Wheelchair',
        weight = 540,
        stack = false,
        close = true,
    },

    ['dealer_phone'] = {
        label = 'Dealer Phone',
        weight = 936,
        stack = false,
        close = true,
    },

    ['mustard'] = {
        label = 'Mustard',
        weight = 500,
        client = {
            status = { hunger = 25000, thirst = 25000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
            usetime = 2500,
            notification = 'You... drank mustard'
        },
    },

    ['water'] = {
        label = 'Water',
        weight = 500,
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
            usetime = 2500,
            cancel = true,
            notification = 'You drank some refreshing water'
        },
    },

    ['armour'] = {
        label = 'Bulletproof Vest',
        weight = 3000,
        stack = false,
        client = {
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
            usetime = 3500
        },
    },

    -- ============================================
    -- CLOTHING ITEMS - For Character Panel
    -- These items have metadata with drawable/texture IDs
    -- ============================================

    ['clothing'] = {
        label = 'Clothing',
        weight = 10,
        consume = 0,
    },

    -- Hat items (Component 0 / Prop 0)
    ['clothing_hat_cap'] = {
        label = 'Baseball Cap',
        weight = 50,
        stack = false,
        consume = 0,
        close = true,
        category = 'hat',
        description = 'A stylish baseball cap',
        client = {
            image = 'clothing_hat.png',
            event = 'ox_inventory:equipClothing',
            category = 'hat',
        },
    },

    ['clothing_hat_beanie'] = {
        label = 'Beanie',
        weight = 40,
        stack = false,
        consume = 0,
        close = true,
        category = 'hat',
        description = 'A warm beanie hat',
        client = {
            image = 'clothing_hat.png',
            event = 'ox_inventory:equipClothing',
            category = 'hat',
        },
    },

    -- Shirt items (Component 3 - Torso)
    ['clothing_shirt_tee'] = {
        label = 'T-Shirt',
        weight = 100,
        stack = false,
        consume = 0,
        close = true,
        category = 'shirt',
        description = 'A casual t-shirt',
        client = {
            image = 'clothing_shirt.png',
            event = 'ox_inventory:equipClothing',
            category = 'shirt',
        },
    },

    ['clothing_shirt_hoodie'] = {
        label = 'Hoodie',
        weight = 200,
        stack = false,
        consume = 0,
        close = true,
        category = 'shirt',
        description = 'A comfortable hoodie',
        client = {
            image = 'clothing_shirt.png',
            event = 'ox_inventory:equipClothing',
            category = 'shirt',
        },
    },

    -- Pants items (Component 4 - Legs)
    ['clothing_pants_jeans'] = {
        label = 'Jeans',
        weight = 150,
        stack = false,
        consume = 0,
        close = true,
        category = 'pants',
        description = 'Classic denim jeans',
        client = {
            image = 'clothing_pants.png',
            event = 'ox_inventory:equipClothing',
            category = 'pants',
        },
    },

    ['clothing_pants_cargo'] = {
        label = 'Cargo Pants',
        weight = 180,
        stack = false,
        consume = 0,
        close = true,
        category = 'pants',
        description = 'Tactical cargo pants with pockets',
        client = {
            image = 'clothing_pants.png',
            event = 'ox_inventory:equipClothing',
            category = 'pants',
        },
    },

    -- Shoes items (Component 6 - Feet)
    ['clothing_shoes_sneakers'] = {
        label = 'Sneakers',
        weight = 300,
        stack = false,
        consume = 0,
        close = true,
        category = 'shoes',
        description = 'Comfortable sneakers',
        client = {
            image = 'clothing_shoes.png',
            event = 'ox_inventory:equipClothing',
            category = 'shoes',
        },
    },

    ['clothing_shoes_boots'] = {
        label = 'Boots',
        weight = 450,
        stack = false,
        consume = 0,
        close = true,
        category = 'shoes',
        description = 'Heavy duty boots',
        client = {
            image = 'clothing_shoes.png',
            event = 'ox_inventory:equipClothing',
            category = 'shoes',
        },
    },

    -- Glasses items (Prop 1)
    ['clothing_glasses_aviator'] = {
        label = 'Aviator Sunglasses',
        weight = 30,
        stack = false,
        consume = 0,
        close = true,
        category = 'glasses',
        description = 'Classic aviator style sunglasses',
        client = {
            image = 'clothing_glasses.png',
            event = 'ox_inventory:equipClothing',
            category = 'glasses',
        },
    },

    -- Mask items (Component 1)
    ['clothing_mask_bandana'] = {
        label = 'Bandana',
        weight = 20,
        stack = false,
        consume = 0,
        close = true,
        category = 'mask',
        description = 'A simple bandana mask',
        client = {
            image = 'clothing_mask.png',
            event = 'ox_inventory:equipClothing',
            category = 'mask',
        },
    },

    ['clothing_mask_ski'] = {
        label = 'Ski Mask',
        weight = 40,
        stack = false,
        consume = 0,
        close = true,
        category = 'mask',
        description = 'A full ski mask',
        client = {
            image = 'clothing_mask.png',
            event = 'ox_inventory:equipClothing',
            category = 'mask',
        },
    },

    -- Vest items (Component 9 - Body Armor)
    ['clothing_vest_kevlar'] = {
        label = 'Kevlar Vest',
        weight = 2000,
        stack = false,
        consume = 0,
        close = true,
        category = 'vest',
        description = 'A protective kevlar vest',
        client = {
            image = 'clothing_vest.png',
            event = 'ox_inventory:equipClothing',
            category = 'vest',
        },
    },

    -- Bag items (Component 5)
    ['clothing_bag_backpack'] = {
        label = 'Backpack',
        weight = 500,
        stack = false,
        consume = 0,
        close = true,
        category = 'bag',
        description = 'A standard backpack',
        client = {
            image = 'clothing_bag.png',
            event = 'ox_inventory:equipClothing',
            category = 'bag',
        },
    },

    -- Chain/Accessories items (Component 7)
    ['clothing_chain_gold'] = {
        label = 'Gold Chain',
        weight = 100,
        stack = false,
        consume = 0,
        close = true,
        category = 'chain',
        description = 'A flashy gold chain',
        client = {
            image = 'clothing_chain.png',
            event = 'ox_inventory:equipClothing',
            category = 'chain',
        },
    },

    -- Gloves items (Component 3 variant)
    ['clothing_gloves_leather'] = {
        label = 'Leather Gloves',
        weight = 80,
        stack = false,
        consume = 0,
        close = true,
        category = 'gloves',
        description = 'Classic leather gloves',
        client = {
            image = 'clothing_gloves.png',
            event = 'ox_inventory:equipClothing',
            category = 'gloves',
        },
    },

    ['clothing_piece'] = {
        label = 'Clothing',
        weight = 100,
        stack = false,
        consume = 0,
        close = false,
        category = 'shirt',
        description = 'A clothing piece returned from your outfit',
        client = {
            image = 'clothing_shirt.png',
            event = 'ox_inventory:equipClothing',
            category = 'shirt',
        },
    },

    ['money'] = {
        label = 'Money',
        weight = 1,
    },

    ['black_money'] = {
        label = 'Dirty Money',
        weight = 1,
    },

    ['markedbills'] = {
        label = 'Marked Bills',
        weight = 1,
        stack = true,
        close = true,
        description = 'Unmarked bills that need laundering',
        client = {
            image = 'markedbills.png',
        }
    },

    ['id_card'] = {
        label = 'Identification Card',
        weight = 0,
    },

    ['driver_license'] = {
        label = 'Drivers License',
        weight = 0,
    },

    ['weaponlicense'] = {
        label = 'Weapon License',
        weight = 0,
    },

    ['lawyerpass'] = {
        label = 'Lawyer Pass',
        weight = 0,
    },

    ['radio'] = {
        label = 'Radio', weight = 1000, stack = false, close = true,
        allowArmed = true, consume = 0, client = { export = 'plt_radio.useRadio' },
    },

    ['radio_signal_analyzer'] = {
        label = 'Signal Analyzer', weight = 800, stack = false, close = true,
        consume = 0, client = { export = 'plt_radio.useSignalEquipment' },
    },

    ['radio_jammer_controller'] = {
        label = 'Jammer Controller', weight = 800, stack = false, close = true,
        consume = 0, client = { export = 'plt_radio.useSignalEquipment' },
    },

    ['radio_transmitter'] = {
        label = 'Radio Transmitter', weight = 5000, stack = false, close = true,
        consume = 0, client = { export = 'plt_radio.useSignalEquipment' },
    },

    ['radio_jammer_50'] = {
        label = 'Compact Jammer (50 m)', weight = 2000, stack = false, close = true,
        consume = 0, client = { export = 'plt_radio.useSignalEquipment' },
    },

    ['radio_jammer_200'] = {
        label = 'Area Jammer (200 m)', weight = 5000, stack = false, close = true,
        consume = 0, client = { export = 'plt_radio.useSignalEquipment' },
    },

    ['jammer'] = {
        label = 'Radio Jammer',
        weight = 10000,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'AAA Cells',
        weight = 1000,
        stack = true,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },

    ['vehiclekeys'] = {
        label = 'Vehicle Key',
        weight = 220,
        stack = false,
        close = true,
        description = "Keys To A Car",
        client = {
            image = 'vehicle_keyfob.png',
        }
    },

    ['keyring'] = {
        label = 'Keyring',
        weight = 220,
        stack = false,
        close = true,
        description = "A keyring that holds car keys.",
        client = {
            image = 'vehicle_keyfob.png',
        }
    },



    ['rental_paperwork'] = {
        label = 'Rental Paperwork',
        weight = 220,
        stack = false,
        close = true,
        description = "Paperwork for a rental vehicle"
    },

    ['aftermarket_locks'] = {
        label = 'Aftermarket Lock System',
        weight = 220,
        stack = false,
        close = true,
        description = "A lock system for the locks in a car.",
    },

    ['screwdriverset'] = {
        label = 'Screwdriver Set',
        weight = 500,
    },

    ['screwdriver'] = {
        label = 'Screwdriver',
        weight = 50,
        stack = true,
        close = false,
        description = 'A useful tool',
        client = {
            image = 'screwdriver.png',
        }
    },

    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 500,
    },

    ['c4_bomb'] = {
        label = 'C4 bomb',
        weight = 1,
        stack = true,
        close = true,
        description = 'B00M'
    },

    ['cleaningkit'] = {
        label = 'Cleaning Kit',
        weight = 500,
    },

    ['cleankit'] = {
        label = 'Car Cleaner Kit',
        weight = 600,
    },

    ['bigkit'] = {
        label = 'Big Fix-it Kit',
        weight = 800,
    },

    ['smallkit'] = {
        label = 'Small Fix Kit',
        weight = 400,
    },

    ['repairkit'] = {
        label = 'Repair Kit',
        weight = 2500,
    },

    ['tirekit'] = {
        label = 'Tire Repair kit',
        weight = 3000,
    },

    ['advancedrepairkit'] = {
        label = 'Advanced Repair Kit',
        weight = 4000,
    },

    ['mdt_tablet'] = {
        label = 'MDT Tablet',
        weight = 500,
        stack = false,
        close = true,
        allowArmed = false,
        description = 'A police-issued tablet to access the MDT system.',
        client = {
            event = 'ersi:client:useMDTTablet',
        },
    },

    ["broom"] = {
        label = "Broom",
        weight = 500,
        stack = false,
        close = true,
        allowArmed = false,
        description = "Clean your scenes",
        client = {
            event = "ersi:broom",
        },
    },

    ['wraithradar'] = {
        label = 'Wraith Radar Remote',
        weight = 100,
        stack = false,
        close = true,
        allowArmed = false,
        description = "Remote for Police Radar Control",
        client = {
            event = 'wk:openRemote'
        }
    },

    ['firehose'] = {
        label = 'Fire Hose',
        weight = 500,
        stack = false,
        close = true,
        allowArmed = false,
        description = "Put out those flames",
        client = {
            event = 'ersi:firehose'
        }
    },

    ['stretcher'] = {
        label = 'Stretcher',
        weight = 1000,
        stack = false,
        close = true,
        allowArmed = false,
        description = "Fix me up doc",
        client = {
            event = 'ersi:stretcher'
        }
    },

    ['laptop'] = {
        label = 'RW Laptop',
        weight = 1000,
        description = 'A high-tech gadget, probably useful',
        stack = false,
        close = false,
        consume = 0,
        client = {
            image = 'RW-laptop.png',
        },
        server = {
            export = 'fd_laptop.useLaptop'
        },
        buttons = {
            {
                label = "Open storage",
                action = function(slot)
                    TriggerServerEvent("fd_laptop:server:openLaptopStorage", slot)
                end
            }
        }
    },

    ['diamond_ring'] = {
        label = 'Diamond',
        weight = 1500,
    },


    ['rolex'] = {
        label = 'Golden Watch',
        weight = 1500,
    },

    ['goldbar'] = {
        label = 'Gold Bar',
        weight = 1500,
    },

    ['goldchain'] = {
        label = 'Golden Chain',
        weight = 1500,
    },

    ['crack_baggy'] = {
        label = 'Crack Baggy',
        weight = 100,
    },

    ['cokebaggy'] = {
        label = 'Bag of Coke',
        weight = 100,
    },

    ['coke_brick'] = {
        label = 'Coke Brick',
        weight = 2000,
    },

    ['coke_small_brick'] = {
        label = 'Coke Package',
        weight = 1000,
    },

    ['xtcbaggy'] = {
        label = 'Bag of Ecstasy',
        weight = 100,
    },

    ['meth'] = {
        label = 'Methamphetamine',
        weight = 100,
    },

    ['oxy'] = {
        label = 'Oxycodone',
        weight = 100,
    },

    ['weed_ak47'] = {
        label = 'AK47 2g',
        weight = 200,
    },

    ['weed_ak47_seed'] = {
        label = 'AK47 Seed',
        weight = 1,
    },

    ['weed_skunk'] = {
        label = 'Skunk 2g',
        weight = 200,
    },

    ['weed_skunk_seed'] = {
        label = 'Skunk Seed',
        weight = 1,
    },

    ['weed_amnesia'] = {
        label = 'Amnesia 2g',
        weight = 200,
    },

    ['weed_amnesia_seed'] = {
        label = 'Amnesia Seed',
        weight = 1,
    },

    ['weed_og-kush'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_og-kush_seed'] = {
        label = 'OGKush Seed',
        weight = 1,
    },

    ['weed_white-widow'] = {
        label = 'OGKush 2g',
        weight = 200,
    },

    ['weed_white-widow_seed'] = {
        label = 'White Widow Seed',
        weight = 1,
    },

    ['weed_purple-haze'] = {
        label = 'Purple Haze 2g',
        weight = 200,
    },

    ['weed_purple-haze_seed'] = {
        label = 'Purple Haze Seed',
        weight = 1,
    },

    ['weed_brick'] = {
        label = 'Weed Brick',
        weight = 2000,
    },

    ['weed_nutrition'] = {
        label = 'Plant Fertilizer',
        weight = 2000,
    },

    ['rolling_paper'] = {
        label = 'Rolling Paper',
        weight = 0,
    },

    ['empty_weed_bag'] = {
        label = 'Empty Weed Bag',
        weight = 0,
    },

    ['firstaid'] = {
        label = 'First Aid',
        weight = 2500,
    },

    ['ifaks'] = {
        label = 'Individual First Aid Kit',
        weight = 2500,
    },

    ['painkillers'] = {
        label = 'Painkillers',
        weight = 400,
    },

    ['firework1'] = {
        label = '2Brothers',
        weight = 1000,
    },

    ['firework2'] = {
        label = 'Poppelers',
        weight = 1000,
    },

    ['firework3'] = {
        label = 'WipeOut',
        weight = 1000,
    },

    ['firework4'] = {
        label = 'Weeping Willow',
        weight = 1000,
    },

    ['steel'] = {
        label = 'Steel',
        weight = 100,
        client = { image = 'steel.png' },
    },

    ['rubber'] = {
        label = 'Rubber',
        weight = 100,
        client = { image = 'rubber.png' },
    },

    ['metalscrap'] = {
        label = 'Metal Scrap',
        weight = 100,
    },

    ['iron'] = {
        label = 'Iron',
        weight = 100,
    },

    ['copper'] = {
        label = 'Copper',
        weight = 100,
    },

    ['aluminum'] = {
        label = 'Aluminium',
        weight = 100,
        client = { image = 'aluminum.png' },

    -- Prism prp-mining items
    ['iron_ore'] = {
        label = 'Iron Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['copper_ore'] = {
        label = 'Copper Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['zinc_ore'] = {
        label = 'Zinc Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['aluminium_ore'] = {
        label = 'Aluminium Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['lithium_ore'] = {
        label = 'Lithium Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['nickel_ore'] = {
        label = 'Nickel Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['magnesium_ore'] = {
        label = 'Magnesium Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['gold_ore'] = {
        label = 'Gold Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['diamond_ore'] = {
        label = 'Diamond Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['limestone_ore'] = {
        label = 'Limestone Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['basic_looking_ore'] = {
        label = 'Stone Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['gem_ore'] = {
        label = 'Gem Ore',
        weight = 500,
        stack = true,
        close = true,
    },

    ['zinc'] = {
        label = 'Zinc',
        weight = 500,
        stack = true,
        close = true,
    },

    ['aluminium'] = {
        label = 'Aluminium',
        weight = 500,
        stack = true,
        close = true,
    },

    ['lithium'] = {
        label = 'Lithium',
        weight = 500,
        stack = true,
        close = true,
    },

    ['nickel'] = {
        label = 'Nickel',
        weight = 500,
        stack = true,
        close = true,
    },

    ['magnesium'] = {
        label = 'Magnesium',
        weight = 500,
        stack = true,
        close = true,
    },

    ['gold'] = {
        label = 'Gold',
        weight = 500,
        stack = true,
        close = true,
    },

    ['limestone'] = {
        label = 'Limestone',
        weight = 500,
        stack = true,
        close = true,
    },

    ['basic_looking'] = {
        label = 'Stone',
        weight = 500,
        stack = true,
        close = true,
    },

    ['gem'] = {
        label = 'Gem',
        weight = 500,
        stack = true,
        close = true,
    },

    ['sapphire_gem'] = {
        label = 'Sapphire',
        weight = 100,
        stack = true,
        close = true,
    },

    ['ruby_gem'] = {
        label = 'Ruby',
        weight = 100,
        stack = true,
        close = true,
    },

    ['emerald_gem'] = {
        label = 'Emerald',
        weight = 100,
        stack = true,
        close = true,
    },

    ['topaz_gem'] = {
        label = 'Topaz',
        weight = 100,
        stack = true,
        close = true,
    },
    },

    ['plastic'] = {
        label = 'Plastic',
        weight = 100,
    },

    ['glass'] = {
        label = 'Glass',
        weight = 100,
    },

    ['gatecrack'] = {
        label = 'Gatecrack',
        weight = 1000,
    },

    ['cryptostick'] = {
        label = 'Crypto Stick',
        weight = 100,
    },

    --Wais-JobPack

    ["gold_tooth"] = {
        label = "Gold Tooth",
        weight = 1,
        stack = true,
        close = false,
    },

    ["dirty_photo"] = {
        label = "Dity Photo",
        weight = 1,
        stack = true,
        close = false,
    },

    ["chain"] = {
        label = "Chain",
        weight = 1,
        stack = true,
        close = false,
    },

    ["medal"] = {
        label = "Medal",
        weight = 1,
        stack = true,
        close = false,
    },

    ["rusted_tin"] = {
        label = "Rusted Tin",
        weight = 1,
        stack = true,
        close = false,
    },

    ["nail"] = {
        label = "Nail",
        weight = 1,
        stack = true,
        close = false,
    },

    ["ring"] = {
        label = "Ring",
        weight = 1,
        stack = true,
        close = false,
    },

    ["vehicle_tyre"] = {
        label = "Vehicle Tyre",
        weight = 1,
        stack = true,
        close = false,
    },

    ["vehicle_door"] = {
        label = "Vehicle Door",
        weight = 1,
        stack = true,
        close = false,
    },

    ['decrypter'] = {
        label = 'Decrypter v2',
        weight = 500,
        stack = false,
        close = true,
        description = 'Advanced hardware to bypass digital security.',
        client = {
            image = 'decrypter.png',
        }
    },

    ['trojan_usb'] = {
        label = 'Trojan USB',
        weight = 50,
        stack = true,
        close = true,
        description = 'Malicious software on a stick. Used for ATMs.',
        client = {
            image = 'trojan_usb.png',
        }
    },

    ['usb'] = {
        label = 'RW USB',
        weight = 150,
    },

    ['toaster'] = {
        label = 'Toaster',
        weight = 5000,
    },

    ['small_tv'] = {
        label = 'Small TV',
        weight = 100,
    },

    ['security_card_01'] = {
        label = 'Security Card A',
        weight = 100,
    },

    ['security_card_02'] = {
        label = 'Security Card B',
        weight = 100,
    },

    ['drill'] = {
        label = 'Drill',
        weight = 5000,
    },

    ['thermite'] = {
        label = 'Thermite',
        weight = 1000,
    },

    ['diving_gear'] = {
        label = 'Diving Gear',
        weight = 30000,
    },

    ['diving_fill'] = {
        label = 'Diving Tube',
        weight = 3000,
    },

    ['antipatharia_coral'] = {
        label = 'Antipatharia',
        weight = 1000,
    },

    ['dendrogyra_coral'] = {
        label = 'Dendrogyra',
        weight = 1000,
    },

    ['jerry_can'] = {
        label = 'Jerrycan',
        weight = 3000,
    },

    ['nitrous'] = {
        label = 'Nitrous',
        weight = 1000,
    },

    ['wine'] = {
        label = 'Wine',
        weight = 500,
    },

    ['grape'] = {
        label = 'Grape',
        weight = 10,
    },

    ['grapejuice'] = {
        label = 'Grape Juice',
        weight = 200,
    },

    ['coffee'] = {
        label = 'Coffee',
        weight = 200,
    },

    ['vodka'] = {
        label = 'Vodka',
        weight = 500,
    },

    ['whiskey'] = {
        label = 'Whiskey',
        weight = 200,
    },

    ['beer'] = {
        label = 'Beer',
        weight = 200,
    },

    ['sandwich'] = {
        label = 'Sandwich',
        weight = 200,
    },

    ['walking_stick'] = {
        label = 'Walking Stick',
        weight = 1000,
    },

    ['lighter'] = {
        label = 'Lighter',
        weight = 200,
    },

    ['binoculars'] = {
        label = 'Binoculars',
        weight = 800,
    },

    ['stickynote'] = {
        label = 'Sticky Note',
        weight = 0,
    },

    ['empty_evidence_bag'] = {
        label = 'Empty Evidence Bag',
        weight = 200,
    },

    ['filled_evidence_bag'] = {
        label = 'Filled Evidence Bag',
        weight = 200,
    },

    ['harness'] = {
        label = 'Harness',
        weight = 200,
    },

    -- base handcuffs definition
    ['handcuffs'] = {
        label = 'Handcuffs',
        weight = 200,
    },

    -- lb-phone
    ['phone'] = {
        label = 'Phone',
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            export = 'lb-phone.UsePhoneItem',
            remove = function()
                TriggerEvent('lb-phone:itemRemoved')
            end,
            add = function()
                TriggerEvent('lb-phone:itemAdded')
            end
        }
    },

    -- wasabi / medical & police tools
    ['uvlight'] = {
        label = 'UV Light',
        weight = 95,
        stack = false
    },

    ['bleachwipes'] = {
        label = 'Bleach Wipes',
        weight = 185,
        stack = true
    },

    ['bobby_pin'] = {
        label = 'Bobby Pin',
        weight = 2,
        stack = true,
        close = true,
    },

    ['tracking_bracelet'] = {
        label = 'Tracking Bracelet',
        weight = 2,
        stack = true,
        close = true,
    },

    ['medikit'] = {
        label = 'Medikit',
        weight = 165,
        stack = true,
        close = true,
    },

    ['medbag'] = {
        label = 'Medical Bag',
        weight = 165,
        stack = false,
        close = true,
    },

    ['tweezers'] = {
        label = 'Tweezers',
        weight = 2,
        stack = true,
        close = true,
    },

    ['suturekit'] = {
        label = 'Suture Kit',
        weight = 15,
        stack = true,
        close = true,
    },

    ['icepack'] = {
        label = 'Ice Pack',
        weight = 29,
        stack = true,
        close = true,
    },

    ['burncream'] = {
        label = 'Burn Cream',
        weight = 19,
        stack = true,
        close = true,
    },

    ['defib'] = {
        label = 'Defibrillator',
        weight = 225,
        stack = false,
        close = true,
    },

    ['sedative'] = {
        label = 'Sedative',
        weight = 15,
        stack = true,
        close = true,
    },

    ['morphine30'] = {
        label = 'Morphine 30MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['morphine15'] = {
        label = 'Morphine 15MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['perc30'] = {
        label = 'Percocet 30MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['perc10'] = {
        label = 'Percocet 10MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['perc5'] = {
        label = 'Percocet 5MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['vic10'] = {
        label = 'Vicodin 10MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['vic5'] = {
        label = 'Vicodin 5MG',
        weight = 2,
        stack = true,
        close = true,
    },

    ['recoveredbullet'] = {
        label = 'Recovered Bullet',
        weight = 1,
        stack = true,
        close = false,
    },

    -- JG mechanic / vehicle parts
    ['engine_oil'] = {
        label = 'Engine Oil',
        weight = 1000,
    },

    ['tyre_replacement'] = {
        label = 'Tyre Replacement',
        weight = 1000,
    },

    ['clutch_replacement'] = {
        label = 'Clutch Replacement',
        weight = 1000,
    },

    ['air_filter'] = {
        label = 'Air Filter',
        weight = 100,
    },

    ['spark_plug'] = {
        label = 'Spark Plug',
        weight = 1000,
    },

    ['brakepad_replacement'] = {
        label = 'Brakepad Replacement',
        weight = 1000,
    },

    ['suspension_parts'] = {
        label = 'Suspension Parts',
        weight = 1000,
    },

    -- Engine Items
    ['i4_engine'] = {
        label = 'I4 Engine',
        weight = 1000,
    },

    ['v6_engine'] = {
        label = 'V6 Engine',
        weight = 1000,
    },

    ['v8_engine'] = {
        label = 'V8 Engine',
        weight = 1000,
    },

    ['v12_engine'] = {
        label = 'V12 Engine',
        weight = 1000,
    },

    ['7.2V8'] = {
        label = '7.2L V8 Engine',
        weight = 1200,
        stack = false,
        description = '1000 hp 7.2L V8 — dens-only candidate.',
    },

    ['V8-TT'] = {
        label = 'V8-TwinTurbo Engine',
        weight = 1200,
        stack = false,
        description = '1341 hp 5.1L V8-TT — dens-only candidate.',
    },

    ['hellcat_v8'] = {
        label = 'Hellcat Supercharged V8',
        weight = 1200,
        stack = false,
        description = 'Premium crate — 6.2L supercharged V8. Tech Den bay only.',
    },

    ['tt_v6_35'] = {
        label = 'Twin-Turbo V6 3.5L',
        weight = 1100,
        stack = false,
        description = 'Premium crate — twin-turbo V6. Tech Den bay only.',
    },

    ['i6_2jz_race'] = {
        label = 'I6 Twin-Turbo Race',
        weight = 1150,
        stack = false,
        description = 'Premium crate — inline-six race twin-turbo (2JZ-style). Tech Den bay only.',
    },

    ['rotary_bp'] = {
        label = 'Twin-Rotor Bridgeport',
        weight = 900,
        stack = false,
        description = 'Premium crate — bridgeported rotary. Tech Den bay only.',
    },

    ['v12_59_na'] = {
        label = 'NA V12 5.9L',
        weight = 1300,
        stack = false,
        description = 'Premium crate — naturally aspirated 5.9L V12. Tech Den bay only.',
    },

    ['flat6_gt3'] = {
        label = 'Flat-6 Race',
        weight = 1050,
        stack = false,
        description = 'Premium crate — race flat-six. Tech Den bay only.',
    },

    ['bigblock_427fe'] = {
        label = '427 Big-Block FE',
        weight = 1400,
        stack = false,
        description = 'Premium crate — 427 FE big-block (not Elephant). Tech Den bay only.',
    },



    ['turbocharger'] = {
        label = 'Turbocharger',
        weight = 1000,
    },

    -- Electric Engines
    ['ev_motor'] = {
        label = 'High-Torque EV Drive',
        weight = 1100,
        stack = false,
        description = 'Premium electric drive unit — Tech Den / EV chassis.',
    },

    ['ev_battery'] = {
        label = 'EV Battery',
        weight = 1000,
    },

    ['ev_coolant'] = {
        label = 'EV Coolant',
        weight = 1000,
    },

    -- Drivetrain Items
    ['awd_drivetrain'] = {
        label = 'AWD Drivetrain',
        weight = 1000,
    },

    ['rwd_drivetrain'] = {
        label = 'RWD Drivetrain',
        weight = 1000,
    },

    ['fwd_drivetrain'] = {
        label = 'FWD Drivetrain',
        weight = 1000,
    },

    -- Tuning Items
    ['slick_tyres'] = {
        label = 'Slick Tyres',
        weight = 1000,
    },

    ['semi_slick_tyres'] = {
        label = 'Semi Slick Tyres',
        weight = 1000,
    },

    ['offroad_tyres'] = {
        label = 'Offroad Tyres',
        weight = 1000,
    },

    ['drift_tuning_kit'] = {
        label = 'Drift Tuning Kit',
        weight = 1000,
    },

    ['veh_mine'] = {
        label = 'Proximity Vehicle Mine',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Tech Den issue. Plant from a racked vehicle.',
    },

    ['ceramic_brakes'] = {
        label = 'Ceramic Brakes',
        weight = 1000,
    },

    -- Cosmetic Items
    ['lighting_controller'] = {
        label = 'Lighting Controller',
        weight = 100,
        client = {
            event = 'jg-mechanic:client:show-lighting-controller',
        }
    },

    ['stancing_kit'] = {
        label = 'Stancer Kit',
        weight = 100,
        client = {
            event = 'jg-mechanic:client:show-stancer-kit',
        }
    },

    ['cosmetic_part'] = {
        label = 'Cosmetic Parts',
        weight = 100,
    },

    ['respray_kit'] = {
        label = 'Respray Kit',
        weight = 1000,
    },

    ['vehicle_wheels'] = {
        label = 'Vehicle Wheels Set',
        weight = 1000,
    },

    ['tyre_smoke_kit'] = {
        label = 'Tyre Smoke Kit',
        weight = 1000,
    },

    ['bulletproof_tyres'] = {
        label = 'Bulletproof Tyres',
        weight = 1000,
    },

    ['extras_kit'] = {
        label = 'Extras Kit',
        weight = 1000,
    },

    -- Nitrous & Cleaning Items
    ['nitrous_bottle'] = {
        label = 'Nitrous Bottle',
        weight = 1000,
        client = {
            event = 'jg-mechanic:client:use-nitrous-bottle',
        }
    },

    ['empty_nitrous_bottle'] = {
        label = 'Empty Nitrous Bottle',
        weight = 1000,
    },

    ['nitrous_install_kit'] = {
        label = 'Nitrous Install Kit',
        weight = 1000,
    },

    ['cleaning_kit'] = {
        label = 'Cleaning Kit',
        weight = 1000,
        client = {
            event = 'jg-mechanic:client:clean-vehicle',
        }
    },

    ['repair_kit'] = {
        label = 'Repair Kit',
        weight = 1000,
        client = {
            event = 'jg-mechanic:client:repair-vehicle',
        }
    },

    ['duct_tape'] = {
        label = 'Duct Tape',
        weight = 1000,
        client = {
            event = 'jg-mechanic:client:use-duct-tape',
        }
    },

    -- Performance Item
    ['performance_part'] = {
        label = 'Performance Parts',
        weight = 1000,
    },

    -- Mechanic Tablet Item
    ['mechanic_tablet'] = {
        label = 'Mechanic Tablet',
        weight = 1000,
        client = {
            event = 'jg-mechanic:client:use-tablet',
        }
    },

    ['garbage_tablet'] = {
        label = 'Garbage Tablet',
        weight = 500,
        stack = false,
        close = true,
        description = 'Job tablet for the garbage route. Use it to open the garbage menu.',
        client = {
            image = 'tablet.png',
        },
    },

    -- Gearbox
    ['manual_gearbox'] = {
        label = 'Manual Gearbox',
        weight = 1000,
    },
    -- Snacks
    ['bluecrush'] = {
        label = 'Blue Rush',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['bluegatorade'] = {
        label = 'Blue Charge',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['cherrycoke'] = {
        label = 'Cherry Cola',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['cola'] = {
        label = 'Cola',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['dietdew'] = {
        label = 'Diet Blast',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['grapekoolaid'] = {
        label = 'Grape Aid',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['jarrito_grapefruit'] = {
        label = 'Jarrita Grapefruit',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['jarrito_lime'] = {
        label = 'Jarrita Lime',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['jarrito_mandarin'] = {
        label = 'Jarrita Mandarin',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['jarrito_strawberry'] = {
        label = 'Jarrita Strawberry',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['jarritos_mango'] = {
        label = 'Jarrita Mango',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['mmbluer'] = {
        label = 'MunchMix Blue Razz',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['mmkiwis'] = {
        label = 'MunchMix Kiwi Chews',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['mmwatermelon'] = {
        label = 'MunchMix Watermelon',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['orangegatorade'] = {
        label = 'Orange Charge',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_blueraspberry'] = {
        label = 'Primo Blue Raspberry',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_grape'] = {
        label = 'Primo Grape',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_icepop'] = {
        label = 'Primo Ice Pop',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_lemonlime'] = {
        label = 'Primo Lemon Lime',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_metamoon'] = {
        label = 'Primo MetaMoon',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_orange'] = {
        label = 'Primo Orange',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['prime_tropicalpunch'] = {
        label = 'Primo Tropical Punch',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['redbull'] = {
        label = 'Red Ox',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['redbullsf'] = {
        label = 'Red Ox Zero',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['redgatorade'] = {
        label = 'Red Charge',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['rootbeer'] = {
        label = 'Root Beer',
        weight = 200,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    -- Snacks & Candy
    ['chilicheesecheetos'] = {
        label = 'Chili Cheese Puffs',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['cjcheetos'] = {
        label = 'CJ Crunchers',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['coolranch'] = {
        label = 'Cool Ranch Triangles',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['doritos'] = {
        label = 'Nacho Triangles',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['dots'] = {
        label = 'Dots',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fhbobcheetos'] = {
        label = 'Spicy Skeleton Puffs',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fhccheetos'] = {
        label = 'Spicy Crunch Cheetos',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fhcheetos'] = {
        label = 'Spicy Lime Cheetos',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fhfcheetos'] = {
        label = 'Spicy Stix',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fritos'] = {
        label = 'Corn Ritos',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['fritos_twist'] = {
        label = 'Corn Twistys',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['gobstopper'] = {
        label = 'Gob Stoppa',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['hersheys'] = {
        label = 'Hershays',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['hottamales'] = {
        label = 'Spicy Tamales',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['lays'] = {
        label = 'Wave Potato Chips',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['lays_bbq'] = {
        label = 'Wave BBQ Chips',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['lays_sc'] = {
        label = 'Wave Sour Cream Chips',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['milkduds'] = {
        label = 'Choco Duds',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['nerdsgummy'] = {
        label = 'Geek Gummies',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['pringles'] = {
        label = 'Pringles',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['sun_cheddar'] = {
        label = 'Solar Chips Cheddar',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['sunchip'] = {
        label = 'Solar Chips',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['sweedishfish'] = {
        label = 'Nordic Fish',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['sweettarts'] = {
        label = 'Tangy Tarts',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['takis'] = {
        label = 'Takiz',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['trolli'] = {
        label = 'Trollies',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    ['whoppers'] = {
        label = 'Poppers',
        weight = 20,
        stack = true,
        close = true,
        description = nil,
        consume = 1,
        allowArmed = true,
        client = {
            export = 'devkit_snacks.use',
        },
    },

    --BluePrint stuff

    ['blank_blueprint'] = {
        label = 'Blank Blueprint',
        weight = 1,
        stack = true,
        close = true,
        description = 'A blank blueprint.. I wonder what it\'s for..',
        client = {
            image = 'blank_blueprint.png',
        },
    },

    -- General

    ['usb_blue'] = {
        label = 'usb blue',
        weight = 90,
        stack = false,
        close = true,
        description = 'usb blue'
    },

    ['usb_green'] = {
        label = 'usb green',
        weight = 90,
        stack = false,
        close = true,
        description = 'usb green'
    },

    ['usb_purple'] = {
        label = 'usb purple',
        weight = 90,
        stack = false,
        close = true,
        description = 'usb purple'
    },

    ['usb_grey'] = {
        label = 'usb grey',
        weight = 90,
        stack = false,
        close = true,
        description = 'usb grey'
    },

    ['vr_keycard'] = {
        label = 'vr keycard',
        weight = 30,
        stack = false,
        close = true,
        description = 'vr keycard'
    },

    ['vr_keycard_blue'] = {
        label = 'vr keycard blue',
        weight = 30,
        stack = false,
        close = true,
        description = 'vr keycard blue'
    },

    ['vr_keycard_green'] = {
        label = 'vr keycard green',
        weight = 30,
        stack = false,
        close = true,
        description = 'vr keycard green'
    },

    ['vr_keycard_pink'] = {
        label = 'vr keycard pink',
        weight = 30,
        stack = false,
        close = true,
        description = 'vr keycard pink'
    },

    ['vr_keycard_yellow'] = {
        label = 'vr keycard yellow',
        weight = 30,
        stack = false,
        close = true,
        description = 'vr keycard yellow'
    },

    ['diamond'] = {
        label = 'Diamond',
        weight = 50,
        stack = true,
        close = false,
        description = 'A brilliant cut diamond. Extremely valuable and used in legendary crafting.',
        client = {
            image = 'diamond.png',
        },
    },

    ['emerald'] = {
        label = 'Emerald',
        weight = 50,
        stack = true,
        close = false,
        description = 'A brilliant green emerald with magical properties.',
        client = {
            image = 'emerald.png',
        },
    },

    ['sapphire'] = {
        label = 'Sapphire',
        weight = 50,
        stack = true,
        close = false,
        description = 'A royal blue sapphire. Used in advanced crafting.',
        client = {
            image = 'sapphire.png',
        },
    },

    ['ruby'] = {
        label = 'Ruby',
        weight = 50,
        stack = true,
        close = false,
        description = 'A deep red ruby with a fiery glow. Used in advanced crafting.',
        client = {
            image = 'ruby.png',
        },
    },

    ['uncut_diamond'] = {
        label = 'uncut diamond',
        weight = 1,
        stack = true,
        close = true,
        description = 'uncut diamond'
    },

    ['uncut_emerald'] = {
        label = 'uncut emerald',
        weight = 1,
        stack = true,
        close = true,
        description = 'uncut emerald'
    },

    ['goldore'] = {
        label = 'goldore',
        weight = 1,
        stack = true,
        close = true,
        description = 'goldore'
    },

    ['copperore'] = {
        label = 'copperore',
        weight = 1,
        stack = true,
        close = true,
        description = 'copperore'
    },

    ['carbon'] = {
        label = 'carbon',
        weight = 1,
        stack = true,
        close = true,
        description = 'carbon'
    },

    ['ironore'] = {
        label = 'ironore',
        weight = 1,
        stack = true,
        close = true,
        description = 'ironore'
    },

    ['silverore'] = {
        label = 'silverore',
        weight = 1,
        stack = true,
        close = true,
        description = 'silverore'
    },

    ['uncut_sapphire'] = {
        label = 'uncut sapphire',
        weight = 1,
        stack = true,
        close = true,
        description = 'uncut sapphire'
    },

    ['uncut_ruby'] = {
        label = 'uncut ruby',
        weight = 1,
        stack = true,
        close = true,
        description = 'uncut ruby'
    },


    ['wood'] = {
        label = 'Wood',
        weight = 200,
        stack = true,
        close = true,
        description = 'Cut lumber from forestry work. Sell it at the Job Center buyer.',
    },
    ['stone'] = {
        label = 'stone',
        weight = 1,
        stack = true,
        close = true,
        description = 'stone'
    },

    ['silveringot'] = {
        label = 'silveringot',
        weight = 1,
        stack = true,
        close = true,
        description = 'silveringot'
    },

    ['case_1'] = {
        label = 'case 1',
        weight = 1,
        stack = true,
        close = true,
        description = 'case 1'
    },

    ['case_5'] = {
        label = 'case 5',
        weight = 1,
        stack = true,
        close = true,
        description = 'case 5'
    },

    ['case_7'] = {
        label = 'case 7',
        weight = 1,
        stack = true,
        close = true,
        description = 'case 7'
    },

    ['case_3'] = {
        label = 'case 3',
        weight = 1,
        stack = true,
        close = true,
        description = 'case 3'
    },

    ['key'] = {
        label = 'key',
        weight = 1,
        stack = true,
        close = true,
        description = 'Hmm, this could be useful..'
    },

    ['key_diamond'] = {
        label = 'key-diamond',
        weight = 1,
        stack = true,
        close = true,
        description = 'key-diamond'
    },

    ['key_bankboxkey'] = {
        label = 'key-bankboxkey',
        weight = 1,
        stack = true,
        close = true,
        description = 'key-bankboxkey'
    },

    ['carkeys'] = {
        label = 'Car Key',
        weight = 50,
        stack = false,
        close = true,
        description = 'A set of keys for a vehicle.',
        client = {
            image = 'vehicle_keyfob.png',
        }
    },

    ['keyfob'] = {
        label = 'Vehicle Keyfob',
        weight = 50,
        stack = false,
        close = true,
        description = 'A smart keyfob that stores access to multiple vehicles.',
        client = {
            image = 'vehicle_keyfob.png',
        }
    },

    ['skateboard'] = {
        label = 'Skateboard',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A skateboard you can ride.',
        client = {
            image = 'skateboard.png',
            event = 'bdx-skate:usedFromOxInventory',
        },
    },

    -- ==========================================
    -- BLUEPRINT ITEMS
    -- Use these to learn special crafting recipes
    -- ==========================================

    ['blueprint_lockpick'] = {
        label = 'Lockpick Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft standard lockpicks. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_bandage'] = {
        label = 'Bandage Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft basic bandages. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_radio'] = {
        label = 'Radio Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft radios. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_repairkit'] = {
        label = 'Repair Kit Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft repair kits. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_flashlight'] = {
        label = 'Flashlight Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft flashlights. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_binoculars'] = {
        label = 'Binoculars Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft binoculars. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_armor'] = {
        label = 'Armor Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft basic armor. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_reinforced_handle'] = {
        label = 'Reinforced Handle Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft reinforced tool handles. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_fishing_line'] = {
        label = 'Fishing Line Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft durable fishing lines. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_tool_parts'] = {
        label = 'Tool Parts Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft essential tool components. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_gold_band'] = {
        label = 'Gold Band Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft decorative gold bands. Requires Crafting Level 1.',
        client = {
            image = 'blueprint_basic.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_advanced_lockpick'] = {
        label = 'Advanced Lockpick Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft superior lockpicks. Requires Crafting Level 5.',
        client = {
            image = 'blueprint_advanced.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_advanced_radio'] = {
        label = 'Advanced Radio Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft long-range radios. Requires Crafting Level 8.',
        client = {
            image = 'blueprint_advanced.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_advanced_armor'] = {
        label = 'Advanced Armor Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft reinforced body armor. Requires Crafting Level 10.',
        client = {
            image = 'blueprint_advanced.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_master_lockpick'] = {
        label = 'Master Lockpick Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft unbreakable lockpicks. Requires Crafting Level 15.',
        client = {
            image = 'blueprint_master.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_master_medkit'] = {
        label = 'Master Medkit Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft military-grade medkits. Requires Crafting Level 18.',
        client = {
            image = 'blueprint_master.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_master_weapon_parts'] = {
        label = 'Master Weapon Parts Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft precision weapon components. Requires Crafting Level 20.',
        client = {
            image = 'blueprint_master.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    -- Khan futuristic weapon blueprints
    ['blueprint_WEAPON_ascia'] = {
        label = 'Ascia Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to forge the Ascia combat axe. Requires Crafting Level 15.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_motosega'] = {
        label = 'Chainsaw Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to assemble a motorized saw. Requires Crafting Level 18.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_skippy'] = {
        label = 'Skippy Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rare smart-pistol schematic. Requires Crafting Level 20.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_SARATOGA'] = {
        label = 'Saratoga Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft the Saratoga SMG. Requires Crafting Level 18.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_carnage'] = {
        label = 'Carnage Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft the Carnage shotgun. Requires Crafting Level 19.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_silverhand'] = {
        label = 'Malorian Arms Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Legendary Malorian Arms 3516 schematic. Requires Crafting Level 22.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_MASAMUNE'] = {
        label = 'Masamune Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Top-tier rifle schematic. Requires Crafting Level 23.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['blueprint_WEAPON_NEKOMATA'] = {
        label = 'Nekomata Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Extremely rare dual-barrel sniper schematic. Requires Crafting Level 26.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_legendary_toolkit'] = {
        label = 'Legendary Toolkit Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft the ultimate multi-tool. Requires Crafting Level 25.',
        client = {
            image = 'blueprint_legendary.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_legendary_armor'] = {
        label = 'Legendary Armor Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft experimental body armor. Requires Crafting Level 28.',
        client = {
            image = 'blueprint_legendary.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    -- Crafted items from blueprints
    ['advanced_lockpick'] = {
        label = 'Advanced Lockpick',
        weight = 150,
        stack = true,
        close = true,
        description = 'A superior lockpick with enhanced durability.',
        client = {
            image = 'advanced_lockpick.png',
        },
    },

    ['advanced_radio'] = {
        label = 'Advanced Radio',
        weight = 500,
        stack = true,
        close = true,
        description = 'Long-range communication device.',
        client = {
            image = 'advanced_radio.png',
        },
    },

    ['advanced_armor'] = {
        label = 'Advanced Armor',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Reinforced body armor providing enhanced protection.',
        client = {
            image = 'advanced_armor.png',
        },
    },

    ['master_lockpick'] = {
        label = 'Master Lockpick',
        weight = 200,
        stack = true,
        close = true,
        description = 'An unbreakable lockpick crafted with precision.',
        client = {
            image = 'master_lockpick.png',
        },
    },

    ['master_medkit'] = {
        label = 'Master Medkit',
        weight = 500,
        stack = true,
        close = true,
        description = 'Military-grade medical kit for serious injuries.',
        client = {
            image = 'master_medkit.png',
        },
    },

    ['master_weapon_parts'] = {
        label = 'Master Weapon Parts',
        weight = 300,
        stack = true,
        close = true,
        description = 'Precision-crafted weapon components.',
        client = {
            image = 'master_weapon_parts.png',
        },
    },

    ['legendary_toolkit'] = {
        label = 'Legendary Toolkit',
        weight = 500,
        stack = false,
        close = true,
        description = 'The ultimate multi-tool for any situation.',
        client = {
            image = 'legendary_toolkit.png',
        },
    },

    ['legendary_armor'] = {
        label = 'Legendary Armor',
        weight = 2500,
        stack = false,
        close = true,
        description = 'Experimental body armor with maximum protection.',
        client = {
            image = 'legendary_armor.png',
        },
    },

    -- ==========================================
    -- CRAFTING MATERIALS - Fantasy & Rare
    -- ==========================================

    ['amethyst'] = {
        label = 'Amethyst',
        weight = 50,
        stack = true,
        close = false,
        description = 'A mystical purple amethyst crystal.',
        client = {
            image = 'amethyst.png',
        },
    },

    ['onyx'] = {
        label = 'Onyx',
        weight = 50,
        stack = true,
        close = false,
        description = 'A dark onyx stone with a mysterious purple sheen.',
        client = {
            image = 'onyx_stone.png',
        },
    },

    ['rune_core'] = {
        label = 'Rune Core',
        weight = 100,
        stack = true,
        close = false,
        description = 'A mystical crystal orb pulsing with ancient rune energy. Essential for legendary crafting.',
        client = {
            image = 'rune_core.png',
        },
    },

    ['mithril_ore'] = {
        label = 'Mithril Ore',
        weight = 200,
        stack = true,
        close = false,
        description = 'Rare silvery-blue ore. Lightweight yet incredibly strong.',
        client = {
            image = 'mithril_ore.png',
        },
    },

    ['arcane_dust'] = {
        label = 'Arcane Dust',
        weight = 10,
        stack = true,
        close = false,
        description = 'Glowing magical dust particles. Used to enchant items.',
        client = {
            image = 'arcane_dust.png',
        },
    },

    ['dark_glass'] = {
        label = 'Dark Glass',
        weight = 75,
        stack = true,
        close = false,
        description = 'Obsidian-like volcanic glass. Sharp and dangerous.',
        client = {
            image = 'dark_glass.png',
        },
    },

    ['carbon_fiber'] = {
        label = 'Carbon Fiber',
        weight = 50,
        stack = true,
        close = false,
        description = 'High-tech woven carbon fiber material. Lightweight and strong.',
        client = {
            image = 'carbon_fiber.png',
        },
    },

    ['titanium_alloy'] = {
        label = 'Titanium Alloy',
        weight = 150,
        stack = true,
        close = false,
        description = 'Aerospace-grade titanium alloy ingot. Premium quality.',
        client = {
            image = 'titanium_alloy.png',
        },
    },

    ['advanced_circuit'] = {
        label = 'Advanced Circuit',
        weight = 50,
        stack = true,
        close = false,
        description = 'A complex electronic circuit board used in high-tech devices.',
        client = {
            image = 'advanced_circuit.png',
        },
    },

    ['blueprint_hacking_device'] = {
        label = 'Hacking Device Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematics for an electronic hacking tool. Requires Crafting Level 22.',
        client = {
            image = 'blueprint_expert.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['hacking_device'] = {
        label = 'Hacking Device',
        weight = 500,
        stack = false,
        close = true,
        description = 'A sophisticated tool for bypassing electronic security.',
        client = {
            image = 'hacking_device.png',
        },
    },

    ['blueprint_revive_crystal'] = {
        label = 'Revive Crystal Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Ancient scroll describing how to fuse a Revive Crystal. Requires Crafting Level 30.',
        client = {
            image = 'blueprint_legendary.png',
            usetime = 2000,
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['revive_crystal'] = {
        label = 'Revive Crystal',
        weight = 200,
        stack = true,
        close = true,
        description = 'A glowing crystal pulsing with life energy. Rumored to bring people back from the brink.',
        client = {
            image = 'revive_crystal.png',
        },
    },

    -- ==========================================
    -- CRAFTABLE EQUIPMENT (Referenced by Recipes)
    -- ==========================================

    ['armor'] = {
        label = 'Body Armor',
        weight = 3000,
        stack = false,
        close = true,
        description = 'Standard body armor providing basic ballistic protection.',
        client = {
            image = 'armor.png',
        },
    },

    ['nightvision'] = {
        label = 'Night Vision Goggles',
        weight = 500,
        stack = false,
        close = true,
        description = 'Military-grade night vision goggles. See clearly in the dark.',
        client = {
            image = 'nightvision.png',
        },
    },

    ['c4'] = {
        label = 'C4 Explosive',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Military-grade plastic explosive. Handle with extreme care.',
        client = {
            image = 'c4.png',
        },
    },

    ['emp_grenade'] = {
        label = 'EMP Grenade',
        weight = 300,
        stack = true,
        close = true,
        description = 'Electromagnetic pulse device. Disables electronics in a small radius.',
        client = {
            image = 'emp_grenade.png',
        },
    },

    ['legendary_hacking_suite'] = {
        label = 'Legendary Hacking Suite',
        weight = 200,
        stack = false,
        close = true,
        description = 'A state-of-the-art hacking toolkit. Bypass almost any security system.',
        client = {
            image = 'hacking_device.png',
        },
    },

    ['legendary_emp'] = {
        label = 'Legendary EMP Device',
        weight = 500,
        stack = false,
        close = true,
        description = 'An advanced EMP device with extended range and duration.',
        client = {
            image = 'emp_grenade.png',
        },
    },

    -- ==========================================
    -- CRAFTING MATERIALS (Ingredients)
    -- ==========================================

    ['dark_glass'] = {
        label = 'Dark Glass',
        weight = 50,
        stack = true,
        close = false,
        description = 'Tinted glass used in optical equipment.',
        client = { image = 'dark_glass.png' },
    },

    ['cloth'] = {
        label = 'Cloth',
        weight = 20,
        stack = true,
        close = false,
        description = 'Basic fabric material for crafting.',
        client = { image = 'supplies_textile.png' },
    },

    ['leather'] = {
        label = 'Leather',
        weight = 80,
        stack = true,
        close = false,
        description = 'Durable animal hide for crafting.',
        client = { image = 'leather.png' },
    },

    ['electronics'] = {
        label = 'Electronics',
        weight = 30,
        stack = true,
        close = false,
        description = 'Salvaged electronic components.',
        client = { image = 'electronics.png' },
    },

    ['plastic'] = {
        label = 'Plastic',
        weight = 15,
        stack = true,
        close = false,
        description = 'Moldable plastic material.',
        client = { image = 'plastic.png' },
    },

    ['rubber'] = {
        label = 'Rubber',
        weight = 25,
        stack = true,
        close = false,
        description = 'Flexible rubber material.',
        client = { image = 'rubber.png' },
    },

    -- ==========================================
    -- ADVANCED TIER CRAFTABLES
    -- ==========================================

    ['advanced_lockpick'] = {
        label = 'Advanced Lockpick',
        weight = 100,
        stack = true,
        close = true,
        description = 'A high-quality lockpick with enhanced durability.',
        client = { image = 'advanced_lockpick.png' },
    },

    ['advanced_radio'] = {
        label = 'Advanced Radio',
        weight = 300,
        stack = false,
        close = true,
        description = 'Long-range communication device with encryption.',
        client = { image = 'advanced_radio.png' },
    },

    ['advanced_armor'] = {
        label = 'Advanced Armor',
        weight = 4000,
        stack = false,
        close = true,
        description = 'Enhanced body armor with superior protection.',
        client = { image = 'advanced_armor.png' },
    },

    ['advancedrepairkit'] = {
        label = 'Advanced Repair Kit',
        weight = 500,
        stack = true,
        close = true,
        description = 'Professional-grade vehicle repair kit.',
        client = { image = 'advancedrepairkit.png' },
    },

    ['thermite'] = {
        label = 'Thermite',
        weight = 200,
        stack = true,
        close = true,
        description = 'High-temperature incendiary compound.',
        client = { image = 'thermite.png' },
    },

    ['cobalt_lockpick'] = {
        label = 'Cobalt Lockpick',
        weight = 80,
        stack = true,
        close = true,
        description = 'A lightweight lockpick made from cobalt alloy.',
        client = { image = 'cobalt_lockpick.png' },
    },

    ['shadow_parachute'] = {
        label = 'Shadow Parachute',
        weight = 1500,
        stack = false,
        close = true,
        description = 'A stealth parachute made from light-absorbing fabric.',
        client = { image = 'shadow_parachute.png' },
    },

    -- ==========================================
    -- MASTER TIER CRAFTABLES
    -- ==========================================

    ['master_lockpick'] = {
        label = 'Master Lockpick',
        weight = 80,
        stack = true,
        close = true,
        description = 'The finest lockpick money can buy. Extremely durable.',
        client = { image = 'master_lockpick.png' },
    },

    ['master_medkit'] = {
        label = 'Master Medkit',
        weight = 800,
        stack = true,
        close = true,
        description = 'Military-grade medical kit for critical injuries.',
        client = { image = 'master_medkit.png' },
    },

    ['master_weapon_parts'] = {
        label = 'Master Weapon Parts',
        weight = 400,
        stack = true,
        close = true,
        description = 'High-quality weapon components for upgrades.',
        client = { image = 'master_weapon_parts.png' },
    },

    ['hacking_device'] = {
        label = 'Hacking Device',
        weight = 150,
        stack = false,
        close = true,
        description = 'Electronic device for bypassing security systems.',
        client = { image = 'hacking_device.png' },
    },

    ['adamantite_armor'] = {
        label = 'Adamantite Armor',
        weight = 5000,
        stack = false,
        close = true,
        description = 'Extremely heavy armor made from adamantite alloy. Maximum protection.',
        client = { image = 'adamantite_armor.png' },
    },

    -- ==========================================
    -- LEGENDARY TIER CRAFTABLES
    -- ==========================================

    ['legendary_toolkit'] = {
        label = 'Legendary Toolkit',
        weight = 600,
        stack = false,
        close = true,
        description = 'The ultimate crafting toolkit. Improves all crafting results.',
        client = { image = 'legendary_toolkit.png' },
    },

    ['legendary_armor'] = {
        label = 'Legendary Armor',
        weight = 6000,
        stack = false,
        close = true,
        description = 'Mythical armor infused with arcane energy. Unmatched protection.',
        client = { image = 'legendary_armor.png' },
    },

    ['runite_blade'] = {
        label = 'Runite Blade',
        weight = 1200,
        stack = false,
        close = true,
        description = 'A razor-sharp blade forged from runite ore. Glows with power.',
        client = { image = 'runite_blade.png' },
    },

    -- ==========================================
    -- MODERN RPG PACK: MATERIALS
    -- ==========================================


    ['cobalt_ore'] = {
        label = 'Cobalt Ore',
        weight = 150,
        stack = true,
        close = false,
        description = 'A durable blue metal, lighter than steel. Used for advanced tools.',
        client = {
            image = 'cobalt_ore.png',
        },
    },

    ['adamantite_ore'] = {
        label = 'Adamantite Ore',
        weight = 250,
        stack = true,
        close = false,
        description = 'An incredibly hard, green-tinted metal alloy. Used for heavy armor.',
        client = {
            image = 'adamantite_ore.png', -- Fallback to emerald appearance or custom
        },
    },

    ['runite_ore'] = {
        label = 'Runite Ore',
        weight = 300,
        stack = true,
        close = false,
        description = 'A faint blue ore that pulses with energy. The strongest known metal.',
        client = {
            image = 'runite_ore.png',
        },
    },

    ['shadow_silk'] = {
        label = 'Shadow Silk',
        weight = 20,
        stack = true,
        close = false,
        description = 'Synthetic fabric that seems to absorb light. Ideal for stealth gear.',
        client = {
            image = 'shadow_silk.png',
        },
    },

    ['infernal_dust'] = {
        label = 'Infernal Dust',
        weight = 10,
        stack = true,
        close = false,
        description = 'Unstable gunpowder residue that burns with a green hue. Extremely volatile.',
        client = {
            image = 'infernal_dust.png',
        },
    },

    -- ==========================================
    -- MODERN RPG PACK: CRAFTABLES & BLUEPRINTS
    -- ==========================================

    -- Cobalt Lockpick (Advanced)
    ['blueprint_cobalt_lockpick'] = {
        label = 'Cobalt Lockpick Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematics for a durable cobalt lockpick. Requires Crafting Level 12.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['cobalt_lockpick'] = {
        label = 'Cobalt Lockpick',
        weight = 100,
        stack = true,
        close = true,
        description = 'A lightweight, durable lockpick made from cobalt alloy.',
        client = { image = 'cobalt_lockpick.png' },
    },

    -- Adamantite Armor (Master)
    ['blueprint_adamantite_armor'] = {
        label = 'Adamantite Armor Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematics for heavy adamantite plating. Requires Crafting Level 20.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['adamantite_armor'] = {
        label = 'Adamantite Armor',
        weight = 4000,
        stack = false,
        close = true,
        description = 'Heavy duty body armor reinforced with adamantite plating. Exceptional protection.',
        client = { image = 'adamantite_armor.png' },
    },

    -- Runite Blade (Legendary)
    ['blueprint_runite_blade'] = {
        label = 'Runite Blade Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Plans for a razor-sharp runite combat blade. Requires Crafting Level 28.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['runite_blade'] = {
        label = 'Runite Blade',
        weight = 1200,
        stack = false,
        close = true,
        description = 'A custom machete forged from runite. Incredibly sharp and durable.',
        client = { image = 'runite_blade.png' },
    },

    -- Shadow Parachute (Basic/Advanced)
    ['blueprint_shadow_parachute'] = {
        label = 'Shadow Parachute Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Design for a stealth parachute. Requires Crafting Level 8.',
        client = { image = 'blueprint_basic.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['shadow_parachute'] = {
        label = 'Shadow Parachute',
        weight = 1500,
        stack = false,
        close = true,
        description = 'A stealth parachute woven from shadow silk. Hard to spot in the sky.',
        client = { image = 'shadow_parachute.png' },
    },

    -- Infernal Charge (Master)
    ['blueprint_infernal_charge'] = {
        label = 'Infernal Charge Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Formula for a high-yield explosive. Requires Crafting Level 22.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },
    ['infernal_charge'] = {
        label = 'Infernal Charge',
        weight = 600,
        stack = true,
        close = true,
        description = 'A volatile explosive device powered by infernal dust.',
        client = { image = 'infernal_charge.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: NEW MATERIALS
    -- ==========================================

    ['refined_mithril'] = {
        label = 'Refined Mithril',
        weight = 200,
        stack = true,
        close = false,
        description = 'Purified mithril ingot. Lighter and stronger than raw ore.',
        client = { image = 'refined_mithril.png' },
    },

    ['arcane_crystal'] = {
        label = 'Arcane Crystal',
        weight = 100,
        stack = true,
        close = false,
        description = 'Crystallized magical energy pulsing with power.',
        client = { image = 'arcane_crystal.png' },
    },

    ['cobalt_alloy'] = {
        label = 'Cobalt Alloy',
        weight = 180,
        stack = true,
        close = false,
        description = 'Reinforced cobalt-titanium alloy. Extremely lightweight.',
        client = { image = 'cobalt_alloy.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: BASIC TIER CRAFTABLES
    -- ==========================================

    ['molotov'] = {
        label = 'Molotov Cocktail',
        weight = 400,
        stack = true,
        close = true,
        description = 'An improvised incendiary weapon. Highly flammable.',
        client = { image = 'molotov.png' },
    },

    ['shiv'] = {
        label = 'Shiv',
        weight = 150,
        stack = true,
        close = true,
        description = 'A concealed blade. Favored in close quarters.',
        client = { image = 'shiv.png' },
    },

    ['rope'] = {
        label = 'Rope',
        weight = 300,
        stack = true,
        close = false,
        description = 'Sturdy rope useful for many applications.',
        client = { image = 'rope.png' },
    },

    ['flare'] = {
        label = 'Flare',
        weight = 100,
        stack = true,
        close = true,
        description = 'Emergency signal flare. Burns bright red.',
        client = { image = 'flare.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: ADVANCED TIER CRAFTABLES
    -- ==========================================

    ['silencer'] = {
        label = 'Silencer',
        weight = 300,
        stack = false,
        close = true,
        description = 'Weapon suppressor. Reduces gunfire noise significantly.',
        client = { image = 'silencer.png' },
    },

    ['extended_mag'] = {
        label = 'Extended Magazine',
        weight = 200,
        stack = true,
        close = true,
        description = 'Increases ammunition capacity.',
        client = { image = 'extended_mag.png' },
    },

    ['drill'] = {
        label = 'Drill',
        weight = 800,
        stack = false,
        close = true,
        description = 'Heavy-duty power drill. Essential for safe cracking.',
        client = { image = 'drill.png' },
    },

    ['gps_tracker'] = {
        label = 'GPS Tracker',
        weight = 50,
        stack = true,
        close = true,
        description = 'Covert tracking device. Attach to any vehicle.',
        client = { image = 'gps_tracker.png' },
    },

    ['radio_jammer'] = {
        label = 'Radio Jammer',
        weight = 400,
        stack = false,
        close = true,
        description = 'Blocks radio communications in a small area.',
        client = { image = 'radio_jammer.png' },
    },

    ['medic_bag'] = {
        label = 'Medic Bag',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Advanced medical kit. Can revive downed players.',
        client = { image = 'medic_bag.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: MASTER TIER CRAFTABLES
    -- ==========================================

    ['thermal_scope'] = {
        label = 'Thermal Scope',
        weight = 400,
        stack = false,
        close = true,
        description = 'Military-grade thermal imaging scope. Sees heat signatures.',
        client = { image = 'thermal_scope.png' },
    },

    ['explosive_charge'] = {
        label = 'Explosive Charge',
        weight = 1200,
        stack = true,
        close = true,
        description = 'Military-grade breaching explosive.',
        client = { image = 'explosive_charge.png' },
    },

    ['stim_shot'] = {
        label = 'Stim Shot',
        weight = 100,
        stack = true,
        close = true,
        description = 'Combat stimulant. Temporary speed and stamina boost.',
        client = { image = 'stim_shot.png' },
    },

    ['keycard_cloner'] = {
        label = 'Keycard Cloner',
        weight = 200,
        stack = false,
        close = true,
        description = 'Device for duplicating access keycards.',
        client = { image = 'keycard_cloner.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: LEGENDARY TIER CRAFTABLES
    -- ==========================================
    ['plasma_cutter'] = {
        label = 'Plasma Cutter',
        weight = 1500,
        stack = false,
        close = true,
        description = 'High-tech cutting tool. Slices through any material.',
        client = { image = 'plasma_cutter.png' },
    },

    ['shadow_cloak'] = {
        label = 'Shadow Cloak',
        weight = 500,
        stack = false,
        close = true,
        description = 'Mystical garment that bends light. Temporary invisibility.',
        client = { image = 'shadow_cloak.png', export = 'ox_inventory.UseShadowCloak' },
    },

    ['revive_syringe'] = {
        label = 'Revive Syringe',
        weight = 100,
        stack = true,
        close = true,
        description = 'Arcane medical solution. Instantly revives anyone.',
        client = { image = 'revive_syringe.png', export = 'ox_inventory.UseReviveSyringe' },
    },

    ['quantum_lockpick'] = {
        label = 'Quantum Lockpick',
        weight = 50,
        stack = false,
        close = true,
        description = 'Legendary tool that opens any lock. Never breaks.',
        client = { image = 'quantum_lockpick.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: BLUEPRINTS
    -- ==========================================

    ['blueprint_silencer'] = {
        label = 'Silencer Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rare schematic for a weapon suppressor. Requires Level 25.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_extended_mag'] = {
        label = 'Extended Mag Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rare schematic for extended magazines. Requires Level 25.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_drill'] = {
        label = 'Drill Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for a safe-cracking drill. Requires Level 8.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_gps_tracker'] = {
        label = 'GPS Tracker Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for a covert tracking device. Requires Level 6.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_radio_jammer'] = {
        label = 'Radio Jammer Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for a communications jammer. Requires Level 10.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_medic_bag'] = {
        label = 'Medic Bag Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for an advanced medical kit. Requires Level 8.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_thermal_scope'] = {
        label = 'Thermal Scope Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for thermal imaging optics. Requires Level 15.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_explosive_charge'] = {
        label = 'Explosive Charge Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for military breaching charges. Requires Level 18.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_stim_shot'] = {
        label = 'Stim Shot Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Formula for combat stimulants. Requires Level 15.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_keycard_cloner'] = {
        label = 'Keycard Cloner Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for a keycard duplicator. Requires Level 20.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_plasma_cutter'] = {
        label = 'Plasma Cutter Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Ancient schematic for a legendary cutting tool. Requires Level 25.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_shadow_cloak'] = {
        label = 'Shadow Cloak Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Mystical pattern for a cloak of shadows. Requires Level 28.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_revive_syringe'] = {
        label = 'Revive Syringe Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Arcane formula for resurrection serum. Requires Level 25.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_quantum_lockpick'] = {
        label = 'Quantum Lockpick Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Legendary schematic for the ultimate lockpick. Requires Level 30.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    -- ==========================================
    -- CONTENT PACK 2: INTERMEDIATE COMPONENTS
    -- ==========================================

    ['reinforced_handle'] = {
        label = 'Reinforced Handle',
        weight = 150,
        stack = true,
        close = false,
        description = 'A sturdy tool handle reinforced with cobalt and titanium.',
        client = { image = 'reinforced_handle.png' },
    },

    ['fishing_line'] = {
        label = 'Fishing Line',
        weight = 30,
        stack = true,
        close = false,
        description = 'Strong monofilament fishing line. Essential for quality rods.',
        client = { image = 'fishing_line.png' },
    },

    ['tool_parts'] = {
        label = 'Tool Parts',
        weight = 200,
        stack = true,
        close = false,
        description = 'Precision mechanical components for crafting tools.',
        client = { image = 'tool_parts.png' },
    },

    ['refined_gem'] = {
        label = 'Refined Gem',
        weight = 50,
        stack = true,
        close = false,
        description = 'A perfectly polished gem infused with arcane energy.',
        client = { image = 'onyx_gem.png' },
    },

    ['gold_band'] = {
        label = 'Gold Band',
        weight = 30,
        stack = true,
        close = false,
        description = 'A simple gold band. Base for jewelry crafting.',
        client = { image = 'gold_band.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: UPGRADED TOOLS
    -- ==========================================

    ['steel_pickaxe'] = {
        label = 'Steel Pickaxe',
        weight = 1200,
        stack = false,
        close = true,
        description = 'A reinforced pickaxe. +25% mining yield.',
        client = { image = 'steel_pickaxe.png' },
    },

    ['runic_pickaxe'] = {
        label = 'Runic Pickaxe',
        weight = 1000,
        stack = false,
        close = true,
        description = 'A legendary pickaxe etched with glowing runes. +50% yield, chance for rare gems.',
        client = { image = 'runic_pickaxe.png' },
    },

    ['quality_fishing_rod'] = {
        label = 'Quality Fishing Rod',
        weight = 600,
        stack = false,
        close = true,
        description = 'A professional-grade fishing rod. Better catch quality.',
        client = { image = 'quality_fishing_rod.png' },
    },

    ['salvage_kit'] = {
        label = 'Salvage Kit',
        weight = 800,
        stack = false,
        close = true,
        description = 'Tools for salvaging parts from vehicles and electronics.',
        client = { image = 'salvage_kit.png' },
    },

    ['master_toolset'] = {
        label = 'Master Toolset',
        weight = 1500,
        stack = false,
        close = true,
        description = 'Premium repair tools. Repairs consume fewer parts.',
        client = { image = 'master_toolset.png' },
    },

    ['skeleton_key'] = {
        label = 'Skeleton Key',
        weight = 50,
        stack = false,
        close = true,
        description = 'A legendary arcane key. Opens all standard locks without breaking.',
        client = { image = 'skeleton_key.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: SELLABLE JEWELRY
    -- ==========================================

    ['diamond_necklace'] = {
        label = 'Diamond Necklace',
        weight = 100,
        stack = true,
        close = true,
        description = 'An exquisite diamond necklace. Very valuable.',
        client = { image = 'diamond_necklace.png' },
    },

    ['ruby_ring'] = {
        label = 'Ruby Ring',
        weight = 30,
        stack = true,
        close = true,
        description = 'A beautiful gold ring with a ruby gemstone.',
        client = { image = 'ruby_ring.png' },
    },

    ['emerald_pendant'] = {
        label = 'Emerald Pendant',
        weight = 50,
        stack = true,
        close = true,
        description = 'An elegant pendant with a brilliant emerald.',
        client = { image = 'emerald_pendant.png' },
    },

    ['sapphire_bracelet'] = {
        label = 'Sapphire Bracelet',
        weight = 60,
        stack = true,
        close = true,
        description = 'A stunning bracelet adorned with sapphires.',
        client = { image = 'sapphire_bracelet.png' },
    },

    -- ==========================================
    -- CONTENT PACK 2: BLUEPRINTS
    -- ==========================================

    ['blueprint_steel_pickaxe'] = {
        label = 'Steel Pickaxe Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for a reinforced mining pickaxe. Requires Level 8.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_runic_pickaxe'] = {
        label = 'Runic Pickaxe Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Ancient schematic for a legendary pickaxe. Requires Level 25.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_quality_fishing_rod'] = {
        label = 'Quality Fishing Rod Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for professional fishing equipment. Requires Level 6.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_salvage_kit'] = {
        label = 'Salvage Kit Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for vehicle salvage tools. Requires Level 10.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_master_toolset'] = {
        label = 'Master Toolset Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for premium repair tools. Requires Level 18.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_skeleton_key'] = {
        label = 'Skeleton Key Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Legendary schematic for the ultimate lockpick. Requires Level 28.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_diamond_necklace'] = {
        label = 'Diamond Necklace Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for crafting diamond jewelry. Requires Level 15.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    ['blueprint_ruby_ring'] = {
        label = 'Ruby Ring Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Schematic for ruby jewelry. Requires Level 10.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
        server = { event = 'ox_inventory:useBlueprint' },
    },

    -- ==========================================
    -- RAMP ITEM & BLUEPRINT
    -- ==========================================
    ['ramp'] = {
        label = 'Portable Ramp',
        weight = 5000,
        stack = true,
        close = true,
        description =
        'A portable ramp that can be placed on the ground. Perfect for vehicular stunts and creative getaways!',
        client = {
            image = 'ramp.png',
            usetime = 2000,
            anim = { dict = 'anim@heists@box_carry@', clip = 'idle' },
            export = 'ox_inventory.placeRamp',
        },
    },

    ['blueprint_ramp'] = {
        label = 'Ramp Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Legendary schematic for crafting portable ramps. Requires Level 25.',
        client = {
            image = 'blueprint_ramp.png',
            usetime = 2000
        },
        server = {
            event = 'ox_inventory:useBlueprint',
        },
    },

    ['blueprint_advancedrepairkit'] = {
        label = 'Advanced Repair Kit Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft advanced vehicle repair kits. Requires Level 7.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
    },

    ['blueprint_nightvision'] = {
        label = 'Night Vision Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft night vision goggles. Requires Level 10.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
    },

    ['blueprint_thermite'] = {
        label = 'Thermite Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft thermite charges. Requires Level 12.',
        client = { image = 'blueprint_advanced.png', usetime = 2000 },
    },

    ['blueprint_c4'] = {
        label = 'C4 Explosive Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft military-grade explosives. Requires Level 16.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
    },

    ['blueprint_emp_grenade'] = {
        label = 'EMP Grenade Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Learn to craft electromagnetic pulse grenades. Requires Level 18.',
        client = { image = 'blueprint_master.png', usetime = 2000 },
    },

    ['blueprint_legendary_hacking_suite'] = {
        label = 'Legendary Hacking Suite Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Elite hacker schematics beyond compare. Requires Level 24.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
    },

    ['blueprint_legendary_emp'] = {
        label = 'Legendary EMP Blueprint',
        weight = 50,
        stack = true,
        close = true,
        description = 'Ancient design for a devastating EMP device. Requires Level 26.',
        client = { image = 'blueprint_legendary.png', usetime = 2000 },
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 100,
        stack = true,
        close = true,
        description = 'A tool used to pick locks.',
        client = {
            image = 'lockpick.png',
            usetime = 2500,
            export = 'RW-Inventory.UseLockpick'
        }
    },

    ['advancedlockpick'] = {
        label = 'Advanced Lockpick',
        weight = 100,
        stack = true,
        close = true,
        description = 'A more durable and effective lockpick.',
        client = {
            image = 'advancedlockpick.png',
            usetime = 2500,
            export = 'RW-Inventory.UseAdvancedLockpick'
        }
    },

    -- FORGED ITEMS (Blueprints)
    ['shadow_cloak'] = {
        label = 'Shadow Cloak',
        weight = 500,
        stack = false,
        description = 'A mythical cloak that renders the wearer invisible for a short duration.',
        client = {
            export = 'RW-Inventory.UseShadowCloak'
        }
    },
    ['revive_syringe'] = {
        label = 'Revive Syringe',
        weight = 100,
        description = 'A potent serum capable of instantly reviving a downed person.',
        consume = 0, -- Consumed by script manually
        client = {
            export = 'RW-Inventory.UseReviveSyringe'
        }
    },
    ['plasma_cutter'] = {
        label = 'Plasma Cutter',
        weight = 2500,
        stack = false,
        description = 'High-tech cutting tool capable of slicing through reinforced steel.',
    },
    ['emp_grenade'] = {
        label = 'EMP Grenade',
        weight = 300,
        description = 'Emits an electromagnetic pulse that disables electronics and vehicles.',
        weapon = 'WEAPON_GRENADE',
    },
    ['keycard_cloner'] = {
        label = 'Keycard Cloner',
        weight = 500,
        description = 'Device used to duplicate electronic keycards.',
    },
    ['hacking_device'] = {
        label = 'Hacking Device',
        weight = 1000,
        description = 'Portable computer optimized for bypassing security systems.',
    },
    ['thermite'] = {
        label = 'Thermite Charge',
        weight = 1000,
        description = 'Incendiary mixture used to melt through locks and hinges.',
    },
    ['drill'] = {
        label = 'Heavy Drill',
        weight = 3000,
        stack = false,
        description = 'Industrial drill suitable for cracking safe deposits.',
    },
    ['thermal_scope'] = {
        label = 'Thermal Scope',
        weight = 400,
        description = 'Weapon attachment providing thermal imaging capabilities.',
    },
    ['explosive_charge'] = {
        label = 'Breaching Charge',
        weight = 800,
        description = 'Directed explosive for blowing open heavy doors.',
    },
    ['medic_bag'] = {
        label = 'Trauma Bag',
        weight = 2000,
        description = 'Advanced medical kit containing supplies for major injuries.',
    },
    ['radio_jammer'] = {
        label = 'Signal Jammer',
        weight = 1500,
        description = 'Disrupts radio communications in the immediate vicinity.',
    },
    ['gps_tracker'] = {
        label = 'GPS Tracker',
        weight = 100,
        description = 'Small device that can be attached to vehicles to track their location.',
    },
    ['silencer'] = {
        label = 'Supressor',
        weight = 200,
        description = 'Reduces weapon noise and muzzle flash.',
        client = {
            usetime = 2000,
        }
    },
    ['extended_mag'] = {
        label = 'Extended Magazine',
        weight = 200,
        description = 'Increases ammunition capacity for compatible firearms.',
    },
    ['ruby_ring'] = {
        label = 'Ruby Ring',
        weight = 50,
        description = 'A crafted ring set with a precious ruby. Valuable.',
    },
    ['diamond_necklace'] = {
        label = 'Diamond Necklace',
        weight = 100,
        description = 'Exquisite jewelry featuring a large diamond. Highly valuable.',
    },
    ['master_toolset'] = {
        label = 'Master Toolset',
        weight = 5000,
        stack = false,
        description = 'Comprehensive set of high-quality tools for advanced repair jobs.',
    },
    ['skeleton_key'] = {
        label = 'Skeleton Key',
        weight = 100,
        description = 'The ultimate lockpicking tool. Can open almost any simple lock.',
    },
    ['quantum_lockpick'] = {
        label = 'Quantum Lockpick',
        weight = 100,
        description = 'Advanced device that computes lock phases to bypass security instantly.',
    },
    ['legendary_toolkit'] = {
        label = 'Legendary Toolkit',
        weight = 4000,
        stack = false,
        description = 'One-of-a-kind toolkit said to be able to fix anything.',
    },
    ['legendary_armor'] = {
        label = 'Reactive Armor',
        weight = 6000,
        description = 'Experimental body armor with superior ballistic protection.',
        client = {
            anim = { dict = 'clothingtie', clip = 'try_tie_neutral_a' },
            usetime = 5000,
        }
    },

    -- ============================================
    -- THEFT LOOT ITEMS (MISSING)
    -- ============================================
    ['donut'] = {
        label = 'Donut',
        weight = 10,
        stack = true,
        close = true,
        description = 'A sweet treat, likely stale.',
        client = {
            status = { hunger = 50000, thirst = -5000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            usetime = 2500,
        }
    },
    ['cigarette'] = {
        label = 'Cigarette',
        weight = 1,
        stack = true,
        close = true,
        description = 'Smokes to ease the nerves.',
        client = {
            status = { stress = -5000 },
            anim = { dict = 'amb@world_human_smoking@male@male_a@base', clip = 'base' },
            usetime = 5000,
        }
    },

    ['flashlight'] = {
        label = 'Flashlight',
        weight = 200,
        stack = false,
        close = true,
        description = 'Useful when it gets dark.',
    },

    ['trash'] = {
        label = 'Trash',
        weight = 50,
        stack = true,
        close = true,
        description = 'Literal garbage.',
    },

    ['scrapmetal'] = {
        label = 'Scrap Metal',
        weight = 100,
        stack = true,
        close = true,
        description = 'Useless pieces of metal... or are they?',
    },

    -- ============================================
    -- SAFES / PLAYER STORAGE
    -- ============================================
    ['safe_small'] = {
        label = 'Small Safe',
        weight = 5000,
        stack = false,
        close = true,
        description = 'A compact personal safe. Placeable.',
        client = {
            image = 'safe_small.png',
            export = 'ox_inventory.placePlayerSafe'
        }
    },
    ['safe_medium'] = {
        label = 'Medium Safe',
        weight = 10000,
        stack = false,
        close = true,
        description = 'A medium-sized personal safe. Placeable.',
        client = {
            image = 'safe_medium.png',
            export = 'ox_inventory.placePlayerSafe'
        }
    },
    ['safe_large'] = {
        label = 'Large Safe',
        weight = 15000,
        stack = false,
        close = true,
        description = 'A heavy-duty personal safe. Placeable.',
        client = {
            image = 'safe_large.png',
            export = 'ox_inventory.placePlayerSafe'
        }
    },
    ['sf_prop_v_43_safe_s_bk_01a'] = {
        label = 'XXL Safe',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Use this item to place your upgraded Safe !',
        client = {
            image = 'safe_xxl.png',
            export = 'ox_inventory.placePlayerSafe'
        }
    },

    -- ─── mWeed (weed job) ───
    ['indica_seed'] = { label = 'Indica Seed', weight = 100, stack = true, close = false, description = 'A cannabis seed that provides indica weed.', client = { image = 'indica_seed.png' } },
    ['sativa_seed'] = { label = 'Sativa Seed', weight = 100, stack = true, close = false, description = 'A cannabis seed that provides sativa weed.', client = { image = 'sativa_seed.png' } },
    ['indica_weed'] = { label = 'Indica Weed', weight = 100, stack = true, close = false, description = 'Harvested indica weed.', client = { image = 'indica_weed.png' } },
    ['sativa_weed'] = { label = 'Sativa Weed', weight = 100, stack = true, close = false, description = 'Harvested sativa weed.', client = { image = 'sativa_weed.png' } },
    ['quality_fertilizer'] = { label = 'Quality Fertilizer', weight = 100, stack = true, close = false, description = 'Premium fertilizer for growing weed.', client = { image = 'quality_fertilizer.png' } },
    ['spray'] = { label = 'Spray', weight = 100, stack = true, close = false, description = 'Spray used in the weed growth process.', client = { image = 'spray.png' } },
    ['grubber'] = { label = 'Grubber', weight = 100, stack = true, close = false, description = 'Tool used for digging and closing dirt when planting.', client = { image = 'grubber.png' } },
    ['raw_paper'] = { label = 'Raw Paper', weight = 10, stack = true, close = false, description = 'Rolling paper used to roll joints.', client = { image = 'raw_paper.png' } },
    ['indica_joint'] = { label = 'Indica Joint', weight = 10, stack = true, close = true, description = 'A rolled indica joint.', client = { image = 'indica_joint.png' } },
    ['sativa_joint'] = { label = 'Sativa Joint', weight = 10, stack = true, close = true, description = 'A rolled sativa joint.', client = { image = 'sativa_joint.png' } },
    ['lemon_haze_joint'] = { label = 'Lemon Haze Joint', weight = 10, stack = true, close = true, description = 'A rolled lemon haze joint.', client = { image = 'lemon_haze_joint.png' } },
    ['purple_haze_joint'] = { label = 'Purple Haze Joint', weight = 10, stack = true, close = true, description = 'A rolled purple haze joint.', client = { image = 'purple_haze_joint.png' } },
    ['grinded_indica'] = { label = 'Grinded Indica', weight = 50, stack = true, close = false, description = 'Grinded indica weed, ready to roll.', client = { image = 'grinded_indica.png' } },
    ['grinded_sativa'] = { label = 'Grinded Sativa', weight = 50, stack = true, close = false, description = 'Grinded sativa weed, ready to roll.', client = { image = 'grinded_sativa.png' } },

    -- ─── 0r-illegalpack ───
    ['illegal_tablet'] = { label = 'Illegal Tablet', weight = 1000, stack = false, close = true, description = 'Opens the illegal jobs menu.', client = { image = 'illegal_tablet.png' } },
    ['powdered_milk'] = { label = 'Powdered Milk', weight = 200, stack = true, close = false, description = 'Cutting agent for cocaine.', client = { image = 'powdered_milk.png' } },
    ['money_sheet'] = { label = 'Money Sheet', weight = 50, stack = true, close = false, description = 'A sheet used to print counterfeit money.', client = { image = 'money_sheet.png' } },
    ['anchor'] = { label = 'Anchor', weight = 2000, stack = true, close = false, description = 'A diving anchor.', client = { image = 'anchor.png' } },
    ['plant_spray'] = { label = 'Plant Spray', weight = 200, stack = true, close = false, description = 'Spray used while growing weed.', client = { image = 'plant_spray.png' } },
    ['ammonia'] = { label = 'Ammonia', weight = 200, stack = true, close = false, description = 'A chemical used to cook meth.', client = { image = 'ammonia.png' } },
    ['sacid'] = { label = 'Sulfuric Acid', weight = 200, stack = true, close = false, description = 'A chemical used to cook meth.', client = { image = 'sacid.png' } },
    ['atm_hack_device'] = { label = 'ATM Hack Device', weight = 500, stack = true, close = false, description = 'A device used to hack ATMs.', client = { image = 'atm_hack_device.png' } },
    ['blank_card'] = { label = 'Blank Credit Card', weight = 10, stack = true, close = false, description = 'A blank card, ready to be written.', client = { image = 'blank_card.png' } },
    ['fake_credit_card'] = { label = 'Credit Card', weight = 10, stack = true, close = false, description = 'A cloned credit card.', client = { image = 'fake_credit_card.png' } },
    ['moonshine_still'] = { label = 'Moonshine Still', weight = 5000, stack = true, close = false, description = 'A still used to make moonshine.', client = { image = 'moonshine_still.png' } },
    ['moonshine_pack'] = { label = 'Moonshine Pack', weight = 100, stack = true, close = false, description = 'A pack of moonshine ingredients.', client = { image = 'moonshine_pack.png' } },
    ['old_corn'] = { label = 'Old Corn', weight = 100, stack = true, close = false, description = 'Old corn used to make moonshine.', client = { image = 'old_corn.png' } },
    ['old_fruit'] = { label = 'Old Fruit', weight = 100, stack = true, close = false, description = 'Old fruit used to make moonshine.', client = { image = 'old_fruit.png' } },
    ['tap_water'] = { label = 'Tap Water', weight = 100, stack = true, close = false, description = 'Water used to make moonshine.', client = { image = 'tap_water.png' } },
    ['crushed_ingredients'] = { label = 'Crushed Ingredients', weight = 100, stack = true, close = false, description = 'Crushed moonshine ingredients.', client = { image = 'crushed_ingredients.png' } },
    ['blended_ingredients'] = { label = 'Blended Ingredients', weight = 100, stack = true, close = false, description = 'Blended moonshine ingredients.', client = { image = 'blended_ingredients.png' } },
    ['moonshine'] = { label = 'Moonshine', weight = 200, stack = true, close = false, description = 'A bottle of moonshine.', client = { image = 'moonshine.png' } },
    ['unpacked_weed'] = { label = 'Unpacked Weed', weight = 100, stack = true, close = false, description = 'Unpacked weed.', client = { image = 'unpacked_weed.png' } },
    ['packed_weed'] = { label = 'Packed Weed', weight = 100, stack = true, close = false, description = 'Packed weed ready to sell.', client = { image = 'packed_weed.png' } },
    ['rolled_weed'] = { label = 'Rolled Weed', weight = 20, stack = true, close = false, description = 'A rolled weed joint.', client = { image = 'rolled_weed.png' } },
    ['uncutted_money'] = { label = 'Uncut Money', weight = 50, stack = true, close = false, description = 'Uncut counterfeit money.', client = { image = 'uncutted_money.png' } },
    ['cutted_money'] = { label = 'Cut Money', weight = 50, stack = true, close = false, description = 'Cut counterfeit money.', client = { image = 'cutted_money.png' } },
    ['cooked_meth'] = { label = 'Cooked Meth', weight = 100, stack = true, close = false, description = 'Freshly cooked meth.', client = { image = 'cooked_meth.png' } },
    ['breaked_meth'] = { label = 'Broken Meth', weight = 100, stack = true, close = false, description = 'Broken down meth.', client = { image = 'breaked_meth.png' } },
    ['packed_meth'] = { label = 'Packed Meth', weight = 100, stack = true, close = false, description = 'Packed meth ready to sell.', client = { image = 'packed_meth.png' } },
    ['unpacked_coke'] = { label = 'Unpacked Coke', weight = 100, stack = true, close = false, description = 'Unpacked cocaine.', client = { image = 'unpacked_coke.png' } },
    ['cutted_coke'] = { label = 'Cut Coke', weight = 100, stack = true, close = false, description = 'Cut cocaine.', client = { image = 'cutted_coke.png' } },
    ['packed_coke'] = { label = 'Packed Coke', weight = 100, stack = true, close = false, description = 'Packed cocaine ready to sell.', client = { image = 'packed_coke.png' } },
    ['stolen_bag'] = { label = 'Stolen Bag', weight = 500, stack = true, close = false, description = 'A snatched bag with unknown contents.', client = { image = 'stolen_bag.png' } },
    ['copperwire'] = { label = 'Copper Wire', weight = 100, stack = true, close = false, description = 'Scrap copper wire.', client = { image = 'copperwire.png' } },
    ['painkiller'] = { label = 'Painkiller', weight = 10, stack = true, close = true, description = 'Relieves pain.', client = { image = 'painkiller.png' } },
    ['medkit'] = { label = 'Medkit', weight = 500, stack = true, close = true, description = 'A medical kit.', client = { image = 'medkit.png' } },
    ['adrenaline'] = { label = 'Adrenaline', weight = 100, stack = true, close = true, description = 'An adrenaline shot.', client = { image = 'adrenaline.png' } },
    -- ─── Lunar Scripts (heist contracts + drugs creator) ───
    ['blue_keycard'] = {
        label = 'Blue Keycard',
        weight = 100,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'blue_keycard.png' },
    },
    ['purple_keycard'] = {
        label = 'Purple Keycard',
        weight = 100,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'purple_keycard.png' },
    },
    ['hack_usb'] = {
        label = 'Phantom USB',
        weight = 100,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'hack_usb.png' },
    },
    ['hack_card'] = {
        label = 'Spoofing Card',
        weight = 100,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'hack_card.png' },
    },
    ['coins'] = {
        label = 'Coins',
        weight = 10,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coins.png' },
    },
    ['painting'] = {
        label = 'Painting',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'painting.png' },
    },
    ['bomb_c4'] = {
        label = 'C4 Explosive',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'bomb_c4.png' },
    },
    ['angle_grinder'] = {
        label = 'Angle Grinder',
        weight = 1500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'angle_grinder.png' },
    },
    ['contracts_tablet'] = {
        label = 'Contract Tablet',
        weight = 400,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'contracts_tablet.png' },
    },
    ['classified_docs'] = {
        label = 'Classified Documents',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'classified_docs.png' },
    },
    ['diamonds_box'] = {
        label = 'Diamonds Box',
        weight = 200,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'diamonds_box.png' },
    },
    ['luxurious_watch'] = {
        label = 'Luxurious Watch',
        weight = 200,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'luxurious_watch.png' },
    },
    ['rare_coins'] = {
        label = 'Rare Coins',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'rare_coins.png' },
    },
    ['gold_bar'] = {
        label = 'Gold Bar',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'gold_bar.png' },
    },
    ['large_drill'] = {
        label = 'Large Drill',
        weight = 12500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'large_drill.png' },
    },
    ['casino_keycard'] = {
        label = 'Casino Keycard',
        weight = 100,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'casino_keycard.png' },
    },
    ['small_drill'] = {
        label = 'Small Drill',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'small_drill.png' },
    },
    ['explosives'] = {
        label = 'Explosives',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'explosives.png' },
    },
    ['tv'] = {
        label = 'Television',
        weight = 12500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'tv.png' },
    },
    ['microwave'] = {
        label = 'Microwave',
        weight = 7500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'microwave.png' },
    },
    ['monitor'] = {
        label = 'Computer Monitor',
        weight = 5000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'monitor.png' },
    },
    ['printer'] = {
        label = 'Printer',
        weight = 10000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'printer.png' },
    },
    ['flat_tv'] = {
        label = 'Flat Screen TV',
        weight = 12500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'flat_tv.png' },
    },
    ['old_tv'] = {
        label = 'Old TV',
        weight = 12500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'old_tv.png' },
    },
    ['dj_deck'] = {
        label = 'DJ Deck',
        weight = 7500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'dj_deck.png' },
    },
    ['console'] = {
        label = 'Gaming Console',
        weight = 3000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'console.png' },
    },
    ['keyboard'] = {
        label = 'Keyboard',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'keyboard.png' },
    },
    ['bong'] = {
        label = 'Bong',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'bong.png' },
    },
    ['meth_bag'] = {
        label = 'Meth Bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'meth_bag.png' },
    },
    ['pink_diamond'] = {
        label = 'Pink Diamond',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'pink_diamond.png' },
    },
    ['rare_tequila'] = {
        label = 'Rare Tequila',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'rare_tequila.png' },
    },
    ['sodium_benzoate'] = {
        label = 'Sodium benzoate',
        weight = 750,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'sodium_benzoate.png' },
    },
    ['meth_tray'] = {
        label = 'Meth tray',
        weight = 1000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'meth_tray.png' },
    },
    ['meth_syringe'] = {
        label = 'Meth syringe',
        weight = 75,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'meth_syringe.png' },
    },
    ['coke_seed'] = {
        label = 'Cocaine seed',
        weight = 10,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_seed.png' },
    },
    ['coke_leaf'] = {
        label = 'Cocaine leaf',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_leaf.png' },
    },
    ['coke_paste'] = {
        label = 'Cocaine paste',
        weight = 150,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_paste.png' },
    },
    ['coke'] = {
        label = 'Cocaine',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke.png' },
    },
    ['coke_bag'] = {
        label = 'Cocaine bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_bag.png' },
    },
    ['coke_doll'] = {
        label = 'Cocaine doll',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_doll.png' },
    },
    ['weed_seed'] = {
        label = 'Weed seed',
        weight = 5,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_seed.png' },
    },
    ['weed_pot'] = {
        label = 'Flower Pot',
        weight = 500,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_pot.png' },
    },
    ['trowel'] = {
        label = 'Trowel',
        weight = 150,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'trowel.png' },
    },
    ['weed_bud'] = {
        label = 'Weed bud',
        weight = 25,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_bud.png' },
    },
    ['clean_weed_bud'] = {
        label = 'Clean weed bud',
        weight = 20,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'clean_weed_bud.png' },
    },
    ['cookie_dough'] = {
        label = 'Cookie dough',
        weight = 200,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'cookie_dough.png' },
    },
    ['weed_cookie'] = {
        label = 'Weed cookie',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_cookie.png' },
    },
    ['weed_bag'] = {
        label = 'Weed bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_bag.png' },
    },
    ['weed_joint'] = {
        label = 'Weed joint',
        weight = 15,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_joint.png' },
    },
    ['weed_papers'] = {
        label = 'Weed papers',
        weight = 5,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_papers.png' },
    },
    ['poppy_seeds'] = {
        label = 'Poppy seeds',
        weight = 5,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'poppy_seeds.png' },
    },
    ['poppy_plant'] = {
        label = 'Poppy plant',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'poppy_plant.png' },
    },
    ['opium'] = {
        label = 'Opium',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'opium.png' },
    },
    ['heroin'] = {
        label = 'Heroin',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'heroin.png' },
    },
    ['heroin_bag'] = {
        label = 'Heroin bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'heroin_bag.png' },
    },
    ['heroin_syringe'] = {
        label = 'Heroin syringe',
        weight = 75,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'heroin_syringe.png' },
    },
    ['syringe'] = {
        label = 'Syringe',
        weight = 25,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'syringe.png' },
    },
    ['ergot_fungus'] = {
        label = 'Ergot fungus',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'ergot_fungus.png' },
    },
    ['generic_leaf'] = {
        label = 'Leaf',
        weight = 20,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'generic_leaf.png' },
    },
    ['lsd_liquid'] = {
        label = 'LSD liquid',
        weight = 25,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'lsd_liquid.png' },
    },
    ['lsd'] = {
        label = 'LSD',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'lsd.png' },
    },
    ['art_papers'] = {
        label = 'Art papers',
        weight = 5,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'art_papers.png' },
    },
    ['safrole_oil'] = {
        label = 'Safrole oil',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'safrole_oil.png' },
    },
    ['ecstasy_crystals'] = {
        label = 'Ecstasy crystals',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'ecstasy_crystals.png' },
    },
    ['ecstasy_pill'] = {
        label = 'Ecstasy pill',
        weight = 15,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'ecstasy_pill.png' },
    },
    ['mushrooms'] = {
        label = 'Mushrooms',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'mushrooms.png' },
    },
    ['mushroom_powder'] = {
        label = 'Mushroom powder',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'mushroom_powder.png' },
    },
    ['chocolate_chips'] = {
        label = 'Chocolate chips',
        weight = 30,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'chocolate_chips.png' },
    },
    ['mushroom_chocolate'] = {
        label = 'Mushroom chocolate',
        weight = 45,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'mushroom_chocolate.png' },
    },
    ['anesthetic'] = {
        label = 'anesthetic',
        weight = 200,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'anesthetic.png' },
    },
    ['ketamine'] = {
        label = 'Ketamine',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'ketamine.png' },
    },
    ['ketamine_bag'] = {
        label = 'Ketamine bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'ketamine_bag.png' },
    },
    ['baking_soda'] = {
        label = 'Baking soda',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'baking_soda.png' },
    },
    ['crack'] = {
        label = 'Crack',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'crack.png' },
    },
    ['crack_bag'] = {
        label = 'Crack bag',
        weight = 50,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'crack_bag.png' },
    },
    ['crack_pipe'] = {
        label = 'Crack pipe',
        weight = 150,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'crack_pipe.png' },
    },
    ['crack_syringe'] = {
        label = 'Crack syringe',
        weight = 75,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'crack_syringe.png' },
    },
    ['pipe'] = {
        label = 'Pipe',
        weight = 100,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'pipe.png' },
    },
    ['npp_chemical'] = {
        label = 'NPP chemical',
        weight = 300,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'npp_chemical.png' },
    },
    ['aniline_solution'] = {
        label = 'Aniline solution',
        weight = 250,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'aniline_solution.png' },
    },
    ['fentanyl'] = {
        label = 'Fentanyl',
        weight = 1,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'fentanyl.png' },
    },
    ['fentanyl_bag'] = {
        label = 'Fentanyl bag',
        weight = 25,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'fentanyl_bag.png' },
    },
    ['meth_table'] = {
        label = 'Meth table',
        weight = 2250,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'meth_table.png' },
    },
    ['coke_table'] = {
        label = 'Coke table',
        weight = 2250,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'coke_table.png' },
    },
    ['weed_table'] = {
        label = 'Weed table',
        weight = 2250,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'weed_table.png' },
    },
    ['chem_table'] = {
        label = 'Chemistry table',
        weight = 2250,
        stack = false,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'chem_table.png' },
    },
    ['burner_phone'] = {
        label = 'Burner phone',
        weight = 200,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'burner_phone.png' },
    },
    ['light1'] = {
        label = 'Portable Lamp',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'light1.png' },
    },
    ['light2'] = {
        label = 'Portable Lamp',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'light2.png' },
    },
    ['water_can'] = {
        label = 'Watering can',
        weight = 250,
        stack = true,
        close = true,
        description = 'Lunar Scripts item.',
        client = { image = 'water_can.png' },
    },

    -- ─── 0r-heistpack ───
    ['heistpack_tablet'] = {
        label = 'Heist Tablet',
        weight = 500,
        stack = false,
        close = true,
        description = 'Opens the 0r heist menu.',
        client = { image = 'heistpack_tablet.png' },
    },
    ['heistpack_drone'] = {
        label = 'Heist Drone',
        weight = 1500,
        stack = false,
        close = true,
        description = 'Surveillance drone for heists.',
        client = { image = 'heistpack_drone.png' },
    },
    ['heistpack_drill'] = {
        label = 'Heist Drill',
        weight = 5000,
        stack = false,
        close = true,
        description = 'Heavy drill for vaults and ATMs.',
        client = { image = 'heistpack_drill.png' },
    },
    ['heistpack_anchor'] = {
        label = 'Heist Anchor',
        weight = 2000,
        stack = false,
        close = true,
        description = 'Anchor used during cargo ship jobs.',
        client = { image = 'heistpack_anchor.png' },
    },
    ['heistpack_grinder'] = {
        label = 'Angle Grinder',
        weight = 2500,
        stack = false,
        close = true,
        description = 'Cuts through metal during robberies.',
        client = { image = 'heistpack_grinder.png' },
    },
    ['gasmask'] = {
        label = 'Gas Mask',
        weight = 800,
        stack = false,
        close = true,
        description = 'Protects against gas during heists.',
        client = { image = 'gasmask.png' },
    },
    ['heavy_rope'] = {
        label = 'Heavy Rope',
        weight = 600,
        stack = true,
        close = true,
        description = 'Heavy rope for ATM pulls.',
        client = { image = 'heavy_rope.png' },
    },
    ['weapon_hackingdevice'] = {
        label = 'Hacking Device',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Used to hack house and ATM systems.',
        client = { image = 'weapon_hackingdevice.png' },
    },
    ['weapon_stickybomb'] = {
        label = 'Sticky Bomb',
        weight = 2000,
        stack = true,
        close = true,
        description = 'Explosive charge for bank jobs.',
        client = { image = 'weapon_stickybomb.png' },
    },

    -- Prism Farming
    ['wheat_seeds'] = {
        label = 'Wheat Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'A small packet of wheat seeds ready for planting.',
        client = { image = 'wheat_seeds.png' },
    },
    ['corn_seeds'] = {
        label = 'Corn Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'A small packet of corn seeds ready for planting.',
        client = { image = 'corn_seeds.png' },
    },
    ['carrot_seeds'] = {
        label = 'Carrot Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'A small packet of carrot seeds ready for planting.',
        client = { image = 'carrot_seeds.png' },
    },
    ['potato_seeds'] = {
        label = 'Potato Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'A small packet of potato seeds ready for planting.',
        client = { image = 'potato_seeds.png' },
    },
    ['wheat_bundle'] = {
        label = 'Wheat Bundle',
        weight = 500,
        stack = true,
        close = true,
        description = 'A bundle of freshly harvested wheat stalks.',
        client = { image = 'wheat_bundle.png' },
    },
    ['corn_crate'] = {
        label = 'Corn Crate',
        weight = 600,
        stack = true,
        close = true,
        description = 'A crate filled with freshly harvested corn.',
        client = { image = 'corn_crate.png' },
    },
    ['carrot_bundle'] = {
        label = 'Carrot Bundle',
        weight = 400,
        stack = true,
        close = true,
        description = 'A bundle of freshly dug carrots.',
        client = { image = 'carrot_bundle.png' },
    },
    ['potato_sack'] = {
        label = 'Potato Sack',
        weight = 700,
        stack = true,
        close = true,
        description = 'A sack of freshly dug potatoes.',
        client = { image = 'potato_sack.png' },
    },
    ['raw_milk'] = {
        label = 'Raw Milk',
        weight = 300,
        stack = true,
        close = true,
        description = 'Fresh raw milk from a farm cow.',
        client = { image = 'raw_milk.png' },
    },
    ['fresh_eggs'] = {
        label = 'Fresh Eggs',
        weight = 150,
        stack = true,
        close = true,
        description = 'A carton of fresh farm eggs.',
        client = { image = 'fresh_eggs.png' },
    },
    ['raw_pork'] = {
        label = 'Raw Pork',
        weight = 500,
        stack = true,
        close = true,
        description = 'Raw pork cuts from a farm pig.',
        client = { image = 'raw_pork.png' },
    },
    ['raw_wool'] = {
        label = 'Raw Wool',
        weight = 350,
        stack = true,
        close = true,
        description = 'Freshly sheared raw wool.',
        client = { image = 'raw_wool.png' },
    },
    ['premium_milk'] = {
        label = 'Premium Milk',
        weight = 300,
        stack = true,
        close = true,
        description = 'High quality premium milk. Highly valued.',
        client = { image = 'premium_milk.png' },
    },
    ['golden_egg'] = {
        label = 'Golden Egg',
        weight = 200,
        stack = true,
        close = true,
        description = 'An extremely rare golden egg. Very valuable.',
        client = { image = 'golden_egg.png' },
    },
    ['truffle'] = {
        label = 'Truffle',
        weight = 100,
        stack = true,
        close = true,
        description = 'A rare truffle found by a farm pig. Extremely valuable.',
        client = { image = 'truffle.png' },
    },
    ['fine_wool'] = {
        label = 'Fine Wool',
        weight = 350,
        stack = true,
        close = true,
        description = 'Premium quality fine wool. Highly sought after.',
        client = { image = 'fine_wool.png' },
    },
    ['fresh_apple'] = {
        label = 'Fresh Apple',
        weight = 120,
        stack = true,
        close = true,
        description = 'A fresh red apple picked from the orchard.',
        client = { image = 'fresh_apple.png' },
    },
    ['fresh_orange'] = {
        label = 'Fresh Orange',
        weight = 150,
        stack = true,
        close = true,
        description = 'A fresh orange picked from the orchard.',
        client = { image = 'fresh_orange.png' },
    },
    ['fresh_lemon'] = {
        label = 'Fresh Lemon',
        weight = 100,
        stack = true,
        close = true,
        description = 'A fresh lemon picked from the orchard.',
        client = { image = 'fresh_lemon.png' },
    },
    ['apple_sapling'] = {
        label = 'Apple Sapling',
        weight = 200,
        stack = true,
        close = true,
        description = 'A young apple tree sapling. Can be planted.',
        client = { image = 'apple_sapling.png' },
    },
    ['orange_sapling'] = {
        label = 'Orange Sapling',
        weight = 200,
        stack = true,
        close = true,
        description = 'A young orange tree sapling. Can be planted.',
        client = { image = 'orange_sapling.png' },
    },
    ['lemon_sapling'] = {
        label = 'Lemon Sapling',
        weight = 200,
        stack = true,
        close = true,
        description = 'A young lemon tree sapling. Can be planted.',
        client = { image = 'lemon_sapling.png' },
    },
    ['golden_wheat_seeds'] = {
        label = 'Golden Wheat Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rare golden wheat seeds. Produces premium harvest with chance for rare herbs.',
        client = { image = 'golden_wheat_seeds.png' },
    },
    ['royal_potato_seeds'] = {
        label = 'Royal Potato Seeds',
        weight = 50,
        stack = true,
        close = true,
        description = 'Rare royal potato seeds. Produces premium harvest with chance for rare herbs.',
        client = { image = 'royal_potato_seeds.png' },
    },
    ['golden_wheat_bundle'] = {
        label = 'Golden Wheat Bundle',
        weight = 500,
        stack = true,
        close = true,
        description = 'A bundle of rare golden wheat. Sells for a premium price.',
        client = { image = 'golden_wheat_bundle.png' },
    },
    ['royal_potato_sack'] = {
        label = 'Royal Potato Sack',
        weight = 700,
        stack = true,
        close = true,
        description = 'A sack of rare royal potatoes. Sells for a premium price.',
        client = { image = 'royal_potato_sack.png' },
    },
    ['rare_herb'] = {
        label = 'Rare Herb',
        weight = 50,
        stack = true,
        close = true,
        description = 'An extremely rare herb found while farming premium crops. Very valuable.',
        client = { image = 'rare_herb.png' },
    },
    ['pesticide'] = {
        label = 'Pesticide',
        weight = 250,
        stack = true,
        close = true,
        description = 'Cures pest infestations on farm plots. Use near an infested plant.',
        client = { image = 'pesticide.png' },
    },
    ['dirt'] = {
        label = 'Dirt',
        weight = 100,
        stack = true,
        close = true,
        description = 'A handful of farm dirt. Sometimes found while harvesting.',
        client = { image = 'dirt.png' },
    },

    ['starter_vehicle_voucher'] = {
        label = 'Starter Vehicle Voucher',
        weight = 10,
        stack = false,
        close = true,
        description = 'Redeem at Premium Deluxe Motorsport for one free starter vehicle (one class of your choice).',
        client = {
            image = 'starter_vehicle_voucher.png',
            export = 'rw-welcome.useVoucher',
        },
    },


    ['grappler'] = {
        label = 'PD Grappler',
        weight = 3500,
        stack = false,
        close = true,
        description = 'Police pursuit wheel-grappler. Target the front of a PD unit to Assemble. Returned when disassembled.',
        client = {
            image = 'grappler.png',
        },
    },



    ['orbit_device'] = {
        label = 'Orbit Tablet',
        weight = 500,
        stack = false,
        close = true,
        description = 'Your personal Orbit ride tablet. Use it to call an autonomous Orbit.',
        client = {
            image = 'orbit_device.png',
            export = 'wb_orbit.useDevice',
        },
    },


    ['bm_burner_phone'] = {
        label = 'Burner Phone',
        weight = 200,
        stack = false,
        close = true,
        description = 'One-time off-books contact for anonymous storage. Bound to you — use it to unlock Off-Books rentals.',
        client = {
            image = 'bm_burner_phone.png',
            export = 'oxlyn-containers.useBurnerPhone',
        },
    },


    -- RealWrld Backpack V4 (oxlyn_backpack)
    ['backpack_level_1'] = {
        label = 'Scout Pack',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Compact backpack — 16 slots / 10 kg. Open it from your inventory.',
        client = { export = 'oxlyn_backpack.openBackpack' },
    },
    ['backpack_level_2'] = {
        label = 'Courier Pack',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Mid-tier backpack — 24 slots / 15 kg. Open it from your inventory.',
        client = { export = 'oxlyn_backpack.openBackpack' },
    },
    ['backpack_level_3'] = {
        label = 'Operator Pack',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Heavy-duty backpack — 32 slots / 20 kg. Open it from your inventory.',
        client = { export = 'oxlyn_backpack.openBackpack' },
    },
    ['backpack_level_4'] = {
        label = 'Expedition Pack',
        weight = 1000,
        stack = false,
        close = true,
        description = 'Top-tier backpack — 46 slots / 25 kg. Open it from your inventory.',
        client = { export = 'oxlyn_backpack.openBackpack' },
    },
    ['backpack_padlock'] = {
        label = 'Padlock',
        weight = 200,
        stack = false,
        close = true,
        description = 'PIN padlock. Drag it into an open backpack to secure it with a 4-digit code.',
    },
    ['backpack_fingerprint_padlock'] = {
        label = 'Fingerprint Padlock',
        weight = 250,
        stack = false,
        close = true,
        description = 'Biometric lock. Drag it into an open backpack to bind it to your fingerprint.',
    },
    ['backpack_gps'] = {
        label = 'GPS Module',
        weight = 150,
        stack = false,
        close = true,
        description = 'Place inside a backpack to track it. Includes tamper alerts.',
    },
    ['backpack_multitool'] = {
        label = 'Multitool',
        weight = 300,
        stack = false,
        close = true,
        description = 'Precision cracking tool for padlocks that are not yours.',
    },
    ['backpack_custom_1']  = { label = 'Custom Backpack 1',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_2']  = { label = 'Custom Backpack 2',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_3']  = { label = 'Custom Backpack 3',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_4']  = { label = 'Custom Backpack 4',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_5']  = { label = 'Custom Backpack 5',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_6']  = { label = 'Custom Backpack 6',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_7']  = { label = 'Custom Backpack 7',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_8']  = { label = 'Custom Backpack 8',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_9']  = { label = 'Custom Backpack 9',  weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },
    ['backpack_custom_10'] = { label = 'Custom Backpack 10', weight = 1000, stack = false, close = true, description = 'A configurable backpack.', client = { export = 'oxlyn_backpack.openBackpack' } },

    -- Apex Billing --
    ['apex_invoice'] = {
        label  = 'Invoice',
        weight = 5,
        stack  = false,
        close  = true,
        description = 'A printed invoice. Inspect it to view details and pay.',
        client = {
            export = 'apex_billing.useInvoice',
        },
    },
    ['apex_printer'] = {
        label  = 'Invoice Printer',
        weight = 1200,
        stack  = false,
        close  = true,
        description = 'Required to issue invoices. Carry one to use /billing.',
    },
    -- Apex Gangs --
    ['spraycan'] = {
        label = 'Spray Can', weight = 400, stack = true, close = true,
        description = 'Tag walls with your gang colours.',
        client = { export = 'apex_gangs.useSprayItem' },
    },
    ['spray_remover'] = {
        label = 'Spray Remover', weight = 500, stack = true, close = true,
        description = 'Scrub rival tags off the wall.',
    },
    ['gang_supplies'] = { label = 'Gang Supplies', weight = 1000, stack = true, close = false },
    ['weapon_parts']  = { label = 'Weapon Parts',  weight = 800,  stack = true, close = false },



-- REALWRLD POLICEKIT BEGIN
-- Insert these entries inside the return table in ox_inventory/data/items.lua.
-- Do not register a second ESX usable-item handler for these entries.

['oxlyn_pk_evidence_01'] = {
    label = 'Evidence Marker 01', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_01.png' }
},

['oxlyn_pk_evidence_02'] = {
    label = 'Evidence Marker 02', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_02.png' }
},

['oxlyn_pk_evidence_03'] = {
    label = 'Evidence Marker 03', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_03.png' }
},

['oxlyn_pk_evidence_04'] = {
    label = 'Evidence Marker 04', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_04.png' }
},

['oxlyn_pk_evidence_05'] = {
    label = 'Evidence Marker 05', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_05.png' }
},

['oxlyn_pk_evidence_06'] = {
    label = 'Evidence Marker 06', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_06.png' }
},

['oxlyn_pk_evidence_07'] = {
    label = 'Evidence Marker 07', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_07.png' }
},

['oxlyn_pk_evidence_08'] = {
    label = 'Evidence Marker 08', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_08.png' }
},

['oxlyn_pk_evidence_09'] = {
    label = 'Evidence Marker 09', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_09.png' }
},

['oxlyn_pk_evidence_10'] = {
    label = 'Evidence Marker 10', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_10.png' }
},

['oxlyn_pk_evidence_11'] = {
    label = 'Evidence Marker 11', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_11.png' }
},

['oxlyn_pk_evidence_12'] = {
    label = 'Evidence Marker 12', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_12.png' }
},

['oxlyn_pk_evidence_13'] = {
    label = 'Evidence Marker 13', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_13.png' }
},

['oxlyn_pk_evidence_14'] = {
    label = 'Evidence Marker 14', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_14.png' }
},

['oxlyn_pk_evidence_15'] = {
    label = 'Evidence Marker 15', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_15.png' }
},

['oxlyn_pk_evidence_bag'] = {
    label = 'Evidence Bag', weight = 0, stack = false, close = true, consume = 0,
    description = 'Reusable evidence collection case. Place it closed, open the lid, then access its private inventory. Contents stay with the case.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_evidence_bag.png' }
},

['oxlyn_pk_metal_detector'] = {
    label = 'Walk-Through Metal Detector', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_metal_detector.png' }
},

['oxlyn_pk_police_tape_reel'] = {
    label = 'Police Tape Reel', weight = 0, stack = false, close = true, consume = 0,
    description = 'Start a tape line, then use Extend tape to add sections up to 10 m. Removing the last section returns the original reel.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_police_tape_reel.png' }
},

['oxlyn_pk_police_tent'] = {
    label = 'Police Canopy', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_police_tent.png' }
},

['oxlyn_pk_portable_floodlight'] = {
    label = 'Portable Floodlight', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_portable_floodlight.png' }
},

['oxlyn_pk_portable_message_board'] = {
    label = 'Portable Message Board', weight = 0, stack = false, close = true, consume = 0,
    description = 'Place the board, then enter two message lines of up to 12 characters each. Edit or switch it off with ox_target.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_portable_message_board.png' }
},

['oxlyn_pk_portable_stop_sign'] = {
    label = 'Portable Stop Sign', weight = 0, stack = false, close = true, consume = 0,
    description = 'Portable checkpoint sign with amber warning lamps. Switch lights on or off and select flashing or steady mode.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_portable_stop_sign.png' }
},

['oxlyn_pk_road_barricade'] = {
    label = 'Road Barricade', weight = 0, stack = false, close = true, consume = 0,
    description = 'Reusable police equipment. One inventory item places multiple units; removing a unit gives no extra item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_road_barricade.png' }
},

['oxlyn_pk_speed_trailer'] = {
    label = 'Mobile Speed Radar', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_speed_trailer.png' }
},

['oxlyn_pk_spike'] = {
    label = 'Spike Strip', weight = 0, stack = false, close = true, consume = 0,
    description = 'Police equipment. Use to place; recover to return the original item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_spike.png' }
},

['oxlyn_pk_traffic_cone'] = {
    label = 'Traffic Cone', weight = 0, stack = false, close = true, consume = 0,
    description = 'Reusable police equipment. One inventory item places multiple units; removing a unit gives no extra item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_traffic_cone.png' }
},

['oxlyn_pk_water_filled_barrier'] = {
    label = 'Water-Filled Barrier', weight = 0, stack = false, close = true, consume = 0,
    description = 'Reusable water-ballasted barrier. One inventory item places multiple barriers; removing a barrier gives no extra item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_water_filled_barrier.png' }
},

['oxlyn_pk_wheel_clamp'] = {
    label = 'Wheel Clamp', weight = 0, stack = false, close = true, consume = 0,
    description = 'Aim at a vehicle wheel to install. Authorized personnel can unlock and recover it.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_wheel_clamp.png' }
},

['oxlyn_pk_wooden_barrier'] = {
    label = 'Police Wooden Barrier', weight = 0, stack = false, close = true, consume = 0,
    description = 'Reusable police equipment. One inventory item places multiple units; removing a unit gives no extra item.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_wooden_barrier.png' }
},

-- Compatibility aliases only: do not distribute these names. Existing inventory items recover as oxlyn_pk_spike.

['oxlyn_pk_spike_long'] = {
    label = 'Spike Strip', weight = 0, stack = false, close = true, consume = 0,
    description = 'Legacy equipment. Place and recover to receive the unified spike strip.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_spike.png' }
},

['oxlyn_pk_spike_medium'] = {
    label = 'Spike Strip', weight = 0, stack = false, close = true, consume = 0,
    description = 'Legacy equipment. Place and recover to receive the unified spike strip.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_spike.png' }
},

['oxlyn_pk_spike_short'] = {
    label = 'Spike Strip', weight = 0, stack = false, close = true, consume = 0,
    description = 'Legacy equipment. Place and recover to receive the unified spike strip.',
    client = { export = 'oxlyn-policekit.useKitItem', image = 'https://cfx-nui-ox_inventory/web/img/oxlyn_pk_spike.png' }
},
-- REALWRLD POLICEKIT END




-- ═══════════════════════════════════════════════════════════════════════════
--  ox_inventory  ·  paste these entries inside the `return { ... }` table of
--  ox_inventory/data/items.lua, then copy install/images/*.png to
--  ox_inventory/web/images/.
--
--  The client.export line is what makes using the item start placement:
--  ox_inventory runs usable items on the client. Do NOT also register them
--  as ESX / QBCore usable items.
--
--  The workbench is stack = false on purpose: each cabinet carries its own
--  storage identity in its metadata.
-- ═══════════════════════════════════════════════════════════════════════════

['oxlyn_mk_vehicle_lift'] = {
    label = 'Vehicle Lift', weight = 0, stack = true, close = true, consume = 0,
    description = 'Portable hydraulic vehicle lift.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_vehicle_lift.png' },
},

['oxlyn_mk_two_post_lift'] = {
    label = 'Two-post Vehicle Lift', weight = 0, stack = true, close = true, consume = 0,
    description = 'High-rise two-column lift with telescopic chassis support arms.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_two_post_lift.png' },
},

['oxlyn_mk_dyno'] = {
    label = 'Rolling Road Dyno', weight = 0, stack = true, close = true, consume = 0,
    description = 'Vehicle dynamometer platform and display.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_dyno.png' },
},

['oxlyn_mk_workbench'] = {
    label = 'Mechanic Workbench', weight = 0, stack = false, close = true, consume = 0,
    description = 'Tool cabinet with its own private storage.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_workbench.png' },
},

['oxlyn_mk_spray_kit'] = {
    label = 'Portable Spray Kit', weight = 0, stack = true, close = true, consume = 0,
    description = 'Compressor, hose and paint spray gun.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_spray_kit.png' },
},

['oxlyn_mk_floor_jack'] = {
    label = 'Hydraulic Floor Jack', weight = 0, stack = true, close = true, consume = 0,
    description = 'Low-profile hydraulic jack. Place beside the vehicle sill.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_floor_jack.png' },
},

['oxlyn_mk_workshop_light'] = {
    label = 'Workshop Inspection Light', weight = 0, stack = true, close = true, consume = 0,
    description = 'Folding battery-powered twin LED workshop light.',
    client = { export = 'oxlyn-mechanickit.useKitItem', image = 'oxlyn_mk_workshop_light.png' },
},


    ['3dprinter'] = {
        label = '3D Printer',
        weight = 12000,
        stack = false,
        close = true,
        consume = 0,
        description = 'A placeable 3D printer. Use it to set up a print station.',
        client = {
            export = 'ox_inventory.usePrinter',
            image = '3dprinter.png',
        },
    },

    ['3dprinter_battery'] = {
        label = 'Printer Battery',
        weight = 500,
        stack = true,
        close = true,
        description = 'Replacement battery for a 3D printer.',
        client = { image = '3dprinter_battery.png' },
    },

    -- plt_drugs items (added 2026-10-28)
    ['gingeritis_weed'] = {
        label = 'Wet Gingeritis Weed',
        weight = 110,
        stack = true,
        close = true,
    },
    ['energizing_dried_weed'] = {
        label = 'Energizing Dried Weed',
        weight = 30,
        stack = true,
        close = true,
    },
    ['high_quality_weed'] = {
        label = 'Wet High Quality Weed',
        weight = 100,
        stack = true,
        close = true,
    },
    ['dried_weed'] = {
        label = 'Dried Weed',
        weight = 20,
        stack = true,
        close = true,
    },
    ['dried_high_quality_weed'] = {
        label = 'Dried High Quality Weed',
        weight = 20,
        stack = true,
        close = true,
    },
    ['packaged_gingeritis_weed'] = {
        label = 'Packaged Wet Gingeritis Weed',
        weight = 110,
        stack = true,
        close = true,
    },
    ['packaged_energizing_dried_weed'] = {
        label = 'Packaged Dried Energizing Weed',
        weight = 40,
        stack = true,
        close = true,
    },
    ['packaged_weed'] = {
        label = 'Packaged Wet Weed',
        weight = 110,
        stack = true,
        close = true,
    },
    ['packaged_high_quality_weed'] = {
        label = 'Packaged Wet High Quality Weed',
        weight = 110,
        stack = true,
        close = true,
    },
    ['packaged_dried_weed'] = {
        label = 'Packaged Dried Weed',
        weight = 30,
        stack = true,
        close = true,
    },
    ['packaged_dried_high_quality_weed'] = {
        label = 'Packaged Dried High Quality Weed',
        weight = 20,
        stack = true,
        close = true,
    },
    ['high_quality_coke_leaf'] = {
        label = 'Wet High Quality Coke Leaf',
        weight = 50,
        stack = true,
        close = true,
    },
    ['dried_coke_leaf'] = {
        label = 'Dried Coke Leaf',
        weight = 10,
        stack = true,
        close = true,
    },
    ['dried_high_quality_coke_leaf'] = {
        label = 'Dried High Quality Coke Leaf',
        weight = 10,
        stack = true,
        close = true,
    },
    ['high_quality_coke'] = {
        label = 'Wet High Quality Coke Base',
        weight = 100,
        stack = true,
        close = true,
    },
    ['dried_coke'] = {
        label = 'Dried Coke Base',
        weight = 20,
        stack = true,
        close = true,
    },
    ['dried_high_quality_coke'] = {
        label = 'Dried High Quality Coke Base',
        weight = 20,
        stack = true,
        close = true,
    },
    ['cooked_coke'] = {
        label = 'Wet Coke',
        weight = 100,
        stack = true,
        close = true,
    },
    ['cooked_high_quality_coke'] = {
        label = 'Wet High Quality Coke',
        weight = 100,
        stack = true,
        close = true,
    },
    ['cooked_dried_coke'] = {
        label = 'Dried Coke',
        weight = 20,
        stack = true,
        close = true,
    },
    ['cooked_dried_high_quality_coke'] = {
        label = 'Dried High Quality Coke',
        weight = 20,
        stack = true,
        close = true,
    },
    ['packaged_coke'] = {
        label = 'Packaged Wet Coke Base',
        weight = 100,
        stack = true,
        close = true,
    },
    ['packaged_high_quality_coke'] = {
        label = 'Packaged Wet High Quality Coke Base',
        weight = 100,
        stack = true,
        close = true,
    },
    ['packaged_dried_coke'] = {
        label = 'Packaged Dried Coke Base',
        weight = 20,
        stack = true,
        close = true,
    },
    ['packaged_dried_high_quality_coke'] = {
        label = 'Packaged Dried High Quality Coke Base',
        weight = 20,
        stack = true,
        close = true,
    },
    ['packaged_cooked_coke'] = {
        label = 'Packaged Wet Coke',
        weight = 100,
        stack = true,
        close = true,
    },
    ['packaged_cooked_high_quality_coke'] = {
        label = 'Packaged Wet High Quality Coke',
        weight = 100,
        stack = true,
        close = true,
    },
    ['packaged_cooked_dried_coke'] = {
        label = 'Packaged Dried Coke',
        weight = 20,
        stack = true,
        close = true,
    },
    ['packaged_cooked_dried_high_quality_coke'] = {
        label = 'Packaged Dried High Quality Coke',
        weight = 20,
        stack = true,
        close = true,
    },
    ['liquid_meth'] = {
        label = 'Liquid Meth',
        weight = 200,
        stack = true,
        close = true,
    },
    ['default_meth'] = {
        label = 'Meth Bud',
        weight = 10,
        stack = true,
        close = true,
    },
    ['packaged_default_meth'] = {
        label = 'Packaged Meth',
        weight = 60,
        stack = true,
        close = true,
    },
    ['high_quality_weed_brick'] = {
        label = 'High Quality Weed Brick',
        weight = 400,
        stack = true,
        close = true,
    },
    ['high_quality_coke_brick'] = {
        label = 'High Quality Coke Base Brick',
        weight = 500,
        stack = true,
        close = true,
    },
    ['cooked_coke_brick'] = {
        label = 'Coke Brick',
        weight = 500,
        stack = true,
        close = true,
    },
    ['cooked_high_quality_coke_brick'] = {
        label = 'Coke High Quality Brick',
        weight = 500,
        stack = true,
        close = true,
    },
    ['baggy'] = {
        label = 'Baggy',
        weight = 10,
        stack = true,
        close = true,
    },
    ['plant_pot'] = {
        label = 'Plant Pot',
        weight = 100,
        stack = true,
        close = true,
    },
    ['default_lamp'] = {
        label = 'Lamp',
        weight = 500,
        stack = true,
        close = true,
    },
    ['default_fan'] = {
        label = 'Fan',
        weight = 500,
        stack = true,
        close = true,
    },
    ['default_soil'] = {
        label = 'Soil',
        weight = 500,
        stack = true,
        close = true,
    },
    ['drying_rack'] = {
        label = 'Drying Rack',
        weight = 500,
        stack = false,
        close = true,
    },
    ['default_brick_press'] = {
        label = 'Brick Press',
        weight = 3500,
        stack = false,
        close = true,
    },
    ['packaging_station'] = {
        label = 'Packaging Station',
        weight = 5000,
        stack = false,
        close = true,
    },
    ['drug_mixer'] = {
        label = 'Drug Mixer',
        weight = 2000,
        stack = false,
        close = true,
    },
    ['plant_trimmers'] = {
        label = 'Plant Trimmers',
        weight = 200,
        stack = true,
        close = true,
    },
    ['drug_cauldron'] = {
        label = 'Cauldron',
        weight = 5000,
        stack = false,
        close = true,
    },
    ['drug_oven'] = {
        label = 'Lab Oven',
        weight = 5000,
        stack = false,
        close = true,
    },
    ['chemistry_station'] = {
        label = 'Chemistry Station',
        weight = 5000,
        stack = false,
        close = true,
    },
    ['acetone'] = {
        label = 'Acetone',
        weight = 500,
        stack = true,
        close = true,
    },
    ['ecola'] = {
        label = 'E-Cola',
        weight = 200,
        stack = true,
        close = true,
    },
    ['pills'] = {
        label = 'Pseudo',
        weight = 100,
        stack = true,
        close = true,
    },
    ['phosphorus'] = {
        label = 'Phosphorus',
        weight = 500,
        stack = true,
        close = true,
    },
    ['gasoline'] = {
        label = 'Gasoline',
        weight = 2000,
        stack = true,
        close = true,
    },
    ['hammer'] = {
        label = 'Hammer',
        weight = 1000,
        stack = true,
        close = true,
    },
    ['banana'] = {
        label = 'Banana',
        weight = 100,
        stack = true,
        close = true,
    },

    -- rm_vaultheist required item (added 2026-10-29)
    ['bag'] = {
        label = 'Bag',
        weight = 160,
    },

    -- prp-atmrob required items (added 2026-10-29)
    ['atm_bomb'] = {
        label = 'Small Explosive',
        weight = 200,
        stack = false,
    },

    ['metal_rope'] = {
        label = 'Metal Rope',
        weight = 500,
        stack = false,
    },

    -- plt-illegal-jobs entry items (added 2026-10-29, accessibility quick-wins)
    ['sketchy_tablet'] = {
        label = 'Sketchy Tablet',
        weight = 1200,
        stack = false,
        close = true,
        consume = 0,
        description = 'Encrypted tablet with access to the darknet OS',
        client = {
            export = 'plt-illegal-jobs.useTablet',
        },
    },

    ['skeet_vpn'] = {
        label = 'Skeet VPN',
        weight = 200,
        stack = false,
        close = false,
        consume = 0,
        description = 'USB dongle required to connect the VPN relay',
    },

    -- kq_meth2 items (added 2026-10-29, from the resource's shipped _INSTALLATION defs)
    ['kq_meth_low'] = {
        label = 'Meth (Low grade)',
        weight = 100,
        stack = true,
        close = true,
    },

    ['kq_meth_mid'] = {
        label = 'Meth (Medium grade)',
        weight = 100,
        stack = true,
        close = true,
    },

    ['kq_meth_high'] = {
        label = 'Meth (High grade)',
        weight = 100,
        stack = true,
        close = true,
    },

    ['kq_ethanol'] = {
        label = 'Ethanol',
        weight = 200,
        stack = true,
        close = true,
    },

    ['kq_meth_pills'] = {
        label = 'Pseudoephedrine',
        weight = 300,
        stack = true,
        close = true,
    },

    ['kq_lithium'] = {
        label = 'Lithium pack',
        weight = 300,
        stack = true,
        close = true,
    },

    ['kq_acetone'] = {
        label = 'Acetone',
        weight = 1000,
        stack = true,
        close = true,
    },

    ['kq_ammonia'] = {
        label = 'Ammonia',
        weight = 1000,
        stack = true,
        close = true,
    },

    ['kq_meth_lab_kit'] = {
        label = 'Meth cooking kit',
        weight = 3000,
        stack = true,
        close = true,
    },

    -- prp-warehouse-robbery items (added 2026-10-29, accessibility quick-wins)
    ['warehouse_entry'] = {
        label = 'Warehouse Entry Pass',
        weight = 100,
        stack = true,
        close = true,
        consume = 0,
        description = 'Single-use pass to start a warehouse robbery',
    },

    ['ocean_run_entry'] = {
        label = 'Ocean Run Entry Pass',
        weight = 100,
        stack = true,
        close = true,
        consume = 0,
        description = 'Single-use pass to start an ocean smuggling run',
    },

    ['warehouse_bomb'] = {
        label = 'Breaching Bomb',
        weight = 2000,
        stack = false,
        close = true,
        consume = 0,
        description = 'Charge used inside warehouse robberies',
    },

    ['warehouse_fuse'] = {
        label = 'Fuse',
        weight = 200,
        stack = true,
        close = true,
        consume = 0,
        description = 'Electrical fuse used inside warehouse robberies',
    },

    ['smuggling_hdd'] = {
        label = 'Smuggled HDD',
        weight = 500,
        stack = true,
        close = true,
        consume = 0,
        description = 'Data drive recovered from an ocean smuggling run',
    },

    ['smuggling_nas'] = {
        label = 'Smuggled NAS',
        weight = 1200,
        stack = true,
        close = true,
        consume = 0,
        description = 'Network storage unit recovered from an ocean smuggling run',
    },

    -- BDX Sport Hub gear (added 2026-10-29)
    ['bmx'] = {
        label = 'BMX',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A BMX bike you can ride and do tricks on.',
        client = {
            image = 'bmx.png',
        }
    },

    ['slopstyle'] = {
        label = 'Slopestyle Bike',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A slopestyle mountain bike.',
        client = {
            image = 'slopstyle.png',
        }
    },

    ['hoverboard'] = {
        label = 'Hoverboard',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A hoverboard you can ride.',
        client = {
            image = 'hoverboard.png',
        }
    },

    ['rollers'] = {
        label = 'Roller Skates',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A pair of roller skates.',
        client = {
            image = 'rollers.png',
        }
    },

    ['scooter'] = {
        label = 'Scooter',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A scooter you can ride.',
        client = {
            image = 'scooter.png',
        }
    },

    ['skis'] = {
        label = 'Skis',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A pair of skis.',
        client = {
            image = 'skis.png',
        }
    },

    ['iceskates'] = {
        label = 'Ice Skates',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A pair of ice skates.',
        client = {
            image = 'iceskates.png',
        }
    },

    ['snowboard'] = {
        label = 'Snowboard',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A snowboard you can ride.',
        client = {
            image = 'snowboard.png',
        }
    },

    ['surfboard'] = {
        label = 'Surfboard',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        description = 'A surfboard you can ride.',
        client = {
            image = 'surfboard.png',
        }
    },


    -- JotaDev Criminal Organizations items (wired 2026-11-03)
    ['bandana'] = {
        label = 'Bandana',
        weight = 500,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'bandana.png',
        }
    },
    ['gunpowder'] = {
        label = 'Gunpowder',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'gunpowder.png',
        }
    },
    ['handcuff'] = {
        label = 'Handcuff',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'handcuff.png',
        }
    },
    ['org_blue_weed_1g_bag'] = {
        label = 'Blue Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_blue_weed_1g_bag.png',
        }
    },
    ['org_common_weed_1g_bag'] = {
        label = 'Common Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_common_weed_1g_bag.png',
        }
    },
    ['org_deletegraffiti'] = {
        label = 'Delete Graffiti',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_deletegraffiti.png',
        }
    },
    ['org_graffiti'] = {
        label = 'Graffiti',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_graffiti.png',
        }
    },
    ['org_lightgreen_weed_1g_bag'] = {
        label = 'Light green Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_lightgreen_weed_1g_bag.png',
        }
    },
    ['org_pink_weed_1g_bag'] = {
        label = 'Pink Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_pink_weed_1g_bag.png',
        }
    },
    ['org_purple_weed_1g_bag'] = {
        label = 'Purple Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_purple_weed_1g_bag.png',
        }
    },
    ['org_yellow_weed_1g_bag'] = {
        label = 'Yellow Weed Bag',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'org_yellow_weed_1g_bag.png',
        }
    },
    ['orgs_1g_bag_cocaine'] = {
        label = 'Orgs 1g Bag Cocaine',
        weight = 15,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_1g_bag_cocaine.png',
        }
    },
    ['orgs_acid_bottle'] = {
        label = 'Orgs Acid Bottle',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_acid_bottle.png',
        }
    },
    ['orgs_activation_module'] = {
        label = 'Orgs Activation Module',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_activation_module.png',
        }
    },
    ['orgs_aluminum'] = {
        label = 'Orgs Aluminum',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_aluminum.png',
        }
    },
    ['orgs_ammunition_tube'] = {
        label = 'Orgs Ammunition Tube',
        weight = 120,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_ammunition_tube.png',
        }
    },
    ['orgs_bluee_weed_bud_dried'] = {
        label = 'Orgs Bluee Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_bluee_weed_bud_dried.png',
        }
    },
    ['orgs_broken_glass_bottle'] = {
        label = 'Orgs Broken Glass Bottle',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_broken_glass_bottle.png',
        }
    },
    ['orgs_caustic_soda'] = {
        label = 'Orgs Caustic Soda',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_caustic_soda.png',
        }
    },
    ['orgs_cocaine_leaf'] = {
        label = 'Orgs Cocaine Leaf',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_cocaine_leaf.png',
        }
    },
    ['orgs_cocaine_powder'] = {
        label = 'Orgs Cocaine Powder',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_cocaine_powder.png',
        }
    },
    ['orgs_common_lightgreen_buds'] = {
        label = 'Orgs Common Lightgreen Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_lightgreen_buds.png',
        }
    },
    ['orgs_common_weed_blue_buds'] = {
        label = 'Orgs Common Weed Blue Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_blue_buds.png',
        }
    },
    ['orgs_common_weed_bud_dried'] = {
        label = 'Orgs Common Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_bud_dried.png',
        }
    },
    ['orgs_common_weed_buds'] = {
        label = 'Orgs Common Weed Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_buds.png',
        }
    },
    ['orgs_common_weed_pink_buds'] = {
        label = 'Orgs Common Weed Pink Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_pink_buds.png',
        }
    },
    ['orgs_common_weed_purple_buds'] = {
        label = 'Orgs Common Weed Purple Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_purple_buds.png',
        }
    },
    ['orgs_common_weed_yellow_buds'] = {
        label = 'Orgs Common Weed Yellow Buds',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_common_weed_yellow_buds.png',
        }
    },
    ['orgs_electronic_components'] = {
        label = 'Orgs Electronic Components',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_electronic_components.png',
        }
    },
    ['orgs_empty_bag'] = {
        label = 'Orgs Empty Bag',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_empty_bag.png',
        }
    },
    ['orgs_empty_charger'] = {
        label = 'Orgs Empty Charger',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_empty_charger.png',
        }
    },
    ['orgs_empty_container'] = {
        label = 'Orgs Empty Container',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_empty_container.png',
        }
    },
    ['orgs_empty_gas_can'] = {
        label = 'Orgs Empty Gas Can',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_empty_gas_can.png',
        }
    },
    ['orgs_empty_gasoline_drum'] = {
        label = 'Orgs Empty Gasoline Drum',
        weight = 300,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_empty_gasoline_drum.png',
        }
    },
    ['orgs_fertilizer'] = {
        label = 'Orgs Fertilizer',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_fertilizer.png',
        }
    },
    ['orgs_flammable_compound'] = {
        label = 'Orgs Flammable Compound',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_flammable_compound.png',
        }
    },
    ['orgs_flowerpot'] = {
        label = 'Orgs Flowerpot',
        weight = 500,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_flowerpot.png',
        }
    },
    ['orgs_gasoline_can'] = {
        label = 'Orgs Gasoline Can',
        weight = 400,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_gasoline_can.png',
        }
    },
    ['orgs_gun_barrel'] = {
        label = 'Orgs Gun Barrel',
        weight = 300,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_gun_barrel.png',
        }
    },
    ['orgs_hand_protector'] = {
        label = 'Orgs Hand Protector',
        weight = 80,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_hand_protector.png',
        }
    },
    ['orgs_handle'] = {
        label = 'Orgs Handle',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_handle.png',
        }
    },
    ['orgs_industrial_plastic'] = {
        label = 'Orgs Industrial Plastic',
        weight = 120,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_industrial_plastic.png',
        }
    },
    ['orgs_industrial_rubber'] = {
        label = 'Orgs Industrial Rubber',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_industrial_rubber.png',
        }
    },
    ['orgs_lightgreen_weed_bud_dried'] = {
        label = 'Orgs Lightgreen Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_lightgreen_weed_bud_dried.png',
        }
    },
    ['orgs_locking_mechanism'] = {
        label = 'Orgs Locking Mechanism',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_locking_mechanism.png',
        }
    },
    ['orgs_mechanism_kit'] = {
        label = 'Orgs Mechanism Kit',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_mechanism_kit.png',
        }
    },
    ['orgs_metal_casing'] = {
        label = 'Orgs Metal Casing',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_metal_casing.png',
        }
    },
    ['orgs_metal_tube'] = {
        label = 'Orgs Metal Tube',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_metal_tube.png',
        }
    },
    ['orgs_optical_crystal'] = {
        label = 'Orgs Optical Crystal',
        weight = 80,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_optical_crystal.png',
        }
    },
    ['orgs_pink_weed_bud_dried'] = {
        label = 'Orgs Pink Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_pink_weed_bud_dried.png',
        }
    },
    ['orgs_precision_cannon'] = {
        label = 'Orgs Precision Cannon',
        weight = 400,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_precision_cannon.png',
        }
    },
    ['orgs_precision_chargere'] = {
        label = 'Orgs Precision Chargere',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_precision_chargere.png',
        }
    },
    ['orgs_precision_handguard'] = {
        label = 'Orgs Precision Handguard',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_precision_handguard.png',
        }
    },
    ['orgs_precision_stock'] = {
        label = 'Orgs Precision Stock',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_precision_stock.png',
        }
    },
    ['orgs_pruning_shears'] = {
        label = 'Orgs Pruning Shears',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_pruning_shears.png',
        }
    },
    ['orgs_purple_weed_bud_dried'] = {
        label = 'Orgs Purple Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_purple_weed_bud_dried.png',
        }
    },
    ['orgs_recovery_dock'] = {
        label = 'Orgs Recovery Dock',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_recovery_dock.png',
        }
    },
    ['orgs_refined_steel'] = {
        label = 'Orgs Refined Steel',
        weight = 300,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_refined_steel.png',
        }
    },
    ['orgs_reinforced_casing'] = {
        label = 'Orgs Reinforced Casing',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_reinforced_casing.png',
        }
    },
    ['orgs_reinforced_sheet'] = {
        label = 'Orgs Reinforced Sheet',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_reinforced_sheet.png',
        }
    },
    ['orgs_reinforced_spring'] = {
        label = 'Orgs Reinforced Spring',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_reinforced_spring.png',
        }
    },
    ['orgs_retractable_stockt'] = {
        label = 'Orgs Retractable Stockt',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_retractable_stockt.png',
        }
    },
    ['orgs_rifle_magazine'] = {
        label = 'Orgs Rifle Magazine',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_rifle_magazine.png',
        }
    },
    ['orgs_safety_pin'] = {
        label = 'Orgs Safety Pin',
        weight = 30,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_safety_pin.png',
        }
    },
    ['orgs_sand'] = {
        label = 'Orgs Sand',
        weight = 300,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_sand.png',
        }
    },
    ['orgs_screws'] = {
        label = 'Orgs Screws',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_screws.png',
        }
    },
    ['orgs_sealed_circuit'] = {
        label = 'Orgs Sealed Circuit',
        weight = 100,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_sealed_circuit.png',
        }
    },
    ['orgs_seeds_weed_blue'] = {
        label = 'Orgs Seeds Weed Blue',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_blue.png',
        }
    },
    ['orgs_seeds_weed_common'] = {
        label = 'Orgs Seeds Weed Common',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_common.png',
        }
    },
    ['orgs_seeds_weed_lightgreen'] = {
        label = 'Orgs Seeds Weed Lightgreen',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_lightgreen.png',
        }
    },
    ['orgs_seeds_weed_pink'] = {
        label = 'Orgs Seeds Weed Pink',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_pink.png',
        }
    },
    ['orgs_seeds_weed_purple'] = {
        label = 'Orgs Seeds Weed Purple',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_purple.png',
        }
    },
    ['orgs_seeds_weed_yellow'] = {
        label = 'Orgs Seeds Weed Yellow',
        weight = 10,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_seeds_weed_yellow.png',
        }
    },
    ['orgs_sheet_steel'] = {
        label = 'Orgs Sheet Steel',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_sheet_steel.png',
        }
    },
    ['orgs_shotgun_barrel'] = {
        label = 'Orgs Shotgun Barrel',
        weight = 350,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_shotgun_barrel.png',
        }
    },
    ['orgs_shotgun_stock'] = {
        label = 'Orgs Shotgun Stock',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_shotgun_stock.png',
        }
    },
    ['orgs_sodium_bicarbonate'] = {
        label = 'Orgs Sodium Bicarbonate',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_sodium_bicarbonate.png',
        }
    },
    ['orgs_springs'] = {
        label = 'Orgs Springs',
        weight = 80,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_springs.png',
        }
    },
    ['orgs_steel_blade'] = {
        label = 'Orgs Steel Blade',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_steel_blade.png',
        }
    },
    ['orgs_submachine_gun_magazine'] = {
        label = 'Orgs Submachine Gun Magazine',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_submachine_gun_magazine.png',
        }
    },
    ['orgs_synthetic_wick'] = {
        label = 'Orgs Synthetic Wick',
        weight = 50,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_synthetic_wick.png',
        }
    },
    ['orgs_tactical_charge'] = {
        label = 'Orgs Tactical Charge',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_tactical_charge.png',
        }
    },
    ['orgs_tactical_stock'] = {
        label = 'Orgs Tactical Stock',
        weight = 250,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_tactical_stock.png',
        }
    },
    ['orgs_tactical_support'] = {
        label = 'Orgs Tactical Support',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_tactical_support.png',
        }
    },
    ['orgs_trigger_mechanism'] = {
        label = 'Orgs Trigger Mechanism',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_trigger_mechanism.png',
        }
    },
    ['orgs_water_jug'] = {
        label = 'Orgs Water Jug',
        weight = 500,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_water_jug.png',
        }
    },
    ['orgs_watering_can'] = {
        label = 'Orgs Watering Can',
        weight = 400,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_watering_can.png',
        }
    },
    ['orgs_watering_can_empty'] = {
        label = 'Orgs Watering Can Empty',
        weight = 200,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_watering_can_empty.png',
        }
    },
    ['orgs_weed_rack'] = {
        label = 'Orgs Weed Rack',
        weight = 1000,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_weed_rack.png',
        }
    },
    ['orgs_wooden_table'] = {
        label = 'Orgs Wooden Table',
        weight = 150,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_wooden_table.png',
        }
    },
    ['orgs_yellowe_weed_bud_dried'] = {
        label = 'Orgs Yellowe Weed Bud Dried',
        weight = 40,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'orgs_yellowe_weed_bud_dried.png',
        }
    },
    ['tablet_ilegal'] = {
        label = 'Tablet Ilegal',
        weight = 500,
        stack = true,
        close = true,
        description = '',
        client = {
            image = 'tablet_ilegal.png',
        }
    },
}

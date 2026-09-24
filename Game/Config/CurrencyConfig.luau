-- CurrencyConfig (VIDK SMCurrency)
-- SoftCurrency is the game's Candy. HardCurrency is unused for now (reserved).
return {
    HardCurrency = {
        Name = "Tokens",
        Symbol = "◆",
        DefaultAmount = 0,
    },
    SoftCurrency = {
        Name = "Candy",
        Symbol = "🍬",
        DefaultAmount = 100, -- enough for a first consumable so the shop makes sense on day one
    },
}

-- Store sections, products and quests, ported from the web game.
-- Names are { English, Latvian, Russian }. Nutrients (n) are per 100 g / 100 ml.

local NutriScore = require(script.Parent.NutriScore)

local GameData = {}

-- Sections: positions in metres. Products face +Z (toward the shopper).
GameData.SECTIONS = {
	{ id = "drinks", e = "🥤", col = "#1f8fd1", x = -12, z = -15.6, len = 9, kind = "fridge", nm = { "Drinks", "Dzērieni", "Напитки" } },
	{ id = "dairy", e = "🥛", col = "#4a7fe0", x = 0, z = -15.6, len = 9, kind = "fridge", nm = { "Dairy & eggs", "Piens un olas", "Молочное и яйца" } },
	{ id = "meat", e = "🍗", col = "#d4463f", x = 12, z = -15.6, len = 9, kind = "fridge", nm = { "Meat & fish", "Gaļa un zivis", "Мясо и рыба" } },
	{ id = "bakery", e = "🥐", col = "#d58431", x = -9, z = -8, len = 9, kind = "shelf", nm = { "Bakery", "Maiznīca", "Пекарня" } },
	{ id = "pantry", e = "🍝", col = "#8a62d6", x = 9, z = -8, len = 9, kind = "shelf", nm = { "Pantry", "Bakaleja", "Бакалея" } },
	{ id = "breakfast", e = "🥣", col = "#e0a51d", x = -9, z = -1, len = 9, kind = "shelf", nm = { "Breakfast & spreads", "Brokastis un ziežamie", "Завтрак и пасты" } },
	{ id = "snacks", e = "🍿", col = "#e2477f", x = 9, z = -1, len = 9, kind = "shelf", nm = { "Snacks & sweets", "Uzkodas un saldumi", "Снеки и сладости" } },
	{ id = "produce", e = "🍎", col = "#2f9e54", x = 9, z = 7, len = 13.2, kind = "crates", nm = { "Fruit & veg", "Augļi un dārzeņi", "Фрукты и овощи" } },
}

-- Generic products (no brands).
GameData.PRODUCTS = {
	-- produce
	{ id = "apple", s = "produce", e = "🍎", sh = "crate", c = "#d93a2b", nm = { "Apples", "Āboli", "Яблоки" }, n = { kj = 218, sug = 10.4, fib = 2.4, pro = 0.3, fvl = 100 }, tg = { "fruit" } },
	{ id = "banana", s = "produce", e = "🍌", sh = "crate", c = "#f2d02f", nm = { "Bananas", "Banāni", "Бананы" }, n = { kj = 371, sug = 12.2, fib = 2.6, pro = 1.1, fvl = 100 }, tg = { "fruit" } },
	{ id = "grapes", s = "produce", e = "🍇", sh = "crate", c = "#7b3fa0", nm = { "Grapes", "Vīnogas", "Виноград" }, n = { kj = 288, sug = 16, fib = 0.9, pro = 0.7, fvl = 100 }, tg = { "fruit" } },
	{ id = "strawberry", s = "produce", e = "🍓", sh = "crate", c = "#e8303f", nm = { "Strawberries", "Zemenes", "Клубника" }, n = { kj = 136, sug = 4.9, fib = 2, pro = 0.7, fvl = 100 }, tg = { "fruit" } },
	{ id = "avocado", s = "produce", e = "🥑", sh = "crate", c = "#4f7a2a", nm = { "Avocados", "Avokado", "Авокадо" }, n = { kj = 670, sug = 0.7, sf = 2.1, fib = 6.7, pro = 2, fvl = 100 }, tg = { "fruit" } },
	{ id = "carrot", s = "produce", e = "🥕", sh = "crate", c = "#f07c1c", nm = { "Carrots", "Burkāni", "Морковь" }, n = { kj = 173, sug = 4.7, fib = 2.8, pro = 0.9, fvl = 100 }, tg = { "veg" } },
	{ id = "broccoli", s = "produce", e = "🥦", sh = "crate", c = "#3d8b3d", nm = { "Broccoli", "Brokoļi", "Брокколи" }, n = { kj = 141, sug = 1.7, fib = 2.6, pro = 2.8, fvl = 100 }, tg = { "veg" } },
	{ id = "tomato", s = "produce", e = "🍅", sh = "crate", c = "#e2412f", nm = { "Tomatoes", "Tomāti", "Помидоры" }, n = { kj = 74, sug = 2.6, fib = 1.2, pro = 0.9, fvl = 100 }, tg = { "veg" } },
	{ id = "cucumber", s = "produce", e = "🥒", sh = "crate", c = "#3f9a45", nm = { "Cucumbers", "Gurķi", "Огурцы" }, n = { kj = 64, sug = 1.7, fib = 0.5, pro = 0.7, fvl = 100 }, tg = { "veg" } },
	{ id = "onion", s = "produce", e = "🧅", sh = "crate", c = "#c9955a", nm = { "Onions", "Sīpoli", "Лук" }, n = { kj = 166, sug = 4.2, fib = 1.7, pro = 1.1, fvl = 100 }, tg = { "veg" } },
	{ id = "potato", s = "produce", e = "🥔", sh = "crate", c = "#b9894f", nm = { "Potatoes", "Kartupeļi", "Картофель" }, n = { kj = 322, sug = 0.8, fib = 2.2, pro = 2 }, tg = { "side" } },
	-- bakery
	{ id = "rye", s = "bakery", e = "🍞", sh = "loaf", c = "#4a2c1a", nm = { "Dark rye bread", "Rupjmaize", "Тёмный ржаной хлеб" }, n = { kj = 900, sug = 4, sf = 0.3, salt = 0.9, fib = 8, pro = 7 }, tg = { "bread" } },
	{ id = "toast", s = "bakery", e = "🍞", sh = "loaf", c = "#f1e2c2", nm = { "White toast bread", "Baltmaize tostiem", "Белый хлеб для тостов" }, n = { kj = 1100, sug = 5, sf = 0.5, salt = 1.2, fib = 2.5, pro = 8 }, tg = { "bread" } },
	{ id = "bun", s = "bakery", e = "🥯", sh = "loaf", c = "#c08a4a", nm = { "Wholegrain buns", "Pilngraudu maizītes", "Цельнозерновые булочки" }, n = { kj = 1050, sug = 5, sf = 0.4, salt = 1, fib = 4.5, pro = 10 }, tg = { "bread" } },
	{ id = "croissant", s = "bakery", e = "🥐", sh = "bag", c = "#e9b25a", nm = { "Butter croissants", "Sviesta kruasāni", "Круассаны" }, n = { kj = 1700, sug = 10, sf = 14, salt = 1, fib = 2, pro = 8 }, tg = { "pastry" } },
	{ id = "donut", s = "bakery", e = "🍩", sh = "bag", c = "#f29bc0", nm = { "Glazed doughnuts", "Glazēti virtuļi", "Пончики в глазури" }, n = { kj = 1800, sug = 22, sf = 9, salt = 0.8, fib = 1.5, pro = 5 }, tg = { "sweet" } },
	{ id = "wrapW", s = "bakery", e = "🌯", sh = "bag", c = "#f5ecd7", nm = { "White tortilla wraps", "Baltās tortiljas", "Белые тортильи" }, n = { kj = 1300, sug = 3, sf = 2.5, salt = 1.3, fib = 2.5, pro = 8 }, tg = { "bread" } },
	{ id = "wrapG", s = "bakery", e = "🌯", sh = "bag", c = "#b98a55", nm = { "Wholegrain wraps", "Pilngraudu tortiljas", "Цельнозерновые тортильи" }, n = { kj = 1250, sug = 2.5, sf = 1, salt = 1, fib = 7, pro = 9 }, tg = { "bread" } },
	-- dairy
	{ id = "milk", s = "dairy", e = "🥛", sh = "carton", c = "#ffffff", cat = "drink", nm = { "Milk 1.5%", "Piens 1,5%", "Молоко 1,5%" }, n = { kj = 195, sug = 4.8, sf = 1, salt = 0.1, pro = 3.4 }, tg = { "milk" } },
	{ id = "kefir", s = "dairy", e = "🥛", sh = "carton", c = "#cfe0f7", cat = "drink", nm = { "Kefir", "Kefīrs", "Кефир" }, n = { kj = 170, sug = 4, sf = 1, salt = 0.1, pro = 3.2 }, tg = { "milk" } },
	{ id = "yogurt", s = "dairy", e = "🥣", sh = "jar", c = "#ffffff", nm = { "Plain yogurt", "Dabīgais jogurts", "Натуральный йогурт" }, n = { kj = 260, sug = 4, sf = 1.2, salt = 0.1, pro = 4.5 }, tg = { "yogurt" } },
	{ id = "yogurtS", s = "dairy", e = "🍓", sh = "jar", c = "#f6b4c4", nm = { "Strawberry yogurt", "Zemeņu jogurts", "Клубничный йогурт" }, n = { kj = 400, sug = 12, sf = 2, salt = 0.1, pro = 3.5, fvl = 10 }, tg = { "yogurt", "dessert" } },
	{ id = "quark", s = "dairy", e = "🥣", sh = "tray", c = "#ffffff", nm = { "Quark (biezpiens)", "Biezpiens", "Творог" }, n = { kj = 420, sug = 3, sf = 3, salt = 0.1, pro = 16 }, tg = { "quark" } },
	{ id = "pudding", s = "dairy", e = "🍮", sh = "jar", c = "#6b3e26", nm = { "Chocolate pudding", "Šokolādes pudiņš", "Шоколадный пудинг" }, n = { kj = 520, sug = 18, sf = 3.5, salt = 0.2, pro = 3 }, tg = { "dessert" } },
	{ id = "gouda", s = "dairy", e = "🧀", sh = "tray", c = "#f4c430", cat = "cheese", nm = { "Gouda cheese", "Gouda siers", "Сыр гауда" }, n = { kj = 1500, sf = 17, salt = 1.6, pro = 25 }, tg = { "cheese" } },
	{ id = "mozz", s = "dairy", e = "🧀", sh = "tray", c = "#fbf6e9", cat = "cheese", nm = { "Mozzarella", "Mocarella", "Моцарелла" }, n = { kj = 1050, sf = 11, salt = 0.5, pro = 18 }, tg = { "cheese" } },
	{ id = "mozzL", s = "dairy", e = "🧀", sh = "tray", c = "#d8e6fb", cat = "cheese", nm = { "Light mozzarella", "Vieglā mocarella", "Моцарелла лайт" }, n = { kj = 700, sf = 6, salt = 0.4, pro = 19 }, tg = { "cheese" } },
	{ id = "butter", s = "dairy", e = "🧈", sh = "tray", c = "#f7e27a", cat = "fat", nm = { "Butter", "Sviests", "Сливочное масло" }, n = { fat = 82, sf = 51, sug = 0.6 }, tg = { "fat" } },
	{ id = "eggs", s = "dairy", e = "🥚", sh = "tray", c = "#e9d7b5", nm = { "Eggs", "Olas", "Яйца" }, n = { kj = 600, sug = 0.4, sf = 3.1, salt = 0.35, pro = 12.6 }, tg = { "egg", "protein" } },
	-- meat & fish
	{ id = "chicken", s = "meat", e = "🍗", sh = "tray", c = "#f2b8a0", nm = { "Chicken fillet", "Vistas fileja", "Куриное филе" }, n = { kj = 460, sf = 0.3, salt = 0.2, pro = 23 }, tg = { "protein" } },
	{ id = "salmon", s = "meat", e = "🐟", sh = "tray", c = "#f08a5d", nm = { "Salmon fillet", "Laša fileja", "Филе лосося" }, n = { kj = 870, sf = 2.3, salt = 0.1, pro = 20 }, tg = { "protein", "fish" } },
	{ id = "tuna", s = "meat", e = "🐟", sh = "can", c = "#5b8fc9", nm = { "Tuna in water", "Tuncis savā sulā", "Тунец в собственном соку" }, n = { kj = 480, sf = 0.3, salt = 0.9, pro = 25 }, tg = { "protein", "fish" } },
	{ id = "ham", s = "meat", e = "🍖", sh = "tray", c = "#e88a9a", nm = { "Smoked ham slices", "Kūpināta šķiņķa šķēles", "Копчёная ветчина" }, n = { kj = 480, sug = 1, sf = 1.2, salt = 2.5, pro = 19 }, tg = { "coldcut", "protein" } },
	{ id = "turkey", s = "meat", e = "🦃", sh = "tray", c = "#f3d1b3", nm = { "Turkey slices, less salt", "Tītara šķēles, mazāk sāls", "Индейка в нарезке, меньше соли" }, n = { kj = 430, sug = 1, sf = 0.6, salt = 1.6, pro = 20 }, tg = { "coldcut" } },
	{ id = "sausage", s = "meat", e = "🌭", sh = "tray", c = "#d0654a", nm = { "Frankfurters", "Cīsiņi", "Сосиски" }, n = { kj = 1200, sug = 1.5, sf = 9, salt = 2, pro = 12 }, tg = { "protein" } },
	-- pantry
	{ id = "pastaG", s = "pantry", e = "🍝", sh = "box", c = "#8a5a2b", nm = { "Wholegrain pasta", "Pilngraudu makaroni", "Цельнозерновые макароны" }, n = { kj = 1450, sug = 3, sf = 0.5, fib = 8, pro = 13 }, tg = { "side" } },
	{ id = "pastaW", s = "pantry", e = "🍝", sh = "box", c = "#f3d36b", nm = { "White pasta", "Makaroni", "Макароны" }, n = { kj = 1500, sug = 3.5, sf = 0.3, fib = 3, pro = 12 }, tg = { "side" } },
	{ id = "rice", s = "pantry", e = "🍚", sh = "bag", c = "#c79a6b", nm = { "Brown rice", "Brūnie rīsi", "Бурый рис" }, n = { kj = 1500, sug = 0.7, sf = 0.5, fib = 3.5, pro = 7.5 }, tg = { "side" } },
	{ id = "passata", s = "pantry", e = "🍅", sh = "bottle", c = "#c8281e", nm = { "Tomato passata", "Tomātu pasata", "Томатная пассата" }, n = { kj = 130, sug = 4, salt = 0.4, fib = 1.4, pro = 1.4, fvl = 90 }, tg = { "sauce" } },
	{ id = "ketchup", s = "pantry", e = "🥫", sh = "bottle", c = "#d1241c", nm = { "Ketchup", "Kečups", "Кетчуп" }, n = { kj = 430, sug = 22, salt = 1.8, fib = 0.8, pro = 1.2, fvl = 60 }, tg = { "sauce" } },
	{ id = "chickpeas", s = "pantry", e = "🥫", sh = "can", c = "#d9b26f", nm = { "Chickpeas, tinned", "Aunazirņi, konservēti", "Нут консервированный" }, n = { kj = 470, sug = 0.5, salt = 0.6, fib = 6, pro = 7, fvl = 100 }, tg = { "protein" } },
	{ id = "flourG", s = "pantry", e = "🌾", sh = "bag", c = "#b88a5a", nm = { "Wholegrain flour", "Pilngraudu milti", "Цельнозерновая мука" }, n = { kj = 1400, sug = 1, sf = 0.3, fib = 10, pro = 12 }, tg = { "flour" } },
	{ id = "flourW", s = "pantry", e = "🌾", sh = "bag", c = "#f4f4f4", nm = { "White flour", "Kviešu milti", "Пшеничная мука" }, n = { kj = 1450, sug = 0.3, sf = 0.2, fib = 3, pro = 10 }, tg = { "flour" } },
	{ id = "oil", s = "pantry", e = "🌼", sh = "bottle", c = "#f2d43a", cat = "fat", nm = { "Rapeseed oil", "Rapšu eļļa", "Рапсовое масло" }, n = { fat = 100, sf = 7 }, tg = { "fat" } },
	{ id = "doughW", s = "pantry", e = "🍕", sh = "bag", c = "#f5e6c8", nm = { "Pizza dough", "Picas mīkla", "Тесто для пиццы" }, n = { kj = 1100, sug = 2, sf = 1.5, salt = 1.4, fib = 2.5, pro = 7.5 }, tg = { "dough" } },
	{ id = "doughG", s = "pantry", e = "🍕", sh = "bag", c = "#c49a6c", nm = { "Wholegrain pizza dough", "Pilngraudu picas mīkla", "Цельнозерновое тесто для пиццы" }, n = { kj = 1050, sug = 2, sf = 0.5, salt = 1, fib = 6, pro = 9 }, tg = { "dough" } },
	-- breakfast & spreads
	{ id = "oats", s = "breakfast", e = "🥣", sh = "box", c = "#d9c08a", nm = { "Oat flakes", "Auzu pārslas", "Овсяные хлопья" }, n = { kj = 1550, sug = 1, sf = 1.3, fib = 10, pro = 13 }, tg = { "cereal" } },
	{ id = "muesli", s = "breakfast", e = "🥣", sh = "box", c = "#9cc46b", nm = { "Muesli, no added sugar", "Musli bez pievienota cukura", "Мюсли без добавленного сахара" }, n = { kj = 1500, sug = 12, sf = 1.5, salt = 0.05, fib = 9, pro = 10, fvl = 20 }, tg = { "cereal" } },
	{ id = "chocoballs", s = "breakfast", e = "🥣", sh = "box", c = "#6a3b1f", nm = { "Chocolate cereal balls", "Šokolādes pārslu bumbiņas", "Шоколадные шарики" }, n = { kj = 1650, sug = 30, sf = 2, salt = 0.5, fib = 5, pro = 8 }, tg = { "cereal" } },
	{ id = "frosted", s = "breakfast", e = "🥣", sh = "box", c = "#3a7bd5", nm = { "Frosted corn flakes", "Glazētas kukurūzas pārslas", "Глазированные кукурузные хлопья" }, n = { kj = 1600, sug = 35, sf = 0.2, salt = 0.8, fib = 2, pro = 7 }, tg = { "cereal" } },
	{ id = "honey", s = "breakfast", e = "🍯", sh = "jar", c = "#e0a21b", nm = { "Honey", "Medus", "Мёд" }, n = { kj = 1270, sug = 82 }, tg = { "sweet" } },
	{ id = "jam", s = "breakfast", e = "🍓", sh = "jar", c = "#b5172f", nm = { "Strawberry jam", "Zemeņu ievārījums", "Клубничное варенье" }, n = { kj = 1000, sug = 50, fvl = 40 }, tg = { "sweet" } },
	{ id = "chocspread", s = "breakfast", e = "🍫", sh = "jar", c = "#5a3420", nm = { "Chocolate spread", "Šokolādes krēms", "Шоколадная паста" }, n = { kj = 2250, sug = 56, sf = 10.6, salt = 0.1, fib = 3.4, pro = 6 }, tg = { "sweet" } },
	{ id = "pb", s = "breakfast", e = "🥜", sh = "jar", c = "#c58a46", cat = "fat", nm = { "Peanut butter", "Zemesriekstu sviests", "Арахисовая паста" }, n = { fat = 50, sf = 10, sug = 5, salt = 1, fib = 6, pro = 25, fvl = 100 }, tg = { "spread" } },
	-- drinks
	{ id = "water", s = "drinks", e = "💧", sh = "bottle", c = "#9fd8f5", cat = "water", nm = { "Still water", "Negāzēts ūdens", "Вода без газа" }, tg = { "drink" } },
	{ id = "sparkling", s = "drinks", e = "💦", sh = "bottle", c = "#5fb4e0", cat = "water", nm = { "Sparkling water", "Gāzēts ūdens", "Газированная вода" }, tg = { "drink" } },
	{ id = "birch", s = "drinks", e = "🌳", sh = "bottle", c = "#e7f2d0", cat = "drink", nm = { "Birch sap", "Bērzu sula", "Берёзовый сок" }, n = { kj = 25, sug = 0.9 }, tg = { "drink" } },
	{ id = "oj", s = "drinks", e = "🍊", sh = "carton", c = "#f6a21a", cat = "drink", nm = { "Orange juice 100%", "Apelsīnu sula 100%", "Апельсиновый сок 100%" }, n = { kj = 190, sug = 8.4, fib = 0.2, pro = 0.7, fvl = 100 }, tg = { "drink" } },
	{ id = "smoothie", s = "drinks", e = "🍹", sh = "bottle", c = "#e95f8b", cat = "drink", nm = { "Fruit smoothie", "Augļu smūtijs", "Фруктовый смузи" }, n = { kj = 250, sug = 11, fib = 1.5, pro = 0.8, fvl = 100 }, tg = { "drink" } },
	{ id = "kvass", s = "drinks", e = "🌾", sh = "bottle", c = "#7a4a1d", cat = "drink", nm = { "Kvass", "Kvass", "Квас" }, n = { kj = 130, sug = 6 }, tg = { "drink" } },
	{ id = "icedtea", s = "drinks", e = "🍑", sh = "bottle", c = "#f0a35e", cat = "drink", nm = { "Peach iced tea", "Persiku ledus tēja", "Холодный чай с персиком" }, n = { kj = 85, sug = 5 }, tg = { "drink" } },
	{ id = "chocmilk", s = "drinks", e = "🍫", sh = "carton", c = "#8b5a3c", cat = "drink", nm = { "Chocolate milk", "Šokolādes piens", "Шоколадное молоко" }, n = { kj = 300, sug = 10, sf = 1, salt = 0.1, pro = 3.2 }, tg = { "drink" } },
	{ id = "cola", s = "drinks", e = "🥤", sh = "bottle", c = "#8b1e1e", cat = "drink", nm = { "Cola", "Kola", "Кола" }, n = { kj = 180, sug = 10.6 }, tg = { "drink" } },
	{ id = "colazero", s = "drinks", e = "🥤", sh = "bottle", c = "#2a2a2a", cat = "drink", nm = { "Cola, zero sugar", "Kola bez cukura", "Кола без сахара" }, n = { kj = 1, sweet = true }, tg = { "drink" } },
	-- snacks & sweets
	{ id = "nuts", s = "snacks", e = "🌰", sh = "bag", c = "#a8743f", cat = "fat", nm = { "Mixed nuts, unsalted", "Riekstu maisījums, nesālīts", "Ореховая смесь без соли" }, n = { fat = 54, sf = 6, sug = 4, fib = 9, pro = 20, fvl = 100 }, tg = { "snack" } },
	{ id = "popcorn", s = "snacks", e = "🍿", sh = "bag", c = "#e94b3c", nm = { "Popcorn, lightly salted", "Popkorns, viegli sālīts", "Попкорн, слегка солёный" }, n = { kj = 1600, sug = 0.5, sf = 1.5, salt = 0.5, fib = 13, pro = 12 }, tg = { "snack" } },
	{ id = "ricecakes", s = "snacks", e = "🍘", sh = "bag", c = "#efe2c4", nm = { "Rice cakes", "Rīsu galetes", "Рисовые хлебцы" }, n = { kj = 1600, sug = 0.5, salt = 0.3, fib = 4, pro = 8 }, tg = { "snack" } },
	{ id = "peanuts", s = "snacks", e = "🥜", sh = "bag", c = "#d99a4e", cat = "fat", nm = { "Salted peanuts", "Sālīti zemesrieksti", "Солёный арахис" }, n = { fat = 50, sf = 7, sug = 5, salt = 1.5, fib = 8, pro = 25, fvl = 100 }, tg = { "snack" } },
	{ id = "apricots", s = "snacks", e = "🍑", sh = "bag", c = "#f39a3d", nm = { "Dried apricots", "Žāvētas aprikozes", "Курага" }, n = { kj = 1000, sug = 53, fib = 7, pro = 3.4, fvl = 100 }, tg = { "snack", "dessert" } },
	{ id = "chips", s = "snacks", e = "🍟", sh = "bag", c = "#f2c12e", nm = { "Potato crisps", "Kartupeļu čipsi", "Картофельные чипсы" }, n = { kj = 2200, sug = 0.5, sf = 3, salt = 1.4, fib = 4.5, pro = 6 }, tg = { "snack" } },
	{ id = "gummies", s = "snacks", e = "🐻", sh = "bag", c = "#ff6fa5", nm = { "Gummy bears", "Želejas lācīši", "Мармеладные мишки" }, n = { kj = 1450, sug = 46, pro = 6 }, tg = { "snack", "sweet" } },
	{ id = "icecream", s = "snacks", e = "🍦", sh = "box", c = "#f7e7b6", nm = { "Vanilla ice cream", "Vaniļas saldējums", "Ванильное мороженое" }, n = { kj = 900, sug = 22, sf = 7, salt = 0.1, pro = 3.5 }, tg = { "dessert", "sweet" } },
	{ id = "cookies", s = "snacks", e = "🍪", sh = "box", c = "#c47a3a", nm = { "Chocolate chip cookies", "Cepumi ar šokolādi", "Печенье с шоколадом" }, n = { kj = 2000, sug = 30, sf = 10, salt = 0.7, fib = 2, pro = 6 }, tg = { "snack", "sweet" } },
	{ id = "chocolate", s = "snacks", e = "🍫", sh = "box", c = "#6b3a1e", nm = { "Milk chocolate", "Piena šokolāde", "Молочный шоколад" }, n = { kj = 2250, sug = 55, sf = 18, salt = 0.2, fib = 2, pro = 7 }, tg = { "snack", "sweet" } },
}

-- Quests: slots name the tags a product must have and the worst letter allowed.
GameData.QUESTS = {
	{
		id = "salad", e = "🥗", title = { "Rainbow fruit salad", "Varavīksnes augļu salāti", "Радужный фруктовый салат" },
		slots = {
			{ tags = { "fruit" }, max = "A", count = 3, e = "🍎", lbl = { "Fruit", "Auglis", "Фрукт" } },
			{ tags = { "yogurt", "quark" }, max = "B", e = "🥣", lbl = { "Yogurt or quark", "Jogurts vai biezpiens", "Йогурт или творог" } },
		},
	},
	{
		id = "sandwich", e = "🥪", title = { "Super sandwiches", "Superbuterbrodi", "Супербутерброды" },
		slots = {
			{ tags = { "bread" }, max = "B", e = "🍞", lbl = { "Bread", "Maize", "Хлеб" } },
			{ tags = { "coldcut", "fish", "egg" }, max = "B", e = "🐟", lbl = { "Filling: fish, egg or slices", "Pildījums: zivs, ola vai šķēles", "Начинка: рыба, яйцо или нарезка" } },
			{ tags = { "veg" }, max = "A", count = 2, e = "🥒", lbl = { "Vegetable", "Dārzenis", "Овощ" } },
		},
	},
	{
		id = "breakfast", e = "🍳", title = { "Family breakfast", "Ģimenes brokastis", "Семейный завтрак" },
		slots = {
			{ tags = { "cereal" }, max = "A", e = "🥣", lbl = { "Cereal", "Pārslas", "Хлопья" } },
			{ tags = { "milk", "yogurt", "quark" }, max = "B", e = "🥛", lbl = { "Milk, kefir or yogurt", "Piens, kefīrs vai jogurts", "Молоко, кефир или йогурт" } },
			{ tags = { "fruit" }, max = "A", e = "🍌", lbl = { "Fruit", "Auglis", "Фрукт" } },
			{ tags = { "drink" }, max = "B", e = "💧", lbl = { "Drink", "Dzēriens", "Напиток" } },
		},
	},
	{
		id = "pizza", e = "🍕", title = { "Pizza night", "Picas vakars", "Вечер пиццы" },
		slots = {
			{ tags = { "dough" }, max = "B", e = "🍕", lbl = { "Pizza dough", "Picas mīkla", "Тесто для пиццы" } },
			{ tags = { "sauce" }, max = "A", e = "🍅", lbl = { "Sauce", "Mērce", "Соус" } },
			{ tags = { "cheese" }, max = "C", e = "🧀", lbl = { "Cheese", "Siers", "Сыр" } },
			{ tags = { "veg" }, max = "A", count = 2, e = "🥦", lbl = { "Topping vegetable", "Dārzenis piedevām", "Овощ для начинки" } },
			{ tags = { "sweet", "dessert" }, max = "E", treat = true, e = "🍦", lbl = { "One treat", "Viens gardums", "Одно лакомство" } },
		},
	},
	{
		id = "party", e = "🎉", title = { "Birthday party", "Dzimšanas dienas ballīte", "День рождения" },
		slots = {
			{ tags = { "drink" }, max = "B", count = 2, e = "💧", lbl = { "Drink", "Dzēriens", "Напиток" } },
			{ tags = { "snack" }, max = "B", count = 2, e = "🍿", lbl = { "Snack", "Uzkoda", "Снек" } },
			{ tags = { "fruit" }, max = "A", e = "🍇", lbl = { "Fruit", "Auglis", "Фрукт" } },
			{ tags = { "sweet", "dessert" }, max = "E", treat = true, e = "🍪", lbl = { "One treat", "Viens gardums", "Одно лакомство" } },
		},
	},
	{
		id = "dinner", e = "🍽️", title = { "Grand family dinner", "Lielās ģimenes vakariņas", "Большой семейный ужин" },
		slots = {
			{ tags = { "protein" }, max = "A", e = "🍗", lbl = { "Protein: meat, fish, eggs or beans", "Olbaltumvielas: gaļa, zivs, olas vai pākšaugi", "Белок: мясо, рыба, яйца или бобовые" } },
			{ tags = { "side" }, max = "A", e = "🍚", lbl = { "Side: pasta, rice or potatoes", "Piedeva: makaroni, rīsi vai kartupeļi", "Гарнир: макароны, рис или картофель" } },
			{ tags = { "veg" }, max = "A", count = 2, e = "🥕", lbl = { "Vegetable", "Dārzenis", "Овощ" } },
			{ tags = { "fat" }, max = "B", e = "🌼", lbl = { "Oil or fat", "Eļļa vai tauki", "Масло или жир" } },
			{ tags = { "drink" }, max = "B", e = "💧", lbl = { "Drink", "Dzēriens", "Напиток" } },
			{ tags = { "dessert" }, max = "C", e = "🍮", lbl = { "Dessert", "Deserts", "Десерт" } },
		},
	},
}

GameData.PRODUCT_BY_ID = {}
GameData.SECTION_BY_ID = {}

for _, p in GameData.PRODUCTS do
	p.ns = NutriScore.compute(p)
	GameData.PRODUCT_BY_ID[p.id] = p
end
for _, s in GameData.SECTIONS do
	GameData.SECTION_BY_ID[s.id] = s
end

-- Products of one section, in the order they stand on the shelf.
function GameData.productsIn(sectionId)
	local list = {}
	for _, p in GameData.PRODUCTS do
		if p.s == sectionId then
			table.insert(list, p)
		end
	end
	return list
end

return GameData

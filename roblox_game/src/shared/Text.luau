-- All words in the game, in English, Latvian and Russian, ported from the web game.
-- Only the control hints changed: Roblox uses WASD/thumbstick and the E key / touch button.

local Config = require(script.Parent.Config)

local Text = {}

local T = {
	en = {
		game = "Spike's Nutri Quest", spike = "Spike", market = "MARKET", kitchen = "Spike’s kitchen",
		tag = "Help Spike the porcupine chef shop for six home cooking projects, and learn to read the Nutri-Score letters from A to E.",
		play = "Play", cont = "Continue", newGame = "Start over", next = "Next ▸", go = "Let's go!",
		points = "Points", found = "Letters found", quest = "Quest", of = "of",
		orBetter = "{g} or better", onlyA = "A only", anyGrade = "any letter",
		look = "Look closer", talk = "Talk to Spike", talkReady = "Show Spike your basket",
		guessQ = "Guess the Nutri-Score!", guessHint = "Lots of sugar, salt or fat pushes the letter down. Fibre, protein and fruit or veg push it up.",
		per100g = "per 100 g", per100ml = "per 100 ml",
		energy = "Energy", sugar = "Sugars", satfat = "Saturated fat", salt = "Salt", fiber = "Fibre", protein = "Protein", fvl = "Fruit, veg & nuts", fat = "Fat", sweet = "Sweeteners", yes = "yes",
		badPts = "not-so-good", goodPts = "good", scoreW = "score",
		right = "Spot on! +10", close = "So close! +5", wrongG = "Nice try! It is a {g}.", seen = "You already know this one: {g}",
		why = "Biggest minus: {bad}. Biggest plus: {good}.", whyNoGood = "Biggest minus: {bad}. No plus points here.", whyNoBad = "No minus points at all!",
		water = "Water is the only drink that gets an A!",
		noteFat = "Oils, nuts and butter have special rules for fat.", noteCheese = "In cheese, protein always counts.", noteDrink = "Drinks have stricter rules than food.",
		noteProtein = "Protein does not count here: too many not-so-good points.",
		add = "Put in basket", back = "Put back", close2 = "Close",
		notNeeded = "That's not on today's list. Maybe next time!", full = "We already have enough of that. Look at what is still missing on the list!",
		tooLow = "{name} is a {g}. We need {need} or better. Look for a greener letter on the same shelf!",
		added = "Great pick! {name} ({g}) is in the basket. +20",
		dupe = "{name} is already in the basket. Try a different one!",
		basketDone = "Basket complete! Bring it to Spike at the kitchen.",
		hintOn = "Follow the stars ★ to the shelves you need!",
		more = "{n} more to find! I lit up the shelves you need with stars ★.",
		peek = "Let me peek in your basket…", yay = "Wonderful! Everything we need. You are a natural!",
		done = "Quest complete!", s1 = "Finished the list", s2 = "No wrong picks", s3 = "Good letter guesser", nextQ = "Next quest", finish = "Finish",
		finalT = "You are a Nutri-Master!", again = "Play again",
		finalText = "You finished all six quests with {s} of 18 stars and {p} points.",
		help = "How to play",
		h1 = "Walk with W A S D, the arrow keys or the thumbstick.",
		h2 = "Walk up to a product and press E, or tap its button, to look closer and guess its letter. You can also press the letter keys.",
		h3 = "Put the right products in your basket. The list shows which letter each one needs.",
		h4 = "Stuck? Press ★ (or H) or talk to Spike: the shelves you need light up.",
		hScale = "A (dark green) is the healthiest choice. E (red) is for small amounts now and then.",
		sound = "Sound", lang = "Language", hint = "Hint",
	},
	lv = {
		game = "Adatiņa Nutri misija", spike = "Adatiņš", market = "TIRGUS", kitchen = "Adatiņa virtuve",
		tag = "Palīdzi dzeloņcūkai pavāram Adatiņam iepirkties sešiem mājas ēdienu projektiem un iemācies lasīt Nutri-Score burtus no A līdz E.",
		play = "Spēlēt", cont = "Turpināt", newGame = "Sākt no jauna", next = "Tālāk ▸", go = "Aiziet!",
		points = "Punkti", found = "Atrasti burti", quest = "Misija", of = "no",
		orBetter = "{g} vai labāk", onlyA = "tikai A", anyGrade = "jebkurš burts",
		look = "Apskatīt", talk = "Runāt ar Adatiņu", talkReady = "Parādi Adatiņam grozu",
		guessQ = "Uzmini Nutri-Score!", guessHint = "Daudz cukura, sāls vai tauku burtu pasliktina. Šķiedrvielas, olbaltumvielas, augļi un dārzeņi to uzlabo.",
		per100g = "uz 100 g", per100ml = "uz 100 ml",
		energy = "Enerģija", sugar = "Cukuri", satfat = "Piesātinātie tauki", salt = "Sāls", fiber = "Šķiedrvielas", protein = "Olbaltumvielas", fvl = "Augļi, dārzeņi un rieksti", fat = "Tauki", sweet = "Saldinātāji", yes = "jā",
		badPts = "mazāk labie", goodPts = "labie", scoreW = "rezultāts",
		right = "Precīzi! +10", close = "Gandrīz! +5", wrongG = "Labs mēģinājums! Tas ir {g}.", seen = "Šo tu jau zini: {g}",
		why = "Lielākais mīnuss: {bad}. Lielākais pluss: {good}.", whyNoGood = "Lielākais mīnuss: {bad}. Plusu nav.", whyNoBad = "Nav neviena mīnusa punkta!",
		water = "Ūdens ir vienīgais dzēriens, kas saņem A!",
		noteFat = "Eļļām, riekstiem un sviestam taukiem ir īpaši noteikumi.", noteCheese = "Sieram olbaltumvielas skaitās vienmēr.", noteDrink = "Dzērieniem noteikumi ir stingrāki nekā ēdienam.",
		noteProtein = "Olbaltumvielas šeit neskaitās: par daudz mazāk labo punktu.",
		add = "Likt grozā", back = "Nolikt atpakaļ", close2 = "Aizvērt",
		notNeeded = "Tā šodien nav sarakstā. Varbūt nākamreiz!", full = "Tā mums jau pietiek. Paskaties, kas vēl trūkst sarakstā!",
		tooLow = "{name}: burts {g}. Mums vajag {need} vai labāk. Meklē zaļāku burtu tajā pašā plauktā!",
		added = "Lieliska izvēle! {name} ({g}) ir grozā. +20",
		dupe = "{name} jau ir grozā. Pamēģini ko citu!",
		basketDone = "Grozs pilns! Nes to Adatiņam uz virtuvi.",
		hintOn = "Seko zvaigznēm ★ līdz vajadzīgajiem plauktiem!",
		more = "Vēl jāatrod: {n}! Es iededzu zvaigznes ★ virs vajadzīgajiem plauktiem.",
		peek = "Paskatīšos tavā grozā…", yay = "Brīnišķīgi! Viss, kas vajadzīgs. Tev tas padodas!",
		done = "Misija paveikta!", s1 = "Saraksts izpildīts", s2 = "Bez kļūdām", s3 = "Labs burtu minētājs", nextQ = "Nākamā misija", finish = "Pabeigt",
		finalT = "Tu esi Nutri meistars!", again = "Spēlēt vēlreiz",
		finalText = "Tu pabeidzi visas sešas misijas ar {s} no 18 zvaigznēm un {p} punktiem.",
		help = "Kā spēlēt",
		h1 = "Staigā ar W A S D, bultiņām vai kursorsviru.",
		h2 = "Pieej pie produkta un nospied E vai pieskaries pogai, lai to apskatītu un uzminētu burtu. Var spiest arī burtu taustiņus.",
		h3 = "Liec grozā pareizos produktus. Sarakstā redzams, kāds burts katram vajadzīgs.",
		h4 = "Nezini, kur iet? Nospied ★ (vai H) vai runā ar Adatiņu: vajadzīgie plaukti iedegsies.",
		hScale = "A (tumši zaļš) ir veselīgākā izvēle. E (sarkans) ir mazām porcijām un reizēm.",
		sound = "Skaņa", lang = "Valoda", hint = "Padoms",
	},
	ru = {
		game = "Нутри-квест Колючкина", spike = "Колючкин", market = "МАРКЕТ", kitchen = "Кухня Колючкина",
		tag = "Помоги дикобразу-повару Колючкину сделать покупки для шести домашних блюд и научись читать буквы Nutri-Score от A до E.",
		play = "Играть", cont = "Продолжить", newGame = "Начать заново", next = "Дальше ▸", go = "Вперёд!",
		points = "Очки", found = "Найдено букв", quest = "Задание", of = "из",
		orBetter = "{g} или лучше", onlyA = "только A", anyGrade = "любая буква",
		look = "Рассмотреть", talk = "Поговорить с Колючкиным", talkReady = "Покажи Колючкину корзину",
		guessQ = "Угадай Nutri-Score!", guessHint = "Много сахара, соли или жира делают букву хуже. Клетчатка, белок, фрукты и овощи делают её лучше.",
		per100g = "на 100 г", per100ml = "на 100 мл",
		energy = "Энергия", sugar = "Сахара", satfat = "Насыщенные жиры", salt = "Соль", fiber = "Клетчатка", protein = "Белки", fvl = "Фрукты, овощи и орехи", fat = "Жиры", sweet = "Подсластители", yes = "да",
		badPts = "не очень полезные", goodPts = "полезные", scoreW = "итог",
		right = "В точку! +10", close = "Почти! +5", wrongG = "Хорошая попытка! Это {g}.", seen = "Эту букву ты уже знаешь: {g}",
		why = "Главный минус: {bad}. Главный плюс: {good}.", whyNoGood = "Главный минус: {bad}. Плюсов нет.", whyNoBad = "Ни одного минуса!",
		water = "Вода — единственный напиток с буквой A!",
		noteFat = "Для масел, орехов и сливочного масла особые правила по жирам.", noteCheese = "У сыра белок считается всегда.", noteDrink = "Для напитков правила строже, чем для еды.",
		noteProtein = "Белок здесь не считается: слишком много не очень полезных баллов.",
		add = "В корзину", back = "Положить обратно", close2 = "Закрыть",
		notNeeded = "Этого сегодня нет в списке. Может, в другой раз!", full = "Этого у нас уже хватает. Посмотри, чего ещё не хватает в списке!",
		tooLow = "У продукта «{name}» буква {g}. Нужно {need} или лучше. Поищи букву зеленее на той же полке!",
		added = "Отличный выбор! «{name}» ({g}) в корзине. +20",
		dupe = "«{name}» уже в корзине. Попробуй что-нибудь другое!",
		basketDone = "Корзина собрана! Неси её Колючкину на кухню.",
		hintOn = "Иди за звёздочками ★ к нужным полкам!",
		more = "Осталось найти: {n}! Я зажёг звёздочки ★ над нужными полками.",
		peek = "Дай-ка загляну в корзину…", yay = "Чудесно! Всё, что нужно. У тебя талант!",
		done = "Задание выполнено!", s1 = "Список собран", s2 = "Без ошибок", s3 = "Отлично угадываешь буквы", nextQ = "Следующее задание", finish = "Завершить",
		finalT = "Ты — Нутри-мастер!", again = "Играть снова",
		finalText = "Ты прошёл все шесть заданий: {s} звёзд из 18 и {p} очков.",
		help = "Как играть",
		h1 = "Ходи клавишами W A S D, стрелками или джойстиком.",
		h2 = "Подойди к продукту и нажми E или кнопку на экране, чтобы рассмотреть его и угадать букву. Можно нажимать и клавиши с буквами.",
		h3 = "Клади в корзину нужные продукты. В списке видно, какая буква нужна каждому.",
		h4 = "Не знаешь, куда идти? Нажми ★ (или H) или поговори с Колючкиным: нужные полки засветятся.",
		hScale = "A (тёмно-зелёная) — самый полезный выбор. E (красная) — понемногу и изредка.",
		sound = "Звук", lang = "Язык", hint = "Подсказка",
	},
}

-- Spike's lessons. Lines with `scale` show the A–E strip ("all", or the letter to highlight).
local LESSONS = {
	intro = {
		en = {
			{ t = "Hi there! I'm Spike, the porcupine chef of the ABCDE Market. My quills are sharp, and my shopping eye is even sharper!" },
			{ t = "See the letters on food packs? That is the Nutri-Score. It goes from A to E.", scale = "all" },
			{ t = "A, dark green, means: eat it often. E, red, means: just a little, now and then. B, C and D are in between.", scale = "A" },
			{ t = "Every shelf tag hides a letter. Look closer at a product, guess its letter, and I will tell you if you are right!" },
			{ t = "Walk with W A S D or the thumbstick. Walk up to a product and press E, or tap the button, to look closer." },
		},
		lv = {
			{ t = "Sveiks! Es esmu Adatiņš, ABCDE tirgus dzeloņcūku pavārs. Manas adatas ir asas, bet acs iepirkšanās — vēl asāka!" },
			{ t = "Redzi burtus uz pārtikas iepakojumiem? Tas ir Nutri-Score. Tas iet no A līdz E.", scale = "all" },
			{ t = "Tumši zaļais A nozīmē: ēd bieži. Sarkanais E nozīmē: tikai mazliet un reizēm. B, C un D ir pa vidu.", scale = "A" },
			{ t = "Katrā plaukta cenu zīmē slēpjas burts. Apskati produktu, uzmini tā burtu, un es pateikšu, vai uzminēji!" },
			{ t = "Staigā ar W A S D vai kursorsviru. Pieej pie produkta un nospied E vai pieskaries pogai, lai to apskatītu." },
		},
		ru = {
			{ t = "Привет! Я Колючкин, шеф-повар дикобраз из магазина ABCDE. Иголки у меня острые, а глаз на покупки ещё острее!" },
			{ t = "Видишь буквы на упаковках? Это Nutri-Score. Он бывает от A до E.", scale = "all" },
			{ t = "Тёмно-зелёная A значит: можно есть часто. Красная E значит: совсем немного и изредка. B, C и D — посередине.", scale = "A" },
			{ t = "На каждом ценнике спрятана буква. Рассмотри продукт, угадай букву, а я скажу, прав ли ты!" },
			{ t = "Ходи клавишами W A S D или джойстиком. Подойди к продукту и нажми E или кнопку на экране, чтобы рассмотреть его." },
		},
	},
	salad = {
		en = { { t = "First quest: a rainbow fruit salad!" }, { t = "Find 3 different fruits with an A, and a plain yogurt or quark that is B or better. Fruit is in the crates by my kitchen. Dairy is in the fridges at the back." } },
		lv = { { t = "Pirmā misija: varavīksnes augļu salāti!" }, { t = "Atrodi 3 dažādus augļus ar A un dabīgo jogurtu vai biezpienu ar B vai labāk. Augļi ir kastēs pie manas virtuves. Piena produkti ir ledusskapjos aizmugurē." } },
		ru = { { t = "Первое задание: радужный фруктовый салат!" }, { t = "Найди 3 разных фрукта с буквой A и натуральный йогурт или творог на B или лучше. Фрукты — в ящиках у моей кухни. Молочное — в холодильниках у дальней стены." } },
	},
	sandwich = {
		en = { { t = "Sandwich time! Here is a secret: letters help you compare things on the SAME shelf." }, { t = "Two breads can look alike, but one is an A and the other is a C. Pick the greener one!", scale = "all" }, { t = "We need bread (B or better), a filling (B or better) and two vegetables with an A." } },
		lv = { { t = "Buterbrodu laiks! Atklāšu noslēpumu: burti palīdz salīdzināt produktus TAJĀ PAŠĀ plauktā." }, { t = "Divas maizes var izskatīties līdzīgi, bet viena ir A, bet otra ir C. Izvēlies zaļāko!", scale = "all" }, { t = "Mums vajag maizi (B vai labāk), pildījumu (B vai labāk) un divus dārzeņus ar A." } },
		ru = { { t = "Время бутербродов! Открою секрет: буквы помогают сравнивать продукты на ОДНОЙ полке." }, { t = "Два хлеба могут быть похожи, но у одного A, а у другого C. Выбирай тот, что зеленее!", scale = "all" }, { t = "Нам нужен хлеб (B или лучше), начинка (B или лучше) и два овоща с буквой A." } },
	},
	breakfast = {
		en = { { t = "How does food get its letter? I count points, like in a game!" }, { t = "Not-so-good points come from lots of energy, sugar, saturated fat and salt." }, { t = "Good points come from fibre, protein, and fruit, veg and nuts." }, { t = "Not-so-good minus good gives the score. The lower the score, the greener the letter! Watch the coloured chips when you look at a product.", scale = "all" }, { t = "Breakfast for the whole family: a cereal with an A, milk, kefir or yogurt (B or better), a fruit with an A, and a drink that is B or better." } },
		lv = { { t = "Kā produkts iegūst savu burtu? Es skaitu punktus, gluži kā spēlē!" }, { t = "Mazāk labos punktus dod daudz enerģijas, cukura, piesātināto tauku un sāls." }, { t = "Labos punktus dod šķiedrvielas, olbaltumvielas, augļi, dārzeņi un rieksti." }, { t = "Mazāk labie mīnus labie ir rezultāts. Jo mazāks rezultāts, jo zaļāks burts! Skaties krāsainos punktus, kad apskati produktu.", scale = "all" }, { t = "Brokastis visai ģimenei: pārslas ar A, piens, kefīrs vai jogurts (B vai labāk), auglis ar A un dzēriens ar B vai labāk." } },
		ru = { { t = "Как продукт получает букву? Я считаю баллы, прямо как в игре!" }, { t = "Не очень полезные баллы дают много энергии, сахара, насыщенных жиров и соли." }, { t = "Полезные баллы дают клетчатка, белок, фрукты, овощи и орехи." }, { t = "Не очень полезные минус полезные — это итог. Чем меньше итог, тем зеленее буква! Смотри на цветные баллы, когда рассматриваешь продукт.", scale = "all" }, { t = "Завтрак для всей семьи: хлопья с буквой A, молоко, кефир или йогурт (B или лучше), фрукт с A и напиток на B или лучше." } },
	},
	pizza = {
		en = { { t = "Pizza night! Something important: no food is forbidden." }, { t = "D and E foods are fine as a treat, just not every day. Today you may pick ONE treat with any letter for dessert!", scale = "E" }, { t = "We also need pizza dough (B or better), a sauce with an A, cheese (C or better) and two A vegetables for toppings." } },
		lv = { { t = "Picas vakars! Svarīga lieta: neviens ēdiens nav aizliegts." }, { t = "D un E produkti der kā gardums, tikai ne katru dienu. Šodien desertam drīksti izvēlēties VIENU gardumu ar jebkuru burtu!", scale = "E" }, { t = "Vēl vajag picas mīklu (B vai labāk), mērci ar A, sieru (C vai labāk) un divus dārzeņus ar A piedevām." } },
		ru = { { t = "Вечер пиццы! Важная вещь: запрещённой еды не бывает." }, { t = "Продукты на D и E — это лакомство, просто не на каждый день. Сегодня на десерт можно взять ОДНО лакомство с любой буквой!", scale = "E" }, { t = "Ещё нужно тесто для пиццы (B или лучше), соус с A, сыр (C или лучше) и два овоща с A для начинки." } },
	},
	party = {
		en = { { t = "Party time! Let us talk about drinks. Only water gets an A. Sweet drinks often get a D or an E.", scale = "A" }, { t = "Even 100% juice has lots of natural sugar, so it cannot be an A." }, { t = "We need 2 drinks (B or better), 2 snacks (B or better), a fruit with an A, and one treat." } },
		lv = { { t = "Ballītes laiks! Parunāsim par dzērieniem. A saņem tikai ūdens. Saldie dzērieni bieži saņem D vai E.", scale = "A" }, { t = "Pat 100% sulā ir daudz dabīgā cukura, tāpēc tā nevar būt A." }, { t = "Mums vajag 2 dzērienus (B vai labāk), 2 uzkodas (B vai labāk), augli ar A un vienu gardumu." } },
		ru = { { t = "Праздник! Поговорим о напитках. Букву A получает только вода. Сладкие напитки часто получают D или E.", scale = "A" }, { t = "Даже в соке 100% много природного сахара, поэтому у него не может быть A." }, { t = "Нужно 2 напитка (B или лучше), 2 снека (B или лучше), фрукт с A и одно лакомство." } },
	},
	dinner = {
		en = { { t = "The grand family dinner! Time to use everything you have learned." }, { t = "A protein with an A, a side with an A, two A vegetables, oil or fat that is B or better, a drink that is B or better, and a dessert that is C or better." }, { t = "I believe in you, chef!" } },
		lv = { { t = "Lielās ģimenes vakariņas! Laiks izmantot visu, ko esi iemācījies." }, { t = "Olbaltumvielu produkts ar A, piedeva ar A, divi dārzeņi ar A, eļļa vai tauki ar B vai labāk, dzēriens ar B vai labāk un deserts ar C vai labāk." }, { t = "Es tev ticu, pavār!" } },
		ru = { { t = "Большой семейный ужин! Пора применить всё, чему ты научился." }, { t = "Белковый продукт с A, гарнир с A, два овоща с A, масло или жир на B или лучше, напиток на B или лучше и десерт на C или лучше." }, { t = "Я в тебя верю, шеф!" } },
	},
	final = {
		en = { { t = "You did it! You are a real Nutri-Master!" }, { t = "Next time you shop with your family, look for the letters and help pick the greener ones." }, { t = "And remember: treats are for now and then, and water is the champion drink!" } },
		lv = { { t = "Tev izdevās! Tu esi īsts Nutri meistars!" }, { t = "Nākamreiz, kad iepērcies ar ģimeni, meklē burtus un palīdzi izvēlēties zaļākos." }, { t = "Un atceries: gardumi ir reizēm, un ūdens ir dzērienu čempions!" } },
		ru = { { t = "У тебя получилось! Ты настоящий Нутри-мастер!" }, { t = "Когда пойдёшь в магазин с семьёй, ищи буквы и помогай выбирать те, что зеленее." }, { t = "И помни: лакомства — иногда, а вода — чемпион среди напитков!" } },
	},
}

Text.LANGS = { "en", "lv", "ru" }

function Text.isLang(lang)
	return T[lang] ~= nil
end

-- Looks up a string and fills in {placeholders} from `vars`.
function Text.get(lang, key, vars)
	local s = (T[lang] and T[lang][key]) or T.en[key] or key
	if vars then
		for k, v in vars do
			s = string.gsub(s, "{" .. k .. "}", function()
				return tostring(v)
			end)
		end
	end
	return s
end

-- Picks this language's entry from a { English, Latvian, Russian } array.
function Text.name(lang, names)
	return names[Config.LANG_INDEX[lang] or 1] or names[1]
end

-- One lesson's lines as { t = text, scale = optional }.
function Text.lesson(lang, key)
	local lesson = LESSONS[key]
	return lesson[lang] or lesson.en
end

return Text

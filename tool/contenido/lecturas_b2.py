"""Lecturas graduadas B2 nuevas (2026-10). Mismo formato que lecturas_b1.py."""

from lecturas_b1 import fill, mc, tf

TEXTS = [
    {
        "id": "b2-remote-towns",
        "title": "Can remote work save small towns?",
        "title_es": "¿Puede el trabajo remoto salvar a los pueblos?",
        "topic": "Trabajo y economía",
        "paragraphs": [
            "For decades, the story of rural areas in many countries has been one of decline. Young people "
            "left for the cities in search of jobs, schools closed, and shops pulled down their shutters for the "
            "last time. Then, almost overnight, the pandemic changed the rules. Millions of office workers "
            "discovered that they could do their jobs from a kitchen table, and some began to wonder why that "
            "table had to be in an expensive city.",
            "Some towns were quick to seize the opportunity. Since 2018, a programme in Tulsa, Oklahoma, has "
            "offered remote workers ten thousand dollars to relocate there for at least a year. Villages in "
            "Spain, Italy and Ireland have set up co-working spaces in old schools and post offices, sometimes "
            "combined with cheap housing, in the hope of attracting new residents.",
            "Supporters argue that the benefits go well beyond the newcomers themselves. Remote workers earn "
            "city salaries but spend their money locally, in cafés, shops and gyms. Their children keep schools "
            "open, and their presence can make it worthwhile for businesses to stay. Some studies of relocation "
            "programmes suggest that most participants remain in their new home after the incentive ends.",
            "Nevertheless, the picture is not entirely rosy. Fast and reliable internet is still a luxury in many "
            "rural areas, and without it the whole idea collapses. Moreover, the arrival of well-paid outsiders "
            "can push up house prices, making it harder for local young people to stay. In some popular "
            "villages, long-standing residents complain that they are becoming strangers in their own streets.",
            "There is also the question of whether remote work is here to stay. Since the pandemic ended, "
            "many large companies have called their employees back to the office for at least part of the week, "
            "which makes living hundreds of kilometres away far less practical.",
            "Perhaps the most realistic conclusion is that remote work will not reverse rural decline on its "
            "own, but it can be one tool among many. Towns that combine good connections with affordable housing, "
            "decent services and a genuine welcome for newcomers seem to have the best chance of turning a "
            "temporary trend into a lasting revival.",
        ],
        "glossary": [
            ("decline", "decadencia, declive"),
            ("shutters", "persianas metálicas"),
            ("seize the opportunity", "aprovechar la oportunidad"),
            ("relocate", "mudarse, trasladarse"),
            ("incentive", "incentivo"),
            ("rosy", "color de rosa, optimista"),
            ("collapses", "se derrumba"),
            ("long-standing", "de toda la vida"),
            ("reverse", "revertir"),
            ("revival", "renacimiento, recuperación"),
        ],
        "questions": [
            mc("What changed the situation for rural areas, according to the text?",
               ["The pandemic showed that many jobs can be done remotely", "New factories opened in villages",
                "Governments banned offices in cities", "Cities became more expensive overnight"],
               "Dice: the pandemic changed the rules."),
            mc("What does the Tulsa programme offer?",
               ["Money to remote workers who move there", "Free university places",
                "Jobs in local factories", "Cheap flights to the city"],
               "Ofrece diez mil dólares para mudarse."),
            tf("Remote workers usually earn local salaries.", False,
               "Dice: Remote workers earn city salaries but spend their money locally."),
            mc("Why do supporters think newcomers benefit the whole town?",
               ["They spend money locally and keep schools open", "They build new roads",
                "They pay higher taxes to the town", "They bring their companies with them"],
               "Lo explica el tercer párrafo."),
            mc("Which risk is mentioned in the fourth paragraph?",
               ["House prices may rise for local people", "Newcomers may refuse to pay taxes",
                "Villages may lose their schools", "Tourism may disappear"],
               "Dice: can push up house prices."),
            fill("Without fast and reliable internet, the whole idea ___.", "collapses",
                 "Dice: without it the whole idea collapses."),
            mc("Why might remote work be less attractive now than during the pandemic?",
               ["Many companies want employees in the office part of the week",
                "Internet has become more expensive", "Villages have stopped offering incentives",
                "Remote work has been made illegal"],
               "Dice: many large companies have called their employees back to the office."),
            tf("The writer believes remote work alone will save rural areas.", False,
               "Dice: will not reverse rural decline on its own."),
        ],
        "task": "¿Te mudarías a un pueblo si pudieras trabajar a distancia? Escribe 130–160 palabras con ventajas, "
        "desventajas y una conclusión, usando conectores como nevertheless, moreover y on the whole.",
        "summary": "After the pandemic, some towns tried to attract remote workers with money, co-working spaces "
        "and cheap housing. Supporters say newcomers spend money locally and keep schools and businesses open. "
        "However, poor internet, rising house prices and companies calling staff back to the office are "
        "problems. Remote work can help rural areas, but it will not reverse their decline on its own.",
    },
    {
        "id": "b2-attention",
        "title": "Who is stealing your attention?",
        "title_es": "¿Quién te roba la atención?",
        "topic": "Tecnología",
        "paragraphs": [
            "In 1971, the economist Herbert Simon made an observation that sounds remarkably modern: \"a wealth "
            "of information creates a poverty of attention.\" Half a century later, his words have become the "
            "foundation of one of the most profitable business models in history.",
            "Many of the apps we use every day are free. Social networks, video platforms and news sites do not "
            "charge us a penny. Instead, they make money by selling advertising, and advertisers pay for one "
            "thing above all: our time and attention. The longer we stay, the more adverts we see, and the more "
            "data the company collects about our interests. This is what critics call the \"attention economy\".",
            "To keep us engaged, designers use techniques borrowed from psychology. Infinite scrolling removes "
            "natural stopping points, so there is never a moment when we reach the end. Notifications arrive at "
            "unpredictable moments, which, like a slot machine, makes us check our phones again and again. "
            "Videos start playing automatically, and recommendation algorithms learn which content keeps each "
            "individual hooked, which is often content that makes us angry or anxious.",
            "Some former employees of technology companies have become outspoken critics of these practices. "
            "They argue that products designed to capture as much attention as possible may damage our ability "
            "to concentrate, our sleep and even public debate, since outrage spreads faster than calm reflection.",
            "The companies reply that they give users tools to control their screen time, and that people are "
            "free to choose what they watch. It is also worth remembering that worries about new media are not "
            "new: similar fears were expressed about novels, radio and television.",
            "Still, many people are looking for ways to take back control. Some switch off all non-essential "
            "notifications or turn their screens grey, which makes them less attractive. Others keep their "
            "phones out of the bedroom. None of these strategies is perfect, but they share a simple idea: "
            "attention is a limited resource, and it is worth deciding consciously where we spend it.",
        ],
        "glossary": [
            ("wealth", "riqueza, abundancia"),
            ("profitable", "rentable"),
            ("advertising", "publicidad"),
            ("engaged", "enganchados, comprometidos"),
            ("infinite scrolling", "desplazamiento infinito"),
            ("slot machine", "máquina tragamonedas"),
            ("hooked", "enganchado"),
            ("outspoken", "que habla sin rodeos"),
            ("outrage", "indignación"),
            ("consciously", "conscientemente"),
        ],
        "questions": [
            mc("What did Herbert Simon say in 1971?",
               ["A lot of information leads to a lack of attention", "Computers will replace people",
                "Advertising will disappear", "Attention is unlimited"],
               "Dice: a wealth of information creates a poverty of attention."),
            mc("How do free apps make money, according to the text?",
               ["By selling advertising", "By charging monthly fees", "By selling phones", "Through donations"],
               "Dice: they make money by selling advertising."),
            tf("The more time we spend on an app, the more data the company collects about us.", True,
               "Dice: the more data the company collects about our interests."),
            mc("Why does infinite scrolling keep us on an app?",
               ["It removes natural stopping points", "It makes videos shorter",
                "It shows fewer adverts", "It saves battery"],
               "Dice: removes natural stopping points."),
            mc("Why are notifications compared to a slot machine?",
               ["They arrive at unpredictable moments", "They cost money",
                "They are colourful and noisy", "They only appear at night"],
               "Dice: arrive at unpredictable moments, which, like a slot machine..."),
            mc("What do the companies say in their defence?",
               ["Users have tools to control their screen time", "Their apps are not addictive at all",
                "They don't collect any data", "They will stop showing adverts"],
               "Lo dice el quinto párrafo."),
            fill("Some people turn their screens ___, which makes them less attractive.", "grey",
                 "Dice: turn their screens grey."),
            tf("The text says fears about new media are a completely new phenomenon.", False,
               "Hubo miedos parecidos con las novelas, la radio y la televisión."),
        ],
        "task": "Escribe un artículo breve (130–160 palabras) con consejos para usar el celular de forma más "
        "consciente. Incluye al menos una oración con the more..., the more... y otra en voz pasiva.",
        "summary": "Many free apps make money from advertising, so they compete for our time and attention. "
        "Designers use techniques like infinite scrolling, unpredictable notifications and recommendation "
        "algorithms to keep us hooked. Critics say this harms concentration, sleep and public debate, while "
        "companies say users can control their screen time. Some people take back control with simple habits.",
    },
    {
        "id": "b2-placebo",
        "title": "The strange power of placebos",
        "title_es": "El extraño poder de los placebos",
        "topic": "Ciencia",
        "paragraphs": [
            "Imagine taking a pill that contains nothing but sugar and feeling noticeably better. It sounds like "
            "a trick, yet it happens so often that doctors have a name for it: the placebo effect.",
            "Placebos play a central role in medical research. When a new drug is tested, some patients receive "
            "the real medicine while others receive an identical-looking pill with no active ingredient. "
            "Ideally, neither the patients nor the doctors know who has received what. Only if the real drug "
            "works clearly better than the placebo is it considered effective.",
            "What surprises many people is how strong the placebo response can be, especially for symptoms "
            "such as pain, nausea or fatigue. Researchers have found that the details matter: two pills tend to "
            "work better than one, injections better than pills, and expensive-looking treatments better than "
            "cheap ones. Even the colour of a tablet can influence how patients feel.",
            "How can an inactive substance have real effects? Part of the explanation lies in expectations. When "
            "we believe that we will get better, the brain can release its own pain-relieving chemicals. "
            "Conditioning also plays a role: if we have often felt relief after taking medicine, the ritual "
            "itself can trigger a response. The care and attention of a doctor seem to matter too.",
            "Perhaps the most puzzling finding comes from studies of so-called open-label placebos. In some "
            "experiments, patients with chronic conditions were told honestly that they were receiving sugar "
            "pills, and yet many still reported improvements. Scientists are still debating why.",
            "It is important not to exaggerate. Placebos cannot shrink tumours or cure infections, and they "
            "mostly affect how we experience symptoms rather than the disease itself. There is also an evil "
            "twin, the nocebo effect: people who expect side effects are more likely to report them. Still, the "
            "placebo effect is a powerful reminder that the mind and the body are more closely connected than we "
            "often assume.",
        ],
        "glossary": [
            ("noticeably", "notablemente"),
            ("active ingredient", "principio activo"),
            ("nausea", "náuseas"),
            ("fatigue", "cansancio, fatiga"),
            ("expectations", "expectativas"),
            ("pain-relieving", "analgésicos, que alivian el dolor"),
            ("trigger", "desencadenar"),
            ("puzzling", "desconcertante"),
            ("shrink", "reducir, encoger"),
            ("side effects", "efectos secundarios"),
        ],
        "questions": [
            mc("What is a placebo, according to the text?",
               ["A pill with no active ingredient", "A very strong painkiller",
                "A new type of vaccine", "A kind of surgery"],
               "Contiene solo azúcar, sin principio activo."),
            mc("When is a new drug considered effective?",
               ["When it works clearly better than the placebo", "When patients like its colour",
                "When it is cheaper than a placebo", "When doctors know who received it"],
               "Lo explica el segundo párrafo."),
            tf("Expensive-looking treatments tend to produce a stronger placebo effect.", True,
               "Dice: expensive-looking treatments better than cheap ones."),
            mc("Which explanation of the placebo effect is NOT mentioned?",
               ["The sugar in the pill cures the illness", "Expectations", "Conditioning",
                "The care of the doctor"],
               "El texto menciona las expectativas, el condicionamiento y la atención del médico."),
            mc("What is surprising about open-label placebos?",
               ["Patients improved even though they knew the pills were sugar", "They are illegal",
                "They only work on children", "They contain a secret medicine"],
               "Dice: told honestly that they were receiving sugar pills, and yet many still reported improvements."),
            tf("According to the text, placebos can cure infections.", False,
               "Dice: Placebos cannot shrink tumours or cure infections."),
            fill("People who expect side effects are more likely to report them: this is the ___ effect.", "nocebo",
                 "Dice: the nocebo effect."),
            mc("What general idea does the text end with?",
               ["The mind and the body are closely connected", "Medicine is useless",
                "Doctors should only prescribe placebos", "Research should stop using placebos"],
               "Es la idea del último párrafo."),
        ],
        "task": "Explica en 130–160 palabras el efecto placebo a alguien que nunca oyó hablar de él, con un ejemplo. "
        "Usa al menos dos verbos en voz pasiva y una oración con although o even though.",
        "summary": "A placebo is a pill with no active ingredient, but it can make people feel better, "
        "especially with pain, nausea or fatigue. New drugs must work better than placebos to be considered "
        "effective. The effect seems to come from expectations, conditioning and the doctor's care, and it "
        "even works when patients know the pill is sugar. However, placebos cannot cure diseases.",
    },
    {
        "id": "b2-overtourism",
        "title": "When there are too many tourists",
        "title_es": "Cuando hay demasiados turistas",
        "topic": "Viajes y medio ambiente",
        "paragraphs": [
            "Every summer, the same images appear in the news: narrow streets so crowded that residents cannot "
            "reach their front doors, cruise ships towering over historic squares, and locals holding banners "
            "that say \"Tourists go home\". The word for this phenomenon, \"overtourism\", has entered "
            "dictionaries in the last few years.",
            "Tourism is a vital source of income for many places. It creates jobs, keeps restaurants and museums "
            "alive and helps to pay for the conservation of monuments. The problem arises when the number of "
            "visitors grows faster than the ability of a place to cope with them.",
            "Cheap flights, huge cruise ships and social media have all contributed. A single viral photo can "
            "transform a quiet village into a must-see destination overnight. Short-term rental platforms have "
            "also changed city centres: when flats are rented to tourists rather than to residents, rents rise, "
            "local shops are replaced by souvenir stores, and neighbourhoods slowly lose their character.",
            "Cities are experimenting with different solutions. Venice has introduced a fee for day-trippers on "
            "the busiest days. Amsterdam launched a campaign telling certain groups of young visitors to stay "
            "away, and several cities have limited the number of tourist flats or banned large cruise ships from "
            "their historic centres. Some destinations encourage visitors to come outside the peak season or to "
            "explore less famous areas.",
            "Critics of these measures point out that they can turn travel into a privilege for the wealthy and "
            "that many workers depend on tourists for their livelihood. Others argue that the measures do not go "
            "far enough, since visitor numbers keep breaking records.",
            "Travellers themselves can make a difference, too. Staying longer in one place, travelling out of "
            "season, choosing locally owned accommodation and respecting the rules of the places they visit are "
            "small decisions, but multiplied by millions of people, they could help ensure that the places we "
            "love are still worth visiting in the future.",
        ],
        "glossary": [
            ("cruise ships", "cruceros"),
            ("towering over", "elevándose sobre"),
            ("banners", "pancartas"),
            ("cope with", "hacer frente a, soportar"),
            ("must-see", "imperdible"),
            ("short-term rental", "alquiler temporario"),
            ("day-trippers", "turistas de un día"),
            ("peak season", "temporada alta"),
            ("livelihood", "sustento"),
            ("locally owned", "de propietarios locales"),
        ],
        "questions": [
            mc("When does tourism become a problem, according to the text?",
               ["When visitor numbers grow faster than a place can cope with",
                "When tourists spend too little money", "When museums are free", "When it rains in summer"],
               "Dice: when the number of visitors grows faster than the ability of a place to cope with them."),
            tf("The text says tourism has no benefits for local people.", False,
               "Crea empleo y ayuda a conservar monumentos."),
            mc("How can a viral photo affect a village?",
               ["It can suddenly make it a popular destination", "It can make it disappear from maps",
                "It can lower house prices", "It can stop cruise ships"],
               "Dice: can transform a quiet village into a must-see destination overnight."),
            mc("What happens when flats are rented to tourists instead of residents?",
               ["Rents rise and neighbourhoods lose their character", "Rents fall",
                "More residents move in", "Local shops become more popular"],
               "Lo explica el tercer párrafo."),
            fill("Venice has introduced a fee for ___ on the busiest days.", "day-trippers",
                 "Dice: a fee for day-trippers."),
            mc("What criticism of the measures is mentioned?",
               ["They could make travel a privilege of the rich", "They are too cheap",
                "They only affect cruise ships", "They were invented by tourists"],
               "Dice: can turn travel into a privilege for the wealthy."),
            tf("Some people think the measures are not strong enough.", True,
               "Dice: the measures do not go far enough."),
            mc("Which of these is suggested to travellers?",
               ["Travel out of season and stay longer", "Visit only famous places",
                "Always travel on cruise ships", "Rent large flats in city centres"],
               "Lo sugiere el último párrafo."),
        ],
        "task": "Eres concejal de una ciudad turística. Escribe una propuesta de 130–160 palabras con dos medidas "
        "contra el exceso de turismo, explicando sus ventajas y un posible inconveniente.",
        "summary": "Overtourism happens when visitor numbers grow faster than a place can cope with. Cheap flights, "
        "cruise ships, social media and short-term rentals have made the problem worse, raising rents and "
        "changing neighbourhoods. Cities like Venice and Amsterdam have introduced fees, campaigns and limits, "
        "although critics say these make travel a privilege. Travellers can also help with their choices.",
    },
    {
        "id": "b2-bilingual-brain",
        "title": "Does speaking two languages change your brain?",
        "title_es": "¿Hablar dos idiomas cambia el cerebro?",
        "topic": "Psicología",
        "paragraphs": [
            "Not so long ago, many parents and teachers believed that bringing up a child with two languages was "
            "a bad idea. It would confuse the child, they thought, and slow down their development. Today, "
            "bilingualism is more often described as a superpower. The truth, as usual, is more nuanced.",
            "We now know that children are perfectly capable of learning two or more languages at the same time. "
            "Bilingual children may know fewer words in each individual language than monolingual children of "
            "the same age, but when both languages are counted together, their vocabulary is usually just as "
            "large. Mixing languages within a sentence, which once worried parents, is now seen as a natural and "
            "skilful use of both systems rather than a sign of confusion.",
            "The more controversial question is whether bilingualism brings advantages beyond language itself. "
            "Since both languages are always active in the brain, bilingual people constantly have to select one "
            "and suppress the other. Some researchers proposed that this daily mental exercise strengthens "
            "\"executive functions\", the skills we use to focus, switch between tasks and ignore distractions. "
            "Early studies seemed to confirm this so-called bilingual advantage.",
            "However, as more and larger studies were carried out, the picture became less clear. Several "
            "attempts to replicate the original findings failed, and some scientists now believe that the "
            "advantage, if it exists, is small and depends on many other factors, such as education, income and "
            "how often people actually switch between their languages.",
            "Another much-discussed claim is that bilingualism may help to delay the symptoms of dementia in old "
            "age. Some studies have reported delays of several years, but others have found little or no effect, "
            "and the debate continues.",
            "What is beyond doubt is that speaking another language opens doors: to other cultures, other "
            "people and other ways of seeing the world. Even if it does not turn us into geniuses, that may be "
            "reason enough to learn one.",
        ],
        "glossary": [
            ("bringing up", "criar"),
            ("nuanced", "matizado"),
            ("skilful", "hábil"),
            ("suppress", "suprimir, inhibir"),
            ("executive functions", "funciones ejecutivas"),
            ("distractions", "distracciones"),
            ("replicate", "replicar, repetir"),
            ("findings", "hallazgos, resultados"),
            ("delay", "retrasar"),
            ("beyond doubt", "fuera de duda"),
        ],
        "questions": [
            mc("What did many people believe in the past about raising bilingual children?",
               ["That it would confuse them", "That it would make them geniuses",
                "That it was only possible for rich families", "That it was the best method"],
               "Dice: It would confuse the child... and slow down their development."),
            tf("Bilingual children usually have a smaller total vocabulary than monolingual children.", False,
               "Contando los dos idiomas, su vocabulario suele ser igual de grande."),
            mc("How is mixing languages within a sentence seen today?",
               ["As a skilful use of both languages", "As a sign of confusion",
                "As a learning disorder", "As bad manners"],
               "Dice: a natural and skilful use of both systems."),
            mc("What are executive functions?",
               ["Skills used to focus and switch between tasks", "Jobs in large companies",
                "Parts of grammar", "Memory for vocabulary"],
               "El texto las define en el tercer párrafo."),
            mc("What happened when larger studies were carried out?",
               ["The bilingual advantage became less clear", "The advantage became much bigger",
                "All studies confirmed the advantage", "Scientists stopped studying the topic"],
               "Dice: the picture became less clear."),
            fill("Several attempts to ___ the original findings failed.", "replicate",
                 "Dice: Several attempts to replicate the original findings failed."),
            tf("All studies agree that bilingualism delays dementia by several years.", False,
               "Algunos estudios no encontraron efecto; el debate sigue."),
            mc("What does the writer say is beyond doubt?",
               ["Learning a language opens doors to other cultures", "Bilingual people are smarter",
                "Bilingualism prevents dementia", "Children should learn three languages"],
               "Es la idea del último párrafo."),
        ],
        "task": "Escribe 130–160 palabras sobre tu experiencia aprendiendo inglés: qué te resultó más difícil, qué "
        "beneficios notaste y qué le recomendarías a otra persona. Usa el present perfect continuous.",
        "summary": "In the past, people thought bilingualism confused children, but we now know children can "
        "learn two languages easily and mixing them is normal. Some researchers claimed that bilinguals have "
        "better executive functions, but larger studies have made this advantage less clear, and the effect on "
        "dementia is still debated. What is certain is that languages open doors to other cultures.",
    },
    {
        "id": "b2-lab-meat",
        "title": "Meat without animals",
        "title_es": "Carne sin animales",
        "topic": "Ciencia",
        "paragraphs": [
            "In August 2013, a group of journalists in London tasted a hamburger that had cost around a quarter "
            "of a million pounds to produce. It was not made from a cow, at least not in the usual way. The meat "
            "had been grown in a laboratory from cells taken from a living animal. The verdict of the tasters "
            "was polite rather than enthusiastic: close to meat, but not very juicy.",
            "More than a decade later, cultivated meat, as its producers prefer to call it, has moved from "
            "science fiction to the shelves of a handful of restaurants. In 2020, Singapore became the first "
            "country to approve its sale, and in 2023 two companies received permission to sell cultivated "
            "chicken in the United States.",
            "The process begins with a small sample of cells taken from an animal, usually without harming it. "
            "These cells are placed in large steel tanks called bioreactors, where they are fed a nutrient-rich "
            "liquid and multiply. The result can then be shaped into products such as nuggets or burgers.",
            "Supporters point to several potential benefits. Animal farming uses a large share of the world's "
            "agricultural land and produces significant greenhouse gas emissions. Growing meat from cells "
            "could, in theory, require far less land and water, and it would avoid the slaughter of billions of "
            "animals every year.",
            "However, many obstacles remain. Producing cultivated meat on a large scale is still extremely "
            "expensive, and some scientists doubt that costs will ever fall enough to compete with conventional "
            "meat. Its environmental benefits also depend on how much energy the bioreactors consume and where "
            "that energy comes from. Meanwhile, some governments have taken the opposite direction: Italy, for "
            "instance, banned its production and sale in 2023, partly to protect traditional farmers.",
            "Then there is the question of taste and trust. Surveys suggest that many consumers are curious but "
            "hesitant about eating something grown in a tank. Whether cultivated meat becomes an everyday food or "
            "remains an expensive curiosity may depend less on scientists than on what ends up on our plates.",
        ],
        "glossary": [
            ("verdict", "veredicto"),
            ("juicy", "jugoso"),
            ("cultivated", "cultivada"),
            ("a handful of", "un puñado de"),
            ("sample", "muestra"),
            ("tanks", "tanques"),
            ("multiply", "se multiplican"),
            ("greenhouse gas", "gases de efecto invernadero"),
            ("slaughter", "matanza, sacrificio"),
            ("hesitant", "dudoso, vacilante"),
        ],
        "questions": [
            mc("What was special about the hamburger tasted in 2013?",
               ["It was grown in a laboratory from animal cells", "It was made from plants",
                "It was the cheapest burger ever", "It came from a cloned cow"],
               "Dice: The meat had been grown in a laboratory from cells."),
            tf("The journalists thought the burger was extremely juicy.", False,
               "Dice: close to meat, but not very juicy."),
            fill("In 2020, which country became the first to approve the sale of cultivated meat?", "Singapore",
                 "Dice: In 2020, Singapore became the first country to approve its sale."),
            mc("What happens inside a bioreactor?",
               ["Cells are fed and multiply", "Animals are kept and fed", "Meat is cooked", "Plants are grown"],
               "Lo explica el tercer párrafo."),
            mc("Which potential benefit is mentioned?",
               ["It could need less land and water", "It is cheaper than all other meat",
                "It needs no energy", "It tastes better than any other meat"],
               "Dice: could, in theory, require far less land and water."),
            mc("Why do some scientists doubt the future of cultivated meat?",
               ["Large-scale production is still very expensive", "It is dangerous to eat",
                "Nobody has ever tasted it", "It cannot be shaped into burgers"],
               "Dice: Producing cultivated meat on a large scale is still extremely expensive."),
            tf("Italy banned cultivated meat partly to protect traditional farmers.", True,
               "El texto lo menciona en el quinto párrafo."),
            mc("According to the writer, what may decide the future of cultivated meat?",
               ["What consumers are willing to eat", "The weather", "Football clubs", "The price of cows"],
               "Dice: may depend less on scientists than on what ends up on our plates."),
        ],
        "task": "¿Comerías carne cultivada? Escribe 130–160 palabras con tu postura y argumentos a favor y en contra. "
        "Incluye al menos un condicional de segundo tipo (If it were..., I would...).",
        "summary": "Cultivated meat is grown from animal cells in bioreactors. The first lab burger was tasted in "
        "2013, and Singapore and the United States have since approved its sale. It could use less land and "
        "avoid killing animals, but it is still very expensive, its environmental benefits depend on energy, "
        "and some countries like Italy have banned it. Consumers are curious but hesitant.",
    },
    {
        "id": "b2-urban-heat",
        "title": "Cities that are too hot",
        "title_es": "Ciudades demasiado calurosas",
        "topic": "Medio ambiente",
        "paragraphs": [
            "On a summer afternoon, walking from a city park into a busy street feels like opening an oven door. "
            "This is not just an impression. Cities are often several degrees warmer than the surrounding "
            "countryside, a phenomenon known as the urban heat island.",
            "The causes are well understood. Asphalt and concrete absorb heat during the day and release it "
            "slowly at night, so cities cool down far less than rural areas. Tall buildings trap warm air and "
            "block the wind, while cars, air conditioners and industry add extra heat. Meanwhile, there are "
            "fewer trees and less vegetation, which in the countryside cool the air by providing shade and "
            "releasing water.",
            "As heatwaves become more frequent and intense with climate change, the consequences are serious. "
            "Extreme heat is linked to thousands of deaths every year, mostly among elderly people, young "
            "children and those with health problems. The effects are not distributed equally either: poorer "
            "neighbourhoods often have fewer trees and parks than wealthier ones, and their residents are less "
            "likely to have air conditioning.",
            "Cities around the world are looking for solutions. Medellín, in Colombia, has turned roads and "
            "streams into \"green corridors\" full of plants and trees, which have reportedly lowered "
            "temperatures in the surrounding streets by around two degrees. Paris has been transforming school "
            "playgrounds, replacing asphalt with trees and surfaces that absorb water, so that they can serve "
            "as cool spaces for neighbours during heatwaves. Other cities paint roofs white to reflect sunlight "
            "or require new buildings to include green roofs.",
            "Air conditioning provides immediate relief, but it is not a perfect answer. It consumes large "
            "amounts of energy and pumps hot air into the street, which makes the problem worse outside.",
            "Experts agree that there is no single solution. Planting trees, however, comes close: a mature tree "
            "can cool its surroundings, absorb rainwater, clean the air and make streets more pleasant to walk "
            "along. The challenge is that trees take decades to grow, so the best time to plant them, as an old "
            "saying goes, was twenty years ago.",
        ],
        "glossary": [
            ("surrounding", "circundante, de alrededor"),
            ("heat island", "isla de calor"),
            ("asphalt", "asfalto"),
            ("concrete", "hormigón, cemento"),
            ("trap", "atrapan"),
            ("shade", "sombra"),
            ("heatwaves", "olas de calor"),
            ("reportedly", "según se informa"),
            ("relief", "alivio"),
            ("mature", "maduro, adulto"),
        ],
        "questions": [
            mc("What is the urban heat island?",
               ["Cities being warmer than the surrounding countryside", "A very hot island",
                "A park in the centre of a city", "A type of building"],
               "Lo define el primer párrafo."),
            mc("Why do cities cool down less at night?",
               ["Asphalt and concrete release heat slowly", "There are more clouds over cities",
                "People open their windows", "The wind is stronger"],
               "Dice: absorb heat during the day and release it slowly at night."),
            tf("Extreme heat affects all neighbourhoods equally.", False,
               "Los barrios más pobres suelen tener menos árboles y menos aire acondicionado."),
            fill("Medellín has created \"green ___\" full of plants and trees.", "corridors",
                 "Dice: green corridors."),
            mc("How is Paris changing school playgrounds?",
               ["Replacing asphalt with trees and surfaces that absorb water", "Covering them with air conditioners",
                "Building car parks on them", "Painting them black"],
               "Lo explica el cuarto párrafo."),
            mc("What is a problem with air conditioning?",
               ["It uses a lot of energy and heats the street", "It doesn't cool rooms",
                "It is illegal in most cities", "It makes trees grow slower"],
               "Dice: consumes large amounts of energy and pumps hot air into the street."),
            mc("Why do experts consider trees almost an ideal solution?",
               ["They cool, absorb rainwater and clean the air", "They grow very quickly",
                "They cost nothing to maintain", "They produce electricity"],
               "Lo dice el último párrafo."),
            tf("Trees are a quick solution because they grow in a few months.", False,
               "Dice: trees take decades to grow."),
        ],
        "task": "Escribe un correo formal (130–160 palabras) al municipio de tu ciudad proponiendo dos medidas contra "
        "el calor en tu barrio. Usa it would be..., I would suggest... y una oración en voz pasiva.",
        "summary": "Cities are often several degrees warmer than the countryside because asphalt and concrete store "
        "heat, buildings trap warm air and there are few trees. With more heatwaves, this causes deaths and "
        "affects poorer areas most. Cities like Medellín and Paris are adding plants and trees, and others paint "
        "roofs white. Air conditioning helps but makes streets hotter, while trees are slow but effective.",
    },
    {
        "id": "b2-citizen-science",
        "title": "Science by everyone",
        "title_es": "Ciencia hecha por todos",
        "topic": "Ciencia",
        "paragraphs": [
            "In 2007, a Dutch schoolteacher called Hanny van Arkel was looking at pictures of galaxies on her "
            "computer when she noticed a strange green cloud that nobody had ever described. Astronomers later "
            "concluded that it was a cloud of gas lit up by a black hole, and it was named after her: Hanny's "
            "Voorwerp, Dutch for \"Hanny's object\". She was not a professional scientist. She was one of hundreds "
            "of thousands of volunteers taking part in a project called Galaxy Zoo.",
            "Galaxy Zoo is an example of citizen science: research in which members of the public collect or "
            "analyse data. The project was created because astronomers had millions of images of galaxies and "
            "nowhere near enough people to classify them. Computers at the time were poor at the task, but "
            "human beings, it turned out, were very good at it, even after a short online tutorial.",
            "Citizen science is not new. For more than a century, volunteers in North America have counted birds "
            "every winter, and their records have helped scientists track how populations change. What is new is "
            "the scale. Smartphones and the internet now allow millions of people to identify plants, measure "
            "air quality, listen for whales or transcribe old documents from home.",
            "The benefits flow in both directions. Scientists gain data that would be impossible or "
            "prohibitively expensive to collect on their own, and volunteers gain knowledge, a sense of purpose "
            "and sometimes an unexpected place in history. Some projects have also strengthened trust between "
            "communities and researchers, for example when residents measure pollution in their own "
            "neighbourhoods.",
            "There are, of course, concerns. Data collected by non-experts can contain errors, so projects "
            "usually ask several volunteers to classify the same item and compare their answers. Critics also "
            "warn against using volunteers simply as free labour, without giving them credit or sharing the "
            "results.",
            "Still, the message of citizen science is an attractive one: curiosity is not reserved for people in "
            "laboratories, and anyone with a little time and attention can contribute to human knowledge.",
        ],
        "glossary": [
            ("galaxies", "galaxias"),
            ("lit up", "iluminada"),
            ("named after", "bautizada en honor a"),
            ("classify", "clasificar"),
            ("tutorial", "tutorial, guía"),
            ("track", "seguir, rastrear"),
            ("transcribe", "transcribir"),
            ("prohibitively", "prohibitivamente"),
            ("free labour", "mano de obra gratuita"),
            ("credit", "reconocimiento"),
        ],
        "questions": [
            mc("Who was Hanny van Arkel?",
               ["A schoolteacher who volunteered for Galaxy Zoo", "A professional astronomer",
                "A computer programmer", "The founder of Galaxy Zoo"],
               "Dice: a Dutch schoolteacher... She was not a professional scientist."),
            mc("What did she discover?",
               ["A cloud of gas lit up by a black hole", "A new planet", "A new type of bird", "A comet"],
               "Lo explica el primer párrafo."),
            mc("Why was Galaxy Zoo created?",
               ["There were too many images for astronomers to classify", "To teach children astronomy",
                "To sell telescopes", "Because computers were too expensive"],
               "Dice: had millions of images... and nowhere near enough people to classify them."),
            tf("Citizen science only began with the internet.", False,
               "Los voluntarios cuentan aves desde hace más de un siglo."),
            fill("Smartphones allow people to ___ old documents from home.", "transcribe",
                 "Dice: transcribe old documents from home."),
            mc("What do volunteers gain, according to the text?",
               ["Knowledge and a sense of purpose", "A salary", "A university degree", "Free equipment"],
               "Dice: volunteers gain knowledge, a sense of purpose..."),
            mc("How do projects reduce errors made by non-experts?",
               ["Several volunteers classify the same item", "Only experts are allowed to take part",
                "Volunteers take an exam every week", "Computers check every answer"],
               "Lo explica el quinto párrafo."),
            tf("Critics warn that volunteers should receive credit and share the results.", True,
               "Advierten contra usarlos solo como mano de obra gratuita."),
        ],
        "task": "Busca (o imagina) un proyecto de ciencia ciudadana que te interese y escribe 130–160 palabras "
        "explicando qué hacen los voluntarios, para qué sirve y por qué participarías.",
        "summary": "Citizen science is research in which ordinary people collect or analyse data. In the Galaxy "
        "Zoo project, a Dutch teacher discovered a strange gas cloud while classifying galaxies. Volunteers have "
        "counted birds for a century, and now smartphones let millions take part. Scientists get valuable data "
        "and volunteers gain knowledge, although errors and fair credit are concerns.",
    },
    {
        "id": "b2-failure",
        "title": "Learning to fail",
        "title_es": "Aprender a fracasar",
        "topic": "Psicología",
        "paragraphs": [
            "In 2016, a Princeton professor called Johannes Haushofer published an unusual document online: a "
            "\"CV of failures\". Instead of listing his degrees and awards, it listed the jobs he had not got, the "
            "scholarships he had been refused and the papers that journals had rejected. To his surprise, it went "
            "viral. \"This darn CV of failures has received way more attention than my entire body of academic "
            "work,\" he later joked.",
            "Part of the reason it struck a chord is that we rarely see other people's failures. Social media, "
            "job applications and even conversations with friends tend to show a carefully selected version of "
            "our lives, full of successes. As a result, it is easy to believe that everyone else succeeds at the "
            "first attempt, and that our own setbacks are a sign that we are not good enough.",
            "Psychologists who study learning tell a different story. Making mistakes, especially when we receive "
            "useful feedback afterwards, is one of the most effective ways to learn. In some experiments, people "
            "who tried to answer questions before being taught the material, and got many of them wrong, "
            "remembered more afterwards than people who simply studied the answers.",
            "The psychologist Carol Dweck has popularised the idea of a \"growth mindset\": the belief that "
            "abilities can be developed through effort and good strategies, rather than being fixed. People with "
            "this mindset, she argues, are more likely to see failures as information rather than as a verdict on "
            "their worth. Later research has found the effects of mindset training to be smaller than early "
            "studies suggested, but the basic idea remains influential in schools and companies.",
            "None of this means that failure is pleasant, or that we should celebrate every mistake. Losing a "
            "job or failing an important exam can be painful, and some failures have serious consequences. The "
            "point is rather to separate what we did from who we are, and to ask a useful question: what can I "
            "learn from this?",
            "Perhaps that is why Haushofer's CV continues to circulate. It reminds us that behind every success "
            "story there is usually a much longer, and much less visible, list of rejections.",
        ],
        "glossary": [
            ("scholarships", "becas"),
            ("rejected", "rechazó, rechazados"),
            ("went viral", "se hizo viral"),
            ("struck a chord", "tocó una fibra sensible"),
            ("setbacks", "reveses, contratiempos"),
            ("feedback", "devolución, comentarios"),
            ("growth mindset", "mentalidad de crecimiento"),
            ("fixed", "fijas"),
            ("worth", "valor, valía"),
            ("rejections", "rechazos"),
        ],
        "questions": [
            mc("What did Johannes Haushofer's \"CV of failures\" list?",
               ["Jobs, scholarships and papers he had been refused", "His degrees and awards",
                "The mistakes of his students", "Famous people's failures"],
               "Lo explica el primer párrafo."),
            tf("Haushofer expected his CV of failures to become very popular.", False,
               "Dice: To his surprise, it went viral."),
            mc("Why do we rarely see other people's failures?",
               ["People usually show a selected version of their lives", "Failures are illegal to publish",
                "Most people never fail", "Failures are kept secret by companies"],
               "Lo explica el segundo párrafo."),
            mc("What did some learning experiments show?",
               ["Trying and failing before being taught helped people remember more",
                "People who never made mistakes learned more", "Feedback makes learning slower",
                "Studying answers is always the best method"],
               "Lo dice el tercer párrafo."),
            fill("Carol Dweck popularised the idea of a \"growth ___\".", "mindset",
                 "Dice: a growth mindset."),
            tf("Later research found mindset training effects to be larger than early studies suggested.", False,
               "Dice: smaller than early studies suggested."),
            mc("What does the writer suggest doing after a failure?",
               ["Separate what we did from who we are and ask what we can learn", "Celebrate it with friends",
                "Forget it immediately", "Publish it online"],
               "Lo dice el quinto párrafo."),
            mc("What does Haushofer's CV remind us of?",
               ["Success stories usually hide many rejections", "Professors never fail",
                "CVs should be short", "Failure is always pleasant"],
               "Es la idea del último párrafo."),
        ],
        "task": "Escribe tu propio «CV de fracasos» breve (130–160 palabras): tres intentos que no salieron bien y qué "
        "aprendiste de cada uno. Usa el past perfect y expresiones como as a result o looking back.",
        "summary": "A Princeton professor published a CV listing his failures, and it went viral because we rarely "
        "see other people's setbacks. Research shows that making mistakes and receiving feedback helps us learn, "
        "and Carol Dweck's growth mindset encourages seeing failure as information, although its effects may be "
        "small. The key is to separate what we did from who we are.",
    },
    {
        "id": "b2-local-news",
        "title": "The silence of local newspapers",
        "title_es": "El silencio de los diarios locales",
        "topic": "Medios",
        "paragraphs": [
            "For most of the twentieth century, almost every town of a reasonable size had its own newspaper. "
            "Its reporters sat through council meetings, covered local trials, interviewed the new head of the "
            "hospital and published the results of the school football match. Few of these stories made national "
            "headlines, but together they kept communities informed.",
            "Over the past two decades, thousands of these papers have closed. In the United States alone, "
            "researchers estimate that more than a quarter of all local newspapers have disappeared since the "
            "early 2000s, leaving many areas without any regular source of local news. These places are now "
            "described as \"news deserts\".",
            "The main cause is economic. Local papers traditionally depended on advertising, especially small "
            "adverts for jobs, houses and second-hand cars. When those adverts moved to free websites and social "
            "networks, the papers lost their most reliable source of income. Many were bought by large companies "
            "that cut costs by reducing staff, so that even the papers that survived often have far fewer "
            "journalists than before.",
            "Why does this matter? Studies suggest that when a local paper closes, fewer people vote in local "
            "elections and fewer candidates stand for office. Some research has also found that local governments "
            "borrow money at higher costs, possibly because there is nobody watching how public money is spent. "
            "In addition, people who lose access to local news tend to rely more on national media, which often "
            "focus on divisive political conflicts rather than on practical local issues.",
            "There are signs of hope. Non-profit news organisations funded by donations and foundations have been "
            "set up in many cities. Some publications ask readers to become members rather than subscribers, and "
            "a few local newsletters run by one or two journalists have attracted thousands of readers.",
            "None of these models has yet replaced what was lost. But they share a conviction that democracy works "
            "better when someone is paid to sit through the long, boring council meeting and tell everyone else "
            "what happened.",
        ],
        "glossary": [
            ("council meetings", "reuniones del concejo"),
            ("trials", "juicios"),
            ("headlines", "titulares"),
            ("news deserts", "desiertos informativos"),
            ("cut costs", "recortar gastos"),
            ("staff", "personal"),
            ("stand for office", "se presentan como candidatos"),
            ("divisive", "que divide, polémico"),
            ("non-profit", "sin fines de lucro"),
            ("conviction", "convicción"),
        ],
        "questions": [
            mc("What kind of stories did local newspapers publish?",
               ["Council meetings, local trials and school sports", "Only national politics",
                "International news", "Celebrity gossip"],
               "Lo describe el primer párrafo."),
            fill("Areas without any regular source of local news are called \"news ___\".", "deserts",
                 "Dice: news deserts."),
            mc("What is the main cause of the closures?",
               ["Advertising moved to free websites and social networks", "People stopped reading",
                "Paper became too expensive", "Governments closed them"],
               "Dice: The main cause is economic... adverts moved to free websites."),
            tf("The papers that survived usually have more journalists than before.", False,
               "Dice: often have far fewer journalists than before."),
            mc("What happens, according to studies, when a local paper closes?",
               ["Fewer people vote in local elections", "Crime disappears",
                "More people read national newspapers on paper", "Local taxes fall"],
               "Lo dice el cuarto párrafo."),
            mc("Why might local governments borrow money at higher costs?",
               ["Nobody is watching how public money is spent", "Banks dislike journalists",
                "They print fewer newspapers", "Interest rates are higher in small towns"],
               "Dice: possibly because there is nobody watching how public money is spent."),
            mc("Which new model is mentioned as a sign of hope?",
               ["Non-profit news organisations funded by donations", "Free newspapers paid by the government",
                "Newspapers written by artificial intelligence", "Radio stations owned by schools"],
               "Lo menciona el quinto párrafo."),
            tf("The writer believes the new models have fully replaced traditional local papers.", False,
               "Dice: None of these models has yet replaced what was lost."),
        ],
        "task": "Escribe una carta al editor (130–160 palabras) defendiendo la importancia de un medio local de tu "
        "ciudad o pidiendo que exista uno. Usa conectores de causa y consecuencia.",
        "summary": "Local newspapers used to cover council meetings, trials and community events, but thousands have "
        "closed, creating news deserts. The main reason is that advertising moved online. Studies suggest that "
        "without local news fewer people vote and public money is watched less closely. Non-profit newsrooms and "
        "small newsletters offer hope, but they have not replaced what was lost.",
    },
    {
        "id": "b2-art-forger",
        "title": "The man who fooled the art world",
        "title_es": "El hombre que engañó al mundo del arte",
        "topic": "Arte",
        "paragraphs": [
            "In 1945, shortly after the end of the Second World War, Dutch police arrested a painter called Han "
            "van Meegeren. The charge was extremely serious: he had sold a national treasure, a painting by the "
            "seventeenth-century master Johannes Vermeer, to the Nazi leader Hermann Göring. If he was found "
            "guilty of collaborating with the enemy, he could face the death penalty.",
            "After several weeks in prison, van Meegeren made a startling confession. The painting was not a "
            "Vermeer at all. He had painted it himself, along with several other \"Vermeers\" that hung in famous "
            "collections, including one that a Rotterdam museum had proudly bought in 1937.",
            "At first, nobody believed him. So, to prove his claim, he painted another fake Vermeer in front of "
            "witnesses. The story turned him from a traitor into something close to a folk hero: the man who had "
            "tricked Göring.",
            "How had he fooled so many experts? Van Meegeren was a skilled painter who felt that critics had never "
            "recognised his talent. He studied Vermeer's technique in depth, bought old canvases from the period "
            "and used pigments that would have been available in the seventeenth century. He also developed a "
            "method of hardening the paint by baking it, so that it would look centuries old. Crucially, rather "
            "than copying known works, he painted religious scenes that experts had long believed Vermeer must "
            "have produced early in his career. His fakes, in a sense, told the experts exactly what they wanted "
            "to hear.",
            "In 1947, he was convicted not of collaboration but of forgery and fraud, and sentenced to one year in "
            "prison. He never served it: he died of a heart attack a few weeks later.",
            "Today, his forgeries look surprisingly unlike Vermeer to many viewers; the faces, for instance, seem "
            "to belong more to the 1930s than to the 1600s. The case is often used to show how expectations, "
            "reputation and wishful thinking can influence even the most expert eyes.",
        ],
        "glossary": [
            ("charge", "acusación, cargo"),
            ("treasure", "tesoro"),
            ("guilty", "culpable"),
            ("startling", "sorprendente, asombroso"),
            ("fake", "falso"),
            ("witnesses", "testigos"),
            ("traitor", "traidor"),
            ("canvases", "lienzos"),
            ("forgery", "falsificación"),
            ("wishful thinking", "ilusiones, pensar con el deseo"),
        ],
        "questions": [
            mc("Why was van Meegeren arrested in 1945?",
               ["For selling a supposed Vermeer to Göring", "For stealing paintings from a museum",
                "For painting political posters", "For fighting in the war"],
               "Lo explica el primer párrafo."),
            mc("What did he confess?",
               ["That he had painted the \"Vermeer\" himself", "That he had worked for the Nazis",
                "That he had stolen the painting", "That he had destroyed a real Vermeer"],
               "Dice: He had painted it himself."),
            fill("To prove his claim, he painted another fake Vermeer in front of ___.", "witnesses",
                 "Dice: in front of witnesses."),
            tf("After his confession, many people saw him as a kind of hero.", True,
               "Dice: something close to a folk hero: the man who had tricked Göring."),
            mc("Which technique did he use to make the paint look old?",
               ["He baked the paint to harden it", "He painted in the dark",
                "He used modern plastic paints", "He washed the canvases with coffee"],
               "Dice: a method of hardening the paint by baking it."),
            mc("Why did experts accept his paintings so easily?",
               ["They showed the kind of early works experts expected Vermeer to have painted",
                "They were exact copies of famous Vermeers", "He bribed the experts",
                "He signed them with his own name"],
               "Dice: told the experts exactly what they wanted to hear."),
            tf("He served his full prison sentence.", False, "Murió unas semanas después, sin cumplirla."),
            mc("What lesson is the case often used to illustrate?",
               ["Expectations can influence even experts", "Old paintings are always fake",
                "Museums should not buy art", "Vermeer was a poor painter"],
               "Es la idea del último párrafo."),
        ],
        "task": "Escribe una reseña (130–160 palabras) de una obra de arte, película o libro que te haya sorprendido. "
        "Incluye una oración con having + participio y otra con what impressed me most was...",
        "summary": "In 1945, Han van Meegeren was arrested for selling a Vermeer to Göring, but he confessed that he "
        "had painted it, and proved it by painting another in front of witnesses. He had fooled experts by "
        "using old materials, baking the paint and painting the early Vermeers they expected to find. He was "
        "convicted of forgery in 1947 and died soon after.",
    },
    {
        "id": "b2-lighthouse-keeper",
        "title": "The last keeper",
        "title_es": "El último farero",
        "topic": "Ficción",
        "paragraphs": [
            "When the letter from the maritime authority arrived, Arthur Penrose read it twice, folded it neatly "
            "and put it in the drawer where he kept the logbooks. The lighthouse on Carrick Point was to be "
            "automated in the spring. After forty-one years, the light would go on and off without him.",
            "He did not tell anyone at first, partly because there was hardly anyone to tell. The supply boat "
            "came on Thursdays, weather permitting, and the young woman who brought the post rarely stayed long "
            "enough for a conversation. Arthur had never minded. He had grown used to the company of the wind, the "
            "gulls and the long, patient sweep of the beam across the water.",
            "The engineers came in March: two cheerful men from the mainland with a van full of cables and "
            "a small grey box that, they explained, would do everything Arthur did, only better. \"No offence, "
            "sir,\" said the younger one. \"It doesn't need sleep.\"",
            "Arthur showed them around anyway. He explained how the fog rolled in from the south-west without "
            "warning, how the old lens had to be cleaned by hand, and which step on the spiral staircase "
            "creaked. They nodded politely and took notes they would never need.",
            "On his last night, a storm came in, the worst in years. Just after midnight, the new system "
            "failed. The beam flickered and died, and for a moment the whole headland was swallowed by darkness. "
            "Somewhere out there, Arthur knew, the fishing boats would be heading home.",
            "He climbed the hundred and twelve steps faster than he had in a decade, lit the old emergency lamp "
            "and kept it turning by hand until dawn. In the morning, a trawler captain radioed to thank \"whoever "
            "was up there\".",
            "The authority sent a polite letter of gratitude and, a month later, a technician to fix the fault. "
            "Arthur moved to a small cottage in the village. But on stormy nights, people say, he still sits by "
            "his window, watching the light, just in case.",
        ],
        "glossary": [
            ("maritime", "marítima"),
            ("logbooks", "cuadernos de bitácora"),
            ("automated", "automatizado"),
            ("weather permitting", "si el tiempo lo permite"),
            ("gulls", "gaviotas"),
            ("beam", "haz de luz"),
            ("creaked", "crujía"),
            ("flickered", "parpadeó"),
            ("headland", "cabo, promontorio"),
            ("trawler", "barco pesquero de arrastre"),
        ],
        "questions": [
            mc("What did the letter from the maritime authority announce?",
               ["The lighthouse would be automated", "Arthur would receive a prize",
                "A new keeper was coming", "The lighthouse would be demolished"],
               "Dice: The lighthouse on Carrick Point was to be automated."),
            fill("The lighthouse on Carrick Point was to be ___ in the spring.", "automated",
                 "Dice: was to be automated in the spring."),
            tf("Arthur had many visitors at the lighthouse.", False,
               "Dice: there was hardly anyone to tell."),
            mc("What did the younger engineer say about the new system?",
               ["It doesn't need sleep", "It is more beautiful", "It is cheaper", "It needs Arthur's help"],
               "Dice: It doesn't need sleep."),
            mc("What happened on Arthur's last night?",
               ["The new system failed during a storm", "The engineers came back",
                "A boat crashed into the rocks", "Arthur decided to stay for ever"],
               "Dice: the new system failed."),
            mc("What did Arthur do?",
               ["He lit the old lamp and turned it by hand until dawn", "He called the engineers",
                "He went to sleep", "He sent a message to the boats"],
               "Lo cuenta el sexto párrafo."),
            tf("A trawler captain thanked whoever was operating the light.", True,
               "Dice: a trawler captain radioed to thank whoever was up there."),
            mc("Where does Arthur live at the end of the story?",
               ["In a small cottage in the village", "Still in the lighthouse",
                "On the mainland, in a city", "On a fishing boat"],
               "Dice: Arthur moved to a small cottage in the village."),
        ],
        "task": "Escribe la misma historia desde el punto de vista del capitán del pesquero (130–160 palabras). "
        "Usa el past continuous para la escena de la tormenta y el past perfect para lo que había pasado antes.",
        "summary": "Arthur, a lighthouse keeper for forty-one years, learned that his lighthouse would be automated. "
        "Engineers installed a new system that didn't need sleep. On his last night, a storm broke the new "
        "system, so Arthur lit the old lamp and turned it by hand until dawn, helping the fishing boats get home. "
        "Afterwards he moved to the village, but he still watches the light on stormy nights.",
    },
]

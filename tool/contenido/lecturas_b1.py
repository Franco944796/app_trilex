"""Lecturas graduadas B1 nuevas (2026-10). Las genera tool/contenido/generar.py.

Cada lectura: párrafos, glosario (palabra tal como aparece en el texto → significado en español),
preguntas en inglés con la explicación en español, tarea de escritura y resumen modelo.
"""


def mc(q, options, why):
    """La primera opción es la correcta; la web y la app las barajan."""
    return {"type": "mc", "q": q, "options": options, "answer": options[0], "why": why}


def tf(q, answer, why):
    return {"type": "tf", "q": q, "answer": answer, "why": why}


def fill(q, answer, why):
    return {"type": "fill", "q": q, "answer": answer if isinstance(answer, list) else [answer], "why": why}


TEXTS = [
    {
        "id": "b1-job-interview",
        "title": "My first real job interview",
        "title_es": "Mi primera entrevista de trabajo de verdad",
        "topic": "Trabajo",
        "paragraphs": [
            "I was twenty-two when I applied for my first proper job, as an assistant in a small design studio. "
            "I had sent out more than forty applications, so when the studio finally called me, I was thrilled "
            "and terrified at the same time.",
            "The night before the interview, I prepared answers to all the typical questions: Why do you want "
            "this job? What are your strengths and weaknesses? Where do you see yourself in five years? I even "
            "practised in front of the mirror. I chose my clothes carefully and set three alarms.",
            "Of course, the day did not go as planned. My bus broke down halfway, and I had to run the last two "
            "kilometres. I arrived ten minutes late, out of breath, with my shirt stuck to my back. The "
            "receptionist smiled kindly and offered me a glass of water.",
            "The interview itself was nothing like the one I had imagined. The manager, a calm woman called "
            "Priya, did not ask a single question from my list. Instead, she showed me a poster and asked me "
            "what I would change. I was nervous, but I explained my ideas honestly. Then she asked about a "
            "mistake I had made at university and what I had learned from it.",
            "Two days later, Priya phoned to offer me the job. Months afterwards, I asked her why she had chosen "
            "me, even though I had arrived late. \"You apologised, you didn't make excuses, and you told me what "
            "you really thought about the poster,\" she said. \"Skills can be taught. Honesty is harder.\"",
            "Since then, I have been on the other side of the table many times. My advice is simple: prepare, "
            "but don't learn a script. Interviewers want to meet a person, not a recording.",
        ],
        "glossary": [
            ("applied for", "solicité, me postulé para"),
            ("applications", "solicitudes, postulaciones"),
            ("thrilled", "emocionado, encantado"),
            ("strengths", "puntos fuertes"),
            ("weaknesses", "puntos débiles"),
            ("broke down", "se descompuso"),
            ("out of breath", "sin aliento"),
            ("apologised", "pediste disculpas"),
            ("make excuses", "poner excusas"),
        ],
        "questions": [
            mc("How did the writer feel when the studio called?",
               ["Excited and scared at the same time", "Calm and confident", "Disappointed", "Bored"],
               "Dice: I was thrilled and terrified at the same time."),
            mc("Why did the writer arrive late?",
               ["The bus broke down", "The alarms didn't ring", "They got lost in the city", "They missed the train"],
               "Dice: My bus broke down halfway."),
            tf("The manager asked all the questions the writer had prepared.", False,
               "Dice: did not ask a single question from my list."),
            mc("What did Priya ask the writer to do with the poster?",
               ["Say what they would change", "Design a new one", "Describe its colours", "Find the mistakes in it"],
               "Dice: she showed me a poster and asked me what I would change."),
            mc("According to Priya, why did she choose the writer?",
               ["Because they were honest", "Because they had the best degree",
                "Because they arrived early", "Because they knew the answers by heart"],
               "Dice: You apologised, you didn't make excuses... Honesty is harder."),
            tf("The writer has interviewed other people since then.", True,
               "Dice: I have been on the other side of the table many times."),
            fill("Complete Priya's words: \"Skills can be ___. Honesty is harder.\"", "taught",
                 "Dice: Skills can be taught."),
            mc("What is the writer's main advice?",
               ["Prepare, but don't memorise a script", "Always arrive very early",
                "Learn answers to typical questions by heart", "Wear your best clothes"],
               "Dice: prepare, but don't learn a script."),
        ],
        "task": "Cuenta en 80–100 palabras una entrevista, un examen oral o una prueba importante que hayas tenido: "
        "cómo te preparaste, qué pasó y qué aprendiste. Usa el pasado simple y el past perfect.",
        "summary": "The writer had a difficult first job interview: the bus broke down and they arrived late. "
        "The manager didn't ask the expected questions but asked for honest opinions. The writer got the job "
        "because they were honest and didn't make excuses. Their advice is to prepare without learning a script.",
    },
    {
        "id": "b1-coffee",
        "title": "How coffee conquered the world",
        "title_es": "Cómo el café conquistó el mundo",
        "topic": "Cultura y tradiciones",
        "paragraphs": [
            "Every day, people around the world drink more than two billion cups of coffee. But how did a small "
            "red fruit from the hills of Africa become one of the most popular drinks on the planet?",
            "According to a famous legend, a goat herder in Ethiopia called Kaldi noticed that his goats became "
            "unusually lively after eating the fruit of a certain bush. Historians are not sure that the story "
            "is true, but they agree that coffee plants first grew wild in Ethiopia.",
            "By the fifteenth century, people in Yemen were roasting the beans and making a drink from them. "
            "Religious men drank it to stay awake during long night prayers. From there, coffee spread to Mecca, "
            "Cairo and Istanbul, where the first coffee houses opened. They quickly became places to meet "
            "friends, play games, listen to music and discuss the news.",
            "In the seventeenth century, coffee arrived in Europe. Not everyone welcomed it: some people called "
            "it \"the bitter invention of Satan\". Even so, coffee houses opened in Venice, London, Paris and "
            "Vienna. In London they were nicknamed \"penny universities\", because for the price of a cup you "
            "could listen to conversations about science, politics and business. One of them, owned by Edward "
            "Lloyd, became the famous insurance market that still carries his name.",
            "European countries soon started growing coffee in their colonies, from Indonesia to Brazil, often "
            "using the forced labour of enslaved people. Brazil is still the world's largest producer today.",
            "Today coffee is a huge industry, but for many small farmers life is hard, because prices change a "
            "lot from year to year. That is why some people choose \"fair trade\" coffee, which promises farmers a "
            "minimum price. So next time you drink a cup, remember the long journey behind it.",
        ],
        "glossary": [
            ("goat herder", "pastor de cabras"),
            ("lively", "animado, inquieto"),
            ("roasting", "tostando"),
            ("beans", "granos"),
            ("spread", "se extendió"),
            ("nicknamed", "apodados"),
            ("insurance", "seguros"),
            ("enslaved people", "personas esclavizadas"),
            ("fair trade", "comercio justo"),
        ],
        "questions": [
            mc("Where did coffee plants first grow wild?",
               ["In Ethiopia", "In Yemen", "In Brazil", "In Indonesia"],
               "Dice: coffee plants first grew wild in Ethiopia."),
            tf("Historians are certain that the story of Kaldi is true.", False,
               "Dice: Historians are not sure that the story is true."),
            mc("Why did religious men in Yemen drink coffee?",
               ["To stay awake during night prayers", "To feel less hungry",
                "Because it was cheaper than tea", "To cure illnesses"],
               "Dice: to stay awake during long night prayers."),
            mc("What did people do in the first coffee houses?",
               ["They met friends and discussed the news", "They grew coffee plants",
                "They studied at university", "They bought insurance"],
               "Dice: places to meet friends, play games, listen to music and discuss the news."),
            mc("Why were London coffee houses called \"penny universities\"?",
               ["For the price of a cup you could hear interesting conversations",
                "Students worked there to pay for university", "Teachers gave classes there for a penny",
                "They were built next to universities"],
               "Dice: for the price of a cup you could listen to conversations about science, politics and business."),
            fill("Which country is the world's largest producer of coffee today?", "Brazil",
                 "Dice: Brazil is still the world's largest producer today."),
            mc("What does fair trade coffee promise farmers?",
               ["A minimum price", "Free land", "Better weather", "Lower taxes"],
               "Dice: promises farmers a minimum price."),
            tf("Everyone in Europe welcomed coffee when it arrived.", False,
               "Algunos lo llamaron the bitter invention of Satan."),
        ],
        "task": "Escribe 80–100 palabras sobre una bebida o comida típica de tu país: de dónde viene, cómo se "
        "prepara y qué papel tiene en la vida social. Usa la voz pasiva al menos dos veces.",
        "summary": "Coffee plants first grew in Ethiopia, and people in Yemen started making the drink in the "
        "fifteenth century. Coffee houses spread through the Middle East and then Europe, where they became "
        "places for conversation and business. European colonies grew coffee, often with enslaved workers. "
        "Today it is a huge industry, but small farmers often have a hard life.",
    },
    {
        "id": "b1-rooftop-gardens",
        "title": "Gardens in the sky",
        "title_es": "Jardines en el cielo",
        "topic": "Medio ambiente",
        "paragraphs": [
            "Look up the next time you walk through a big city. Above the shops and offices, there may be a "
            "garden. In cities such as New York, Paris and Singapore, more and more roofs are being covered with "
            "plants, vegetables and even beehives.",
            "Rooftop gardens are not just pretty. A roof covered with plants absorbs rainwater, so less water "
            "runs into the streets during heavy storms. The plants also keep buildings cooler in summer and "
            "warmer in winter, which can reduce the energy needed for air conditioning and heating. In addition, "
            "they provide a home for birds, butterflies and bees.",
            "Some rooftop gardens are businesses. In Brooklyn, one farm grows tons of vegetables every year on "
            "top of old industrial buildings and sells them to local restaurants and families. Other gardens are "
            "run by volunteers who share the harvest. On the roof of a hospital in Boston, staff grow vegetables "
            "that are served to patients.",
            "However, creating a garden on a roof is not as easy as it sounds. The building has to be strong "
            "enough to support the weight of soil, water and people. The roof must be completely waterproof, "
            "and the gardeners need to think about strong winds and intense sun. All this can be expensive, so "
            "some cities offer grants or tax reductions to building owners who install green roofs.",
            "For many city dwellers, the biggest benefit is not the vegetables but the experience. \"After work, "
            "I come up here, pull out a few weeds and forget about my emails,\" says Lena, who looks after a "
            "small plot on a roof in Berlin. \"I've met more neighbours here than in ten years of living in this "
            "building.\"",
        ],
        "glossary": [
            ("beehives", "colmenas"),
            ("absorbs", "absorbe"),
            ("harvest", "cosecha"),
            ("support the weight", "soportar el peso"),
            ("soil", "tierra"),
            ("waterproof", "impermeable"),
            ("grants", "subsidios"),
            ("city dwellers", "habitantes de la ciudad"),
            ("weeds", "malas hierbas"),
        ],
        "questions": [
            mc("What happens to rainwater on a green roof?",
               ["The plants absorb it", "It runs into the streets faster", "It freezes", "It is sold"],
               "Dice: A roof covered with plants absorbs rainwater."),
            mc("How can rooftop gardens save energy?",
               ["They keep buildings cooler in summer and warmer in winter", "They produce electricity",
                "They make buildings smaller", "They stop people from using lifts"],
               "Dice: keep buildings cooler in summer and warmer in winter."),
            tf("The farm in Brooklyn sells its vegetables to restaurants and families.", True,
               "Dice: sells them to local restaurants and families."),
            mc("Who eats the vegetables grown on the hospital roof in Boston?",
               ["The patients", "The doctors' families", "Tourists", "Local schools"],
               "Dice: vegetables that are served to patients."),
            mc("Which of these is a difficulty mentioned in the text?",
               ["The building must support a lot of weight", "Plants don't grow in cities",
                "Neighbours don't like gardens", "Vegetables on roofs are poisonous"],
               "Dice: The building has to be strong enough to support the weight."),
            fill("Some cities offer ___ or tax reductions to owners who install green roofs.", "grants",
                 "Dice: some cities offer grants or tax reductions."),
            mc("For Lena, what is the biggest benefit of her rooftop plot?",
               ["Relaxing and meeting neighbours", "Saving money on food", "Selling vegetables", "Getting exercise"],
               "Habla de olvidarse de los mails y de conocer vecinos."),
            tf("According to the text, creating a rooftop garden is cheap and simple.", False,
               "Dice: is not as easy as it sounds... can be expensive."),
        ],
        "task": "Imagina que en tu edificio o escuela quieren hacer un jardín en la terraza. Escribe un mensaje "
        "de 80–100 palabras a los vecinos con ventajas, posibles problemas y una propuesta concreta.",
        "summary": "In many big cities, roofs are being turned into gardens. They absorb rainwater, save energy "
        "and give a home to birds and insects, and some are businesses or feed hospital patients. However, they "
        "need strong, waterproof roofs and can be expensive. For many people, the main benefit is relaxing and "
        "meeting neighbours.",
    },
    {
        "id": "b1-teen-sleep",
        "title": "Why teenagers can't get up",
        "title_es": "Por qué a los adolescentes les cuesta levantarse",
        "topic": "Salud",
        "paragraphs": [
            "Parents all over the world have the same complaint: their teenagers stay up late at night and are "
            "impossible to wake up in the morning. Many adults think this is simply laziness. Scientists, "
            "however, say the explanation is biological.",
            "Our bodies have an internal clock that tells us when to feel sleepy and when to feel awake. During "
            "adolescence, this clock moves later. The brain starts producing melatonin, the hormone that makes "
            "us sleepy, about two hours later than it did in childhood. As a result, many teenagers do not feel "
            "tired until eleven o'clock or midnight, even if they are exhausted.",
            "At the same time, sleep experts recommend that teenagers sleep between eight and ten hours a night. "
            "If school starts at eight o'clock and a student falls asleep at midnight, it is easy to see the "
            "problem. Lack of sleep has been linked to poor concentration, bad moods, weaker memory and more "
            "car accidents among young drivers.",
            "Some schools have decided to start later. In several places in the United States and Europe where "
            "classes begin at half past eight or nine, researchers have found that students sleep more, arrive "
            "late less often and pay more attention in class. Not everyone agrees, though: later start times "
            "can be difficult for parents who work early and for schools that share buses.",
            "Phones make things worse. The blue light from screens can delay sleep even more, and messages and "
            "videos keep the brain busy. Experts suggest switching off devices an hour before bed, keeping the "
            "same timetable at weekends and getting some sunlight in the morning.",
            "So, next time a teenager refuses to get out of bed, remember: it may not be laziness at all.",
        ],
        "glossary": [
            ("complaint", "queja"),
            ("laziness", "pereza"),
            ("internal clock", "reloj interno"),
            ("adolescence", "adolescencia"),
            ("exhausted", "agotados"),
            ("lack of sleep", "falta de sueño"),
            ("moods", "humores, estados de ánimo"),
            ("delay", "retrasar"),
            ("switching off", "apagar"),
        ],
        "questions": [
            mc("What do many adults think about teenagers who sleep late?",
               ["That they are lazy", "That they are ill", "That they study too much", "That they are worried"],
               "Dice: Many adults think this is simply laziness."),
            mc("What happens to the internal clock during adolescence?",
               ["It moves later", "It moves earlier", "It stops working", "It becomes irregular for ever"],
               "Dice: During adolescence, this clock moves later."),
            fill("Melatonin is the ___ that makes us sleepy.", "hormone",
                 "Dice: melatonin, the hormone that makes us sleepy."),
            mc("How many hours should teenagers sleep, according to experts?",
               ["Between eight and ten", "Between six and seven", "At least twelve", "Exactly seven"],
               "Dice: between eight and ten hours a night."),
            tf("Lack of sleep has been linked to more car accidents among young drivers.", True,
               "El texto lo menciona entre los efectos."),
            mc("What did researchers find in schools that start later?",
               ["Students sleep more and pay more attention", "Students go to bed even later",
                "Students get worse marks", "There is no difference"],
               "Dice: students sleep more, arrive late less often and pay more attention."),
            tf("Everyone agrees that schools should start later.", False,
               "Dice: Not everyone agrees, though."),
            mc("Which piece of advice is given in the text?",
               ["Switch off devices an hour before bed", "Sleep more at weekends",
                "Drink coffee in the morning", "Study late at night"],
               "Dice: switching off devices an hour before bed."),
        ],
        "task": "Escribe 80–100 palabras dando consejos a un amigo que duerme mal. Usa should, shouldn't, "
        "if you... y al menos una razón del texto.",
        "summary": "Teenagers often go to bed late and find it hard to get up, but scientists say this is "
        "biological: their internal clock moves later. They need eight to ten hours of sleep, and lack of sleep "
        "causes many problems. Some schools start later with good results, and experts advise switching off "
        "phones before bed.",
    },
    {
        "id": "b1-language-exchange",
        "title": "The tandem that changed my life",
        "title_es": "El tándem que me cambió la vida",
        "topic": "Aprender idiomas",
        "paragraphs": [
            "For years I studied English at school, but I could hardly hold a conversation. I knew the rules, I "
            "had done hundreds of exercises, and yet, when a tourist asked me for directions, my mind went blank.",
            "Everything changed when a friend told me about language exchanges, also called tandems. The idea "
            "is simple: two people who want to learn each other's language meet regularly and spend half of the "
            "time speaking one language and half speaking the other. There are no teachers and no exams. You "
            "just talk.",
            "My partner was Owen, a Welsh engineer who had just moved to my city and wanted to improve his "
            "Spanish. We met every Thursday in a café near the station. At first, it was awkward. I spoke slowly "
            "and kept apologising for my mistakes. Owen did the same in Spanish. After a few weeks, though, we "
            "stopped worrying and started laughing at our errors.",
            "We agreed on a few rules. We corrected each other only when a mistake made the message unclear, or "
            "when the other person asked. Each of us brought a topic to discuss, from football to politics. And "
            "we always wrote down three new expressions in a notebook.",
            "In six months, my English improved more than in six years at school. I learned phrases that are "
            "never in textbooks, like \"I'm knackered\" (I'm very tired) or \"it's not my cup of tea\". More "
            "importantly, I lost my fear of speaking.",
            "Owen went back to Wales two years ago, but we still talk online every month. Last summer I visited "
            "him in Cardiff, and he introduced me to his family as \"my teacher\". I told them the truth: we "
            "taught each other.",
        ],
        "glossary": [
            ("hold a conversation", "mantener una conversación"),
            ("went blank", "se quedó en blanco"),
            ("each other's", "el uno del otro"),
            ("awkward", "incómodo"),
            ("kept apologising", "no paraba de pedir disculpas"),
            ("unclear", "poco claro"),
            ("knackered", "reventado, muy cansado (coloquial británico)"),
            ("cup of tea", "lo mío (en not my cup of tea)"),
            ("introduced", "presentó"),
        ],
        "questions": [
            mc("What was the writer's problem with English at the beginning?",
               ["They couldn't speak, although they knew the rules", "They couldn't read",
                "They had never studied it", "They didn't like the teacher"],
               "Dice: I knew the rules... and yet... my mind went blank."),
            mc("How does a language exchange work?",
               ["Two people practise each other's languages", "A teacher gives free classes",
                "You study online with exercises", "You travel to another country"],
               "El texto lo explica en el segundo párrafo."),
            fill("Owen is an engineer from which country?", ["Wales"], "Dice: a Welsh engineer... went back to Wales."),
            tf("From the first day, the meetings were relaxed and easy.", False,
               "Dice: At first, it was awkward."),
            mc("When did they correct each other?",
               ["When a mistake made the message unclear or the other person asked", "After every sentence",
                "Never", "Only in writing"],
               "Es una de sus reglas."),
            mc("What does \"I'm knackered\" mean?",
               ["I'm very tired", "I'm very happy", "I'm hungry", "I'm confused"],
               "El texto lo explica entre paréntesis."),
            mc("According to the writer, what was the most important result?",
               ["They lost their fear of speaking", "They passed an exam",
                "They got a job in Wales", "They learned grammar rules"],
               "Dice: More importantly, I lost my fear of speaking."),
            tf("The writer and Owen are still in contact.", True,
               "Dice: we still talk online every month."),
        ],
        "task": "Escribe un anuncio de 70–90 palabras para buscar un compañero de tándem: quién eres, qué idioma "
        "ofreces y buscas, tus temas favoritos y cuándo puedes reunirte.",
        "summary": "The writer had studied English for years but couldn't speak it. Then they started a language "
        "exchange with Owen, a Welsh engineer learning Spanish. They met every week, followed a few simple "
        "rules and soon lost their fear of making mistakes. The writer improved a lot and they are still "
        "friends.",
    },
    {
        "id": "b1-phone-free-school",
        "title": "A school without smartphones",
        "title_es": "Una escuela sin celulares",
        "topic": "Tecnología",
        "paragraphs": [
            "When the headteacher of a secondary school in the north of England announced that phones would be "
            "banned during the school day, many students were furious. \"How will my parents contact me?\" asked "
            "one. \"It's like going back to the Stone Age,\" complained another.",
            "The rule was simple. Students could bring their phones, but they had to switch them off and lock "
            "them in a special pouch when they arrived. The pouches could only be opened at the end of the day. "
            "In an emergency, parents could call the school office, as they did in the past.",
            "The first weeks were difficult. Some students tried to hide a second phone, and teachers had to "
            "deal with complaints every morning. But slowly, things changed. At lunchtime, the playground "
            "became noisier: instead of looking at screens, students were talking, playing football and even "
            "playing cards.",
            "A year later, the school published some results. There were fewer fights and fewer cases of online "
            "bullying during school hours. Teachers said that students concentrated better in class, and exam "
            "results improved slightly. However, the head admitted that it was impossible to know if the phone "
            "ban was the only reason.",
            "Not everyone is convinced. Some experts argue that schools should teach young people to use "
            "technology responsibly, not simply take it away. Phones can also be useful in lessons, for example "
            "to look up information or record a project.",
            "Interestingly, many students changed their minds. \"I hated it at first,\" says Maya, who is "
            "fifteen. \"Now I actually like having a break from my phone. I don't feel I have to answer every "
            "message immediately.\"",
        ],
        "glossary": [
            ("headteacher", "director/a de escuela"),
            ("banned", "prohibidos"),
            ("furious", "furiosos"),
            ("pouch", "funda, bolsita"),
            ("deal with", "lidiar con, ocuparse de"),
            ("playground", "patio de la escuela"),
            ("bullying", "acoso"),
            ("slightly", "ligeramente"),
            ("responsibly", "con responsabilidad"),
        ],
        "questions": [
            mc("How did many students react to the new rule at first?",
               ["They were very angry", "They were happy", "They didn't care", "They left the school"],
               "Dice: many students were furious."),
            mc("What did students have to do with their phones?",
               ["Switch them off and lock them in a pouch", "Leave them at home",
                "Give them to the teachers", "Use them only in class"],
               "Dice: switch them off and lock them in a special pouch."),
            tf("Parents could no longer contact the school in an emergency.", False,
               "Podían llamar a la oficina de la escuela."),
            mc("What changed at lunchtime?",
               ["Students talked and played more", "Students studied more",
                "Students left the school", "The playground became quieter"],
               "Dice: the playground became noisier... students were talking, playing..."),
            fill("There were fewer cases of online ___ during school hours.", "bullying",
                 "Dice: fewer cases of online bullying."),
            mc("What did the head admit about the results?",
               ["The phone ban might not be the only reason", "The results were invented",
                "Exam results got worse", "The experiment failed"],
               "Dice: it was impossible to know if the phone ban was the only reason."),
            mc("What do some experts think?",
               ["Schools should teach responsible use of technology", "Phones should be banned everywhere",
                "Students should have two phones", "Teachers should use more phones"],
               "Dice: schools should teach young people to use technology responsibly."),
            tf("Maya still hates the rule.", False, "Dice: Now I actually like having a break."),
        ],
        "task": "¿Prohibirías los celulares en las escuelas? Escribe 90–110 palabras con tu opinión, dos "
        "argumentos y una respuesta a una posible objeción (however, on the other hand...).",
        "summary": "An English secondary school banned phones during the school day: students had to lock them "
        "in a pouch. At first students were angry, but soon they talked and played more, and there were fewer "
        "fights and less online bullying. Some experts think schools should teach responsible use instead, but "
        "many students, like Maya, now like the break.",
    },
    {
        "id": "b1-marathon",
        "title": "From the sofa to the marathon",
        "title_es": "Del sillón a la maratón",
        "topic": "Deporte",
        "paragraphs": [
            "Three years ago, Tom Hughes could not run for a bus. He was forty-five, he worked long hours in an "
            "office, and his only exercise was walking to the car. Then his doctor gave him a warning: his blood "
            "pressure was too high, and he needed to change his lifestyle.",
            "Tom decided to try running, but he started very carefully. He downloaded a free beginners' "
            "programme that combined one minute of running with ninety seconds of walking, three times a week. "
            "\"The first day, I thought I was going to die,\" he laughs. \"After sixty seconds I was completely "
            "out of breath.\"",
            "Little by little, the running periods got longer. After nine weeks, he could run for thirty "
            "minutes without stopping. He joined a local running club, where he met people of all ages and "
            "abilities. \"Nobody cared how slow I was,\" he says. \"They just cheered when I finished.\"",
            "Encouraged by his new friends, Tom set himself a bigger goal: a full marathon, 42.2 kilometres. He "
            "trained for eight months, increasing the distance gradually and learning about rest, food and "
            "proper shoes. He also learned to listen to his body; when his knee started to hurt, he stopped for "
            "two weeks instead of ignoring the pain.",
            "Last April, Tom crossed the finish line of the London Marathon in five hours and twelve minutes. "
            "\"I wasn't fast, but I didn't walk once,\" he says proudly. His blood pressure is now normal, and he "
            "has lost fifteen kilos.",
            "His advice for beginners? \"Start slower than you think you need to, find people to run with, and "
            "celebrate small victories. Nobody becomes a runner in a week.\"",
        ],
        "glossary": [
            ("warning", "advertencia"),
            ("blood pressure", "presión arterial"),
            ("beginners", "principiantes"),
            ("little by little", "poco a poco"),
            ("cheered", "aplaudían, alentaban"),
            ("encouraged", "animado"),
            ("gradually", "gradualmente"),
            ("finish line", "línea de llegada"),
            ("victories", "victorias, logros"),
        ],
        "questions": [
            mc("Why did Tom start running?",
               ["His doctor warned him about his health", "He wanted to win a race",
                "His friends were runners", "He lost his car"],
               "Dice: his doctor gave him a warning."),
            mc("How did his beginners' programme work?",
               ["It mixed short runs with walking", "He ran 5 km every day",
                "He ran only at weekends", "He trained with a personal coach"],
               "Un minuto corriendo y noventa segundos caminando."),
            fill("After nine weeks, he could run for ___ minutes without stopping.", "thirty",
                 "Dice: he could run for thirty minutes without stopping."),
            tf("The people at the running club criticised Tom for being slow.", False,
               "Dice: Nobody cared how slow I was."),
            mc("What did Tom do when his knee started to hurt?",
               ["He stopped running for two weeks", "He ran faster", "He ignored the pain", "He gave up running"],
               "Dice: he stopped for two weeks instead of ignoring the pain."),
            mc("How long did it take him to finish the marathon?",
               ["Five hours and twelve minutes", "Three hours", "Eight months", "Forty-two minutes"],
               "Dice: in five hours and twelve minutes."),
            tf("Tom walked part of the marathon.", False, "Dice: I didn't walk once."),
            mc("Which of these is part of Tom's advice?",
               ["Start slower than you think", "Run alone", "Train every day", "Buy expensive shoes"],
               "Dice: Start slower than you think you need to."),
        ],
        "task": "Escribe 80–100 palabras sobre un objetivo difícil que te propusiste (o que te gustaría "
        "proponerte): cómo empezaste, qué dificultades hubo y qué consejo darías. Usa used to, managed to.",
        "summary": "At forty-five, Tom couldn't run and his blood pressure was too high. He started a careful "
        "beginners' programme, joined a friendly running club and trained for eight months. He finished the "
        "London Marathon in just over five hours and is now much healthier. He advises beginners to start "
        "slowly and celebrate small victories.",
    },
    {
        "id": "b1-street-food",
        "title": "Street food: the world on a plate",
        "title_es": "Comida callejera: el mundo en un plato",
        "topic": "Comida y bebida",
        "paragraphs": [
            "If you want to understand a country, some travellers say, don't go to its expensive restaurants: "
            "eat in its streets. Street food is cheap, fast and often delicious, and it tells you a lot about "
            "the history and daily life of a place.",
            "In Mexico City, millions of people start the day with tacos or tamales bought from a stall on the "
            "pavement. In Bangkok, vendors push carts full of noodles, grilled meat and fresh fruit along busy "
            "roads until late at night. In Istanbul, you can buy grilled fish sandwiches from boats on the "
            "Bosphorus, and in Buenos Aires the smell of choripán fills the air near football stadiums.",
            "Street food is not new. In ancient Rome, most people lived in small flats without kitchens, so they "
            "bought hot food from street counters. Many famous dishes began as cheap food for workers: pizza in "
            "Naples, for example, was sold in the streets to poor families.",
            "Today, street food is also big business. Food markets and food trucks have become fashionable, and "
            "some street vendors have even received international awards. In Singapore, the government has "
            "built special food centres where hundreds of stalls work under the same roof, with rules about "
            "hygiene and prices.",
            "However, some cities have tried to remove street vendors, saying that they block the pavements or "
            "are not hygienic enough. Vendors reply that they provide affordable meals and that many families "
            "depend on this income.",
            "For travellers, a few tips can help: choose busy stalls, where the food is cooked fresh in front of "
            "you, and watch what local people order. And don't be afraid to point and smile if you don't know "
            "the name of a dish.",
        ],
        "glossary": [
            ("stall", "puesto"),
            ("pavement", "vereda, acera"),
            ("vendors", "vendedores"),
            ("carts", "carritos"),
            ("counters", "mostradores"),
            ("food trucks", "camiones de comida"),
            ("awards", "premios"),
            ("affordable", "accesibles, baratos"),
            ("income", "ingresos"),
        ],
        "questions": [
            mc("According to some travellers, where should you eat to understand a country?",
               ["In the streets", "In expensive restaurants", "In hotels", "At home"],
               "Dice: don't go to its expensive restaurants: eat in its streets."),
            mc("What can you buy from boats in Istanbul?",
               ["Grilled fish sandwiches", "Tacos", "Noodles", "Pizza"],
               "Dice: grilled fish sandwiches from boats on the Bosphorus."),
            mc("Why did people in ancient Rome buy food in the street?",
               ["Their flats had no kitchens", "It was healthier", "Restaurants were forbidden", "Food was free"],
               "Dice: small flats without kitchens."),
            fill("Pizza began as cheap food for poor families in which city?", "Naples",
                 "Dice: pizza in Naples."),
            tf("Some street vendors have won international awards.", True,
               "Dice: some street vendors have even received international awards."),
            mc("What has the government of Singapore done?",
               ["Built food centres with rules about hygiene and prices", "Banned street food",
                "Closed all food markets", "Given free food to tourists"],
               "Lo explica el cuarto párrafo."),
            mc("Why do some cities want to remove street vendors?",
               ["They say vendors block pavements or aren't hygienic", "Vendors don't pay for electricity",
                "Tourists don't like them", "They sell foreign food"],
               "Dice: they block the pavements or are not hygienic enough."),
            tf("The text advises travellers to choose empty stalls.", False, "Aconseja elegir puestos con mucha gente."),
        ],
        "task": "Describe en 80–100 palabras un plato callejero o una comida rápida típica de tu ciudad para un "
        "turista: qué es, dónde se compra, cuánto cuesta y por qué debería probarlo.",
        "summary": "Street food is cheap and tasty and shows the history and daily life of a place, from tacos in "
        "Mexico City to choripán in Buenos Aires. It is very old: people in ancient Rome bought food in the "
        "street, and pizza began as food for the poor. Today it is a big business, although some cities want "
        "to remove vendors.",
    },
    {
        "id": "b1-ghost-town",
        "title": "A night in a ghost town",
        "title_es": "Una noche en un pueblo fantasma",
        "topic": "Viajes",
        "paragraphs": [
            "We were driving across the desert in Nevada when the warning light came on. My friend Carla looked "
            "at the map on her phone, but there was no signal. The last petrol station we had passed was sixty "
            "miles behind us, and the sun was already going down.",
            "A few minutes later, we saw a sign: Rhyolite. Behind it there were the ruins of a town: a bank "
            "without a roof, an empty railway station and a strange house made of thousands of glass bottles. "
            "We decided to stop there and wait for a passing car.",
            "Later we learned the town's story. In 1904, gold was found in the hills nearby, and in just a few "
            "years Rhyolite grew into a busy town of several thousand people, with shops, hotels, a hospital and "
            "even an opera house. But the gold ran out quickly, a financial crisis hit, and by 1920 almost "
            "everyone had left.",
            "That night, nobody passed. We sat in the car and ate the only food we had: a packet of crisps and "
            "two apples. The silence was incredible. Every time the wind moved a piece of metal, Carla jumped. "
            "\"It's just the wind,\" I said, although I wasn't completely sure myself.",
            "At around midnight, we saw lights moving among the ruins. My heart was beating fast. Then we heard "
            "voices speaking in German. It was a group of photographers who had come to take pictures of the "
            "stars. They laughed when we told them we had thought they were ghosts, and in the morning they "
            "lent us enough petrol to reach the next town.",
            "I have travelled a lot since then, but that night under the desert sky is still my favourite "
            "travel story.",
        ],
        "glossary": [
            ("warning light", "luz de advertencia"),
            ("signal", "señal"),
            ("ruins", "ruinas"),
            ("ran out", "se acabó"),
            ("crisps", "papas fritas de paquete"),
            ("jumped", "se sobresaltó"),
            ("among", "entre"),
            ("lent", "prestaron"),
        ],
        "questions": [
            mc("Why did the writer and Carla stop in Rhyolite?",
               ["They had a problem with the car and no signal", "They wanted to visit the museum",
                "They were looking for gold", "They had booked a hotel there"],
               "Se encendió la luz de advertencia y no había señal."),
            mc("What unusual building did they see?",
               ["A house made of glass bottles", "A glass bank", "A castle", "A wooden church"],
               "Dice: a strange house made of thousands of glass bottles."),
            fill("Rhyolite grew quickly after ___ was found in the hills nearby.", "gold",
                 "Dice: In 1904, gold was found in the hills nearby."),
            tf("Rhyolite once had an opera house.", True, "Dice: and even an opera house."),
            mc("Why did people leave Rhyolite?",
               ["The gold ran out and there was a financial crisis", "There was a big fire",
                "A flood destroyed it", "The railway closed"],
               "Dice: the gold ran out quickly, a financial crisis hit."),
            mc("What did they eat that night?",
               ["Crisps and two apples", "Nothing at all", "Sandwiches from the photographers", "Pizza"],
               "Dice: a packet of crisps and two apples."),
            mc("Who were the lights in the ruins?",
               ["Photographers taking pictures of the stars", "Police officers", "Ghosts", "Other lost drivers"],
               "Era un grupo de fotógrafos."),
            tf("The photographers took them to the next town in their car.", False,
               "Les prestaron nafta (petrol) para llegar."),
        ],
        "task": "Cuenta en 90–110 palabras un viaje en el que algo salió mal. Usa el pasado simple, el pasado "
        "continuo y al menos un past perfect (had + participio).",
        "summary": "While driving through the Nevada desert, the writer and Carla had a car problem near Rhyolite, "
        "a ghost town. The town had grown quickly after gold was found in 1904 but was abandoned when the gold "
        "ran out. They spent a frightening night in the car until some photographers appeared and lent them "
        "petrol in the morning.",
    },
    {
        "id": "b1-second-hand",
        "title": "The second-hand clothes boom",
        "title_es": "El auge de la ropa de segunda mano",
        "topic": "Consumo",
        "paragraphs": [
            "Not long ago, wearing second-hand clothes was something many people did only when they had no "
            "money. Today it has become fashionable. Apps for selling used clothes have millions of users, and "
            "vintage shops are full of young customers looking for something different.",
            "One reason is the price. A designer jacket that costs hundreds of pounds when it is new can be "
            "found for a fraction of that online. But money is not the only motivation. Many shoppers say they "
            "are worried about the environment.",
            "The fashion industry has a serious impact on the planet. Producing new clothes uses huge amounts "
            "of water and energy, and many garments are made from synthetic materials that come from oil. "
            "\"Fast fashion\" brands produce new collections every few weeks, at very low prices, so people buy "
            "more and throw away more. Every year, millions of tonnes of clothes end up in landfills or are "
            "burned.",
            "Buying second-hand helps, because it makes clothes last longer. If a T-shirt is worn by two "
            "people instead of one, fewer new T-shirts need to be made. Some people go further and organise "
            "swap parties, where friends exchange clothes they no longer wear.",
            "Not everyone is enthusiastic, though. Some critics point out that people who buy cheap second-hand "
            "clothes online often buy more than they need, so they don't really consume less. Others worry that "
            "charity shops, which used to sell cheap clothes to people on low incomes, are now more expensive "
            "because of the demand.",
            "Still, for many young people, a second-hand wardrobe is a way of showing their values. As one "
            "student put it: \"I like knowing that my favourite coat already has a story.\"",
        ],
        "glossary": [
            ("second-hand", "de segunda mano"),
            ("vintage", "antiguo, de época"),
            ("a fraction", "una fracción, una pequeña parte"),
            ("garments", "prendas"),
            ("landfills", "basurales, rellenos sanitarios"),
            ("swap parties", "fiestas de intercambio"),
            ("charity shops", "tiendas benéficas"),
            ("demand", "demanda"),
            ("wardrobe", "guardarropa"),
        ],
        "questions": [
            mc("How has the image of second-hand clothes changed?",
               ["It has become fashionable", "It has become illegal", "Nobody buys them any more",
                "Only older people buy them"],
               "Dice: Today it has become fashionable."),
            mc("Besides price, why do many people buy second-hand clothes?",
               ["They are worried about the environment", "They are better quality",
                "They are easier to find", "Shops give them away"],
               "Dice: Many shoppers say they are worried about the environment."),
            fill("Many garments are made from synthetic materials that come from ___.", "oil",
                 "Dice: synthetic materials that come from oil."),
            mc("What is a characteristic of fast fashion?",
               ["New collections every few weeks at low prices", "Clothes that last for years",
                "Handmade, expensive clothes", "Clothes made only from cotton"],
               "Lo explica el tercer párrafo."),
            tf("Every year, millions of tonnes of clothes end up in landfills or are burned.", True,
               "El texto lo afirma."),
            mc("What happens at a swap party?",
               ["Friends exchange clothes", "People buy new designer clothes",
                "Old clothes are burned", "Clothes are repaired for money"],
               "Dice: friends exchange clothes they no longer wear."),
            mc("What is one criticism mentioned in the text?",
               ["People may buy more than they need", "Second-hand clothes are dangerous",
                "Apps are too slow", "Vintage clothes are ugly"],
               "Dice: often buy more than they need."),
            tf("According to critics, charity shops have become cheaper.", False,
               "Se volvieron más caras por la demanda."),
        ],
        "task": "Escribe 90–110 palabras sobre tu forma de comprar ropa: ¿compras de segunda mano? ¿Qué harías para "
        "consumir menos? Usa comparativos y al menos un condicional.",
        "summary": "Second-hand clothes have become fashionable, partly because they are cheaper and partly for "
        "environmental reasons. The fashion industry uses a lot of water and energy, and fast fashion makes "
        "people throw away many clothes. Buying second-hand makes clothes last longer, but critics say people "
        "may still buy too much and charity shops have become more expensive.",
    },
    {
        "id": "b1-library-of-things",
        "title": "The library of things",
        "title_es": "La biblioteca de cosas",
        "topic": "Personas y vecinos",
        "paragraphs": [
            "How many times have you used your drill? If you are like most people, the answer is \"almost "
            "never\". Yet millions of homes have one, along with ladders, tents, sewing machines and other "
            "objects that spend most of their lives in a cupboard.",
            "A few years ago, a group of neighbours in a London suburb had an idea: what if people could borrow "
            "these things, just like books from a library? They collected donations, found a small room in a "
            "community centre and opened a \"library of things\".",
            "It works like this. Members pay a small yearly fee, or nothing if they can't afford it. They can "
            "then borrow a drill for the weekend, a projector for a party or a tent for a camping trip. When "
            "they bring the item back, volunteers check that it works and clean it for the next person.",
            "The project has grown quickly. Similar libraries now exist in dozens of towns in Europe and North "
            "America. Supporters say they save money, reduce waste and free up space in small homes. \"Why buy "
            "a carpet cleaner you'll use twice a year?\" asks Grace, one of the founders.",
            "But the founders say the biggest surprise was social. Volunteers run free workshops where people "
            "learn to repair a bicycle or fix a broken lamp. Older members teach younger ones how to use "
            "tools, and people who live on the same street meet for the first time. \"People come to borrow a "
            "ladder and stay for a cup of tea,\" Grace laughs.",
            "Of course, there are problems. Some items come back broken, and finding volunteers is not always "
            "easy. Still, the idea is spreading, and many people now think twice before buying something they "
            "will hardly ever use.",
        ],
        "glossary": [
            ("drill", "taladro"),
            ("ladders", "escaleras de mano"),
            ("sewing machines", "máquinas de coser"),
            ("borrow", "pedir prestado"),
            ("donations", "donaciones"),
            ("fee", "cuota"),
            ("free up space", "liberar espacio"),
            ("workshops", "talleres"),
            ("think twice", "pensarlo dos veces"),
        ],
        "questions": [
            mc("What is the problem with objects like drills and ladders?",
               ["People rarely use them", "They are too expensive to repair",
                "They are dangerous", "They break easily"],
               "Pasan casi toda su vida en un armario."),
            mc("Where did the first library of things open?",
               ["In a community centre in a London suburb", "In a public library in New York",
                "In a shop in Paris", "In a school"],
               "Dice: a small room in a community centre."),
            tf("Members who can't afford the fee can still join.", True,
               "Dice: or nothing if they can't afford it."),
            mc("What do volunteers do when an item is returned?",
               ["Check that it works and clean it", "Sell it", "Throw it away", "Paint it"],
               "Lo dice el tercer párrafo."),
            fill("Supporters say these libraries save money, reduce ___ and free up space.", "waste",
                 "Dice: save money, reduce waste and free up space."),
            mc("What was the biggest surprise for the founders?",
               ["The social side of the project", "How much money they made",
                "That nobody borrowed anything", "That the council closed it"],
               "Dice: the biggest surprise was social."),
            mc("What can people learn at the free workshops?",
               ["To repair bicycles and lamps", "To sew clothes for sale", "To build houses", "To cook"],
               "Dice: learn to repair a bicycle or fix a broken lamp."),
            tf("The project has no problems at all.", False,
               "Algunos objetos vuelven rotos y faltan voluntarios."),
        ],
        "task": "Propón en 80–100 palabras un proyecto para tu barrio que ayude a los vecinos a compartir algo "
        "(objetos, conocimientos, tiempo). Explica cómo funcionaría usando could, would y if.",
        "summary": "Many objects like drills and ladders are hardly ever used, so neighbours in a London suburb "
        "opened a library of things where members borrow them for a small fee. The idea has spread to many "
        "towns because it saves money, reduces waste and frees up space. Its biggest benefit is social, although "
        "some items come back broken.",
    },
    {
        "id": "b1-wrong-parcel",
        "title": "The wrong parcel",
        "title_es": "El paquete equivocado",
        "topic": "Ficción",
        "paragraphs": [
            "The parcel arrived on a rainy Tuesday. Jamie had been waiting for new headphones, so when the "
            "delivery driver handed him a box, he signed without looking and ran upstairs.",
            "Inside there were no headphones. Instead, he found an old leather notebook, a key with a red "
            "ribbon and a black and white photograph of a lighthouse. The address on the label was his, but "
            "the name was not: \"For Mrs E. Hart\".",
            "Jamie had lived in the flat for only three months. He went downstairs to ask his neighbour, Mr "
            "Okafor, who had lived in the building for thirty years. When he saw the name, the old man went "
            "quiet. \"Edith Hart lived in your flat before you,\" he said. \"She died last winter. She had no "
            "family. At least, none that we knew about.\"",
            "That night, Jamie opened the notebook. It was a diary from 1968. The writer was a young woman "
            "working in a lighthouse in Cornwall with her father. On the last page, someone had written a "
            "phone number and a message: \"If you ever want to know the truth, call me. — S.\"",
            "Jamie knew he should give the parcel to the police or send it back. But he couldn't stop thinking "
            "about it. After two days, he dialled the number. An elderly man answered. When Jamie mentioned "
            "Edith's name, there was a long silence. Then the man said, very softly, \"Did she get my parcel? I "
            "sent it so she would finally know she had a brother.\"",
            "Jamie explained what had happened. The man began to cry. A month later, Jamie took the train to "
            "Cornwall with the box under his arm. He had a lot of questions, and for the first time, someone "
            "was ready to answer them.",
        ],
        "glossary": [
            ("parcel", "paquete"),
            ("handed", "entregó"),
            ("leather", "de cuero"),
            ("ribbon", "cinta"),
            ("label", "etiqueta"),
            ("went quiet", "se quedó callado"),
            ("diary", "diario"),
            ("dialled", "marcó"),
            ("elderly", "anciano"),
        ],
        "questions": [
            mc("What was Jamie expecting?",
               ["New headphones", "A notebook", "A letter from his family", "A key"],
               "Dice: Jamie had been waiting for new headphones."),
            mc("Who was the parcel addressed to?",
               ["Mrs E. Hart", "Jamie", "Mr Okafor", "S."],
               "Dice: For Mrs E. Hart."),
            tf("Edith Hart was still living in the building.", False,
               "Dice: She died last winter."),
            fill("In the parcel there was a black and white photograph of a ___.", "lighthouse",
                 "Dice: a black and white photograph of a lighthouse."),
            mc("Where did the young woman in the diary work?",
               ["In a lighthouse in Cornwall", "In a library in London",
                "In a post office", "On a fishing boat"],
               "Dice: working in a lighthouse in Cornwall with her father."),
            mc("Why had the man sent the parcel?",
               ["So that Edith would know she had a brother", "To ask Edith for money",
                "To return a key he had borrowed", "To sell the lighthouse"],
               "Dice: so she would finally know she had a brother."),
            tf("Jamie gave the parcel to the police.", False,
               "Llamó al número y luego viajó a Cornwall."),
            mc("How does the story end?",
               ["Jamie travels to Cornwall to meet the man", "Jamie throws the box away",
                "Edith's brother visits Jamie in London", "Mr Okafor takes the parcel"],
               "Dice: Jamie took the train to Cornwall with the box under his arm."),
        ],
        "task": "Continúa la historia en 100–120 palabras: ¿qué pasa cuando Jamie llega a Cornwall? Usa diálogos "
        "y al menos dos tiempos del pasado.",
        "summary": "Jamie received a parcel addressed to Edith Hart, the woman who had lived in his flat and died "
        "the winter before. Inside were a diary from 1968, a key and a photo of a lighthouse. Jamie called the "
        "number in the diary and discovered that the sender was Edith's brother, who had wanted her to know "
        "about him. Jamie decided to take the box to him in Cornwall.",
    },
]

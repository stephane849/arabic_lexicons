package io.github.stephane849.arabic_lexicons_kompakt.data

/**
 * The ten verb forms, ported from the Flutter app's
 * `lib/pages/fams/fams_data.dart` — the reference Hans Wehr assumes when
 * it lists a root's derived forms by Roman numeral, and leaves you to
 * know what II or VII implies.
 *
 * Generated from that file rather than retyped, so the vocalized Arabic
 * is character-for-character the original's.
 */
data class VerbExample(val arabic: String, val literal: String)

data class VerbForm(
    val form: String,
    val pattern: String,
    val rootExample: String,
    val commonMeaning: String,
    val transitivity: String,
    val explanation: String,
    val morphologyNote: String,
    val examples: List<VerbExample>,
)

data class GrammarTerm(val term: String, val definition: String)

val VERB_FORMS: List<VerbForm> = listOf(
    VerbForm(
        form = "I",
        pattern = "فَعَلَ",
        rootExample = "ك ت ب",
        commonMeaning = "Basic root meaning.",
        transitivity = "Both",
        explanation = "The base form. It carries the core lexical meaning. It can be transitive (needs an object) or intransitive depending strictly on the root.",
        morphologyNote = "Pure triliteral root without additional letters.",
        examples = listOf(
            VerbExample("كَتَبَ الرَّجُلُ الرِّسَالَةَ", "The man wrote the letter"),
            VerbExample("جَلَسَ الطِّفْلُ عَلَى الكُرْسِيِّ", "The child sat on the chair"),
            VerbExample("ذَهَبَ الطَّالِبُ إِلَى الْمَدْرَسَةِ", "The student went to school"),
        ),
    ),
    VerbForm(
        form = "II",
        pattern = "فَعَّلَ",
        rootExample = "ع ل م",
        commonMeaning = "Causative or Intensive.",
        transitivity = "Transitive",
        explanation = "Often makes an intransitive root transitive (Causative). It can also indicate doing the action repeatedly or violently (Intensive).",
        morphologyNote = "Gemination (shadda) on the middle root letter (Ayin).",
        examples = listOf(
            VerbExample("عَلَّمَ المُدَرِّسُ الطُّلَّابَ", "The teacher taught the students (caused them to know)"),
            VerbExample("كَسَّرَ الزُّجَاجَ", "He smashed the glass to pieces (Intensive of 'broke')"),
        ),
    ),
    VerbForm(
        form = "III",
        pattern = "فَاعَلَ",
        rootExample = "ق ت ل",
        commonMeaning = "Interaction / Reciprocity.",
        transitivity = "Transitive",
        explanation = "Implies an action done towards another entity, often suggesting an attempt or interaction.",
        morphologyNote = "Alif added after the first root letter.",
        examples = listOf(
            VerbExample("قَاتَلَ الجُنْدِيُّ العَدُوَّ", "The soldier fought the enemy"),
            VerbExample("شَارَكَ المُوَظَّفُ فِي الاِجْتِمَاعِ", "The employee participated in the meeting"),
            VerbExample("سَافَرَ الرَّجُلُ", "The man traveled (journeyed through space)"),
        ),
    ),
    VerbForm(
        form = "IV",
        pattern = "أَفْعَلَ",
        rootExample = "خ ر ج",
        commonMeaning = "Causative.",
        transitivity = "Transitive",
        explanation = "The standard causative form. It makes an intransitive verb transitive, or a transitive verb doubly transitive.",
        morphologyNote = "Prefixed Hamza (أَ) before the root.",
        examples = listOf(
            VerbExample("أَخْرَجَ المُعَلِّمُ الكِتَابَ", "The teacher brought out the book"),
            VerbExample("أَرْسَلَ اللهُ الرُّسُلَ", "Allah sent the messengers"),
            VerbExample("أَكْرَمَ الْمُضِيفُ الضَّيْفَ", "The host honored the guest"),
        ),
    ),
    VerbForm(
        form = "V",
        pattern = "تَفَعَّلَ",
        rootExample = "ع ل م",
        commonMeaning = "Reflexive of II / Gradualness.",
        transitivity = "Intransitive",
        explanation = "Often the result of Form II. Can also imply gradualness or doing something with effort.",
        morphologyNote = "Prefix (تَ) plus the gemination of Form II.",
        examples = listOf(
            VerbExample("تَعَلَّمَ الطَّالِبُ الدَّرْسَ", "The student learned the lesson"),
            VerbExample("تَكَلَّمَ الرَّجُلُ بِوُضُوحٍ", "The man spoke clearly"),
            VerbExample("تَذَكَّرَ الْمَوْعِدَ", "He remembered the appointment"),
        ),
    ),
    VerbForm(
        form = "VI",
        pattern = "تَفَاعَلَ",
        rootExample = "ع و ن",
        commonMeaning = "Reciprocity / Feigning.",
        transitivity = "Reciprocal / Intransitive",
        explanation = "Indicates mutual action between two or more parties. Crucially, it can also mean pretending or feigning a state (e.g., pretending to be sick).",
        morphologyNote = "Prefix (تَ) plus the Alif of Form III.",
        examples = listOf(
            VerbExample("تَعَاوَنَ الفَرِيقُ", "The team cooperated (with each other)"),
            VerbExample("تَجَاهَلَ المُدِيرُ الْمُشْكِلَةَ", "The manager feigned ignorance of the problem"),
            VerbExample("تَنَافَسَ اللَّاعِبُونَ", "The players competed (against each other)"),
        ),
    ),
    VerbForm(
        form = "VII",
        pattern = "اِنْفَعَلَ",
        rootExample = "ك س ر",
        commonMeaning = "Passive / Reflexive.",
        transitivity = "Intransitive",
        explanation = "Strictly intransitive. It describes the state of having undergone the action. It is the reflexive/passive of Form I.",
        morphologyNote = "Prefix (اِنْ) added before the root.",
        examples = listOf(
            VerbExample("اِنْكَسَرَ الكُوبُ", "The cup broke (shattered)"),
            VerbExample("اِنْقَطَعَ الاِتِّصَالُ", "The connection was cut off"),
            VerbExample("اِنْفَجَرَ اللَّغَمُ", "The mine exploded"),
        ),
    ),
    VerbForm(
        form = "VIII",
        pattern = "اِفْتَعَلَ",
        rootExample = "ج م ع",
        commonMeaning = "Participating / Taking for oneself.",
        transitivity = "Varies",
        explanation = "Indicates doing the action for oneself, striving, or mutual participation. Often reflexive of Form I.",
        morphologyNote = "Infix (ت) inserted after the first root letter.",
        examples = listOf(
            VerbExample("اِجْتَمَعَ الْمُوَظَّفُونَ", "The employees gathered/met"),
            VerbExample("اِشْتَرَى الرَّجُلُ سَيَّارَةً", "The man bought a car (for himself)"),
            VerbExample("اِسْتَمَعَ الطَّالِبُ", "The student listened (intent to hear)"),
        ),
    ),
    VerbForm(
        form = "IX",
        pattern = "اِفْعَلَّ",
        rootExample = "ح م ر",
        commonMeaning = "Colors / Physical Defects.",
        transitivity = "Intransitive",
        explanation = "Used almost exclusively for colors (turning a color) or physical defects (becoming twisted/crooked).",
        morphologyNote = "Gemination (shadda) on the final root letter.",
        examples = listOf(
            VerbExample("اِحْمَرَّ وَجْهُهُ خَجَلًا", "His face turned red from shyness"),
            VerbExample("اِصْفَرَّتْ أَوْرَاقُ الشَّجَرِ", "The tree leaves turned yellow"),
        ),
    ),
    VerbForm(
        form = "X",
        pattern = "اِسْتَفْعَلَ",
        rootExample = "غ ف ر",
        commonMeaning = "Requesting / Estimative.",
        transitivity = "Transitive",
        explanation = "Indicates asking for the action (Requesting) or considering something to have a certain quality (Estimative).",
        morphologyNote = "Prefix (اِسْتَ) added before the root.",
        examples = listOf(
            VerbExample("اِسْتَغْفَرَ الْمُؤْمِنُ رَبَّهُ", "The believer sought forgiveness from his Lord"),
            VerbExample("اِسْتَخْدَمَ النَّاسُ التِّكْنُولُوجِيَا", "People utilized/used technology (sought service from it)"),
            VerbExample("اِسْتَحْسَنَ المُدِيرُ الاِقْتِرَاحَ", "The manager considered the proposal good (Estimative)"),
        ),
    ),
)

val GRAMMAR_TERMS: List<GrammarTerm> = listOf(
    GrammarTerm("Transitive Verb", "A verb that requires a direct object. The action passes from the doer to a receiver (e.g., 'He wrote the letter')."),
    GrammarTerm("Intransitive Verb", "A verb that does not take a direct object. The action remains with the subject (e.g., 'He sat')."),
    GrammarTerm("Reflexive", "The subject performs the action on itself (e.g., 'He taught himself' or 'He washed himself')."),
    GrammarTerm("Causative", "The subject causes someone or something else to perform the action or enter a state (e.g., 'To teach' is the causative of 'to know')."),
    GrammarTerm("Reciprocal", "Two or more subjects perform the action on each other simultaneously (e.g., 'They cooperated')."),
    GrammarTerm("Intensive", "The action is done with greater force, frequency, or violence (e.g., 'To smash' vs. 'To break')."),
    GrammarTerm("Seeking Form", "Indicates asking for, seeking, or attempting to obtain the root meaning (Common in Form X)."),
    GrammarTerm("Root (Jizr)", "The base sequence of consonants (usually three) that carries the core lexical meaning of the word, before any vowels or affixes are added."),
    GrammarTerm("Triliteral", "A root consisting of exactly three consonants. This is the standard foundation for most Arabic verbs."),
    GrammarTerm("Gemination", "The doubling of a consonant, resulting in a stronger sound. In Arabic script, this is marked with a Shadda (ّ). Critical for Forms II and IX."),
    GrammarTerm("Affix (Prefix/Infix)", "Letters added to the root to change its meaning. A 'Prefix' is added to the front (like 'ista-' in Form X), and an 'Infix' is inserted inside the root (like the 't' in Form VIII)."),
    GrammarTerm("Estimative", "A mental action where the subject deems or considers the object to have a certain quality (e.g., 'He considered it good'). Common in Form X."),
    GrammarTerm("Feigning", "Pretending to have a certain quality or state that one does not actually possess (e.g., 'Pretending to be sick'). A unique feature of Form VI."),
    GrammarTerm("Stative", "A verb that describes a state of being or a condition (like a color or physical trait) rather than a dynamic action. Common in Form IX."),
)

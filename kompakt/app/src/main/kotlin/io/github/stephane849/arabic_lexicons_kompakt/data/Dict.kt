package io.github.stephane849.arabic_lexicons_kompakt.data

/**
 * Line-for-line port of `lib/data.dart`'s `Dict` enum from the Flutter app
 * (arabic_lexicons). Order matters: it's used as the bit position for the
 * dictionary-selection mask stored in preferences, and as the DB index
 * stored in search-history rows.
 */
enum class Dict(
    val table: String,
    val ar: String,
    val en: String,
    val enLong: String,
    val description: String,
    val link: String? = null,
    val hasRefs: Boolean = false,
) {
    AR_EN(
        table = "arEn",
        ar = "مباشر",
        en = "Direct",
        enLong = "Aratools Arabic–English",
        description = "GPL-licensed components of the Aratools Arabic-English dictionary. " +
            "Based on Tim Buckwalter's Aramorph Arabic morphological analyzer " +
            "(dictprefixes, dictstems, dictsuffixes, tableab, tableac, tablebc). " +
            "Distributed via Aramorph and Linguistic Data Consortium sources.",
        link = "http://www.nongnu.org/aramorph/",
    ),

    HANSWEHR(
        table = "hanswehr",
        ar = "هانز",
        en = "Hanswehr",
        enLong = "Hans Wehr Dictionary",
        description = "Modern Arabic–English dictionary compiled by Hans Wehr. " +
            "Widely used academic reference organized by triliteral roots.",
        link = "https://en.wikipedia.org/wiki/Hans_Wehr_dictionary",
    ),

    LANE_LEXICON(
        table = "lanelexcon",
        ar = "لين",
        en = "Lanes",
        enLong = "Lane's Arabic-English Lexicon",
        description = "Comprehensive 19th-century Arabic-English lexicon by Edward William Lane, " +
            "based on major classical sources.",
        link = "https://en.wikipedia.org/wiki/Edward_William_Lane",
    ),

    MUJAMUL_GHONI(
        table = "mujamul_ghoni",
        ar = "الغني",
        en = "Ghani",
        enLong = "Al-Muʿjam al-Ghani",
        description = "Contemporary Arabic dictionary focusing on modern vocabulary and usage.",
    ),

    MUJAMUL_SHIHAH(
        table = "mujamul_shihah",
        ar = "الصحاح",
        en = "Sihah",
        enLong = "Al-Sihah (al-Jawhari)",
        description = "Classical Arabic dictionary by al-Jawhari (4th century AH), " +
            "one of the foundational root-based lexicons.",
        link = "https://ar.wikipedia.org/wiki/الصحاح_في_اللغة",
        hasRefs = true,
    ),

    LISAN_AL_ARAB(
        table = "lisanularab",
        ar = "لسان",
        en = "Lisan",
        enLong = "Lisan al-Arab",
        description = "Major classical Arabic lexicon compiled by Ibn Manzur (7th century AH), " +
            "drawing from earlier authoritative sources.",
        link = "https://en.wikipedia.org/wiki/Lisan_al-Arab",
        hasRefs = true,
    ),

    MUJAMUL_MUASHIROH(
        table = "mujamul_muashiroh",
        ar = "المعاصرة",
        en = "Muasiroh",
        enLong = "Al-Muʿjam al-Muʿasirah",
        description = "Modern Arabic dictionary emphasizing contemporary terminology and usage.",
    ),

    MUJAMUL_WASITH(
        table = "mujamul_wasith",
        ar = "الوسيط",
        en = "Wasit",
        enLong = "Al-Muʿjam al-Wasit",
        description = "Standard modern Arabic dictionary published by the Arabic Language Academy in Cairo.",
        link = "https://ar.wikipedia.org/wiki/المعجم_الوسيط",
    ),

    MUJAMUL_MUHITH(
        table = "mujamul_muhith",
        ar = "المحيط",
        en = "Muhit",
        enLong = "Al-Qamus al-Muhit",
        description = "Influential classical dictionary by al-Firuzabadi (8th century AH), " +
            "widely cited in later lexicons.",
        link = "https://ar.wikipedia.org/wiki/القاموس_المحيط",
    ),

    MAQAYEESUL_LUGA(
        table = "maqayeesul_luga",
        ar = "مقاييس",
        en = "Maqayes",
        enLong = "Maqayis al-Lugha",
        description = "Root-based semantic analysis by Ibn Faris (4th century AH), " +
            "reducing each root to its core conceptual meanings.",
        link = "https://ar.wikipedia.org/wiki/مقاييس_اللغة",
        hasRefs = true,
    ),

    MUFRADAT_ALFAJUL_QURAN(
        table = "mufradat_alfajul_quran",
        ar = "مفردات",
        en = "Mufradat",
        enLong = "Mufradat Alfaz al-Qur'an",
        description = "Qur'anic lexicon by al-Raghib al-Isfahani, " +
            "analyzing vocabulary and semantic nuances of Qur'anic terms.",
        link = "https://ar.wikipedia.org/wiki/المفردات_في_غريب_القرآن",
        hasRefs = true,
    );

    /** In the default (untranslated-to-English-UI) app, Arabic name is shown. */
    val displayName: String get() = ar

    companion object {
        val ALL: List<Dict> = entries.toList()

        fun encode(selected: Set<Dict>): Int {
            var mask = 0
            for (d in selected) mask = mask or (1 shl d.ordinal)
            return mask
        }

        fun decode(mask: Int): Set<Dict> {
            val result = mutableSetOf<Dict>()
            for (d in entries) {
                if ((mask and (1 shl d.ordinal)) != 0) result.add(d)
            }
            return result
        }
    }
}

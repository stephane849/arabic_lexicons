package io.github.stephane849.arabic_lexicons_kompakt.ui.components

import io.github.stephane849.arabic_lexicons_kompakt.data.db.DbRow

/** One lazy-list row of a result view. */
sealed interface ResultBlock {
    data class Title(val word: String) : ResultBlock
    data class Body(val html: String, val emphasized: Boolean) : ResultBlock
    data object Separator : ResultBlock
}

/**
 * How much text one block may hold before it is broken up. Sized to be
 * comfortably taller than a screenful is wide — small enough that a block
 * is never unreachable, large enough that paging stays coarse.
 */
private const val MAX_BLOCK_CHARS = 500

/**
 * Breaks an entry into blocks at its own line breaks, then splits any
 * remaining over-long stretch at a word boundary.
 *
 * This is load-bearing, not cosmetic. `LazyColumnMMD` turns off Compose's
 * own scrolling and moves by whole item indices instead (`scrollToItem`),
 * which is what keeps scrolling crisp on E Ink — but it means a list of
 * one item cannot scroll at all. The Arabic lexicons answer with a single
 * very long entry, so rendering a result as one item left everything past
 * the first screen unreachable. Many small blocks give the list something
 * to step through.
 */
fun splitIntoBlocks(text: String, maxChars: Int = MAX_BLOCK_CHARS): List<String> {
    val blocks = mutableListOf<String>()

    for (paragraph in text.split('\n')) {
        val p = paragraph.trim()
        if (p.isEmpty()) continue

        if (p.length <= maxChars) {
            blocks.add(p)
            continue
        }

        var start = 0
        while (start < p.length) {
            var end = minOf(start + maxChars, p.length)
            if (end < p.length) {
                // Prefer a word boundary, but only if it makes progress.
                val space = p.lastIndexOf(' ', end)
                if (space > start) end = space
            }
            val piece = p.substring(start, end).trim()
            if (piece.isNotEmpty()) blocks.add(piece)
            start = end
        }
    }

    return blocks.ifEmpty { listOf(text) }
}

/**
 * Flattens results into blocks, and reports which block the searched word
 * itself starts at (-1 when nothing matched exactly), so the caller can
 * jump there — Hans Wehr and Lane answer with a root's whole chain.
 */
fun buildResultBlocks(rows: List<DbRow>, showTitles: Boolean): Pair<List<ResultBlock>, Int> {
    val blocks = mutableListOf<ResultBlock>()
    var matchIndex = -1

    for (row in rows) {
        if (row.isHi && matchIndex < 0) matchIndex = blocks.size

        if (showTitles && row.word.isNotEmpty()) blocks.add(ResultBlock.Title(row.word))

        for (piece in splitIntoBlocks(row.meanings)) {
            blocks.add(ResultBlock.Body(piece, row.isHi))
        }

        blocks.add(ResultBlock.Separator)
    }

    return blocks to matchIndex
}

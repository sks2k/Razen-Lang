package com.razen.ide

import com.intellij.lexer.Lexer
import com.intellij.openapi.editor.DefaultLanguageHighlighterColors
import com.intellij.openapi.editor.HighlighterColors
import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.fileTypes.SyntaxHighlighterBase
import com.intellij.psi.TokenType
import com.intellij.psi.tree.IElementType
import com.razen.ide.lexer.RazenLexer
import com.razen.ide.psi.RazenTokenTypes

class RazenSyntaxHighlighter : SyntaxHighlighterBase() {
    companion object {
        val KEYWORD = TextAttributesKey.createTextAttributesKey("RAZEN_KEYWORD", DefaultLanguageHighlighterColors.KEYWORD)
        val FUNCTION = TextAttributesKey.createTextAttributesKey("RAZEN_FUNCTION", DefaultLanguageHighlighterColors.FUNCTION_DECLARATION)
        val COMMENT = TextAttributesKey.createTextAttributesKey("RAZEN_COMMENT", DefaultLanguageHighlighterColors.LINE_COMMENT)
        val STRING = TextAttributesKey.createTextAttributesKey("RAZEN_STRING", DefaultLanguageHighlighterColors.STRING)
        val NUMBER = TextAttributesKey.createTextAttributesKey("RAZEN_NUMBER", DefaultLanguageHighlighterColors.NUMBER)
        val OPERATOR = TextAttributesKey.createTextAttributesKey("RAZEN_OPERATOR", DefaultLanguageHighlighterColors.OPERATION_SIGN)
        val VARIABLE = TextAttributesKey.createTextAttributesKey("RAZEN_VARIABLE", DefaultLanguageHighlighterColors.INSTANCE_FIELD)
        val BAD_CHARACTER = TextAttributesKey.createTextAttributesKey("RAZEN_BAD_CHARACTER", HighlighterColors.BAD_CHARACTER)
    }

    override fun getHighlightingLexer(): Lexer {
        return RazenLexer()
    }

    override fun getTokenHighlights(tokenType: IElementType): Array<TextAttributesKey> {
        return when (tokenType) {
            RazenTokenTypes.KEYWORD -> arrayOf(KEYWORD)
            RazenTokenTypes.FUNCTION -> arrayOf(FUNCTION)
            RazenTokenTypes.COMMENT -> arrayOf(COMMENT)
            RazenTokenTypes.STRING -> arrayOf(STRING)
            RazenTokenTypes.NUMBER -> arrayOf(NUMBER)
            RazenTokenTypes.OPERATOR -> arrayOf(OPERATOR)
            RazenTokenTypes.VARIABLE -> arrayOf(VARIABLE)
            TokenType.BAD_CHARACTER -> arrayOf(BAD_CHARACTER)
            else -> TextAttributesKey.EMPTY_ARRAY
        }
    }
}

package com.razen.ide.psi

import com.intellij.psi.tree.IElementType
import com.razen.ide.RazenLanguage

object RazenTokenTypes {
    val KEYWORD = RazenElementType("KEYWORD")
    val FUNCTION = RazenElementType("FUNCTION")
    val COMMENT = RazenElementType("COMMENT")
    val STRING = RazenElementType("STRING")
    val NUMBER = RazenElementType("NUMBER")
    val OPERATOR = RazenElementType("OPERATOR")
    val VARIABLE = RazenElementType("VARIABLE")
    val BAD_CHARACTER = RazenElementType("BAD_CHARACTER")
}

class RazenElementType(debugName: String) : IElementType(debugName, RazenLanguage.INSTANCE)

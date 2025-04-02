package com.razen.ide.lexer

import com.intellij.lexer.LexerBase
import com.intellij.psi.tree.IElementType
import com.razen.ide.psi.RazenTokenTypes

class RazenLexer : LexerBase() {
    private var buffer: CharSequence = ""
    private var bufferEnd: Int = 0
    private var bufferStart: Int = 0
    private var currentPosition: Int = 0
    private var tokenStart: Int = 0
    private var tokenEnd: Int = 0
    private var currentToken: IElementType? = null

    override fun start(buffer: CharSequence, startOffset: Int, endOffset: Int, initialState: Int) {
        this.buffer = buffer
        this.bufferStart = startOffset
        this.bufferEnd = endOffset
        this.currentPosition = startOffset
        this.tokenStart = startOffset
        this.tokenEnd = startOffset
        advance()
    }

    override fun getState(): Int = 0

    override fun getTokenType(): IElementType? {
        return if (tokenStart >= bufferEnd) null else currentToken
    }

    override fun getTokenStart(): Int = tokenStart

    override fun getTokenEnd(): Int = tokenEnd

    override fun advance() {
        if (currentPosition >= bufferEnd) {
            tokenStart = bufferEnd
            tokenEnd = bufferEnd
            currentToken = null
            return
        }

        tokenStart = currentPosition
        
        // Simple lexer implementation for Razen language
        when {
            isComment() -> processComment()
            isString() -> processString()
            isNumber() -> processNumber()
            isKeyword() -> processKeyword()
            isFunction() -> processFunction()
            isVariable() -> processVariable()
            isOperator() -> processOperator()
            else -> {
                currentPosition++
                tokenEnd = currentPosition
                currentToken = RazenTokenTypes.BAD_CHARACTER
            }
        }
    }

    private fun isComment(): Boolean {
        return buffer[currentPosition] == '#'
    }

    private fun processComment() {
        while (currentPosition < bufferEnd && buffer[currentPosition] != '\n') {
            currentPosition++
        }
        tokenEnd = currentPosition
        currentToken = RazenTokenTypes.COMMENT
    }

    private fun isString(): Boolean {
        return buffer[currentPosition] == '"' || buffer[currentPosition] == '\''
    }

    private fun processString() {
        val quote = buffer[currentPosition++]
        while (currentPosition < bufferEnd && buffer[currentPosition] != quote) {
            if (buffer[currentPosition] == '\\' && currentPosition + 1 < bufferEnd) {
                currentPosition += 2
            } else {
                currentPosition++
            }
        }
        if (currentPosition < bufferEnd) currentPosition++
        tokenEnd = currentPosition
        currentToken = RazenTokenTypes.STRING
    }

    private fun isNumber(): Boolean {
        return buffer[currentPosition].isDigit()
    }

    private fun processNumber() {
        while (currentPosition < bufferEnd && 
               (buffer[currentPosition].isDigit() || buffer[currentPosition] == '.')) {
            currentPosition++
        }
        tokenEnd = currentPosition
        currentToken = RazenTokenTypes.NUMBER
    }

    private fun isKeyword(): Boolean {
        val keywords = listOf("fun", "if", "else", "while", "return", "let", "take", "hold", 
                             "put", "when", "not", "true", "false", "null", "throw")
        
        for (keyword in keywords) {
            if (matchesAtPosition(keyword)) {
                return true
            }
        }
        return false
    }

    private fun processKeyword() {
        val keywords = listOf("fun", "if", "else", "while", "return", "let", "take", "hold", 
                             "put", "when", "not", "true", "false", "null", "throw")
        
        for (keyword in keywords) {
            if (matchesAtPosition(keyword)) {
                currentPosition += keyword.length
                tokenEnd = currentPosition
                currentToken = RazenTokenTypes.KEYWORD
                return
            }
        }
    }

    private fun isFunction(): Boolean {
        val functions = listOf("add", "subtract", "multiply", "divide", "power", "abs", "max", "min", 
                              "round", "len", "concat", "upper", "lower", "substring", "replace", 
                              "trim", "push", "pop", "join_array", "sort", "reverse", "slice", 
                              "int", "float", "bool", "show")
        
        for (function in functions) {
            if (matchesAtPosition(function)) {
                return true
            }
        }
        return false
    }

    private fun processFunction() {
        val functions = listOf("add", "subtract", "multiply", "divide", "power", "abs", "max", "min", 
                              "round", "len", "concat", "upper", "lower", "substring", "replace", 
                              "trim", "push", "pop", "join_array", "sort", "reverse", "slice", 
                              "int", "float", "bool", "show")
        
        for (function in functions) {
            if (matchesAtPosition(function)) {
                currentPosition += function.length
                tokenEnd = currentPosition
                currentToken = RazenTokenTypes.FUNCTION
                return
            }
        }
    }

    private fun isVariable(): Boolean {
        val variables = listOf("sum", "diff", "prod", "div", "mod", "is", "text", "concat", 
                              "slice", "len", "list", "arr", "append", "remove", "map", "key", 
                              "value", "current", "now", "year", "month", "day", "hour", 
                              "minute", "second", "store", "box", "ref", "show", "read")
        
        for (variable in variables) {
            if (matchesAtPosition(variable)) {
                return true
            }
        }
        return false
    }

    private fun processVariable() {
        val variables = listOf("sum", "diff", "prod", "div", "mod", "is", "text", "concat", 
                              "slice", "len", "list", "arr", "append", "remove", "map", "key", 
                              "value", "current", "now", "year", "month", "day", "hour", 
                              "minute", "second", "store", "box", "ref", "show", "read")
        
        for (variable in variables) {
            if (matchesAtPosition(variable)) {
                currentPosition += variable.length
                tokenEnd = currentPosition
                currentToken = RazenTokenTypes.VARIABLE
                return
            }
        }
    }

    private fun isOperator(): Boolean {
        return "+-*/=<>!&|^~.%".contains(buffer[currentPosition])
    }

    private fun processOperator() {
        currentPosition++
        tokenEnd = currentPosition
        currentToken = RazenTokenTypes.OPERATOR
    }

    private fun matchesAtPosition(text: String): Boolean {
        if (currentPosition + text.length > bufferEnd) return false
        
        for (i in text.indices) {
            if (buffer[currentPosition + i] != text[i]) return false
        }
        
        // Check that the match is a complete token (followed by whitespace, punctuation, etc.)
        return currentPosition + text.length >= bufferEnd || 
               !isIdentifierPart(buffer[currentPosition + text.length])
    }

    private fun isIdentifierPart(c: Char): Boolean {
        return c.isLetterOrDigit() || c == '_'
    }

    override fun getBufferSequence(): CharSequence = buffer

    override fun getBufferEnd(): Int = bufferEnd
}

package com.razen.ide

import com.intellij.lang.Language

class RazenLanguage private constructor() : Language("Razen") {
    companion object {
        @JvmStatic
        val INSTANCE = RazenLanguage()
    }
}

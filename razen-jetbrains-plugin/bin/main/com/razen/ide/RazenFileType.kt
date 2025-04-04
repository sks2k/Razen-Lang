package com.razen.ide

import com.intellij.openapi.fileTypes.LanguageFileType
import com.intellij.openapi.util.IconLoader
import javax.swing.Icon

class RazenFileType private constructor() : LanguageFileType(RazenLanguage.INSTANCE) {
    companion object {
        @JvmStatic
        val INSTANCE = RazenFileType()
        
        private val ICON = IconLoader.getIcon("/icons/razen.png", RazenFileType::class.java)
    }

    override fun getName(): String = "Razen"
    override fun getDescription(): String = "Razen language file"
    override fun getDefaultExtension(): String = "rzn"
    override fun getIcon(): Icon = ICON
}

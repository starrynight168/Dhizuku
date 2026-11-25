package com.rosan.dhizuku.data.account.entity

data class AccountEntity(
    val userId: Int,
    val type: String,
    val name: String
) {
    val hasKnownName: Boolean
        get() = name.isNotBlank() && !maskedName.matches(name.trim())

    private companion object {
        val maskedName = Regex("(?:x{3,}|[*•·]{3,})", RegexOption.IGNORE_CASE)
    }
}

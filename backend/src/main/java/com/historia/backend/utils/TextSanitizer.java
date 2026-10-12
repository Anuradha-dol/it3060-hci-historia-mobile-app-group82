package com.historia.backend.utils;

public final class TextSanitizer {

    private TextSanitizer() {
    }

    public static String cleanRequired(String value) {
        return removeInvalidDatabaseChars(value).trim();
    }

    public static String cleanOptional(String value) {
        if (value == null) {
            return null;
        }

        String cleaned = removeInvalidDatabaseChars(value).trim();

        return cleaned.isBlank()
                ? null
                : cleaned;
    }

    private static String removeInvalidDatabaseChars(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("\u0000", "");
    }
}

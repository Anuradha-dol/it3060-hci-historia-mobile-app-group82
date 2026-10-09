package com.historia.backend.utils;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.Locale;

public final class LocationMatcher {

    private LocationMatcher() {
    }

    public static boolean matchesServiceArea(
            String serviceArea,
            String requestedArea
    ) {

        String service = normalize(serviceArea);
        String requested = normalize(requestedArea);

        if (service.isBlank() || requested.isBlank()) {
            return false;
        }

        if (isRelated(service, requested)) {
            return true;
        }

        return Arrays.stream(requestedArea.split(","))
                .map(LocationMatcher::normalize)
                .filter(component -> !component.isBlank())
                .anyMatch(component ->
                        isRelated(service, component)
                );
    }


    private static boolean isRelated(
            String left,
            String right
    ) {

        return left.equals(right) ||
                left.startsWith(right + " ") ||
                right.startsWith(left + " ");
    }


    private static String normalize(String value) {

        if (value == null) {
            return "";
        }

        String withoutMarks = Normalizer
                .normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");

        return withoutMarks
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
    }
}

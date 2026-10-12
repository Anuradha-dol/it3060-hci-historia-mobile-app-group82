package com.historia.backend.utils;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LocationMatcherTest {

    @Test
    void matchesPlacePickerLabelsAgainstStoredServiceAreas() {
        assertTrue(
                LocationMatcher.matchesServiceArea(
                        "Galle",
                        "Galle, Sri Lanka"
                )
        );

        assertTrue(
                LocationMatcher.matchesServiceArea(
                        "Galle Fort",
                        "Galle, Sri Lanka"
                )
        );

        assertTrue(
                LocationMatcher.matchesServiceArea(
                        "Galle",
                        "Galle Southern Province Sri Lanka"
                )
        );

        assertFalse(
                LocationMatcher.matchesServiceArea(
                        "Kandy",
                        "Galle, Sri Lanka"
                )
        );
    }
}

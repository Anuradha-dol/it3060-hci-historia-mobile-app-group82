package com.historia.backend.booking;

import com.historia.backend.entity.GuideProfile;
import com.historia.backend.enums.GuideApplicationStatus;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Component
@RequiredArgsConstructor
public class GuideBookingDefaults implements CommandLineRunner {
    private final EntityManager em;

    @Override
    @Transactional
    public void run(String... args) {
        em.createQuery("""
                        select g
                        from GuideProfile g
                        where g.status=:status
                          and g.user.deleted=false
                          and g.user.enabled=true
                        """, GuideProfile.class)
                .setParameter("status", GuideApplicationStatus.APPROVED)
                .getResultList()
                .forEach(this::ensureBookable);
    }

    public void ensureBookable(GuideProfile guide) {
        boolean hasPackage = hasPackages(guide);
        boolean hasWindow = hasFutureWindows(guide);

        if (!hasPackage) {
            GuidePackage guidePackage = new GuidePackage();
            guidePackage.setGuide(guide);
            guidePackage.setName("Heritage Walk");
            guidePackage.setFeatures("Guided local heritage tour");
            guidePackage.setDurationMinutes(120);
            guidePackage.setPricePerVisitor(new BigDecimal("2500.00"));
            guidePackage.setMinVisitors(1);
            guidePackage.setMaxVisitors(10);
            guidePackage.setEnabled(true);
            em.persist(guidePackage);
        }

        if (!hasWindow) {
            createAvailabilityWindows(guide);
        }
    }

    private boolean hasPackages(GuideProfile guide) {
        return em.createQuery(
                        "select count(p) from GuidePackage p where p.guide.id=:guide",
                        Long.class
                )
                .setParameter("guide", guide.getId())
                .getSingleResult() > 0;
    }

    private boolean hasFutureWindows(GuideProfile guide) {
        return em.createQuery(
                        "select count(w) from GuideWindow w where w.guide.id=:guide and w.endsAt>:now",
                        Long.class
                )
                .setParameter("guide", guide.getId())
                .setParameter("now", Instant.now())
                .getSingleResult() > 0;
    }

    private void createAvailabilityWindows(GuideProfile guide) {
        for (int day = 0; day < 14; day++) {
            Instant startsAt = LocalDate.now(BookingService.ZONE)
                    .plusDays(day)
                    .atTime(8, 0)
                    .atZone(BookingService.ZONE)
                    .toInstant();

            Instant endsAt = startsAt.plusSeconds(10 * 3600L);

            GuideWindow window = new GuideWindow();
            window.setGuide(guide);
            window.setStartsAt(startsAt);
            window.setEndsAt(endsAt);
            em.persist(window);
        }
    }
}

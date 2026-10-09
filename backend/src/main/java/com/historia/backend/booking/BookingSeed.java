package com.historia.backend.booking;
import com.historia.backend.entity.*;
import com.historia.backend.enums.*;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

@Component @Profile("demo") @ConditionalOnProperty(name="historia.booking.seed",havingValue="true")
@RequiredArgsConstructor
public class BookingSeed implements CommandLineRunner {
    private final EntityManager em;
    private final PasswordEncoder encoder;
    @Value("${HISTORIA_DEMO_PASSWORD:}") private String password;
    @Override @Transactional public void run(String... args) {
        if(password.length()<12) throw new IllegalStateException("Set HISTORIA_DEMO_PASSWORD to your own 12+ character local test password before enabling seed");
        user("demo_traveler",Role.TOURIST,"Demo","Traveler");
        for(String[] fixture:List.of(new String[]{"demo_kamal","Kamal","Perera"},new String[]{"demo_sunil","Sunil","Fernando"})) {
            User u=user(fixture[0],Role.GUIDE,fixture[1],fixture[2]);
            GuideProfile g=em.createQuery("select g from GuideProfile g where g.user.id=:u",GuideProfile.class).setParameter("u",u.getId()).getResultStream().findFirst().orElse(null);
            if(g==null) {g=new GuideProfile();g.setUser(u);g.setDisplayName(fixture[1]+" "+fixture[2]);g.setPrimaryServiceArea("Galle Fort");g.setServiceAreas(new LinkedHashSet<>(List.of("Galle Fort")));g.setLanguages(new LinkedHashSet<>(List.of("English","Sinhala","Tamil")));g.setSpecialties(new LinkedHashSet<>(List.of("Dutch Ramparts","Colonial history")));g.setYearsExperience(11);g.setStatus(GuideApplicationStatus.APPROVED);g.setBio("DEMO fixture. Not a real listing or certification.");em.persist(g);em.flush();}
            if(em.find(GuideEvidence.class,g.getId())==null){GuideEvidence e=new GuideEvidence();e.setGuide(g);e.setDemo(true);e.setCertified(true);e.setRating(fixture[0].equals("demo_kamal")?4.9:4.6);e.setReviewCount(0);em.persist(e);}
            Long count=em.createQuery("select count(p) from GuidePackage p where p.guide.id=:g",Long.class).setParameter("g",g.getId()).getSingleResult();
            if(count==0) for(int i=0;i<2;i++){GuidePackage p=new GuidePackage();p.setGuide(g);p.setName(i==0?"Full Heritage Walk":"Point to Point");p.setDurationMinutes(i==0?120:45);p.setPricePerVisitor(new BigDecimal(i==0?"2500.00":"1500.00"));p.setFeatures(i==0?"Guided history walk • Offline meeting access":"Short guide assistance • Highlights route");p.setMaxVisitors(10);em.persist(p);}
            for(int day=0;day<14;day++){Instant start=LocalDate.now(BookingService.ZONE).plusDays(day).atTime(8,0).atZone(BookingService.ZONE).toInstant();Instant end=start.plusSeconds(11*3600);
                Long existing=em.createQuery("select count(w) from GuideWindow w where w.guide.id=:g and w.startsAt=:s",Long.class).setParameter("g",g.getId()).setParameter("s",start).getSingleResult();
                if(existing==0){GuideWindow w=new GuideWindow();w.setGuide(g);w.setStartsAt(start);w.setEndsAt(end);em.persist(w);}}
        }
    }
    private User user(String username,Role role,String first,String last){
        var existing=em.createQuery("select u from User u where u.username=:name",User.class).setParameter("name",username).getResultStream().findFirst();
        if(existing.isPresent()) {User u=existing.get();if(!u.getEmail().equals(username+"@example.invalid") || u.getRole()!=role)throw new IllegalStateException("Demo username belongs to another account; seed stopped");return u;}
        User u=User.builder().username(username).email(username+"@example.invalid").firstName(first).lastName(last).role(role).password(encoder.encode(password)).emailVerified(true).enabled(true).build();em.persist(u);em.flush();return u;
    }
}

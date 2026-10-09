package com.historia.backend.booking;

import com.historia.backend.entity.*;
import com.historia.backend.enums.*;
import jakarta.persistence.*;
import lombok.RequiredArgsConstructor;
import com.historia.backend.service.NotificationService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.*;
import java.util.*;
import static com.historia.backend.booking.BookingDto.*;
import static com.historia.backend.utils.LocationMatcher.matchesServiceArea;

@Service @RequiredArgsConstructor @Transactional
public class BookingService {
    private final EntityManager em;
    private final NotificationService notificationService;
    @Value("${historia.booking.demo-payments:false}") private boolean demoPayments;
    @Value("${spring.profiles.active:}") private String profiles;
    private static final SecureRandom RANDOM = new SecureRandom();
    public static final ZoneId ZONE = ZoneId.of("Asia/Colombo");
    static final Set<String> ACTIVE = Set.of("CONFIRMED", "EN_ROUTE", "ARRIVED", "IN_PROGRESS");

    static ResponseStatusException bad(String message) { return new ResponseStatusException(HttpStatus.CONFLICT, message); }
    private User actor(Long id) {
        User u = em.find(User.class, id);
        if (u == null || !u.isEnabled()) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Active account required");
        return u;
    }
    private GuideProfile eligible(Long id, boolean lock) {
        GuideProfile g = lock ? em.find(GuideProfile.class, id, LockModeType.PESSIMISTIC_WRITE) : em.find(GuideProfile.class, id);
        if (g == null || g.getStatus() != GuideApplicationStatus.APPROVED || !g.getUser().isEnabled())
            throw bad("Guide is not eligible for bookings");
        return g;
    }
    private GuideProfile ownGuide(Long userId) {
        User u = actor(userId);
        if (u.getRole() != Role.GUIDE) throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Guide account required");
        return em.createQuery("select g from GuideProfile g where g.user.id=:id", GuideProfile.class)
            .setParameter("id", userId).getResultStream().findFirst().map(g -> eligible(g.getId(), true))
            .orElseThrow(() -> bad("Approved guide profile required"));
    }
    private GuidePackage tourPackage(Long id, Long guideId) {
        GuidePackage p = em.find(GuidePackage.class, id);
        if (p == null || !p.isEnabled() || !p.getGuide().getId().equals(guideId)) throw bad("Package unavailable for this guide");
        return p;
    }
    static boolean contains(String text, String query) { return query == null || query.isBlank() || (text != null && text.toLowerCase(Locale.ROOT).contains(query.toLowerCase(Locale.ROOT))); }
    private List<GuidePackage> packages(Long id) { return em.createQuery("select p from GuidePackage p where p.guide.id=:id order by p.id", GuidePackage.class).setParameter("id", id).getResultList(); }
    private PackageView packageView(GuidePackage p) { return new PackageView(p.getId(),p.getName(),p.getFeatures(),p.getDurationMinutes(),p.getPricePerVisitor(),p.getMinVisitors(),p.getMaxVisitors(),p.isEnabled()); }
    public List<GuideView> discover(String q, String language, String area, String specialty, boolean certified, Double rating, LocalDate date, Instant at) {
        LocalDate day = date == null ? LocalDate.now(ZONE) : date;
        return em.createQuery("select g from GuideProfile g where g.status=:status", GuideProfile.class)
            .setParameter("status", GuideApplicationStatus.APPROVED).getResultList().stream()
            .filter(g -> g.getUser().isEnabled())
            .filter(g -> contains(g.getDisplayName()+" "+g.getSpecialties(), q))
            .filter(g -> contains(g.getLanguages().toString(), language))
            .filter(g -> matchesSearchArea(g, area))
            .filter(g -> contains(g.getSpecialties().toString(), specialty))
            .map(g -> {
                GuideEvidence e = em.find(GuideEvidence.class, g.getId());
                List<GuidePackage> ps = packages(g.getId()).stream().filter(GuidePackage::isEnabled).toList();
                boolean available = ps.stream().anyMatch(p -> at == null ? !slots(g.getId(),p.getId(),day).isEmpty() : available(g.getId(),at,at.plusSeconds(p.getDurationMinutes()*60L)));
                Set<String> areas = new LinkedHashSet<>(g.getServiceAreas()); areas.add(g.getPrimaryServiceArea());
                return new GuideView(g.getId(),g.getDisplayName(),g.getLanguages(),g.getSpecialties(),areas,g.getYearsExperience(),g.getUser().getProfileImageUrl(),e != null && e.isCertified(),e != null && e.isDemo(),e == null ? null : e.getRating(),e == null ? null : e.getReviewCount(),ps.stream().map(this::packageView).toList(),available);
            }).filter(g -> !certified || g.certified()).filter(g -> rating == null || (g.rating()!=null && g.rating()>=rating)).toList();
    }
    public List<MeetingLandmark> landmarks() { return em.createQuery("select l from MeetingLandmark l order by l.id", MeetingLandmark.class).getResultList(); }
    public List<Instant> slots(Long guideId, Long packageId, LocalDate date) {
        eligible(guideId,false); GuidePackage p = tourPackage(packageId,guideId);
        if (date.isBefore(LocalDate.now(ZONE)) || date.isAfter(LocalDate.now(ZONE).plusDays(365))) return List.of();
        Instant dayStart = date.atStartOfDay(ZONE).toInstant(), dayEnd = date.plusDays(1).atStartOfDay(ZONE).toInstant();
        List<GuideWindow> windows = em.createQuery("select w from GuideWindow w where w.guide.id=:g and w.startsAt<:end and w.endsAt>:start", GuideWindow.class)
            .setParameter("g",guideId).setParameter("start",dayStart).setParameter("end",dayEnd).getResultList();
        TreeSet<Instant> result = new TreeSet<>();
        for (GuideWindow w : windows) {
            for (Instant t=w.getStartsAt(); !t.plusSeconds(p.getDurationMinutes()*60L).isAfter(w.getEndsAt()); t=t.plusSeconds(1800)) {
                if (!t.isBefore(dayStart) && t.isBefore(dayEnd) && available(guideId,t,t.plusSeconds(p.getDurationMinutes()*60L))) result.add(t);
            }
        }
        return new ArrayList<>(result);
    }
    private boolean available(Long guide, Instant start, Instant end) {
        if (!start.isAfter(Instant.now())) return false;
        long windows = em.createQuery("select count(w) from GuideWindow w where w.guide.id=:g and w.startsAt<=:s and w.endsAt>=:e", Long.class)
            .setParameter("g",guide).setParameter("s",start).setParameter("e",end).getSingleResult();
        long conflicts = em.createQuery("select count(b) from GuideBooking b where b.guide.id=:g and b.startsAt<:e and b.endsAt>:s and (b.state in :active or (b.state='HELD' and b.holdExpiresAt>:now))",Long.class)
            .setParameter("g",guide).setParameter("s",start).setParameter("e",end).setParameter("active",ACTIVE).setParameter("now",Instant.now()).getSingleResult();
        return windows>0 && conflicts==0;
    }
    public BookingView hold(Long userId, HoldInput r) {
        User user=actor(userId);
        if (user.getRole()!=Role.TOURIST) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Traveler account required");
        // Lock the tourist before the guide: serializes retries, including keys reused across guides.
        em.lock(user,LockModeType.PESSIMISTIC_WRITE);
        var previous=em.createQuery("select b from GuideBooking b where b.tourist.id=:u and b.requestKey=:key",GuideBooking.class)
            .setParameter("u",userId).setParameter("key",r.requestKey()).getResultStream().findFirst();
        if(previous.isPresent()) {
            GuideBooking b=previous.get();
            if(!b.getGuide().getId().equals(r.guideId()) || !b.getTourPackage().getId().equals(r.packageId()) || !b.getStartsAt().equals(r.startsAt()) || b.getVisitors()!=r.visitors() || !b.getLandmark().getId().equals(r.landmarkId())) throw bad("Retry key belongs to different booking details");
            expire(b); return view(b,userId);
        }
        GuideProfile g=eligible(r.guideId(),true);
        GuidePackage p=tourPackage(r.packageId(),g.getId());
        if(r.visitors()<p.getMinVisitors() || r.visitors()>p.getMaxVisitors()) throw bad("Visitor count outside package limits");
        MeetingLandmark l=em.find(MeetingLandmark.class,r.landmarkId());
        if(l==null || !matchesRequiredArea(g, l.getArea())) throw bad("Meeting point is outside guide service area");
        Instant end=r.startsAt().plusSeconds(p.getDurationMinutes()*60L);
        if(!slots(g.getId(),p.getId(),r.startsAt().atZone(ZONE).toLocalDate()).contains(r.startsAt()) || !available(g.getId(),r.startsAt(),end)) throw bad("This slot is no longer available. Choose another time.");
        GuideBooking b=new GuideBooking(); b.setId(UUID.randomUUID().toString()); b.setTourist(user); b.setGuide(g); b.setTourPackage(p); b.setLandmark(l);
        b.setRequestKey(r.requestKey()); b.setStartsAt(r.startsAt()); b.setEndsAt(end); b.setVisitors(r.visitors()); b.setPackageName(p.getName());
        b.setAmount(p.getPricePerVisitor().multiply(BigDecimal.valueOf(r.visitors()))); b.setHoldExpiresAt(Instant.now().plusSeconds(600));
        b.setMeetingPin(String.format("%04d",RANDOM.nextInt(10000))); b.setPinExpiresAt(end.plusSeconds(3600));
        em.persist(b);
        notifyBookingParticipants(
            b,
            "BOOKING_HOLD",
            "Booking hold created",
            user.getUsername() + " held a booking with " + g.getDisplayName() + "."
        );
        return view(b,userId);
    }
    private void expire(GuideBooking b) { if(b.getState().equals("HELD") && (!b.getHoldExpiresAt().isAfter(Instant.now()) || !b.getStartsAt().isAfter(Instant.now()))) b.setState("EXPIRED"); }
    private boolean matchesSearchArea(GuideProfile g, String area) { return area==null || area.isBlank() || matchesRequiredArea(g, area); }
    private boolean matchesRequiredArea(GuideProfile g, String area) { return matchesServiceArea(g.getPrimaryServiceArea(), area) || (g.getServiceAreas()!=null && g.getServiceAreas().stream().anyMatch(a->matchesServiceArea(a, area))); }
    private GuideBooking authorized(Long userId,String id) {
        actor(userId); GuideBooking b=em.find(GuideBooking.class,id,LockModeType.PESSIMISTIC_WRITE);
        if(b==null || !(b.getTourist().getId().equals(userId) || b.getGuide().getUser().getId().equals(userId))) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Booking not found");
        expire(b); return b;
    }
    public List<BookingView> mine(Long userId) {
        actor(userId);
        return em.createQuery("select b from GuideBooking b where b.tourist.id=:u or b.guide.user.id=:u order by b.startsAt desc",GuideBooking.class).setParameter("u",userId).getResultList().stream()
            .map(b->{expire(b);return view(b,userId);}).toList();
    }
    public BookingView get(Long userId,String id) {return view(authorized(userId,id),userId);}
    private boolean demoEnabled() {return demoPayments && Arrays.asList(profiles.split(",")).contains("demo");}
    public Checkout checkout(Long userId,String id) {
        GuideBooking b=authorized(userId,id); tourist(b,userId);
        if(!b.getState().equals("HELD")) throw bad("Booking hold is no longer payable");
        return new Checkout(b.getId(),reference(b),b.getAmount(),"LKR",b.getGuide().getDisplayName(),b.getPackageName(),b.getLandmark(),b.getStartsAt(),b.getVisitors(),b.getHoldExpiresAt(),demoEnabled());
    }
    private void tourist(GuideBooking b,Long u) {if(!b.getTourist().getId().equals(u)) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Only the booking traveler may pay");}

    /** Internal payment-team boundary. Call ONLY after a server-side gateway verification.
     * No controller exposes this method; client success flags must never invoke it. */
    public void confirmVerifiedPayment(String id, BigDecimal settledAmount, String currency, String gatewayReference) {
        GuideBooking b=em.find(GuideBooking.class,id,LockModeType.PESSIMISTIC_WRITE);
        if(b==null) throw bad("Booking not found");
        if(gatewayReference==null || gatewayReference.isBlank() || gatewayReference.startsWith("demo:") || !"LKR".equals(currency) || settledAmount==null || settledAmount.compareTo(b.getAmount())!=0) throw bad("Verified payment does not match booking");
        if("PAID".equals(b.getPaymentState()) && gatewayReference.equals(b.getPaymentReference())) return;
        eligible(b.getGuide().getId(),true);expire(b);
        if(!"HELD".equals(b.getState())) throw bad("Hold is not payable; payment team must reconcile/refund settlement");
        b.setPaymentReference(gatewayReference);b.setPaymentState("PAID");b.setState("CONFIRMED");
    }
    public BookingView demoPay(Long userId,String id,String outcome) {
        if(!demoEnabled()) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Demo checkout disabled");
        GuideBooking b=authorized(userId,id); tourist(b,userId);
        if(b.getPaymentState().equals("DEMO_PAID")) return view(b,userId);
        if(!b.getState().equals("HELD")) throw bad("Hold expired or booking is no longer payable");
        switch(outcome) {
            case "success" -> {
                eligible(b.getGuide().getId(),true);
                expire(b);
                if (!b.getState().equals("HELD")) throw bad("Hold expired while checkout was pending");
                b.setPaymentState("DEMO_PAID");b.setPaymentReference("demo:"+b.getId());b.setState("CONFIRMED");
                notifyBookingParticipants(
                    b,
                    "BOOKING_CONFIRMED",
                    "Booking confirmed",
                    "Payment was completed for " + b.getPackageName() + "."
                );
            }
            case "failure" -> {
                b.setPaymentState("FAILED");
                notifyBookingParticipants(
                    b,
                    "BOOKING_PAYMENT_FAILED",
                    "Booking payment failed",
                    "Payment failed for " + b.getPackageName() + "."
                );
            }
            case "cancel" -> {
                b.setPaymentState("CANCELLED");b.setState("CANCELLED");
                notifyBookingParticipants(
                    b,
                    "BOOKING_CANCELLED",
                    "Booking cancelled",
                    "Checkout was cancelled for " + b.getPackageName() + "."
                );
            }
            default -> throw bad("Unknown checkout outcome");
        }
        return view(b,userId);
    }
    public BookingView transition(Long userId,String id,String next) {
        GuideBooking b=authorized(userId,id);
        boolean guide=b.getGuide().getUser().getId().equals(userId);
        if(next.equals("CANCELLED") && Set.of("HELD","CONFIRMED","EN_ROUTE","ARRIVED").contains(b.getState())) {
            b.setState(next); if(Set.of("PAID","DEMO_PAID").contains(b.getPaymentState())) b.setPaymentState("REFUND_REQUIRED");
        } else {
            if(!guide) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Assigned guide required");
            String expected=switch(b.getState()) {case "CONFIRMED"->"EN_ROUTE";case "EN_ROUTE"->"ARRIVED";case "ARRIVED"->"IN_PROGRESS";case "IN_PROGRESS"->"COMPLETED";default->"";};
            if(!next.equals(expected) || (next.equals("IN_PROGRESS") && b.getPinUsedAt()==null)) throw bad("Invalid transition or meeting code not verified");
            if(Instant.now().isBefore(b.getStartsAt().minusSeconds(7200)) || Instant.now().isAfter(b.getPinExpiresAt())) throw bad("Booking is outside its active service window");
            b.setState(next);
        }
        if(!ACTIVE.contains(b.getState())) {b.setLatitude(null);b.setLongitude(null);b.setEta(null);}
        notifyBookingParticipants(
            b,
            "BOOKING_STATUS",
            "Booking status updated",
            "Booking " + reference(b) + " is now " + formatState(b.getState()) + "."
        );
        return view(b,userId);
    }
    public BookingView location(Long userId,String id,LocationInput r) {
        GuideBooking b=authorized(userId,id);
        if(!b.getGuide().getUser().getId().equals(userId)) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Assigned guide required");
        if(!Set.of("EN_ROUTE","ARRIVED","IN_PROGRESS").contains(b.getState()) || Instant.now().isAfter(b.getPinExpiresAt())) throw bad("Location sharing is not active");
        if(r.eta()!=null && (r.eta().isBefore(Instant.now()) || r.eta().isAfter(Instant.now().plusSeconds(14400)))) throw bad("ETA must be within the next four hours");
        b.setLatitude(r.latitude());b.setLongitude(r.longitude());b.setLocationUpdatedAt(Instant.now());b.setEta(r.eta());
        return view(b,userId);
    }
    public Map<String,Object> verifyPin(Long userId,String id,String pin) {
        GuideBooking b=authorized(userId,id);
        if(!b.getGuide().getUser().getId().equals(userId)) throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Assigned guide confirms the meeting code");
        if(!b.getState().equals("ARRIVED") || b.getPinUsedAt()!=null || b.getPinAttempts()>=5 || !b.getPinExpiresAt().isAfter(Instant.now())) return Map.of("verified",false,"message","Code expired, used, locked, or guide has not arrived");
        b.setPinAttempts(b.getPinAttempts()+1);
        if(!b.getMeetingPin().equals(pin)) return Map.of("verified",false,"message","Incorrect code; "+(5-b.getPinAttempts())+" attempts remaining");
        b.setPinUsedAt(Instant.now()); return Map.of("verified",true,"message","Meeting confirmed online");
    }
    public Map<String,Object> management(Long userId) {
        GuideProfile g=ownGuide(userId);
        var ws=em.createQuery("select w from GuideWindow w where w.guide.id=:g and w.endsAt>:now order by w.startsAt",GuideWindow.class).setParameter("g",g.getId()).setParameter("now",Instant.now()).getResultList();
        return Map.of("packages",packages(g.getId()).stream().map(this::packageView).toList(),"windows",ws.stream().map(w->Map.of("id",w.getId(),"startsAt",w.getStartsAt(),"endsAt",w.getEndsAt())).toList());
    }
    public PackageView savePackage(Long userId,PackageInput r) {
        GuideProfile g=ownGuide(userId); GuidePackage p=r.id()==null?new GuidePackage():em.find(GuidePackage.class,r.id());
        if(p==null || (p.getId()!=null && !p.getGuide().getId().equals(g.getId()))) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Package not found");
        if(r.minVisitors()>r.maxVisitors()) throw bad("Minimum visitors exceeds capacity");
        p.setGuide(g);p.setName(r.name());p.setFeatures(r.features());p.setDurationMinutes(r.durationMinutes());p.setPricePerVisitor(r.pricePerVisitor());p.setMinVisitors(r.minVisitors());p.setMaxVisitors(r.maxVisitors());p.setEnabled(r.enabled());
        if(p.getId()==null) em.persist(p);return packageView(p);
    }
    public void addWindow(Long userId,WindowInput r) {
        GuideProfile g=ownGuide(userId);
        if(!r.startsAt().isAfter(Instant.now()) || !r.endsAt().isAfter(r.startsAt()) || Duration.between(r.startsAt(),r.endsAt()).toHours()>24 || r.endsAt().isAfter(Instant.now().plusSeconds(366*86400L))) throw bad("Enter a future window of at most 24 hours within the next year");
        GuideWindow w=new GuideWindow();w.setGuide(g);w.setStartsAt(r.startsAt());w.setEndsAt(r.endsAt());em.persist(w);
    }
    public void removeWindow(Long userId,Long id) {
        GuideProfile g=ownGuide(userId);GuideWindow w=em.find(GuideWindow.class,id);
        if(w==null || !w.getGuide().getId().equals(g.getId())) throw new ResponseStatusException(HttpStatus.NOT_FOUND,"Window not found");
        em.remove(w); // Existing reservations retain their schedule.
    }
    private String reference(GuideBooking b) {return "HS-"+b.getId().substring(0,8).toUpperCase(Locale.ROOT);}
    private void notifyBookingParticipants(GuideBooking b, String type, String title, String message) {
        String referenceId = b.getId();
        notificationService.notifyUser(b.getTourist(),type,title,message,"GUIDE_BOOKING",referenceId,"/bookings/"+referenceId);
        notificationService.notifyUser(b.getGuide().getUser(),type,title,message,"GUIDE_BOOKING",referenceId,"/guide/bookings/"+referenceId);
    }
    private String formatState(String state) {
        return state == null ? "updated" : state.replace('_',' ').toLowerCase(Locale.ROOT);
    }
    private BookingView view(GuideBooking b,Long userId) {
        boolean active=ACTIVE.contains(b.getState()) && b.getPinExpiresAt().isAfter(Instant.now());
        return new BookingView(b.getId(),reference(b),b.getGuide().getId(),b.getGuide().getDisplayName(),b.getGuide().getUser().getPhone(),b.getTourist().getId().equals(userId)?b.getGuide().getUser().getPhone():b.getTourist().getPhone(),b.getPackageName(),b.getLandmark(),b.getStartsAt(),b.getEndsAt(),b.getVisitors(),b.getAmount(),"LKR",b.getState(),b.getPaymentState(),b.getHoldExpiresAt(),active&&b.getPinUsedAt()==null?b.getMeetingPin():null,b.getPinExpiresAt(),b.getPinUsedAt()!=null,Math.max(0,5-b.getPinAttempts()),active?b.getLatitude():null,active?b.getLongitude():null,b.getLocationUpdatedAt(),active?b.getEta():null,demoEnabled());
    }
}

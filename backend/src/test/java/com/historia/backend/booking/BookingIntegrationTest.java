package com.historia.backend.booking;

import com.historia.backend.BackendApplication;
import com.historia.backend.entity.*;
import com.historia.backend.enums.*;
import com.historia.backend.security.JwtService;
import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.*;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.web.server.ResponseStatusException;
import java.net.URI;
import java.net.http.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static com.historia.backend.booking.BookingDto.*;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class BookingIntegrationTest {
    EmbeddedPostgres postgres;
    ConfigurableApplicationContext context;
    BookingService service;
    EntityManager em;
    TransactionTemplate tx;
    long tourist,other,guideUser,guide,pack;
    Instant start;

    @BeforeAll void boot() throws Exception {
        postgres=EmbeddedPostgres.builder().setPort(0).start();
        byte[] key=new byte[64];new java.security.SecureRandom().nextBytes(key);
        context=new SpringApplicationBuilder(BackendApplication.class).run(
            "--spring.config.import=", "--spring.datasource.url="+postgres.getJdbcUrl("postgres","postgres"),
            "--spring.datasource.username=postgres","--spring.datasource.password=postgres",
            "--spring.jpa.hibernate.ddl-auto=create", "--server.port=0", "--spring.profiles.active=demo",
            "--historia.booking.demo-payments=true", "--historia.booking.seed=false",
            "--jwt.secret="+Base64.getEncoder().encodeToString(key),"--google.oauth.client-id=",
            "--admin.username=","--admin.email=","--admin.password=", "--logging.level.org.hibernate.SQL=WARN", "--logging.level.org.springframework.web=WARN");
        service=context.getBean(BookingService.class);
        // Shared proxy uses the current thread's transaction, including concurrent workers.
        em=org.springframework.orm.jpa.SharedEntityManagerCreator.createSharedEntityManager(context.getBean(jakarta.persistence.EntityManagerFactory.class));
        tx=new TransactionTemplate(context.getBean(PlatformTransactionManager.class));
    }
    @AfterAll void close() throws Exception {if(context!=null)context.close();if(postgres!=null)postgres.close();}
    @BeforeEach void fixture() {
        tx.executeWithoutResult(s->{
            String suffix=UUID.randomUUID().toString().substring(0,8);
            User t=user("traveler"+suffix,Role.TOURIST),o=user("other"+suffix,Role.TOURIST),u=user("guide"+suffix,Role.GUIDE);
            tourist=t.getId();other=o.getId();guideUser=u.getId();
            GuideProfile g=new GuideProfile();g.setUser(u);g.setDisplayName("Guide "+suffix);g.setPrimaryServiceArea("Galle Fort");g.setLanguages(new LinkedHashSet<>(List.of("English","Tamil")));g.setSpecialties(new LinkedHashSet<>(List.of("Ramparts")));g.setYearsExperience(5);g.setStatus(GuideApplicationStatus.APPROVED);em.persist(g);em.flush();guide=g.getId();
            GuidePackage p=new GuidePackage();p.setGuide(g);p.setName("Full Heritage Walk");p.setPricePerVisitor(new BigDecimal("2500.00"));p.setDurationMinutes(120);p.setMinVisitors(1);p.setMaxVisitors(5);em.persist(p);em.flush();pack=p.getId();
            start=Instant.now().plusSeconds(1800).truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
            GuideWindow w=new GuideWindow();w.setGuide(g);w.setStartsAt(start);w.setEndsAt(start.plusSeconds(6*3600));em.persist(w);
        });
    }
    User user(String name,Role role){User u=User.builder().username(name).email(name+"@example.invalid").password("test-only-unused-hash").role(role).emailVerified(true).enabled(true).build();em.persist(u);em.flush();return u;}
    HoldInput request(String key,Instant time,int visitors){return new HoldInput(guide,pack,"clock",time,visitors,key);}
    BookingView hold(){return service.hold(tourist,request(UUID.randomUUID().toString(),start,3));}
    BookingView confirmed(){BookingView b=hold();return service.demoPay(tourist,b.id(),"success");}

    @Test void pricingLimitsAndSchedule() {
        assertThrows(ResponseStatusException.class,()->service.hold(tourist,request("over",start,6)));
        assertThrows(ResponseStatusException.class,()->service.hold(tourist,request("past",start.minusSeconds(86400),1)));
        BookingView b=hold();assertEquals(new BigDecimal("7500.00"),b.amount());assertEquals(start,b.startsAt());assertEquals(start.plusSeconds(7200),b.endsAt());assertNull(b.meetingPin());
        assertEquals(b.amount(),service.checkout(tourist,b.id()).amount());
    }
    @Test void retriesAreIdempotentAndPayloadBound() {
        HoldInput r=request("repeat",start,2);BookingView a=service.hold(tourist,r),b=service.hold(tourist,r);assertEquals(a.id(),b.id());
        assertThrows(ResponseStatusException.class,()->service.hold(tourist,request("repeat",start,3)));
    }
    @Test void concurrentOverlappingDurationsAllowOnlyOneReservation() throws Exception {
        ExecutorService pool=Executors.newFixedThreadPool(2);CountDownLatch ready=new CountDownLatch(2),go=new CountDownLatch(1);
        try {
            Callable<Boolean> first=()->{ready.countDown();go.await();try{service.hold(tourist,request("race1",start,1));return true;}catch(ResponseStatusException e){return false;}};
            Callable<Boolean> second=()->{ready.countDown();go.await();try{service.hold(other,request("race2",start.plusSeconds(1800),1));return true;}catch(ResponseStatusException e){return false;}};
            Future<Boolean>a=pool.submit(first),b=pool.submit(second);assertTrue(ready.await(5,TimeUnit.SECONDS));go.countDown();assertNotEquals(a.get(20,TimeUnit.SECONDS),b.get(20,TimeUnit.SECONDS));
        } finally {pool.shutdownNow();}
    }
    @Test void expiredHoldReleasesIntervalAndCannotBePaid() {
        BookingView b=hold();tx.executeWithoutResult(s->em.find(GuideBooking.class,b.id()).setHoldExpiresAt(Instant.now().minusSeconds(1)));
        assertThrows(ResponseStatusException.class,()->service.demoPay(tourist,b.id(),"success"));
        assertEquals("HELD",service.hold(other,request("after-expiry",start,1)).state());
    }
    @Test void ownershipProtectsReadsLocationCheckoutAndPin() {
        BookingView b=confirmed();assertThrows(ResponseStatusException.class,()->service.get(other,b.id()));
        assertThrows(ResponseStatusException.class,()->service.verifyPin(other,b.id(),"0000"));
        assertThrows(ResponseStatusException.class,()->service.location(tourist,b.id(),new LocationInput(6.03,80.21,null)));
        assertThrows(ResponseStatusException.class,()->service.checkout(guideUser,b.id()));
        assertThrows(ResponseStatusException.class,()->service.transition(tourist,b.id(),"EN_ROUTE"));
    }
    @Test void paymentFailureCancelSuccessAndProductionGate() {
        BookingView b=hold();assertEquals("FAILED",service.demoPay(tourist,b.id(),"failure").paymentState());
        assertEquals("HELD",service.get(tourist,b.id()).state());assertEquals("CANCELLED",service.demoPay(tourist,b.id(),"cancel").state());
        BookingView c=hold();assertEquals("CONFIRMED",service.demoPay(tourist,c.id(),"success").state());assertEquals("CONFIRMED",service.demoPay(tourist,c.id(),"success").state());
        Object target=org.springframework.test.util.AopTestUtils.getTargetObject(service);
        org.springframework.test.util.ReflectionTestUtils.setField(target,"profiles","");
        try {assertThrows(ResponseStatusException.class,()->service.demoPay(tourist,c.id(),"success"));}
        finally {org.springframework.test.util.ReflectionTestUtils.setField(target,"profiles","demo");}
    }
    @Test void guideUpdatesPinSingleUseAndCompletion() {
        BookingView b=confirmed();assertTrue(b.meetingPin().matches("[0-9]{4}"));
        service.transition(guideUser,b.id(),"EN_ROUTE");Instant eta=Instant.now().plusSeconds(600).truncatedTo(java.time.temporal.ChronoUnit.MILLIS);
        service.location(guideUser,b.id(),new LocationInput(6.03,80.21,eta));assertEquals(eta,service.get(tourist,b.id()).eta());
        service.transition(guideUser,b.id(),"ARRIVED");assertThrows(ResponseStatusException.class,()->service.transition(guideUser,b.id(),"IN_PROGRESS"));
        assertEquals(true,service.verifyPin(guideUser,b.id(),b.meetingPin()).get("verified"));
        assertEquals(false,service.verifyPin(guideUser,b.id(),b.meetingPin()).get("verified"));
        service.transition(guideUser,b.id(),"IN_PROGRESS");service.transition(guideUser,b.id(),"COMPLETED");
        BookingView done=service.get(tourist,b.id());assertNull(done.latitude());assertNull(done.meetingPin());assertFalse(done.state().equals("IN_PROGRESS"));
        assertThrows(ResponseStatusException.class,()->service.location(guideUser,b.id(),new LocationInput(6.03,80.21,null)));
    }
    @Test void pinAttemptLimitAndExpiry() {
        BookingView b=confirmed();service.transition(guideUser,b.id(),"EN_ROUTE");service.transition(guideUser,b.id(),"ARRIVED");
        String wrong=b.meetingPin().equals("0000")?"0001":"0000";
        for(int i=0;i<5;i++)assertEquals(false,service.verifyPin(guideUser,b.id(),wrong).get("verified"));
        assertEquals(false,service.verifyPin(guideUser,b.id(),b.meetingPin()).get("verified"));assertEquals(0,service.get(tourist,b.id()).pinAttemptsRemaining());
        tx.executeWithoutResult(s->{GuideBooking entity=em.find(GuideBooking.class,b.id());entity.setPinAttempts(0);entity.setPinExpiresAt(Instant.now().minusSeconds(1));});
        assertEquals(false,service.verifyPin(guideUser,b.id(),b.meetingPin()).get("verified"));
    }
    @Test void filtersAndDisabledGuideEligibility() {
        String name=tx.execute(s->em.find(GuideProfile.class,guide).getDisplayName());
        assertEquals(1,service.discover(name,"Tamil","Galle Fort","Ramparts",false,null,start.atZone(BookingService.ZONE).toLocalDate(),start).size());
        assertTrue(service.discover(name,"Sinhala","Galle Fort","",false,null,null,null).isEmpty());
        assertTrue(service.discover(name,"","","",true,null,null,null).isEmpty());
        assertTrue(service.discover(name,"","","",false,4.8,null,null).isEmpty());
        tx.executeWithoutResult(s->em.find(User.class,guideUser).setEnabled(false));
        assertThrows(ResponseStatusException.class,this::hold);
        assertTrue(service.discover(name,"","","",false,null,null,null).isEmpty());
    }
    @Test void trustedPaymentBoundaryRejectsTamperingAndIsIdempotent() {
        BookingView b=hold();
        assertThrows(ResponseStatusException.class,()->service.confirmVerifiedPayment(b.id(),new BigDecimal("1.00"),"LKR","gateway-1"));
        assertThrows(ResponseStatusException.class,()->service.confirmVerifiedPayment(b.id(),b.amount(),"USD","gateway-1"));
        service.confirmVerifiedPayment(b.id(),b.amount(),"LKR","gateway-"+b.id());
        service.confirmVerifiedPayment(b.id(),b.amount(),"LKR","gateway-"+b.id());
        assertEquals("PAID",service.get(tourist,b.id()).paymentState());
    }
    @Test void managementOwnershipAndSnapshotRates() {
        assertThrows(ResponseStatusException.class,()->service.management(tourist));
        BookingView b=hold();
        service.savePackage(guideUser,new PackageInput(pack,"Updated package","Features",45,new BigDecimal("4000.00"),1,2,true));
        BookingView retained=service.get(tourist,b.id());assertEquals(new BigDecimal("7500.00"),retained.amount());assertEquals("Full Heritage Walk",retained.packageName());assertEquals(start.plusSeconds(7200),retained.endsAt());
        assertThrows(ResponseStatusException.class,()->service.savePackage(guideUser,new PackageInput(pack,"Invalid",null,45,new BigDecimal("4000.00"),5,2,true)));
    }
    @Test void httpBoundaryRequiresJwtAndRejectsOutsider() throws Exception {
        BookingView b=confirmed();HttpClient client=HttpClient.newHttpClient();String base="http://localhost:"+context.getEnvironment().getProperty("local.server.port")+"/api/guide-bookings/";
        int anonymous=client.send(HttpRequest.newBuilder(URI.create(base+b.id())).GET().build(),HttpResponse.BodyHandlers.ofString()).statusCode();assertTrue(anonymous==401||anonymous==403);
        String otherToken=tx.execute(s->context.getBean(JwtService.class).generateAccessToken(em.find(User.class,other)));
        var response=client.send(HttpRequest.newBuilder(URI.create(base+b.id())).header("Authorization","Bearer "+otherToken).GET().build(),HttpResponse.BodyHandlers.ofString());assertEquals(404,response.statusCode());assertFalse(response.body().contains(b.meetingPin()));
        String token=tx.execute(s->context.getBean(JwtService.class).generateAccessToken(em.find(User.class,tourist)));
        var own=client.send(HttpRequest.newBuilder(URI.create(base+b.id())).header("Authorization","Bearer "+token).GET().build(),HttpResponse.BodyHandlers.ofString());assertEquals(200,own.statusCode());assertTrue(own.body().contains(b.id()));
    }

    @Test void existingReadRoutesAndBuddyRoleRestrictionRemainUsable() throws Exception {
        HttpClient client=HttpClient.newHttpClient();String base="http://localhost:"+context.getEnvironment().getProperty("local.server.port");
        String travelerToken=tx.execute(s->context.getBean(JwtService.class).generateAccessToken(em.find(User.class,tourist)));
        String guideToken=tx.execute(s->context.getBean(JwtService.class).generateAccessToken(em.find(User.class,guideUser)));
        for(String route:List.of("/api/users/me","/api/places","/api/tours/user/"+tourist,"/api/buddies/conversations","/api/guides/approved?area=Galle%20Fort")) {
            assertEquals(200,client.send(HttpRequest.newBuilder(URI.create(base+route)).header("Authorization","Bearer "+travelerToken).GET().build(),HttpResponse.BodyHandlers.ofString()).statusCode(),route);
        }
        assertEquals(200,client.send(HttpRequest.newBuilder(URI.create(base+"/api/guides/me")).header("Authorization","Bearer "+guideToken).GET().build(),HttpResponse.BodyHandlers.ofString()).statusCode());
        assertEquals(403,client.send(HttpRequest.newBuilder(URI.create(base+"/api/buddies/conversations")).header("Authorization","Bearer "+guideToken).GET().build(),HttpResponse.BodyHandlers.ofString()).statusCode());
    }
}

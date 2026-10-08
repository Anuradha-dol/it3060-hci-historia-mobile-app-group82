package com.historia.backend.booking;
import com.historia.backend.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.*;
import java.util.*;
import static com.historia.backend.booking.BookingDto.*;

@RestController @RequestMapping("/api/guide-bookings") @RequiredArgsConstructor
public class BookingController {
    private final BookingService service;
    @GetMapping("/guides") public List<GuideView> guides(@RequestParam(defaultValue="") String q,@RequestParam(defaultValue="") String language,@RequestParam(defaultValue="") String area,@RequestParam(defaultValue="") String specialty,@RequestParam(defaultValue="false") boolean certified,@RequestParam(required=false) Double rating,@RequestParam(required=false) LocalDate date,@RequestParam(required=false) Instant at) {return service.discover(q,language,area,specialty,certified,rating,date,at);}
    @GetMapping("/landmarks") public List<MeetingLandmark> landmarks(){return service.landmarks();}
    @GetMapping("/slots") public List<Instant> slots(@RequestParam Long guideId,@RequestParam Long packageId,@RequestParam LocalDate date){return service.slots(guideId,packageId,date);}
    @GetMapping public List<BookingView> mine(@AuthenticationPrincipal User u){return service.mine(u.getId());}
    @PostMapping public BookingView hold(@AuthenticationPrincipal User u,@Valid @RequestBody HoldInput r){return service.hold(u.getId(),r);}
    @GetMapping("/{id}") public BookingView get(@AuthenticationPrincipal User u,@PathVariable String id){return service.get(u.getId(),id);}
    @GetMapping("/{id}/checkout") public Checkout checkout(@AuthenticationPrincipal User u,@PathVariable String id){return service.checkout(u.getId(),id);}
    @PostMapping("/{id}/demo-checkout") public BookingView pay(@AuthenticationPrincipal User u,@PathVariable String id,@Valid @RequestBody PaymentInput r){return service.demoPay(u.getId(),id,r.outcome());}
    @PostMapping("/{id}/state") public BookingView state(@AuthenticationPrincipal User u,@PathVariable String id,@Valid @RequestBody StateInput r){return service.transition(u.getId(),id,r.state());}
    @PostMapping("/{id}/location") public BookingView location(@AuthenticationPrincipal User u,@PathVariable String id,@Valid @RequestBody LocationInput r){return service.location(u.getId(),id,r);}
    @PostMapping("/{id}/verify-pin") public Map<String,Object> pin(@AuthenticationPrincipal User u,@PathVariable String id,@Valid @RequestBody PinInput r){return service.verifyPin(u.getId(),id,r.pin());}
    @GetMapping("/management") public Map<String,Object> management(@AuthenticationPrincipal User u){return service.management(u.getId());}
    @PutMapping("/management/packages") public PackageView packages(@AuthenticationPrincipal User u,@Valid @RequestBody PackageInput r){return service.savePackage(u.getId(),r);}
    @PostMapping("/management/windows") public void window(@AuthenticationPrincipal User u,@Valid @RequestBody WindowInput r){service.addWindow(u.getId(),r);}
    @DeleteMapping("/management/windows/{id}") public void removeWindow(@AuthenticationPrincipal User u,@PathVariable Long id){service.removeWindow(u.getId(),id);}
}

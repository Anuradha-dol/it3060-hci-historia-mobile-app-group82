package com.historia.backend.booking;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
@Component @RequiredArgsConstructor
public class LandmarkInitializer implements CommandLineRunner {
    private final EntityManager em;
    @Override @Transactional public void run(String... args) {
        add("clock","Clock Tower Gate","Meet by the clock tower entrance. Confirm the exact side with your guide.","Prototype estimate: 5 minutes from main car park; confirm locally.",.62,.30);
        add("sun","Sun Bastion","Meet at the Sun Bastion landmark. Confirm the accessible entrance with your guide.","Rampart paths may include steps; ask your guide about accessible access.",.82,.42);
        add("moon","Moon Bastion","Meet at the Moon Bastion landmark.","Use the public access path; confirm current access with your guide.",.34,.32);
    }
    private void add(String id,String name,String description,String access,double x,double y){if(em.find(MeetingLandmark.class,id)!=null)return;MeetingLandmark l=new MeetingLandmark();l.setId(id);l.setName(name);l.setArea("Galle Fort");l.setDescription(description);l.setAccessInfo(access);l.setMapX(x);l.setMapY(y);em.persist(l);}
}

package com.historia.backend.booking;

import com.historia.backend.BackendApplication;
import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.springframework.boot.builder.SpringApplicationBuilder;
import java.nio.file.*;
import java.security.SecureRandom;
import java.util.*;

/** Disposable, loopback-only verification server. No application-local.yml or permanent DB. */
public class LocalDemoServer {
    public static void main(String[] args) throws Exception {
        byte[] key=new byte[64];new SecureRandom().nextBytes(key);
        String password=UUID.randomUUID().toString();
        try(var pg=EmbeddedPostgres.builder().setPort(0).start();
            var app=new SpringApplicationBuilder(BackendApplication.class).run(
                "--spring.config.import=","--spring.datasource.url="+pg.getJdbcUrl("postgres","postgres"),
                "--spring.datasource.username=postgres","--spring.datasource.password=postgres",
                "--spring.jpa.hibernate.ddl-auto=create","--server.port=8081","--server.address=127.0.0.1",
                "--spring.profiles.active=demo","--historia.booking.demo-payments=true","--historia.booking.seed=true",
                "--HISTORIA_DEMO_PASSWORD="+password,"--jwt.secret="+Base64.getEncoder().encodeToString(key),
                "--google.oauth.client-id=test-client-id","--admin.username=","--admin.email=","--admin.password=",
                "--logging.level.org.hibernate.SQL=WARN","--logging.level.org.springframework.web=WARN")) {
            Path target=Path.of("target/demo-session.json");
            Files.writeString(target,"{\"password\":\""+password+"\",\"baseUrl\":\"http://localhost:8081\"}");
            System.out.println("Disposable demo ready on localhost:8081. Credentials are in ignored target/demo-session.json. Stops after 30 minutes or target/stop-demo appears.");
            long end=System.currentTimeMillis()+1800000;
            while(System.currentTimeMillis()<end && !Files.exists(Path.of("target/stop-demo")))Thread.sleep(1000);
            Files.deleteIfExists(target);
        }
    }
}

package com.historia.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.LinkedHashSet;
import java.util.Set;
import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(
            ResourceHandlerRegistry registry
    ) {

        Set<String> uploadLocations = new LinkedHashSet<>();

        uploadLocations.add(
                Paths.get("uploads")
                        .toAbsolutePath()
                        .normalize()
                        .toUri()
                        .toString()
        );

        uploadLocations.add(
                Paths.get("..", "uploads")
                        .toAbsolutePath()
                        .normalize()
                        .toUri()
                        .toString()
        );

        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(
                        uploadLocations.toArray(String[]::new)
                );
    }
}

package com.example;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import java.util.Arrays;

@Controller
public class ReflectionController {

    @Get("/reflection")
    public String message() {
        return getMessage();
    }

    private String getMessage() {
        try {
            String className = String.join(".", Arrays.asList("com", "example", "Message"));
            return (String) Class.forName(className).getDeclaredField("MESSAGE").get(null);
        } catch (Exception e) {
            return "Got an error: " + e.getMessage();
        }
    }
}
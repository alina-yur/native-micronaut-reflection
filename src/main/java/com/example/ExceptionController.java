package com.example;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public class ExceptionController {

    @Get("/error")
    public String throwError() {
        throw new RuntimeException("Something went wrong!");
    }

}
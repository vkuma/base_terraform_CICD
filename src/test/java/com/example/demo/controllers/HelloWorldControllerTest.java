package com.example.demo.controllers;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertEquals;


@DisplayName("Write assertions for Hello World Controller")
public class HelloWorldControllerTest {
    public HelloWorldController helloWorldController = new HelloWorldController();

    @Test
    @DisplayName("Should be equal")
    public void helloTest(){
        assertEquals("Hello World!",helloWorldController.helloWorld());
    }
}

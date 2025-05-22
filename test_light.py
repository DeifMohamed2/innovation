"""
Simple light test for ESP32
This script tests the GPIO output for controlling a light
"""
from machine import Pin
import time

# Define the light pin (use the same pin as in your integrated_system.py)
LIGHT_PIN = 13

# Create pin object for light
light_pin = Pin(LIGHT_PIN, Pin.OUT)

# Turn light on
print(f"Turning light ON (Pin {LIGHT_PIN})")
light_pin.value(1)
time.sleep(2)

# Turn light off
print(f"Turning light OFF (Pin {LIGHT_PIN})")
light_pin.value(0)
time.sleep(2)

# Toggle light 5 times
print(f"Toggling light (Pin {LIGHT_PIN}) 5 times")
for i in range(5):
    light_pin.value(1)
    print(f"ON - {i+1}/5")
    time.sleep(0.5)
    light_pin.value(0)
    print(f"OFF - {i+1}/5")
    time.sleep(0.5)

print("Light test complete") 
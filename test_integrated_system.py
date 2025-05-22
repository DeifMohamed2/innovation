#!/usr/bin/env python3
"""
Test script for integrated_system.py
This script tests the functionality of the integrated system in a standard Python environment.
"""
import time
import json
import os
import sys
import firebase_admin
from firebase_admin import credentials, db

# Check if serviceAccountKey.json exists
if not os.path.exists('serviceAccountKey.json'):
    print("Error: serviceAccountKey.json not found!")
    print("Please create a serviceAccountKey.json file with your Firebase credentials.")
    sys.exit(1)

# Firebase configuration
FIREBASE_URL = "https://smarthub-60812-default-rtdb.firebaseio.com"

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_app = firebase_admin.initialize_app(cred, {
    'databaseURL': FIREBASE_URL
})

def create_test_room():
    """Create a test room in Firebase"""
    print("Creating test room...")
    
    # Generate a unique ID for the test room
    rooms_ref = db.reference('rooms')
    new_room_ref = rooms_ref.push()
    room_id = new_room_ref.key
    
    # Room data
    room_data = {
        'name': f'Test Room {int(time.time())}',
        'hasLights': True,
        'hasDoor': True,
        'lightPin': 13,  # Use default pin
        'doorPin': 15,   # Use default pin
        'lightStatus': False,
        'doorStatus': False
    }
    
    # Push to Firebase
    new_room_ref.set(room_data)
    print(f"Test room created with ID: {room_id}")
    return room_id

def toggle_light(room_id, state):
    """Toggle a light in a room"""
    print(f"Setting light in room {room_id} to: {'ON' if state else 'OFF'}")
    room_ref = db.reference(f'rooms/{room_id}')
    room_ref.update({'lightStatus': state})
    
    # Wait for a moment to simulate real-world delay
    time.sleep(1)
    
    # Verify the change
    current_state = room_ref.child('lightStatus').get()
    if current_state == state:
        print(f"✅ Light successfully set to {'ON' if state else 'OFF'}")
    else:
        print(f"❌ Light state verification failed: expected {'ON' if state else 'OFF'}, got {'ON' if current_state else 'OFF'}")

def toggle_door(room_id, state):
    """Toggle a door in a room"""
    print(f"Setting door in room {room_id} to: {'OPEN' if state else 'CLOSED'}")
    room_ref = db.reference(f'rooms/{room_id}')
    room_ref.update({'doorStatus': state})
    
    # Wait for a moment to simulate real-world delay
    time.sleep(1)
    
    # Verify the change
    current_state = room_ref.child('doorStatus').get()
    if current_state == state:
        print(f"✅ Door successfully set to {'OPEN' if state else 'CLOSED'}")
    else:
        print(f"❌ Door state verification failed: expected {'OPEN' if state else 'CLOSED'}, got {'OPEN' if current_state else 'CLOSED'}")

def toggle_ac(state):
    """Toggle the AC"""
    print(f"Setting AC to: {'ON' if state else 'OFF'}")
    ac_ref = db.reference('esp_control')
    ac_ref.update({'ac': state})
    
    # Wait for a moment to simulate real-world delay
    time.sleep(1)
    
    # Verify the change
    current_state = ac_ref.child('ac').get()
    if current_state == state:
        print(f"✅ AC successfully set to {'ON' if state else 'OFF'}")
    else:
        print(f"❌ AC state verification failed: expected {'ON' if state else 'OFF'}, got {'ON' if current_state else 'OFF'}")

def verify_system_status():
    """Verify system status in Firebase"""
    print("Checking system status...")
    status_ref = db.reference('esp_status')
    status = status_ref.get()
    
    if status:
        print(f"System status:")
        print(f"  Online: {status.get('online', 'Unknown')}")
        print(f"  IP: {status.get('ip', 'Unknown')}")
        print(f"  Last update: {status.get('last_update', 'Unknown')}")
        last_update = status.get('last_update', 0)
        time_diff = int(time.time() * 1000) - last_update
        print(f"  Time since last update: {time_diff/1000:.1f} seconds")
        
        if time_diff > 60000:  # More than 1 minute
            print("❌ System may be offline (last update >1 minute ago)")
        else:
            print("✅ System appears to be online")
    else:
        print("❌ No system status information found!")

def cleanup_test_room(room_id):
    """Clean up the test room"""
    print(f"Cleaning up test room {room_id}...")
    room_ref = db.reference(f'rooms/{room_id}')
    room_ref.delete()
    print("Test room deleted.")

def run_tests():
    """Run all tests"""
    print("Starting integrated system tests...\n")
    
    # Create a test room
    room_id = create_test_room()
    
    try:
        # Toggle light tests
        print("\n=== Light Control Test ===")
        toggle_light(room_id, True)   # Turn on
        toggle_light(room_id, False)  # Turn off
        
        # Toggle door tests
        print("\n=== Door Control Test ===")
        toggle_door(room_id, True)    # Open
        toggle_door(room_id, False)   # Close
        
        # Toggle AC tests
        print("\n=== AC Control Test ===")
        toggle_ac(True)               # Turn on
        toggle_ac(False)              # Turn off
        
        # Check system status
        print("\n=== System Status Test ===")
        verify_system_status()
        
    finally:
        # Clean up
        print("\n=== Cleanup ===")
        cleanup_test_room(room_id)
    
    print("\nTests completed!")

if __name__ == "__main__":
    run_tests()
    
    # Clean up Firebase app
    firebase_admin.delete_app(firebase_app) 
import RPi.GPIO as GPIO
import time
import firebase_admin
from firebase_admin import credentials, db
import json
import os
import uuid
import math

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://smarthub-60812-default-rtdb.firebaseio.com'
})

# GPIO pin configuration for Left Motor (BTS7960)
L_RPWM = 17
L_LPWM = 27
L_R_EN = 22
L_L_EN = 23

# GPIO pin configuration for Right Motor (BTS7960)
R_RPWM = 5
R_LPWM = 6
R_R_EN = 13
R_L_EN = 19

# Setup GPIO mode
GPIO.setmode(GPIO.BCM)

# Setup motor driver pins
MOTOR_PINS = [L_RPWM, L_LPWM, L_R_EN, L_L_EN, R_RPWM, R_LPWM, R_R_EN, R_L_EN]
GPIO.setup(MOTOR_PINS, GPIO.OUT)

# Enable both motors
GPIO.output(L_R_EN, GPIO.HIGH)
GPIO.output(L_L_EN, GPIO.HIGH)
GPIO.output(R_R_EN, GPIO.HIGH)
GPIO.output(R_L_EN, GPIO.HIGH)

# PWM setup
pwm_L_R = GPIO.PWM(L_RPWM, 1000)  # Left Motor Forward
pwm_L_L = GPIO.PWM(L_LPWM, 1000)  # Left Motor Backward
pwm_R_R = GPIO.PWM(R_RPWM, 1000)  # Right Motor Forward
pwm_R_L = GPIO.PWM(R_LPWM, 1000)  # Right Motor Backward

# Start PWM with 0 speed
pwm_L_R.start(0)
pwm_L_L.start(0)
pwm_R_R.start(0)
pwm_R_L.start(0)

# Speed configuration
MIN_SPEED = 20
MAX_SPEED = 100
DEFAULT_SPEED = 50
current_speed = DEFAULT_SPEED  # Default to medium speed

# Chair configuration
CHAIR_CODE = None  # This will be set from Firebase
CHAIR_ID = None

def generate_chair_code():
    """Generate a unique chair code"""
    return str(uuid.uuid4())[:8].upper()

def register_chair():
    """Register the chair with Firebase"""
    global CHAIR_CODE, CHAIR_ID
    
    # Generate a new chair code
    CHAIR_CODE = generate_chair_code()
    
    # Create a new chair entry in Firebase
    chairs_ref = db.reference('chairs')
    new_chair_ref = chairs_ref.push()
    CHAIR_ID = new_chair_ref.key
    
    chair_data = {
        'code': CHAIR_CODE,
        'name': f'Chair {CHAIR_CODE}',
        'status': 'online',
        'created_at': {'.sv': 'timestamp'},
        'current_speed': DEFAULT_SPEED
    }
    
    new_chair_ref.set(chair_data)
    save_chair_info(CHAIR_CODE, CHAIR_ID)
    
    print(f"Chair registered successfully!")
    print(f"Chair Code: {CHAIR_CODE}")
    print(f"Chair ID: {CHAIR_ID}")
    print("Please use this code in the mobile app to connect to this chair.")

def load_chair_info():
    """Load the chair info from a local file"""
    try:
        with open('chair_info.json', 'r') as f:
            chair_info = json.load(f)
            return chair_info.get('code'), chair_info.get('id')
    except (FileNotFoundError, json.JSONDecodeError):
        return None, None

def save_chair_info(code, chair_id):
    """Save the chair info to a local file"""
    with open('chair_info.json', 'w') as f:
        json.dump({'code': code, 'id': chair_id}, f)

def stop():
    """Stop all motors"""
    pwm_L_R.ChangeDutyCycle(0)
    pwm_L_L.ChangeDutyCycle(0)
    pwm_R_R.ChangeDutyCycle(0)
    pwm_R_L.ChangeDutyCycle(0)
    print("Motors stopped.")
    
    # Update status in Firebase if chair ID is available
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('ready')

def set_speed(speed_value):
    """Set the motor speed level"""
    global current_speed
    
    try:
        # If it's a string command for backward compatibility
        if isinstance(speed_value, str):
            if speed_value == 'full_speed':
                speed = MAX_SPEED
            elif speed_value == 'low_speed':
                speed = MIN_SPEED
            else:
                print(f"Unknown speed command: {speed_value}")
                return
        else:
            # Ensure speed is within valid range
            speed = max(MIN_SPEED, min(int(speed_value), MAX_SPEED))
        
        current_speed = speed
        
        # Update speed in Firebase
        if CHAIR_ID:
            db.reference(f'chairs/{CHAIR_ID}/current_speed').set(current_speed)
            
        print(f"Speed set to {current_speed}%")
        
    except (ValueError, TypeError):
        print(f"Invalid speed value: {speed_value}")

def move_forward():
    """Move the chair forward"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(0)
    pwm_L_L.ChangeDutyCycle(current_speed)
    pwm_R_R.ChangeDutyCycle(current_speed)
    pwm_R_L.ChangeDutyCycle(0)
    print(f"Moving FORWARD at speed {current_speed}%")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')

def move_backward():
    """Move the chair backward"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(current_speed)
    pwm_L_L.ChangeDutyCycle(0)
    pwm_R_R.ChangeDutyCycle(0)
    pwm_R_L.ChangeDutyCycle(current_speed)
    print(f"Moving BACKWARD at speed {current_speed}%")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')

def turn_left():
    """Turn the chair left"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(0)
    pwm_L_L.ChangeDutyCycle(current_speed)
    pwm_R_R.ChangeDutyCycle(0)
    pwm_R_L.ChangeDutyCycle(current_speed)
    print(f"Turning LEFT at speed {current_speed}%")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')

def turn_right():
    """Turn the chair right"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(current_speed)
    pwm_L_L.ChangeDutyCycle(0)
    pwm_R_R.ChangeDutyCycle(current_speed)
    pwm_R_L.ChangeDutyCycle(0)
    print(f"Turning RIGHT at speed {current_speed}%")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')

def move_joystick(x, y):
    """
    Move the chair based on joystick coordinates.
    x: -100 to 100 (left to right)
    y: -100 to 100 (backward to forward)
    """
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    
    # Ensure values are within range
    x = max(-100, min(100, x))
    y = max(-100, min(100, y))
    
    # Swap x and y for correct direction mapping
    # This makes the joystick work correctly with our swapped motor controls
    temp_x = x
    x = y
    y = -temp_x  # Invert to maintain proper direction
    
    # Calculate motor speeds based on joystick position
    # Convert to radial coordinates for smoother control
    magnitude = min(100, math.sqrt(x*x + y*y))  # 0-100
    
    # Scale magnitude to speed range
    speed_factor = magnitude / 100.0
    motor_speed = current_speed * speed_factor
    
    if motor_speed < MIN_SPEED and magnitude > 0:
        motor_speed = MIN_SPEED  # Ensure we meet minimum speed if joystick is moved
    
    # Calculate left/right motor differential based on x position
    if magnitude == 0:
        # Joystick at center, stop motors
        stop()
        return
    
    # Calculate motor speeds
    left_speed = motor_speed
    right_speed = motor_speed
    
    # Apply differential turning based on x value
    if x != 0:
        # Calculate turning factor (-1 to 1)
        turn_factor = x / 100.0
        
        # Apply turning factor to reduce speed of one side
        if turn_factor > 0:  # Turning right
            left_speed = motor_speed
            right_speed = motor_speed * (1 - turn_factor)
        else:  # Turning left
            left_speed = motor_speed * (1 + turn_factor)
            right_speed = motor_speed
    
    # Set motor directions based on y value
    if y >= 0:  # Forward
        # Forward direction
        pwm_L_R.ChangeDutyCycle(left_speed)
        pwm_L_L.ChangeDutyCycle(0)
        pwm_R_R.ChangeDutyCycle(right_speed)
        pwm_R_L.ChangeDutyCycle(0)
    else:  # Backward
        # Backward direction
        pwm_L_R.ChangeDutyCycle(0)
        pwm_L_L.ChangeDutyCycle(left_speed)
        pwm_R_R.ChangeDutyCycle(0)
        pwm_R_L.ChangeDutyCycle(right_speed)
    
    print(f"Joystick: x={x}, y={y}, left_speed={left_speed:.1f}, right_speed={right_speed:.1f}")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')

def handle_command(command, value=None):
    """Handle incoming commands"""
    if command == 'forward':
        move_forward()
    elif command == 'backward':
        move_backward()
    elif command == 'left':
        turn_left()
    elif command == 'right':
        turn_right()
    elif command == 'joystick':
        if isinstance(value, dict) and 'x' in value and 'y' in value:
            move_joystick(value['x'], value['y'])
        else:
            print("Invalid joystick value format. Expected {x: value, y: value}")
    elif command == 'speed':
        if value is not None:
            set_speed(value)
    elif command == 'full_speed':  # For backward compatibility
        set_speed('full_speed')
    elif command == 'low_speed':   # For backward compatibility
        set_speed('low_speed')
    elif command == 'start':
        start()
    elif command == 'stop':
        stop()
    else:
        print(f"Unknown command: {command}")

def start():
    """Start the chair - initialize motors but don't move yet"""
    # Reset motors to ready state
    stop()
    print("Chair initialized and ready to move.")
    
    # Update status in Firebase if chair ID is available
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('ready')

def setup_chair():
    """Setup the chair with its code"""
    global CHAIR_CODE, CHAIR_ID
    
    # Try to load existing chair info
    CHAIR_CODE, CHAIR_ID = load_chair_info()
    
    if CHAIR_CODE is None or CHAIR_ID is None:
        # If no info exists, register a new chair
        register_chair()
    else:
        # Verify the chair exists in Firebase
        chair_ref = db.reference(f'chairs/{CHAIR_ID}')
        chair_data = chair_ref.get()
        if chair_data is None:
            print("Chair not found in database. Registering new chair...")
            register_chair()
        else:
            print(f"Chair initialized with code: {CHAIR_CODE}")
            print(f"Chair ID: {CHAIR_ID}")
            
            # Update the chair's status to online
            chair_ref.update({
                'status': 'online',
                'last_seen': {'.sv': 'timestamp'}
            })
            
            # Load saved speed if available
            if 'current_speed' in chair_data:
                set_speed(chair_data['current_speed'])
            
            # Initialize motors to stopped state
            stop()

def listen_for_commands():
    """Listen for commands from Firebase"""
    if CHAIR_ID is None:
        print("Chair not properly initialized!")
        return
        
    commands_ref = db.reference(f'chairs/{CHAIR_ID}/commands')
    
    # Set initial speed
    set_speed(DEFAULT_SPEED)
    
    def handle_command_update(event):
        """Handle updates to the chair's commands"""
        if event.path == '/' and event.data is None:
            return
            
        # If event.path is '/', we received the full commands object
        if event.path == '/':
            if not event.data:
                return
                
            # Find the latest command
            latest_command = None
            latest_timestamp = 0
            latest_value = None
            
            for cmd_id, cmd_data in event.data.items():
                if cmd_data.get('timestamp', 0) > latest_timestamp:
                    latest_timestamp = cmd_data.get('timestamp', 0)
                    latest_command = cmd_data.get('command')
                    latest_value = cmd_data.get('value')
            
            if latest_command:
                handle_command(latest_command, latest_value)
        else:
            # We received a specific command update
            command_path = event.path.split('/')
            if len(command_path) >= 2:  # Format: /command_id
                command_id = command_path[1]
                command_data = commands_ref.child(command_id).get()
                if command_data and 'command' in command_data:
                    handle_command(command_data['command'], command_data.get('value'))
    
    # Listen for changes to commands
    commands_ref.listen(handle_command_update)

def main():
    """Main function"""
    try:
        setup_chair()
        print("Starting chair control system...")
        print("Listening for commands...")
        listen_for_commands()
        
        # Keep the program running
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        stop()
        GPIO.cleanup()

if __name__ == "__main__":
    main()
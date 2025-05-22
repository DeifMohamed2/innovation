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

# Movement state tracking
current_movement_state = {
    'x': 0,
    'y': 0,
    'left_speed': 0,
    'right_speed': 0,
    'direction': 'stop',
    'angle': 0,
    'magnitude': 0,
    'last_update_time': 0
}

# Define threshold for significant movement change
MOVEMENT_THRESHOLD = 5  # Units in joystick coordinates (0-100)
ANGLE_THRESHOLD = 10    # Degrees
SPEED_THRESHOLD = 5     # Percentage points
# Reduced from earlier value to be more responsive
UPDATE_TIME_THRESHOLD = 0.05  # 50ms minimum between updates

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
    
    # Create basic chair data
    chair_data = {
        'code': CHAIR_CODE,
        'name': f'Chair {CHAIR_CODE}',
        'status': 'online',
        'created_at': {'.sv': 'timestamp'},
        'current_speed': DEFAULT_SPEED,
        'movement_state': {
            'direction': 'stop',
            'x': 0,             # X=0 (center)
            'y': 0,             # Y=0 (center)
            'magnitude': 0,     # No movement magnitude
            'left_speed': 0,    # Motors stopped
            'right_speed': 0,   # Motors stopped
            'angle': 0          # No direction angle
        }
    }
    
    # Set the data in Firebase
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
    
    # Update movement state
    global current_movement_state
    current_movement_state = {
        'x': 0,
        'y': 0,
        'left_speed': 0,
        'right_speed': 0,
        'direction': 'stop',
        'angle': 0,
        'magnitude': 0,
        'last_update_time': time.time()
    }
    
    # Update status in Firebase if chair ID is available
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('ready')
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': 'stop',
            'x': 0,
            'y': 0
        })

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
        
        # Only update if the speed change is significant
        if abs(current_speed - speed) >= SPEED_THRESHOLD:
            current_speed = speed
            
            # Update speed in Firebase
            if CHAIR_ID:
                db.reference(f'chairs/{CHAIR_ID}/current_speed').set(current_speed)
                
            print(f"Speed set to {current_speed}%")
            
            # If we're currently moving, apply the new speed
            if current_movement_state['direction'] != 'stop':
                # Re-apply the current movement with the new speed
                move_joystick(current_movement_state['x'], current_movement_state['y'])
        
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
    
    # Update movement state
    global current_movement_state
    current_movement_state = {
        'x': 0,
        'y': 100,  # 100 = full forward
        'left_speed': current_speed,
        'right_speed': current_speed,
        'direction': 'forward',
        'angle': 90,  # Degrees (90° = forward)
        'magnitude': 100,
        'last_update_time': time.time()
    }
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': 'forward',
            'x': 0,       # X=0 for straight forward
            'y': 100      # Y=100 for full forward
        })

def move_backward():
    """Move the chair backward"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(current_speed)
    pwm_L_L.ChangeDutyCycle(0)
    pwm_R_R.ChangeDutyCycle(0)
    pwm_R_L.ChangeDutyCycle(current_speed)
    print(f"Moving BACKWARD at speed {current_speed}%")
    
    # Update movement state
    global current_movement_state
    current_movement_state = {
        'x': 0,
        'y': -100,  # -100 = full backward
        'left_speed': current_speed,
        'right_speed': current_speed,
        'direction': 'backward',
        'angle': 270,  # Degrees (270° = backward)
        'magnitude': 100,
        'last_update_time': time.time()
    }
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': 'backward',
            'x': 0,        # X=0 for straight backward
            'y': -100      # Y=-100 for full backward
        })

def turn_left():
    """Turn the chair left"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(0)
    pwm_L_L.ChangeDutyCycle(current_speed)
    pwm_R_R.ChangeDutyCycle(0)
    pwm_R_L.ChangeDutyCycle(current_speed)
    print(f"Turning LEFT at speed {current_speed}%")
    
    # Update movement state
    global current_movement_state
    current_movement_state = {
        'x': -100,  # -100 = full left
        'y': 0,
        'left_speed': current_speed,
        'right_speed': current_speed,
        'direction': 'left',
        'angle': 180,  # Degrees (180° = left)
        'magnitude': 100,
        'last_update_time': time.time()
    }
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': 'left',
            'x': -100,     # X=-100 for full left
            'y': 0         # Y=0 for no forward/backward
        })

def turn_right():
    """Turn the chair right"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    pwm_L_R.ChangeDutyCycle(current_speed)
    pwm_L_L.ChangeDutyCycle(0)
    pwm_R_R.ChangeDutyCycle(current_speed)
    pwm_R_L.ChangeDutyCycle(0)
    print(f"Turning RIGHT at speed {current_speed}%")
    
    # Update movement state
    global current_movement_state
    current_movement_state = {
        'x': 100,  # 100 = full right
        'y': 0,
        'left_speed': current_speed,
        'right_speed': current_speed,
        'direction': 'right',
        'angle': 0,  # Degrees (0° = right)
        'magnitude': 100,
        'last_update_time': time.time()
    }
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': 'right',
            'x': 100,      # X=100 for full right
            'y': 0         # Y=0 for no forward/backward
        })

def move_joystick(x, y):
    """
    Move the chair based on joystick coordinates.
    x: -100 to 100 (left to right)
    y: -100 to 100 (backward to forward)
    """
    global current_movement_state
    current_time = time.time()
    
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    
    # Ensure values are within range
    x = max(-100, min(100, x))
    y = max(-100, min(100, y))
    
    # Store the original joystick values for Firebase updates
    original_x = x
    original_y = y
    
    # Check if movement is within the deadzone
    if abs(x) < 5 and abs(y) < 5:
        # If we're already stopped, don't do anything
        if current_movement_state['direction'] == 'stop':
            return
        stop()
        return
    
    # Calculate movement angle and magnitude
    angle = math.degrees(math.atan2(y, x))
    if angle < 0:
        angle += 360  # Convert to 0-360 range
    magnitude = min(100, math.sqrt(x*x + y*y))  # 0-100
    
    # Calculate time since last update
    time_since_last_update = current_time - current_movement_state['last_update_time']
    
    # Check if the change in movement is significant OR if we've exceeded the time threshold for an update
    angle_diff = abs((angle - current_movement_state['angle'] + 180) % 360 - 180)
    magnitude_diff = abs(magnitude - current_movement_state['magnitude'])
    
    if ((magnitude_diff < MOVEMENT_THRESHOLD and 
        angle_diff < ANGLE_THRESHOLD) and
        time_since_last_update < UPDATE_TIME_THRESHOLD and
        current_movement_state['direction'] != 'stop'):
        return
    
    # No longer swapping x and y - use directly for correct direction mapping
    # Previously:
    # temp_x = x
    # x = y
    # y = -temp_x
    
    # Update movement state with the actual joystick values
    current_movement_state['x'] = x
    current_movement_state['y'] = y
    current_movement_state['angle'] = angle
    current_movement_state['magnitude'] = magnitude
    current_movement_state['last_update_time'] = current_time
    
    # Scale magnitude to speed range
    speed_factor = magnitude / 100.0
    motor_speed = current_speed * speed_factor
    
    if motor_speed < MIN_SPEED and magnitude > 0:
        motor_speed = MIN_SPEED  # Ensure we meet minimum speed if joystick is moved
    
    # Calculate motor speeds
    left_speed = motor_speed
    right_speed = motor_speed
    
    # Determine direction and adjust motor speeds based on joystick position
    if x < 0:  # Left side of joystick (turn left)
        turn_factor = abs(x) / 100.0
        right_speed = motor_speed
        left_speed = motor_speed * (1 - turn_factor)
        
        if y > 0:  # Forward-left
            current_movement_state['direction'] = 'forward-left'
        elif y < 0:  # Backward-left
            current_movement_state['direction'] = 'backward-left'
        else:  # Pure left
            current_movement_state['direction'] = 'left'
            
    elif x > 0:  # Right side of joystick (turn right)
        turn_factor = x / 100.0
        left_speed = motor_speed
        right_speed = motor_speed * (1 - turn_factor)
        
        if y > 0:  # Forward-right
            current_movement_state['direction'] = 'forward-right'
        elif y < 0:  # Backward-right
            current_movement_state['direction'] = 'backward-right'
        else:  # Pure right
            current_movement_state['direction'] = 'right'
            
    else:  # Pure forward/backward
        if y > 0:
            current_movement_state['direction'] = 'forward'
        elif y < 0:
            current_movement_state['direction'] = 'backward'
    
    # Update the motor speeds in the state
    current_movement_state['left_speed'] = left_speed
    current_movement_state['right_speed'] = right_speed
    
    # Apply motor speeds based on direction
    if y >= 0:  # Forward or neutral with turning
        # Forward direction
        pwm_L_R.ChangeDutyCycle(0)
        pwm_L_L.ChangeDutyCycle(left_speed if y > 0 or x != 0 else 0)
        pwm_R_R.ChangeDutyCycle(right_speed if y > 0 or x != 0 else 0)
        pwm_R_L.ChangeDutyCycle(0)
    else:  # Backward
        # Backward direction
        pwm_L_R.ChangeDutyCycle(left_speed)
        pwm_L_L.ChangeDutyCycle(0)
        pwm_R_R.ChangeDutyCycle(0)
        pwm_R_L.ChangeDutyCycle(right_speed)
    
    print(f"Joystick: x={x}, y={y}, direction={current_movement_state['direction']}, left_speed={left_speed:.1f}, right_speed={right_speed:.1f}")
    
    # Update status in Firebase
    if CHAIR_ID:
        db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
        
        # Important: Use the original joystick values for the movement_state
        # to ensure consistent values between the app and the chair
        db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
            'direction': current_movement_state['direction'],
            'x': original_x,  # Use original X value received from joystick
            'y': original_y   # Use original Y value received from joystick
        })

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
    elif command == 'direction':
        # Handle directional commands for diagonal movements
        if isinstance(value, str):
            handle_direction(value)
        else:
            print("Invalid direction format. Expected string value.")
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

def handle_direction(direction):
    """Handle directional commands including diagonals"""
    if current_speed == 0:
        set_speed(DEFAULT_SPEED)  # Default to medium speed if none set
    
    print(f"Handling direction: {direction}")
    
    # Coordinates for each direction (x, y values in range -100 to 100)
    direction_coords = {
        'forward': (0, 100),
        'backward': (0, -100),
        'left': (-100, 0),
        'right': (100, 0),
        'forward-left': (-70, 70),     # Diagonal forward-left
        'forward-right': (70, 70),     # Diagonal forward-right
        'backward-left': (-70, -70),   # Diagonal backward-left
        'backward-right': (70, -70),   # Diagonal backward-right
        'stop': (0, 0)
    }
    
    # Get the coordinates for the requested direction
    if direction in direction_coords:
        x, y = direction_coords[direction]
        
        # Update movement state
        global current_movement_state
        current_time = time.time()
        
        current_movement_state['x'] = x
        current_movement_state['y'] = y
        current_movement_state['direction'] = direction
        current_movement_state['last_update_time'] = current_time
        
        # Calculate motor speeds based on direction
        if direction == 'forward':
            # Full forward
            pwm_L_R.ChangeDutyCycle(0)
            pwm_L_L.ChangeDutyCycle(current_speed)
            pwm_R_R.ChangeDutyCycle(current_speed)
            pwm_R_L.ChangeDutyCycle(0)
            current_movement_state['left_speed'] = current_speed
            current_movement_state['right_speed'] = current_speed
            
        elif direction == 'backward':
            # Full backward
            pwm_L_R.ChangeDutyCycle(current_speed)
            pwm_L_L.ChangeDutyCycle(0)
            pwm_R_R.ChangeDutyCycle(0)
            pwm_R_L.ChangeDutyCycle(current_speed)
            current_movement_state['left_speed'] = current_speed
            current_movement_state['right_speed'] = current_speed
            
        elif direction == 'right':
            # FIXED: This is turning RIGHT, swap the speeds
            pwm_L_R.ChangeDutyCycle(0)
            pwm_L_L.ChangeDutyCycle(current_speed * 0.5)  # Left motor slower
            pwm_R_R.ChangeDutyCycle(current_speed)        # Right motor faster
            pwm_R_L.ChangeDutyCycle(0)
            current_movement_state['left_speed'] = current_speed * 0.5
            current_movement_state['right_speed'] = current_speed
            
        elif direction == 'left':
            # FIXED: This is turning LEFT, swap the speeds
            pwm_L_R.ChangeDutyCycle(0)
            pwm_L_L.ChangeDutyCycle(current_speed)        # Left motor faster
            pwm_R_R.ChangeDutyCycle(current_speed * 0.5)  # Right motor slower
            pwm_R_L.ChangeDutyCycle(0)
            current_movement_state['left_speed'] = current_speed
            current_movement_state['right_speed'] = current_speed * 0.5
            
        elif direction == 'forward-right':
            # FIXED: Forward-RIGHT diagonal, swapped motor speeds
            left_speed = current_speed * 0.3  # Left motor slower
            right_speed = current_speed       # Right motor faster
            pwm_L_R.ChangeDutyCycle(0)
            pwm_L_L.ChangeDutyCycle(left_speed)
            pwm_R_R.ChangeDutyCycle(right_speed)
            pwm_R_L.ChangeDutyCycle(0)
            current_movement_state['left_speed'] = left_speed
            current_movement_state['right_speed'] = right_speed
            
        elif direction == 'forward-left':
            # FIXED: Forward-LEFT diagonal, swapped motor speeds
            left_speed = current_speed       # Left motor faster
            right_speed = current_speed * 0.3  # Right motor slower
            pwm_L_R.ChangeDutyCycle(0)
            pwm_L_L.ChangeDutyCycle(left_speed)
            pwm_R_R.ChangeDutyCycle(right_speed)
            pwm_R_L.ChangeDutyCycle(0)
            current_movement_state['left_speed'] = left_speed
            current_movement_state['right_speed'] = right_speed
            
        elif direction == 'backward-right':
            # FIXED: Backward-RIGHT diagonal, swapped motor speeds
            left_speed = current_speed * 0.3  # Left motor slower
            right_speed = current_speed       # Right motor faster
            pwm_L_R.ChangeDutyCycle(left_speed)
            pwm_L_L.ChangeDutyCycle(0)
            pwm_R_R.ChangeDutyCycle(0)
            pwm_R_L.ChangeDutyCycle(right_speed)
            current_movement_state['left_speed'] = left_speed
            current_movement_state['right_speed'] = right_speed
            
        elif direction == 'backward-left':
            # FIXED: Backward-LEFT diagonal, swapped motor speeds
            left_speed = current_speed       # Left motor faster
            right_speed = current_speed * 0.3  # Right motor slower
            pwm_L_R.ChangeDutyCycle(left_speed)
            pwm_L_L.ChangeDutyCycle(0)
            pwm_R_R.ChangeDutyCycle(0)
            pwm_R_L.ChangeDutyCycle(right_speed)
            current_movement_state['left_speed'] = left_speed
            current_movement_state['right_speed'] = right_speed
            
        elif direction == 'stop':
            # Stop all motors
            stop()
            return
        
        # Calculate magnitude and angle from x, y coordinates
        magnitude = min(100, math.sqrt(x*x + y*y))
        angle = math.degrees(math.atan2(y, x))
        if angle < 0:
            angle += 360
        
        current_movement_state['magnitude'] = magnitude
        current_movement_state['angle'] = angle
        
        # Update status in Firebase
        if CHAIR_ID:
            db.reference(f'chairs/{CHAIR_ID}/status').set('moving')
            db.reference(f'chairs/{CHAIR_ID}/movement_state').update({
                'direction': direction,
                'x': x,
                'y': y,
                'left_speed': current_movement_state['left_speed'],
                'right_speed': current_movement_state['right_speed'],
                'magnitude': magnitude,
                'angle': angle
            })
        
        print(f"Moving {direction} at speed L:{current_movement_state['left_speed']:.1f}, R:{current_movement_state['right_speed']:.1f}")
    else:
        print(f"Unknown direction: {direction}")
        stop()

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
            
            # Update the chair's status to online and reset movement state
            chair_ref.update({
                'status': 'online',
                'last_seen': {'.sv': 'timestamp'},
                'movement_state': {
                    'direction': 'stop',
                    'x': 0,     # X=0 (center)
                    'y': 0      # Y=0 (center)
                }
            })
            
            # Create detailed movement state reference for efficient updates
            movement_ref = db.reference(f'chairs/{CHAIR_ID}/movement_state')
            movement_ref.update({
                'direction': 'stop',
                'x': 0,
                'y': 0,
                'magnitude': 0,
                'left_speed': 0,
                'right_speed': 0
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
    
    # Create a state reference node for efficient state updates
    state_ref = db.reference(f'chairs/{CHAIR_ID}/movement_state')
    state_ref.set({
        'direction': 'stop',
        'x': 0,             # X=0 (center)
        'y': 0,             # Y=0 (center)
        'magnitude': 0,     # No movement
        'left_speed': 0,    # Motors stopped 
        'right_speed': 0,   # Motors stopped
        'angle': 0          # No direction angle
    })
    
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
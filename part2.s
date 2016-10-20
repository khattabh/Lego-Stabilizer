.equ LEGO, 0xFF200060  # JP1 memory address
.equ TIMER, 0xFF202000  # Timer1 memory address

.text

.global _start
_start:
  # Initialize lego controller with default values
  movia r2, LEGO
  movia r3, 0X07F557FF
  stwio r3, 4(r2)  # Direction register

# Start the balancing loop
LOOP:

  ldwio r8, 0(r2)
  andi  r8, r8, 3
SENSORONE:

  # Remember previous motor state and direction (mask it)
  # "C" since we want to OR it with previous state and 00
  movia r4, 0xFFFFFBFC
  or   r4, r4, r8
  
  stwio r4, 0(r2)  # Activate sensor 0
  ldwio r7, 0(r2)  # Read controller
  srli  r7, r7, 11 # Shift 11 bits to get the ready value
  andi  r7, r7, 1
  bne   r7, r0, SENSORONE  # If not ready, try again
  ldwio r5, 0(r2)
  srli  r5, r5, 27 # Shift 27 bits to get to the sensor value
  andi  r5, r5, 0xF # Get the next 4 bits
SENSORTWO:

  # Remember previous motor state and direction (mask it)
  # "C" since we want to OR it with previous state and 00
  movia r4, 0xFFFFEFFC
  or   r4, r4, r8
  
  stwio r4, 0(r2)  # Activate sensor 1
  ldwio r7, 0(r2)  # Read controller
  srli  r7, r7, 13 # Shift 11 bits to get the ready value
  andi  r7, r7, 1
  bne   r7, r0, SENSORTWO  # If not ready, try again
  ldwio r6, 0(r2)
  srli  r6, r6, 27 # Shift 27 bits to get to the sensor value
  andi  r6, r6, 0xF # Get the next 4 bits

# Determine the way to balance after reading sensors
CONTROL:
  # Determine which way to rotate to balance
  # r5 contains Sensor 0's reading
  # r6 contains Sensor 1's reading
  beq r5, r6, BALANCE
  bgt r5, r6, CLOCKWISE
COUNTERCLOCKWISE:
  # Rotate motor counter clockerwise
  movia r4, 0xFFFFFFFC
  stwio r4, 0(r2)
  
  movi r8, %lo(196666)
  movi r9, %hi(196666)
  call DELAY
  # turn off the motor
  movia r4, 0xFFFFFFFE
  stwio r4, 0(r2)
  
  movi r8, %lo(35000)
  movi r9, %hi(35000)
  call DELAY
  
  movia r4, 0xFFFFFFFC
  stwio r4, 0(r2)
  
  br LOOP
BALANCE:
  # Turn motor off
  movia r4, 0xFFFFFFFF
  stwio r4, 0(r2)
    movi r8, %lo(196666)
  movi r9, %hi(196666)
  call DELAY
  br LOOP
CLOCKWISE:
  # Rotate motor clockwise
  movia r4, 0xFFFFFFFE
  stwio r4, 0(r2)
  
  movi r8, %lo(196666)
  movi r9, %hi(196666)
  call DELAY
  # turn off the motor
  movia r4, 0xFFFFFFFC
  stwio r4, 0(r2)
  
  movi r8, %lo(35000)
  movi r9, %hi(35000)
  call DELAY
  
  movia r4, 0xFFFFFFFE
  stwio r4, 0(r2)
  
  br LOOP

DELAY:
  # We will delay the motor with the timer
  movia r7, TIMER
  
  stwio   r8, 8(r7)
  stwio   r9, 12(r7)
  # Start timer
  movui r4, 4
  stw   r4, 4(r7)
WAIT:
  ldw   r4, 0(r7)
  andi  r4, r4, 1
  beq   r4, r0, WAIT
  ret
  
  
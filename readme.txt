ENSE 352-001 Term Project, “Read Me” file for Documentation  12/06/2018


WHAT IS "WHACK-A-MOLE" (WHAC-A-MOLE)
------------------------------------
***! Please note that material regarding the Whac-A-Mole arcade game is referenced from the Wikipedia article -> https://en.wikipedia.org/wiki/Whac-A-Mole <- !***

"Whac-A-Mole is a popular arcade redemption game invented in 1976 by Aaron Fechter of Creative Engineering, Inc." (Wikipedia, November 4, 2018) Traditionally, the arcade game is played on a machine which raises "moles" from its flat surface which can be "whacked" by the player using a soft mallet. The more moles the player successfully whacks, the higher their score. Each timed round of raising moles becomes progressively shorter until the player is forced to complete the game and miss the next mole. Some renditions of the game have a maximum number of rounds - the player receives a score based on how fast they whacked all the moles in every round as well as the number of rounds they lasted.

This particular project implements a Whac-A-Mole game of the latter variety.


HOW TO PLAY
-----------
For this particular implementation of Whac-A-Mole, the user must rely on the LED signals to determine what state the game is in. Several use cases are also described below for a more thorough documentation on how to play (includes extended features).

1. Plug in the ENEL 384 Board and press the black reset button on the VLdiscovery Cortex-M3 Board. 
2. Wait for the cycling back-and-forth LED pattern on the board to appear. Press any button on the ENEL 384 Board
3. Wait for an LED to light up. This is the mole, press the aligned button-to-LED on the ENEL 384 Board to "whack" the mole. Each mole is up for a limited time.
4. Repeat step 3. until some flashing LED pattern appears (or no LEDs light up) then continue to step 5. depending on the pattern seen.

(LED Pattern - Cycling LED flashing of all 4 LEDs)
5. The user has won the game by whacking all the moles on all the rounds. The game will then display the number of rounds played in binary pattern on the LEDs.
6. Either wait for the round pattern to pass (1 min.), upon which the game returns to step 2. - or press any button on the board, starting again from step 2.

(LED Pattern - Non-cycling LED flashing of 0 or all 4 LEDs)
5. The user has lost the game, either by pressing the wrong button or timing out a mole. The LED signal displays the binary pattern of the rounds you lasted (If you didn't last at least 1 round, no LEDs will flash). The game will then display the total number of rounds for that game in binary pattern on the LEDs.
6. Either wait for the round pattern to pass (1 min.), upon which the game returns to step 2. - or press any button on the board, starting again from step 2.


USE CASES (INCLUDES EXTENDED FEATURES)
--------------------------------------
These use cases attempt to capture the system requirements from a user’s perspective. These are extended from the Term Project Handout Revision 2: 2018-11-22 15:48:25 -0600 (1a50b2e).

UC1 Turning on the system
1. The user performs a system boot by pressing the reset button.
2. The system enters Use Case 2 (UC2): Waiting for Player.

UC2 Waiting for Player
1. The system goes into the startup routine. This is an LED pattern indicating that no game is in progress and the system is waiting for a player to start. The four LEDs will be cycling back and forth at approx. 1 Hz This continues without stopping until:
2. The user presses any of the four buttons. The system enters Normal Game Play (UC3).

UC3 Normal Game Play
1. A fixed wait time elapses: PRELIM_WAIT. PRELIM_WAIT is approximately a few tenths of a second.
2. The game turns on a randomly selected LED. The game starts the REACT_TIME timer. REACT_TIME is approx. 4 seconds to begin with.
3. The user presses the corresponding button before REACT_TIME expires.
4. The REACT_TIME value is reduced by a few tenths of a second to prepare for the next cycle.
5. The system goes back to step 1. After a (random [1-15] or predetermined) NUM_CYCLES of these successful loops complete, the game enters End Success (UC4).

UC3 Alternate Path: REACT_TIME expires.
1. During UC3 step 2 the user fails to press the correct button before REACT_TIME expires, or the user presses an incorrect button.
2. The game enters End Failure (UC5).

UC4 End Success. The user has won the game.
1. The game displays the “winning” signal, which is a cycling, flashing LED pattern indicating the person won. This signal is displayed for time WINNING_SIGNAL_TIME.
2. After displaying this signal, the game displays the total rounds of the game (the user's proficiency level). This display remains visible for approx. 1 minute, after which the game returns to UC2.

UC5 End Failure. The user has lost the game.
1. The system displays the “losing” signal, which is a flashing display, in binary, of the number of successful cycles completed. This flashing signal is displayed for time LOSING_SIGNAL_TIME. 
2. After displaying this signal, the game returns to UC2, Waiting for Player.


PROBLEMS ENCOUNTERED
--------------------
1. Shifting bits of the GPIOA_ODR Register during the startup routine

There is a possible issue with this project during the startup routine. The cycling pattern is achieved by shifting the bits of the GPIOA_ODR register (which contains the ENEL 384 Board LEDs) left or right, depending on the current LED cycle. I encountered a problem where isolating and shifting the bits of the register specific to the LEDs resulted in more than one LED being turned on at a time (the cycling pattern requires only one LED on at a time). Since the LEDs are active-LOW, shifting the entire bit pattern of the GPIOA_ODR register cycles the 0 bit to turn on the LEDs. However, logical shifting of bits out of the register results in lost bits being replaced by 0s; this could turn on/off any other peripherals on the ENEL 384 Board on the GPIOA_ODR register. 

The LEDs are the only output peripherals on the GPIOA_ODR register that are visually affected by the bit pattern cycling, so I have elected to keep shifting the entire register even though it possibly affects other peripherals. 

This issue is not seen elsewhere as proper isolation and replacement of required bits is done.


FAILED IMPLEMENTED FEATURES
---------------------------
All system requirements as outlined in the Term Project Handout Revision 2: 2018-11-22 15:48:25 -0600 (1a50b2e) are met in this project. 


FEATURE INTERPRETATION
----------------------
1. Proficiency signal

In UC4 (and UC5 for this project), the "proficiency" signal was left open for students to interpret - further to the Whac-A-Mole implementation in the WHAT IS WHAC-A-MOLE section, the proficiency signal is interpreted as the number of rounds the player lasted (displayed in binary pattern on the LEDs at the end of the game).

2. Binary pattern visible on LEDs

The binary patterns on the four LEDs are limited to displaying 0-15. This limitation affects both the losing signal in UC5 and the rounds displayed at the end of the game. I have chosen to interpret any score greater than or equal to 15 as the bit pattern of 15 on the LEDs. If the user ends the game with a score of 0, no LEDs light up, representing the bit pattern for 0.


EXTRA FEATURES IMPLEMENTED
--------------------------
1. Randomized NUM_CYCLES

In the submitted proj.s assembly file, there is the choice between non-randomized NUM_CYCLEs and randomized NUM_CYCLEs. The user is able to switch between these in the HOW TO ADJUST GAME PARAMETERS section below.

Randomized NUM_CYCLES are achieved by selecting the lowest 4 bits from a pseudo-randomized number. Four bits of the randomized number are chosen to set NUM_CYCLES to a number between 0-15 (15 being the maximum number in binary that can be represented on 4 LEDs). For proper gameplay, if the selected bits result in NUM_CYCLES = 0, NUM_CYCLES is set to at least 1. A game with 0 rounds is not a game at all. 

The NUM_CYCLES are generated from the same seed as the randomized LEDs. In order to separate the first LED choice of the game from the number of rounds, I elected to choose bits from opposite ends of the expected 32-bit random number. Due to the randomization function (detailed in the proj.s file), the lower bits of the random number are decidedly less random than the upper bits of the number. However, since NUM_CYCLES is randomized once per game we do not need to worry about subsequent random numbers. The first random number is random enough for its purpose in NUM_CYCLES generation.


POSSIBLE FUTURE EXPANSION
-------------------------
1. The addition of more than one mole appearing at a time

The current method for mole selection is controlled by an assembly branch table (equivalent to the switch case in C). In order to expand this to selecting more than one mole at a time, the table would have to be expanded to set the LED and button patterns for every possible combination of 4 LEDs. This could be quite lengthy, as the cases are aligned by 4 bytes each. In such a case, the compiler would most like generate ITE instructions for each branch. 

There is also the issue of recognizing the button presses for moles. The current method for confirming that the button pressed matches the lit LED would mean the user would have to press up to 4 buttons at a time to whack all the moles. To replace this method, extra steps would need to be added: one step to check if a button press matches at least one of the lit LEDs, another step to turn off that LED and remove that button's pattern, another step to set the new LED and button patterns if there are still moles left, etc. 

To implement the addition of more than one mole appearing at a time, the current methods of LED and button selection would need to be overhauled almost completely. 


HOW TO ADJUST GAME PARAMETERS
-----------------------------
All game parameters (except NUM_CYCLES) can be readily adjusted at the top of the proj.s file, under EQUATES in the "Other Times (Modifiable)" heading.

1. PRELIM_WAIT (at the beginning of a cycle, the time to wait before lighting a LED)
   PRELIM_WAIT works best if it is long enough for the user to let go of a button. The current value is set to 0x186A00 (24*0xFF00, or approx. 24 ms). This time is specific to a single, dedicated count loop.

2. REACT_TIME (the time allowed for the user to press the correct button to avoid terminating the game)
   REACT_TIME works best if it is long enough to not encourage the user to smash the buttons or damage the ENEL 384 Board. The current beginning value is set to 0x3FC00 (4*0xFFOO, or approx. 4s). This value is specific to the Normal_Gameplay loop. There is an offset to the amount of time that is reduced each round. At minimum, the rounds last at least 1s. The beginning time can be adjusted for longer.

3. WINNING_SIGNAL_TIME and LOSING_SIGNAL_TIME
   Both "times" of these signals are actually the number of times the LEDs flash, as the time which the LED pattern is displayed is controlled by the beginning REACT_TIME set for the game.
   The current signals are set to flash 0x20 (or 32) times. It is recommended that the signals flash long enough that the user is able to both see and read what is being displayed.

4. NUM_CYCLES (Randomized)
   The game is currently set up to randomize the number of rounds. In order to change the game to randomized NUM_CYCLES, the following lines must be uncommented:
	Line 52: The EQUATE for the randomized NUM_CYCLES. This is the RAM address that the number is stored at. Recommended to not be within stack space, which starts at 0x20001000.
	Line 247: Calls the RNG_Rounds function which randomizes the NUM_CYCLES.
	Line 615: Loads the randomized NUM_CYCLES into a register for use.

   The following lines must then be commented out:
	Line 51: The EQUATE for the set NUM_CYCLES.
	Line 246: Loads the non-randomized NUM_CYCLES into a register for use.
	Line 614: Loads the non-randomized NUM_CYCLES into a register for use.

5. NUM_CYCLES (Non-randomized)
   In order to change the game to non-randomized NUM_CYCLES, the following lines must be uncommented:
	Line 51: The EQUATE for the set NUM_CYCLES. Recommended to be at least 1.
	Line 246: Loads the non-randomized NUM_CYCLES into a register for use.
	Line 614: Loads the non-randomized NUM_CYCLES into a register for use.

   The following lines must then be commented out:
	Line 52: The EQUATE for the randomized NUM_CYCLES.
	Line 247: Calls the RNG_Rounds function which randomizes the NUM_CYCLES. There is no need to comment out the RNG_Rounds function as it goes unused otherwise.
	Line 615: Loads the randomized NUM_CYCLES into a register for use.

LICENSE
-----------------------------
This project is presented for academic purposes.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>

-----------------------------
-----------------------------

AUTHOR
------

Kelly Holtzman
University of Regina
I.D.: 200366225
E-mail: holtzmak@uregina.ca
-----------------------------
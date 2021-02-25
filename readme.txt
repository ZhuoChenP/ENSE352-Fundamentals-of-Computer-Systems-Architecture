1. What the game is?
This is a "Whack-a-mole" game, by using buttons to plays, and LEDs as indicators
2.How to plays
There are four buttons(black, red, green, blue) in order from left to right placed on the breadboard. Each button has a corresponding LED, also aligned from left to right. Firstly, the game is in the waiting_play model, aligned LEDs will turn on (cycling from left to right at 1HZ). The player needs to press any one of four buttons to start the game. 
After the player presses, a button, one of the four LEDs will turn on randomly, and it will turn off in a certain period.
The player needs to press the corresponding button to turn off the LED, and the game will go into the next cycle and turn on the LED randomly again. For each, the reacting time(during of LED lighted up)
is reducing by a certain degree, to make it more challenging.
But if the player presses the wrong button or not presses the correct button within a certain period (during the LED lighting time), then the game is over, and LEDs will show how many
cycles the player have been completed correctly, the number is binary form, starting from the right(LSB) and the corresponding LED/LEDs will turn on and flashing for LosingSignalTime times.
If the game enter the failer section by some accidents, which means 
the cycles completed are greater than 15 or less than 1, the LEDs set on the most right and left(MSB and LSB) will turn on and then toggling and flashing for LosingSignalTime times. 
After LosingSignalTime times flashing to show the cycles completed, it will go back to the waiting_play model.
To succeed in the game, players need to complete 16 cycles in total, by pressing the correct buttons on time. After success, LEDs will flash left side two LEDs and right side two LEDs, and toggle back and forth. After WinningSignalTime times flashing. The game will show the user's proficiency level.
In this design, there are two levels in total, if the player just uses half of the total time to complete the game, the right two LEDs will turn on, which implies two stars
if the player uses more than half of the total time, then only most rights LED will turn on, which means one star. And after one minute it will go back to the waiting_player model.
3.Any information about problems encountered, features you failed to implement, extra features you implemented 
beyond the basic requirements, possible future expansion, etc.
I completed the program with meeting all requirements. Nothing is extra features and features failed to implement. But for problems I met,
I was having some troubles with UC3. Because I used functions and the program is just too long, the software gave me some error, but after swapping the position of 
UC3, the error is gone.
4. How the user can adjust the game parameters, including:
(a) PrelimWait: The user can set any value for this argument, but maybe not too long, or large, and greater than 10000.
(b) ReactTime: The time for each reduction is 0x8000, so the minimal value for react time is 0x8000*16 which is 0xB0000
(c) NumCycles:  it must be greater than 0.
(d) values of WinningSignalTime and LosingSignalTime:  They must be greater than 0.
(e) DELAYONEHZ: must be greater than 5000, the player must observe the LEDs is flashing, if it is too small, the flashing cannot be observed.
(f) Random: user can change any hex number, but cannot be zero and the MSB position number must be greater than NumCycles.

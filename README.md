This is the ReadMe for my game SlimeFall. before we get into how everything works and what is in the game i would like to tell you:
this game was planned over 5 hours and then made for another 9-10 hours. This game is not the first game of the same idea, my first game lava slime was way toambitious so I decided to scrap it.
This game has a selection from 4 AIs (easy, medium, hard and impossible), unfourtunately I was not able to make the impossible actually impossible :(.

what does Sllme Fall have:
  1. A FULLY fuctoining shop with colors and over 15 cosmetics!
  2. 3 types of platforms! maybe if you"re good enough you will find out what they are :)
  3. 2 EXTRA obstacles and 1 Power-Up of sorts called the "Spring"

you might wonder what the SlimeAI is:
  1. an AI capable of playing the game perfectly (almost)
  2. this AI consists of has 26 neurons (3 + PLATFORMS * 6 + 1 + 3 + 1)
  4. it has a neural.json that helps it store values of stuff
  5. it has a random number then multiplied by a number called the bias (RAND * bias) and that corresponds to the movement, after the generation is finished it checks for the best 10% keeps their numbers and the other 90%       it "mutates" and it creates a simmilar but a different AI, if better the numbers get saved to neural.json!
  6. neural_view or "the lines showing" uses a _draw() func to draw everything and a _node_pos() to put the rectangle in the bottom right corner
  7. the network is initiated on all 4 bots at once
  8. the training process: 1. the impossible slime tries 3 attemps on its own. 2. 500 slimes try to geet as high as possible. 3. repeat until finished
  9. the AI is as perfect as it could be, except with the hold_jump variable, you see jumps are smaller if a small tap and big if a hold! unfourtunately i only realised this typing this Readme.md (xd)

Thank you for reading the ReadMe,
 Enjoy SlimeFall,

 restt88

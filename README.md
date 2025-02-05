# Bordle

## Description

`Bash + Wordle == Bordle`

A Wordle Terminal User Interface (TUI) written entirely in Bash.

## Preview
![Img](https://github.com/sean-gall-41/Bordle/blob/master/images/game_preview.png?raw=true)

## Installation

Installation is as simple as wget'ing the `bordle.sh` file. You can of course `git clone` the project as well.
It's your choice.

## Usage

Make sure to change permissions on the `bordle.sh` file so that it is executable (`chmod +x` or `chmod 755`
for linux users). If you are on Windows, ensure you have a Bash binary installed (in an environment like cygwin
or git-bash). If you haven't added the binary to your environment you should do that. From there, run:

`bash bordle.sh` 

or

`sh bordle.sh`

and you'll be impressing your friends with your (b)ordle skills in no time!

## Future Plans

- Create an exit statistics screen akin to the original
- Create a command line option to bring up the statistics screen without playing the game
- Create a command line option that allows user to ignore 1 day limit
- Create a command line option that allows user to specify a difficulty 
- Use a 5-letter dictionary of common words (as it stands, it is too difficult at the moment)
- Allow for multiple users to play, have their data saved into respective files

## Bugs 

- If screen is smaller than 189 x 49, tput throws an `invalid option -- 3` error.
- If screen is smaller than 210 x 57, keyboard at the bottom of the screen gets clipped

## License
 MIT License

    Copyright (c) [2022] [Sean Gallogly]
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE. 

## Badges
  ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
## License Link
  [Click Me](https://opensource.org/licenses/MIT) 

# Usakotter
Commind line Twitter client - a fork of tw written by shokai

# Features
```
Usakotter allows you to:
- post a tweet.
- display timelines: Home, Mention, User, List, Retweets-of-me, Favorites (Likes), Search.
- show a specified user's information.
- show the Lists which a specified user own.
- show the Lists which a specified user belongs to.
- show the member users in a specified List.
- add a specified user to a specified List which you created.
- show the users which a specified user follow.
- show the users which a specified user is followed by.
- show the users which you mute.
- show the users which you block.
- show the current rate of Twitter APIs.
- output each data in both a human readable text format and JSON.
```

# Usage
## Examples
Using B-shell and compatibles are assumed in the following examples.

### Post a Tweet

__Format__:

    $ us <text>

__Simple example__

    $ us 'This is the house that Jack built.'
    $ us "This is the house that Jack built."

Tweet:

    This is the house that Jack built.

__Exclamation mark:__

    $ us 'Good morning!'
    $ us "Good morning\!"

Tweet:

    Good moring!

__Double quotation:__

    $ us 'Emily said to Sam, "What were you doing today?"'
    $ us "Emily said to Sam, \"Wyhat were you doing today?\""

Tweet:

    Emily said to Sam, "What were you doing today?"

__Single quotation:__

    $ us 'You'"'"'re joking, right?'
    $ us "You're joking, right?"

Tweet:

    You're joking, right?

__New line:__

    $ us 'I have a pen\nI have an apple\nUgh, apple pen'
    $ us "I have a pen\nI have an apple\nUgh, apple pen"

Tweet:

    I have a pen
    I have an apple
    Ugh, apple pen

'\\\\n' expresses the string '\n':

    $ us 'To send a new line, use a '"'"'\\n'"'"'.'
    $ us "To send a new line, use a '\\\n'."

_Note: '\\\\' between double quotations is interpreted as '\n' by the shell._

Tweet:

    To send a new line, use a '\n'.

__Tweet a message from the standard input__

    $ cat message.txt | us --pipe
    $ echo "Hello, world" | us --pipe

__Tweet without the confirmation prompt__

In each of the following examples, __us__ tweets the message immediately.

    $ us "Hello, world" -y
    $ cat message.txt | us --pipe -y


# Author
Shimaden (@SHIMADEN, 94380019, on Twitter, https://github.com/shimaden )

## Original author
shokai (Sho Hashimoto, https://github.com/shokai )

# Thanks to
shokai (Sho Hashimoto, https://github.com/shokai )

# License
MIT License

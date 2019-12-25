# Usakotter
Commind line Twitter client - a fork of tw written by shokai

# Features
```
Usakotter allows you to:
- post a tweet.
- post a tweet with up to four image files.
- post a tweet with a video file.
- display timelines: Home, Mention, User, List, Retweets-of-me, Favorites (Likes), Search.
- show a specified user's information.
- show the Lists which a specified user own.
- show the Lists which a specified user belongs to.
- show the member users in a specified List.
- add a specified user to a specified List which you created.
- show the users who a specified user follow.
- show the users who a specified user is followed by.
- show the users who you mute.
- show the users who you block.
- show the current rate of Twitter APIs.
- output each data in both a human readable text format and JSON.
```

# Usage
## Examples
Using B-shell and compatibles are assumed in the following examples.

### Post a Tweet

__us__ TEXT

__Simple example__

    $ us 'This is the house that Jack built.'
    $ us "This is the house that Jack built."

Tweet:

    This is the house that Jack built.

__Post a tweet with image files__

__Usakotter__ can post a tweet with up to four image files. JPEG and PNG formats are supported.

__--media1__ FILE1

__--media2__ FILE2

__--media3__ FILE3

__--media4__ FILE4

__us__ TEXT __--media1__ FILE1 [__--media2__ FILE2 [__--media3__ FILE3 [__--media4__ FILE4]]]

Attach an image file to the tweet:

    $ us "I'm on Mt. Fuji now." --media1 mt-fuji.jpg

Attach two or more image files to the tweet:

    $ us "I'm on Mt. Fuji now." --media1 fuji-1.jpg --media2 fuji-2.jpg
    $ us "I'm on Mt. Fuji now." --media1 fuji-1.jpg --media2 fuji-2.jpg --media3 selfie.png --media4 friend.png

__Post a tweet with a video file__

__--video__ FILE

__Usakotter__ can post a tweet with up to one video file.

    $ us "My puppy." --video puppy.mp4

__Post a tweet with a quoted tweet__

__--quote-tweet__ TWEET-URL

Post a tweet which quotes the tweet whose URL is TWEET-URL.

    $ us "Awsome piano performance\!" -q https://twitter.com/USAFBandPacific/status/1188709081197895680

__Tweet a message starting with a '-'__

__-t__

    $ us -t '-3 + 2 = -1'

Tweet:

    -3 + 2 = -1

__Reply__

__New style reply__

__--in-reply-to-new__, __-r__ STATUS-ID

With this option, Usakotter posts a reply to the tweet specified by STATUS-ID.

Status ID is a unique number to identify a tweet. There are no tweets which have the same Status ID.
Status ID is found at the tail part of the URL of each tweet.

    https://twitter.com/<SCREEN-NAME>/status/<STATUS-ID>

For example, to reply to the tweet whose URL is as follows:

    https://twitter.com/<SCREEN-NAME>/status/1234123412341234134

execute __us__ like this:

    $ us "Yes, I think so too." -r 1234123412341234134

Note that with this opotion, the reply is addressed to all users involved in the destination tweet, not only to the destination tweet owner.

__Old style reply__

__--in-reply-to__, __-R__ STATUS-ID

This option is used to reply to the tweet with STATUS-ID. The message text must contain a @&lt;SCREEN-NAME> of the destination tweet owner somewhere in the message text.

In the following examples, Usakotter replies to the tweet with Status ID 1234123412341234134 which is tweeted by @&lt;SCREEN-NAME>.

    $ us "@<SCREEN-NAME> I think so too." -R 1234123412341234134
    $ us "Mt. Fuji is beautiful. RT @<SCREEN-NAME>: I think so too." -R 1234123412341234134

__Tweet a message from the standard input__

__--pipe__

    $ cat message.txt | us --pipe
    $ echo "Hello, world" | us --pipe

__Tweet without the confirmation prompt__

__--assume-yes__, __--yes__, __-y__

In each of the following examples, __Usakotter__ tweets the message immediately.

    $ us "Hello, world" -y
    $ cat message.txt | us --pipe -y

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

### Display Timelines

#### Home Timeline

__--timeline-home__, __--th__

Display your Home Timeline.

    $ us --timeline-home

#### Mention Timeline

__--timeline-mention__, __--tm__

Mention Timeline is a collection of tweets to you. Mention is also called "reply".

    $ us --timeline-mention

#### Retweets of Me Timelin

__--timeline-retweets-of-me__, __--tr__

Retweets of Me Timeline is a collection of your tweets which are retweeted by someone.

    $ us --timeline-retweets-of-me
    or
    $ us --tr

#### Favorites Timeline

__--timeline-favorites__, __--tf__ USER

This option displays a series of tweets which USER liked (favorited).

USER is a Screen Name or a User ID.

Both of the following two command display tweets liked by @NASA.

    $ us --timeline-favorites @NASA
    $ us --tf 11348282

#### User Timeline

__--timeline-user__, __--tu__ USER

USER is a Screen Name or a User ID.

The following four command lines do the same thing. They display the User Timeline of @NASA.

    $ us --timeline-user @NASA
    $ us --timeline-user 11348282
    or
    $ us --tu @NASA
    $ us --tu 11348282

#### Search Timeline

__--timeline-search__, __--ts__ QUERY

This option displays tweets which matchs QUERY

The following two lines display tweets including the words both "Japan" and "Olympics". If there are no tweets wich match QUERY, no tweets will be displayed.

    $ us --timeline-search 'Japan Olympics'
    or
    $ us --ts 'Japan Olympics'

The format of QUERY is the same as the one for Twitter Webclient or Official Twitter apps for mobile phones.

#### List Timeline

__--timeline--list__, __--tl__ @SCREEN-NAME/LIST

This option displays tweets in the list specified by LIST owned by the user specified by SCREEN-NAME.

The following example displays tweets in the List "leadership-at-nasa" owned by @NASA.

    $ us --timeline-list @NASA/leadership-at-nasa

### Display individual tweets

__--status__, __--id__, __-i__ STATUS-ID[,STATUS=ID[,[STATUS=ID]]]

__us__ -i STATUS=ID[,STATUS=ID[,[STATUS=ID]]]

Display a tweet with Status ID 1234123412341234134:

    $ us -i 1234123412341234001

Display two or more individual tweets. In the following example, Usakotter display three tweets:

    $ us -i 1234123412341234001,1234123412341234002,1234123412341234003

About Suatus ID, see __--in-reply-to-new__ option.

### Display a tweet and replies

__--reply-depth__, __--rd__ NUM

If this option is given, Usakotter displays up to NUM tweets in the reply chain from the specified tweet. If 1 is given to NUM, Usakotter displays the destination tweet to which the specified tweet replies. If 2 is given to NUM, Usakotter displays the specified tweet, the destination tweet of the specified tweet, and the destination tweet of the destination tweet of the specified tweet. Usakotter repeats this operation up to NUM times.

In the followeing example, Usakotter displays the specified tweet, whose Status ID is 1234123412341234001, and up to five tweets in the reply chain from the specified tweet.

    $us -i 1234123412341234001 -c 5

If __--reply-depth__=1, Usakotter displays the destination tweet to which the specified tweet replies. If the destination tweet is a reply, Usakotter 

### User information

#### User account information

__--user__, __-u__ USER

The following two example do the same thihg.

    $ us -u @NASA
    $ us -u 11348282

#### List of following users

__--followings-users__, __--friends-users__ [USER]

Display the list of the users who USER follows.

The following two example do the same thihg.

    $ us --followings-users @NASA
    $ us --followings-users 11348282

If USER is omited, your follows are listed.

    $ us --followings-users

#### List of followers
 __--followers-users__ [USER]
 
Display the list of the users who USER is followed by.
 
The following two example do the same thihg.

    $ us --followers-users @NASA
    $ us --followers-users 11348282
 
 If USER is omitted, your followers are listed.
 
    $ us --followers-users

#### List of following users by User ID

__--followings-ids__, __--friends-ids__ [USER]

Display the User IDs of the users who USER follows.

    $ us --followings-ids @NASA
    $ us --followings-ids 11348282

If USER is omitted, your following USER's User IDs are listed.

#### List of followers by User ID

__--followers-ids__

Display the User IDs of the users who USER is followed by.

    $ us --followers-ids @NASA
    $ us --followers-ids 11348282

#### List of your blocking users

__--blocks-users__

Display the list of the users who you block.

    $ us --blocks-users

#### List of your muting users

__--mutes-users__

Display the list of the users who you mute.

    $ us --mutes-users

### Specify how many tweets to display

__--count__, __-c__ NUM

Display up to the 20 latest tweets on your Home Timeline:

    $ us --timeline-home -c 20

Display up to 10 latest followers of @NASA:

    $ us --followers-users @NASA

### Output format

__--format__ FORMAT

```
FORMAT:
    text (defalut)
    json (JSON)
```

### Save tweet data

__--save-as-text=FILE__

Save tweets to FILE in text format.

    $ us --timeline-home --save-as-text timeline-tweets.txt

__--save-as-json=FILE__

Save tweets to FILE in JSON format.

    $ us --timeline-mention --save-as-json mentions.json

# Requirements

## Degian pagages

```
libruby2.5:amd64        2.5.5-3+deb10u1
ruby-json               2.1.0+dfsg-2+b1
ruby-locale             2.1.2-1
ruby-multipart-post     2.0.0-1
ruby-nokogiri           1.10.0+dfsg1-2
ruby-oauth              0.5.4-1
ruby-httpclient         2.8.3-2
ruby-addressable        2.5.2-1
```

## Gems
```
rainbow                 3.0.0
twitter                 6.2.0
twitter-text            3.0.0
```
# Author
Shimaden (@SHIMADEN, 94380019, on Twitter, https://github.com/shimaden )

## Original author
shokai (Sho Hashimoto, https://github.com/shokai )

# Thanks to
shokai (Sho Hashimoto, https://github.com/shokai )

# License
MIT License

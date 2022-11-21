A few days ago I recalled a friend in a private Discord server sending a
message I _think_ was very funny; though I didn't precisely remember what it said,
I remember being entertained.

I could remember how the message started (a few characters of the first word),
and how it ended (an emoji). Unfortunately, Discord's built-in search feature
isn't very good at searching for _either_ of those things.

But I really wanted to find this message.

So I took it upon myself to create a Discord bot solely to find this one message.

The concept was simple: Make a bot that, upon joining a
guild<sup><a id="1body" href="#1">[1]</a></sup>,
looks at every message in every channel and stores them in a database that you can
query in some way that's better than whatever Discord is doing. Ez.

<pre><code class="lang-python">
@bot.event
async def on_guild_join(guild):
...
    await scrape(guild)

async def scrape(guild):
...
    async for message in channel.history(limit=None):
        msgs += 1
        cur.execute('''INSERT OR IGNORE INTO messages
            (id, guild, author, author_nickname, contents, created, channel) VALUES (?, ?, ?, ?, ?, ?, ?)''',
            (message.id, message.guild.id, message.author.id, message.author.display_name, message.content,
                int(time.mktime(message.created_at.timetuple())), message.channel.id))
...
</code></pre>

Done!

It takes a while to get itself up to speed — I think the ~200,000 messages in this
server took about an hour, which I personally attribute to the Discord API having
a hard limit of returning 200 messages per request. Nonetheless, we got there:

<pre>
sqlite> SELECT * FROM messages ORDER BY RANDOM() LIMIT 1;
[redacted]|[redacted]|[redacted]|noatime|the only fast browser is Netscape Navigator 4.0|[redacted]|[redacted]
</pre>

Now I had to figure out how I wanted to query this data. The kind of filters I'd
want came to me pretty quickly.

<pre><code class="lang-python">
@bot.slash_command()
@guild_only()
async def look(ctx,
        query: str,
        max_count:   int = 25,
        min_length:  int = None,
        max_length:  int = None,
        starts_with: str = None,
        ends_with:   str = None,
        case_sensitive: bool = False,
        channel: discord.TextChannel  = None,
        author:  discord.User         = None,
    ):
</code></pre>

Now I needed to settle on the actual search algorithm. At first I tried using `fnmatch.fnmatch`
from Python's [fnmatch](https://docs.python.org/3/library/fnmatch.html) built-in library,
but fnmatch, being similar to a cut-down [Glob](https://en.wikipedia.org/wiki/Glob_(programming)),
was naturally inadequate.

Fortunately, a few minutes of Googling surfaced [thefuzz](https://github.com/seatgeek/thefuzz),
a fuzzy-finding library that harnessess [Levenshtein distancing](https://en.wikipedia.org/wiki/Levenshtein_distance),
a string metric algorithm I definitely understand.

TheFuzz comes with a few different variations of fuzzy finding. Simple ratio, partial ratio, token sort ratio,
and token set ratio. At first I tried simple ratio because it sounded simple, but the similarity score is severely
penalised when queries lack words from the source or has words in the wrong order, which I found were common
mistakes to occur when recalling message content.

<pre><code class="lang-python">
>>> fuzz.ratio('A test sentence', 'A sentence test')
67
>>> fuzz.ratio('A test', 'A test sentence')
57
>>> fuzz.ratio('Aa test sentenc', 'A test sentence')
93
</code></pre>

Instead, I found token set ratio, which didn't penalise for word duplicates nor word order, fit the bill better.

<pre><code class="lang-python">
>>> fuzz.token_set_ratio('A test sentence', 'A sentence test')
100
>>> fuzz.token_set_ratio('A test', 'A test sentence')
100
>>> fuzz.token_set_ratio('Aa test sentenc', 'A test sentence')
93
</code></pre>

And with the fuzz returning a similarity score rather than a simple `True`/`False`, I added a threshold parameter
to the bot too.

<pre><code class="lang-python">
async def look(ctx,
...
        channel: discord.TextChannel  = None,
        author:  discord.User         = None,
        similarity_threshold: int  = 75,
    ):
...
    messages = cur.execute('SELECT * FROM messages WHERE guild = ?', (ctx.guild.id,)).fetchall()

    if max_count > 25:
        max_count = 25

    count = 0
    for message in messages:
        if fuzz.token_set_ratio(query, message_text) >= similarity_threshold:
            count += 1
            response.append_field(
                discord.EmbedField(
                    name=message[3],
                    value=f'{message[4]}\nSent {datetime.utcfromtimestamp(message[5]).strftime("%Y/%m/%d %H:%M:%S")}+00:00. **[Link](https://discord.com/channels/{ctx.guild.id}/{message[6]}/{message[0]})**.'
                )
            )
...
</code></pre>

And sure enough, with that few hours of work and the query `/look query:[redacted] author:[redacted] min_length:5 max_length:25 ends_with:😭 case_sensitive:false`:

![](/img/found_message.png)

<hr>

<sup id="1"><a href="#1body">[1]</a></sup> The Discord API docs call servers _guilds_
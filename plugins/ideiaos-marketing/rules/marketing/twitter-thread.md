---
name: "Twitter/X Thread"
platform: "twitter"
content_type: "thread"
description: "Multi-post threaded content for teaching, storytelling, and building authority on Twitter/X"
whenToUse: |
  Creating agents that produce Twitter/X threads, multi-tweet educational or narrative content.
constraints:
  max_chars_per_tweet: 280
  recommended_thread_length: "5-12 tweets"
  max_thread_length: 25
  max_hashtags_total: 2
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- Threads live and die by their first tweet. If the hook does not stop the scroll, the entire thread goes unread. The first tweet must function as a standalone, self-contained statement.
- Thread engagement is cumulative: engagement on early tweets boosts distribution of later tweets. Front-load the most compelling hook and tightest logic in the first 1-3 tweets.
- Threads perform best when they teach something specific, tell a compelling story, or make a clearly-argued case. Pure promotional threads have near-zero engagement.
- Ideal thread length: 5-12 tweets. Shorter threads often feel thin; longer threads (25+) lose readers through attrition. The sweet spot is delivering complete value without overstaying.
- The last tweet must pay off the hook's promise and include a specific CTA (follow, like, share, or reply).
- Threads benefit from bookmarking. Readers who bookmark return later. Design threads to be saved as reference material.
- Number the tweets explicitly (1/, 2/, 3/...) to signal that this is a thread and help readers navigate back.

## Thread Formats

### Format 1: The Educational Thread

**Goal:** Teach a skill, concept, or process step by step.
**Structure:**
1. Hook tweet: Bold claim or promised outcome ("I learned X that changed how I do Y. Here's everything:")
2. Context tweet: Why this matters and who it applies to
3-N. One concept, step, or principle per tweet
N+1. Summary tweet: Bullet-point recap of all points
N+2. CTA tweet: Follow, save, or reply for more

### Format 2: The Story Thread

**Goal:** Share a compelling professional story with extracted lessons.
**Structure:**
1. Hook tweet: Tease the outcome or most dramatic moment ("Three years ago I almost lost everything. Here's the story:")
2. Setup: The situation, the context, the stakes
3-N. Story beats: Chronological, one beat per tweet, building tension
N+1. Resolution: What happened, what changed
N+2. Lessons: 3-5 bullet points of extractable takeaways
N+3. CTA tweet

### Format 3: The Argument Thread

**Goal:** Make a case for a specific position.
**Structure:**
1. Hook tweet: The thesis statement ("X is wrong. Here's why:")
2. Context tweet: Why this matters and who holds the conventional view
3-N. Arguments/evidence tweets: One argument per tweet with supporting data or example
N+1. Counterargument acknowledgment: Steel-man the opposing view briefly
N+2. Rebuttal: Why the original position holds despite the counterargument
N+3. Conclusion and CTA

### Format 4: The Resource Thread

**Goal:** Curate and annotate high-value resources.
**Structure:**
1. Hook tweet: What is included and why it matters
2-N. One resource per tweet with: name, what it is, why it is valuable, link
N+1. CTA tweet: Save this thread, follow for more

## Writing Guidelines

- **Every tweet must stand alone.** A reader should be able to read any individual tweet and extract value even without the surrounding context.
- **Number every tweet** from 1/ onward so readers know where they are in the thread.
- **One idea per tweet.** Never cram two points into one tweet. If you cannot fit a complete thought in 280 characters, restructure the point.
- **Use numbered lists within tweets sparingly.** Bullet points within a single tweet work well for 2-3 items. For longer lists, one item per tweet is cleaner.
- **Include evidence.** Numbers, case studies, named examples, direct quotes. Specificity is the thread writer's credibility.
- **The transition between tweets matters.** Each tweet should flow naturally into the next. Avoid abrupt topic shifts.
- **The last tweet must close the loop.** Restate the hook's promise, deliver it, and give a specific CTA.
- **No hashtags in middle tweets.** Place hashtags only in the first or last tweet. Maximum 2.

## Output Format

```
=== THREAD ===

TWEET 1 (Hook):
[Bold claim, outcome tease, or story opener — must work as standalone]

---

TWEET 2 (Context/Setup):
[Why this matters / who this applies to / setup for the story or argument]

---

TWEET 3:
[First main point, step, story beat, or argument — one idea only]

---

TWEET 4:
[Second main point, step, story beat, or argument]

---

[Continue through all body tweets...]

---

TWEET N-1 (Summary/Resolution):
[Bullet-point recap or story resolution]

---

TWEET N (CTA):
[Specific CTA — follow, save, reply with answer]

If this was helpful, follow me for more [topic] content.
Save this thread for later.

#hashtag1 [optional, max 2 in entire thread]

=== THREAD NOTES ===
Format used: [Educational / Story / Argument / Resource]
Total tweets: [X]
Characters per tweet: [list if any are near the 280 limit]
Hashtags used: [where they appear, what they are]
```

## Quality Criteria

- [ ] First tweet functions as a standalone statement — compelling without any context
- [ ] First tweet explicitly signals there is more (colon, "Here's how:", "Thread:")
- [ ] Every tweet is numbered (1/, 2/, 3/...)
- [ ] Each tweet contains exactly one complete idea
- [ ] All tweets are under 280 characters
- [ ] Thread follows one of the four defined formats
- [ ] Body tweets contain specific evidence, examples, or data
- [ ] Transitions between tweets are logical and smooth
- [ ] Summary or resolution tweet consolidates the value
- [ ] Final tweet includes a specific CTA
- [ ] Maximum 2 hashtags appear in the entire thread (first or last tweet only)
- [ ] Total thread length is 5-12 tweets

## Anti-Patterns

- **Weak first tweet** — The most common thread failure. If the hook does not make someone stop and want more, the thread is dead. Test the first tweet as a standalone post before threading.
- **One tweet per concept that needs two** — Cramming complex ideas into 280 characters creates unclear, incomplete thoughts. Split the idea into two tweets.
- **Padding to extend thread length** — Adding filler tweets ("And that's not all...") to reach a round number. Every tweet must earn its place.
- **No CTA on the last tweet** — A thread without a clear ask at the end generates 50-70% fewer follows and saves. Always close the loop.
- **Excessive hashtags** — More than 2 hashtags in an entire thread signals spam. Place tags only at the start or end.
- **Orphaned tweets** — Any tweet in the thread that cannot be understood without reading the tweets before it breaks the "each tweet stands alone" rule.
- **Skipping the summary tweet** — For educational and argument threads, the summary tweet is where readers decide to bookmark. Do not skip it.
- **Self-promotion without value** — Threads that are primarily about the author's product or service without delivering educational or narrative value have near-zero engagement outside existing fans.

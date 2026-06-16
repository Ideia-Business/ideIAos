---
name: "YouTube Script"
platform: "youtube"
content_type: "script"
description: "Long-form video scripts optimized for watch time, retention, and channel growth"
whenToUse: |
  Creating agents that produce YouTube video scripts, long-form educational or entertainment video content.
constraints:
  recommended_duration: "8-15 minutes"
  min_words: 1200
  max_words: 2500
  title_max_chars: 100
  description_max_chars: 5000
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- YouTube's primary ranking metric is Watch Time (total minutes watched). High click-through rate (CTR) brings viewers in; high watch time keeps them in the algorithm. Both are required.
- Average View Duration (AVD) matters more than raw views. A video watched for 70% of its length by 1,000 viewers outperforms a video watched for 20% by 10,000 viewers.
- The first 30 seconds determine whether viewers stay for the full video. This section must deliver immediate value, establish what the video covers, and create a reason to keep watching.
- YouTube search and suggested video algorithms use title, description, and tags for discovery. Front-load primary keywords in the title and first 200 characters of the description.
- The "click and stay" loop: compelling thumbnail + title drives CTR; strong hook + retention arc drives AVD. Both must be engineered.
- Best video lengths for most educational channels: 8-15 minutes. Long enough to cover the topic with depth; short enough to maintain retention.
- Videos under 8 minutes are less monetizable and have lower perceived value for educational content. Videos over 20 minutes require exceptional retention scripting.

## Content Structure

### Script Structure

**1. Pattern Interrupt / Open Loop Hook (0-30 seconds)**
- The first statement must create an open loop: a question, a surprising claim, or a preview of the payoff that will only be delivered at the end.
- Do NOT start with "Hey guys, welcome back to my channel" — this is the pattern that drives immediate click-away.
- Technique: Start in the middle of the story. Show the result before explaining the journey.

**2. Credibility + Preview (30-60 seconds)**
- Establish why you are the right person to explain this topic (briefly — show, don't claim).
- Preview exactly what the viewer will learn by the end of the video.
- Optional: "If you watch until the end, you'll get [specific bonus or insight]" to reduce early drop-off.

**3. Content Body (bulk of video)**
- Divided into 3-5 distinct chapters or sections.
- Each section opens with a micro-hook (a question or claim specific to that section).
- Each section closes with a transition that creates anticipation for the next section.
- Pattern interrupt every 90-120 seconds: change camera angle, cut to B-roll, show a graphic, or shift the pace.

**4. Retention Techniques (throughout)**
- Open loops: raise questions and delay the answer.
- Callbacks: reference something said earlier to create coherence.
- Micro-payoffs: deliver small value moments every 60-90 seconds so the viewer keeps getting rewarded.
- Re-hooks after the 2-minute mark: re-engage viewers who are drifting with a bold statement or a preview of what is coming.

**5. Conclusion + CTA (last 60-90 seconds)**
- Summary: recap the 3 main points in 30 seconds.
- Value affirmation: remind the viewer of what they can now do with what they learned.
- CTA: one primary ask (subscribe, comment, watch next video, download resource). Never stack three CTAs.
- Teaser for the next video: increases session time, which is a separate ranking signal.

## Script Writing Guidelines

- Write in a conversational register, not an essay register. The script should sound like how you talk, not how you write.
- Short sentences. Mix sentence lengths to maintain rhythm: one short, one longer, one short.
- Write every sentence to be spoken, not read. Awkward constructions that look fine on the page often stumble when spoken aloud.
- Use the word "you" constantly. This is a conversation, not a presentation. The viewer should feel directly addressed at all times.
- Embed pattern interrupts explicitly in the script: [B-ROLL: show example X] or [GRAPHIC: show table] or [CUT TO: close-up].
- Avoid long, uninterrupted sections of talking head. Every 60-90 seconds, change something visually.
- Write a clear on-screen text cue for every key statistic, concept name, or step number.

## Output Format

```
=== SCRIPT ===

TITLE (for YouTube): [Keyword-optimized, max 100 chars]
THUMBNAIL TEXT: [2-5 word bold text for thumbnail overlay]
ESTIMATED DURATION: [X minutes]

---

[HOOK SECTION 0:00-0:30]

[First sentence — open loop, surprising statement, or result-first hook]

[Second sentence — why this matters to the viewer personally]

[Third sentence — "In this video, I'm going to show you exactly how to..."]

---

[CREDIBILITY + PREVIEW 0:30-1:00]

[Brief credibility signal — specific result, experience, or context]

[Explicit preview of the 3-5 things they will learn]

[Optional retention hook: "Stay until the end because I'm going to share X"]

---

[SECTION 1 TITLE: X minutes into video]

[Micro-hook opening this section]

[Main content of this section — conversational, specific, with examples]

[On-screen text cue: "[KEY POINT TEXT]"]

[Transition into Section 2: "But here is where most people get stuck..."]

---

[SECTION 2 TITLE]

[Continue pattern...]

---

[SECTION 3-5 as needed...]

---

[CONCLUSION AND CTA]

[30-second summary of 3 key points]

[Value affirmation: "Now you can..."]

[One primary CTA — specific and direct]

[Teaser for next video]

---

=== VIDEO METADATA ===

DESCRIPTION (first 200 chars, keyword-optimized):
[Keywords front-loaded, value promise]

FULL DESCRIPTION:
[Chapters list with timestamps]
[Resource links]
[Related videos]
[Standard channel CTA]

TAGS: [10-15 relevant search tags]

CHAPTERS:
0:00 — [Hook/Intro]
0:30 — [Preview]
1:00 — [Section 1]
X:XX — [Section 2]
...
X:XX — [Conclusion]
```

## Quality Criteria

- [ ] Script opens with a hook in the first sentence that creates an open loop (not a greeting)
- [ ] First 30 seconds clearly state what the viewer will learn and why they should stay
- [ ] Content is divided into 3-5 distinct sections with clear transitions
- [ ] Each section includes explicit pattern interrupt cues (B-roll, graphic, on-screen text)
- [ ] Script is written in conversational spoken register, not essay register
- [ ] "You" is used consistently throughout to maintain direct address
- [ ] Retention hook is present after the 2-minute mark to re-engage drifting viewers
- [ ] Conclusion delivers on the hook's open loop and summarizes 3 key points
- [ ] One clear CTA in the conclusion — not three stacked asks
- [ ] Title is keyword-optimized and under 100 characters
- [ ] Estimated duration is 8-15 minutes for educational content
- [ ] Video metadata section includes description (with first 200 chars), tags, and chapter timestamps

## Anti-Patterns

- **Starting with a greeting** — "Hey guys, welcome back!" before delivering any value causes immediate viewer drop-off. The hook must come first.
- **Telling viewers what you are about to do without showing it** — "In this video I will explain X and then Y and then Z" is a preview, not a hook. Tease the outcome or the most interesting part, not the structure.
- **No pattern interrupts** — A talking-head video with no visual variety has severe retention drop-off. Every 90 seconds, change something on screen.
- **Stacking CTAs** — "Subscribe, like, comment, download, and check out my course" is too many asks. Choose one primary CTA per video.
- **Thin content padded to hit a length target** — Padding to 10 minutes with repetition and filler destroys watch-time metrics. Every section must earn its time.
- **No chapter timestamps** — Chapters are an algorithmic feature that increases click-through on suggested videos and helps retention by letting viewers skip to relevant sections.
- **Essay-register writing** — Scripts that sound like academic articles are painful to deliver and painful to listen to. Conversational register is mandatory.
- **Abandoning the open loop** — Raising a question or teasing a reveal and then not delivering it loses viewer trust. Every open loop must close by the end of the video.

---
name: "YouTube Shorts"
platform: "youtube"
content_type: "shorts"
description: "Vertical short-form video scripts optimized for discovery, watch time, and channel subscriber growth"
whenToUse: |
  Creating agents that produce YouTube Shorts scripts or vertical short-form video content.
constraints:
  max_duration_seconds: 60
  recommended_duration: "30-45s"
  aspect_ratio: "9:16 vertical"
  max_title_chars: 100
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- YouTube Shorts are distributed via the Shorts shelf and the dedicated Shorts feed, which is separate from the main YouTube recommendation system. Shorts can reach non-subscribers, making them a discovery tool for growing a channel.
- The primary metric for Shorts is Watch Percentage (what percentage of the Short viewers watch). A Short watched 3x by 1,000 viewers signals stronger quality than a Short watched once by 5,000 viewers.
- Shorts do NOT replace long-form videos in search rankings — they rank separately in the Shorts shelf. Shorts and long-form content complement each other.
- First 1-3 seconds are the decisive window. The viewer is scrolling vertically at high speed. The hook must be immediate and visual.
- Shorts under 45 seconds tend to have higher completion rates. Target 30-45 seconds.
- Adding chapters to Shorts is not supported. Keep the content linear.
- Using trending audio in Shorts boosts discoverability within the Shorts feed.
- Posting Shorts consistently (3-5x/week) signals an active channel and improves placement.

## Content Structure

### Shorts Script Structure

1. **Hook (0-3 seconds)** — Visual action or spoken statement that makes the viewer stop swiping. No intros, no logos.
2. **Setup (3-8 seconds)** — Brief context establishing what the Short is demonstrating or teaching.
3. **Delivery (8-45 seconds)** — The complete value: technique, fact, demonstration, or story beat. Keep it moving — no pauses or filler.
4. **Loop/CTA (last 3-5 seconds)** — End with a visual or spoken cue that can loop back to the beginning (increases replays), or a direct CTA ("Subscribe for more" / "Comment [word]").

### Content Types for Shorts

- **Quick tip**: One actionable insight in under 45 seconds
- **Surprising fact**: One counterintuitive or little-known piece of information
- **Demonstration**: Show a technique, result, or transformation in real-time
- **Story fragment**: The most compelling 30-45 seconds of a longer story, leading the viewer to the full video
- **Reaction/Commentary**: 30-45 second take on a trending topic or piece of news

## Writing Guidelines

- Write for screen-first. Every sentence must be paired with a visual action or on-screen text.
- No slow setups. If the first visual is not interesting, the viewer has already left.
- Burned-in captions are essential. Like all short-form vertical video, Shorts are watched without sound by a significant portion of viewers.
- Keep spoken words under 120 words for a 45-second Short (allowing for natural pacing at 150 wpm).
- Write on-screen text that reinforces, not duplicates, the spoken words. Do not caption the script verbatim — use text overlays to highlight key words and numbers.
- Design the ending for loop potential. Seamless loops increase the watch percentage score.

## Output Format

```
=== SHORT SCRIPT ===

TITLE: [Keyword-optimized, max 100 chars, includes search term]
DURATION TARGET: [X seconds]

---

HOOK (0-3s):
[Visual]: [What appears on screen — action, text overlay, or visual hook]
[Audio]: [First spoken words or sound]
[On-screen text]: [Bold text overlay if different from spoken]

SETUP (3-8s):
[Visual]: [Scene or transition]
[Script]: [Brief spoken context — 1 sentence maximum]

DELIVERY (8-45s):
[Visual]: [Shot description with cuts every 5-8 seconds]
[Script]: [Full spoken content for the delivery section]
[On-screen text]: [Key facts, steps, or terms to highlight]

LOOP/CTA (last 3-5s):
[Visual]: [Final frame — ideally loops back to opening]
[Script]: [CTA or loop-enabling spoken line]
[On-screen text]: [Subscribe / Comment / "Watch this again"]

---

=== SHORTS METADATA ===

TITLE: [Same as above]
DESCRIPTION: [2-3 sentences with primary keywords. Include #Shorts]
TAGS: [5-10 relevant tags]
AUDIO: [Trending sound suggestion or original audio]
```

## Quality Criteria

- [ ] Hook delivers an immediately interesting visual or statement within the first 3 seconds
- [ ] Total duration is 30-45 seconds
- [ ] Burned-in captions or on-screen text overlays are specified
- [ ] On-screen text highlights key words/numbers, not just duplicates the script
- [ ] Ending is designed for loop potential or includes a clear CTA
- [ ] Title includes primary search keyword
- [ ] Description includes #Shorts tag
- [ ] Audio direction is specified (trending sound or original audio)
- [ ] No slow intro — value delivery begins immediately
- [ ] Spoken script is under 120 words (for natural pacing at 45 seconds)

## Anti-Patterns

- **Slow intros** — Any Shorts that starts with a greeting, logo, or context before delivering the hook is dead on arrival. Begin with the hook.
- **No captions** — Shorts are watched without sound in large proportions. No captions = no value delivery for silent viewers.
- **Repurposing landscape video** — Horizontal video cropped to 9:16 wastes screen real estate and signals low effort. Shoot natively vertical.
- **Too long** — Shorts over 60 seconds are automatically reclassified, and Shorts over 45 seconds suffer from high drop-off rates. Target 30-45 seconds.
- **No keyword in title** — Shorts can surface in YouTube search. A title without a relevant keyword misses the discoverability opportunity.
- **Ending without a loop or CTA** — Shorts that end abruptly with no loop design and no CTA miss the replay-boosting mechanic that drives watch percentage scores.
- **Stacking multiple CTAs** — "Like, comment, subscribe, and check out my long video" is too many asks for 45 seconds. Choose one.

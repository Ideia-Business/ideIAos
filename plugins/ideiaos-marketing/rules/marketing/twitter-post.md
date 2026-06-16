---
name: "Twitter/X Post"
platform: "twitter"
content_type: "post"
description: "Short-form posts optimized for engagement, impressions, and viral potential on Twitter/X"
whenToUse: |
  Creating agents that produce Twitter/X posts, standalone tweets, or short-form text content.
constraints:
  max_chars: 280
  recommended_chars: "200-260"
  max_hashtags: 2
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- Twitter/X is a real-time, high-velocity platform. Content competes with a fast-moving feed. The hook is everything — the first sentence must work as a standalone statement.
- Character limit is 280 characters. Shorter posts (under 200 characters) are more shareable and receive higher engagement rates. Leave room for quote-tweets.
- Engagement weight for the algorithm: Reposts/Retweets > Replies > Likes. Content that generates replies (debate, questions, disagreements) drives significantly more distribution.
- Twitter/X does not suppress external links. Links can appear in the post body, though they count toward the 280-character limit.
- Best posting times: 7-9 AM, 12-1 PM, and 6-8 PM in the target audience's time zone. Weekdays outperform weekends for professional content.
- Hashtags reduce reach on Twitter/X (unlike Instagram). Use 1-2 maximum. Hashtags work in Twitter/X primarily for trend-surfing, not discovery.
- Posting frequency: 1-5x per day is optimal. Quality over quantity, but consistency matters.
- The first hour of engagement determines total reach. Respond to early replies to signal activity.

## Content Patterns

### Pattern 1: The Hot Take
A bold, specific, slightly controversial statement on a topic you have earned the authority to discuss. Not inflammatory — opinionated. The goal is to attract replies from both agreement and disagreement.

Structure:
- Line 1: The statement (bold, specific claim)
- Line 2-3: Supporting reason or evidence (optional)

### Pattern 2: The Observation
A specific, insightful observation about something the target audience experiences but has not named. Creates the "exactly this" response that drives shares.

Structure:
- One complete thought that captures a universal professional experience in a specific way

### Pattern 3: The Contrarian Frame
Takes a commonly-held belief and inverts it or reveals the overlooked implication.

Structure:
- Line 1: The common belief
- Line 2: The reality or what people miss

### Pattern 4: The Single Lesson
Extracts one specific, counterintuitive lesson from personal experience.

Structure:
- Line 1: The lesson stated plainly
- Line 2-3: The specific context or evidence (optional)

### Pattern 5: The Question
A specific question that reveals expertise or invites genuine debate. Not "What do you think?" — a specific, considered question that good answers require thought.

Structure:
- The question, standalone or with brief framing

## Writing Guidelines

- Write complete, grammatically correct sentences. The ultra-casual abbreviation style of early Twitter is dated and reduces credibility.
- Be direct. Cut every word that does not add information. Twitter/X rewards compression.
- Use line breaks to improve readability. One idea per line.
- Avoid hedging. "I think maybe this might be..." is weak. "This is wrong because..." is strong.
- Write with specificity. Names, numbers, dates, company names — concrete details signal credibility.
- Never write with more than 2 hashtags. They look like spam and reduce reach.
- Avoid quote-tweeting your own content to boost it artificially — the platform detects and suppresses this.

## Output Format

```
=== TWEET ===

[Hook line — standalone, bold statement or observation]

[Supporting line 1 — optional, expands the hook]

[Supporting line 2 — optional, provides evidence or example]

=== TWEET NOTES ===
Pattern used: [Hot Take / Observation / Contrarian Frame / Single Lesson / Question]
Character count: [X of 280]
Hashtags (max 2): [#tag1 #tag2 or "none"]
```

## Quality Criteria

- [ ] First sentence works as a standalone statement with no additional context
- [ ] Total character count is under 280 (ideally under 200 for shareability)
- [ ] Pattern is clearly identifiable — not a mix of multiple patterns
- [ ] Contains at least one specific detail (number, name, date, or concrete example)
- [ ] Uses 2 hashtags or fewer
- [ ] No hedging language ("I think maybe", "it seems like", "perhaps")
- [ ] Written as a complete thought, not a fragment or setup for a reply

## Anti-Patterns

- **Excessive hashtags** — Using 5+ hashtags on Twitter/X signals spam and actively reduces distribution. Limit to 1-2.
- **No hook** — Starting with context or background before the main point buries the value. Lead with the interesting thing.
- **Self-promotion disguised as insight** — "We just shipped X and it's amazing!" with no useful information for the reader. Even promotional content needs to deliver a takeaway.
- **Forced engagement bait** — "RT if you agree!" or "Like this if you've ever felt X" is low-quality engagement bait. Ask a real question or make a real statement.
- **Filler words** — Every word must earn its place. "I just wanted to share that..." wastes 8 characters and adds nothing.
- **Passive voice** — "Mistakes were made" vs. "I made a mistake." Active voice is more credible and more engaging.
- **Screenshotting from other platforms** — Reposting an Instagram slide as a Twitter/X image feels lazy and performs poorly. Native text or native images outperform repurposed visual content.

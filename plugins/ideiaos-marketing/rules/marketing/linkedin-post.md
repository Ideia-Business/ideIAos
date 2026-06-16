---
name: "LinkedIn Post"
platform: "linkedin"
content_type: "post"
description: "Professional text-first posts optimized for impressions, engagement, and profile authority"
whenToUse: |
  Creating agents that produce LinkedIn posts, short-form professional content, or text-based updates for LinkedIn.
constraints:
  max_chars: 3000
  visible_chars_before_more: 210
  max_hashtags: 5
  optimal_hashtags: "3-5"
  max_images: 10
  max_video_length_minutes: 10
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- LinkedIn ranks content by relevance to professional identity, not by recency alone. Content that aligns with the reader's industry and role receives priority distribution.
- The first 210 characters are visible before the "See more" cutoff. These characters determine whether the reader expands the post. Front-load the hook.
- Text-only posts (no images, no links) typically receive higher reach than posts with external links. LinkedIn suppresses content that drives users off-platform. Keep links in comments when possible.
- Engagement signal weight: Comments > Reactions > Reposts. A post with 20 meaningful comments outperforms one with 200 reactions in algorithmic distribution.
- Dwell time matters. LinkedIn tracks how long users stop at each post. Long-form content that readers finish reads as high-quality signal.
- Best posting times: Tuesday through Thursday, 7-9 AM or 12-1 PM in the professional's local time zone. Monday mornings and Friday afternoons have lower engagement.
- Early engagement in the first 60-90 minutes strongly influences total distribution. Do not post and disappear. Engage with early commenters.
- Posting frequency: 3-5x per week is optimal. Daily posting with quality content maintains momentum. More than one post per day on the same account reduces reach.

## Content Structure

### The LinkedIn Hook Formula

The hook is the first 1-3 sentences. It must stop the scroll and create enough curiosity or value promise that the reader taps "See more." No slow openers, no "I'm excited to announce," no throat-clearing.

**High-performing hook patterns:**
- **Contrarian opener**: "Everyone says X. They're wrong."
- **Quantified claim**: "I grew our LinkedIn following from 0 to 12,000 in 90 days. Here is exactly how."
- **Story opener**: "Three years ago, I was about to quit my job. Then one meeting changed everything."
- **Direct challenge**: "If you're still doing X in 2024, you're behind. Here's what's replacing it."
- **Uncomfortable truth**: "Most marketing advice you read on LinkedIn is wrong. Including this post. Here's why that's fine."

### Post Body Patterns

**Pattern 1: Insight + Story + Lesson**
- Hook with a counterintuitive insight
- 3-5 sentences of personal story that illustrates the insight
- 3-5 bullet points with transferable lessons
- Closing question or reflection

**Pattern 2: The Numbered List**
- Hook that promises X number of things
- Numbered list with one point per line and a brief explanation
- Closing synthesis that ties the list together
- CTA

**Pattern 3: The Hot Take**
- Bold, specific, slightly controversial statement
- 2-3 paragraphs arguing the position with evidence or examples
- Acknowledgment of the counterargument
- Resolution that reinforces the original take
- Question that invites debate

**Pattern 4: Mini Case Study**
- Problem statement (company or situation)
- What was tried
- What failed
- What worked
- Key takeaway and transferable lesson

### Formatting Rules

- Use short paragraphs: 1-3 sentences maximum per paragraph.
- Leave a blank line between every paragraph or list item. Dense text blocks have lower dwell time.
- Use line breaks strategically. Each idea gets its own line.
- Use bullet points or numbered lists for scannable value delivery.
- Avoid bold and italic formatting. LinkedIn does not support markdown. Use line breaks for emphasis.
- Never include hyperlinks in the post body. They suppress reach. Put them in the comments.
- Hashtags go at the end of the post. Use 3-5 maximum. Mix broad professional tags with niche topic tags.

## Writing Guidelines

- Write in first person. LinkedIn is a professional network built on individual voice. Corporate-sounding "we" posts consistently underperform personal narrative.
- Be specific. Name the company, cite the exact number, state the year. Specificity is credibility.
- Write how you talk. Conversational, direct, and clear. Not stiff, not academic.
- Include exactly one main idea per post. Posts that try to cover multiple topics lose coherence and engagement.
- End with a question that drives comments. Avoid generic "What do you think?" Specific questions ("What is the single biggest mistake you made in your first year of X?") generate higher-quality responses.
- Add personal perspective to information. Pure information without a point of view is forgettable. What do YOU think about the data?

## Output Format

```
=== POST ===
[Hook — 1-3 lines. First 210 characters must work as standalone hook.]

[Blank line]

[Body — follow the chosen pattern. Short paragraphs. One idea per paragraph. Blank line between each paragraph.]

[Blank line]

[Closing question or reflection]

[Blank line]

#hashtag1 #hashtag2 #hashtag3

=== POST NOTES ===
Pattern used: [Insight+Story+Lesson / Numbered List / Hot Take / Mini Case Study]
Character count: [X of 3000]
First 210 characters: [paste here for visual verification]
Link to add in comments: [URL or "none"]
```

## Quality Criteria

- [ ] First 1-3 lines create a curiosity gap or value promise that compels "See more"
- [ ] First 210 characters function as a standalone hook without being cut off mid-thought
- [ ] Post follows one of the four defined patterns with consistent structure
- [ ] Written in first person with a clear, identifiable point of view
- [ ] Contains at least one specific detail (number, name, date, or concrete example)
- [ ] Paragraphs are 1-3 sentences maximum with blank lines between each
- [ ] No external links in the post body (links go in comments)
- [ ] Ends with a specific, conversation-starting question
- [ ] Uses 3-5 hashtags at the end of the post
- [ ] Total character count is under 3,000

## Anti-Patterns

- **Corporate-speak opener** — "We are thrilled to announce" or "Excited to share" tells the reader nothing about why they should care. This phrasing has the lowest opening rate of any LinkedIn hook pattern.
- **Linking in the post body** — External links reduce LinkedIn distribution. The algorithm suppresses posts that drive users off-platform. Put the link in the first comment.
- **Too many hashtags** — More than 5 hashtags looks like keyword stuffing and reduces professional credibility. Stick to 3-5 relevant tags.
- **Dense paragraph blocks** — No blank lines between paragraphs creates visual walls that readers skip. Use aggressive line breaks.
- **Generic CTA** — "Let me know what you think!" generates minimal engagement. Ask a specific question that requires a real answer.
- **Multiple topics in one post** — Trying to cover three points in one post weakens all three. One idea per post, fully developed.
- **No personal angle** — Sharing data or news without a personal perspective is a summary, not a post. Add your take.
- **Posting and disappearing** — LinkedIn's algorithm rewards sustained engagement. Responding to every comment in the first 90 minutes significantly boosts reach.
- **Humble-bragging** — "I'm humbled to have been named..." or "Just another record-breaking quarter for our team..." Signal confidence, not false modesty or overt bragging.

---
name: "Blog Post"
platform: "blog"
content_type: "post"
description: "Long-form blog articles optimized for reader value, engagement, and organic discovery"
whenToUse: |
  Creating agents that produce blog posts, editorial articles, or long-form written content for a blog.
constraints:
  min_words: 800
  max_words: 3000
  recommended_words: "1200-2000"
  title_max_chars: 70
  meta_description_chars: "150-160"
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- Blog posts are consumed on-demand by readers actively seeking information. The reader's intent defines the format and depth. Match the post's structure to the intent: informational, educational, or opinion.
- Reading time expectations: most blog readers will not read past 1,500 words unless the content is genuinely delivering value at every paragraph. Plan your word count based on topic complexity, not a length target.
- Internal linking from blog posts to related content significantly improves time-on-site metrics and distributes SEO equity. Include 2-4 contextual internal links per post.
- External links to authoritative sources strengthen credibility and support SEO. Link to high-quality sources when citing data or referencing expertise.
- Blog posts indexed by search engines require attention to semantic structure: one H1 (title), organized H2 and H3 subheadings, and descriptive alt text on images.
- Share-worthiness: posts that take a clear point of view, surface a non-obvious insight, or synthesize complex information into an accessible format are significantly more likely to be shared.

## Content Structure

### Blog Post Formats

**Format 1: The How-To Post**
- Title: "How to [achieve outcome] [qualifier]"
- Structure: Problem setup → Prerequisites (optional) → Step-by-step process → Common mistakes → Conclusion with next steps
- Best for: Tutorials, technical guides, practical instructions

**Format 2: The Listicle**
- Title: "[Number] [Things/Ways/Tools] to [achieve outcome]"
- Structure: Brief intro with the problem or opportunity → Numbered items with explanation → Synthesis conclusion
- Best for: Tips collections, resource roundups, strategy overviews

**Format 3: The Ultimate Guide / Pillar Post**
- Title: "The Ultimate Guide to [Topic]" or "Everything You Need to Know About [Topic]"
- Structure: Comprehensive coverage organized into chapters with a table of contents
- Best for: Cornerstone content, keyword anchor posts, comprehensive reference material

**Format 4: The Opinion / Thought Leadership Post**
- Title: "[Contrarian claim]" or "Why [Common Belief] Is Wrong"
- Structure: State the position → Evidence and argument → Counterargument acknowledgment → Resolution → Call to discussion
- Best for: Building authority, generating discussion, positioning on key issues

**Format 5: The Case Study**
- Title: "How [Subject] [Achieved Result] in [Time Period]"
- Structure: Context → Challenge → Approach → Results (with specific numbers) → Lessons extracted
- Best for: Demonstrating expertise, social proof, practical examples

### Core Structure (all formats)

**Introduction (150-250 words):**
- Hook: Open with a provocative statement, surprising statistic, or compelling scenario
- Problem/stakes: Why this topic matters right now, to whom
- Promise: What the reader will have learned or be able to do by the end

**Body (format-dependent):**
- Clear H2 subheadings every 200-350 words
- One main idea per section
- Concrete examples, data, or case references in every section
- Transition sentences between sections

**Conclusion (100-200 words):**
- Synthesize without verbatim repetition
- Actionable takeaway the reader can implement today
- CTA: comment, share, subscribe, or related content recommendation

## Writing Guidelines

- Write with a clear point of view. Neutral, unattributed generalizations are forgettable. Take a position and defend it.
- Use "you" to address the reader throughout. Not "readers" or "one" — "you."
- Every paragraph must earn its place. If a paragraph can be removed without loss of meaning, remove it.
- Vary sentence length deliberately. Long sentences establish context; short sentences land impact.
- Use active voice as the default. Passive voice adds words and removes clarity.
- Do not use jargon without defining it. Define every domain-specific term on first use.
- Include data and specific numbers wherever they exist. "40% reduction in churn" is more credible than "significantly reduced churn."
- Do not bury the most useful information at the bottom of the post. Front-load the value, then expand with context and evidence.

## Output Format

```
=== BLOG POST ===

TITLE: [Clear, keyword-aware, max 70 chars]
META DESCRIPTION: [150-160 chars — the sentence that appears in Google. Compelling summary.]
ESTIMATED READ TIME: [X minutes]
FORMAT: [How-To / Listicle / Ultimate Guide / Opinion / Case Study]

---

INTRODUCTION

[Hook — surprising stat, bold claim, or vivid scenario]

[Problem/stakes — who this is for and why it matters now]

[Promise — what the reader will learn or be able to do]

---

[H2: Section 1 Title]

[Topic sentence — core claim of this section]

[Body — evidence, example, data. One idea per paragraph. 200-350 words per section.]

[Transition into next section]

---

[H2: Section 2 Title]

[Continue pattern...]

---

[Continue through all sections...]

---

CONCLUSION

[Synthesis — key insights distilled without repetition]

[Actionable takeaway — one specific thing to do today]

[CTA — comment/share/subscribe/related content]

---

=== POST METADATA ===
Title: [Final version]
Meta description: [Final version, 150-160 chars]
Format: [Selected format]
Primary keyword: [The main search term this post targets]
Secondary keywords: [2-4 supporting keywords used naturally in the text]
Internal links: [2-4 URLs for contextual internal linking]
External sources cited: [List of any data sources or external references]
Word count: [X words]
```

## Quality Criteria

- [ ] Title is clear, keyword-aware, and under 70 characters
- [ ] Meta description is 150-160 characters and compels the click from search results
- [ ] Introduction has hook, stakes, and promise in the first 250 words
- [ ] Post follows one of the five defined formats
- [ ] H2 subheadings appear every 200-350 words
- [ ] Every section contains at least one concrete example, data point, or case reference
- [ ] Written in first person or second person ("you") with a clear point of view
- [ ] No jargon used without inline definition
- [ ] Active voice is used as default throughout
- [ ] Conclusion delivers a specific, actionable takeaway
- [ ] Includes 2-4 internal link placeholders
- [ ] Cites sources for all data and external claims
- [ ] Word count is 1,200-2,000 (or justified length for topic complexity)
- [ ] Metadata section is complete

## Anti-Patterns

- **No point of view** — A post that summarizes information without taking a position is a summary, not an article. Take a stance and defend it.
- **Keyword stuffing** — Repeating the target keyword in every paragraph makes the text unreadable and is penalized by search engines. Use the keyword naturally and include semantic variations.
- **Introduction that starts with a definition** — "Marketing is the process of..." is the weakest possible hook. Start with a problem, scenario, or surprise.
- **Section without an example** — Abstract explanations without concrete examples leave readers unable to apply the information. One example per section is the minimum.
- **Walls of text** — More than 5 sentences in a single paragraph makes online reading difficult. Break paragraphs more aggressively than in print.
- **Conclusion that repeats the introduction** — Synthesize and add, do not recap. The conclusion should deliver the payoff, not restate the promise.
- **Missing meta description** — Without a meta description, search engines generate their own from random body text. Always write the meta description intentionally.
- **Padding to hit a word count** — Adding filler paragraphs to reach 2,000 words when the topic is covered in 900 produces low-quality content. Let the topic dictate the length.
- **No CTA** — Blog posts without a clear next step leave readers at a dead end. Even a simple "What did you find most useful? Share in the comments" is better than nothing.

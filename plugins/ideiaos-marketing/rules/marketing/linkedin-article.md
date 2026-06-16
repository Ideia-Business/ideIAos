---
name: "LinkedIn Article"
platform: "linkedin"
content_type: "article"
description: "Long-form professional articles for thought leadership, authority building, and search visibility"
whenToUse: |
  Creating agents that produce LinkedIn articles or long-form content for professional thought leadership.
constraints:
  min_words: 800
  max_words: 3000
  recommended_words: "1200-2000"
  max_hashtags: 5
  seo_enabled: true
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- LinkedIn Articles are indexed by search engines and appear in Google results. They have a significantly longer shelf life than regular posts — high-quality articles continue driving traffic months or years after publication.
- Articles are accessible via the author's profile under "Articles" and can be featured on the profile prominently. They are the primary format for establishing LinkedIn thought leadership.
- Articles do not receive the same immediate algorithmic distribution as posts. They require intentional promotion via a regular post linking to the article (or sharing a key excerpt) at publication time.
- Articles support rich formatting: headers, bold, italic, bullet lists, numbered lists, and embedded images. Use these to improve scannability and visual quality.
- LinkedIn's internal search engine surfaces articles by topic and keyword. Include relevant professional keywords naturally in the title, headers, and body.
- Article length sweet spot: 1,200-2,000 words. Long enough to demonstrate depth; short enough to maintain reading completion. Articles under 800 words feel thin; articles over 3,000 words lose the majority of readers.

## Content Structure

### Article Structure

**1. Title**
- Specific and keyword-aware. Not clever wordplay — clear promise of the article's value.
- Formats that perform well: "How to X" / "X Lessons from Y" / "Why X is Wrong (And What to Do Instead)" / "The [Year] Guide to X"

**2. Introduction (150-200 words)**
- Hook: Open with a concrete scenario, provocative statistic, or clear problem statement.
- Problem/stakes: Establish why this matters and who it matters to.
- Promise: State clearly what the reader will learn or gain by reading to the end.
- Keep it short. The reader has already chosen to read the article — do not spend 500 words justifying yourself.

**3. Body Sections (500-1,500 words across 3-6 sections)**
- Each section has an H2 subheading that communicates the section's core point.
- Within each section: topic sentence, supporting evidence or example, takeaway.
- Use subheadings every 200-300 words.
- Include concrete examples, case studies, data points, or direct quotes.
- One main idea per section.

**4. Conclusion (100-200 words)**
- Synthesize the key points without repeating them verbatim.
- Deliver a specific, actionable takeaway the reader can implement immediately.
- End with a question or reflection that drives comments.

### Article Formats

**Format 1: The Framework Article**
- Introduces a new mental model, framework, or systematic approach to a professional problem.
- Structure: Problem → Why Current Approaches Fail → The Framework → How to Apply It → Results/Evidence

**Format 2: The Experience Debrief**
- Derives transferable lessons from a specific professional experience.
- Structure: Context → What Happened → What Was Tried → What Failed → What Worked → Lessons Extracted

**Format 3: The Industry Analysis**
- Examines a trend, shift, or change in a professional domain.
- Structure: The Change → Why It's Happening → Who It Affects → What to Do → Predictions

**Format 4: The Definitive Guide**
- Comprehensive reference on a specific professional topic.
- Structure: Introduction/Overview → Section 1 → Section 2 → ... → Conclusion/Resources

**Format 5: The Contrarian Take**
- Argues against a widely-held professional belief, practice, or convention.
- Structure: The Conventional Wisdom → Why It Fails → The Evidence → The Alternative → How to Transition

## Writing Guidelines

- Write in first person. Articles with an identifiable professional voice outperform generic informational content.
- Use subheadings as navigational markers. A reader who scans the subheadings should understand the article's core argument without reading a word of body copy.
- Support every significant claim with evidence: data, a case study, a direct quote, or a concrete example.
- Avoid padding. If a section can be cut without losing meaning, cut it. Tight writing is more credible than comprehensive writing.
- Define technical terms and acronyms on first use. LinkedIn audiences span expertise levels — do not assume prior knowledge.
- Use concrete language: specific numbers, named companies, real scenarios. Vague language reduces credibility.
- End sections with a transition sentence that connects to the next section. The reader should never wonder why they are reading the next part.

## Output Format

```
=== ARTICLE ===

TITLE: [Specific, keyword-aware title — max 100 characters]

INTRODUCTION
[Hook sentence — concrete scenario, statistic, or problem statement]

[Problem/stakes paragraph — why this matters and to whom]

[Promise sentence — what the reader will learn or gain]

---

[H2: Section 1 Title]

[Topic sentence — core point of this section]

[Evidence, example, or case study — 2-4 sentences]

[Takeaway — what this means for the reader]

---

[H2: Section 2 Title]

[Continue pattern...]

---

[H2: Section N Title]

[Continue pattern...]

---

CONCLUSION

[Synthesis paragraph — key insights without verbatim repetition]

[Actionable takeaway — one specific thing the reader can do today]

[Closing question — specific question that drives comments]

---

=== ARTICLE METADATA ===
Word count: [X words]
Format used: [Framework / Experience Debrief / Industry Analysis / Definitive Guide / Contrarian Take]
Keywords: [3-5 primary keywords the article targets]
Hashtags: #hashtag1 #hashtag2 #hashtag3
Suggested social post excerpt: [2-3 line excerpt for the LinkedIn post that promotes this article]
```

## Quality Criteria

- [ ] Title is specific, keyword-aware, and makes a clear value promise
- [ ] Introduction has hook, stakes, and promise in the first 200 words
- [ ] Article follows one of the five defined formats with consistent structure
- [ ] Subheadings appear every 200-300 words
- [ ] Every major claim is supported by evidence, data, or a concrete example
- [ ] Written in first person with a clear professional voice and perspective
- [ ] No undefined jargon or unexplained acronyms
- [ ] Conclusion delivers a specific, actionable takeaway
- [ ] Ends with a specific, conversation-starting question
- [ ] Word count is between 1,200-2,000 words
- [ ] Keywords are used naturally in title, at least two subheadings, and body content
- [ ] Metadata section is complete (word count, format, keywords, hashtags, social excerpt)

## Anti-Patterns

- **Generic title** — "Thoughts on Leadership" or "Why Innovation Matters" makes no clear promise. The title must tell the reader exactly what they will get.
- **Slow introduction** — Spending the first 200 words on background, history, or context loses most readers before the article begins. Hook first, context second.
- **Subheading-free walls of text** — An article without subheadings is unnavigable. Readers scan before they commit. No subheadings means no commitment.
- **Claims without evidence** — "Research shows that most leaders fail at X" without citing the research is a credibility killer. Name the study, cite the number, link to the source.
- **Padding with transitions** — Using an entire paragraph to say "Now let us move on to the next topic" wastes the reader's time and signals thin content.
- **First person without perspective** — Recounting events without sharing what they meant or what was learned is narrative without insight. Tell the reader what YOU concluded.
- **Republishing existing posts** — Articles should deliver content too long or deep for a regular post. Republishing a 500-word post as an article adds no value and wastes the format.
- **No promotion plan** — Articles need a corresponding post (or excerpt post) to drive initial readers. Publishing and hoping the algorithm finds the audience does not work.

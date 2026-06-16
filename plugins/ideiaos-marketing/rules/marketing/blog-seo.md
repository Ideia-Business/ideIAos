---
name: "Blog Post (SEO)"
platform: "blog"
content_type: "seo"
description: "Search-engine-optimized blog posts targeting specific keywords for organic traffic growth"
whenToUse: |
  Creating agents that produce SEO-optimized blog posts targeting specific search keywords for organic traffic.
constraints:
  min_words: 1000
  recommended_words: "1500-2500"
  title_max_chars: 60
  meta_description_chars: "150-160"
  keyword_density: "1-2%"
  target_keyword_in_title: true
  target_keyword_in_h1: true
  target_keyword_in_first_100_words: true
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- SEO blog posts are written to rank for a specific search query. The primary objective is to appear on the first page of Google results for the target keyword, then convert that search traffic into readers, subscribers, or customers.
- Search intent is the most important factor in SEO copywriting. The post must match the intent behind the keyword: informational (learn), navigational (find), transactional (buy), or commercial investigation (compare). Mismatching intent kills rankings regardless of technical optimization.
- Google evaluates three factors in order: (1) Topical relevance and depth, (2) E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness), (3) Technical SEO signals. Create content that genuinely answers the query better than any existing result.
- Word count correlates with rankings for informational keywords, but only because thorough content tends to cover the topic more completely — not because Google rewards length. Write to cover the topic completely, not to hit a word count.
- Featured snippet optimization: if the target keyword shows a featured snippet in Google, structure one of your sections to answer the query in 40-60 words under a clear subheading. This is the most reliable path to the #0 position.
- Page speed and Core Web Vitals affect rankings. Do not embed unnecessary images, scripts, or embeds in the post content.

## SEO Optimization Checklist

### Title (H1) Requirements
- Target keyword appears in the title, as close to the beginning as possible
- Under 60 characters (to avoid truncation in search results)
- Compelling enough to earn the click over adjacent results
- Includes a power word when possible: Best, Ultimate, Proven, Complete, Exact

### Meta Description Requirements
- 150-160 characters
- Includes the target keyword naturally
- Compels the click with a value statement or promise
- Ends with a soft CTA or benefit statement

### Content Structure Requirements
- Target keyword in the first 100 words of the article body
- Primary keyword used in at least one H2 subheading
- Semantic variations of the keyword (LSI terms) distributed throughout the body
- Subheadings (H2, H3) that reflect common related search queries

### Link Requirements
- 2-4 internal links to topically related content on the same domain
- 1-3 external links to authoritative sources (government sites, major publications, studies)
- Anchor text for internal links is descriptive, not "click here"

### Image Requirements (if applicable)
- Descriptive file names (not IMG_001.jpg)
- Alt text describing the image and including the keyword where natural
- Compressed to minimize page load impact

## SEO Content Structure

### Step 1: Determine Search Intent

Before writing, classify the keyword's search intent:
- **Informational**: The user wants to learn. Format: guide, how-to, explainer, listicle.
- **Commercial investigation**: The user is comparing options before buying. Format: comparison, review, best-of list.
- **Transactional**: The user is ready to buy. Format: product/service landing page (not blog format).
- **Navigational**: The user is looking for a specific site. Not targetable with blog content.

### Step 2: Analyze the SERP

Examine the top 5-10 results for the target keyword:
- What formats are ranking? (listicles, guides, single articles?)
- What word counts do top results use?
- What subheadings and topics do multiple results cover? (These are the required topics for comprehensive coverage.)
- Is there a featured snippet? If yes, what format does it use?

### Step 3: Build the Outline

Create an outline that covers all the topics the SERP analysis revealed as required, plus at least one angle or section that adds new value not present in competing results. This "content uplift" is the differentiator.

### Step 4: Write with Featured Snippet Awareness

For any H2 or H3 that targets a query with a featured snippet:
- Open the section with a 40-60 word direct answer to the question
- Then expand with detail, examples, and context below the snippet-optimized paragraph
- Do not bury the direct answer inside a paragraph — lead with it

### Step 5: Internal Link Placement

- Link within the body text to related content on the same site
- Anchor text should describe the destination content, not the URL
- Link early (in the first third of the article) for maximum SEO equity transfer

## Output Format

```
=== SEO BLOG POST ===

TARGET KEYWORD: [Exact match keyword]
SEARCH INTENT: [Informational / Commercial / Transactional]
FEATURED SNIPPET TARGET: [Yes / No — if yes, specify which section targets it]

TITLE (H1): [Target keyword near start, max 60 chars]
META DESCRIPTION: [150-160 chars, includes keyword, ends with value promise]

---

INTRODUCTION (first 200 words):

[Hook — immediately relevant to search intent]

[Target keyword used naturally in the first 100 words]

[Promise of what the post covers]

---

[H2: Primary related question or topic — include keyword variation]

[40-60 word featured snippet answer, if targeting snippet for this query]

[Expanded section — evidence, example, detail. 200-350 words.]

---

[H2: Second major topic]

[Continue pattern...]

---

[Continue all required SERP topics + at least one differentiating angle...]

---

CONCLUSION:

[Summary synthesis]

[Actionable takeaway]

[CTA or soft conversion prompt]

---

=== SEO METADATA ===
Target keyword: [Exact keyword]
Search intent: [Classification]
Title (H1): [Final, max 60 chars]
Meta description: [Final, 150-160 chars]
Primary keyword appearances: [List where the keyword appears — title, first 100 words, H2, body]
LSI/semantic keywords used: [List 5-10 variations used naturally in the body]
Internal links: [List 2-4 anchor text + target URL pairs]
External links: [List 1-3 authoritative sources cited]
Featured snippet section: [Which H2 targets the snippet, or "none"]
Word count: [X words]
```

## Quality Criteria

- [ ] Target keyword appears in the title (H1) near the beginning
- [ ] Title is under 60 characters
- [ ] Meta description is 150-160 characters and includes the target keyword
- [ ] Target keyword appears in the first 100 words of body content
- [ ] Target keyword appears in at least one H2 subheading
- [ ] Semantic variations (LSI terms) are distributed naturally throughout the body
- [ ] Post matches the search intent classification (informational, commercial, etc.)
- [ ] Covers all major subtopics that SERP analysis reveals are required
- [ ] At least one differentiating angle or section not present in competitor results
- [ ] Featured snippet optimization: 40-60 word direct answer under relevant subheading (if applicable)
- [ ] 2-4 internal links with descriptive anchor text
- [ ] 1-3 external links to authoritative sources
- [ ] Word count is appropriate for topic depth (minimum 1,000 words)
- [ ] SEO metadata section is complete with all required fields

## Anti-Patterns

- **Keyword stuffing** — Forcing the target keyword into every paragraph unnatural density triggers Google's spam filters and makes the content unreadable. Keep keyword density under 2%.
- **Mismatched search intent** — Writing an opinion piece for an informational keyword, or an informational piece for a keyword with clear commercial intent. Google will not rank content that does not satisfy the underlying search intent.
- **Thin content** — A 400-word post targeting a competitive informational keyword will not rank against comprehensive guides with 2,000+ words of genuine depth. Thin content should be expanded or consolidated.
- **Exact keyword in every subheading** — Using the exact target keyword in every H2 looks spammy and limits coverage of related topics. Use the primary keyword in 1-2 subheadings; use semantic variations in others.
- **No internal links** — Blog posts with no internal links are orphaned pages. They do not contribute to the site's authority architecture and miss link equity distribution opportunities.
- **External links to competitors** — Linking to a direct competitor for reference is a judgment call. When in doubt, link to research papers, government sources, or industry reports instead.
- **Ignoring the featured snippet** — If the target keyword shows a featured snippet in Google, not formatting a direct answer in the post is a missed #0 opportunity.
- **Writing for robots** — Optimizing so heavily for keywords that the content is unpleasant to read. Google's algorithms increasingly reward content that humans actually want to read and share. If humans would not enjoy reading it, it will not rank long-term.

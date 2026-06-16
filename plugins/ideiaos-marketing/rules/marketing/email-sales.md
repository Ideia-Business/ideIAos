---
name: "Email Sales"
platform: "email"
content_type: "sales"
description: "Sales and conversion-focused emails optimized for click-through rate and purchase conversion"
whenToUse: |
  Creating agents that produce sales emails, promotional emails, product launches, or conversion-focused email content.
constraints:
  subject_max_chars: 50
  preview_text_max_chars: 90
  recommended_word_count: "200-500"
  max_cta_count: 1
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- Sales emails live and die by their subject line and the relevance of the offer to the recipient. A well-timed, relevant sales email to a warm list converts; an unsolicited blast to a cold list generates spam complaints.
- Conversion rate in sales emails depends on three factors in this order: (1) the offer itself, (2) the timing and audience segmentation, (3) the copy. Great copy cannot save a bad offer or poor timing.
- Shorter sales emails outperform longer ones in nearly all categories. The goal is to get the click. The landing page or sales page does the selling. The email's job is to generate the click.
- Urgency and scarcity are the most powerful conversion levers — but only when genuine. Fake deadlines and artificial scarcity permanently damage trust and increase unsubscribes.
- Segmented campaigns consistently outperform broadcast emails by 30-50% in open rate and by 100%+ in click-through rate. Send the right offer to the right segment, not one message to the entire list.
- Sales email sequences (multiple emails over a launch period) outperform single-email campaigns. Minimum 3-email sequence: announcement, value-add/objection-handling, final reminder with deadline.

## Sales Email Types

### Type 1: The Direct Offer Email

**Use:** When the list is warm and the offer is clear. No need to warm up the audience — they know the product and the brand.

**Structure:**
1. Subject: Clear statement of the offer + benefit or deadline
2. Opening: One sentence establishing the hook or the reader's pain point
3. Offer statement: What is available, what it costs, what the reader gets
4. Key benefits: 3-5 bullet points of the most compelling outcomes
5. Objection handler: One sentence addressing the most common objection
6. CTA: Direct link to the sales page with urgency trigger
7. P.S.: Restate the offer and deadline in one sentence

### Type 2: The Story-Offer Email

**Use:** For launches to audiences less familiar with the product, or when social proof needs to be established before the ask.

**Structure:**
1. Subject: Story tease or outcome claim
2. Opening: Story hook (2-3 sentences)
3. Story middle: The challenge, the turning point, or the client result (3-5 sentences)
4. Transition to offer: "This is exactly why I built/why we created..."
5. Offer statement: Concise description of what is available
6. CTA: Link with benefit-oriented copy
7. P.S.: Deadline or scarcity reminder

### Type 3: The Objection-Handler Email

**Use:** Second or third email in a launch sequence, after the initial announcement has gone out.

**Structure:**
1. Subject: Address the most common objection directly
2. Opening: Acknowledge the objection without defensive framing
3. Handler: Evidence, story, or logic that neutralizes the objection
4. Social proof: Testimonial or result that supports the handler
5. Restate the offer: Brief reminder of what is available
6. CTA: Link with urgency copy

### Type 4: The Last Chance Email

**Use:** Final email in a launch sequence, sent on the last day or hours before a deadline.

**Structure:**
1. Subject: Explicit deadline reminder ("Closes tonight at midnight")
2. Opening: Direct acknowledgment that this is the last email about this offer
3. Summary: What the reader will miss if they do not act
4. Urgency amplifier: The specific deadline with the time zone
5. CTA: The clearest, most direct CTA in the sequence
6. P.S.: One sentence with a final urgency cue

## Writing Guidelines

- Write the way you speak in a direct sales conversation. Confident, clear, and focused on the reader's outcome — not the product's features.
- Lead with the reader's desired outcome, not with the product's name or your company's history.
- Benefits drive conversion; features do not. Translate every feature into a concrete outcome for the reader.
- Use specificity to build credibility: "47 customers" beats "many customers." "In 14 days" beats "quickly." "Save 3 hours per week" beats "save time."
- Address the most obvious objection before the reader can raise it internally. Preempting objections increases conversion.
- Urgency must be genuine. State the real reason for the deadline. If there is no genuine scarcity, do not manufacture it. Buyers recognize fake urgency and it destroys trust.
- The P.S. is the second most-read element in any email. Use it to restate the offer and deadline in a single sentence.

## Output Format

```
=== SALES EMAIL ===

TYPE: [Direct Offer / Story-Offer / Objection-Handler / Last Chance]
FROM NAME: [Name]
SUBJECT LINE: [Under 50 chars]
PREVIEW TEXT: [40-90 chars]

---

BODY:

[Opening — hook, story start, or direct pain point in 1-2 sentences]

[Blank line]

[Offer or story middle — 2-4 sentences]

[Blank line]

[Benefits — 3-5 bullet points of concrete outcomes, not features]
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

[Blank line]

[Objection handler — 1-2 sentences addressing the primary objection]

[Blank line]

[CTA — single, direct, benefit-oriented]
[Link or button text]

[Sign-off]
[Name]

P.S. [One sentence restating the offer + deadline]

---

=== EMAIL METADATA ===
Email type: [Direct Offer / Story-Offer / Objection-Handler / Last Chance]
Subject line: [Final version]
Preview text: [Final version]
CTA destination: [URL]
Deadline/urgency: [Specific date and time with time zone, or "none"]
Segment: [Who this email targets within the list]
Position in sequence: [Email 1/3, 2/3, 3/3, or standalone]
```

## Quality Criteria

- [ ] Subject line is under 50 characters, clear and benefit-driven or deadline-driven
- [ ] Preview text extends the subject and compels the open
- [ ] Opening hook is immediately relevant — no slow warmup
- [ ] Benefits are written as outcomes, not features
- [ ] Contains exactly one CTA with benefit-oriented copy
- [ ] CTA is placed after value delivery, not before
- [ ] Includes an objection handler for the most predictable resistance
- [ ] P.S. restates the offer and deadline in one sentence
- [ ] Urgency is genuine — no fake deadlines or manufactured scarcity
- [ ] Total word count is 200-500 words (shorter for direct offer and last chance; slightly longer for story-offer)
- [ ] Metadata section specifies email type, sequence position, and target segment

## Anti-Patterns

- **Feature-forward copy** — "Our product has X, Y, and Z features" converts far worse than "You will be able to do X, Y, and Z." Translate features into outcomes always.
- **Fake urgency and scarcity** — "Limited spots available" when there are unlimited spots, or "Offer expires tonight" that resets the next day. Sophisticated buyers recognize this immediately and it permanently damages trust.
- **Multiple CTAs** — A link to the sales page, a link to a webinar replay, and a link to a testimonial video in the same email. Each additional link reduces clicks on all of them.
- **Starting with your company name or product name** — "Brand X is launching Y" is the reader's least interesting framing. Start with their outcome or their problem.
- **No P.S.** — Sales emails without a P.S. miss the second most-read element. The P.S. is read by a large portion of readers who skip the body. Always include it.
- **No segmentation** — Sending a pitch for an advanced product to subscribers who just joined the list creates a mismatch between offer and audience readiness. Segment.
- **Wall of text** — Long, dense paragraphs in a sales email signal high friction to the reader before they even start reading. Short paragraphs, bullet points, and visible whitespace are conversion requirements.
- **Sending the same email to unresponsive subscribers** — Re-sending the same pitch to subscribers who have not opened the last 3-5 emails increases spam complaint rates and reduces deliverability for the entire list.

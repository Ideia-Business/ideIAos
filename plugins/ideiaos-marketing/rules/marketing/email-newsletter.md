---
name: "Email Newsletter"
platform: "email"
content_type: "newsletter"
description: "Subscriber newsletter optimized for open rate, click-through rate, and long-term reader relationship"
whenToUse: |
  Creating agents that produce email newsletters, subscriber communications, or recurring email content.
constraints:
  subject_max_chars: 50
  preview_text_max_chars: 90
  recommended_word_count: "400-800"
  max_cta_count: 1
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- Email open rate is determined almost entirely by the subject line and preview text. The content quality determines click-through rate, reply rate, and retention. These are separate optimization problems.
- Deliverability is a pre-condition. Emails that go to spam never get opened. Avoid spam-trigger words, maintain clean list hygiene, and authenticate sending domains (SPF, DKIM, DMARC).
- Mobile-first composition is mandatory. Over 60% of emails are opened on mobile. Short paragraphs, large font sizes, and single-column layouts are non-negotiable.
- The "from" name is as important as the subject line. Subscribers open emails from people they trust. Use a recognizable, consistent sender identity.
- Best send times: Tuesday through Thursday, 9-11 AM or 1-3 PM in the subscriber's local time zone. Avoid Monday mornings and Friday afternoons.
- Personalization (first name in subject or opening line) improves open rates by 20-30%.
- One CTA per email. Multiple CTAs reduce click-through on all of them. Decide what you want the reader to do and ask only that.

## Email Structure

### Component 1: Subject Line

**Rules:**
- Under 50 characters (to avoid mobile truncation)
- No all-caps
- No excessive punctuation or emoji (one emoji maximum, only if brand-appropriate)
- Creates curiosity, promises value, or establishes urgency — never all three at once
- Test two versions: a curiosity-gap subject and a direct-value subject

**High-performing patterns:**
- **Curiosity gap**: "The mistake I almost made last week"
- **Direct value**: "3 email templates that actually convert"
- **Personal question**: "Have you tried this yet?"
- **Number promise**: "5 tools I use every day (free)"
- **Story tease**: "What happened when I doubled my prices"

### Component 2: Preview Text

**Rules:**
- 40-90 characters — extends the subject line's hook, never repeats it
- Treated as the "second subject line" by most email clients
- If not set, email clients pull the first line of the email body (often undesirable)

### Component 3: Opening Line

- First sentence must earn continued reading. Treat it like a social media hook.
- Address the reader directly: "You already know that..."
- Or start with the story or insight directly: "Last Tuesday, a client asked me..."
- Never start with "I hope this email finds you well" — this is the signal that nothing interesting follows.

### Component 4: Body

**Newsletter body structure:**
- **Segment 1: The lead (100-200 words)** — The main story, insight, or hook that establishes the theme of this issue.
- **Segment 2: The content (200-400 words)** — The value delivery: the lesson, the data, the how-to, or the story continuation. One primary idea.
- **Segment 3: The application (100-150 words)** — What the reader can do with what they just learned. Practical, specific, actionable.

**Formatting rules:**
- Paragraphs: 1-3 sentences maximum.
- Blank line between every paragraph.
- No walls of text. Subheadings if the email exceeds 600 words.
- Bold key phrases that carry the most information.
- No more than 2-3 links in the email body (excluding the final CTA).

### Component 5: CTA

- One CTA, clearly and visually separated from the body text.
- Use a button or a bold hyperlinked line of text.
- Write the CTA copy as a benefit, not an action: "Get the free template" not "Click here."
- Place the CTA after the value has been delivered, not before.

### Component 6: Footer

- Unsubscribe link (required by law — CAN-SPAM, GDPR)
- Physical mailing address (required in many jurisdictions)
- Brief relationship reminder: "You're receiving this because you signed up at [source]."

## Writing Guidelines

- Write to one person, not your whole list. Imagine your ideal subscriber and write the email as if you are responding to a message they sent you.
- Use "you" throughout. Never "subscribers" or "our readers."
- Be honest about the email's purpose. If you are selling something, readers can handle that — but not if it is disguised as a pure value piece.
- Do not write to impress. Write to communicate. Plain, direct language outperforms elaborate prose in email.
- Keep the email focused on a single idea. A newsletter that covers three topics simultaneously gives readers three reasons to stop reading.
- Vary email types within your newsletter cadence: occasional personal stories build relationship; pure value issues build authority; promotional issues convert. Never run three promotional emails in a row.

## Output Format

```
=== EMAIL ===

FROM NAME: [Name or "First Name from Brand Name"]
SUBJECT LINE: [Under 50 chars — no caps, max 1 emoji]
PREVIEW TEXT: [40-90 chars — extends the subject, does not repeat it]

---

BODY:

[Opening line — hook, story start, or direct value entry]

[Blank line]

[Lead segment — 100-200 words establishing the theme]

[Blank line]

[Content segment — 200-400 words, the core value delivery]

[Blank line]

[Application segment — 100-150 words, what to do with this]

---

[CTA — single, benefit-oriented, visually distinct]

[CTA button or bold hyperlink text]

---

[Sign-off]
[Your name]
[Optional P.S. — a P.S. is the second most-read element of any email after the subject line. Use for a reinforcement of the CTA, a secondary link, or a human note.]

---

FOOTER:
[Standard unsubscribe / address / permission reminder]

=== EMAIL METADATA ===
Subject line A: [Version 1]
Subject line B: [Version 2 for A/B test]
Preview text: [Final version]
Primary CTA destination: [URL]
Word count: [X words]
Estimated read time: [X minutes]
```

## Quality Criteria

- [ ] Subject line is under 50 characters, creates curiosity or promises value, no all-caps
- [ ] Preview text is 40-90 characters and extends the subject without repeating it
- [ ] Opening line hooks the reader — no "I hope this email finds you well"
- [ ] Email covers exactly one main idea or theme
- [ ] Body paragraphs are 1-3 sentences with blank lines between each
- [ ] Includes exactly one CTA with benefit-oriented copy
- [ ] CTA is visually distinct and placed after the value delivery
- [ ] Total word count is 400-800 words
- [ ] Includes a P.S. with a reinforcement or human note
- [ ] Footer includes unsubscribe link and mailing address
- [ ] Metadata section includes A/B subject line, preview text, CTA destination, word count

## Anti-Patterns

- **"I hope this email finds you well"** — The lowest-performing email opener. Start with value or a hook immediately.
- **Multiple CTAs** — "Download the guide, follow us on Instagram, and book a call" in one email. Each additional CTA reduces click-through on all of them.
- **Long paragraphs** — Dense blocks of text in email render unreadable on mobile. Maximum 3 sentences per paragraph.
- **Promotional disguised as value** — Writing a "helpful tips" email where every tip leads to a paid product erodes trust permanently. When you are selling, be honest about it.
- **No preview text set** — Without intentional preview text, email clients pull the first line of the email or technical boilerplate. Always set the preview text explicitly.
- **Sending from "noreply@"** — This sender name signals that the relationship is one-way. Use a real name.
- **Subject line clickbait** — Overpromising in the subject and underdelivering in the body increases unsubscribes and spam complaints, which permanently damages deliverability.
- **Inconsistent cadence** — Sending 5 emails one week and disappearing for 3 weeks trains subscribers to ignore you. Consistency builds the open-rate habit.

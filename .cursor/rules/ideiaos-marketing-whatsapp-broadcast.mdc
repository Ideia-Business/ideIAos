---
name: "WhatsApp Broadcast"
platform: "whatsapp"
content_type: "broadcast"
description: "WhatsApp broadcast and group messages optimized for open rate, responses, and conversions in a high-trust channel"
whenToUse: |
  Creating agents that produce WhatsApp broadcast messages, group messages, or conversational marketing content for WhatsApp.
constraints:
  max_chars: 4096
  recommended_chars: "200-600"
  max_messages_per_sequence: 3
  format: "plain text, no markdown rendering"
  tone: "conversational, personal, direct"
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

## Platform Rules

- WhatsApp is a high-trust, high-intimacy channel. It is closer to SMS or a personal conversation than to social media or email. Broadcast messages must feel personal, not promotional.
- Open rates are typically 70-98% because of native push notifications and the personal context of the app. Click-through rates are correspondingly high when messages are relevant and conversational.
- WhatsApp Business API allows broadcasts to opted-in contacts. Non-opted-in broadcasts violate WhatsApp's terms of service and risk account bans.
- Markdown does NOT render as formatting in most WhatsApp contexts. Bold (**text**) renders as `**text**`, not bold, for many users. Write plain text that works without formatting.
- Exception: Some WhatsApp formatting does work in-app: *bold* (asterisks), _italic_ (underscores), ~strikethrough~ (tildes), `monospace` (backticks). Use sparingly. Keep messages primarily plain text.
- Frequency matters enormously. WhatsApp audiences are more sensitive to over-messaging than email lists. Maximum 1-2 broadcasts per week for most use cases. More than 3x/week causes significant opt-out rates.
- Replies to broadcasts go to the sender's DMs. Engage with every reply promptly — this is what sustains the channel's health.
- Messages with a single link get link previews that increase click visibility. Multiple links do not all get previews.

## Message Types

### Type 1: The Value Drop

**Use:** Sharing useful content, tips, or insights with no direct promotional intent. Builds the relationship and positions for future offers.

**Structure:**
1. Personal opener (1 sentence, casual and direct)
2. The value content (2-4 sentences or a short list)
3. Optional soft CTA or conversation starter

**Length:** 100-300 words

### Type 2: The Announcement

**Use:** Sharing news, launches, or important updates. Can be promotional if the contact has opted in for offers.

**Structure:**
1. Clear announcement statement (what it is, in plain terms)
2. Why it matters to this contact
3. One action: a link, a reply keyword, or a date to save

**Length:** 100-250 words

### Type 3: The Offer Message

**Use:** Directly presenting a product, service, or time-limited deal to opted-in contacts.

**Structure:**
1. Hook: The outcome or opportunity (not the product name)
2. The offer: What is available, the key benefit, the price or discount
3. Urgency: Genuine deadline or scarcity
4. Single CTA: One link or one reply keyword

**Length:** 150-350 words

### Type 4: The Conversation Starter

**Use:** Generating replies and direct conversations to warm up the channel or qualify leads.

**Structure:**
1. A direct question or statement that invites a personal response
2. Context for why you are asking (brief)
3. A clear response instruction ("Reply [word] if yes / [other word] if not")

**Length:** 50-150 words

## Writing Guidelines

- **Write in the first person, singular.** "I wanted to share this with you" outperforms "We at [Company] are pleased to inform you."
- **Address the contact directly.** Use their first name if the platform supports personalization. "Oi [Nome]," is the standard opener in Brazilian Portuguese.
- **Write short paragraphs.** WhatsApp renders text in a small mobile window. Blocks of more than 3 sentences look overwhelming. Break aggressively.
- **One message, one message.** Do not send 5 WhatsApp messages in rapid succession. Batch the content into the minimum number of messages. Maximum 3 messages in one sequence.
- **Never lead with the product or the brand name.** Lead with the person's outcome or situation. "Você está procurando..." not "A [empresa] tem o produto certo para..."
- **Avoid "marketing speak."** WhatsApp tone is like a message from a trusted friend who knows your situation. Formal, corporate language breaks the channel's trust contract.
- **Use emojis sparingly and purposefully.** 1-2 emojis to guide the eye or add warmth. Never use them as decoration.
- **Explicit opt-out instruction is required.** Include "Responda SAIR para sair da lista" or equivalent in the first message of any new broadcast sequence.

## Output Format

```
=== WHATSAPP BROADCAST ===

TYPE: [Value Drop / Announcement / Offer / Conversation Starter]
SEQUENCE: [Message 1 of X]

---

MESSAGE:

[Opener — first name personalization or direct relatable statement]

[Blank line]

[Core content — short paragraphs, plain text, max 3 sentences per paragraph]

[Blank line]

[CTA or conversation starter — one action only]

[Blank line]

[Optional: opt-out instruction if first message of a new sequence]
"Responda SAIR se não quiser mais receber mensagens assim."

---

=== MESSAGE METADATA ===
Type: [Value Drop / Announcement / Offer / Conversation Starter]
Sequence position: [X of Y]
Estimated read time: [X seconds]
Character count: [X of 4096]
Personalization tokens: [List any merge tags used, e.g., {first_name}]
Opt-out included: [Yes / No]
Link (if any): [URL — only one link per message for preview rendering]
Emoji count: [X — target 1-2 max]
```

## Quality Criteria

- [ ] Written in first person, singular — not corporate "we" language
- [ ] Opener is personal and direct — not a company name or formal greeting
- [ ] Paragraphs are 1-3 sentences maximum with blank lines between each
- [ ] Contains exactly one CTA or one clear action instruction
- [ ] Total character count is under 4,096 (ideally under 600 for mobile readability)
- [ ] Maximum one link in the message (for link preview rendering)
- [ ] Emoji count is 1-2 or zero — not decorative
- [ ] Opt-out instruction is included if this is the first message of a new broadcast sequence
- [ ] Tone is conversational, personal, and direct — no marketing speak
- [ ] For offer messages: urgency is genuine (real deadline or real scarcity)
- [ ] No unrendered markdown formatting (avoid **bold** text that renders as asterisks)

## Anti-Patterns

- **Corporate opener** — "A [Empresa] tem o prazer de informar..." is the fastest way to break the high-trust intimacy of WhatsApp. Write like a person.
- **Multiple CTAs** — "Clique aqui, responda SIM, ou acesse nosso site e também siga no Instagram" in one message overwhelms the reader. One action per message.
- **Multiple links** — More than one link prevents WhatsApp from rendering the preview. Include only one URL per message.
- **Spamming the contact** — Sending 5 short messages in rapid succession in WhatsApp feels like harassment. Write one good message, not five fragments.
- **Fake urgency** — "Últimas vagas!" when there are unlimited spots. WhatsApp is an intimate channel; fake urgency is immediately detected and destroys trust permanently.
- **No opt-out instruction** — Not giving contacts a clear way to exit the list increases block rates. Block rates damage WhatsApp Business account standing.
- **Emoji overload** — More than 3-4 emojis in a message reduces perceived professionalism significantly in a business context.
- **Sending to non-opted-in contacts** — Violates WhatsApp Business API terms. Risks permanent account ban. Only broadcast to contacts who have explicitly opted in.
- **Ignoring replies** — WhatsApp broadcasts that generate replies and receive no response kill the channel's health rapidly. Engage with every reply within hours.

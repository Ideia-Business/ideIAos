---
id: technical-writing
name: "Technical & Long-Form Writing"
whenToUse: |
  Creating agents that write articles, blog posts, documentation, tutorials,
  white papers, case studies, or educational content.
  NOT for: short-form persuasive copy, research, data analysis, strategic planning.
version: "1.0.0"
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

# Technical & Long-Form Writing — Best Practices

## Core Principles

1. **Clarity over cleverness.** Use simple, direct language. Choose concrete examples over abstract explanations. If a twelve-year-old cannot understand your sentence structure, rewrite it. Technical content does not require complicated prose.

2. **Structure first, always.** Never write without an outline. The outline is the skeleton that holds everything together. Define your sections, their order, and their purpose before drafting a single paragraph. Share the outline for approval before proceeding to the full draft.

3. **Evidence-based arguments.** Every claim needs support. Cite sources, reference data, quote experts, or provide concrete examples. Unsupported assertions undermine credibility. When exact data is unavailable, say so explicitly rather than fabricating statistics.

4. **Progressive disclosure.** Start simple, build complexity. Introduce concepts in layers so readers can follow regardless of their starting knowledge level. The first paragraph of each section should be accessible; depth increases as the section progresses.

5. **Accessibility without compromise.** Never use jargon without defining it on first use. Acronyms get spelled out the first time. Technical terms receive inline definitions or parenthetical explanations. Accessibility does not mean dumbing down; it means removing unnecessary barriers.

6. **Completeness within scope.** Cover the topic thoroughly within the defined boundaries. If a topic requires more depth than the current format allows, flag it and recommend a follow-up piece or a series. Never leave obvious questions unanswered.

7. **Audience-appropriate depth.** A tutorial for beginners requires different depth than a white paper for CTOs. Assess the audience before writing and calibrate vocabulary, example complexity, and assumed knowledge accordingly. When in doubt, err on the side of more explanation, not less.

8. **Scannable structure.** Use subheadings, bullet points, numbered lists, bold key terms, and short paragraphs. Readers scan before they read. Make scanning productive by ensuring subheadings communicate the key point of each section.

9. **Actionable takeaways.** Every piece should leave the reader with something they can do. A blog post should end with next steps. A tutorial should produce a working result. A white paper should inform a decision. Content without action is content without purpose.

## Writing Methodology

### Step 1: Load Context

Gather all inputs before writing anything. Required context includes:
- Topic definition and scope boundaries
- Target audience (role, expertise level, goals)
- Brand voice guidelines (if available)
- Research brief or source materials (from researcher agent)
- Content format (blog post, tutorial, documentation, white paper)
- Target word count or depth expectations
- Any existing content on the topic to avoid duplication

### Step 2: Create Outline

Build a detailed outline that maps the argument or teaching progression:
- Define the hook (why should the reader care right now?)
- Map sections to a logical flow (chronological, problem-solution, simple-to-complex)
- Assign approximate word counts per section
- Identify where evidence, examples, and visuals are needed
- Mark sections that may need additional research
- Present the outline for approval before proceeding

### Step 3: Draft Introduction

Write the introduction with three components:
- **Hook:** A concrete scenario, surprising statistic, or relatable problem that pulls the reader in
- **Promise:** A clear statement of what the reader will learn or gain
- **Roadmap:** A brief preview of the article structure so the reader knows what to expect

### Step 4: Write Body Sections

Draft one section at a time, following the approved outline:
- Open each section with a clear topic sentence
- Support claims with evidence (data, citations, examples)
- Include at least one concrete example per section
- Use transitional phrases between paragraphs and sections
- Add subheadings every 200-300 words
- Keep paragraphs under 4-5 sentences

### Step 5: Draft Conclusion

Write a conclusion that delivers on the introduction's promise:
- Summarize key points without repeating them verbatim
- Provide an actionable takeaway the reader can implement immediately
- If appropriate, point to next steps or related resources
- End on a forward-looking or motivating note, not a summary rehash

### Step 6: Self-Review

Review the complete draft against quality criteria:
- Read the full piece for flow and coherence
- Check that every section delivers on its outline promise
- Verify all claims have supporting evidence
- Confirm no jargon is used without definition
- Validate subheading frequency and readability
- Ensure the introduction's promise matches the conclusion's delivery
- Check reading level appropriateness for the target audience

### Step 7: Compile with Metadata

Prepare the final output with all required metadata:
- Title (compelling, specific, keyword-aware)
- Subtitle or deck (one-sentence summary)
- Meta description (for SEO, 150-160 characters)
- Suggested tags or categories
- Estimated reading time
- The complete article body

## Decision Criteria

- **When to add examples vs. move on:** Add an example whenever a concept is abstract, counterintuitive, or new to the target audience. Move on when the point is concrete and self-evident.
- **When depth is sufficient:** Depth is sufficient when a reader at the target expertise level can act on the information without needing to consult another source for the same concept.
- **When to recommend splitting into a series:** If the outline exceeds the target word count by more than 30%, or if two or more sections could stand alone as complete articles, recommend a series.
- **When to use lists vs. prose:** Use lists for sequential steps, parallel items, or scannable reference material. Use prose for narrative flow, argumentation, and context-setting.
- **When to recommend visuals:** Recommend a diagram, screenshot, or illustration whenever a concept involves spatial relationships, multi-step processes, or comparisons across three or more items.

## Quality Criteria

Before delivering any piece of content, verify the following:

- [ ] **Clear structure.** The piece has a defined introduction, body sections, and conclusion. The reader can predict the flow from the introduction.
- [ ] **Examples in every section.** Each body section contains at least one concrete example, code snippet, scenario, or case reference.
- [ ] **No undefined jargon.** Every technical term, acronym, or domain-specific phrase is defined on first use.
- [ ] **Appropriate subheading frequency.** No section runs longer than 300 words without a subheading or visual break.
- [ ] **Evidence-backed claims.** Quantitative claims reference a source. Qualitative claims are supported by examples or expert references.
- [ ] **Actionable takeaway present.** The piece ends with specific next steps, recommendations, or actions the reader can take.
- [ ] **Reading level matches audience.** A beginner tutorial reads at a lower complexity than a white paper for senior engineers. Vocabulary and assumed knowledge align with the target audience.
- [ ] **Word count matches format.** Blog posts: 800-2,000 words. Tutorials: 1,500-3,000 words. White papers: 3,000-6,000 words. Documentation pages: 500-1,500 words.
- [ ] **No em dashes.** The entire output has been checked for em dashes and none are present.
- [ ] **Introduction promise matches conclusion delivery.** Whatever the introduction says the reader will learn, the conclusion confirms they learned it.
- [ ] **Transitions between sections.** Each section connects logically to the next. The reader never wonders "why am I reading this now?"
- [ ] **Metadata complete.** Title, meta description, tags, and estimated reading time are all provided with the final draft.

## Anti-Patterns

### Never Do

1. **Write without an outline.** Drafting without structure leads to meandering content, redundant sections, and missing coverage. Always outline first, get approval, then write.

2. **Use jargon without definition.** Every undefined technical term is a potential exit point for the reader. Define terms inline on first use, even if you think the audience "should know."

3. **Exceed scope without flagging.** If writing reveals that the topic needs more coverage than planned, stop and flag it. Recommend a follow-up piece or series rather than inflating the current piece beyond its intended scope.

4. **Write walls of text without subheadings.** More than 300 words without a visual break (subheading, list, code block, or image) signals that the content needs restructuring.

5. **Make claims without evidence.** Statements like "most developers prefer" or "this approach is faster" require supporting data, a citation, or at minimum a concrete example. Unsupported claims erode trust.

6. **Use em dashes anywhere in the output.** Replace every em dash with a comma, period, colon, or parenthetical. This is a non-negotiable formatting rule.

7. **Start sections with definitions.** "Authentication is the process of..." is the weakest possible opening. Start with a problem, scenario, or consequence, then introduce the concept as the solution.

8. **Repeat the same point in different words.** If you have said it clearly once, move forward. Repetition for emphasis works in speeches, not in written content.

### Always Do

1. **Include at least one concrete example in every section.** Abstract explanations without examples leave readers uncertain about practical application. Examples bridge the gap between theory and practice.

2. **Define technical terms on first use.** Use inline definitions (parenthetical or appositive) to keep the reader moving without requiring them to look things up externally.

3. **Use subheadings every 200-300 words.** Subheadings serve two purposes: they help scanners find relevant sections, and they help readers track their progress through the piece.

4. **Provide actionable takeaways.** Every article, tutorial, or guide should end with something the reader can do next. If your content does not change behavior or inform a decision, reconsider its purpose.

5. **Front-load key information.** Put the most important point of each section in the first sentence. Readers who scan will still absorb the core message.

6. **Use parallel structure in lists.** Every item in a list should follow the same grammatical pattern. Mixing verb forms, sentence fragments, and complete sentences within a single list creates cognitive friction.

## Vocabulary Guidance

### Use

- **Concrete examples** to anchor abstract concepts: "For instance, if your API returns a 429 status code, that means..."
- **Scenario-based framing** to build relevance: "Consider this scenario: your team just shipped a feature and usage spikes overnight..."
- **Transitional phrases** to maintain flow between paragraphs and sections: "Building on this foundation...", "With that context in mind...", "This brings us to..."
- **Active voice** as the default for direct, clear communication: "The function validates the input" not "The input is validated by the function."
- **Specific numbers and data** over vague qualifiers: "Reduced load time by 40%" not "Significantly improved performance."
- **Reader-addressing language** to maintain engagement: "You will notice...", "At this point, you have...", "Your next step is..."
- **Short sentences for key points.** When stating something important, keep it brief. Let the sentence stand alone.

### Avoid

- **Jargon without definition.** If a term requires domain knowledge, define it inline on first use. No exceptions.
- **Em dashes.** Do not use em dashes in any output. They are the most recognizable marker of AI-generated text. Use commas, periods, parentheses, or colons instead.
- **Filler phrases.** Remove "It's important to note that...", "It goes without saying...", "Needless to say...", "At the end of the day...", "In today's world..." These add no information.
- **Passive voice without reason.** Use passive voice only when the actor is genuinely unknown or irrelevant. Otherwise, name the subject.
- **"In conclusion" or "To summarize."** The conclusion should feel like a natural landing, not an announcement. Show the ending through content, not labels.
- **Walls of text.** Never write more than 300 words without a subheading, list, or visual break. Dense paragraphs lose readers.
- **Rhetorical questions as filler.** Only use a question when you immediately answer it and the answer drives the narrative forward.
- **Exclamation marks.** Professional content earns enthusiasm through substance, not punctuation.

### Tone Rules

1. **Authoritative but approachable.** Write like a senior colleague explaining something to a motivated junior, not like a professor lecturing a class. Confidence without condescension.
2. **Educational without patronizing.** Assume the reader is intelligent but may lack specific domain knowledge. Explain concepts, not because the reader is incapable, but because the topic is genuinely complex.
3. **Evidence-driven, not opinion-driven.** State facts, cite sources, present data. When offering an opinion or recommendation, label it clearly: "Based on these results, we recommend..." or "In our experience..."
4. **Calm and measured.** Avoid hype, urgency, or sensationalism. Let the content's value speak for itself. "This approach reduces errors by 60%" is more persuasive than "This game-changing approach will revolutionize your workflow."

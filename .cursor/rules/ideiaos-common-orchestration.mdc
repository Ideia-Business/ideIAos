<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->
# Orchestration Rules

## Iterative Retrieval (Subagent Loops)

When an orchestrator spawns a subagent for research/lookup:
1. Subagent returns result
2. Orchestrator evaluates: is the result sufficient? Yes → proceed; No → follow-up query
3. Max 3 retrieval cycles per question before escalating or abandoning
4. Pass goal + specific query to subagent, NOT prescribed steps — let it decide the method

## Sequential Phases with Output Files

Long tasks must be broken into phases with output written to files between phases:
- Phase boundary = compact opportunity
- Each phase reads the output file of the previous phase, not the conversation
- Never rely on conversation memory across >2 phase transitions

## Minimum Viable Parallelization

Parallelize when: tasks are truly independent AND both would take >30s alone.
Do NOT parallelize: tasks that share mutable files, tasks that need each other's output.
Rule: Tier 1 (subagents, metaprompting) before Tier 2 (multi-agent parallel).

## Wave-Based Execution (GSD Pattern)

Wave 1: independent tasks in parallel (each gets fresh context).
Wave 2: integration tasks that depend on Wave 1 output.
Never mix independent and dependent tasks in the same wave.

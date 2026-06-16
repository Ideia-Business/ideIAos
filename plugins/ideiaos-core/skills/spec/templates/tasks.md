# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Tasks: <slug-da-mudanca>

**Change:** <slug-da-mudanca>
**Capability(ies):** <lista de capabilities afetadas>
**Gerado em:** <AAAA-MM-DD>

Estas tasks derivam do delta e são consumíveis pelo GSD (`/gsd-execute-phase`) ou pelo `@dev` do AIOX.
Formato: `- [ ] N.M <descrição` onde N = grupo, M = subtask sequencial.

---

## 1. Preparação

- [ ] 1.1 Ler a proposta em `specs/_changes/<slug>/proposta.md` e confirmar escopo
- [ ] 1.2 Verificar dependências: capabilities afetadas estão estáveis?
- [ ] 1.3 <tarefa de preparação específica desta change>

---

## 2. Implementação

- [ ] 2.1 <primeira tarefa de implementação — o que precisa ser feito no código>
- [ ] 2.2 <segunda tarefa — manter atômico e testável>
- [ ] 2.3 <adicionar mais subtasks conforme necessário>

---

## 3. Testes

- [ ] 3.1 Cobrir o(s) cenário(s) ADICIONADO(s) com testes automatizados
- [ ] 3.2 Atualizar testes existentes para refletir MODIFICADO(s)
- [ ] 3.3 Confirmar que testes de REMOVIDO(s) foram removidos ou adaptados
- [ ] 3.4 Rodar suite completa e garantir green

---

## 4. Merge e Archive

- [ ] 4.1 Validar delta: `bash source/skills/spec/lib/spec-validate.sh specs/_changes/<slug>`
- [ ] 4.2 Aplicar merge: `bash source/skills/spec/lib/spec-merge.sh <produto-root> <slug> --yes`
- [ ] 4.3 Confirmar archive em `specs/_archive/<AAAA-MM-DD>-<slug>/`
- [ ] 4.4 Commit com mensagem: `spec(<capability>): apply <slug> delta`

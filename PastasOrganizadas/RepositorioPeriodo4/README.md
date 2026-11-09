# Jacaré Mecânica – Banco de Dados PostgreSQL

Banco de dados de um sistema integrado de gestão para a **Jacaré Mecânica**, uma oficina e loja de autopeças. Ele cobre o catálogo de peças e a compatibilidade com os veículos, a operação da oficina (ordens de serviço e estoque) e a parte contábil e fiscal. O banco foi migrado do MySQL para o PostgreSQL e dividido em três schemas: **`site`**, **`adm`** e **`contabil`**.

**Projeto Integrador IV** – Sistemas de Informação – Doctum Cataguases
**Professor:** Márcio Magalhães
**Equipe:** Rogério, Renan, Davi, Lukas e Anderson

---

## 📂 Estrutura do repositório

```
├── README.md
├── scripts/
│   ├── PiEnt2.sql          script completo: estrutura, dados de teste, views e Práticas 03 e 05
│   ├── 01_site.sql         só a estrutura do schema site
│   ├── 02_adm.sql          só a estrutura do schema adm
│   ├── 03_contabil.sql     só a estrutura do schema contabil
│   └── testes/
│       ├── rodar_testes.sh   roda toda a bateria e grava os logs em testes/resultados/
│       ├── testes.sql        53 testes funcionais (integridade, trigger, views, dados, práticas)
│       ├── teste_carga.sql   teste de carga com 100 mil lançamentos
│       └── um_lancamento.sql transação usada no pgbench
└── docs/
    ├── Artigo_Jacare_Mecanica.docx
    └── Slides_PI_Entrega02_Jacare_Mecanica.pdf
```

---

## 🚀 Como executar

Testado no **PostgreSQL 16**.

### Opção 1: banco completo (recomendada)

O `PiEnt2.sql` cria tudo num banco vazio, de uma vez só: os schemas, as tabelas, os dados de teste, as views, a carga da Prática 03 e o trigger da Prática 05.

```bash
createdb jacare_mecanica
psql -d jacare_mecanica -f scripts/PiEnt2.sql
```

No fim da execução, o script mostra as consultas de conferência. Todas devem dar `ok`, e os saldos devem fechar em **39.000 devedor = 39.000 credor**.

### Opção 2: só a estrutura, schema por schema

```bash
psql -d jacare_mecanica -f scripts/01_site.sql
psql -d jacare_mecanica -f scripts/02_adm.sql
psql -d jacare_mecanica -f scripts/03_contabil.sql
```

**A ordem importa**, porque há chaves estrangeiras entre os schemas:

- `adm.movimentacao_estoque` aponta para `site.peca`, então `site` vem antes de `adm`;
- `contabil.nota_fiscal` aponta para `adm.ordem_servico` e `adm.fornecedor`, então `adm` vem antes de `contabil`.

Se a ordem for invertida, o PostgreSQL recusa a criação das tabelas (`relation does not exist`).

> O `PiEnt2.sql` não foi feito para rodar duas vezes no mesmo banco, porque os `CREATE TABLE` não têm `IF NOT EXISTS`. Para recriar, apague e crie o banco de novo. Já os blocos das Práticas 03 e 05 podem ser executados de novo sem duplicar dados.

---

## 📋 Schemas e tabelas

### `site` – catálogo e compatibilidade
| Tabela | O que guarda |
|---|---|
| `marca` | marcas de veículos (Volkswagen, Chevrolet, Fiat…) |
| `modelo` | modelos de cada marca |
| `veiculo` | ano, motorização e combustível de cada modelo |
| `categoria` | categorias de peças (freios, motor, suspensão…) |
| `peca` | peças à venda, com preço, fabricante e quantidade em estoque |
| `compatibilidade` | quais peças servem em quais veículos, com posição e observações |

### `adm` – oficina e estoque
| Tabela | O que guarda |
|---|---|
| `funcionario` | funcionários da oficina |
| `fornecedor` | fornecedores de peças |
| `ordem_servico` | OS abertas para os clientes, com funcionário responsável, status e valor total |
| `item_ordem_servico` | serviços e peças de cada OS (o valor total da OS é a soma dos itens) |
| `movimentacao_estoque` | entradas, saídas e ajustes de estoque das peças |

### `contabil` – financeiro e fiscal
| Tabela | O que guarda |
|---|---|
| `plano_contas` | as 23 contas contábeis, com tipo e natureza (ENUMs) |
| `lancamentos` | lançamentos contábeis por partidas dobradas (conta de débito, conta de crédito, valor) |
| `saldo_contas` | saldo atual de cada conta, mantido pelo trigger |
| `nota_fiscal` | notas de entrada (compras) e de saída (vendas e OS) |
| `conta_pagar_receber` | títulos a pagar e a receber, ligados a uma nota e a uma conta |
| `lancamento_financeiro` | pagamentos e recebimentos efetivados de cada título |
| `fechamento_mensal` | totais do mês: receitas, despesas e impostos, calculados a partir das notas |

---

## 🔒 Regras de integridade

### Valores permitidos
| Onde | Regra |
|---|---|
| `contabil.plano_contas.tipo_conta` | ENUM: `ATIVO`, `PASSIVO`, `PATRIMONIO_LIQUIDO`, `RECEITA`, `DESPESA` |
| `contabil.plano_contas.natureza_conta` | ENUM: `DEVEDORA`, `CREDORA` |
| `contabil.lancamentos.valor` | `CHECK (valor > 0)` |
| `site.peca.preco_venda` | `CHECK (preco_venda > 0)` |
| `adm.ordem_servico.status` | `Em Aberto` (padrão), `Em Andamento`, `Concluída`, `Cancelada` |
| `adm.movimentacao_estoque.tipo_movimentacao` | `ENTRADA`, `SAIDA`, `AJUSTE` |
| `adm.movimentacao_estoque.quantidade` | `CHECK (quantidade > 0)` |
| `contabil.nota_fiscal.tipo_operacao` | `ENTRADA`, `SAIDA` |
| `contabil.conta_pagar_receber.tipo` / `status` | `PAGAR`, `RECEBER` / `PENDENTE` (padrão), `PAGO`, `CANCELADO` |
| `contabil.fechamento_mensal.mes_referencia` | entre 1 e 12, com um único fechamento por mês e ano (`UNIQUE`) |
| `adm.funcionario.cpf`, `adm.fornecedor.cnpj`, `contabil.plano_contas.codigo_conta` | `UNIQUE` |

### O que acontece ao apagar um registro (`ON DELETE`)
| Relação | Regra | Por quê |
|---|---|---|
| `modelo → marca`, `veiculo → modelo` | **CASCADE** | um modelo não existe sem a marca, nem um veículo sem o modelo |
| `compatibilidade → peca / veiculo` | **CASCADE** | a compatibilidade só faz sentido enquanto a peça e o veículo existem |
| `item_ordem_servico → ordem_servico` | **CASCADE** | os itens são parte da OS; apagar a OS apaga os itens |
| `lancamento_financeiro → conta_pagar_receber` | **CASCADE** | o pagamento pertence ao título |
| `saldo_contas → plano_contas` | **CASCADE** | o saldo é um dado derivado da conta |
| `peca → categoria` | **SET NULL** | a peça continua à venda, só fica sem categoria |
| `ordem_servico → funcionario` | **SET NULL** | a OS é histórico do cliente e deve continuar mesmo se o funcionário sair |
| `movimentacao_estoque → fornecedor`, `nota_fiscal → fornecedor / ordem_servico`, `conta_pagar_receber → nota_fiscal` | **SET NULL** | o registro financeiro ou de estoque precisa ser mantido mesmo sem a origem |
| `movimentacao_estoque → peca` | **RESTRICT** | uma peça com histórico de estoque não pode sumir |
| `lancamentos → plano_contas`, `conta_pagar_receber → plano_contas` | **RESTRICT** | uma conta com lançamentos ou títulos não pode ser apagada; isso quebraria a contabilidade |

---

## 👁️ Views

| View | Tipo de JOIN | O que responde |
|---|---|---|
| `site.vw_carros` | INNER JOIN | catálogo completo: marca, modelo, ano, motorização e combustível de cada veículo |
| `site.vw_revisao_carros` | INNER JOIN | quais peças servem em cada veículo, com fabricante, posição e observações (veículos sem peça compatível não aparecem) |
| `adm.vw_gerenciamento_cliente` | LEFT JOIN | cada OS com cliente, veículo, status, itens e funcionário (uma linha por item; uma OS sem itens também aparece, com o item vazio) |

---

## 📚 Práticas

### Prática 01 – Modelo do plano de contas
`tipo_conta` e `natureza_conta` são **ENUMs**, então o banco só aceita os valores previstos. A tabela `lancamentos` registra cada fato contábil pelas partidas dobradas: uma conta de débito, uma de crédito e o valor.

### Prática 03 – Carga e normalização dos lançamentos de março
O script cadastra as **23 contas** da prática:

| Tipo | Contas |
|---|---|
| Ativo | 6 |
| Passivo | 4 |
| Patrimônio líquido | 2 |
| Receita | 2 |
| Despesa | 9 |

Em seguida, carrega os **53 lançamentos de março**, que chegaram "sujos": uma data com hífen (`05-03-2026`), nomes de conta com maiúsculas e espaços diferentes ("CAIXA") e apelidos como "Bancos", "Fornecedor" e "CMV".

O tratamento funciona assim:

1. os dados entram primeiro numa tabela temporária, como texto;
2. uma função liga cada nome à conta certa, ignorando maiúsculas e espaços e usando uma tabela de apelidos;
3. o hífen das datas vira barra, e elas são convertidas com `to_date`.

O modelo da Prática 01 não tem a coluna `valor`, então esses lançamentos entram sem valor e não mexem nos saldos da Prática 05.

O único lançamento sem conta de crédito é o de 31/03, que já veio vazio na planilha.

### Prática 05 – Trigger de saldo automático
A função `contabil.fn_atualiza_saldo()` e o trigger `trg_atualiza_saldo` (`AFTER INSERT … FOR EACH ROW`) atualizam a tabela `saldo_contas` a cada novo lançamento, de acordo com a natureza de cada conta:

| Conta | Lado do lançamento | Efeito no saldo |
|---|---|---|
| devedora | debitada | aumenta |
| devedora | creditada | diminui |
| credora | creditada | aumenta |
| credora | debitada | diminui |

Saldos depois dos 6 lançamentos de teste:

| Conta | Natureza | Saldo |
|---|---|---|
| 1.1.01 Caixa | devedora | 5.000,00 |
| 1.1.02 Bancos - Conta Movimento | devedora | 20.500,00 |
| 1.1.04 Estoque de Mercadorias | devedora | 9.000,00 |
| 5.1.01 Custo das Mercadorias Vendidas | devedora | 3.000,00 |
| 5.1.03 Despesas com Aluguel | devedora | 1.500,00 |
| 2.1.01 Fornecedores a Pagar | credora | 4.000,00 |
| 3.1.01 Capital Social | credora | 30.000,00 |
| 4.1.01 Receita de Vendas | credora | 5.000,00 |
| **Total** | | **39.000 devedor = 39.000 credor** |

**Exclusão e alteração (atividade 9):** o trigger só trata `INSERT`, então um `DELETE` ou um `UPDATE` em `lancamentos` não refaz os saldos. Há duas soluções, comentadas no fim do script:

- ampliar o trigger para `AFTER INSERT OR UPDATE OR DELETE`, desfazendo o efeito de `OLD` e aplicando o de `NEW`;
- corrigir sempre com um **lançamento de estorno**, que é a prática contábil.

---

## 🧪 Testes

```bash
cd scripts/testes
PGUSER=postgres PGHOST=localhost ./rodar_testes.sh
```

O script cria bancos temporários com o prefixo `jm_teste_` e grava os logs em `scripts/testes/resultados/`. Ele precisa do `psql`, do `createdb` e do `pgbench`, que já vêm com o PostgreSQL.

### Resultado
| Verificação | Resultado |
|---|---|
| `01_site → 02_adm → 03_contabil` | 0 erros |
| `03_contabil` antes de `02_adm` | recusado, como esperado |
| `PiEnt2.sql` num banco vazio | 0 erros, nenhuma conferência divergente |
| Reexecução das Práticas 03 e 05 | 0 erros, saldos iguais (39.000 = 39.000) |
| Testes funcionais (`testes.sql`) | **53 testes: 49 passaram, 4 limitações confirmadas, 0 falhas** |

| Categoria | Testes |
|---|---|
| 1. Integridade (CHECK, ENUM, UNIQUE, NOT NULL, chaves estrangeiras, CASCADE / SET NULL / RESTRICT, DEFAULT, SERIAL) | 26 |
| 2. Trigger (os 4 casos de natureza, várias linhas num INSERT, partidas dobradas, saldo guardado = recalculado) | 12 |
| 3. Views (INNER × LEFT JOIN, atualização automática) | 6 |
| 4. Dados de teste (OS = soma dos itens, estoque = movimentações, título = nota, fechamento = notas) | 4 |
| 5. Práticas 01 e 03 (23 contas, natureza × tipo, 53 lançamentos, nomes normalizados) | 5 |

### Teste de carga
| Medição | Tempo (mediana) |
|---|---|
| 1 lançamento por transação, **com** trigger (pgbench) | ~1,3 ms |
| 1 lançamento por transação, **sem** trigger | ~0,4 ms |
| saldo de Bancos lendo `saldo_contas` (100 mil lançamentos) | 0,03 ms |
| saldo de Bancos somando os lançamentos, sem índice | 12,9 ms |
| saldo de Bancos somando os lançamentos, com índice | 8,8 ms |
| 100 mil lançamentos numa única transação, sem trigger | ~1,1 s |
| 100 mil lançamentos numa única transação, com trigger | ~118 s |

Ler o saldo pronto é centenas de vezes mais rápido que somar os lançamentos, e é isso que justifica a tabela `saldo_contas`. No uso normal, com um lançamento por vez, o trigger custa menos de 1 ms a mais.

Em cargas grandes numa única transação, o tempo cresce mais rápido que a quantidade de lançamentos. O trigger atualiza as mesmas poucas linhas de `saldo_contas` milhares de vezes, e cada atualização deixa uma versão antiga da linha que só é limpa depois. Para importações em massa, o indicado é desligar o trigger, carregar os dados e recalcular os saldos de uma vez.

### Limitações conhecidas (confirmadas pelos testes)
- `UPDATE` e `DELETE` em `lancamentos` não refazem os saldos (ver atividade 9 acima).
- Um lançamento com `valor` vazio é gravado, mas não altera nenhum saldo.
- Um lançamento com só uma das contas preenchida altera só um lado, e os totais devedor e credor deixam de bater.
- No PostgreSQL, chave estrangeira não cria índice sozinha (no MySQL, cria). Os índices em `conta_debito_id` e `conta_credito_id` são criados apenas no teste de carga.

---

## 📌 Pendências

- [ ] Modelos conceitual e lógico no brModelo, a serem colocados em `docs/`.

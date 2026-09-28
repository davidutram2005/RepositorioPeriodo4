# Documentação do Sistema de Gestão (Banco de Dados PostgreSQL)

Este repositório contém os scripts SQL para a criação da estrutura de banco de dados relacional de um sistema integrado de gestão (oficina/comércio automotivo), dividido em três esquemas principais: **`site`**, **`adm`** e **`contabil`**.

---

## 🛠️ Tecnologias Utilizadas
* **SGBD:** PostgreSQL
* **Linguagem:** SQL (DDL)

---

## 📂 Estrutura dos Esquemas

O banco de dados é modularizado através de schemas do PostgreSQL para separar as responsabilidades do sistema:

1. **`site`**: Gerencia o catálogo de veículos, marcas, modelos, categorias, peças e compatibilidade de peças com os automóveis.
2. **`adm`**: Gerencia a parte administrativa operacional, incluindo funcionários, fornecedores, ordens de serviço (OS) e movimentações de estoque.
3. **`contabil`**: Controla a parte financeira e fiscal, abrangendo plano de contas, notas fiscais, contas a pagar/receber, lançamentos e fechamento mensal.

---

## 📋 Descrição das Tabelas por Schema

### 1. Schema `site` (Catálogo e Produtos)
* **`marca`**: Armazena as marcas dos veículos (ex: Fiat, Volkswagen, Chevrolet).
* **`modelo`**: Vincula os modelos de veículos às suas respectivas marcas.
* **`veiculo`**: Detalha especificações dos veículos como ano de fabricação, motorização e combustível.
* **`categoria`**: Categorias para classificação das peças (ex: Suspensão, Freios, Motor).
* **`peca`**: Cadastro de peças disponíveis, contendo preço de venda, quantidade em estoque e dados do fabricante.
* **`compatibilidade`**: Tabela associativa que relaciona quais peças são compatíveis com quais veículos, incluindo posição de aplicação e observações.

### 2. Schema `adm` (Administrativo e Operacional)
* **`funcionario`**: Cadastro dos colaboradores da empresa.
* **`fornecedor`**: Cadastro de fornecedores de peças e serviços.
* **`ordem_servico`**: Registra as ordens de serviço abertas para os clientes, vinculando um funcionário responsável, dados do veículo e status da OS.
* **`item_ordem_servico`**: Itens (serviços ou peças) adicionados a uma ordem de serviço específica.
* **`movimentacao_estoque`**: Registra as entradas, saídas e ajustes de estoque das peças cadastradas no schema `site`.

### 3. Schema `contabil` (Financeiro e Fiscal)
* **`plano_contas`**: Estrutura contábil dividida por tipos (`RECEITA`, `DESPESA`, `ATIVO`, `PASSIVO`).
* **`nota_fiscal`**: Emissão e controle de notas fiscais de entrada e saída, podendo estar vinculada a uma OS ou fornecedor.
* **`conta_pagar_receber`**: Títulos financeiros a pagar ou a receber, vinculados ao plano de contas e notas fiscais.
* **`lancamento_financeiro`**: Registra os pagamentos/recebimentos efetivados associados aos títulos.
* **`fechamento_mensal`**: Consolidado financeiro mensal contendo total de receitas, despesas, impostos devidos e status do período.

---

## 🚀 Como Executar

Para criar a estrutura corretamente no PostgreSQL, execute os arquivos na ordem de dependência (já que o schema `adm` possui chave estrangeira apontando para o schema `site`):

1. **Executar primeiro:** `site.SQL`
2. **Executar em seguida:** `adm.SQL`
3. **Por fim:** `contabil.SQL`

```bash
psql -U seu_usuario -d seu_banco -f site.SQL
psql -U seu_usuario -d seu_banco -f adm.SQL
psql -U seu_usuario -d seu_banco -f contabil.SQL
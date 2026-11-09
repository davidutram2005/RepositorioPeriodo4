#!/usr/bin/env bash
# ============================================================================
# Roda todos os testes do projeto Jacaré Mecânica e grava o resultado em ./resultados/
#
# Uso (dentro da pasta scripts/testes, com o PostgreSQL rodando):
#   PGUSER=postgres PGHOST=localhost ./rodar_testes.sh
# Usa os scripts da pasta de cima (scripts/): 01_site.sql, 02_adm.sql,
# 03_contabil.sql e PiEnt2.sql; e os desta pasta: testes.sql,
# teste_carga.sql e um_lancamento.sql. Precisa do pgbench (vem com o PostgreSQL).
# Cria e apaga bancos temporários com o prefixo jm_teste_.
# ============================================================================
set -u
cd "$(dirname "$0")"
SCRIPTS=..
OUT=resultados
mkdir -p "$OUT"
PSQL="psql -X -q -v ON_ERROR_STOP=0"

novo_banco() { dropdb --if-exists "$1" 2>/dev/null; createdb "$1"; }
erros() { grep -c "ERROR" "$1" || true; }

echo "== 1. Ordem de execução correta: 01_site -> 02_adm -> 03_contabil =="
novo_banco jm_teste_ordem
for f in 01_site 02_adm 03_contabil; do $PSQL -d jm_teste_ordem -f "$SCRIPTS/$f.sql"; done > "$OUT/1_ordem_correta.log" 2>&1
echo "erros: $(erros "$OUT/1_ordem_correta.log") (esperado: 0)"

echo "== 2. Ordem errada: contabil antes de adm =="
novo_banco jm_teste_ordem_errada
for f in 01_site 03_contabil; do $PSQL -d jm_teste_ordem_errada -f "$SCRIPTS/$f.sql"; done > "$OUT/2_ordem_errada.log" 2>&1
echo "erros: $(erros "$OUT/2_ordem_errada.log") (esperado: maior que 0)"
grep -m1 "ERROR" "$OUT/2_ordem_errada.log"

echo "== 3. PiEnt2.sql executado inteiro num banco vazio =="
novo_banco jm_teste_principal
$PSQL -d jm_teste_principal -f "$SCRIPTS/PiEnt2.sql" > "$OUT/3_pient2.log" 2>&1
echo "erros: $(erros "$OUT/3_pient2.log") (esperado: 0)"
echo "conferências com DIVERGENTE: $(grep -c DIVERGENTE "$OUT/3_pient2.log") (esperado: 0)"

echo "== 4. Testes funcionais (integridade, trigger, views, dados) =="
$PSQL -d jm_teste_principal -f testes.sql > "$OUT/4_testes_funcionais.log" 2>&1
$PSQL -d jm_teste_principal -A -F '|' -c "SELECT id, categoria, status, teste, esperado, obtido FROM teste.resultados ORDER BY id" > "$OUT/4_testes_funcionais.csv"
$PSQL -d jm_teste_principal -c "SELECT status, count(*) FROM teste.resultados GROUP BY status ORDER BY status"

echo "== 5. Reexecução das Práticas 03 e 05 (deve dar o mesmo resultado) =="
sed -n '/^-- PRÁTICA 03/,$p' "$SCRIPTS/PiEnt2.sql" > "$OUT/_praticas.sql"
$PSQL -d jm_teste_principal -f "$OUT/_praticas.sql" > "$OUT/5_reexecucao_praticas.log" 2>&1
echo "erros: $(erros "$OUT/5_reexecucao_praticas.log") (esperado: 0)"
grep -E "DEVEDORA|CREDORA" "$OUT/5_reexecucao_praticas.log" | tail -2

echo "== 6. Reexecução do PiEnt2.sql inteiro (tabelas e ids já existem) =="
$PSQL -d jm_teste_principal -f "$SCRIPTS/PiEnt2.sql" > "$OUT/6_reexecucao_completa.log" 2>&1
echo "erros: $(erros "$OUT/6_reexecucao_completa.log") (esperado: maior que 0, CREATE TABLE sem IF NOT EXISTS)"

echo "== 7. Teste de carga (100 mil lançamentos) =="
novo_banco jm_teste_carga
$PSQL -d jm_teste_carga -f "$SCRIPTS/PiEnt2.sql" > /dev/null 2>&1
$PSQL -d jm_teste_carga -f teste_carga.sql > "$OUT/7_teste_carga.log" 2>&1
sed -n '/Resumo dos tempos/,$p' "$OUT/7_teste_carga.log"

echo "== 8. Um lançamento por transação (pgbench, 5 rodadas de 2000, com e sem trigger) =="
: > "$OUT/8_pgbench.log"
for r in 1 2 3 4 5; do
  $PSQL -d jm_teste_carga -c "ALTER TABLE contabil.lancamentos ENABLE TRIGGER trg_atualiza_saldo"
  echo "rodada $r COM trigger: $(pgbench -n -c 1 -t 2000 -f um_lancamento.sql jm_teste_carga 2>&1 | grep 'latency average')" | tee -a "$OUT/8_pgbench.log"
  $PSQL -d jm_teste_carga -c "ALTER TABLE contabil.lancamentos DISABLE TRIGGER trg_atualiza_saldo"
  echo "rodada $r SEM trigger: $(pgbench -n -c 1 -t 2000 -f um_lancamento.sql jm_teste_carga 2>&1 | grep 'latency average')" | tee -a "$OUT/8_pgbench.log"
done
$PSQL -d jm_teste_carga -c "ALTER TABLE contabil.lancamentos ENABLE TRIGGER trg_atualiza_saldo"

echo "Pronto. Logs em scripts/testes/$OUT/"

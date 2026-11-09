-- Usado pelo pgbench: um lançamento por transação (como um sistema real faria).
INSERT INTO contabil.lancamentos (data_lancamento, historico, conta_debito_id, conta_credito_id, valor)
VALUES (CURRENT_DATE, 'pgbench',
        (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '1.1.01'),
        (SELECT id_conta FROM contabil.plano_contas WHERE codigo_conta = '4.1.01'),
        100);

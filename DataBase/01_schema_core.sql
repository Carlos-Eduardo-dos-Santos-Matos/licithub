-- =====================================================================
-- modelo fisico licitacoes - MySQL 8.0.16+
-- ---------------------------------------------------------------------
-- pre-requisito no servidor:  default-time-zone = '+00:00'
--   tudo é gravado em UTC. A API de origem informa horário de Brasília.
-- convenções: utf8mb4; DECIMAL para dinheiro; TINYINT(1) para
--   booleano (mais performático); PK BIGINT; soft delete (excluido_em) só na empresa (a conta
--   do cliente); o login é bloqueado com usuario.ativo = 0.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS db_licitacoes
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE db_licitacoes;

-- "usuario" = credencial (quem autentica). "empresa" = entidade jurídica e
-- dona de todos os dados privados. Cadastro = um INSERT em usuario + um em empresa, na MESMA transação.

-- Se o backend usar ASP.NET Core Identity, esta tabela é mapeada para
-- AspNetUsers (tokens de confirmação e recuperação de senha do Identity
-- são stateless, por isso não há tabela de token).
CREATE TABLE usuario (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  email               VARCHAR(254)    NOT NULL COMMENT 'E-mail de LOGIN. Contatos da empresa ficam em empresa_email',
  senha_hash          VARCHAR(255)    NOT NULL,
  email_confirmado_em DATETIME        NULL,
  ativo               TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '0 = login bloqueado (conta excluída ou suspensa)',
  criado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuario_email (email)
);

CREATE TABLE empresa (
  id            BIGINT NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT          NOT NULL COMMENT 'Credencial de acesso desta empresa (1:1)',
  cnpj          CHAR(14)        NOT NULL COMMENT 'Sem máscara; 14 posições comportam o CNPJ alfanumérico',
  razao_social  VARCHAR(200)    NOT NULL,
  nome_fantasia VARCHAR(200)    NULL,
  porte         ENUM('MEI','ME','EPP','MEDIO','GRANDE') NOT NULL,
  criado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  excluido_em   DATETIME        NULL COMMENT 'Soft delete da conta. Ao excluir: usuario.ativo = 0 e anonimizar dados pessoais',
  PRIMARY KEY (id),
  UNIQUE KEY uq_empresa_usuario (usuario_id),
  UNIQUE KEY uq_empresa_cnpj (cnpj),
  CONSTRAINT fk_empresa_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id),
  CONSTRAINT ck_empresa_cnpj CHECK (cnpj REGEXP '^[0-9A-Za-z]{14}$')
);

-- Contatos da empresa. "principal_unico" (coluna gerada) + UNIQUE garante
-- no máximo UM principal por empresa: o MySQL não tem índice parcial, e
-- vários NULL são permitidos num UNIQUE. (if principal = 1, então principal_unico = 1; se não, então principal_unico = NULL.)
CREATE TABLE empresa_email (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT NOT NULL,
  email           VARCHAR(254)    NOT NULL,
  finalidade      ENUM('GERAL','FINANCEIRO','COMERCIAL','LICITACOES') NOT NULL DEFAULT 'GERAL',
  principal       TINYINT(1)      NOT NULL DEFAULT 0,
  principal_unico TINYINT GENERATED ALWAYS AS (IF(principal = 1, 1, NULL)) STORED,
  verificado_em   DATETIME        NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_empresa_email (empresa_id, email),
  UNIQUE KEY uq_empresa_email_principal (empresa_id, principal_unico),
  CONSTRAINT fk_ee_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (id)
);

CREATE TABLE empresa_telefone (
  id              BIGINT NOT NULL AUTO_INCREMENT,
  empresa_id      BIGINT NOT NULL,
  numero          VARCHAR(20)     NOT NULL COMMENT 'Somente dígitos, com DDD',
  tipo            ENUM('FIXO','CELULAR','WHATSAPP') NOT NULL DEFAULT 'CELULAR',
  principal       TINYINT(1)      NOT NULL DEFAULT 0,
  principal_unico TINYINT GENERATED ALWAYS AS (IF(principal = 1, 1, NULL)) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uq_empresa_telefone (empresa_id, numero),
  UNIQUE KEY uq_empresa_telefone_principal (empresa_id, principal_unico),
  CONSTRAINT fk_et_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (id)
);


CREATE TABLE cnae (
  codigo    CHAR(7)      NOT NULL COMMENT 'Subclasse sem pontuação, ex.: 6201501',
  descricao VARCHAR(255) NOT NULL,
  divisao   CHAR(2) GENERATED ALWAYS AS (LEFT(codigo, 2)) STORED,
  PRIMARY KEY (codigo),
  KEY ix_cnae_divisao (divisao)
);

-- Ponte CNAE -> texto da licitação. A licitação NÃO traz CNAE;
CREATE TABLE cnae_palavra_chave (
  id         BIGINT NOT NULL AUTO_INCREMENT,
  cnae_codigo CHAR(7)        NOT NULL,
  termo      VARCHAR(100)    NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cnae_termo (cnae_codigo, termo),
  CONSTRAINT fk_ckw_cnae FOREIGN KEY (cnae_codigo) REFERENCES cnae (codigo)
);

CREATE TABLE empresa_cnae (
  empresa_id      BIGINT NOT NULL,
  cnae_codigo     CHAR(7)         NOT NULL,
  principal       TINYINT(1)      NOT NULL DEFAULT 0,
  principal_unico TINYINT GENERATED ALWAYS AS (IF(principal = 1, 1, NULL)) STORED,
  PRIMARY KEY (empresa_id, cnae_codigo),
  UNIQUE KEY uq_empresa_cnae_principal (empresa_id, principal_unico),
  KEY ix_empresa_cnae_cnae (cnae_codigo),
  CONSTRAINT fk_ec_empresa FOREIGN KEY (empresa_id)  REFERENCES empresa (id),
  CONSTRAINT fk_ec_cnae    FOREIGN KEY (cnae_codigo) REFERENCES cnae (codigo)
);

CREATE TABLE empresa_regiao (
  empresa_id BIGINT NOT NULL,
  uf         CHAR(2)         NOT NULL,
  PRIMARY KEY (empresa_id, uf),
  CONSTRAINT fk_er_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (id),
  CONSTRAINT ck_er_uf CHECK (uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
);


CREATE TABLE orgao (
  id           BIGINT NOT NULL AUTO_INCREMENT,
  cnpj         CHAR(14)        NOT NULL,
  razao_social VARCHAR(255)    NOT NULL,
  esfera       ENUM('FEDERAL','ESTADUAL','MUNICIPAL','DISTRITAL','OUTRA') NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orgao_cnpj (cnpj)
);

CREATE TABLE licitacao (
  id                   BIGINT NOT NULL AUTO_INCREMENT,
  numero_controle_pncp VARCHAR(60)     NOT NULL COMMENT 'Chave natural da origem: torna a ingestão idempotente (upsert)',
  orgao_id             BIGINT NOT NULL,
  numero_edital        VARCHAR(80)     NULL,
  modalidade_codigo    SMALLINT NOT NULL COMMENT 'Código da modalidade na origem',
  modalidade_nome      VARCHAR(80)     NOT NULL,
  modo_disputa         VARCHAR(40)     NULL,
  situacao             VARCHAR(40)     NOT NULL COMMENT 'Texto da origem; não é ENUM porque a fonte pode criar valores',
  objeto               TEXT            NOT NULL,
  valor_estimado       DECIMAL(15,2)   NULL,
  uf                   CHAR(2)         NULL COMMENT 'UF da unidade compradora (denormalizado p/ filtro rápido)',
  municipio            VARCHAR(100)    NULL,
  data_publicacao      DATETIME        NULL,
  inicio_propostas     DATETIME        NULL COMMENT 'Início do recebimento de propostas',
  fim_propostas        DATETIME        NULL COMMENT 'Encerramento do recebimento de propostas',
  inicio_sessao        DATETIME        NULL COMMENT 'Sessão pública / início da fase de lances',
  impugnacao_ate       DATETIME        NULL,
  link_origem          VARCHAR(500)    NULL,
  payload              JSON            NULL COMMENT 'Resposta bruta da API, para reprocessar sem reingerir',
  sincronizado_em      DATETIME        NOT NULL,
  criado_em            DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_licitacao_pncp (numero_controle_pncp),
  KEY ix_licitacao_uf_fim (uf, fim_propostas),
  KEY ix_licitacao_fim (fim_propostas),
  KEY ix_licitacao_sessao (inicio_sessao),
  KEY ix_licitacao_criado (criado_em),
  KEY ix_licitacao_orgao (orgao_id),
  FULLTEXT KEY ft_licitacao_objeto (objeto),
  CONSTRAINT fk_lic_orgao FOREIGN KEY (orgao_id) REFERENCES orgao (id),
  CONSTRAINT ck_lic_periodo CHECK (fim_propostas IS NULL OR inicio_propostas IS NULL OR fim_propostas >= inicio_propostas),
  CONSTRAINT ck_lic_uf CHECK (uf IS NULL OR uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
);

CREATE TABLE licitacao_item (
  id                      BIGINT NOT NULL AUTO_INCREMENT,
  licitacao_id            BIGINT NOT NULL,
  numero_item             INT    NOT NULL,
  descricao               TEXT            NOT NULL,
  quantidade              DECIMAL(15,4)   NULL,
  unidade                 VARCHAR(30)     NULL,
  valor_unitario_estimado DECIMAL(15,2)   NULL,
  catalogo_tipo           ENUM('CATMAT','CATSER','OUTRO') NULL,
  codigo_catalogo         VARCHAR(20)     NULL,
  tratamento_diferenciado VARCHAR(60)     NULL COMMENT 'Benefício ME/EPP conforme a origem (confirmar o campo na API)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_item_licitacao_numero (licitacao_id, numero_item),
  KEY ix_item_catalogo (catalogo_tipo, codigo_catalogo),
  FULLTEXT KEY ft_item_descricao (descricao),
  CONSTRAINT fk_item_licitacao FOREIGN KEY (licitacao_id) REFERENCES licitacao (id) ON DELETE CASCADE,
  CONSTRAINT ck_item_numero CHECK (numero_item > 0)
);

-- Log de cada execução do job de sincronização (observabilidade).
CREATE TABLE sync_execucao (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  iniciado_em         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finalizado_em       DATETIME        NULL,
  status              ENUM('EXECUTANDO','SUCESSO','PARCIAL','FALHA') NOT NULL DEFAULT 'EXECUTANDO',
  janela_inicio       DATETIME        NULL,
  janela_fim          DATETIME        NULL,
  registros_lidos     INT    NOT NULL DEFAULT 0,
  registros_novos     INT    NOT NULL DEFAULT 0,
  registros_atualizados INT  NOT NULL DEFAULT 0,
  mensagem_erro       TEXT            NULL,
  PRIMARY KEY (id),
  KEY ix_sync_iniciado (iniciado_em),
  CONSTRAINT ck_sync_contadores CHECK (registros_lidos >= 0 AND registros_novos >= 0 AND registros_atualizados >= 0)
);

-- O que a empresa FAZ com uma licitação pública.
CREATE TABLE acompanhamento (
  id            BIGINT NOT NULL AUTO_INCREMENT,
  empresa_id    BIGINT NOT NULL,
  licitacao_id  BIGINT NOT NULL,
  status        ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NOT NULL DEFAULT 'INTERESSE',
  anotacoes     TEXT            NULL,
  criado_em     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_acomp_empresa_licitacao (empresa_id, licitacao_id),
  KEY ix_acomp_empresa_status (empresa_id, status),
  KEY ix_acomp_licitacao (licitacao_id),
  CONSTRAINT fk_ac_empresa   FOREIGN KEY (empresa_id)   REFERENCES empresa (id),
  CONSTRAINT fk_ac_licitacao FOREIGN KEY (licitacao_id) REFERENCES licitacao (id)
);

-- Histórico = tabela de eventos (uma coluna "status" só guarda o atual).
CREATE TABLE acompanhamento_evento (
  id               BIGINT NOT NULL AUTO_INCREMENT,
  acompanhamento_id BIGINT NOT NULL,
  status_anterior  ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NULL,
  status_novo      ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NOT NULL,
  observacao       VARCHAR(500)    NULL,
  ocorrido_em      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_ev_acomp_data (acompanhamento_id, ocorrido_em),
  CONSTRAINT fk_ev_acomp   FOREIGN KEY (acompanhamento_id) REFERENCES acompanhamento (id) ON DELETE CASCADE
);

-- =====================================================================
-- 5. ALERTAS E JORNAL DE LICITAÇÕES
-- =====================================================================

CREATE TABLE filtro_alerta (
  id                  BIGINT NOT NULL AUTO_INCREMENT,
  empresa_id          BIGINT NOT NULL,
  nome                VARCHAR(100)    NOT NULL,
  usar_perfil_empresa TINYINT(1)      NOT NULL DEFAULT 1 COMMENT '1 = usa CNAEs e UFs do perfil da empresa',
  palavras_chave      VARCHAR(500)    NULL,
  valor_min           DECIMAL(15,2)   NULL,
  valor_max           DECIMAL(15,2)   NULL,
  modalidade_codigo   SMALLINT NULL,
  frequencia          ENUM('DIARIA','SEMANAL') NOT NULL DEFAULT 'DIARIA',
  ativo               TINYINT(1)      NOT NULL DEFAULT 1,
  criado_em           DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_filtro_empresa (empresa_id, ativo),
  CONSTRAINT fk_fa_empresa FOREIGN KEY (empresa_id) REFERENCES empresa (id),
  CONSTRAINT ck_fa_valores CHECK (valor_min IS NULL OR valor_max IS NULL OR valor_max >= valor_min)
);

-- Outbox do jornal: uma linha por (filtro, licitação) casada. O job diário
-- envia as linhas com enviado_em IS NULL e as marca. O UNIQUE impede
-- reenviar a mesma licitação para o mesmo filtro.
CREATE TABLE alerta_licitacao (
  id           BIGINT NOT NULL AUTO_INCREMENT,
  filtro_id    BIGINT NOT NULL,
  licitacao_id BIGINT NOT NULL,
  criado_em    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  enviado_em   DATETIME        NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_alerta_filtro_licitacao (filtro_id, licitacao_id),
  KEY ix_alerta_pendente (enviado_em),
  CONSTRAINT fk_al_filtro    FOREIGN KEY (filtro_id)    REFERENCES filtro_alerta (id) ON DELETE CASCADE,
  CONSTRAINT fk_al_licitacao FOREIGN KEY (licitacao_id) REFERENCES licitacao (id)
);

-- LGPD (a implementar na aplicação): excluir conta = empresa.excluido_em
-- preenchido, usuario.ativo = 0 e anonimização do e-mail de login e dos
-- e-mails/telefones de contato; manter apenas o que a lei exigir. Toda
-- consulta de dado privado deve filtrar por empresa_id (no EF Core:
-- HasQueryFilter), obtido a partir do usuário autenticado.

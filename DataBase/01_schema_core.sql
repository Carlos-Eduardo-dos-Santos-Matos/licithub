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

-- =====================================================================
-- 1. IDENTIDADE E MULTI-TENANCY (vários usuários por empresa)
-- =====================================================================
CREATE TABLE tb_usuarios (
  id_usuario           BIGINT       NOT NULL AUTO_INCREMENT,
  nm_usuario           VARCHAR(150) NOT NULL,
  ds_email             VARCHAR(254) NOT NULL COMMENT 'E-mail de LOGIN. Contatos da empresa ficam em tb_empresas_emails',
  hs_senha             VARCHAR(255) NOT NULL COMMENT 'Hash da senha, nunca texto puro',
  dh_confirmacao_email DATETIME     NULL,
  fl_ativo             TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '0 = login bloqueado',
  dh_criacao           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dh_exclusao          DATETIME     NULL COMMENT 'Soft delete (LGPD). Ao excluir, anonimizar nome e e-mail para liberar o UNIQUE',
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuarios_email (ds_email)
);

CREATE TABLE tb_empresas (
  id_empresa      BIGINT       NOT NULL AUTO_INCREMENT,
  nr_cnpj         CHAR(14)     NOT NULL COMMENT 'Sem máscara; 14 posições comportam o CNPJ alfanumérico',
  nm_razao_social VARCHAR(200) NOT NULL,
  nm_fantasia     VARCHAR(200) NULL,
  tp_porte        ENUM('MEI','ME','EPP','MEDIO','GRANDE') NOT NULL,
  dh_criacao      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dh_exclusao     DATETIME     NULL COMMENT 'Soft delete da empresa (LGPD)',
  PRIMARY KEY (id_empresa),
  UNIQUE KEY uq_empresas_cnpj (nr_cnpj),
  CONSTRAINT ck_empresas_cnpj CHECK (nr_cnpj REGEXP '^[0-9A-Za-z]{14}$')
);

CREATE TABLE tb_empresas_usuarios (
  id_empresa BIGINT NOT NULL,
  id_usuario BIGINT NOT NULL,
  tp_papel   ENUM('ADMIN','ANALISTA','LEITOR')     NOT NULL DEFAULT 'ANALISTA',
  st_vinculo ENUM('CONVIDADO','ATIVO','REMOVIDO') NOT NULL DEFAULT 'CONVIDADO',
  dh_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_empresa, id_usuario),
  KEY ix_empresas_usuarios_usuario (id_usuario),
  CONSTRAINT fk_empresas_usuarios_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa),
  CONSTRAINT fk_empresas_usuarios_usuarios FOREIGN KEY (id_usuario) REFERENCES tb_usuarios (id_usuario)
);

CREATE TABLE tb_empresas_emails (
  id_empresa_email   BIGINT       NOT NULL AUTO_INCREMENT,
  id_empresa         BIGINT       NOT NULL,
  ds_email           VARCHAR(254) NOT NULL,
  tp_finalidade      ENUM('GERAL','FINANCEIRO','COMERCIAL','LICITACOES') NOT NULL DEFAULT 'GERAL',
  fl_principal       TINYINT(1)   NOT NULL DEFAULT 0,
  fl_principal_unico TINYINT GENERATED ALWAYS AS (IF(fl_principal = 1, 1, NULL)) STORED,
  dh_verificacao     DATETIME     NULL,
  PRIMARY KEY (id_empresa_email),
  UNIQUE KEY uq_empresas_emails_empresa_email (id_empresa, ds_email),
  UNIQUE KEY uq_empresas_emails_principal (id_empresa, fl_principal_unico),
  CONSTRAINT fk_empresas_emails_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa)
);

CREATE TABLE tb_empresas_telefones (
  id_empresa_telefone BIGINT      NOT NULL AUTO_INCREMENT,
  id_empresa          BIGINT      NOT NULL,
  nr_telefone         VARCHAR(20) NOT NULL COMMENT 'Somente dígitos, com DDD',
  tp_telefone         ENUM('FIXO','CELULAR','WHATSAPP') NOT NULL DEFAULT 'CELULAR',
  fl_principal        TINYINT(1)  NOT NULL DEFAULT 0,
  fl_principal_unico  TINYINT GENERATED ALWAYS AS (IF(fl_principal = 1, 1, NULL)) STORED,
  PRIMARY KEY (id_empresa_telefone),
  UNIQUE KEY uq_empresas_telefones_empresa_telefone (id_empresa, nr_telefone),
  UNIQUE KEY uq_empresas_telefones_principal (id_empresa, fl_principal_unico),
  CONSTRAINT fk_empresas_telefones_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa)
);

-- =====================================================================
-- 2. PERFIL DE ATUAÇÃO DA EMPRESA
-- =====================================================================
CREATE TABLE tb_cnaes (
  cd_cnae    CHAR(7)      NOT NULL COMMENT 'Subclasse sem pontuação, ex.: 6201501',
  ds_cnae    VARCHAR(255) NOT NULL,
  cd_divisao CHAR(2) GENERATED ALWAYS AS (LEFT(cd_cnae, 2)) STORED,
  PRIMARY KEY (cd_cnae),
  KEY ix_cnaes_divisao (cd_divisao)
);

CREATE TABLE tb_cnaes_palavras_chave (
  id_cnae_palavra_chave BIGINT       NOT NULL AUTO_INCREMENT,
  cd_cnae               CHAR(7)      NOT NULL,
  ds_termo              VARCHAR(100) NOT NULL,
  PRIMARY KEY (id_cnae_palavra_chave),
  UNIQUE KEY uq_cnaes_palavras_chave_cnae_termo (cd_cnae, ds_termo),
  CONSTRAINT fk_cnaes_palavras_chave_cnaes FOREIGN KEY (cd_cnae) REFERENCES tb_cnaes (cd_cnae)
);

CREATE TABLE tb_empresas_cnaes (
  id_empresa         BIGINT     NOT NULL,
  cd_cnae            CHAR(7)    NOT NULL,
  fl_principal       TINYINT(1) NOT NULL DEFAULT 0,
  fl_principal_unico TINYINT GENERATED ALWAYS AS (IF(fl_principal = 1, 1, NULL)) STORED,
  PRIMARY KEY (id_empresa, cd_cnae),
  UNIQUE KEY uq_empresas_cnaes_principal (id_empresa, fl_principal_unico),
  KEY ix_empresas_cnaes_cnae (cd_cnae),
  CONSTRAINT fk_empresas_cnaes_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa),
  CONSTRAINT fk_empresas_cnaes_cnaes    FOREIGN KEY (cd_cnae)    REFERENCES tb_cnaes (cd_cnae)
);

CREATE TABLE tb_empresas_regioes (
  id_empresa BIGINT  NOT NULL,
  sg_uf      CHAR(2) NOT NULL,
  PRIMARY KEY (id_empresa, sg_uf),
  CONSTRAINT fk_empresas_regioes_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa),
  CONSTRAINT ck_empresas_regioes_uf CHECK (sg_uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
);

-- =====================================================================
-- 3. DADOS PÚBLICOS (espelho do PNCP)
-- =====================================================================
CREATE TABLE tb_orgaos (
  id_orgao        BIGINT       NOT NULL AUTO_INCREMENT,
  nr_cnpj         CHAR(14)     NOT NULL,
  nm_razao_social VARCHAR(255) NOT NULL,
  tp_esfera       ENUM('FEDERAL','ESTADUAL','MUNICIPAL','DISTRITAL','OUTRA') NULL,
  PRIMARY KEY (id_orgao),
  UNIQUE KEY uq_orgaos_cnpj (nr_cnpj)
);

CREATE TABLE tb_licitacoes (
  id_licitacao         BIGINT        NOT NULL AUTO_INCREMENT,
  nr_controle_pncp     VARCHAR(60)   NOT NULL COMMENT 'Chave natural da origem: torna a ingestão idempotente (upsert)',
  id_orgao             BIGINT        NOT NULL,
  nr_edital            VARCHAR(80)   NULL,
  cd_modalidade        SMALLINT      NOT NULL COMMENT 'Código da modalidade na origem',
  nm_modalidade        VARCHAR(80)   NOT NULL,
  nm_modo_disputa      VARCHAR(40)   NULL,
  st_situacao          VARCHAR(40)   NOT NULL COMMENT 'Texto da origem; não é ENUM porque a fonte pode criar valores',
  ds_objeto            TEXT          NOT NULL,
  vl_estimado          DECIMAL(15,2) NULL,
  sg_uf                CHAR(2)       NULL COMMENT 'UF da unidade compradora (denormalizado p/ filtro rápido)',
  nm_municipio         VARCHAR(100)  NULL,
  dh_publicacao        DATETIME      NULL,
  dh_inicio_propostas  DATETIME      NULL COMMENT 'Início do recebimento de propostas',
  dh_fim_propostas     DATETIME      NULL COMMENT 'Encerramento do recebimento de propostas',
  dh_inicio_sessao     DATETIME      NULL COMMENT 'Sessão pública / início da fase de lances',
  dh_limite_impugnacao DATETIME      NULL,
  ds_link_origem       VARCHAR(500)  NULL,
  js_payload           JSON          NULL COMMENT 'Resposta bruta da API, para reprocessar sem reingerir',
  dh_sincronizacao     DATETIME      NOT NULL,
  dh_criacao           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_licitacao),
  UNIQUE KEY uq_licitacoes_controle_pncp (nr_controle_pncp),
  KEY ix_licitacoes_uf_fim_propostas (sg_uf, dh_fim_propostas),
  KEY ix_licitacoes_fim_propostas (dh_fim_propostas),
  KEY ix_licitacoes_inicio_sessao (dh_inicio_sessao),
  KEY ix_licitacoes_criacao (dh_criacao),
  KEY ix_licitacoes_orgao (id_orgao),
  FULLTEXT KEY ft_licitacoes_objeto (ds_objeto),
  CONSTRAINT fk_licitacoes_orgaos FOREIGN KEY (id_orgao) REFERENCES tb_orgaos (id_orgao),
  CONSTRAINT ck_licitacoes_periodo CHECK (dh_fim_propostas IS NULL OR dh_inicio_propostas IS NULL OR dh_fim_propostas >= dh_inicio_propostas),
  CONSTRAINT ck_licitacoes_uf CHECK (sg_uf IS NULL OR sg_uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
);

CREATE TABLE tb_licitacoes_itens (
  id_licitacao_item          BIGINT        NOT NULL AUTO_INCREMENT,
  id_licitacao               BIGINT        NOT NULL,
  nr_item                    INT           NOT NULL,
  ds_item                    TEXT          NOT NULL,
  qt_item                    DECIMAL(15,4) NULL,
  nm_unidade                 VARCHAR(30)   NULL,
  vl_unitario_estimado       DECIMAL(15,2) NULL,
  tp_catalogo                ENUM('CATMAT','CATSER','OUTRO') NULL,
  cd_catalogo                VARCHAR(20)   NULL,
  ds_tratamento_diferenciado VARCHAR(60)   NULL COMMENT 'Benefício ME/EPP conforme a origem (confirmar o campo na API)',
  PRIMARY KEY (id_licitacao_item),
  UNIQUE KEY uq_licitacoes_itens_licitacao_item (id_licitacao, nr_item),
  KEY ix_licitacoes_itens_catalogo (tp_catalogo, cd_catalogo),
  FULLTEXT KEY ft_licitacoes_itens_item (ds_item),
  CONSTRAINT fk_licitacoes_itens_licitacoes FOREIGN KEY (id_licitacao) REFERENCES tb_licitacoes (id_licitacao) ON DELETE CASCADE,
  CONSTRAINT ck_licitacoes_itens_numero CHECK (nr_item > 0)
);

CREATE TABLE tb_execucoes_sincronizacao (
  id_execucao_sincronizacao BIGINT       NOT NULL AUTO_INCREMENT,
  dh_inicio                 DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dh_fim                    DATETIME     NULL,
  st_execucao               ENUM('EXECUTANDO','SUCESSO','PARCIAL','FALHA') NOT NULL DEFAULT 'EXECUTANDO',
  dh_janela_inicio          DATETIME     NULL,
  dh_janela_fim             DATETIME     NULL,
  qt_registros_lidos        INT          NOT NULL DEFAULT 0,
  qt_registros_novos        INT          NOT NULL DEFAULT 0,
  qt_registros_atualizados  INT          NOT NULL DEFAULT 0,
  ds_erro                   TEXT         NULL,
  PRIMARY KEY (id_execucao_sincronizacao),
  KEY ix_execucoes_sincronizacao_inicio (dh_inicio),
  CONSTRAINT ck_execucoes_sincronizacao_contadores CHECK (qt_registros_lidos >= 0 AND qt_registros_novos >= 0 AND qt_registros_atualizados >= 0)
);

-- =====================================================================
-- 4. DADOS DA EMPRESA (privados; TODA consulta filtra por id_empresa)
-- =====================================================================
CREATE TABLE tb_acompanhamentos (
  id_acompanhamento   BIGINT   NOT NULL AUTO_INCREMENT,
  id_empresa          BIGINT   NOT NULL,
  id_licitacao        BIGINT   NOT NULL,
  id_usuario_criacao  BIGINT   NOT NULL,
  st_acompanhamento   ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NOT NULL DEFAULT 'INTERESSE',
  ds_anotacoes        TEXT     NULL,
  dh_criacao          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dh_atualizacao      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_acompanhamento),
  UNIQUE KEY uq_acompanhamentos_empresa_licitacao (id_empresa, id_licitacao),
  KEY ix_acompanhamentos_empresa_status (id_empresa, st_acompanhamento),
  KEY ix_acompanhamentos_licitacao (id_licitacao),
  KEY ix_acompanhamentos_empresa_usuario (id_empresa, id_usuario_criacao),
  CONSTRAINT fk_acompanhamentos_empresas          FOREIGN KEY (id_empresa)  REFERENCES tb_empresas (id_empresa),
  CONSTRAINT fk_acompanhamentos_licitacoes        FOREIGN KEY (id_licitacao) REFERENCES tb_licitacoes (id_licitacao),
  CONSTRAINT fk_acompanhamentos_empresas_usuarios FOREIGN KEY (id_empresa, id_usuario_criacao)
    REFERENCES tb_empresas_usuarios (id_empresa, id_usuario)
);

CREATE TABLE tb_acompanhamentos_eventos (
  id_acompanhamento_evento BIGINT        NOT NULL AUTO_INCREMENT,
  id_acompanhamento        BIGINT        NOT NULL,
  id_usuario               BIGINT        NULL,
  st_anterior              ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NULL,
  st_novo                  ENUM('INTERESSE','ANALISANDO','PROPOSTA_EM_PREPARO','PARTICIPANDO','GANHOU','PERDEU','DESCARTADO') NOT NULL,
  ds_observacao            VARCHAR(500)  NULL,
  dh_ocorrencia            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_acompanhamento_evento),
  KEY ix_acompanhamentos_eventos_acompanhamento_data (id_acompanhamento, dh_ocorrencia),
  CONSTRAINT fk_acompanhamentos_eventos_acompanhamentos FOREIGN KEY (id_acompanhamento) REFERENCES tb_acompanhamentos (id_acompanhamento) ON DELETE CASCADE,
  CONSTRAINT fk_acompanhamentos_eventos_usuarios        FOREIGN KEY (id_usuario)         REFERENCES tb_usuarios (id_usuario)
);

-- =====================================================================
-- 5. ALERTAS E JORNAL DE LICITAÇÕES
-- =====================================================================
CREATE TABLE tb_filtros_alertas (
  id_filtro_alerta       BIGINT        NOT NULL AUTO_INCREMENT,
  id_empresa             BIGINT        NOT NULL,
  nm_filtro              VARCHAR(100)  NOT NULL,
  fl_usar_perfil_empresa TINYINT(1)    NOT NULL DEFAULT 1 COMMENT '1 = usa CNAEs e UFs do perfil da empresa',
  ds_palavras_chave      VARCHAR(500)  NULL,
  vl_minimo              DECIMAL(15,2) NULL,
  vl_maximo              DECIMAL(15,2) NULL,
  cd_modalidade          SMALLINT      NULL,
  tp_frequencia          ENUM('DIARIA','SEMANAL') NOT NULL DEFAULT 'DIARIA',
  fl_ativo               TINYINT(1)    NOT NULL DEFAULT 1,
  dh_criacao             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_filtro_alerta),
  KEY ix_filtros_alertas_empresa_ativo (id_empresa, fl_ativo),
  CONSTRAINT fk_filtros_alertas_empresas FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa),
  CONSTRAINT ck_filtros_alertas_valores CHECK (vl_minimo IS NULL OR vl_maximo IS NULL OR vl_maximo >= vl_minimo)
);

CREATE TABLE tb_alertas_licitacoes (
  id_alerta_licitacao BIGINT   NOT NULL AUTO_INCREMENT,
  id_filtro_alerta    BIGINT   NOT NULL,
  id_licitacao        BIGINT   NOT NULL,
  dh_criacao          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dh_envio            DATETIME NULL,
  PRIMARY KEY (id_alerta_licitacao),
  UNIQUE KEY uq_alertas_licitacoes_filtro_licitacao (id_filtro_alerta, id_licitacao),
  KEY ix_alertas_licitacoes_pendente (dh_envio),
  CONSTRAINT fk_alertas_licitacoes_filtros_alertas FOREIGN KEY (id_filtro_alerta) REFERENCES tb_filtros_alertas (id_filtro_alerta) ON DELETE CASCADE,
  CONSTRAINT fk_alertas_licitacoes_licitacoes      FOREIGN KEY (id_licitacao)      REFERENCES tb_licitacoes (id_licitacao)
);

-- LGPD (a implementar na aplicação): excluir conta = empresa.excluido_em
-- preenchido, usuario.ativo = 0 e anonimização do e-mail de login e dos
-- e-mails/telefones de contato; manter apenas o que a lei exigir. Toda
-- consulta de dado privado deve filtrar por empresa_id (no EF Core:
-- HasQueryFilter), obtido a partir do usuário autenticado.

CREATE DATABASE IF NOT EXISTS licithub_db;
USE licithub_db;

CREATE TABLE IF NOT EXISTS licitacoes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_contratacao VARCHAR(150) UNIQUE,
    orgao_nome VARCHAR(255),
    objeto TEXT,
    valor_estimado DECIMAL(15,2),
    status_kanban VARCHAR(50) DEFAULT 'Mapeados',
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
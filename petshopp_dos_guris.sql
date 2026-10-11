-- Petshopp dos Guris - sistema de gestão
-- Script de criação do banco (MySQL 8.0.16 ou superior, por causa dos CHECK)

DROP DATABASE IF EXISTS petshopp_dos_guris;
CREATE DATABASE petshopp_dos_guris
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE petshopp_dos_guris;

-- ---------------------------------------------------------------
-- Usuários e perfis
-- ---------------------------------------------------------------

CREATE TABLE Usuario (
    idUsuario   INT          NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100) NOT NULL,
    login       VARCHAR(50)  NOT NULL,
    senhaHash   VARCHAR(255) NOT NULL,
    ativo       BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (idUsuario),
    UNIQUE KEY uq_usuario_login (login)
) ENGINE=InnoDB;

CREATE TABLE Proprietario (
    idUsuario INT NOT NULL,
    PRIMARY KEY (idUsuario),
    CONSTRAINT fk_proprietario_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Vendedor (
    idUsuario INT NOT NULL,
    PRIMARY KEY (idUsuario),
    CONSTRAINT fk_vendedor_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Atendente (
    idUsuario INT NOT NULL,
    PRIMARY KEY (idUsuario),
    CONSTRAINT fk_atendente_usuario FOREIGN KEY (idUsuario)
        REFERENCES Usuario (idUsuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------
-- Clientes e pets
-- ---------------------------------------------------------------

CREATE TABLE Cliente (
    idCliente     INT          NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(100) NOT NULL,
    telefone      VARCHAR(20),
    email         VARCHAR(100),
    dataCadastro  DATE         NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (idCliente)
) ENGINE=InnoDB;

CREATE TABLE Pet (
    idPet        INT          NOT NULL AUTO_INCREMENT,
    nome         VARCHAR(50)  NOT NULL,
    especie      VARCHAR(30)  NOT NULL,
    raca         VARCHAR(50),
    porte        VARCHAR(20),
    alergias     VARCHAR(255),
    observacoes  VARCHAR(255),
    idCliente    INT          NOT NULL,
    PRIMARY KEY (idPet),
    CONSTRAINT ck_pet_porte CHECK (porte IN ('PEQUENO', 'MEDIO', 'GRANDE')),
    CONSTRAINT fk_pet_cliente FOREIGN KEY (idCliente)
        REFERENCES Cliente (idCliente)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------
-- Produtos e estoque
-- ---------------------------------------------------------------

CREATE TABLE Categoria (
    idCategoria INT         NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(50) NOT NULL,
    PRIMARY KEY (idCategoria),
    UNIQUE KEY uq_categoria_nome (nome)
) ENGINE=InnoDB;

CREATE TABLE Fornecedor (
    idFornecedor INT          NOT NULL AUTO_INCREMENT,
    nome         VARCHAR(100) NOT NULL,
    telefone     VARCHAR(20),
    email        VARCHAR(100),
    PRIMARY KEY (idFornecedor)
) ENGINE=InnoDB;

CREATE TABLE Produto (
    idProduto      INT           NOT NULL AUTO_INCREMENT,
    nome           VARCHAR(100)  NOT NULL,
    marca          VARCHAR(50),
    sabor          VARCHAR(50),
    tamanhoPeso    VARCHAR(30),
    precoVenda     DECIMAL(10,2) NOT NULL,
    qtdEstoque     INT           NOT NULL DEFAULT 0,
    estoqueMinimo  INT           NOT NULL DEFAULT 0,
    idCategoria    INT           NOT NULL,
    idFornecedor   INT           NOT NULL,
    PRIMARY KEY (idProduto),
    CONSTRAINT ck_produto_preco CHECK (precoVenda >= 0),
    CONSTRAINT ck_produto_estoque CHECK (qtdEstoque >= 0 AND estoqueMinimo >= 0),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (idCategoria)
        REFERENCES Categoria (idCategoria),
    CONSTRAINT fk_produto_fornecedor FOREIGN KEY (idFornecedor)
        REFERENCES Fornecedor (idFornecedor)
) ENGINE=InnoDB;

CREATE TABLE MovimentacaoEstoque (
    idMovimentacao INT          NOT NULL AUTO_INCREMENT,
    tipo           VARCHAR(20)  NOT NULL,
    quantidade     INT          NOT NULL,
    dataHora       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo         VARCHAR(100),
    idProduto      INT          NOT NULL,
    PRIMARY KEY (idMovimentacao),
    CONSTRAINT ck_movimentacao_tipo CHECK (tipo IN ('ENTRADA', 'SAIDA', 'AJUSTE')),
    CONSTRAINT fk_movimentacao_produto FOREIGN KEY (idProduto)
        REFERENCES Produto (idProduto)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------
-- Caixa, vendas e pagamentos
-- ---------------------------------------------------------------

CREATE TABLE FechamentoCaixa (
    idFechamento    INT           NOT NULL AUTO_INCREMENT,
    data            DATE          NOT NULL,
    totalDinheiro   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    totalPix        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    totalDebito     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    totalCredito    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    valorConferido  DECIMAL(10,2),
    PRIMARY KEY (idFechamento),
    UNIQUE KEY uq_fechamento_data (data)
) ENGINE=InnoDB;

CREATE TABLE Venda (
    idVenda      INT           NOT NULL AUTO_INCREMENT,
    dataHora     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status       VARCHAR(20)   NOT NULL DEFAULT 'ABERTA',
    idVendedor   INT           NOT NULL,
    idAtendente  INT           NOT NULL,
    idCliente    INT,
    PRIMARY KEY (idVenda),
    CONSTRAINT ck_venda_status CHECK (status IN ('ABERTA', 'PAGA', 'CANCELADA')),
    CONSTRAINT fk_venda_vendedor FOREIGN KEY (idVendedor)
        REFERENCES Vendedor (idUsuario),
    CONSTRAINT fk_venda_atendente FOREIGN KEY (idAtendente)
        REFERENCES Atendente (idUsuario),
    CONSTRAINT fk_venda_cliente FOREIGN KEY (idCliente)
        REFERENCES Cliente (idCliente) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE ItemVenda (
    idItemVenda    INT           NOT NULL AUTO_INCREMENT,
    quantidade     INT           NOT NULL,
    precoUnitario  DECIMAL(10,2) NOT NULL,
    idVenda        INT           NOT NULL,
    idProduto      INT           NOT NULL,
    PRIMARY KEY (idItemVenda),
    CONSTRAINT ck_itemvenda_valores CHECK (quantidade > 0 AND precoUnitario >= 0),
    CONSTRAINT fk_itemvenda_venda FOREIGN KEY (idVenda)
        REFERENCES Venda (idVenda) ON DELETE CASCADE,
    CONSTRAINT fk_itemvenda_produto FOREIGN KEY (idProduto)
        REFERENCES Produto (idProduto)
) ENGINE=InnoDB;

CREATE TABLE Pagamento (
    idPagamento   INT           NOT NULL AUTO_INCREMENT,
    forma         VARCHAR(20)   NOT NULL,
    valor         DECIMAL(10,2) NOT NULL,
    dataHora      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    idVenda       INT           NOT NULL,
    idFechamento  INT,
    PRIMARY KEY (idPagamento),
    CONSTRAINT ck_pagamento_forma CHECK (forma IN ('DINHEIRO', 'PIX', 'DEBITO', 'CREDITO')),
    CONSTRAINT ck_pagamento_valor CHECK (valor > 0),
    CONSTRAINT fk_pagamento_venda FOREIGN KEY (idVenda)
        REFERENCES Venda (idVenda),
    CONSTRAINT fk_pagamento_fechamento FOREIGN KEY (idFechamento)
        REFERENCES FechamentoCaixa (idFechamento) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE TrocaDevolucao (
    idTroca         INT           NOT NULL AUTO_INCREMENT,
    tipo            VARCHAR(20)   NOT NULL,
    motivo          VARCHAR(100),
    dataHora        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valorEstornado  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    idItemVenda     INT           NOT NULL,
    PRIMARY KEY (idTroca),
    CONSTRAINT ck_troca_tipo CHECK (tipo IN ('TROCA', 'DEVOLUCAO')),
    CONSTRAINT fk_troca_itemvenda FOREIGN KEY (idItemVenda)
        REFERENCES ItemVenda (idItemVenda)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------
-- Serviços e agenda de banho e tosa
-- ---------------------------------------------------------------

CREATE TABLE Servico (
    idServico   INT           NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(50)   NOT NULL,
    preco       DECIMAL(10,2) NOT NULL,
    duracaoMin  INT           NOT NULL,
    PRIMARY KEY (idServico),
    CONSTRAINT ck_servico_valores CHECK (preco >= 0 AND duracaoMin > 0)
) ENGINE=InnoDB;

CREATE TABLE Agendamento (
    idAgendamento  INT          NOT NULL AUTO_INCREMENT,
    dataHora       DATETIME     NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'AGENDADO',
    observacoes    VARCHAR(255),
    idPet          INT          NOT NULL,
    idVenda        INT,
    PRIMARY KEY (idAgendamento),
    UNIQUE KEY uq_agendamento_venda (idVenda),
    CONSTRAINT ck_agendamento_status CHECK (status IN ('AGENDADO', 'CONCLUIDO', 'CANCELADO')),
    CONSTRAINT fk_agendamento_pet FOREIGN KEY (idPet)
        REFERENCES Pet (idPet),
    CONSTRAINT fk_agendamento_venda FOREIGN KEY (idVenda)
        REFERENCES Venda (idVenda) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE AgendamentoServico (
    idAgendamento INT NOT NULL,
    idServico     INT NOT NULL,
    PRIMARY KEY (idAgendamento, idServico),
    CONSTRAINT fk_agendserv_agendamento FOREIGN KEY (idAgendamento)
        REFERENCES Agendamento (idAgendamento) ON DELETE CASCADE,
    CONSTRAINT fk_agendserv_servico FOREIGN KEY (idServico)
        REFERENCES Servico (idServico)
) ENGINE=InnoDB;

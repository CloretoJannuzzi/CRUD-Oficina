GO
USE [tempdb]
GO

create table pessoa_tmp(
	id_pessoa int identity(1,1) primary key,
	nome varchar(50) not  null,
	sobrenome varchar(50),
	cpf char(15) unique,
	data_criacao date
)

create table cliente_tmp(
	id_cliente int identity(1,1) primary key,
	id_pessoa int foreign key references pessoa_tmp(id_pessoa)
);

create table funcionario_tmp
(
      id_funcionario int identity(1,1) primary key,
      id_pessoa int foreign key references pessoa_tmp(id_pessoa)
);

create table carro_tmp(
	id_carro int identity(1,1) primary key,
	placa char(8) not null unique,
	modelo varchar(15),
	marca varchar(15)
);
create  table cliente_carro_tmp(
	id_carro int foreign key references carro_tmp(id_carro),
	id_cliente int foreign key references cliente_tmp(id_cliente)
);

create table peca_tmp(
	id_peca int identity(1,1) primary key,
	nome varchar(50) not null,
	valor_unidade decimal(9,2)
);

create table orcamento_tmp(
	id_orcamento int identity(1,1) primary key,
	id_cliente int foreign key references cliente_tmp(id_cliente),
	id_carro int foreign key references carro_tmp(id_carro)
);

create table lista_tmp(
	id_orcamento int foreign key references orcamento_tmp(id_orcamento),
	id_peca int foreign key references peca_tmp(id_peca),
	quantidade int not null,
);

--<<<================================================================================>>>
--<<<================================================================================>>>
-- --------------------------- PROCEDURE DA OFICINA V1.5 -------------------------------
--<<<================================================================================>>>
--<<<================================================================================>>>

CREATE PROCEDURE sp_oficina
      @tabela int = NULL,
      @operacao int = NULL,
      @suboperacao int = NULL,
      @nome varchar(50) = NULL,
      @sobrenome varchar(50) = NULl,
      @cpf char(15) = NULL,
      @data date = NULL,
      @placa char(10) = NULL,
      @modelo varchar(25) = NULL,
      @marca varchar(25) = NULL,
      @nome_peca varchar(50) = NULL,
      @valor_unidade decimal(9,2) = NULL,
      @orcamento int = NULL,
      @quantidade int = NULL
AS
IF @tabela IS NOT NULL AND @operacao IS NOT NULL
BEGIN

      --<<<================================================================================>>>
      -- ------------------------------- PROCEDURE FUNCIONÁRIO--------------------------------
      --<<<================================================================================>>>

      IF @tabela = 1 -- pessoa/funcionário
      BEGIN

            IF @operacao = 0 -- select
            BEGIN

                  SELECT [nome], [sobrenome], [cpf], [data_criacação]
                  FROM pessoa_tmp pt
                        INNER JOIN funcionario_tmp ft ON pt.id_pessoa = ft.id_pessoa
                  WHERE (@nome IS NULL OR nome = @nome)
                        AND (@sobrenome IS NULL OR sobrenome = @sobrenome)
                        AND (@cpf IS NULL OR cpf = @cpf)
                        AND (@data IS NULL OR @data = @data)
                  RETURN

            END

            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO pessoa_tmp
                        ([nome], [sobrenome], [cpf], [data_criacação])
                  VALUES(
                              @nome,
                              @sobrenome,
                              @cpf,
                              GETDATE()
                  )

                  DECLARE @id INT = SCOPE_IDENTITY()
                  INSERT INTO funcionario_tmp
                        (id_pessoa)
                  VALUES(@id)
                  RETURN

            END

            IF (EXISTS(SELECT *
            FROM pessoa_tmp pt
                  INNER JOIN funcionario_tmp ft ON pt.id_pessoa = ft.id_pessoa
            WHERE cpf = @cpf))
            BEGIN

                  IF @operacao = 2 -- update
                  BEGIN

                        IF @nome IS NULL 
                        BEGIN
                              SELECT @nome = [nome]
                              FROM pessoa_tmp
                              WHERE cpf = @cpf
                        END

                        IF @sobrenome IS NULL 
                        BEGIN
                              SELECT @sobrenome = [sobrenome]
                              FROM pessoa_tmp
                              WHERE cpf = @cpf
                        END

                        UPDATE pessoa_tmp SET nome = @nome, sobrenome = @sobrenome
                        FROM pessoa_tmp pt
                              INNER JOIN funcionario_tmp ft
                              ON pt.id_pessoa = ft.id_pessoa
                        WHERE pt.cpf = @cpf
                        RETURN

                  END

                  IF @operacao = 3 -- delete
                  BEGIN

                        DECLARE @id_pessoa INT

                        SELECT @id_pessoa = [id_pessoa]
                        FROM pessoa_tmp
                        WHERE cpf = @cpf

                        DELETE funcionario_tmp where id_pessoa = @id_pessoa
                        DELETE pessoa_tmp where cpf = @cpf
                        RETURN

                  END
            END
      END

      --<<<================================================================================>>>
      -- ------------------------------- PROCEDURE CLIENTE------------------------------------
      --<<<================================================================================>>>

      IF @tabela = 2 --pessoa/cliente
      BEGIN

            IF @operacao = 0 -- select
            BEGIN

                  SELECT [nome], [sobrenome], [cpf], [data_criacação]
                  FROM pessoa_tmp pt
                        INNER JOIN cliente_tmp ct ON pt.id_pessoa = ct.id_pessoa
                  WHERE (@nome IS NULL OR nome = @nome)
                        AND (@sobrenome IS NULL OR sobrenome = @sobrenome)
                        AND (@cpf IS NULL OR cpf = @cpf)
                        AND (@data IS NULL OR @data = @data)
                  RETURN

            END
            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO pessoa_tmp
                        ([nome], [sobrenome], [cpf], [data_criacação])
                  VALUES(
                              @nome,
                              @sobrenome,
                              @cpf,
                              GETDATE()
                  )

                  DECLARE @id_c INT = SCOPE_IDENTITY()
                  INSERT INTO cliente_tmp
                        (id_pessoa)
                  VALUES(@id_c)
                  RETURN

            END

            IF (EXISTS(SELECT *
            FROM pessoa_tmp pt
                  INNER JOIN cliente_tmp ct ON pt.id_pessoa = ct.id_pessoa
            WHERE cpf = @cpf))
            BEGIN

                  IF @operacao = 2 -- update
                  BEGIN

                        IF @nome IS NULL
                        BEGIN

                              SELECT @nome = [nome]
                              FROM pessoa_tmp
                              WHERE cpf = @cpf

                        END

                        IF @sobrenome IS NULL
                        BEGIN

                              SELECT @sobrenome = [sobrenome]
                              FROM pessoa_tmp
                              WHERE cpf = @cpf

                        END

                        UPDATE pessoa_tmp SET nome = @nome, sobrenome = @sobrenome
                        FROM pessoa_tmp pt
                              INNER JOIN cliente_tmp ct
                              ON pt.id_pessoa = ct.id_pessoa
                        WHERE pt.cpf = @cpf
                        RETURN

                  END

                  IF @operacao = 3 -- delete
                  BEGIN

                        DECLARE @id_p INT
                        SELECT @id_p = [id_pessoa]
                        FROM pessoa_tmp
                        WHERE cpf = @cpf
                        DELETE cliente_tmp where id_pessoa = @id_p
                        DELETE pessoa_tmp where cpf = @cpf
                        RETURN

                  END
            END
      END

      --<<<================================================================================>>>
      -- -------------------------------- PROCEDURE VEICULO-----------------------------------
      --<<<================================================================================>>>

      IF @tabela = 3 --carro
      BEGIN

            IF @operacao = 0 -- select
            BEGIN

                  SELECT *
                  FROM carro_tmp
                  WHERE (@placa IS NULL OR placa = @placa)
                        AND(@modelo IS NULL OR modelo = @modelo)
                        AND(@marca IS NULL OR marca = @marca)
                  RETURN

            END

            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO carro_tmp
                        ([placa], [modelo], [marca])
                  VALUES(
                              @placa,
                              @modelo,
                              @marca
                        )
                  DECLARE @id_carro int = SCOPE_IDENTITY()

                  IF @suboperacao = 1 -- relacionar cliente com o carro pelo CPF
                  BEGIN

                        DECLARE @id_cliente INT
                        SELECT @id_cliente = [id_cliente]
                        FROM cliente_tmp ct INNER JOIN pessoa_tmp pt ON ct.id_pessoa = pt.id_pessoa
                        WHERE cpf = @cpf

                        INSERT INTO cliente_carro_tmp
                              ([id_carro],[id_cliente])
                        VALUES(
                                    @id_carro, @id_cliente
                              )
                        RETURN

                  END
                  RETURN

            END

            IF (EXISTS(SELECT *
            FROM carro_tmp
            WHERE placa = @placa))
            BEGIN

                  IF @operacao = 2 -- update
                  BEGIN

                        IF @modelo IS NULL
                        BEGIN

                              SELECT @modelo = [modelo]
                              FROM carro_tmp
                              WHERE placa = @placa

                        END
                        IF @marca IS NULL
                        BEGIN

                              SELECT @marca = [marca]
                              FROM carro_tmp
                              WHERE placa = @placa

                        END

                        UPDATE carro_tmp SET modelo = @modelo, marca = @marca
                        FROM carro_tmp ct
                              INNER JOIN cliente_carro_tmp cct
                              ON ct.id_carro = cct.id_carro
                        WHERE placa = @placa
                        RETURN

                  END

                  IF @operacao = 3 -- delete
                  BEGIN

                        DECLARE @id_carro_d INT
                        SELECT @id_carro_d = [id_Carro]
                        FROM carro_tmp
                        WHERE placa = @placa
                        DELETE cliente_carro_tmp where id_carro = @id_carro_d
                        DELETE carro_tmp where placa = @placa
                        RETURN

                  END
            END
      END

      --<<<================================================================================>>>
      -- ---------------------------------- PROCEDURE PEÇAS-----------------------------------
      --<<<================================================================================>>>

      IF @tabela = 4 -- pecas
      BEGIN

            IF @operacao = 0 -- select
            BEGIN

                  SELECT *
                  FROM peca_tmp
                  WHERE(@nome_peca IS NULL OR nome = @nome_peca)
                  RETURN

            END

            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO peca_tmp
                        ([nome], [valor_unidade])
                  VALUES(
                              @nome,
                              @valor_unidade
                        )
                  RETURN

            END

            IF (EXISTS(SELECT *
            FROM peca_tmp
            WHERE nome = @nome))
            BEGIN

                  IF @operacao = 2 -- update
                  BEGIN

                        UPDATE peca_tmp SET valor_unidade = @valor_unidade 
                        WHERE nome = @nome_peca
                        RETURN

                  END
                  IF @operacao = 3 -- delete
                  BEGIN

                        DECLARE @id_peca INT
                        SELECT @id_peca = [id_peca]
                        FROM peca_tmp
                        WHERE nome = @nome_peca

                        DELETE lista_tmp WHERE id_peca = @id_peca
                        DELETE peca_tmp WHERE id_peca = @id_peca
                        RETURN

                  END
            END
      END

      --<<<================================================================================>>>
      -- ------------------------------- PROCEDURE ORÇAMENTO----------------------------------
      --<<<================================================================================>>>

      IF @tabela = 5 -- orcamento
      BEGIN

            DECLARE @id_cliente_orcamento INT, @id_carro_orcamento INT

            SELECT @id_cliente_orcamento = cct.id_cliente
            FROM cliente_carro_tmp cct
                  INNER JOIN cliente_tmp ct ON cct.id_cliente = ct.id_cliente
                  INNER JOIN pessoa_tmp pt ON ct.id_pessoa = pt.id_pessoa
            WHERE cpf = @cpf

            SELECT @id_carro_orcamento = cct.id_carro
            FROM cliente_carro_tmp cct
                  INNER JOIN carro_tmp ct ON cct.id_carro = ct.id_carro
            WHERE placa = @placa

            IF @operacao = 0 -- select
            BEGIN

                  SELECT *
                  FROM orcamento_tmp
                  WHERE id_orcamento = @orcamento
                  RETURN

            END
            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO orcamento_tmp
                        ([id_cliente], [id_carro])
                  VALUES(
                              @id_cliente_orcamento, @id_carro_orcamento
                        )
                  RETURN

            END

            IF (EXISTS(SELECT *
            FROM orcamento_tmp
            WHERE id_orcamento = @orcamento))
            BEGIN

                  IF @operacao = 2 -- update
                  BEGIN

                        IF @id_cliente_orcamento IS NULL
                        BEGIN

                              SELECT @id_cliente_orcamento = id_cliente
                              FROM orcamento_tmp
                              WHERE id_orcamento = @orcamento

                        END

                        IF @id_carro_orcamento IS NULL
                        BEGIN

                              SELECT @id_carro_orcamento = id_carro
                              FROM orcamento_tmp
                              WHERE id_orcamento = @orcamento

                        END

                        UPDATE orcamento_tmp SET id_cliente = @id_cliente_orcamento, id_carro = @id_carro_orcamento 
                        WHERE (id_cliente = @id_cliente AND id_carro != @id_carro)
                              OR (id_carro = @id_carro_orcamento AND id_cliente != @id_cliente_orcamento)
                              OR (id_orcamento = @orcamento)
                        RETURN

                  END

                  IF @operacao = 3 -- delete
                  BEGIN

                        DELETE lista_tmp WHERE id_orcamento = @orcamento
                        DELETE orcamento_tmp WHERE id_orcamento = @orcamento
                        RETURN

                  END
            END
      END

      --<<<================================================================================>>>
      -- ------------------------------- PROCEDURE LISTA PEÇA---------------------------------
      --<<<================================================================================>>>

      IF @tabela = 6  -- lista (Criar trigger de update)
      BEGIN

            DECLARE @cod_peca INT
            SELECT @cod_peca = id_peca
            FROM peca_tmp
            WHERE nome = @nome_peca
            -- a pessoa insere o nome da peça mas no código a query pega seu id para executar as funções

            IF @operacao = 0 -- select
            BEGIN

                  SELECT *
                  FROM lista_tmp
                  WHERE id_orcamento = @orcamento OR @orcamento IS NULL
                  RETURN

            END
            IF @operacao = 1 -- insert
            BEGIN

                  INSERT INTO lista_tmp
                        (id_orcamento,id_peca,quantidade)
                  VALUES(@orcamento, @cod_peca, @quantidade)
                  RETURN

            END
            IF @operacao = 2 -- update
            BEGIN

                  UPDATE lista_tmp SET quantidade = @quantidade WHERE id_orcamento = @orcamento and id_peca = @cod_peca
                  RETURN

            END
            IF @operacao = 3 -- delete
            BEGIN

                  DELETE lista_tmp WHERE id_orcamento = @orcamento and id_peca = @cod_peca

            END
      END
END
-- FIM. (versão 1.5)

CREATE TABLE ocorrencias_brutas (
    ID_DELEGACIA            VARCHAR(600),
    NOME_DELEGACIA          VARCHAR(600),
    NOME_MUNICIPIO          VARCHAR(600),
    ANO_BO                  VARCHAR(600),
    NUM_BO                  VARCHAR(600),
    DATA_OCORRENCIA_BO      VARCHAR(600),
    HORA_OCORRENCIA         VARCHAR(600),
    DESCRICAO_APRESENTACAO  VARCHAR(600),
    DATAHORA_REGISTRO_BO    VARCHAR(600),
    DESCR_PERIODO           VARCHAR(600),
    AUTORIA_BO              VARCHAR(600),
    FLAG_FLAGRANTE          VARCHAR(600),
    FLAG_STATUS             VARCHAR(600),
    DESC_LEI                VARCHAR(600),
    RUBRICA                 VARCHAR(600),
    DESDOBRAMENTO           VARCHAR(600),
    DESCR_SUBTIPOLOCAL      VARCHAR(600),
    CIDADE                  VARCHAR(600),
    BAIRRO                  VARCHAR(600),
    CEP                     VARCHAR(600),
    LOGRADOURO              VARCHAR(600),
    NUMERO_LOGRADOURO       VARCHAR(600),
    MARCA_OBJETO            VARCHAR(600),
    FLAG_BLOQUEIO           VARCHAR(600),
    FLAG_DESBLOQUEIO        VARCHAR(600),
    num_imei                VARCHAR(50)
);

create table if not exists regiao(
    regiao_id int primary key,
    nome_regiao varchar(100) not null
);

INSERT INTO regiao (regiao_id, nome_regiao)
WITH zonas AS (
  SELECT * FROM (VALUES
    ('Zona Central'),
    ('Zona Norte'),
    ('Zona Sul'),
    ('Zona Oeste'),
    ('Zona Leste')
  ) AS t(nome_regiao)
)
SELECT
  ROW_NUMBER() OVER (ORDER BY nome_regiao) AS regiao_id,
  nome_regiao
FROM zonas
ON CONFLICT DO NOTHING;


create table if not exists bairro(
    bairro_id int primary key ,
    nome_bairro varchar(1000) null,
    populacao int not null,
    idh decimal(4,3) not null,
    regiao_id int not null,
    foreign key(regiao_id) references regiao(regiao_id)
);

insert into bairro
with resultado_bairro as (
select distinct
  REPLACE(
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        LOWER(bairro),
                        'á', 'a'
                      ), 'â', 'a'
                    ), 'ã', 'a'
                  ), 'à', 'a'
                ), 'é', 'e'
              ), 'ê', 'e'
            ), 'í', 'i'
          ), 'ó', 'o'
        ), 'ô', 'o'
      ), 'õ', 'o'
    ), 'ú', 'u'
  ) AS nome_bairro
from segurancasp2testemigracao.ocorrencias_brutas
where UPPER(nome_municipio) = 'S.PAULO' --and BAIRRO IN ('SE','SÉ')
) select ROW_NUMBER() OVER () AS bairro_id, nome_bairro
from resultado_bairro

create table if not exists logradouro(
	id_logradouro int primary key,
    nome_logradouro varchar(200) not null
);

insert into logradouro
with resultado_logradouro as (
select distinct logradouro
from segurancasp2testemigracao.ocorrencias_brutas
where UPPER(nome_municipio) = 'S.PAULO'
) select ROW_NUMBER() OVER () AS id_logradouro, logradouro 
from resultado_logradouro

create table if not exists cep(
	cep varchar(20) primary key,
	numero_inicio varchar(20)  null,
    numero_fim varchar(20)  null
);

insert into cep
with resultado_logradouro as (
select cep as cep, min(numero_logradouro) as numero_inicio,max(numero_logradouro) as numero_fim
from segurancasp2testemigracao.ocorrencias_brutas
where UPPER(nome_municipio) = 'S.PAULO'
group by 1
) select cep, numero_inicio, numero_fim
from resultado_logradouro

create table if not exists delegacia(
	id_delegacia int primary key,
	nome_delegacia varchar(100) not null,
	nome_municipio varchar(100) default 'São Paulo'
);

insert into delegacia
with resultado_delegacia as (
select distinct nome_delegacia,nome_municipio 
from segurancasp2testemigracao.ocorrencias_brutas
) select ROW_NUMBER() OVER () AS id_logradouro, nome_delegacia, nome_municipio
from resultado_delegacia

create table if not exists rubrica(
	id_rubrica int primary key,
	nome_rubrica varchar(300),
	descr_lei text
);

insert into rubrica
with resultado_rubrica as (
select distinct rubrica, desc_lei
from segurancasp2testemigracao.ocorrencias_brutas
) select ROW_NUMBER() OVER () as id_rubrica, rubrica as nome_rubrica, desc_lei
from resultado_rubrica

CREATE TABLE IF NOT EXISTS dispoe (
	id_delegacia INT NOT NULL,
	num_bo VARCHAR(50) NOT NULL,
	ano_bo VARCHAR(100) NOT NULL,
	id_rubrica INT NOT NULL,
	PRIMARY KEY (id_delegacia, num_bo, ano_bo, id_rubrica)
);

INSERT INTO dispoe
SELECT DISTINCT
    b.id_rubrica,
    a.num_bo,
    a.ano_bo,
    c.id_delegacia
FROM segurancasp2testemigracao.ocorrencias_brutas a
JOIN rubrica b  ON a.rubrica       = b.nome_rubrica
JOIN delegacia c ON a.nome_delegacia = c.nome_delegacia
WHERE UPPER(a.nome_municipio) = 'S.PAULO';


create table if not exists ocorrencia(
	id_delegacia int not null,
	num_bo varchar(50) not null,
	data_ocorrencia date,
	ano_bo int not null,
	datahora_registro_bo date,
	hora_ocorrencia time,
	descricao_apresentacao text,
	descr_periodo varchar(50),
	autoria_bo varchar(25),
	flag_flagrante varchar(5),
	flag_status varchar(25),
	desdobramento text,
	desc_subtipolocal text,
	primary key (id_delegacia, num_bo, ano_bo),
	foreign key (id_delegacia) references delegacia(id_delegacia),
	CHECK (flag_flagrante IN ('S', 'N')),
	CHECK (autoria_bo IN ('C', 'D', 'S')),
	CHECK (descr_periodo IN ('De madrugada', 'Pela manha', 'A tarde', 'A noite', 'Em hora incerta') OR descr_periodo IS NULL)
);

WITH staging AS (
  SELECT
    d.id_delegacia,
    o.num_bo,
    CASE 
      WHEN o.data_ocorrencia_bo ~ '^\d{2}/\d{2}/\d{4}$'
      THEN to_date(o.data_ocorrencia_bo, 'DD/MM/YYYY')
      ELSE NULL
    END AS data_ocorrencia,

    CAST(o.ano_bo AS INT) AS ano_bo,

    CASE 
      WHEN o.datahora_registro_bo ~ '^\d{2}/\d{2}/\d{4}$'
      THEN to_date(o.datahora_registro_bo, 'DD/MM/YYYY')
      ELSE NULL
    END AS datahora_registro_bo,

    CASE
      WHEN o.hora_ocorrencia ~ '^\d{2}:\d{2}(:\d{2})?$'
      THEN o.hora_ocorrencia::TIME
      ELSE NULL
    END AS hora_ocorrencia,

    o.descricao_apresentacao,
    o.descr_periodo,
    o.autoria_bo,
    o.flag_flagrante,
    o.flag_status,
    o.desdobramento,
    o.descr_subtipolocal

  FROM segurancasp2testemigracao.ocorrencias_brutas o
  JOIN delegacia d
    ON o.nome_delegacia = d.nome_delegacia
  WHERE UPPER(o.nome_municipio) = 'S.PAULO'
)
INSERT INTO ocorrencia (
    id_delegacia,
    num_bo,
    data_ocorrencia,
    ano_bo,
    datahora_registro_bo,
    hora_ocorrencia,
    descricao_apresentacao,
    descr_periodo,
    autoria_bo,
    flag_flagrante,
    flag_status,
    desdobramento,
    desc_subtipolocal
)
SELECT
    id_delegacia,
    num_bo,
    data_ocorrencia,
    ano_bo,
    datahora_registro_bo,
    hora_ocorrencia,
    descricao_apresentacao,
    descr_periodo,
    autoria_bo,
    flag_flagrante,
    flag_status,
    desdobramento,
    descr_subtipolocal
FROM staging
ON CONFLICT DO NOTHING;

create table if not exists localidade(
    localidade_id int primary key,
    id_delegacia int not null,
    num_bo varchar(50) not null,
    ano_bo int not null,
    complemento varchar(100),
    bairro_id int not null,
    cep varchar(20) not null,
    numero_endereco varchar(20),
    foreign key(id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo),
    foreign key(bairro_id) references bairro(bairro_id),
    foreign key(cep) references cep(cep)
);

INSERT INTO localidade (
    localidade_id,
    id_delegacia,
    num_bo,
    ano_bo,
    complemento,        
    bairro_id,
    cep,
    numero_endereco
)
WITH resultado_localidade AS (
  SELECT DISTINCT
    d.id_delegacia,
    o.num_bo,
    CAST(o.ano_bo AS INT)            AS ano_bo,
    NULL::VARCHAR(100)               AS complemento,   
    b.bairro_id,
    o.cep,
    o.numero_logradouro              AS numero_endereco
  FROM segurancasp2testemigracao.ocorrencias_brutas o
  JOIN delegacia d  ON o.nome_delegacia = d.nome_delegacia
  JOIN bairro b     ON LOWER(o.bairro)   = LOWER(b.nome_bairro)
  JOIN cep c        ON o.cep             = c.cep
  WHERE UPPER(o.nome_municipio) = 'S.PAULO'
)
SELECT
  ROW_NUMBER() OVER (ORDER BY id_delegacia, num_bo, ano_bo, bairro_id, cep) AS localidade_id,
  id_delegacia,
  num_bo,
  ano_bo,
  complemento,  
  bairro_id,
  cep,
  numero_endereco
FROM resultado_localidade;

create table if not exists inclui(
	cep varchar(20) not null,
    id_logradouro int not null,
    primary key(cep, id_logradouro),
    foreign key (cep) references cep(cep),
    foreign key (id_logradouro) references logradouro(id_logradouro)
);

INSERT INTO inclui (cep, id_logradouro)
SELECT DISTINCT
    c.cep,
    l.id_logradouro
FROM segurancasp2testemigracao.ocorrencias_brutas ob
JOIN cep c ON ob.cep = c.cep
JOIN logradouro l ON ob.logradouro = l.nome_logradouro
WHERE ob.cep IS NOT NULL AND ob.logradouro IS NOT NULL;

CREATE TABLE IF NOT EXISTS feriado (
    feriado_id INT PRIMARY KEY,
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    nome_feriado VARCHAR(100) NOT NULL,
    tipo_feriado VARCHAR(50),
    dia_semana VARCHAR(50)
);

INSERT INTO feriado (feriado_id, data_inicio, data_fim, nome_feriado, tipo_feriado, dia_semana)
VALUES
(1, '2025-01-01', '2025-01-01', 'Confraternizacao Universal', 'Nacional', 'Quarta-feira'),
(2, '2025-03-03', '2025-03-04', 'Carnaval', 'Facultativo', 'Segunda/Terca-feira'),
(3, '2025-03-05', '2025-03-05', 'Quarta-feira de Cinzas', 'Facultativo', 'Quarta-feira'),
(4, '2025-04-18', '2025-04-18', 'Paixao de Cristo', 'Nacional', 'Sexta-feira'),
(5, '2025-04-21', '2025-04-21', 'Tiradentes', 'Nacional', 'Segunda-feira'),
(6, '2025-05-01', '2025-05-01', 'Dia do Trabalhador', 'Nacional', 'Quinta-feira'),
(7, '2025-06-19', '2025-06-19', 'Corpus Christi', 'Facultativo', 'Quinta-feira'),
(8, '2025-09-07', '2025-09-07', 'Independencia do Brasil', 'Nacional', 'Domingo'),
(9, '2025-10-12', '2025-10-12', 'Nossa Senhora Aparecida', 'Nacional', 'Domingo'),
(10, '2025-11-02', '2025-11-02', 'Finados', 'Nacional', 'Domingo'),
(11, '2025-11-15', '2025-11-15', 'Proclamação da Republica', 'Nacional', 'Sabado'),
(12, '2025-12-25', '2025-12-25', 'Natal', 'Nacional', 'Quinta-feira');

create table if not exists marca(
	id_marca int primary key,
	nome_marca varchar(30)
);

WITH marcas_distintas AS (
    SELECT DISTINCT marca_objeto AS nome_marca
    FROM segurancasp2testemigracao.ocorrencias_brutas
    WHERE marca_objeto IS NOT NULL AND marca_objeto != ''
)
INSERT INTO marca (id_marca, nome_marca)
SELECT ROW_NUMBER() OVER (ORDER BY nome_marca) AS id_marca, nome_marca
FROM marcas_distintas;

CREATE TABLE IF NOT EXISTS celular (
    id_celular int PRIMARY KEY,
    flag_bloqueio VARCHAR(1),
    flag_desbloqueio VARCHAR(1),
    id_marca INT NOT NULL,
    num_imei VARCHAR(50),
    FOREIGN KEY (id_marca) REFERENCES marca(id_marca),
    CHECK (flag_bloqueio IN ('S', 'N') OR flag_bloqueio IS NULL),
    CHECK (flag_desbloqueio IN ('S', 'N') OR flag_desbloqueio IS NULL)
);

WITH combos AS (
  SELECT DISTINCT
    ob.num_imei,
    ob.flag_bloqueio,
    ob.flag_desbloqueio,
    ob.marca_objeto
  FROM ocorrencias_brutas ob
  WHERE ob.num_imei IS NOT NULL
),
mapped AS (
  SELECT
    c.num_imei,
    c.flag_bloqueio,
    c.flag_desbloqueio,
    m.id_marca
  FROM combos c
  JOIN marca m
    ON m.nome_marca = c.marca_objeto
),
with_id AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY num_imei) AS id_celular,
    flag_bloqueio,
    flag_desbloqueio,
    id_marca,
    num_imei 
  FROM mapped
)

INSERT INTO celular (
  id_celular,
  flag_bloqueio,
  flag_desbloqueio,
  id_marca,
  num_imei
)
SELECT
  id_celular,
  flag_bloqueio,
  flag_desbloqueio,
  id_marca,
  num_imei
FROM with_id
ON CONFLICT (id_celular) DO NOTHING;

create table if not exists acolhe(
	id_celular int not null,
	id_delegacia int not null,
	num_bo varchar(50) not null,
	ano_bo int not null,
    primary key(id_celular, id_delegacia, num_bo, ano_bo),
    foreign key(id_celular) references celular(id_celular),
	foreign key(id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo)
);

INSERT INTO acolhe (id_celular, id_delegacia, num_bo, ano_bo)
SELECT
  c.id_celular,
  o.id_delegacia,
  o.num_bo,
  o.ano_bo
FROM ocorrencias_brutas ob
JOIN delegacia d
  ON ob.nome_delegacia = d.nome_delegacia
JOIN ocorrencia o
  ON o.id_delegacia = d.id_delegacia
 AND o.num_bo       = ob.num_bo
 AND o.ano_bo       = CAST(ob.ano_bo AS INT)
JOIN celular c
  ON c.num_imei = ob.num_imei
WHERE ob.num_imei IS NOT NULL
ON CONFLICT (id_celular, id_delegacia, num_bo, ano_bo) DO NOTHING;

create table if not exists associa(
	id_delegacia int not null,
    num_bo varchar(50) not null,
    ano_bo int not null,
    feriado_id int not null,
    primary key (id_delegacia, num_bo, ano_bo, feriado_id),
    foreign key (id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo),
    foreign key (feriado_id) references feriado(feriado_id)
);

INSERT INTO associa (id_delegacia, num_bo, ano_bo, feriado_id)
SELECT
    o.id_delegacia,
    o.num_bo,
    o.ano_bo,
    f.feriado_id
FROM ocorrencia o
JOIN feriado f
  ON o.data_ocorrencia BETWEEN f.data_inicio AND f.data_fim
ON CONFLICT (id_delegacia, num_bo, ano_bo, feriado_id) DO NOTHING;

create database if not exists segurancasp2;

use segurancasp2;

create table if not exists delegacia(
	id_delegacia int primary key,
	nome_delegacia varchar(100) not null,
	nome_municipio varchar(100) default 'São Paulo'
);

create table if not exists ocorrencia(
	id_delegacia int not null,
	num_bo varchar(50) not null,
	data_ocorrencia date not null,
	ano_bo int not null,
	datahora_registro_bo datetime,
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
	CHECK (autoria_bo IN ('CONHECIDA', 'DESCONHECIDA')),
	CHECK (descr_periodo IN ('MANHA', 'TARDE', 'NOITE'))
);

create table if not exists rubrica(
	id_rubrica int auto_increment primary key,
	nome_rubrica varchar(100),
	descr_lei text
);

create table if not exists dispoe(
	id_delegacia int not null,
	num_bo varchar(50) not null,
	ano_bo int not null,
	id_rubrica int not null,
    primary key (id_delegacia, num_bo, ano_bo, id_rubrica),
	foreign key (id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo),
	foreign key (id_rubrica) references rubrica(id_rubrica)
);

create table if not exists regiao(
    regiao_id int auto_increment primary key,
    nome_regiao varchar(100) not null
);

create table if not exists bairro(
    bairro_id int auto_increment primary key ,
    nome_bairro varchar(100) not null,
    populacao int not null,
    idh decimal(4,3) not null,
    regiao_id int not null,
    foreign key(regiao_id) references regiao(regiao_id)
);

create table if not exists logradouro(
	id_logradouro int auto_increment primary key,
    nome_logradouro varchar(200) not null
);

create table if not exists cep(
	cep varchar(20) primary key,
	numero_inicio int not null,
    numero_fim int not null
);

create table if not exists inclui(
	cep varchar(20) not null,
    id_logradouro int not null,
    primary key(cep, id_logradouro),
    foreign key (cep) references cep(cep),
    foreign key (id_logradouro) references logradouro(id_logradouro)
);

create table if not exists localidade(
    localidade_id int auto_increment primary key,
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

create table if not exists feriado(
	feriado_id int auto_increment primary key,
	data_inicio date not null,
    data_fim date not null,
	nome_feriado varchar(100) not null
);

create table if not exists associa(
	id_delegacia int not null,
    num_bo varchar(50) not null,
    ano_bo int not null,
    feriado_id int not null,
    primary key (id_delegacia, num_bo, ano_bo, feriado_id),
    foreign key (id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo),
    foreign key (feriado_id) references feriado(feriado_id)
);

create table if not exists marca(
	id_marca int auto_increment primary key,
	nome_marca varchar(30)
);

create table if not exists celular(
    id_celular int auto_increment primary key,
    flag_bloqueio varchar(1),
    flag_desbloqueio varchar(1),
    id_marca int not null,
    num_imei int,
    foreign key(id_marca) references marca(id_marca),
    CHECK (flag_bloqueio IN ('S', 'N')),
    CHECK (flag_desbloqueio IN('S','N'))
);

create table if not exists acolhe(
	id_celular int not null,
	id_delegacia int not null,
	num_bo varchar(50) not null,
	ano_bo int not null,
    primary key(id_celular, id_delegacia, num_bo, ano_bo),
    foreign key(id_celular) references celular(id_celular),
	foreign key(id_delegacia, num_bo, ano_bo) references ocorrencia(id_delegacia, num_bo, ano_bo)
);

-- liquibase formatted sql

-- changeset sergiovqc:1744899477281-1
CREATE TABLE CATEGORIAS2 (CATEGORIA_ID NUMBER(38) AUTOINCREMENT (1, 1) NOT NULL, NOMBRE VARCHAR(100) NOT NULL, DESCRIPCION VARCHAR(1000), CONSTRAINT PK_CATEGORIAS PRIMARY KEY (CATEGORIA_ID));

-- changeset sergiovqc:1744899477281-2
CREATE TABLE PRODUCTOS2 (PRODUCTO_ID NUMBER(38) AUTOINCREMENT (1, 1) NOT NULL, NOMBRE VARCHAR(150) NOT NULL, DESCRIPCION VARCHAR(1000), PRECIO NUMBER(10, 2) DEFAULT 0 NOT NULL, STOCK NUMBER(38) DEFAULT 0 NOT NULL, CATEGORIA_ID NUMBER(38), CONSTRAINT PK_PRODUCTOS PRIMARY KEY (PRODUCTO_ID));


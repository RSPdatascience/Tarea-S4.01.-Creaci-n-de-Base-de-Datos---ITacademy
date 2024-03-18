
# NIVEL 1

-- Descarga los archivos CSV, estudialos y diseña una base de datos con un esquema de estrella que contenga, 
-- al menos 4 tablas de las que puedas realizar las siguientes consultas:

create database ventas;

use ventas;

CREATE TABLE companies (
    company_id VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(40),
    phone VARCHAR(20),
    email VARCHAR(50),
    country VARCHAR(60),
    website VARCHAR(50)
); 


SHOW VARIABLES LIKE "secure_file_priv";  -- Para ver en qué carpeta hay que colocar los csv para poder cargar los datos en las tablas de manera segura


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE credit_cards (
    id VARCHAR(10) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(40),
    pan VARCHAR(30),
    pin VARCHAR(10),
    cvv VARCHAR(5),
    track1 VARCHAR(50),
    track2 VARCHAR(50),
    expiring_date VARCHAR(10)    
); 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

use ventas;

CREATE TABLE products (
    id INT PRIMARY KEY,
    product_name VARCHAR(40),
    price VARCHAR(10),
    colour VARCHAR(10),
    weight VARCHAR(5),
    warehouse_id VARCHAR(10)
); 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE transactions (
    id VARCHAR(45) PRIMARY KEY,
    card_id VARCHAR(10),
    business_id VARCHAR(10),
    timestamp TIMESTAMP,
    amount DECIMAL(10, 2),
    declined TINYINT,
    product_ids VARCHAR(15),
    user_id INT,
    lat DECIMAL(15, 11),
    longitude DECIMAL(15, 11)
); 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


CREATE TABLE users (
    id INT PRIMARY KEY,
    name TINYTEXT,
    surname TINYTEXT,
    phone VARCHAR(20),
    email VARCHAR(40),
    birth_date VARCHAR(15),
    country TINYTEXT,
    city TINYTEXT,
    postal_code VARCHAR(11),
    address VARCHAR(40)
); 


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca-2.csv' 
-- El archivo original daba problemas, de modo que fue transformado con python 
-- sustituyendo el delimitador coma por semicolon y eliminando comillas
INTO TABLE users
FIELDS TERMINATED BY ';'
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk-2.csv' 
-- El archivo original daba problemas, de modo que fue transformado con python 
-- sustituyendo el delimitador coma por semicolon y eliminando comillas
INTO TABLE users
FIELDS TERMINATED BY ';'
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa-2.csv' 
-- El archivo original daba problemas, de modo que fue transformado con python 
-- sustituyendo el delimitador coma por semicolon y eliminando comillas
INTO TABLE users
FIELDS TERMINATED BY ';'
-- ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Se genera una tabla para romper la relación n:n entre las tablas products y transactions.
-- (Esto corresponde al Nivel 3, pero lo hacemos aquí y así el modelo ya está completo)
-- La tabla se genera mediante Python (ver código en archivo ipynb incluido en el repositorio)



CREATE TABLE products_transactions (
    transaction_id VARCHAR(45),
    product_id INT
); 

-- El csv siguiente se ha generado con python 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products_transactions.csv'
INTO TABLE products_transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Alternativa basada en código SQL:
CREATE TABLE products_transactions_n (
    transaction_id VARCHAR(255),
    product_id INT
) AS
SELECT 
    id AS transaction_id,
    SUBSTRING_INDEX(product_ids, ',', 1) AS product_id
FROM transactions
UNION ALL
SELECT 
    id AS transaction_id,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 2), ',', -1) AS product_id
FROM transactions
UNION ALL
SELECT 
    id AS transaction_id,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 3), ',', -1) AS product_id
FROM transactions
UNION ALL
SELECT 
    id AS transaction_id,
    SUBSTRING_INDEX(SUBSTRING_INDEX(product_ids, ',', 4), ',', -1) AS product_id
FROM transactions;




-- Se crean las claves foraneas 
ALTER TABLE credit_cards ADD FOREIGN KEY(user_id) REFERENCES users(id);
ALTER TABLE transactions ADD FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE transactions ADD FOREIGN KEY (business_id) REFERENCES companies(company_id);
ALTER TABLE products_transactions ADD FOREIGN KEY (transaction_id) REFERENCES transactions(id);
ALTER TABLE products_transactions ADD FOREIGN KEY (product_id) REFERENCES products(id);
    
    
    
-- Ejercicio 1: Realiza una subconsulta que muestre a todos los usuarios con más de 30 transacciones utilizando al menos 2 tablas.
SELECT 
    name as Nombre, surname as Apellido, COUNT(transactions.id) as Transacciones
FROM
    transactions
        JOIN
    users ON users.id = transactions.user_id
GROUP BY user_id
HAVING Transacciones > 30
ORDER BY Transacciones DESC;


-- Ejercicio 2: Muestra el promedio de la suma de transacciones por IBAN de las tarjetas de crédito en la compañía Donec Ltd. utilizando al menos 2 tablas.

SELECT 
    company_name AS Compañía,
    IBAN,
    round(AVG(amount), 2) AS Promedio,
    COUNT(transactions.id) AS Transacciones
FROM
    transactions
        JOIN
    credit_cards ON credit_cards.id = transactions.card_id
        JOIN
    companies ON companies.company_id = transactions.business_id
WHERE
    company_name = 'Donec Ltd'
GROUP BY iban
ORDER BY Transacciones DESC;



# NIVEL 2
-- Crea una tabla nueva que refleje el estado de las tarjetas de crédito en base a si 
-- las últimas tres transacciones fueron declinadas y genera la siguiente consulta:
-- Ejercicio 1: Cuantas tarjetas están activas

-- Query preliminar 1: devuelve una view con las últimas 3 transacciones
create view ultimas_compras as (
SELECT t.card_id, t.timestamp, t.declined
FROM transactions t
WHERE  (
    SELECT COUNT(*)
    FROM transactions t2
    WHERE t2.card_id = t.card_id AND t2.timestamp > t.timestamp
) < 3
ORDER BY t.card_id, t.timestamp DESC);

-- Query preliminar 2: muestra el estado de las tarjetas como 'Inactiva' si la suma de los últimos tres valores de declined es 3
select card_id, sum(declined), count(card_id), case
When sum(declined) = 3 Then 'Inactiva'
Else 'Activa'
End as Estado
from ultimas_compras
group by card_id
order by sum(declined) desc;

-- Esta query combina las dos anteriores para generar la tabla deseada
CREATE VIEW estado_tarjetas AS
SELECT 
    card_id,
    SUM(declined) AS total_declined,
    COUNT(card_id) AS total_transactions,
    CASE
        WHEN SUM(declined) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS Estado
FROM (
    SELECT 
        t.card_id,
        t.timestamp,
        t.declined
    FROM transactions t
    WHERE  (
        SELECT COUNT(*)
        FROM transactions t2
        WHERE t2.card_id = t.card_id AND t2.timestamp > t.timestamp
    ) < 3
) AS ult_compras
GROUP BY card_id;

SELECT card_id as Targeta, total_declined as 'Num. rechazos ult. 3 trans.', Estado FROM ventas.estado_tarjetas;

-- Ejercicio 1: Cuantas tarjetas están activas
select count(*) from estado_tarjetas where Estado = 'Activa';

select count(id) from credit_cards;

# NIVEL 3
-- Crea una tabla con la que podamos unir los datos del nuevo archivo products.csv con la base de datos creada, 
-- teniendo en cuenta que desde transaction tienes product_ids. Genera la siguiente consulta: (Se ha hecho antes)
-- Ejercicio 1: Necesitamos conocer el número de veces que se ha vendido cada producto.
SELECT 
    product_name AS Producto, COUNT(transactions.id) AS Ventas
FROM
    products
        JOIN
    products_transactions ON products_transactions.product_id = products.id
        JOIN
    transactions ON transactions.id = products_transactions.transaction_id
GROUP BY product_name
ORDER BY Ventas DESC;


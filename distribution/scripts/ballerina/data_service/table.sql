CREATE TABLE Orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(255) NOT NULL,
    buyerID VARCHAR(255) NOT NULL,
    price FLOAT NOT NULL,
    volume INT NOT NULL
);

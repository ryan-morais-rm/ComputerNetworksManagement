USE tts;
CREATE TABLE IF NOT EXISTS cliente (
    id INT(11) UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
    matricula VARCHAR(11) NOT NULL,
    nome VARCHAR(100) NOT NULL
);
CREATE INDEX idx_matricula ON cliente (matricula);
INSERT INTO cliente (matricula, nome) VALUES ('20211380000', 'Aluno Teste'), ('1','ifpb');

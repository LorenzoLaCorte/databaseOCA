------------------------------------------------------------------------------
-- 			5. Creazione della Schema Logico
------------------------------------------------------------------------------

-- drop schema "oca" cascade;
create schema "oca";
set search_path to "oca";
set datestyle to "MDY";

CREATE TABLE Set_Icone(
nomeSet VARCHAR(20) PRIMARY KEY,
tema VARCHAR(20) NOT NULL
);

CREATE TABLE Gioco(
codGioco VARCHAR(3) PRIMARY KEY,
dadiRichiesti decimal(5,0) NOT NULL,
maxSquadre decimal(5,0) NOT NULL,
planciaDiGioco VARCHAR(300) NOT NULL,
nomeSet VARCHAR(20) REFERENCES Set_Icone,
dummy TEXT 
);

CREATE TABLE Sfida(
codSfida decimal(5,0) PRIMARY KEY,
dataOra TIMESTAMP NOT NULL,
durataMax INTEGER NOT NULL,
codGioco VARCHAR(3) REFERENCES Gioco NOT NULL,
moderata BOOLEAN NOT NULL DEFAULT 'false'
);

CREATE TABLE Casella_Gioco(
codCasella decimal(5,0) PRIMARY KEY, 
x decimal(6,2) NOT NULL,
y decimal(6,2) NOT NULL, 
numero smallint NOT NULL, 
codGioco VARCHAR(3) REFERENCES Gioco NOT NULL,
video VARCHAR(300),
tipologia VARCHAR(20) NOT NULL CHECK(tipologia='Inizio' OR tipologia='Fine'
									 		OR tipologia='Normale' OR tipologia='CasellaAvanza'
									 		OR tipologia='CasellaIndietreggia'), 
codCasellaArrivo decimal(5,0) REFERENCES Casella_Gioco,
UNIQUE(x, y, numero, codGioco)
);

CREATE TABLE Icona(
nomeIcona VARCHAR(20) PRIMARY KEY,
nomeSet VARCHAR(20) REFERENCES Set_Icone
);

CREATE TABLE Squadra(
nome VARCHAR(20), 
codSfida decimal(5,0) REFERENCES Sfida, 
numDadi smallint NOT NULL,
punteggioAttuale INTEGER NOT NULL DEFAULT 0,
nomeIcona VARCHAR(20) REFERENCES Icona,
PRIMARY KEY(nome, codSfida)
);

CREATE TABLE Casella_Podio(
x decimal(6,2),
y decimal(6,2), 
codGioco VARCHAR(3) REFERENCES Gioco, 
nome VARCHAR(20) NOT NULL, 
codSfida decimal(5,0) NOT NULL, 
posto smallint NOT NULL CHECK(posto=1 OR posto=2 OR posto=3),
PRIMARY KEY(x, y, codGioco),
FOREIGN KEY(nome, codSfida) REFERENCES Squadra
);

CREATE TABLE Turno_Di_Gioco(
codTurno SERIAL, 
nome VARCHAR(20) NOT NULL, 
codSfida decimal(5,0) NOT NULL,
codCasella decimal(5,0) REFERENCES Casella_Gioco NOT NULL,
PRIMARY KEY(codTurno, nome, codSfida),
FOREIGN KEY(nome, codSfida) REFERENCES Squadra
);

CREATE TABLE Utente(
nickname VARCHAR(20) PRIMARY KEY, 
eMail VARCHAR(50) NOT NULL, 
nome VARCHAR(20), 
cognome VARCHAR(20), 
dataN DATE
);

CREATE TABLE Partecipa(
nome VARCHAR(20),
codSfida decimal(5,0),
nickname VARCHAR(20) REFERENCES Utente,
FOREIGN KEY(nome, codSfida) REFERENCES Squadra,
PRIMARY KEY(nome, codSfida, nickname)
);

CREATE TABLE Dado(
codDado decimal(5,0) PRIMARY KEY, 
nome VARCHAR(20) NOT NULL,
codSfida decimal(5,0) NOT NULL,
valore decimal(1,0) NOT NULL CHECK (valore >=1 AND valore <=6), 
codGioco VARCHAR(3) REFERENCES Gioco NOT NULL,
FOREIGN KEY(nome, codSfida) REFERENCES Squadra
);

CREATE TABLE Quiz(
codQuiz decimal(5,0) PRIMARY KEY, 
testoHtml VARCHAR(200) NOT NULL UNIQUE, 
punteggio decimal(5,0) NOT NULL, 
tempoMassimo INTERVAL minute NOT NULL, 
immagine VARCHAR(300), 
codCasella decimal(5,0) REFERENCES Casella_Gioco NOT NULL
);

CREATE TABLE Task(
codTask decimal(5,0) PRIMARY KEY, 
testoHtml VARCHAR(200) NOT NULL UNIQUE, 
punteggio decimal(5,0) NOT NULL, 
tempoMassimo INTERVAL minute NOT NULL, 
codCasella decimal(5,0) REFERENCES Casella_Gioco NOT NULL
);

CREATE TABLE Moderatore(
nickname VARCHAR(20) PRIMARY KEY REFERENCES Utente
);

CREATE TABLE Risposta_Quiz(
codRisp decimal(5,0) PRIMARY KEY,
testoHtml VARCHAR(200) NOT NULL, 
immagine VARCHAR(300), 
codQuiz decimal(5,0) REFERENCES Quiz NOT NULL, 
nicknameModeratore VARCHAR(20) REFERENCES Moderatore,
corretta boolean NOT NULL,
scelta boolean,
UNIQUE(testoHtml, codQuiz)
);

CREATE TABLE Admin(
codAdmin decimal(5,0) PRIMARY KEY
);

CREATE TABLE Risposta_Task(
idFile VARCHAR(300) PRIMARY KEY,
codTask decimal(5,0) REFERENCES Task NOT NULL,
nicknameModeratore VARCHAR(20) REFERENCES Moderatore,
codAdmin decimal(5,0) REFERENCES Admin NOT NULL,
corretta boolean NOT NULL,
scelta boolean
);

CREATE TABLE Giocatore(
nickname VARCHAR(20) PRIMARY KEY REFERENCES Utente, 
codRisp decimal(5,0) REFERENCES Risposta_Quiz,
idFile VARCHAR(300) REFERENCES Risposta_Task
);
------------------------------------------------------------------------------
-- 			8. 	Interrogazioni e Vista
------------------------------------------------------------------------------

set search_path to "oca"; 
set datestyle to "MDY";

-- Interrogazioni relative al workload:
-- 1)	Determinare l’identificatore dei giochi che coinvolgono al più quattro squadre 
-- e richiedono l’uso di due dadi.

SELECT CodGioco
FROM Gioco
WHERE maxSquadre = 4 AND dadiRichiesti = 2;

-- senza lo schema large dovrebbe restituire 'DMA'

-- 2)	Determinare l’identificatore delle sfide relative a un gioco A di vostra scelta = OCA
-- (specificare direttamente l’identificatore nella richiesta) che, in alternativa:
-- •	hanno avuto luogo a gennaio 2021 e durata massima superiore a 2 ore, o
-- •	hanno avuto luogo a marzo 2021 e durata massima pari a 30 minuti.

SELECT CodSfida
FROM Sfida
WHERE 	codGioco = 'OCA' AND
		EXTRACT(YEAR FROM Sfida.dataOra) = 2021 AND
		((EXTRACT(MONTH FROM Sfida.dataOra) = 1 AND Sfida.durataMax > 120)
		OR (EXTRACT(MONTH FROM Sfida.dataOra) = 3 AND Sfida.durataMax = 30));

-- senza lo schema large, deve restituire il codice 1

-- 3)	Determinare le sfide, di durata massima superiore a 2 ore, dei giochi che richiedono almeno due dadi.
-- Restituire sia l’identificatore della sfida sia l’identificatore del gioco

SELECT Sfida.CodSfida, Gioco.CodGioco
FROM Dado NATURAL JOIN Gioco JOIN Sfida ON Gioco.codGioco = Sfida.codGioco
WHERE Sfida.durataMax > 120
GROUP BY Sfida.CodSfida, Gioco.CodGioco
HAVING COUNT(Gioco.CodGioco) >= 2;

-- restituisce: 1 OCA, 2 OCA, 4 DMA, 6 DMA


-----------		Interrogazioni aggiuntive:		-----------
-- 1)	La definizione di una vista che fornisca alcune informazioni riassuntive per ogni gioco: 
-- il numero di sfide relative a quel gioco disputate, la durata media di tali sfide, 
-- il numero di squadre e di giocatori partecipanti a tali sfide, 
-- i punteggi minimo, medio e massimo ottenuti dalle squadre partecipanti a tali sfide;

CREATE OR REPLACE VIEW infoNumSfide AS
SELECT Gioco.codGioco, COUNT(Sfida.CodSfida) AS NumSfideGiocate, AVG(Sfida.durataMax) AS durataMediaSfide
FROM Gioco NATURAL JOIN Sfida
GROUP BY Gioco.codGioco;

CREATE OR REPLACE VIEW infoNumSquadre AS
SELECT Sfida.CodGioco, COUNT(DISTINCT (Squadra.Nome, Squadra.CodSfida)) AS NumeroSquadre,
	COUNT(DISTINCT nickname) AS NumGiocatori
FROM Sfida NATURAL JOIN Squadra NATURAL JOIN Partecipa NATURAL JOIN Giocatore
GROUP BY Sfida.CodGioco;

CREATE OR REPLACE VIEW infoPuntiSquadre AS
SELECT Sfida.CodGioco, MIN(Squadra.PunteggioAttuale) AS PunteggioMinimo, 
	MAX(Squadra.PunteggioAttuale) AS PunteggioMassimo, 
	AVG(Squadra.PunteggioAttuale) AS PunteggioMedio
FROM Sfida NATURAL JOIN Squadra
-- la condizione nel where mi permette di considerare squadre con almeno un giocatore
-- per rimanere consistenti con "numSquadre" nella vista principale
-- in questo modo se abbiamo "numSquadre"=2 allora le operazione sui punteggi avvengono solo tra queste 2 squadre
WHERE (Squadra.Nome, Squadra.CodSfida) IN (SELECT Partecipa.Nome, Partecipa.CodSfida FROM Partecipa)
GROUP BY Sfida.CodGioco;

CREATE OR REPLACE VIEW infoGioco AS
SELECT *
FROM infoNumSfide NATURAL JOIN infoPuntiSquadre NATURAL JOIN infoNumSquadre;

SELECT * FROM infoGioco;

-- il numero di sfide si riferisce a quelle giocate da almeno una squadra
-- il numero di squadre si riferisce a quelle giocate da almeno un giocatore
-- se un giocatore partecipa a sfide diverse dello stesso gioco è contato una sola volta

-- 2) Le seguenti interrogazioni:
-- a. Determinare i giochi che contengono caselle a cui sono associati task;
SELECT DISTINCT CodGioco
FROM Gioco NATURAL JOIN Casella_Gioco NATURAL JOIN Task;

-- b. Determinare i giochi che non contengono caselle a cui sono associati task;
SELECT CodGioco
FROM Gioco
EXCEPT
SELECT CodGioco
FROM Gioco NATURAL JOIN Casella_Gioco NATURAL JOIN Task;

-- c. Determinare le sfide che hanno durata superiore alla durata media delle sfide relative 
-- allo stesso gioco
SELECT S.CodSfida
FROM Sfida S
WHERE S.durataMax > (
		SELECT AVG(durataMax) FROM Sfida NATURAL JOIN Gioco
			WHERE S.codGioco = Gioco.codGioco
			GROUP BY CodGioco);



------------------------------------------------------------------------------
-- 			7. Creazione della Schema Fisico
------------------------------------------------------------------------------

set search_path to "oca";
set datestyle to "MDY";

-- Interrogazioni relative al workload:
-- 1)	Determinare l’identificatore dei giochi che coinvolgono al più quattro squadre 
-- e richiedono l’uso di due dadi.

-- osserviamo il piano di esecuzione senza l'indice
ANALYZE;
EXPLAIN ANALYZE SELECT CodGioco
FROM Gioco
WHERE maxSquadre = 4 AND dadiRichiesti = 2;

/*
"Seq Scan on gioco  (cost=0.00..232.47 rows=6758 width=4) (actual time=0.025..3.719 rows=6761 loops=1)"
"  Filter: ((maxsquadre <= '4'::numeric) AND (dadirichiesti = '2'::numeric))"
"  Rows Removed by Filter: 4"
"Planning time: 0.188 ms"
"Execution time: 4.111 ms"
*/

-- creiamo un indice multiattributo ordinato su maxSquadre e dadiRichiesti
CREATE INDEX gioco_multi
ON Gioco(maxSquadre, dadiRichiesti);

-- guardiamo se esso è stato inserito
ANALYZE;
SELECT relname, relkind, indexrelid, indnatts, indisunique, indisprimary, indisclustered, indkey
	FROM pg_index JOIN pg_class ON indexrelid = oid
	JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
		WHERE nspname = 'oca' AND (relname LIKE 'gioco%');

-- osserviamo il piano di esecuzione con l'indice
ANALYZE;
EXPLAIN ANALYZE SELECT CodGioco
FROM Gioco
WHERE maxSquadre = 4 AND dadiRichiesti = 2;

/*
"Index Scan using gioco_multi on gioco  (cost=0.28..8.30 rows=1 width=4) (actual time=0.029..0.029 rows=1 loops=1)"
"  Index Cond: ((maxsquadre = '4'::numeric) AND (dadirichiesti = '2'::numeric))"
"Planning time: 0.155 ms"
"Execution time: 0.041 ms"
*/

-- 2)	Determinare l’identificatore delle sfide relative a un gioco A di vostra scelta = OCA
-- (specificare direttamente l’identificatore nella richiesta) che, in alternativa:
-- •	hanno avuto luogo a gennaio 2021 e durata massima superiore a 2 ore, o
-- •	hanno avuto luogo a marzo 2021 e durata massima pari a 30 minuti.

-- osserviamo il piano di esecuzione senza l'indice
ANALYZE;
EXPLAIN ANALYZE SELECT CodSfida
FROM Sfida
WHERE 	codGioco = 'OCA' AND
		EXTRACT(YEAR FROM Sfida.dataOra) = 2021 AND
		((EXTRACT(MONTH FROM Sfida.dataOra) = 1 AND Sfida.durataMax > 120)
		OR (EXTRACT(MONTH FROM Sfida.dataOra) = 3 AND Sfida.durataMax = 30));

/*
"Seq Scan on sfida  (cost=0.00..398.94 rows=1 width=5) (actual time=0.041..9.092 rows=3972 loops=1)"
"  Filter: (((codgioco)::text = 'OCA'::text) AND (date_part('year'::text, dataora) = '2021'::double precision) AND (((date_part('month'::text, dataora) = '1'::double precision) AND (duratamax > 120)) OR ((date_part('month'::text, dataora) = '3'::double precision) AND (duratamax = 30))))"
"  Rows Removed by Filter: 6026"
"Planning time: 0.739 ms"
"Execution time: 9.305 ms"
*/

-- Ci servono indici su codGioco, dataOra e durataMax.

CREATE INDEX sfida_codGioco
ON Sfida(codGioco);
CLUSTER Sfida USING sfida_codGioco;

CREATE INDEX sfida_dataOra
ON Sfida(dataOra);
 
CREATE INDEX sfida_durataMax
ON Sfida(durataMax);

-- guardiamo se sono stati inseriti
ANALYZE;
SELECT relname, relkind, indexrelid, indnatts, indisunique, indisprimary, indisclustered, indkey
	FROM pg_index JOIN pg_class ON indexrelid = oid
	JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
		WHERE nspname = 'oca' AND (relname LIKE 'sfida%');

-- osserviamo il piano di esecuzione con gli indici
EXPLAIN ANALYZE SELECT CodSfida
FROM Sfida
WHERE 	codGioco = 'OCA' AND
		EXTRACT(YEAR FROM Sfida.dataOra) = 2021 AND
		((EXTRACT(MONTH FROM Sfida.dataOra) = 1 AND Sfida.durataMax > 120)
		OR (EXTRACT(MONTH FROM Sfida.dataOra) = 3 AND Sfida.durataMax = 30));

/*
"Seq Scan on sfida  (cost=0.00..398.94 rows=1 width=5) (actual time=0.044..9.440 rows=3972 loops=1)"
"  Filter: (((codgioco)::text = 'OCA'::text) AND (date_part('year'::text, dataora) = '2021'::double precision) AND (((date_part('month'::text, dataora) = '1'::double precision) AND (duratamax > 120)) OR ((date_part('month'::text, dataora) = '3'::double precision) AND (duratamax = 30))))"
"  Rows Removed by Filter: 6026"
"Planning time: 1.603 ms"
"Execution time: 8.015 ms"
*/

-- 3) Determinare le sfide, di durata massima superiore a 2 ore, dei giochi che richiedono almeno due dadi. 
-- Restituire sia l’identificatore della sfida sia l’identificatore del gioco.

ANALYZE;
EXPLAIN ANALYZE SELECT Sfida.CodSfida, Gioco.CodGioco
FROM Dado NATURAL JOIN Gioco JOIN Sfida ON Gioco.codGioco = Sfida.codGioco
WHERE Sfida.durataMax > 120
GROUP BY Sfida.CodSfida, Gioco.CodGioco
HAVING COUNT(Gioco.CodGioco) >= 2;

/*
"GroupAggregate  (cost=2400.15..2635.13 rows=11749 width=9) (actual time=59.850..70.356 rows=7937 loops=1)"
"  Group Key: sfida.codsfida, gioco.codgioco"
"  Filter: (count(gioco.codgioco) >= 2)"
"  Rows Removed by Filter: 1"
"  ->  Sort  (cost=2400.15..2429.52 rows=11749 width=9) (actual time=59.835..64.701 rows=15875 loops=1)"
"        Sort Key: sfida.codsfida, gioco.codgioco"
"        Sort Method: external merge  Disk: 304kB"
"        ->  Hash Join  (cost=751.94..1199.90 rows=11749 width=9) (actual time=27.933..48.663 rows=15875 loops=1)"
"              Hash Cond: ((dado.codgioco)::text = (gioco.codgioco)::text)"
"              ->  Seq Scan on dado  (cost=0.00..173.98 rows=9998 width=4) (actual time=0.013..1.379 rows=9998 loops=1)"
"              ->  Hash  (cost=613.56..613.56 rows=7950 width=13) (actual time=12.635..12.635 rows=7938 loops=1)"
"                    Buckets: 2048 (originally 2048)  Batches: 32 (originally 8)  Memory Usage: 349kB"
"                    ->  Merge Join  (cost=27.55..613.56 rows=7950 width=13) (actual time=0.548..6.082 rows=7938 loops=1)"
"                          Merge Cond: ((gioco.codgioco)::text = (sfida.codgioco)::text)"
"                          ->  Index Only Scan using gioco_pkey on gioco  (cost=0.28..185.76 rows=6765 width=4) (actual time=0.135..0.648 rows=4615 loops=1)"
"                                Heap Fetches: 0"
"                          ->  Index Scan using sfida_codgioco on sfida  (cost=0.29..372.25 rows=7950 width=9) (actual time=0.009..2.600 rows=7938 loops=1)"
"                                Filter: (duratamax > 120)"
"                                Rows Removed by Filter: 2060"
"Planning time: 1.293 ms"
"Execution time: 71.519 ms"
*/

-- creo indice ordinato su Dado.codGioco e Gioco.codGioco per il merge join
-- Per la selezione abbiamo già l’indice ad albero su durataMax creato nel punto precedente.

CREATE INDEX gioco_codGioco
ON Gioco(codGioco);
CLUSTER Gioco USING gioco_codGioco;

CREATE INDEX dado_codGioco
ON Dado(codGioco);
CLUSTER Dado USING dado_codGioco;

-- osserviamo il piano di esecuzione con l'indice

ANALYZE;
EXPLAIN ANALYZE SELECT Sfida.CodSfida, Gioco.CodGioco
FROM Dado NATURAL JOIN Gioco JOIN Sfida ON Gioco.codGioco = Sfida.codGioco
WHERE Sfida.durataMax > 120
GROUP BY Sfida.CodSfida, Gioco.CodGioco
HAVING COUNT(Gioco.CodGioco) >= 2;

/*
"GroupAggregate  (cost=2214.99..2449.97 rows=11749 width=9) (actual time=29.337..36.820 rows=7937 loops=1)"
"  Group Key: sfida.codsfida, gioco.codgioco"
"  Filter: (count(gioco.codgioco) >= 2)"
"  Rows Removed by Filter: 1"
"  ->  Sort  (cost=2214.99..2244.37 rows=11749 width=9) (actual time=29.323..31.278 rows=15875 loops=1)"
"        Sort Key: sfida.codsfida, gioco.codgioco"
"        Sort Method: external merge  Disk: 296kB"
"        ->  Merge Join  (cost=86.94..1014.75 rows=11749 width=9) (actual time=1.956..19.057 rows=15875 loops=1)"
"              Merge Cond: ((sfida.codgioco)::text = (dado.codgioco)::text)"
"              ->  Index Scan using sfida_codgioco on sfida  (cost=0.29..372.25 rows=7950 width=9) (actual time=0.009..2.918 rows=7938 loops=1)"
"                    Filter: (duratamax > 120)"
"                    Rows Removed by Filter: 2060"
"              ->  Materialize  (cost=0.57..622.90 rows=9998 width=8) (actual time=0.022..7.466 rows=22692 loops=1)"
"                    ->  Merge Join  (cost=0.57..597.90 rows=9998 width=8) (actual time=0.019..5.404 rows=6822 loops=1)"
"                          Merge Cond: ((gioco.codgioco)::text = (dado.codgioco)::text)"
"                          ->  Index Only Scan using gioco_codgioco on gioco  (cost=0.28..185.76 rows=6765 width=4) (actual time=0.008..0.546 rows=4615 loops=1)"
"                                Heap Fetches: 0"
"                          ->  Index Only Scan using dado_codgioco on dado  (cost=0.29..270.26 rows=9998 width=4) (actual time=0.006..0.824 rows=6822 loops=1)"
"                                Heap Fetches: 0"
"Planning time: 1.830 ms"
"Execution time: 38.144 ms"
*/


------------------------------------------------------------------------------
-- 			8. 	Interrogazioni e Vista
------------------------------------------------------------------------------

-- Interrogazioni relative al workload:
-- 1)	Determinare l’identificatore dei giochi che coinvolgono al più quattro squadre 
-- e richiedono l’uso di due dadi.

SELECT CodGioco
FROM Gioco
WHERE maxSquadre = 4 AND dadiRichiesti = 2;

-- dovrebbe restituire 'DMA'

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

-- senza lo schema large, restituisce: 1 OCA, 2 OCA, 4 DMA, 6 DMA


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

-- senza schema large, dovrebbe restituire OCA

-- b. Determinare i giochi che non contengono caselle a cui sono associati task;
SELECT CodGioco
FROM Gioco
EXCEPT
SELECT CodGioco
FROM Gioco NATURAL JOIN Casella_Gioco NATURAL JOIN Task;

-- senza schema large, dovrebbe restituire "SCC" "RSK" "MNP" "DMA"
-- con schema large, restituisce tutti i giochi tranne "OCA"

-- c. Determinare le sfide che hanno durata superiore alla durata media delle sfide relative 
-- allo stesso gioco
SELECT S.CodSfida
FROM Sfida S
WHERE S.durataMax > (
		SELECT AVG(durataMax) FROM Sfida NATURAL JOIN Gioco
			WHERE S.codGioco = Gioco.codGioco
			GROUP BY CodGioco);
			
-- senza schema large dovrebbe restituire 1,2,6
-- ATTENZIONE: con schema large ci vuole qualche decina di secondi

------------------------------------------------------------------------------
-- 			9. 	Funzioni e Procedure
------------------------------------------------------------------------------

-- Specifica delle seguenti procedure/funzioni:

-- a. Funzione che determina le sfide che hanno durata superiore alla durata medie delle sfide
-- di un dato gioco, prendendo come parametro l’ID del gioco

CREATE OR REPLACE FUNCTION detSfide(IN IDGioco VARCHAR(3))
RETURNS VOID AS 
$$ 
DECLARE
	mediaSfideGioco INTEGER = 
			(SELECT AVG(durataMax) FROM Sfida WHERE Sfida.CodGioco = IDGioco);
	SfideGioco CURSOR FOR (SELECT CodSfida, durataMax FROM Sfida WHERE Sfida.CodGioco = IDGioco);
	IDSfida decimal(5,0);
	durataSfida INTEGER;
BEGIN

	OPEN SfideGioco;
	FETCH SfideGioco INTO IDSfida, durataSfida;
	
	RAISE NOTICE E'Sfide con durataMax maggiore della media delle durate delle sfide nel gioco % \n', IDGioco;

	-- stampe
	WHILE FOUND LOOP

			IF  durataSfida > mediaSfideGioco	THEN 
				RAISE NOTICE 'Codice Sfida: %', IDSfida;
				RAISE NOTICE E'Durata della sfida: % \n', durataSfida;
			
			END IF;

			FETCH SfideGioco INTO IDSfida, durataSfida;
			
	END LOOP;
	CLOSE SfideGioco;
	
END;
$$ 
LANGUAGE plpgsql;

-- IL RISULTATO VIENE STAMPATO TRAMITE NOTIFICHE NEL BOX "messages"
SELECT detSfide('OCA');

-- nello schema base (non large), per questo esempio, vengono stampate:
-- Codice Sfida: 1 \ Durata della sfida: 180 
-- Codice Sfida: 2 \ Durata della sfida: 180 

-- b. Funzione di scelta dell’icona da parte di una squadra in una sfida: possono essere scelte solo le
-- icone corrispondenti al gioco cui si riferisce la sfida che non siano già state scelte da altre squadre.

-- prendo in input una sfida,
-- guardo il gioco corrispondente alla sfida,
-- confronto le icone disponibili per il gioco con quelle usate nella sfida,
-- e ritorno la prima non usata,
-- oppure 'not_found' se non trovata

CREATE OR REPLACE FUNCTION sceltaIcona(IN IDSfida decimal(5,0))
RETURNS VARCHAR(20) AS 
$$ 
DECLARE
	-- acquisire le icone nel gioco della sfida e defirne un cursore
	iconeGioco CURSOR FOR (SELECT nomeIcona 
						   		FROM Sfida NATURAL JOIN Gioco NATURAL JOIN Set_Icone NATURAL JOIN Icona
						  		WHERE CodSfida = IDSfida);
								
	-- acquisire le icone usate in quella sfida e definirne un cursore
	iconeSfida CURSOR FOR (SELECT nomeIcona 
						   		FROM Sfida NATURAL JOIN Squadra
						  		WHERE CodSfida = IDSfida);

	iconaCorrente VARCHAR(20);
	iconaConfronto VARCHAR(20);
	flagFound BOOLEAN = 'false';
	
BEGIN

	OPEN iconeGioco;
	FETCH iconeGioco INTO iconaCorrente;
	
	-- confronto mano a mano le icone del gioco
	WHILE FOUND LOOP

		-- se essa non è tra quelle usate nella sfida
		-- (devo confrontarla con tutte le icone nella sfida: uso il flag)
		OPEN iconeSfida;
		FETCH iconeSfida INTO iconaConfronto;
		
		WHILE FOUND LOOP
			IF iconaCorrente = iconaConfronto THEN 
				flagFound = 'true';
			END IF;
			
			FETCH iconeSfida INTO iconaConfronto;
		END LOOP;
		CLOSE iconeSfida;

		-- se flagFound è true vuol dire che l'icona è già stata usata e quindi non posso ritornarla
		IF flagFound='false' THEN 
			-- allora ne ritorno il nome
			RETURN iconaCorrente;
		END IF;

		FETCH iconeGioco INTO iconaCorrente;
		
		flagFound = 'false'; -- resetto la flag

	END LOOP;
	CLOSE iconeGioco;

	-- se arrivo alla fine del ciclo e non ho ritornato nessuna icona,
	-- vuol dire che nessuna è disponibile e quindi ritorno 'not_found'
	
	RETURN 'not_found';
	
END;
$$ 
LANGUAGE plpgsql;

SELECT sceltaIcona(1); -- nello schema base dovrebbe ritornare not_found perché le 3 icone sono tutte usate

-- nello schema base dovrebbe ritornare 'cane' perché è la prima icona disponibile
SELECT sceltaIcona(3); 

-- nello schema base dovrebbe ritornare 'cane' perché è l'unica icona non usata (cervo e gatto sono usate)
SELECT sceltaIcona(5); 


------------------------------------------------------------------------------
-- 			10. 		Trigger
------------------------------------------------------------------------------

-- Definire i seguenti trigger:

-- a. Verifica del vincolo che nessun utente possa partecipare a sfide contemporanee;

-- utilizzo un trigger apposito per i vincoli, ovvero un CONSTRAINT TRIGGER
-- definiamo secondo il Paradigma ECA:
-- ON evento: 	quando un utente partecipa ad una squadra, che a sua volta sta partecipando a una sfida,
			-- 	che rischia di essere contemporanea ad un'altra
			-- 	quindi quando inseriamo una tupla in PARTECIPA
-- IF condizione: 	l'utente stia partecipando a due sfide contemporanee
-- THEN azione: 	sollevamento di un'eccezione

-- il controllo della condizione è così svolto
	-- NEW.nickname è il nome dell'utente
	-- guardo le sfide associate a questo nickname
	-- controllo che esse non siano contemporanee a NEW.codSfida
	-- NEW.codSfida è la sfida a cui sta partecipando la squadra a cui partecipa l'utente
	
CREATE OR REPLACE FUNCTION nonContempAux()
RETURNS trigger
AS
$$
DECLARE
	-- NEW.nickname è il nome dell'utente
	-- guardo le sfide associate a questo nickname
	SfideGiocatore CURSOR FOR 	(SELECT CodSfida, dataOra, durataMax 
							 	FROM Sfida NATURAL JOIN Squadra NATURAL JOIN Partecipa
							 	WHERE Partecipa.nickname = NEW.nickname);
	
	-- NEW.codSfida è la sfida a cui sta partecipando la squadra a cui partecipa l'utente
	-- partendo da questo attributo posso calcolarne i corrispondenti dataOra e durataMax
	newDataOra TIMESTAMP = (SELECT dataOra FROM Sfida WHERE codSfida = NEW.codSfida);
	newDurataMax INTEGER = (SELECT durataMax FROM Sfida WHERE codSfida = NEW.codSfida);

	thisSfida decimal(5,0);
	thisDataOra TIMESTAMP;
	thisDurataMax INTEGER;
	
	thisOraFine TIMESTAMP;
	newOraFine TIMESTAMP;

BEGIN
	-- controllo la condizione: l'utente stia partecipando a due sfide contemporanee
	
	-- controllo che le tuple di SfideGiocatore non siano contemporanee a NEW.codSfida
	-- NEW.codSfida è la sfida a cui sta partecipando la squadra a cui partecipa l'utente
	
	OPEN SfideGiocatore;
	FETCH SfideGiocatore INTO thisSfida, thisDataOra, thisDurataMax;
	
	WHILE FOUND LOOP
	
			-- orario di inizio: 	thisDataOra
			--						newDataOra
			
			-- orario di fine: 	(thisDataOra + thisDurataMax) 
			--					(newDataOra + newDurataMax)
			
			thisOraFine = thisDataOra + (INTERVAL '1 min' * thisDurataMax);
			newOraFine = newDataOra + (INTERVAL '1 min' * newDurataMax);
			
			-- eventuale debugging, molto utile per capire il funzionamento:
			-- RAISE NOTICE 'thisDataOra: %', thisDataOra; -- debug
			-- RAISE NOTICE 'thisDurataMax: %', thisDurataMax; -- debug
			-- RAISE NOTICE E'thisOraFine: % \n', thisOraFine; -- debug
			
			-- RAISE NOTICE 'newDataOra: %', newDataOra; -- debug
			-- RAISE NOTICE 'newDurataMax: %', newDurataMax; -- debug
			-- RAISE NOTICE E'newOraFine: % \n', newOraFine; -- debug
			
			-- non sono contemporanee se:
			-- l'inizio di NEW è dopo la fine di this
			-- oppure la fine di NEW è prima dell'inizio di this
			
			-- sono contemporanee se:
			-- non sono la stessa sfida e inoltre
			-- l'inizio di NEW è fra l'inizio e la fine di this
			-- oppure la fine di NEW è fra l'inizio e la fine di this
			
			IF 	(thisSfida <> NEW.codSfida) AND
				((newDataOra >= thisDataOra AND newDataOra <= thisOraFine)
				OR 	(newOraFine >= thisDataOra AND newOraFine <= thisOraFine))
			THEN
				RAISE EXCEPTION 'l''utente inserito sta partecipando a due sfide contemporanee';
			END IF;
			
			FETCH SfideGiocatore INTO thisSfida, thisDataOra, thisDurataMax;
			
	END LOOP;
	CLOSE SfideGiocatore;
	
	RETURN NEW;
END;
$$
LANGUAGE plpgsql;
 

-- DROP TRIGGER IF EXISTS nonContemp ON Partecipa; -- utile in fase di costruzione e debugging
 
CREATE CONSTRAINT TRIGGER nonContemp
AFTER INSERT ON Partecipa
NOT DEFERRABLE
FOR EACH ROW EXECUTE PROCEDURE nonContempAux();

-- Test: inserimento di una sfida contemporanea alla sfida con id=10, 
-- con inserimento di una squadra che la gioca e un giocatore che gioca nella squadra
INSERT INTO Sfida VALUES (110,'31-Jul-2020 22:47:12.3',30,'SCC');
INSERT INTO Squadra VALUES('XXXXX', 110, 1, 0, 'pizza');
INSERT INTO Partecipa VALUES('XXXXX', 110, 'giocatoreContemp'); -- giocatore

-- inserisco in una sfida contemporanea, infatti:
-- thisDataOra: 2020-07-31 22:37:12.3
-- thisDurataMax: 20
-- thisOraFine: 2020-07-31 22:57:12.3 

-- newDataOra: 2020-07-31 22:47:12.3
-- newDurataMax: 330
-- newOraFine: 2020-08-01 04:17:12.3 

-- risulta quindi che vi è un momento in cui le sfide sono giocate nello stesso momento

SELECT * FROM Partecipa; -- controllo che NON ci sia la tupla con ('XXXXX', 110, 'giocatoreContemp')
 

-- b. Mantenimento del punteggio corrente di ciascuna squadra in ogni sfida 
-- e inserimento delle icone opportune nella casella podio.

-- essendo questo un trigger per calcolo di dati derivati utilizzo un trigger normale
-- definiamo secondo il Paradigma ECA:
-- ON evento: inizia il nuovo turno di gioco
-- IF condizione: se la squadra ha risposto a quiz o task nel vecchio turno di gioco
-- THEN azione: aggiornare punteggioAttuale della squadra e aggiornare poi il podio

CREATE OR REPLACE FUNCTION aggiornaPodioPuntiAux()
RETURNS trigger
AS
$$
DECLARE
	-- ci possiamo riferire al turno di gioco precedente
	-- acquisendo (NEW.codTurno - 1); 
	turnoPrec NUMERIC = (NEW.codTurno - 1);
	
	-- cursore di ogni squadra che ha giocato il turno di gioco
	squadre CURSOR FOR 	(SELECT nome, codSfida FROM Turno_di_gioco WHERE codTurno = turnoPrec);
	
	nomeSquadra VARCHAR(20);
	prima VARCHAR(20);
	seconda VARCHAR(20);
	terza VARCHAR(20);

	IDSfida decimal(5,0);
	IDCasella decimal(5,0);
	IDQuiz decimal(5,0);
	IDTask decimal(5,0);
	SModerata BOOLEAN;
	ptiQuiz decimal(5,0);
	piuVotata decimal(5,0);
	giusta BOOLEAN;
	scelta BOOLEAN;
	ptiTask decimal(5,0);
	rispTask VARCHAR(300);

BEGIN
	-- se turnoPrec = 0 siamo al primo turno e non dobbiamo fare niente
	IF turnoPrec = 0 THEN
		RETURN NEW;
	END IF;
		
	-- per ogni squadra che ha giocato il turno di gioco
	OPEN squadre;
	FETCH squadre INTO nomeSquadra, IDSfida;
	
	WHILE FOUND LOOP
		RAISE NOTICE E'La squadra: %', nomeSquadra; -- debug

		-- acquisiamo la casella in cui è ricaduta la squadra
		IDCasella = (SELECT codCasella FROM CASELLA_GIOCO NATURAL JOIN TURNO_DI_GIOCO
						WHERE codTurno = turnoPrec AND nome = nomeSquadra AND codSfida = IDSfida);

		RAISE NOTICE 'IDCasella: %', IDCasella; -- debug
		
		-- acquisiamo quiz/task su quella casella
		IDQuiz = (SELECT codQuiz FROM Quiz NATURAL JOIN CASELLA_GIOCO WHERE codCasella = IDCasella);
		IDTask = (SELECT codTask FROM Task NATURAL JOIN CASELLA_GIOCO WHERE codCasella = IDCasella);
		
		RAISE NOTICE 'IDQuiz: %', IDQuiz; -- debug
		RAISE NOTICE 'IDTask: %', IDTask; -- debug

		SModerata = (SELECT moderata FROM Sfida WHERE codSfida = IDSfida);
		
		-- se la sfida non è moderata
		IF SModerata = 'false' THEN
			
			-- per i quiz:
			IF IDQuiz IS NOT NULL THEN
				ptiQuiz = (SELECT punteggio FROM Quiz WHERE codQuiz = IDQuiz);
				RAISE NOTICE 'ptiQuiz: %', ptiQuiz; -- debug

				-- prendere la risposta piu' votata
				-- prendere tutte le risposte associate a IDQuiz 
				-- della squadra identificata da nomeSquadra, IDSfida;
				piuVotata = (SELECT codRisp FROM RISPOSTA_QUIZ NATURAL JOIN GIOCATORE NATURAL JOIN PARTECIPA
					WHERE codQuiz = IDQuiz AND nome=nomeSquadra AND codSfida = IDSfida
					GROUP BY codRisp
					HAVING COUNT(*) >= ALL 
				 		(SELECT COUNT(*) FROM RISPOSTA_QUIZ NATURAL JOIN GIOCATORE NATURAL JOIN PARTECIPA
							WHERE codQuiz = IDQuiz AND nome=nomeSquadra AND codSfida = IDSfida
							GROUP BY codRisp));
							
				RAISE NOTICE 'piuVotata: %', piuVotata; -- debug
				
				giusta = (SELECT corretta FROM RISPOSTA_QUIZ WHERE codRisp = piuVotata);
				-- se è giusta
				IF giusta = 'true' THEN
					-- incrementa punteggioAttuale della squadra del punteggio del quiz
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale + ptiQuiz
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
					
				-- altrimenti
				ELSE 
					-- decrementa punteggioAttuale della squadra del punteggio del quiz
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale - ptiQuiz
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
					
				END IF;
			
			END IF;
			
			-- per i task:
			IF IDTask IS NOT NULL THEN
				ptiTask = (SELECT punteggio FROM Task WHERE codTask = IDTask);

				-- prendo la prima risposta inserita da un giocatore di quella squadra
				rispTask = (SELECT idFile FROM Risposta_Task NATURAL JOIN Giocatore NATURAL JOIN Partecipa
								WHERE codTask = IDTask 
									AND nome = nomeSquadra AND codSfida = IDSfida
									LIMIT 1);
				giusta = (SELECT corretta FROM Risposta_Task WHERE idFile = rispTask); 
				
				RAISE NOTICE 'rispTask: %', rispTask; -- debug
				RAISE NOTICE 'giusta: %', giusta; -- debug
				
				-- se è giusta
				IF giusta = 'true' THEN
					-- incrementa punteggioAttuale della squadra del punteggio del task
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale + ptiTask
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
				-- altrimenti
				ELSE
					-- decrementa punteggioAttuale della squadra del punteggio del task
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale - ptiTask
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
				END IF;
			END IF;

		RAISE NOTICE E'-----------------\n'; -- debug
		
		ELSE -- se la sfida è moderata
			-- per i quiz e per i task:
			IF IDQuiz IS NOT NULL THEN
				ptiQuiz = (SELECT punteggio FROM Quiz WHERE codQuiz = IDQuiz);
				-- prendi la risposta scelta dal moderatore
				scelta = (SELECT codRisp FROM RISPOSTA_QUIZ NATURAL JOIN GIOCATORE NATURAL JOIN PARTECIPA
							WHERE codQuiz = IDQuiz AND nome=nomeSquadra AND codSfida = IDSfida
								AND scelta = 'true');

				giusta = (SELECT corretta FROM RISPOSTA_QUIZ WHERE codRisp = scelta);

				-- se è giusta
				IF giusta = 'true' THEN
					-- incrementa punteggioAttuale della squadra del punteggio del quiz
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale + ptiQuiz
					WHERE nome = nomeSquadra AND codSfida = IDSfida;

				-- altrimenti
				ELSE 
					-- decrementa punteggioAttuale della squadra del punteggio del quiz
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale - ptiQuiz
					WHERE nome = nomeSquadra AND codSfida = IDSfida;

				END IF;
			
			END IF;
			
			-- per i task:
			IF IDTask IS NOT NULL THEN -- sono nel caso di task in una sfida moderata
				ptiTask = (SELECT punteggio FROM Task WHERE codTask = IDTask);

				-- prendo la risposta scelta dal moderatore
				rispTask = (SELECT idFile FROM Risposta_Task NATURAL JOIN Giocatore NATURAL JOIN Partecipa
								WHERE codTask = IDTask 
									AND nome = nomeSquadra AND codSfida = IDSfida
									AND scelta = 'true');
				giusta = (SELECT corretta FROM Risposta_Task WHERE idFile = rispTask); 
				
				-- se è giusta
				IF giusta = 'true' THEN
					-- incrementa punteggioAttuale della squadra del punteggio del task
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale + ptiTask
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
				-- altrimenti
				ELSE
					-- decrementa punteggioAttuale della squadra del punteggio del task
					UPDATE Squadra
					SET punteggioAttuale = punteggioAttuale - ptiTask
					WHERE nome = nomeSquadra AND codSfida = IDSfida;
				END IF;
			
			END IF;
			
		END IF;

		-- aggiorno il podio:
		-- prendo i punteggi di tutte le squadre di quella sfida 
		-- metto le squadre al loro posto
		
		-- metto la prima squadra
		prima = (SELECT nome FROM Squadra WHERE codSfida = IDSfida ORDER BY punteggioAttuale DESC
					LIMIT 1);
				
		UPDATE Casella_Podio
		SET nome = prima
		WHERE posto = 1;
		
		seconda = (SELECT nome FROM Squadra WHERE codSfida = IDSfida ORDER BY punteggioAttuale DESC
					LIMIT 1 OFFSET 1);
					
		UPDATE Casella_Podio
		SET nome = seconda
		WHERE posto = 2;
		
		terza = (SELECT nome FROM Squadra WHERE codSfida = IDSfida ORDER BY punteggioAttuale DESC
					LIMIT 1 OFFSET 2);
		
		UPDATE Casella_Podio
		SET nome = terza
		WHERE posto = 3;
		
		FETCH squadre INTO nomeSquadra, IDSfida;
		
	END LOOP;
	CLOSE squadre;
	
	RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS aggiornaPodioPunti ON Turno_Di_Gioco; -- utile in fase di costruzione e debugging

CREATE TRIGGER aggiornaPodioPunti
AFTER INSERT ON TURNO_DI_GIOCO
FOR EACH ROW
EXECUTE PROCEDURE aggiornaPodioPuntiAux();

-- guardo i punteggi prima di inserire
SELECT nome, punteggioAttuale FROM Squadra WHERE codSfida = 1 ORDER BY PunteggioAttuale DESC; 
-- guardo il podio prima di inserire
SELECT nome, posto FROM Casella_Podio WHERE codSfida = 1; 

-- Inserisco turno di gioco per far scattare il trigger
INSERT INTO TURNO_DI_GIOCO VALUES(2, 'ATeam', 1, 4);

-- ATeam ha giocato il primo turno rispondendo bene al quiz 1, quindi dovrebbe avere 5 pti

-- BTeam ha giocato il primo turno rispondendo male al quiz 2, quindi dovrebbe avere -3 pti
-- BTeam ha inoltre risposto bene al task e quindi dovrebbe avere +10pti
-- in totale quindi dovrebbe avere 7 pti

SELECT nome, punteggioAttuale FROM Squadra WHERE codSfida = 1 ORDER BY PunteggioAttuale DESC; 

-- XTeam ha 10 punti quindi primo; BTeam ne ha 7 quindi secondo; ATeam ne ha 5, quindi terzo
SELECT nome, posto FROM Casella_Podio WHERE codSfida = 1; 



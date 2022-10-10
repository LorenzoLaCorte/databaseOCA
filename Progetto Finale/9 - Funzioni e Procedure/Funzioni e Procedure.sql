------------------------------------------------------------------------------
-- 			9. 	Funzioni e Procedure
------------------------------------------------------------------------------

set search_path to "oca";
set datestyle to "MDY";

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

-- il risultato viene stampato tramite notifiche nel box "messages"
SELECT detSfide('OCA');

-- nello schema base, per questo esempio, vengono stampate:
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



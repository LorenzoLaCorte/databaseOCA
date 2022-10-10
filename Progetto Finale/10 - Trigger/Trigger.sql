------------------------------------------------------------------------------
-- 			10. 		Trigger
------------------------------------------------------------------------------

set search_path to "oca"; 
set datestyle to "MDY";

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



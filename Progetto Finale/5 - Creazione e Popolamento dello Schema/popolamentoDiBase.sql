------------------------------------------------------------------------------
-- 			Popolamento della Schema
------------------------------------------------------------------------------

set search_path to "oca";
set datestyle to "MDY";

--SET_ICONE(nomeSet, tema);

INSERT INTO Set_Icone VALUES ('set1','animali');
INSERT INTO Set_Icone VALUES ('set2','citta');
INSERT INTO Set_Icone VALUES ('set3','vip');
INSERT INTO Set_Icone VALUES ('set4','cibo');
INSERT INTO Set_Icone VALUES ('set5','indumenti');

--GIOCO(codGioco, dadiRichiesti, maxSquadre, planciaDiGioco, nomeSetSET_ICONE)

INSERT INTO Gioco VALUES ('OCA',5, 6,'sfondi/pdg1.png','set1');
INSERT INTO Gioco VALUES ('MNP',3, 4,'sfondi/pdg2.png','set1');
INSERT INTO Gioco VALUES ('RSK',4, 8,'sfondi/pdg3.png','set2');
INSERT INTO Gioco VALUES ('DMA',2, 4,'sfondi/pdg4.png','set3');
INSERT INTO Gioco VALUES ('SCC',3, 10,'sfondi/pdg5.png','set4');

-- da eseguire anche popolamentoGioco.sql


-- SFIDA(codSfida, dataOra, durataMax, codGiocoGIOCO, moderata)

INSERT INTO Sfida VALUES(1,'08-Jan-2021 21:56:32.5',180,'OCA');
INSERT INTO Sfida VALUES (2,'09-Nov-2007 23:15:32.5',180,'OCA');
INSERT INTO Sfida VALUES (3,'08-Mar-2012 21:46:32.5',30,'OCA');
INSERT INTO Sfida VALUES (4,'05-Aug-2013 03:56:55.5',330,'DMA');
INSERT INTO Sfida VALUES (5,'20-Sep-2002 17:47:32.6',30,'OCA');
INSERT INTO Sfida VALUES (6,'25-Aug-2003 04:56:55.5',450,'DMA');
INSERT INTO Sfida VALUES (7,'26-Apr-2005 11:34:15.9',80,'MNP');
INSERT INTO Sfida VALUES (8,'04-Jun-2009 15:23:37.7',50,'OCA');
INSERT INTO Sfida VALUES (9,'11-May-2013 18:16:25.1',360,'RSK');
INSERT INTO Sfida VALUES (10,'31-Jul-2020 22:37:12.3',20,'SCC');

-- da eseguire anche popolamentoSfida.sql

-- ICONA(nomeIcona, nomeSetSET_ICONE)
INSERT INTO Icona VALUES('cervo', 'set1');
INSERT INTO Icona VALUES('cane', 'set1');
INSERT INTO Icona VALUES('gatto', 'set1');
INSERT INTO Icona VALUES('tokyo', 'set2');
INSERT INTO Icona VALUES('palermo', 'set2');
INSERT INTO Icona VALUES('obama', 'set3');
INSERT INTO Icona VALUES('jordan', 'set3');
INSERT INTO Icona VALUES('elisabetta', 'set3');
INSERT INTO Icona VALUES('pasta', 'set4');
INSERT INTO Icona VALUES('pizza', 'set4');
INSERT INTO Icona VALUES('cappello', 'set5');
INSERT INTO Icona VALUES('scarpa', 'set5');

-- SQUADRA(nome, codSfidaSFIDA, numDadi, punteggioAttuale, nomeIcona);

INSERT INTO Squadra VALUES('ATeam', 1, 1, 0, 'cervo');
INSERT INTO Squadra VALUES('BTeam', 1, 1, 0, 'gatto');
INSERT INTO Squadra VALUES('XTeam', 1, 1, 10, 'cane');
INSERT INTO Squadra VALUES('CTeam', 3, 1, 0, 'cervo');
INSERT INTO Squadra VALUES('DTeam', 4, 1, 0, 'obama');
INSERT INTO Squadra VALUES('ETeam', 4, 1, 0, 'jordan');
INSERT INTO Squadra VALUES('HTeam', 4, 1, 170, 'elisabetta');
INSERT INTO Squadra VALUES('FTeam', 5, 1, 120, 'cervo');
INSERT INTO Squadra VALUES('GTeam', 5, 1, 40, 'gatto');
INSERT INTO Squadra VALUES('YYYYY', 10, 1, 0, 'pasta');


--CASELLA_GIOCO(codCasella, x, y, numero, codGiocoGIOCO, videoO, tipologia, codCasellaArrivoOCASELLA_GIOCO);

INSERT INTO Casella_gioco VALUES (1, 2.0, 3.0, 1, 'OCA', 'video/video1.mp4', 'Inizio', NULL);
INSERT INTO Casella_gioco VALUES (2, 5.0, 6.0, 2, 'OCA', NULL,'Normale', NULL);
INSERT INTO Casella_gioco VALUES (3, 2.0, 3.0, 3, 'OCA', 'video/video2.mp4', 'Normale', NULL);
INSERT INTO Casella_gioco VALUES (4, 4.0, 8.0, 4, 'OCA', NULL,'Normale', NULL);
INSERT INTO Casella_gioco VALUES (5, 7.0, 10.0, 5, 'OCA', 'video/video3.mp4', 'Fine', NULL);

-- TURNO_DI_GIOCO(codTurno, nomeSQUADRA, codSfidaSQUADRA, codCasellaCASELLA_GIOCO)

INSERT INTO TURNO_DI_GIOCO VALUES(1, 'ATeam', 1, 1);
INSERT INTO TURNO_DI_GIOCO VALUES(1, 'BTeam', 1, 2);
-- INSERT INTO TURNO_DI_GIOCO VALUES(2, 'BTeam', 1, 5);

--UTENTE(nickname, eMail, nomeO, cognomeO, dataNO);

INSERT INTO UTENTE VALUES ('Lorenzooo', 'lorenzo@hotmail.it', 'Lorenzo', 'Ricciotti', '2001-09-28');
INSERT INTO UTENTE VALUES ('Gianchi', 'giancarlo@libero.it', 'Giancarlo', 'Limoni', '1999-02-18');
INSERT INTO UTENTE VALUES ('XxTritolo', 'luca@hotmail.it', '2002-11-11');
INSERT INTO UTENTE VALUES ('TheBrave', 'riccardo@gmail.com', 'Riccardo', NULL);
INSERT INTO UTENTE VALUES ('Luchino78', 'luca@libero.it', 'Luca', 'Ribelle', NULL);
INSERT INTO UTENTE VALUES ('xxDraghetta92', 'Draga92@hotmail.it', 'Carla', 'Ricciotti', '2003-09-28');
INSERT INTO UTENTE VALUES ('pippoPlutoxD', 'pippoxD@libero.it', NULL, NULL, '1995-02-18');
INSERT INTO UTENTE VALUES ('xxSpaccoTutto', 'Spacco@hotmail.it', NULL, NULL, '2001-11-11');
INSERT INTO UTENTE VALUES ('TheDisc', 'TheDisc@gmail.com', NULL, NULL, NULL);
INSERT INTO UTENTE VALUES ('Luchino2002', 'Luchino@libero.it', NULL, NULL, NULL);
INSERT INTO UTENTE VALUES ('Lax99', 'adfs@libero.it', NULL, NULL, NULL);
INSERT INTO UTENTE VALUES ('Rix99', 'afkafs@libero.it', NULL, NULL, NULL);
INSERT INTO UTENTE VALUES ('Paperina87', 'safde@libero.it', NULL, NULL, NULL);
INSERT INTO UTENTE VALUES ('giocatoreContemp', 'giocatoreContemporaneo@libero.it', NULL, NULL, NULL);

--MODERATORE(nicknameUTENTE);

INSERT INTO MODERATORE VALUES ('Lorenzooo');
INSERT INTO MODERATORE VALUES ('Gianchi');
INSERT INTO MODERATORE VALUES ('XxTritolo');
INSERT INTO MODERATORE VALUES ('TheBrave');
INSERT INTO MODERATORE VALUES ('Luchino78');

-- PARTECIPA(nomeSQUADRA, codSfidaSFIDA, nicknameUTENTE);

INSERT INTO PARTECIPA VALUES('ATeam', 1, 'xxDraghetta92'); -- giocatore
INSERT INTO PARTECIPA VALUES('ATeam', 1, 'pippoPlutoxD'); -- giocatore
INSERT INTO PARTECIPA VALUES('ATeam', 1, 'xxSpaccoTutto'); -- giocatore
INSERT INTO PARTECIPA VALUES('BTeam', 1, 'TheDisc'); -- giocatore
INSERT INTO PARTECIPA VALUES('BTeam', 1, 'Luchino2002'); -- giocatore
INSERT INTO PARTECIPA VALUES('FTeam', 5, 'Lax99'); -- giocatore
INSERT INTO PARTECIPA VALUES('GTeam', 5, 'Rix99'); -- giocatore
INSERT INTO PARTECIPA VALUES('HTeam', 4, 'Paperina87'); -- giocatore
INSERT INTO PARTECIPA VALUES('YYYYY', 10, 'giocatoreContemp'); -- giocatore

-- CASELLA_PODIO(x, y, codGiocoGIOCO, nomeSQUADRA, codSfidaSFIDA, posto);

INSERT INTO CASELLA_PODIO VALUES(15, 15, 'OCA', 'XTeam', 1, 1);
INSERT INTO CASELLA_PODIO VALUES(25, 25, 'OCA', 'ATeam', 1, 2);
INSERT INTO CASELLA_PODIO VALUES(35, 35, 'OCA', 'BTeam', 1, 3);

-- DADO(codDado, NomeSQUADRA, codSfidaSFIDA, valore, codGiocoGIOCO);

INSERT INTO DADO VALUES(1, 'ATeam', 1, 1, 'OCA');
INSERT INTO DADO VALUES(2, 'BTeam', 1, 1, 'OCA');
INSERT INTO DADO VALUES(3, 'XTeam', 1, 6, 'RSK');
INSERT INTO DADO VALUES(4, 'CTeam', 3, 5, 'DMA');
INSERT INTO DADO VALUES(5, 'ETeam', 4, 1, 'DMA');

-- da eseguire anche popolamentoDado.sql

--QUIZ(codQuiz, testoHtml, punteggio, tempoMassimo, immagineO, codCasellaCASELLA_GIOCO);

INSERT INTO Quiz VALUES (1,'vocali in anna?',		5, '02' ,'IMG1',1);
INSERT INTO Quiz VALUES (2,'vocali in pera?',		3, '01', 'IMG2',2);
INSERT INTO Quiz VALUES (3,'consonanti in ciao?',	2, '01', 'IMG3',3);
INSERT INTO Quiz VALUES (4,'vocali in lollo?',		10, '05', 'IMG4',4);
INSERT INTO Quiz VALUES (5,'anna palindromo?',		7, '03', 'IMG5',5);

--TASK(codTask, testoHtml, punteggio, tempoMassimo, codCasellaCASELLA_GIOCO);

INSERT INTO Task VALUES (1,'colore preferito',10,'06',2);
/*INSERT INTO Task VALUES (2,'animale preferito',3,'02',2);
INSERT INTO Task VALUES (3,'frutto preferito',6,'05',1);
INSERT INTO Task VALUES (4,'gioco preferito',2,'07',5);
INSERT INTO Task VALUES (5,'pizza preferita',8,'10',4);*/

-- RISPOSTA_QUIZ(codRisp, testoHtml, immagineO, codQuizQUIZ, nicknameModeratoreUTENTEO, corretta, sceltaO)
-- scelta quando non è specificata è null

INSERT INTO RISPOSTA_QUIZ VALUES (1, 'due', 'icona1/Quiz.png', 1, NULL, 'true');
INSERT INTO RISPOSTA_QUIZ VALUES (2, 'tre', 'icona1/Quiz.png', 1, NULL, 'false');
INSERT INTO RISPOSTA_QUIZ VALUES (3, 'due', 'icona1/Quiz.png', 2, NULL, 'true');
INSERT INTO RISPOSTA_QUIZ VALUES (4, 'cinque', 'icona1/Quiz.png', 2, NULL, 'false');
INSERT INTO RISPOSTA_QUIZ VALUES (5, 'una', 'icona1/Quiz.png', 3, NULL, 'true');
INSERT INTO RISPOSTA_QUIZ VALUES (6, 'ventisei', 'icona1/Quiz.png', 3, NULL, 'false');
INSERT INTO RISPOSTA_QUIZ VALUES (7, 'nove', 'icona1/Quiz.png', 3, NULL, 'false');
INSERT INTO RISPOSTA_QUIZ VALUES (8, 'due', 'icona1/Quiz.png', 4, NULL, 'true');
INSERT INTO RISPOSTA_QUIZ VALUES (9, 'nove', 'icona1/Quiz.png', 4, NULL, 'false');
INSERT INTO RISPOSTA_QUIZ VALUES (10, 'si', 'icona1/Quiz.png', 5, NULL, 'true');
INSERT INTO RISPOSTA_QUIZ VALUES (11, 'no', 'icona1/Quiz.png', 5, NULL, 'false');



--ADMIN(codAdmin);

INSERT INTO ADMIN VALUES (1);
INSERT INTO ADMIN VALUES (2);
INSERT INTO ADMIN VALUES (3);
INSERT INTO ADMIN VALUES (4);
INSERT INTO ADMIN VALUES (5);

--RISPOSTA_TASK(idFile, codTaskTASK, nicknameModeratoreUTENTE, codAdminADMIN, corretta, sceltaO)
-- scelta quando non è specificata è null

INSERT INTO RISPOSTA_TASK VALUES (1, 1, NULL, 1, 'true');
INSERT INTO RISPOSTA_TASK VALUES (2, 1, NULL, 1, 'false');
/*
INSERT INTO RISPOSTA_TASK VALUES (3, 3, 'Gianchi', 1, 'false');
INSERT INTO RISPOSTA_TASK VALUES (4, 4, 'TheBrave', 1, 'true');
INSERT INTO RISPOSTA_TASK VALUES (5, 5, 'TheBrave', 1, 'true');
*/

--GIOCATORE(nicknameUTENTE, codRispRISPOSTA_QUIZO, idFileRISPOSTA_TASKO);

INSERT INTO GIOCATORE VALUES ('xxDraghetta92', 1, NULL); -- risponde al quiz correttamente
INSERT INTO GIOCATORE VALUES ('pippoPlutoxD', 1, NULL); -- risponde al quiz correttamente
INSERT INTO GIOCATORE VALUES ('xxSpaccoTutto', 2, NULL); -- risponde al quiz male
INSERT INTO GIOCATORE VALUES ('TheDisc', 4, 1); -- risponde al quiz male, mentre al task bne
INSERT INTO GIOCATORE VALUES ('Luchino2002', 4, NULL); -- risponde al quiz male
INSERT INTO GIOCATORE VALUES ('Lax99', 2, NULL);
INSERT INTO GIOCATORE VALUES ('Rix99', 1, 1);
INSERT INTO GIOCATORE VALUES ('Paperina87', 2, NULL);
INSERT INTO GIOCATORE VALUES ('giocatoreContemp', 1, NULL);



----	il numero di tuple contenute in ogni tabella e il numero di blocchi occupati su disco 	--
ANALYZE;
SELECT relname, relpages, reltuples
	FROM pg_class JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
		WHERE nspname = 'oca' AND relkind='r';
		
/*	NomeTabella 		NumeroPagine 	Numero Tuple
	"set_icone"			1				5
	"sfida"				74				9998
	"icona"				1				12
	"casella_podio"		1				3
	"turno_di_gioco"	1				2
	"partecipa"			1				9
	"gioco"				131				6765
	"squadra"			1				10
	"dado"				74				9998
	"casella_gioco"		1				5
	"quiz"				1				5
	"task"				1				1
	"moderatore"		1				5
	"admin"				1				5
	"utente"			1				14
	"risposta_quiz"		1				11
	"risposta_task"		1				2
	"giocatore"			1				9
*/

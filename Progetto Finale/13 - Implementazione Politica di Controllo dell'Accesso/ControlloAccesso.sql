------------------------------------------------------------------------------
-- 			13. Controllo dell'Accesso
------------------------------------------------------------------------------

set search_path to "oca";

-- creiamo i vari ruoli
CREATE ROLE utente;
CREATE ROLE giocatore;
CREATE ROLE gameadmin;
CREATE ROLE gamecreator; 

-- garantiamo i privilegi a utente
GRANT USAGE ON SCHEMA "oca" TO utente;

GRANT select
ON giocatore, gioco, moderatore, partecipa, sfida, squadra, utente
TO utente;	

GRANT insert
ON giocatore, moderatore, partecipa, squadra
TO utente;	

GRANT update
ON utente
TO utente;	

-- passiamo tutti i privilegi di utente a giocatore
GRANT USAGE ON SCHEMA "oca" TO giocatore;

GRANT utente TO giocatore;

-- e inoltre aggiungiamo a giocatore i privilegi mancanti
GRANT select
ON casella_gioco, casella_podio, dado, icona, quiz, risposta_quiz, risposta_task, set_icone, task, turno_di_gioco
TO giocatore;	

GRANT insert
ON risposta_quiz, risposta_task
TO giocatore;	

GRANT update
ON dado
TO giocatore;	

-- garantiamo i privilegi a gameadmin
GRANT USAGE ON SCHEMA "oca" TO gameadmin;

GRANT select
ON ALL TABLES IN SCHEMA "oca"
TO gameadmin;	

GRANT insert
ON admin, risposta_task, sfida, turno_di_gioco
TO gameadmin;	

GRANT update
ON admin, casella_podio, risposta_task, sfida, turno_di_gioco, squadra
TO gameadmin;	

GRANT delete
ON admin, risposta_task, sfida, turno_di_gioco
TO gameadmin;	


-- garantiamo tutti i privilegi a gamecreator
GRANT USAGE ON SCHEMA "oca" TO gamecreator;

GRANT select, insert, update, delete
ON ALL TABLES IN SCHEMA "oca"
TO gamecreator;	


-- controllo che siano stati inserite le autorizzazioni
set search_path to 'information_schema';
SELECT grantee, table_name, privilege_type  FROM table_privileges 
	WHERE (grantee = 'utente' 
		OR grantee = 'giocatore' 
		OR grantee = 'gameadmin' 
		OR grantee = 'gamecreator')
		AND table_schema='oca'
		ORDER BY grantee;
		
-- testiamo i privilegi ponendoci come utente
SET ROLE utente;

-- proviamo a leggere la tabella admin, a cui l'utente NON può accedere
SELECT * FROM admin;
-- ci viene infatti visualizzato: ERRORE:  permesso negato per la relazione admin

-- proviamo invece a leggere la tabella UTENTE, che dovrebbe essere possibile
SELECT * FROM utente;
-- ed infatti ci viene restituita la tabella utente


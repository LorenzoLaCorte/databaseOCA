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
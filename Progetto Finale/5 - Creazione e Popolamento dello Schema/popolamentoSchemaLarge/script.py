import random

def main():
	outF = open("1. popolamentoGioco.sql", "w")
	outD = open("2. popolamentoDado.sql", "w")
	outS = open("3. popolamentoSfida.sql", "w")

	line = "set search_path to \"oca\";\nset datestyle to \"MDY\";\n\n";

	outF.write(line)
	outD.write(line)
	outS.write(line)

	lettere = ['A', 'B', 'C', 'D','E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']

	giochi = []

	numeri = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

	setGiochi = ['set1', 'set2', 'set3', 'set4', 'set5']

	

	for x in lettere:

		for y in lettere:


			for z in numeri:

				# INSERT INTO Gioco VALUES ('OCA',6,'sfondi/pdg1.png','ciao');
				line = "INSERT INTO Gioco VALUES ('" + str(x) + str(y) + str(z) + "', 2, 3, 'sfondo.png', '" + random.choice(setGiochi) + "' , 'Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.');"

				# INSERT INTO DADO VALUES(1, 'ATeam', 1, 1, 'OCA');

				outF.write(line)
				outF.write("\n")

				stringa = str(str(x) + str(y) + str(z))

				giochi.append(stringa)				



	for num in range(6, 9999):

		sceltaGioco = random.choice(giochi)

		# INSERT INTO DADO VALUES(1, 'ATeam', 1, 1, 'OCA');
		line2 = "INSERT INTO DADO VALUES (" + str(num) + ", 'ATeam', 1, 1, '" + str(sceltaGioco) + " ');"

		outD.write(line2)
		outD.write("\n")



	month = ['Jan', 'Mar']

	for num in range(11, 9999):

		sceltaGioco = random.choice(giochi)

		# INSERT INTO Sfida VALUES(1,'08-Oct-2020 21:56:32.5','02:00','OCA');
		line3 = "INSERT INTO Sfida VALUES (" + str(num) + ", '08-" + str(random.choice(month)) + "-2021 21:56:32.5', " + str(random.randint(0, 600)) +  ",'OCA');"

		outS.write(line3)
		outS.write("\n")
	
	outF.close()
	outD.close()
	outS.close()


main()
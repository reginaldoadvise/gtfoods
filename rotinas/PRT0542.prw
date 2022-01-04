#Include 'Totvs.ch'
#Include 'CATTMS.ch'

/*/{Protheus.doc} PRT0542
Realiza a persistência do arquivo CTE/CRT importado pelo programa PRT0527.
@author Paulo Carvalho
@since 27/12/2018
@param cArqImp, caracter, Arquivo escolhido pelo usuário para importação.
@version 1.01
@type User Function
/*/
User Function PRT0542(aDados)

	Local aArea			:= GetArea()
	Local aAuxItem		:= {}
	Local aCabec		:= {}
	Local aItens		:= {}
	Local aLinha		:= {}
	Local aICMS			:= {}
	Local i
    Local cMensagem		:= ""
	Local cStatus		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local lPercICMS		:= .F.
	Local nAux			:= 1	// 1-OK / 2-Imp. Erro / 3-N Imp.
	Local nLinhas		:= 0
	Local nOk			:= 0
	Local nErro			:= 0
	Local nNImp			:= 0
	Local nPercIcms		:= 0
	Local cSvFil		:= cFilAnt
	Private aLog		:= {}
	Private cCancel		:= ""
	Private cCliente	:= ""
	Private cDocumento	:= ""
	Private cFilArq		:= ""
	Private cId			:= ""
	Private lImp		:= .T.
	Private nLinha		:= 0
	Private nValor		:= 0

	nLinhas := Len(aDados)

	ProcRegua(nLinhas)

	For i := 1 to Len(aDados)

		// Reinicializa os arrays de cabeçalho e itens
		aAuxItem	:= {}
		aCabec		:= {}
		aItens 		:= {}

		cFilAnt := aDados[i][1]

		// Define o Id do arquivo CTE/CRT
		cId := aDados[i][3]

		// Incrementa a contagem da Linha
		nLinha++

		// Cria a régua de processamento
		IncProc(CAT542005 + AllTrim(Str(nLinha))) // "Importando linha: "

		cDocumento := aDados[i][33]

		dbselectarea("SA1")
		SA1->( DbSetOrder(3) )
		If !SA1->( DbSeek( xFilial("SA1") + aDados[i][4] ) )
			cCliente   := ""
			cStatus := "E"
			cMensagem := "Cliente não encontrado para o CNPJ/CPF: "+aDados[i][4]
			cCancelLog := Space(TamSX3("UQF_CANCEL")[1])

			// Adicion o log ao array
			Aadd(aLog, {aDados[i][1], Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
						cMensagem, nLinha, "", cStatus, cCancelLog, cBlqEmail, !lImp})
			
		Else
			cCliente   := SA1->A1_COD
		Endif

		nPercIcms := Round( ( aDados[i][21] / aDados[i][20] ) * 100 ,2)

		cFilArq := aDados[i][1]
		cCancel := aDados[i][36]

		Aadd(aCabec, aDados[i][1]) //1 Filial
		Aadd(aCabec, aDados[i][2]) //2 CRT = "ZCRT", CTRC  =  "ZTRC"
		Aadd(aCabec, "") //3 
		Aadd(aCabec, "") //4 
		Aadd(aCabec, "") //5 
		Aadd(aCabec, "") //6 
		Aadd(aCabec, SA1->A1_COD ) //7 
		Aadd(aCabec, SA1->A1_LOJA ) //8 
		Aadd(aCabec, "") //9 
		Aadd(aCabec, 1) //10 
		Aadd(aCabec, aDados[i][9] ) //11 
		Aadd(aCabec, "BRL") //12 
		Aadd(aCabec, aDados[i][21]) //13 
		Aadd(aCabec, "") //14 
		Aadd(aCabec, "CTE") //15 
		Aadd(aCabec, aDados[i][33]) //16 
		Aadd(aCabec, "") //17 
		Aadd(aCabec, "") //18 
		Aadd(aCabec, "") //19 
		Aadd(aCabec, "210121") //20 CENTRO DE CUSTO 
		Aadd(aCabec, aDados[i][8] ) //21 
		Aadd(aCabec, aDados[i][11] + ";" + aDados[i][12] ) //22  UQD_MUNCOL
		Aadd(aCabec, aDados[i][34]) //23 UQD_UFFOR
		Aadd(aCabec, "") //24 
		Aadd(aCabec, aDados[i][35]) //25 UQD_UFDES
		Aadd(aCabec, aDados[i][36]) //26 UQD_CANCEL
		Aadd(aCabec, aDados[i][18] ) //27 
		Aadd(aCabec, "") //28 
		Aadd(aCabec, aDados[i][8] ) //29 
		Aadd(aCabec, "") //30 
		Aadd(aCabec, aDados[i][6] ) //31 
		Aadd(aCabec, "") //32 
		Aadd(aCabec, aDados[i][37] ) //33 UQD_TIPOCT
		Aadd(aCabec, "") //34 
		Aadd(aCabec, "") //35 
		Aadd(aCabec, aDados[i][8] ) //36 
		Aadd(aCabec, nPercIcms) 	//37 
		Aadd(aCabec, aDados[i][19]) //38 
		Aadd(aCabec, aDados[i][26]) //39 
		Aadd(aCabec, aDados[i][20]) //40

		Aadd(aCabec, aDados[i][25]) //41 BASPIS
		Aadd(aCabec, aDados[i][25]) //42 BASCOF
		Aadd(aCabec, aDados[i][28]) //43 VLRPIS
		Aadd(aCabec, aDados[i][30]) //44 VLRCOF
		Aadd(aCabec, aDados[i][27]) //45 ALQPIS
		Aadd(aCabec, aDados[i][29]) //46 ALQCOF
		Aadd(aCabec, aDados[i][38]) //47 UQD_CHVREF

		//Filial Produto , Valor
		aAdd(aItens,{aDados[i][1],"FRETE",aDados[i][9]})

		lPercICMS := .F.
		aICMS := {}

		// Se não houver nenhum item no arquivo
		/*If nIniItens < nQtdeCampos
			// Define os itens do arquivo CTE/CRT
			For nA := nIniItens To nQtdeCampos
				Aadd(aAuxItem, aLinha[nA])
			Next

			// Cria um array bidimensional no padrão {Documento, {Itens}}
			aItens := fArrayItem(aAuxItem)
		EndIf
		*/

		// -----------------------------------------------------------------------
		// Estrutura do array aCabec
		// -----------------------------------------------------------------------
		// aLinha[1]	->	Filial emissora do conhecimento.
		// aLinha[2]	->	Tipo de Contrato. Ex: CRT = “ZCRT”, CTRC  =  “ZTRC”
		// aLinha[3]	->	Código da Companhia: “2020” = Brasil, “1020” = Argentina
		// aLinha[4]	->	Linda de Produto
		// aLinha[5]	->	Canal de Distribuição
		// aLinha[6]	->	Escritório de Vendas
		// aLinha[7]	->	Código do Cliente
		// aLinha[8]	->	Número do Material
		// aLinha[9]	->	Quantidade de Serviços
		// aLinha[10]	->	Valor do Conhecimento
		// aLinha[11]	->	Moeda
		// aLinha[12]	->	Taxa de ICMS
		// aLinha[13]	->	Filial
		// aLinha[14]	->	Indicador de CTR/CTRC
		// aLinha[15]	->	Número CTR/CTRC
		// aLinha[16]	->	Indicador de ICMS
		// aLinha[17]	->	Indicador Brasil/Argentina
		// aLinha[18]	->	Contrato Mestre
		// aLinha[19]	->	Centro de Custo
		// aLinha[20]	->	Data de Emissão do Conhecimento
		// aLinha[21]	->	Cidade da Coleta
		// aLinha[22]	->	UF Fornecedor
		// aLinha[23]	->	UF de Coleta
		// aLinha[24]	->	UF Destino
		// aLinha[25]	->	Cancelamento
		// aLinha[26]	->	CFOP
		// aLinha[27]	->	Identificador de Pagador
		// aLinha[28]	->	Data Viagem
		// aLinha[29]	->	Fatura do Cliente
		// aLinha[30]	->	Chave do CTE
		// -----------------------------------------------------------------------

		// Se não houver nenhum item no arquivo e for uma inclusão ou reprocessamento
		If Empty(aItens) .And. cCancel <> "C"
			nNImp++
			cStatus := "E"
			cMensagem := CAT542006 + aLinha[14] + CAT542009 // "O arquivo CTE/CRT" + " não contém itens que compõe o valor do frete."
			cCancelLog := Space(TamSX3("UQF_CANCEL")[1])

			// Adicion o log ao array
			Aadd(aLog, {aDados[i][1], Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
						cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})

		EndIf

		// Se o arquivo e seus itens são válidos para serem importados para o sistema
		If fVldArquivo(aCabec, aItens, nLinha)
			// Incrementa um arquivo com erro
			If aLog[Len(aLog)][Len(aLog[1])]
				If aLog[Len(aLog)][9] == "I"
					// Incrementa um arquivo processado com sucesso
					nOk++
					nAux := 1
				ElseIf aLog[Len(aLog)][9] == "E"
					nErro++
					nAux := 2
				EndIf

				// Grava o arquivo no sistema
				fGrvArquivo(aCabec, aItens, nLinha, nAux)
				nAux := 1
			EndIf
		Else
			//nNImp++
			nAux := 3
		EndIf

		cFilAnt := cSvFil
	Next i

	// Realiza a gravação das ocorrências de log.
	fGrvLog(aLog)

	If !l527Auto
		cMensagem 	:=  CAT542010 + CRLF +; //Importação CTE/CRT finalizada. Verifique o resultado abaixo.
						CRLF + CAT542011 + cValToChar(nOk) + CRLF +; //Itens importados:
						CAT542012 + cValToChar(nErro) + CRLF +; //Itens importados com erros:
						CAT542013 + cValToChar(nNImp) + CRLF +; //Itens não importados:
						CRLF + CAT542014 //Deseja visualizar o log de importação?

		If MsgYesNo(cMensagem, cCadastro)
			// Chama o programa de visualização de log de registros.
			U_PRT0533("UQF", .T.)
		EndIf
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc} fArrayItem
Cria um array bidimensional com os itens do arquivo CTE/CRT no padrão produto - valor.
@author Paulo Carvalho
@since 28/12/2018
@param aItem, array, array contendo os itens do arquivo CTE/CRT conforme lidos no arquivo.
@return aItens, array, array bidimencional no padrão produto - valor.
@version 1.01
@type Static Function
/*/
Static Function fArrayItem(aItem)

	Local aAux		:= {}
	Local aItens	:= {}

	Local nI

	// Adiciona o primeiro item ao array auxiliar
	Aadd(aAux, aItem[1])

	// Inicia a leitura do array a partir do segundo elemento
	For nI := 2 To Len(aItem)
		// Se o índice atual do array não é divisivel por 2
		If Mod(nI, 2) <> 0
			// Adiciona o array aAux como elemento de aItens
			Aadd(aItens, aAux)

			// Limpa array aAux para produção de nova linha
			aAux := {}

			// Adiciona o elemento do índice atual ao array aAux
			Aadd(aAux, aItem[nI])
		// Se o índice atual do array é divisivel por 2
		Else
			// Adiciona o elemento do índice atual ao array aAux
			Aadd(aAux, aItem[nI])
		EndIf
	Next

	// Adiciona o último par produto - valor no array aItens
	Aadd(aItens, aAux)

Return aClone(aItens)

/*/{Protheus.doc} fVldArquivo
Persiste os dados de cabeçalho da linha processada no banco de dados.
@author Paulo Carvalho
@since 31/10/2018
@param aCabec, array, Array contendo as informações do cabeçalho do arquivo CTE/CRT
@param aItens, array, Array contendo as informações dos itens do arquivo CTE/CRT
@param nLinha, numérico, Informa o número da linha do arquivo que está sendo processada.
@return lRet, lógico, retorna se o arquivo é válido ou não para importação.
@version 1.01
@type Static Function
/*/
Static Function fVldArquivo(aCabec, aItens, nLinha)

	Local lRet			:= .T.
	Local cMensagem 	:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"

	Private cVldStatus := "I"

	// Valida as informações do cabeçalho do arquivo CTE/CRT
	If !fVldCabec(aCabec, nLinha)
		lRet := .F.
	Else
		// Se não for um arquivo de cancelamento
		/*If cCancel <> "C"
			// Valida as informações dos itens do arquivo CTE/CRT
			If !fVldItens(aItens, nLinha, aCabec)
				lRet := .F.
			EndIf
		EndIf*/
	EndIf

	If lRet
		If cVldStatus == "I"
			cMensagem := CAT542015	//"Arquivo importado com sucesso."
		ElseIf cVldStatus == "E"
			cMensagem := ""
		EndIf
		// Adicion o log ao array
		If !Empty(cMensagem)//Evita adição de mensagem contendo apenas "Arquivo importado com erro"

			If AllTrim(aCabec[25]) == "R"
				cCancelLog := "R"
			ElseIf AllTrim(aCabec[25]) == "C"
				cCancelLog := "C"
			Else
				cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
			EndIf

			Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
					cMensagem, nLinha, cArquivo, cVldStatus, cCancelLog, cBlqEmail, lImp})
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} fVldCabec
Valida a linha de dados a ser importada.
@author Paulo Carvalho
@since 01/11/2018
@param aCabec, array, Array contendo as informações do cabeçalho do arquivo CTE/CRT
@param nLinha, numérico, Informa o número da linha do arquivo que está sendo processada.
@version 1.01
@type Static Function
/*/
Static Function fVldCabec(aCabec, nLinha)

	Local lRet	:= .T.

	// Valida o código do documento que está sendo processado.
	If !fValCTE(aCabec)
		lRet := .F.
	Else

		// Valida o cliente do documento que está sendo processado.
		If !fValCli(aCabec)
			lRet := .F.
		EndIf

	EndIf

Return lRet

/*/{Protheus.doc} fVldItens
Valida a linha de dados a ser importada.
@author Paulo Carvalho
@since 01/11/2018
@param aItens, array, Array contendo as informações dos itens do arquivo CTE/CRT
@param nLinha, numérico, Informa o número da linha do arquivo que está sendo processada.
@return lRet, lógico, informa se os itens são válidos para importação.
@version 1.01
@type Static Function
/*/
Static Function fVldItens(aItens, nLinha, aCabec)

	Local cMensagem		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local lRet			:= .T.
	Local lValTotal		:= .F.
	Local nI

	lValTotal	:= fValorTotal(aItens)

	If lValTotal

		For nI := 1 To Len(aItens)
			// Verifica se a quantidade de itens não é impar
			If Mod(Len(aItens[nI]), 2) == 0
				// Se o produto não está cadastrado no sistema
				If !fValProd(aItens[nI][2])
					lRet		:= .T.	// Invalida o item
					cStatus		:= "E"	// Arquivo não importado por conter erros.
					cMensagem	:= CAT542016 + aItens[nI][2] + CAT542017 // "O produto " + " não está cadastrado no sistema."
					cVldStatus	:= "E"

					If AllTrim(aCabec[25]) == "R"
						cCancelLog := "R"
					ElseIf AllTrim(aCabec[25]) == "C"
						cCancelLog := "C"
					Else
						cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
					EndIf

					// Adiciona o log ao array
					Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
								cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, lImp})
				EndIf

				// Se o valor do produto for menor do que 0 (zero).
				If SuperVal(aItens[nI][3]) <= 0
					lRet		:= .F.	// Invalida o item
					cStatus		:= "E"	// Arquivo não importado por conter erros.
					cMensagem	:= CAT542018 //Valor do produto é inferior a zero.
					cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

					// Adicion o log ao array
					Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
								cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
				EndIf
			Else

				lRet		:= .F.	// Invalida o item
				cStatus		:= "E"	// Arquivo não importado por conter erros.
				cMensagem	:= CAT542003 + cDocumento + CAT542019	//"O arquivo " ### " não contém todas as informações necessárias para a inclusão dos itens."
				cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

				// Adiciona o log ao array
				Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
							cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
			EndIf
		Next
	Else
		lRet		:= .F.	// Invalida o item
		cStatus 	:= "E"
		cMensagem 	:= CAT542006 + cDocumento + CAT542020 //"O arquivo CTE/CRT" + " possui divergência entre o valor total e os itens."
		cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

		// Adicion o log ao array
		Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
					cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})

	EndIf

Return lRet

/*/{Protheus.doc} fGrvLog
Grava o registro de log para a importação dos arquivos CTE/CRT
@author Paulo Carvalho
@since 18/12/2018
@param aLog, array, Array contendo as informações da ocorrência de log.
@version 1.01
@type Static Function
/*/
Static Function fGrvLog(aLog)

	Local aArea		:= GetArea()
	Local aAreaUQF	:= UQF->(GetArea())

	Local cHora		:= "" // Time()
	Local cUsuario	:= IIf(l527Auto, cUserSched, UsrRetName(RetCodUsr()))
	Local cErro		:= CAT542021	//"Arquivo importado com erro. "
	Local dData		:= Date()

	Local nI

	// Abre a tabela de log da importação de arquivos CTE/CRT
	DbSelectArea("UQF")

	For nI := 1 To Len(aLog)
		cHora := Time()

		//Se a ultima variavel do array for .T. indica a importação com erros
		If aLog[nI][Len(aLog[nI])] .AND. aLog[nI][9] == "E"
			aLog[nI][6] := cErro + aLog[nI][6]
		EndIf

		// Trava a tabela para inclusão de registro
		UQF->(RecLock("UQF", .T.))
			// Grava as informações do log
			//If !Empty(aLog[nI][1])
				UQF->UQF_FILIAL	:= aLog[nI][1] //fDefFilial(aLog[nI][1])
			//Else
			//	UQF->UQF_FILIAL	:= FWxFilial("UQF")
			//EndIf

			UQF->UQF_FIL	:= aLog[nI][1]
			UQF->UQF_IDIMP	:= aLog[nI][2]
			UQF->UQF_DATA	:= dData
			UQF->UQF_HORA	:= cHora
			UQF->UQF_REGCOD	:= aLog[nI][3]
			UQF->UQF_CLIENT	:= aLog[nI][4]
			UQF->UQF_VALOR	:= aLog[nI][5]
			UQF->UQF_MSG	:= aLog[nI][6]
			UQF->UQF_NLINHA	:= aLog[nI][7]
			UQF->UQF_ARQUIV	:= aLog[nI][8]
			UQF->UQF_USER	:= cUsuario
			UQF->UQF_ACAO	:= "IMP"
			UQF->UQF_LIDO	:= "N"
			UQF->UQF_STATUS	:= aLog[nI][9]

			If l527Auto
				UQF->UQF_IDSCHE := cIdSched
			EndIf

			UQF->UQF_CANCEL	:= aLog[nI][10]
			UQF->UQF_BLQMAI := aLog[nI][11]
		// Destrava a Tabela
		UQF->(MsUnlock())
	Next

	RestArea(aAreaUQF)
	RestArea(aArea)

Return

/*/{Protheus.doc} fDefFilial
Define a filial do sistema baseando-se na filial veloce enviada no arquivo
@author Paulo Carvalho
@since 19/02/2019
@param cFilVelo, caracter, filial veloce.
@return cFilSis, caracter, filial do sistema equivalente à filial veloce.
@version 1.01
@type Static Function
/*/
Static Function fDefFilial(cFilVelo)

	Local aArea			:= GetArea()
	Local aAreaUQK		:= UQK->(GetArea())

	Local cFilSis		:= ""

	Local nTamFilial	:= Len(cFilAnt)

	// Procura a filial veloce na tabela de filiais
	DbSelectArea("UQK")
	UQK->(DbSetOrder(1))	// UQK_FILIAL + UQK_FILARQ

	// Se encontrar a filial veloce
	If UQK->(DbSeek(FWxFilial("UQK") + cFilVelo))
		// Armazena a filial do sistema
		cFilSis := UQK->UQK_FILPRO
	Else
		cFilSis := Replicate("X", nTamFilial)
	EndIf

	RestArea(aAreaUQK)
	RestArea(aArea)

Return cFilSis

/*/{Protheus.doc} fValCTE
Valida o documento que está sendo processado para importação.
@author Paulo Carvalho
@since 03/01/2019
@param cDocumento, caracter, código do cliente a ser validado.
@param cCancel, caracter, inofrmação da ação que será executada com o documento.
@param nLinha, númerico, número da linha que está sendo processada.
@version 1.01
@type Static Function
/*/
Static Function fValCTE(aCabec)

	Local aArea			:= GetArea()
	Local cMensagem		:= ""
	Local cStatus		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"

	Local lRet			:= .T.

	Default aCabec		:= {}

	// Valida se o número do documento está preenchido
	If Empty(cDocumento)
		lRet 		:= .F.
		cStatus		:= "E"			// Arquivo não importado por conter erros.
		cMensagem 	:= CAT542022	//O número do documento não está preenchido no arquivo.
		cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])
		// Adicion o log ao array
		Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
					cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
	Else

		// Verifica, caso for inclusão, se o arquivo já está cadastrado no sistema
		DbSelectArea("UQD")
		UQD->(DbSetOrder(2))	
		If cCancel <> "R" .And. UQD->(DbSeek( xFilial("UQD") + Padr(cDocumento, TamSX3("UQD_NUMERO")[1]) + cCancel ))
			// Se o arquivo encontrado não estiver cancelado
			If UQD->UQD_STATUS <> "C"
				lRet 		:= .F.
				cStatus		:= "D"	// Arquivo já importado anteriormente
				cMensagem 	:= CAT542023 + cDocumento + CAT542024 //"O documento " + " já foi importado no sistema."
				cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

				// Adicion o log ao array
				//Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
				//			cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
			EndIf

		Else
			// Caso for um arquivo de cancelamento, verifica se existe um de inclusão cadastrado
			If "C" $ cCancel

				UQD->(DbSetOrder(2))
				If UQD->(DbSeek( xFilial("UQD") + Padr(cDocumento, TamSX3("UQD_NUMERO")[1]) + cCancel ))
					lRet 		:= .F.
					cStatus		:= "E"	// Arquivo já importado anteriormente
					cMensagem 	:= CAT542003 + cDocumento + CAT542025 //"O arquivo " + " não possui um arquivo de inclusão importado."
					cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

					// Adiciona o log ao array
					//Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
					//			cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
				EndIf

			ElseIf "R" $ cCancel
				lRet := fVldArqRep(aCabec)

			EndIf
		EndIf
	EndIf

	// Fecha a Tabela
	UQD->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fValCli
Verifica se o cliente utilizado está cadastrado no sistema
@author Paulo Carvalho
@since 01/11/2018]
@param cCliente, caracter, código do cliente a ser validado.
@param nLinha, númerico, número da linha que está sendo processada.
@version 1.01
@type Static Function
/*/
Static Function fValCli(aCabec)

	Local aArea			:= GetArea()

	Local cMensagem		:= ""
	Local cStatus		:= ""

	Local cCancelLog	:= ""
	//Local cBlqEmail		:= "N"
	Local lRet			:= .T.

	// Verifica se o campo está vazio.
	If Empty(cCliente)
		lRet 		:= .F.
		cStatus		:= "E"			// Arquivo não importado por conter erros.
		cMensagem 	:= CAT542026 	// O código do cliente não está preenchido no arquivo.
		cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])// Linhas de logs Aadd(aLog) com ultima posição igual a !lImp(.F.) indica que houveram erros que impedem a importação,
													// por isso não há porque marcar a linha como carta de correção/cancelamento mesmo que seja uma,pois não estara na UQD

		// Adicion o log ao array
		//Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
		//			cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
	/*Else
		DbSelectArea("SA1")
		SA1->(DbSetOrder(1))

		If !SA1->(DbSeek(xFilial("SA1") + cCliente))

			lRet 		:= .T.
			cStatus		:= "E"	// Arquivo não importado por conter erros.
			cMensagem 	:= CAT542027 + cCliente + CAT542028 //"O cliente " + " não está está cadastrado no sistema."
			cVldStatus	:= "E"

			If AllTrim(aCabec[25]) == "R"
				cCancelLog := "R"
			ElseIf AllTrim(aCabec[25]) == "C"
				cCancelLog := "C"
			Else
				cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
			EndIf

			// Adiciona o log ao array
			Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
						cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, lImp})

		EndIf

		SA1->(DbCloseArea())*/
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fValProd
Verifica se o produto do item do arquivo está cadastrado no sistema
@author Paulo Carvalho
@since 28/12/2018
@param cProduto, caracter, Produto a ser validado.
@return lRet, lógico, true se o produto está cadastrado e false se não estiver.
@version 1.01
@type Static Function
/*/
Static Function fValProd(cProduto)

	Local aArea		:= GetArea()
	Local lRet		:= .T.

	// Abre a tabela de produtos
	DbSelectArea("SB1")
	SB1->(DbSetOrder(1))

	// Verifica se o produto não está cadastrado no sistema
	If !SB1->(DbSeek(xFilial("SB1") + cProduto))
		lRet := .F.
	EndIf

	// Fecha a tabela de produtos
	SB1->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvArquivo
Persiste o arquivo CTE/CRT importado no banco de dados.
@author Paulo Carvalho
@since 28/12/2018
@param aCabec, array	, Array contendo as informações do cabeçalho do arquivo CTE/CRT
@param aItens, array	, Array contendo as informações dos itens do arquivo CTE/CRT
@param nLinha, numérico	, Informa o número da linha do arquivo que está sendo processada.
@param nErr	 , numérico	, Indica se 1-Linha OK, 2-Importar com erros, 3-Não importar
@version 1.01
@type Static Function
/*/
Static Function fGrvArquivo(aCabec, aItens, nLinha, nErr)

	Local lErro		:= IIF(nErr > 1, .T., .F.)

	//Se o erro for 3 pular todo o processo
	If nErr < 3
		// Grava o cabeçalho do arquivo CTE/CRT
		fGrvCabec(aCabec, nLinha, lErro)

		// Se não for um cancelamento
		If cCancel <> "C"
			// Grava os itens do arquivo CTE/CRT
			fGrvItens(aItens, nLinha)
		EndIf
	EndIf

Return

/*/{Protheus.doc} fGrvCabec
Persiste os dados de cabeçalho da linha processada no banco de dados.
@author Paulo Carvalho
@since 31/10/2018
@param aCabec, array	, Array contendo as informações do cabeçalho do arquivo CTE/CRT
@param nLinha, numérico	, Informa o número da linha do arquivo que está sendo processada.
@param lErr	 , lógico	, Informa se o registro esta sendo importado com erros
@version 1.01
@type Static Function
/*/
Static Function fGrvCabec(aCabec, nLinha, lErr)

	Local aArea			:= GetArea()
	Local lRet			:= .T.
	Local cStatus		:= IIF(lErr, "E", "I")

	// Abre a tabela de arquivos CTE/CRT
	DbSelectArea("UQD")
	UQD->(DbSetOrder(2))	

	// Abre uma transação para gravação do cabeçalho do arquivo
	Begin Transaction
		// Inclui o registro.
		If Len(aCabec) > 0
			If !UQD->(DbSeek( aCabec[1] + Padr(aCabec[16], TamSX3("UQD_NUMERO")[1]) + cCancel ))
				UQD->(RecLock("UQD", .T.))
					UQD->UQD_FILIAL	:= aCabec[1]
					UQD->UQD_IDIMP	:= cId
					UQD->UQD_DTIMP	:= Date()
					UQD->UQD_TPCON	:= aCabec[2]
					UQD->UQD_COMPAN	:= aCabec[3]
					UQD->UQD_LINPRO	:= aCabec[4]
					UQD->UQD_CANDIS	:= aCabec[5]
					UQD->UQD_ESCVEN	:= aCabec[6]
					UQD->UQD_CLIENT	:= aCabec[7]
					UQD->UQD_LOJACL	:= aCabec[8]
					UQD->UQD_NUMMAT	:= aCabec[9]
					UQD->UQD_QTDESE	:= aCabec[10]
					UQD->UQD_VALOR	:= aCabec[11]
					UQD->UQD_MOEDA	:= aCabec[12]
					UQD->UQD_ICMS	:= aCabec[13]
					UQD->UQD_FIL	:= aCabec[14]
					UQD->UQD_INDICA	:= aCabec[15]
					UQD->UQD_NUMERO	:= aCabec[16]
					UQD->UQD_INDICM	:= aCabec[17]
					UQD->UQD_INDPAI	:= aCabec[18]
					UQD->UQD_CONMES	:= aCabec[19]
					UQD->UQD_EMISSA	:= aCabec[21]
					UQD->UQD_MUNCOL	:= aCabec[22]
					UQD->UQD_UFFOR	:= aCabec[23]
					UQD->UQD_UFCOL	:= aCabec[24]
					UQD->UQD_UFDES	:= aCabec[25]
					UQD->UQD_CANCEL	:= aCabec[26]
					UQD->UQD_CFOP	:= aCabec[27]
					UQD->UQD_IDPAG	:= aCabec[28]
					UQD->UQD_VIAGEM	:= aCabec[29]
					UQD->UQD_FATURA	:= aCabec[30]
					UQD->UQD_CHVCTE	:= aCabec[31]
					UQD->UQD_TOMSER	:= aCabec[32]
					UQD->UQD_TIPOCT	:= aCabec[33]
					UQD->UQD_STATUS	:= cStatus
					UQD->UQD_IDSCHE := IIf(l527Auto, cIdSched, "")
					UQD->UQD_BLQMAI := "N"
					UQD->UQD_SISCOS := aCabec[34]
					UQD->UQD_PAISDE := aCabec[35]
					UQD->UQD_FIMVIA	:= aCabec[36]
					UQD->UQD_PICMS	:= aCabec[37]
					UQD->UQD_CSTICM	:= If(Len(aCabec[38])>2,Substr(aCabec[38],2,3),aCabec[38])
					UQD->UQD_CSTPIC	:= If(Len(aCabec[39])>2,Substr(aCabec[39],2,3),aCabec[39])
					UQD->UQD_BSICMS	:= aCabec[40]
					UQD->UQD_BASPIS	:= aCabec[41]
					UQD->UQD_BASCOF	:= aCabec[42]
					UQD->UQD_VLRPIS	:= aCabec[43]
					UQD->UQD_VLRCOF	:= aCabec[44]
					UQD->UQD_ALQPIS	:= aCabec[45]
					UQD->UQD_ALQCOF	:= aCabec[46]
					UQD->UQD_CHVREF	:= aCabec[47]
					UQD->UQD_CCUSTO	:= GetMv("PLG_CCUSTO") //"220118" //aCabec[20]
					UQD->UQD_ITEMCT	:= GetMv("PLG_ITEMCT") //"10501" //aCabec[47]
					UQD->UQD_CONTAC	:= GetMv("PLG_CONTAC") //"3210103002" //aCabec[47]
				UQD->(MsUnlock())
			Endif
		EndIf
	End Transaction

	// Fecha as tabelas
	SA1->(DbCloseArea())
	UQD->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvItens
Persiste os itens do arquivo CTE/CRT em importação.
@author Paulo Carvalho
@since 27/12/2018
@param aItens, array	, Array contendo os itens do arquivo CTE/CRT
@param nLinha, numérico	, Informa a linha do item atual
@param lErr	 , lógico	, Informa se o registro esta sendo importado com erros
@version 1.01
@type Static Function
/*/
Static Function fGrvItens(aItens, nLinha)

    Local aArea     	:= GetArea()
	Local aAreaUQE		:= UQE->(GetArea())

	Local cItem			:= ""
    Local lRet      	:= .T.

    Local nI
	Local nItem			:= 0
	Local nPrcVen		:= 0

	// Seleciona a área de itens
	DbSelectArea("UQE")
	UQE->(DbSetOrder(1))	// UQE_FILIAL + UQE_IDIMP + UQE_ITEM

	For nI := 1 to Len(aItens)
		// Define as variaveis de cada item
		nItem++
		cItem	:= PadL(cValToChar(nItem), TamSX3("UQE_ITEM")[1], "0")
		nPrcVen	:= SuperVal(aItens[nI][3])

		// Posiciona no produto específico
		DbSelectArea("SB1")
		SB1->(DbSetOrder(1))	// B1_FILIAL + B1_COD

		// Existência do produto validada na funcão fValProd
//		If SB1->(DbSeek(xFilial("SB1") + aItens[nI][1]))
			BEGIN TRANSACTION
				If !UQE->(DbSeek( aItens[nI][1] + aItens[nI][2] ))
					// Efetua a inclusão do item na tabela
					UQE->(RecLock("UQE", .T.))
						UQE->UQE_FILIAL := aItens[nI][1]
						UQE->UQE_IDIMP  := cId
						UQE->UQE_ITEM   := cItem
						UQE->UQE_PRODUT := aItens[nI][2]//SB1->B1_COD
						UQE->UQE_PRCVEN	:= nPrcVen
					UQE->(MsUnlock())
				Endif
			END TRANSACTION
//		EndIf
	Next nI

	// Fecha as tabelas
	SB1->(DbCloseArea())

    RestArea(aAreaUQE)
    RestArea(aArea)

Return lRet

/*/{Protheus.doc} fData
Transforma as datas importadas do arquivo para string.
@author Paulo Carvalho
@since 08/01/2019
@param cData, caracter, data importada dos arquivos de texto.
@return sData, string, data transformada para padrão string.
@version 1.01
@type Static Function
/*/
Static Function fData(cData)

	Local cAux	:= ""
	Local sData	:= ""

	cAux += Left(cData, 2) + "/"
	cAux += SubStr(cData, 3, 2) + "/"
	cAux += Right(cData, 2)

	sData := DtoS(CtoD(cAux))

Return sData

/*/{Protheus.doc} fSetLido
Seta todos os registros de log já cadastrados como lidos.
@author Paulo Carvalho
@since 14/01/2019
@version 1.01
@type Static Function
/*/
Static Function fSetLido()

	Local aArea		:= GetArea()
	Local cQuery	:= ""

	cQuery	+= "UPDATE " + RetSQLName("UQF") + " SET UQF_LIDO = 'S' "	+ CRLF

	Execute(cQuery)

	RestArea(aArea)

Return

/*/{Protheus.doc} fDefId
Seta todos os registros de log já cadastrados como lidos.
@author Paulo Carvalho
@since 14/01/2019
@version 1.01
@type Static Function
/*/
Static Function fDefId()

	Local aArea		:= GetArea()
	Local aAreaUQD	:= UQD->(GetArea())
	Local cIdArq	:= GetSX8Num("UQD", "UQD_IDIMP", , 1)

	// Posiciona no último arquivo CTE/CRT importado
	DbSelectArea("UQD")
	UQD->(DbSetOrder(1))	// UQD_FILIAL + UQD_IDIMP

	While UQD->(DbSeek(xFilial("UQD") + cIdArq))
		ConfirmSX8()
		cIdArq := GetSX8Num("UQD", "UQD_IDIMP", , 1)
	EndDo

	RestArea(aAreaUQD)
	RestArea(aArea)

Return cIdArq

/*/{Protheus.doc} EXECUTE
Função que executa função sql
@author douglas-gregorio
@since 26/12/2017
@version undefined
@param cQuery, characters, descricao
@type function
/*/
Static Function Execute(cQuery)
	Local cErro  := ""
	Local lRet    := .T.
	Local nStatus := 0

	nStatus := TcSqlExec(cQuery)

	If nStatus < 0
		lRet := .F.
		cErro := TCSQLError()
		MsgAlert(CAT542029 + CRLF + cErro, cCadastro) //Erro ao executar rotina:
	EndIf

Return lRet

/*/{Protheus.doc} fValorTotal
Valida se a soma do valor das linhas é igual ao total do cabeçalho
@author douglas-gregorio
@since 07/02/2019
@param aItens, array, itens para validação
@type function
/*/
Static Function fValorTotal(aItens)

	Local lRet		:= .F.
	Local nSoma		:= 0
	Local nI		:= 0
	Local nPosVal	:= 3

	For nI := 1 to Len(aItens)
		nSoma += SuperVal(aItens[nI,nPosVal])
	Next nI

	If nSoma == nValor
		lRet := .T.
	EndIf

Return lRet

/*/{Protheus.doc} fPosRegAtivo
Posiciona no ultimo registro ativo da tabela UQD.
@type function
@author Juliano Fernandes
@since 25/01/2019
@version 1.0
@param cDoc, caracter, Numero do documento (CTE/CRT) a ser localizado
@return lOk, Indica se o registro foi localizado
/*/
Static Function fPosRegAtivo(cDoc)
	Local cCancel 	:= Space(TamSX3("UQD_CANCEL")[1])
	Local lOk		:= .F.

	cDoc := Padr(cDoc, TamSX3("UQD_NUMERO")[1])

	DbSelectArea("UQD")
	UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
	If UQD->(DbSeek(xFilial("UQD") + Padr(cDoc, TamSX3("UQD_NUMERO")[1]) + cCancel))
		While !UQD->(EoF()) .And. UQD->UQD_FILIAL == xFilial("UQD") .And. UQD->UQD_NUMERO == cDoc
			lOk := .T.
			Exit

			UQD->(DbSkip())
		EndDo
	EndIf

Return(lOk)

/*/{Protheus.doc} fVldArqRep
Responsável por validar um arquivo de reprocessamento
@author Icaro Laudade
@since 18/09/2019
@return lOk, Indica se é valido ou não
@type function
/*/
Static Function fVldArqRep(aCabec)
	Local aAreaUQD		:= UQD->(GetArea())
	Local aAreaSD2		:= {}
	Local aAreaSE1		:= {}
	Local cBlqEmail		:= "N"
	Local cPerg			:= "CATTIPOINT"
	Local dEmissao		:= StoD(fData(aCabec[20]))
	Local lFaturaPed	:= .T.
	Local lOk			:= .T.
	Local nAnoCarta		:= 0
	Local nMesCarta 	:= 0
	Local nDiaCarta 	:= 0

	nAnoCarta := Year(dEmissao)
	nMesCarta := Month(dEmissao)
	nDiaCarta := Day(dEmissao)

	If AllTrim(aCabec[25]) == "R" .And. Empty(aCabec[30])
		lOk 		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT542030 //"Carta de Correção não informada."
		cCancelLog	:= "R"

		Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
		cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
	Else
		//Posiciona no original
		If !fPosRegAtivo(aCabec[15])
			lOk 		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT542031 //"CTE/CRT origem não importado no Protheus."
			cCancelLog	:= "R"

			Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
			cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
		Else
			nAnoOrig	:= Year(UQD->UQD_EMISSA)
			nMesOrig	:= Month(UQD->UQD_EMISSA)
			nDiaOrig	:= Day(UQD->UQD_EMISSA)

			/*If nAnoOrig != nAnoCarta

				lOk 		:= .F.
				cStatus		:= "E"
				cMensagem	:= CAT542032 //"O ano de emissão da carta de correção é diferente do ano original."
				cCancelLog	:= "R"

				Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
				cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})
			EndIf

			If nMesOrig != nMesCarta

				lOk 		:= .F.
				cStatus		:= "E"
				cMensagem	:= CAT542033 //"O mês de emissão da carta de correção é diferente do mês original."
				cCancelLog	:= "R"

				Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
				cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})

			EndIf

			If nAnoOrig == nAnoCarta .And. nMesOrig == nMesCarta .And. nDiaOrig > nDiaCarta

				lOk 		:= .F.
				cStatus		:= "E"
				cMensagem	:= CAT542034 //"A data de emissão da carta de correção é anterior a data original."
				cCancelLog	:= "R"

				Aadd(aLog, {cFilArq, Space(TamSX3("UQF_IDIMP")[1]), cDocumento, cCliente, nValor,;
				cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, !lImp})

			EndIf*/

			If lOk
				fAtuSX1(cPerg)

				Pergunte( cPerg, .F. )

				lFaturaPed := .T. //MV_PAR01 == 2

				If !lFaturaPed
					aAreaSD2 := SD2->(GetArea())

					cPedido := UQD->UQD_PEDIDO

					If !Empty(cPedido)

						DbSelectArea("SD2")
						SD2->(DbSetOrder(8))//D2_FILIAL+D2_PEDIDO+D2_ITEMPV
						If SD2->(DbSeek(xFilial("SD2") + Padr(cPedido, TamSX3("D2_PEDIDO")[1])))

							lOk 		:= .T.
							cStatus		:= "E"
							cMensagem	:= CAT542035 //"O pedido de venda está sendo utilizado em uma nota fiscal."
							cCancelLog	:= "R"
							cVldStatus	:= "E"

							Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
							cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, lImp})
						EndIf

					EndIf

					RestArea(aAreaSD2)

				Else
					aAreaSE1 := SE1->(GetArea())

					cPrefixTit := Padr(UQD->UQD_PREFIX, TamSX3("E1_PREFIXO")[1] )
					cNumTit := Padr(UQD->UQD_TITULO, TamSX3("E1_NUM")[1] )
					cParcTit := Padr(UQD->UQD_PARCEL, TamSX3("E1_PARCELA")[1])
					cTipoTit := Padr(UQD->UQD_TIPOTI, TamSX3("E1_TIPO")[1])

					If !Empty(cNumTit)

						DbSelectArea("SE1")
						SE1->(DbSetOrder(1))//E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						If SE1->(DbSeek( xFilial("SE1") + cPrefixTit + cNumTit + cParcTit + cTipoTit))

							nValTit	:= SE1->E1_VALOR

							If !Empty(SE1->E1_BAIXA)
								lOk 		:= .T.
								cStatus		:= "E"
								cMensagem	:= CAT542036 //"O título gerado anteriormente pelo pedido de venda foi baixado."
								cCancelLog	:= "R"
								cVldStatus	:= "E"

								Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
								cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, lImp})

							EndIf

							If !Empty(SE1->E1_XIDFAT)
								lOk 		:= .T.
								cStatus		:= "E"
								cMensagem	:=  CAT542037//"O título gerado anteriormente pelo pedido de venda está sendo utilizado em uma fatura."
								cCancelLog	:= "R"
								cVldStatus	:= "E"

								Aadd(aLog, {cFilArq, cId, cDocumento, cCliente, nValor,;
								cMensagem, nLinha, cArquivo, cStatus, cCancelLog, cBlqEmail, lImp})
							EndIf

						EndIf

					EndIf
					RestArea(aAreaSE1)
				EndIf
			EndIf
		EndIf
	EndIf
	RestArea(aAreaUQD)
Return lOk

/*/{Protheus.doc} fAtuSX1
Atualização de pergunta na tabela SX1.
@type function
@version 1.0
@author Juliano Fernandes
@since 09/11/2020
@param cPergunte, character, Código do Pergunte que será gerado
/*/
Static Function fAtuSX1(cPergunte)

	U_PutSx1PG(cPergunte,"01","Tipo de integração","Tipo de integración","Type of integration","mv_ch1","N",1,0,1,"C","","","","","mv_par01","Pedido de Venda","Orden de venta","Sales order","","Pedido + Financeiro","Pedido + Financiero","Order + Financial","","","","","","","","","",{"Selecione o tipo de integração"},{"Select the type of integration"},{"Seleccione el tipo de integración"})

Return(Nil)

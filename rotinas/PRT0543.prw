#Include 'Totvs.ch'
#Include 'CATTMS.ch'

/*/{Protheus.doc} PRT0543
Realiza a persist�ncia do arquivo CTRB importado pelo programa PRT0527.
@author Paulo Carvalho
@since 28/12/2018
@param cArqImp, caracter, Arquivo escolhido pelo usu�rio para importa��o.
@version 1.01
@type User Function
/*/
User Function PRT0543(cArqImp)

    Local aArea         := GetArea()

    Local aCabec        := {}
	Local aDet			:= {}
    Local aDetalhe      := {}
    Local aLinha        := {}

    Local cDetalhe      := "D"
    Local cHeader       := "H"
	Local cItem			:= "000"

    Local lRet          := .T.

	Local nI, nJ

	Local nOk			:= 0
	Local nErro			:= 0
	Local nImpErro		:= 0
	Local nHandle		:= 0
	Local nPosEmpFil	:= 0

	Private aLog		:= {}

	Private aFinanc		:= { "21", "31" }
	Private aContab		:= { "39", "40", "50", "60" }

    Private cArquivo    := cArqImp
	Private cFilArq		:= ""
	Private cIdImp		:= ""
	Private cCancel		:= ""
	Private cRegistro	:= ""
	Private cTipoArq	:= ""
	Private cTpTrans	:= ""

	Private lImpErro	:= .T.
	Private lImp		:= .T.

    Private nLinha      := 0

	// Seta todos os logs j� cadastrados como lidos
	If !l527Auto
		fSetLido()
	EndIf

    //+---------------------------------------------------------------------+
	//| Valida o arquivo para processamento									|
    //+---------------------------------------------------------------------+
	If !File(cArquivo)
		lRet := .F.
		MsgStop(CAT543001, cCadastro) // "Arquivo inv�lido para esta opera��o."
	EndIf

	If lRet
        //+---------------------------------------------------------------------+
        //| Abertura do arquivo texto                                           |
        //+---------------------------------------------------------------------+
		nHandle := fOpen(cArquivo)

        //+---------------------------------------------------------------------+
		//| Verifica se o arquivo se encontrar aberto pelo usu�rio				|
        //+---------------------------------------------------------------------+
		If nHandle == -1
			If fError() == 516
				Alert(CAT543002) // "Feche o arquivo para continuar o processamento."
			EndIf
		EndIf

        //+---------------------------------------------------------------------+
        //| Verifica se foi poss�vel abrir o arquivo                            |
        //+---------------------------------------------------------------------+
        If nHandle == -1
        	lRet := .F.
        	cMensagem := CAT543003 + cArquivo + CAT543004 // #"O arquivo ", #" n�o pode ser aberto! Verifique o local onde o arquivo est� armazenado."

        	MsgAlert(cMensagem, cCadastro)
        EndIf

		If lRet
			//+---------------------------------------------------------------------+
	        //| Posiciona no Inicio do Arquivo                                      |
	        //+---------------------------------------------------------------------+
			fSeek(nHandle, 0, 0)

	        //+---------------------------------------------------------------------+
	        //| Traz o Tamanho do Arquivo TXT                                       |
	        //+---------------------------------------------------------------------+
	        nTamArq := fSeek(nHandle, 0, 2)

	        //+---------------------------------------------------------------------+
	        //| Posicona novamemte na primeir linha valida.                         |
	        //+---------------------------------------------------------------------+
	        fSeek(nHandle, 0, 0)

	        //+---------------------------------------------------------------------+
	        //| Fecha o Arquivo                                                     |
	        //+---------------------------------------------------------------------+
	        fClose(nHandle)
	        FT_FUse(cArquivo)  					// Abre o arquivo
	        FT_FGoTop()         				// Posiciona na primeira linha do arquivo
	        nTamLinha := Len(FT_FReadLN()) 	// Ve o tamanho da linha
	        FT_FGoTop()

	        //+---------------------------------------------------------------------+
	        //| Verifica quantas linhas tem o arquivo                               |
	        //+---------------------------------------------------------------------+
	        nLinhas := nTamArq/nTamLinha

			ProcRegua(nLinhas)

	        //+---------------------------------------------------------------------+
	        //| L� o arquivo e preenche o array com os dados de cada linha.			|
	        //+---------------------------------------------------------------------+
			While !FT_FEof()
				// Incrementa a contagem da Linha
				nLinha++

				// Cria a r�gua de processamento
				IncProc(CAT543005 + AllTrim(Str(nLinha))) // "Importando linha: "

				// Captura dos dados da linha atual
				cLinha := FT_FReadLN()

				// Verifica se a linha n�o � vazia.
				If Len(cLinha) > 0
					// Explode a linha em um array
					aLinha := Separa(cLinha, "~", .T.)

	                // Verifica se � um registro de cabe�alho ou detalhe
	                If aLinha[1] == cHeader

						//-- Define a filial para o processamento do registro
						//-- Juliano - 07/02/2019
						If !StaticCall(PRT0527, fAltFilial, aLinha[12])
							// ---------------------------------------------------------------------------------------------------------
							// Ajuste realizado por Juliano em 29/10/2019 para o problema de grava��o do Log de Filial n�o cadastrada
							// Se estiver executando via Schedule e localizar a filial em outra empresa atrav�s do array aFilVeloce
							// n�o grava o Log.
							// ---------------------------------------------------------------------------------------------------------
							If l527Auto
								If (nPosEmpFil := AScan(aFilVeloce, {|x| AllTrim(x[1]) == AllTrim(aLinha[12]) })) > 0
									If AllTrim(aFilVeloce[nPosEmpFil,2]) != AllTrim(cEmpAnt)
										// Passa para a pr�xima linha do arquivo.
										FT_FSkip()
										Loop
									EndIf
								EndIf
							EndIf

//							If !l527Auto
								nErro++
								cStatus 	:= "E"
								cMensagem 	:= StrTran(CAT543006,".","") + ": " + aLinha[12]  //"Filial n�o cadastrada no sistema."

								// Adiciona ao array de log
								Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), aLinha[8], cMensagem, nLinha, cArquivo, cStatus,!lImp})

								If l527Auto
									Aadd(aNaoImpFil, {	"UQJ"		,;
														aLinha[8]	,;
														nLinha		,;
														cArquivo	})
								EndIf
//							EndIf

							// Passa para a pr�xima linha do arquivo.
							FT_FSkip()
							Loop
						EndIf

						// Se o array de Cabe�alho n�o estiver v�zio
						If !Empty(aCabec) // .And. !Empty(aDetalhe)
							// Define se registro � para cancelamento
							cCancel 	:= aCabec[5]
							cFilArq 	:= aCabec[15]
							cRegistro 	:= aCabec[10]

							// Trata o c�digo de refer�ncia e o tipo de transa��o caso seja reprocessamento.
							fTrtRef(@aCabec)

							// Se o arquivo � valido para importa��o
							If fVldArq(aCabec, aDetalhe, cCancel)
								// Grava o registro
								fGrvArq(aCabec, aDetalhe, cCancel)

								If(lImpErro, nImpErro++, nOk++)
							Else
								nErro++
							EndIf

							// Reinicia os arrays principais
							aCabec 		:= {}
							aDetalhe 	:= {}
							cItem		:= "000"
						EndIf

						// Define o n�mero identificador da importa��o.
						cIdImp := fDefIdImp()

						// Define o tipo do arquivo (Provis�o ou Rendi��o)
						cTipoArq := Right(aLinha[8], 2)

						// Se for adiantamento, retira o primeiro caracter que n�o corresponde ao tipo de documento.
						If "A" $ cTipoArq
							cTipoArq := Right(cTipoArq, 1)
						EndIf

						// Alimenta os campos padr�es que n�o s�o importados do arquivo. (Filial, Id de Importacao)
						Aadd(aCabec, xFilial("UQG"))
						Aadd(aCabec, cIdImp)

						// Adiciona os itens lido ao cabe�alho
						For nI:= 1 to Len(aLinha)
							// Divide a refer�ncia de documento em documento e tipo de arquivo
							If nI == 8
								Aadd(aCabec, aLinha[8])
								Aadd(aCabec, cTipoArq)
							Else
								Aadd(aCabec, aLinha[nI])
							EndIf
						Next

						// Adiciona a linha do cabe�alho.
						Aadd(aCabec, nLinha)
					ElseIf aLinha[1] == cDetalhe .And. !Empty(aCabec)
						// Reinicia o array aDet
						aDet := {}

						// Define o item do arquivo importado
						cItem := Soma1(cItem)

						// Alimenta os campos padr�es que n�o s�o importados do arquivo. (Filial, Id de Importacao, Item)
						Aadd(aDet, xFilial("UQG"))
						Aadd(aDet, cIdImp)
						Aadd(aDet, cItem)

						For nJ:= 1 to Len(aLinha)
							Aadd(aDet, aLinha[nJ])
						Next

						// ------------------------------------------------
						// Ajusta a conta cont�bil removendo os pontos
						// Juliano Fernandes - 03/05/19
						// Solicitado por Marcos na mesma data via Skype
						// ------------------------------------------------
						If AScan(aContab, aDet[20]) > 0 // Verifica se o tipo � cont�bil
							aDet[21] := StrTran(aDet[21], ".", "")
						EndIf

						If (cTipoArq == "RD" /* .Or. cTipoArq == "A" */) .And. (AScan(aFinanc, aDet[20]) > 0)
							fAjustaDet(@aDet, @cItem)

							// Adiciona a linha de detalhe ao array aDetalhe
							AEval(aDet, {|x| Aadd(aDetalhe, x)})
						Else
							// Adiciona a linha de detalhe ao array aDetalhe
							Aadd(aDetalhe, aDet)
						EndIf
	                EndIf

	                // Passa para a pr�xima linha do arquivo.
	                FT_FSkip()
				Else
					// Passa para a pr�xima linha do arquivo.
					FT_FSkip()
				EndIf

			EndDo

			// Realiza a grava��o para o �ltimo registro.
			If !Empty(aCabec) // .And. !Empty(aDetalhe)
				// Determina a filial, tipo de transa��o e refer�ncia do arquivo importado
				cCancel 	:= aCabec[5]
				cFilArq 	:= aCabec[15]
				cRegistro 	:= aCabec[10]

				// Trata o c�digo de refer�ncia e o tipo de transa��o caso seja reprocessamento.
				fTrtRef(@aCabec)

				// Se o arquivo � valido para importa��o
				If fVldArq(aCabec, aDetalhe, cCancel)
					// Grava o registro
					fGrvArq(aCabec, aDetalhe, cCancel)

					If(lImpErro, nImpErro++, nOk++)
				Else
					nErro++
				EndIf

				// Reinicia os arrays principais
				aCabec 		:= {}
				aDetalhe 	:= {}
				cItem		:= "000"
			EndIf

	        // Fecha o Arquivo.
	        FT_FUSE()
		EndIf
	EndIf

	// Grava o log de importa��o
	fGrvLog(aLog)

	If !l527Auto
		cMensagem 	:= 	CAT543007 + CRLF +; // "Importa��o CTRB finalizada. Verifique o resultado abaixo."
						CRLF + CAT543008 + cValToChar(nOk) + CRLF +; // "Itens importados: "
						CRLF + CAT543009 + cValToChar(nImpErro) + CRLF +; // "Itens importados com erro: "
						CAT543010 + cValToChar(nErro) + CRLF +; // "Itens n�o importados: "
						CRLF + CAT543011 // "Deseja visualizar o log da importa��o?"

		If MsgYesNo(cMensagem, cCadastro)
			// Chama o programa de visualiza��o de log de registros.
			U_PRT0533("UQJ", .T.)
		EndIf
	EndIf

    RestArea(aArea)

Return

/*/{Protheus.doc} fTrtRef
Trata o c�digo de refer�ncia do arquivo quando o mesmo for para reprocessamento.
@author Paulo Carvalho
@since 20/02/2019
@param aCabec, Array, Array contendo o cabe�alho do arquivo.
@version 1.01
@type User Function
/*/
Static Function fTrtRef(aCabec)

	Local nUnderLine	:= 0

	If "_" $ aCabec[10] // .And. "RD" $ aCabec[11]
		cTpTrans := "R"
		nUnderLine := At("_", aCabec[10])
		aCabec[10] := StrTran(aCabec[10], cTipoArq, "")//Retiro o RD temporariamente do Final

		aAdd(aCabec, SubStr(aCabec[10], nUnderLine + 1))//Adiciona o N�mero AP�S o simbolo "_", por isso o + 1
		aCabec[10] := SubStr(aCabec[10] , 1,  nUnderLine - 1)//Exclus�o do "_" e tudo que vem ap�s
		aCabec[10] += cTipoArq //Inclus�o novamente do RD
		aCabec[10] := PadR(aCabec[10], TamSX3("UQG_REF")[1], " ")

		cRegistro := aCabec[10]
	Else
		cTpTrans := aCabec[5]
	EndIf

Return

/*/{Protheus.doc} fVldArq
Valida os itens do arquivo importado e realiza a grava��o.
@author Paulo Carvalho
@since 07/01/2019
@return lRet, l�gico, retorna se o arquivo � v�lido ou n�o.
@version 1.01
@type User Function
/*/
Static Function fVldArq(aCabec, aDetalhe, cAcao)

	Local aArea			:= GetArea()

	Local cMensagem		:= CAT543012 // "Registro importado com sucesso."
	Local cStatus		:= "I"

	Local lRet			:= .T.

	Private cTransp		:= ""
	Private nLin		:= aCabec[37]

	// Reinicia a vari�vel de arquivo importado com erro a cada valida��o.
	lImpErro	:= .F.

	// Valida o cabe�alho do arquivo
	If !fVldCabec(aCabec)
		lRet := .F.
	Else
	 	// Se for uma inclus�o
	 	If Empty(cAcao)
			// Valida os detalhes do arquivo
			If !fVldDet(aCabec, aDetalhe)
				lRet := .F.
			Else
			 	cTransp	:= aDetalhe[1][29]

				If !lImpErro
					Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus,!lImp})
				EndIf

			EndIf
		ElseIf "C" $ cAcao //Se for um cancelamento
			//Cancelamento n�o tem detalhes portanto se o cabe�alho for valido ser� importado
			Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
		EndIf
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvArq
Valida os itens do arquivo importado e realiza a grava��o.
@author Paulo Carvalho
@since 07/01/2019
@return cId, C�digo sequ�ncial da importa��o.
@version 1.01
@type User Function
/*/
Static Function fGrvArq(aCabec, aDetalhe, cAcao)

	Private cTransp		:= ""

	// Grava o cabe�alho
	fGrvCabec(aCabec)

	// Se for uma inclus�o de registro
	If Empty(cAcao)
		cTransp := aDetalhe[1][29]

		// Grava o detalhe
		fGrvDet(aDetalhe)
	EndIf

Return

/*/{Protheus.doc} fDefIdImp
Define os campos do cabe�alho do arquivo que n�o s�o importados no arquivo de texto.
@author Paulo Carvalho
@since 07/01/2019
@return cId, C�digo sequ�ncial da importa��o.
@version 1.01
@type User Function
/*/
Static Function fDefIdImp()

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())
	Local cIdArq	:= GetSX8Num("UQG", "UQG_IDIMP", , 1)

	// Posiciona no �ltimo arquivo CTRB importado
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	While UQG->(DbSeek(xFilial("UQG") + cIdArq))
		ConfirmSX8()
		cIdArq := GetSX8Num("UQG", "UQG_IDIMP", , 1)
	EndDo

	RestArea(aAreaUQG)
	RestArea(aArea)

Return cIdArq

/*/{Protheus.doc} fVldCabec
Valida as informa��es do cabe�alho do arquivo.
@author Paulo Carvalho
@since 07/01/2019
@param, aCabec, array, Array contendo os dados do cabe�alho do arquivo.
@return lRet, l�gico, True se o arquivo � valido e false se n�o o �.
@version 1.01
@type User Function
/*/
Static Function fVldCabec(aCabec)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())
	Local aMoeda	:= 	{ 	{ "BRL", "01" },;
							{ "ARG", "02" },;
							{ "USD", "03" }		}

	Local cInclusao	:= " "
	Local cMensagem	:= ""
	Local cMoeda	:= aCabec[13]
	Local cStatus	:= ""

	Local lRet		:= .T.

	Local nI
	Local nLin		:= aCabec[37]
	Local nMoeda	:= 0

	// Determina a moeda
	For nI := 1 To Len(aMoeda)
		If aScan(aMoeda[nI], cMoeda) > 0
			nMoeda := nI
		EndIf
	Next

	// Seleciona a tabela de cabe�alho
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2)) // UQG_FILIAL + UQG_REF + UQG_TPTRAN

	// Valida se o arquivo j� n�o foi importado
	If UQG->(DbSeek(xFilial("UQG") + aCabec[10] + cTpTrans))
		// Se n�o for um reprocessamento
		If cTpTrans <> "R"
			// Se o arquivo encontrado n�o estiver cancelado.
			If UQG->UQG_STATUS <> "C"
				lRet 		:= .F.
				cStatus		:= "D"
				cMensagem 	:= CAT543013 + aCabec[10] + CAT543014 // #"O documento " #" j� foi importado anteriormente."

				// Adicion ao array de log
				Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus,!lImp})
			EndIf
		Else
			// Verifica a vers�o do reprocessamento
			If AllTrim(UQG->UQG_VERREP) == aCabec[38]
				lRet 		:= .F.
				cStatus		:= "D"
				cMensagem 	:= CAT543015 + AllTrim(aCabec[10]) + CAT543016 //"Esta vers�o de reprocessamento do arquivo " # " j� foi importada."

				// Adicion ao array de log
				Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
			EndIf
		EndIf
	EndIf

	// Se arquivo ainda n�o foi importado no Protheus
	If lRet
		// Se o registro for de cancelamento
		If "C" $ cCancel
			// Verifica se existe o arquivo de inclus�o
			If cTpTrans == "R" //Se for igual a R ent�o � um reprocessamento em um arquivo de cancelamento
				lRet 		:= .F.
				cStatus		:= "E"
				cMensagem 	:= CAT543017 //"N�o � poss�vel reprocessar um arquivo de cancelamento."

				// Adicion ao array de log
				Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus,!lImp})

			ElseIf !UQG->(DbSeek(xFilial("UQG") + aCabec[10] + cInclusao))
				lRet 		:= .F.
				cStatus		:= "E"
				cMensagem 	:= CAT543018 + AllTrim(aCabec[10]) + CAT543019 // #"N�o � poss�vel cancelar o documento " #" pois n�o houve inclus�o no sistema."

				// Adiciona ao array de log
				Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
			EndIf

		EndIf

		// Valida se a moeda utilizada na transa��o est� cadastrada
		If !Empty(nMoeda)
			cMoeda	:= aMoeda[nMoeda][2]
		Else
			//lRet		:= .F.
			lImpErro	:= .T.
			cStatus		:= "E"
			cMensagem	:= CAT543020 //"A moeda utilizada n�o est� configurada nos par�metros do Protheus."

			// Adicion ao array de log
			Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
		EndIf

		// Seleciona a tabela de moedas cont�beis
		DbSelectArea("CTO")
		CTO->(DbSetOrder(1))	// CTO_FILIAL + CTO_MOEDA

		// Verifica a existencia da moeda
		If !CTO->(DbSeek(xFilial("CTO") + cMoeda))
			//lRet		:= .F.
			lImpErro	:= .T.
			cStatus		:= "E"
			cMensagem	:= CAT543021 + cMoeda + CAT543022 // #"A moeda cont�bil utilizada no arquivo " #" n�o est� cadastrada no sistema."

			// Adicion ao array de log
			Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
		EndIf

		// Fecha a tabela de moedas
		CTO->(DbCloseArea())
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldDet
Valida as informa��es dos detalhes do arquivo.
@author Paulo Carvalho
@since 07/01/2019
@param, aDetalhe, array, Array contendo os dados do cabe�alho do arquivo.
@return lRet, l�gico, True se o arquivo � valido e false se n�o o �.
@version 1.01
@type User Function
/*/
Static Function fVldDet(aCabec, aDetalhe)

	Local aArea		:= GetArea()

	Local cAssig	:= ""
	Local cCCusto	:= ""
	Local cContab	:= ""
	Local cMensagem	:= ""
	Local cStatus	:= ""
	Local cTipo		:= ""
	Local cTransp	:= ""

	Local dVencto	:= CtoD("  /  /    ")
	Local dLancam	:= CtoD("  /  /    ")

	Local lRet		:= .T.

	Local nI
	Local nErro		:= 0
	Local nValor	:= 0

//	Private aFinanc	:= { "21", "31" }
//	Private aContab	:= { "39", "40", "50", "60" }

	If Len(aDetalhe) <= 0
		lRet 		:= .F.
		cStatus		:= "E"
		cMensagem 	:= CAT543003 + cRegistro + CAT543023 // #"O arquivo " #" n�o cont�m linhas de detalhes a serem importadas."
		nErro++

		// Adicion ao array de log
		Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
	Else
		For nI := 1 to Len(aDetalhe)
			// Define as vari�veis diferenciais
			cAssig		:= aDetalhe[nI][29]
			cTipo 		:= aDetalhe[nI][20]
			cCCusto		:= aDetalhe[nI][34]
			cContab		:= If(aScan(aContab, cTipo) > 0, aDetalhe[nI][21], "")  // Se o tipo � cont�bil, define a conta cont�bil
			cTransp		:= If(aScan(aFinanc, cTipo) > 0, aDetalhe[nI][21], "")  // Se o tipo � financeiro, define o forncedor
			dVencto		:= If(aScan(aFinanc, cTipo) > 0, aDetalhe[nI][27], "")  // Se o tipo � financeiro, define a data de vencimento do t�tulo.
			dLancam		:= aCabec[8]
			nValor		:= SuperVal(aDetalhe[nI][23])

			// Se o arquivo for do tipo financeiro.
			If aScan(aFinanc, cTipo) > 0
				// Valida a transportador como fornecedor.
				If !fVldForne(cTransp)
					nErro++
				EndIf

				// Valida a data de vencimento.
				If !Empty(dVencto)
					// Transforma as datas para o tipo date
					fDData(@dVencto)
					fDData(@dLancam)

					// Valida se a data de vencimento � maior que a de lan�amento.
					If !fVldVcto(dVencto, dLancam)
						nErro++
					EndIf
				EndIf
			EndIf

			// Se o arquivo for do tipo cont�bil.
			If aScan(aContab, cTipo) > 0
				// Valida a conta cont�bil.
				If !fVldContab(cContab)
					nErro++
				EndIf
			EndIf

			// Valida o destinat�rio da movimenta��o cont�bil.
			If !fVldForne(cAssig)
				nErro++
			EndIf

			// Se o arquivo for do tipo cont�bil.
			If aScan(aContab, cTipo) > 0
				// Valida o centro de custo.
				If !fVldCCusto(cCCusto)
					nErro++
				EndIf
			EndIf

			//Valida se a data de vencimento � superior
			// If !fVldVcto()//fVldVcto(UQI->UQI_IDIMP, UQI->UQI_VENC, UQI->UQI_ITEM)
				// lRet := .F.
			// EndIf

			// Valida o valor do documento
			If nValor <= 0
				nErro++
				cStatus		:= "E"
				cMensagem 	:= CAT543024 //"O valor do documento � menor ou igual a 0 (zero)."

				// Adicion ao array de log
				Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
			EndIf
		Next

		// Se alguma linha de detalhe n�o � valida.
		If nErro > 0
			lRet := .F.
		EndIf

	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldForne
Valida
@author Paulo Carvalho
@since 07/01/2019
@param cFornecedor, caracter, codigo do fornecedor.
@return lRet, l�gico, se a informa��o � valida.
@version 1.01
@type Static Function
/*/
Static Function fVldForne(cFornecedor)

	Local aArea		:= GetArea()
	Local aAreaSA2	:= SA2->(GetArea())

	Local lRet		:= .T.

	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))	// A2_FILIAL + A2_COD + A2_LOJA

	// Verifica se o campo n�o est� vazio
	If Empty(cFornecedor)
		lRet 		:= .F.
		cStatus		:= "E"
		cMensagem 	:= CAT543025 + cFornecedor + CAT543026 // #"A transportadora " #" n�o est� devidamente preenchida no detalhe do arquivo."

		// Adicion ao array de log
		Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
	Else
		// Valida a exist�ncia do fornecedor
		If !SA2->(DbSeek(xFilial("SA2") + cFornecedor))
		//	lRet 		:= .F.
			lImpErro	:= .T.
			cStatus		:= "E"
			cMensagem 	:= CAT543025 + cFornecedor + CAT543027 // #"A transportadora " #" n�o est� cadastrada no sistema como fornecedor."

			//Verifica se o erro j� foi registrado anteriormente e Adicion ao array de log
			If aScan(aLog, {|x| AllTrim(x[4]) == cMensagem	}) == 0
				Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
			EndIf
		Else
			// Valida se o fornecedor possui conta cont�bil cadastrada.
			If Empty(SA2->A2_CONTA)
			//	lRet 		:= .F.
				cStatus		:= "E"
				lImpErro	:= .T.
				cMensagem 	:= CAT543028 + cFornecedor + CAT543029 // #"O fornecedor " # " n�o possui vinculo com uma conta cont�bil."

				// Adicion ao array de log
				Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
			EndIf
		EndIf
	EndIf

	SA2->(DbCloseArea())

	RestArea(aAreaSA2)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldContab
Valida a exist�ncia da conta cont�bil
@author Paulo Carvalho
@since 07/01/2019
@param cContab, caracter, c�digo da conta cont�bil.
@return lRet, l�gico, se a informa��o � valida.
@version 1.01
@type Static Function
/*/
Static Function fVldContab(cContab)

	Local aArea		:= GetArea()
	Local lRet		:= .T.

	DbSelectArea("CT1")
	CT1->(DbSetOrder(1))	// CT1_FILIAL + CT1_CONTA

	// Verifica se o campo n�o est� vazio
	If Empty(cContab)
		lRet 		:= .F.
		cStatus		:= "E"
		cMensagem 	:= CAT543030 + cContab + CAT543031 // #"A conta cont�bil " #" n�o est� devidamente preenchida no detalhe do arquivo."

		// Adicion ao array de log
		Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
	Else
		// Valida a exist�ncia do fornecedor
		If !CT1->(DbSeek(xFilial("CT1") + cContab))
			// lRet 		:= .F.
			lImpErro	:= .T.
			cStatus		:= "E"
			cMensagem 	:= CAT543030 + cContab + CAT543032 // #"A conta cont�bil " #" n�o est� cadastrada no sistema."

			// Adicion ao array de log
			Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
		EndIf
	EndIf

	CT1->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldCCusto
Valida o centro de custo.
@author Paulo Carvalho
@since 07/01/2019
@param cCCusto, caracter, c�digo do centro de custo.
@return lRet, l�gico, se a informa��o � valida.
@version 1.01
@type Static Function
/*/
Static Function fVldCCusto(cCCusto)

	Local aArea		:= GetArea()
	Local lRet		:= .T.

	DbSelectArea("CTT")
	CTT->(DbSetOrder(1))	// CTT_FILIAL + CTT_CUSTO

	// Verifica se o campo n�o est� vazio
	If Empty(cCCusto)
		lRet 		:= .F.
		cStatus		:= "E"
		cMensagem 	:= CAT543033 + cCCusto + CAT543034 // #"O centro de custo " #" n�o est� devidamente preenchido no detalhe do arquivo."

		// Adicion ao array de log
		Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
	Else
		// Valida a exist�ncia do centro de custo
		If !CTT->(DbSeek(xFilial("CTT") + cCCusto))
			//lRet 		:= .F.
			lImpErro	:= .T.
			cStatus		:= "E"
			cMensagem 	:= CAT543033 + cCCusto + CAT543035 // #"O centro de custo " #" n�o est� cadastrado no sistema."

			// Adicion ao array de log
			Aadd(aLog, {cFilArq, cIdImp, cRegistro, cMensagem, nLin, cArquivo, cStatus, lImp})
		EndIf
	EndIf

	CTT->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldVcto
Valida se a data de vencimento n�o � menor do que a data do documento.
@author Paulo Carvalho
@since 16/01/2019
@param dVencto, data, data de vencimento do arquivo CTRB.
@param cLinha, car�cter, n�mero do item do arquivo CTRB para ser transformado em linha para o log de registro.
@return lRet, l�gico, .T. se a moeda � v�lida e .F. se n�o.
@version 1.01
@type Static function
/*/
Static Function fVldVcto(dVencto, dLancam)

	Local aArea		:= GetArea()

	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local lRet		:= .T.

	// Posiciona no fornecedor do item de rendi��o
	If dLancam > dVencto
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT543036 // "A data de vencimento � menor do que a data do t�tulo."

		// Adicion ao array de log
		Aadd(aLog, {cFilArq, Space( TamSX3("UQJ_IDIMP")[1]), cRegistro, cMensagem, nLin, cArquivo, cStatus, !lImp})
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvLog
Grava o registro de log para a importa��o dos arquivos CTRB
@author Paulo Carvalho
@since 07/01/2019
@param nLinha, n�merico, N�mero da linha que gerou o log.
@param cMensagem, caracter, Mensagem descritiva da ocorr�ncia do log.
@version 1.01
@type Static Function
/*/
Static Function fGrvLog(aLog)

	Local aArea		:= GetArea()
	Local cErro		:= CAT543037 //"Arquivo importado com erro. "
	Local cHora		:= "" // Time()
	Local cUsuario	:= IIf(l527Auto, cUserSched, UsrRetName(RetCodUsr()))
	Local dData		:= Date()

	Local nI

	// Abre a tabela de log da importa��o de arquivos CTRB
	DbSelectArea("UQJ")

	// Grava as informa��es do log
	For nI := 1 To Len(aLog)
		// Determina o hor�rio da gera��o do log
		cHora := Time()

		//Se a ultima variavel do array for .T. indica a importa��o com erros
		If aLog[nI][Len(aLog[nI])] .AND. aLog[nI][7] == "E"
			aLog[nI][4] := cErro + aLog[nI][4]
		EndIf

		// Trava a tabela para inclus�o de registro
		UQJ->(RecLock("UQJ", .T.))
			If !Empty(aLog[nI][1])
				UQJ->UQJ_FILIAL	:= fDefFilial(aLog[nI][1])
			Else
				UQJ->UQJ_FILIAL	:= FWxFilial("UQJ")
			EndIf

			UQJ->UQJ_FIL		:= aLog[nI][1]
			UQJ->UQJ_DATA	:= dData
			UQJ->UQJ_HORA	:= cHora
			UQJ->UQJ_IDIMP	:= aLog[nI][2]
			UQJ->UQJ_REGCOD	:= aLog[nI][3]
			UQJ->UQJ_MSG		:= aLog[nI][4]
			UQJ->UQJ_NLINHA	:= aLog[nI][5]
			UQJ->UQJ_ARQUIV	:= aLog[nI][6]
			UQJ->UQJ_USER	:= cUsuario
			UQJ->UQJ_ACAO	:= "IMP"
			UQJ->UQJ_LIDO	:= "N"
			UQJ->UQJ_STATUS	:= aLog[nI][7]

			If l527Auto
				UQJ->UQJ_IDSCHE := cIdSched
			EndIf

		// Destrava a Tabela
		UQJ->(MsUnlock())
	Next

	RestArea(aArea)

Return

/*/{Protheus.doc} fDefFilial
Define a filial do sistema baseando-se na filial veloce enviada no arquivo
@author Paulo Carvalho
@since 19/02/2019
@param cFilVelo, caracter, filial veloce.
@return cFilSis, caracter, filial do sistema equivalente � filial veloce.
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

/*/{Protheus.doc} fGrvCabec
Grava as informa��es do cabe�alho do arquivo.
@author Paulo Carvalho
@since 07/01/2019
@param aCabec, array, array contendo as informa��es do cabe�alho.
@version 1.01
@type Static Function
/*/
Static Function fGrvCabec(aCabec)

	Local aArea		:= GetArea()

	Local cStatus	:= If(lImpErro, "E", "I")

	Local dDoc		:= fData(aCabec[8])
	Local dGera		:= fData(aCabec[9])

	Local nTotal	:= SuperVal(aCabec[19])

	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	// Inicia transa��o
	BEGIN TRANSACTION

		// Grava o cabe�alho na tabela
		UQG->(RecLock("UQG", .T.))
			UQG->UQG_FILIAL	:= aCabec[1]
			UQG->UQG_IDIMP	:= aCabec[2]
			UQG->UQG_DTIMP	:= Date()
			UQG->UQG_TPREG	:= aCabec[3]
			UQG->UQG_TMSREG	:= aCabec[4]
			UQG->UQG_TPTRAN	:= cTpTrans//aCabec[5]
			UQG->UQG_TPDOC	:= aCabec[6]
			UQG->UQG_COMPCO	:= aCabec[7]
			UQG->UQG_DTDOC	:= StoD(dDoc)
			UQG->UQG_GERADO	:= StoD(dGera)
			UQG->UQG_REF	:= aCabec[10]
			UQG->UQG_TIPO	:= aCabec[11]
			UQG->UQG_HDTEXT	:= aCabec[12]
			UQG->UQG_MOEDA	:= aCabec[13]
			UQG->UQG_TXCAMB	:= SuperVal(aCabec[14])
			UQG->UQG_FIL	:= aCabec[15]
			UQG->UQG_CFOP	:= aCabec[16]
			UQG->UQG_NF		:= aCabec[17]
			UQG->UQG_VENDOR	:= aCabec[18]
			UQG->UQG_TOTAL	:= nTotal
			UQG->UQG_FILL1	:= aCabec[20]
			UQG->UQG_FILL2	:= aCabec[21]
			UQG->UQG_STATUS	:= cStatus
			UQG->UQG_VERREP	:= IIF(cTpTrans == "R" .And. Len(aCabec) >= 38, aCabec[38], "")
			UQG->UQG_IDSCHE	:= IIF(l527Auto, cIdSched, "")
		UQG->(MsUnlock())

	END TRANSACTION

	// Fecha a tabela
	UQG->(DbCloseArea())

	RestArea(aArea)

Return

/*/{Protheus.doc} fGrvDet
Grava as informa��es dos detalhes do arquivo.
@author Paulo Carvalho
@since 07/01/2019
@param aDetalhe, array, array contendo as informa��es dos detalhes.
@version 1.01
@type Static Function
/*/
Static Function fGrvDet(aDetalhe)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())

	Local nI

	// Se for um registro de provis�o
	If cTipoArq == "PR"
		// Seleciona a tabela de itens de provis�o
		DbSelectArea("UQH")
		UQH->(DbSetOrder(1))	// UQH_FILIAL + UQH_IDIMP + UQH_ITEM

		For nI := 1 to Len(aDetalhe)
			// Inicia a transa��o
			BEGIN TRANSACTION

				// Trava a tabela e inclui o registro
				RecLock("UQH", .T.)
					UQH->UQH_FILIAL	:= aDetalhe[nI][1]
					UQH->UQH_IDIMP	:= aDetalhe[nI][2]
					UQH->UQH_REF		:= cRegistro
					UQH->UQH_ITEM	:= aDetalhe[nI][3]
					UQH->UQH_TPREG	:= aDetalhe[nI][4]
					UQH->UQH_CHAVE	:= aDetalhe[nI][20]
					UQH->UQH_CONTAB	:= aDetalhe[nI][21]
					UQH->UQH_INDGL	:= aDetalhe[nI][22]
					UQH->UQH_TOTAL	:= SuperVal(aDetalhe[nI][23])
					UQH->UQH_TAXA	:= aDetalhe[nI][24]
					UQH->UQH_JURFIS	:= aDetalhe[nI][25]
					UQH->UQH_LCLNEG	:= aDetalhe[nI][26]
					UQH->UQH_VENC	:= StoD(fData(aDetalhe[nI][27]))
					UQH->UQH_CONDPA	:= aDetalhe[nI][28]
					UQH->UQH_ASSGN	:= aDetalhe[nI][29]
					UQH->UQH_ITMTEX	:= aDetalhe[nI][30]
					UQH->UQH_CONMAS	:= aDetalhe[nI][31]
					UQH->UQH_ESCVEN	:= aDetalhe[nI][32]
					UQH->UQH_DIV	:= aDetalhe[nI][33]
					UQH->UQH_CCUSTO	:= aDetalhe[nI][34]
					UQH->UQH_TRANSP	:= aDetalhe[nI][29]
				UQH->(MsUnlock())

			END TRANSACTION
		Next

		// Fecha a tabela de itens
		UQH->(DbCloseArea())
	ElseIf cTipoArq == "RD" .Or. cTipoArq == "A"
		// Seleciona a tabela de itens de provis�o
		DbSelectArea("UQI")
		UQI->(DbSetOrder(1))	// UQI_FILIAL + UQI_IDIMP + UQI_ITEM

		// Inicia a transa��o
		BEGIN TRANSACTION
			For nI := 1 to Len(aDetalhe)
				// Trava a tabela
				RecLock("UQI", .T.)
					// Inclui o registro de d�bito e adiciona no array de registro de credito
					UQI->UQI_FILIAL	:= aDetalhe[nI][1]
					UQI->UQI_IDIMP	:= aDetalhe[nI][2]
					UQI->UQI_REF		:= cRegistro
					UQI->UQI_ITEM	:= aDetalhe[nI][3]
					UQI->UQI_TPREG	:= aDetalhe[nI][4]
					UQI->UQI_CHAVE	:= aDetalhe[nI][20]

					// Se a chave do arquivo for 21, 31 ou 29
					If aScan(aFinanc, aDetalhe[nI][20]) > 0
						// Adiciona a transportadora
						UQI->UQI_TRANSP	:= aDetalhe[nI][21]
						UQI->UQI_LOJA	:= Posicione("SA2", 1, xFilial("SA2") + UQI->UQI_TRANSP, "A2_LOJA") // CriaVar("A2_LOJA")

						// Guarda a data de Vencimento
						// sVencto 		:= StoD(fData(aDetalhe[nI][27]))
						// cFornecedor		:= PadR(aDetalhe[nI][29], TamSX3("A2_COD")[1], " ")
					Else
						// Sen�o, adiciona conta cont�bil
						UQI->UQI_CONTAB	:= aDetalhe[nI][21]
					EndIf

					UQI->UQI_INDGL	:= aDetalhe[nI][22]
					UQI->UQI_TOTAL	:= SuperVal(aDetalhe[nI][23])
					UQI->UQI_TAXA	:= aDetalhe[nI][24]
					UQI->UQI_JURFIS	:= aDetalhe[nI][25]
					UQI->UQI_LCLNEG	:= aDetalhe[nI][26]
					UQI->UQI_VENC	:= StoD(fData(aDetalhe[nI][27]))
					UQI->UQI_CONDPA	:= aDetalhe[nI][28]
					UQI->UQI_ASSGN	:= aDetalhe[nI][29]
					UQI->UQI_ITMTEX	:= aDetalhe[nI][30]
					UQI->UQI_CONMAS	:= aDetalhe[nI][31]
					UQI->UQI_ESCVEN	:= aDetalhe[nI][32]
					UQI->UQI_DIV	:= aDetalhe[nI][33]
					UQI->UQI_CCUSTO	:= aDetalhe[nI][34]

					If cTipoArq == "RD" .And. AScan(aFinanc, UQI->UQI_CHAVE) > 0
						If Len(aDetalhe[nI]) == 38
							UQI->UQI_TPFRET	:= aDetalhe[nI][36]
							UQI->UQI_PRODUT	:= aDetalhe[nI][37]

							If !Empty(UQI->UQI_TPFRET) .And. !Empty(UQI->UQI_PRODUT)
								UQI->UQI_TOTAL	:= SuperVal(aDetalhe[nI][38])
							EndIf
						EndIf
					EndIf

				UQI->(MsUnlock())
			Next

			/*/ Comentado em 15/02/2019 - Paulo Carvalho
			*	Em reuni�o entre Marcos, Veloce e Silv�rio foi definido
			*	que a contrapartida de cred�to n�o ser� mais necess�ria.
			// Adiciona a contrapartida de credito para o lan�amento cont�bil da rendi��o
			RecLock("UQI", .T.)
				UQI->UQI_FILIAL	:= aDetalhe[2][1]
				UQI->UQI_IDIMP	:= aDetalhe[2][2]
				UQI->UQI_REF	:= cRegistro
				UQI->UQI_ITEM	:= aDetalhe[2][3]
				UQI->UQI_TPREG	:= aDetalhe[2][4]
				UQI->UQI_CHAVE	:= cChaveCP
				UQI->UQI_CONTAB	:= Posicione("SA2", 1, xFilial("SA2") + cFornecedor, "A2_CONTA")
				UQI->UQI_INDGL	:= cIndGL
				UQI->UQI_TOTAL	:= SuperVal(aDetalhe[1][23])
				UQI->UQI_TAXA	:= aDetalhe[2][24]
				UQI->UQI_JURFIS	:= aDetalhe[2][25]
				UQI->UQI_LCLNEG	:= aDetalhe[2][26]
				UQI->UQI_VENC	:= sVencto
				UQI->UQI_CONDPA	:= cCondPag
				UQI->UQI_ASSGN	:= aDetalhe[2][29]
				UQI->UQI_ITMTEX	:= aDetalhe[2][30]
				UQI->UQI_CONMAS	:= aDetalhe[2][31]
				UQI->UQI_ESCVEN	:= aDetalhe[2][32]
				UQI->UQI_DIV	:= aDetalhe[2][33]
				UQI->UQI_CCUSTO	:= aDetalhe[2][34]
			UQI->(MsUnlock())
			/*/
		END TRANSACTION

		// Fecha a tabela de itens
		UQI->(DbCloseArea())
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fData
Transforma as datas importadas do arquivo para string.
@author Paulo Carvalho
@since 08/01/2019
@param cData, caracter, data importada dos arquivos de texto.
@return sData, string, data transformada para padr�o string.
@version 1.01
@type Static Function
/*/
Static Function fData(cData)

	Local cAux	:= ""
	Local sData	:= ""

	cAux += Left(cData, 2) + "/"
	cAux += SubStr(cData, 3, 2) + "/"
	cAux += Right(cData, 4)

	sData := DtoS(CtoD(cAux))

Return sData

/*/{Protheus.doc} fDData
Transforma a data para o tipo date.
@author Paulo Carvalho
@since 05/02/2019
@param cData, caracter, data importada dos arquivos de texto.
@version 1.01
@type Static Function
/*/
Static Function fDData(dVencto)

	Local cAux	:= ""

	cAux += Left(dVencto, 2) + "/"
	cAux += SubStr(dVencto, 3, 2) + "/"
	cAux += Right(dVencto, 4)

	dVencto := CtoD(cAux)

Return

/*/{Protheus.doc} fSetLido
Seta todos os registros de log j� cadastrados como lidos.
@author Paulo Carvalho
@since 14/01/2019
@version 1.01
@type Static Function
/*/
Static Function fSetLido()

	Local aArea		:= GetArea()
	Local cQuery	:= ""

	cQuery	+= "UPDATE " + RetSQLName("UQJ") + " SET UQJ_LIDO = 'S' "	+ CRLF

	Execute(cQuery)

	RestArea(aArea)

Return

/*/{Protheus.doc} EXECUTE
Fun��o que executa fun��o sql
@author douglas-gregorio
@since 26/12/2017
@version undefined
@param cQuery, characters, descricao
@type function
/*/
Static Function Execute(cQuery)
	Local cErro   := ""
	Local lRet    := .T.
	Local nStatus := 0

	nStatus := TcSqlExec(cQuery)

	If nStatus < 0
		lRet := .F.
		cErro := TCSQLError()
		MsgAlert(CAT543038 + CRLF + cErro, cCadastro)	// "Erro ao executar rotina:"
	EndIf

Return lRet

/*/{Protheus.doc} fAjustaDet
Ajusta o array de detalhes gerando uma linha para cada produto da linha.
@author Juliano Fernandes
@since 26/08/2019
@version 1.0
@return Nil, N�o h� retorno
@param aDet, array, Detalhes CTRB Rendi��o (UQI) - (Referencia)
@param cItem, caracter, N�mero do item - (Referencia)
@type function
/*/
Static Function fAjustaDet(aDet, cItem)

	Local aProdutos := {}
	Local aAux		:= {}
	Local aDetOrig	:= AClone(aDet)

	Local nI		:= 0
	Local nJ		:= 0

	If Len(aDet) > 36
		For nI := 37 To Len(aDet)
			If nI + 1 <= Len(aDet)
				Aadd(aProdutos, {	aDet[ nI ] 	,;
									aDet[++nI]	})
			EndIf
		Next nI
	ElseIf Len(aDet) == 34
		Aadd(aDet, "")
		Aadd(aDet, CriaVar("UQI_TPFRET"))
		Aadd(aDet, CriaVar("UQI_PRODUT"))
		Aadd(aDet, CriaVar("UQI_TOTAL"))
	EndIf

	aAux := AClone(aDet)

	While Len(aAux) > 36
		ADel(aAux, Len(aAux))
		ASize(aAux, Len(aAux) - 1)
	EndDo

	aDet := {}

//	For nI := 0 To Len(aProdutos)
	For nI := 1 To Len(aProdutos)
		Aadd(aDet, {})
	Next nI

	// ---------------------------
	// Adiciona o item principal
	// ---------------------------
/*	AEval(aAux, {|x| Aadd(aDet[1], x)})
	Aadd(aDet[1], CriaVar("UQI_PRODUT"))
	Aadd(aDet[1], CriaVar("UQI_TOTAL"))
*/
	// ------------------------------------------
	// Adiciona uma linha para cada produto
	// ------------------------------------------
	For nI := 1 To Len(aProdutos)
		For nJ := 1 To Len(aAux)
//			Aadd(aDet[nI+1], aAux[nJ])
			Aadd(aDet[nI], aAux[nJ])
		Next nJ

/*		Aadd(aDet[nI+1], aProdutos[nI,1])
		Aadd(aDet[nI+1], aProdutos[nI,2])
*/		Aadd(aDet[nI], aProdutos[nI,1])
		Aadd(aDet[nI], aProdutos[nI,2])
	Next nI

	// ---------------------------
	// Ajusta o campo de item
	// ---------------------------
	For nI := 2 To Len(aDet)
		cItem := Soma1(cItem)

		aDet[nI,3] := cItem
	Next nI

	If Empty(aDet)
		aDet := AClone(aDetOrig)
	EndIf

Return(Nil)

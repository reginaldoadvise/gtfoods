#Include 'Totvs.ch'
#Include "CATTMS.ch"

// Variáveis Estáticas
Static NomePrt		:= "PRT0545"
Static VersaoJedi	:= "V1.38"

/*/{Protheus.doc} PRT0545
Rotinas do processo de integração dos arquivos CTRB no sistema.
@author Paulo Carvalho
@since 09/01/2019
@param cAcao, caracter, indica o processamento que dever ser realizado pela rotina.
@param aRecno, array, traz os recnos dos arquivos que devem ser integrados no sistema.
@return lRet, lógico, retorna se o processamento solicitado foi executado com sucesso ou não.
@version 1.01
@type User Function
/*/
User Function PRT0545( nAcao, aRecno, uPar )

    Local aArea         := GetArea()
    Local lRet          := .T.
    Local nOperacao   	:= If(Empty(nAcao), 1, nAcao)

	Private aLog		:= {}

    // Executa a Rotina solicitada
    Do Case
        Case nOperacao == NGETDADOS // Criação da GetDados
			fGetDados()
        Case nOperacao == NFILTRAR  // Filtragem dos Dados
            Processa({|| fFillCab()}, CAT545001, CAT545002 ) // #"Aguarde..." #"Filtrando registros."
        Case nOperacao == NINTEGRAR // Integração dos Dados
            Processa({|| fIntegrar()},	CAT545001, CAT545003) // #"Aguarde..." #"Processando integração dos registros selecionados."
        Case nOperacao == NEXCLUIR // Integração dos Dados
            Processa({|| fExcluir()},	CAT545001, CAT545004) // #"Aguarde..." #"Excluindo os registros selecionados."
		Case nOperacao == NESTORNAR
			Processa({|| fEstornar(uPar)}, CAT545001, CAT545005) //"Aguarde..." #"Estornando Arquivos"
        Case nOperacao == NCHECK   	// Integração dos Dados
            Processa({|| fSetChek(uPar)}, CAT545001, CAT545006)	// #"Aguarde...", #"Executando."
        Case nOperacao == NIMPRIMIR
		 	Processa({|| fReport()}, 	CAT545001, CAT545007)	// #"Aguarde...", #"Gerando relatório..."
		 Case nOperacao == NCONTAPAGAR
		 	Processa({|| fContaPagar()}, CAT545001, CAT545008)	// #"Aguarde...", #"Localizando conta a pagar..."
		 Case nOperacao == NLANCCTB
		 	Processa({|| fLancCTB()}, 	CAT545001, CAT545009) // #"Aguarde...", #"Localizando lançamento contábil..."
    EndCase

    RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGetDados
Cria a GetDados de cabeçalho do arquivo CTRB de acordo com os parâmetros definidos pelo usuário.
@author Paulo Carvalho
@since 09/01/2019
@version 1.01
@type Static Function
/*/
Static Function fGetDados()

    Local aArea     	:= GetArea()
    Local aArray    	:= {}
	Local aCampos		:= {}

	Local bChange		:= {|| fChangeGet() }

	Local cAlias		:= "UQG"

	Local nI, nH, nA

	Local nRow			:= 0
	Local nLeft			:= 0
	Local nBottom		:= 0
	Local nRight		:= 0

	Local oNo 			:= LoadBitmap( GetResources(), "LBNO" )
	Local oBlue   		:= LoadBitmap( GetResources(), "BR_AZUL")
	Local oAdd		   	:= LoadBitmap( GetResources(), "CATTMS_INC")

	// Reinicia o array a header
	aHeaderUQG := {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQD", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQD", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQD", "LINEND" )
		nRight	:= oSize:GetDimension( "GETDADOS_UQD", "COLEND" )
	EndIf

	// Posiciona no Alias correto
	SX3->(DbSeek(cAlias))

	// Adiciona, manualmente, todos os campos da tabela para o array aCampos
	Aadd( aCampos, "UQG_FILIAL"	)
	Aadd( aCampos, "UQK_DESCRI"	)
	Aadd( aCampos, "UQG_IDIMP" 	)
	Aadd( aCampos, "UQG_DTIMP" 	)
	Aadd( aCampos, "UQG_DTDOC" 	)
	Aadd( aCampos, "UQG_REF" 	)
	Aadd( aCampos, "UQG_HDTEXT"	)
	Aadd( aCampos, "UQG_MOEDA" 	)
	Aadd( aCampos, "UQG_TIPO" 	)
	Aadd( aCampos, "UQG_VERREP"	)

	// Adiciona campo para legenda no aHeader
	fAddExtra( @aHeaderUQG )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQG, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
	AdHeadRec( cAlias, aHeaderUQG )

	// Popula o array com dados inicias em branco.
	Aadd( aArray, oNo 	)
	Aadd( aArray, oBlue )
	Aadd( aArray, oAdd 	)

	For nA := 4 To Len( aHeaderUQG ) - 2
		Aadd( aArray, CriaVar( aHeaderUQG[nA][2], .T. ) )
    Next

	Aadd(aArray, cAlias) 	// Alias
	Aadd(aArray, 0) 		// Recno
	Aadd(aArray, .F.) 		// D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len (aHeaderUQG)
	 	If Empty(aHeaderUQG[nH][3]) .And. aHeaderUQG[nH][8] == "C"
			aHeaderUQG[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		// Instancia a GetDados
		oGDadUQG 	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oDialog, aHeaderUQG, { aArray }, bChange, /*cTela*/	)

		// Seleciona o item clicado
		oGDadUQG:oBrowse:bLDblClick := {|| fCheck(), oGDadUQG:oBrowse:Refresh()}

		// Impede a edição de linha
		oGDadUQG:SetEditLine(.F.)

		// Atualiza a GetDados
		oGDadUQG:Refresh()
	EndIf

	// Cria a GetDados de Provisão na primeira vez.
	fGDProv( Nil )

    RestArea(aArea)

Return

/*/{Protheus.doc} fCheck
Marca ou desmarca o registro.
@type function
@author Juliano Fernandes
@since 07/02/2018
@return Nil, Sem retorno
/*/
Static Function fCheck()

	Local nPsUQGCheck 	:= GDFieldPos("CHK", aHeaderUQG)

	Local oNo 			:= LoadBitmap( GetResources(), "LBNO" )
	Local oOk 			:= LoadBitmap( GetResources(), "LBOK" )

	If fVldCheck(.T.)
		If oGDadUQG:aCols[oGDadUQG:nAt, nPsUQGCheck]:cName == "LBNO"
			oGDadUQG:aCols[oGDadUQG:nAt, nPsUQGCheck] := oOk
		Else
			oGDadUQG:aCols[oGDadUQG:nAt, nPsUQGCheck] := oNo
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fSetChek
Marca e desmarca ou inverte o check em todos os registros.
@type function
@author Juliano Fernandes
@since 07/02/2018
@return Nil, Sem retorno
/*/
Static Function fSetChek(nOpc)

	Local cFilBkp		:= cFilAnt

	Local nI			:= 0
	Local nAt			:= 0
	Local nPsUQGCheck 	:= GDFieldPos("CHK", aHeaderUQG)

	Local oNo 			:= LoadBitmap( GetResources(), "LBNO" )
	Local oOk 			:= LoadBitmap( GetResources(), "LBOK" )

	ProcRegua(1)

	If !l528Auto
		nAt := oGDadUQG:nAt
	EndIf

	If nOpc == 1 /* Marcar todos */

		If l528Auto
			AEVal(aCoUQGAuto, {|x| nI++, IIf(fVldCheck(.F., nI), x[nPsUQGCheck] := oOk, Nil)})
		Else
			IncProc(CAT545010)	// "Marcando registros"
			AEVal(oGDadUQG:aCols, {|x| nI++, oGDadUQG:GoTo(nI), IIf(fVldCheck(.F.), x[nPsUQGCheck] := oOk, Nil)})
		EndIf

	ElseIf nOpc == 2 /* Desmarcar todos */

		If l528Auto
			AEVal(aCoUQGAuto, {|x| nI++, x[nPsUQGCheck] := oNo})
		Else
			IncProc(CAT545011) // "Desmarcando registros"
			AEVal(oGDadUQG:aCols, {|x| nI++, oGDadUQG:GoTo(nI), x[nPsUQGCheck] := oNo})
		EndIf

	ElseIf nOpc == 3 /* Inverter seleção */

		If l528Auto
			AEVal(aCoUQGAuto, {|x| nI++, x[nPsUQGCheck] := IIf(x[nPsUQGCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F., nI), oOk, oNo))})
		Else
			IncProc(CAT545012) // "Invertendo seleção de registros"
			AEVal(oGDadUQG:aCols, {|x| nI++, oGDadUQG:GoTo(nI), x[nPsUQGCheck] := IIf(x[nPsUQGCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F.), oOk, oNo))})
		EndIf

	EndIf

	StaticCall(PRT0528, fAltFilial, cFilBkp)

	If !l528Auto
		oGDadUQG:GoTo(nAt)
		oGDadUQG:Refresh()
	EndIf

Return(Nil)

/*/{Protheus.doc} fVldCheck
Valida se um determinado item da GetDados pode ou não ser marcado.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lValid, Indica se o registro pode ser marcado
@param lExibeMsg, logical, Indica se deve ou não exibir mensagem caso o registro não possa ser marcado
@type function
/*/
Static Function fVldCheck(lExibeMsg, nLinha)

	Local aArea		:= GetArea()
	Local aAreaUQG 	:= UQG->(GetArea())
	Local aColsVld	:= {}

	Local lValid 	:= .T.

	Local nPsIdImp	:= GDFieldPos("UQG_IDIMP", aHeaderUQG)
	Local nPsFilial	:= GDFieldPos("UQG_FILIAL", aHeaderUQG)
	Local nLinhaVld	:= 0
	Local nPos		:= 0

	Default nLinha 	:= 0

	If l528Auto
		aColsVld := AClone(aCoUQGAuto)
		nLinhaVld := nLinha
	Else
		aColsVld := AClone(oGDadUQG:aCols)
		nLinhaVld := oGDadUQG:nAt
	EndIf

	If Empty(aColsVld[nLinhaVld,nPsIdImp])
		lValid := .F.
	EndIf

	If lValid
		If (nPos := AScan(aFiliais, {|x| x[2] == aColsVld[nLinhaVld,nPsFilial]})) > 0
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])
		EndIf

		DbSelectArea("UQG")
		UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
		If UQG->( DbSeek(xFilial("UQG") + aColsVld[nLinhaVld,nPsIdImp]) )
			If UQG->UQG_STATUS == "P" // Integrado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT545013, cCadastro) // "O registro selecionado não pode ser marcado pois já foi integrado ao Protheus."
				EndIf
			ElseIf UQG->UQG_STATUS == "C" // Cancelado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT545014, cCadastro) // "O registro selecionado não pode ser marcado pois foi cancelado."
				EndIf
			ElseIf UQG->UQG_TIPO == "A"
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT545015, cCadastro) // "Não é possível integrar arquivos de adiantamento. O processo ainda está em desenvolvimento."
				EndIf
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return(lValid)

/*/{Protheus.doc} fFillCab
Popula a GetDados do cabeçalho dos arquivos CTRB.
@author Paulo Carvalho
@since 09/01/2019
@version 1.01
@type Static Function
/*/
Static Function fFillCab()

	Local aArea			:= GetArea()
	Local aCabec		:= {}
	Local aLinha		:= {}
	Local aTam			:= {}
	Local aTCSetField	:= {}
	Local aFilSel		:= {}
	Local aIdInQry		:= {} // Lista de Ids para cláusula IN da Qry caso tenha filtros de Título e Lote

	Local cAliasQry		:= GetNextAlias()
	Local cQuery		:= ""
	Local cAuxDocDe		:= ""
	Local cAuxDocAte	:= ""
	Local cFiliaisIn	:= ""

	Local lDeleted		:= .F.

	Local nJ			:= 0
	Local nI			:= 0

	Local oOk 			:= LoadBitmap( GetResources(), "LBOK" 		 	)
	Local oNo 			:= LoadBitmap( GetResources(), "LBNO" 		 	)

	Local oBlack		:= LoadBitmap( GetResources(), "BR_PRETO" 	 	)
	Local oBlue			:= LoadBitmap( GetResources(), "BR_AZUL" 	 	)
	Local oCancel		:= LoadBitmap( GetResources(), "BR_CANCEL" 	 	)
	Local oGreen		:= LoadBitmap( GetResources(), "BR_VERDE" 	 	)
	Local oVioleta		:= LoadBitmap( GetResources(), "BR_VIOLETA"		)
	Local oReprocess	:= LoadBitmap( GetResources(), "CATTMS_REP"		)
	Local oAdd			:= LoadBitmap( GetResources(), "CATTMS_INC"		)
	Local oRed			:= LoadBitmap( GetResources(), "BR_VERMELHO" 	)

	// Define os campos que passarão pela função TCSetField
	aTam := TamSX3("UQG_DTIMP") 	; Aadd( aTCSetField, { "UQG_DTIMP"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQG_DTDOC") 	; Aadd( aTCSetField, { "UQG_DTDOC"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQG_GERADO")	; Aadd( aTCSetField, { "UQG_GERADO"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQG_TXCAMB") 	; Aadd( aTCSetField, { "UQG_TXCAMB"	, aTam[3], aTam[1], aTam[2]	} )

	//-- Separa em array as filiais selecionadas pelo usuário
	aFilSel := StaticCall(PRT0528, fSepFiliais)
	aFiliais := {}
	cFiliaisIn := ""

	For nI := 1 To Len(aFilSel)
		cFiliaisIn += aFilSel[nI]

		If nI < Len(aFilSel)
			cFiliaisIn += ","
		EndIf
	Next nI

	cFiliaisIn := FormatIn(cFiliaisIn, ",")

		//-- Altera para a filial selecionada pelo usuário
		// StaticCall(PRT0528, fAltFilial, aFilSel[nI])

		// ----------------------------------------------------------
		// Juliano Fernandes - 06/05/19
		// Alterado para após o processamento da query
		// para que insira no array aFilials apenas as
		// filiais em que existem registros na tela
		// ----------------------------------------------------------
		//Aadd(aFiliais, {cFilAnt, xFilial("UQG")})

		// Monta a query do cabeçalho
		cQuery	:= "SELECT	UQG.UQG_FILIAL, UQG.UQG_STATUS, UQG.UQG_TMSREG, UQG.UQG_TPTRAN, UQG.UQG_TPDOC, UQG.UQG_COMPCO, "	+ CRLF
		cQuery	+= "		UQG.UQG_DTDOC, UQG.UQG_GERADO, UQG.UQG_REF, UQG.UQG_HDTEXT, UQG.UQG_MOEDA, UQG.UQG_TXCAMB, "			+ CRLF
		cQuery	+= "		UQG.UQG_TIPO, UQG.UQG_CFOP, UQG.UQG_NF, UQG.UQG_VENDOR, UQG.UQG_TIPO, UQG.UQG_IDIMP, UQG.UQG_DTIMP, " 	+ CRLF
		cQuery	+= "		UQG.UQG_VERREP, UQG.R_E_C_N_O_ AS RECNOUQG, UQK.UQK_DESCRI "										+ CRLF
		cQuery	+= "FROM	" + RetSqlName("UQG") + " UQG "																	+ CRLF
		cQuery	+= "	LEFT JOIN " + RetSqlName("UQK") + " UQK "															+ CRLF
		cQuery	+= "		ON UQK.UQK_FILIAL = '" + xFilial("UQK") + "' "													+ CRLF
		cQuery	+= "		AND UQK.UQK_FILPRO = UQG.UQG_FILIAL "															+ CRLF
		cQuery	+= "		AND UQK.D_E_L_E_T_ <> '*' "																		+ CRLF
		//cQuery	+= "WHERE	UQG.UQG_FILIAL = '" 			+ xFilial("UQG") 		+ "' "									+ CRLF
		cQuery	+= "WHERE	UQG.UQG_FILIAL IN " + cFiliaisIn + " "															+ CRLF

		If l528Auto
			cQuery  += "AND		UQG.UQG_STATUS = 'I'     "  				 					                      	 		+ CRLF
			cQuery  += "AND		UQG.UQG_IDSCHE = '" + cIdSched + "'     "   					                      	 	+ CRLF
		Else
			If !Empty(cFornecDe)
				cQuery	+= "AND		UQG.UQG_VENDOR >= '" 	+ cFornecDe 			+ "' "									+ CRLF
			EndIf

			If !Empty(cFornecAte)
				cQuery	+= "AND		UQG.UQG_VENDOR <= '" 	+ cFornecAte 			+ "' "									+ CRLF
			EndIf

			// Define o range de documentos
			cAuxDocDe	:= fDefDocDe(cDocDeUQG, cFiliaisIn)
			cAuxDocAte	:= fDefDocAte(cDocAteUQG, cFiliaisIn)

			If !Empty(cAuxDocDe)
				cQuery	+= "AND		UQG.UQG_REF >= '" + cAuxDocDe + "' "														+ CRLF
			EndIf

			If !Empty(cAuxDocAte)
				cQuery	+= "AND		UQG.UQG_REF <= '" + cAuxDocAte + "' "													+ CRLF
			EndIf

			If !Empty(dDataDe)
				cQuery	+= "AND		UQG.UQG_DTIMP >= '" 		+ DtoS(dDataDe)			+ "' "									+ CRLF
			EndIf

			If !Empty(dDataAte)
				cQuery	+= "AND		UQG.UQG_DTIMP <= '" 		+ DtoS(dDataAte)		+ "' "									+ CRLF
			EndIf

			If cCbStatus <> "Todos"
				cQuery	+= "AND		UQG.UQG_STATUS = '" 		+ Left(cCbStatus, 1)	+ "' "									+ CRLF
			EndIf
		EndIf

		cQuery	+= "AND		UQG.D_E_L_E_T_ <> '*' "																			+ CRLF

		If !l528Auto
			If !Empty(cGNTitDe) .Or. !Empty(cGNTitAte) .Or. !Empty(cGLoteDe) .Or. !Empty(cGLoteAte)
				aIdInQry := fTitLot()

				If !Empty(aIdInQry)
					For nJ := 1 To Len(aIdInQry)

						If nJ == 1
							cQuery += " AND UQG_IDIMP IN ( " + CRLF
						EndIf

						cQuery += " '" + aIdInQry[nJ] + "' " + CRLF

						If nJ == Len(aIdInQry)
							cQuery += ") " + CRLF
						Else
							cQuery += ", " + CRLF
						EndIf

					Next nJ
				EndIf

			EndIf
		EndIf

		cQuery	+= "ORDER BY UQG.UQG_FILIAL, UQG.UQG_REF" + CRLF

		// Cria o Alias
		MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

		ProcRegua(0)

		While !(cAliasQry)->(Eof())
			IncProc()

			If AScan(aFiliais, {|x| x[2] == (cAliasQry)->UQG_FILIAL}) == 0
				// ------------------------------------------------------------------
				// Inserido duas vezes no array aFilials por questão de adaptação
				// ao modo que o programa foi desenvolvido inicialmente.
				// ------------------------------------------------------------------
				Aadd(aFiliais, {(cAliasQry)->UQG_FILIAL, (cAliasQry)->UQG_FILIAL})
			EndIf

			// Reinicia o array aLinha
			aLinha := {}

			// Define o check e a Legenda do Status
			If (cAliasQry)->UQG_STATUS == "I"		// Aguardando Integração
				Aadd( aLinha, oOk )
				Aadd( aLinha, oBlue	)
			ElseIf (cAliasQry)->UQG_STATUS == "P"	// Integrado no Protheus
				Aadd( aLinha, oNo )
				Aadd( aLinha, oGreen)
			ElseIf (cAliasQry)->UQG_STATUS == "E"	// Erro na Integração
				Aadd( aLinha, oNo )
				Aadd( aLinha, oRed	)
			ElseIf (cAliasQry)->UQG_STATUS == "C"	// Cancelado
				Aadd( aLinha, oNo )
				Aadd( aLinha, oBlack)
			ElseIf (cAliasQry)->UQG_STATUS == "R" // Arquivo reprocessado
				Aadd( aLinha, oNo  )
				Aadd( aLinha, oVioleta )
			EndIf

			// Define a legenda do tipo de transação.
			If Empty((cAliasQry)->UQG_TPTRAN)
				Aadd( aLinha, oAdd )
			ElseIf (cAliasQry)->UQG_TPTRAN == "R"
				Aadd( aLinha, oReprocess )
			ElseIf (cAliasQry)->UQG_TPTRAN == "C"
				Aadd( aLinha, oCancel )
			EndIf

			Aadd( aLinha, (cAliasQry)->UQG_FILIAL	)
			Aadd( aLinha, (cAliasQry)->UQK_DESCRI 	)
			Aadd( aLinha, (cAliasQry)->UQG_IDIMP		)
			Aadd( aLinha, (cAliasQry)->UQG_DTIMP 	)
			Aadd( aLinha, (cAliasQry)->UQG_DTDOC 	)
			Aadd( aLinha, (cAliasQry)->UQG_REF	 	)
			Aadd( aLinha, (cAliasQry)->UQG_HDTEXT 	)
			Aadd( aLinha, (cAliasQry)->UQG_MOEDA 	)
			Aadd( aLinha, (cAliasQry)->UQG_TIPO	 	)
			Aadd( aLinha, (cAliasQry)->UQG_VERREP 	)
			Aadd( aLinha, "UQG"	 					)
			Aadd( aLinha, (cAliasQry)->RECNOUQG	 	)
			Aadd( aLinha, lDeleted				 	)

			// Adiciona a linha ao aCols
			Aadd( aCabec, aLinha )

			// Passa para próximo arquivos
			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
//	Next nI

	If !l528Auto
		// Se não houver nenhum dado
		If Empty(aCabec)
			// Reinicia o array aLinha
			aLinha := {}

			Aadd( aLinha, oNo 	)
			Aadd( aLinha, oBlue )
			Aadd( aLinha, oAdd 	)

			// Cria o array em branco
			For nJ := 4 To Len( aHeaderUQG ) - 2
				Aadd( aLinha, CriaVar( aHeaderUQG[nJ][2], .T. ) )
			Next

			Aadd( aLinha, "UQG" 	) // Alias WT
			Aadd( aLinha, 0 		) // Recno WT
			Aadd( aLinha, .F. 		) // D_E_L_E_T_

			Aadd(aCabec, aLinha)

			// Informe o usuário
			MsgInfo(CAT545016, cCadastro) // "Nenhum registro encontrado."
		EndIf

		// Define array aDados como aCols da GetDados
		oGDadUQG:SetArray( aCabec )

		// Atualiza a GetDados
		oGDadUQG:Refresh()
	Else
		aCoUQGAuto := AClone(aCabec)
	EndIf

	// Carrega os dados de provisão ou rendição de acordo com o primeiro registro
	fChangeGet()

	RestArea(aArea)

Return

/*/{Protheus.doc} fDefDocDe
Determina o primeiro documento para o range de pesquisa.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@return ${cAuxDocDe}, ${Primeiro documento para o range de pesquisa de documentos.}
@param cDocumento, characters, porção do documento desejado digitado pelo usuário.
@type Static function
/*/
Static Function fDefDocDe(cDocumento, cFiliaisIn)

	Local aArea		:= GetArea()

	Local cAliasQry	:= GetNextAlias()
	Local cAuxDocDe	:= ""
	Local cQuery	:= ""

	cQuery	+= "SELECT	UQG.UQG_REF "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQG") + " AS UQG "					+ CRLF
	//cQuery	+= "WHERE	UQG.UQG_FILIAL = '" + xFilial("UQG") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQG.UQG_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQG.UQG_REF LIKE '%" + AllTrim(cDocumento) + "%'  "	+ CRLF
	cQuery	+= "AND		UQG.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQG.UQG_REF "										+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocDe := (cAliasQry)->UQG_REF
	Else
		cAuxDocDe := "CTRB" + AllTrim(cDocumento) + "PR"
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return cAuxDocDe

/*/{Protheus.doc} fDefDocAte
Determina o último documento para o range de pesquisa.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@return ${cAuxDocDe}, ${Último documento para o range de pesquisa de documentos.}
@param cDocumento, characters, porção do documento desejado digitado pelo usuário.
@type Static function
/*/
Static Function fDefDocAte(cDocumento, cFiliaisIn)

	Local aArea			:= GetArea()

	Local cAliasQry		:= GetNextAlias()
	Local cAuxDocAte	:= ""
	Local cQuery		:= ""

	cQuery	+= "SELECT	UQG.UQG_REF "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQG") + " AS UQG "					+ CRLF
	// cQuery	+= "WHERE	UQG.UQG_FILIAL = '" + xFilial("UQG") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQG.UQG_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQG.UQG_REF LIKE '%" + AllTrim(cDocumento) + "%'  "	+ CRLF
	cQuery	+= "AND		UQG.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQG.UQG_REF DESC "									+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocAte := (cAliasQry)->UQG_REF
	Else
		cAuxDocAte := "CTRB" + AllTrim(cDocumento) + "RD"
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return cAuxDocAte

/*/{Protheus.doc} fChangeGet
Cria a GetDados de itens de provisão do arquivo CTRB.
@author Paulo Carvalho
@since 09/01/2019
@param cRef, caracter, numero de referência do arquivo CTRB.
@version 1.01
@type Static Function
/*/
Static Function fChangeGet()

	Local cRef		:= ""
	Local cIdImp	:= ""
	Local cTipo 	:= ""
	Local cFilImp	:= ""

	Local lContinua	:= .T.

	Local nPos		:= 0

	// Verifica se a GetDados já foi criada
	If !Type("oGDadUQG") == "O"
		lContinua := .F.
	EndIf

	If lContinua
		cIdImp 	:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_IDIMP",oGDadUQG:aHeader)]
		cFilImp	:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_FILIAL",oGDadUQG:aHeader)]
		cRef 	:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_REF",oGDadUQG:aHeader)]
		cTipo	:= Right(AllTrim(cRef), 2)

		// Se for do tipo adiantamento, acerta a variável
		If "A" $ cTipo
			cTipo := Right(cTipo, 1)
		EndIf

		If (nPos := AScan(aFiliais, {|x| x[2] == cFilImp})) > 0
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])
		EndIf

		If ValType(aHeaderUQH) != "A" //Valida se existe e cria a GetDados
			fGDProv()
		EndIf

		If ValType(aHeaderUQI) != "A" //Valida se existe e cria a GetDados
			fGDRend()
		EndIf

		Do Case
			Case "PR" $ cTipo
				// Esconde a GetDados de Rendição
				If ValType("oGDadUQI") == "O"
					oGDadUQI:Hide()
				EndIf

				// Exibe a GetDados de Provisão
				oGDadUQH:Show()

				// Popula a GetDados de Provisão
				fGDProv(cIdImp)
			Case cTipo == "RD" .Or. AllTrim(cTipo) == "A"
				// Esconde a GetDados de Provisão
				oGDadUQH:Hide()

				// Exibe a GetDados de Rendição
				If ValType("oGDadUQI") == "O"
					oGDadUQI:Show()
				EndIf

				// Popula a GetDados de Rendição
				fGDRend(cIdImp)
			Case Empty(cTipo)
				// Popula a GetDados de Provisão
				fGDProv("")
		EndCase
	EndIf

Return

/*/{Protheus.doc} fGDProv
Cria a GetDados de itens de provisão do arquivo CTRB.
@author Paulo Carvalho
@since 09/01/2019
@param cIdImp, caracter, Número sequencial identificador da importação do arquivo.
@version 1.01
@type Static Function
/*/
Static Function fGDProv(cIdImp)

    Local aArea     := GetArea()
    Local aArray    := {}
	Local aCampos	:= {}

	Local cAlias 	:= "UQH"

	Local nI, nJ, nH

	Local nRow		:= 0
	Local nLeft		:= 0
	Local nBottom	:= 0
	Local nRight	:= 0

	//Local oNo 		:= LoadBitmap( GetResources(), "LBNO" )
	//Local oBlue   	:= LoadBitmap( GetResources(), "BR_AZUL")

	// Reinicia o array a header
	aHeaderUQH := {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQE", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQE", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQE", "LINEND" ) + 15 // + 15 para compensar a falta da barra de título
		nRight	:= oSize:GetDimension( "GETDADOS_UQE", "COLEND" )
	EndIf

	// Adiciona todos os campos da tabela para o array aCampos
	Aadd( aCampos, "UQH_ITEM" 	)
	Aadd( aCampos, "UQH_CHAVE" 	)
	Aadd( aCampos, "UQH_CONTAB" 	)
	Aadd( aCampos, "UQH_TOTAL" 	)
	Aadd( aCampos, "UQH_CCUSTO" 	)
	Aadd( aCampos, "UQH_LOTE" 	)
	Aadd( aCampos, "UQH_SBLOTE" 	)
	Aadd( aCampos, "UQH_DOC" 	)
	Aadd( aCampos, "UQH_LINHA" 	)

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQH, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
	AdHeadRec( cAlias, aHeaderUQH )

	// Popula o array com dados inicias em branco.
	For nJ := 1 To Len( aHeaderUQH ) - 2
		Aadd( aArray, CriaVar( aHeaderUQH[nJ][2], .T. ) )
    Next

	Aadd(aArray, cAlias) 	// Alias
	Aadd(aArray, 0) 		// Recno
	Aadd(aArray, .F.) 		// D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len (aHeaderUQH)
		If Empty(aHeaderUQH[nH][3]) .And. aHeaderUQH[nH][8] == "C"
			aHeaderUQH[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		If ValType("oGDadUQH") != "O"
			// Instancia a GetDados
			oGDadUQH 	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
												/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
												/*cDelOk*/, oDialog, aHeaderUQH, { aArray }, /*uChange*/, /*cTela*/	)

			// Impede a edição de linha
			oGDadUQH:SetEditLine( .F. )
		EndIf
	EndIf

	// Popula a GetDados de provisão.
	If !Empty(cIdImp)
		fFillProv(cIdImp)
	EndIf

	If !l528Auto
		// Atualiza a GetDados
		oGDadUQH:Refresh()
	EndIf

    RestArea(aArea)

Return

/*/{Protheus.doc} fFillProv
Popula a GetDados de itens de provisão dos arquivos CTRB.
@author Paulo Carvalho
@since 09/01/2019
@param cIdImp, caracter, Número de referência do arquivo importado.
@version 1.01
@type Static Function
/*/
Static Function fFillProv(cIdImp)

	Local aArea			:= GetArea()
	Local aProvi		:= {}
	Local aLinha		:= {}
	Local aTCSetField	:= {}

	Local cAliasQry		:= GetNextAlias()
	Local cQuery		:= ""

	Local lDeleted		:= .F.

	Local nJ

	// Se for passado um documento de referência
	If !Empty(cIdImp)
		// Define os campos que passarão pela função TCSetField
		aTam := TamSX3("UQH_VENC") 	; Aadd( aTCSetField, { "UQH_VENC"	, aTam[3], aTam[1], aTam[2]	} )
		aTam := TamSX3("UQH_TOTAL") 	; Aadd( aTCSetField, { "UQH_TOTAL"	, aTam[3], aTam[1], aTam[2]	} )

		// Monta a query do cabeçalho
		cQuery	+= "SELECT	UQH.UQH_FILIAL, UQH.UQH_REF, UQH.UQH_ITEM, UQH.UQH_CHAVE, UQH.UQH_CONTAB, UQH.UQH_INDGL, "		+ CRLF
		cQuery	+= "		UQH.UQH_TOTAL, UQH.UQH_LCLNEG, UQH.UQH_VENC, UQH.UQH_CONDPA, UQH.UQH_ASSGN, UQH.UQH_ITMTEX, "	+ CRLF
		cQuery	+= "		UQH.UQH_CONMAS, UQH.UQH_ESCVEN, UQH.UQH_DIV, UQH.UQH_CCUSTO, UQH.UQH_LOTE, UQH.UQH_SBLOTE, "		+ CRLF
		cQuery	+= "		UQH.UQH_DOC, UQH.UQH_LINHA, UQH.UQH_IDIMP, UQH.R_E_C_N_O_ AS RECNOUQH"							+ CRLF
		cQuery	+= "FROM	" + RetSqlName("UQH") + " UQH "																+ CRLF
		cQuery	+= "WHERE	UQH.UQH_FILIAL = '" 		+ xFilial("UQH") 	+ "' "											+ CRLF
		cQuery	+= "AND		UQH.UQH_IDIMP = '" 		+ cIdImp			+ "' "											+ CRLF
		cQuery	+= "AND		UQH.D_E_L_E_T_ <> '*' "																		+ CRLF

		// Cria o Alias
		MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

		While !(cAliasQry)->(Eof())
			// Reinicia o array aLinha
			aLinha := {}

			// Preenche o array aLinha
			Aadd( aLinha, (cAliasQry)->UQH_ITEM		)
			Aadd( aLinha, (cAliasQry)->UQH_CHAVE 	)
			Aadd( aLinha, (cAliasQry)->UQH_CONTAB 	)
			Aadd( aLinha, (cAliasQry)->UQH_TOTAL		)
			Aadd( aLinha, (cAliasQry)->UQH_CCUSTO 	)
			Aadd( aLinha, (cAliasQry)->UQH_LOTE	 	)
			Aadd( aLinha, (cAliasQry)->UQH_SBLOTE 	)
			Aadd( aLinha, (cAliasQry)->UQH_DOC	 	)
			Aadd( aLinha, (cAliasQry)->UQH_LINHA	 	)
			Aadd( aLinha, "UQH" 					)
			Aadd( aLinha, (cAliasQry)->RECNOUQH 	)
			Aadd( aLinha, lDeleted 					)

			// Adiciona a linha ao aCols
			Aadd( aProvi, aLinha )

			// Passa para próximo arquivos
			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
	EndIf

	If !l528Auto
		// Se não houver nenhum dado
		If Empty(aProvi)
			// Reinicia o array aLinha
			aLinha := {}

			// Cria o array em branco
			For nJ := 1 To Len( aHeaderUQH ) - 2
				Aadd( aLinha, CriaVar( aHeaderUQH[nJ][2], .T. ) )
			Next

			Aadd( aLinha, "UQH" 	) // Alias WT
			Aadd( aLinha, 0 		) // Recno WT
			Aadd( aLinha, .F. 		) // D_E_L_E_T_

			Aadd(aProvi, aLinha)
		EndIf

		// Define array aProvi como aCols da GetDados
		oGDadUQH:SetArray( aProvi )

		// Atualiza a GetDados
		oGDadUQH:Refresh()
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc} fGDRend
Cria a GetDados de itens de rendição do arquivo CTRB.
@author Paulo Carvalho
@since 09/01/2019
@param cIdImp, caracter, Número de referência do arquivo importado.
@version 1.01
@type Static Function
/*/
Static Function fGDRend(cIdImp)

    Local aArea     := GetArea()
    Local aAreaSX3  := SX3->(GetArea())
    Local aArray    := {}
	Local aCampos	:= {}

	Local cAlias	:= "UQI"

	Local nI, nJ, nH

	Local nRow		:= 0
	Local nLeft		:= 0
	Local nBottom	:= 0
	Local nRight	:= 0

	// Reinicia o array a header
	aHeaderUQI := {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQE", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQE", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQE", "LINEND" ) + 15 // + 15 para compensar a falta da barra de título
		nRight	:= oSize:GetDimension( "GETDADOS_UQE", "COLEND" )
	EndIf

	// Adiciona todos os campos da tabela para o array aCampos
	Aadd( aCampos, "UQI_ITEM" 	)
	Aadd( aCampos, "UQI_CHAVE" 	)
	Aadd( aCampos, "UQI_CONTAB"	)
	Aadd( aCampos, "UQI_TRANSP" )
	Aadd( aCampos, "UQI_TPFRET"	)
	Aadd( aCampos, "UQI_PRODUT"	)
	Aadd( aCampos, "UQI_TOTAL" 	)
	Aadd( aCampos, "UQI_CCUSTO" )
	Aadd( aCampos, "UQI_LOTE" 	)
	Aadd( aCampos, "UQI_SBLOTE" )
	Aadd( aCampos, "UQI_DOC" 	)
	Aadd( aCampos, "UQI_LINHA" 	)
	Aadd( aCampos, "UQI_PREFIX"	)
	Aadd( aCampos, "UQI_NUM" 	)
	Aadd( aCampos, "UQI_PARCEL"	)
	Aadd( aCampos, "UQI_TIPO"	)

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQI, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
	AdHeadRec( cAlias, aHeaderUQI )

	For nJ := 1 To Len( aHeaderUQI ) - 2
		Aadd( aArray, CriaVar( aHeaderUQI[nJ][2], .T. ) )
    Next

	Aadd(aArray, cAlias) 	// Alias
	Aadd(aArray, 0) 		// Recno
	Aadd(aArray, .F.) 		// D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len (aHeaderUQI)
		If Empty(aHeaderUQI[nH][3]) .And. aHeaderUQI[nH][8] == "C"
			aHeaderUQI[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		If ValType("oGDadUQI") != "O"
			// Instancia a GetDados
			oGDadUQI 	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialog, aHeaderUQI, { aArray }, /*uChange*/, /*cTela*/	)

			// Impede a edição de linha
			oGDadUQI:SetEditLine( .F. )
		EndIf
	EndIf

	// Popula a GetDados de provisão.
	If !Empty(cIdImp)
		fFillRend(cIdImp)
	EndIf

	If !l528Auto
		// Atualiza a GetDados
		oGDadUQI:Refresh()
	EndIf

    RestArea(aAreaSX3)
    RestArea(aArea)

Return

/*/{Protheus.doc} fFillRend
Popula a GetDados de itens de rendição dos arquivos CTRB.
@author Paulo Carvalho
@since 09/01/2019
@param cIdImp, caracter, Número de referência do arquivo importado.
@version 1.01
@type Static Function
/*/
Static Function fFillRend(cIdImp)

	Local aArea			:= GetArea()
	Local aRendi		:= {}
	Local aLinha		:= {}
	Local aTCSetField	:= {}

	Local nJ

	Local lDeleted		:= .F.

	Local cAliasQry		:= GetNextAlias()
	Local cQuery		:= ""

	// Se o número de referência do documento não estiver vázio
	If !Empty(cIdImp)
		// Define os campos que passarão pela função TCSetField
		aTam := TamSX3("UQI_VENC") 	; Aadd( aTCSetField, { "UQI_VENC"	, aTam[3], aTam[1], aTam[2]	} )
		aTam := TamSX3("UQI_TOTAL") 	; Aadd( aTCSetField, { "UQI_TOTAL"	, aTam[3], aTam[1], aTam[2]	} )
		aTam := { 17, 0, "N" } 		; Aadd( aTCSetField, { "RECNOUQI"	, aTam[3], aTam[1], aTam[2]	} )

		// Monta a query do cabeçalho
		cQuery	+= "SELECT	UQI.UQI_FILIAL, UQI.UQI_IDIMP, UQI.UQI_REF, UQI.UQI_ITEM, UQI.UQI_CHAVE, UQI.UQI_CONTAB, UQI.UQI_INDGL, "	+ CRLF
		cQuery	+= "		UQI.UQI_TOTAL, UQI.UQI_LCLNEG, UQI.UQI_VENC, UQI.UQI_CONDPA, UQI.UQI_ASSGN, UQI.UQI_ITMTEX, "			+ CRLF
		cQuery	+= "		UQI.UQI_CONMAS, UQI.UQI_ESCVEN, UQI.UQI_DIV, UQI.UQI_CCUSTO, UQI.UQI_LOTE, UQI.UQI_SBLOTE, UQI.UQI_LINHA,"	+ CRLF
		cQuery	+= "		UQI.UQI_DOC, UQI.UQI_TRANSP, UQI.UQI_PREFIX, UQI.UQI_NUM, UQI.UQI_PARCEL, UQI.UQI_TIPO, "				+ CRLF
		cQuery	+= "		UQI.UQI_TPFRET, UQI.UQI_PRODUT, UQI.R_E_C_N_O_ RECNOUQI "											+ CRLF
		cQuery	+= "FROM	" + RetSqlName("UQI") + " UQI "																		+ CRLF
		cQuery	+= "WHERE	UQI.UQI_FILIAL = '" 		+ xFilial("UQI") 	+ "' "													+ CRLF
		cQuery	+= "AND		UQI.UQI_IDIMP = '" 		+ cIdImp			+ "' "													+ CRLF
		cQuery	+= "AND		UQI.D_E_L_E_T_ <> '*' "																				+ CRLF

		// Cria o Alias
		MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

		While !(cAliasQry)->(Eof())
			// Reinicia o array aLinha
			aLinha := {}

			// Preenche o array aLinha
			Aadd( aLinha, (cAliasQry)->UQI_ITEM		)
			Aadd( aLinha, (cAliasQry)->UQI_CHAVE 	)
			Aadd( aLinha, (cAliasQry)->UQI_CONTAB 	)
			Aadd( aLinha, (cAliasQry)->UQI_TRANSP 	)
			Aadd( aLinha, (cAliasQry)->UQI_TPFRET 	)
			Aadd( aLinha, (cAliasQry)->UQI_PRODUT 	)
			Aadd( aLinha, (cAliasQry)->UQI_TOTAL	)
			Aadd( aLinha, (cAliasQry)->UQI_CCUSTO 	)
			Aadd( aLinha, (cAliasQry)->UQI_LOTE	 	)
			Aadd( aLinha, (cAliasQry)->UQI_SBLOTE 	)
			Aadd( aLinha, (cAliasQry)->UQI_DOC	 	)
			Aadd( aLinha, (cAliasQry)->UQI_LINHA	)
			Aadd( aLinha, (cAliasQry)->UQI_PREFIX 	)
			Aadd( aLinha, (cAliasQry)->UQI_NUM	 	)
			Aadd( aLinha, (cAliasQry)->UQI_PARCEL 	)
			Aadd( aLinha, (cAliasQry)->UQI_TIPO 	)
			Aadd( aLinha, "UQI" 					)
			Aadd( aLinha, (cAliasQry)->RECNOUQI 	)
			Aadd( aLinha, lDeleted 					)

			// Adiciona a linha ao aCols
			Aadd( aRendi, aLinha )

			// Passa para próximo arquivos
			(cAliasQry)->(DbSkip())
		EndDo
		(cAliasQry)->(DbCloseArea())
	EndIf

	If !l528Auto
		// Se não houver nenhum dado
		If Empty(aRendi)
			// Reinicia o array aLinha
			aLinha := {}

			// Cria o array em branco
			For nJ := 1 To Len( aHeaderUQI ) - 2
				Aadd( aLinha, CriaVar( aHeaderUQI[nJ][2], .T. ) )
			Next

			Aadd( aLinha, "UQI"	) // Alias WT
			Aadd( aLinha, 0 	) // Recno WT
			Aadd( aLinha, .F. 	) // D_E_L_E_T_

			Aadd(aRendi, aLinha)
		EndIf

		// Define array aRendi como aCols da GetDados
		oGDadUQI:SetArray( aRendi )

		// Atualiza a GetDados
		oGDadUQI:Refresh()
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc} fAddExtra
Adiciona campos extra SX3 no aHeader.
@author Paulo Carvalho
@since 09/01/2019
@param aArray, array, Array contendo a referência de aHeader
@version 1.01
@type function
/*/
Static Function fAddExtra( aArray )

	// CheckBox
	Aadd( aArray, { "", "CHK", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

	// Legenda
	Aadd( aArray, { "", "COR", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

	// Legenda Ação
	Aadd( aArray, { "", "COR2", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

Return

/*/{Protheus.doc} fAddHeader
Função para adicionar no aHeader o campo determinado.
@author Douglas Gregório
@since 07/05/2018
@version 1.01
@return uRet, Nulo
@param aArray, array, Array que irá receber os dados da coluna
@param cNomeCampo, characters, Campo que será adicionado
@type function
/*/
Static Function fAddHeader(aArray, cNomeCampo)

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	Local uRet	:= Nil

	DbSelectArea("SX3")
	SX3->(dbSetOrder(2))	// X3_CAMPO

	If SX3->(DbSeek(cNomeCampo))
		Aadd( aArray, {	X3Titulo(),;
						SX3->X3_CAMPO,;
						SX3->X3_PICTURE,;
						SX3->X3_TAMANHO,;
						SX3->X3_DECIMAL,;
						SX3->X3_VALID,;
						SX3->X3_USADO,;
						SX3->X3_TIPO,;
						SX3->X3_F3,;
						SX3->X3_CONTEXT,;
						X3Cbox(),;
						SX3->X3_RELACAO	} )
	Endif

	RestArea(aAreaSX3)
	RestArea(aArea)

Return uRet

/*/{Protheus.doc} fIntegrar
Rotina que realiza a integração contábil e financeiro dos arquivos CTRB.
@author Paulo Carvalho
@since 11/01/2019
@version 1.01
@type Static function
/*/
Static Function fIntegrar()

	Local aRegistros	:= {}
	Local aProvisao		:= {}
	Local aRendicao		:= {}

	Local cMensagem		:= ""
	Local cModBkp		:= ""

	//Local lRet			:= .T.

	Local nI			:= 0
	Local nModBkp		:= 0

	Private a545WrkAre	:= {}

	Private n545WrkAre	:= 0

	Private nOk			:= 0
	Private nErro		:= 0

	// Seta os logs como lidos
	fSetLido()

	//-- Grava informações do módulo atual
	StaticCall(PRT0528, fAltModulo, @cModBkp, @nModBkp)

	For nI := 1 To Len(aFiliais)
		// Define os registros selecionados para integração.
		aRegistros := fGetSels(aFiliais[nI,2])

		If !Empty(aRegistros)
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nI,1])

			// Separa os registros em arrays de provisão e rendição
			fArrPrvRnd(@aProvisao, @aRendicao, aRegistros)

			a545WrkAre := {}
			n545WrkAre := 0

			// Realiza a integração de itens de provisão
			Processa( {|| fIntProv(aProvisao)}, CAT545017, CAT545018) // "Integrando...", "Processando registros de provisão."

			a545WrkAre := {}
			n545WrkAre := 0

			// Realiza a integração de itens de rendição
			Processa( {|| fIntRend(aRendicao)}, CAT545017, CAT545019) // "Integrando...", "Processando registros de rendição."
		EndIf
	Next nI

	// Realiza a gravação do log de integração
	fGrvLog(aLog)

	If !l528Auto
		// Exibe mensagem
		cMensagem 	:= 	CAT545020 + CRLF +; // "Integração de arquivos CTRB finalizada. Verifique o resultado abaixo."
						CRLF + CAT545021 + cValToChar(nOk) + CRLF +; // "Itens integrados: "
						CAT545022 + cValToChar(nErro) + CRLF +; // "Itens não integrados: "
						CRLF + CAT545023 // "Deseja visualizar o log da integração?"

		If MsgYesNo(cMensagem, cCadastro)
			// Chama o programa de visualização de log de registros.
			U_PRT0533("UQJ", .T., Nil, "INT")
		EndIf
	EndIf

	// Atualiza GetDados
	fFillCab()

	//-- Retorna para o módulo de origem
	StaticCall(PRT0528, fAltModulo, cModBkp, nModBkp)

Return

/*/{Protheus.doc} fGetSels
Extrai da GetDados os documentos selecionados para integração.
@author Paulo Carvalho
@since 15/01/2019
@version 1.01
@param cFilSel caracter, Filial a ser filtrada
@type Static function
/*/
Static Function fGetSels(cFilSel)

	// Captura a GetDados.
	Local aAux		:= {}
	Local aSels		:= {}

	// Define a posição do check de selecionado
	Local nPsUQGCheck	:= GDFieldPos("CHK", aHeaderUQG)
	Local nPsUQGFilial	:= GDFieldPos("UQG_FILIAL", aHeaderUQG)

	Default cFilSel	:= ""

	If !l528Auto
		aAux := aClone(oGDadUQG:aCols)
	Else
		aAux := AClone(aCoUQGAuto)
	EndIf

	// Separa os itens selecionados pelo usuário.
	If Empty(cFilSel)
		aEval( aAux, {|x| If( x[nPsUQGCheck]:cName == "LBOK", Aadd(aSels, x), Nil ) } )
	Else
		aEval( aAux, {|x| If( x[nPsUQGCheck]:cName == "LBOK" .And. x[nPsUQGFilial] == cFilSel, Aadd(aSels, x), Nil ) } )
	EndIf

Return aClone(aSels)

/*/{Protheus.doc} fArrPrvRnd
Extrai da GetDados os documentos selecionados para integração.
@author Paulo Carvalho
@since 15/01/2019
@version 1.01
@type Static function
/*/
Static Function fArrPrvRnd(aProvisao, aRendicao, aRegistros)

	Local cProvisao		:= "PR"
	Local cRendicao		:= "RD"
	Local cAdiantamento	:= "A"

	Local nI

	Local nPsTipo	:= GdFieldPos("UQG_TIPO", aHeaderUQG)
	Local nPsData	:= GdFieldPos("UQG_DTDOC", aHeaderUQG)
	Local nPsRef	:= GdFieldPos("UQG_REF", aHeaderUQG)

	// Para cada registro selecionado
	For nI := 1 To Len(aRegistros)
		// Se for um arquivo de provisão
		If aRegistros[nI][nPsTipo] == cProvisao
			Aadd(aProvisao, aRegistros[nI])
		// Se for um arquivo de rendição ou adiantamento
		ElseIf aRegistros[nI][nPsTipo] == cRendicao .Or. AllTrim(aRegistros[nI][nPsTipo]) == cAdiantamento
			Aadd(aRendicao, aRegistros[nI])
		EndIf
	Next

	// Ordena os arrays por data e referência
	aSort(aProvisao, , , {|x,y| DtoS(x[nPsData]) + x[nPsRef] < DtoS(y[nPsData]) + y[nPsRef]})
	aSort(aRendicao, , , {|x,y| DtoS(x[nPsData]) + x[nPsRef] < DtoS(y[nPsData]) + y[nPsRef]})

Return

/*/{Protheus.doc} fIntProv
Rotina para integração dos arquivos CTRB de provisão.
@author Paulo Carvalho
@since 11/01/2019
@return aProvisao, array, array com os arquivos de provisão selecionados para integração.
@version 1.01
@type Static function
/*/
Static Function fIntProv(aProvisao)

	Local aArea			:= GetArea()

	Local cCancelamento	:= "C"
	Local cIdImp		:= ""
	Local cInclusao		:= " "

	Local lRet			:= .T.

	Local nI
	Local nProvisoes	:= Len(aProvisao)
	Local nPsIdImp		:= GdFieldPos("UQG_IDIMP", aHeaderUQG)
	Local nPsRef		:= GdFieldPos("UQG_REF", aHeaderUQG)

	Private cCTRB		:= ""
	Private cFilArq		:= ""

	ProcRegua(nProvisoes)

	For nI := 1 To Len(aProvisao)
		IncProc(CAT545024) //"Integrando provisões..."

		// Define o arquivo CTRB a ser integrado
		cIdImp	:= aProvisao[nI][nPsIdImp]
		cCTRB	:= aProvisao[nI][nPsRef]

		// Posiciona no cabeçalho do arquivo atual
		DbSelectArea("UQG")
		UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

		If UQG->(DbSeek(xFilial("UQG") + cIdImp))
			// Define a filial do arquivo
			cFilArq := UQG->UQG_FIL

			// Verifica o tipo de ação a ser realizada
			If UQG->UQG_TPTRAN == cInclusao
				fIncluiPrv(UQG->UQG_IDIMP)
			ElseIf UQG->UQG_TPTRAN == cCancelamento
				fCancelPrv(UQG->UQG_REF, .F., UQG->UQG_VERREP, cIdImp)
			EndIf
		EndIf
	Next

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fIncluiPrv
Rotina de integração de inclusão de arquivos de provisão.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImp, carácter, código identificador da importação da provisão.
@version 1.01
@type Static function
/*/
Static Function fIncluiPrv(cIdImp)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())
	Local aAreaUQH		:= UQH->(GetArea())

	Local aCabecalho	:= {}
	Local aItem			:= {}
	Local aItens		:= {}
	Local aFornec		:= {}

	Local cCusCred		:= ""
	Local cCusDeb		:= ""
	Local cCredito		:= ""
	Local cDebito		:= ""
	Local cDoc			:= ""
	Local cHist			:= ""
	Local cLinha		:= "0"
	Local cLote			:= ""
	Local cMensagem		:= ""
	Local cMoeda		:= ""
	Local cMsgDet		:= ""
	Local cProvisao		:= "PR"
	Local cStatus		:= ""
	Local cSubLote		:= ""
	Local cClVl			:= ""
	Local cFornecUQH	:= ""

	Local dData			:= ""

	//Local lContinua		:= .T.

	Local nDC			:= 1
	Local nValor		:= 0

	//Variavel de Controle do MsExecAuto
	Private lMsErroAuto := .F.

	//Variavel de Controle do GetAutoGRLog
	Private lAutoErrNoFile := .T.

	// Posiciona no cabeçalho do registro
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))		// UQG_FILIAL + UQG_IDIMP

	If UQG->(DbSeek(xFilial("UQG") + cIdImp))
		// Abre a tabela de itens de provisão
		DbSelectArea("UQH")
		UQH->(DbSetOrder(1))	// UQH_FILIAL + UQH_IDIMP + UQH_ITEM

		// Se encontrar itens para este arquivo
		If UQH->( DbSeek(xFilial("UQH") + UQG->UQG_IDIMP) )
			// Verifica se o arquivo é válido para inclusão
			If fVldProv(cIdImp)
				// Define as variáveis principais
				dData		:= UQG->UQG_DTDOC
				cDoc		:= SubStr(AllTrim(UQG->UQG_REF), 5, 6)
				cLote		:= fProxLote()  // GetSXENum("CT2", "CT2_LOTE", Nil, 1)
				cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)
				cSubLote	:= cProvisao
				aFornec		:= fGetFornec(cIdImp, cSubLote)
				cFornecUQH	:= aFornec[1]

				// Monta o Array de cabeçalho
				Aadd(aCabecalho, { 'DDATALANC'	, dData		, NIL })
				Aadd(aCabecalho, { 'CLOTE'	  	, cLote		, NIL })
				Aadd(aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL })
				Aadd(aCabecalho, { 'CDOC'		, cDoc		, NIL })
				Aadd(aCabecalho, { 'CPADRAO'	, ""		, NIL })
				Aadd(aCabecalho, { 'NTOTINF'	, 0			, NIL })
				Aadd(aCabecalho, { 'NTOTINFLOT', 0			, NIL })

				// Enquanto houver itens de provisão
				While !UQH->(Eof()) .And. UQH->UQH_IDIMP == cIdImp
					// Reinicia o array de item
					aItem := {}

					// Define as variáveis dos itens
					cCredito	:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", AllTrim(UQH->UQH_CONTAB), "" )
					cDebito		:= IIf( !(AllTrim(UQH->UQH_CHAVE) $ ".39.50."), AllTrim(UQH->UQH_CONTAB), "" )
					cCusCred	:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", AllTrim(UQH->UQH_CCUSTO), "" )
					cCusDeb		:= IIf( !(AllTrim(UQH->UQH_CHAVE) $ ".39.50."), AllTrim(UQH->UQH_CCUSTO), "" )
					cLinha		:= PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
					cHist		:= UQH->UQH_ITMTEX
					nDC 		:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", 2, 1 )
					nValor		:= UQH->UQH_TOTAL

					// Monta array do item
					Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
					Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
					Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
					Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada

					If AllTrim(UQH->UQH_CHAVE) $ ".39.50."
						Aadd( aItem, {'CT2_CREDIT'	, cCredito		, NIL } )
						Aadd( aItem, {'CT2_CCC'		, cCusCred		, NIL } )

						If fClVlObrig(cCredito)
						/*	cFornecUQH := UQH->UQH_TRANSP

							If Empty(cFornecUQH)
								cFornecUQH := UQH->UQH_ASSGN
							EndIf

							Padr(cFornecUQH, TamSX3("A2_COD")[1]) */

							cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQH, "A2_CGC")

							Aadd( aItem, {'CT2_CLVLCR'	, cClVl		, NIL } )
						EndIf
					Else
						Aadd( aItem, {'CT2_DEBITO'	, cDebito		, NIL } )
						Aadd( aItem, {'CT2_CCD'		, cCusDeb		, NIL } )

						If fClVlObrig(cDebito)
						/*	cFornecUQH := UQH->UQH_TRANSP

							If Empty(cFornecUQH)
								cFornecUQH := UQH->UQH_ASSGN
							EndIf

							Padr(cFornecUQH, TamSX3("A2_COD")[1]) */

							cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQH, "A2_CGC")

							Aadd( aItem, {'CT2_CLVLDB'	, cClVl		, NIL } )
						EndIf
					EndIf

					Aadd( aItem, {'CT2_VALOR'	, nValor			, NIL } )
					Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
					Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
					Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

					aItem := FWVetByDic(aItem, "CT2")

					// Adiciona o item ao array principal de itens
					Aadd( aItens, aItem )

					UQH->(DbSkip())
				EndDo

				If Empty(a545WrkAre)
					a545WrkAre := fGetWorkArea()
					n545WrkAre := Len(a545WrkAre)
				EndIf

				BEGIN TRANSACTION
					//-- Altera para o módulo de Contabilidade
					StaticCall(PRT0528, fAltModulo, "CTB", 34)

					// Integra os movimentos contábeis
					MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 3 ) //Grava sempre um único item/linha

					If lMsErroAuto
						// Disarma a transação
						DisarmTransaction()

						// Prepara o log de erro para ser gravado
						nErro++
						lRet 		:= .F.
						cStatus		:= "E"
						cMsgDet		:= fValExecAut()
						cMensagem	:= CAT545025 //"Erro ao executar programa CTBA102 de gravação de lançamentos contábeis via MSExecAuto."

						Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})
					Else
						nOk++

						// Grava as informações necessárias na tabela de muro
						fGrvProv(cIdImp, aCabecalho, aItens)
					EndIf
				END TRANSACTION

				fRestWorkArea()
			Else
				nErro++
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQH)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCancelPrv
Rotina de integração de cancelamento de arquivos de provisão.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImport, carácter, código identificador da importação da provisão.
@version 1.01
@type Static function
/*/
Static Function fCancelPrv(cReferencia, lEstorno, cVerRep, cIdImport)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())
	Local aAreaUQH		:= UQH->(GetArea())

	Local aCabecalho	:= {}
	Local aItem			:= {}
	Local aItens		:= {}

	Local cIdImp		:= ""
	Local cIdInc		:= ""
	Local cMoeda		:= ""
	//Local cRefInc		:= ""
	Local cTipoTrans	:= ""

	Local lRet			:= .T.

	//Variavel de Controle do MsExecAuto
	Private lMsErroAuto := .F.

	//Variavel de Controle do GetAutoGRLog
	Private lAutoErrNoFile := .T.

	//Se veio da rotina de estorno as variáveis abaixo não foram inicializadas
	If lEstorno
		cTipoTrans := Space(TamSX3("UQG_TPTRAN")[1])

		nOK		:= 0
		nErro	:= 0
	Else
		cTipoTrans := "C"
	EndIf

	// Posiciona no cabeçalho do registro
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))		// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

	// Posiciona no registro de cancelamento
	If UQG->(DbSeek(xFilial("UQG") + cReferencia + cTipoTrans + cVerRep))
		If fVerPrvInc(UQG->UQG_REF, @cIdInc)
			If UQG->(DbSeek(xFilial("UQG") + cReferencia + " " + cVerRep))
				// Abre a tabela de itens de provisão
				DbSelectArea("UQH")
				UQH->(DbSetOrder(3))	// UQH_FILIAL + UQH_REF + UQH_ITEM

				// Verifica se o arquivo está integrado
				If UQG->UQG_STATUS == "P"
					cIdImp := cIdInc

					// Se encontrar itens para este arquivo
					If UQH->(DbSeek(xFilial("UQH") + UQG->UQG_REF))
						// Define as variáveis principais
						dData		:= UQG->UQG_DTDOC
						cDoc		:= UQH->UQH_DOC
						cLote		:= UQH->UQH_LOTE
						cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)
						cSubLote	:= UQH->UQH_SBLOTE

						// Monta o Array de cabeçalho
						Aadd( aCabecalho, { 'DDATALANC'	, dData		, NIL } )
						Aadd( aCabecalho, { 'CLOTE'	  	, cLote		, NIL } )
						Aadd( aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL } )
						Aadd( aCabecalho, { 'CDOC'		, cDoc		, NIL } )
						Aadd( aCabecalho, { 'CPADRAO'	, ""		, NIL } )
						Aadd( aCabecalho, { 'NTOTINF'	, 0			, NIL } )
						Aadd( aCabecalho, { 'NTOTINFLOT', 0			, NIL } )

						// Enquanto houver itens de provisão
						While !UQH->(Eof()) .And. UQH->UQH_IDIMP == cIdImp
							// Reinicia o array de item
							aItem := {}

							// Define as variáveis dos itens
							cCredito	:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", AllTrim(UQH->UQH_CONTAB), "" )
							cDebito		:= IIf( !(AllTrim(UQH->UQH_CHAVE) $ ".39.50."), AllTrim(UQH->UQH_CONTAB), "" )
							cCusCred	:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", AllTrim(UQH->UQH_CCUSTO), "" )
							cCusDeb		:= IIf( !(AllTrim(UQH->UQH_CHAVE) $ ".39.50."), AllTrim(UQH->UQH_CCUSTO), "" )
							cLinha		:= UQH->UQH_LINHA
							cHist		:= UQH->UQH_ITMTEX
							nDC 		:= IIf( AllTrim(UQH->UQH_CHAVE) $ ".39.50.", 2, 1 )
							nValor		:= UQH->UQH_TOTAL

							// Monta array do item
							Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
							Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
							Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
							Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
							Aadd( aItem, {'CT2_CREDIT'	, cCredito			, NIL } )
							Aadd( aItem, {'CT2_DEBITO'	, cDebito			, NIL } )
							Aadd( aItem, {'CT2_VALOR'	, nValor			, NIL } )
							Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
							Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
							Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )
							Aadd( aItem, {'CT2_CCD'		, cCusDeb			, NIL } )
							Aadd( aItem, {'CT2_CCC'		, cCusCred			, NIL } )

							// Adiciona o item ao array principal de itens
							Aadd( aItens, aItem )

							UQH->(DbSkip())
						EndDo

						BEGIN TRANSACTION
							//-- Altera para o módulo de Contabilidade
							StaticCall(PRT0528, fAltModulo, "CTB", 34)

							// Integra os movimentos contábeis
							MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 5 ) // Exclusão dos lançamentos contábeis.
							If lMsErroAuto
								// Disarma a transação
								DisarmTransaction()

								// Prepara o log para ser gravado
								nErro++
								lRet 		:= .F.
								cStatus		:= "E"
								cMsgDet		:= fValExecAut()
								cMensagem	:= CAT545026 //"Erro ao executar programa CTBA102 de exclusão de lançamentos contábeis via MSExecAuto. Contate o administrador."

								Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})
							Else
								nOk++

								// Grava as informações necessárias na tabela de muro
								If !lEstorno
									fGrvCancel(UQG->UQG_REF, lRet, UQG->UQG_VERREP)
								EndIf
							EndIf
						END TRANSACTION
					EndIf
				Else
					// Grava as informações de cancelamento na tabela de muro
					If !lEstorno
						fGrvCancel(UQG->UQG_REF, lRet, UQG->UQG_VERREP)
					EndIf
				EndIf
			EndIf

			DbSelectArea("UQG")
			UQG->(DbSetOrder(1)) // UQG_FILIAL + UQG_IDIMP
			//Posiciono novamente no registro de cancelamento
			If UQG->(DbSeek(xFilial("UQG") + cIdImport))
				If !lRet
					Reclock( "UQG", .F.)
						UQG->UQG_STATUS := "E"
					MsUnlock()
				EndIf
			EndIf
		Else

			nErro++
			lRet		:= .F.
			cIdImp 		:= UQG->UQG_IDIMP
			cStatus		:= "E"
			cMensagem	:= CAT545093//"Arquivo de inclusão não encontrado ou já cancelado."

			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})

			DbSelectArea("UQG")
			UQG->(DbSetOrder(1)) // UQG_FILIAL + UQG_IDIMP
			//Posiciono novamente no registro de cancelamento
			If UQG->(DbSeek(xFilial("UQG") + cIdImport))
				If !lRet
					Reclock( "UQG", .F.)
						UQG->UQG_STATUS := "E"
					MsUnlock()
				EndIf
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQH)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fGrvCancel
Realiza a atualização do status dos arquivos de inclusão e cancelamento.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@param cReferencia, caracter, código de referência do arquivo cancelado.
@param lOk, lógico, informa se o arquivo foi processado com sucesso ou não.
@param cVerRep, caracter, Versão de reprocessamento.
@type Static function
/*/
Static Function fGrvCancel(cReferencia, lOk, cVerRep)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	Local cMensagem	:= ""
	Local cStatus	:= ""
	Local cIdImp	:= ""

	//Local nLinha	:= 0

	// Posiciona no registro cancelado.
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

	// Se o cancelamento foi processado com sucesso.
	If lOk
		// Atualiza o status do arquivo de inclusão.
		If UQG->(DbSeek(xFilial("UQG") + cReferencia + " " + cVerRep))
			Reclock("UQG", .F.)
				UQG->UQG_STATUS := "C"
			UQG->(MsUnlock())
		EndIf

		// Reposiciona no top da tabela
		UQG->(DbGoTop())

		// Atualiza o status do arquivo de cancelamento.
		If UQG->(DbSeek(xFilial("UQG") + cReferencia + "C" + cVerRep))
			cIdImp := UQG->UQG_IDIMP

			Reclock("UQG", .F.)
				UQG->UQG_STATUS := "P"
			UQG->(MsUnlock())
		EndIf

		// Define as informações do log e grava
		cStatus		:= "I"
		cMensagem	:= CAT545027 + AllTrim(cReferencia) + CAT545028	//"Arquivo " # " cancelado com sucesso."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	Else
		// Posiciona no arquivo processado
		If UQG->(DbSeek(xFilial("UQG") + cReferencia + "C" + cVerRep))
			cIdImp := UQG->UQG_IDIMP

			Reclock("UQG", .F.)
				UQG->UQG_STATUS := "E"
			UQG->(MsUnlock())
		EndIf

		// Define as informações do log e grava
		cStatus		:= "E"
		cMensagem	:= CAT545029 + cReferencia	//"Erro no cancelamento do arquivo "

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	RestArea(aArea)
	RestArea(aAreaUQG)

Return

/*/{Protheus.doc} fVldProv
Rotina de validação para integração dos arquivos.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImp, carácter, código identificador da importação do arquivo.
@version 1.01
@type Static function
/*/
Static Function fVldProv(cIdImp)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	Local lRet		:= .T.

	// Posiciona no registro que está sendo integrado
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	If UQG->(DbSeek(xFilial("UQG") + cIdImp))
		// Valida o cabeçalho do arquivo CTRB
		If !fVldCabec(UQG->UQG_IDIMP)
			lRet := .F.
		EndIf

		// Valida os itens de provisão do arquivo CTRB
		If !fVldItmPrv(UQG->UQG_IDIMP)
			lRet := .F.
		EndIf

		If !lRet
			Reclock( "UQG", .F.)
				UQG->UQG_STATUS := "E"
			MsUnlock()
		EndIf
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldRend
Rotina de validação para integração dos arquivos.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImp, carácter, código identificador da importação do arquivo.
@version 1.01
@type Static function
/*/
Static Function fVldRend(cIdImp)

	Local aArea		:= GetArea()
	Local lRet		:= .T.

	// Posiciona no arquivo que está sendo integrado
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	If UQG->(DbSeek(xFilial("UQG") + cIdImp))
		// Valida o cabeçalho do arquivo CTRB
		If !fVldCabec(UQG->UQG_IDIMP)
			lRet := .F.
		EndIf

		// Valida os itens de provisão do arquivo CTRB
		If !fVldItmRnd(UQG->UQG_IDIMP)
			lRet := .F.
		EndIf

		If !lRet
			Reclock( "UQG", .F.)
				UQG->UQG_STATUS := "E"
			MsUnlock()
		EndIf
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVerPrvInc
Verifica se o arquivo selecionado de rendição para cancelamento possui um arquivo de inclusão integrado ou disponível para integração.
@author Paulo Carvalho
@since 13/02/2019
@version 1.0
@return lRet, lógico, .T. se o arquivo é válido e .F. se não.
@param cIdImp, characters, código identificador da importação do arquivo selecionado.
@type Static function
/*/
Static Function fVerPrvInc(cReferencia, cIdInc)

	Local aArea		:= GetArea()

	Local cAliasQry	:= GetNextAlias()
	Local cQuery	:= ""

	Local lRet		:= .F.

	// Cria a query para procurar arquivos de inclusão integrados ou prontos para integração
	cQuery 	+= "SELECT	UQG.UQG_FILIAL, UQG.UQG_IDIMP, UQG.UQG_REF, UQG.UQG_TPTRAN, UQG.UQG_STATUS"	+ CRLF
	cQuery 	+= "FROM	" + RetSqlName("UQG") 	+ " AS UQG "									+ CRLF
	cQuery 	+= "WHERE	UQG.UQG_FILIAL = '" 		+ FWxFilial("UQG") 	+ "' "						+ CRLF
	cQuery 	+= "AND		UQG.UQG_REF = '" 		+ cReferencia 		+ "' "						+ CRLF
	cQuery 	+= "AND		UQG.UQG_TPTRAN = ' ' "													+ CRLF
	cQuery 	+= "AND		UQG.UQG_STATUS IN ('P', 'I', 'E') "										+ CRLF
	cQuery 	+= "AND		UQG.D_E_L_E_T_ <> '*' "													+ CRLF

	// Executa a query e cria um alias temporário
	MPSysOpenQuery(cQuery, cAliasQry)

	// Se houver arquivo de inclusão
	If !(cAliasQry)->(Eof())
		lRet	:= .T.
		cIdInc 	:= (cAliasQry)->UQG_IDIMP
	EndIf

	// Fecha o alias temporário
	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldRndInt
Valida se o arquivo a ser cancelado possui ou não uma rendição integrada no Protheus.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@return lRet, verdadeiro se não possui uma rendição integrada e false se possui.
@param cReferencia, characters, descricao
@type Static function
/*/
Static Function fVldRndInt(cReferencia, cVerRep)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	Local cMensagem	:= ""
	Local cRefRend	:= ""
	Local cStatus	:= ""
	Local cIdImp	:= ""

	Local lRet		:= .T.

	//Local nLinha	:= 0

	// Posiciona a tabela no registro de rendição
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

	// Define o arquivo de rendição equivalente.
	cRefRend	:= (Left(AllTrim(cReferencia), 10) + "RD")

	If UQG->(DbSeek(xFilial("UQG") + cRefRend + " " + cVerRep))
		// Verifica o Status
		If UQG->UQG_STATUS == "P"
			nErro++
			lRet 		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545030 + AllTrim(cRefRend) + CAT545031 // "Este arquivo possui a rendição ", " integrada no Protheus e não pode ser cancelado."
			cIdImp 		:= UQG->UQG_IDIMP

			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldCabec
Rotina de validação do cabeçalho dos arquivos CTRB.
@author Paulo Carvalho
@since 16/01/2019
@param aArquivo, array, array contendo os dados de cabeçalho do arquivo de provisão a ser validado.
@version 1.01
@type Static function
/*/
Static Function fVldCabec(cIdImp)

	//Local aAreaUQG	:= UQG->(GetArea())
	Local lRet		:= .T.

	// Seleciona a tabela de cabeçalho
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	// Posiciona no item selecionado para integração
	If UQG->( DbSeek( xFilial("UQG") + cIdImp ) )
		// Se for um arquivo de cancelamento
		If UQG->UQG_TPTRAN == "C"
			// Valida a existência do arquivo de inclusão
			If !fVldInc(UQG->UQG_REF, UQG->UQG_IDIMP)
				lRet := .F.
			EndIf
		EndIf

		// Se for arquivo de rendição.
		If UQG->UQG_TIPO == "RD" .Or. AllTrim(UQG->UQG_TIPO) == "A"
			// Valida se o arquivo possui um provisão não cancelada
			If !fVArqPrv(UQG->UQG_REF, UQG->UQG_IDIMP)
				lRet := .F.
			// Se possuir o equivalente de provisão
			Else
				// Verifica se o mesmo não foi integrado
				If !fVldIntPrv(UQG->UQG_REF, UQG->UQG_IDIMP)
					lRet := .F.
				EndIf
			EndIf
		EndIf

		// Valida a data de movimentação contábil
		If !fVldDtCont(UQG->UQG_DTDOC, UQG->UQG_REF, UQG->UQG_IDIMP)
			lRet := .F.
		EndIf

		// Valida se a moeda utilizada na movimentação
		If !fVldMoeda(UQG->UQG_MOEDA, UQG->UQG_DTDOC, UQG->UQG_REF, UQG->UQG_IDIMP)
			lRet := .F.
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} fVldInc
Valida se o arquivo de cancelamento possui um de inclusão integrado.
@author Paulo Carvalho
@since 21/01/2019
@param cDocumento, carácter, número do documento que está sendo importado.
@return lRet, lógico, .T. se existe o equivalente de inclusão e .F. se não existe.
@version 1.01
@type Static function
/*/
Static Function fVldInc(cDocumento, cIdImp)

	Local aAreaUQG		:= UQG->(GetArea())
	Local cDocProv		:= StrTran(cDocumento, "RD", "PR") // Left(Alltrim(cDocumento), 10) + "PR"

	Local lRet			:= .F.

	DbSelectArea("UQG")
	DbSetOrder(2)		// UQG_FILIAL + UQG_REF + UQG_TPTRAN

	// Verifica se a provisão está integrada.
	If !UQG->(DbSeek(xFilial("UQG") + cDocProv + " "))
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545032 + cDocumento + CAT545033 // "O arquivo ", " não possui um arquivo de inclusão importado."


		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	Else
		If UQG->UQG_STATUS <> "P"
			lRet		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545034 + cDocumento + CAT545035 // "A inclusão  do arquivo ", " não está integrada no Protheus."


			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aAreaUQG)

Return lRet

/*/{Protheus.doc} fVArqPrv
Valida se um arquivo de rendição possui um equivalente de provisão.
@author Paulo Carvalho
@since 21/01/2019
@param cDocumento, carácter, número do documento que está sendo importado.
@return lRet, lógico, .T. se existe o equivalente de provisão e .F. se não existe.
@version 1.01
@type Static function
/*/
Static Function fVArqPrv(cDocumento, cIdImp)

	Local aAreaUQG		:= UQG->(GetArea())
	Local cDocProv		:= If(UQG->UQG_TIPO == "RD", StrTran(cDocumento, "RD", "PR"), StrTran(cDocumento, "A ", "PR")) // Left(Alltrim(cDocumento), 10) + "PR"

	Local lRet			:= .T.
	// Local nLinha		:= 0

	DbSelectArea("UQG")
	DbSetOrder(2)		// UQG_FILIAL + UQG_REF + UQG_TPTRAN

	// Verifica se o arquivo não possui o equivaliente de provisão
	If !UQG->(DbSeek(xFilial("UQG") + cDocProv + " "))
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545032 + cDocumento + CAT545036 // "O arquivo ", " de rendição não possui um arquivo equivalente de provisão importado."


		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	Else
		// Verifica se possui alguma provisão integrada
		If !fVProvInt(cDocProv, UQG->UQG_TPTRAN)
			// Verifica se a provisão foi cancelada.
			If UQG->UQG_STATUS == "C"
				lRet		:= .F.
				cStatus		:= "E"
				cMensagem	:= CAT545037 + cDocumento + CAT545038 // "A provisão do arquivo ", " está cancelada. Não é possível incluir a rendição."


				Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQG)

Return lRet

/*/{Protheus.doc} fVProvInt
Verifica se o arquivo a ser integrado possui uma provisão integrada no Protheus ou pronta para importação.
@author Paulo Carvalho
@since 13/02/2019
@param cDocumento, carácter, código de referência do documento que está sendo importado.
@return lRet, lógico, .T. se existe o equivalente de provisão e .F. se não existe.
@version 1.01
@type Static function
/*/
Static Function fVProvInt(cDocumento, cTpTrans)

	Local aArea		:= GetArea()

	Local cAliasQry	:= GetNextAlias()
	Local cQuery	:= ""

	Local lRet		:= .F.

	// Cria a query de pesquisa dos documentos de provisão para o arquivo integrado
	cQuery	+= "SELECT 	UQG.UQG_FILIAL, UQG.UQG_IDIMP, UQG.UQG_REF, UQG.UQG_TPTRAN, UQG.UQG_STATUS "	+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQG") 	+ " AS UQG "										+ CRLF
	cQuery	+= "WHERE	UQG.UQG_FILIAL = '" 		+ xFilial("UQG") 	+ "' "							+ CRLF
	cQuery	+= "AND		UQG.UQG_REF = '" 		+ cDocumento 		+ "' "							+ CRLF
	cQuery	+= "AND		UQG.UQG_TPTRAN = '"		+ cTpTrans 			+ "' "							+ CRLF
	cQuery	+= "AND		UQG.D_E_L_E_T_ <> '*' "														+ CRLF

	// Executa a query
	MPSysOpenQuery(cQuery, cAliasQry)

	// Varre todos os registros encontrados
	While !(cAliasQry)->(Eof())
		// Verifica se o arquivo não está cancelado
		If (cAliasQry)->UQG_STATUS $ "PI"
			lRet := .T.
		EndIf

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldIntPrv
Valida se o arquivo de provisão não foi integrado.
@author Paulo Carvalho
@since 21/01/2019
@param cDocumento, carácter, número do documento que está sendo importado.
@return lRet, lógico, .T. se existe o equivalente de provisão e .F. se não existe.
@version 1.01
@type Static function
/*/
Static Function fVldIntPrv(cDocumento, cIdImp)

	Local aAreaUQG		:= UQG->(GetArea())
	Local cDocProv		:= Left(Alltrim(cDocumento), 10) + "PR"

	Local lRet			:= .T.
	// Local nLinha		:= 0

	DbSelectArea("UQG")
	DbSetOrder(2)		// UQG_FILIAL + UQG_REF + UQG_TPTRAN

	// Verifica se a provisão está integrada.
	If UQG->(DbSeek(xFilial("UQG") + cDocProv + " "))
		If UQG->UQG_STATUS <> "P" .And. UQG->UQG_STATUS <> "C"
			lRet		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545037 + cDocProv + CAT545039 // "A provisão do arquivo ", " não está integrada no Protheus."


			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aAreaUQG)

Return lRet

/*/{Protheus.doc} fVldDtCont
Valida se a data de lançamento contábil do arquivo está contemplada por calendário contábil ativo.
@author Paulo Carvalho
@since 16/01/2019
@param dDtMovi, carácter, data da movimentação em formato carácter.
@param cDocumento, carácter, número do documento CTRB.
@return lRet, lógico, .T. se existe calendário contábil vigente e .F. se não existe.
@version 1.01
@type Static function
/*/
Static Function fVldDtCont(dDtMovi, cDocumento, cIdImp)

	Local aArea			:= GetArea()
	Local aTam			:= {}
	Local aTCSetField	:= {}

	Local cAliasQry		:= GetNextAlias()
	Local cMensagem		:= ""
	Local cQuery		:= ""
	Local cStatus		:= ""

	Local sDtMovi		:= DtoS(dDtMovi)

	Local lRet			:= .T.

	// Local nLinha		:= 0

	cDocumento := AllTrim(cDocumento)

	// Define os campos que passarão pela função TCSetField
	aTam := TamSX3("CTG_DTINI") ; Aadd( aTCSetField, { "CTG_DTINI"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("CTG_DTFIM")	; Aadd( aTCSetField, { "CTG_DTFIM"	, aTam[3], aTam[1], aTam[2]	} )

	// Define a query de pesquisa do calendário contábil
	cQuery	+= "SELECT	CTG_FILIAL, CTG_CALEND, CTG_DTINI, CTG_DTFIM, CTG_STATUS"	+ CRLF
	cQuery	+= "FROM	" + RetSqlName("CTG") + " "									+ CRLF
	cQuery	+= "WHERE	CTG_FILIAL = '"	+ xFilial("CTG")	+ "' "					+ CRLF
	cQuery	+= "AND		CTG_DTINI <= '" + sDtMovi 			+ "' "					+ CRLF
	cQuery	+= "AND		CTG_DTFIM >= '" + sDtMovi 			+ "' "					+ CRLF
	cQuery	+= "AND		CTG_STATUS = '1' "											+ CRLF
	cQuery	+= "AND		D_E_L_E_T_ <> '*' "											+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	// Se não foram encontrados calendários contábeis
	If (cAliasQry)->(Eof())
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545040 + cDocumento +  "." // "Não existe calendário contábil que contemple o lançamento do arquivo "

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldMoeda
Valida se a moeda utilizada não está bloqueada e se está amarrada a um calendário contábil vigente.
@author Paulo Carvalho
@since 16/01/2019
@param cMoeda, carácter, dmoeda utilizada na transação.
@param cDtMovi, carácter, data da movimentação em formato carácter.
@param cDocumento, carácter, número do documento CTRB.
@return lRet, lógico, .T. se a moeda é válida e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldMoeda(cMoeda, dDtMovi, cDocumento, cIdImp)

	Local aArea		:= GetArea()
	Local aMoeda	:= 	{ 	{ "BRL", "01" },;
							{ "ARG", "02" },;
							{ "USD", "03" }		}

	Local cAuxMoeda	:= ""
	Local cAliasQry	:= GetNextAlias()
	Local cMensagem	:= ""
	Local cQuery	:= ""
	Local cStatus	:= ""

	Local lRet		:= .T.

	Local nI
	// Local nLinha	:= 0

	Local sDtMovi	:= DtoS(dDtMovi)

	cDocumento := AllTrim(cDocumento)

	// Define a moeda
	For nI := 1 To Len(aMoeda)
		If aScan(aMoeda[nI], cMoeda) > 0
			cAuxMoeda := aMoeda[nI][2]
		EndIf
	Next

	// Seleciona a tabela de moedas contábeis
	DbSelectArea("CTO")
	CTO->(DbSetOrder(1))	// CTO_FILIAL + CTO_MOEDA

	// Verifica a existencia da moeda
	If CTO->( DbSeek( xFilial("CTO") + cAuxMoeda ) ) .And. CTO->CTO_BLOQ == "1"
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545041 + cDocumento + CAT545042 // "A moeda contábil utilizada no arquivo ", " está bloqueada."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	// Fecha tabela de moedas
	CTO->(DbCloseArea())

	// Verifica se a moeda está cadastrada para um calendário vigente
	cQuery	+= "SELECT	CTE.CTE_MOEDA, CTE.CTE_CALEND "						+ CRLF
	cQuery	+= "FROM	" 		+ RetSqlName("CTE") 	+ " AS CTE "		+ CRLF
	cQuery	+= "LEFT JOIN	" 	+ RetSqlName("CTG") 	+ " AS CTG  "		+ CRLF
	cQuery	+= "	ON	CTG.CTG_FILIAL = '" + xFilial("CTG") 	+ "' AND "	+ CRLF
	cQuery	+= "		CTG.CTG_CALEND = CTE.CTE_CALEND AND "				+ CRLF
	cQuery	+= "		CTG.CTG_DTINI <= '" + sDtMovi 			+ "' AND "	+ CRLF
	cQuery	+= "		CTG.CTG_DTFIM >= '" + sDtMovi 			+ "' AND "	+ CRLF
	cQuery	+= "		CTG.D_E_L_E_T_ <> '*' "								+ CRLF
	cQuery	+= "WHERE	CTE.CTE_FILIAL = '" + xFilial("CTE") 	+ "' "		+ CRLF
	cQuery	+= "AND		CTE.CTE_MOEDA = '" 	+ cAuxMoeda			+ "' "		+ CRLF
	cQuery	+= "AND		CTE.D_E_L_E_T_ <> '*' "								+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	// Se não encontrar nenhuma amarração entre calendários vigente e a moeda
	If (cAliasQry)->(Eof())
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545043 + cMoeda + CAT545044 // "Não existe nenhuma amarração entre a moeda ", " e um calendário contábil vigente."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	(cAliasQry)->(DbCloseArea())
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldItmPrv
Rotina de validação dos itens de provisão de um arquivo CTRB.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImp, carácter, Id de importação do arquivo que está sendo integrado.
@return lRet, lógico, .T. se os itens são válidos para integração e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldItmPrv(cIdImp)

	Local aAreaUQH	:= UQH->(GetArea())
	Local aAreaSA2	:= SA2->(GetArea())

	Local cForneUQH	:= ""

	Local lRet		:= .T.

	// Seleciona a tabela de itens de provisão
	DbSelectArea("UQH")
	UQH->(DbSetOrder(1))	// UQH_FILIAL + UQH_IDIMP + UQH_ITEM

	// Posiciona nos itens do arquivo que está sendo integrado
	If UQH->( DbSeek( xFilial("UQH") + cIdImp ) )

		// Enquanto houver itens de provisão para o arquivo
		While !UQH->(Eof()) .And. UQH->UQH_IDIMP == cIdImp

			cForneUQH := Padr( UQH->UQH_ASSGN, TAMSX3("A2_COD")[1] )

			// Valida o fornecedor
			If !fVldFornec( cForneUQH, UQH->UQH_REF, UQH->UQH_ITEM, UQH->UQH_IDIMP)
				lRet := .F.
			EndIF

			// Valida a conta contábil
			If !fVldContab(UQH->UQH_CONTAB, UQH->UQH_REF, UQH->UQH_ITEM, UQH->UQH_IDIMP)
				lRet := .F.
			EndIf

			// Valida o centro de custo
			If !fVldCusto(UQH->UQH_CCUSTO, UQH->UQH_REF, UQH->UQH_ITEM, UQH->UQH_IDIMP)
				lRet := .F.
			EndIF

			UQH->(DbSkip())
		EndDo
	EndIf

	RestArea(aAreaSA2)
	RestArea(aAreaUQH)

Return lRet

/*/{Protheus.doc} fVldItmRnd
Rotina de validação dos itens de rendição de um arquivo CTRB.
@author Paulo Carvalho
@since 16/01/2019
@param cIdImp, carácter, Id de importação do arquivo que está sendo integrado.
@return lRet, lógico, .T. se os itens são válidos para integração e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldItmRnd(cIdImp)

	//Local aAreaUQI	:= UQI->(GetArea())
	Local aContab	:= { "39", "40", "50", "60" }
	Local aFinanc	:= { "21", "31" }

	Local lRet		:= .T.

	// Seleciona a tabela de itens de rendição
	DbSelectArea("UQI")
	UQI->(DbSetOrder(1))	// UQI_FILIAL + UQI_IDIMP + UQI_ITEM

	// Posiciona nos itens do arquivo que está sendo integrado
	If UQI->( DbSeek( xFilial("UQI") + cIdImp ) )
		// Enquanto houver itens de rendição para o arquivo
		While !UQI->(Eof()) .And. UQI->UQI_IDIMP == cIdImp
			// Verifica se é lançamento contábil ou financeiro
			If aScan( aContab, UQI->UQI_CHAVE ) > 0
				// Valida a conta contábil
				If !fVldContab(UQI->UQI_CONTAB, UQI->UQI_REF, UQI->UQI_ITEM, UQI->UQI_IDIMP)
					lRet := .F.
				EndIf

				// Valida o centro de custo
				If !fVldCusto(UQI->UQI_CCUSTO, UQI->UQI_REF, UQI->UQI_ITEM, UQI->UQI_IDIMP)
					lRet := .F.
				EndIF
			ElseIf aScan( aFinanc, UQI->UQI_CHAVE ) > 0
				// Valida o fornecedor
				If !fVldFornec(UQI->UQI_TRANSP, UQI->UQI_REF, UQI->UQI_ITEM, UQI->UQI_IDIMP)
					lRet := .F.
				EndIF

				// Valida se já existe um título com esse número
				If !fVldTitulo(UQI->UQI_REF, UQI->UQI_ITEM, UQI->UQI_IDIMP)
					lRet := .F.
				EndIf

			EndIf

			UQI->(DbSkip())
		EndDo
	EndIf

Return lRet

/*/{Protheus.doc} fVldFornec
Valida se o fornecedor não está bloqueado para lançamentos.
@author Paulo Carvalho
@since 16/01/2019
@param cFornecedor, carácter, fornecedor utilizado na transação.
@param cDocumento, carácter, número do documento CTRB.
@param cLinha, carácter, número do item do arquivo CTRB para ser transformado em linha para o log de registro.
@return lRet, lógico, .T. se a moeda é válida e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldFornec(cFornecedor, cDocumento, cLinha, cIdImp)

	Local aArea		:= GetArea()

	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local lRet		:= .T.

	// Retira os espaços em branco
	cFornecedor	:= AllTrim(cFornecedor)
	cDocumento	:= AllTrim(cDocumento)

	// Seleciona a tabela de fornecedores
	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))	// A2_FILIAL + A2_COD + A2_LOJA

	// Posiciona no fornecedor do item de rendição
	If SA2->( DbSeek( xFilial("SA2") + AllTrim(cFornecedor) ) )
		// Verifica se está bloqueado
		If SA2->A2_MSBLQL == "1"
			lRet		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545045 + cFornecedor + CAT545046 // "O fornecedor ", " está bloqueado no sistema."

			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	Else
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545045 + cFornecedor + CAT545092 // "O fornecedor ", " não está cadastrado no sistema."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})

	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldContab
Valida se a conta contábil não está bloqueada para lançamentos.
@author Paulo Carvalho
@since 16/01/2019
@param cContab, carácter, conta contábil utilizada na transação.
@param cDocumento, carácter, número do documento CTRB.
@param cLinha, carácter, número do item do arquivo CTRB para ser transformado em linha para o log de registro.
@return lRet, lógico, .T. se a moeda é válida e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldContab(cContab, cDocumento, cLinha, cIdImp)

	Local aArea		:= GetArea()

	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local lRet		:= .T.

	// Local nLinha	:= Val(cLinha)

	// Retira os espaços em branco
	cContab		:= AllTrim(cContab)
	cDocumento	:= AllTrim(cDocumento)

	// Seleciona a tabela de contas contábeis
	DbSelectArea("CT1")
	CT1->(DbSetOrder(1))	// CT1_FILIAL + CT1_CONTA

	// Posiciona na conta contábil do item
	If CT1->( DbSeek( xFilial("CT1") + cContab ) )
		// Valida se a conta está bloqueada
		If CT1->CT1_BLOQ == "1"
			lRet		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545047 + cContab + CAT545048 // "A conta contábil ", " está bloqueada no sistema."

			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldCusto
Valida se a centro de custo não está bloqueado para lançamentos.
@author Paulo Carvalho
@since 16/01/2019
@param cCusto, carácter, centro de custo utilizado na transação.
@param cDocumento, carácter, número do documento CTRB.
@param cLinha, carácter, número do item do arquivo CTRB para ser transformado em linha para o log de registro.
@return lRet, lógico, .T. se a moeda é válida e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldCusto(cCusto, cDocumento, cLinha, cIdImp)

	Local aArea		:= GetArea()

	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local lRet		:= .T.

	// Local nLinha	:= Val(cLinha)

	// Retira os espaços em branco
	cCusto		:= AllTrim(cCusto)
	cDocumento	:= AllTrim(cDocumento)

	// Seleciona a tabela de centro de custo
	DbSelectArea("CTT")
	CTT->(DbSetOrder(1))	// CTT_FILIAL + CTT_CUSTO

	// Posiciona na conta contábil do item
	If CTT->( DbSeek( xFilial("CTT") + cCusto ) )
		// Valida se a conta está bloqueada
		If CTT->CTT_BLOQ == "1"
			lRet		:= .F.
			cStatus		:= "E"
			cMensagem	:= CAT545049 + cCusto + CAT545050 // "O centro custo ", " está bloqueado no sistema."

			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldTitulo
Valida se já existe um título com o mesmo número do que será criado.
@author Paulo Carvalho
@since 16/01/2019
@param cDocumento, carácter, número do documento CTRB.
@param cLinha, carácter, número do item do arquivo CTRB para ser transformado em linha para o log de registro.
@return lRet, lógico, .T. se a moeda é válida e .F. se não.
@version 1.01
@type Static function
/*/
Static Function fVldTitulo(cDocumento, cLinha, cIdImp)

	Local aArea		:= GetArea()

	Local cMensagem	:= ""
	Local cParcela	:= "1"
	Local cPrefixo	:= "001"
	Local cStatus	:= ""
	Local cTitulo	:= ""

	Local lRet		:= .T.

	// Local nLinha	:= Val(cLinha)

	// Retira os espaços em branco
	cDocumento	:= AllTrim(cDocumento)

	// Determina o número do novo título
	cTitulo := SubStr(cDocumento, 5, 6)

	// Seleciona a tabela de fornecedores
	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))	// A2_FILIAL + A2_COD + A2_LOJA

	// Posiciona no fornecedor do item de rendição
	If SE1->( DbSeek( xFilial("SE1") + cPrefixo + cTitulo + cParcela ) )
		lRet		:= .F.
		cStatus		:= "E"
		cMensagem	:= CAT545050 + cTitulo + CAT545051 // "O número ", " já está sendo usado por outro título."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvProv
Rotina para integração dos arquivos CTRB de rendição.
@author Paulo Carvalho
@since 11/01/2019
@return aCabecalho, array, array contendo os dados do cabeçalho enviado para o MSExecAuto.
@return aItens, array, array contendo os dados dos itens enviados para o MSExecAuto.
@version 1.01
@type Static function
/*/
Static Function fGrvProv(cIdImp, aCabecalho, aItens)

	Local aAreaUQH	:= UQH->(GetArea())
	Local aAreaUQG	:= UQG->(GetArea())

	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local nI
	// Local nLinha	:= 0
	Local nPsLinha	:= 0
	Local nPsDoc	:= AScan(aCabecalho, {|x| x[1] == "CDOC"})
	Local nPsLote	:= AScan(aCabecalho, {|x| x[1] == "CLOTE"})
	Local nPsSbLote	:= AScan(aCabecalho, {|x| x[1] == "CSUBLOTE"})

	// Atualiza as informações dos itens de Provisão
	For nI := 1 To Len(aItens)
		If (nPsLinha := AScan(aItens[nI], {|x| x[1] == "CT2_LINHA"})) > 0
			If nPsDoc > 0 .And. nPsLote > 0 .And. nPsSbLote > 0
				// Abre a tabela de itens de provisão
				DbSelectArea("UQH")
				UQH->(DbSetOrder(1)) // UQH_FILIAL + UQH_IDIMP + UQH_ITEM

				// Se existe o item importado
				If UQH->( DbSeek(xFilial("UQH") + cIdImp + aItens[nI][nPsLinha][2] ) )
					// Locka a tabela
					RecLock("UQH", .F.)
						UQH->UQH_LOTE	:= aCabecalho[nPsLote][2]
						UQH->UQH_SBLOTE	:= aCabecalho[nPsSbLote][2]
						UQH->UQH_DOC		:= aCabecalho[nPsDoc][2]
						UQH->UQH_LINHA	:= aItens[nI][nPsLinha][2]
					UQH->(MsUnlock())
				EndIf
			EndIf
		EndIf
	Next

	// Atualiza o status do cabeçalho dos arquivos de provisão.
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	// Se encontrar o arquivo
	If UQG->( DbSeek( xFilial("UQG") + cIdImp ) )
		// Locka a tabela e realiza a alteração do status
		Reclock("UQG", .F.)
			UQG->UQG_STATUS	:= "P"
		UQG->(MsUnlock())

		// Grava o log de registro integrado com sucesso
		cStatus 	:= "I"
		cMensagem	:= CAT545053 + AllTrim(cCTRB) + CAT545054 // "O arquivo CTRB ", " foi integrado com sucesso."

		Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
	EndIf

	RestArea(aAreaUQG)
	RestArea(aAreaUQH)

Return

/*/{Protheus.doc} fIntRend
Rotina para integração dos arquivos CTRB de rendição.
@author Paulo Carvalho
@since 11/01/2019
@return aRendicao, array, array com os arquivos de rendição selecionados para integração.
@version 1.01
@type Static function
/*/
Static Function fIntRend(aRendicao)

	Local aArea			:= GetArea()

	Local cCancelamento	:= "C"
	Local cInclusao		:= " "
	Local cReprocessa	:= "R"

	Local nI
	Local nPsIdImp		:= GdFieldPos("UQG_IDIMP", aHeaderUQG)
	Local nPsRef		:= GdFieldPos("UQG_REF", aHeaderUQG)
	Local nRendicoes	:= Len(aRendicao)

	Private cFilArq		:= ""
	Private cCTRB		:= ""

	ProcRegua(nRendicoes)

	// Integra cada arquivo selecionado pelo usuário.
	For nI := 1 To Len(aRendicao)
		IncProc(CAT545055) //"Integrando rendições e adiantamentos..."

		// Define o arquivo CTRB a ser integrado
		cIdImp 	:= aRendicao[nI][nPsIdImp]
		cCTRB	:= aRendicao[nI][nPsRef]

		// Posiciona no cabeçalho do arquivo atual
		DbSelectArea("UQG")
		UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

		If UQG->(DbSeek(xFilial("UQG") + cIdImp))
			// Define a filial do arquivo
			cFilArq := UQG->UQG_FIL

			// Verifica o tipo de ação a ser realizada
			If UQG->UQG_TPTRAN == cInclusao
				fIncluiRnd(UQG->UQG_IDIMP)
			ElseIf UQG->UQG_TPTRAN == cCancelamento
				fCancelRnd(UQG->UQG_REF, , UQG->UQG_VERREP, cIdImp)
			ElseIf UQG->UQG_TPTRAN == cReprocessa
				fReprocessar(UQG->UQG_REF, UQG->UQG_VERREP, cIdImp)
			EndIf
		EndIf
	Next

	RestArea(aArea)

Return

/*/{Protheus.doc} fIncluiRnd
Rotina para integração dos arquivos CTRB de rendição.
@author Paulo Carvalho
@since 11/01/2019
@return aCabecalho, array, array contendo os dados do cabeçalho enviado para o MSExecAuto.
@return aItens, array, array contendo os dados dos itens enviados para o MSExecAuto.
@version 1.01
@type Static function
/*/
Static Function fIncluiRnd(cIdImp)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())
	Local aAreaUQI		:= UQI->(GetArea())

	Local aCabecalho	:= {}
	Local aItem			:= {}
	Local aItens		:= {}
	Local aTitulo		:= {}
	Local aTitulos		:= {}
	Local aInfoTitulo	:= {}
	Local aContab		:= {"39", "40", "50", "60"}
	Local aFinanc		:= {"21", "31"}
	Local aFornec		:= {}

	Local cAdiantamento	:= "A"
	Local cCredito		:= ""
	Local dData			:= ""
	Local cDebito		:= ""
	Local cDoc			:= ""
	Local cFornecUQI	:= ""
	Local cLojaUQI		:= ""
	Local cPrefixo		:= ""
	Local cNumTitulo	:= ""
	Local cParcela		:= ""

	Local cLinha		:= "0"
	Local cLote			:= ""
	Local cMensagem		:= ""
	Local cMoeda		:= ""
	Local cMsgDet		:= ""
	Local cRendicao		:= "RD"
	Local cStatus		:= ""
	Local cSubLote		:= ""
	Local cNatureza		:= ""
	Local cTipoTitulo	:= ""
	Local cItem			:= ""

	Local dBkpDtBase	:= dDataBase

	Local lRet			:= .T.
	//Local lFrete		:= .T.
	Local lAtunOk		:= .F.

	//Local nI
	Local nJ			:= 0
	Local nDC			:= 1
	Local nPosCred		:= 0
	// Local nLinha		:= 0

	//Variavel de Controle do MsExecAuto
	Private lMsErroAuto := .F.

	//Variavel de Controle do GetAutoGRLog
	Private lAutoErrNoFile := .T.

	// Posiciona no cabeçalho do registro
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	If UQG->( DbSeek(xFilial("UQG") + cIdImp) )
		// Abre a tabela de itens de rendição
		DbSelectArea("UQI")
		UQI->(DbSetOrder(1))	// UQI_FILIAL + UQI_IDIMP + UQI_ITEM

		If UQI->( DbSeek(xFilial("UQI") + cIdImp) )
			// Se o arquivo for válido para integração
			If fVldRend(cIdImp)
				// Define as variáveis principais
				dData		:= UQG->UQG_DTDOC
				cDoc		:= SubStr(AllTrim(UQI->UQI_REF), 5, 6)
				cLote		:= fGLoteUQH(UQI->UQI_REF, UQG->UQG_TIPO) // GetSXENum("CT2", "CT2_LOTE", Nil, 1)
				cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)
				cSubLote	:= If(UQG->UQG_TIPO == cRendicao, cRendicao, cAdiantamento)
				aFornec		:= fGetFornec(cIdImp, cSubLote)
				cFornecUQI	:= aFornec[1]
				cLojaUQI	:= aFornec[2]

				// Monta o Array de cabeçalho
				Aadd( aCabecalho, { 'DDATALANC'	, dData		, NIL } )
				Aadd( aCabecalho, { 'CLOTE'	  	, cLote		, NIL } )
				Aadd( aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL } )
				Aadd( aCabecalho, { 'CDOC'		, cDoc		, NIL } )
				Aadd( aCabecalho, { 'CPADRAO'	, ""		, NIL } )
				Aadd( aCabecalho, { 'NTOTINF'	, 0			, NIL } )
				Aadd( aCabecalho, { 'NTOTINFLOT', 0			, NIL } )

				// Enquanto houver itens de rendição
				While !UQI->(Eof()) .And. UQI->UQI_IDIMP == cIdImp
					// Se for uma movimentação contábil
					If aScan( aContab, UQI->UQI_CHAVE ) > 0
						// Reinicia o array de item
						aItem		:= {}

						// Define as variáveis dos itens
						cCredito	:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", UQI->UQI_CONTAB, "" )
						cDebito		:= IIf( !(AllTrim(UQI->UQI_CHAVE) $ ".39.50."), UQI->UQI_CONTAB, "" )
						cLinha		:= PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
						nDC 		:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", 2, 1 )

						// Monta array do item
						Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
						Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
						Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
						Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada

						If AllTrim(UQI->UQI_CHAVE) $ ".39.50."
							Aadd( aItem, {'CT2_CREDIT'	, cCredito		, NIL } )

							If fClVlObrig(cCredito)
								cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQI + cLojaUQI, "A2_CGC")

								Aadd( aItem, {'CT2_CLVLCR'	, cClVl		, NIL } )
							EndIf
						Else
							Aadd( aItem, {'CT2_DEBITO'	, cDebito		, NIL } )

							If fClVlObrig(cDebito)
								cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQI + cLojaUQI, "A2_CGC")

								Aadd( aItem, {'CT2_CLVLDB'	, cClVl		, NIL } )
							EndIf
						EndIf

						Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
						Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
						Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
						Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

						aItem := FWVetByDic(aItem, "CT2")

						// Adiciona o item ao array de itens
						Aadd( aItens, aItem )

						DbSelectArea("SA2")
						SA2->(DbSetOrder(1)) // A2_FILIAL + A2_COD + A2_LOJA
						If SA2->(DbSeek(xFilial("SA2") + cFornecUQI + cLojaUQI))
							If !Empty(SA2->A2_CONTA)

								aItem := {}
								cLinha := PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
								// Monta contrapartida no array do item
								Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
								Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
								Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )

								nPosCred := aScan(aItens[1], {|x| x[1] == 'CT2_CREDIT'} )
								If nPosCred > 0
									//Adiciono a contrapartida
									Aadd( aItem, {'CT2_DC'		, 1				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
									Aadd( aItem, {'CT2_DEBITO'	, SA2->A2_CONTA	, NIL } )

									If fClVlObrig(SA2->A2_CONTA)
										cClVl := SA2->A2_CGC

										Aadd( aItem, {'CT2_CLVLDB'	, cClVl		, NIL } )
									EndIf
								Else
									//Adiciono a contrapartida
									Aadd( aItem, {'CT2_DC'		, 2				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
									Aadd( aItem, {'CT2_CREDIT'	, SA2->A2_CONTA	, NIL } )

									If fClVlObrig(SA2->A2_CONTA)
										cClVl := SA2->A2_CGC

										Aadd( aItem, {'CT2_CLVLCR'	, cClVl		, NIL } )
									EndIf
								EndIf

								Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
								Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
								Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
								Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

								aItem := FWVetByDic(aItem, "CT2")

								// Adiciona o item ao array de itens
								Aadd( aItens, aItem )
							EndIf
						EndIf

					// Se for um título a pagar
					ElseIf aScan( aFinanc, UQI->UQI_CHAVE ) > 0
						// Reinicia array do titulo
						aTitulo := {}

						// -----------------------------------------------------------------------------------
						// Verifica se o fornecedor é autônomo
						// Só gera o título se o fornecedor não for autônomo
						// Regra incluída em 30/05/2019 por Juliano Fernandes conforme solicitação Marcos
						// -----------------------------------------------------------------------------------
						// Conforme solicitação feita por Marcos Santos em 12/06/2019, por momento a regra
						// comentada acima não será aplicada no programa e por esse motivo, a verificação se
						// o fornecedor é autônomo foi comentada.
						// -----------------------------------------------------------------------------------
						//If !fFornAuton(UQI->UQI_TRANSP, UQI->UQI_LOJA)
							cPrefixo   := PadR( SuperGetMV("PLG_PFXCTR", .F.), TamSX3("E2_PREFIXO")[1] )
							cNumTitulo := PadR( SubStr(AllTrim(cCTRB), 5, 6) , TamSX3("E2_NUM")[1]     )

							aInfoTitulo := fGetInfoTit(UQI->UQI_TRANSP, UQI->UQI_LOJA, UQI->UQI_PRODUT, UQI->UQI_TPFRET, UQG->UQG_TIPO, cPrefixo, cNumTitulo, aTitulos)

							cNatureza	:= aInfoTitulo[1]
							cTipoTitulo	:= aInfoTitulo[2]
							cParcela	:= aInfoTitulo[3]

							// Define os elementos do array
							Aadd( aTitulo, { "E2_PREFIXO"	, cPrefixo						, Nil } )
							Aadd( aTitulo, { "E2_NUM"		, cNumTitulo					, Nil } )
							Aadd( aTitulo, { "E2_TIPO"		, cTipoTitulo					, Nil } )
							Aadd( aTitulo, { "E2_NATUREZ"	, cNatureza						, Nil } )
							Aadd( aTitulo, { "E2_FORNECE"	, AllTrim(UQI->UQI_TRANSP)		, Nil } )
							Aadd( aTitulo, { "E2_EMISSAO"	, UQG->UQG_DTDOC					, Nil } )
							Aadd( aTitulo, { "E2_VENCTO"	, UQI->UQI_VENC					, Nil } )
							Aadd( aTitulo, { "E2_VENCREA"	, DataValida(UQI->UQI_VENC, .T.)	, Nil } )
							Aadd( aTitulo, { "E2_VALOR"		, UQI->UQI_TOTAL					, Nil } )
							Aadd( aTitulo, { "E2_PARCELA"	, cParcela						, Nil } )
							Aadd( aTitulo, { "E2_MOEDA"		, Val(cMoeda)					, Nil } )
							Aadd( aTitulo, { "E2_CCD"		, fGetCCusto(UQI->UQI_IDIMP)		, Nil } )

							If !Empty(UQI->UQI_PRODUT)
								Aadd( aTitulo, { "E2_HIST"		, CAT545091 + UQI->UQI_PRODUT	, Nil } )
							EndIf

						//EndIf
					/*	cFornecUQI := AllTrim(UQI->UQI_TRANSP)
						cLojaUQI := AllTrim(UQI->UQI_LOJA) */

						AAdd(aTitulos, {aTitulo, UQI->UQI_ITEM})
					EndIf

					UQI->(DbSkip())
				EndDo

				If Empty(a545WrkAre)
					a545WrkAre := fGetWorkArea()
					n545WrkAre := Len(a545WrkAre)
				EndIf

				BEGIN TRANSACTION
					//-- Altera para o módulo de Contabilidade
					StaticCall(PRT0528, fAltModulo, "CTB", 34)

					// Integra os movimentos contábeis
					MSExecAuto({|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 3) //Grava sempre um único item/linha
					If lMsErroAuto
						// Disarma a transação
						DisarmTransaction()

						// Prepara o log para ser gravado
						nErro++
						lRet 		:= .F.
						cStatus		:= "E"
						cMsgDet		:= fValExecAut()
						cMensagem	:= CAT545025//"Erro ao executar programa CTBA102 de gravação de lançamentos contábeis via MSExecAuto. Contate o administrador."

						Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})
					Else
						fRestWorkArea()

						// Se houverem títulos a serem integrados
						If !Empty(aTitulos)
							For nJ := 1 To Len(aTitulos)
								aTitulo := AClone(aTitulos[nJ,1])
								cItem := aTitulos[nJ,2]

								// Se houverem títulos a serem integrados
								If !Empty(aTitulo)
									//-- Altera para o módulo Financeiro
									StaticCall(PRT0528, fAltModulo, "FIN", 5)

									dDataBase := UQG->UQG_DTDOC

									// Inclui títulos a pagar
									MSExecAuto({|X,Y,Z| FINA050(X,Y,Z)} , aTitulo, , 3) // 3: Inclusao; 4: Alteração; 5:Exclusão

									dDataBase := dBkpDtBase

									If lMsErroAuto .Or. SE2->(EoF())

										// Disarma a transação
										DisarmTransaction()

										// Prepara o log para ser gravado
										nErro++
										lRet 		:= .F.
										cStatus		:= "E"
										cMsgDet		:= fValExecAut()
										cMensagem	:= CAT545056//"Erro ao executar programa FINA050 de gravação de contas a receber via MSExecAuto. Contate o administrador."

										Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})

										Exit
									Else
										If !lAtunOk // Variavel utilizada para que atualize apenas uma vez a variável nOk
											// Adiciona um registro integrado com sucesso.
											nOk++
											lAtunOk := .T.
										EndIf

										// Grava as informações de movimentação contábil nos itens contábeis
										fGrvRend(cIdImp, aCabecalho, aItens, aTitulo, cItem)
									EndIf
								Else
									// Adiciona um registro integrado com sucesso.
									nOk++

									// Grava as informações de movimentação contábil nos itens contábeis
									fGrvRend(cIdImp, aCabecalho, aItens, aTitulo, cItem)
								EndIf
							Next nJ
						Else
							// Adiciona um registro integrado com sucesso.
							nOk++

							// Grava as informações de movimentação contábil nos itens contábeis
							fGrvRend(cIdImp, aCabecalho, aItens, aTitulo, "")
						EndIf
					EndIf
				END TRANSACTION

				fRestWorkArea()
			Else
				nErro++
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQI)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCancelRnd
Rotina para cancelamento de arquivos de rendição CTRB.
@author Paulo Carvalho
@since 24/01/2019
@param lEstorno, lógico, booleano q indica se foi chamado da rotina de estorno
@return cIdImport, carácter, código identificador do arquivo importado.
@version 1.01
@type Static function
/*/
Static Function fCancelRnd(cReferencia, lEstorno, cVerRep, cIdImport)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())
	Local aAreaUQI		:= UQI->(GetArea())

	Local aCabecalho	:= {}
	Local aContab		:= {"39", "40", "50", "60"}
	Local aFinanc		:= {"21", "31"}
	Local aItem			:= {}
	Local aItens		:= {}
	Local aTitulo		:= {}
	Local aTitulos		:= {}

	Local cFornecUQI	:= ""
	Local cLojaUQI		:= ""
	Local cIdImp		:= ""
	Local cMoeda		:= ""
	//Local cRefInc		:= ""
	Local cSubLote		:= ""

	Local lRet			:= .T.

	Local nJ			:= 0

	//Se veio da rotina de estorno as variáveis abaixo não foram inicializadas
	If lEstorno
		cCTRB	:= cReferencia
		nOK		:= 0
		nErro	:= 0
	EndIf

	//Variavel de Controle do MsExecAuto
	Private lMsErroAuto := .F.

	//Variavel de Controle do GetAutoGRLog
	Private lAutoErrNoFile := .T.

	// Se o arquivo é válido para cancelamento
	If fVldCanRnd(cReferencia, cVerRep)
		// Posiciona no registro de cancelamento
		DbSelectArea("UQG")
		UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

		If UQG->(DbSeek(xFilial("UQG") + cReferencia + " " + cVerRep))
			cIdImp := UQG->UQG_IDIMP

			// Verifica o status do arquivo
			If UQG->UQG_STATUS == "P" // Processado no Protheus
				// Abre a tabela de itens de rendição
				DbSelectArea("UQI")
				UQI->(DbSetOrder(4))	//	UQI_FILIAL + UQI_REF + UQI_CHAVE

				// Posiciona nos itens
				If UQI->(DbSeek(xFilial("UQI") + cCTRB))
					// Enquanto houver detalhes para o registro
					While !UQI->(Eof()) .And. UQI->UQI_REF == cCTRB
						// Se é um arquivo que gera financeiro
						If aScan(aFinanc, UQI->UQI_CHAVE) > 0
							// Reinicia array do titulo
							aTitulo := {}

							If !Empty(UQI->UQI_NUM)
								// Define os elementos do array
								Aadd( aTitulo, { "E2_PREFIXO"	, UQI->UQI_PREFIX	, Nil } )
								Aadd( aTitulo, { "E2_NUM"		, UQI->UQI_NUM		, Nil } )
								Aadd( aTitulo, { "E2_PARCELA"	, UQI->UQI_PARCEL	, Nil } )
								Aadd( aTitulo, { "E2_TIPO"		, UQI->UQI_TIPO		, Nil } )
								Aadd( aTitulo, { "E2_FORNECE"	, UQI->UQI_TRANSP	, Nil } )
								Aadd( aTitulo, { "E2_LOJA"		, UQI->UQI_LOJA		, Nil } )
							EndIf

							cFornecUQI := AllTrim(UQI->UQI_TRANSP)
							cLojaUQI := AllTrim(UQI->UQI_LOJA)

							If !Empty(aTitulo)
								AAdd(aTitulos, aTitulo)
							EndIf

						// Se é um arquivo contábil
						ElseIf aScan(aContab, UQI->UQI_CHAVE) > 0
							// Define as variáveis principais
							dData		:= UQG->UQG_DTDOC
							cDoc		:= UQI->UQI_DOC
							cLote		:= UQI->UQI_LOTE
							cSubLote	:= If(UQG->UQG_TIPO == "RD", "RD", "A")

							// Monta o Array de cabeçalho
							Aadd( aCabecalho, { 'DDATALANC'	, dData		, NIL } )
							Aadd( aCabecalho, { 'CLOTE'	  	, cLote		, NIL } )
							Aadd( aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL } )
							Aadd( aCabecalho, { 'CDOC'		, cDoc		, NIL } )
							Aadd( aCabecalho, { 'CPADRAO'	, ""		, NIL } )
							Aadd( aCabecalho, { 'NTOTINF'	, 0			, NIL } )
							Aadd( aCabecalho, { 'NTOTINFLOT', 0			, NIL } )

							// Reinicia o array de item
							aItem		:= {}

							// Define as variáveis dos itens
							cCredito	:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", UQI->UQI_CONTAB, "" )
							nDC 		:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", 2, 1 )
							cDebito		:= IIf( !(AllTrim(UQI->UQI_CHAVE) $ ".39.50."), UQI->UQI_CONTAB, "" )
							cLinha		:= UQI->UQI_LINHA
							cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)

							// Monta array do item
							Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
							Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
							Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
							Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
							Aadd( aItem, {'CT2_CREDIT'	, cCredito			, NIL } )
							Aadd( aItem, {'CT2_DEBITO'	, cDebito			, NIL } )
							Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
							Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
							Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
							Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

							// Adiciona o item ao array de itens
							Aadd( aItens, aItem )

							DbSelectArea("SA2")
							SA2->(DbSetOrder(1)) // A2_FILIAL + A2_COD + A2_LOJA
							If SA2->(DbSeek(xFilial("SA2") + cFornecUQI + cLojaUQI))
								If !Empty(SA2->A2_CONTA)

									aItem := {}
									cLinha := PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
									// Monta contrapartida no array do item
									Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
									Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
									Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )

									If !Empty(cCredito)
										//Adiciono a contrapartida
										Aadd( aItem, {'CT2_DC'		, 1				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
										Aadd( aItem, {'CT2_CREDIT'	, ""			, NIL } )
										Aadd( aItem, {'CT2_DEBITO'	, SA2->A2_CONTA	, NIL } )
									Else
										//Adiciono a contrapartida
										Aadd( aItem, {'CT2_DC'		, 2				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
										Aadd( aItem, {'CT2_CREDIT'	, SA2->A2_CONTA	, NIL } )
										Aadd( aItem, {'CT2_DEBITO'	, ""			, NIL } )
									EndIf

									Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
									Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
									Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
									Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

									aItem := FWVetByDic(aItem, "CT2")

									// Adiciona o item ao array de itens
									Aadd( aItens, aItem )
								EndIf
							EndIf
						EndIf

						UQI->(DbSkip())
					EndDo

					// Realiza o cancelamento dos registros.
					BEGIN TRANSACTION
						// Se existirem títulos a pagar
						If !Empty(aTitulos)
							For nJ := 1 To Len(aTitulos)
								aTitulo := AClone(aTitulos[nJ])

								// Se existirem títulos a pagar
								If !Empty(aTitulo)
									//-- Altera para o módulo Financeiro
									StaticCall(PRT0528, fAltModulo, "FIN", 5)

									// Exclui o título a pagar
									MSExecAuto({|X,Y,Z| FINA050(X,Y,Z)} , aTitulo, , 5) // 3: Inclusao; 4: Alteração; 5:Exclusão
									If lMsErroAuto
										// Disarma a transação
										DisarmTransaction()

										// Prepara o log para ser gravado
										nErro++
										lRet 		:= .F.
										cStatus		:= "E"
										cMsgDet		:= fValExecAut()
										cMensagem	:= CAT545057	//"Erro ao executar programa FINA050 de exclusão de contas a receber via MSExecAuto. Contate o administrador."

										Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})

										Exit
									EndIf
								EndIf
							Next nJ
						EndIf

						// Se todo processo estiver correto até o momento
						If lRet
							//-- Altera para o módulo de Contabilidade
							StaticCall(PRT0528, fAltModulo, "CTB", 34)

							// Exclui os movimentos contábeis
							MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 5 ) // Exclusão
							If lMsErroAuto
								// Disarma a transação
								DisarmTransaction()

								// Prepara o log para ser gravado
								nErro++
								lRet 		:= .F.
								cStatus		:= "E"
								cMsgDet		:= fValExecAut()
								cMensagem	:= CAT545026	//"Erro ao executar programa CTBA102 de exclusão de lançamentos contábeis via MSExecAuto. Contate o administrador."

								Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})
							Else
								// Adiciona um registro cancelado com sucesso.
								nOk++

								// Grava as informações de cancelamento na tabela de muro
								If !lEstorno
									fGrvCancel(UQG->UQG_REF, lRet, UQG->UQG_VERREP)
								EndIf
							EndIf
						EndIf
					END TRANSACTION

				EndIf
			Else	// Não processado
				nErro++
				lRet		:= .F.
				cIdImp 		:= UQG->UQG_IDIMP
				cStatus		:= "E"
				cMensagem	:= CAT545093//"Arquivo de inclusão não encontrado ou já cancelado."

				Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})

				// Adiciona um registro cancelado com sucesso.
				/*	nOk++

				// Grava as informações de cancelamento na tabela de muro
				If !lEstorno
					fGrvCancel(UQG->UQG_REF, lRet, UQG->UQG_VERREP)
				EndIf*/
			EndIf

			DbSelectArea("UQG")
			UQG->(DbSetOrder(1)) // UQG_FILIAL + UQG_IDIMP
			//Posiciono novamente no registro de cancelamento
			If UQG->(DbSeek(xFilial("UQG") + cIdImport))
				If !lRet
					Reclock( "UQG", .F.)
						UQG->UQG_STATUS := "E"
					MsUnlock()
				EndIf
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQI)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fVldCanRnd
Rotina de validação do cancelamento do arquivo de rendição.
@author Paulo Carvalho
@since 24/01/2019
@return cReferencia, carácter, código de referência do arquivo importado.
@version 1.01
@type Static function
/*/
Static Function fVldCanRnd(cReferencia, cVerRep)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	Local lRet		:= .T.

	// Posiciona no registro de cancelamento
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

	If UQG->(DbSeek(xFilial("UQG") + cReferencia + " " + cVerRep))
		// Valida se o título está baixado
		If !fVldTitRnd(cReferencia, cVerRep)
			lRet := .F.
		EndIf
	EndIf
/*/
	If !lRet
		fGrvCancel(cReferencia, lRet)
	EndIf
/*/
	RestArea(aAreaUQG)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fReprocessar
Realiza o reprocessamento do arquivo.
@author Paulo Carvalho
@since 18/02/2019
@return cReferencia, carácter, código de referência do arquivo importado.
@version 1.01
@type Static function
/*/
Static Function fReprocessar(cReferencia, cVerRep, cIdImport)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())

	Local aContab		:= {"39", "40", "50", "60"}
	Local aFinanc		:= {"21", "31"}

	Local aCabecalho	:= {}
	Local aItem			:= {}
	Local aItens		:= {}
	Local aTitulo		:= {}
	Local aTitulos		:= {}

	Local aRefAnt		:= {}
	Local aInfoTitulo	:= {}
	Local aFornec		:= {}

	//Local cAliasQry		:= GetNextAlias()
	Local cCredito		:= ""
	Local cDebito		:= ""
	Local cDoc			:= ""
	Local cFornecUQI	:= ""
	Local cLojaUQI		:= ""
	//Local cIdRep		:= ""
	Local cLinha		:= "0"
	Local cLote			:= ""
	Local cMoeda		:= ""
	//Local cQuery		:= ""
	Local cSubLote		:= ""
	Local cTpTrans		:= "R"
	Local cIdImp		:= ""
	Local cNatureza		:= ""
	Local cTipoTitulo	:= ""
	Local cItem			:= ""
	Local cPrefixo		:= ""
	Local cNumTitulo	:= ""
	Local cParcela		:= ""
	Local cClVl			:= ""

	Local dData			:= ""
	Local dBkpDtBase	:= dDataBase

	Local lContinua		:= .T.
	Local lAtunOk		:= .F.
	Local lRet			:= .T.

	//Local nAt			:= 0
	//Local nI
	Local nJ			:= 0
	Local nPosCred		:= 0

	//Variavel de Controle do MsExecAuto
	Private lMsErroAuto := .F.

	//Variavel de Controle do GetAutoGRLog
	Private lAutoErrNoFile := .T.

	// Abre a tabela de arquivos CTRB
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP

	// Posiciona no arquivo de reprocessamento
	If UQG->(DbSeek(xFilial("UQG") + cReferencia + cTpTrans + cVerRep))
		cIdImp := UQG->UQG_IDIMP

		// Verifica se o arquivo é válido para integração
		If fVldRend(UQG->UQG_IDIMP)
/*			// Define a query para encontrar o arquivo a ser reprocessado
			cQuery	:= "SELECT 	UQG.UQG_FILIAL, UQG.UQG_IDIMP, UQG.UQG_REF, UQG.UQG_STATUS,"+ CRLF
			cQuery	+= "		UQG.UQG_TPTRAN"											+ CRLF
			cQuery	+= "FROM	" + RetSqlName("UQG") + " AS UQG"						+ CRLF
			cQuery	+= "WHERE	UQG.UQG_FILIAL = '" 	+ xFilial("UQG") 	+ "' "			+ CRLF
			cQuery	+= "AND		UQG.UQG_REF = '" 	+ UQG->UQG_REF 		+ "' "			+ CRLF
			cQuery	+= "AND		UQG.UQG_STATUS IN ('I', 'P')"							+ CRLF
			cQuery	+= "AND		UQG.D_E_L_E_T_ <> '*' "									+ CRLF

			MPSysOpenQuery(cQuery, cAliasQry)

			// Se encontrar o arquivo a ser reprocessado.
			If !(cAliasQry)->(Eof())
				// Se possuir mais de um registro, captura o de inclusão para reprocessamento
				While !(cAliasQry)->(Eof())
					// Verifica se o registro é de inclusão
					If (cAliasQry)->UQG_TPTRAN == " "
						cIdRep := (cAliasQry)->UQG_IDIMP
					EndIf

					(cAliasQry)->(DbSkip())
				EndDo

				// Verifica se não foi definido um IDIMP para reprocessamento
				If Empty(cIdRep)
					// Então volta ao topo do alias
					(cAliasQry)->(DbGoTop())

					// E define o único arquivo encontrado para reprocessamento
					cIdRep := (cAliasQry)->UQG_IDIMP
				EndIf
				(cAliasQry)->(DbCloseArea())
*/
				// Realiza o estorno da integração do arquivo
//				If fEstRep(cIdRep)
					// Integra o arquivo de reprocessamento
					// Abre a tabela de itens de rendição
					DbSelectArea("UQI")
					UQI->(DbSetOrder(1))	// UQI_FILIAL + UQI_IDIMP + UQI_ITEM

					If UQI->( DbSeek(xFilial("UQI") + UQG->UQG_IDIMP) )
						// Se o arquivo for válido para integração
						If fVldRend(UQG->UQG_IDIMP)
							BEGIN TRANSACTION
								//-- Busca os arquivos de referência anteriores para serem cancelados
								aRefAnt := fGetRefAnt(UQG->UQG_IDIMP)

								//-- Cancela os arquivos de referência anteriores
								AEval(aRefAnt, {|x| IIf(lContinua, lContinua := fEstRep(x), Nil)})

								If lContinua
									// Define as variáveis principais
									dData		:= UQG->UQG_DTDOC
									cDoc		:= SubStr(AllTrim(UQI->UQI_REF), 5, 6)
									cLote		:= fGLoteUQH(UQI->UQI_REF, UQG->UQG_TIPO) // GetSXENum("CT2", "CT2_LOTE", Nil, 1)
									cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)
									cSubLote	:= If(UQG->UQG_TIPO == "RD", "RD", "A")
									aFornec		:= fGetFornec(cIdImp, cSubLote)
									cFornecUQI	:= aFornec[1]
									cLojaUQI	:= aFornec[2]

									// Monta o Array de cabeçalho
									Aadd( aCabecalho, { 'DDATALANC'	, dData		, NIL } )
									Aadd( aCabecalho, { 'CLOTE'	  	, cLote		, NIL } )
									Aadd( aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL } )
									Aadd( aCabecalho, { 'CDOC'		, cDoc		, NIL } )
									Aadd( aCabecalho, { 'CPADRAO'	, ""		, NIL } )
									Aadd( aCabecalho, { 'NTOTINF'	, 0			, NIL } )
									Aadd( aCabecalho, { 'NTOTINFLOT', 0			, NIL } )

									// Enquanto houver itens de rendição
									While !UQI->(Eof()) .And. UQI->UQI_IDIMP == cIdImp
										// Se for uma movimentação contábil
										If aScan(aContab, UQI->UQI_CHAVE) > 0
											// Reinicia o array de item
											aItem		:= {}

											// Define as variáveis dos itens
											cCredito	:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", UQI->UQI_CONTAB, "" )
											nDC 		:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", 2, 1 )
											cDebito		:= IIf( !(AllTrim(UQI->UQI_CHAVE) $ ".39.50."), UQI->UQI_CONTAB, "" )
											cLinha		:= PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")

											// Monta array do item
											Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
											Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
											Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
											Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada

											If AllTrim(UQI->UQI_CHAVE) $ ".39.50."
												Aadd( aItem, {'CT2_CREDIT'	, cCredito		, NIL } )

												If fClVlObrig(cCredito)
													cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQI + cLojaUQI, "A2_CGC")

													Aadd( aItem, {'CT2_CLVLCR'	, cClVl		, NIL } )
												EndIf
											Else
												Aadd( aItem, {'CT2_DEBITO'	, cDebito		, NIL } )

												If fClVlObrig(cDebito)
													cClVl := Posicione("SA2", 1, xFilial("SA2") + cFornecUQI + cLojaUQI, "A2_CGC")

													Aadd( aItem, {'CT2_CLVLDB'	, cClVl		, NIL } )
												EndIf
											EndIf

											Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
											Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
											Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
											Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

											aItem := FWVetByDic(aItem, "CT2")

											// Adiciona o item ao array de itens
											Aadd( aItens, aItem )

											DbSelectArea("SA2")
											SA2->(DbSetOrder(1)) // A2_FILIAL + A2_COD + A2_LOJA
											If SA2->(DbSeek(xFilial("SA2") + cFornecUQI + cLojaUQI))
												If !Empty(SA2->A2_CONTA)

													aItem := {}
													cLinha := PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
													// Monta contrapartida no array do item
													Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
													Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
													Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )

													nPosCred := aScan(aItens[1], {|x| x[1] == 'CT2_CREDIT'} )
													If nPosCred > 0
														//Adiciono a contrapartida
														Aadd( aItem, {'CT2_DC'		, 1				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
														Aadd( aItem, {'CT2_DEBITO'	, SA2->A2_CONTA	, NIL } )

														If fClVlObrig(SA2->A2_CONTA)
															cClVl := SA2->A2_CGC

															Aadd( aItem, {'CT2_CLVLDB'	, cClVl		, NIL } )
														EndIf
													Else
														//Adiciono a contrapartida
														Aadd( aItem, {'CT2_DC'		, 2				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
														Aadd( aItem, {'CT2_CREDIT'	, SA2->A2_CONTA	, NIL } )

														If fClVlObrig(SA2->A2_CONTA)
															cClVl := SA2->A2_CGC

															Aadd( aItem, {'CT2_CLVLCR'	, cClVl		, NIL } )
														EndIf
													EndIf

													Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
													Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
													Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
													Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

													aItem := FWVetByDic(aItem, "CT2")

													// Adiciona o item ao array de itens
													Aadd( aItens, aItem )
												EndIf
											EndIf
										// Se for um título a pagar
										ElseIf aScan(aFinanc, UQI->UQI_CHAVE) > 0
											// Reinicia array do titulo
											aTitulo := {}

											// -----------------------------------------------------------------------------------
											// Verifica se o fornecedor é autônomo
											// Só gera o título se o fornecedor não for autônomo
											// Regra incluída em 30/05/2019 por Juliano Fernandes conforme solicitação Marcos
											// -----------------------------------------------------------------------------------
											// -----------------------------------------------------------------------------------
											// Conforme solicitação feita por Marcos Santos em 12/06/2019, por momento a regra
											// comentada acima não será aplicada no programa e por esse motivo, a verificação se
											// o fornecedor é autônomo foi comentada.
											// -----------------------------------------------------------------------------------
											//If !fFornAuton(UQI->UQI_TRANSP, UQI->UQI_LOJA)
												cPrefixo   := PadR( SuperGetMV("PLG_PFXCTR", .F.), TamSX3("E2_PREFIXO")[1] )
												cNumTitulo := PadR( SubStr(AllTrim(cCTRB), 5, 6) , TamSX3("E2_NUM")[1]     )

												aInfoTitulo := fGetInfoTit(UQI->UQI_TRANSP, UQI->UQI_LOJA, UQI->UQI_PRODUT, UQI->UQI_TPFRET, UQG->UQG_TIPO, cPrefixo, cNumTitulo, aTitulos)

												cNatureza	:= aInfoTitulo[1]
												cTipoTitulo	:= aInfoTitulo[2]
												cParcela	:= aInfoTitulo[3]

												// Define os elementos do array
												Aadd( aTitulo, { "E2_PREFIXO"	, cPrefixo						, Nil } )
												Aadd( aTitulo, { "E2_NUM"		, cNumTitulo					, Nil } )
												Aadd( aTitulo, { "E2_TIPO"		, cTipoTitulo					, Nil } )
												Aadd( aTitulo, { "E2_NATUREZ"	, cNatureza						, Nil } )
												Aadd( aTitulo, { "E2_FORNECE"	, AllTrim(UQI->UQI_TRANSP)		, Nil } )
												Aadd( aTitulo, { "E2_EMISSAO"	, UQG->UQG_DTDOC				, Nil } )
												Aadd( aTitulo, { "E2_VENCTO"	, UQI->UQI_VENC					, Nil } )
												Aadd( aTitulo, { "E2_VENCREA"	, DataValida(UQI->UQI_VENC, .T.), Nil } )
												Aadd( aTitulo, { "E2_VALOR"		, UQI->UQI_TOTAL				, Nil } )
												Aadd( aTitulo, { "E2_PARCELA"	, cParcela						, Nil } )
												Aadd( aTitulo, { "E2_MOEDA"		, Val(cMoeda)					, Nil } )
												Aadd( aTitulo, { "E2_CCD"		, fGetCCusto(UQI->UQI_IDIMP)	, Nil } )

												If !Empty(UQI->UQI_PRODUT)
													Aadd( aTitulo, { "E2_HIST"	, CAT545091 + UQI->UQI_PRODUT	, Nil } )
												EndIf

											//EndIf
										/*	cFornecUQI := AllTrim(UQI->UQI_TRANSP)
											cLojaUQI := AllTrim(UQI->UQI_LOJA) */

											AAdd(aTitulos, {aTitulo, UQI->UQI_ITEM})
										EndIf

										UQI->(DbSkip())
									EndDo

									//-- Altera para o módulo de Contabilidade
									StaticCall(PRT0528, fAltModulo, "CTB", 34)

									// Integra os movimentos contábeis
									MSExecAuto({|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 3) //Grava sempre um único item/linha
									If lMsErroAuto
										// Disarma a transação
										DisarmTransaction()

										// Prepara o log para ser gravado
										nErro++
										lRet 		:= .F.
										cStatus		:= "E"
										cMsgDet		:= fValExecAut()
										cMensagem	:= CAT545025	//"Erro ao executar programa CTBA102 de gravação de lançamentos contábeis via MSExecAuto. Contate o administrador."

										Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})
									Else
										// Se houverem títulos a serem integrados
										If !Empty(aTitulos)
											For nJ := 1 To Len(aTitulos)
												aTitulo := AClone(aTitulos[nJ,1])
												cItem := aTitulos[nJ,2]

												// Se houverem títulos a serem integrados
												If !Empty(aTitulo)
													//-- Altera para o módulo Financeiro
													StaticCall(PRT0528, fAltModulo, "FIN", 5)

													dDataBase := UQG->UQG_DTDOC

													// Inclui títulos a pagar
													MSExecAuto({|X,Y,Z| FINA050(X,Y,Z)} , aTitulo, , 3) // 3: Inclusao; 4: Alteração; 5:Exclusão

													dDataBase := dBkpDtBase

													If lMsErroAuto .Or. SE2->(EoF())
														// Disarma a transação
														DisarmTransaction()

														// Prepara o log para ser gravado
														nErro++
														lRet 		:= .F.
														cStatus		:= "E"
														cMsgDet		:= fValExecAut()
														cMensagem	:= CAT545056	//"Erro ao executar programa FINA050 de gravação de contas a receber via MSExecAuto. Contate o administrador."

														Aadd(aLog, {cFilArq, cCTRB, cMensagem, cMsgDet, cStatus, cIdImp})

														Exit
													Else
														If !lAtunOk // Variavel utilizada para que atualize apenas uma vez a variável nOk
															// Adiciona um registro integrado com sucesso.
															nOk++
															lAtunOk := .T.
														EndIf

														// Grava as informações de movimentação contábil nos itens contábeis
														fGrvRend(UQG->UQG_IDIMP, aCabecalho, aItens, aTitulo, cItem)
													EndIf
												Else
													// Adiciona um registro integrado com sucesso.
													nOk++

													// Grava as informações de movimentação contábil nos itens contábeis
													fGrvRend(UQG->UQG_IDIMP, aCabecalho, aItens, aTitulo, cItem)
												EndIf
											Next nJ
										Else
											// Adiciona um registro integrado com sucesso.
											nOk++

											// Grava as informações de movimentação contábil nos itens contábeis
											fGrvRend(UQG->UQG_IDIMP, aCabecalho, aItens, aTitulo, "")
										EndIf
									EndIf
								Else
									lRet := .F.
									DisarmTransaction()
								EndIf
							END TRANSACTION
						Else
							nErro++
						EndIf

						DbSelectArea("UQG")
						UQG->(DbSetOrder(1)) // UQG_FILIAL + UQG_IDIMP
						//Posiciono novamente no registro de cancelamento
						If UQG->(DbSeek(xFilial("UQG") + cIdImport))
							If !lRet

								Reclock( "UQG", .F.)
									UQG->UQG_STATUS := "E"
								MsUnlock()
							EndIf
						EndIf
					EndIf
//				EndIf
//			EndIf
		Else
			nErro ++
		EndIf
	Endif

	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fEstRep
Realiza o estorno da integração do arquivo a ser reprocessado.
@author Paulo Carvalho
@since 18/02/2019
@return cIdEstorno, carácter, id de importação do arquivo a ser estornado.
@version 1.01
@type Static function
/*/
Static Function fEstRep(cIdEstorno)

	Local aArea			:= GetArea()
	Local aAreaUQG		:= UQG->(GetArea())
	Local aAreaUQI		:= UQI->(GetArea())

	Local aContab		:= {"39", "40", "50", "60"}
	Local aFinanc		:= {"21", "31"}

	Local aCabecalho	:= {}
	Local aItem			:= {}
	Local aItens		:= {}
	Local aTitulo		:= {}
	Local aTitulos		:= {}

	Local cDoc			:= ""
	Local cDocumento	:= ""
	Local cFornecUQI	:= ""
	Local cLojaUQI		:= ""
	Local cLote			:= ""
	Local cMoeda		:= ""
	Local cRefEst		:= ""
	Local cSubLote		:= ""
	Local cSeekCT2		:= ""
	Local cSeekSE2		:= ""
	Local cTpSaldo		:= "1"
	Local cIdImp		:= ""

	Local dData			:= ""

	Local lRet			:= .T.

	Local nJ			:= 0

	// Busca o arquivo a ser estornado
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	// Posiciona no cabeçalho do arquivo
	If UQG->(DbSeek(xFilial("UQG") + cIdEstorno))
		cDocumento := UQG->UQG_REF
		cIdImp     := UQG->UQG_IDIMP

		// Verificar se o arquivo já foi processado
		If UQG->UQG_STATUS == "P"
			// Busca os Itens do arquivo a ser estornado
			DbSelectArea("UQI")
			UQI->(DbSetOrder(1))	// UQI_FILIAL + UQI_IDIMP + UQI_ITEM

			// Posiciona no item do arquivo
			If UQI->(DbSeek(xFilial("UQI") + cIdEstorno))
				cRefEst := UQG->UQG_REF

				// Enquanto houver itens para o arquivo
				While !UQI->(Eof()) .And. UQI->UQI_IDIMP == cIdEstorno
					// Se é um arquivo que gera financeiro
					If aScan(aFinanc, UQI->UQI_CHAVE) > 0
						// Reinicia array do titulo
						aTitulo := {}

						If !Empty(UQI->UQI_NUM)
							// Define os elementos do array
							Aadd( aTitulo, { "E2_PREFIXO"	, UQI->UQI_PREFIX			, Nil } )
							Aadd( aTitulo, { "E2_NUM"		, UQI->UQI_NUM				, Nil } )
							Aadd( aTitulo, { "E2_PARCELA"	, UQI->UQI_PARCEL			, Nil } )
							Aadd( aTitulo, { "E2_TIPO"		, fGetTipoTit(UQG->UQG_TIPO)	, Nil } )
							Aadd( aTitulo, { "E2_FORNECE"	, UQI->UQI_TRANSP			, Nil } )
							Aadd( aTitulo, { "E2_LOJA"		, UQI->UQI_LOJA				, Nil } )

							cSeekSE2 := xFilial("SE2") + UQI->UQI_PREFIX + UQI->UQI_NUM + UQI->UQI_PARCEL + fGetTipoTit(UQG->UQG_TIPO) + UQI->UQI_TRANSP + UQI->UQI_LOJA
						EndIf

						cFornecUQI := AllTrim(UQI->UQI_TRANSP)
						cLojaUQI := AllTrim(UQI->UQI_LOJA)

						If !Empty(aTitulo) .And. !Empty(cSeekSE2)
							AAdd(aTitulos, {aTitulo, cSeekSE2})
						EndIf

					// Se é um arquivo contábil
					ElseIf aScan(aContab, UQI->UQI_CHAVE) > 0
						// Define as variáveis principais
						dData		:= UQG->UQG_DTDOC
						cDoc		:= UQI->UQI_DOC
						cLote		:= UQI->UQI_LOTE
						cSubLote	:= "RD" // If(UQG->UQG_TIPO == "RD", "RD", "A")

						// Monta o Array de cabeçalho
						Aadd( aCabecalho, { 'DDATALANC'	, dData		, NIL } )
						Aadd( aCabecalho, { 'CLOTE'	  	, cLote		, NIL } )
						Aadd( aCabecalho, { 'CSUBLOTE'	, cSubLote	, NIL } )
						Aadd( aCabecalho, { 'CDOC'		, cDoc		, NIL } )
						Aadd( aCabecalho, { 'CPADRAO'	, ""		, NIL } )
						Aadd( aCabecalho, { 'NTOTINF'	, 0			, NIL } )
						Aadd( aCabecalho, { 'NTOTINFLOT', 0			, NIL } )

						// Reinicia o array de item
						aItem		:= {}

						// Define as variáveis dos itens
						cCredito	:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", UQI->UQI_CONTAB, "" )
						nDC 		:= IIf( AllTrim(UQI->UQI_CHAVE) $ ".39.50.", 2, 1 )
						cDebito		:= IIf( !(AllTrim(UQI->UQI_CHAVE) $ ".39.50."), UQI->UQI_CONTAB, "" )
						cLinha		:= UQI->UQI_LINHA
						cMoeda		:= fDefMoeda(UQG->UQG_MOEDA)

						// Monta array do item
						Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
						Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
						Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )
						Aadd( aItem, {'CT2_DC'		, nDC				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
						Aadd( aItem, {'CT2_CREDIT'	, cCredito			, NIL } )
						Aadd( aItem, {'CT2_DEBITO'	, cDebito			, NIL } )
						Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
						Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
						Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
						Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

						// Adiciona o item ao array de itens
						Aadd(aItens, aItem)

						DbSelectArea("SA2")
						SA2->(DbSetOrder(1)) // A2_FILIAL + A2_COD + A2_LOJA
						If SA2->(DbSeek(xFilial("SA2") + cFornecUQI + cLojaUQI))
							If !Empty(SA2->A2_CONTA)

								aItem := {}
								//cLinha := PadL(Soma1(cLinha), TamSX3("CT2_LINHA")[1], "0")
								// Monta contrapartida no array do item
								Aadd( aItem, {'CT2_FILIAL'	, xFilial("CT2")	, NIL } )
								Aadd( aItem, {'CT2_LINHA'	, cLinha			, NIL } )
								Aadd( aItem, {'CT2_MOEDLC'	, cMoeda			, NIL } )

								If !Empty(cCredito)
									//Adiciono a contrapartida
									Aadd( aItem, {'CT2_DC'		, 1				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
									Aadd( aItem, {'CT2_CREDIT'	, ""			, NIL } )
									Aadd( aItem, {'CT2_DEBITO'	, SA2->A2_CONTA	, NIL } )
								Else
									//Adiciono a contrapartida
									Aadd( aItem, {'CT2_DC'		, 2				, NIL } )	//1 - Débito | 2 - Crédito | 3- Partida Dobrada
									Aadd( aItem, {'CT2_CREDIT'	, SA2->A2_CONTA	, NIL } )
									Aadd( aItem, {'CT2_DEBITO'	, ""			, NIL } )
								EndIf

								Aadd( aItem, {'CT2_VALOR'	, UQI->UQI_TOTAL		, NIL } )
								Aadd( aItem, {'CT2_ORIGEM'	, 'MSEXECAUT'		, NIL } )
								Aadd( aItem, {'CT2_HP'		, ""				, NIL } )
								Aadd( aItem, {'CT2_HIST'	, fGetHistor(cIdImp), NIL } )

								aItem := FWVetByDic(aItem, "CT2")

								// Adiciona o item ao array de itens
								Aadd( aItens, aItem )
							EndIf
						EndIf
						// Cria o índice para a CT2
						If Empty(cSeekCT2)
							cSeekCT2 := xFilial("CT2") + DtoS(dData) + cLote + PadR(cSubLote, TamSX3("CT2_SBLOTE")[1], " ") +;
										cDoc + cLinha + cTpSaldo + cEmpAnt + cFilAnt
						EndIf
					EndIf

					UQI->(DbSkip())
				EndDo

				// Inicia o processo de estorno
				BEGIN TRANSACTION
					// Se existirem títulos a pagar
					If !Empty(aTitulos)
						For nJ := 1 To Len(aTitulos)
							aTitulo := AClone(aTitulos[nJ,1])
							cSeekSE2 := aTitulos[nJ,2]

							// Se existirem títulos a pagar
							If !Empty(aTitulo)
								DbSelectArea("SE2")
								SE2->(DbSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
								If SE2->(DbSeek(cSeekSE2))
									//-- Altera para o módulo Financeiro
									StaticCall(PRT0528, fAltModulo, "FIN", 5)

									// Exclui o título a pagar
									MSExecAuto({|X,Y,Z| FINA050(X,Y,Z)} , aTitulo, , 5) // 3: Inclusao; 4: Alteração; 5:Exclusão
									If lMsErroAuto
										// Disarma a transação
										DisarmTransaction()

										// Prepara o log para ser gravado
										nErro++
										lRet 		:= .F.
										cStatus		:= "E"
										cMsgDet		:= fValExecAut()
										cMensagem	:= CAT545057	//"Erro ao executar programa FINA050 de exclusão de contas a receber via MSExecAuto. Contate o administrador."

										Aadd(aLog, {cFilArq, cDocumento, cMensagem, cMsgDet, cStatus, cIdImp})

										Exit
									EndIf
								Else
									// Disarma a transação
									DisarmTransaction()

									// Prepara o log para ser gravado
									nErro++
									lRet 		:= .F.
									cStatus		:= "E"
									cMsgDet		:= ""
									cMensagem	:= CAT545058 //"Titulo não localizado."

									Aadd(aLog, {cFilArq, cDocumento, cMensagem, cMsgDet, cStatus, cIdImp})

									Exit
								EndIf
							EndIf
						Next nJ
					Else
						// Disarma a transação
						DisarmTransaction()

						// Prepara o log para ser gravado
						nErro++
						lRet 		:= .F.
						cStatus		:= "E"
						cMsgDet		:= ""
						cMensagem	:= CAT545058 //"Titulo não localizado."

						Aadd(aLog, {cFilArq, cDocumento, cMensagem, cMsgDet, cStatus, cIdImp})
					EndIf

					// Se todo processo estiver correto até o momento
					If lRet
						// Posiciona na CT2 para execução do ExecAuto de exclusão
						DbSelectArea("CT2")
						CT2->(DbSetOrder(1)) 		// CT2_FILIAL + DTOS(CT2_DATA) + CT2_LOTE + CT2_SBLOTE + CT2_DOC + CT2_LINHA + CT2_TPSALD + CT2_EMPORI  + CT2_FILORI + CT2_MOEDLC
						If CT2->(DbSeek(cSeekCT2))
							//-- Altera para o módulo de Contabilidade
							StaticCall(PRT0528, fAltModulo, "CTB", 34)

							// Exclui os movimentos contábeis
							MSExecAuto( {|X,Y,Z| CTBA102(X,Y,Z)} , aCabecalho, aItens, 5 ) // Exclusão
							If lMsErroAuto
								// Disarma a transação
								DisarmTransaction()

								// Prepara o log para ser gravado
								nErro++
								lRet 		:= .F.
								cStatus		:= "E"
								cMsgDet		:= fValExecAut()
								cMensagem	:= CAT545026	//"Erro ao executar programa CTBA102 de exclusão de lançamentos contábeis via MSExecAuto. Contate o administrador."

								Aadd(aLog, {cFilArq, cDocumento, cMensagem, cMsgDet, cStatus, cIdImp})
							Else
								// Adiciona um registro cancelado com sucesso.
								nOk++
							EndIf
						EndIf
					EndIf

					// Se o processo de estorno foi realizado com sucesso
					If lRet
						cStatus		:= "I"
						cMensagem	:= CAT545027 + cDocumento + CAT545028	//"Arquivo " # " cancelado com sucesso."

						Aadd(aLog, {cFilArq, cDocumento, cMensagem, Nil, cStatus, cIdImp})

						// Altera o status do arquivo para reprocessado
						fGrvRep(cIdEstorno)
					EndIf
				END TRANSACTION
			EndIf
		Else
			cStatus		:= "I"
			cMensagem	:= CAT545027 + cDocumento + CAT545028	//"Arquivo " # " cancelado com sucesso."

			Aadd(aLog, {cFilArq, cDocumento, cMensagem, Nil, cStatus, cIdImp})

			fGrvRep(cIdEstorno)
		EndIf
	EndIf

	RestArea(aAreaUQI)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGrvRep
Altera o status do arquivo para reprocessado.
@author Paulo Carvalho
@since 18/02/2019
@return cIdEstorno, carácter, id de importação do arquivo reprocessado.
@version 1.01
@type Static function
/*/
Static Function fGrvRep(cIdEstorno)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	// Posiciona no arquivo reprocessado
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	If UQG->(DbSeek(xFilial("UQG") + cIdEstorno))
		// Trava a tabela realiza a alteração de status
		Reclock("UQG", .F.)
			UQG->UQG_STATUS := "C"
		UQG->(MsUnlock())
	EndIf

	RestArea(aArea)
	RestArea(aAreaUQG)

Return

/*/{Protheus.doc} fVldTitRnd
Valida se o título a pagar referente à rendição não está baixado.
@author Paulo Carvalho
@since 24/01/2019
@return cReferencia, carácter, código de referência do arquivo importado.
@version 1.01
@type Static function
/*/
Static Function fVldTitRnd(cReferencia, cVerRep)

	//Local aAreaUQG	:= UQG->(GetArea())
	//Local aAreaUQI	:= UQI->(GetArea())

	Local cAcao		:= " "
	Local cIdInc	:= ""
	Local cMensagem	:= ""
	Local cStatus	:= ""

	// Local nLinha	:= 0

	Local lRet		:= .T.

	// Posiciona no arquivo de rendição com título a pagar
	DbSelectArea("UQG")
	UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP
	UQG->(DbGoTop())

	// Busco a arquivo de inclusão da rendição
	If UQG->(DbSeek(xFilial("UQG") + cReferencia + cAcao + cVerRep))
		// Verifico se a rendição foi processada no sistema
		If UQG->UQG_STATUS == "P"
			// Recupera o código identificador da importação da inclusão
			cIdInc := UQG->UQG_IDIMP

			// Posiciona nos itens da rendição
			DbSelectArea("UQI")
			UQI->(DbSetOrder(2))	// UQI_FILIAL + UQI_IDIMP + UQI_CHAVE

			If UQI->(DbSeek(xFilial("UQI") + cIdInc + "21")) .Or. UQI->(DbSeek(xFilial("UQI") + cIdInc + "31"))
				// Posiciona no título a pagar
				DbSelectArea("SE2")
				SE2->(DbSetOrder(1))	// E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA

				If SE2->(DbSeek(xFilial("SE2") + UQI->UQI_PREFIX + UQI->UQI_NUM + UQI->UQI_PARCEL + fGetTipoTit(UQG->UQG_TIPO)))
					// Verifica se o título foi baixado
					If !Empty(SE2->E2_BAIXA)
						lRet		:= .F.
						cStatus		:= "E"
						cMensagem	:= CAT545059 + AllTrim(cReferencia) + CAT545060 + AllTrim(SE2->E2_NUM) + CAT545061 // "Não é possível cancelar a rendição ", " pois o título a pagar ", " já foi baixado."

						Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdInc})
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

Return lRet

/*/{Protheus.doc} fGLoteUQH
Rotina para recuperar o lote do lançamento contábil de provisão.
@author Paulo Carvalho
@since 22/01/2019
@return cRef, carácter, código de referência do arquivo importado.
@version 1.01
@type Static function
/*/
Static Function fGLoteUQH(cRef, cTipo)

	Local aArea			:= GetArea()

	Local cAliasQry		:= GetNextAlias()
	Local cLote			:= ""
	Local cReferencia	:= If(cTipo == "RD", StrTran(cRef, "RD", "PR"), StrTran(cRef, "A", "PR")) // PadR(Left(AllTrim(cRef), 10) + "PR", 16, " ")
	Local cQuery		:= ""

	// Define a query
	cQuery	+= "SELECT 	UQH.UQH_FILIAL, UQH.UQH_IDIMP, UQH.UQH_REF, UQH.UQH_LOTE"	+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQH") 	+ " AS UQH "					+ CRLF
	cQuery	+= "WHERE	UQH.UQH_FILIAL = '" 		+ FWxFilial("UQH") 	+ "' "		+ CRLF
	cQuery	+= "AND		UQH.UQH_REF = '" 		+ cReferencia 		+ "' "		+ CRLF
	cQuery	+= "AND		UQH.UQH_LOTE <> '' "										+ CRLF

	// Executa a query criando um alias
	MPSysOpenQuery(cQuery, cAliasQry)

	// Se encontrou alguma registro
	If !(cAliasQry)->(Eof())
		cLote := (cAliasQry)->UQH_LOTE
	EndIf

	(cAliasQry)->(DbCloseArea())
	RestArea(aArea)

Return cLote

/*/{Protheus.doc} fGrvRend
Rotina para integração dos arquivos CTRB de rendição.
@author Paulo Carvalho
@since 11/01/2019
@return aCabecalho, array, array contendo os dados do cabeçalho enviado para o MSExecAuto.
@return aItens, array, array contendo os dados dos itens enviados para o MSExecAuto.
@version 1.01
@type Static function
/*/
Static Function fGrvRend(cIdImp, aCabecalho, aItens, aTitulo, cItem)

	Local aAreaUQI	:= UQI->(GetArea())
	Local aAreaUQG	:= UQG->(GetArea())

	Local cChaveCon	:= "40"
	Local cChaveAdi	:= "39"
	Local cMensagem	:= ""
	Local cStatus	:= ""

	Local nI
	// Local nLinha	:= 0
	Local nPsDoc	:= 4
	Local nPsLinha	:= 2
	Local nPsLote	:= 2
	Local nPsPrefix	:= 1
	Local nPsNum	:= 2
	Local nPsTipo	:= 3
	Local nPsParcel	:= 10
	Local nPsSbLote	:= 3

	// Atualiza as informações dos itens contábeis de rendição
	For nI := 1 To Len(aItens)
		// Abre a tabela de itens de rendição
		DbSelectArea("UQI")
		UQI->(DbSetOrder(2)) // UQI_FILIAL + UQI_IDIMP + UQI_CHAVE

		// Se existe o item contábil importado
		If UQI->( DbSeek(xFilial("UQI") + cIdImp + cChaveCon ) )
			// Locka a tabela
			RecLock("UQI", .F.)
				UQI->UQI_LOTE	:= aCabecalho[nPsLote][2]
				UQI->UQI_SBLOTE	:= aCabecalho[nPsSbLote][2]
				UQI->UQI_DOC		:= aCabecalho[nPsDoc][2]
				UQI->UQI_LINHA	:= aItens[nI][nPsLinha][2]
			UQI->(MsUnlock())
		// Se for um adiantamento
		ElseIf UQI->( DbSeek(xFilial("UQI") + cIdImp + cChaveAdi ) )
			// Locka a tabela
			RecLock("UQI", .F.)
				UQI->UQI_LOTE	:= aCabecalho[nPsLote][2]
				UQI->UQI_SBLOTE	:= aCabecalho[nPsSbLote][2]
				UQI->UQI_DOC		:= aCabecalho[nPsDoc][2]
				UQI->UQI_LINHA	:= aItens[nI][nPsLinha][2]
			UQI->(MsUnlock())
		EndIf
	Next

//	cChave := "31"

	// Atualiza as informações dos itens financeiras de rendição
	If !Empty(aTitulo) .And. !Empty(cItem)
//		For nI := 1 To Len(aTitulo)
			// Abre a tabela de itens de rendição
			DbSelectArea("UQI")
			UQI->(DbSetOrder(1)) // UQI_FILIAL+UQI_IDIMP+UQI_ITEM

			cChave := ".21.31."

			// Se existe o item importado
			If UQI->( DbSeek(xFilial("UQI") + cIdImp + cItem ) )
				If AllTrim(UQI->UQI_CHAVE) $ cChave
				// Locka a tabela
					RecLock("UQI", .F.)
						UQI->UQI_PREFIX	:= aTitulo[nPsPrefix][2]
						UQI->UQI_NUM	:= aTitulo[nPsNum][2]
						UQI->UQI_PARCEL	:= aTitulo[nPsParcel][2]
						UQI->UQI_TIPO	:= aTitulo[nPsTipo][2]
					UQI->(MsUnlock())
				EndIf
			EndIf
//		Next
	EndIf

	// Atualiza o status do cabeçalho dos arquivos de provisão.
	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

	// Se encontrar o arquivo
	If UQG->( DbSeek( xFilial("UQG") + cIdImp ) )
		// Locka a tabela e realiza a alteração do status
		Reclock("UQG", .F.)
			UQG->UQG_STATUS	:= "P"
		UQG->(MsUnlock())

		// Grava o log de registro integrado com sucesso
		cStatus 	:= "I"
		cMensagem	:= CAT545062 + AllTrim(cCTRB) + CAT545063 // "O arquivo CTRB ", " foi integrado com sucesso."

		If AScan(aLog, {|x| x[1] + x[2] + x[5] + x[6] == cFilArq + cCTRB + cStatus + cIdImp}) == 0
			Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
		EndIf
	EndIf

	RestArea(aAreaUQG)
	RestArea(aAreaUQI)

Return

/*/{Protheus.doc} fExcluir
Realiza a integração dos dados das tabelas UQD e UQE gerando Pedido de Venda, Liberação e Nota Fiscal.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param lAgrupa, logical, descricao
@type function
/*/
Static Function fExcluir()

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())
	Local aAreaUQH	:= UQH->(GetArea())
	Local aAreaUQI	:= UQI->(GetArea())

	Local aSels		:= fGetSels()

	Local cMensagem	:= ""
	Local cStatus	:= "I"
	Local cIdImp	:= ""

	Local nI, nJ
	// Local nLinha	:= 0
	Local nPsIdImp	:= GdFieldPos("UQG_IDIMP", aHeaderUQG)

	Private cFilArq	:= ""
	Private cCTRB	:= ""

	If !Empty(aSels)
		If MsgYesNo( CAT545064, cCadastro) //"Deseja realmente excluir os arquivos selecionados?"
			For nJ := 1 To Len(aFiliais)
				aSels := fGetSels(aFiliais[nJ,2])

				If !Empty(aSels)
					//-- Altera para a filial do registro selecionado
					StaticCall(PRT0528, fAltFilial, aFiliais[nJ,1])

					// Abre a tabela de cabeçalho dos arquivos
					DbSelectArea("UQG")
					UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
					UQG->(DbGoTop())

					For nI := 1 To Len(aSels)
						// Posiciona no arquivo selecionado
						If UQG->(DbSeek(xFilial("UQG") + aSels[nI][nPsIdImp]))
							cFilArq	:= UQG->UQG_FIL
							cCTRB 	:= UQG->UQG_REF
							cIdImp	:= UQG->UQG_IDIMP

							// Verifica se o mesmo não está processado, reprocessado ou cancelado.
							If !(UQG->UQG_STATUS $ "PRC")
								// Posiciona nos itens do cabeçalho para exclusão
								If "PR" $ UQG->UQG_TIPO	// Provisão
									DbSelectArea("UQH")
									UQH->(DbSetOrder(1))	// UQH_FILIAL + UQH_IDIMP + UQH_ITEM

									// Se encontrar os itens
									If UQH->(DbSeek(xFilial("UQH") + UQG->UQG_IDIMP))
										// Enquanto houver itens para o arquivo
										While !UQH->(Eof()) .And. UQH->UQH_IDIMP ==  UQG->UQG_IDIMP
											// Deleta o item
											UQH->(Reclock("UQH", .F.))
												UQH->(DbDelete())
											UQH->(MsUnlock())

											UQH->(DbSkip())
										EndDo
									EndIf
								ElseIf "RD" $ UQG->UQG_TIPO .Or. "A"	$ UQG->UQG_TIPO // Rendição ou Adiantamento
									DbSelectArea("UQI")
									UQI->(DbSetOrder(1))	// UQH_FILIAL + UQH_IDIMP + UQH_ITEM

									// Se encontrar os itens
									If UQI->(DbSeek(xFilial("UQI") + UQG->UQG_IDIMP))
										// Enquanto houver itens para o arquivo
										While !UQI->(Eof()) .And. UQI->UQI_IDIMP ==  UQG->UQG_IDIMP
											// Deleta o item
											UQI->(Reclock("UQI", .F.))
												UQI->(DbDelete())
											UQI->(MsUnlock())

											UQI->(DbSkip())
										EndDo
									EndIf
								EndIf

								// Deleta o cabeçalho do arquivo
								UQG->(Reclock("UQG", .F.))
									UQG->(DbDelete())
								UQG->(MsUnlock())

								cMensagem := CAT545027 + AllTrim(UQG->UQG_REF) + CAT545065 //"Arquivo " #" excluído com sucesso."

								// Grava o log de exclusão
								Aadd(aLog, {cFilArq, cCTRB, cMensagem, "", cStatus, cIdImp})
							EndIf
						EndIf

						// Retorna ao topo da tabela
						UQG->(DbGotop())
					Next
				EndIf
			Next nJ

			fGrvLog(aLog)

			MsgInfo(CAT545066, cCadastro)	//"Registros excluídos com sucesso."

			// Atualiza GetDados
			fFillCab()
		EndIf
	Else
		MsgInfo(CAT545067, cCadastro) //"Nenhum registro selecionado para exclusão."
	EndIf

	RestArea(aAreaUQI)
	RestArea(aAreaUQH)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fEstornar
Estorna
@author Kevin Willians
@since 21/02/2019
@return Nil, Nulo
@param nAt, numeric, descricao
@type function
/*/
Static Function fEstornar(nAt)

	Local aArea		:= GetArea()
	Local aAreaUQG	:= UQG->(GetArea())

	Local cIdImp	:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_IDIMP", aHeaderUQG)]
	Local cTipo		:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_TIPO", aHeaderUQG)]
	Local cRef		:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_REF", aHeaderUQG)]
	Local cVerRep	:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_VERREP", aHeaderUQG)]
	Local cStatus	:= "I"

	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
	UQG->(DbSeek(xFilial("UQG") + cIdImp ))

	// Verifica se o arquivo selecionado está integrado ao Protheus
	If UQG->UQG_STATUS <> "P"
		MsgAlert(CAT545068, cCadastro)	//"Só é permitido o estorno de arquivos integrados ao Protheus."
	Else
		If MsgYesNo( CAT545069, cCadastro) //"Deseja realmente realizar o estorno do lote de registros posicionado?"
			//	Verifica se o usuário tem acesso a rotina de estorno
			If RetCodUsr() $ SuperGetMV("PLG_USREST",,.F.)
				// Verifica o tipo de ação a ser realizada
				If cTipo == "PR"
					fCancelPrv(cRef, .T., cVerRep, cIdImp)
				ElseIf cTipo == "RD"
					fCancelRnd(cRef, .T., cVerRep, cIdImp)
				EndIf

				UQG->(DbSeek(xFilial("UQG") + cIdImp))

				//-- Atualiza a UQG
				fAtuSZ(cTipo, cStatus, cIdImp)
				oGDadUQG:Refresh()
				fFillCab()//atualiza as legendas recarregando a busca

				MsgInfo( CAT545070, cCadastro)	//"Registro estornado com sucesso!"
			Else
				MsgInfo(CAT545071, cCadastro)	//"Usuário sem permissão necessária para estornar registros"
			EndIf
		EndIf
	EndIf

	RestArea(aAreaUQG)
	RestArea(aArea)

Return

/*/{Protheus.doc} fAtuSZ
Atualiza os campos necessários após estorno de integração.
@author Kevin Willians
@since 19/02/2019
@param cTipo, caracter, tipo de transação do arquivo.
@param cStatus, caracter, status atual do arquivo após estorno.
@param cRef, caracter, código de referência do arquivo estornado.
@version 1.01
@type Static Function
/*/
Static Function fAtuSZ(cTipo, cStatus, cRef)

	//Local aAreas 	:= {}
	Local nI		:= 0
	//Local aCol		:= {}

	Local aAreaUQG 	:= UQG->(GetArea())
	Local aAreaUQH	:= UQH->(GetArea())
	Local aAreaUQI 	:= UQI->(GetArea())

	If cTipo == "PR"
		DbSelectArea("UQH")

		UQH->(DbSetOrder(1))	//UQH_FILIAL+UQH_IDIMP+UQH_ITEM
		UQH->(DbSeek(xFilial("UQH") + cRef))	//Encontra o primeiro item
		For nI := 1 To Len(oGDadUQH:aCols)
			UQH->(Reclock("UQH", .F.))
				UQH->UQH_LOTE 	:= ""
				UQH->UQH_SBLOTE	:= ""
				UQH->UQH_DOC		:= ""
				UQH->UQH_LINHA	:= ""
			UQH->(MsUnlock())

			UQH->(DbSkip())
		Next nI
	ElseIf cTipo == "RD" .Or. AllTrim(cTipo) == "A"
		DbSelectArea("UQI")

		UQI->(DbSetOrder(1))	//UQI_FILIAL+UQI_IDIMP+UQI_ITEM
		UQI->(DbSeek(xFilial("UQI") + cRef))	//Encontra o primeiro item
		For nI := 1 To Len(oGDadUQI:aCols)
			UQI->(Reclock("UQI", .F.))
				UQI->UQI_LOTE 	:= ""
				UQI->UQI_SBLOTE	:= ""
				UQI->UQI_DOC	:= ""
				UQI->UQI_LINHA	:= ""
				UQI->UQI_PREFIX	:= ""
				UQI->UQI_NUM	:= ""
				UQI->UQI_PARCEL	:= ""
				UQI->UQI_TIPO	:= ""
			UQI->(MsUnlock())
			UQI->(DbSkip())
		Next nI
	EndIf

	DbSelectArea("UQG")
	// Atualiza o status do arquivo de inclusão.
		If UQG->(DbSeek(xFilial("UQG") + cRef ))
			Reclock("UQG", .F.)
				UQG->UQG_STATUS := cStatus
			UQG->(MsUnlock())
		EndIf

	RestArea(aAreaUQG)
	RestArea(aAreaUQH)
	RestArea(aAreaUQI)

Return(Nil)

/*/{Protheus.doc} fValExecAut
Monta a mensagem de erro gerada pela Execauto e retorna para gravação da mensagem em detalhes.
@author Kevin Willians & Paulo Carvalho
@since 19/02/2019
@return cMensagem, caracter, mensagem de erro tratada retornada pela Execauto.
@version 0.01
@type Static Function
/*/
Static Function fValExecAut()

	Local aErro		:= {}
	Local cMensagem := ""

	Local nI

	// Captura o erro ocorrido em forma de array
	aErro	:= GetAutoGRLog()

	// Verifica se array não está vázio
	If !Empty(aErro)
		For nI := 1 To Len(aErro)
			cMensagem += aErro[nI] + CRLF
		Next
	EndIf

Return cMensagem

/*/{Protheus.doc} fGrvLog
Grava o registro de log para a importação dos arquivos CTE/CRT
@author Paulo Carvalho
@since 07/01/2019
@param nLinha, númerico, Número da linha que gerou o log.
@param cMensagem, caracter, Mensagem descritiva da ocorrência do log.
@version 1.01
@type Static Function
/*/
Static Function fGrvLog(aLog)

	Local aArea		:= GetArea()

	Local cHora		:= "" // Time()
	Local cUsuario	:= IIf(l528Auto, cUserSched, UsrRetName(RetCodUsr()))

	Local dData		:= Date()

	Local nI
	Local nLinha	:= 0

	// Abre a tabela de log da importação de arquivos CTRB
	DbSelectArea( "UQJ" )

	For nI := 1 To Len(aLog)
		// Determina a hora da gravação do log
		cHora := Time()

		// Trava a tabela para inclusão de registro
		UQJ->(RecLock( "UQJ", .T. ))
			// Grava as informações do log
			If !Empty(aLog[nI][1])
				UQJ->UQJ_FILIAL	:= fDefFilial(aLog[nI][1])
			Else
				UQJ->UQJ_FILIAL	:= FWxFilial("UQJ")
			EndIf

			UQJ->UQJ_FIL		:= aLog[nI][1]
			UQJ->UQJ_DATA	:= dData
			UQJ->UQJ_HORA	:= cHora
			UQJ->UQJ_REGCOD	:= aLog[nI][2]
			UQJ->UQJ_MSG		:= aLog[nI][3]
			UQJ->UQJ_MSGDET	:= aLog[nI][4]
			UQJ->UQJ_NLINHA	:= nLinha
			UQJ->UQJ_ARQUIV	:= CAT545072	// "Integração"
			UQJ->UQJ_USER	:= cUsuario
			UQJ->UQJ_LIDO	:= "N"
			UQJ->UQJ_ACAO	:= "INT"
			UQJ->UQJ_STATUS	:= aLog[nI][5]

			If l528Auto
				UQJ->UQJ_IDSCHE := cIdSched
			EndIf

			UQJ->UQJ_IDIMP	:= aLog[nI][6]

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
@return cFilSis, caracter, filial do sistema equivalente à filial veloce.
@version 1.01
@type Static Function
/*/
Static Function fDefFilial(cFilVelo)

	Local aArea		:= GetArea()
	Local aAreaUQK	:= UQK->(GetArea())

	Local cFilSis	:= ""

	// Procura a filial veloce na tabela de filiais
	DbSelectArea("UQK")
	UQK->(DbSetOrder(1))	// UQK_FILIAL + UQK_FILARQ

	// Se encontrar a filial veloce
	If UQK->(DbSeek(FWxFilial("UQK") + cFilVelo))
		// Armazena a filial do sistema
		cFilSis := UQK->UQK_FILPRO
	EndIf

	RestArea(aAreaUQK)
	RestArea(aArea)

Return cFilSis

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

	cQuery	+= "UPDATE " + RetSQLName("UQJ") + " SET UQJ_LIDO = 'S' "	+ CRLF

	Execute(cQuery)

	RestArea(aArea)

Return

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
		MsgAlert( CAT545058 + CRLF + cErro, cCadastro )	// "Erro ao executar rotina:"
	EndIf

Return lRet

/*/{Protheus.doc} fReport
Gera o relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return Nil, Nulo
@type function
/*/
Static Function fReport()

	Local lBold			:= .T.
	Local lItalic		:= .T.
	Local lUnderline	:= .T.
	//Local cPerg			:= "PRT0545"

	Private oF12		:= TFont():New("Arial",,12,,!lBold,,,,,!lUnderline,!lItalic)
	Private oF12UB		:= TFont():New("Arial",,12,, lBold,,,,, lUnderline,!lItalic)
	Private oF12B		:= TFont():New("Arial",,12,, lBold,,,,,!lUnderline,!lItalic)
	Private oF18B		:= TFont():New("Arial",,18,, lBold,,,,,!lUnderline,!lItalic)

	Private cTitulo		:= NomePrt + CAT545074 + VersaoJedi // " - Relatório de Arq. Importados - "
	Private oRelatorio	:= Nil
	Private oSecCab		:= Nil
	Private oSecPR		:= Nil
	Private oSecRD		:= Nil

	// Verifica se a GetDados está vazia

	oRelatorio := ReportDef()
	oRelatorio:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
//TODO Descrição auto-gerada.
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return oRelatorio, ${return_description}
@type function
/*/
Static Function ReportDef()
	Local cAliasPR	:= GetNextAlias()
	Local cAliasRD	:= GetNextAlias()
	Local cArquivo	:= "PRT0545_" + DtoS( Date() ) + StrTran( Time(), ":", "" )
	Local cTitulo	:= NomePrt + " - " + CAT545076 + " - " + VersaoJedi	// "Arquivos CTRB"
	Local cBmpLogo	:= "\logotipos\logo_empresa.jpg" //Deve ser jpg na pasta system
												 //A função FisxLogo("1") busca o logo(BMP) a ser impresso, mas
												 //esse logo não é impresso caso a opção selecionada seja arquivo

	Local bAction	:= { |oRelatorio| PrintReport( oRelatorio, oGDadUQG:aCols, cAliasPR, cAliasRD) }
	Local nI		:= 1
	//Local aCab 		:= oGDadUQG:aCols

	Local oRelatorio

	// Instanciando o objeto TReport
	oRelatorio := TReport():New( "PRT0545" )
	oRelatorio:nFontBody:=10
	oRelatorio:SetLineHeight(50)
	oRelatorio:SetLogo(cBmpLogo)
	oSecCab := TRSection():New( oRelatorio , "Cabec", /*aCab*/, , , , , , , .T.	 )

	For nI := 4 to Len(aHeaderUQG) - 2
		TRCell():New( oSecCab, AllTrim(aHeaderUQG[nI][2]), /*aCab*/, , , TAMSX3(aHeaderUQG[nI][2])[1] + 15, .F.,,,,,,,,,, .T.  )
	Next

	oSecPR := TRSection():New( oRelatorio , "Previsao", cAliasPR, , , , , , , .T.	 )
	If ValType(aHeaderUQH) != "A" //Valida se existe e cria a GetDados
		fGDProv()
	EndIf
	For nI := 1 to Len(oGDadUQH:aHeader) - 2
		TRCell():New( oSecPR, AllTrim(oGDadUQH:aHeader[nI][2]), cAliasPR, ,  , TAMSX3(oGDadUQH:aHeader[nI][2])[1] + 15, .F.,,"LEFT",,"LEFT")
	Next

	If ValType(aHeaderUQI) != "A" //Valida se existe e cria a GetDados
		fGDRend()
	EndIf
	oSecRD := TRSection():New( oRelatorio , "Rendicao", cAliasRD, , , , , , , .T.	 )
	For nI := 1 to Len(aHeaderUQI) - 2
		TRCell():New( oSecRD, AllTrim(aHeaderUQI[nI][2]), cAliasRD, ,  , TAMSX3(aHeaderUQI[nI][2])[1] + 15, .F.,,"LEFT",,"LEFT")
	Next

	oSecCab:SetHeaderSection( .T. )
	TRFunction():New(oSecCab:Cell("UQG_IDIMP"),/*cId*/,"COUNT", /*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/, .F., .T., .F., oSecCab)

	// Define o Título do reltório
	oRelatorio:SetTitle( cTitulo )

	// Define os parâmetros de configuração (perguntas) do relatório
	oRelatorio:SetParam( nomePrt )

	// Define o bloco de código que será executado na confirmação da impressão
	oRelatorio:SetAction( bAction )

	// Define a orientação da impressão do relatório
	oRelatorio:SetLandScape()

	// Define o tamanho do papel para landscape
	oRelatorio:oPage:SetPaperSize( DMPAPER_A4 )

	// Define o nome do arquivo temporário utilizado para a impressão do relatório
	oRelatorio:SetFile( cArquivo )

	// Define a Descrição do Relatório
	oRelatorio:SetDescription( CAT545077 )	// "Esta rotina imprime Arq. de Importação"

	// Desabilita o cabeçalho padrão do TReport
	oRelatorio:lHeaderVisible := .T.

	// Desabilita o rodapé padrão do TReport
	oRelatorio:lFooterVisible := .F.

	oRelatorio:Preview()

Return oRelatorio

/*/{Protheus.doc} fImpPR
Retorna todos os itens da Previsão atual
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return oSecCab:Cell("UQG_IDIMP"), ${return_description}
@param oRelatorio, object, descricao
@param cAliasPR, characters, descricao
@type function
/*/
Static Function fImpPR(oRelatorio, cAliasPR)

	Local cQuery := ""
	Local cIdUQG:= oSecCab:Cell("UQG_IDIMP")

	cIdUQG 	 := cIdUQG:GetText()

	// Define a query para pesquisa dos arquivos.
	cQuery  += "SELECT  UQH.UQH_ITEM, UQH.UQH_CHAVE, UQH.UQH_CONTAB, UQH.UQH_TOTAL,"           				+ CRLF
	cQuery  += "        UQH.UQH_CCUSTO, UQH.UQH_LOTE, UQH.UQH_SBLOTE,"							            + CRLF
	cQuery  += "        UQH.UQH_DOC, UQH.UQH_LINHA, UQH.R_E_C_N_O_ RECNOUQH"								+ CRLF
	cQuery  += "FROM    " + RetSqlName("UQH") + " AS UQH "                                              + CRLF
	cQuery  += "WHERE   UQH.UQH_FILIAL = '"	+ xFilial("UQH") + "' "                                     + CRLF
	cQuery	+= "AND		UQH.UQH_IDIMP = '"	+ Alltrim(cIdUQG) + "' "									+ CRLF
	cQuery  += "AND     UQH.D_E_L_E_T_ <> '*' "                                                         + CRLF

	MPSysOpenQuery( cQuery, cAliasPR)

Return oSecCab:Cell("UQG_IDIMP")

/*/{Protheus.doc} fImpRD
Retorna todos os itens da Rendição atual
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return oSecCab:Cell("UQG_IDIMP"), ${return_description}
@param oRelatorio, object, descricao
@param cAliasRD, characters, descricao
@type function
/*/
Static Function fImpRD(oRelatorio, cAliasRD )
	Local cQuery := ""
	Local cIdUQG:= oSecCab:Cell("UQG_IDIMP")

	cIdUQG 	 := cIdUQG:GetText()

	// Define a query para pesquisa dos arquivos.
		cQuery	+= "SELECT	UQI.UQI_FILIAL, UQI.UQI_IDIMP, UQI.UQI_REF, UQI.UQI_ITEM, UQI.UQI_CHAVE, UQI.UQI_CONTAB, UQI.UQI_INDGL, "	+ CRLF
		cQuery	+= "		UQI.UQI_TOTAL, UQI.UQI_LCLNEG, UQI.UQI_VENC, UQI.UQI_CONDPA, UQI.UQI_ASSGN, UQI.UQI_ITMTEX, "			+ CRLF
		cQuery	+= "		UQI.UQI_CONMAS, UQI.UQI_ESCVEN, UQI.UQI_DIV, UQI.UQI_CCUSTO, UQI.UQI_LOTE, UQI.UQI_SBLOTE, UQI.UQI_LINHA,"	+ CRLF
		cQuery	+= "		UQI.UQI_DOC, UQI.UQI_TRANSP, UQI.UQI_PREFIX, UQI.UQI_NUM, UQI.UQI_PARCEL, UQI.R_E_C_N_O_ RECNOUQI "	+ CRLF
		cQuery	+= "FROM	" + RetSqlName("UQI") + " UQI "																		+ CRLF
		cQuery	+= "WHERE	UQI.UQI_FILIAL = '" 		+ xFilial("UQI") 	+ "' "													+ CRLF
		cQuery	+= "AND		UQI.UQI_IDIMP = '" 		+ AllTrim(cIdUQG)	+ "' "													+ CRLF
		cQuery	+= "AND		UQI.D_E_L_E_T_ <> '*' "																				+ CRLF

	MPSysOpenQuery( cQuery, cAliasRD)

Return oSecCab:Cell("UQG_IDIMP")

/*/{Protheus.doc} PrintReport
//Imprime o Relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return Nil, Nulo
@param oRelatorio, object, descricao
@param aUQG, array, descricao
@param cAliasPR, characters, descricao
@param cAliasRD, characters, descricao
@type function
/*/
Static Function PrintReport( oRelatorio, aUQG, cAliasPR, cAliasRD )

	Local nI			:= 0
	Local nJ			:= 0
	Local nPos 			:= 0
	Local nPsUQGFilial	:= GdFieldPos("UQG_FILIAL", oGDadUQG:aHeader)

 	For nI:= 1 to Len(aUQG)
		If (nPos := AScan(aFiliais, {|x| x[2] == aUQG[nI,nPsUQGFilial]})) > 0
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])

			// Incrementa a régua de progressão do relatório
			oRelatorio:IncMeter()

			oSecCab:Init(.T.)
			For nJ := 4 to Len(aUQG[nI]) - 3 //Alias_WT + Recno + Flag de delete
				oSecCab:Cell(AllTrim(aHeaderUQG[nJ][2])):SetValue(aUQG[nI][nJ])
			Next

			oSecCab:PrintLine()
			If AllTrim(oSecCab:Cell("UQG_TIPO"):GetValue()) == "PR"
				oSecPR:Init()
				fImpPR(oRelatorio, cAliasPR)
				While !(cAliasPR)->(EoF())
					oSecPR:PrintLine()
					(cAliasPR)->(DbSkip())
				EndDo
				//finalizo a segunda seção para que seja reiniciada para o proximo registro
				oSecPR:Finish()

			Else
				oSecRD:Init()
				fImpRD(oRelatorio, cAliasRD)
				While !(cAliasRD)->(EoF())
					oSecRD:PrintLine()
					(cAliasRD)->(DbSkip())
				EndDo
				//finalizo a segunda seção para que seja reiniciada para o proximo registro
				oSecRD:Finish()
			EndIf

			oSecCab:Finish()
			//imprimo uma linha para separar um arquivo do outro
			oRelatorio:ThinLine()
			oRelatorio:SkipLine()
		EndIf
	Next nI

	oRelatorio:ThinLine()
	//finalizo a primeira seção
	oSecCab:Finish()
	oSecPR:Finish()
	oSecRD:Finish()
Return (Nil)

/*/{Protheus.doc} fContaPagar
Visualização de Conta a Pagar do registro posicionado.
@author Icaro Laudade
@since 18/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fContaPagar()

	Local aArea			:=	GetArea()
	Local aTipoFin		:=	{"21", "31"}
	Local aAreaUQG		:=	UQG->(GetArea())
	Local aAreaSE2		:=	SE2->(GetArea())
	Local cContPagar	:=	Space( TamSX3("E2_NUM")[1] )
	Local cParcela		:=	Space( TamSX3("E2_PARCELA")[1] )
	Local cPrefixo		:=	Space( TamSX3("E2_PREFIXO")[1] )
	Local cTipo			:=	Space( TamSX3("E2_TIPO")[1] )
	Local cTransp		:=	Space( TamSX3("E2_FORNECE")[1] )
	Local cCadOld		:=	cCadastro
	//Local lOK			:=	.T.
	Local nPsIdImp		:=	aScan(oGDadUQG:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQG_IDIMP"  })
	Local nPsChave		:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_CHAVE"  })
	Local nPsNumTit		:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_NUM"    })
	Local nPsParcela	:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_PARCEL" })
	Local nPsPrefixo	:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_PREFIX" })
	Local nPsTipo		:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_TIPO"   })
	Local nPsTransp		:=	aScan(oGDadUQI:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQI_TRANSP" })

	Private aRotina		:=	StaticCall(FINA050, MenuDef)

	ProcRegua(0)

	If nPsNumTit > 0
		cContPagar := oGDadUQI:aCols[oGDadUQI:nAt,nPsNumTit]
	EndIf

	If nPsParcela > 0
		cParcela := oGDadUQI:aCols[oGDadUQI:nAt,nPsParcela]
	EndIf

	If nPsPrefixo > 0
		cPrefixo := oGDadUQI:aCols[oGDadUQI:nAt,nPsPrefixo]
	EndIf

	If nPsTipo > 0
		cTipo := oGDadUQI:aCols[oGDadUQI:nAt,nPsTipo]
	EndIf

	If nPsTransp > 0
		cTransp := oGDadUQI:aCols[oGDadUQI:nAt,nPsTransp]
	EndIf

	If nPsChave > 0 .And. aScan(aTipoFin, oGDadUQI:aCols[oGDadUQI:nAt, nPsChave]) > 0
		DbSelectArea("UQG")
		UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
		If UQG->( DbSeek(xFilial("UQG") + oGDadUQG:aCols[oGDadUQG:nAt,nPsIdImp]) )
			If UQG->UQG_STATUS == "P" // Integrado
				If AllTrim(UQG->UQG_TIPO) $ ".RD.A." // Rendição ou Adiantamento
					DbSelectArea("SE2")
					SE2->(DbSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
					If SE2->(DbSeek(xFilial("SE2") + cPrefixo + cContPagar + cParcela + IIf(!Empty(cTipo) .And. !Empty(cTransp), cTipo + cTransp, "") ))

						cCadastro := CAT545078 // "Contas a Pagar - VISUALIZAR"

						IncProc(CAT545079) // "Preparando dados para apresentação..."
						//FA050Visua( "SE2", SE2->(Recno()), 2 )
						fE2Visual( "SE2", SE2->(Recno()), 2 )

					Else
						MsgAlert(CAT545080, cCadastro) // "Titulo não localizado."
					EndIf
				Else
					MsgAlert(CAT545081, cCadastro) // "Arquivo selecionado não é uma rendição."
				EndIf
			Else
				MsgAlert(CAT545082, cCadastro) // "Arquivo não integrado ao Protheus."
			EndIf
		Else
			MsgAlert(CAT545083, cCadastro) // "Nenhum registro encontrado."
		EndIf
	Else
		MsgAlert(CAT545084, cCadastro) // "Registro selecionado não corresponde a uma Conta a Pagar."
	EndIf

	cCadastro := cCadOld

	RestArea(aAreaSE2)
	RestArea(aAreaUQG)
	RestArea(aArea)

Return (Nil)

/*/{Protheus.doc} fE2Visual
Adaptação da função padrão FA050Visua para visualização de SE2 - Contas a Pagar
@author Icaro Laudade
@since 18/01/2019
@return Nil, Nulo
@param cAlias, characters, Alias da tabela
@param nReg, numeric, Recno
@param nOpc, numeric, Número da opção
@type function
/*/
Static Function fE2Visual( cAlias,nReg,nOpc )
	Local nOpcA
	Local aBut050
	Local lF050VIS := Existblock("F050VIS")
	Local lIntSJURI  := SuperGetMV("MV_JURXFIN",,.F.) //Integração com SIGAPFS

	Private aRatAFR		:= {}
	Private bPMSDlgFI	:= {||PmsDlgFI(2,M->E2_PREFIXO,M->E2_NUM,M->E2_PARCELA,M->E2_TIPO,M->E2_FORNECE,M->E2_LOJA)}
	Private _Opc 		:= nOpc
	Private aSE2FI2		:=	{} // Utilizada para gravacao das justificativas
	Private aCposAlter  :=  {}

	DbSelectArea("SA2")
	SA2->(DbSeek(cFilial+SE2->E2_FORNECE+SE2->E2_LOJA))

	//Botoes adicionais na EnchoiceBar
	aBut050 := fa050BAR('SE2->E2_PROJPMS == "1"')

	///Projeto
	//inclusao do botao Posicao
	AADD(aBut050, {"HISTORIC", {|| Fc050Con() }, CAT545085}) //"Posicao"

	//inclusao do botao Rastreamento
	AADD(aBut050, {"HISTORIC", {|| Fin250Pag(2) }, CAT545086}) //"Rastreamento"

	If lIntSJURI .And. FindFunction("JURA246")
		Aadd(aBut050,{"", {|| JURA246(1) }, CAT545087}) //"Detalhe / Desdobramentos" (Módulo SIGAPFS)
	EndIf

	// integração com o PMS
	If IntePMS() .And. SE2->E2_PROJPMS == "1"
		SetKey(VK_F10, {|| Eval(bPMSDlgFI)})
	EndIf

	DbSelectArea(cAlias)
	//RegToMemory("SE2",.T.,,.F.,FunName())
	nOpca := AxVisual(cAlias,nReg,nOpc,,4,SA2->A2_NOME,"FA050MCPOS",aBut050)

	If lF050VIS		// ponto na saida da visualizacao
		Execblock("F050VIS",.f.,.f.)
	Endif

	If IntePMS() .And. SE2->E2_PROJPMS == "1"
		SetKey(VK_F10, Nil)
	EndIf

	If SM0->M0_CODIGO == "01"
		F986LimpaVar() //Limpa as variaveis estaticas - Complemento de Titulo
	EndIf

Return(Nil)

/*/{Protheus.doc} fLancCTB
Visualização do lançamento contábil do registro posicionado.
@author Kevin Willians
@since 18/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fLancCTB()

	Local aCol		:= {} // array com as posições necessárias para o DbSeek na CT2
	Local aSeek		:= {}
	Local aTipos	:= {"39","40","50","60"}
	Local cChave	:= ""
	Local nCol		:= AScan(aHeaderUQG, {|x| AllTrim(x[2]) == "UQG_TIPO" })
	Local nLin		:= oGDadUQG:nAt	// Linha da Getdados Selecionada para carregar o Lanc. Contábil
	Local nRecno	:= 0

	cChave	:= oGDadUQG:aCols[nLin][nCol] //UQG_TIPO PR RD A
 	If oGDadUQG:aCols[nLin][2]:cName == "BR_VERDE"//Verifica se arquivo já foi processado P através da legenda
		If AllTrim(cChave) == "RD" .Or. AllTrim(cChave) == "A"
			nLin	:= oGDadUQI:nAt
			nCol	:= AScan(aHeaderUQI, {|x| AllTrim(x[2]) == "UQI_CHAVE" })
			cChave	:= oGDadUQI:aCols[nLin][nCol] //UQI_CHAVE 40 50 60

			If aScan(aTipos, AllTrim(cChave)) > 0

				aAdd(aCol, AScan(aHeaderUQG, {|x| AllTrim(x[2]) == "UQG_DTDOC" 	}))
				aAdd(aCol, AScan(aHeaderUQI, {|x| AllTrim(x[2]) == "UQI_LOTE" 	}))
				aAdd(aCol, AScan(aHeaderUQI, {|x| AllTrim(x[2]) == "UQI_SBLOTE" 	}))
				aAdd(aCol, AScan(aHeaderUQI, {|x| AllTrim(x[2]) == "UQI_DOC" 	}))
				aAdd(aCol, AScan(aHeaderUQI, {|x| AllTrim(x[2]) == "UQI_LINHA" 	}))

				aAdd(aSeek, oGDadUQG:aCols[oGDadUQG:nAt] [ aCol[1] ])
				aAdd(aSeek, oGDadUQI:aCols[nLin][aCol[2]])
				aAdd(aSeek, oGDadUQI:aCols[nLin][aCol[3]])
				aAdd(aSeek, oGDadUQI:aCols[nLin][aCol[4]])
				aAdd(aSeek, oGDadUQI:aCols[nLin][aCol[5]])

				DbSelectArea("CT2")
				CT2->(DbSetOrder(1)) // CT2_FILIAL+DTOS(CT2_DATA)+CT2_LOTE+CT2_SBLOTE+CT2_DOC+CT2_LINHA+CT2_TPSALD+CT2_EMPORI+CT2_FILORI+CT2_MOEDLC
				If CT2->(DbSeek(xFilial("CT2")+ dToS(aSeek[1]) + aSeek[2] + aSeek[3] + aSeek[4] + aSeek[5]))
					nRecno := CT2->(RecNo())
					CTBA101(2, nRecno )//(nCallOpcx, nRec, cTab)
				Else
					Alert(CAT545088) // "Lançamento contábil não encontrado"
				EndIf
				CT2->(DbCloseArea())
			Else
				Alert(CAT545089)// "Registro selecionado não corresponde a um lançamento contábil"
			EndIf

		Else //"PR"
			nLin	:= oGDadUQH:nAt
			nCol	:= AScan(aHeaderUQH, {|x| AllTrim(x[2]) == "UQH_CHAVE" })
			cChave	:= oGDadUQH:aCols[nLin][nCol] //UQH_CHAVE 40 50 60
			aAdd(aCol, AScan(aHeaderUQG, {|x| AllTrim(x[2]) == "UQG_DTDOC" 	}))
			aAdd(aCol, AScan(aHeaderUQH, {|x| AllTrim(x[2]) == "UQH_LOTE" 	}))
			aAdd(aCol, AScan(aHeaderUQH, {|x| AllTrim(x[2]) == "UQH_SBLOTE" 	}))
			aAdd(aCol, AScan(aHeaderUQH, {|x| AllTrim(x[2]) == "UQH_DOC" 	}))
			aAdd(aCol, AScan(aHeaderUQH, {|x| AllTrim(x[2]) == "UQH_LINHA" 	}))

			aAdd(aSeek, oGDadUQG:aCols[oGDadUQG:nAt][aCol[1]])
			aAdd(aSeek, PadR(oGDadUQH:aCols[nLin][aCol[2]], TamSX3("UQH_LOTE")[1]))
			aAdd(aSeek, PadR(oGDadUQH:aCols[nLin][aCol[3]], TamSX3("UQH_SBLOTE")[1]))
			aAdd(aSeek, PadR(oGDadUQH:aCols[nLin][aCol[4]], TamSX3("UQH_DOC")[1]))
			aAdd(aSeek, PadR(oGDadUQH:aCols[nLin][aCol[5]], TamSX3("UQH_LINHA")[1]))

			DbSelectArea("CT2")
			CT2->(DbSetOrder(1)) // CT2_FILIAL+DTOS(CT2_DATA)+CT2_LOTE+CT2_SBLOTE+CT2_DOC+CT2_LINHA+CT2_TPSALD+CT2_EMPORI+CT2_FILORI+CT2_MOEDLC
			If CT2->(DbSeek(xFilial("CT2") + dToS(aSeek[1]) + aSeek[2] + aSeek[3] + aSeek[4] + aSeek[5]))
				nRecno := CT2->(RecNo())
				CTBA101(2, nRecno )//(nCallOpcx, nRec, cTab)
			Else
				Alert(CAT545088) // "Lançamento Contabil não encontrado"
			EndIf
			CT2->(DbCloseArea())
		EndIf

	Else
		Alert(CAT545090) // "Arquivo não Integrado ao Protheus, portanto sem Lançamentos Contábeis encontrados"
	EndIf

Return

/*/{Protheus.doc} fProxLote
Define o próximo número de lote disponível.
@author Paulo Carvalho
@since 22/01/2019
@return cNumero, carácter, próximo número disponível não utilizado.
@type function
/*/
Static Function fProxLote()
	Local cNumero	:= SuperGetMV( "PLG_LOTCTR", .F., "PLG001")

	//Comentado por solicitação Marcos dia 28/05/2019
	/*Local aArea		:= GetArea()
	Local aAreaCT2	:= CT2->(GetArea())

	Local cAliasQry	:= GetNextAlias()
	Local cQuery	:= ""

	// Busca o último lote cadastrado na tabela CT2
	cQuery	+= "SELECT	MAX(CT2_LOTE) AS CT2_LTMAX  "						+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("CT2") 	+ " "						+ CRLF
	cQuery	+= "WHERE	CT2_FILIAL = '" 		+ xFilial("CT2") + "'  "	+ CRLF
	cQuery	+= "AND 	D_E_L_E_T_ <> '*' "									+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		cNumero := Soma1((cAliasQry)->CT2_LTMAX)

		DbSelectArea("CT2")
		CT2->(DbSetOrder(17))
		CT2->(DbGoTop())

		While CT2->(DbSeek(xFilial("CT2") + cNumero))
			ConfirmSX8()
			cNumero := GetSXENum("CT2", "CT2_LOTE", , 17)
		EndDo

		CT2->(DbCloseArea())
	EndIf

	(cAliasQry)->(DbCloseArea())
	RestArea(aAreaCT2)
	RestArea(aArea)*/

Return cNumero

/*/{Protheus.doc} fGetRefAnt
Retorna os arquivos de referência anteriores ao IdImp passado por parâmetro.
@author Juliano Fernandes
@since 22/02/2019
@return aVerRepAnt, array, Array contendo as versões anteriores não integradas
@type function
/*/
Static Function fGetRefAnt(cIdImp)
	Local aAreas		:= {}
	Local aVerRepAnt 	:= {}
	Local cVerRep 		:= ""
	Local cRef 			:= ""
	Local nI 			:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQG->(GetArea()))

	DbSelectArea("UQG")
	UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
	If UQG->(DbSeek(xFilial("UQG") + cIdImp))
		cRef	:= UQG->UQG_REF
		cVerRep	:= UQG->UQG_VERREP

		DbSelectArea("UQG")
		UQG->(DbSetOrder(2))	// UQG_FILIAL + UQG_REF + UQG_TPTRAN + UQG_VERREP
		If UQG->(DbSeek(xFilial("UQG") + cRef))
			While !UQG->(EoF()) .And. UQG->UQG_FILIAL == xFilial("UQG") .And. UQG->UQG_REF == cRef
				If UQG->UQG_STATUS != "C" .And. UQG->UQG_IDIMP != cIdImp .And. UQG->UQG_VERREP < cVerRep
					Aadd(aVerRepAnt, UQG->UQG_IDIMP)
				EndIf

				UQG->(DbSkip())
			EndDo
		EndIf
	EndIf

	For nI := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nI])
	Next nI
Return(aVerRepAnt)

/*/{Protheus.doc} fTitLot
Retorna os Ids de Importação que possuem o título e Lote passados nos filtros
@author Kevin Willians
@since 08/03/2019
@return aIdImp, caracter, String concatenando os Ids (ex: "001,002,003")
@type function
/*/
Static Function fTitLot()
	Local aIdImp	:=	{}
	Local aLotes	:=	{}
	Local aTitulos	:=	{}
	Local cAliLotUQH	:=	GetNextAlias()
	Local cAliLotUQI :=  GetNextAlias()
	Local cAliasTit	:=	GetNextAlias()
	Local cQryLotUQH	:=	""
	Local cQryLotUQI :=	""
	Local cQryTit	:=	""
	Local nI		:=	0
	Local nJ		:=	0
	Local nPosIdImp :=	0
	Local nPosLote	:=	0
	Local nPosTitu	:=	0

	If  !Empty(cGLoteDe) .Or. !Empty(cGLoteAte)
		//UQH-PR
		cQryLotUQH := " SELECT DISTINCT UQG.UQG_IDIMP "								+ CRLF
		cQryLotUQH += " FROM " + RetSQLName("UQG") + " UQG " 						+ CRLF
		cQryLotUQH += " INNER JOIN " + RetSQLName("UQH") + " UQH "					+ CRLF
		cQryLotUQH += " 	ON  UQH.UQH_FILIAL = '" + xFilial("UQH") + "' "				+ CRLF
		cQryLotUQH += "	AND UQG.UQG_IDIMP = UQH.UQH_IDIMP"							+ CRLF

		If !Empty(cGLoteDe)
			cQryLotUQH += "	AND	UQH.UQH_LOTE >= '" + AllTrim(cGLoteDe)	+ "' "		+ CRLF
		EndIf

		If !Empty(cGLoteAte)
			cQryLotUQH += "	AND	UQH.UQH_LOTE <= '" + AllTrim(cGLoteAte)	+ "' "		+ CRLF
		EndIf

		cQryLotUQH += "	AND UQH.D_E_L_E_T_ <> '*' "									+ CRLF
		cQryLotUQH += " WHERE UQG.UQG_FILIAL = '" + xFilial("UQG") + "' "				+ CRLF
		cQryLotUQH += "   AND UQG.D_E_L_E_T_ <> '*' "								+ CRLF

		MPSysOpenQuery(cQryLotUQH, cAliLotUQH)

		While !(cAliLotUQH)->(Eof())
			nPosLote := aScan(aLotes, (cAliLotUQH)->UQG_IDIMP)

			If nPosLote == 0
				aAdd( aLotes, (cAliLotUQH)->UQG_IDIMP)
			EndIf

			(cAliLotUQH)->(DbSkip())
		EndDo

		(cAliLotUQH)->(DbCloseArea())
		//Os IDs Imps SEMPRE serão diferentes.

		//UQI-RD
		cQryLotUQI := " SELECT DISTINCT UQG.UQG_IDIMP "								+ CRLF
		cQryLotUQI += " FROM " + RetSQLName("UQG") + " UQG " 						+ CRLF
		cQryLotUQI += " INNER JOIN " + RetSQLName("UQI") + " UQI "					+ CRLF
		cQryLotUQI += "    ON UQI.UQI_FILIAL = '" + xFilial("UQI") + "' "				+ CRLF
		cQryLotUQI += " 	 AND UQG.UQG_IDIMP = UQI.UQI_IDIMP "							+ CRLF

		If !Empty(cGLoteDe)
			cQryLotUQI += "	AND	UQI.UQI_LOTE >= '" + AllTrim(cGLoteDe) + "' "		+ CRLF
		EndIf

		If !Empty(cGLoteAte)
			cQryLotUQI += "	AND	UQI.UQI_LOTE <= '" + AllTrim(cGLoteAte) + "' "		+ CRLF
		EndIf

		cQryLotUQI += "   AND UQI.D_E_L_E_T_ <> '*' " 								+ CRLF
		cQryLotUQI += " WHERE UQG.UQG_FILIAL = '" + xFilial("UQG") + "' "				+ CRLF
		cQryLotUQI += "   AND UQG.D_E_L_E_T_ <> '*' "								+ CRLF

		MpSysOpenQuery(cQryLotUQI, cAliLotUQI)

		While !(cAliLotUQI)->(Eof())
			nPosLote := aScan(aLotes, (cAliLotUQI)->UQG_IDIMP)

			If nPosLote == 0
				aAdd( aLotes, (cAliLotUQI)->UQG_IDIMP)
			EndIf

			(cAliLotUQI)->(DbSkip())
		EndDo

		(cAliLotUQI)->(DbCloseArea())
	EndIf

	If !Empty(cGNTitDe) .Or. !Empty(cGNTitAte)
		//UQI-RD
		cQryTit	+= " SELECT DISTINCT UQG.UQG_IDIMP " 																+ CRLF
		cQryTit += " FROM " + RetSQLName("UQG") + " UQG "				 											+ CRLF
		cQryTit	+= " INNER JOIN " + RetSQLName("UQI") + " UQI "														+ CRLF
		cQryTit	+= " 	ON  UQI.UQI_FILIAL = '" + xFilial("UQI") + "' "												+ CRLF
		cQryTit	+= " 	AND UQG.UQG_IDIMP = UQI.UQI_IDIMP "															+ CRLF

		If !Empty(cGNTitDe)
			cQryTit	+= " 	AND	UQI.UQI_NUM >= '" + AllTrim(cGNTitDe)  + "' "										+ CRLF
		EndIf

		If !Empty(cGNTitAte)
			cQryTit += " 	AND	UQI.UQI_NUM <= '" + AllTrim(cGNTitAte) + "' "										+ CRLF
		EndIf

		cQryTit	+= " 	AND UQI.D_E_L_E_T_ <> '*' "																	+ CRLF
		cQryTit += " WHERE UQG.UQG_FILIAL = '" + xFilial("UQG") + "' "												+ CRLF
		cQryTit += "   AND UQG.D_E_L_E_T_ <> '*' "																	+ CRLF

		MPSysOpenQuery(cQryTit, cAliasTit)

		While !(cAliasTit)->(Eof())

			nPosTitu := aScan(aTitulos, (cAliasTit)->UQG_IDIMP)

			If nPosTitu == 0
				aAdd( aTitulos, (cAliasTit)->UQG_IDIMP)
			EndIf

			(cAliasTit)->(DbSkip())
		EndDo

		(cAliasTit)->(DbCloseArea())
	EndIf

	If (!Empty(cGLoteDe) .Or. !Empty(cGLoteAte)) .And. (!Empty(cGNTitDe) .Or. !Empty(cGNTitAte))  // Caso de ao menos um lote
	 																						 	  // e titulo ter sido passado
		If !Empty(aLotes) .And. !Empty(aTitulos)

			For nI := 1 To Len(aLotes)
				For nJ := 1 To Len(aTitulos)
					If aLotes[nI] == aTitulos[nJ]

						nPosIdImp := aScan(aIdImp, aLotes[nI])

						If nPosIdImp == 0
							aAdd( aIdImp, aLotes[nI] )
						EndIf

						Loop
					EndIf
				Next nJ
			Next nI

			If Empty(aIdImp)
				aAdd(aIdImp, "") //Indica que nada foi encontrado. Usado para o In da query que utiliza o retorno dessa função não retornar nada
			EndIf

		Else
			aAdd( aIdImp, "" ) //Indica que nada foi encontrado. Usado para o In da query que utiliza o retorno dessa função não retornar nada.
		EndIf

	ElseIf (!Empty(cGLoteDe) .Or. !Empty(cGLoteAte)) .And. Empty(cGNTitDe) .And. Empty(cGNTitAte)  //Apenas o filtro de lote

		If !Empty(aLotes)

			For nI := 1 To Len(aLotes)
				aAdd( aIdImp, aLotes[nI] )
			Next

		Else
			aAdd( aIdImp, "" ) //Indica que nada foi encontrado. Usado para o In da query que utiliza o retorno dessa função não retornar nada.
		EndIf

	ElseIf (!Empty(cGNTitDe) .Or. !Empty(cGNTitAte)) .And. Empty(cGLoteDe) .And. Empty(cGLoteAte) //Apenas o filtro de titulo
		If !Empty(aTitulos)

			For nI := 1 To Len(aTitulos)
				aAdd( aIdImp, aTitulos[nI] )
			Next nI

		Else
			aAdd( aIdImp, "") //Indica que nada foi encontrado. Usado para o In da query que utiliza o retorno dessa função não retornar nada.
		EndIf
	EndIf

Return aIdImp

/*/{Protheus.doc} fDefMoeda
Define o código da moeda no sistema de acordo com a sigla informada no arquivo importado.
@author Paulo Carvalho
@since 21/03/2019
@param cMoedaArq, carácter, Sigla da moeda informada no arquivo importado.
@return cMoeda, carácter, Código da moeda.
@type function
/*/
Static Function fDefMoeda(cMoedaArq)

	Local aArea		:= GetArea()
	Local aAreaUQN	:= UQN->(GetArea())

	Local cMoeda	:= "1"

	// Verifica se cMoedaArq não está vázio
	If !Empty(cMoedaArq)
		DbSelectArea("UQN")
		UQN->(DbSetOrder(1))	// UQN_FILIAL + UQN_MOEDAR

		If UQN->(DbSeek(FWxFilial("UQN") + cMoedaArq))
			cMoeda 	:= "0" + cValToChar(UQN->UQN_CODIGO)
		EndIf
	EndIf

	RestArea(aAreaUQN)
	RestArea(aArea)

Return cMoeda

/*/{Protheus.doc} fFornAuton
Retorna se o fornecedor é autônomo.
@author Juliano Fernandes
@since 30/05/2019
@version 1.0
@return lAutonomo, Indica se o fornecedor é autônomo
@param cCod, caracter, Código do fornecedor
@param cLoja, caracter, Loja do fornecedor
@type function
/*/
Static Function fFornAuton(cCod, cLoja)

	Local aArea		:= GetArea()
	Local aAreaSA2	:= SA2->(GetArea())

	Local lAutonomo	:= .F.

	If !Empty(cCod)
		cCod := PadR(cCod, TamSX3("A2_COD")[1])

		If !Empty(cLoja)
			cLoja := PadR(cLoja, TamSX3("A2_LOJA")[1])
		EndIf

		DbSelectArea("SA2")
		SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
		If SA2->(DbSeek(xFilial("SA2") + cCod + cLoja))
			lAutonomo := SA2->A2_XAUTONO == "1" // Sim
		EndIf
	EndIf

	RestArea(aAreaSA2)
	RestArea(aArea)

Return(lAutonomo)

/*/{Protheus.doc} fGetCCusto
Retorna o centro de custo para a Rendição de arquivos CTRB.
@author Juliano Fernandes
@since 16/08/2019
@version 1.0
@return cCCusto, Centro de Custo
@param cIdImp, caracter, ID de Importação
@type function
/*/
Static Function fGetCCusto(cIdImp)

	Local cCCusto 	:= ""
	Local cQuery	:= ""
	Local cAliasQry	:= GetNextAlias()

	cQuery := " SELECT UQI_CCUSTO " 												+ CRLF
	cQuery += " FROM " + RetSQLName("UQI") 										+ CRLF
	cQuery += " WHERE UQI_FILIAL = '" + xFilial("UQI") + "' " 					+ CRLF
	cQuery += " 	AND UQI_IDIMP = '" + cIdImp + "' " 							+ CRLF
	cQuery += " 	AND UQI_CCUSTO <> '" + Space(TamSX3("UQI_CCUSTO")[1]) + "' " 	+ CRLF
	cQuery += " 	AND D_E_L_E_T_ <> '*' " 									+ CRLF

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

	If !(cAliasQry)->(EoF())
		cCCusto := (cAliasQry)->UQI_CCUSTO
	EndIf

	(cAliasQry)->(DbCloseArea())

Return(cCCusto)

/*/{Protheus.doc} fGetTipoTit
Retorna o tipo do título a pagar para o array do ExecAuto FINA050.
@author Juliano Fernandes
@since 19/08/2019
@version 1.0
@return cTipoTit, Tipo do título a pagar
@param cTipoArq, caracter, Tipo de arquivo que está sendo processado
@type function
/*/
Static Function fGetTipoTit(cTipoArq)

	Local cTipoTit := ""

	If !Empty(UQI->UQI_TIPO)
		cTipoTit := UQI->UQI_TIPO
	Else
		If AllTrim(cTipoArq) == "A"	// Adiantamento
			cTipoTit := "NDF"
		Else						// Provisão ou Rendição
			cTipoTit := "BOL"
		EndIf
	EndIf

	cTipoTit := PadR(cTipoTit, TamSX3("E2_TIPO")[1])

Return(cTipoTit)

/*/{Protheus.doc} fGetHistor
Retorna o histórico para a gravação no campo CT2_HIST ao integrar arquivos CTRB / CTRN.
@author Juliano Fernandes
@since 22/08/2019
@version 1.0
@return cHistorico, Histórico
@param cIdImp, caracter, ID de Importação
@type function
/*/
Static Function fGetHistor(cIdImp)

	Local cHistorico	:= ""
	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()

	cQuery := " SELECT UQG_REF, UQG_HDTEXT "						+ CRLF
	cQuery += " FROM " + RetSQLName("UQG") 						+ CRLF
	cQuery += " WHERE UQG_FILIAL = '" + xFilial("UQG") + "' "	+ CRLF
	cQuery += " 	AND UQG_IDIMP = '" + cIdImp + "' " 			+ CRLF
	cQuery += " 	AND D_E_L_E_T_ <> '*' " 					+ CRLF

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

	If !(cAliasQry)->(EoF())
		cHistorico := Left((cAliasQry)->UQG_REF, 4)		// CTRB ou CTRN
		cHistorico += Space(1)
		cHistorico += AllTrim((cAliasQry)->UQG_HDTEXT)	// Nome do fornecedor
		cHistorico += Space(1)
		cHistorico += SubStr((cAliasQry)->UQG_REF, 5)	// Numero do CTRB ou CTRN
	EndIf

	(cAliasQry)->(DbCloseArea())

Return(cHistorico)

/*/{Protheus.doc} fGetInfoTit
Retorna informações para a geração do título a pagar conforme as regras da Veloce.
@author Juliano Fernandes
@since 27/08/2019
@version 1.0
@param cFornec, caracter, Código do fornecedor
@param cLoja, caracter, Loja do fornecedor
@param cProduto, caracter, Produto
@param cTpFrete, caracter, Tipo de Frete
@param cTpArq, caracter, Tipo de arquivo
@param cPrefixo, caracter, Prefixo do título que será gerado
@param cNumTitulo, caracter, Número do título que será gerado
@param aTitulos, array, Demais titulos que serão gerados
@return aInfo, Array com indformações do título que será gerado
@type function
/*/
Static Function fGetInfoTit(cFornec, cLoja, cProduto, cTpFrete, cTpArq, cPrefixo, cNumTitulo, aTitulos)

	Local aAreas		:= {}

	Local cNatureza 	:= ""
	Local cTipo			:= ""
	Local cParcela		:= ""

	Local lParcelaOk	:= .F.

	Local nPsPrefixo	:= 0
	Local nPsNum		:= 0
	Local nPsParcela	:= 0
	Local nI			:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SA2->(GetArea()))
	Aadd(aAreas, SE2->(GetArea()))

	DbSelectArea("SA2")
	SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
	If SA2->(DbSeek(xFilial("SA2") + cFornec + cLoja))
		cNatureza := SA2->A2_NATUREZ
	EndIf

	cTipo := fGetTipoTit(cTpArq)

	// -------------------------------------------------------------
	// Verifica a parcela disponível para a geração do novo título
	// -------------------------------------------------------------
	cParcela := PadR(SuperGetMV("MV_1DUP",,"AA"), TamSX3("E2_PARCELA")[1])

	DbSelectArea("SE2")
	SE2->(DbSetOrder(1)) // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	While SE2->(DbSeek(xFilial("SE2") + cPrefixo + cNumTitulo + cParcela))
		cParcela := fIncParcela(cParcela)
	EndDo

	If !Empty(aTitulos)
		nPsPrefixo 	:= AScan(aTitulos[1,1], {|x| x[1] == "E2_PREFIXO"})
		nPsNum 		:= AScan(aTitulos[1,1], {|x| x[1] == "E2_NUM"    })
		nPsParcela 	:= AScan(aTitulos[1,1], {|x| x[1] == "E2_PARCELA"})

		While !lParcelaOk

			lParcelaOk := .T.

			For nI := 1 To Len(aTitulos)
				If aTitulos[nI,1,nPsPrefixo,2] == cPrefixo   .And. ;
				   aTitulos[nI,1,nPsNum    ,2] == cNumTitulo .And. ;
				   aTitulos[nI,1,nPsParcela,2] == cParcela

					cParcela := fIncParcela(cParcela)

					lParcelaOk := .F.

					Exit
				EndIf
			Next nI
		EndDo
	EndIf

	fRestAreas(aAreas)

Return({cNatureza, cTipo, cParcela})

/*/{Protheus.doc} fIncParcela
Função para o incremento do parcela do título.
@author Juliano Fernandes
@since 03/09/2019
@version 1.0
@return cParcela, Nova parcela (Valor incrementado)
@param cParcAtu, caracter, Parcela atual
@type function
/*/
Static Function fIncParcela(cParcAtu)

	Local cParcela := ""

	cParcela := AllTrim(cParcAtu)

	cParcela := Soma1(cParcela)

	cParcela := PadR(cParcela, TamSX3("E2_PARCELA")[1])

Return(cParcela)

/*/{Protheus.doc} fRestAreas
Executa o RestArea das áreas passadas no array.
@author Juliano Fernandes
@since 27/08/2019
@version 1.0
@param aAreas, array, Array com as areas geradas pela função GetArea()
@type function
/*/
Static Function fRestAreas(aAreas)

	Local nI := 0

	For nI := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nI])
	Next nI

Return(Nil)

/*/{Protheus.doc} fGetWorkArea
Obtém a WorkArea (todos os Alias abertos).
@author Juliano Fernandes
@since 23/09/2019
@version 1.0
@return aWorkArea, WorkArea (todos os Alias abertos)
@type function
/*/
Static Function fGetWorkArea()

	Local aArea		:= GetArea()
	Local aWorkArea	:= {}

	Local c545Alias	:= ""

	Local nAlias	:= 1

	DbSelectArea(nAlias)

	c545Alias := Alias()

	While !Empty(c545Alias)

		Aadd(aWorkArea, (c545Alias)->(GetArea()))

		nAlias++

		DbSelectArea(nAlias)

		c545Alias := Alias()

	EndDo

	RestArea(aArea)

Return(AClone(aWorkArea))

/*/{Protheus.doc} fRestWorkArea
Restaura a WorkArea (todos os Alias abertos) fechando os demais Alias que foram abertos posteriormente.
@author Juliano Fernandes
@since 23/09/2019
@version 1.0
@type function
/*/
Static Function fRestWorkArea()

	Local a545AliClo	:= {}

	Local c545Alias		:= ""

	Local nAlias		:= n545WrkAre
	Local nI			:= 0

	nAlias++

	DbSelectArea(nAlias)

	c545Alias := Alias()

	While !Empty(c545Alias)
		Aadd(a545AliClo, c545Alias)

		nAlias++

		DbSelectArea(nAlias)

		c545Alias := Alias()
	EndDo

	For nI := Len(a545AliClo) To 1 Step -1
		c545Alias := a545AliClo[nI]

		(c545Alias)->(DbCloseArea())
	Next nI

	RestArea( a545WrkAre[n545WrkAre] )

Return(Nil)

/*/{Protheus.doc} fClVlObrig
Retorna se a classe de valor é obrigatória no cadastro de Plano de Contas.
@author Juliano Fernandes
@since 09/01/2020
@version 1.0
@return lObrigat, Indica se a classe de valor é obrigatória
@param cContaCtb, caracter, Conta contábil que será analisada
@type function
/*/
Static Function fClVlObrig(cContaCtb)

	Local aArea := GetArea()

	Local lObrigat := .F.

	DbSelectArea("CT1")
	CT1->(DbSetOrder(1)) // CT1_FILIAL+CT1_CONTA
	If CT1->(DbSeek(xFilial("CT1") + cContaCtb))
		lObrigat := CT1->CT1_CLOBRG == "1" // 1=Sim;2=Nao
	EndIf

	RestArea(aArea)

Return(lObrigat)

/*/{Protheus.doc} fGetFornec
Retorna o código e loja do Fornecedor do registro que está sendo integrado.
@author Juliano Fernandes
@since 18/03/2020
@version 1.0
@return aFornecedor, Array contendo o código [1] e loja do fornecedor [2]
@param cIdImp, caracter, ID de Importação
@param cTipoReg, caracter, Tipo de registro que está sendo integrado (Provisão, Rendição ou Adto.)
@type function
/*/
Static Function fGetFornec(cIdImp, cTipoReg)

	Local aFornecedor	:= {"",""}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()

	Do Case
		Case (cTipoReg == "PR")

			cQuery := " SELECT DISTINCT "														+ CRLF
			cQuery += " 	CASE WHEN UQH_TRANSP <> ' ' THEN UQH_TRANSP ELSE UQH_ASSGN END COD, "	+ CRLF
			cQuery += " 	'' LOJA "															+ CRLF
			cQuery += " FROM " + RetSQLName("UQH") 												+ CRLF
			cQuery += " WHERE UQH_FILIAL = '" + xFilial("UQH") + "' "							+ CRLF
			cQuery += " 	AND UQH_IDIMP = '" + cIdImp + "' " 									+ CRLF
			cQuery += " 	AND (UQH_TRANSP <> ' ' OR UQH_ASSGN <> ' ') "							+ CRLF
			cQuery += " 	AND D_E_L_E_T_ <> '*' " 											+ CRLF

		Case (cTipoReg == "RD" .Or. cTipoReg == "A")

			cQuery := " SELECT DISTINCT "														+ CRLF
			cQuery += " 	UQI_TRANSP COD, UQI_LOJA LOJA "										+ CRLF
			cQuery += " FROM " + RetSQLName("UQI") 												+ CRLF
			cQuery += " WHERE UQI_FILIAL = '" + xFilial("UQI") + "' "							+ CRLF
			cQuery += " 	AND UQI_IDIMP = '" + cIdImp + "' " 									+ CRLF
			cQuery += " 	AND UQI_TRANSP <> ' ' "			 									+ CRLF
			cQuery += " 	AND D_E_L_E_T_ <> '*' " 											+ CRLF

	EndCase

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

	If !(cAliasQry)->(EoF())
		If !Empty((cAliasQry)->COD)
			aFornecedor[1] := PadR((cAliasQry)->COD , TamSX3("A2_COD")[1])
		EndIf

		If !Empty((cAliasQry)->LOJA)
			aFornecedor[2] := PadR((cAliasQry)->LOJA, TamSX3("A2_LOJA")[1])
		EndIf
	EndIf

	(cAliasQry)->(DbCloseArea())

Return(aFornecedor)

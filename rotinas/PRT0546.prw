#Include 'Totvs.ch'
#Include "CATTMS.ch"

// Variáveis Estáticas
Static NomePrt		:= "PRT0546"
Static VersaoJedi	:= "V1.05"

/*/{Protheus.doc} PRT0546
Programa para visualização dos detalhes dos arquivos CTE/CRT e CTRB.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type User Function
/*/
User Function PRT0546()

	Local aEncCab		:= {}
	Local aPosCab		:= {}

	Local bOk			:= {|| oDlgVis:End()}

	Local cAliasCab		:= ""
	Local cAliasDet		:= ""

	Local lPixel		:= .T.
	Local lTransparent	:= .T.

	Local nOpcao		:= 2
	Local nOrientacao	:= 1
	Local nRecno		:= 0

	Private	aHeaderVis	:= {}
	Private aPosDet		:= {}

	Private cCadastro	:= NomePrt + CAT546001 + VersaoJedi // " - Visualização de Detalhes - "

	Private lDeleted	:= .F.

    Private nTop		:= Nil
    Private nLeft		:= Nil
    Private nBottom		:= Nil
    Private nRight		:= Nil

	Private oDlgVis		:= Nil
	Private oEncCab		:= Nil
	Private oGetDet		:= Nil
	Private oPanCab		:= Nil
	Private oPanDet		:= Nil
	Private oSplitter	:= Nil

    Private oSizeVis    := Nil

	// Instancia o objeto para controle das coordenadas da aplicação
	oSizeVis	:= FWDefSize():New(.T.) // Indica que a tela terá EnchoiceBar

	// Define que os objetos não serão expostos lado a lado
	oSizeVis:lProp		:= .T.
	oSizeVis:lLateral	:= .F.

	// Adiciona ao objeto oSizeVis os objetos que irão compor a tela
	oSizeVis:AddObject( "ENCHOICE", 100, 050, .T., .T.  )
	oSizeVis:AddObject( "GETDADOS", 100, 050, .T., .T.  )

	// Realiza o cálculo das coordenadas
	oSizeVis:Process()

	// Define as coordenadas da Dialog principal
	nTop	:= oSizeVis:aWindSize[1]
	nLeft	:= oSizeVis:aWindSize[2]
	nBottom	:= oSizeVis:aWindSize[3]
	nRight	:= oSizeVis:aWindSize[4]

	// Define quais tabelas serão usadas para o cabeçalho e detalhes
	fDefAlias(@cAliasCab, @cAliasDet, @nRecno)

	// Instancia a classe MSDialog
	oDlgVis := MSDialog():New( 	nTop, nLeft, nBottom, nRight, cCadastro,;
								/*uParam6*/, /*uParam7*/, /*uParam8*/,;
								nOr( WS_VISIBLE, WS_POPUP ), /*nClrText*/, /*nClrBack*/,;
								/*uParam12*/, /*oWnd*/, lPixel, /*uParam15*/,;
								/*uParam16*/, /*uParam17*/, !lTransparent )

	// Cria os objetos da tela.
	oSplitter	:= TSplitter():New( 001, 001, oDlgVis, 260, 184, nOrientacao )

	oPanCab		:= TPanel():New( 000, 002,'',oSplitter,,,,, /*CLR_YELLOW*/, 100, 048 )
	oPanDet		:= TPanel():New( 000, 002,'',oSplitter,,,,, /*CLR_HRED  */, 100, 060 )

	aPosDet := 	{	oSizeVis:GetDimension("GETDADOS","LININI")		,;
					oSizeVis:GetDimension("GETDADOS","COLINI")		,;
					oSizeVis:GetDimension("GETDADOS","LINEND") + 15	,; // + 15 para compensar a falta da barra de título
					oSizeVis:GetDimension("GETDADOS","COLEND")		}

	// Define o posicionamento dos objetos da tela
	aPosCab := 	{	oSizeVis:GetDimension("ENCHOICE","LININI"),;
					oSizeVis:GetDimension("ENCHOICE","COLINI"),;
					oSizeVis:GetDimension("ENCHOICE","LINEND"),;
					oSizeVis:GetDimension("ENCHOICE","COLEND")}

	// Define os campos que irão compor a MsmGet
	aEncCab := fGeraAlt(cAliasCab)

	// Cria a MsmGet
	oEncCab := MsmGet():New(cAliasCab, /*nRecno*/, nOpcao,/*aCRA*/,/*cLetras*/,/*cTexto*/,aEncCab,aPosCab,{},;
							/*nModelo*/,/*nColMens*/,/*cMensagem*/, /*cTudoOk*/,oPanCab,/*lF3*/,/*lMemoria*/,/*lColumn*/,;
							/*caTela*/,/*lNoFolder*/,/*lProperty*/,/*aField*/,/*aFolder*/,/*lCreate*/,;
							/*lNoMDIStretch*/,/*cTela*/)

	// Alinha os objetos da tela
	oEncCab:oBox:Align 	:= CONTROL_ALIGN_ALLCLIENT
	oSplitter:Align		:= CONTROL_ALIGN_ALLCLIENT

	oPanCab:Align		:= CONTROL_ALIGN_TOP
	oPanDet:Align		:= CONTROL_ALIGN_BOTTOM

	// Cria a GetDados
	fGetDet(cAliasDet)

	oGetDet:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	oDlgVis:Activate( , , , .T., {|| .T.}, , EnchoiceBar(oDlgVis, bOk, bOk,,,,,.F.,.F.,.F.,.F., .F., ), , )

Return

/*/{Protheus.doc} fGetDet
Cria GetDados para apresentação dos itens de detalhes.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static User Function
/*/
Static Function fGetDet(cAliasDet)

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	Local aArray	:= {}
	Local aCampos	:= {}

	Local nA, nH, nI

	// Define os campos que irão compor a GetDados
	fAddCampo(@aCampos, cAliasDet)

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderVis, aCampos[nI] )
	Next

	For nA := 1 To Len( aHeaderVis )
		Aadd( aArray, CriaVar( aHeaderVis[nA][2], .T. ) )
    Next

	// Adiciona o Alias e o Recno
	AdHeadRec( cAliasDet, aHeaderVis )

	Aadd(aArray, cAliasDet	)	// Alias
	Aadd(aArray, 0			)	// Recno
	Aadd(aArray, .F.		)	// D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderVis)
	 	If Empty(aHeaderVis[nH][3]) .And. aHeaderVis[nH][8] == "C"
			aHeaderVis[nH][3] := "@!"
		EndIf
	Next

	// Instancia a GetDados
	oGetDet 	:= MsNewGetDados():New(	aPosDet[1], aPosDet[2], aPosDet[3], aPosDet[4], /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oPanDet, aHeaderVis, { aArray }, /*bChange*/, /*cTela*/	)

	// Impede a edição de linha
	oGetDet:SetEditLine(.F.)

	// Atualiza a GetDados
	oGetDet:Refresh()

	// Popula a GetDados de acordo com o Alias
	If "UQE" $ cAliasDet
		fFillUQE()
	ElseIf "UQH" $ cAliasDet
		fFillUQH()
	ElseIf "UQI" $ cAliasDet
		fFillUQI()
	Endif

	RestArea(aAreaSX3)
	RestArea(aArea)

Return

/*/{Protheus.doc} fFillUQE
Popula a get dados com itens dos arquivos CTE/CRT.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static User Function
/*/
Static Function fFillUQE()

	Local aDados		:= {}
	Local aLinha		:= {}
	Local aTcSetField	:= {}

	Local bQuebraLin	:= {|| Mod(nI, 5) == 0} // Quebra linha a cada 5 campos no Select

	Local cAliasQry		:= GetNextAlias()
	Local cIdImp		:= ""
	Local cQuery		:= ""
	Local cCampos		:= ""

	Local nI			:= 0

	For nI := 1 To Len(oGetDet:aHeader) - 2
		cCampos += "UQE." + AllTrim(oGetDet:aHeader[nI,2]) + ", "
		cCampos += IIf(EVal(bQuebraLin), CRLF, "")

		If oGetDet:aHeader[nI,8] $ "D|N"
			Aadd( aTCSetField, { oGetDet:aHeader[nI,2],oGetDet:aHeader[nI,8],oGetDet:aHeader[nI,4],oGetDet:aHeader[nI,5] })
		EndIf
	Next nI

	cCampos += "UQE.R_E_C_N_O_ AS UQE_RECNO "

	Aadd( aTCSetField, { "UQE_RECNO", "N", 17, 0 } )

	// Define o id de importação do arquivo selecionado para visualização
	cIdImp := oGetDadUQD:aCols[oGetDadUQD:nAt][GdFieldPos("UQD_IDIMP", aHeaderUQD)]

	// Define a query de pesquisa do item selecionado
	cQuery	+= "SELECT " + cCampos										+ CRLF
	cQuery	+= "FROM   " + RetSqlName("UQE") + " UQE "				+ CRLF
	cQuery	+= "WHERE  UQE.UQE_FILIAL = '"    + xFilial("UQE") + "' "	+ CRLF
	cQuery	+= "AND    UQE.UQE_IDIMP = '"     + cIdImp         + "' "	+ CRLF
	cQuery	+= "AND    UQE.D_E_L_E_T_ <> '*' "							+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	ProcRegua(0)

	While !(cAliasQry)->(Eof())
		IncProc()

		// Reinicia a linha
		aLinha := {}

		// Adiciona os dados da linha
		For nI := 1 To Len(oGetDet:aHeader) - 2
			Aadd( aLinha, (cAliasQry)->&(oGetDet:aHeader[nI,2]) )
		Next nI

		Aadd( aLinha, "UQE"						)
		Aadd( aLinha, (cAliasQry)->UQE_RECNO		)
		Aadd( aLinha, lDeleted					)

		// Adiciona a linha ao array de Dados
		Aadd( aDados, aLinha )

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	// Adiciona os dados à aCols da GetDados
	oGetDet:SetArray(aDados)

	// Atualiza a GetDados
	oGetDet:Refresh()

Return

/*/{Protheus.doc} fFillUQH
Popula a get dados com itens de provisão dos arquivos CTRB.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static User Function
/*/
Static Function fFillUQH()

	Local aDados		:= {}
	Local aLinha		:= {}
	Local aTcSetField	:= {}

	Local bQuebraLin	:= {|| Mod(nI, 5) == 0} // Quebra linha a cada 5 campos no Select

	Local cAliasQry		:= GetNextAlias()
	Local cIdImp		:= ""
	Local cQuery		:= ""
	Local cCampos		:= ""

	Local nI			:= 0

	For nI := 1 To Len(oGetDet:aHeader) - 2
		cCampos += "UQH." + AllTrim(oGetDet:aHeader[nI,2]) + ", "
		cCampos += IIf(EVal(bQuebraLin), CRLF, "")

		If oGetDet:aHeader[nI,8] $ "D|N"
			Aadd( aTCSetField, { oGetDet:aHeader[nI,2],oGetDet:aHeader[nI,8],oGetDet:aHeader[nI,4],oGetDet:aHeader[nI,5] })
		EndIf
	Next nI

	cCampos += "UQH.R_E_C_N_O_ AS UQH_RECNO "

	Aadd( aTCSetField, { "UQH_RECNO", "N", 17, 0 } )

	// Define o id de importação do arquivo selecionado para visualização
	cIdImp := oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_IDIMP", aHeaderUQG)]

	// Define a query de pesquisa do item selecionado
	cQuery	+= "SELECT " + cCampos										+ CRLF
	cQuery	+= "FROM   " + RetSqlName("UQH") + " UQH "				+ CRLF
	cQuery	+= "WHERE  UQH.UQH_FILIAL = '"	 + xFilial("UQH") + "' "	+ CRLF
	cQuery	+= "AND    UQH.UQH_IDIMP = '"	 + cIdImp         + "' " 	+ CRLF
	cQuery	+= "AND    UQH.D_E_L_E_T_ <> '*' "							+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry, aTcSetField)

	ProcRegua(0)

	While !(cAliasQry)->(Eof())
		IncProc()

		// Reinica a Linha
		aLinha := {}

		// Adiciona os dados da linha
		For nI := 1 To Len(oGetDet:aHeader) - 2
			Aadd( aLinha, (cAliasQry)->&(oGetDet:aHeader[nI,2]) )
		Next nI

		Aadd( aLinha, "UQH"						)
		Aadd( aLinha, (cAliasQry)->UQH_RECNO	)
		Aadd( aLinha, lDeleted					)

		// Adiciona a Linha ao Dados principais
		Aadd( aDados, aLinha )

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	// Adiciona os dados à aCols da GetDados
	oGetDet:SetArray(aDados)

	// Atualiza a GetDados
	oGetDet:Refresh()

Return

/*/{Protheus.doc} fFillUQI
Popula a get dados com itens de rendição dos arquivos CTRB.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static User Function
/*/
Static Function fFillUQI()

	Local aDados		:= {}
	Local aLinha		:= {}
	Local aTcSetField	:= {}

	Local bQuebraLin	:= {|| Mod(nI, 5) == 0} // Quebra linha a cada 5 campos no Select

	Local cAliasQry		:= GetNextAlias()
	Local cIdImp		:= ""
	Local cQuery		:= ""
	Local cCampos		:= ""

	Local nI			:= 0

	For nI := 1 To Len(oGetDet:aHeader) - 2
		cCampos += "UQI." + AllTrim(oGetDet:aHeader[nI,2]) + ", "
		cCampos += IIf(EVal(bQuebraLin), CRLF, "")

		If oGetDet:aHeader[nI,8] $ "D|N"
			Aadd( aTCSetField, { oGetDet:aHeader[nI,2],oGetDet:aHeader[nI,8],oGetDet:aHeader[nI,4],oGetDet:aHeader[nI,5] })
		EndIf
	Next nI

	cCampos += "UQI.R_E_C_N_O_ AS UQI_RECNO "

	Aadd( aTCSetField, { "UQI_RECNO", "N", 17, 0 } )

	// Define o id de importação do arquivo selecionado para visualização
	cIdImp := oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_IDIMP", aHeaderUQG)]

	// Define a query de pesquisa do item selecionado
	cQuery	+= "SELECT " + cCampos 										+ CRLF
	cQuery	+= "FROM   " + RetSqlName("UQI") + " UQI "				+ CRLF
	cQuery	+= "WHERE  UQI.UQI_FILIAL = '"    + xFilial("UQI") + "' "	+ CRLF
	cQuery	+= "AND    UQI.UQI_IDIMP = '"     + cIdImp         + "' " 	+ CRLF
	cQuery	+= "AND    UQI.D_E_L_E_T_ <> '*' "							+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry, aTcSetField)

	ProcRegua(0)

	While !(cAliasQry)->(Eof())
		IncProc()

		// Reinica a Linha
		aLinha := {}

		// Adiciona os dados da linha
		For nI := 1 To Len(oGetDet:aHeader) - 2
			Aadd( aLinha, (cAliasQry)->&(oGetDet:aHeader[nI,2]) )
		Next nI

		Aadd( aLinha, "UQI"						)
		Aadd( aLinha, (cAliasQry)->UQI_RECNO	)
		Aadd( aLinha, lDeleted					)

		// Adiciona a Linha ao Dados principais
		Aadd( aDados, aLinha )

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	// Adiciona os dados à aCols da GetDados
	oGetDet:SetArray(aDados)

	// Atualiza a GetDados
	oGetDet:Refresh()

Return

/*/{Protheus.doc} fAddCampo
Adiciona todos os campos da tabela ao array de campos da GetDados.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static Function
/*/
Static Function fAddCampo(aCampos, cAliasDet)

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	DbSelectArea("SX3")
	SX3->(DbSetOrder(1)) // X3_ARQUIVO + X3_ORDERM + X3_CAMPO

	If SX3->(DbSeek(cAliasDet))
		While !SX3->(Eof()) .And. SX3->X3_ARQUIVO == cAliasDet
			Aadd(aCampos, SX3->X3_CAMPO)
			SX3->(DbSkip())
		EndDo
	EndIf

	RestArea(aAreaSX3)
	RestArea(aArea)

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

/*/{Protheus.doc} fDefAlias
Define quais alias serão utilizados na visualização.
@author Paulo Carvalho
@since 18/01/2019
@version 1.01
@type Static Function
/*/
Static Function fDefAlias(cAliasCab, cAliasDet, nRecno)

	Local cAdiantamento	:= "A"
	Local cIdImp		:= ""
	Local cProvisao		:= "PR"
	Local cRendicao		:= "RD"
	Local cTipo			:= ""
	Local cDocx			:= ""
	Local cCancel		:= ""

	If cTipoArq == CTE_CRT
		cAliasCab 	:= "UQD"
		cAliasDet 	:= "UQE"
		cIdImp 		:= oGetDadUQD:aCols[oGetDadUQD:nAt][GdFieldPos("UQD_IDIMP", aHeaderUQD)]
		cDocx 		:= oGetDadUQD:aCols[oGetDadUQD:nAt][GdFieldPos("UQD_NUMERO", aHeaderUQD)]
		cCancel		:= oGetDadUQD:aCols[oGetDadUQD:nAt][GdFieldPos("UQD_CANCEL", aHeaderUQD)]

		// Posiciona o cabeçalho
		DbSelectArea("UQD")
		//UQD->(DbSetOrder(1))	// UQD_FILIAL + UQD_IDIMP

		//If UQD->(DbSeek(xFilial("UQD") + cIdImp))
		UQD->(DbSetOrder(2))
		If UQD->(DbSeek( xFilial("UQD") + Padr(cDocx, TamSX3("UQD_NUMERO")[1]) + cCancel ))
			nRecno := UQD->( Recno() ) //oGetDadUQD:aCols[oGetDadUQD:nAt][GdFieldPos("UQD_REC_WT", aHeaderUQD)]
		EndIf
	ElseIf cTipoArq == CTRB
		cAliasCab 	:= "UQG"

		// Define se é arquivo de provisão ou rendição
		cTipo 		:= AllTrim(oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_TIPO", aHeaderUQG)])
		cIdImp 		:= oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_IDIMP", aHeaderUQG)]

		// Posiciona o cabeçalho
		DbSelectArea("UQG")
		UQG->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP

		If UQG->(DbSeek(xFilial("UQG") + cIdImp))
			nRecno := oGDadUQG:aCols[oGDadUQG:nAt][GdFieldPos("UQG_REC_WT", aHeaderUQG)]
		EndIf

		// Define o alias de acordo com o tipo de arquivo
		If cTipo == cProvisao
			cAliasDet := "UQH"
		ElseIf cTipo == cRendicao .Or. cTipo == cAdiantamento
			cAliasDet := "UQI"
		EndIf
	ElseIf cTipoArq == CTE_CF
		cAliasCab 	:= "UQB"
		cAliasDet 	:= "UQC"
		cIdImp 		:= oGetDadUQB:aCols[oGetDadUQB:nAt][GdFieldPos("UQB_IDIMP", aHeaderUQB)]

		// Posiciona o cabeçalho
		DbSelectArea("UQB")
		UQB->(DbSetOrder(1))	// UQD_FILIAL + UQD_IDIMP

		If UQB->(DbSeek(xFilial("UQB") + cIdImp))
			nRecno := oGetDadUQB:aCols[oGetDadUQB:nAt][GdFieldPos("UQB_REC_WT", aHeaderUQB)]
		EndIf
	EndIf

Return

/*/{Protheus.doc} fGeraAlt
Define quais campos serão utilizados na visualização.
@author Paulo Carvalho
@since 18/01/2019
@param cAliasAlter, carácter, Alias dos campos que serão utilizados na visualização.
@type function
/*/
Static Function fGeraAlt(cAliasAlter)

	Local aArea			:= GetArea()
	Local aAreaSX3		:= SX3->(GetArea())

	Local aEnchoice		:= {}

	DbSelectArea("SX3")
	SX3->(DbSetOrder(1))
	SX3->(DbSeek(cAliasAlter))

	While !SX3->(Eof()) .And. (SX3->X3_ARQUIVO==cAliasAlter)
		Aadd(aEnchoice, SX3->X3_CAMPO )
		SX3->(dbSkip())
	End

	//Adiciona campo
	Aadd(aEnchoice, "NOUSER" )

	RestArea(aArea)
	RestArea(aAreaSX3)

Return aClone(aEnchoice)

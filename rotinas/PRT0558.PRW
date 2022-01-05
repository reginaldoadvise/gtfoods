#Include "Totvs.ch"
#Include "CATTMS.ch"

/*/{Protheus.doc} PRT0558
Define as funções específicas para manutenção de arquvios CTE/CRT.
@author Paulo Carvalho / Juliano Fernandes
@since 28/12/2018
@version P12 17.0.1
@database SQL Server
@type User Function
/*/
User Function PRT0558( nOperacao , uPar )
	Private aLogs		:= {}
	Private oBlue		:= LoadBitmap( GetResources(), "BR_AZUL" 		)	//Importado
	Private oGreen  	:= LoadBitmap( GetResources(), "BR_VERDE" 		)	//Integrado
	Private oRed    	:= LoadBitmap( GetResources(), "BR_VERMELHO"	)	//Erro no processamento
	Private oBlack		:= LoadBitmap( GetResources(), "BR_PRETO" 		)	//Cancelado
	Private oVioleta	:= LoadBitmap( GetResources(), "BR_VIOLETA"		)
	Private oInclusao	:= LoadBitmap( GetResources(), "CATTMS_INC"		)
	Private oReprocess	:= LoadBitmap( GetResources(), "CATTMS_REP"		)
	Private oCancel		:= LoadBitmap( GetResources(), "BR_CANCEL"		)
	Private oNo			:= LoadBitmap( GetResources(), "LBNO" 			)
	Private oOk			:= LoadBitmap( GetResources(), "LBOK" 			)

	Private cFornec	:= ""
	Private cFilArq		:= ""

    Do Case
        Case nOperacao == NGETDADOS
            fGetDados()
        Case nOperacao == NFILTRAR
			Processa({|| fFillDados()},CAT544001, CAT544002) 	// "Aguarde", "Filtrando Registros..."
		Case nOperacao == NCHECK
			Processa({|| fBtnCheck(uPar)},CAT544001, CAT544003) // "Aguarde", "Executando"
		Case nOperacao == NINTEGRAR
			Processa({|| fIntegra(uPar)},CAT544001, CAT544004) 	// "Aguarde", "Processando"
		Case nOperacao == NEXCLUIR
			Processa({|| fExcluir()},CAT544001, CAT544005) 		// "Aguarde", "Excluindo arquivo(s)"
		Case nOperacao == NESTORNAR
			Processa({|| fEstornar(uPar)}, CAT544001, CAT544006)//"Estornando Arquivos"
		Case nOperacao == NPEDVENDA
			Processa({|| fPedVenda()},CAT544001, CAT544007) 	// "Aguarde", "Localizando Pedido de Venda"
		Case nOperacao == NNOTAFISCAL
			Processa({|| fNotaFiscal()},CAT544001, CAT544008) 	// "Aguarde", "Localizando Nota Fiscal de Saí­da"
		Case nOperacao == NIMPRIMIR
		 	Processa({|| fReport()},CAT544001, CAT544009) 		// "Aguarde", "Gerando Relatório"
		Case nOperacao == NCONTAPAGAR
			Processa({||  fContaPagar()},CAT544001, "Contas a Pagar") 
    EndCase

Return

/*/{Protheus.doc} fGetDados
Cria a GetDados para arquvios CTE/CRT.
@author Paulo Carvalho / Juliano Fernandes
@since 02/01/2019
@version 1.01
@type Static Function
/*/
Static Function fGetDados()

    Local aArea         := GetArea()
    Local aAreaSX3      := SX3->( GetArea() )
    Local aArray        := {}
    Local aCampos       := {}

    Local bChange       := {|| fChgUQB()}

    Local nH, nI, nJ

	Local nRow			:= 0
	Local nLeft			:= 0
	Local nBottom		:= 0
	Local nRight		:= 0

    // Reinicia o array aHeader
    aHeaderUQB 	:= {}
    aCampos 	:= {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQD", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQD", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQD", "LINEND" )
		nRight	:= oSize:GetDimension( "GETDADOS_UQD", "COLEND" )
	EndIf

	// Adiciona, manualmente, os campos da tabela que serão visualizados para o array aCampos
	Aadd( aCampos, "UQB_FILIAL" )
	Aadd( aCampos, "UQK_DESCRI" )
	Aadd( aCampos, "UQB_IDIMP"  )
    Aadd( aCampos, "UQB_TPCON"  )
    Aadd( aCampos, "UQB_NUMERO" )
    Aadd( aCampos, "UQB_TPCF" )
	Aadd( aCampos, "UQB_DTIMP"  )
    Aadd( aCampos, "UQB_EMISSA" )
    Aadd( aCampos, "UQB_FORNEC" )
    Aadd( aCampos, "UQB_LOJA" )
    Aadd( aCampos, "A2_NOME" 	)
    Aadd( aCampos, "UQB_VALOR"  )
    Aadd( aCampos, "UQB_MOEDA"  )
	Aadd( aCampos, "UQB_PEDIDO"	)
	Aadd( aCampos, "UQB_NF" 	)
	Aadd( aCampos, "UQB_SERIE" 	)
    Aadd( aCampos, "UQB_PREFIX" )
    Aadd( aCampos, "UQB_TITULO" )
    Aadd( aCampos, "UQB_PARCEL" )
    Aadd( aCampos, "UQB_TIPOTI" )
	Aadd( aCampos, "UQB_XTPCTE" )
	Aadd( aCampos, "UQB_CTEREF" )
	Aadd( aCampos, "UQB_ADMCF" )

	// Adiciona campo para legenda no aHeader
	fAddCheck( @aHeaderUQB )

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeaderUQB, 1 )

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeaderUQB, 2 )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQB, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
    AdHeadRec( "UQB", aHeaderUQB )

	// Popula o array com dados inicias em branco.
	Aadd( aArray, oNo )
	Aadd( aArray, oBlue )
	Aadd( aArray, oInclusao )

	For nJ := 4 To Len( aHeaderUQB ) - 2
		Aadd( aArray, CriaVar( aHeaderUQB[nJ][2], .T. ) )
    Next

    Aadd( aArray, "UQB" 	) // Alias WT
    Aadd( aArray, 0 		) // Recno WT
	Aadd( aArray, .F. 		) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderUQB)
		If Empty(aHeaderUQB[nH][3]) .And. aHeaderUQB[nH][8] == "C"
			aHeaderUQB[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		// Instancia a GetDados
		oGetDadUQB   := MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialog, aHeaderUQB, { aArray }, bChange, /*cTela*/	)

		oGetDadUQB:oBrowse:bLDblClick := {|| fCheck(), oGetDadUQB:oBrowse:Refresh()}

		// Impede a edição de linha
		oGetDadUQB:SetEditLine( .F. )

		// Atualiza a GetDados
		oGetDadUQB:Refresh()
	EndIf

    // Reinicia o array aHeader
    aHeaderUQC := {}
    aCampos := {}
    aArray := {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQE", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQE", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQE", "LINEND" ) + 15 // + 15 para compensar a falta da barra de título
		nRight	:= oSize:GetDimension( "GETDADOS_UQE", "COLEND" )
	EndIf

	// Adiciona, manualmente, os campos da tabela que serão visualizados para o array aCampos
    Aadd( aCampos, "UQC_ITEM"   )
    Aadd( aCampos, "UQC_PRODUT" )
    Aadd( aCampos, "B1_DESC"    )
    Aadd( aCampos, "UQC_PRCVEN" )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQC, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
    AdHeadRec( "UQC", aHeaderUQC )

	// Popula o array com dados inicias em branco.
	For nJ := 1 To Len( aHeaderUQC ) - 2
        Aadd( aArray, CriaVar( aHeaderUQC[nJ][2], .T. ) )
    Next

    Aadd( aArray, "UQC" 	) // Alias WT
    Aadd( aArray, 0 		) // Recno WT
	Aadd( aArray, .F. 		) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderUQC)
		If Empty(aHeaderUQC[nH][3]) .And. aHeaderUQC[nH][8] == "C"
			aHeaderUQC[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		// Instancia a GetDados
		oGetDadUQC   := MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialog, aHeaderUQC, { aArray }, /*uChange*/, /*cTela*/	)

		// Impede a edição de linha
		oGetDadUQC:SetEditLine( .F. )

		// Atualiza a GetDados
		oGetDadUQC:Refresh()
	EndIf

	//-- Cria as variáveis de posição
	fCria_nPos()

	RestArea(aAreaSX3)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCria_nPos
Cria as variáveis de controle de posição das GetDados.
@author Juliano Fernandes
@since 25/01/2019
@version 1.01
@type Static Function
/*/
Static Function fCria_nPos()
	_SetNamedPrvt("nPsUQBCheck"	, GDFieldPos("CHK"		 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBLeg1"	, GDFieldPos("LEG1"		 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBLeg2"	, GDFieldPos("LEG2"		 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBFilial", GDFieldPos("UQB_FILIAL" , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQKDescric", GDFieldPos("UQK_DESCRI", aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBIDImp"	, GDFieldPos("UQB_IDIMP"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBTpCon"	, GDFieldPos("UQB_TPCON"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBNumero"	, GDFieldPos("UQB_NUMERO" , aHeaderUQB), "U_PRT0528")
    _SetNamedPrvt("nPsUQBTPCF"	, GDFieldPos("UQB_TPCF" , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBDtImp"	, GDFieldPos("UQB_DTIMP"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBEmissao", GDFieldPos("UQB_EMISSA", aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBFornec", GDFieldPos("UQB_FORNEC", aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBLoja", GDFieldPos("UQB_LOJA", aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBNomeCli", GDFieldPos("A2_NOME"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBValor"	, GDFieldPos("UQB_VALOR"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBMoeda"	, GDFieldPos("UQB_MOEDA"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBPedido"	, GDFieldPos("UQB_PEDIDO" , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBNF"		, GDFieldPos("UQB_NF"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_SERIE"	 , aHeaderUQB), "U_PRT0528")
    _SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_PREFIX"	 , aHeaderUQB), "U_PRT0528")
    _SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_TITULO"	 , aHeaderUQB), "U_PRT0528")
    _SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_PARCEL"	 , aHeaderUQB), "U_PRT0528")
    _SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_TIPOTI"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_XTPCTE"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_CTEREF"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBSerie"	, GDFieldPos("UQB_ADMCF"	 , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBAlias"	, GDFieldPos("UQB_ALI_WT" , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBRecno"	, GDFieldPos("UQB_REC_WT" , aHeaderUQB), "U_PRT0528")
	_SetNamedPrvt("nPsUQBDelet"	, Len(aHeaderUQB) + 1				  , "U_PRT0528")

	_SetNamedPrvt("nPsUQCItem"	, GDFieldPos("UQC_ITEM"	 , aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCProduto", GDFieldPos("UQC_PRODUT", aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCDesc"	, GDFieldPos("B1_DESC"	 , aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCPrcVen"	, GDFieldPos("UQC_PRCVEN" , aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCAlias"	, GDFieldPos("UQC_ALI_WT" , aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCRecno"	, GDFieldPos("UQC_REC_WT" , aHeaderUQC), "U_PRT0528")
	_SetNamedPrvt("nPsUQCDelet"	, Len(aHeaderUQC) + 1				  , "U_PRT0528")
Return(Nil)

/*/{Protheus.doc} fFillDados
Preenche a GetDados com os arquvios CTE/CRT selecionados pelo filtro.
@author Paulo Carvalho
@since 02/01/2019
@version 1.01
@type function
/*/
Static Function fFillDados()

    Local aArea         := GetArea()
    Local aDados        := {}
    Local aLinha        := {}
	Local aNota			:= {}
    Local aTCSetField   := {}
    Local aTam          := {}
	Local aFilSel		:= {}

    Local cAliasQry     := GetNextAlias()
    Local cQuery        := ""
	Local cAuxDocDe		:= ""
	Local cAuxDocAte	:= ""
	Local cFiliaisIn	:= ""

	Local lDeleted		:= .F.
	Local lDados		:= .F.

	Local nJ			:= 0
	Local nI			:= 0

	// Define o campos que devem passar pela função TCSetField
	aTam := TamSX3("UQB_EMISSA") ; Aadd( aTCSetField, { "UQB_EMISSA", aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQB_DTIMP"  ) ; Aadd( aTCSetField, { "UQB_DTIMP"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQB_VALOR"  ) ; Aadd( aTCSetField, { "UQB_VALOR"  , aTam[3], aTam[1], aTam[2]	} )
    aTam := {17, 0, "N"}         ; Aadd( aTCSetField, { "RECNOUQB"  , aTam[3], aTam[1], aTam[2]	} )

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
		//Aadd(aFiliais, {cFilAnt, xFilial("UQB")})

		// Define a query para pesquisa dos arquivos.
		cQuery  := "SELECT  UQB.UQB_FILIAL, UQB.UQB_DTIMP, UQB.UQB_IDIMP, UQB.UQB_TPCON, UQB.UQB_NUMERO, "		+ CRLF
		cQuery  += "        UQB.UQB_EMISSA, UQB.UQB_FORNEC, UQB.UQB_LOJA, SA2.A2_NOME, UQB.UQB_VALOR, "	+ CRLF
		cQuery  += "        UQB.UQB_MOEDA, UQB.UQB_PEDIDO, UQB.UQB_NF, UQB.UQB_SERIE, UQB.UQB_STATUS, "			+ CRLF
		cQuery  += "        UQB.UQB_CANCEL, UQB.R_E_C_N_O_ RECNOUQB, UQK.UQK_DESCRI,UQB_TPCF,UQB_PREFIX,UQB_TITULO,UQB_PARCEL,UQB_TIPOTI,UQB_CTEREF,UQB_XTPCTE,UQB_ADMCF "						+ CRLF
		cQuery  += "FROM    " + RetSqlName("UQB") + " UQB "                                             	+ CRLF
		cQuery 	+= "LEFT JOIN " + RetSqlName("SA2") + " SA2 "											+ CRLF
		cQuery 	+= "	ON SA2.A2_FILIAL = '" + xFilial("SA2") + "' " 										+ CRLF
		cQuery 	+= "	AND SA2.A2_COD = UQB.UQB_FORNEC" 													+ CRLF
		cQuery 	+= "	AND SA2.A2_LOJA = UQB.UQB_LOJA" 													+ CRLF
		cQuery 	+= "	AND SA2.D_E_L_E_T_ <> '*'" 															+ CRLF
		cQuery	+= "LEFT JOIN " + RetSqlName("UQK") + " UQK "												+ CRLF
		cQuery	+= "	ON UQK.UQK_FILIAL = '" + xFilial("UQK") + "' "										+ CRLF
		cQuery	+= "	AND UQK.UQK_FILPRO = UQB.UQB_FILIAL "												+ CRLF
		cQuery	+= "	AND UQK.D_E_L_E_T_ <> '*' "															+ CRLF
		// cQuery  += "WHERE   UQB.UQB_FILIAL = '" + xFilial("UQB") + "' "                                  	+ CRLF
		cQuery  += "WHERE   UQB.UQB_FILIAL IN " + cFiliaisIn + " "	                                     	+ CRLF

		If l528Auto
			cQuery  += "AND		UQB.UQB_STATUS = 'I'     "     			                	    	 		+ CRLF
			cQuery  += "AND		UQB.UQB_IDSCHE = '" + cIdSched + "'     "                     	    	 	+ CRLF
		Else
			// Define o range de documentos
			cAuxDocDe	:= fDefDocDe(cDocDe, cFiliaisIn)
			cAuxDocAte	:= fDefDocAte(cDocAte, cFiliaisIn)

			If !Empty(cAuxDocDe)
				cQuery	+= "AND		UQB.UQB_NUMERO >= '" + cAuxDocDe + "' "										+ CRLF
			EndIf

			If !Empty(cAuxDocAte)
				cQuery	+= "AND		UQB.UQB_NUMERO <= '" + cAuxDocAte + "' "										+ CRLF
			EndIf

			If !Empty(cFornecDe)
				cQuery  += "AND     UQB.UQB_FORNEC >= '" + cFornecDe       + "' "                         	 	+ CRLF
			EndIf

			If !Empty(cFornecAte)
				cQuery  += "AND     UQB.UQB_FORNEC <= '" + cFornecAte      + "' "                            	+ CRLF
			EndIf

			If !Empty(dDataDe)
				cQuery  += "AND     UQB.UQB_DTIMP >= '" + DtoS( dDataDe )  + "' "                            	+ CRLF
			EndIf

			If !Empty(dDataAte)
				cQuery  += "AND     UQB.UQB_DTIMP <= '" + DtoS( dDataAte ) + "' "                            	+ CRLF
			EndIf

			If cCbStatus != "Todos"
				cQuery  += "AND     UQB.UQB_STATUS = '" + Left(cCbStatus,1) + "'  "                            	+ CRLF
			EndIf

			If !Empty(cPedidoDe)
				cQuery  += "AND     UQB.UQB_PEDIDO >= '" + cPedidoDe       + "'   "                         	 	+ CRLF
			EndIf

			If !Empty(cPedidoAte)
				cQuery  += "AND     UQB.UQB_PEDIDO <= '" + cPedidoAte       + "'  "                         	 	+ CRLF
			EndIf

			If !Empty(cGNFDe)
				cQuery  += "AND     UQB.UQB_NF >= '" + cGNFDe       + "'      "                         	 		+ CRLF
			EndIf

			If !Empty(cGNFAte)
				cQuery  += "AND     UQB.UQB_NF <= '" + cGNFAte       + "'     "                         	 		+ CRLF
			EndIf
		EndIf

		cQuery  += "AND     UQB.D_E_L_E_T_ <> '*' "																+ CRLF
		cQuery  += "ORDER BY UQB.UQB_FILIAL, UQB.R_E_C_N_O_ "                                               		+ CRLF

		MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

		ProcRegua(0)

		While !(cAliasQry)->(Eof())
			lDados := .T.

			IncProc()

			If AScan(aFiliais, {|x| x[2] == (cAliasQry)->UQB_FILIAL}) == 0
				// ------------------------------------------------------------------
				// Inserido duas vezes no array aFilials por questão de adaptação
				// ao modo que o programa foi desenvolvido inicialmente.
				// ------------------------------------------------------------------
				Aadd(aFiliais, {(cAliasQry)->UQB_FILIAL, (cAliasQry)->UQB_FILIAL})
			EndIf

			// Reinicia aLinha a cada iteração
			aLinha := {}

			Aadd( aLinha, oNo )

			// Define a legenda para o registro.
			If (cAliasQry)->UQB_STATUS == "I" // Arquivo importado
				Aadd( aLinha, oBlue )
			ElseIf (cAliasQry)->UQB_STATUS == "P" // Arquivo integrado no Protheus
				Aadd( aLinha, oGreen )
			ElseIf (cAliasQry)->UQB_STATUS == "E" // Arquivo com erros na integração
				Aadd( aLinha, oRed )
			ElseIf (cAliasQry)->UQB_STATUS == "C" // Arquivo cancelado
				Aadd( aLinha, oBlack )
			ElseIf (cAliasQry)->UQB_STATUS == "R" // Arquivo reprocessado
				Aadd( aLinha, oVioleta )
			EndIf

			// Define a legenda para o registro.
			If Empty((cAliasQry)->UQB_CANCEL) // Arquivo para inclusão
				Aadd( aLinha, oInclusao )
			ElseIf (cAliasQry)->UQB_CANCEL == "R" // Arquivo para reprocessamento
				Aadd( aLinha, oReprocess )
			ElseIf (cAliasQry)->UQB_CANCEL == "C" // Arquivo para cancelamento
				Aadd( aLinha, oCancel )
			EndIf

			Aadd( aLinha, (cAliasQry)->UQB_FILIAL	)
			Aadd( aLinha, (cAliasQry)->UQK_DESCRI	)
			Aadd( aLinha, (cAliasQry)->UQB_IDIMP	)
			Aadd( aLinha, (cAliasQry)->UQB_TPCON 	)
			Aadd( aLinha, (cAliasQry)->UQB_NUMERO 	)
            Aadd( aLinha, (cAliasQry)->UQB_TPCF     )
			Aadd( aLinha, (cAliasQry)->UQB_DTIMP	)
			Aadd( aLinha, (cAliasQry)->UQB_EMISSA 	)
			Aadd( aLinha, (cAliasQry)->UQB_FORNEC 	)
			Aadd( aLinha, (cAliasQry)->UQB_LOJA 	)
			Aadd( aLinha, (cAliasQry)->A2_NOME	 	)
			Aadd( aLinha, (cAliasQry)->UQB_VALOR 	)
			Aadd( aLinha, (cAliasQry)->UQB_MOEDA 	)
			Aadd( aLinha, (cAliasQry)->UQB_PEDIDO 	)

			If !lFaturaPed .And. !Empty((cAliasQry)->UQB_PEDIDO)
				aNota := fDefFiscal((cAliasQry)->UQB_IDIMP, (cAliasQry)->UQB_PEDIDO)

				Aadd( aLinha, aNota[1] 				)
				Aadd( aLinha, aNota[2] 				)
			Else
				Aadd( aLinha, (cAliasQry)->UQB_NF 	)
				Aadd( aLinha, (cAliasQry)->UQB_SERIE )
			EndIf
   
            Aadd( aLinha, (cAliasQry)->UQB_PREFIX )
            Aadd( aLinha, (cAliasQry)->UQB_TITULO )
            Aadd( aLinha, (cAliasQry)->UQB_PARCEL )
            Aadd( aLinha, (cAliasQry)->UQB_TIPOTI )
			Aadd( aLinha, (cAliasQry)->UQB_XTPCTE )
			Aadd( aLinha, (cAliasQry)->UQB_CTEREF )
			Aadd( aLinha, (cAliasQry)->UQB_ADMCF )

			Aadd( aLinha, "UQB" 	                )
			Aadd( aLinha, (cAliasQry)->RECNOUQB 	)
			Aadd( aLinha, lDeleted 					)

			// Adiciona a linha ao array principal
			Aadd( aDados, aLinha )

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
//	Next nI

	If !l528Auto
		If Empty(aDados)
			Aadd( aLinha, oNo )
			Aadd( aLinha, oBlue )
			Aadd( aLinha, oInclusao )

			// Popula o array com dados em branco.
			For nJ := 4 To Len( aHeaderUQB ) - 2
				Aadd( aLinha, CriaVar( aHeaderUQB[nJ][2], .T. ) )
			Next

			Aadd( aLinha, "UQB" 	) // Alias WT
			Aadd( aLinha, 0 		) // Recno WT
			Aadd( aLinha, .F. 		) // D_E_L_E_T_

			Aadd(aDados, aLinha)
		EndIf

		// Define array aDados como aCols da GetDados
		oGetDadUQB:SetArray( aDados )
	Else
		aCoUQBAuto := AClone(aDados)
	EndIf

	//-- Marca todos os registros
	fBtnCheck(1)

	// Atualiza a GetDados
	If !l528Auto
		//oGetDadUQB:Refresh()
	EndIf

	//-- Carrega a GetDados da UQC
	fChgUQB()

	If !lDados
		MsgAlert(CAT544010, "PRT0558 - Carta Frete") //"Nenhum registro localizado com os filtros informados."
	EndIf

    RestArea(aArea)

Return

/*/{Protheus.doc} fDefFiscal
Alimenta, em tempo de execução, o número da nota e série fiscal, caso o pedido tenha sido faturado.
@author Paulo Carvalho
@since 29/04/2019
@version 12.1.23
@param cIdImp, carácter, Id de importação do arquivo.
@param cPedido, carácter, Pedido de Venda gerado para o arquivo importado.
@return aNF, Array com a Nota Fiscal e Serie
@type Static function
/*/
Static Function fDefFiscal(cIdImp, cPedido)

	Local aArea		:= GetArea()
	Local aAreaSC5	:= SC5->(GetArea())
	Local aAreaUQB	:= UQB->(GetArea())
	Local aNF		:= {"",""}

	DbSelectArea("SC5")
	SC5->(DbSetOrder(1))	// C5_FILIAL + C5_NUM
	If SC5->(DbSeek(FWxFilial("SC5") + cPedido))
		aNF[1] 	:= SC5->C5_NOTA
		aNF[2] 	:= SC5->C5_SERIE

		// Atualiza a tabela UQB
		DbSelectArea("UQB")
		UQB->(DbSetOrder(1))	// UQB_FILIAL + UQB_IDIMP
		If UQB->(DbSeek(FWxFilial("UQB") + cIdImp))
			UQB->(RecLock("UQB", .F.))
				UQB->UQB_NF 	:= aNF[1]
				UQB->UQB_SERIE 	:= aNF[2]
			UQB->(MsUnlock())
		EndIf
	EndIf

	RestArea(aAreaUQB)
	RestArea(aAreaSC5)
	RestArea(aArea)

Return(AClone(aNF))

/*/{Protheus.doc} fDefDocDe
Determina o primeiro documento para o range de pesquisa.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@return cAuxDocDe, Primeiro documento para o range de pesquisa de documentos.
@param cDocumento, characters, porção do documento desejado digitado pelo usuário.
@type Static function
/*/
Static Function fDefDocDe(cDocumento, cFiliaisIn)

	Local aArea		:= GetArea()

	Local cAliasQry	:= GetNextAlias()
	Local cAuxDocDe	:= ""
	Local cQuery	:= ""

	cQuery	+= "SELECT	UQB.UQB_NUMERO "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQB") + " UQB "					+ CRLF
	// cQuery	+= "WHERE	UQB.UQB_FILIAL = '" + xFilial("UQB") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQB.UQB_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQB.UQB_NUMERO LIKE '%" + AllTrim(cDocumento) + "%'"	+ CRLF
	cQuery	+= "AND		UQB.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQB.UQB_NUMERO "									+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocDe := (cAliasQry)->UQB_NUMERO
	Else
		cAuxDocDe := AllTrim(cDocumento)
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return cAuxDocDe

/*/{Protheus.doc} fDefDocAte
Determina o último documento para o range de pesquisa.
@author Paulo Carvalho
@since 23/01/2019
@version 1.0
@return cAuxDocDe, Último documento para o range de pesquisa de documentos.
@param cDocumento, characters, porção do documento desejado digitado pelo usuário.
@type Static function
/*/
Static Function fDefDocAte(cDocumento, cFiliaisIn)

	Local aArea			:= GetArea()

	Local cAliasQry		:= GetNextAlias()
	Local cAuxDocAte	:= ""
	Local cQuery		:= ""

	cQuery	+= "SELECT	UQB.UQB_NUMERO "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQB") + " UQB "					+ CRLF
	// cQuery	+= "WHERE	UQB.UQB_FILIAL = '" + xFilial("UQB") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQB.UQB_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQB.UQB_NUMERO LIKE '%" + AllTrim(cDocumento) + "%'"	+ CRLF
	cQuery	+= "AND		UQB.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQB.UQB_NUMERO DESC "								+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocAte := (cAliasQry)->UQB_NUMERO
	Else
		cAuxDocAte := AllTrim(cDocumento)
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return cAuxDocAte

/*/{Protheus.doc} fFillUQC
Filtra e carrega os dados da tabela UQC conforme o ID de importação passado por parâmetro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param cIDImp, characters, Código do ID de importação
@type function
/*/
Static Function fFillUQC(cIDImp)
    Local aDados        := {}
    Local aLinha        := {}
    Local aTCSetField   := {}
    Local aTam          := {}

    Local cAliasQry     := GetNextAlias()
    Local cQuery        := ""

	Local lDeleted		:= .F.
	Local lContinua		:= .T.

	Local nJ			:= 0

	If Empty(cIDImp)
		lContinua := .F.
	EndIf

	If lContinua
		cMemIDImp := cIDImp

		// Define o campos que devem passar pela função TCSetField
		aTam := TamSX3("UQC_PRCVEN") ; Aadd( aTCSetField, { "UQC_PRCVEN", aTam[3], aTam[1], aTam[2]	} )
		aTam := {17, 0, "N"}        ; Aadd( aTCSetField, { "RECNOUQC" , aTam[3], aTam[1], aTam[2]	} )

		// Define a query para pesquisa dos arquivos.
		cQuery  += "SELECT  UQC.UQC_ITEM, UQC.UQC_PRODUT, SB1.B1_DESC,"	+ CRLF
		cQuery  += "        UQC.UQC_PRCVEN, UQC.R_E_C_N_O_ RECNOUQC"		+ CRLF
		cQuery  += "FROM    " + RetSqlName("UQC") + " UQC "			+ CRLF
		cQuery 	+= "LEFT JOIN " + RetSqlName("SB1") + " SB1 "		+ CRLF
		cQuery 	+= "	ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' " 	+ CRLF
		cQuery 	+= "	AND SB1.B1_COD = UQC.UQC_PRODUT" 				+ CRLF
		cQuery 	+= "	AND SB1.D_E_L_E_T_ <> '*'" 						+ CRLF
		cQuery  += "WHERE   UQC.UQC_FILIAL = '" + xFilial("UQC") + "' "	+ CRLF
		cQuery  += "AND     UQC.UQC_IDIMP = '" + cIDImp + "' "         	+ CRLF
		cQuery  += "AND     UQC.D_E_L_E_T_ <> '*' "                  	+ CRLF
		cQuery  += "ORDER BY UQC.UQC_ITEM "                    			+ CRLF

		MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

		While !(cAliasQry)->(Eof())
			// Reinicia aLinha a cada iteração
			aLinha := {}

			Aadd( aLinha, (cAliasQry)->UQC_ITEM 		)
			Aadd( aLinha, (cAliasQry)->UQC_PRODUT 	)
			Aadd( aLinha, (cAliasQry)->B1_DESC 		)
			Aadd( aLinha, (cAliasQry)->UQC_PRCVEN 	)
			Aadd( aLinha, "UQC" 					)
			Aadd( aLinha, (cAliasQry)->RECNOUQC 	)
			Aadd( aLinha, lDeleted 					)

			// Adiciona a linha ao array principal
			Aadd( aDados, aLinha )

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
	EndIf

	If Empty(aDados)
		// Popula o array com dados em branco.
		For nJ := 1 To Len( aHeaderUQC ) - 2
			Aadd( aLinha, CriaVar( aHeaderUQC[nJ][2], .T. ) )
		Next

		Aadd( aLinha, "UQC" 	) // Alias WT
		Aadd( aLinha, 0 		) // Recno WT
		Aadd( aLinha, .F. 		) // D_E_L_E_T_

		Aadd(aDados, aLinha)
	EndIf

	// Define array aDados como aCols da GetDados
	oGetDadUQC:SetArray( aDados )

	// Atualiza a GetDados
	oGetDadUQC:Refresh()
Return(Nil)

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
	Local uRet	:= Nil

	DbSelectArea("SX3")
	SX3->(dbSetOrder(2))

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

Return uRet

/*/{Protheus.doc} fAddCheck
Função para adicionar no aHeader o campo para legenda.
@author Juliano Fernandes
@since 09/01/2019
@param aArray, array, Array contendo a referência de aHeader
@version 1.01
@type function
/*/
Static Function fAddCheck( aArray )

	Aadd( aArray, { "", "CHK", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

Return

/*/{Protheus.doc} fAddLegenda
Função para adicionar no aHeader o campo para legenda.
@author Paulo Carvalho
@since 21/12/2018
@param aArray, array, Array contendo a referência de aHeader
@version 1.01
@type function
/*/
Static Function fAddLegenda( aArray, nLeg )

	Aadd( aArray, { "", "LEG" + CValToChar(nLeg), "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

Return

/*/{Protheus.doc} fChgUQB
Função executada ao mudar de linha na GetDados da tabela de cabeçalho UQB.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fChgUQB()
	Local cFilImp	:= ""
	Local cIDImp 	:= ""
	Local nPos		:= 0

	If Type("oGetDadUQB") == "O"
		cFilImp := oGetDadUQB:aCols[oGetDadUQB:nAt, nPsUQBFilial]
		cIDImp  := oGetDadUQB:aCols[oGetDadUQB:nAt, nPsUQBIDImp]

		If (nPos := AScan(aFiliais, {|x| x[2] == cFilImp})) > 0
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])
		EndIf

		If AllTrim(cIDImp) != AllTrim(cMemIDImp)
			fFillUQC(cIDImp)
		EndIf
	EndIf
Return(Nil)

/*/{Protheus.doc} fCheck
Realiza a marcação de um registro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fCheck()
	Local oNo := LoadBitmap( GetResources(), "LBNO" )
	Local oOk := LoadBitmap( GetResources(), "LBOK" )

	If fVldCheck(.T.)
		If oGetDadUQB:aCols[oGetDadUQB:nAt, nPsUQBCheck]:cName == "LBNO"
			oGetDadUQB:aCols[oGetDadUQB:nAt, nPsUQBCheck] := oOk
			If oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBIDImp]==oGetDadUQB:aCols[oGetDadUQB:nAt+1,nPsUQBIDImp]
				oGetDadUQB:aCols[oGetDadUQB:nAt+1, nPsUQBCheck] := oOk
			ElseIf oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBIDImp]==oGetDadUQB:aCols[oGetDadUQB:nAt-1,nPsUQBIDImp]
				oGetDadUQB:aCols[oGetDadUQB:nAt-1, nPsUQBCheck] := oOk
			EndIf
		Else
			oGetDadUQB:aCols[oGetDadUQB:nAt, nPsUQBCheck] := oNo
			If oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBIDImp]==oGetDadUQB:aCols[oGetDadUQB:nAt+1,nPsUQBIDImp]
				oGetDadUQB:aCols[oGetDadUQB:nAt+1, nPsUQBCheck] := oNo
			ElseIf oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBIDImp]==oGetDadUQB:aCols[oGetDadUQB:nAt-1,nPsUQBIDImp]
				oGetDadUQB:aCols[oGetDadUQB:nAt-1, nPsUQBCheck] := oNo
			EndIf
		EndIf
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

	Local aAreas 		:= {}
	Local aColsVld		:= {}

	Local cNumeroOri	:= ""
	Local cCliVld		:= ""
	Local cLojaVld		:= ""
	Local cNumVld		:= ""

	Local lValid 		:= .T.
	Local lExisteReg	:= .F.

	Local nLinhaVld		:= 0
	Local nI			:= 0

	Default nLinha 		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	If l528Auto
		aColsVld := aCoUQBAuto
		nLinhaVld := nLinha
	Else
		aColsVld := oGetDadUQB:aCols
		nLinhaVld := oGetDadUQB:nAt
	EndIf

	If Empty(aColsVld[nLinhaVld,nPsUQBRecno])
		lValid := .F.
	EndIf

	If lValid
		DbSelectArea("UQB")
		UQB->(DbGoTo( aColsVld[nLinhaVld,nPsUQBRecno] ))
		If UQB->(Recno()) == aColsVld[nLinhaVld,nPsUQBRecno]
			If UQB->UQB_STATUS == "P" // Integrado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544011, "PRT0558 - Carta Frete")	//"O registro selecionado não pode ser marcado pois já foi integrado ao Protheus."
				EndIf

			ElseIf UQB->UQB_STATUS == "C" // Cancelado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544012, "PRT0558 - Carta Frete")	//"O registro selecionado não pode ser marcado pois foi cancelado."
				EndIf

			ElseIf UQB->UQB_STATUS == "R" // Reprocessado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544013, "PRT0558 - Carta Frete")	//"O registro selecionado não pode ser marcado pois foi reprocessado."
				EndIf

			EndIf

			If lValid
				//-- Validação para registros de cancelamento e reprocessamento
				//-- Só permite a seleção caso o registro original já tenha sido integrado
				If UQB->UQB_CANCEL $ "C|R" // Cancelamento ou Reprocessamento
					cNumeroOri := PadR(UQB->UQB_NUMERO, TamSX3("UQB_NUMERO")[1])
					cCliVld  := UQB->UQB_FORNEC
					cLojaVld := UQB->UQB_LOJA
					cNumVld  := UQB->UQB_NUMERO

					StaticCall(PRT0528, fAltFilial, UQB->UQB_FILIAL)

					If !fPosRegAtivo(cNumeroOri, @lExisteReg)
						If lExisteReg
							If l528Auto
								lValid := .F.

								// ------------------------------------------------
								// Verifica se o registro de inclusão está junto
								// com os registros que serão processados
								// ------------------------------------------------
								For nI := 1 To Len(aColsVld)
									If nI == nLinhaVld
										Loop
									Else
										If aColsVld[nI,nPsUQBFilial ] == xFilial("UQB")	.And. ;
										   aColsVld[nI,nPsUQBFornec] == cCliVld		.And. ;
										   aColsVld[nI,nPsUQBLoja] == cLojaVld		.And. ;
										   aColsVld[nI,nPsUQBNumero ] == cNumVld		.And. ;
										   aColsVld[nI,nPsUQBLeg2   ]:cName == "CATTMS_INC"

											lValid := .T.
											Exit

										EndIf
									EndIf
								Next nI
							Else
								// --------------------------------------------------------------------
								// Não encontrou registro processado, mas existe registro importado
								// --------------------------------------------------------------------
								lValid := .F.

								If lExibeMsg
									MsgAlert(CAT544014, "PRT0558 - Carta Frete")	//"O registro selecionado não pode ser marcado pois o registro de inclusão não foi integrado."
								EndIf
							EndIf
						Else
							// --------------------------------------------------------------------
							// Não encontrou nenhum registro importado
							// --------------------------------------------------------------------
							lValid := .F.

							If lExibeMsg
								MsgAlert(CAT544015, "PRT0558 - Carta Frete")	//"O registro selecionado não pode ser marcado pois não foi localizado o registro de inclusão do CTE/CRT."
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(lValid)

/*/{Protheus.doc} fBtnCheck
Marca e desmarca ou inverte o check em todos os registros.
@type function
@author Juliano Fernandes
@since 07/02/2018
@return Nil, Sem retorno
/*/
Static Function fBtnCheck(nOpc)

	Local cFilBkp	:= cFilAnt

	Local nI		:= 0
	Local nAt		:= 0

	ProcRegua(1)

	If !l528Auto
		nAt := oGetDadUQB:nAt
	EndIf

	If nOpc == 1 /* Marcar todos */

		If l528Auto
			AEVal(aCoUQBAuto, {|x| nI++, IIf(fVldCheck(.F., nI), x[nPsUQBCheck] := oOk, Nil)})
		Else
			IncProc(CAT544016)	//Marcando registros
			AEVal(oGetDadUQB:aCols, {|x| nI++, oGetDadUQB:GoTo(nI), IIf(fVldCheck(.F.), x[nPsUQBCheck] := oOk, Nil)})
		EndIf

	ElseIf nOpc == 2 /* Desmarcar todos */

		If l528Auto
			AEVal(aCoUQBAuto, {|x| nI++, x[nPsUQBCheck] := oNo})
		Else
			IncProc(CAT544017)	//"Desmarcando registros"
			AEVal(oGetDadUQB:aCols, {|x| nI++, oGetDadUQB:GoTo(nI), x[nPsUQBCheck] := oNo})
		EndIf

	ElseIf nOpc == 3 /* Inverter seleção */

		If l528Auto
			AEVal(aCoUQBAuto, {|x| nI++, x[nPsUQBCheck] := IIf(x[nPsUQBCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F., nI), oOk, oNo))})
		Else
			IncProc(CAT544018)	//"Invertendo seleção de registros"
			AEVal(oGetDadUQB:aCols, {|x| nI++, oGetDadUQB:GoTo(nI), x[nPsUQBCheck] := IIf(x[nPsUQBCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F.), oOk, oNo))})
		EndIf

	EndIf

	If !l528Auto
		oGetDadUQB:GoTo(nAt)
		oGetDadUQB:Refresh()
	EndIf

	StaticCall(PRT0528, fAltFilial, cFilBkp)

Return(Nil)

/*/{Protheus.doc} fIntegra
Realiza a integração dos dados das tabelas UQB e UQC gerando Pedido de Venda, Liberação e Nota Fiscal.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param lAgrupa, logical, descricao
@type function
/*/
Static Function fIntegra(lAgrupa)

	Local aRegs			:= {}
	Local aCab			:= {}
	Local aIte			:= {}
	Local aAtuGetDad	:= {}
	Local aRegAgru		:= {}
	Local aColsInt		:= {}
	Local aFatPed		:= {}

	Local cMensagem		:= ""
	Local cModBkp		:= ""
	Local cNF			:= ""
	Local cNumPed		:= ""
	Local cSerie		:= ""
	Local cStatus		:= ""
	Local cStatusUQB	:= ""
	Local cTipoProc		:= ""
	Local cIDImp		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local cTpCon		:= ""

	Local dDtBaseBkp	:= dDataBase

	Local lOk			:= .T.
	Local lMostraErro	:= .F.
	Local lSelect		:= .F.

	Local nI, nJ, nK	:= 0

	Local nLinha		:= 0
	Local nModBkp		:= 0
	Local nRecProc		:= 0
    Local cIdImpUqb     := ""

	Private cMsgDet		:= ""
	Private cRegistro	:= ""
	Private cCCusto		:= ""

	Private nOk			:= 0
	Private n544RecUQB	:= 0
	Private nErro		:= 0
	Private nValor		:= 0
    
    Private cBanco      := SuperGetMv("MV_XBCOCF",.F.,"341")
    Private cAgencia    := SuperGetMv("MV_XAGECF",.F.,"0113")
    Private cConta      := SuperGetMv("MV_XCTOCF",.F.,"14935")
    Private cPref       := "LOG"
    Private cNat        := SuperGetMV("MV_XNATCF",.F.,"202001")
    Private lMsErroAuto := .F.
	//Variáveis privadas movidas para a função inicial PRT0558
	cFornec	:= ""
	cFilArq		:= ""

	ProcRegua(0)
	IncProc()

	// Seta todos os logs anteriores como lidos
	fSetLido()

	//-- Grava informações do módulo atual
	StaticCall(PRT0528, fAltModulo, @cModBkp, @nModBkp)

	//-- Altera para o módulo de faturamento
	StaticCall(PRT0528, fAltModulo, "FAT", 5)

	If !l528Auto
		aColsInt := oGetDadUQB:aCols
	Else
		aColsInt := aCoUQBAuto
	EndIf

	For nI := 1 To Len(aColsInt)
		If aColsInt[nI,nPsUQBCheck]:cName == "LBOK"
			lSelect := .T.
			Exit
		EndIf
	Next nI

	If !lSelect
		lOk := .F.
		MsgAlert(CAT544019, "PRT0558 - Carta Frete") //"Nenhum registro selecionado para processamento."
	EndIf

	If lOk
		For nK := 1 To Len(aFiliais)
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nK,1])

			lOk := .T.

			aRegs := fGetRegSel(lAgrupa, aFiliais[nK,2])

			If Empty(aRegs)
				lOk := .F.
			EndIf

			If lOk
                For _ngr:= 1 to Len(aRegs)
                    DbSelectArea("UQB")
                    dbGoto(aRegs[_ngr,1])

                    // GRAVA PEDIDO DE COMPRA    
                    If UQB->UQB_IDIMP<>cIdImpUqb
                        cNumPed:= GetSXENum("SC7","C7_NUM")
                        ConfirmSX8()
                        RecLock("SC7",.T.)
                        SC7->C7_FILIAL  := xFilial("SC7")
                        SC7->C7_NUM     :=  cNumPed
                        SC7->C7_ITEM    := "001"
                        SC7->C7_TIPO    := 1
                        SC7->C7_PRODUTO := cPrd:= SuperGetMV("MV_XPRDCF",.F.,"SERV000062")
                        SC7->C7_DESCRI  := POSICIONE("SB1",1,xFilial("SB1")+cPrd,"B1_DESC")     
                        SC7->C7_UM      := SB1->B1_UM
                        SC7->C7_QUANT   := 1
                        SC7->C7_PRECO   := UQB->UQB_VLRPED//Val(oXml:_CARTASFRETES:_CARTAFRETE[i]:_VLFRETE:TEXT)
                        SC7->C7_TOTAL   := UQB->UQB_VLRPED//Val(oXml:_CARTASFRETES:_CARTAFRETE[i]:_VLFRETE:TEXT)
                        SC7->C7_LOCAL   := SB1->B1_LOCPAD
                        SC7->C7_DINICOM := Date()
                        SC7->C7_DINITRA := Date()
                        SC7->C7_DATPRF  := Date()
                        SC7->C7_DINICQ  := Date()
                        SC7->C7_FORNECE := UQB->UQB_FORNEC
                        SC7->C7_LOJA    := UQB->UQB_LOJA
                        SC7->C7_CONTA   := SB1->B1_CONTA
                        SC7->C7_COND    := UQB->UQB_CONPG 
                        SC7->C7_CONAPRO := "L"
                        SC7->C7_FILENT  :=  xFilial("SC7")
                        SC7->C7_EMISSAO := DATE()
                        SC7->C7_XIDCF   := RIGHT(UQB->UQB_IDIMP,9)//oXml:_CARTASFRETES:_CARTAFRETE[i]:_ID:TEXT
                        SC7->C7_XCFNUM  := UQB->UQB_NF//oXml:_CARTASFRETES:_CARTAFRETE[i]:_NUMERO:TEXT
                        SC7->(MsUnLock())
                    ENDIF
                    cIdImpUqb:=UQB->UQB_IDIMP
                    If !Empty(UQB->UQB_ADMCF)
						//GRAVA TITULO PA
						aArray:={}
						aAdd(aArray,{ "E2_PREFIXO" , cPref , NIL })
						aAdd(aArray,{ "E2_NUM" , cNumPed  , NIL })
						aAdd(aArray,{ "E2_PARCELA" , If(UQB->UQB_TPCF=="A","1","2") , NIL })
						aAdd(aArray,{ "E2_TIPO" , "PA" , NIL })
						aAdd(aArray,{ "E2_NATUREZ" , cNat , NIL })
						aAdd(aArray,{ "E2_FORNECE" , UQB->UQB_FORNEC , NIL })
						aAdd(aArray,{ "E2_LOJA"     ,  UQB->UQB_LOJA    , NIL })
						aAdd(aArray,{ "E2_EMISSAO" , Date(), NIL })
						aAdd(aArray,{ "E2_VENCTO" , Date(), NIL })
						aAdd(aArray,{ "E2_VENCREA" , Date(), NIL })
						aAdd(aArray,{ "E2_XCTRCF" , UQB->UQB_NF, NIL })
						aAdd(aArray,{ "E2_XNUMCF" , RIGHT(UQB->UQB_IDIMP,9), NIL })
						aAdd(aArray,{ "E2_VALOR" , UQB->UQB_VALOR , NIL })
						aAdd(aArray,{ "E2_XNUMPED" ,cNumPed  , NIL })
						aAdd(aArray,{ "E2_XTPCTE" , UQB->UQB_XTPCTE , NIL })
						aAdd(aArray,{ "E2_XCHVREF" , UQB->UQB_CTEREF , NIL })
						aAdd(aArray,{ "AUTBANCO" , cBanco , NIL })
						aAdd(aArray,{ "AUTAGENCIA" , cAgencia , NIL })
						aAdd(aArray,{ "AUTCONTA" , cConta , NIL })
						pergunte("FIN050",.F.)
						MV_PAR05:="2"
						MV_PAR09:="1"
						MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
						If !lMsErroAuto
							//AMARRAÇÃO PEDIDO ADIANTAMENTO
							RecLock("FIE",.T. )
							FIE->FIE_FILIAL	:= xFilial( "FIE" )
							FIE->FIE_CART	:= "P"
							FIE->FIE_PEDIDO	:= cNumPed
							FIE->FIE_PREFIX	:= SE2->E2_PREFIXO
							FIE->FIE_NUM	:= SE2->E2_NUM
							FIE->FIE_PARCEL	:= SE2->E2_PARCELA
							FIE->FIE_TIPO	:= SE2->E2_TIPO
							FIE->FIE_FORNEC	:= SE2->E2_FORNECE
							FIE->FIE_LOJA	:= SE2->E2_LOJA
							FIE->FIE_VALOR	:= SE2->E2_VALOR                        
							FIE->FIE_SALDO	:= SE2->E2_VALOR  
							FIE->FIE_FILORI := xFilial( "FIE" )							
							FIE->( MsUnLock() )

							cTpCf:= If (UQB->UQB_TPCF=="A","Adiantamneto","Saldo")						
							cStatus 	:= "I"
							cMensagem	:= "Foi Realizada Integração do contrato Frete de "+cTpCf+" numero "+UQB->UQB_NUMERO+" Gerou PC: "+SC7->C7_NUM+" e titulo PA "+SE2->E2_PREFIXO+"/"+SE2->E2_NUM
							cFornec	    := UQB->UQB_FORNEC
							cFilArq		:= UQB->UQB_FIL
							cRegistro	:= "CF"+SUBSTR(UQB->UQB_NUMERO,3,14)
							nValor		:= UQB->UQB_VALOR
							cIDImp		:= UQB->UQB_IDIMP
							cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])
							RecLock("UQB", .F.)
							UQB->UQB_PREFIX:= SE2->E2_PREFIXO
							UQB->UQB_TITULO:= SE2->E2_NUM 
							UQB->UQB_PARCEL:= SE2->E2_PARCELA
							UQB->UQB_TIPOTI:= SE2->E2_TIPO     
							UQB->UQB_STATUS:= "P"     
							UQB->UQB_PEDIDO:= cNumPed
							UQB->UQB_RECSE2:= SE2->(Recno())
							MsUnlock()
							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							nOk++
						ELSE
							cMsgDet:=MostraErro("C:\Temp","erroPa.txt") 
							cStatus 	:= "E"
							cMensagem	:= "Erro na nGeração do Titulo PA"
							cFornec	    := UQB->UQB_FORNEC
							cFilArq		:= UQB->UQB_FIL
							cRegistro	:= "CF"+SUBSTR(UQB->UQB_NUMERO,3,14)
							nValor		:= UQB->UQB_VALOR
							cIDImp		:= UQB->UQB_IDIMP
							cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])
							nErro++
							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						EndIf    
					else
						cTpCf:= If (UQB->UQB_TPCF=="A","Adiantamneto","Saldo")						
						cStatus 	:= "I"
						cMensagem	:= "Foi Realizada Integração do contrato Frete de "+cTpCf+" numero "+UQB->UQB_NUMERO+" Gerou PC: "+SC7->C7_NUM+"."
						cFornec	    := UQB->UQB_FORNEC
						cFilArq		:= UQB->UQB_FIL
						cRegistro	:= "CF"+SUBSTR(UQB->UQB_NUMERO,3,14)
						nValor		:= UQB->UQB_VALOR
						cIDImp		:= UQB->UQB_IDIMP
						cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])
						RecLock("UQB", .F.)
						UQB->UQB_PREFIX:= SE2->E2_PREFIXO
						UQB->UQB_TITULO:= SE2->E2_NUM 
						UQB->UQB_PARCEL:= SE2->E2_PARCELA
						UQB->UQB_TIPOTI:= SE2->E2_TIPO     
						UQB->UQB_STATUS:= "P"     
						UQB->UQB_PEDIDO:= cNumPed
						UQB->UQB_RECSE2:= SE2->(Recno())
						MsUnlock()
						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						nOk++
					EndIf	
                Next _ngr
			EndIf
		Next nK
	EndIf

	dDataBase := dDtBaseBkp

	//-- Atualização das informações na GetDados
	If !l528Auto
		If !Empty(aAtuGetDad)
			fAtuGetDad(aAtuGetDad)
		EndIf
	EndIf

	fGrvLog()

	If !l528Auto
		// Exibe mensagem
		cMensagem 	:= 	 "Processamento de arquivos Carta Frete finalizado. Verifique o resultado abaixo." + CRLF +; // "Processamento de arquivos CTE/CRT finalizado. Verifique o resultado abaixo."
						CRLF + CAT544031 + cValToChar(nOk) + CRLF +; // "Itens processados: "
						CAT544032 + cValToChar(nErro) + CRLF +; // "Itens não processados: "
						CRLF + CAT544033 // "Deseja visualizar o log de processamento?"

		If MsgYesNo( cMensagem, "PRT0558 - Carta Frete" )

			// Chama o programa de visualização de log de registros.
			U_PRT0533( "UQF", .T., Nil, "INT" )
		EndIf
	EndIf
	fFillDados()
	//-- Retorna para o módulo de origem
	StaticCall(PRT0528, fAltModulo, cModBkp, nModBkp)

Return(Nil)

/*/{Protheus.doc} fGetRegSel
Retorna os Recnos dos registros selecionados para a integração agrupados ou não, conforma a opção do usuário.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return aRegs, Array com os registros selecionados e agrupados
@param lAgrupa, logical, Indica se os registros devem ou não ser agrupados
@param cFilReg, caracter, Filial do registro selecionado
@type function
/*/
Static Function fGetRegSel(lAgrupa, cFilReg)
	Local aInfo		:= {}
	Local aAux		:= {}
	Local aRegs 	:= {}
	Local cCodCli	:= ""
	Local cLojaCli	:= ""
	Local nRecnoUQB	:= 0
	Local nI 		:= 0
	Local nJ		:= 0
	Local nLen		:= 0
	Local nLenRegs	:= 0

	If !l528Auto
		aAux := AClone(oGetDadUQB:aCols)
	Else
		aAux := AClone(aCoUQBAuto)
	EndIf

	//-- Ajusta array aInfo com somente os registros da filial que está sendo processada
	For nI := 1 To Len(aAux)
		If aAux[nI,nPsUQBFilial] == cFilReg
			Aadd(aInfo, aAux[nI])
		EndIf
	Next nI

	If lAgrupa
		//-- Ordena o array da UQB por Fornecedor, loja e recno
		ASort(aInfo,,,{|x,y| x[nPsUQBFornec] + x[nPsUQBLoja] + StrZero(x[nPsUQBRecno],10) < y[nPsUQBFornec] + y[nPsUQBLoja] + StrZero(y[nPsUQBRecno],10)})

		aAux := AClone(aInfo)
		aInfo := {}

		//-- Separa os itens selecionados pelo usuário
		AEval(aAux, {|x| IIf(x[nPsUQBCheck]:cName == "LBOK", Aadd(aInfo, x), Nil)})

		nLen := Len(aInfo)

		For nI := 1 To nLen

			cCodCli   := aInfo[nI,nPsUQBFornec]
			cLojaCli  := aInfo[nI,nPsUQBLoja]

			Aadd(aRegs, {})

			nLenRegs := Len(aRegs)

			While nI <= nLen .And. cCodCli == aInfo[nI,nPsUQBFornec]
				nRecnoUQB := aInfo[nI,nPsUQBRecno]

				Aadd(aRegs[nLenRegs], nRecnoUQB)

				If nI+1 <= nLen .And. cCodCli == aInfo[nI+1,nPsUQBFornec]
					nI++
				Else
					Exit
				EndIf
			EndDo
		Next nI

		//-- Separa os registros de cancelamento dos registros de inclusão em caso de agrupamento
		aAux := {}
		aAux := AClone(aRegs)
		aRegs := {}

		For nI := 1 To Len(aAux)
			Aadd(aRegs, {})

			For nJ := 1 To Len(aAux[nI])
				If fVerCancel( {aAux[nI,nJ]} )
					Aadd(aRegs, {aAux[nI,nJ]})
				Else
					Aadd(aRegs[nI], aAux[nI,nJ])
				EndIf
			Next nJ
		Next nI
	Else
		aAux := AClone(aInfo)
		aInfo := {}

		//-- Separa os itens selecionados pelo usuário
		AEval(aAux, {|x| IIf(x[nPsUQBCheck]:cName == "LBOK", Aadd(aInfo, x), Nil)})

		For nI := 1 To Len(aInfo)
			nRecnoUQB := aInfo[nI,nPsUQBRecno]

			Aadd(aRegs, {nRecnoUQB})
		Next nI
	EndIf
Return(aRegs)

/*/{Protheus.doc} fVerCancel
Verifica se é um registro de cancelamento.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lCancela, Indica se é um registro de cancelamento
@param aRegs, array, Registros a serem processados
@type function
/*/
Static Function fVerCancel(aRegs)
	Local aAreas	:= {}
	Local lCancela 	:= .F.
	Local nI		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	DbSelectArea("UQB")

	For nI := 1 To Len(aRegs)
		UQB->(DbGoTo(aRegs[nI]))

		If UQB->(Recno()) == aRegs[nI]
			lCancela := UQB->UQB_CANCEL == "C"
		EndIf
	Next nI

	fRestAreas(aAreas)
Return(lCancela)

/*/{Protheus.doc} fVerReproc
Verifica se é um registro de cancelamento.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lReproc, Indica se é um registro de reprocessamento
@param aRegs, array, Registros a serem processados
@type function
/*/
Static Function fVerReproc(aRegs)
	Local aAreas	:= {}
	Local lReproc 	:= .F.
	Local nI		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	DbSelectArea("UQB")

	For nI := 1 To Len(aRegs)
		UQB->(DbGoTo(aRegs[nI]))

		If UQB->(Recno()) == aRegs[nI]
			lReproc := UQB->UQB_CANCEL == "R"
		EndIf
	Next nI

	fRestAreas(aAreas)
Return(lReproc)

/*/{Protheus.doc} fGetTpProc
Verifica o tipo de processamento (Inclusão, cancelamento ou reprocessamento).
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return cTipoProc, Tipo de processamento
@param aRegs, array, Registros a serem processados
@type function
/*/
Static Function fGetTpProc(aRegs)
	Local cTipoProc := ""

	If fVerCancel(aRegs)
		cTipoProc := "C" // Cancelamento
	EndIf

	If Empty(cTipoProc)
		If fVerReproc(aRegs)
			cTipoProc := "R" // Reprocessamento
		EndIf
	EndIf

	If Empty(cTipoProc)
		cTipoProc := "I" // Inclusao
	EndIf
Return(cTipoProc)

/*/{Protheus.doc} fVldDados
Valida se todos os dados necessários para gerar o pedido de venda estão disponí­veis.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lValid, Indica se os dados são válidos
@param aRegs, array, Registros a serem processados
@param aErros, array, Array com erros ocorridos ao validar (Referência)
@param aRegAgru, array, Array que armazena os registros que foram agrupados (apenas em caso de cancelamento) (Referência)
@param lAgrupa, logico, Indica se o usuário selecionou o agrupamento
@param aRegsTot, array, Array com todos os registros selecionados pelo usuário e separados por agrupamento
@type function
/*/
Static Function fVldDados(aRegs, aRegAgru, lAgrupa, aRegsTot)
	Local aAreas		:= {}
	Local aAreaSM2		:= {}
	Local aCancela		:= {}
	Local aColsVld		:= {}
	Local aOriDes		:= {}
	Local aOrigem		:= {}
	Local aDestino		:= {}

	Local cCampoSM2		:= ""
	Local cCancela		:= ""
	Local cMensagem		:= ""
	Local cMsgAgrup		:= ""
	Local cStatus		:= ""
	Local cIDImp		:= ""
	Local cTes			:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local cMoeda		:= ""

	Local lValid 		:= .T.

	Local nI			:= 0
	Local nJ			:= 0
	Local nK			:= 0
	Local nLinha		:= 0
	Local nMoeda		:= 0
	Local nPos			:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))
	Aadd(aAreas, UQC->(GetArea()))
	Aadd(aAreas, SA2->(GetArea()))
	Aadd(aAreas, SE4->(GetArea()))
	Aadd(aAreas, SED->(GetArea()))
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SF4->(GetArea()))
	Aadd(aAreas, CTT->(GetArea()))

	If !l528Auto
		aColsVld := AClone(oGetDadUQB:aCols)
	Else
		aColsVld := AClone(aCoUQBAuto)
	EndIf

	DbSelectArea("UQB") ; UQB->(DbSetOrder(1)) // UQB_FILIAL+UQB_IDIMP
	DbSelectArea("UQC") ; UQC->(DbSetOrder(1)) // UQC_FILIAL+UQC_IDIMP+UQC_ITEM
	DbSelectArea("SA2") ; SA2->(DbSetOrder(1)) // A2_FILIAL+A2_COD+A2_LOJA
	DbSelectArea("SE4") ; SE4->(DbSetOrder(1)) // E4_FILIAL+E4_CODIGO
	DbSelectArea("SED") ; SED->(DbSetOrder(1)) // ED_FILIAL+ED_CODIGO
	DbSelectArea("SB1") ; SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
	DbSelectArea("SF4") ; SF4->(DbSetOrder(1)) // F4_FILIAL+F4_CODIGO
	DbSelectArea("CTT") ; CTT->(DbSetOrder(1)) // CTT_FILIAL+CTT_CUSTO

	If lFaturaPed
		DbSelectArea("CC2") ; CC2->(DbSetOrder(1)) // CC2_FILIAL+CC2_EST+CC2_CODMUN
	EndIf

	For nI := 1 To Len(aRegs)
		UQB->(DbGoTo(aRegs[nI]))

		If UQB->(Recno()) == aRegs[nI]
			// Define o registro e o Fornecedor que está sendo validado
			cFornec 	:= UQB->UQB_FORNEC
			cFilArq		:= UQB->UQB_FIL
			cRegistro 	:= UQB->UQB_NUMERO
			nValor		:= UQB->UQB_VALOR
			cIDImp		:= UQB->UQB_IDIMP

			If UQB->UQB_CANCEL == "C"
				Aadd(aCancela, {UQB->UQB_NUMERO, aRegs[nI]})
				cCancelLog := "C"
			ElseIf UQB->UQB_CANCEL == "R"
				cCancelLog := "R"
			Else
				cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
			EndIf

			// -------------------------------------------------------------------------------
			// Validação do cabeçalho
			// -------------------------------------------------------------------------------

			// Validação do Fornecedor
			If !SA2->(DbSeek(xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA))

				lValid 		:= .F.
				cStatus 	:= "E"
				cMensagem	:= "Fornecedor não cadastrado."//CAT544034 //"Fornecedor não cadastrado."

				aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
				//fGrvLog(nLinha, cMensagem, cStatus)
			Else		

				If SA2->A2_MSBLQL == "1" // Bloqueado

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544035 //Fornecedor bloqueado.

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				//-- Validação da condição de pagamento
				If Empty(SA2->A2_COND)

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= "Condição de pagamento não informada no cadastro do Fornecedor."//CAT544036 //"Condição de pagamento não informada no cadastro do cliente.

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				If !SE4->(DbSeek(xFilial("SE4") + SA2->A2_COND))

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544037 //"Condição de pagamento não cadastrada."

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				If lFaturaPed

					cMoeda := UQB->UQB_MOEDA

					nMoeda := fDefMoeda(cMoeda)

					If nMoeda != 1
						aAreaSM2 := SM2->(GetArea())

						DbSelectArea("SM2")
						SM2->(DbSetOrder(1)) // M2_DATA

						If SM2->(DbSeek(UQB->UQB_EMISSA))
							cCampoSM2 := "SM2->M2_MOEDA" + cValToChar(nMoeda)

							If &(cCampoSM2) == 0
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544111  + DToC(UQB->UQB_EMISSA) + "."//"Moeda sem cotação para o dia "

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf

						EndIf

						RestArea(aAreaSM2)
					EndIf

					If SE4->E4_MSBLQL == "1" // Bloqueado

						lValid 		:= .F.
						cStatus 	:= "E"
						cMensagem	:= CAT544038 //"Condição de pagamento bloqueada."

						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf
				EndIf
			EndIf

			//-- Validação do Centro de Custo
			If !Empty(UQB->UQB_CCUSTO)
				If !CTT->(DbSeek(xFilial("CTT") + UQB->UQB_CCUSTO))

					lValid		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544092 + ": " + UQB->UQB_CCUSTO // Centro de Custo não encontrado

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf
			EndIf

			If lFaturaPed
				//-- Validação do estado e município de origem e destino
				If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
					aOriDes		:= fGetOriDes(UQB->UQB_TPCON, UQB->UQB_UFCOL, UQB->UQB_UFDES, UQB->UQB_MUNCOL)
					aOrigem  	:= aOriDes[1]
					aDestino 	:= aOriDes[2]

					If !Empty(aOrigem)
						If !Empty(aOrigem[1]) .And. !Empty(aOrigem[2])
							aOrigem[1] := PadR(aOrigem[1], TamSX3("CC2_EST"   )[1])
							aOrigem[2] := PadR(aOrigem[2], TamSX3("CC2_CODMUN")[1])

							If !CC2->(DbSeek(xFilial("CC2") + aOrigem[1] + aOrigem[2]))
								lValid		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544114 // "Estado e município de origem inválidos."
								cMensagem	+= CAT544116 + AllTrim(aOrigem[1]) // " Estado: "
								cMensagem	+= CAT544117 + AllTrim(aOrigem[2]) // " Município: "

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						EndIf
					EndIf

					If !Empty(aDestino)
						If !Empty(aDestino[1]) .And. !Empty(aDestino[2])
							aDestino[1] := PadR(aDestino[1], TamSX3("CC2_EST"   )[1])
							aDestino[2] := PadR(aDestino[2], TamSX3("CC2_CODMUN")[1])

							If !CC2->(DbSeek(xFilial("CC2") + aDestino[1] + aDestino[2]))
								lValid		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544115 // "Estado e município de destino inválidos."
								cMensagem	+= CAT544116 + AllTrim(aDestino[1]) // " Estado: "
								cMensagem	+= CAT544117 + AllTrim(aDestino[2]) // " Município: "

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf

			// -------------------------------------------------------------------------------
			// Validação dos itens
			// -------------------------------------------------------------------------------
			If UQC->(DbSeek(UQB->UQB_FILIAL + UQB->UQB_IDIMP))
				While !UQC->(EoF()) .And. UQC->UQC_FILIAL == UQB->UQB_FILIAL .And. UQC->UQC_IDIMP == UQB->UQB_IDIMP
					//-- Validação do produto
					If !SB1->(DbSeek(xFilial("SB1") + UQC->UQC_PRODUT))

						lValid 		:= .F.
						cStatus 	:= "E"
						cMensagem	:= CAT544039 //"Produto não cadastrado."

						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					Else
						If SB1->B1_MSBLQL == "1" // Bloqueado

							lValid 		:= .F.
							cStatus 	:= "E"
							cMensagem	:= CAT544040 //"Produto bloqueado.

							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf

						//Comentado por solicitação Marcos dia 17/06/2019
						//-- Validação da TES
						/*If Empty(SB1->B1_TS)

							lValid 		:= .F.
							cStatus 	:= "E"
							cMensagem	:= CAT544041 //"TES não informada no cadastro do produto.

							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						Else*/
							cTes := fDefTes()

							If !SF4->(DbSeek(xFilial("SF4") + cTes))
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544042 //"TES não cadastrada.

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							ElseIf SF4->F4_MSBLQL == "1" // Bloqueado
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544043 //"TES bloqueada.

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						//EndIf
					EndIf

					UQC->(DbSkip())
				EndDo
			EndIf
		EndIf
	Next nI

	If lValid
		/*
		Em caso de cancelamento, verifica se o Pedido e Nota Fiscal foram gerados de forma
		agrupada, ou seja, o mesmo pedido e NF foi gerado para mais de um CTE/CRT
		*/
		If !Empty(aCancela)
			cCancela := Space(TamSX3("UQB_CANCEL")[1])

			For nI := 1 To Len(aCancela)
				//-- Busca o registro de inclusão
				DbSelectArea("UQB")
				UQB->(DbSetOrder(2)) //UQB_FILIAL+UQB_NUMERO+UQB_CANCEL
				If UQB->(DbSeek(xFilial("UQB") + aCancela[nI,1] + cCancela))
					If !Empty(UQB->UQB_PEDIDO) .And. !Empty(UQB->UQB_NF) .And. !Empty(UQB->UQB_SERIE)

						cMsgAgrup += fVerAgrupa(UQB->UQB_PEDIDO, UQB->UQB_NF, UQB->UQB_SERIE, @aRegAgru)

					ElseIf (nPos := AScan(aColsVld, {|x| x[nPsUQBRecno] == UQB->(Recno())})) > 0

						If aColsVld[nPos,nPsUQBCheck]:cName == "LBOK" // Registro selecionado
							Aadd(aRegAgru, UQB->(Recno()))
						EndIf

						//-- Em caso de agrupamento, adiciona os demais Recnos dos registros selecionados pelo
						//-- usuário para que possam ficar disponí­veis novamente para integração
						If lAgrupa
							For nJ := 1 To Len(aRegsTot)
								If (nPos := AScan(aRegsTot[nJ], {|x| x == UQB->(Recno())})) > 0
									For nK := 1 To Len(aRegsTot[nJ])
										If nK != nPos
											Aadd(aRegAgru, aRegsTot[nJ,nK])
										EndIf
									Next nK
								EndIf
							Next nJ
						EndIf

					EndIf
				EndIf
			Next nI

			If !Empty(cMsgAgrup)
				lValid := MsgYesNo(CAT544044 + CRLF + CAT544045 + CRLF + CRLF + cMsgAgrup, "PRT0558 - Carta Frete") //"Um ou mais registros de cancelamento selecionados foi integrado ao Protheus de forma agrupada com outros CTE/CRT."
																									  //"Confirma o cancelamento do Pedido de Venda e das Notas Fiscais abaixo para todos os CTE/CRT?"
				If !lValid

					For nI := 1 To Len(aCancela)
						cStatus 	:= "E"
						cMensagem	:= CAT544046 //"Processamento cancelado pelo usuário."
						cCancelLog	:= "C"

						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					Next
				EndIf
			EndIf
		EndIf
	Else
		nErro++
	EndIf

	fRestAreas(aAreas)
Return(lValid)

/*/{Protheus.doc} fMontaPed
Faz a montagem dos arrays de cabeçalho e itens do pedido de venda para passar para o ExecAuto Mata410.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return cNum, Numero do pedido de venda que será gerado
@param aRegs, array, Registros da tabela UQB para a geração do pedido de venda
@param aCabec, array, Cabeçalho do pedido (Referência)
@param aItens, array, Itens do pedido (Referência)
@param nOpc, numerico, Opção (3=Inclusão ou 5=Exclusão)
@param cPedido, caracter, Numero do pedido (Somente em caso de Exclusão)
@param lReprocess, logico, Indica se é um reprocessamento
@type function
/*/
Static Function fMontaPed(aRegs, aCabec, aItens, nOpc, cPedido, lReprocess, nValPed)
	Local aAreas	:= {}
	Local aLinha	:= {}
	Local aOriDes	:= {}
	Local aOrigem	:= {}
	Local aDestino	:= {}
	Local cNum 		:= ""
	Local cNumUQB	:= "" //Num CTE sem série
	Local cItem		:= ""
	Local cCondPag	:= ""
	Local cTES		:= ""
	Local cNatureza	:= ""
	Local nI		:= 0
	Local nMoeda	:= 0
	Local nQtde		:= 1
	Local nTotPed	:= 0 //Usado em um reprocessamento

	Default cPedido	:= ""
	Default lReprocess := .F.
	Default nValPed := 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))
	Aadd(aAreas, UQC->(GetArea()))
	Aadd(aAreas, SA2->(GetArea()))
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SC5->(GetArea()))
	Aadd(aAreas, SC6->(GetArea()))

	DbSelectArea("UQB") ; UQB->(DbSetOrder(1)) // UQB_FILIAL+UQB_IDIMP
	DbSelectArea("UQC") ; UQC->(DbSetOrder(1)) // UQC_FILIAL+UQC_IDIMP+UQC_ITEM
	DbSelectArea("SC5") ; SC5->(DbSetOrder(1)) // C5_FILIAL+C5_NUM
	DbSelectArea("SC6") ; SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

	If nOpc == 3
		For nI := 1 To Len(aRegs)
			UQB->(DbGoTo(aRegs[nI]))
			If UQB->(Recno()) == aRegs[nI]
				dDataBase  := UQB->UQB_EMISSA
				n544RecUQB := UQB->(Recno())

				If Empty(aCabec)

					If !lFaturaPed .And. lReprocess

						cNum := cPedido
					Else
						cNum := GetSXENum("SC5","C5_NUM")
						RollBackSx8()
					EndIf

					// Recupera o número do arquivo sem Série
					cNumUQB	:= UQB->UQB_NUMERO

					//Comentado dia 30/09/2019 por solicitação Veloce - Icaro
					//No cabeçalho e item deve ser gravado o mesmo conteudo do campo UQB-UQB_NUMERO
					/*If At("-", cNumUQB) > 0
						cNumUQB	:= Left(cNumUQB, At("-", cNumUQB)-1)
					EndIf*/

					nMoeda		:= fDefMoeda(UQB->UQB_MOEDA)
					cCondPag 	:= Posicione("SA2",1,xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA,"A2_COND")
					cNatureza	:= Posicione("SA2",1,xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA,"A2_NATUREZ") //fGetNaturez(UQB->UQB_TPCON, UQB->UQB_FORNEC, UQB->UQB_LOJA)

					If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
						aOriDes		:= fGetOriDes(UQB->UQB_TPCON, UQB->UQB_UFCOL, UQB->UQB_UFDES, UQB->UQB_MUNCOL)
						aOrigem  	:= aOriDes[1]
						aDestino 	:= aOriDes[2]
					EndIf

					Aadd(aCabec, {"C5_NUM"		, cNum				, Nil})
					Aadd(aCabec, {"C5_TIPO" 	, "N"				, Nil})
					Aadd(aCabec, {"C5_CLIENTE"	, UQB->UQB_FORNEC	, Nil})
					Aadd(aCabec, {"C5_LOJACLI"	, UQB->UQB_LOJA	, Nil})
					Aadd(aCabec, {"C5_CLIENT"	, UQB->UQB_FORNEC	, Nil})
					Aadd(aCabec, {"C5_LOJAENT"	, UQB->UQB_LOJA	, Nil})
					Aadd(aCabec, {"C5_CONDPAG"	, cCondPag			, Nil})
					Aadd(aCabec, {"C5_EMISSAO"	, UQB->UQB_EMISSA	, Nil})
					Aadd(aCabec, {"C5_MOEDA"	, nMoeda			, Nil})
					Aadd(aCabec, {"C5_PEDECOM"	, cNumUQB			, Nil})
					Aadd(aCabec, {"C5_NATUREZ"	, cNatureza			, Nil})

					If !Empty(aOrigem)
						If !Empty(aOrigem[1])
							Aadd(aCabec, {"C5_UFORIG"	, aOrigem[1]		, Nil})
						EndIf

						If !Empty(aOrigem[2])
							Aadd(aCabec, {"C5_CMUNOR"	, aOrigem[2]		, Nil})
						EndIf
					EndIf

					If !Empty(aDestino)
						If !Empty(aDestino[1])
							Aadd(aCabec, {"C5_UFDEST"	, aDestino[1]		, Nil})
						EndIf

						If !Empty(aDestino[2])
							Aadd(aCabec, {"C5_CMUNDE"	, aDestino[2]		, Nil})
						EndIf
					EndIf

					If !lFaturaPed .And. lReprocess
						Aadd(aCabec, {"C5_XHIST", CAT544102 + AllTrim(UQB->UQB_CHVCTE) + " " + CAT544110 + cValToChar(nValPed), Nil}) //"C.C: " # "Valor: "

						//Complemento para gravação de pedido no campo C5_XHIST comentado dia 20/09/2019
						//+ "  " + CAT544104 + AllTrim(SC5->C5_NUM)// # "Pedido: "

					EndIf

					cItem := StrZero(0, TamSX3("C6_ITEM")[1])
				EndIf

				If UQC->(DbSeek(UQB->UQB_FILIAL + UQB->UQB_IDIMP))
					While !UQC->(EoF()) .And. UQC->UQC_FILIAL == UQB->UQB_FILIAL .And. UQC->UQC_IDIMP == UQB->UQB_IDIMP
						cItem := Soma1(cItem)
						cTES := fDefTes()

						aLinha := {}

						Aadd(aLinha, {"C6_ITEM"		, cItem						, Nil})
						Aadd(aLinha, {"C6_PRODUTO"	, UQC->UQC_PRODUT			, Nil})
						Aadd(aLinha, {"C6_QTDVEN"	, nQtde						, Nil})
						Aadd(aLinha, {"C6_PRCVEN"	, UQC->UQC_PRCVEN			, Nil})
						Aadd(aLinha, {"C6_PRUNIT"	, UQC->UQC_PRCVEN			, Nil})
						Aadd(aLinha, {"C6_VALOR"	, nQtde * UQC->UQC_PRCVEN 	, Nil})
						Aadd(aLinha, {"C6_TES"		, cTES						, Nil})
						Aadd(aLinha, {"C6_PEDCLI"	, UQB->UQB_NUMERO			, Nil})

						If lFaturaPed
							Aadd(aLinha, {"C6_CC"		, UQB->UQB_CCUSTO			, Nil})
						Else
							Aadd(aLinha, {"C6_CCUSTO"	, UQB->UQB_CCUSTO			, Nil})
						EndIf

						cCCusto := UQB->UQB_CCUSTO

						Aadd(aItens,aLinha)

						UQC->(DbSkip())
					EndDo
				EndIf
			EndIf
		Next nI
	ElseIf nOpc == 4

		If SC5->(DbSeek(xFilial("SC5") + cPedido))
			For nI := 1 To Len(aRegs)
				UQB->(DbGoTo(aRegs[nI]))
				If UQB->(Recno()) == aRegs[nI]
					n544RecUQB := UQB->(Recno())

					// Recupera o número do arquivo sem Série
					cNumUQB	:= UQB->UQB_NUMERO

					//Comentado dia 30/09/2019 por solicitação Veloce - Icaro
					//No cabeçalho e item deve ser gravado o mesmo conteudo do campo UQB-UQB_NUMERO
					/*If At("-", cNumUQB) > 0
						cNumUQB	:= Left(cNumUQB, At("-", cNumUQB)-1)
					EndIf*/

					nMoeda		:= fDefMoeda(UQB->UQB_MOEDA)
					cCondPag 	:= Posicione("SA2",1,xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA,"A2_COND")
					cNatureza	:= Posicione("SA2",1,xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA,"A2_NATUREZ") //fGetNaturez(UQB->UQB_TPCON, UQB->UQB_FORNEC, UQB->UQB_LOJA)

					If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
						aOriDes		:= fGetOriDes(UQB->UQB_TPCON, UQB->UQB_UFCOL, UQB->UQB_UFDES, UQB->UQB_MUNCOL)
						aOrigem  	:= aOriDes[1]
						aDestino 	:= aOriDes[2]
					EndIf

					dDataBase  := SC5->C5_EMISSAO

					Aadd(aCabec, {"C5_NUM"		, SC5->C5_NUM		, Nil})
					Aadd(aCabec, {"C5_TIPO" 	, SC5->C5_TIPO		, Nil})
					Aadd(aCabec, {"C5_CLIENTE"	, SC5->C5_CLIENTE	, Nil})
					Aadd(aCabec, {"C5_LOJACLI"	, SC5->C5_LOJACLI	, Nil})
					Aadd(aCabec, {"C5_CLIENT"	, SC5->C5_CLIENT	, Nil})
					Aadd(aCabec, {"C5_LOJAENT"	, SC5->C5_LOJAENT	, Nil})
					Aadd(aCabec, {"C5_EMISSAO"	, UQB->UQB_EMISSA	, Nil})
					Aadd(aCabec, {"C5_CONDPAG"	, cCondPag			, Nil})
					Aadd(aCabec, {"C5_MOEDA"	, nMoeda			, Nil})
					Aadd(aCabec, {"C5_PEDECOM"	, cNumUQB			, Nil})
					Aadd(aCabec, {"C5_NATUREZ"	, cNatureza			, Nil})

					If !Empty(aOrigem)
						If !Empty(aOrigem[1])
							Aadd(aCabec, {"C5_UFORIG"	, aOrigem[1]		, Nil})
						EndIf

						If !Empty(aOrigem[2])
							Aadd(aCabec, {"C5_CMUNOR"	, aOrigem[2]		, Nil})
						EndIf
					EndIf

					If !Empty(aDestino)
						If !Empty(aDestino[1])
							Aadd(aCabec, {"C5_UFDEST"	, aDestino[1]		, Nil})
						EndIf

						If !Empty(aDestino[2])
							Aadd(aCabec, {"C5_CMUNDE"	, aDestino[2]		, Nil})
						EndIf
					EndIf

					/*If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
						Aadd(aCabec, {"C5_UFORIG"	, SC5->C5_UFORIG	, Nil})
						Aadd(aCabec, {"C5_CMUNOR"	, SC5->C5_CMUNOR	, Nil})
						Aadd(aCabec, {"C5_UFDEST"	, SC5->C5_UFDEST	, Nil})
						Aadd(aCabec, {"C5_CMUNDE"	, SC5->C5_CMUNDE	, Nil})
					EndIf*/
				EndIf
			Next nI

			If SC6->(DbSeek(xFilial("SC6") + SC5->C5_NUM))
				While !SC6->(EoF()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. SC6->C6_NUM == SC5->C5_NUM
					aLinha := {}
					nTotPed += SC6->C6_VALOR

					Aadd(aLinha, {"LINPOS"		, "C6_ITEM"			, SC6->C6_ITEM})
					Aadd(aLinha, {"C6_PRODUTO"	, SC6->C6_PRODUTO	, Nil})
					Aadd(aLinha, {"C6_QTDVEN"	, SC6->C6_QTDVEN	, Nil})
					Aadd(aLinha, {"C6_PRCVEN"	, SC6->C6_PRCVEN	, Nil})
					Aadd(aLinha, {"C6_PRUNIT"	, SC6->C6_PRUNIT	, Nil})
					Aadd(aLinha, {"C6_VALOR"	, SC6->C6_VALOR 	, Nil})
					Aadd(aLinha, {"C6_TES"		, SC6->C6_TES		, Nil})
					Aadd(aLinha, {"C6_PEDCLI"	, SC6->C6_PEDCLI	, Nil})

					If lFaturaPed
						Aadd(aLinha, {"C6_CC"		, SC6->C6_CC		, Nil})
					Else
						Aadd(aLinha, {"C6_CCUSTO"	, SC6->C6_CCUSTO	, Nil})
					EndIf

					Aadd(aLinha, {"AUTDELETA"	, "S"				, Nil})

					cCCusto := SC6->C6_CCUSTO

					Aadd(aItens,aLinha)

					SC6->(DbSkip())
				EndDo
			EndIf

			DbSelectArea("UQB")

			cItem := StrZero(0, TamSX3("C6_ITEM")[1])

			For nI := 1 To Len(aRegs)
				UQB->(DbGoTo(aRegs[nI]))
				If UQB->(Recno()) == aRegs[nI]

					If UQC->(DbSeek(xFilial("UQC") + UQB->UQB_IDIMP))
						While !UQC->(EoF()) .And. UQC->UQC_FILIAL == xFilial("UQC") .And. UQC->UQC_IDIMP == UQB->UQB_IDIMP
							cItem := Soma1(cItem)
							cTES := fDefTes()

							aLinha := {}

							Aadd(aLinha, {"C6_ITEM"		, cItem						, Nil})
							Aadd(aLinha, {"C6_PRODUTO"	, UQC->UQC_PRODUT			, Nil})
							Aadd(aLinha, {"C6_QTDVEN"	, nQtde						, Nil})
							Aadd(aLinha, {"C6_PRCVEN"	, UQC->UQC_PRCVEN			, Nil})
							Aadd(aLinha, {"C6_PRUNIT"	, UQC->UQC_PRCVEN			, Nil})
							Aadd(aLinha, {"C6_VALOR"	, nQtde * UQC->UQC_PRCVEN 	, Nil})
							Aadd(aLinha, {"C6_TES"		, cTES						, Nil})
							Aadd(aLinha, {"C6_PEDCLI"	, UQB->UQB_NUMERO			, Nil})

							If lFaturaPed
								Aadd(aLinha, {"C6_CC"		, UQB->UQB_CCUSTO			, Nil})
							Else
								Aadd(aLinha, {"C6_CCUSTO"	, UQB->UQB_CCUSTO			, Nil})
							EndIf

							cCCusto := UQB->UQB_CCUSTO

							Aadd(aItens,aLinha)

							UQC->(DbSkip())
						EndDo
					EndIf

					//O array aRegs conterá apenas um RECNO se for um reprocessamento
					/*If !lFaturaPed .And. lReprocess
						Aadd(aCabec, {"C5_XHIST", CAT544102 + AllTrim(UQB->UQB_CHVCTE) + " " + CAT544110 + cValToChar(nTotPed), Nil}) //"C.C: " # "Valor: "

						//Complemento para gravação de pedido no campo C5_XHIST comentado dia 20/09/2019
						//+ "  " + CAT544104 + AllTrim(SC5->C5_NUM)// # "Pedido: "

					EndIf*/

				EndIf
			Next nI
		EndIf
	ElseIf nOpc == 5
		If SC5->(DbSeek(xFilial("SC5") + cPedido))
			Aadd(aCabec, {"C5_NUM"		, SC5->C5_NUM		, Nil})
			Aadd(aCabec, {"C5_TIPO" 	, SC5->C5_TIPO		, Nil})
			Aadd(aCabec, {"C5_CLIENTE"	, SC5->C5_CLIENTE	, Nil})
			Aadd(aCabec, {"C5_LOJACLI"	, SC5->C5_LOJACLI	, Nil})
			Aadd(aCabec, {"C5_CLIENT"	, SC5->C5_CLIENT	, Nil})
			Aadd(aCabec, {"C5_LOJAENT"	, SC5->C5_LOJAENT	, Nil})
			Aadd(aCabec, {"C5_CONDPAG"	, SC5->C5_CONDPAG	, Nil})
			Aadd(aCabec, {"C5_EMISSAO"	, SC5->C5_EMISSAO	, Nil})
			Aadd(aCabec, {"C5_MOEDA"	, SC5->C5_MOEDA		, Nil})
			Aadd(aCabec, {"C5_PEDECOM"	, SC5->C5_PEDECOM	, Nil})
			Aadd(aCabec, {"C5_NATUREZ"	, SC5->C5_NATUREZ	, Nil})

			If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
				Aadd(aCabec, {"C5_UFORIG"	, SC5->C5_UFORIG	, Nil})
				Aadd(aCabec, {"C5_CMUNOR"	, SC5->C5_CMUNOR	, Nil})
				Aadd(aCabec, {"C5_UFDEST"	, SC5->C5_UFDEST	, Nil})
				Aadd(aCabec, {"C5_CMUNDE"	, SC5->C5_CMUNDE	, Nil})
			EndIf

			If SC6->(DbSeek(xFilial("SC6") + SC5->C5_NUM))
				While !SC6->(EoF()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. SC6->C6_NUM == SC5->C5_NUM
					aLinha := {}
					//nValPed += SC6->C6_VALOR

					Aadd(aLinha, {"LINPOS"		, "C6_ITEM"			, SC6->C6_ITEM	})
					Aadd(aLinha, {"C6_PRODUTO"	, SC6->C6_PRODUTO	, Nil			})
					Aadd(aLinha, {"C6_QTDVEN"	, SC6->C6_QTDVEN	, Nil			})
					Aadd(aLinha, {"C6_PRCVEN"	, SC6->C6_PRCVEN	, Nil			})
					Aadd(aLinha, {"C6_PRUNIT"	, SC6->C6_PRUNIT	, Nil			})
					Aadd(aLinha, {"C6_VALOR"	, SC6->C6_VALOR 	, Nil			})
					Aadd(aLinha, {"C6_TES"		, SC6->C6_TES		, Nil			})
					Aadd(aLinha, {"C6_PEDCLI"	, SC6->C6_PEDCLI	, Nil			})

					If lFaturaPed
						Aadd(aLinha, {"C6_CC"		, SC6->C6_CC		, Nil			})
					Else
						Aadd(aLinha, {"C6_CCUSTO"	, SC6->C6_CCUSTO	, Nil			})
					EndIf

					Aadd(aItens,aLinha)

					SC6->(DbSkip())
				EndDo
			EndIf
		EndIf
	EndIf

	fRestAreas(aAreas)
Return(cNum)


/*/{Protheus.doc} fSetParams
Executa o Pergunte passado por parâmetro para o retorno de dados para o processamento da liberação e faturamento do pedido.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param cPerg, characters, Código do Pergunte a ser executado
@param uPar01, undefined, Parâmetro 1 a ser preenchido (Referência)
@param uPar02, undefined, Parâmetro 2 a ser preenchido (Referência)
@param uPar03, undefined, Parâmetro 3 a ser preenchido (Referência)
@param uPar04, undefined, Parâmetro 4 a ser preenchido (Referência)
@param uPar05, undefined, Parâmetro 5 a ser preenchido (Referência)
@param uPar06, undefined, Parâmetro 6 a ser preenchido (Referência)
@param uPar07, undefined, Parâmetro 7 a ser preenchido (Referência)
@param uPar08, undefined, Parâmetro 8 a ser preenchido (Referência)
@param uPar09, undefined, Parâmetro 9 a ser preenchido (Referência)
@type function
/*/
Static Function fSetParams(cPerg,uPar01,uPar02,uPar03,uPar04,uPar05,uPar06,uPar07,uPar08,uPar09)
	Pergunte(cPerg,.F.)

	Do Case
		Case cPerg == "MTA440"
			/*
				Pergunte MTA440:
				MV_PAR01 - Transfere Armazens		?	Sim/Nao
				MV_PAR02 - Libera so c/ Estoque		?	Sim/Nao
				MV_PAR03 - Sugere Qtde Liber.		?	Sim/Nao
			*/
			uPar01 := MV_PAR01 == 1	// lLiber
			uPar02 := MV_PAR02 == 1	// lTransf
		Case cPerg == "MT460A"
			/*
				Pergunte MT460A:
				MV_PAR01 - Mostra Lanc.Contab     		?  	Sim/Nao
				MV_PAR02 - Aglut. Lancamentos     		?  	Sim/Nao
				MV_PAR03 - Lanc.Contab.On-Line    		?  	Sim/Nao
				MV_PAR04 - Contb.Custo On-Line    		?  	Sim/Nao
				MV_PAR05 - Reaj. na mesma N.F.    		?  	Sim/Nao
				MV_PAR06 - Taxa deflacao ICMS     		?  	Numerico
				MV_PAR07 - Metodo calc.acr.fin    		?  	Taxa defl/Dif.lista/% Acrs.ped
				MV_PAR08 - Arred.prc unit vist    		?  	Sempre/Nunca/Consumid.final
				MV_PAR09 - Agreg. liberac. de     		?  	Caracter
				MV_PAR10 - Agreg. liberac. ate    		?  	Caracter
				MV_PAR11 - Aglut.Ped. Iguais      		?  	Sim/Nao
				MV_PAR12 - Valor Minimo p/fatu    		?
				MV_PAR13 - Transportadora de      		?
				MV_PAR14 - Transportadora ate     		?
				MV_PAR15 - Atualiza Cli.X Prod    		?
				MV_PAR16 - Emitir                 		?  	Nota / Cupom Fiscal / DAV
				MV_PAR17 - Gera Titulo            		?  	Sim/Nao
				MV_PAR18 - Gera guia recolhimento 		?  	Sim/Nao
				MV_PAR19 - Gera Titulo ICMS Próprio 	?  	Sim/Nao
				MV_PAR20 - Gera Guia ICMS Próprio 		?  	Sim/Nao
				MV_PAR22 - Gera Titulo por Pruduto		?  	Sim/Nao
				MV_PAR23 - Gera Guia por Produto		?  	Sim/Nao
				MV_PAR24 - Gera Guia ICM Compl. UF Dest.?	Sim/Nao
				MV_PAR25 - Gera Guia FECP da UF Destino	?	Sim/Nao
				MV_PAR26 - Gera Guia / Titulo PROTEGE-G	?	Sim/Nao
			*/
			uPar01 := MV_PAR01 == 1	// lMostraCtb
			uPar02 := MV_PAR02 == 1	// lAglutCtb
			uPar03 := MV_PAR03 == 1	// lCtbOnLine
			uPar04 := MV_PAR04 == 1	// lCtbCusto
			uPar05 := MV_PAR05 == 1	// lReajuste
			uPar06 := MV_PAR07		// nCalAcrs
			uPar07 := MV_PAR08		// nArrPrcLis
			uPar08 := MV_PAR15 == 1	// lAtuSA7
			uPar09 := MV_PAR16 == 2	// lECF
		Case cPerg == "MTA521"
			/*
				Pergunte MTA521:
				MV_PAR01 - Mostra Lanç. Contab	?	Sim/Nao
				MV_PAR02 - Aglut. Lançamentos	?	Sim/Nao
				MV_PAR03 - Contabiliza			?	Sim/Nao
				MV_PAR04 - Retornar Ped. Venda	?	Carteira/Apto a Faturar
			*/
			uPar01 := MV_PAR01 == 1 // lMostraCtb
			uPar02 := MV_PAR02 == 1 // lAglCtb
			uPar03 := MV_PAR03 == 1 // lContab
			uPar04 := MV_PAR04 == 1 // lCarteira
	EndCase
Return(Nil)

/*/{Protheus.doc} fAtuUQB
Executa a atualização de registros na tabela UQB.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param aRegsUQB, array, Array com os registros a serem atualizados
@param cStatus, characters, Conteúdo para a atualização do Status
@param cPedido, characters, Conteúdo para a atualização do numero do pedido de venda
@param cNF, characters, Conteúdo para a atualização do numero da nota fiscal
@param cSerie, characters, Conteúdo para a atualização da série da nota fiscal
@param lExcPVeNF, logico, Indica se deve excluir o numero do pedido e Nota Fiscal
@type function
/*/
Static Function fAtuUQB(aRegsUQB, cStatus, cPedido, cNF, cSerie, lExcPVeNF)
	Local aAreas 	:= {}
	Local cParcela	:= ""
	Local cPrefixo	:= ""
	Local cTipoTit	:= ""
	Local cTitulo	:= ""
	Local cSeekSE1	:= ""
	Local nI		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))
	Aadd(aAreas, SE1->(GetArea()))

	DbSelectArea("UQB")

	For nI := 1 To Len(aRegsUQB)
		UQB->(DbGoTo(aRegsUQB[nI]))

		//-- Não atualiza registros processados e cancelados
		If UQB->(Recno()) == aRegsUQB[nI]
			// Define o prefixo do título de acordo com o tipo de contrato do arquivo
			cPrefixo := IIf(AllTrim(UQB->UQB_TPCON) == "ZCRT", "CRT", "CTE")
			cPrefixo := PadR(cPrefixo, TamSX3("E1_PREFIXO")[1])

			cTitulo  := ""
			cParcela := ""
			cTipoTit := ""

			If !Empty(cNF)
				cSeekSE1 := xFilial("SE1")
				cSeekSE1 += PadR(cPrefixo, TamSX3("E1_PREFIXO")[1])
				cSeekSE1 += PadR(cNF	 , TamSX3("E1_NUM    ")[1])
				cSeekSE1 += PadR(cSerie  , TamSX3("E1_PARCELA")[1])

				// Posiciona no título a receber gerado
				DbSelectArea("SE1")
				SE1->(DbSetOrder(1))	// E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
				If SE1->(DbSeek( cSeekSE1 ))
					While !SE1->(EoF()) .And. cSeekSE1 == SE1->(E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA)

						If SE1->E1_CLIENTE == UQB->UQB_FORNEC .And. SE1->E1_LOJA == UQB->UQB_LOJA
							cTitulo  := SE1->E1_NUM
							cParcela := SE1->E1_PARCELA
							cTipoTit := SE1->E1_TIPO

							Exit
						EndIf

						SE1->(DbSkip())
					EndDo
				EndIf
			EndIf

			UQB->(Reclock("UQB", .F.))
				UQB->UQB_STATUS 	:= cStatus
				UQB->UQB_PEDIDO 	:= IIf(!Empty(cPedido) .Or. lExcPVeNF, cPedido, UQB->UQB_PEDIDO)

				// Atualiza as informações sobre a nota e o título somente se não for Argentina
				If lFaturaPed
					UQB->UQB_NF		:= IIf(!Empty(cNF) .Or. lExcPVeNF, cNF, UQB->UQB_NF)
					//If cStatus != "P" // Para o caso de Status P o ponto de entrada M460NUM irá gravar a série
						UQB->UQB_SERIE	:= cSerie //IIf(!Empty(cSerie) .Or. lExcPVeNF, cSerie, UQB->UQB_SERIE)
					//EndIf
					UQB->UQB_PREFIX	:= IIf(!Empty(cTitulo), cPrefixo, "")
					UQB->UQB_TITULO	:= IIf(!Empty(cTitulo), cTitulo, "")
					UQB->UQB_PARCEL	:= IIf(!Empty(cParcela), cParcela, "")
					UQB->UQB_TIPOTI	:= IIf(!Empty(cTipoTit), cTipoTit, "")
				EndIf
			UQB->(MsUnlock())
		EndIf
	Next nI

	If !l528Auto
	//	fFillDados()//Atualizo a getDados para correta exibição da serie
	EndIf

	fRestAreas(aAreas)
Return(Nil)

/*/{Protheus.doc} fAtuGetDad
Função que realiza a atualização da GetDados durante o processamento da integração.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param aRegAtu, array, Array com os registros e status para a atualização da legenda
@type function
/*/
Static Function fAtuGetDad(aRegAtu)
	Local nI		:= 0
	Local nJ		:= 0
	Local nPos		:= 0
	Local nAt		:= 0

	nAt := oGetDadUQB:nAt

	For nI := 1 To Len(aRegAtu)
		For nJ := 1 To Len(aRegAtu[nI,1])
			If (nPos := AScan(oGetDadUQB:aCols, {|x| x[nPsUQBRecno] == aRegAtu[nI,1,nJ]})) > 0
				oGetDadUQB:GoTo(nPos)

				//-- Atualização da legenda
				If aRegAtu[nI,2] == "I" // Arquivo importado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBLeg1] := oBlue
				ElseIf aRegAtu[nI,2] == "P" // Arquivo integrado no Protheus
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBLeg1] := oGreen

					//-- Desmarca o registro processado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBCheck] := oNo
				ElseIf aRegAtu[nI,2] == "E" // Arquivo com erros na integração
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBLeg1] := oRed
				ElseIf aRegAtu[nI,2] == "C" // Arquivo cancelado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBLeg1] := oBlack

					//-- Desmarca o registro cancelado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBCheck] := oNo
				ElseIf aRegAtu[nI,2] == "R" // Arquivo reprocessado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBLeg1] := oVioleta

					//-- Desmarca o registro reprocessado
					oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBCheck] := oNo
				EndIf

				//-- Atualização do pedido de venda
				oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBPedido] := aRegAtu[nI,3]

				//-- Atualização da Nota Fiscal
				oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBNF] := aRegAtu[nI,4]

				//-- Atualização da série da Nota Fiscal
				oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBSerie] := aRegAtu[nI,5]
			EndIf
		Next nJ
	Next nI

	oGetDadUQB:GoTo(nAt)
	oGetDadUQB:Refresh()
Return(Nil)

/*/{Protheus.doc} fGetInfUQB
Retorna a informação do campo passado por parâmetro do recno da tabela UQB também passado por parâmetro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return uInfo, Informação do campo solicitado
@param nRecno, numeric, Recno para posicionar na tabela UQB
@param cCampo, characters, Campo a ser retornado o conteúdo
@type function
/*/
Static Function fGetInfUQB(nRecno, cCampo)
	Local aAreas	:= {}
	Local uInfo 	:= Nil

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	UQB->(DbGoTo(nRecno))
	If UQB->(Recno()) == nRecno
		uInfo := &("UQB->" + cCampo)
	EndIf

	fRestAreas(aAreas)
Return(uInfo)

/*/{Protheus.doc} fExcluir
Realiza a integração dos dados das tabelas UQB e UQC gerando Pedido de Venda, Liberação e Nota Fiscal.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param lAgrupa, logical, descricao
@type function
/*/
Static Function fExcluir()

	Local aArea			:= GetArea()
	Local aAreaUQB		:= UQB->(GetArea())
	Local aAreaUQC		:= UQC->(GetArea())

	Local aSels			:= fGetSels()

	Local cMensagem		:= ""
	Local cMsgDet		:= ""
	Local cStatus		:= "I"
	Local cIDImp		:= ""
	Local cRegistro		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"

	Local nI, nJ
	Local nValor		:= 0
	Local nLinha		:= 0

	If !Empty(aSels)
		If MsgYesNo(CAT544048, "PRT0558 - Carta Frete") //"Deseja realmente excluir os arquivos selecionados?"
			For nJ := 1 To Len(aFiliais)
				aSels := fGetSels(aFiliais[nJ,2])

				If !Empty(aSels)
					//-- Altera para a filial do registro selecionado
					StaticCall(PRT0528, fAltFilial, aFiliais[nJ,1])

					// Abre a tabela de cabeçalho dos arquivos
					DbSelectArea("UQB")
					UQB->(DbSetOrder(1))	// UQB_FILIAL + UQB_IDIMP
					UQB->(DbGoTop())

					For nI := 1 To Len(aSels)
						// Posiciona no arquivo selecionado
						If UQB->(DbSeek(xFilial("UQB") + aSels[nI][nPsUQBIDImp]))
							cFilArq   := UQB->UQB_FIL
							cRegistro := UQB->UQB_NUMERO
							cFornec  := UQB->UQB_FORNEC
							cIDImp    := UQB->UQB_IDIMP
							nValor    := UQB->UQB_VALOR

							// Verifica se o mesmo não está processado, reprocessado ou cancelado.
							If !(UQB->UQB_STATUS $ "PRC")

								// Exclui o itens do arquivo
								DbSelectArea("UQC")
								UQC->(DbSetOrder(1))	// UQC_FILIAL + UQC_IDIMP + UQC_ITEM

								// Verifica se possui itens
								If UQC->(DbSeek(xFilial("UQC") + UQB->UQB_IDIMP))
									// Enquanto houver itens
									While !UQC->(Eof()) .And. UQC->UQC_IDIMP == UQB->UQB_IDIMP
										// Deleta o item
										UQC->(Reclock("UQC", .F.))
											UQC->(DbDelete())
										UQC->(MsUnlock())

										UQC->(DbSkip())
									EndDo
								EndIf

								// Deleta o arquivo de cabeçalho
								UQB->(Reclock("UQB", .F.))
									UQB->(DbDelete())
								UQB->(MsUnlock())

								cMensagem := CAT544112 + AllTrim(UQB->UQB_NUMERO) + CAT544113 //"Arquivo " #" excluído com sucesso."

								// Grava o log de exclusão
								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf
						EndIf

						// Retorna ao topo da tabela
						UQB->(DbGotop())
					Next nI
				EndIf
			Next nJ

			fGrvLog()

			MsgInfo(CAT544049, "PRT0558 - Carta Frete") //"Registros excluí­dos com sucesso."

			// Atualiza GetDados
			fFillDados()
		EndIf
	Else
		MsgInfo(CAT544050, "PRT0558 - Carta Frete") //"Nenhum registro selecionado para exclusão."
	EndIf

	RestArea(aArea)
	RestArea(aAreaUQB)
	RestArea(aAreaUQC)

Return

/*/{Protheus.doc} fEstornar
Realiza o estorno do arquivo integrado ao Protheus
@author Kevin Willians
@since 15/02/2019
@version v1.02
@param nAt, integer, linha poscionada na GetDados da UQB
@type function
/*/
Static Function fEstornar(nAt)
	Local aCancNF		:= {}
	Local aCancPV		:= {}
	Local aC			:= oGetDadUQB:aCols[oGetDadUQB:nAt]
	Local aRegsUQB		:= {}//{aC[GDFieldPos("UQB_REC_WT"	, oGetDadUQB:aHeader)]}
	Local cFornec		:= aC[GDFieldPos("UQB_FORNEC"	, oGetDadUQB:aHeader)]
	Local cLoja			:= aC[GDFieldPos("UQB_LOJA"	, oGetDadUQB:aHeader)]
	Local cNF			:= aC[GDFieldPos("UQB_NF"		, oGetDadUQB:aHeader)]
	Local cSerie		:= aC[GDFieldPos("UQB_SERIE"		, oGetDadUQB:aHeader)]
	Local cRegistro		:= aC[GDFieldPos("UQB_NUMERO"	, oGetDadUQB:aHeader)]
	Local cPedido		:= aC[GDFieldPos("UQB_PEDIDO"	, oGetDadUQB:aHeader)]
	Local cRecNo		:= aC[GDFieldPos("UQB_REC_WT"	, oGetDadUQB:aHeader)]
	Local cStatus		:= "I"
	Local cIDImp		:= aC[GDFieldPos("UQB_IDIMP"		, oGetDadUQB:aHeader)]
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local nValor		:= aC[GDFieldPos("UQB_VALOR"		, oGetDadUQB:aHeader)]

	// Posiciona no registro a ser estornado.
	UQB->(DbGoTo(cRecNo))

	If UQB->UQB_STATUS <> "P"
		MsgAlert(CAT544051, "PRT0558 - Carta Frete") //"Só é permitido o estorno de arquivos integrados ao Protheus."
	Else
		If MsgYesNo(CAT544052, "PRT0558 - Carta Frete") //"Deseja realmente realizar o estorno da integração do registro posicionado?"
			//	Verifica se o usuário tem acesso a rotina de estorno
			If RetCodUsr() $ SuperGetMV("PLG_USREST",,.F.)
				// Verifica se o registro esta integrado(Verde)
				If UQB->UQB_STATUS == "P"
					//--Varre a GD em busca de outros registros do mesmo lote
					aAdd(aRegsUQB, cRecNo )//aRegsUQB := fGDLote( @aRegsUQB, AllTrim(cNF), AllTrim(cSerie))
					//-- Estorna a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cFornec, cLoja, cPedido)

					//-- Estorna o Pedido
					If aCancNF[1]
						aCancPV := fCanPedVen(cPedido)

						If aCancPV[1]
							//-- Atualiza a UQB fAtuUQB(aRegsUQB, cStatus, cPedido, cNF, cSerie, lExcPVeNF)
							fAtuUQB(aRegsUQB, cStatus, "", "", "", .T.)
							//oGetDadUQB:Refresh()
							fFillDados()//atualiza as legendas recarregando a busca

							cCancelLog := Space(TamSX3("UQF_CANCEL")[1])

							MsgInfo(CAT544053, "PRT0558 - Carta Frete") //"Registro estornado com sucesso!"
										//{cRegistro, nValor, cMensagem, cMsgDet, nLinha, cStatus})
							aAdd( aLogs, {cFilArq, cRegistro, cFornec, nValor, CAT544053, /*cMsgDet*/, 0, cStatus, cIDImp, cCancelLog, cBlqEmail}) //"Registro estornado com sucesso!"
						EndIf
					EndIf
				Else
					MsgInfo(CAT544054, "PRT0558 - Carta Frete") //"Registro deve estar integrado para operação de estorno."
				EndIf
			Else
				MsgInfo(CAT544055, "PRT0558 - Carta Frete") //"Usuário sem permissão necessária para estornar registros."
			EndIf

			fGrvLog()
		EndIf
	EndIf

Return

/*/{Protheus.doc} fGDLote
Varre a GD(UQB) buscando os registros integrados no mesmo lote e acrescentando um array com os recnos dos mesmos
@author Kevin Willians
@since 18/02/2019
@version undefined
@param aRegs, array, array a ser preenchido com os RecNos
@param cNota, characters, Nota fiscal a ser comparada
@param cSerie, characters, Serie da Nota fiscal a ser comparada
@type function
/*/
Static Function fGDLote( aRegs, cNota, cSerie )
	Local nI 		:= oGetDadUQB:nAt
	Local nNFPos	:= GDFieldPos("UQB_NF" 		, oGetDadUQB:aHeader)
	Local nSeriePos	:= GDFieldPos("UQB_SERIE" 	, oGetDadUQB:aHeader)
	Local nRecPos	:= GDFieldPos("UQB_REC_WT"	, oGetDadUQB:aHeader)

//	Varre para trás
	While AllTrim( oGetDadUQB:aCols[nI][nNFPos] ) == cNota .And. AllTrim( oGetDadUQB:aCols[nI][nSeriePos] ) == cSerie	//Nota fiscal igual a selecionada
		aAdd( aRegs, oGetDadUQB:aCols[nI][nRecPos])			//RecNo do registro
		nI--
		If nI == 0
			Exit	//N buscar na posição 0 do array
		EndIf
	EndDo
	nI := oGetDadUQB:nAt + 1
//	Varre para frente
	If nI <= Len(oGetDadUQB:aCols)
		While AllTrim( oGetDadUQB:aCols[nI][nNFPos] ) == cNota .And. AllTrim( oGetDadUQB:aCols[nI][nSeriePos] ) == cSerie	//Nota fiscal igual a selecionada
			aAdd( aRegs, oGetDadUQB:aCols[nI][nRecPos])			//RecNo do registro
			nI++
			If nI > Len(oGetDadUQB:aCols)
				Exit	//N buscar em posição maior que o tam do array
			EndIf
		EndDo
	EndIf

Return aRegs

/*/{Protheus.doc} fGetSels
Extrai da GetDados os documentos selecionados para exclusão.
@author Paulo Carvalho
@since 15/01/2019
@version 1.01
@param cFilSel caracter, Filial a ser filtrada
@type Static function
/*/
Static Function fGetSels(cFilSel)

	// Captura a GetDados.
	Local aAux		:= aClone(oGetDadUQB:aCols)
	Local aSels		:= {}

	Default cFilSel	:= ""

	// Separa os itens selecionados pelo usuário.
	If Empty(cFilSel)
		aEval( aAux, {|x| If( x[nPsUQBCheck]:cName == "LBOK", Aadd(aSels, x), Nil ) } )
	Else
		aEval( aAux, {|x| If( x[nPsUQBCheck]:cName == "LBOK" .And. x[nPsUQBFilial] == cFilSel, Aadd(aSels, x), Nil ) } )
	EndIf

Return aClone(aSels)

/*/{Protheus.doc} fRestAreas
Executa o RestArea das áreas passadas no array.
@author Juliano Fernandes
@since 11/01/2019
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

/*/{Protheus.doc} fPedVenda
Visualização do Pedido de Venda do registro posicionado.
@type Function
@author Juliano Fernandes
@since 16/01/2019
@version 1.0
/*/
Static Function fPedVenda()
	Local aAreas 	:= {}
	Local cPedido	:= ""
	Local cFilPed	:= ""
	Local cCadOld	:= "PRT0558 - Carta Frete"

	Private aRotina	:= StaticCall(MATA410, MenuDef)

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC5->(GetArea()))
	Aadd(aAreas, SC6->(GetArea()))

	ProcRegua(0)

	cCadastro := "Carta Frtete "//CAT544056 //"Pedidos de Venda - VISUALIZAR"

	cFilPed := oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBFilial]

	cPedido := oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBPedido]

	If !Empty(cPedido)
		StaticCall(PRT0528, fAltFilial, cFilPed)

		DbSelectArea("SC5")
		SC5->(DbSetOrder(1)) // C5_FILIAL+C5_NUM
		If SC5->(DbSeek(xFilial("SC5") + cPedido))
			IncProc(CAT544057) //"Pedido localizado..."

			DbSelectArea("SC6")
			SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
			If SC6->(DbSeek(xFilial("SC6") + cPedido))
				IncProc(CAT544058)	//"Preparando dados para apresentação..."
				A410Visual("SC5",SC5->(Recno()),2)
			EndIf
		Else
			MsgAlert(CAT544059 + AllTrim(cPedido) + CAT544060, "PRT0558 - Carta Frete") //"O Pedido de Venda " + AllTrim(cPedido) + " não foi localizado."
		EndIf
	Else
		MsgAlert(CAT544061, "PRT0558 - Carta Frete")	//"Não foi gerado Pedido de Venda para o item selecionado."
	EndIf

	cCadastro := cCadOld

	fRestAreas(aAreas)
Return(Nil)

/*/{Protheus.doc} fNotaFiscal
Visualização da Nota Fiscal do registro posicionado.
@type Function
@author Juliano Fernandes
@since 16/01/2019
@version 1.0
/*/
Static Function fNotaFiscal()
	Local aAreas 	:= {}
	Local cFilNF	:= ""
	Local cPedido	:= ""
	Local cNF		:= ""
	Local cSerie	:= ""
	Local cCadOld	:= "PRT0558 - Carta Frete"
	Local lNF		:= .F.

	Private aRotina	:= StaticCall(MATA460A, MenuDef)

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC9->(GetArea()))
	Aadd(aAreas, SF2->(GetArea()))
	Aadd(aAreas, SD2->(GetArea()))

	ProcRegua(0)

	cFilNF	:= PadR(oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBFilial], TamSX3("C9_FILIAL" )[1])
	cPedido	:= PadR(oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBPedido], TamSX3("C9_PEDIDO" )[1])
	cNF		:= PadR(oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBNF]	, TamSX3("C9_NFISCAL")[1])
	cSerie 	:= PadR(oGetDadUQB:aCols[oGetDadUQB:nAt,nPsUQBSerie]	, TamSX3("C9_SERIENF")[1])

	If !Empty(cPedido) .And. !Empty(cNF) .And. !Empty(cSerie)
		StaticCall(PRT0528, fAltFilial, cFilNF)

		DbSelectArea("SC9")
		SC9->(DbSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO
		If SC9->(DbSeek(xFilial("SC9") + cPedido))
			While !SC9->(EoF()) .And. SC9->C9_FILIAL == xFilial("SC9") .And. SC9->C9_PEDIDO == cPedido
				If SC9->C9_NFISCAL == cNF .And. SC9->C9_SERIENF == cSerie
					IncProc(CAT544062)	//"Nota Fiscal localizada..."
					lNF := .T.
					Exit
				EndIf

				SC9->(DbSkip())
			EndDo

			If lNF
				IncProc(CAT544063)	//"Preparando dados para apresentação..."
				Ma461View("SC9",SC9->(Recno()),2)
			Else
				MsgAlert(CAT544064, "PRT0558 - Carta Frete")	//"Nota Fiscal não localizada."
			EndIf
		Else
			MsgAlert(CAT544065 + AllTrim(cPedido) + CAT544066, "PRT0558 - Carta Frete") //"Os dados da liberação do Pedido de Venda " + AllTrim(cPedido) + " não foram localizados para a visualização da Nota Fiscal."
		EndIf
	Else
		MsgAlert(CAT544067, "PRT0558 - Carta Frete") // "Não foi gerada Nota Fiscal para o item selecionado."
	EndIf

	cCadastro := cCadOld

	fRestAreas(aAreas)
Return(Nil)

/*/{Protheus.doc} fCancela
Rotina executada para cancelar um item de CTE/CRT (Cancela Pedido de Venda e Nota Fiscal).
@author Juliano Fernandes
@since 24/01/2019
@version 1.0
@return lOk, Indica se houve sucesso no cancelamento
@param aRegsCanc, array, Registros a serem cancelados
@param aErros, array, Array com os erros gerados durante o processamento (Referência)
@param cPedido, characters, Numero do pedido de venda cancelado (Referência)
@param cNF, characters, Numero da Nota Fiscal cancelada (Referência)
@param cSerie, characters, Série da Nota Fiscal cancelada (Referência)
@param aAtuGetDad, array, Array com dados a serem atualizados na GetDados (Referência)
@param aRegAgru, array, Array com registros do agrupamento (Referência)
@type function
/*/
Static Function fCancela(aRegsCanc, cPedido, cNF, cSerie, aAtuGetDad, aRegAgru)

	Local aAreas		:= {}
	Local aCancNF		:= {}
	Local aCancPV		:= {}

	Local cDocumento	:= ""
	Local cCancel		:= ""
	Local cFornec		:= ""
	Local cLoja			:= ""
	Local cMensagem		:= ""
	Local cStatus		:= ""
	Local cIDImp		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"

	Local lOk			:= .T.

	Local nI 			:= 0
	Local nPos			:= 0
	Local nLinha		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	cCancel := Space(TamSX3("UQB_CANCEL")[1])

	For nI := 1 To Len(aRegsCanc)
		aCancNF := {.F.,""}
		aCancPV := {.F.,""}
		lOk := .T.

		UQB->(DbGoTo(aRegsCanc[nI]))

		If UQB->(Recno()) == aRegsCanc[nI]
			cDocumento 	:= UQB->UQB_NUMERO
			cPedido		:= UQB->UQB_PEDIDO
			cIDImp		:= UQB->UQB_IDIMP

			//-- Busca registro de inclusão (integração) na UQB
			//UQB->(DbSetOrder(2)) //UQB_FILIAL+UQB_NUMERO+UQB_CANCEL
			If fPosRegAtivo(cDocumento) //UQB->(DbSeek(xFilial("UQB") + cDocumento + cCancel))
				cNF 		:= UQB->UQB_NF
				cSerie 		:= UQB->UQB_SERIE
				cFornec 	:= UQB->UQB_FORNEC
				cLoja 		:= UQB->UQB_LOJA
				nValor		:= UQB->UQB_VALOR

				If Empty(cPedido)
					cPedido := UQB->UQB_PEDIDO
				EndIf

				If (!Empty(cNF) .And. !Empty(cSerie)) .Or. !lFaturaPed .And. !Empty(cFornec) .And. !Empty(cLoja) .And. !Empty(cPedido)
					IncProc(CAT544068 + AllTrim(cNF) + CAT544069 + AllTrim(cSerie) + "...")	//"Cancelando Nota Fiscal ", " Série "

					//-- Cancela a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cFornec, cLoja, cPedido)

					If aCancNF[1]
						IncProc(CAT544070 + AllTrim(cPedido) + "...")	//"Cancelando Pedido de Venda "

						//-- Cancela o Pedido de Venda
						aCancPV := fCanPedVen(cPedido, aRegsCanc)

						If !aCancPV[1]
							nErro++
							lOk 		:= .F.
							cStatus		:= "E"
							cMensagem	:= aCancPV[2]
							cCancelLog	:= "C"

							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf
					Else
						nErro++
						lOk 		:= .F.
						cStatus		:= "E"
						cMensagem	:= aCancNF[2]
						cCancelLog	:= "C"

						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf

				EndIf

				IncProc(CAT544071)	//"Cancelando registro de inclusão..."

				//-- Atualiza o registro de inclusão como cancelado
				fAtuUQB({UQB->(Recno())}, "C", UQB->UQB_PEDIDO, UQB->UQB_NF, UQB->UQB_SERIE, .F.)

				//-- Remove o registro cancelado do array aRegAgru caso tenha sido realizado agrupamento
				If (nPos := AScan(aRegAgru, UQB->(Recno()))) > 0
					ADel(aRegAgru, nPos)
					ASize(aRegAgru, Len(aRegAgru) - 1)
				EndIf

				Aadd(aAtuGetDad, {{UQB->(Recno())}, "C", UQB->UQB_PEDIDO, UQB->UQB_NF, UQB->UQB_SERIE})
			EndIf
		EndIf
	Next nI

	fRestAreas(aAreas)

Return(lOk)

/*/{Protheus.doc} fCancNFS
Rotina para o cancelamento da Nota Fiscal.
@author Juliano Fernandes
@since 24/01/2019
@version 1.0
@return aRet, Array indicando se houve sucesso e mensagem em caso de erros
@param cNota, characters, Nota Fiscal
@param cSerie, characters, Série da Nota Fiscal
@param cFornec, characters, Código do cliente
@param cLoja, characters, Loja do cliente
@type function
/*/
Static Function fCancNFS(cNota, cSerie, cFornec, cLoja, cNumPed)

	Local aAreas		:= {}
	Local aRegSD2 		:= {}
	Local aRegSE1 		:= {}
	Local aRegSE2 		:= {}

	Local cMsg			:= ""

	Local lMostraCtb	:= .F.
	Local lAglCtb		:= .F.
	Local lContab		:= .F.
	Local lCarteira		:= .F.
	Local lOk			:= .T.

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SF2->(GetArea()))
	Aadd(aAreas, SD2->(GetArea()))
	Aadd(aAreas, SC9->(GetArea()))
	Aadd(aAreas, SE1->(GetArea()))

	fSetParams("MTA521",@lMostraCtb,@lAglCtb,@lContab,@lCarteira)

	DbSelectArea("SF2") ; SF2->(DbSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	DbSelectArea("SD2") ; SD2->(DbSetOrder(1)) // D2_FILIAL+D2_COD+D2_LOCAL+D2_NUMSEQ

	If !lFaturaPed
		If SF2->(DbSeek(xFilial("SF2") + cNota + cSerie + cFornec + cLoja))
			lOk := .F.
			cMsg := CAT544091 //"Não foi possível excluir o pedido de venda. Exclua a nota fiscal pela rotina padrão."
		EndIf

		If lOk
			// -----------------------------------------
			// Estorna a liberação do Pedido de Venda
			// Juliano Fernandes - 12/09/2019
			// -----------------------------------------
			DbSelectArea("SC9")
			SC9->(DbSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED

			While SC9->(DbSeek( xFilial("SC9") + cNumPed ))
				SC9->(A460Estorna())
			EndDo
		EndIf
	Else
		If SF2->(DbSeek(xFilial("SF2") + cNota + cSerie + cFornec + cLoja))
			DbSelectArea("SE1")
			SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			If SE1->(DbSeek(xFilial("SE1") + SF2->(F2_CLIENTE+F2_LOJA+F2_PREFIXO+F2_DUPL)))
				While SE1->(!EoF()) .And. SE1->E1_FILIAL == xFilial("SE1") .And. SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM) == SF2->(F2_CLIENTE+F2_LOJA+F2_PREFIXO+F2_DUPL)
					If AllTrim(SE1->E1_TIPO) == "NF" .And. !("MATA460" $ SE1->E1_ORIGEM) // E1_ORIGEM pode estar gravado como FINA460 ou FINA040
						SE1->(Reclock("SE1",.F.))
							SE1->E1_ORIGEM := "MATA460"
						SE1->(MsUnlock())
					EndIf

					SE1->(DbSkip())
				EndDo
			EndIf

			//-- Verifica se o estorno do documento de saida pode ser feito
			If MaCanDelF2("SF2",SF2->(Recno()),@aRegSD2,@aRegSE1,@aRegSE2)
				//-- Estorna o documento de saida
				SF2->(MaDelNFS(aRegSD2,aRegSE1,aRegSE2,lMostraCtb,lAglCtb,lContab,lCarteira))
			Else
				lOk := .F.
				cMsg := CAT544072 + AllTrim(SF2->F2_DOC) + CAT544069 + AllTrim(SF2->F2_SERIE) + CRLF	//"Não é possivel cancelar a Nota Fiscal: " # " Série "
			EndIf
		Else
			lOk := .F.
			cMsg := CAT544073 + AllTrim(SF2->F2_DOC) + CAT544069 + AllTrim(SF2->F2_SERIE) + CAT544074 + CRLF	//Nota fiscal # " Série " # não localizada
		EndIf
	EndIf

	fRestAreas(aAreas)

Return({lOk, cMsg})

/*/{Protheus.doc} fCanPedVen
Rotina para o cancelamento do pedido de venda.
@author Juliano Fernandes
@since 24/01/2019
@version 1.0
@return aRet, Array indicando se houve sucesso e mensagem em caso de erros
@param cPedido, characters, Pedido a ser cancelado
@type function
/*/
Static Function fCanPedVen(cPedido, aRegs)
	Local aAreas	:= {}
	Local aCab		:= {}
	Local aIte		:= {}
	Local cMsg		:= ""
	Local lOk		:= .T.

	Default aRegs 	:= {}

	Aadd(aAreas, GetArea())

	fMontaPed(Nil, @aCab, @aIte, 5, cPedido)

	If !Empty(aCab) .And. !Empty(aIte)
		If !fGeraPed(aCab, aIte, 5, aRegs)
			lOk := .F.
			cMsg := CAT544075 + AllTrim(cPedido) + "." + CRLF	//"Não foi possí­vel cancelar o Pedido de Venda "
		EndIf
	Else
		lOk := .F.
		cMsg := CAT544076 + AllTrim(cPedido) + "." + CRLF	//"Não foi possí­vel localizar os dados para a exclusão do pedido de venda "
	EndIf

	fRestAreas(aAreas)
Return({lOk, cMsg})

/*/{Protheus.doc} fAltPedVen
Rotina para a alteração do pedido de venda.
@author Juliano Fernandes
@since 25/01/2019
@version 1.0
@return aRet, Array indicando se houve sucesso e mensagem em caso de erros
@param cPedido, characters, Pedido a ser alterado
@param aRegs, array, Recno dos registros
@param lReprocess, logico, Indica se é um reprocessamento
@type function
/*/
Static Function fAltPedVen(cPedido, aRegs, lReprocess, nValRep)
	Local aAreas		:= {}
	Local aCab			:= {}
	Local aIte			:= {}
	Local cMsg			:= ""
	Local lOk			:= .T.
	Local nValPed		:= nValRep

	Default lReprocess	:= .F.

	Aadd(aAreas, GetArea())

	If !lFaturaPed
		fMontaPed(aRegs, @aCab, @aIte, 5, cPedido, lReprocess)

		If !Empty(aCab) .And. !Empty(aIte)
			If !fGeraPed(aCab, aIte, 5, aRegs)
				lOk := .F.
				cMsg := CAT544077 + AllTrim(cPedido) + "." + CRLF	//"Não foi possível alterar o Pedido de Venda "
			EndIf
		Else
			lOk := .F.
			cMsg := CAT544078 + AllTrim(cPedido) + "." + CRLF	//"Não foi possí­vel localizar os dados para a alteração do pedido de venda "
		EndIf

		aCab := {}
		aIte := {}

		fMontaPed(aRegs, @aCab, @aIte, 3, cPedido, lReprocess, nValPed)

		If !Empty(aCab) .And. !Empty(aIte)
			If !fGeraPed(aCab, aIte, 3, aRegs)
				lOk := .F.
				cMsg := CAT544077 + AllTrim(cPedido) + "." + CRLF	//"Não foi possível alterar o Pedido de Venda "
			EndIf
		Else
			lOk := .F.
			cMsg := CAT544078 + AllTrim(cPedido) + "." + CRLF	//"Não foi possível localizar os dados para a alteração do pedido de venda "
		EndIf

	Else
		fMontaPed(aRegs, @aCab, @aIte, 4, cPedido, lReprocess)

		If !Empty(aCab) .And. !Empty(aIte)
			If !fGeraPed(aCab, aIte, 4, aRegs)
				lOk := .F.
				cMsg := CAT544077 + AllTrim(cPedido) + "." + CRLF	//"Não foi possível alterar o Pedido de Venda "
			EndIf
		Else
			lOk := .F.
			cMsg := CAT544078 + AllTrim(cPedido) + "." + CRLF	//"Não foi possí­vel localizar os dados para a alteração do pedido de venda "
		EndIf
	EndIf

	fRestAreas(aAreas)
Return({lOk, cMsg})

/*/{Protheus.doc} fVerAgrupa
Verifica se existem registros agrupados com o mesmo pedido e nota fiscal.
@author Juliano Fernandes
@since 24/01/2019
@version 1.0
@return cMsg, Mensagem com os CTE/CRT vinculados com o pedido e nota fiscal
@param cPedido, characters, Pedido
@param cNF, characters, Nota Fiscal
@param cSerie, characters, Serie da Nota Fiscal
@param aRegAgru, array, Array com os registros agrupados (referência)
@type function
/*/
Static Function fVerAgrupa(cPedido, cNF, cSerie, aRegAgru)
	Local cMsg		:= ""
	Local cAliasQry	:= ""
	Local cQuery	:= ""

	//-- Retorna os registros que geraram Pedido e NF
	cAliasQry := GetNextAlias()
	cQuery := "SELECT UQB.UQB_NUMERO, UQB.R_E_C_N_O_ RECNOUQB"					+ CRLF
	cQuery += "FROM " + RetSqlName("UQB") + " UQB" 								+ CRLF
	cQuery += "WHERE UQB.UQB_FILIAL = '" + xFilial("UQB") + "'" 					+ CRLF
	cQuery += "	AND UQB.UQB_CANCEL  = '" + Space(TamSX3("UQB_CANCEL")[1]) + "'" 	+ CRLF
	cQuery += "	AND UQB.UQB_PEDIDO  = '" + cPedido + "'" 						+ CRLF
	cQuery += "	AND UQB.UQB_NF      = '" + cNF + "'" 							+ CRLF
	cQuery += "	AND UQB.UQB_SERIE   = '" + cSerie + "'" 							+ CRLF
	cQuery += "	AND UQB.D_E_L_E_T_ <> '*'" 										+ CRLF
	cQuery += "GROUP BY UQB.UQB_NUMERO, UQB.R_E_C_N_O_" 							+ CRLF
	cQuery += "ORDER BY UQB.UQB_NUMERO" 											+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If Contar(cAliasQry, "!Eof()") > 1
		(cAliasQry)->(DbGoTop())

		cMsg := CAT544079 + cPedido	+ CRLF	//"Pedido: "
		cMsg += CAT544080 + cNF 	+ CRLF	//"Nota Fiscal: "
		cMsg += CAT544081 + cSerie	+ CRLF + CRLF //"Série: "

		cMsg += CAT544082 + CRLF //"CTE/CRT:"

		While !(cAliasQry)->(Eof())
			cMsg += (cAliasQry)->UQB_NUMERO + CRLF

			Aadd(aRegAgru, (cAliasQry)->RECNOUQB)

			(cAliasQry)->(DbSkip())
		EndDo

		cMsg += CRLF
	EndIf

	(cAliasQry)->(DbCloseArea())
Return(cMsg)

/*/{Protheus.doc} fReprocessa
Função executada para o reprocessamento de registros.
@type function
@author Juliano Fernandes
@since 25/01/2019
@version 1.0
@param aRegsRepro, array, Registros a serem reprocessados
@param aErros, array, Array com os erros gerados durante o processamento (Referência)
@param cPedido, characters, Numero do pedido de venda gerado (Referência)
@param cNF, characters, Numero da Nota Fiscal gerada (Referência)
@param cSerie, characters, Série da Nota Fiscal gerada (Referência)
@param aAtuGetDad, array, Array com dados a serem atualizados na GetDados (Referência)
@param aRegAgru, array, Array com registros do agrupamento (Referência)
@return lOk, Indica se o registro foi localizado
/*/
Static Function fReprocessa(aRegsRepro, cPedido, cNF, cSerie, aAtuGetDad, aRegAgru)
	Local aAreas		:= {}
	Local aAreaSE1		:= {}
	Local aCancNF		:= {}
	Local aAltPV		:= {}
	Local aTitulosAj	:= {}
	Local bCond			:= {|| .T.}
	Local cDocumento	:= ""
	Local cFornec		:= ""
	Local cLoja			:= ""
	Local cNumCarta		:= ""
	Local cPrefixTit	:= ""
	Local cNumTit		:= ""
	Local cParcTit		:= ""
	Local cTipoTit		:= ""
	Local cIDImp		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local cSeekSE1		:= "N"
	Local cTpCon		:= ""
	Local lOk			:= .T.
	Local lReprocess	:= .T.
	Local nI 			:= 0
	Local nLinha		:= 0
	Local nAnoOrig		:= 0
	Local nAnoCarta		:= 0
	Local nMesOrig		:= 0
	Local nMesCarta		:= 0
	Local nDiaOrig		:= 0
	Local nDiaCarta		:= 0
	Local nValRep		:= 0
	Local nRecProc		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQB->(GetArea()))

	cCancel := Space(TamSX3("UQB_CANCEL")[1])

	If !lFaturaPed
		bCond := {|| !Empty(cFornec) .And. !Empty(cLoja) .And. !Empty(cPedido) }
	Else
		bCond := {|| !Empty(cNF) .And. !Empty(cSerie) .And. !Empty(cFornec) .And. !Empty(cLoja) .And. !Empty(cPedido) }
	EndIf

	For nI := 1 To Len(aRegsRepro)
		aCancNF := {.F.,""}

		lOk := .T.

		UQB->(DbGoTo(aRegsRepro[nI]))

		If UQB->(Recno()) == aRegsRepro[nI]
			cDocumento 	:= UQB->UQB_NUMERO//PadR(UQB->UQB_CHVCTE, TamSX3("UQB_NUMERO")[1])
			cPedido		:= UQB->UQB_PEDIDO
			cNumCarta	:= PadR(UQB->UQB_CHVCTE, TamSX3("UQB_NUMERO")[1])//UQB->UQB_NUMERO
			cIDImp		:= UQB->UQB_IDIMP
			cTpCon		:= UQB->UQB_TPCON

			nAnoCarta	:= Year(UQB->UQB_EMISSA)
			nMesCarta	:= Month(UQB->UQB_EMISSA)
			nDiaCarta	:= Day(UQB->UQB_EMISSA)

			nRecProc	:= aRegsRepro[nI]

			//-- Busca registro de inclusão (integração) na UQB
			//UQB->(DbSetOrder(2)) //UQB_FILIAL+UQB_NUMERO+UQB_CANCEL
			//Posiciona no original
			If fPosRegAtivo(cDocumento) //UQB->(DbSeek(xFilial("UQB") + cDocumento + cCancel))
				If lFaturaPed
					cNF 	:= UQB->UQB_NF
					cSerie 	:= UQB->UQB_SERIE
				EndIf

				cFornec 	:= UQB->UQB_FORNEC
				cLoja 		:= UQB->UQB_LOJA
				nValor		:= UQB->UQB_VALOR

				nAnoOrig	:= Year(UQB->UQB_EMISSA)
				nMesOrig	:= Month(UQB->UQB_EMISSA)
				nDiaOrig	:= Day(UQB->UQB_EMISSA)

				nValRep := fValGetUQB(cDocumento)//SE1->E1_VALOR

				If Empty(cPedido)
					cPedido := UQB->UQB_PEDIDO
				EndIf

				If lFaturaPed
					aAreaSE1 := SE1->(GetArea())

					cPrefixTit := Padr(UQB->UQB_PREFIX, TamSX3("E1_PREFIXO")[1] )
					cNumTit := Padr(UQB->UQB_TITULO, TamSX3("E1_NUM")[1] )
					cParcTit := Padr(UQB->UQB_PARCEL, TamSX3("E1_PARCELA")[1])
					cTipoTit := Padr(UQB->UQB_TIPOTI, TamSX3("E1_TIPO")[1])

					If !Empty(cNumTit)

						DbSelectArea("SE1")
						SE1->(DbSetOrder(1))//E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						If SE1->(DbSeek( xFilial("SE1") + cPrefixTit + cNumTit + cParcTit + cTipoTit))

							If !Empty(SE1->E1_BAIXA)
								//nErro++
								lOk 		:= .F.
								cStatus		:= "E"
								cMensagem	:= CAT544097 //"O título gerado anteriormente pelo pedido de venda foi baixado."
								cCancelLog	:= "R"

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf

							If !Empty(SE1->E1_XIDFAT)
								//nErro++
								lOk 		:= .F.
								cStatus		:= "E"
								cMensagem	:=  CAT544098//"O título gerado anteriormente pelo pedido de venda está sendo utilizado em uma fatura."
								cCancelLog	:= "R"

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf

						EndIf

					EndIf

					RestArea(aAreaSE1)
				EndIf

				//Comentado por solicitação Veloce dia 14/10/2019 - Icaro

				/*If nAnoOrig != nAnoCarta
					//nErro++
					lOk 		:= .F.
					cStatus		:= "E"
					cMensagem	:= CAT544099 //"O ano de emissão da carta de correção é diferente do ano original."
					cCancelLog	:= "R"

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
				EndIf

				If nMesOrig != nMesCarta

					//nErro++
					lOk 		:= .F.
					cStatus		:= "E"
					cMensagem	:= CAT544100 //"O mês de emissão da carta de correção é diferente do mês original."
					cCancelLog	:= "R"

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf

				If nAnoOrig == nAnoCarta .And. nMesOrig == nMesCarta .And. nDiaOrig > nDiaCarta

					//nErro++
					lOk 		:= .F.
					cStatus		:= "E"
					cMensagem	:= CAT544101 //"A data de emissão da carta de correção é anterior a data original."
					cCancelLog	:= "R"

					aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf*/

				If EVal(bCond) .And. lOk

					If lFaturaPed
						IncProc(CAT544068 + AllTrim(cNF) + CAT544069 + AllTrim(cSerie) + "...")	//"Cancelando Nota Fiscal ", " Série "

						// -------------------------------------------------------------------------------------------------
						// Ajusta os títulos com parcela diferente e que pertencem a outro CTE/CRT para que não sejam
						// excluídos no cancelamento da NF
						// -------------------------------------------------------------------------------------------------
						aTitulosAj := fAjustTit(cPrefixTit, cNumTit, cParcTit, cTipoTit, cFornec, cLoja, UQB->UQB_NUMERO, "1")
					EndIf

					//-- Cancela a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cFornec, cLoja, cPedido)

					If lFaturaPed
						// -------------------------------------------------------------------------------------------------
						// Retorna para a filial correta os registros ajustados antes do cancelamento da NF
						// -------------------------------------------------------------------------------------------------
						If !Empty(aTitulosAj)
							fAjustTit(cPrefixTit, cNumTit, cParcTit, cTipoTit, cFornec, cLoja, UQB->UQB_NUMERO, "2", aTitulosAj)
						EndIf
					EndIf

					If aCancNF[1]
						IncProc(CAT544083 + AllTrim(cPedido) + "...")	//"Alterando Pedido de Venda "

						//-- Altera o Pedido de Venda
						aAltPV := fAltPedVen(cPedido, {aRegsRepro[nI]}, lReprocess, nValRep)

						If aAltPV[1]
							If fLiberaPed(cPedido)
								If lFaturaPed
									If !fFaturaPed(cPedido, @cNF, @cSerie, cTpCon, nRecProc)[1]
									//	nErro++
										lOk 		:= .F.
										cStatus		:= "E"
										cMensagem	:= CAT544084 //"Erro na geração da Nota Fiscal do Pedido de Venda "
										cCancelLog	:= "R"

										aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
										//fGrvLog(nLinha, cMensagem, cStatus)
									Else

										aAreaSE1 := SE1->(GetArea())

										cSeekSE1 := xFilial("SE1")
										cSeekSE1 += PadR(cPrefixTit, TamSX3("E1_PREFIXO")[1])
										cSeekSE1 += PadR(cNF       , TamSX3("E1_NUM    ")[1])
										cSeekSE1 += PadR(cSerie    , TamSX3("E1_PARCELA")[1])
										cSeekSE1 += PadR(cTipoTit  , TamSX3("E1_TIPO   ")[1])

										DbSelectArea("SE1")
										SE1->(DbSetOrder(1))  //E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
										If SE1->(DbSeek( cSeekSE1 ))
											If SE1->E1_CLIENTE == UQB->UQB_FORNEC .And. SE1->E1_LOJA == UQB->UQB_LOJA
												SE1->(Reclock("SE1", .F.))

													SE1->E1_HIST := CAT544102 + AllTrim(cNumCarta) + " " + CAT544110 +  cValToChar(nValRep) ////"C.C: " # "Valor: "
													/*If "ZCRT" $ UQB->UQB_TPCON
														SE1->E1_HIST := CAT544102 + AllTrim(cNumCarta) //+ "  " + CAT544103 + AllTrim(cNumTit) //"C.C: " # "CRT: "
													ElseIf "ZTRC" $ UQB->UQB_TPCON
														SE1->E1_HIST := CAT544102 + AllTrim(cNumCarta) //+ "  " + CAT544105 + AllTrim(cNumTit) //"C.C: " # "CTE: "
													EndIf*/

												SE1->(MsUnlock())
											EndIf
										EndIf

										RestArea(aAreaSE1)

									EndIf

								EndIf
							Else
							//	nErro++
								lOk 		:= .F.
								cStatus		:= "E"
								cMensagem	:= CAT544085 //"Erro na liberação do Pedido de Venda "
								cCancelLog	:= "R"

								aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						Else
						//	nErro++
							lOk 		:= .F.
							cStatus		:= "E"
							cMensagem	:= aAltPV[2]
							cCancelLog	:= "R"

							aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf
					Else
						//nErro++
						lOk 		:= .F.
						cStatus		:= "E"
						cMensagem	:= aCancNF[2]
						cCancelLog	:= "R"

						aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf
				EndIf

				If lOk
					IncProc(CAT544086)	//"Ajustando registro de inclusão..."

					//-- Atualiza o registro de inclusão como reprocessado
					fAtuUQB({UQB->(Recno())}, "R", UQB->UQB_PEDIDO, UQB->UQB_NF, UQB->UQB_SERIE, .T.)

					//-- Remove o registro cancelado do array aRegAgru caso tenha sido realizado agrupamento
					If (nPos := AScan(aRegAgru, UQB->(Recno()))) > 0
						ADel(aRegAgru, nPos)
						ASize(aRegAgru, Len(aRegAgru) - 1)
					EndIf

					Aadd(aAtuGetDad, {{UQB->(Recno())}, "R", UQB->UQB_PEDIDO, UQB->UQB_NF, UQB->UQB_SERIE})
				EndIf
			EndIf
		EndIf
	Next nI

	fRestAreas(aAreas)
Return(lOk)

/*/{Protheus.doc} fPosRegAtivo
Posiciona no ultimo registro ativo e processado da tabela UQB.
@type function
@author Juliano Fernandes
@since 25/01/2019
@version 1.0
@param cDoc, caracter, Numero do documento (CTE/CRT) a ser localizado
@param lExiste, logico, Indica se existe algum registro importado
@return lOk, Indica se o registro foi localizado
/*/
Static Function fPosRegAtivo(cDoc, lExiste)

	Local aTCSetField	:= {}

	Local cCancel 		:= Space(TamSX3("UQB_CANCEL")[1])
	Local cQuery		:= ""
	Local cAliasQry		:= ""

	Local lOk			:= .F.
	Local lReproc		:= UQB->UQB_CANCEL == "R"

	Default lExiste		:= .F.

	DbSelectArea("UQB")
	UQB->(DbSetOrder(2)) //UQB_FILIAL+UQB_NUMERO+UQB_CANCEL
	If UQB->(DbSeek(xFilial("UQB") + cDoc + cCancel))
		lExiste := .T.

		While !UQB->(EoF()) .And. UQB->UQB_FILIAL == xFilial("UQB") .And. UQB->UQB_NUMERO == cDoc
			If UQB->UQB_STATUS == "P" // Integrado
				lOk := .T.
				Exit
			EndIf

			UQB->(DbSkip())
		EndDo
	EndIf

	If !lOk .And. lReproc
		// --------------------------------------------------------------------------------------
		// Busca as cartas de correção processadas para posicionar na última e que está ativa
		// --------------------------------------------------------------------------------------
		cAliasQry := GetNextAlias()

		cQuery := " SELECT R_E_C_N_O_ RECNOUQB "					+ CRLF
		cQuery += " FROM " + RetSQLName("UQB") 						+ CRLF
		cQuery += " WHERE UQB_FILIAL = '" + xFilial("UQB") + "' " 	+ CRLF
		cQuery += " 	AND UQB_CHVCTE = '" + cDoc + "' " 			+ CRLF
		cQuery += " 	AND UQB_STATUS = 'P' " 						+ CRLF
		cQuery += " 	AND D_E_L_E_T_ <> '*' " 					+ CRLF
		cQuery += " ORDER BY R_E_C_N_O_ DESC " 						+ CRLF

		Aadd( aTCSetField, { "RECNOUQB", "N", 17, 0	} )

		MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

		If !(cAliasQry)->(EoF())
			lOk := .T.
			UQB->(DbGoTo( (cAliasQry)->(RECNOUQB) ))
		EndIf

		(cAliasQry)->(DbCloseArea())

		DbSelectArea("UQB")
	EndIf

Return(lOk)

/*/{Protheus.doc} fReport
Gera o relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return Nil, Nulo
@type function
/*/
Static Function fReport()
	
	//Local cPerg			:= "PRT0558"
	Local lBold			:= .T.
	Local lItalic		:= .T.
	Local lUnderline	:= .T.

    Private NomePrt		:= "PRT0528"
    Private VersaoJedi	:= "V1.20"
	Private oF12		:= TFont():New("Arial",,12,,!lBold,,,,,!lUnderline,!lItalic)
	Private oF12UB		:= TFont():New("Arial",,12,, lBold,,,,, lUnderline,!lItalic)
	Private oF12B		:= TFont():New("Arial",,12,, lBold,,,,,!lUnderline,!lItalic)
	Private oF18B		:= TFont():New("Arial",,18,, lBold,,,,,!lUnderline,!lItalic)

	Private cTitulo		:= NomePrt + CAT544087 + VersaoJedi	// " - Relatório de Arq. Importados - "
	Private oRelatorio	:= Nil
	Private oSecCab		:= Nil
	Private oSecIt		:= Nil

	ProcRegua(0)
	IncProc()

	oRelatorio := ReportDef()
	oRelatorio:PrintDialog()

Return

/*/{Protheus.doc} ReportDef
Define as informações do Relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return oRelatorio, ${return_description}
@type function
/*/
Static Function ReportDef()

	//Local aCab 			:= oGetDadUQB:aCols
	Local bAction		:= {||}
	Local cAliasIt		:= GetNextAlias()
	Local cArquivo		:= "PRT0558_" + DtoS( Date() ) + StrTran( Time(), ":", "" )
	Local cTitulo		:= NomePrt + CAT544088 + VersaoJedi	//" - Arquivos CTE/CRT - "
	Local cBmpLogo		:= "\logotipos\logo_empresa.jpg" //Deve ser jpg na pasta system
												 //A função FisxLogo("1") busca o logo(BMP) a ser impresso, mas
												 //esse logo não é impresso caso a opção selecionada seja arquivo
	Local nI			:= 1
	Local oRelatorio	:= Nil

	// Atualiza a GetDados
	oGetDadUQC:Refresh()
	// Atualiza a GetDados
	oGetDadUQB:Refresh()

	bAction := { |oRelatorio| PrintReport( oRelatorio, oGetDadUQB:aCols, cAliasIt) }

	// Instanciando o objeto TReport
	oRelatorio := TReport():New("PRT0558")
	oRelatorio:nFontBody:=10
	oRelatorio:SetLineHeight(50)
	oRelatorio:SetLogo(cBmpLogo)
	oSecCab := TRSection():New( oRelatorio , "Cabec", /*aCab*/, , , , , , , .T.	 )

	For nI := 4 to Len(aHeaderUQB) - 2
		TRCell():New( oSecCab, aHeaderUQB[nI][2], /*aCab*/, , , , .F.,,,,,,,,,, .T. )
	Next

	oSecIt := TRSection():New( oRelatorio , "Itens", cAliasIt, , , , , , , .T.	 )
	For nI := 1 to Len(aHeaderUQC) - 2
		TRCell():New( oSecIt, aHeaderUQC[nI][2], cAliasIt, ,  , , .F.)
	Next

	oSecCab:SetHeaderSection( .T. )
	TRFunction():New(oSecCab:Cell("UQB_NUMERO"),/*cId*/,"COUNT", /*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/, .F., .T., .F., oSecCab)

	// Define o título do reltório
	oRelatorio:SetTitle( cTitulo )

	// Define os parâmetros de configuração (perguntas) do relatório
	oRelatorio:SetParam( "PRT0558" )

	// Define o bloco de código que será executado na confirmação da impressão
	oRelatorio:SetAction( bAction )

	// Define a orientação da impressão do relatório
	oRelatorio:SetLandScape()

	// Define o tamanho do papel para landscape
	oRelatorio:oPage:SetPaperSize( DMPAPER_A4 )

	// Define o nome do arquivo temporário utilizado para a impressão do relatório
	oRelatorio:SetFile( cArquivo )

	// Define a Descrição do Relatório
	oRelatorio:SetDescription( CAT544089 ) //"Esta rotina imprime as ordens de venda e seus respectivos itens"

	// Desabilita o cabeçalho padrão do TReport
	oRelatorio:lHeaderVisible := .T.

	// Desabilita o rodapé padrão do TReport
	oRelatorio:lFooterVisible := .F.

	oRelatorio:Preview()

Return oRelatorio

/*/{Protheus.doc} fImpIt
Retorna todos os itens do relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return cNumUQB, cNumUQB
@param oRelatorio, object, Relatório
@param cAliasIt, characters, alias
@type function
/*/
Static Function fImpIt(oRelatorio, cAliasIt)
	Local cNUMUQB	:= oSecCab:Cell("UQB_IDIMP ")
	Local cQuery 	:= ""

	cNUMUQB := cNUMUQB:GetValue()

	// Define a query para pesquisa dos arquivos.
	cQuery  += "SELECT  UQC.UQC_ITEM, UQC.UQC_PRODUT, SB1.B1_DESC,"            							+ CRLF
	cQuery  += "        UQC.UQC_PRCVEN, UQC.R_E_C_N_O_ RECNOUQC"            							+ CRLF
	cQuery  += "FROM    " + RetSqlName("UQC") + "  UQC "                                              + CRLF
	cQuery 	+= "INNER JOIN " + RetSqlName("SB1") + "  SB1 "											+ CRLF
	cQuery 	+= "	ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' " 										+ CRLF
	cQuery 	+= "	AND SB1.B1_COD = UQC.UQC_PRODUT" 													+ CRLF
	cQuery 	+= "	AND SB1.D_E_L_E_T_ <> '*'" 															+ CRLF
	cQuery  += "WHERE   UQC.UQC_FILIAL = '" + xFilial("UQC") + "' "                                     + CRLF
	cQuery  += "AND     UQC.UQC_IDIMP = '" + AllTrim(cNumUQB) + "' "                            		+ CRLF
	cQuery  += "AND     UQC.D_E_L_E_T_ <> '*' "                                                     	+ CRLF
	cQuery  += "ORDER BY UQC.UQC_ITEM " 			                                                   	+ CRLF

	MPSysOpenQuery(cQuery, cAliasIt)

Return cNumUQB

/*/{Protheus.doc} PrintReport
Imprime as linhas do Relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return Nil, Nulo
@param oRelatorio, object, Relatorio
@param aUQB, array, array de cabeçalho
@param cAliasIt, characters, alias da query
@type function
/*/
Static Function PrintReport( oRelatorio, aUQB, cAliasIt )
	Local nI 	:= 0
	Local nJ 	:= 0
	Local nPos	:= 0

 	For nI:= 1 to Len(aUQB)
	 	If (nPos := AScan(aFiliais, {|x| x[2] == aUQB[nI,nPsUQBFilial]})) > 0
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])

			// Incrementa a régua de progressão do relatório
			oRelatorio:IncMeter()

			oSecCab:Init(.T.)
			For nJ:= 4 to Len(aUQB[nI]) - 3 //Alias_WT + Recno + Flag de delete
				oSecCab:Cell(aHeaderUQB[nJ][2]):SetValue(aUQB[nI][nJ])
			Next

			oSecCab:PrintLine()

			oSecIt:Init()
			fImpIt(oRelatorio, cAliasIt)
			While !(cAliasIt)->(EoF())
				oSecIt:PrintLine()
				(cAliasIt)->(DbSkip())
			EndDo

			//finalizo a segunda seção para que seja reiniciada para o proximo registro
			oSecIt:Finish()
			oSecCab:Finish()
			//imprimo uma linha para separar um arquivo do outro
			oRelatorio:ThinLine()
			oRelatorio:SkipLine()
		EndIf
	Next

	oSecIt:Finish()
	oRelatorio:ThinLine()
	//finalizo a primeira seção
	oSecCab:Finish()
Return

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

/*/{Protheus.doc} EXECUTE
Função que executa função sql
@author Douglas Gregorio
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
		MsgAlert( CAT544090 + CRLF + cErro, "PRT0558 - Carta Frete" )	// "Erro ao executar rotina:"
	EndIf

Return lRet

/*/{Protheus.doc} fGrvLog
Grava o registro de log para a importação dos arquivos CTE/CRT
@author Paulo Carvalho
@since 07/01/2019
@version 1.01
@type Static Function
/*/
Static Function fGrvLog()

	Local aArea		:= GetArea()
	Local cHora		:= ""
	Local cUsuario	:= IIf(l528Auto, cUserSched, UsrRetName(RetCodUsr()))
	Local dData		:= Date()
	Local nI 		:= 1

	If cFilArq == ""
		cFilArq := UQB->UQB_FIL
	EndIf

	If cFornec == ""
		cFornec := UQB->UQB_FORNEC
	EndIf

	// Abre a tabela de log da importação de arquivos CTE

	For nI := 1 To Len(aLogs)

		cHora := Time()

		DbSelectArea( "UQF" )

		// Trava a tabela para inclusão de registro
		UQF->(RecLock( "UQF", .T. ))
			// Grava as informações do log
			If !Empty(aLogs[nI][1])
				UQF->UQF_FILIAL	:= fDefFilial(aLogs[nI][1])
			Else
				UQF->UQF_FILIAL	:= FWxFilial("UQF")
			EndIf

			UQF->UQF_FIL	:= cFilArq
			UQF->UQF_DATA	:= dData
			UQF->UQF_HORA	:= cHora
			UQF->UQF_REGCOD	:= aLogs[nI][2]
			UQF->UQF_FORNEC	:= aLogs[nI][3]
			UQF->UQF_VALOR	:= aLogs[nI][4]
			UQF->UQF_MSG	:= aLogs[nI][5]
			UQF->UQF_MSGDET	:= aLogs[nI][6]
			UQF->UQF_NLINHA	:= aLogs[nI][7]
			UQF->UQF_ARQUIV	:= CAT545072	// "Integração"
			UQF->UQF_USER	:= cUsuario
			UQF->UQF_LIDO	:= "N"
			UQF->UQF_ACAO	:= "INT"
			UQF->UQF_STATUS	:= aLogs[nI][8]

			If l528Auto
				UQF->UQF_IDSCHE := cIdSched
			EndIf

			UQF->UQF_IDIMP	:= aLogs[nI][9]
			UQF->UQF_CANCEL	:= aLogs[nI][10]
			UQF->UQF_BLQMAI	:= aLogs[nI][11]

		// Destrava a Tabela
		UQF->(MsUnlock())
	Next nI

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

/*/{Protheus.doc} fValExecAut
Monta a mensagem de erro gerada pela Execauto e retorna para gravação da mensagem em detalhes.
@author Kevin Willians
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

/*/{Protheus.doc} fDefMoeda
Define o código da moeda no sistema de acordo com a sigla informada no arquivo importado.
@author Paulo Carvalho
@since 21/03/2019
@param cMoedaArq, caracter, Sigla da moeda informada no arquivo importado.
@return nMoeda, numérico, Código da moeda.
@type function
/*/
Static Function fDefMoeda(cMoeda)

	Local aArea		:= GetArea()
	Local aAreaUQN	:= UQN->(GetArea())

	Local nMoeda	:= 1

	// Verifica se cMoeda não está vazio
	If !Empty(cMoeda)
		DbSelectArea("UQN")
		UQN->(DbSetOrder(1))	// UQN_FILIAL + UQN_MOEDAR

		If UQN->(DbSeek(FWxFilial("UQN") + cMoeda))
			nMoeda 	:= UQN->UQN_CODIGO
		EndIf
	EndIf

	RestArea(aAreaUQN)
	RestArea(aArea)

Return nMoeda

/*/{Protheus.doc} fDefTes
Retorna a TES a ser utilizada no pedido de venda
@author Tiago Malta
@since 25/10/2021
@return cTes, TES a ser utilizada
@type function
/*/
Static Function fDefTes()

	Local cTes	:=	"" //SuperGetMV("PLG_544TES",.F.,"501") // "501"

	dbselectarea("UQA")
	UQA->( dbsetorder(1) )
	UQA->( dbseek( xFilial("UQA") + UQB->UQB_FILIAL + UQB->UQB_UFFOR ) )

	While UQA->( !eof() ) .AND. UQA->UQA_EMPEMI == UQB->UQB_FILIAL .AND. Alltrim(UQA->UQA_UFORIG) == Alltrim(UQB->UQB_UFFOR)

		If Alltrim(UQB->UQB_UFDES) $ Alltrim(UQA->UQA_UFDEST) .AND. ;
			Alltrim(UQA->UQA_CFOP)   == Substr(Alltrim(UQB->UQB_CFOP),2,4) .AND. ;
			Alltrim(UQA->UQA_CSTICM) == Alltrim(UQB->UQB_CSTICM) .AND. ;
			Alltrim(UQA->UQA_CSTPIS) == Alltrim(UQB->UQB_CSTPIC) .AND. ;
			Alltrim(UQA->UQA_CSTCOF) == Alltrim(UQB->UQB_CSTPIC)
		
			cTes := UQA->UQA_TES
			exit
		Endif

		UQA->( dbskip() )
	Enddo

Return cTes

/*/{Protheus.doc} fGetNaturez
Retorna a natureza que será gravada no Pedido de Venda.
@author Juliano Fernandes
@since 05/09/2019
@version 1.0
@return cNatureza, Código da Natureza
@param cTpCon, caracter, Indica se é um CTE (ZTRC) ou CRT (ZCRT)
@param cFornec, caracter, Código do cliente
@param cLoja, caracter, Loja do cliente
@type function
/*/
Static Function fGetNaturez(cTpCon, cFornec, cLoja)

	Local cNatureza := ""

	If AllTrim(cTpCon) == "ZCRT" // CRT
		cNatureza := SuperGetMV("PLG_NATCRT",.F.,"21001")
	Else // CTE
		cNatureza := SuperGetMV("PLG_NATCTE",.F.,"21002")//Posicione("SA2",1,xFilial("SA2") + cFornec + cLoja,"A2_NATUREZ")
	EndIf

Return(cNatureza)

/*/{Protheus.doc} fGetOriDes
Retorna os estados e municípios de origem e destino.
@author Juliano Fernandes
@since 06/09/2019
@version 1.0
@return aInfo, Array com dados da origem e destino
@param cTpCon, caracter, Indica se é um CTE (ZTRC) ou CRT (ZCRT)
@param cUFCol, caracter, UF de coleta
@param cUFDes, caracter, UF de destino
@param cMunCol, caracter, Conteúdo do campo UQB_MUNCOL que contém os dados de origem e destino
@type function
/*/
Static Function fGetOriDes(cTpCon, cUFCol, cUFDes, cMunCol)

	Local aOrigem	:= {"",""}
	Local aDestino	:= {"",""}
	Local aOriDes	:= {}

	Local cCodMun	:= ""

	If AllTrim(cTpCon) == "ZTRC" // CTE
		aOrigem[1]  := cUFCol
		aDestino[1] := cUFDes

		If ";" $ cMunCol
			aOriDes := Separa(cMunCol,";",.F.)

			If Len(aOriDes) == 2
				If !Empty(aOriDes[1])
					cCodMun := AllTrim( aOriDes[1] )
					cCodMun := SubStr(cCodMun, 3)

					aOrigem[2] := cCodMun
				EndIf

				If !Empty(aOriDes[2])
					cCodMun := AllTrim( aOriDes[2] )
					cCodMun := SubStr(cCodMun, 3)

					aDestino[2] := cCodMun
				EndIf
			EndIf
		EndIf
	EndIf

Return({ aOrigem, aDestino })

/*/{Protheus.doc} fAjustTit
Função para o ajuste de títulos de mesmo número que não pertencem ao CTE/CRT que está sendo reprocessado.
@author Juliano Fernandes
@since 20/09/2019
@version 1.0
@return Nil, Não há retorno
@param cPrefixo, caracter, Prefixo do título
@param cNum, caracter, Número do título
@param cParcela, caracter, Parcela do título
@param cTipo, caracter, Tipo do título
@param cFornec, caracter, Cliente do título
@param cLoja, caracter, Loja do título
@param cNumUQB, caracter, Numero da tabela UQB que está sendo processado
@param cTpAjuste, caracter, Tipo de ajuste: 1 = Ajusta para filial XXXX, 2 = Retorna filial original
@param aTitulos, array, Titulos que foram ajustados (somente para tipo de ajuste = 2)
@type function
/*/
Static Function fAjustTit(cPrefixo, cNum, cParcela, cTipo, cFornec, cLoja, cNumUQB, cTpAjuste, aTitulos)

	Local aAreas		:= {}
	Local aTitAjust 	:= {}
	Local aTCSetField	:= {}

	Local cAliasQry		:= ""
	Local cQuery		:= ""

	Local nI 			:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SE1->(GetArea()))

	If cTpAjuste == "1"

		// -----------------------------------------------------------
		// Ajusta os títulos com parcela diferente e que
		// pertencem a outro CTE/CRT para filial XXXX
		// -----------------------------------------------------------
		cAliasQry := GetNextAlias()

		cQuery := " SELECT SE1.R_E_C_N_O_ RECNOSE1, SE1.E1_FILIAL "			+ CRLF
		cQuery += " FROM " + RetSQLName("SE1") + " SE1 "					+ CRLF
		cQuery += " 	INNER JOIN " + RetSQLName("UQB") + " UQB " 			+ CRLF
		cQuery += " 		ON  UQB.UQB_FILIAL  = '" + xFilial("UQB") + "' " + CRLF
		cQuery += " 		AND UQB.UQB_FORNEC = SE1.E1_CLIENTE " 			+ CRLF
		cQuery += " 		AND UQB.UQB_LOJA = SE1.E1_LOJA " 				+ CRLF
		cQuery += " 		AND UQB.UQB_PREFIX = SE1.E1_PREFIXO " 			+ CRLF
		cQuery += " 		AND UQB.UQB_TITULO  = SE1.E1_NUM " 				+ CRLF
		cQuery += " 		AND UQB.UQB_PARCEL = SE1.E1_PARCELA " 			+ CRLF
		cQuery += " 		AND UQB.UQB_TIPOTI = E1_TIPO " 					+ CRLF
		cQuery += " 		AND UQB.UQB_NUMERO  <> '" + cNumUQB + "' " 		+ CRLF
		cQuery += " 		AND UQB.D_E_L_E_T_ <> '*' " 					+ CRLF
		cQuery += " WHERE   SE1.E1_FILIAL  = '" + xFilial("SE1") + "' " 	+ CRLF
		cQuery += " 	AND SE1.E1_CLIENTE = '" + cFornec + "' " 			+ CRLF
		cQuery += " 	AND SE1.E1_LOJA    = '" + cLoja + "' " 				+ CRLF
		cQuery += " 	AND SE1.E1_PREFIXO = '" + cPrefixo + "' " 			+ CRLF
		cQuery += " 	AND SE1.E1_NUM     = '" + cNum + "' " 				+ CRLF
		cQuery += " 	AND SE1.E1_PARCELA <> '" + cParcela + "' " 			+ CRLF
		cQuery += " 	AND SE1.E1_TIPO    = '" + cTipo + "' " 				+ CRLF
		cQuery += " 	AND SE1.D_E_L_E_T_ <> '*' " 						+ CRLF

		Aadd( aTCSetField, { "RECNOSE1", "N", 17, 0	} )

		MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

		If !(cAliasQry)->(EoF())
			DbSelectArea("SE1")

			While !(cAliasQry)->(EoF())

				SE1->(DbGoTo( (cAliasQry)->RECNOSE1 ))

				If SE1->(Recno()) == (cAliasQry)->RECNOSE1
					Aadd( aTitAjust, { (cAliasQry)->RECNOSE1, (cAliasQry)->E1_FILIAL } )

					SE1->(Reclock("SE1", .F.))
						SE1->E1_FILIAL := "XXXX"
					SE1->(MsUnlock())
				EndIf

				(cAliasQry)->(DbSkip())
			EndDo
		EndIf

		(cAliasQry)->(DbCloseArea())

	Else

		// -----------------------------------------------------------
		// Retorna para a filial original os registros
		// alterados anteriormente
		// -----------------------------------------------------------
		DbSelectArea("SE1")

		For nI := 1 To Len(aTitulos)
			SE1->(DbGoTo( aTitulos[nI,1] ))

			If SE1->(Recno()) == aTitulos[nI,1]

				SE1->(Reclock("SE1", .F.))
					SE1->E1_FILIAL := aTitulos[nI,2]
				SE1->(MsUnlock())

			EndIf
		Next nI

	EndIf

	fRestAreas(aAreas)

Return(AClone(aTitAjust))

/*/{Protheus.doc} fQtdLibItem
Retorna a quantidade disponível para a liberação do item do pedido de venda.
@author Juliano Fernandes
@since 27/09/2019
@version 1.0
@return nQtdDisp, Quantidade disponível para liberação do item
@param cPedido, caracter, Numero do pedido de venda
@param cItem, caracter, Item do pedido de venda
@param nQuantTot, numerico, Quantidade total do item
@type function
/*/
Static Function fQtdLibItem(cPedido, cItem, nQuantTot)

	Local aAreas		:= {}

	Local nQtdDisp		:= nQuantTot
	Local nQtdLibItem	:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC9->(GetArea()))

	DbSelectArea("SC9")
	SC9->(DbSetOrder(1)) // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
	If SC9->(DbSeek(xFilial("SC9") + cPedido + cItem))
		While !SC9->(EoF()) .And. SC9->C9_FILIAL == xFilial("SC9") .And. SC9->C9_PEDIDO == cPedido .And. SC9->C9_ITEM == cItem

			nQtdLibItem += SC9->C9_QTDLIB

			SC9->(DbSkip())
		EndDo

		nQtdDisp := nQuantTot - nQtdLibItem
	EndIf

	fRestAreas(aAreas)

Return(nQtdDisp)

/*/{Protheus.doc} fValGetUQB
Retorna o valor do CTE/CRT original para reprocessamento
@author Icaro Laudade
@since 18/10/2019
@return nValUQBOri, Valor original do CTE/CRT
@param cNumUQB, characters, Número do CTE/CRT
@type function
/*/
Static Function fValGetUQB(cNumUQB)

	Local cTmpAlias 	:=	GetNextAlias()
	Local nValUQBOri	:=	0

	cQuery := " SELECT UQB.UQB_VALOR "											+ CRLF
	cQuery += " FROM " + RetSQLName("UQB") + " UQB "							+ CRLF
	cQuery += " WHERE UQB.UQB_FILIAL = '" + xFilial("UQB") + "' "				+ CRLF
	cQuery += "   AND UQB.UQB_NUMERO = '" + cNumUQB + "'"						+ CRLF
	cQuery += "   AND UQB.UQB_CANCEL = '" + Space(TamSX3("UQB_CANCEL")[1]) + "'"	+ CRLF
	cQuery += "   AND UQB.D_E_L_E_T_ <> '*' " 									+ CRLF

	MpSysOpenQuery( cQuery, cTmpAlias)

	If !(cTmpAlias)->(EOF())
		nValUQBOri := (cTmpAlias)->UQB_VALOR
	EndIf

	(cTmpAlias)->(DbCloseArea())

Return nValUQBOri

/*/{Protheus.doc} fGrvImpost
Grava impostos na Nota Fiscal de Saída.
@author Juliano Fernandes
@since 28/11/2019
@version 1.0
@return Nil, Não há retorno
@param cDoc, caracter, Numero do documento
@param cSerie, caracter, Série do documento
@param cFornec, caracter, Código do Cliente da NF
@param cLoja, caracter, Código da Loja do cliente da NF
@param cFormul, caracter, Código do formulário
@param cTipo, caracter, Tipo da NF
@param cPedido, caracter, Código do pedido de venda
@type function
/*/
Static Function fGrvImpost(cDoc, cSerie, cFornec, cLoja, cFormul, cTipo, cPedido)

	Local aAreas		:= {}

	Local cFilLogada	:= FWCodFil()
	Local cChvSF2		:= ""
	Local cChvSD2		:= ""
	Local cChvSF3		:= ""
	Local cChvSFT		:= ""
	Local cCFOP			:= ""

	Local lAtuICMS		:= .F.
	Local lPedag_SJP	:= .F.
	Local lZeraSF3		:= .F.
	Local lCTE			:= .F.
	Local lIsenICMS		:= .F.
	Local lNF_RS		:= .F. // Variável que indica se a NF é do Rio Grande do Sul

	Local nICMS			:= 0
	Local nPICM			:= 0
	Local nBICM			:= 0
	Local nTotICMSIt	:= 0
	Local nRecnoSD2		:= 0
	Local nRecnoSFT		:= 0
	Local nRecnoSF3		:= 0
	Local nDiferenca	:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SA2->(GetArea()))
	Aadd(aAreas, SF2->(GetArea()))
	Aadd(aAreas, SD2->(GetArea()))
	Aadd(aAreas, SFT->(GetArea()))
	Aadd(aAreas, SF3->(GetArea()))

	// -------------------------------------------------------------------------------
	// Verifica se a NF é do estado do Rio Grande do Sul e a TES utilizada é a 502.
	// -------------------------------------------------------------------------------
	If AllTrim(UQB->UQB_TPCON) != "ZCRT"
		If AllTrim(UQB->UQB_UFCOL) == "RS" .And. AllTrim(UQB->UQB_UFDES) == "RS"
			DbSelectArea("SA2")
			SA2->(DbSetOrder(1)) // A2_FILIAL + A2_CLIENTE + A2_LOJA
			If SA2->(DbSeek(xFilial("SA2") + UQB->UQB_FORNEC + UQB->UQB_LOJA))
				If AllTrim(SA2->A2_EST) == "RS"
					If AllTrim(cFilLogada) == "0104" .Or. AllTrim(cFilLogada) == "0106" .Or.  AllTrim(cFilLogada) == "0110"
						DbSelectArea("SC6")
						SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
						If SC6->(DbSeek(xFilial("SC6") + cPedido))
							If AllTrim(SC6->C6_TES) == "502"
								lNF_RS := .T.
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	cCFOP		:= Left(UQB->UQB_CFOP,4)
	nICMS		:= UQB->UQB_ICMS
	nPICM		:= UQB->UQB_PICMS
	nBICM		:= UQB->UQB_BSICMS
	lCTE		:= "ZTRC" $ AllTrim(UQB->UQB_TPCON) // CTE
	lIsenICMS	:= lNF_RS .Or. (nICMS == 0 .And. nPICM == 0)

	DbSelectArea("SF2") ; SF2->(DbSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	DbSelectArea("SD2") ; SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	DbSelectArea("SFT") ; SFT->(DbSetOrder(1)) // FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
	DbSelectArea("SF3") ; SF3->(DbSetOrder(5)) // F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT

	cChvSF2 := xFilial("SF2")
	cChvSF2 += PadR(cDoc	, TamSX3("F2_DOC")[1]    )
	cChvSF2 += PadR(cSerie	, TamSX3("F2_SERIE")[1]	 )
	cChvSF2 += PadR(cFornec, TamSX3("F2_CLIENTE")[1])
	cChvSF2 += PadR(cLoja	, TamSX3("F2_LOJA")[1]   )
	cChvSF2 += PadR(cFormul	, TamSX3("F2_FORMUL")[1] )
	cChvSF2 += PadR(cTipo	, TamSX3("F2_TIPO")[1]   )

	If SF2->(DbSeek( cChvSF2 ))
		cChvSD2 := xFilial("SD2")
		cChvSD2 += PadR(SF2->F2_DOC		, TamSX3("D2_DOC")[1]    )
		cChvSD2 += PadR(SF2->F2_SERIE	, TamSX3("D2_SERIE")[1]  )
		cChvSD2 += PadR(SF2->F2_CLIENTE	, TamSX3("D2_CLIENTE")[1])
		cChvSD2 += PadR(SF2->F2_LOJA	, TamSX3("D2_LOJA")[1]   )

		If SD2->(DbSeek( cChvSD2 ))
			While !SD2->(EoF()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == cChvSD2
				If cFilLogada == "0102" .And. "PEDAGIO" $ Upper(SD2->D2_COD)
					lPedag_SJP	:= .T.
				Else
					lPedag_SJP	:= .F.
					lAtuICMS	:= .T.
				EndIf

				SD2->(Reclock("SD2",.F.))
					SD2->D2_CF := cCFOP

					If !lPedag_SJP
						SD2->D2_PICM	:= nPICM
						SD2->D2_VALICM	:= ((SD2->D2_PRCVEN * SD2->D2_PICM) / 100)
						SD2->D2_ALIQSOL	:= nPICM
						SD2->D2_BASEICM	:= IIf(lIsenICMS, 0, SD2->D2_PRCVEN)

						// ------------------------------------------------------------------
						// Grava o Recno do registro que teve o valor de ICMS alterado para
						// que caso haja diferença entre o total de ICMS e soma dos itens,
						// este registro terá a diferença adicionada ou subtraida.
						// ------------------------------------------------------------------
						If nRecnoSD2 == 0
							nRecnoSD2 := SD2->(Recno())
						EndIf
					EndIf
				SD2->(MsUnlock())

				nTotICMSIt += SD2->D2_VALICM

				cChvSFT := xFilial("SFT")
				cChvSFT += PadR("S"				, TamSX3("FT_TIPOMOV")[1])
				cChvSFT += PadR(SD2->D2_SERIE	, TamSX3("FT_SERIE")[1]  )
				cChvSFT += PadR(SD2->D2_DOC		, TamSX3("FT_NFISCAL")[1])
				cChvSFT += PadR(SD2->D2_CLIENTE	, TamSX3("FT_CLIEFOR")[1])
				cChvSFT += PadR(SD2->D2_LOJA	, TamSX3("FT_LOJA")[1]   )
				cChvSFT += PadR(SD2->D2_ITEM	, TamSX3("FT_ITEM")[1]   )
				cChvSFT += PadR(SD2->D2_COD		, TamSX3("FT_PRODUTO")[1])

				SFT->(DbSetOrder(1)) // FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
				If SFT->(DbSeek( cChvSFT ))
					SFT->(Reclock("SFT",.F.))
						SFT->FT_CFOP := SD2->D2_CF

						If !lPedag_SJP
							SFT->FT_ALIQICM	:= SD2->D2_PICM
							SFT->FT_VALICM	:= SD2->D2_VALICM
							SFT->FT_BASEICM	:= SD2->D2_BASEICM
							SFT->FT_BSICMOR	:= SD2->D2_BASEICM


							// ----------------------------------------------------------------------------------------------------------
							// Ajuste feito por Juliano Fernandes em 05/02/2020 conforme solicitação feita por Marcos Santos (Skype) na
							// gravação do campo FT_ISENICM:
							// Quando não tiver valor de ICMS na interface tem que atualizar os campos F3_ISENICM e FT_ISENICM com
							// o valor dos campos F3_VALCONT e FT_VALCONT, somente para CTE (CRT não entra nesta regra).
							// ----------------------------------------------------------------------------------------------------------
							If lCTE
								If lIsenICMS
									SFT->FT_ISENICM := SFT->FT_VALCONT
								Else
									SFT->FT_ISENICM := 0
								EndIf
							Else
								SFT->FT_ISENICM	:= IIf(nICMS > 0, SFT->FT_ISENICM, 0)
							EndIf

							// ------------------------------------------------------------------
							// Grava o Recno do registro que teve o valor de ICMS alterado para
							// que caso haja diferença entre o total de ICMS e soma dos itens,
							// este registro terá a diferença adicionada ou subtraida.
							// ------------------------------------------------------------------
							If nRecnoSFT == 0
								nRecnoSFT := SFT->(Recno())
							EndIf
						EndIf
					SFT->(MsUnlock())

					cChvSF3 := xFilial("SF3")
					cChvSF3 += PadR(SFT->FT_SERIE	, TamSX3("F3_SERIE")[1]  )
					cChvSF3 += PadR(SFT->FT_NFISCAL	, TamSX3("F3_NFISCAL")[1])
					cChvSF3 += PadR(SFT->FT_CLIEFOR	, TamSX3("F3_CLIEFOR")[1])
					cChvSF3 += PadR(SFT->FT_LOJA	, TamSX3("F3_LOJA")[1]   )
					cChvSF3 += PadR(SFT->FT_IDENTF3	, TamSX3("F3_IDENTFT")[1])

					If SF3->(DbSeek( cChvSF3 ))
						lZeraSF3 := .T.

						cChvSFT := xFilial("SFT")
						cChvSFT += SFT->FT_TIPOMOV
						cChvSFT += SFT->FT_CLIEFOR
						cChvSFT += SFT->FT_LOJA
						cChvSFT += SFT->FT_SERIE
						cChvSFT += SFT->FT_NFISCAL
						cChvSFT += SFT->FT_IDENTF3

						SFT->(DbSetOrder(3)) // FT_FILIAL+FT_TIPOMOV+FT_CLIEFOR+FT_LOJA+FT_SERIE+FT_NFISCAL+FT_IDENTF3
						If SFT->(DbSeek( cChvSFT ))
							SF3->(Reclock("SF3",.F.))
								While !SFT->(EoF()) .And. cChvSFT == SFT->(FT_FILIAL+FT_TIPOMOV+FT_CLIEFOR+FT_LOJA+FT_SERIE+FT_NFISCAL+FT_IDENTF3)
									SF3->F3_CFO := SFT->FT_CFOP

									If !lPedag_SJP
										If lZeraSF3
											SF3->F3_VALICM	:= 0
											SF3->F3_BASEICM	:= 0
											SF3->F3_BSICMOR := 0

											If !lCTE
												SF3->F3_ISENICM	:= 0
											EndIf

											lZeraSF3 := .F.
										EndIf

										SF3->F3_ALIQICM	:= SFT->FT_ALIQICM
										SF3->F3_VALICM	+= SFT->FT_VALICM
										SF3->F3_BASEICM	+= SFT->FT_BASEICM
										SF3->F3_BSICMOR += SFT->FT_BASEICM

										// ----------------------------------------------------------------------------------------------------------
										// Ajuste feito por Juliano Fernandes em 05/02/2020 conforme solicitação feita por Marcos Santos (Skype) na
										// gravação do campo F3_ISENICM:
										// Quando não tiver valor de ICMS na interface tem que atualizar os campos F3_ISENICM e FT_ISENICM com
										// o valor dos campos F3_VALCONT e FT_VALCONT, somente para CTE (CRT não entra nesta regra).
										// ----------------------------------------------------------------------------------------------------------
										If lCTE
											If lIsenICMS
												SF3->F3_ISENICM := SF3->F3_VALCONT
											Else
												SF3->F3_ISENICM := 0
											EndIf
										Else
											SF3->F3_ISENICM	+= SFT->FT_ISENICM
										EndIf

										// ------------------------------------------------------------------
										// Grava o Recno do registro que teve o valor de ICMS alterado para
										// que caso haja diferença entre o total de ICMS e soma dos itens,
										// este registro terá a diferença adicionada ou subtraida.
										// ------------------------------------------------------------------
										If nRecnoSF3 == 0
											nRecnoSF3 := SF3->(Recno())
										EndIf
									EndIf

									SFT->(DbSkip())
								EndDo
							SF3->(MsUnlock())
						EndIf
					EndIf
				EndIf

				SD2->(DbSkip())
			EndDo
		EndIf

		//If lAtuICMS
			SF2->(Reclock("SF2",.F.))
				SF2->F2_VALICM	:= nICMS
				SF2->F2_BASEICM	:= nBICM //IIf(lIsenICMS, 0, nBICM)
			SF2->(MsUnlock())
		//EndIf

		// ----------------------------------------------------------------------
		// Verifica se há diferença entre a soma de ICMS dos itens e cabeçalho
		// ----------------------------------------------------------------------
		If nICMS > 0 .And. nTotICMSIt > 0
			nDiferenca := nICMS - nTotICMSIt

			If nDiferenca != 0
				// ---------------------------
				// Ajusta a diferença na SD2
				// ---------------------------
				If nRecnoSD2 > 0
					SD2->(DbGoTo( nRecnoSD2 ))

					If SD2->(Recno()) == nRecnoSD2
						SD2->(RecLock("SD2",.F.))
							SD2->D2_VALICM += nDiferenca
						SD2->(MsUnlock())
					EndIf
				EndIf

				// ---------------------------
				// Ajusta a diferença na SFT
				// ---------------------------
				If nRecnoSFT > 0
					SFT->(DbGoTo( nRecnoSFT ))

					If SFT->(Recno()) == nRecnoSFT
						SFT->(RecLock("SFT",.F.))
							SFT->FT_VALICM += nDiferenca
						SFT->(MsUnlock())
					EndIf
				EndIf

				// ---------------------------
				// Ajusta a diferença na SF3
				// ---------------------------
				If nRecnoSF3 > 0
					SF3->(DbGoTo( nRecnoSF3 ))

					If SF3->(Recno()) == nRecnoSF3
						SF3->(RecLock("SF3",.F.))
							SF3->F3_VALICM += nDiferenca
						SF3->(MsUnlock())
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fAjustaSX5
Verifica e ajusta a tabela 01 da SX5 (Numeração de NF de Saída) para evitar o erro
"Primary Key violation in SE1" na função padrão CHKE1NOTA que está no fonte MATXFUNA.PRX.
@author Juliano Fernandes
@since 22/01/2020
@version 1.0
@return Nil, Não há retorno
@param cSerieNF, caracter, Série da Nota Fiscal
@type function
/*/
Static Function fAjustaSX5(cSerieNF)

	Local cQuery		:= ""
	Local cNumNF		:= ""
	Local cNumNFOrig	:= ""
	Local cAliasQry		:= GetNextAlias()

	Local lExisteNF		:= .T.

	cQuery := " SELECT X5_DESCRI "						+ CRLF
	cQuery += " FROM " + RetSQLName("SX5")				+ CRLF
	cQuery += " WHERE X5_FILIAL = '" + cFilAnt + "' "	+ CRLF
	cQuery += " 	AND X5_TABELA = '01' "				+ CRLF
	cQuery += " 	AND X5_CHAVE = '" + cSerieNF + "' "	+ CRLF
	cQuery += " 	AND D_E_L_E_T_ <> '*' "				+ CRLF

	MPSysOpenQuery( cQuery, cAliasQry )

	If !(cAliasQry)->(Eof())
		cNumNF := AllTrim((cAliasQry)->X5_DESCRI)
		cNumNFOrig := cNumNF

		While lExisteNF
			// --------------------------------------------------------
			// Verifica se já existe registro com o código encontrado
			// --------------------------------------------------------
			cQuery := " SELECT COUNT(E1_FILIAL) TITULOS "						+ CRLF
			cQuery += " FROM " + RetSQLName("SE1") + " SE1 "					+ CRLF
			cQuery += " WHERE SE1.E1_FILIAL = '" + xFilial("SE1") + "' "		+ CRLF
			cQuery += " 	AND SE1.E1_PREFIXO = '" + cSerieNF + "' "			+ CRLF
			cQuery += " 	AND SE1.E1_NUM = '" + cNumNF + "' "					+ CRLF
			cQuery += " 	AND SE1.E1_TIPO = '" + MVNOTAFIS + "' "				+ CRLF
			cQuery += " 	AND SE1.D_E_L_E_T_ <> '*' "							+ CRLF

			IIf(Select(cAliasQry) > 0, (cAliasQry)->(DbCloseArea()), Nil)

			MPSysOpenQuery( cQuery, cAliasQry, {{"TITULOS", "N", 17, 0}} )

			If !(cAliasQry)->(Eof())
				If (cAliasQry)->TITULOS == 0
					lExisteNF := .F.
				EndIf
			Else
				lExisteNF := .F.
			EndIf

			If lExisteNF
				cNumNF := Soma1(cNumNF)
			EndIf
		EndDo

		If cNumNFOrig != cNumNF
			// ----------------------------------------------
			// Atualiza a SX5 com o numero da proxima NF
			// ----------------------------------------------
			cQuery := " UPDATE " + RetSQLName("SX5")										+ CRLF
			cQuery += " SET X5_DESCRI = '" + PadR(cNumNF, TamSX3("X5_DESCRI")[1]) + "', "	+ CRLF
			cQuery += " 	X5_DESCSPA = '" + PadR(cNumNF, TamSX3("X5_DESCSPA")[1]) + "', "	+ CRLF
			cQuery += " 	X5_DESCENG = '" + PadR(cNumNF, TamSX3("X5_DESCENG")[1]) + "' "	+ CRLF
			cQuery += " WHERE X5_FILIAL = '" + cFilAnt + "' "								+ CRLF
			cQuery += " 	AND X5_TABELA = '01' "											+ CRLF
			cQuery += " 	AND X5_CHAVE = '" + cSerieNF + "' "								+ CRLF
			cQuery += " 	AND D_E_L_E_T_ <> '*' "											+ CRLF

			Execute(cQuery)
		EndIf
	EndIf

	(cAliasQry)->(DbCloseArea())

Return(Nil)

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

/*/{Protheus.doc} fContaPagar
Visualização de Conta a Pagar do registro posicionado.
@author Icaro Laudade
@since 18/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fContaPagar()
Local nPsIdImp		:=	aScan(oGetDadUQB:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQB_IDIMP"  })
Local nPsTpCf		:=	aScan(oGetDadUQB:aHeader, {|aHeader| AllTrim(aHeader[2]) == "UQB_TPCF"  })
Private aRotina		:=	StaticCall(FINA050, MenuDef)
Private INCLUI 		:= .F. 
Private ALTERA 		:= .F. 
Private EXCLUI 		:= .F. 
	DbSelectArea("UQB")
	UQB->(DbSetOrder(1))	// UQG_FILIAL + UQG_IDIMP
	If UQB->( DbSeek(xFilial("UQB") + oGetDadUQB:aCols[oGetDadUQB:nAt,nPsIdImp]+ oGetDadUQB:aCols[oGetDadUQB:nAt,nPsTpCf]) )
		IF UQB->UQB_RECSE2 > 0
			DbSelectArea("SE2")
			SE2->(dbGoto(UQB->UQB_RECSE2))
			fE2Visual( "SE2",UQB->UQB_RECSE2,2 )
		Else			
			MsgAlert("Não Existe Contas a Pagar Relacioando")
		ENDIF	
	EndIf	
Return

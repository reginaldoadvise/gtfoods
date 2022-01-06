#Include "Totvs.ch"
#Include "CATTMS.ch"

/*/{Protheus.doc} PRT0544
Define as funções específicas para manutenção de arquvios CTE/CRT.
@author Paulo Carvalho / Juliano Fernandes
@since 28/12/2018
@version P12 17.0.1
@database SQL Server
@type User Function
/*/
User Function PRT0544( nOperacao , uPar )
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

	Private cCliente	:= ""
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

    Local bChange       := {|| fChgUQD()}

    Local nH, nI, nJ

	Local nRow			:= 0
	Local nLeft			:= 0
	Local nBottom		:= 0
	Local nRight		:= 0

    // Reinicia o array aHeader
    aHeaderUQD 	:= {}
    aCampos 	:= {}

	If !l528Auto
		// Define as coordenadas seguindo o padrão de criação da página
		nRow	:= oSize:GetDimension( "GETDADOS_UQD", "LININI" )
		nLeft	:= oSize:GetDimension( "GETDADOS_UQD", "COLINI" )
		nBottom	:= oSize:GetDimension( "GETDADOS_UQD", "LINEND" )
		nRight	:= oSize:GetDimension( "GETDADOS_UQD", "COLEND" )
	EndIf

	// Adiciona, manualmente, os campos da tabela que serão visualizados para o array aCampos
	Aadd( aCampos, "UQD_FILIAL" )
	Aadd( aCampos, "UQK_DESCRI" )
	Aadd( aCampos, "UQD_IDIMP"  )
    Aadd( aCampos, "UQD_TPCON"  )
    Aadd( aCampos, "UQD_NUMERO" )
	Aadd( aCampos, "UQD_DTIMP"  )
    Aadd( aCampos, "UQD_EMISSA" )
    Aadd( aCampos, "UQD_CLIENT" )
    Aadd( aCampos, "UQD_LOJACL" )
    Aadd( aCampos, "A1_NOME" 	)
    Aadd( aCampos, "UQD_VALOR"  )
    Aadd( aCampos, "UQD_MOEDA"  )
	Aadd( aCampos, "UQD_PEDIDO"	)
	Aadd( aCampos, "UQD_NF" 	)
	Aadd( aCampos, "UQD_SERIE" 	)
	Aadd( aCampos, "UQD_CANCEL"	)

	// Adiciona campo para legenda no aHeader
	fAddCheck( @aHeaderUQD )

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeaderUQD, 1 )

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeaderUQD, 2 )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQD, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
    AdHeadRec( "UQD", aHeaderUQD )

	// Popula o array com dados inicias em branco.
	Aadd( aArray, oNo )
	Aadd( aArray, oBlue )
	Aadd( aArray, oInclusao )

	For nJ := 4 To Len( aHeaderUQD ) - 2
		Aadd( aArray, CriaVar( aHeaderUQD[nJ][2], .T. ) )
    Next

    Aadd( aArray, "UQD" 	) // Alias WT
    Aadd( aArray, 0 		) // Recno WT
	Aadd( aArray, .F. 		) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderUQD)
		If Empty(aHeaderUQD[nH][3]) .And. aHeaderUQD[nH][8] == "C"
			aHeaderUQD[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		// Instancia a GetDados
		oGetDadUQD   := MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialog, aHeaderUQD, { aArray }, bChange, /*cTela*/	)

		oGetDadUQD:oBrowse:bLDblClick := {|| fCheck(), oGetDadUQD:oBrowse:Refresh()}

		// Impede a edição de linha
		oGetDadUQD:SetEditLine( .F. )

		// Atualiza a GetDados
		oGetDadUQD:Refresh()
	EndIf

    // Reinicia o array aHeader
    aHeaderUQE := {}
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
    Aadd( aCampos, "UQE_ITEM"   )
    Aadd( aCampos, "UQE_PRODUT" )
    Aadd( aCampos, "B1_DESC"    )
    Aadd( aCampos, "UQE_PRCVEN" )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQE, aCampos[nI] )
	Next

	// Adiciona o Alias e o Recno
    AdHeadRec( "UQE", aHeaderUQE )

	// Popula o array com dados inicias em branco.
	For nJ := 1 To Len( aHeaderUQE ) - 2
        Aadd( aArray, CriaVar( aHeaderUQE[nJ][2], .T. ) )
    Next

    Aadd( aArray, "UQE" 	) // Alias WT
    Aadd( aArray, 0 		) // Recno WT
	Aadd( aArray, .F. 		) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderUQE)
		If Empty(aHeaderUQE[nH][3]) .And. aHeaderUQE[nH][8] == "C"
			aHeaderUQE[nH][3] := "@!"
		EndIf
	Next

	If !l528Auto
		// Instancia a GetDados
		oGetDadUQE   := MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialog, aHeaderUQE, { aArray }, /*uChange*/, /*cTela*/	)

		// Impede a edição de linha
		oGetDadUQE:SetEditLine( .F. )

		// Atualiza a GetDados
		oGetDadUQE:Refresh()
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
	_SetNamedPrvt("nPsUQDCheck"	, GDFieldPos("CHK"		 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDLeg1"	, GDFieldPos("LEG1"		 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDLeg2"	, GDFieldPos("LEG2"		 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDFilial", GDFieldPos("UQD_FILIAL" , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQKDescric", GDFieldPos("UQK_DESCRI", aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDIDImp"	, GDFieldPos("UQD_IDIMP"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDTpCon"	, GDFieldPos("UQD_TPCON"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDNumero"	, GDFieldPos("UQD_NUMERO" , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDDtImp"	, GDFieldPos("UQD_DTIMP"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDEmissao", GDFieldPos("UQD_EMISSA", aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDCliente", GDFieldPos("UQD_CLIENT", aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDLojaCli", GDFieldPos("UQD_LOJACL", aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDNomeCli", GDFieldPos("A1_NOME"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDValor"	, GDFieldPos("UQD_VALOR"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDMoeda"	, GDFieldPos("UQD_MOEDA"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDPedido"	, GDFieldPos("UQD_PEDIDO" , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDNF"		, GDFieldPos("UQD_NF"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDSerie"	, GDFieldPos("UQD_SERIE"	 , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDAlias"	, GDFieldPos("UQD_ALI_WT" , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDRecno"	, GDFieldPos("UQD_REC_WT" , aHeaderUQD), "U_PRT0528")
	_SetNamedPrvt("nPsUQDDelet"	, Len(aHeaderUQD) + 1				  , "U_PRT0528")

	_SetNamedPrvt("nPsUQEItem"	, GDFieldPos("UQE_ITEM"	 , aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQEProduto", GDFieldPos("UQE_PRODUT", aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQEDesc"	, GDFieldPos("B1_DESC"	 , aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQEPrcVen"	, GDFieldPos("UQE_PRCVEN" , aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQEAlias"	, GDFieldPos("UQE_ALI_WT" , aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQERecno"	, GDFieldPos("UQE_REC_WT" , aHeaderUQE), "U_PRT0528")
	_SetNamedPrvt("nPsUQEDelet"	, Len(aHeaderUQE) + 1				  , "U_PRT0528")
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
	Local nPosFil		:= 0
	Local cDesFil		:= ""
	Local aSM0Data 		:= FWLoadSM0(.T.)
	
	// Define o campos que devem passar pela função TCSetField
	aTam := TamSX3("UQD_EMISSA") ; Aadd( aTCSetField, { "UQD_EMISSA", aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQD_DTIMP"  ) ; Aadd( aTCSetField, { "UQD_DTIMP"	, aTam[3], aTam[1], aTam[2]	} )
	aTam := TamSX3("UQD_VALOR"  ) ; Aadd( aTCSetField, { "UQD_VALOR"  , aTam[3], aTam[1], aTam[2]	} )
    aTam := {17, 0, "N"}         ; Aadd( aTCSetField, { "RECNOUQD"  , aTam[3], aTam[1], aTam[2]	} )

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
		//Aadd(aFiliais, {cFilAnt, xFilial("UQD")})

		// Define a query para pesquisa dos arquivos.
		cQuery  := "SELECT  UQD.UQD_FILIAL, UQD.UQD_DTIMP, UQD.UQD_IDIMP, UQD.UQD_TPCON, UQD.UQD_NUMERO, "		+ CRLF
		cQuery  += "        UQD.UQD_EMISSA, UQD.UQD_CLIENT, UQD.UQD_LOJACL, SA1.A1_NOME, UQD.UQD_VALOR, "	+ CRLF
		cQuery  += "        UQD.UQD_MOEDA, UQD.UQD_PEDIDO, UQD.UQD_NF, UQD.UQD_SERIE, UQD.UQD_STATUS, "			+ CRLF
		cQuery  += "        UQD.UQD_CANCEL, UQD.R_E_C_N_O_ RECNOUQD, UQK.UQK_DESCRI "						+ CRLF
		cQuery  += "FROM    " + RetSqlName("UQD") + " UQD "                                             	+ CRLF
		cQuery 	+= "LEFT JOIN " + RetSqlName("SA1") + " SA1 "											+ CRLF
		cQuery 	+= "	ON SA1.A1_FILIAL = '" + xFilial("SA1") + "' " 										+ CRLF
		cQuery 	+= "	AND SA1.A1_COD = UQD.UQD_CLIENT" 													+ CRLF
		cQuery 	+= "	AND SA1.A1_LOJA = UQD.UQD_LOJACL" 													+ CRLF
		cQuery 	+= "	AND SA1.D_E_L_E_T_ <> '*'" 															+ CRLF
		cQuery	+= "LEFT JOIN " + RetSqlName("UQK") + " UQK "												+ CRLF
		cQuery	+= "	ON UQK.UQK_FILIAL = '" + xFilial("UQK") + "' "										+ CRLF
		cQuery	+= "	AND UQK.UQK_FILPRO = UQD.UQD_FILIAL "												+ CRLF
		cQuery	+= "	AND UQK.D_E_L_E_T_ <> '*' "															+ CRLF
		// cQuery  += "WHERE   UQD.UQD_FILIAL = '" + xFilial("UQD") + "' "                                  	+ CRLF
		cQuery  += "WHERE   UQD.UQD_FILIAL IN " + cFiliaisIn + " "	                                     	+ CRLF

		If l528Auto
			cQuery  += "AND		UQD.UQD_STATUS = 'I'     "     			                	    	 		+ CRLF
			cQuery  += "AND		UQD.UQD_IDSCHE = '" + cIdSched + "'     "                     	    	 	+ CRLF
		Else
			// Define o range de documentos
			cAuxDocDe	:= fDefDocDe(cDocDe, cFiliaisIn)
			cAuxDocAte	:= fDefDocAte(cDocAte, cFiliaisIn)

			If !Empty(cAuxDocDe)
				cQuery	+= "AND		UQD.UQD_NUMERO >= '" + cAuxDocDe + "' "										+ CRLF
			EndIf

			If !Empty(cAuxDocAte)
				cQuery	+= "AND		UQD.UQD_NUMERO <= '" + cAuxDocAte + "' "										+ CRLF
			EndIf

			If !Empty(cClienteDe)
				cQuery  += "AND     UQD.UQD_CLIENT >= '" + cClienteDe       + "' "                         	 	+ CRLF
			EndIf

			If !Empty(cClienteAte)
				cQuery  += "AND     UQD.UQD_CLIENT <= '" + cClienteAte      + "' "                            	+ CRLF
			EndIf

			If !Empty(dDataDe)
				cQuery  += "AND     UQD.UQD_DTIMP >= '" + DtoS( dDataDe )  + "' "                            	+ CRLF
			EndIf

			If !Empty(dDataAte)
				cQuery  += "AND     UQD.UQD_DTIMP <= '" + DtoS( dDataAte ) + "' "                            	+ CRLF
			EndIf

			If cCbStatus != "Todos"
				cQuery  += "AND     UQD.UQD_STATUS = '" + Left(cCbStatus,1) + "'  "                            	+ CRLF
			EndIf

			If !Empty(cPedidoDe)
				cQuery  += "AND     UQD.UQD_PEDIDO >= '" + cPedidoDe       + "'   "                         	 	+ CRLF
			EndIf

			If !Empty(cPedidoAte)
				cQuery  += "AND     UQD.UQD_PEDIDO <= '" + cPedidoAte       + "'  "                         	 	+ CRLF
			EndIf

			If !Empty(cGNFDe)
				cQuery  += "AND     UQD.UQD_NF >= '" + cGNFDe       + "'      "                         	 		+ CRLF
			EndIf

			If !Empty(cGNFAte)
				cQuery  += "AND     UQD.UQD_NF <= '" + cGNFAte       + "'     "                         	 		+ CRLF
			EndIf
		EndIf

		cQuery  += "AND     UQD.D_E_L_E_T_ <> '*' "																+ CRLF
		cQuery  += "ORDER BY UQD.UQD_FILIAL, UQD.R_E_C_N_O_ "                                               		+ CRLF

		MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

		ProcRegua(0)

		While !(cAliasQry)->(Eof())
			lDados := .T.

			IncProc()

			If AScan(aFiliais, {|x| x[2] == (cAliasQry)->UQD_FILIAL}) == 0
				// ------------------------------------------------------------------
				// Inserido duas vezes no array aFilials por questão de adaptação
				// ao modo que o programa foi desenvolvido inicialmente.
				// ------------------------------------------------------------------
				Aadd(aFiliais, {(cAliasQry)->UQD_FILIAL, (cAliasQry)->UQD_FILIAL})
			EndIf

			// Reinicia aLinha a cada iteração
			aLinha := {}

			Aadd( aLinha, oNo )

			// Define a legenda para o registro.
			If (cAliasQry)->UQD_STATUS == "I" // Arquivo importado
				Aadd( aLinha, oBlue )
			ElseIf (cAliasQry)->UQD_STATUS == "P" // Arquivo integrado no Protheus
				Aadd( aLinha, oGreen )
			ElseIf (cAliasQry)->UQD_STATUS == "E" // Arquivo com erros na integração
				Aadd( aLinha, oRed )
			ElseIf (cAliasQry)->UQD_STATUS == "C" // Arquivo cancelado
				Aadd( aLinha, oBlack )
			ElseIf (cAliasQry)->UQD_STATUS == "R" // Arquivo reprocessado
				Aadd( aLinha, oVioleta )
			EndIf

			// Define a legenda para o registro.
			If Empty((cAliasQry)->UQD_CANCEL) // Arquivo para inclusão
				Aadd( aLinha, oInclusao )
			ElseIf (cAliasQry)->UQD_CANCEL == "R" // Arquivo para reprocessamento
				Aadd( aLinha, oReprocess )
			ElseIf (cAliasQry)->UQD_CANCEL == "C" // Arquivo para cancelamento
				Aadd( aLinha, oCancel )
			EndIf

			nPosFil  := aScan(aSM0Data,{|x| Alltrim(x[2]) == Alltrim((cAliasQry)->UQD_FILIAL) })

            If nPosFil > 0
                cDesFil := aSM0Data[nPosFil][7]
			Else
				cDesFil := ""
			Endif

			Aadd( aLinha, (cAliasQry)->UQD_FILIAL	)
			Aadd( aLinha, cDesFil	)
			Aadd( aLinha, (cAliasQry)->UQD_IDIMP	)
			Aadd( aLinha, (cAliasQry)->UQD_TPCON 	)
			Aadd( aLinha, (cAliasQry)->UQD_NUMERO 	)
			Aadd( aLinha, (cAliasQry)->UQD_DTIMP	)
			Aadd( aLinha, (cAliasQry)->UQD_EMISSA 	)
			Aadd( aLinha, (cAliasQry)->UQD_CLIENT 	)
			Aadd( aLinha, (cAliasQry)->UQD_LOJACL 	)
			Aadd( aLinha, (cAliasQry)->A1_NOME	 	)
			Aadd( aLinha, (cAliasQry)->UQD_VALOR 	)
			Aadd( aLinha, (cAliasQry)->UQD_MOEDA 	)
			Aadd( aLinha, (cAliasQry)->UQD_PEDIDO 	)

			If !lFaturaPed .And. !Empty((cAliasQry)->UQD_PEDIDO)
				aNota := fDefFiscal((cAliasQry)->UQD_IDIMP, (cAliasQry)->UQD_PEDIDO)

				Aadd( aLinha, aNota[1] 				)
				Aadd( aLinha, aNota[2] 				)
			Else
				Aadd( aLinha, (cAliasQry)->UQD_NF 	)
				Aadd( aLinha, (cAliasQry)->UQD_SERIE )
			EndIf
			
			Aadd( aLinha, (cAliasQry)->UQD_CANCEL 	                )
			Aadd( aLinha, "UQD" 	                )
			Aadd( aLinha, (cAliasQry)->RECNOUQD 	)
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
			For nJ := 4 To Len( aHeaderUQD ) - 2
				Aadd( aLinha, CriaVar( aHeaderUQD[nJ][2], .T. ) )
			Next

			Aadd( aLinha, "UQD" 	) // Alias WT
			Aadd( aLinha, 0 		) // Recno WT
			Aadd( aLinha, .F. 		) // D_E_L_E_T_

			Aadd(aDados, aLinha)
		EndIf

		// Define array aDados como aCols da GetDados
		oGetDadUQD:SetArray( aDados )
	Else
		aCoUQDAuto := AClone(aDados)
	EndIf

	//-- Marca todos os registros
	fBtnCheck(1)

	// Atualiza a GetDados
	If !l528Auto
		//oGetDadUQD:Refresh()
	EndIf

	//-- Carrega a GetDados da UQE
	fChgUQD()

	If !lDados
		MsgAlert(CAT544010, cCadastro) //"Nenhum registro localizado com os filtros informados."
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
	Local aAreaUQD	:= UQD->(GetArea())
	Local aNF		:= {"",""}

	DbSelectArea("SC5")
	SC5->(DbSetOrder(1))	// C5_FILIAL + C5_NUM
	If SC5->(DbSeek(FWxFilial("SC5") + cPedido))
		aNF[1] 	:= SC5->C5_NOTA
		aNF[2] 	:= SC5->C5_SERIE

		// Atualiza a tabela UQD
		DbSelectArea("UQD")
		UQD->(DbSetOrder(1))	// UQD_FILIAL + UQD_IDIMP
		If UQD->(DbSeek(FWxFilial("UQD") + cIdImp))
			UQD->(RecLock("UQD", .F.))
				UQD->UQD_NF 	:= aNF[1]
				UQD->UQD_SERIE 	:= aNF[2]
			UQD->(MsUnlock())
		EndIf
	EndIf

	RestArea(aAreaUQD)
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

	cQuery	+= "SELECT	UQD.UQD_NUMERO "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQD") + " UQD "					+ CRLF
	// cQuery	+= "WHERE	UQD.UQD_FILIAL = '" + xFilial("UQD") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQD.UQD_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQD.UQD_NUMERO LIKE '%" + AllTrim(cDocumento) + "%'"	+ CRLF
	cQuery	+= "AND		UQD.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQD.UQD_NUMERO "									+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocDe := (cAliasQry)->UQD_NUMERO
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

	cQuery	+= "SELECT	UQD.UQD_NUMERO "										+ CRLF
	cQuery	+= "FROM 	" + RetSqlName("UQD") + " UQD "					+ CRLF
	// cQuery	+= "WHERE	UQD.UQD_FILIAL = '" + xFilial("UQD") + "'  "			+ CRLF
	cQuery	+= "WHERE	UQD.UQD_FILIAL IN " + cFiliaisIn + "  "				+ CRLF
	cQuery	+= "AND		UQD.UQD_NUMERO LIKE '%" + AllTrim(cDocumento) + "%'"	+ CRLF
	cQuery	+= "AND		UQD.D_E_L_E_T_ <> '*'  "							+ CRLF
	cQuery	+= "ORDER BY UQD.UQD_NUMERO DESC "								+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocAte := (cAliasQry)->UQD_NUMERO
	Else
		cAuxDocAte := AllTrim(cDocumento)
	EndIf

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return cAuxDocAte

/*/{Protheus.doc} fFillUQE
Filtra e carrega os dados da tabela UQE conforme o ID de importação passado por parâmetro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param cIDImp, characters, Código do ID de importação
@type function
/*/
Static Function fFillUQE(cIDImp)
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
		aTam := TamSX3("UQE_PRCVEN") ; Aadd( aTCSetField, { "UQE_PRCVEN", aTam[3], aTam[1], aTam[2]	} )
		aTam := {17, 0, "N"}        ; Aadd( aTCSetField, { "RECNOUQE" , aTam[3], aTam[1], aTam[2]	} )

		// Define a query para pesquisa dos arquivos.
		cQuery  += "SELECT  UQE.UQE_ITEM, UQE.UQE_PRODUT, SB1.B1_DESC,"	+ CRLF
		cQuery  += "        UQE.UQE_PRCVEN, UQE.R_E_C_N_O_ RECNOUQE"		+ CRLF
		cQuery  += "FROM    " + RetSqlName("UQE") + " UQE "			+ CRLF
		cQuery 	+= "LEFT JOIN " + RetSqlName("SB1") + " SB1 "		+ CRLF
		cQuery 	+= "	ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' " 	+ CRLF
		cQuery 	+= "	AND SB1.B1_COD = UQE.UQE_PRODUT" 				+ CRLF
		cQuery 	+= "	AND SB1.D_E_L_E_T_ <> '*'" 						+ CRLF
		cQuery  += "WHERE   UQE.UQE_FILIAL = '" + xFilial("UQE") + "' "	+ CRLF
		cQuery  += "AND     UQE.UQE_IDIMP = '" + cIDImp + "' "         	+ CRLF
		cQuery  += "AND     UQE.D_E_L_E_T_ <> '*' "                  	+ CRLF
		cQuery  += "ORDER BY UQE.UQE_ITEM "                    			+ CRLF

		MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

		While !(cAliasQry)->(Eof())
			// Reinicia aLinha a cada iteração
			aLinha := {}

			Aadd( aLinha, (cAliasQry)->UQE_ITEM 		)
			Aadd( aLinha, (cAliasQry)->UQE_PRODUT 	)
			Aadd( aLinha, (cAliasQry)->B1_DESC 		)
			Aadd( aLinha, (cAliasQry)->UQE_PRCVEN 	)
			Aadd( aLinha, "UQE" 					)
			Aadd( aLinha, (cAliasQry)->RECNOUQE 	)
			Aadd( aLinha, lDeleted 					)

			// Adiciona a linha ao array principal
			Aadd( aDados, aLinha )

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
	EndIf

	If Empty(aDados)
		// Popula o array com dados em branco.
		For nJ := 1 To Len( aHeaderUQE ) - 2
			Aadd( aLinha, CriaVar( aHeaderUQE[nJ][2], .T. ) )
		Next

		Aadd( aLinha, "UQE" 	) // Alias WT
		Aadd( aLinha, 0 		) // Recno WT
		Aadd( aLinha, .F. 		) // D_E_L_E_T_

		Aadd(aDados, aLinha)
	EndIf

	// Define array aDados como aCols da GetDados
	oGetDadUQE:SetArray( aDados )

	// Atualiza a GetDados
	oGetDadUQE:Refresh()
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

/*/{Protheus.doc} fChgUQD
Função executada ao mudar de linha na GetDados da tabela de cabeçalho UQD.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fChgUQD()
	Local cFilImp	:= ""
	Local cIDImp 	:= ""
	Local nPos		:= 0

	If Type("oGetDadUQD") == "O"
		cFilImp := oGetDadUQD:aCols[oGetDadUQD:nAt, nPsUQDFilial]
		cIDImp  := oGetDadUQD:aCols[oGetDadUQD:nAt, nPsUQDIDImp]

		If (nPos := AScan(aFiliais, {|x| x[2] == cFilImp})) > 0
			//-- Altera para a filial do registro selecionado
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])
		EndIf

		If AllTrim(cIDImp) != AllTrim(cMemIDImp)
			fFillUQE(cIDImp)
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
		If oGetDadUQD:aCols[oGetDadUQD:nAt, nPsUQDCheck]:cName == "LBNO"
			oGetDadUQD:aCols[oGetDadUQD:nAt, nPsUQDCheck] := oOk
		Else
			oGetDadUQD:aCols[oGetDadUQD:nAt, nPsUQDCheck] := oNo
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
	Aadd(aAreas, UQD->(GetArea()))

	If l528Auto
		aColsVld := aCoUQDAuto
		nLinhaVld := nLinha
	Else
		aColsVld := oGetDadUQD:aCols
		nLinhaVld := oGetDadUQD:nAt
	EndIf

	If Empty(aColsVld[nLinhaVld,nPsUQDRecno])
		lValid := .F.
	EndIf

	If lValid
		DbSelectArea("UQD")
		UQD->(DbGoTo( aColsVld[nLinhaVld,nPsUQDRecno] ))
		If UQD->(Recno()) == aColsVld[nLinhaVld,nPsUQDRecno]
			If UQD->UQD_STATUS == "P" // Integrado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544011, cCadastro)	//"O registro selecionado não pode ser marcado pois já foi integrado ao Protheus."
				EndIf

			ElseIf UQD->UQD_STATUS == "C" // Cancelado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544012, cCadastro)	//"O registro selecionado não pode ser marcado pois foi cancelado."
				EndIf

			ElseIf UQD->UQD_STATUS == "R" // Reprocessado
				lValid := .F.

				If lExibeMsg
					MsgAlert(CAT544013, cCadastro)	//"O registro selecionado não pode ser marcado pois foi reprocessado."
				EndIf

			EndIf

			If lValid
				//-- Validação para registros de cancelamento e reprocessamento
				//-- Só permite a seleção caso o registro original já tenha sido integrado
				If UQD->UQD_CANCEL $ "C|R" // Cancelamento ou Reprocessamento
					cNumeroOri := PadR(UQD->UQD_NUMERO, TamSX3("UQD_NUMERO")[1])
					cCliVld  := UQD->UQD_CLIENT
					cLojaVld := UQD->UQD_LOJACL
					cNumVld  := UQD->UQD_NUMERO

					StaticCall(PRT0528, fAltFilial, UQD->UQD_FILIAL)

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
										If aColsVld[nI,nPsUQDFilial ] == xFilial("UQD")	.And. ;
										   aColsVld[nI,nPsUQDCliente] == cCliVld		.And. ;
										   aColsVld[nI,nPsUQDLojaCli] == cLojaVld		.And. ;
										   aColsVld[nI,nPsUQDNumero ] == cNumVld		.And. ;
										   aColsVld[nI,nPsUQDLeg2   ]:cName == "CATTMS_INC"

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
									MsgAlert(CAT544014, cCadastro)	//"O registro selecionado não pode ser marcado pois o registro de inclusão não foi integrado."
								EndIf
							EndIf
						Else
							// --------------------------------------------------------------------
							// Não encontrou nenhum registro importado
							// --------------------------------------------------------------------
							lValid := .F.

							If lExibeMsg
								MsgAlert(CAT544015, cCadastro)	//"O registro selecionado não pode ser marcado pois não foi localizado o registro de inclusão do CTE/CRT."
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
		nAt := oGetDadUQD:nAt
	EndIf

	If nOpc == 1 /* Marcar todos */

		If l528Auto
			AEVal(aCoUQDAuto, {|x| nI++, IIf(fVldCheck(.F., nI), x[nPsUQDCheck] := oOk, Nil)})
		Else
			IncProc(CAT544016)	//Marcando registros
			AEVal(oGetDadUQD:aCols, {|x| nI++, oGetDadUQD:GoTo(nI), IIf(fVldCheck(.F.), x[nPsUQDCheck] := oOk, Nil)})
		EndIf

	ElseIf nOpc == 2 /* Desmarcar todos */

		If l528Auto
			AEVal(aCoUQDAuto, {|x| nI++, x[nPsUQDCheck] := oNo})
		Else
			IncProc(CAT544017)	//"Desmarcando registros"
			AEVal(oGetDadUQD:aCols, {|x| nI++, oGetDadUQD:GoTo(nI), x[nPsUQDCheck] := oNo})
		EndIf

	ElseIf nOpc == 3 /* Inverter seleção */

		If l528Auto
			AEVal(aCoUQDAuto, {|x| nI++, x[nPsUQDCheck] := IIf(x[nPsUQDCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F., nI), oOk, oNo))})
		Else
			IncProc(CAT544018)	//"Invertendo seleção de registros"
			AEVal(oGetDadUQD:aCols, {|x| nI++, oGetDadUQD:GoTo(nI), x[nPsUQDCheck] := IIf(x[nPsUQDCheck]:cName == "LBOK", oNo, IIf(fVldCheck(.F.), oOk, oNo))})
		EndIf

	EndIf

	If !l528Auto
		oGetDadUQD:GoTo(nAt)
		oGetDadUQD:Refresh()
	EndIf

	StaticCall(PRT0528, fAltFilial, cFilBkp)

Return(Nil)

/*/{Protheus.doc} fIntegra
Realiza a integração dos dados das tabelas UQD e UQE gerando Pedido de Venda, Liberação e Nota Fiscal.
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
	Local cStatusUQD	:= ""
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

	Private cMsgDet		:= ""
	Private cRegistro	:= ""
	Private cCCusto		:= ""

	Private nOk			:= 0
	Private n544RecUQD	:= 0
	Private nErro		:= 0
	Private nValor		:= 0

	//Variáveis privadas movidas para a função inicial PRT0544
	cCliente	:= ""
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
		aColsInt := oGetDadUQD:aCols
	Else
		aColsInt := aCoUQDAuto
	EndIf

	For nI := 1 To Len(aColsInt)
		If aColsInt[nI,nPsUQDCheck]:cName == "LBOK"
			lSelect := .T.
			Exit
		EndIf
	Next nI

	If !lSelect
		lOk := .F.
		MsgAlert(CAT544019, cCadastro) //"Nenhum registro selecionado para processamento."
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

			/*/ 19/03/2019 - Alteração de Juliano Fernandes e Paulo Carvalho
				Retirada validação para integração de arquivos agrupados.
			If lOk
				//-- Altera para a filial do registro selecionado
				StaticCall(PRT0528, fAltFilial, aFiliais[nK,1])

				For nI := 1 To Len(aRegs)

					If !fVldDados(aRegs[nI], @aRegAgru, lAgrupa, aRegs)
						nErro++
					EndIf

				Next nI

				If nErro > 0
					lOk := .F.
				EndIf
			EndIf
			/*/

			If lOk
				ProcRegua((Len(aRegs) * 3))

				For nI := 1 To Len(aRegs)

					If fVldDados(aRegs[nI], @aRegAgru, lAgrupa, aRegs)
						BEGIN TRANSACTION
							aCab		:= {}
							aIte 		:= {}

							cNF 		:= ""
							cSerie 		:= ""
							cNumPed 	:= ""
							cStatusUQD 	:= ""

							lOk 		:= .T.
							lMostraErro	:= .F.

							cTipoProc 	:= fGetTpProc(aRegs[nI])

							If cTipoProc == "I"
								cCancel := " "
								cNumPed := fMontaPed(aRegs[nI], @aCab, @aIte, 3)

								If !Empty(aCab) .And. !Empty(aIte)
									IncProc(CAT544020 + cNumPed + "...") // "Incluindo Pedido de Venda "

									If fGeraPed(aCab, aIte, 3, aRegs)
										IncProc(CAT544021 + cNumPed + "...")	//"Liberando Pedido de Venda "

										If fLiberaPed(cNumPed)
											IncProc(CAT544022 + cNumPed + "...")	//"Gerando Nota Fiscal do Pedido de Venda "

											For nJ := 1 To Len(aRegs[nI])
												cTpCon		:= fGetInfUQD(aRegs[nI,nJ], "UQD_TPCON")
												nRecProc	:= aRegs[nI,nJ]
											Next nJ

											aFatPed := fFaturaPed(cNumPed, @cNF, @cSerie, cTpCon, nRecProc)

											If aFatPed[1]
												For nJ := 1 To Len(aRegs[nI])
													If !aFatPed[2]// Se o titulo não for duplicado
														cStatus 	:= "I"
														cMensagem	:= CAT544023 //"Registro integrado com sucesso."
														cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
														cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
														cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
														nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
														cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
														cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

														aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
													EndIf
													//fGrvLog(nLinha, cMensagem, cStatus)
												Next nJ
											Else
												lOk := .F.

												For nJ := 1 To Len(aRegs[nI])
													cStatus		:= "E"
													cMensagem	:= CAT544024 //"Erro ao gerar Nota Fiscal."
													cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
													cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
													cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
													nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
													cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
													cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

													aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

													//fGrvLog(nLinha, cMensagem, cStatus)
												Next nJ
											EndIf

											If lOk

												If aFatPed[2]
													lOk := .F.

													For nJ := 1 To Len(aRegs[nI])
														cStatus		:= "E"
														cMensagem	:= CAT544093 //"Título gerado já cadastrado no protheus."
														cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
														cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
														cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
														nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
														cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
														cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

														aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

														//fGrvLog(nLinha, cMensagem, cStatus)
													Next nJ

												EndIf

											EndIf
										Else
											lOk := .F.

											For nJ := 1 To Len(aRegs[nI])
												cStatus		:= "E"
												cMensagem	:= CAT544025 //"Erro na liberação de um ou mais itens do pedido."
												cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
												cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
												cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
												nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
												cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
												cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

												aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
												//fGrvLog(nLinha, cMensagem, cStatus)
											Next nJ
										EndIf
									Else
										lOk := .F.

										For nJ := 1 To Len(aRegs[nI])
											cStatus		:= "E"
											cMensagem	:= CAT544026 //"Erro ao gerar pedido de venda."
											cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
											cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
											cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
											nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
											cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
											cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

											aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
											//fGrvLog(nLinha, cMensagem, cStatus)
										Next nJ

										lMostraErro := .T.
									EndIf
								Else
									lOk := .F.

									For nJ := 1 To Len(aRegs[nI])
										cStatus		:= "E"
										cMensagem	:= CAT544027 //"Erro ao gerar dados para o pedido de venda."
										cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
										cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
										cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
										nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
										cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
										cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])

										aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
										//fGrvLog(nLinha, cMensagem, cStatus)
									Next nJ
								EndIf

								If lOk
									nOk++
									cStatusUQD := "P" // Arquivo integrado no Protheus
								Else
									nErro++
									cNumPed := ""
									cNF		:= ""
									cSerie	:= ""
									DisarmTransaction()

									cStatusUQD := "E" // Arquivo com erros na integração
								EndIf

								fAtuUQD(aRegs[nI], cStatusUQD, cNumPed, cNF, cSerie, .F.)

								Aadd(aAtuGetDad, {aRegs[nI], cStatusUQD, cNumPed, cNF, cSerie})
							ElseIf cTipoProc == "C"
								cCancel := "C"
								lOk 	:= fCancela(aRegs[nI], @cNumPed, @cNF, @cSerie, @aAtuGetDad, @aRegAgru)

								If lOk
									//-- Limpa o Pedido e Nota Fiscal dos registros cancelados e que estavam agrupados
									cStatusUQD := "I" // Importado

									If !Empty(aRegAgru)
										fAtuUQD(aRegAgru, cStatusUQD, "", "", "", .T.)

										Aadd(aAtuGetDad, {aRegAgru, cStatusUQD, "", "", ""})
									EndIf

									For nJ := 1 To Len(aRegs[nI])
										nOk++
										cStatus 	:= "I"
										cMensagem	:= CAT544028 //"Registro cancelado com sucesso."
										cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
										cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
										cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
										nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
										cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
										cCancelLog	:= "C"

										aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
										//fGrvLog(nLinha, cMensagem, cStatus)
									Next nJ

									cStatusUQD := "P" // Arquivo integrado no Protheus
								Else
									DisarmTransaction()

									cStatusUQD := "E" // Arquivo com erros no cancelamento
								EndIf

								fAtuUQD(aRegs[nI], cStatusUQD, "", "", "", .F.)

								Aadd(aAtuGetDad, {aRegs[nI], cStatusUQD, "", "", ""})

							ElseIf cTipoProc == "R"
								cCancel	:= "R"
								lOk 	:= fReprocessa(aRegs[nI], @cNumPed, @cNF, @cSerie, @aAtuGetDad, @aRegAgru)

								If lOk
									For nJ := 1 To Len(aRegs[nI])
										nOk++
										cStatus 	:= "I"
										cMensagem	:= CAT544029//"Registro reprocessado com sucesso."
										cCliente	:= fGetInfUQD(aRegs[nI,nJ], "UQD_CLIENT")
										cFilArq		:= fGetInfUQD(aRegs[nI,nJ], "UQD_FIL")
										cRegistro	:= fGetInfUQD(aRegs[nI,nJ], "UQD_NUMERO")
										nValor		:= fGetInfUQD(aRegs[nI,nJ], "UQD_VALOR")
										cIDImp		:= fGetInfUQD(aRegs[nI,nJ], "UQD_IDIMP")
										cCancelLog	:= "R"

										aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
										//fGrvLog(nLinha, cMensagem, cStatus)
									Next nJ

									cStatusUQD := "P" // Arquivo integrado no Protheus

									fAtuUQD(aRegs[nI], cStatusUQD, cNumPed, cNF, cSerie, .F.)
									Aadd(aAtuGetDad, {aRegs[nI], cStatusUQD, cNumPed, cNF, cSerie})
								Else
									nErro++
									DisarmTransaction()

									cStatusUQD := "E" // Arquivo com erros no cancelamento

									fAtuUQD(aRegs[nI], cStatusUQD, "", "", "", .F.)
									Aadd(aAtuGetDad, {aRegs[nI], cStatusUQD, "", "", ""})
								EndIf

							EndIf
						END TRANSACTION
					Else
						fAtuUQD(aRegs[nI], "E", "", "", "", .F.)
						Aadd(aAtuGetDad, {aRegs[nI], "E", "", "", ""})
					EndIf
				Next nI
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
		cMensagem 	:= 	CAT544030 + CRLF +; // "Processamento de arquivos CTE/CRT finalizado. Verifique o resultado abaixo."
						CRLF + CAT544031 + cValToChar(nOk) + CRLF +; // "Itens processados: "
						CAT544032 + cValToChar(nErro) + CRLF +; // "Itens não processados: "
						CRLF + CAT544033 // "Deseja visualizar o log de processamento?"

		If MsgYesNo( cMensagem, cCadastro )

			// Chama o programa de visualização de log de registros.
			U_PRT0533( "UQF", .T., Nil, "INT" )
		EndIf
	EndIf

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
	Local nRecnoUQD	:= 0
	Local nI 		:= 0
	Local nJ		:= 0
	Local nLen		:= 0
	Local nLenRegs	:= 0

	If !l528Auto
		aAux := AClone(oGetDadUQD:aCols)
	Else
		aAux := AClone(aCoUQDAuto)
	EndIf

	//-- Ajusta array aInfo com somente os registros da filial que está sendo processada
	For nI := 1 To Len(aAux)
		If aAux[nI,nPsUQDFilial] == cFilReg
			Aadd(aInfo, aAux[nI])
		EndIf
	Next nI

	If lAgrupa
		//-- Ordena o array da UQD por cliente, loja e recno
		ASort(aInfo,,,{|x,y| x[nPsUQDCliente] + x[nPsUQDLojaCli] + StrZero(x[nPsUQDRecno],10) < y[nPsUQDCliente] + y[nPsUQDLojaCli] + StrZero(y[nPsUQDRecno],10)})

		aAux := AClone(aInfo)
		aInfo := {}

		//-- Separa os itens selecionados pelo usuário
		AEval(aAux, {|x| IIf(x[nPsUQDCheck]:cName == "LBOK", Aadd(aInfo, x), Nil)})

		nLen := Len(aInfo)

		For nI := 1 To nLen

			cCodCli   := aInfo[nI,nPsUQDCliente]
			cLojaCli  := aInfo[nI,nPsUQDLojaCli]

			Aadd(aRegs, {})

			nLenRegs := Len(aRegs)

			While nI <= nLen .And. cCodCli == aInfo[nI,nPsUQDCliente]
				nRecnoUQD := aInfo[nI,nPsUQDRecno]

				Aadd(aRegs[nLenRegs], nRecnoUQD)

				If nI+1 <= nLen .And. cCodCli == aInfo[nI+1,nPsUQDCliente]
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
		AEval(aAux, {|x| IIf(x[nPsUQDCheck]:cName == "LBOK", Aadd(aInfo, x), Nil)})

		For nI := 1 To Len(aInfo)
			nRecnoUQD := aInfo[nI,nPsUQDRecno]

			Aadd(aRegs, {nRecnoUQD})
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
	Aadd(aAreas, UQD->(GetArea()))

	DbSelectArea("UQD")

	For nI := 1 To Len(aRegs)
		UQD->(DbGoTo(aRegs[nI]))

		If UQD->(Recno()) == aRegs[nI]
			lCancela := UQD->UQD_CANCEL == "C"
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
	Aadd(aAreas, UQD->(GetArea()))

	DbSelectArea("UQD")

	For nI := 1 To Len(aRegs)
		UQD->(DbGoTo(aRegs[nI]))

		If UQD->(Recno()) == aRegs[nI]
			lReproc := UQD->UQD_CANCEL == "R"
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
	Aadd(aAreas, UQD->(GetArea()))
	Aadd(aAreas, UQE->(GetArea()))
	Aadd(aAreas, SA1->(GetArea()))
	Aadd(aAreas, SE4->(GetArea()))
	Aadd(aAreas, SED->(GetArea()))
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SF4->(GetArea()))
	Aadd(aAreas, CTT->(GetArea()))

	If !l528Auto
		aColsVld := AClone(oGetDadUQD:aCols)
	Else
		aColsVld := AClone(aCoUQDAuto)
	EndIf

	DbSelectArea("UQD") ; UQD->(DbSetOrder(1)) // UQD_FILIAL+UQD_IDIMP
	DbSelectArea("UQE") ; UQE->(DbSetOrder(1)) // UQE_FILIAL+UQE_IDIMP+UQE_ITEM
	DbSelectArea("SA1") ; SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
	DbSelectArea("SE4") ; SE4->(DbSetOrder(1)) // E4_FILIAL+E4_CODIGO
	DbSelectArea("SED") ; SED->(DbSetOrder(1)) // ED_FILIAL+ED_CODIGO
	DbSelectArea("SB1") ; SB1->(DbSetOrder(1)) // B1_FILIAL+B1_COD
	DbSelectArea("SF4") ; SF4->(DbSetOrder(1)) // F4_FILIAL+F4_CODIGO
	DbSelectArea("CTT") ; CTT->(DbSetOrder(1)) // CTT_FILIAL+CTT_CUSTO

	If lFaturaPed
		DbSelectArea("CC2") ; CC2->(DbSetOrder(1)) // CC2_FILIAL+CC2_EST+CC2_CODMUN
	EndIf

	For nI := 1 To Len(aRegs)
		UQD->(DbGoTo(aRegs[nI]))

		If UQD->(Recno()) == aRegs[nI]
			// Define o registro e o cliente que está sendo validado
			cCliente	:= UQD->UQD_CLIENT
			cFilArq		:= UQD->UQD_FIL
			cRegistro 	:= UQD->UQD_NUMERO
			nValor		:= UQD->UQD_VALOR
			cIDImp		:= UQD->UQD_IDIMP

			If UQD->UQD_CANCEL == "C"
				Aadd(aCancela, {UQD->UQD_NUMERO, aRegs[nI]})
				cCancelLog := "C"
			ElseIf UQD->UQD_CANCEL == "R"
				cCancelLog := "R"
			Else
				cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
			EndIf

			// -------------------------------------------------------------------------------
			// Validação do cabeçalho
			// -------------------------------------------------------------------------------

			// Validação do cliente
			If !SA1->(DbSeek(xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL))

				lValid 		:= .F.
				cStatus 	:= "E"
				cMensagem	:= CAT544034 //"Cliente não cadastrado."

				aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
				//fGrvLog(nLinha, cMensagem, cStatus)
			Else

				//Comentado dia 11/10/2019 solicitação Veloce
				//O bloco abaixo é responsável por validar se a moeda do cliente é igual a do arquivo
				/*If lFaturaPed
					If !Empty(SA1->A1_XMOEDA) .And. AllTrim(Upper(UQD->UQD_MOEDA)) != "BRL"
						nMoeda	:= fDefMoeda(UQD->UQD_MOEDA)

						If SA1->A1_XMOEDA != nMoeda
							lValid 		:= .F.
							cStatus 	:= "E"

							If "ZCRT" $ UQD->UQD_TPCON
								cMensagem := CAT544106 + cCliente + CAT544107 + CAT544108//"A moeda do cliente " # " é diferente da moeda do " # " CRT."
							ElseIf "ZTRC" $ UQD->UQD_TPCON
								cMensagem := CAT544106 + cCliente + CAT544107 + CAT544109//"A moeda do cliente " # " é diferente da moeda do " # " CTE."
							EndIf

							aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						EndIf
					EndIf
				EndIf*/

				If SA1->A1_MSBLQL == "1" // Bloqueado

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544035 //Cliente bloqueado.

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				//-- Validação da condição de pagamento
				If Empty(SA1->A1_COND)

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544036 //"Condição de pagamento não informada no cadastro do cliente.

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				If !SE4->(DbSeek(xFilial("SE4") + SA1->A1_COND))

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544037 //"Condição de pagamento não cadastrada."

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf

				If lFaturaPed

					cMoeda := UQD->UQD_MOEDA

					nMoeda := fDefMoeda(cMoeda)

					If nMoeda != 1
						aAreaSM2 := SM2->(GetArea())

						DbSelectArea("SM2")
						SM2->(DbSetOrder(1)) // M2_DATA

						If SM2->(DbSeek(UQD->UQD_EMISSA))
							cCampoSM2 := "SM2->M2_MOEDA" + cValToChar(nMoeda)

							If &(cCampoSM2) == 0
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544111  + DToC(UQD->UQD_EMISSA) + "."//"Moeda sem cotação para o dia "

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf

						EndIf

						RestArea(aAreaSM2)
					EndIf

					If SE4->E4_MSBLQL == "1" // Bloqueado

						lValid 		:= .F.
						cStatus 	:= "E"
						cMensagem	:= CAT544038 //"Condição de pagamento bloqueada."

						aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf
				EndIf

				//Comentado por solicitação Veloce dia 14/10/2019 - Icaro
				//-- Validação da Natureza
				/*If Empty(SA1->A1_NATUREZ)

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544094 //"Natureza não informada no cadastro do cliente."

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf

				If !SED->(DbSeek(xFilial("SED") + SA1->A1_NATUREZ))

					lValid 		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544095 //"Natureza não cadastrada."

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf*/

			EndIf

			//-- Validação do Centro de Custo
			If !Empty(UQD->UQD_CCUSTO)
				If !CTT->(DbSeek(xFilial("CTT") + UQD->UQD_CCUSTO))

					lValid		:= .F.
					cStatus 	:= "E"
					cMensagem	:= CAT544092 + ": " + UQD->UQD_CCUSTO // Centro de Custo não encontrado

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
					//fGrvLog(nLinha, cMensagem, cStatus)
				EndIf
			EndIf

			If lFaturaPed
				//-- Validação do estado e município de origem e destino
				If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
					aOriDes		:= fGetOriDes(UQD->UQD_TPCON, UQD->UQD_UFCOL, UQD->UQD_UFDES, UQD->UQD_MUNCOL)
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

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
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

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf

			// -------------------------------------------------------------------------------
			// Validação dos itens
			// -------------------------------------------------------------------------------
			If UQE->(DbSeek(UQD->UQD_FILIAL + UQD->UQD_IDIMP))
				While !UQE->(EoF()) .And. UQE->UQE_FILIAL == UQD->UQD_FILIAL .And. UQE->UQE_IDIMP == UQD->UQD_IDIMP
					//-- Validação do produto
					If !SB1->(DbSeek(xFilial("SB1") + UQE->UQE_PRODUT))

						lValid 		:= .F.
						cStatus 	:= "E"
						cMensagem	:= CAT544039 //"Produto não cadastrado."

						aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					Else
						If SB1->B1_MSBLQL == "1" // Bloqueado

							lValid 		:= .F.
							cStatus 	:= "E"
							cMensagem	:= CAT544040 //"Produto bloqueado.

							aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf

						//Comentado por solicitação Marcos dia 17/06/2019
						//-- Validação da TES
						/*If Empty(SB1->B1_TS)

							lValid 		:= .F.
							cStatus 	:= "E"
							cMensagem	:= CAT544041 //"TES não informada no cadastro do produto.

							aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						Else*/
							cTes := fDefTes()

							If !SF4->(DbSeek(xFilial("SF4") + cTes))
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544042 //"TES não cadastrada.

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							ElseIf SF4->F4_MSBLQL == "1" // Bloqueado
								lValid 		:= .F.
								cStatus 	:= "E"
								cMensagem	:= CAT544043 //"TES bloqueada.

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						//EndIf
					EndIf

					UQE->(DbSkip())
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
			cCancela := Space(TamSX3("UQD_CANCEL")[1])

			For nI := 1 To Len(aCancela)
				//-- Busca o registro de inclusão
				DbSelectArea("UQD")
				UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
				If UQD->(DbSeek(xFilial("UQD") + aCancela[nI,1] + cCancela))
					If !Empty(UQD->UQD_PEDIDO) .And. !Empty(UQD->UQD_NF) .And. !Empty(UQD->UQD_SERIE)

						cMsgAgrup += fVerAgrupa(UQD->UQD_PEDIDO, UQD->UQD_NF, UQD->UQD_SERIE, @aRegAgru)

					ElseIf (nPos := AScan(aColsVld, {|x| x[nPsUQDRecno] == UQD->(Recno())})) > 0

						If aColsVld[nPos,nPsUQDCheck]:cName == "LBOK" // Registro selecionado
							Aadd(aRegAgru, UQD->(Recno()))
						EndIf

						//-- Em caso de agrupamento, adiciona os demais Recnos dos registros selecionados pelo
						//-- usuário para que possam ficar disponí­veis novamente para integração
						If lAgrupa
							For nJ := 1 To Len(aRegsTot)
								If (nPos := AScan(aRegsTot[nJ], {|x| x == UQD->(Recno())})) > 0
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
				lValid := MsgYesNo(CAT544044 + CRLF + CAT544045 + CRLF + CRLF + cMsgAgrup, cCadastro) //"Um ou mais registros de cancelamento selecionados foi integrado ao Protheus de forma agrupada com outros CTE/CRT."
																									  //"Confirma o cancelamento do Pedido de Venda e das Notas Fiscais abaixo para todos os CTE/CRT?"
				If !lValid

					For nI := 1 To Len(aCancela)
						cStatus 	:= "E"
						cMensagem	:= CAT544046 //"Processamento cancelado pelo usuário."
						cCancelLog	:= "C"

						aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
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
@param aRegs, array, Registros da tabela UQD para a geração do pedido de venda
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
	Local cNumUQD	:= "" //Num CTE sem série
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
	Aadd(aAreas, UQD->(GetArea()))
	Aadd(aAreas, UQE->(GetArea()))
	Aadd(aAreas, SA1->(GetArea()))
	Aadd(aAreas, SB1->(GetArea()))
	Aadd(aAreas, SC5->(GetArea()))
	Aadd(aAreas, SC6->(GetArea()))

	DbSelectArea("UQD") ; UQD->(DbSetOrder(1)) // UQD_FILIAL+UQD_IDIMP
	DbSelectArea("UQE") ; UQE->(DbSetOrder(1)) // UQE_FILIAL+UQE_IDIMP+UQE_ITEM
	DbSelectArea("SC5") ; SC5->(DbSetOrder(1)) // C5_FILIAL+C5_NUM
	DbSelectArea("SC6") ; SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

	If nOpc == 3
		For nI := 1 To Len(aRegs)
			UQD->(DbGoTo(aRegs[nI]))
			If UQD->(Recno()) == aRegs[nI]
				dDataBase  := UQD->UQD_EMISSA
				n544RecUQD := UQD->(Recno())

				If Empty(aCabec)

					If !lFaturaPed .And. lReprocess

						cNum := cPedido
					Else
						cNum := GetSXENum("SC5","C5_NUM")
						RollBackSx8()
					EndIf

					// Recupera o número do arquivo sem Série
					cNumUQD	:= UQD->UQD_NUMERO

					//Comentado dia 30/09/2019 por solicitação Veloce - Icaro
					//No cabeçalho e item deve ser gravado o mesmo conteudo do campo UQD-UQD_NUMERO
					/*If At("-", cNumUQD) > 0
						cNumUQD	:= Left(cNumUQD, At("-", cNumUQD)-1)
					EndIf*/

					nMoeda		:= fDefMoeda(UQD->UQD_MOEDA)
					cCondPag 	:= Posicione("SA1",1,xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL,"A1_COND")
					cNatureza	:= Posicione("SA1",1,xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL,"A1_NATUREZ") //fGetNaturez(UQD->UQD_TPCON, UQD->UQD_CLIENT, UQD->UQD_LOJACL)

					If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
						aOriDes		:= fGetOriDes(UQD->UQD_TPCON, UQD->UQD_UFCOL, UQD->UQD_UFDES, UQD->UQD_MUNCOL)
						aOrigem  	:= aOriDes[1]
						aDestino 	:= aOriDes[2]
					EndIf

					Aadd(aCabec, {"C5_NUM"		, cNum				, Nil})
					Aadd(aCabec, {"C5_TIPO" 	, "N"				, Nil})
					Aadd(aCabec, {"C5_CLIENTE"	, UQD->UQD_CLIENT	, Nil})
					Aadd(aCabec, {"C5_LOJACLI"	, UQD->UQD_LOJACL	, Nil})
					Aadd(aCabec, {"C5_CLIENT"	, UQD->UQD_CLIENT	, Nil})
					Aadd(aCabec, {"C5_LOJAENT"	, UQD->UQD_LOJACL	, Nil})
					Aadd(aCabec, {"C5_CONDPAG"	, cCondPag			, Nil})
					Aadd(aCabec, {"C5_TABELA"	, space(3)			, Nil})
					Aadd(aCabec, {"C5_EMISSAO"	, UQD->UQD_EMISSA	, Nil})
					Aadd(aCabec, {"C5_MOEDA"	, nMoeda			, Nil})
					Aadd(aCabec, {"C5_PEDECOM"	, cNumUQD			, Nil})
					Aadd(aCabec, {"C5_NATUREZ"	, UQD->UQD_NATURE	, Nil})

					If !Empty(aOrigem)
						/*If !Empty(aOrigem[1])
							Aadd(aCabec, {"C5_UFORIG"	, aOrigem[1]		, Nil})
						EndIf
*/
						If !Empty(aOrigem[2])
							Aadd(aCabec, {"C5_UFORIG"	, UQD->UQD_UFFOR		, Nil})
							Aadd(aCabec, {"C5_CMUNOR"	, aOrigem[2]		, Nil})
						EndIf
					EndIf

					If !Empty(aDestino)
						/*If !Empty(aDestino[1])
							Aadd(aCabec, {"C5_UFDEST"	, aDestino[1]		, Nil})
						EndIf
*/
						If !Empty(aDestino[2])
							Aadd(aCabec, {"C5_UFDEST"	, UQD->UQD_UFDES		, Nil})
							Aadd(aCabec, {"C5_CMUNDE"	, aDestino[2]		, Nil})
						EndIf
					EndIf

					If !lFaturaPed .And. lReprocess
						Aadd(aCabec, {"C5_XHIST", CAT544102 + AllTrim(UQD->UQD_CHVCTE) + " " + CAT544110 + cValToChar(nValPed), Nil}) //"C.C: " # "Valor: "

						//Complemento para gravação de pedido no campo C5_XHIST comentado dia 20/09/2019
						//+ "  " + CAT544104 + AllTrim(SC5->C5_NUM)// # "Pedido: "

					EndIf

					cItem := StrZero(0, TamSX3("C6_ITEM")[1])
				EndIf

				If UQE->(DbSeek(UQD->UQD_FILIAL + UQD->UQD_IDIMP))
					While !UQE->(EoF()) .And. UQE->UQE_FILIAL == UQD->UQD_FILIAL .And. UQE->UQE_IDIMP == UQD->UQD_IDIMP
						cItem := Soma1(cItem)
						cTES := fDefTes()

						aLinha := {}

						Aadd(aLinha, {"C6_ITEM"		, cItem						, Nil})
						Aadd(aLinha, {"C6_PRODUTO"	, UQE->UQE_PRODUT			, Nil})
						Aadd(aLinha, {"C6_QTDVEN"	, nQtde						, Nil})
						Aadd(aLinha, {"C6_PRCVEN"	, UQE->UQE_PRCVEN			, Nil})
						Aadd(aLinha, {"C6_PRUNIT"	, UQE->UQE_PRCVEN			, Nil})
						Aadd(aLinha, {"C6_VALOR"	, nQtde * UQE->UQE_PRCVEN 	, Nil})
						Aadd(aLinha, {"C6_TES"		, cTES						, Nil})
						Aadd(aLinha, {"C6_PEDCLI"	, UQD->UQD_NUMERO			, Nil})

						If lFaturaPed
							Aadd(aLinha, {"C6_CC"		, UQD->UQD_CCUSTO			, Nil})
							Aadd(aLinha, {"C6_ITEMCTA"	, UQD->UQD_ITEMCT			, Nil})
							Aadd(aLinha, {"C6_CONTA"	, UQD->UQD_CONTAC			, Nil})
						Else
							Aadd(aLinha, {"C6_CCUSTO"	, UQD->UQD_CCUSTO			, Nil})
							Aadd(aLinha, {"C6_ITEMCTA"	, UQD->UQD_ITEMCT			, Nil})
							Aadd(aLinha, {"C6_CONTA"	, UQD->UQD_CONTAC			, Nil})
						EndIf

						cCCusto := UQD->UQD_CCUSTO

						Aadd(aItens,aLinha)

						UQE->(DbSkip())
					EndDo
				EndIf
			EndIf
		Next nI
	ElseIf nOpc == 4

		If SC5->(DbSeek(xFilial("SC5") + cPedido))
			For nI := 1 To Len(aRegs)
				UQD->(DbGoTo(aRegs[nI]))
				If UQD->(Recno()) == aRegs[nI]
					n544RecUQD := UQD->(Recno())

					// Recupera o número do arquivo sem Série
					cNumUQD	:= UQD->UQD_NUMERO

					//Comentado dia 30/09/2019 por solicitação Veloce - Icaro
					//No cabeçalho e item deve ser gravado o mesmo conteudo do campo UQD-UQD_NUMERO
					/*If At("-", cNumUQD) > 0
						cNumUQD	:= Left(cNumUQD, At("-", cNumUQD)-1)
					EndIf*/

					nMoeda		:= fDefMoeda(UQD->UQD_MOEDA)
					cCondPag 	:= Posicione("SA1",1,xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL,"A1_COND")
					cNatureza	:= Posicione("SA1",1,xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL,"A1_NATUREZ") //fGetNaturez(UQD->UQD_TPCON, UQD->UQD_CLIENT, UQD->UQD_LOJACL)

					If SC5->(FieldPos("C5_UFORIG")) > 0 .And. SC5->(FieldPos("C5_CMUNOR")) > 0 .And. SC5->(FieldPos("C5_UFDEST")) > 0 .And. SC5->(FieldPos("C5_CMUNDE")) > 0
						aOriDes		:= fGetOriDes(UQD->UQD_TPCON, UQD->UQD_UFCOL, UQD->UQD_UFDES, UQD->UQD_MUNCOL)
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
					Aadd(aCabec, {"C5_EMISSAO"	, UQD->UQD_EMISSA	, Nil})
					Aadd(aCabec, {"C5_CONDPAG"	, cCondPag			, Nil})
					Aadd(aCabec, {"C5_MOEDA"	, nMoeda			, Nil})
					Aadd(aCabec, {"C5_PEDECOM"	, cNumUQD			, Nil})
					Aadd(aCabec, {"C5_NATUREZ"	, UQD->UQD_NATURE	, Nil}) //cNatureza

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

			DbSelectArea("UQD")

			cItem := StrZero(0, TamSX3("C6_ITEM")[1])

			For nI := 1 To Len(aRegs)
				UQD->(DbGoTo(aRegs[nI]))
				If UQD->(Recno()) == aRegs[nI]

					If UQE->(DbSeek(xFilial("UQE") + UQD->UQD_IDIMP))
						While !UQE->(EoF()) .And. UQE->UQE_FILIAL == xFilial("UQE") .And. UQE->UQE_IDIMP == UQD->UQD_IDIMP
							cItem := Soma1(cItem)
							cTES := fDefTes()

							aLinha := {}

							Aadd(aLinha, {"C6_ITEM"		, cItem						, Nil})
							Aadd(aLinha, {"C6_PRODUTO"	, UQE->UQE_PRODUT			, Nil})
							Aadd(aLinha, {"C6_QTDVEN"	, nQtde						, Nil})
							Aadd(aLinha, {"C6_PRCVEN"	, UQE->UQE_PRCVEN			, Nil})
							Aadd(aLinha, {"C6_PRUNIT"	, UQE->UQE_PRCVEN			, Nil})
							Aadd(aLinha, {"C6_VALOR"	, nQtde * UQE->UQE_PRCVEN 	, Nil})
							Aadd(aLinha, {"C6_TES"		, cTES						, Nil})
							Aadd(aLinha, {"C6_PEDCLI"	, UQD->UQD_NUMERO			, Nil})

							If lFaturaPed
								Aadd(aLinha, {"C6_CC"		, UQD->UQD_CCUSTO			, Nil})
								Aadd(aLinha, {"C6_ITEMCTA"	, UQD->UQD_ITEMCT			, Nil})
								Aadd(aLinha, {"C6_CONTA"	, UQD->UQD_CONTAC			, Nil})
							Else
								Aadd(aLinha, {"C6_CCUSTO"	, UQD->UQD_CCUSTO			, Nil})
								Aadd(aLinha, {"C6_ITEMCTA"	, UQD->UQD_ITEMCT			, Nil})
								Aadd(aLinha, {"C6_CONTA"	, UQD->UQD_CONTAC			, Nil})
							EndIf

							cCCusto := UQD->UQD_CCUSTO

							Aadd(aItens,aLinha)

							UQE->(DbSkip())
						EndDo
					EndIf

					//O array aRegs conterá apenas um RECNO se for um reprocessamento
					/*If !lFaturaPed .And. lReprocess
						Aadd(aCabec, {"C5_XHIST", CAT544102 + AllTrim(UQD->UQD_CHVCTE) + " " + CAT544110 + cValToChar(nTotPed), Nil}) //"C.C: " # "Valor: "

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

/*/{Protheus.doc} fGeraPed
Função que executa a inclusão ou exclusão do pedido de venda gerando o registro nas tabelas SC5 e SC6.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lOk, Indica se houve sucesso ao incluir o pedido
@param aCabec, array, Cabeçalho do pedido de venda
@param aItens, array, Itens do pedido de venda
@param aRegs , array, Registros
@type function
/*/
Static Function fGeraPed(aCabec, aItens, nOpc, aRegs)
	Local aAreas		:= {}
	Local cIDImp		:= ""
	Local cRepro		:= ""
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local cNumPed		:= ""
	Local cLojaCli		:= ""
	Local cPaisBkp		:= ""
	Local lOk 			:= .T.
	Local nLinha		:=	0
	Local nPosCliente	:=	0
	Local nPosLojaCli	:=	0
	Local nPosPedCli	:=	0
	Local nPosPed		:=	0

	Private lMsErroAuto	:= .F.
	Private lAutoErrNoFile := .T.

	Default aRegs 		:= {}

	If !lFaturaPed
		If (nPosCliente := AScan(aCabec, {|x| x[1] == "C5_CLIENTE"})) > 0
			cCliente := aCabec[nPosCliente][2]
		EndIf

		If (nPosLojaCli := AScan(aCabec, {|x| x[1] == "C5_LOJACLI"})) > 0
			cLojaCli := aCabec[nPosLojaCli][2]
		EndIf

		DbSelectArea("SA1")
		SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
		If SA1->(DbSeek(xFilial("SA1") + cCliente + cLojaCli))
			cPaisBkp := SA1->A1_PAIS

			If !Empty(cPaisBkp)
				SA1->(Reclock("SA1",.F.))
					SA1->A1_PAIS := ""
				SA1->(MsUnlock())
			EndIf
		EndIf
	EndIf

	MsExecAuto({|x,y,z| Mata410(x,y,z)}, aCabec, aItens, nOpc)

	If lMsErroAuto
		cStatus		:= "E"
		cMensagem	:= CAT544047 //"Erro ao executar programa MATA410 de gravação de Pedido de Venda via MSExecAuto.
		cMsgDet 	:= fValExecAut()

		If Len(aCabec) > 0

			If (nPosCliente := AScan(aCabec, {|x| x[1] == "C5_CLIENTE"})) > 0
				cCliente := aCabec[nPosCliente][2]
			EndIf

			If !Empty(aRegs)

				If ValType(aRegs[1]) == "A"
					cFilArq	:= fGetInfUQD(aRegs[1,1], "UQD_FIL")
					cIDImp  := fGetInfUQD(aRegs[1,1], "UQD_IDIMP")
					cRepro	:= fGetInfUQD(aRegs[1,1], "UQD_CANCEL")
				ElseIf ValType(aRegs[1]) == "N"
					cFilArq	:= fGetInfUQD(aRegs[1], "UQD_FIL")
					cIDImp  := fGetInfUQD(aRegs[1], "UQD_IDIMP")
					cRepro	:= fGetInfUQD(aRegs[1], "UQD_CANCEL")
				EndIf

			Else
				cFilArq := xFilial("SC5")
				cRepro := ""
			EndIf

		Else
			cCliente := ""
			cFilArq	 := xFilial("SC5")
			cRepro   := ""
		EndIf

		If AllTrim(cRepro) == "C"
			cCancelLog := "C"
		ElseIf AllTrim(cRepro) == "R"
			cCancelLog := "R"
		Else
			cCancelLog := Space(TamSX3("UQF_CANCEL")[1])
		EndIf

		If Len(aItens) > 0
			If (nPosPedCli := AScan(aItens[1], {|x| x[1] == "C6_PEDCLI"})) > 0
				cRegistro := aItens[1][nPosPedCli][2]
			EndIf
		Else
			cRegistro := ""
		EndIf

		nValor := 0

		aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

		cMsgDet := ""//Uma vez gravada, a variavel com o erro do execauto é limpa
	Else
		If nOpc == 3 .Or. nOpc == 4
			If !Empty(cCCusto)
				// ------------------------------------------------------------
				// Força a gravação do centro de custo na tabela SC6
				// ------------------------------------------------------------
				If (nPosPed := AScan(aCabec, {|x| x[1] == "C5_NUM"})) > 0
					cNumPed := aCabec[nPosPed,2]

					Aadd(aAreas, SC6->(GetArea()))

					DbSelectArea("SC6")
					SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
					If SC6->(DbSeek(xFilial("SC6") + cNumPed))
						While !SC6->(EoF()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. SC6->C6_NUM == cNumPed
							SC6->(Reclock("SC6", .F.))

								If lFaturaPed
									SC6->C6_CC := cCCusto
								Else
									SC6->C6_CCUSTO := cCCusto
								EndIf

							SC6->(MsUnlock())

							SC6->(DbSkip())
						EndDo
					EndIf

					fRestAreas(aAreas)

				EndIf
			EndIf
		EndIf
	EndIf

	If !lFaturaPed
		If !Empty(cPaisBkp) .And. !Empty(cCliente) .And. !Empty(cLojaCli)
			DbSelectArea("SA1")
			SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
			If SA1->(DbSeek(xFilial("SA1") + cCliente + cLojaCli))
				SA1->(Reclock("SA1",.F.))
					SA1->A1_PAIS := cPaisBkp
				SA1->(MsUnlock())
			EndIf
		EndIf
	EndIf

	lOk := !lMsErroAuto
Return(lOk)

/*/{Protheus.doc} fLiberaPed
Função que executa a liberação do pedido de venda gerando o registro na tabela SC9.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return lOk, Indica se houve sucesso ao liberar o pedido
@param cPedido, characters, Número do pedido
@type function
/*/
Static Function fLiberaPed(cPedido)
	Local aAreas	:= {}
	Local lOk 		:= .T.
	Local lCredito	:= .T.
	Local lEstoque	:= .T.
	Local lAvCred  	:= .F.
	Local lAvEst   	:= .F.
	Local lLiber	:= .F.
	Local lTransf	:= .F.

	Local nQtdLib	:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC5->(GetArea()))
	Aadd(aAreas, SC6->(GetArea()))
	Aadd(aAreas, SC9->(GetArea()))

	fSetParams("MTA440",@lLiber,@lTransf)

	DbSelectArea("SC5")
	SC5->(DbSetOrder(1)) // C5_FILIAL+C5_NUM
	If SC5->(DbSeek(xFilial("SC5") + cPedido))
		DbSelectArea("SC6")
		SC6->(DbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
		If SC6->(DbSeek(xFilial("SC6") + SC5->C5_NUM))
			While !SC6->(EoF()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. SC6->C6_NUM == SC5->C5_NUM
				nQtdLib := fQtdLibItem(SC6->C6_NUM , SC6->C6_ITEM, SC6->C6_QTDVEN - SC6->C6_QTDENT)

				If nQtdLib > 0
					If MaLibDoFat(SC6->(Recno()),nQtdLib,@lCredito,@lEstoque,lAvCred,lAvEst,lLiber,lTransf) > 0
						lOk := .T.

						//-- Marca o pedido como liberado
						MaLiberOk({SC5->C5_NUM}, .T.)
					Else
						lOk := .F.
						Exit
					EndIf
				EndIf

				SC6->(DbSkip())
			EndDo
		EndIf
	EndIf

	fRestAreas(aAreas)

Return(lOk)

/*/{Protheus.doc} fFaturaPed
Função que executa o faturamento do pedido de venda gerando a Nota Fiscal.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return aRet, Array com duas posições sendo que o primeiro indica se houve sucesso ao gerar o faturamento e o segundo se já não há titulo com a mesma chave ao integrar um CTE
@param cNumPedido, characters, Número do pedido
@param cNota, characters, Nota Fiscal que será gerada (Referência)
@param cSerie, characters, Série da Nota Fiscal que será gerada (Referência)
@param cTpCon, characters, Tipo de Contrato (ZCRT=CRT ou ZTRC=CTE)
@param nRecUQDProc, numerico, Recno da tabela UQD que está sendo processado
@type function
/*/
Static Function fFaturaPed(cNumPedido, cNota, cSerie, cTpCon, nRecUQDProc)
	Local aAreas		:= {}
	Local aAreaSE1		:= {}
	Local aPvlNfs		:= {}
	Local aRet			:= {}
	Local bAtuFin		:= Nil
	Local cEmbExp		:= ""
	Local cCCusto		:= ""
	Local lOk 			:= .T.
	Local lMostraCtb	:= .F.
	Local lAglutCtb		:= .F.
	Local lCtbOnLine	:= .F.
	Local lCtbCusto		:= .F.
	Local lReajuste		:= .F.
	Local lAtuSA7		:= .F.
	Local lECF			:= .F.
	Local lTitDupli		:= .F.
	Local nCalAcrs		:= 0
	Local nArrPrcLis	:= 0

	// Realiza a fatura do pedido apenas se não for Argentina
	If lFaturaPed
		Aadd(aAreas, GetArea())
		Aadd(aAreas, SC5->(GetArea()))
		Aadd(aAreas, SE4->(GetArea()))
		Aadd(aAreas, SC6->(GetArea()))
		Aadd(aAreas, SB1->(GetArea()))
		Aadd(aAreas, SB2->(GetArea()))
		Aadd(aAreas, SF4->(GetArea()))
		Aadd(aAreas, SC9->(GetArea()))
		Aadd(aAreas, UQD->(GetArea()))

		UQD->(DbGoTo(nRecUQDProc))

		If UQD->(Recno()) == nRecUQDProc

			If !Empty(UQD->UQD_CCUSTO)
				cClasseCC := Posicione( "CTT", 1, xFilial("CTT") + UQD->UQD_CCUSTO, "CTT_CLASSE")'
				If cClasseCC == "2"
					cCCusto := UQD->UQD_CCUSTO

				EndIf
			EndIf

			DbSelectArea("SC5")
			SC5->( DbSetOrder(1) )
			If SC5->( DbSeek(xFilial("SC5") + cNumPedido) )

				DbSelectArea("SE4")
				SE4->( DbSetOrder(1) )
				If SE4->( DbSeek(xFilial("SE4") + SC5->C5_CONDPAG) )

					DbSelectArea("SC6")
					SC6->( DbSetOrder(1) )
					If SC6->( DbSeek(xFilial("SC6") + SC5->C5_NUM) )
						Do While !SC6->(EoF()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. SC6->C6_NUM == SC5->C5_NUM

							DbSelectArea("SB1")
							SB1->( DbSetOrder(1) )
							If SB1->( DbSeek(xFilial("SB1") + SC6->C6_PRODUTO) )

								DbSelectArea("SB2")
								SB2->( DbSetOrder(1) )
								If SB2->( DbSeek(xFilial("SB2") + SC6->C6_PRODUTO) )

									DbSelectArea("SF4")
									SF4->( DbSetOrder(1) )
									If SF4->( DbSeek(xFilial("SF4") + SC6->C6_TES) )

										DbSelectArea("SC9")
										SC9->( DbSetOrder(1) )
										If SC9->( DbSeek(xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM) )
											Do While !SC9->(EoF()) .And. SC9->C9_FILIAL == xFilial("SC9") .And.;
												SC9->C9_PEDIDO == SC6->C6_NUM .And. SC9->C9_ITEM == SC6->C6_ITEM

												If !Empty(SC9->C9_NFISCAL)
													SC9->(DbSkip())
													Loop
												EndIf

												/* Montagem do array para geração da NF de saí­da */
												Aadd(aPvlNfs,{  SC6->C6_NUM 	,;
																SC6->C6_ITEM 	,;
																SC6->C6_LOCAL 	,;
																SC9->C9_QTDLIB 	,;
																SC6->C6_VALOR 	,;
																SC6->C6_PRODUTO	,;
																.F. 			,;
																SC9->(Recno()) 	,;
																SC5->(Recno()) 	,;
																SC6->(Recno()) 	,;
																SE4->(Recno()) 	,;
																SB1->(Recno()) 	,;
																SB2->(Recno()) 	,;
																SF4->(Recno()) 	,;
																SB2->B2_LOCAL  	,;
																0              	,;
																SC9->C9_QTDLIB2	})

												SC9->(DbSkip())
											EndDo
										EndIf
									EndIf
								EndIf
							EndIf

							SC6->(DbSkip())
						EndDo
					EndIf
				EndIf
			EndIf

			/* Gera a nota fiscal */
			If !Empty(aPvlNfs)
				cSerie := SuperGetMV("PLG_SERIE",.F.,"1")
				cSerie := PadR(cSerie,TamSX3("F2_SERIE")[1])

				fSetParams("MT460A",@lMostraCtb,@lAglutCtb,@lCtbOnLine,@lCtbCusto,@lReajuste,@nCalAcrs,@nArrPrcLis,@lAtuSA7,@lECF)

				fAjustaSX5(cSerie)

				cNota := MaPvlNfs(aPvlNfs,@cSerie,lMostraCtb,lAglutCtb,lCtbOnLine,lCtbCusto,lReajuste,nCalAcrs,nArrPrcLis,lAtuSA7,lECF,cEmbExp,bAtuFin)

				aAreaSE1 := SE1->(GetArea())

				DbSelectArea("SE1")
				SE1->(DbSetOrder(1))  //E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
				//O prefixo ERR é gravado no ponto de entrada M460FIM
				//Se o usuario usou o padrão para inserir um titulo a receber com a mesma chave de um titulo gerado por integração CTE/CRT
				If SE1->(DbSeek(xFilial("SE1") + "ERR" + cNota ))

					lTitDupli := .T.

				EndIf

				RestArea(aAreaSE1)
				//cSerie := SF1->F1_SERIE

				If Empty(cNota)
					lOk := .F.
				Else
					If AllTrim(cNota) == AllTrim(SE1->E1_NUM)
						SE1->(Reclock("SE1",.F.))

							If AllTrim(cTpCon) == "ZCRT" // CRT
								// ------------------------------------------
								// Atualiza a origem da SE1 como FINA040
								// ------------------------------------------
								SE1->E1_ORIGEM := "FINA040"
							EndIf

							If Empty(SE1->E1_CCUSTO) .And. !Empty(cCCusto)
								// ------------------------------------------
								// Ajuste realizado em 16/04/2020 por Juliano
								// Motivo: Erro ao utilizar o título da tabela
								// UQD na tela de faturas (PRT0518).
								// Atualiza o Centro de Custo na tabela SE1
								// ------------------------------------------
								SE1->E1_CCUSTO := cCCusto
							EndIf

						SE1->(MsUnlock())
					EndIf
				EndIf

				fGrvImpost(SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_CLIENTE, SF2->F2_LOJA, SF2->F2_FORMUL, SF2->F2_TIPO, cNumPedido)
			Else
				lOk := .F.
			EndIf
		EndIf

		fRestAreas(aAreas)
	EndIf

	aAdd(aRet, lOk)
	aAdd(aRet, lTitDupli)

Return aRet

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

/*/{Protheus.doc} fAtuUQD
Executa a atualização de registros na tabela UQD.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param aRegsUQD, array, Array com os registros a serem atualizados
@param cStatus, characters, Conteúdo para a atualização do Status
@param cPedido, characters, Conteúdo para a atualização do numero do pedido de venda
@param cNF, characters, Conteúdo para a atualização do numero da nota fiscal
@param cSerie, characters, Conteúdo para a atualização da série da nota fiscal
@param lExcPVeNF, logico, Indica se deve excluir o numero do pedido e Nota Fiscal
@type function
/*/
Static Function fAtuUQD(aRegsUQD, cStatus, cPedido, cNF, cSerie, lExcPVeNF)
	Local aAreas 	:= {}
	Local cParcela	:= ""
	Local cPrefixo	:= ""
	Local cTipoTit	:= ""
	Local cTitulo	:= ""
	Local cSeekSE1	:= ""
	Local nI		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQD->(GetArea()))
	Aadd(aAreas, SE1->(GetArea()))

	DbSelectArea("UQD")

	For nI := 1 To Len(aRegsUQD)
		UQD->(DbGoTo(aRegsUQD[nI]))

		//-- Não atualiza registros processados e cancelados
		If UQD->(Recno()) == aRegsUQD[nI]
			// Define o prefixo do título de acordo com o tipo de contrato do arquivo
			cPrefixo := IIf(AllTrim(UQD->UQD_TPCON) == "ZCRT", "CRT", "CTE")
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

						If SE1->E1_CLIENTE == UQD->UQD_CLIENT .And. SE1->E1_LOJA == UQD->UQD_LOJACL
							cTitulo  := SE1->E1_NUM
							cParcela := SE1->E1_PARCELA
							cTipoTit := SE1->E1_TIPO

							Exit
						EndIf

						SE1->(DbSkip())
					EndDo
				EndIf
			EndIf

			UQD->(Reclock("UQD", .F.))
				UQD->UQD_STATUS 	:= cStatus
				UQD->UQD_PEDIDO 	:= IIf(!Empty(cPedido) .Or. lExcPVeNF, cPedido, UQD->UQD_PEDIDO)

				// Atualiza as informações sobre a nota e o título somente se não for Argentina
				If lFaturaPed
					UQD->UQD_NF		:= IIf(!Empty(cNF) .Or. lExcPVeNF, cNF, UQD->UQD_NF)
					//If cStatus != "P" // Para o caso de Status P o ponto de entrada M460NUM irá gravar a série
						UQD->UQD_SERIE	:= cSerie //IIf(!Empty(cSerie) .Or. lExcPVeNF, cSerie, UQD->UQD_SERIE)
					//EndIf
					UQD->UQD_PREFIX	:= IIf(!Empty(cTitulo), cPrefixo, "")
					UQD->UQD_TITULO	:= IIf(!Empty(cTitulo), cTitulo, "")
					UQD->UQD_PARCEL	:= IIf(!Empty(cParcela), cParcela, "")
					UQD->UQD_TIPOTI	:= IIf(!Empty(cTipoTit), cTipoTit, "")
				EndIf
			UQD->(MsUnlock())
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

	nAt := oGetDadUQD:nAt

	For nI := 1 To Len(aRegAtu)
		For nJ := 1 To Len(aRegAtu[nI,1])
			If (nPos := AScan(oGetDadUQD:aCols, {|x| x[nPsUQDRecno] == aRegAtu[nI,1,nJ]})) > 0
				oGetDadUQD:GoTo(nPos)

				//-- Atualização da legenda
				If aRegAtu[nI,2] == "I" // Arquivo importado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDLeg1] := oBlue
				ElseIf aRegAtu[nI,2] == "P" // Arquivo integrado no Protheus
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDLeg1] := oGreen

					//-- Desmarca o registro processado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDCheck] := oNo
				ElseIf aRegAtu[nI,2] == "E" // Arquivo com erros na integração
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDLeg1] := oRed
				ElseIf aRegAtu[nI,2] == "C" // Arquivo cancelado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDLeg1] := oBlack

					//-- Desmarca o registro cancelado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDCheck] := oNo
				ElseIf aRegAtu[nI,2] == "R" // Arquivo reprocessado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDLeg1] := oVioleta

					//-- Desmarca o registro reprocessado
					oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDCheck] := oNo
				EndIf

				//-- Atualização do pedido de venda
				oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDPedido] := aRegAtu[nI,3]

				//-- Atualização da Nota Fiscal
				oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDNF] := aRegAtu[nI,4]

				//-- Atualização da série da Nota Fiscal
				oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDSerie] := aRegAtu[nI,5]
			EndIf
		Next nJ
	Next nI

	oGetDadUQD:GoTo(nAt)
	oGetDadUQD:Refresh()
Return(Nil)

/*/{Protheus.doc} fGetInfUQD
Retorna a informação do campo passado por parâmetro do recno da tabela UQD também passado por parâmetro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@return uInfo, Informação do campo solicitado
@param nRecno, numeric, Recno para posicionar na tabela UQD
@param cCampo, characters, Campo a ser retornado o conteúdo
@type function
/*/
Static Function fGetInfUQD(nRecno, cCampo)
	Local aAreas	:= {}
	Local uInfo 	:= Nil

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQD->(GetArea()))

	UQD->(DbGoTo(nRecno))
	If UQD->(Recno()) == nRecno
		uInfo := &("UQD->" + cCampo)
	EndIf

	fRestAreas(aAreas)
Return(uInfo)

/*/{Protheus.doc} fExcluir
Realiza a integração dos dados das tabelas UQD e UQE gerando Pedido de Venda, Liberação e Nota Fiscal.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param lAgrupa, logical, descricao
@type function
/*/
Static Function fExcluir()

	Local aArea			:= GetArea()
	Local aAreaUQD		:= UQD->(GetArea())
	Local aAreaUQE		:= UQE->(GetArea())

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
		If MsgYesNo(CAT544048, cCadastro) //"Deseja realmente excluir os arquivos selecionados?"
			For nJ := 1 To Len(aFiliais)
				aSels := fGetSels(aFiliais[nJ,2])

				If !Empty(aSels)
					//-- Altera para a filial do registro selecionado
					StaticCall(PRT0528, fAltFilial, aFiliais[nJ,1])

					// Abre a tabela de cabeçalho dos arquivos
					DbSelectArea("UQD")
					UQD->(DbSetOrder(1))	// UQD_FILIAL + UQD_IDIMP
					UQD->(DbGoTop())

					For nI := 1 To Len(aSels)
						// Posiciona no arquivo selecionado
						If UQD->(DbSeek(xFilial("UQD") + aSels[nI][nPsUQDIDImp]))
							cFilArq   := UQD->UQD_FIL
							cRegistro := UQD->UQD_NUMERO
							cCliente  := UQD->UQD_CLIENT
							cIDImp    := UQD->UQD_IDIMP
							nValor    := UQD->UQD_VALOR

							// Verifica se o mesmo não está processado, reprocessado ou cancelado.
							If !(UQD->UQD_STATUS $ "PRC")

								// Exclui o itens do arquivo
								DbSelectArea("UQE")
								UQE->(DbSetOrder(1))	// UQE_FILIAL + UQE_IDIMP + UQE_ITEM

								// Verifica se possui itens
								If UQE->(DbSeek(xFilial("UQE") + UQD->UQD_IDIMP))
									// Enquanto houver itens
									While !UQE->(Eof()) .And. UQE->UQE_IDIMP == UQD->UQD_IDIMP
										// Deleta o item
										UQE->(Reclock("UQE", .F.))
											UQE->(DbDelete())
										UQE->(MsUnlock())

										UQE->(DbSkip())
									EndDo
								EndIf

								// Deleta o arquivo de cabeçalho
								UQD->(Reclock("UQD", .F.))
									UQD->(DbDelete())
								UQD->(MsUnlock())

								cMensagem := CAT544112 + AllTrim(UQD->UQD_NUMERO) + CAT544113 //"Arquivo " #" excluído com sucesso."

								// Grava o log de exclusão
								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf
						EndIf

						// Retorna ao topo da tabela
						UQD->(DbGotop())
					Next nI
				EndIf
			Next nJ

			fGrvLog()

			MsgInfo(CAT544049, cCadastro) //"Registros excluí­dos com sucesso."

			// Atualiza GetDados
			fFillDados()
		EndIf
	Else
		MsgInfo(CAT544050, cCadastro) //"Nenhum registro selecionado para exclusão."
	EndIf

	RestArea(aArea)
	RestArea(aAreaUQD)
	RestArea(aAreaUQE)

Return

/*/{Protheus.doc} fEstornar
Realiza o estorno do arquivo integrado ao Protheus
@author Kevin Willians
@since 15/02/2019
@version v1.02
@param nAt, integer, linha poscionada na GetDados da UQD
@type function
/*/
Static Function fEstornar(nAt)
	Local aCancNF		:= {}
	Local aCancPV		:= {}
	Local aC			:= oGetDadUQD:aCols[oGetDadUQD:nAt]
	Local aRegsUQD		:= {}//{aC[GDFieldPos("UQD_REC_WT"	, oGetDadUQD:aHeader)]}
	Local cCliente		:= aC[GDFieldPos("UQD_CLIENT"	, oGetDadUQD:aHeader)]
	Local cLoja			:= aC[GDFieldPos("UQD_LOJACL"	, oGetDadUQD:aHeader)]
	Local cNF			:= aC[GDFieldPos("UQD_NF"		, oGetDadUQD:aHeader)]
	Local cSerie		:= aC[GDFieldPos("UQD_SERIE"		, oGetDadUQD:aHeader)]
	Local cRegistro		:= aC[GDFieldPos("UQD_NUMERO"	, oGetDadUQD:aHeader)]
	Local cPedido		:= aC[GDFieldPos("UQD_PEDIDO"	, oGetDadUQD:aHeader)]
	Local cRecNo		:= aC[GDFieldPos("UQD_REC_WT"	, oGetDadUQD:aHeader)]
	Local cStatus		:= "I"
	Local cIDImp		:= aC[GDFieldPos("UQD_IDIMP"		, oGetDadUQD:aHeader)]
	Local cCancelLog	:= ""
	Local cBlqEmail		:= "N"
	Local nValor		:= aC[GDFieldPos("UQD_VALOR"		, oGetDadUQD:aHeader)]

	// Posiciona no registro a ser estornado.
	UQD->(DbGoTo(cRecNo))

	If UQD->UQD_STATUS <> "P"
		MsgAlert(CAT544051, cCadastro) //"Só é permitido o estorno de arquivos integrados ao Protheus."
	Else
		If MsgYesNo(CAT544052, cCadastro) //"Deseja realmente realizar o estorno da integração do registro posicionado?"
			//	Verifica se o usuário tem acesso a rotina de estorno
			If RetCodUsr() $ SuperGetMV("PLG_USREST",,.F.)
				// Verifica se o registro esta integrado(Verde)
				If UQD->UQD_STATUS == "P"
					//--Varre a GD em busca de outros registros do mesmo lote
					aAdd(aRegsUQD, cRecNo )//aRegsUQD := fGDLote( @aRegsUQD, AllTrim(cNF), AllTrim(cSerie))
					//-- Estorna a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cCliente, cLoja, cPedido)

					//-- Estorna o Pedido
					If aCancNF[1]
						aCancPV := fCanPedVen(cPedido)

						If aCancPV[1]
							//-- Atualiza a UQD fAtuUQD(aRegsUQD, cStatus, cPedido, cNF, cSerie, lExcPVeNF)
							fAtuUQD(aRegsUQD, cStatus, "", "", "", .T.)
							//oGetDadUQD:Refresh()
							fFillDados()//atualiza as legendas recarregando a busca

							cCancelLog := Space(TamSX3("UQF_CANCEL")[1])

							MsgInfo(CAT544053, cCadastro) //"Registro estornado com sucesso!"
										//{cRegistro, nValor, cMensagem, cMsgDet, nLinha, cStatus})
							aAdd( aLogs, {cFilArq, cRegistro, cCliente, nValor, CAT544053, /*cMsgDet*/, 0, cStatus, cIDImp, cCancelLog, cBlqEmail}) //"Registro estornado com sucesso!"
						EndIf
					EndIf
				Else
					MsgInfo(CAT544054, cCadastro) //"Registro deve estar integrado para operação de estorno."
				EndIf
			Else
				MsgInfo(CAT544055, cCadastro) //"Usuário sem permissão necessária para estornar registros."
			EndIf

			fGrvLog()
		EndIf
	EndIf

Return

/*/{Protheus.doc} fGDLote
Varre a GD(UQD) buscando os registros integrados no mesmo lote e acrescentando um array com os recnos dos mesmos
@author Kevin Willians
@since 18/02/2019
@version undefined
@param aRegs, array, array a ser preenchido com os RecNos
@param cNota, characters, Nota fiscal a ser comparada
@param cSerie, characters, Serie da Nota fiscal a ser comparada
@type function
/*/
Static Function fGDLote( aRegs, cNota, cSerie )
	Local nI 		:= oGetDadUQD:nAt
	Local nNFPos	:= GDFieldPos("UQD_NF" 		, oGetDadUQD:aHeader)
	Local nSeriePos	:= GDFieldPos("UQD_SERIE" 	, oGetDadUQD:aHeader)
	Local nRecPos	:= GDFieldPos("UQD_REC_WT"	, oGetDadUQD:aHeader)

//	Varre para trás
	While AllTrim( oGetDadUQD:aCols[nI][nNFPos] ) == cNota .And. AllTrim( oGetDadUQD:aCols[nI][nSeriePos] ) == cSerie	//Nota fiscal igual a selecionada
		aAdd( aRegs, oGetDadUQD:aCols[nI][nRecPos])			//RecNo do registro
		nI--
		If nI == 0
			Exit	//N buscar na posição 0 do array
		EndIf
	EndDo
	nI := oGetDadUQD:nAt + 1
//	Varre para frente
	If nI <= Len(oGetDadUQD:aCols)
		While AllTrim( oGetDadUQD:aCols[nI][nNFPos] ) == cNota .And. AllTrim( oGetDadUQD:aCols[nI][nSeriePos] ) == cSerie	//Nota fiscal igual a selecionada
			aAdd( aRegs, oGetDadUQD:aCols[nI][nRecPos])			//RecNo do registro
			nI++
			If nI > Len(oGetDadUQD:aCols)
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
	Local aAux		:= aClone(oGetDadUQD:aCols)
	Local aSels		:= {}

	Default cFilSel	:= ""

	// Separa os itens selecionados pelo usuário.
	If Empty(cFilSel)
		aEval( aAux, {|x| If( x[nPsUQDCheck]:cName == "LBOK", Aadd(aSels, x), Nil ) } )
	Else
		aEval( aAux, {|x| If( x[nPsUQDCheck]:cName == "LBOK" .And. x[nPsUQDFilial] == cFilSel, Aadd(aSels, x), Nil ) } )
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
	Local cCadOld	:= cCadastro

	Private aRotina	:= StaticCall(MATA410, MenuDef)

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC5->(GetArea()))
	Aadd(aAreas, SC6->(GetArea()))

	ProcRegua(0)

	cCadastro := CAT544056 //"Pedidos de Venda - VISUALIZAR"

	cFilPed := oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDFilial]

	cPedido := oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDPedido]

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
			MsgAlert(CAT544059 + AllTrim(cPedido) + CAT544060, cCadastro) //"O Pedido de Venda " + AllTrim(cPedido) + " não foi localizado."
		EndIf
	Else
		MsgAlert(CAT544061, cCadastro)	//"Não foi gerado Pedido de Venda para o item selecionado."
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
	Local cCadOld	:= cCadastro
	Local lNF		:= .F.

	Private aRotina	:= StaticCall(MATA460A, MenuDef)

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SC9->(GetArea()))
	Aadd(aAreas, SF2->(GetArea()))
	Aadd(aAreas, SD2->(GetArea()))

	ProcRegua(0)

	cFilNF	:= PadR(oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDFilial], TamSX3("C9_FILIAL" )[1])
	cPedido	:= PadR(oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDPedido], TamSX3("C9_PEDIDO" )[1])
	cNF		:= PadR(oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDNF]	, TamSX3("C9_NFISCAL")[1])
	cSerie 	:= PadR(oGetDadUQD:aCols[oGetDadUQD:nAt,nPsUQDSerie]	, TamSX3("C9_SERIENF")[1])

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
				MsgAlert(CAT544064, cCadastro)	//"Nota Fiscal não localizada."
			EndIf
		Else
			MsgAlert(CAT544065 + AllTrim(cPedido) + CAT544066, cCadastro) //"Os dados da liberação do Pedido de Venda " + AllTrim(cPedido) + " não foram localizados para a visualização da Nota Fiscal."
		EndIf
	Else
		MsgAlert(CAT544067, cCadastro) // "Não foi gerada Nota Fiscal para o item selecionado."
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
	Local cCliente		:= ""
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
	Aadd(aAreas, UQD->(GetArea()))

	cCancel := Space(TamSX3("UQD_CANCEL")[1])

	For nI := 1 To Len(aRegsCanc)
		aCancNF := {.F.,""}
		aCancPV := {.F.,""}
		lOk := .T.

		UQD->(DbGoTo(aRegsCanc[nI]))

		If UQD->(Recno()) == aRegsCanc[nI]
			cDocumento 	:= UQD->UQD_NUMERO
			cPedido		:= UQD->UQD_PEDIDO
			cIDImp		:= UQD->UQD_IDIMP

			//-- Busca registro de inclusão (integração) na UQD
			//UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
			If fPosRegAtivo(cDocumento) //UQD->(DbSeek(xFilial("UQD") + cDocumento + cCancel))
				cNF 		:= UQD->UQD_NF
				cSerie 		:= UQD->UQD_SERIE
				cCliente 	:= UQD->UQD_CLIENT
				cLoja 		:= UQD->UQD_LOJACL
				nValor		:= UQD->UQD_VALOR

				If Empty(cPedido)
					cPedido := UQD->UQD_PEDIDO
				EndIf

				If (!Empty(cNF) .And. !Empty(cSerie)) .Or. !lFaturaPed .And. !Empty(cCliente) .And. !Empty(cLoja) .And. !Empty(cPedido)
					IncProc(CAT544068 + AllTrim(cNF) + CAT544069 + AllTrim(cSerie) + "...")	//"Cancelando Nota Fiscal ", " Série "

					//-- Cancela a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cCliente, cLoja, cPedido)

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

							aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf
					Else
						nErro++
						lOk 		:= .F.
						cStatus		:= "E"
						cMensagem	:= aCancNF[2]
						cCancelLog	:= "C"

						aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf

				EndIf

				IncProc(CAT544071)	//"Cancelando registro de inclusão..."

				//-- Atualiza o registro de inclusão como cancelado
				fAtuUQD({UQD->(Recno())}, "C", UQD->UQD_PEDIDO, UQD->UQD_NF, UQD->UQD_SERIE, .F.)

				//-- Remove o registro cancelado do array aRegAgru caso tenha sido realizado agrupamento
				If (nPos := AScan(aRegAgru, UQD->(Recno()))) > 0
					ADel(aRegAgru, nPos)
					ASize(aRegAgru, Len(aRegAgru) - 1)
				EndIf

				Aadd(aAtuGetDad, {{UQD->(Recno())}, "C", UQD->UQD_PEDIDO, UQD->UQD_NF, UQD->UQD_SERIE})
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
@param cCliente, characters, Código do cliente
@param cLoja, characters, Loja do cliente
@type function
/*/
Static Function fCancNFS(cNota, cSerie, cCliente, cLoja, cNumPed)

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
		If SF2->(DbSeek(xFilial("SF2") + cNota + cSerie + cCliente + cLoja))
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
		If SF2->(DbSeek(xFilial("SF2") + cNota + cSerie + cCliente + cLoja))
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
	cQuery := "SELECT UQD.UQD_NUMERO, UQD.R_E_C_N_O_ RECNOUQD"					+ CRLF
	cQuery += "FROM " + RetSqlName("UQD") + " UQD" 								+ CRLF
	cQuery += "WHERE UQD.UQD_FILIAL = '" + xFilial("UQD") + "'" 					+ CRLF
	cQuery += "	AND UQD.UQD_CANCEL  = '" + Space(TamSX3("UQD_CANCEL")[1]) + "'" 	+ CRLF
	cQuery += "	AND UQD.UQD_PEDIDO  = '" + cPedido + "'" 						+ CRLF
	cQuery += "	AND UQD.UQD_NF      = '" + cNF + "'" 							+ CRLF
	cQuery += "	AND UQD.UQD_SERIE   = '" + cSerie + "'" 							+ CRLF
	cQuery += "	AND UQD.D_E_L_E_T_ <> '*'" 										+ CRLF
	cQuery += "GROUP BY UQD.UQD_NUMERO, UQD.R_E_C_N_O_" 							+ CRLF
	cQuery += "ORDER BY UQD.UQD_NUMERO" 											+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If Contar(cAliasQry, "!Eof()") > 1
		(cAliasQry)->(DbGoTop())

		cMsg := CAT544079 + cPedido	+ CRLF	//"Pedido: "
		cMsg += CAT544080 + cNF 	+ CRLF	//"Nota Fiscal: "
		cMsg += CAT544081 + cSerie	+ CRLF + CRLF //"Série: "

		cMsg += CAT544082 + CRLF //"CTE/CRT:"

		While !(cAliasQry)->(Eof())
			cMsg += (cAliasQry)->UQD_NUMERO + CRLF

			Aadd(aRegAgru, (cAliasQry)->RECNOUQD)

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
	Local cCliente		:= ""
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
	Aadd(aAreas, UQD->(GetArea()))

	cCancel := Space(TamSX3("UQD_CANCEL")[1])

	If !lFaturaPed
		bCond := {|| !Empty(cCliente) .And. !Empty(cLoja) .And. !Empty(cPedido) }
	Else
		bCond := {|| !Empty(cNF) .And. !Empty(cSerie) .And. !Empty(cCliente) .And. !Empty(cLoja) .And. !Empty(cPedido) }
	EndIf

	For nI := 1 To Len(aRegsRepro)
		aCancNF := {.F.,""}

		lOk := .T.

		UQD->(DbGoTo(aRegsRepro[nI]))

		If UQD->(Recno()) == aRegsRepro[nI]
			cDocumento 	:= UQD->UQD_NUMERO//PadR(UQD->UQD_CHVCTE, TamSX3("UQD_NUMERO")[1])
			cPedido		:= UQD->UQD_PEDIDO
			cNumCarta	:= PadR(UQD->UQD_CHVCTE, TamSX3("UQD_NUMERO")[1])//UQD->UQD_NUMERO
			cIDImp		:= UQD->UQD_IDIMP
			cTpCon		:= UQD->UQD_TPCON

			nAnoCarta	:= Year(UQD->UQD_EMISSA)
			nMesCarta	:= Month(UQD->UQD_EMISSA)
			nDiaCarta	:= Day(UQD->UQD_EMISSA)

			nRecProc	:= aRegsRepro[nI]

			//-- Busca registro de inclusão (integração) na UQD
			//UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
			//Posiciona no original
			If fPosRegAtivo(cDocumento) //UQD->(DbSeek(xFilial("UQD") + cDocumento + cCancel))
				If lFaturaPed
					cNF 	:= UQD->UQD_NF
					cSerie 	:= UQD->UQD_SERIE
				EndIf

				cCliente 	:= UQD->UQD_CLIENT
				cLoja 		:= UQD->UQD_LOJACL
				nValor		:= UQD->UQD_VALOR

				nAnoOrig	:= Year(UQD->UQD_EMISSA)
				nMesOrig	:= Month(UQD->UQD_EMISSA)
				nDiaOrig	:= Day(UQD->UQD_EMISSA)

				nValRep := fValGetUQD(cDocumento)//SE1->E1_VALOR

				If Empty(cPedido)
					cPedido := UQD->UQD_PEDIDO
				EndIf

				If lFaturaPed
					aAreaSE1 := SE1->(GetArea())

					cPrefixTit := Padr(UQD->UQD_PREFIX, TamSX3("E1_PREFIXO")[1] )
					cNumTit := Padr(UQD->UQD_TITULO, TamSX3("E1_NUM")[1] )
					cParcTit := Padr(UQD->UQD_PARCEL, TamSX3("E1_PARCELA")[1])
					cTipoTit := Padr(UQD->UQD_TIPOTI, TamSX3("E1_TIPO")[1])

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

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							EndIf

							If !Empty(SE1->E1_XIDFAT)
								//nErro++
								lOk 		:= .F.
								cStatus		:= "E"
								cMensagem	:=  CAT544098//"O título gerado anteriormente pelo pedido de venda está sendo utilizado em uma fatura."
								cCancelLog	:= "R"

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
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

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
				EndIf

				If nMesOrig != nMesCarta

					//nErro++
					lOk 		:= .F.
					cStatus		:= "E"
					cMensagem	:= CAT544100 //"O mês de emissão da carta de correção é diferente do mês original."
					cCancelLog	:= "R"

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf

				If nAnoOrig == nAnoCarta .And. nMesOrig == nMesCarta .And. nDiaOrig > nDiaCarta

					//nErro++
					lOk 		:= .F.
					cStatus		:= "E"
					cMensagem	:= CAT544101 //"A data de emissão da carta de correção é anterior a data original."
					cCancelLog	:= "R"

					aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})

				EndIf*/

				If EVal(bCond) .And. lOk

					If lFaturaPed
						IncProc(CAT544068 + AllTrim(cNF) + CAT544069 + AllTrim(cSerie) + "...")	//"Cancelando Nota Fiscal ", " Série "

						// -------------------------------------------------------------------------------------------------
						// Ajusta os títulos com parcela diferente e que pertencem a outro CTE/CRT para que não sejam
						// excluídos no cancelamento da NF
						// -------------------------------------------------------------------------------------------------
						aTitulosAj := fAjustTit(cPrefixTit, cNumTit, cParcTit, cTipoTit, cCliente, cLoja, UQD->UQD_NUMERO, "1")
					EndIf

					//-- Cancela a Nota Fiscal
					aCancNF := fCancNFS(cNF, cSerie, cCliente, cLoja, cPedido)

					If lFaturaPed
						// -------------------------------------------------------------------------------------------------
						// Retorna para a filial correta os registros ajustados antes do cancelamento da NF
						// -------------------------------------------------------------------------------------------------
						If !Empty(aTitulosAj)
							fAjustTit(cPrefixTit, cNumTit, cParcTit, cTipoTit, cCliente, cLoja, UQD->UQD_NUMERO, "2", aTitulosAj)
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

										aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
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
											If SE1->E1_CLIENTE == UQD->UQD_CLIENT .And. SE1->E1_LOJA == UQD->UQD_LOJACL
												SE1->(Reclock("SE1", .F.))

													SE1->E1_HIST := CAT544102 + AllTrim(cNumCarta) + " " + CAT544110 +  cValToChar(nValRep) ////"C.C: " # "Valor: "
													/*If "ZCRT" $ UQD->UQD_TPCON
														SE1->E1_HIST := CAT544102 + AllTrim(cNumCarta) //+ "  " + CAT544103 + AllTrim(cNumTit) //"C.C: " # "CRT: "
													ElseIf "ZTRC" $ UQD->UQD_TPCON
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

								aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
								//fGrvLog(nLinha, cMensagem, cStatus)
							EndIf
						Else
						//	nErro++
							lOk 		:= .F.
							cStatus		:= "E"
							cMensagem	:= aAltPV[2]
							cCancelLog	:= "R"

							aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
							//fGrvLog(nLinha, cMensagem, cStatus)
						EndIf
					Else
						//nErro++
						lOk 		:= .F.
						cStatus		:= "E"
						cMensagem	:= aCancNF[2]
						cCancelLog	:= "R"

						aAdd(aLogs, {cFilArq, cRegistro, cCliente, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
						//fGrvLog(nLinha, cMensagem, cStatus)
					EndIf
				EndIf

				If lOk
					IncProc(CAT544086)	//"Ajustando registro de inclusão..."

					//-- Atualiza o registro de inclusão como reprocessado
					fAtuUQD({UQD->(Recno())}, "R", UQD->UQD_PEDIDO, UQD->UQD_NF, UQD->UQD_SERIE, .T.)

					//-- Remove o registro cancelado do array aRegAgru caso tenha sido realizado agrupamento
					If (nPos := AScan(aRegAgru, UQD->(Recno()))) > 0
						ADel(aRegAgru, nPos)
						ASize(aRegAgru, Len(aRegAgru) - 1)
					EndIf

					Aadd(aAtuGetDad, {{UQD->(Recno())}, "R", UQD->UQD_PEDIDO, UQD->UQD_NF, UQD->UQD_SERIE})
				EndIf
			EndIf
		EndIf
	Next nI

	fRestAreas(aAreas)
Return(lOk)

/*/{Protheus.doc} fPosRegAtivo
Posiciona no ultimo registro ativo e processado da tabela UQD.
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

	Local cCancel 		:= Space(TamSX3("UQD_CANCEL")[1])
	Local cQuery		:= ""
	Local cAliasQry		:= ""

	Local lOk			:= .F.
	Local lReproc		:= UQD->UQD_CANCEL == "R"

	Default lExiste		:= .F.

	DbSelectArea("UQD")
	UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
	If UQD->(DbSeek(xFilial("UQD") + cDoc + cCancel))
		lExiste := .T.

		While !UQD->(EoF()) .And. UQD->UQD_FILIAL == xFilial("UQD") .And. UQD->UQD_NUMERO == cDoc
			If UQD->UQD_STATUS == "P" // Integrado
				lOk := .T.
				Exit
			EndIf

			UQD->(DbSkip())
		EndDo
	EndIf

	If !lOk .And. lReproc
		// --------------------------------------------------------------------------------------
		// Busca as cartas de correção processadas para posicionar na última e que está ativa
		// --------------------------------------------------------------------------------------
		cAliasQry := GetNextAlias()

		cQuery := " SELECT R_E_C_N_O_ RECNOUQD "					+ CRLF
		cQuery += " FROM " + RetSQLName("UQD") 						+ CRLF
		cQuery += " WHERE UQD_FILIAL = '" + xFilial("UQD") + "' " 	+ CRLF
		cQuery += " 	AND UQD_CHVCTE = '" + cDoc + "' " 			+ CRLF
		cQuery += " 	AND UQD_STATUS = 'P' " 						+ CRLF
		cQuery += " 	AND D_E_L_E_T_ <> '*' " 					+ CRLF
		cQuery += " ORDER BY R_E_C_N_O_ DESC " 						+ CRLF

		Aadd( aTCSetField, { "RECNOUQD", "N", 17, 0	} )

		MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

		If !(cAliasQry)->(EoF())
			lOk := .T.
			UQD->(DbGoTo( (cAliasQry)->(RECNOUQD) ))
		EndIf

		(cAliasQry)->(DbCloseArea())

		DbSelectArea("UQD")
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
	
	//Local cPerg			:= "PRT0544"
	Local lBold			:= .T.
	Local lItalic		:= .T.
	Local lUnderline	:= .T.

	Private oF12		:= TFont():New("Arial",,12,,!lBold,,,,,!lUnderline,!lItalic)
	Private oF12UB		:= TFont():New("Arial",,12,, lBold,,,,, lUnderline,!lItalic)
	Private oF12B		:= TFont():New("Arial",,12,, lBold,,,,,!lUnderline,!lItalic)
	Private oF18B		:= TFont():New("Arial",,18,, lBold,,,,,!lUnderline,!lItalic)

	Private cTitulo		:= CAT544087 // " - Relatório de Arq. Importados - "
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

	//Local aCab 			:= oGetDadUQD:aCols
	Local bAction		:= {||}
	Local cAliasIt		:= GetNextAlias()
	Local cArquivo		:= "PRT0544_" + DtoS( Date() ) + StrTran( Time(), ":", "" )
	Local cTitulo		:= CAT544088 //" - Arquivos CTE/CRT - "
	Local cBmpLogo		:= "\logotipos\logo_empresa.jpg" //Deve ser jpg na pasta system
												 //A função FisxLogo("1") busca o logo(BMP) a ser impresso, mas
												 //esse logo não é impresso caso a opção selecionada seja arquivo
	Local nI			:= 1
	Local oRelatorio	:= Nil

	// Atualiza a GetDados
	oGetDadUQE:Refresh()
	// Atualiza a GetDados
	oGetDadUQD:Refresh()

	bAction := { |oRelatorio| PrintReport( oRelatorio, oGetDadUQD:aCols, cAliasIt) }

	// Instanciando o objeto TReport
	oRelatorio := TReport():New("PRT0544")
	oRelatorio:nFontBody:=10
	oRelatorio:SetLineHeight(50)
	oRelatorio:SetLogo(cBmpLogo)
	oSecCab := TRSection():New( oRelatorio , "Cabec", /*aCab*/, , , , , , , .T.	 )

	For nI := 4 to Len(aHeaderUQD) - 2
		TRCell():New( oSecCab, aHeaderUQD[nI][2], /*aCab*/, , , , .F.,,,,,,,,,, .T. )
	Next

	oSecIt := TRSection():New( oRelatorio , "Itens", cAliasIt, , , , , , , .T.	 )
	For nI := 1 to Len(aHeaderUQE) - 2
		TRCell():New( oSecIt, aHeaderUQE[nI][2], cAliasIt, ,  , , .F.)
	Next

	oSecCab:SetHeaderSection( .T. )
	TRFunction():New(oSecCab:Cell("UQD_NUMERO"),/*cId*/,"COUNT", /*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/, .F., .T., .F., oSecCab)

	// Define o título do reltório
	oRelatorio:SetTitle( cTitulo )

	// Define os parâmetros de configuração (perguntas) do relatório
	oRelatorio:SetParam( "PRT0544" )

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
@return cNumUQD, cNumUQD
@param oRelatorio, object, Relatório
@param cAliasIt, characters, alias
@type function
/*/
Static Function fImpIt(oRelatorio, cAliasIt)
	Local cNUMUQD	:= oSecCab:Cell("UQD_IDIMP ")
	Local cQuery 	:= ""

	cNUMUQD := cNUMUQD:GetValue()

	// Define a query para pesquisa dos arquivos.
	cQuery  += "SELECT  UQE.UQE_ITEM, UQE.UQE_PRODUT, SB1.B1_DESC,"            							+ CRLF
	cQuery  += "        UQE.UQE_PRCVEN, UQE.R_E_C_N_O_ RECNOUQE"            							+ CRLF
	cQuery  += "FROM    " + RetSqlName("UQE") + " UQE "                                              + CRLF
	cQuery 	+= "INNER JOIN " + RetSqlName("SB1") + " SB1 "											+ CRLF
	cQuery 	+= "	ON SB1.B1_FILIAL = '" + xFilial("SB1") + "' " 										+ CRLF
	cQuery 	+= "	AND SB1.B1_COD = UQE.UQE_PRODUT" 													+ CRLF
	cQuery 	+= "	AND SB1.D_E_L_E_T_ <> '*'" 															+ CRLF
	cQuery  += "WHERE   UQE.UQE_FILIAL = '" + xFilial("UQE") + "' "                                     + CRLF
	cQuery  += "AND     UQE.UQE_IDIMP = '" + AllTrim(cNumUQD) + "' "                            		+ CRLF
	cQuery  += "AND     UQE.D_E_L_E_T_ <> '*' "                                                     	+ CRLF
	cQuery  += "ORDER BY UQE.UQE_ITEM " 			                                                   	+ CRLF

	MPSysOpenQuery(cQuery, cAliasIt)

Return cNumUQD

/*/{Protheus.doc} PrintReport
Imprime as linhas do Relatório
@author Kevin Willians
@since 18/01/2019
@version 1.0
@return Nil, Nulo
@param oRelatorio, object, Relatorio
@param aUQD, array, array de cabeçalho
@param cAliasIt, characters, alias da query
@type function
/*/
Static Function PrintReport( oRelatorio, aUQD, cAliasIt )
	Local nI 	:= 0
	Local nJ 	:= 0
	Local nPos	:= 0

 	For nI:= 1 to Len(aUQD)
	 	If (nPos := AScan(aFiliais, {|x| x[2] == aUQD[nI,nPsUQDFilial]})) > 0
			StaticCall(PRT0528, fAltFilial, aFiliais[nPos,1])

			// Incrementa a régua de progressão do relatório
			oRelatorio:IncMeter()

			oSecCab:Init(.T.)
			For nJ:= 4 to Len(aUQD[nI]) - 3 //Alias_WT + Recno + Flag de delete
				oSecCab:Cell(aHeaderUQD[nJ][2]):SetValue(aUQD[nI][nJ])
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
		MsgAlert( CAT544090 + CRLF + cErro, cCadastro )	// "Erro ao executar rotina:"
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
		cFilArq := UQD->UQD_FIL
	EndIf

	If cCliente == ""
		cCliente := UQD->UQD_CLIENT
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
			UQF->UQF_CLIENT	:= aLogs[nI][3]
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
	UQA->( dbgotop() )
	//UQA->( dbseek( xFilial("UQA") + UQD->UQD_FILIAL + UQD->UQD_UFFOR ) )

	While UQA->( !eof() )
		
		If Alltrim(UQA->UQA_UFORIG) == Alltrim(UQD->UQD_UFFOR)

			If Alltrim(UQD->UQD_UFDES) $ Alltrim(UQA->UQA_UFDEST) .AND. ;
				Alltrim(UQA->UQA_CFOP)   == Substr(Alltrim(UQD->UQD_CFOP),2,4) .AND. ;
				Alltrim(UQA->UQA_CSTICM) == Alltrim(UQD->UQD_CSTICM) .AND. ;
				Alltrim(UQA->UQA_CSTPIS) == Alltrim(UQD->UQD_CSTPIC) .AND. ;
				Alltrim(UQA->UQA_CSTCOF) == Alltrim(UQD->UQD_CSTPIC)
			
				cTes := UQA->UQA_TES
				exit
			Endif
			
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
@param cCliente, caracter, Código do cliente
@param cLoja, caracter, Loja do cliente
@type function
/*/
Static Function fGetNaturez(cTpCon, cCliente, cLoja)

	Local cNatureza := ""

	If AllTrim(cTpCon) == "ZCRT" // CRT
		cNatureza := SuperGetMV("PLG_NATCRT",.F.,"21001")
	Else // CTE
		cNatureza := SuperGetMV("PLG_NATCTE",.F.,"21002")//Posicione("SA1",1,xFilial("SA1") + cCliente + cLoja,"A1_NATUREZ")
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
@param cMunCol, caracter, Conteúdo do campo UQD_MUNCOL que contém os dados de origem e destino
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
@param cCliente, caracter, Cliente do título
@param cLoja, caracter, Loja do título
@param cNumUQD, caracter, Numero da tabela UQD que está sendo processado
@param cTpAjuste, caracter, Tipo de ajuste: 1 = Ajusta para filial XXXX, 2 = Retorna filial original
@param aTitulos, array, Titulos que foram ajustados (somente para tipo de ajuste = 2)
@type function
/*/
Static Function fAjustTit(cPrefixo, cNum, cParcela, cTipo, cCliente, cLoja, cNumUQD, cTpAjuste, aTitulos)

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
		cQuery += " 	INNER JOIN " + RetSQLName("UQD") + " UQD " 			+ CRLF
		cQuery += " 		ON  UQD.UQD_FILIAL  = '" + xFilial("UQD") + "' " + CRLF
		cQuery += " 		AND UQD.UQD_CLIENT = SE1.E1_CLIENTE " 			+ CRLF
		cQuery += " 		AND UQD.UQD_LOJACL = SE1.E1_LOJA " 				+ CRLF
		cQuery += " 		AND UQD.UQD_PREFIX = SE1.E1_PREFIXO " 			+ CRLF
		cQuery += " 		AND UQD.UQD_TITULO  = SE1.E1_NUM " 				+ CRLF
		cQuery += " 		AND UQD.UQD_PARCEL = SE1.E1_PARCELA " 			+ CRLF
		cQuery += " 		AND UQD.UQD_TIPOTI = E1_TIPO " 					+ CRLF
		cQuery += " 		AND UQD.UQD_NUMERO  <> '" + cNumUQD + "' " 		+ CRLF
		cQuery += " 		AND UQD.D_E_L_E_T_ <> '*' " 					+ CRLF
		cQuery += " WHERE   SE1.E1_FILIAL  = '" + xFilial("SE1") + "' " 	+ CRLF
		cQuery += " 	AND SE1.E1_CLIENTE = '" + cCliente + "' " 			+ CRLF
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

/*/{Protheus.doc} fValGetUQD
Retorna o valor do CTE/CRT original para reprocessamento
@author Icaro Laudade
@since 18/10/2019
@return nValUQDOri, Valor original do CTE/CRT
@param cNumUQD, characters, Número do CTE/CRT
@type function
/*/
Static Function fValGetUQD(cNumUQD)

	Local cTmpAlias 	:=	GetNextAlias()
	Local nValUQDOri	:=	0

	cQuery := " SELECT UQD.UQD_VALOR "											+ CRLF
	cQuery += " FROM " + RetSQLName("UQD") + " UQD "							+ CRLF
	cQuery += " WHERE UQD.UQD_FILIAL = '" + xFilial("UQD") + "' "				+ CRLF
	cQuery += "   AND UQD.UQD_NUMERO = '" + cNumUQD + "'"						+ CRLF
	cQuery += "   AND UQD.UQD_CANCEL = '" + Space(TamSX3("UQD_CANCEL")[1]) + "'"	+ CRLF
	cQuery += "   AND UQD.D_E_L_E_T_ <> '*' " 									+ CRLF

	MpSysOpenQuery( cQuery, cTmpAlias)

	If !(cTmpAlias)->(EOF())
		nValUQDOri := (cTmpAlias)->UQD_VALOR
	EndIf

	(cTmpAlias)->(DbCloseArea())

Return nValUQDOri

/*/{Protheus.doc} fGrvImpost
Grava impostos na Nota Fiscal de Saída.
@author Juliano Fernandes
@since 28/11/2019
@version 1.0
@return Nil, Não há retorno
@param cDoc, caracter, Numero do documento
@param cSerie, caracter, Série do documento
@param cCliente, caracter, Código do Cliente da NF
@param cLoja, caracter, Código da Loja do cliente da NF
@param cFormul, caracter, Código do formulário
@param cTipo, caracter, Tipo da NF
@param cPedido, caracter, Código do pedido de venda
@type function
/*/
Static Function fGrvImpost(cDoc, cSerie, cCliente, cLoja, cFormul, cTipo, cPedido)

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
	Aadd(aAreas, SA1->(GetArea()))
	Aadd(aAreas, SF2->(GetArea()))
	Aadd(aAreas, SD2->(GetArea()))
	Aadd(aAreas, SFT->(GetArea()))
	Aadd(aAreas, SF3->(GetArea()))

	// -------------------------------------------------------------------------------
	// Verifica se a NF é do estado do Rio Grande do Sul e a TES utilizada é a 502.
	// -------------------------------------------------------------------------------
	If AllTrim(UQD->UQD_TPCON) != "ZCRT"
		If AllTrim(UQD->UQD_UFCOL) == "RS" .And. AllTrim(UQD->UQD_UFDES) == "RS"
			DbSelectArea("SA1")
			SA1->(DbSetOrder(1)) // A1_FILIAL + A1_CLIENTE + A1_LOJA
			If SA1->(DbSeek(xFilial("SA1") + UQD->UQD_CLIENT + UQD->UQD_LOJACL))
				If AllTrim(SA1->A1_EST) == "RS"
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

	cCFOP		:= Left(UQD->UQD_CFOP,4)
	nICMS		:= UQD->UQD_ICMS
	nPICM		:= UQD->UQD_PICMS
	nBICM		:= UQD->UQD_BSICMS
	lCTE		:= "ZTRC" $ AllTrim(UQD->UQD_TPCON) // CTE
	lIsenICMS	:= lNF_RS .Or. (nICMS == 0 .And. nPICM == 0)

	DbSelectArea("SF2") ; SF2->(DbSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
	DbSelectArea("SD2") ; SD2->(DbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	DbSelectArea("SFT") ; SFT->(DbSetOrder(1)) // FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
	DbSelectArea("SF3") ; SF3->(DbSetOrder(5)) // F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT

	cChvSF2 := xFilial("SF2")
	cChvSF2 += PadR(cDoc	, TamSX3("F2_DOC")[1]    )
	cChvSF2 += PadR(cSerie	, TamSX3("F2_SERIE")[1]	 )
	cChvSF2 += PadR(cCliente, TamSX3("F2_CLIENTE")[1])
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

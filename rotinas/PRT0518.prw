#Include 'Totvs.ch'
#Include 'RPTDef.ch'
#Include "CATTMS.ch"

// Define as informações sobre o programa
Static NomePrt		:= "PRT0518"
Static VersaoJedi	:= "V1.35"

/*/{Protheus.doc} PRT0518
Programa para gerenciamento de Faturas.
@author Paulo Carvalho
@since 25/02/2019
@version 12.1.17
@type function
/*/
User Function PRT0518()

	Local aArea			:= GetArea()

	Private aCores		:= {}
    Private aRotina		:= fMenuDef()
	Private aGetDados	:= {}
	Private aColNaoOrd	:= {}

	Private cAlias		:= "UQO"
	Private cCadastro	:= NomePrt + CAT518001 + VersaoJedi // #" - Faturas - "

	Private c518Cli		:= ""
	Private c518Loja	:= ""

	Private lCrescente	:= .F.

	Private nOrdena		:= 0

	Private oNo			:= LoadBitmap( GetResources(), "LBNO" )
	Private oOk			:= LoadBitmap( GetResources(), "LBOK" )

	// Determina a legenda das faturas
	Aadd(aCores, {"UQO_STATUS == '1'", "BR_AMARELO"	})	// Fatura Em Aberto
	Aadd(aCores, {"UQO_STATUS == '2'", "BR_VERDE"	})	// Fatura Integrada
	Aadd(aCores, {"UQO_STATUS == '3'", "BR_AZUL"	})	// Fatura Baixada parcialmente
	Aadd(aCores, {"UQO_STATUS == '4'", "BR_VERMELHO"})	// Fatura Baixada totalmente

	// Abre a tabela de cabeçalho de faturas
	DbSelectArea("UQO")
	UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_NUMERO
	UQO->(DbGoTop())

	// Inicializa a MBrowse com os dados do cabeçalho do arquivo
	MBrowse(,,,, "UQO",,,,,, aCores)

	RestArea(aArea)

Return

/*/{Protheus.doc} fMenuDef
Define as rotinas que estarão disponíveis no menu do programa.
@author Paulo Carvalho
@since 25/02/2019
@return aRot, array contendo as opções de rotina disponíveis no programa.
@type function
/*/
Static Function fMenuDef()

	Local aRot	:= {}

	Aadd(aRot, { CAT518004	, "AxPesqui"	, 0,  1, 0, .F. }) // "Pesquisar"
	Aadd(aRot, { CAT518005	, "U_fMain518"	, 0,  2, 0, Nil }) // "Visualizar"
	Aadd(aRot, { CAT518006	, "U_fMain518"	, 0,  3, 0, Nil }) // "Incluir"
	Aadd(aRot, { CAT518007	, "U_fMain518"	, 0,  4, 0, Nil }) // "Alterar"
	Aadd(aRot, { CAT518008	, "U_fMain518"	, 0,  5, 0, Nil }) // "Excluir"
	Aadd(aRot, { CAT518019	, "U_fMain518"	, 0,  6, 0, Nil }) // "Integrar Fatura"
	Aadd(aRot, { CAT518009	, "U_fMain518"	, 0,  7, 0, Nil }) // "Imprimir Fatura"
	Aadd(aRot, { CAT518010	, "U_fMain518"	, 0,  8, 0, Nil }) // "Enviar Fatura"
	Aadd(aRot, { CAT518011	, "U_fMain518"	, 0,  9, 0, Nil }) // "Legenda"
	Aadd(aRot, { CAT518081	, "U_fMain518"	, 0, 10, 0, Nil }) // "Liquidação"
	Aadd(aRot, { CAT518085	, "U_fMain518"	, 0, 11, 0, Nil }) // "Exportar Excel"
	Aadd(aRot, { CAT518088	, "U_fMain518"	, 0, 12, 0, Nil }) // "Enviar Múltiplas Faturas"
	Aadd(aRot, { CAT518089	, "U_fMain518"	, 0, 13, 0, Nil }) // "Integrar Múltiplas Faturas"

Return aClone(aRot)

/*/{Protheus.doc} fMain518
Função controladora do programa. Direciona o programa à rotina escolhida pelo usuário.
@author Paulo Carvalho
@since 25/02/2019
@param cAlias, carácter, Alias principal da tela.
@param nRecno, numérico, recno do arquivo selecionado para visualização, alteração ou exclusão.
@param nOpcao, numérico, opção escolhida pelo usuário.
@type function
/*/
User Function fMain518(cAlias, nRecno, nOpcao)

	Local cEmAberto		:= "1"

	Local lVisual		:= .F.
	Local lMultipFat	:= IsInCallStack("fMultipFat")

	Local nInclui		:= 3
	Local nImprime		:= 7
	Local nIntegra		:= 6

	Local uRet			:= Nil

	Private cCliente	:= UQO->UQO_CLIENT
	Private cFatura		:= UQO->UQO_ID
	Private cLoja		:= UQO->UQO_LOJA
	Private cNumero		:= UQO->UQO_NUMERO
	Private cObs		:= UQO->UQO_OBS
	Private cStatus		:= UQO->UQO_STATUS

	Private dEmissao	:= UQO->UQO_EMISSA
	Private dVencto		:= UQO->UQO_VENCTO

	Private nTotal		:= UQO->UQO_TOTAL

	Private aHeader		:= {}
	Private aCols		:= {}
	Private oGetDados	:= Nil
	Private oTGTotal	:= Nil
	Private oTGObs		:= Nil

	// Visualização, Inclusão, Alteração ou Exclusão
	If nOpcao == 12 .Or. nOpcao == 13
		fMultipFat(nOpcao)
	ElseIf nOpcao == 11
		fGeraExcel()
	ElseIf nOpcao == 10
		FINA460()
	ElseIf nOpcao == 9	// Apresenta a tela de legendas
		fLegenda()
	ElseIf nOpcao == 8
		uRet := fEmail()
	ElseIf nOpcao == nImprime
		fImprime()
	ElseIf nOpcao == nIntegra
		If cStatus == cEmAberto
			If lMultipFat .Or. MsgYesNo(CAT518060, cCadastro) // "Confirma a integração da fatura?"
				DbSelectArea("UQO")
				UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID
				If UQO->(DbSeek(xFilial("UQO") + cFatura))
					fGetDados(nOpcao, lVisual)

					If !Empty(aCols)
						If lMultipFat
							uRet := fIntegra(nOpcao)
						Else
							Processa({|| uRet := fIntegra(nOpcao)}, CAT518017, CAT518018)	  // #"Aguarde" // #"Processando integração..."
						EndIf
					Else
						MsgAlert(CAT518077, cCadastro) //"Nenhum ítem cadastrado para o registro selecionado."
					EndIf
				EndIf
			EndIf
		Else
			MsgAlert(CAT518078, cCadastro) //"Fatura já integrada ao sistema, não é necessário reintegra-la."
		EndIf
	Else // Visualização, Inclusão, Alteração, Exclusão
		If cStatus <> cEmAberto .And. nOpcao > nInclui .AND. nOpcao < nIntegra
			MsgAlert(CAT518012, cCadastro)
		Else
			fFatura(cAlias, nRecno, nOpcao)
		EndIf
	EndIf

Return(uRet)

/*/{Protheus.doc} fFatura
Exibe a tela de detalhes da Fatura de acordo com a opção escolhida pelo usuário.
@author Paulo Carvalho
@since 25/02/2019
@param cAlias, caracter, Alias principal do programa (UQO).
@param nRecno, numérico, Recno da fatura selecionada para a rotina.
@param nOpcao, numérico, Opção selecionada no array aRotina.
@type function
/*/
Static Function fFatura(cAlias, nRecno, nOpcao)

	Local aButtons			:= {}	// Array contendo as rotinas da EnchoiceBar
	Local aCabecalho		:= {}	// Campos que irão compor a MSMGet
	Local aCamposAlt		:= {}	// Campos que, em edição, serão alteráveis

	Local bCancela			:= {|| fCancela(nOpcao)}
	Local bConfirma			:= {|| fConfirma(nOpcao)}

	Local nColRight			:= 0
	Local nTotColRig		:= 0
	Local nOrientacao		:= 1

	Private aHeader			:= {}
	Private aPosCab			:= {}
	Private aPosDet			:= {}

	Private cObserv			:= CriaVar("UQO_OBS", .T.)

	Private lCentered		:= .T.
	Private lFocSel			:= .T.
	Private lHasButton		:= .T.
	Private lHasOk			:= .T.
	Private lNoButton		:= .T.
	Private lMemoria		:= .T.
	Private lPassword		:= .T.
	Private lPixel			:= .T.
	Private lPicturePiority	:= .T.
	Private lReadOnly		:= .T.
	Private lTransparent	:= .T.

	Private nTop			:= 0
	Private nLeft			:= 0
	Private nBottom			:= 0
	Private nRight			:= 0

	Private nLblPos			:= 1	// Define que o TSay do objeto TGet será escrito acima do objeto.
	Private nTotalFat		:= 0

	Private oCabecalho		:= Nil
	Private oGetDados		:= Nil
	Private oPnlCabec		:= Nil
	Private oPnlDetal		:= Nil
	Private oPnlFooter		:= Nil
	Private oSplitter		:= Nil

	// Instancia o objeto para controle das coordenadas da aplicação
	Private oSize			:= FWDefSize():New(.T.) // Indica que a tela terá EnchoiceBar

	// Se for inclusão ou alteração, ativa as teclas de atalho
	If nOpcao == 3 .Or. nOpcao == 4
		fSetVK(nOpcao)
	EndIf

	// Define que os objetos não serão expostos lado a lado
	oSize:lProp			:= .T.
	oSize:lLateral		:= .F.

	// Adiciona ao objeto oSize os objetos que irão compor a tela
	oSize:AddObject("ENCHOICE"	, 100, 020, .T., .T.)
	oSize:AddObject("GETDADOS"	, 100, 080, .T., .T.)

	// Realiza o cálculo das coordenadas
	oSize:Process()

	// Define as coordenadas da Dialog principal
	nTop	:= oSize:aWindSize[1]
	nLeft	:= oSize:aWindSize[2]
	nBottom	:= oSize:aWindSize[3]
	nRight	:= oSize:aWindSize[4]

	// Instancia a classe MSDialog
	oDialog := MSDialog():New( 	nTop, nLeft, nBottom, nRight, cCadastro,;
								/*uParam6*/, /*uParam7*/, /*uParam8*/,;
								nOr( WS_VISIBLE, WS_POPUP ), /*nClrText*/, /*nClrBack*/,;
								/*uParam12*/, /*oWnd*/ GetWndDefault(), lPixel, /*uParam15*/,;
								/*uParam16*/, /*uParam17*/, !lTransparent )

	// Cria os objetos da tela.
	oSplitter	:= TSplitter():New( 001, 001, oDialog, 260, 184, nOrientacao )
	oPnlCabec	:= TPanel():New( 000, 002,'',oSplitter,,,,, /*CLR_YELLOW*/, 110, 036 )
	oPnlDetal	:= TPanel():New( 000, 002,'',oSplitter,,,,, /*CLR_HRED  */, 110, 080 )
	oPnlFooter	:= TPanel():New( 000, 002,'',oSplitter,,,,, /*CLR_HRED  */, 110, 034 )

	// Define o posicionamento dos objetos da tela
	aPosCab := 	{	oSize:GetDimension("ENCHOICE","LININI"),;
					oSize:GetDimension("ENCHOICE","COLINI"),;
					oSize:GetDimension("ENCHOICE","LINEND"),;
					oSize:GetDimension("ENCHOICE","COLEND")	}

	aPosDet := 	{	oSize:GetDimension("GETDADOS","LININI"),;
					oSize:GetDimension("GETDADOS","COLINI"),;
					oSize:GetDimension("GETDADOS","LINEND") + 15,; // + 15 para compensar a falta da barra de título
					oSize:GetDimension("GETDADOS","COLEND")	}

	// Cria a GetDados com os itens da Fatura
	fGetDados(nOpcao, .T.)

	// Monta o array com os campos que irão compor a MSMGet
	aCabecalho	:= fCabCampos()

	// Define os campos que podem ser alterados
	aCamposAlt	:= fCamposAlt(nOpcao)

	RegToMemory(cAlias, IIf(nOpcao == 3, .T., .F.))

	// Cria a MsmGet
	oCabecalho	 := MsmGet():New(cAlias, nRecno, nOpcao,/*aCRA*/,/*cLetras*/,/*cTexto*/,aCabecalho,aPosCab,aCamposAlt,;
					/*nModelo*/,/*nColMens*/,/*cMensagem*/, /*cTudoOk*/,oPnlCabec,/*lF3*/,lMemoria,/*lColumn*/,;
					/*caTela*/,/*lNoFolder*/,/*lProperty*/,/*aField*/,/*aFolder*/,/*lCreate*/,;
					/*lNoMDIStretch*/,/*cTela*/)

	If nOpcao == 3
		M->UQO_ID := fGetIDFat()
	EndIf

	// Abre a MSMGet utilizando todo o tamanho disponível
	oCabecalho:oBox:Align	:= CONTROL_ALIGN_ALLCLIENT

	// Alinhamento dos objetos
	oSplitter:Align		:= CONTROL_ALIGN_ALLCLIENT
	oPnlCabec:Align		:= CONTROL_ALIGN_TOP
	oPnlDetal:Align		:= CONTROL_ALIGN_NONE
	oPnlFooter:Align	:= CONTROL_ALIGN_BOTTOM

	// Define o posicionamento da coluna do campo TGTotal
	nTotColRig	:= oSize:GetDimension("GETDADOS","COLEND") - 70

	// Cria o Get para exibição do total no painel oTotalFat.
	oTGTotal	:= TGet():New(	005, nTotColRig, {|u| IIf(Pcount() > 0, nTotalFat := u, nTotalFat)}, oPnlFooter, 070, 011,;
				PesqPict("UQO", "UQO_TOTAL"), /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
				/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
				/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "nTotalFat",;
				/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,; // Valor Total
				CAT518013, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;
				!lPicturePiority, lFocSel )

	oTGTotal:Disable()

	// Define a coluna de posicionamento do campo de Observações
	nColRight 	:= oSize:GetDimension("GETDADOS","COLEND") - 80

	// Cria o Get para exibição do total no painel oTotalFat.
	oTGObs		:= TMultiGet():New(005, 005, {|u| IIf(Pcount() > 0, cObserv := u, cObserv)}, oPnlFooter, nColRight, 40,;
				/*oFont*/, /*uParam8*/, /*uParam9*/, /*uParam10*/, /*uParam11*/, lPixel,;
				/*uParam13*/, /*uParam14*/, /*bWhen*/, /*uParam16*/, /*uParam17*/, !lReadOnly,;
				/*bValid*/, /*uParam20*/, /*uParam21*/, /*lNoBorder*/, /*lVScroll*/, CAT518014,; // Observações
				nLblPos, /*oLabelFont*/, /*nLabelColor*/)

	// Desabilita o objeto de acordo com a opção
	IIf(nOpcao == 2 .Or. nOpcao == 5 .Or. nOpcao == 6, oTGObs:Disable(), oTGObs:Enable())

	// Define os botões da EnchoiceBar
	If nOpcao == 3 .Or. nOpcao == 4
		Aadd(aButtons, { "", {|| fGetCTE()	}	, CAT518020		})		// #"Selecionar títulos"
	EndIf

	// Recupera informações da fatura caso seja uma alteração ou exclusão
	fSetInfo(nOpcao)

	// Ativa a Dialog
	oDialog:Activate(,,, .T., {|| .T.},, EnchoiceBar(oDialog, bConfirma, bCancela,, @aButtons , , , .F. , .F. , .F. , lHasOk := .T. , .F., ),,)

	// Se for inclusão ou alteração, ativa as teclas de atalho
	If nOpcao == 3 .Or. nOpcao == 4
		fVKNil()
	EndIf

Return

/*/{Protheus.doc} fValidId
Valida e retorna o Id sugerido para fatura.
@author Paulo Carvalho
@since 05/04/2019
@param nOpcao, numérico, Opção selecionada no array aRotina.
@param cIdFatura, caracter, Id sugerido pelo incializador padrão para a fatura.
@return cIdFatura, caracter, número validado pela função para a fatura.
@type function
/*/
Static Function fValidId(nOpcao, cIdFatura)

	Local aArea		:= GetArea()
	Local aAreaUQO	:= UQO->(GetArea())

	Local nInclusao	:= 3

	If nOpcao == nInclusao
		// Valida o id da fatura
		DbSelectArea("UQO")
		UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID
		UQO->(DbGoTop())

		While UQO->(DbSeek(FWxFilial("UQO") + cIdFatura))
			ConfirmSX8()
			cIdFatura := GetSXENum("UQO", "UQO_ID")
		EndDo
	EndIf

	RestArea(aAreaUQO)
	RestArea(aArea)

Return cIdFatura

/*/{Protheus.doc} fGetIDFat
Retorna o próximo ID da fatura.
@author Juliano Fernandes
@since 27/06/2019
@version 1.0
@return cIDFat, ID da fatura
@type function
/*/
Static Function fGetIDFat()

	Local cIDFat	:= ""
	Local cQuery	:= ""
	Local cAliasQry	:= GetNextAlias()

	cQuery := " SELECT MAX(UQO_ID) UQO_ID " 					+ CRLF
	cQuery += " FROM " + RetSQLName("UQO") 						+ CRLF
	cQuery += " WHERE UQO_FILIAL = '" + xFilial("UQO") + "' "	+ CRLF

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.F.,.F.)

	If !(cAliasQry)->(EoF())
		cIDFat := (cAliasQry)->UQO_ID
	Else
		cIDFat := Replicate("0", TamSX3("UQO_ID")[1])
	EndIf

	cIDFat := Soma1(cIDFat)

	(cAliasQry)->(DbCloseArea())

Return(cIDFat)

/*/{Protheus.doc} fConfirma
Realiza a gravação dos dados inseridos pelo usuário de acordo com o opção selecionada.
@author Paulo Carvalho
@since 18/03/2019
@param nOpcao, numérico, Opção selecionada no array aRotina.
@type function
/*/
Static Function fConfirma(nOpcao)

	Local cOpcao	:= IIf(nOpcao==3, CAT518021,; // #"inclusão"
							IIf(nOpcao == 4, CAT518022, CAT518023)) // #"alteração", #"exclusão"

	Local lOk		:= .T.

	Local nVisual	:= 2

	If nOpcao > nVisual
		// Verificar se o usuário deseja confirmar a ação
		If MsgYesNo(CAT518024 + cOpcao + "?", cCadastro) // #"Deseja realmente confirmar a "
			BEGIN TRANSACTION

				If nOpcao == 3 .Or. nOpcao == 4
					// Valida os campos obrigatórios
					IIf(fVldIncAlt(), fSalvar(nOpcao), lOk := .F.)
				ElseIf nOpcao == 5
					fExcluir()
				EndIf

			END TRANSACTION

			If lOk
				oDialog:End()
			EndIf
		EndIf
	ElseIf nOpcao == nVisual
		// Fecha a tela de manutenção
		oDialog:End()
	EndIf

Return

/*/{Protheus.doc} fVldIncAlt
Valida se os campos obrigatórios estão preenchidos.
@author Paulo Carvalho
@since 04/04/2019
@return lValid, lógico, retorna true se os campos obrigatórios estão preenchidos e false se não estão.
@type function
/*/
Static Function fVldIncAlt()

	Local lValid	:= .T.

	If fVldCabec()
		lValid := fVldItens()
	Else
		lValid := .F.
	EndIf

Return lValid

/*/{Protheus.doc} fVldCabec
Valida os dados de cabeçalho da fatura.
@author Paulo Carvalho
@since 04/04/2019
@return lValid, lógico, retorna true se o cabeçalho é valida e false se não é valida para inclusão/alteração.
@type function
/*/
Static Function fVldCabec()

	Local lValid 	:= .T.

	Do Case
		Case Empty(M->UQO_EMISSA)
			lValid := .F.
			MsgAlert(CAT518025, cCadastro) // #"Preencha todos os campos obrigatórios para salvar a fatura."
		Case Empty(M->UQO_CLIENT)
			lValid := .F.
			MsgAlert(CAT518025, cCadastro) // #"Preencha todos os campos obrigatórios para salvar a fatura."
		Case Empty(M->UQO_LOJA)
			lValid := .F.
			MsgAlert(CAT518025, cCadastro) // #"Preencha todos os campos obrigatórios para salvar a fatura."
		Case Empty(M->UQO_VENCTO)
			lValid := .F.
			MsgAlert(CAT518025, cCadastro) // #"Preencha todos os campos obrigatórios para salvar a fatura."
		Case nTotalFat < 0
			lValid := .F.
			MsgAlert(CAT518026, cCadastro) // #"O valor total da fatura deve ser maior que (0) zero."
	EndCase

Return lValid

/*/{Protheus.doc} fVldItens
Valida os itens que compõe a fatura.
@author Paulo Carvalho
@since 04/04/2019
@type function
/*/
Static Function fVldItens()

	Local aItens	:= IIF(Empty(oGetDados:aCols),"",oGetDados:aCols)
	Local cErrorMsg	:= CAT518027 // #"Não é permitido incluir um item com título no 2º bloco sem título equivalente no 1º bloco."
	Local lValid 	:= .T.
	Local nI

	If !Empty(aItens)
		For nI := 1 To Len(aItens)
			If Empty(aItens[nI][nPsUQPTtFat]);
					.And. Empty(aItens[nI][nPsUQPVlFat]);
					.And. !Empty(aItens[nI][nPsUQPTit]);
					.And. !Empty(aItens[nI][nPsUQPValor]);
					.And. !aItens[nI][nPsUQPDel]

				lValid := .F.
				MsgAlert(cErrorMsg, cCadastro)

				Exit
			EndIf
		Next
	EndIf

Return lValid

/*/{Protheus.doc} fSalvar
Realiza a gravação dos dados inseridos pelo usuário de acordo com o opção selecionada.
@author Paulo Carvalho
@since 18/03/2019
@type function
/*/
Static Function fSalvar(nOpcao)

	Local lGrv		:= .T.

	// Grava as informações do cabeçalho da fatura
	If fSalvaCab(nOpcao)
		// Grava os itens da fatura
		If fSalvaItem(nOpcao)
			If !IsInCallStack("fIntegra")
				MsgInfo(CAT518028, cCadastro) // #"Fatura gravada com sucesso."
			EndIf
		Else
			lGrv := .F.
		EndIf
	Else
		lGrv := .F.
	EndIf

Return(lGrv)

/*/{Protheus.doc} fExcluir
Realiza a exclusão da fatura selecionada.
@author Paulo Carvalho
@since 18/03/2019
@type function
/*/
Static Function fExcluir()
	Local aArea			:= GetArea()
	Local aAreaUQO		:= UQO->(GetArea())
	Local aAreaUQP		:= UQP->(GetArea())
	Local aAreaSE1		:= SE1->(GetArea())

	Local lDelItens		:= .F.

	Local lRet			:= .T.

	// Posiciona na fatura aberta
	DbSelectArea("UQO")
	UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID

	If UQO->(DbSeek(FWxFilial("UQO") + cFatura))
		// Verifica o status da fatura
		If UQO->UQO_STATUS == "1"
			// Posiciona nos itens da fatura
			DbSelectArea("UQP")
			UQP->(DbSetOrder(1))	// UQP_FILIAL + UQP_IDFAT + UQP_ITEM + UQP_TPFAT + UQP_PFXFAT + UQP_TITFAT + UQP_PARFAT

			// Deleta os itens da fatura
			If UQP->(DbSeek(FWxFilial("UQP") + cFatura))
				lDelItens := .T.

				While !UQP->(Eof()) .And. UQP->UQP_IDFAT == cFatura
					// Se desfizer o relacionamento do título com a fatura
					If fDesfazRel()
						// Excluir o item da fatura
						RecLock("UQP", .F.)
							UQP->(DbDelete())
						UQP->(MsUnlock())
					EndIf

					UQP->(DbSkip())
				EndDo
			EndIf

			// Deleta o cabeçalho da fatura
			RecLock("UQO", .F.)
				UQO->(DbDelete())
			UQO->(MsUnlock())
		Else
			lRet := .F.
			MsgAlert(CAT518029, cCadastro) //#"Não é permitido excluir uma fatura que esteja integrada ou baixada."
		EndIf
	EndIf

	If lRet
		MsgAlert(CAT518030, cCadastro) // #"Fatura excluída com sucesso."
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaUQP)
	RestArea(aAreaUQO)
	RestArea(aArea)
Return

/*/{Protheus.doc} fDesfazRel
Desfaz o relacionamento entre os títulos selecionados e a fatura criada pelo usuário.
@author Paulo Carvalho
@since 01/04/2019
@type function
/*/
Static Function fDesfazRel()

	Local aArea			:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())

	Local cParFat		:= ""
	Local cParcela		:= ""
	Local cPfxFat		:= ""
	Local cPrefixo		:= ""
	Local cTpFat		:= ""
	Local cTipo			:= ""
	Local cTitFat		:= ""
	Local cTitulo		:= ""

	Local lRet			:= .T.

	If "UQP" $ Alias()
		cPfxFat 	:= PadR(UQP->UQP_PFXFAT	, TamSX3("E1_PREFIXO")[1])
		cPrefixo 	:= PadR(UQP->UQP_PREFIX	, TamSX3("E1_PREFIXO")[1])
		cTitFat		:= PadR(UQP->UQP_TITFAT	, TamSX3("E1_NUM"    )[1])
		cTitulo		:= PadR(UQP->UQP_TITULO	, TamSX3("E1_NUM"    )[1])
		cParFat		:= PadR(UQP->UQP_PARFAT	, TamSX3("E1_PARCELA")[1])
		cParcela	:= PadR(UQP->UQP_PARCEL	, TamSX3("E1_PARCELA")[1])
		cTpFat		:= PadR(UQP->UQP_TPFAT	, TamSX3("E1_TIPO"   )[1])
		cTipo		:= PadR(UQP->UQP_TIPO	, TamSX3("E1_TIPO"   )[1])


		// Desvincula o título visível na fatura
		DbSelectArea("SE1")
		SE1->(DbSetOrder(1))	// E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
		SE1->(DbGoTop())

		If SE1->(DbSeek(xFilial("SE1") + cPfxFat + cTitFat + cParFat + cTpFat))
			RecLock("SE1", .F.)
				SE1->E1_XIDFAT 	:= ""
			SE1->(MsUnlock())
		Else
			lRet := .F.
		EndIf

		// Se possuir um título não visível vinculado
		If !Empty(cTitulo)
			// Retorna ao topo
			SE1->(DbGoTop())

			If SE1->(DbSeek(xFilial("SE1") + cPrefixo + cTitulo + cParcela + cTipo))
				RecLock("SE1", .F.)
					SE1->E1_XIDFAT 	:= ""
				SE1->(MsUnlock())
			Else
				lRet := .F.
			EndIf
		EndIf
	Else
		lRet := .F.
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fSalvaCab
Finaliza a manutenção na fatura.
@author Paulo Carvalho
@since 18/03/2019
@param nOpcao, numérico, Opção seleciona no array aRotina.
@type function
/*/
Static Function fSalvaCab(nOpcao)

	Local lRecLock	:= IIf(nOpcao == 3, .T., .F.)
	Local lContinua	:= .T.

	// Abre a tabela de cabeçalho
	DbSelectArea("UQO")
	UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID

	// Se for alteração
	If nOpcao <> 3
		// Posiciona o registro alterado
		If !UQO->(DbSeek(FWxFilial("UQO") + M->UQO_ID))
			lContinua := .F.
			MsgAlert(CAT518031, cCadastro) // #"Fatura não encontrada no sistema."
		EndIf
	EndIf

	// ----------------------------------------------------
	// Confirma se o ID da fatura ainda está disponível
	// ----------------------------------------------------
	If nOpcao == 3
		M->UQO_ID := fGetIDFat()
	EndIf

	// Se encontrou o registro para alteração ou é uma inclusão
	If lContinua
		// Trava a tabela para inclusão ou alteração do registro
		If nOpcao == 6	//Caso seja uma integração estas variáveis não terão sido inicializadas
			nTotalFat := UQO->UQO_TOTAL
			cObserv	  := UQO->UQO_OBS
		EndIf

		RecLock("UQO", lRecLock)
			UQO->UQO_FILIAL	:= FWxFilial("UQO")
			UQO->UQO_ID		:= M->UQO_ID
			UQO->UQO_NUMERO	:= M->UQO_NUMERO
			UQO->UQO_EMISSA	:= M->UQO_EMISSA
			UQO->UQO_VENCTO	:= M->UQO_VENCTO
			UQO->UQO_CLIENT	:= M->UQO_CLIENT
			UQO->UQO_LOJA	:= M->UQO_LOJA
			UQO->UQO_NOMECL	:= M->UQO_NOMECL
			UQO->UQO_TOTAL	:= nTotalFat
			UQO->UQO_OBS	:= cObserv
			UQO->UQO_STATUS	:= M->UQO_STATUS
			If FieldPos("UQO_USUARI") > 0
				UQO->UQO_USUARI	:= Upper(Alltrim(UsrRetName(__CUSERID)))
			EndIf
		UQO->(MsUnlock())
	EndIf

Return lContinua

/*/{Protheus.doc} fSalvaItem
Realiza a persistência dos itens da fatura no banco de dados.
@author Paulo Carvalho
@since 18/03/2019
@param nOpcao, numérico, Opção selecionado no array aRotina.
@type function
/*/
Static Function fSalvaItem(nOpcao)

	Local aItens		:= oGetDados:aCols

	Local cAltera		:= "A"
	Local cExclui		:= "E"
	Local cInclui		:= "I"

	Local lContinua		:= .T.

	Local nI
	Local nItens		:= Len(aItens)

	Private cItem		:= "000"

	// Abre a tabela de cabeçalho
	DbSelectArea("UQP")
	UQP->(DbSetOrder(1))	// UQP_FILIAL + UQP_IDFAT + UQP_ITEM + UQP_TPFAT + UQP_PFXFAT + UQP_TITFAT + UQP_PARFAT

	//Reordenar o array pois gerou erro ao gravar desordenado
	aSort( aItens,,,{|a,b| a[1] < b[1]})

	// Se for alteração
	If nOpcao == 4
		For nI := 1 To nItens
			// Posiciona no registro para alteração
			If UQP->(DbSeek(FWxFilial("UQP") + M->UQO_ID + aItens[nI][nPsUQPItem]))
				// Se a linha estiver vazia
				If Empty(aItens[nI][nPsUQPTtFat])
					fGravaItem(aItens[nI], M->UQO_ID, cExclui, M->UQO_CLIENT, M->UQO_LOJA)
				// Se for um registro excluído
				ElseIf !Empty(aItens[nI][nPsUQPRecno]) .And. aItens[nI][nPsUQPDel]
					fGravaItem(aItens[nI], M->UQO_ID, cExclui, M->UQO_CLIENT, M->UQO_LOJA)
				// Se for um registro alterado e não estiver excluído
				ElseIf !Empty(aItens[nI][nPsUQPRecno]) .And. !aItens[nI][nPsUQPDel]
					fGravaItem(aItens[nI], M->UQO_ID, cAltera, M->UQO_CLIENT, M->UQO_LOJA)
				EndIf
			Else
				// Se for um novo registro e não estiver excluído
				If Empty(aItens[nI][nPsUQPRecno]) .And. !aItens[nI][nPsUQPDel]
					fGravaItem(aItens[nI], M->UQO_ID, cInclui, M->UQO_CLIENT, M->UQO_LOJA)
				Else
					lContinua := .F.

					Exit
					DisarmTransaction()
				EndIf
			EndIf
		Next
	ElseIf nOpcao == 3	// Se for inclusão
		For nI := 1 To nItens
			// Grava o Item
			If !aItens[nI][nPsUQPDel]
				fGravaItem(aItens[nI], M->UQO_ID, "I", M->UQO_CLIENT, M->UQO_LOJA)
			EndIf
		Next
	EndIf

Return lContinua

/*/{Protheus.doc} fGravaItem
Realiza a persistência do item de uma fatura.
@author Paulo Carvalho
@since 18/03/2019
@param aItem, array, Array contendo as informações do item da fatura a ser gravado.
@param cFatura, caracter, código da fatura à qual o item pertence.
@param cAcao, caracter, ação a ser realizada com o item. I = Inclusão; A = Alteração; E = exclusão.
@param cCliente, caracter, Código do cliente.
@param cLoja, caracter, Loja do cliente.
@type function
/*/
Static Function fGravaItem(aItem, cFatura, cAcao, cCliente, cLoja)

	Local aArea			:= GetArea()
	Local aAreaUQP		:= UQP->(GetArea())
	Local aAreaSE1		:= SE1->(GetArea())

	Local cChaveSE1		:= ""

	Local lOk			:= .T.


	If "I" $ cAcao .And. !Empty(aItem[nPsUQPTtFat])
		// Reajusta o item.
		cItem := Soma1(cItem)

		RecLock("UQP", .T.)
			UQP->UQP_FILIAL		:= FWxFilial("UQP")
			UQP->UQP_IDFAT		:= cFatura
			UQP->UQP_ITEM		:= cItem
			UQP->UQP_TPFAT		:= aItem[nPsUQPTpFat]
			UQP->UQP_PFXFAT		:= aItem[nPsUQPPfFat]
			UQP->UQP_PARFAT		:= aItem[nPsUQPPcFat]
			UQP->UQP_TITFAT		:= aItem[nPsUQPTtFat]
			UQP->UQP_EMISFA		:= aItem[nPsUQPEmFat]
			UQP->UQP_VLRFAT		:= aItem[nPsUQPVlFat]
			UQP->UQP_ICMS		:= aItem[nPsUQPIcms]
			UQP->UQP_TIPO		:= aItem[nPsUQPTipo]
			UQP->UQP_PREFIX		:= aItem[nPsUQPPref]
			UQP->UQP_TITULO		:= aItem[nPsUQPTit]
			UQP->UQP_PARCEL		:= aItem[nPsUQPParc]
			UQP->UQP_EMISSA		:= aItem[nPsUQPEmiss]
			UQP->UQP_VALOR		:= aItem[nPsUQPValor]
			UQP->UQP_TOTAL		:= aItem[nPsUQPTotal]
		UQP->(MsUnlock())
	ElseIf  "A" $ cAcao
		// Posiciona no registro a ser alterado
		If  UQP->(DbSeek(FWxFilial("UQP") + cFatura + aItem[nPsUQPItem]))
			cItem := Soma1(cItem)

			RecLock("UQP", .F.)
				UQP->UQP_ITEM		:= cItem
				UQP->UQP_TPFAT		:= aItem[nPsUQPTpFat]
				UQP->UQP_PFXFAT		:= aItem[nPsUQPPfFat]
				UQP->UQP_PARFAT		:= aItem[nPsUQPPcFat]
				UQP->UQP_TITFAT		:= aItem[nPsUQPTtFat]
				UQP->UQP_EMISFA		:= aItem[nPsUQPEmFat]
				UQP->UQP_VLRFAT		:= aItem[nPsUQPVlFat]
				UQP->UQP_ICMS		:= aItem[nPsUQPIcms]
				UQP->UQP_TIPO		:= aItem[nPsUQPTipo]
				UQP->UQP_PREFIX		:= aItem[nPsUQPPref]
				UQP->UQP_TITULO		:= aItem[nPsUQPTit]
				UQP->UQP_PARCEL		:= aItem[nPsUQPParc]
				UQP->UQP_EMISSA		:= aItem[nPsUQPEmiss]
				UQP->UQP_VALOR		:= aItem[nPsUQPValor]
				UQP->UQP_TOTAL		:= aItem[nPsUQPTotal]
			UQP->(MsUnlock())
		Else
			lOk := .F.
		EndIf
	ElseIf "E" $ cAcao
		// Posiciona no registro a ser alterado
		If  UQP->(DbSeek(FWxFilial("UQP") + cFatura + aItem[nPsUQPItem])) /* + aItem[nPsUQPTpFat] +;
						aItem[nPsUQPPfFat] + aItem[nPsUQPTtFat]))*/

			RecLock("UQP", .F.)
				UQP->(DbDelete())
			UQP->(MsUnlock())
		Else
			lOk := .F.
		EndIf
	EndIf

	//--------------------------------------------------------
	// Gravação do código da fatura no Contas a receber (SE1)
	//--------------------------------------------------------
	If lOk
		cChaveSE1 := xFilial("SE1")
		cChaveSE1 += PadR(cCliente		    , TamSX3("E1_CLIENTE")[1])
		cChaveSE1 += PadR(cLoja			    , TamSX3("E1_LOJA"   )[1])
		cChaveSE1 += PadR(aItem[nPsUQPPfFat], TamSX3("E1_PREFIXO")[1])
		cChaveSE1 += PadR(aItem[nPsUQPTtFat], TamSX3("E1_NUM"    )[1])
		cChaveSE1 += PadR(aItem[nPsUQPPcFat], TamSX3("E1_PARCELA")[1])
		cChaveSE1 += PadR(aItem[nPsUQPTpFat], TamSX3("E1_TIPO"   )[1])

		DbSelectArea("SE1")
		SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		If SE1->(DbSeek( cChaveSE1 ))
			SE1->(RecLock("SE1",.F.))
				If cAcao $ ".I.A." // Inclusão ou alteração
					SE1->E1_XIDFAT 	:= cFatura
				Else
					SE1->E1_XIDFAT 	:= ""
				EndIf
			SE1->(MsUnlock())
		EndIf

		If !Empty(aItem[nPsUQPTit]) .And. !Empty(aItem[nPsUQPTipo])
			SE1->(DbGoTop())

			cChaveSE1 := xFilial("SE1")
			cChaveSE1 += PadR(cCliente		   , TamSX3("E1_CLIENTE")[1])
			cChaveSE1 += PadR(cLoja			   , TamSX3("E1_LOJA"   )[1])
			cChaveSE1 += PadR(aItem[nPsUQPPref], TamSX3("E1_PREFIXO")[1])
			cChaveSE1 += PadR(aItem[nPsUQPTit] , TamSX3("E1_NUM"    )[1])
			cChaveSE1 += PadR(aItem[nPsUQPParc], TamSX3("E1_PARCELA")[1])
			cChaveSE1 += PadR(aItem[nPsUQPTipo], TamSX3("E1_TIPO"   )[1])

			If SE1->(DbSeek( cChaveSE1 ))
				SE1->(RecLock("SE1",.F.))
					If cAcao $ ".I.A." // Inclusão ou alteração
						SE1->E1_XIDFAT 	:= cFatura
					Else
						SE1->E1_XIDFAT 	:= ""
					EndIf
				SE1->(MsUnlock())
			EndIf
		EndIf
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaUQP)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCancela
Finaliza a manutenção na fatura.
@author Paulo Carvalho
@since 18/03/2019
@param nOpcao, numérico, número da opção selecionada pelo usuário.
@type function
/*/
Static Function fCancela(nOpcao)

	Local aArea		:= GetArea()
	Local cOpcao	:= IIf(nOpcao==3, CAT518021,; // #"inclusão"
							IIf(nOpcao == 4, CAT518022, CAT518023)) // #"alteração", #"exclusão"

	Local nVisual	:= 2

	If nOpcao > nVisual
		// Verifica se o usuário deseja realmente cancelar.
		If MsgYesNo(CAT518032 + cOpcao + "?", cCadastro) // #"Deseja realmente cancelar a "
			// Se inclusão, restaura o número na SXE
			RollBackSX8()

			// Fecha a tela de manutenção
			oDialog:End()
		EndIf
	ElseIf nOpcao == nVisual
		// Fecha a tela de manutenção
		oDialog:End()
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc}fSetInfo
Recupera as informações de total da fatura e observação.
@author Paulo Carvalho
@since 18/03/2019
@param nOpcao, numérico, Opção selecionada no array aRotina.
@type function
/*/
Static Function fSetInfo(nOpcao)

	Local aArea		:= GetArea()
	Local aAreaUQO	:= UQO->(GetArea())

	If nOpcao <> 3
		// Posiciona na fatura aberta e retorna o total
		DbSelectArea("UQO")
		UQO->(DbSetOrder(1))	// UQO_FILIAL + UQO_ID

		If UQO->(DbSeek(FWxFilial("UQO") + M->UQO_ID))
			cObserv 	:= UQO->UQO_OBS
			nTotalFat 	:= UQO->UQO_TOTAL

			// Atualiza os objetos
			oTGObs:Refresh()
			oTGTotal:Refresh()
		EndIf
	EndIf

	RestArea(aAreaUQO)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCabCampos
Retorna um array com os campos da tabela UQO que irão compor a Get.
@author Paulo Carvalho
@since 26/02/2019
@type function
/*/
Static Function fCabCampos()

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	Local aCampos	:= {}
	Local aNoFields	:= {}

	// -------------------------------------------------
	// Campos que não serão exibidos na MsMGet
	// -------------------------------------------------
	Aadd( aNoFields, PadR("UQO_TOTAL", 10) )
	Aadd( aNoFields, PadR("UQO_OBS"	 , 10) )
	Aadd( aNoFields, PadR("UQO_DTLIQ", 10) )
	Aadd( aNoFields, PadR("UQO_BAIXA", 10) )

	DbSelectArea("SX3")
	SX3->(DbSetOrder(1))
	SX3->(DbSeek("UQO"))

	// Adiciona os campos da tabela ao array
	While !SX3->(Eof()) .And. (SX3->X3_ARQUIVO == "UQO")

		If AScan(aNoFields, SX3->X3_CAMPO) == 0
			Aadd(aCampos, SX3->X3_CAMPO)
		EndIf

		SX3->(dbSkip())
	End

	// Adiciona campo
	Aadd(aCampos, "NOUSER")

	RestArea(aAreaSX3)
	RestArea(aArea)

Return aClone(aCampos)

/*/{Protheus.doc} fCamposAlt
Exibe as legendas possíveis para o status dos arquivos.
@author Paulo Carvalho
@since 26/02/2019
@param nOpcao, numérico, Opção selecionada no array aRotina.
@type function
/*/
Static Function fCamposAlt(nOpcao)

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	Local aCampos	:= {}

	DbSelectArea("SX3")
	SX3->(DbSetOrder(1)) 	// X3_ARQUIVO + X3_ORDERM + X3_CAMPO

	If SX3->(DbSeek("UQO"))
		// Adiciona os campos da tabela ao array
		While !SX3->(Eof()) .And. (SX3->X3_ARQUIVO == "UQO")
			// Se o campo permite alteração
			If SX3->X3_VISUAL == "A"
				If nOpcao == 4
					If SX3->X3_CAMPO <> "UQO_CLIENT" .And. SX3->X3_CAMPO <> "UQO_LOJA"
						Aadd(aCampos, SX3->X3_CAMPO)
					EndIf
				Else
					Aadd(aCampos, SX3->X3_CAMPO)
				EndIf
			EndIf

			SX3->(dbSkip())
		End
	EndIf

	RestArea(aAreaSX3)
	RestArea(aArea)

Return aClone(aCampos)

/*/{Protheus.doc} fGetDados
Cria a GetDados com os itens da fatura de acordo com a opção escolhida pelo usuário.
@author Paulo Carvalho
@since 26/02/2019
@param nOpcao, numerico, número da opção selecionada pelo usuário no menu.
@param lVisual, lógico, indica se a getdados vai ser visivel (.T.) ou não (.F.)
@type function
/*/
Static Function fGetDados(nOpcao, lVisual)

	Local aArea			:= GetArea()

	Local aArray		:= {}
	Local aCampos		:= {}
	Local aCamposAlt	:= {}

	Local cAllTrue		:= "AllwaysTrue"
	Local cDelOk		:= "StaticCall(PRT0518, fDelOk)"
	Local cFieldOk		:= "StaticCall(PRT0518, fFieldOk)"
	Local cIniCpos		:= "+UQP_ITEM"
	Local cLinhaOk		:= "StaticCall(PRT0518, fLinhaOk)"

	Local lVisGD 		:= lVisual

	Local nA, nH, nI

	Local nLock			:= 0
	Local nOpen			:= GD_INSERT + GD_UPDATE + GD_DELETE
	Local nStyle		:= Nil	// Define as operações possíveis da GetDados

	// Define os campos que irão compor a GetDados
	fAddCampos(@aCampos)

	// Define os campos que poderão ser alterados no programa
	fAddCamAlt(@aCamposAlt)

	// Adiciona os campos no aHeader
	For nI := 1 To Len(aCampos)
		fAddHeader(@aHeader, aCampos[nI])
	Next

	// Cria array aCols
	For nA := 1 To Len( aHeader )
		Aadd(aArray, IIf(aHeader[nA][2] <> "DIVISOR", CriaVar(aHeader[nA][2], .T.), ""))
	Next

	// Adiciona o Alias e o Recno
	AdHeadRec("UQP", aHeader)

	Aadd(aArray, "UQP"	)	// Alias
	Aadd(aArray, 0		)	// Recno
	Aadd(aArray, .F.	)	// D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeader)
		 If Empty(aHeader[nH][3]) .And. aHeader[nH][8] == "C"
			aHeader[nH][3] := "@!"
		EndIf
	Next

	// Define as ações na GetDados de acordo com a opção
	nStyle := IIf(nOpcao == 2 .Or. nOpcao == 5 .Or. nOpcao == 6, nLock, nOpen)

	If lVisGD
		// Instancia a GetDados
		oGetDados 	:= MsNewGetDados():New(	aPosDet[1], aPosDet[2], aPosDet[3], aPosDet[4], nStyle, cLinhaOk, cAllTrue,;
										cIniCpos, aCamposAlt, /*nFreeze*/, 999, cFieldOk, /*cSuperDel*/,;
										cDelOk, oPnlDetal, aHeader, { aArray }, /*bChange*/, /*cTela*/	)

		/*Rotina para ordenar com clique no cabeçalho */
		oGetDados:oBrowse:bHeaderClick := {| x, y | aGetDados := oGetDados:aCols, If(nOrdena == 1, fOrdBrw( x, y ), nOrdena++ ) }

		oGetDados:SetEditLine(.T.)
		oGetDados:Refresh()

		// ---------------------------------------------
		// Colunas que não devem ser ordenadas ao
		// clicar no cabeçalho da GetDados.
		// ---------------------------------------------
		Aadd(aColNaoOrd, GdFieldPos("DIVISOR"))
		Aadd(aColNaoOrd, GdFieldPos("UQP_ALI_WT"))
	EndIf

	//-- Cria as variáveis de posição
	fCria_nPos()

	// Preenche a GetDados
	fFillDados(nOpcao, lVisGD)

	RestArea(aArea)

Return

/*/{Protheus.doc} fAddCampos
Define no array aCampos os que campos que irão compor a GetDados.
@author Paulo Carvalho
@since 26/02/2019
@param aCampos, array, Array contendo os campos da GetDados
@type function
/*/
Static Function fAddCampos(aCampos)

	Local aArea		:= GetArea()

	// Define os campos
	Aadd(aCampos, "UQP_ITEM"	)
	Aadd(aCampos, "UQP_TPFAT"	)
	Aadd(aCampos, "UQP_PFXFAT"	)
	Aadd(aCampos, "UQP_PARFAT"	)
	Aadd(aCampos, "UQP_TITFAT"	)
	Aadd(aCampos, "UQP_EMISFA"	)
	Aadd(aCampos, "UQP_VLRFAT"	)
	Aadd(aCampos, "UQP_ICMS"	)
	Aadd(aCampos, "DIVISOR"		)
	Aadd(aCampos, "UQP_TIPO"	)
	Aadd(aCampos, "UQP_PREFIX"	)
	Aadd(aCampos, "UQP_TITULO"	)
	Aadd(aCampos, "UQP_PARCEL"	)
	Aadd(aCampos, "UQP_EMISSA"	)
	Aadd(aCampos, "UQP_VALOR"	)
	Aadd(aCampos, "UQP_TOTAL"	)

	RestArea(aArea)

Return

/*/{Protheus.doc} fAddCamAlt
Define no array aCamposAlt os campos que serão alteráveis na GetDados.
@author Paulo Carvalho
@since 26/02/2019
@param aCamposAlt, array, Array contendo os campos alteráveis da GetDados
@type function
/*/
Static Function fAddCamAlt(aCamposAlt)

	Local aArea		:= GetArea()

	// Define os campos
	Aadd(aCamposAlt, "UQP_TITFAT")
	Aadd(aCamposAlt, "UQP_TITULO")

	RestArea(aArea)

Return

/*/{Protheus.doc} fAddHeader
Função para adicionar no aHeader o campo determinado.
@author Douglas Gregorio
@since 07/05/2018
@param aArray, array, Array que irá receber os dados da coluna
@param cNomeCampo, characters, Campo que será adicionado
@return uRet, Nulo
@type function
/*/
Static Function fAddHeader(aArray, cNomeCampo)

	Local aArea		:= GetArea()
	Local aAreaSX3	:= SX3->(GetArea())

	Local uRet		:= Nil

	DbSelectArea("SX3")
	SX3->(dbSetOrder(2)) // X3_CAMPO

	If SX3->(DbSeek(cNomeCampo))

		Aadd( aArray, {	X3Titulo()		,;
						SX3->X3_CAMPO	,;
						SX3->X3_PICTURE	,;
						SX3->X3_TAMANHO	,;
						SX3->X3_DECIMAL	,;
						SX3->X3_VALID	,;
						SX3->X3_USADO	,;
						SX3->X3_TIPO	,;
						SX3->X3_F3		,;
						SX3->X3_CONTEXT	,;
						X3Cbox()		,;
						SX3->X3_RELACAO	})

	ElseIf cNomeCampo == "DIVISOR"

		Aadd( aArray, { "", "DIVISOR", "@!", 1, 0, .T., "", "C",;
				"", "R", "", "", .F., "V", "", "", "", ""	})

	EndIf

	RestArea(aAreaSX3)
	RestArea(aArea)

Return uRet

/*/{Protheus.doc} fFillDados
Preenche a GetDados de acordo com a opção escolhida pelo usuário.
@author Paulo Carvalho
@since 26/02/2019
@param nOpcao, array, Array contendo os campos da GetDados
@param lVisual, lógico, indica se a getdados vai ser visivel (.T.) ou não (.F.)
@type function
/*/
Static Function fFillDados(nOpcao, lVisual)

	Local aArea		:= GetArea()
	Local aAreaUQP	:= UQP->(GetArea())

	Local aItens	:= {}	// Array dos itens da fatura
	Local aItem		:= {}	// Array auxiliar para receber cada item da fatura

	Local cIniCpos	:= "001"
	Local cParFat	:= ""
	Local cParcela	:= ""

	// Abre a tabela de itens de fatura e posiciona nos itens da fatura selecionada
	DbSelectArea("UQP")
	UQP->(DbSetOrder(1))	// UQP_FILIAL + UQP_IDFAT + UQP_ITEM + UQP_TPFAT + UQP_PFXFAT + UQP_TITFAT + UQP_PARFAT

	If UQP->(DbSeek(xFilial("UQP") + cFatura)) .And. nOpcao <> 3 // Se não for inclusão
		// Enquanto houver itens para a fatura
		While !UQP->(Eof()) .And. UQP->UQP_IDFAT == cFatura
			// Reinicia o array de item
			aItem := {}

			If FwIsInCallStack("fGeraExcel")
				cParFat := StaticCall(PRT0614, fGetSeriEx, UQP->UQP_PARFAT)
				cParcela := StaticCall(PRT0614, fGetSeriEx, UQP->UQP_PARCEL)
			Else
				cParFat := UQP->UQP_PARFAT
				cParcela := UQP->UQP_PARCEL
			EndIf

			Aadd(aItem, UQP->UQP_ITEM	)
			Aadd(aItem, UQP->UQP_TPFAT	)
			Aadd(aItem, UQP->UQP_PFXFAT	)
			Aadd(aItem, cParFat			)
			Aadd(aItem, UQP->UQP_TITFAT	)
			Aadd(aItem, UQP->UQP_EMISFA )
			Aadd(aItem, UQP->UQP_VLRFAT	)
			Aadd(aItem, UQP->UQP_ICMS	)
			Aadd(aItem, ""				)
			Aadd(aItem, UQP->UQP_TIPO	)
			Aadd(aItem, UQP->UQP_PREFIX )
			Aadd(aItem, UQP->UQP_TITULO	)
			Aadd(aItem, cParcela		)
			Aadd(aItem, UQP->UQP_EMISSA )
			Aadd(aItem, UQP->UQP_VALOR	)
			Aadd(aItem, UQP->UQP_TOTAL	)
			Aadd(aItem, "UQP"			)
			Aadd(aItem, UQP->(Recno())	)
			Aadd(aItem, .F.				)

			// Adiciona o item à coleção de itens
			Aadd(aItens, aItem)

			UQP->(DbSkip())
		EndDo

		If !lVisual
			aCols := AClone(aItens)
		EndIf
	Else
		// Inicia a primeira linha vazia
		Aadd(aItem, cIniCpos)
		Aadd(aItem, CriaVar("UQP_TPFAT"	 , .T.))
		Aadd(aItem, CriaVar("UQP_PFXFAT" , .T.))
		Aadd(aItem, CriaVar("UQP_PARFAT" , .T.))
		Aadd(aItem, CriaVar("UQP_TITFAT" , .T.))
		Aadd(aItem, CriaVar("UQP_EMISFA" , .T.))
		Aadd(aItem, CriaVar("UQP_VLRFAT" , .T.))
		Aadd(aItem, CriaVar("UQP_ICMS"	 , .T.))
		Aadd(aItem, ""					       )
		Aadd(aItem, CriaVar("UQP_TIPO"	 , .T.))
		Aadd(aItem, CriaVar("UQP_PREFIX" , .T.))
		Aadd(aItem, CriaVar("UQP_TITULO" , .T.))
		Aadd(aItem, CriaVar("UQP_PARCEL" , .T.))
		Aadd(aItem, CriaVar("UQP_EMISSA" , .T.))
		Aadd(aItem, CriaVar("UQP_VALOR"	 , .T.))
		Aadd(aItem, CriaVar("UQP_TOTAL"	 , .T.))
		Aadd(aItem, "UQP"					   )
		Aadd(aItem, 0						   )
		Aadd(aItem, .F.						   )

		// Adiciona o item à coleção de itens
		Aadd(aItens, aItem)
	EndIf

	If lVisual
		// Seta o array e atualiza a GetDados
		oGetDados:SetArray(aItens)
		oGetDados:Refresh()

		// Expande a GetDados
		oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	EndIf

	RestArea(aAreaUQP)
	RestArea(aArea)

Return

/*/{Protheus.doc} fGetCTE
Exibe tela para seleção de arquivos CTE/CRT que irão compor a fatura.
@author Paulo Carvalho
@since 13/03/2019
@type function
/*/
Static Function fGetCTE()

	Local aArea			:= GetArea()
	Local aButtons		:= {}

	Local bEnchoice
	Local bOk			:= {|| fGrvCTE()}
	Local bCancel		:= {|| oDlgCTE:End()}
	Local bPesquisar	:= {|| fPesquisar()}

	Local lRet			:= .T.

	Private aHeaderUQD	:= {}

	Private cTitDialog	:= NomePrt + CAT518033 + VersaoJedi // #" - Seleção de Títulos - "

	Private cRumoDe		:= CriaVar("UQD_PARCEL")
	Private cRumoAte	:= CriaVar("UQD_PARCEL")

	Private dDtViagDe	:= CtoD("  /  /    ")
	Private dDtViagAte	:= CtoD("  /  /    ")
	Private dDtCTEDe	:= CtoD("  /  /    ")
	Private dDtCTEAte	:= CtoD("  /  /    ")

	Private oBtnPesq	:= Nil
	Private oDlgCTE		:= Nil
	Private oGDCTE		:= Nil

	Private oDtCTEDe	:= Nil
	Private oDtCTEAte	:= Nil
	Private oDtViagDe	:= Nil
	Private oDtViagAte	:= Nil

	Private nTitTop		:= 0
	Private nTitLeft	:= 0
	Private nTitBottom	:= 0
	Private nTitRight	:= 0

	Private oSizeTit	:= FWDefSize():New(.T.)

	If Empty(M->UQO_CLIENT) .Or. Empty(M->UQO_LOJA)
		MsgAlert(CAT518034, cTitDialog) // #"Informe o cliente e a loja para fatura antes de selecionar os CTE's/CTR's."
	Else
		// Define que os objetos não serão expostos lado a lado
		oSizeTit:lProp			:= .T.
		oSizeTit:lLateral		:= .F.

		// Adiciona ao objeto oSizeVis os objetos que irão compor a tela
		oSizeTit:AddObject("ENCHOICE"	, 100, 020, .T., .T.)
		oSizeTit:AddObject("GETDADOS"	, 100, 040, .T., .T.)

		// Define as coordenadas da Dialog principal
		nTitTop		:= oSizeTit:aWindSize[1]
		nTitLeft	:= oSizeTit:aWindSize[2]
		nTitBottom	:= oSizeTit:aWindSize[3]
		nTitRight	:= oSizeTit:aWindSize[4]

		// Realiza o cálculo das coordenadas
		oSize:Process()

		// Inicia a Dialog para seleção de títulos
		oDlgCTE 	:= MSDialog():New(000, 000, 400, 1000, cTitDialog, /*uParam6*/,/*uParam7*/,;
									/*uParam8*/, /*uParam9*/, /*nClrText*/,	/*nClrBack*/,;
									/*uParam12*/, oDialog, lPixel /*uParam15*/,	/*uParam15*/,;
									/*uParam16*/, /*uParam17*/, !lTransparent)

		// Inicia a montagem do painel de filtros
		oDtViagDe	:= TGet():New( 	035, 005, {|u| IIf( Pcount() > 0, dDtViagDe := u, dDtViagDe)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDtViagDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518035, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Data Viagem de"
									!lPicturePiority, lFocSel )

		oDtViagAte	:= TGet():New( 	035, 070, {|u| IIf( Pcount() > 0, dDtViagAte := u, dDtViagAte)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDtViagAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518036, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Data Viagem até"
									!lPicturePiority, lFocSel )

		oDtCTEDe	:= TGet():New( 	035, 135, {|u| IIf( Pcount() > 0, dDtCTEDe := u, dDtCTEDe)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDtCTEDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518037, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Data CTE de"
									!lPicturePiority, lFocSel )

		oDtCTEAte	:= TGet():New( 	035, 200, {|u| IIf( Pcount() > 0, dDtCTEAte := u, dDtCTEAte)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDtCTEAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518038, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Data CTE até"
									!lPicturePiority, lFocSel )
		oRumoDe		:= TGet():New( 	035, 265, {|u| IIf( Pcount() > 0, cRumoDe := u, cRumoDe)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "cRumoDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518086, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Rumo de"
									!lPicturePiority, lFocSel )

		oRumoAte	:= TGet():New( 	035, 330, {|u| IIf( Pcount() > 0, cRumoAte := u, cRumoAte)}, oDlgCTE, 060, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "cRumoAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518087, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; // #"Rumo até"
									!lPicturePiority, lFocSel )

		oBtnPesq	:= TButton():New(041, 440, CAT518004, oDlgCTE, bPesquisar, 050, 015,; // #"Pesquisar"
									/*uParam8*/, /*oFont*/, /*uParam10*/, lPixel, /*uParam12*/, /*uParam13*/,;
									/*uParam14*/, /*bWhen*/, /*uParam16*/, /*uParam17*/	)

		// Cria a GetDados para seleção de títulos
		fGdCTE()

		// Define os botões da EnchoiceBar
		Aadd( aButtons, { "", {|| fSetCheck(1)}, CAT518039 	} )	// #"Marcar todos"
		Aadd( aButtons, { "", {|| fSetCheck(2)}, CAT518040 	} )	// #"Desmarcar todos"
		Aadd( aButtons, { "", {|| fSetCheck(3)}, CAT518041	} )	// #"Inverter seleção"

		// Define EnchoiceBar
		bEnchoice 	:= {|| 	EnchoiceBar( oDlgCTE, bOk, bCancel, .F., aButtons, /*nRecno*/,;
							/*cAlias*/, .F., .F., .F., lHasOk, .F., ) }


		// Ativa a Dialog para visualização de log de registros
		oDlgCTE:Activate(/*uParam1*/, /*uParam2*/, /*uParam3*/, lCentered,;
							/*bValid*/,/*uParam6*/, bEnchoice, /*uParam8*/, /*uParam9*/	)
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fGdCTE
Cria a GetDados de seleção dos arquivos CTE/CRT.
@author Paulo Carvalho
@since 13/03/2019
@type function
/*/
Static Function fGdCTE()

	Local aArea		:= GetArea()
	Local aArraySE1	:= {}
	Local aCampos	:= {}

	Local nH, nI, nJ

	// Define os campos da GetDados manualmente.
	Aadd(aCampos, "UQD_TIPOTI"	)
	Aadd(aCampos, "UQD_PREFIX"	)
	Aadd(aCampos, "UQD_TITULO"	)
	Aadd(aCampos, "UQD_PARCEL"	)
	Aadd(aCampos, "UQD_NUMERO"	)
	Aadd(aCampos, "UQD_EMISSA"	)
	Aadd(aCampos, "UQD_VALOR"	)
	Aadd(aCampos, "UQD_ICMS"	)

	// Adiciona o campo check para seleção do título
	fAddCheck(@aHeaderUQD)

	// Adiciona os campos no aHeader
	For nI := 1 To Len(aCampos)
		fAddHeader(@aHeaderUQD, aCampos[nI])
	Next

	// Adiciona o Alias e o Recno
	AdHeadRec("UQD", aHeaderUQD)

	// Popula o array com dados inicias em branco.
	Aadd(aArraySE1, oNo)

	For nJ := 2 To Len(aHeaderUQD) - 2
		Aadd(aArraySE1, CriaVar(aHeaderUQD[nJ][2], .T.))
	Next

	Aadd( aArraySE1, "UQD"	) // Alias WT
	Aadd( aArraySE1, 0 		) // Recno WT
	Aadd( aArraySE1, .F. 	) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 2 to Len(aHeaderUQD) - 2
		If Empty(aHeaderUQD[nH][3]) .And. aHeaderUQD[nH][8] == "C"
			aHeaderUQD[nH][3] := "@!"
		EndIf
	Next

	// Instancia a GetDados de seleção dos títulos
	oGDCTE   := MsNewGetDados():New(	060, 000, 195, 495, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, /*aAlter*/, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oDlgCTE, aHeaderUQD, {aArraySE1}, /*bChange*/, /*cTela*/	)

	oGDCTE:oBrowse:bLDblClick := {|| fCheck(), oGDCTE:oBrowse:Refresh()}

	//-- Cria as variáveis de posição
	fCria_nPos()

	// Impede a edição de linha
	oGDCTE:SetEditLine(.F.)

	// Atualiza a GetDados
	oGDCTE:Refresh()

	RestArea(aArea)

Return

/*/{Protheus.doc} fPesquisar
Preenche a GetDados de arquivos CTE/CRT de acordo com os filtros.
@author Paulo Carvalho
@since 13/03/2019
@type function
/*/
Static Function fPesquisar()

	Local aArea		:= GetArea()
	Local aDados	:= {}
	Local aLinha	:= {}
	Local aSels		:= {}	// Armazena o número dos títulos já selecionados na tabela UQO
	Local aTitulos	:= oGetDados:aCols

	Local cAliasQry	:= GetNextAlias()
	Local cQuery	:= ""

	Local nI, nJ, nK

	For nJ := 1 To Len(aTitulos)
		// Verifica se o campo não está vazio
		If !Empty(aTitulos[nJ][nPsUQPTtFat])
			Aadd(aSels, aTitulos[nJ][nPsUQPTtFat])
		EndIf
	Next

	cQuery	+= "SELECT 	UQD.UQD_FILIAL, UQD.UQD_NUMERO, UQD.UQD_EMISSA, UQD.UQD_VALOR, "	+ CRLF
	cQuery	+= "		UQD.UQD_PREFIX, UQD.UQD_TITULO, UQD.UQD_TIPOTI, " 					+ CRLF
	cQuery	+= "		UQD.UQD_PARCEL, " 													+ CRLF
	cQuery	+= "		UQD.UQD_ICMS, UQD.UQD_VIAGEM, UQD.UQD_CLIENT, UQD.UQD_LOJACL, "		+ CRLF
	cQuery	+= "		SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, "		+ CRLF
	cQuery	+= "		SE1.E1_TIPO, SE1.E1_BAIXA, UQD.R_E_C_N_O_ AS RECNOUQD  "			+ CRLF
	cQuery	+= "FROM	" 		+ RetSQLName("UQD") + " AS UQD "							+ CRLF
	cQuery	+= "INNER JOIN " 	+ RetSQLName("SE1") + " AS SE1 "							+ CRLF
	cQuery	+= "	ON	SE1.E1_FILIAL = '" + FWxFilial("SE1") + "' "						+ CRLF
	cQuery	+= "	AND	UQD.UQD_CLIENT = SE1.E1_CLIENTE "									+ CRLF
	cQuery	+= "	AND	UQD.UQD_LOJACL = SE1.E1_LOJA "	    								+ CRLF
	cQuery	+= "	AND	UQD.UQD_PREFIX = SE1.E1_PREFIXO "									+ CRLF
	cQuery	+= "	AND	UQD.UQD_TITULO = SE1.E1_NUM "										+ CRLF
	cQuery	+= "	AND	UQD.UQD_PARCEL = SE1.E1_PARCELA "									+ CRLF
	cQuery	+= "	AND	UQD.UQD_TIPOTI = SE1.E1_TIPO "										+ CRLF
	cQuery	+= "	AND	SE1.E1_BAIXA = '" + Space(TamSX3("E1_BAIXA")[1]) + "' "				+ CRLF
	cQuery	+= "	AND	SE1.E1_SALDO = SE1.E1_VALOR "										+ CRLF
	cQuery	+= "	AND	SE1.E1_XIDFAT = '" + Space(TamSX3("E1_XIDFAT")[1]) + "' "			+ CRLF
	cQuery	+= "	AND	SE1.D_E_L_E_T_ <> '*' "												+ CRLF
	cQuery	+= "WHERE	UQD.UQD_FILIAL = '" 		+ FWxFilial("UQD") 	+ "' "				+ CRLF
	cQuery	+= "AND		UQD.UQD_STATUS = 'P' "												+ CRLF

	If !Empty(M->UQO_CLIENT)
		cQuery	+= "AND		UQD.UQD_CLIENT = '" 	+ M->UQO_CLIENT		+ "' "				+ CRLF
	EndIf

	If !Empty(M->UQO_LOJA)
		cQuery	+= "AND		UQD.UQD_LOJACL = '"		+ M->UQO_LOJA		+ "' "				+ CRLF
	EndIf

	If !Empty(dDtViagDe)
		cQuery	+= "AND		UQD.UQD_VIAGEM >= '" 	+ DtoS(dDtViagDe) 	+ "' "				+ CRLF
	EndIf

	If !Empty(dDtViagAte)
		cQuery	+= "AND		UQD.UQD_VIAGEM <= '" 	+ DtoS(dDtViagAte) 	+ "' "				+ CRLF
	EndIf

	If !Empty(dDtCTEDe)
		cQuery	+= "AND		UQD.UQD_EMISSA >= '" 	+ DtoS(dDtCTEDe) 		+ "' "			+ CRLF
	EndIf

	If !Empty(dDtCTEAte)
		cQuery	+= "AND		UQD.UQD_EMISSA <= '" 	+ DtoS(dDtCTEAte) 		+ "' "			+ CRLF
	EndIf

	If !Empty(cRumoDe)
		cQuery	+= "AND		UQD.UQD_PARCEL >= '" 	+ cRumoDe				+ "' "			+ CRLF
	EndIf

	If !Empty(cRumoAte)
		cQuery	+= "AND		UQD.UQD_PARCEL <= '" 	+ cRumoAte				+ "' "			+ CRLF
	EndIf

	// Se já houverem sido selecionados títulos
	If !Empty(aSels)
		cQuery += "AND	UQD.UQD_TITULO NOT IN ( "

		For nK := 1 To Len(aSels)
			If nK <> Len(aSels)
				cQuery += "'" + aSels[nK] + "', "
			Else
				cQuery += "'" + aSels[nK] + "' "
			EndIf
		Next

		cQuery += ") "	+ CRLF
	EndIf

//	cQuery	+= "AND		UQD.UQD_STATUS <> 'R' "											+ CRLF
	cQuery	+= "AND		UQD.D_E_L_E_T_ <> '*' "											+ CRLF
	cQuery	+= "ORDER BY    UQD.R_E_C_N_O_ "   											+ CRLF

	// Abre o cursor sob o alias cAliasQry
	DbUseArea(.T., 'TOPCONN', TCGenQry( , , cQuery ), cAliasQry, .F., .T.)

	// Define tratamento de tipos implícitos nas colunas de retorno da query
	// Tipos: (D) Data, (L) Lógico e (N) Numérico
	TCSetField(cAliasQry, "E1_BAIXA", TamSX3("E1_BAIXA")[3], TamSX3("E1_BAIXA")[1], TamSX3("E1_BAIXA")[2])
	TCSetField(cAliasQry, "UQD_EMISSA", TamSX3("UQD_EMISSA")[3], TamSX3("UQD_EMISSA")[1], TamSX3("UQD_EMISSA")[2])
	TCSetField(cAliasQry, "UQD_VALOR", TamSX3("UQD_VALOR")[3], TamSX3("UQD_VALOR")[1], TamSX3("UQD_VALOR")[2])
	TCSetField(cAliasQry, "UQD_ICMS", TamSX3("UQD_ICMS")[3], TamSX3("UQD_ICMS")[1], TamSX3("UQD_ICMS")[2])

	While !(cAliasQry)->(Eof())
		// Reinicia a linha a cada iteração
		aLinha := {}

		// Inicia como marcado para seleção
		Aadd(aLinha, oNo					)
		Aadd(aLinha, (cAliasQry)->UQD_TIPOTI)
		Aadd(aLinha, (cAliasQry)->UQD_PREFIX)
		Aadd(aLinha, (cAliasQry)->UQD_TITULO	)
		Aadd(aLinha, (cAliasQry)->UQD_PARCEL)
		Aadd(aLinha, (cAliasQry)->UQD_NUMERO	)
		Aadd(aLinha, (cAliasQry)->UQD_EMISSA)
		Aadd(aLinha, (cAliasQry)->UQD_VALOR	)
		Aadd(aLinha, (cAliasQry)->UQD_ICMS	)
		Aadd(aLinha, "UQD"					)
		Aadd(aLinha, (cAliasQry)->RECNOUQD	)
		Aadd(aLinha, .F.					)

		// Adiciona ao array de Dados
		Aadd(aDados, aLinha)

		(cAliasQry)->(DbSKip())
	EndDo

	fFechaTab(cAliasQry)

	// Caso não tenha encontrado nenhum dado
	If Empty(aDados)
		// Preenche a GetDados vazia
		Aadd( aLinha, oNo )

		// Popula o array com dados em branco.
		For nI := 2 To Len( aHeaderUQD ) - 2
			Aadd( aLinha, CriaVar( aHeaderUQD[nI][2], .T. ) )
		Next

		Aadd( aLinha, "UQD"	) // Alias WT
		Aadd( aLinha, 0		) // Recno WT
		Aadd( aLinha, .F. 	) // D_E_L_E_T_

		Aadd(aDados, aLinha)

		// E informa que não foram encontrados registros
		MsgAlert(CAT518042, cTitDialog) // #"Nenhum registro encontrado."
	Else
		// --------------------------------------------------
		// Ajusta o valor dos títulos removendo os impostos
		// --------------------------------------------------
		For nI := 1 To Len(aDados)
			aDados[nI,nPsUQDValor] := fGetValTit(aDados[nI,nPsUQDPrefix], aDados[nI,nPsUQDTit], aDados[nI,nPsUQDParc], aDados[nI,nPsUQDTipo], M->UQO_CLIENT, M->UQO_LOJA, aDados[nI,nPsUQDValor])
		Next nI
	EndIf

	RestArea(aArea)

	// Define array aDados como aCols da GetDados
	oGDCTE:SetArray(aDados)

	// Seleciona todos
	fSetCheck(1)

	// Atualiza a GetDados
	oGDCTE:Refresh()

Return

/*/{Protheus.doc} fGrvCTE
Grava os arquivos CTE/CRT selecionados pelo usuário.
@author Paulo Carvalho
@since 14/03/2019
@type function
/*/
Static Function fGrvCTE()

	Local aArea			:= GetArea()
	Local aGetDadUQP	:= oGetDados:aCols
	Local aGetDadUQD	:= oGDCTE:aCols

	Local aLinha		:= {}

	Local cChaveSF2		:= ""
	Local cItem			:= ""
	Local cNota			:= ""
	Local cSerie		:= ""
	Local cParcela		:= ""

	Local nI
	Local nIcms			:= 0
	Local nTotGeral		:= 0
	Local nTotLinha		:= 0
	Local nUltLinha		:= Len(aGetDadUQP)
	Local nTamArray		:= (nUltLinha - 1)

	// Reinicia o aCols da UQP caso estiver vázio
	If Empty(aGetDadUQP[1][nPsUQPTtFat])
		cItem 		:= "000"
		aGetDadUQP 	:= {}
	Else
		cItem := aGetDadUQP[Len(aGetDadUQP)][nPsUQPItem]
	EndIf

	// Se a GetDados já estiver preenchida
	If nUltLinha > 1
		// Retira linhas em branco do array
		If 	Empty(aGetDadUQP[nUltLinha][nPsUQPTtFat]) .And.;
			Empty(aGetDadUQP[nUltLinha][nPsUQPTtFat]) .And.;
			Empty(aGetDadUQP[nUltLinha][nPsUQPTit])

			// Deleta a última linha
			ADel(aGetDadUQP, nUltLinha)

			// Reorganiza o array
			ASize(aGetDadUQP, nTamArray)
		EndIf
	EndIf

	// Adiciona toda as linhas selecionadas ao array aSels
	For nI := 1 To Len(aGetDadUQD)
		// Reinica o array aLinha
		aLinha := {}

		// Se o arquivo foi selecionado
		If aGetDadUQD[nI][nPsUQDCheck]:cName == "LBOK"
			cItem := Soma1(cItem)

			cNota	:= AllTrim(aGetDadUQD[nI][nPsUQDTit])
			cSerie 	:= AllTrim(SubStr(aGetDadUQD[nI][nPsUQDCte],;
						RAT("-", aGetDadUQD[nI][nPsUQDCte])+1))

			cParcela := cSerie

			cChaveSF2 	:= FWxFilial("SF2")
			cChaveSF2 	+= PadR(cNota, TamSX3("F2_DOC")[1])
			cChaveSF2 	+= PadR(cSerie, TamSX3("F2_SERIE")[1])
			cChaveSF2 	+= PadR(M->UQO_CLIENT, TamSX3("F2_CLIENTE")[1])
			cChaveSF2 	+= PadR(M->UQO_LOJA, TamSX3("F2_LOJA")[1])

			//Coforme solicitado por Gustavo em 22/04, não deve ter valor de icms discriminado no valor
			//da fatura, sendo apenas apresentado no valor total
			nIcms := 0 // Posicione("SF2", 1, cChaveSF2, "F2_VALICM")

			// Soma o total da linha
			nTotLinha := aGetDadUQD[nI][nPsUQDValor] + nIcms

			Aadd(aLinha, cItem						)
			Aadd(aLinha, aGetDadUQD[nI][nPsUQDTipo]	)
			Aadd(aLinha, aGetDadUQD[nI][nPsUQDPrefix])
			Aadd(aLinha, cParcela					)
			Aadd(aLinha, aGetDadUQD[nI][nPsUQDTit]	)
			Aadd(aLinha, aGetDadUQD[nI][nPsUQDEmiss]	)
			Aadd(aLinha, aGetDadUQD[nI][nPsUQDValor]	)
			Aadd(aLinha, nIcms						)
			Aadd(aLinha, ""							)
			Aadd(aLinha, CriaVar("UQP_TIPO", .T.) 	)
			Aadd(aLinha, CriaVar("UQP_PREFIX", .T.)	)
			Aadd(aLinha, CriaVar("UQP_TITULO", .T.) 	)
			Aadd(aLinha, CriaVar("UQP_PARCEL", .T.)	)
			Aadd(aLinha, CtoD("  /  /    ")			)
			Aadd(aLinha, CriaVar("UQP_VALOR", .T.) 	)
			Aadd(aLinha, nTotLinha					)
			Aadd(aLinha, "UQP" 						)
			Aadd(aLinha, 0							)
			Aadd(aLinha, .F. 						)

			// Realiza a soma dos valores dos arquivos selecionados
			nTotGeral += nTotLinha

			// Adiciona a linha ao array principal
			Aadd(aGetDadUQP, aLinha)
		EndIf
	Next

	If Empty(aGetDadUQP)
		MsgAlert(CAT518043, cTitDialog) // #"Nenhum registro selecionado."
	Else
		// Insere o novo aCols à GetDados
		oGetDados:SetArray(aGetDadUQP)

		// Atualiza GetDados
		oGetDados:Refresh()

		// Atualiza o total da fatura
		nTotalFat += nTotGeral
	EndIf

	// Fecha a Dialog de seleção
	oDlgCTE:End()

	// Reorganiza os itens na GetDados
	fOrgItens()

	RestArea(aArea)

Return

/*/{Protheus.doc} fValidCli
Valida o cliente informado pelo usuário e preenche o campo UQO_NOMECL.
@author Paulo Carvalho
@since 19/03/2019
@type function
/*/
Static Function fValidCli()

	Local aArea			:= GetArea()
	Local aAreaSA1		:= SA1->(GetArea())
	Local aVencto		:= {}

	Local cLoja			:= ""

	Local lValid		:= .T.

	Local nVlrFict		:= 10		// Valor ficticio para execução da função Condicao
	Local nI			:= 0

	Private lPrimeira	:= .T.

	If !Empty(c518Cli) .And. !Empty(c518Loja)
		If c518Cli != M->UQO_CLIENT .Or. c518Loja != M->UQO_LOJA
			For nI := 1 to Len(oGetDados:aCols)
				If !Empty(oGetDados:aCols[nI,nPsUQPTtFat]) .And. !oGetDados:aCols[nI,nPsUQPDel]
					lValid := .F.

					MsgAlert(CAT518044 + AllTrim(M->UQO_NOMECL) + "." + CRLF + CAT518045, cCadastro) // #"Títulos já informados para o cliente ", #"Não é possível alterar o cliente."

					Exit
				EndIf
			Next nI
		EndIf
	EndIf

	If lValid
		If !Empty(M->UQO_CLIENT) .And. Empty(M->UQO_LOJA)
			// Verifica se o cliente é um retorno da consulta padrão
			If M->UQO_CLIENT == SA1->A1_COD
				cLoja := SA1->A1_LOJA
			Else
				// Posiciona no cliente informado para recuperar a razão social.
				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))	// A1_FILIAL + A1_COD + A1_LOJA
			EndIf

			If SA1->(DbSeek(FWxFilial("SA1") + M->UQO_CLIENT + cLoja))
				M->UQO_LOJA	 	:= SA1->A1_LOJA
				M->UQO_NOMECL 	:= SA1->A1_NOME
			Else
				lValid := .F.
				MsgAlert(CAT518046, cCadastro) // #"O cliente informado não está cadastrado no sistema."
			EndIf
		ElseIf !Empty(M->UQO_CLIENT) .And. !Empty(M->UQO_LOJA)
			// Posiciona no cliente informado para recuperar a razão social e a observação.
			DbSelectArea("SA1")
			SA1->(DbSetOrder(1))	// A1_FILIAL + A1_COD + A1_LOJA

			If SA1->(DbSeek(FWxFilial("SA1") + M->UQO_CLIENT + M->UQO_LOJA))
				M->UQO_LOJA	 	:= SA1->A1_LOJA
				M->UQO_NOMECL 	:= SA1->A1_NOME

				// Define a obsersação do cliente como sugestão para a fatura.
				If !Empty(oTGObs) //caso seja integração, a variável não terá sido inicializada
					fGetObs()
				EndIf

				// Verifica se o cliente possui uma condição de pagamento vinculada
				If !Empty(SA1->A1_COND)
					aVencto := Condicao(nVlrFict, SA1->A1_COND, , M->UQO_EMISSA)

					M->UQO_VENCTO := DataValida(aVencto[1][1])

					c518Cli  := SA1->A1_COD
					c518Loja := SA1->A1_LOJA
				Else
					MsgAlert(CAT518047 + M->UQO_NOMECL + CAT518048, cCadastro) // #"O cliente ", #" não possui condição de pagamento vinculada em seu cadastro. Digite manualmente a data de vencimento da fatura."
				EndIf
			Else
				lValid := .F.
				MsgAlert(CAT518046, cCadastro) // #"O cliente informado não está cadastrado no sistema."
			EndIf
		ElseIf Empty(M->UQO_CLIENT) .And. Empty(M->UQO_LOJA)
			lValid := .F.
			MsgAlert(CAT518049, cCadastro) // #"Informe o código e a loja do cliente."
		EndIf

		If !lValid
			MsgAlert(CAT518049, cCadastro) // #"Informe o código e a loja do cliente."
		EndIf
	EndIf

	RestArea(aAreaSA1)
	RestArea(aArea)

Return(lValid)

/*/{Protheus.doc} fVldData
Realiza a validação entre as datas de emissão e vencimento.
@author Paulo Carvalho
@since 04/04/2019
@type function
/*/
Static Function fVldData()

	Local aArea		:= GetArea()
	Local lValid	:= .T.

	If !Empty(M->UQO_EMISSA) .And. !Empty(M->UQO_VENCTO)
		If M->UQO_EMISSA > M->UQO_VENCTO
			lValid := .F.
			MsgAlert(CAT518050, cCadastro) // #"A data de vencimento não pode ser menor do que a data de emissão da fatura."
		EndIf
	EndIf

	// ---------------------------------------------------------------------------------------------------------------------------------
	// Em caso de alteração da emissão e os campos de cliente, loja e data de vencimento já estiverem preenchidos, então chama
	// a função fValidCli que irá calcular novamente a data de vencimento conforme a condição de pagamento do cliente
	// ---------------------------------------------------------------------------------------------------------------------------------
	If lValid
		If ReadVar() == "M->UQO_EMISSA"
			If !Empty(M->UQO_CLIENT) .And. !Empty(M->UQO_LOJA) .And. !Empty(M->UQO_VENCTO)
				lValid := fValidCli()
			Endif
		EndIf
	EndIf

	RestArea(aArea)

Return lValid

/*/{Protheus.doc} fGetObs
Define a observação da fatura de acordo com o cadastro do cliente.
@author Paulo Carvalho
@since 01/04/2019
@type function
/*/
Static Function fGetObs()

	Local aArea			:= GetArea()

	If "SA1" $ Alias()
		// Define o texto com o conteúdo do campo A1_XOBSFAT
		oTGObs:VarPut(SA1->A1_XOBSFAT)
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc} fVldTitFat
Valida o título informado para a fatura e executa gatilho nos campos necessários.
@author Paulo Carvalho
@since 15/03/2019
@type function
/*/
Static Function fVldTitFat()

	Local aArea			:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())
	Local aTCSetField	:= {}
	Local aTam			:= {}

	Local cAliasQry		:= GetNextAlias()
	Local cChaveSF2		:= ""
	Local cParcela		:= ""
	Local cPrefixo		:= ""
	Local cNota			:= ""
	Local cSerie		:= ""
	Local cTipo			:= ""
	Local cTitulo		:= ""
	Local cQuery		:= ""

	Local dEmissao		:= CtoD("  /  /    ")

	Local lRet			:= .T.
	Local lContinua		:= .T.

	Local nI			:= oGetDados:nAt
	Local nH			:= 0
//	Local nJ
	Local nIcms			:= 0
	Local nValor		:= 0

	// Verifica se o campo de título não está vázio
	If !Empty(M->UQP_TITFAT)
		// Verifica se o título é um retorno da consulta padrão
		If M->UQP_TITFAT == SE1->E1_NUM
			cTipo		:= SE1->E1_TIPO
			cPrefixo	:= SE1->E1_PREFIXO
			cTitulo		:= SE1->E1_NUM
			cParcela	:= SE1->E1_PARCELA
			dEmissao 	:= SE1->E1_EMISSAO
			nValor 		:= SE1->E1_VALOR
		Else
			// Define a query de pesquisa do título para o cliente da fatura
			cQuery	+= "SELECT	SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA,"	+ CRLF
			cQuery	+= "		SE1.E1_TIPO, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_EMISSAO,"	+ CRLF
			cQuery	+= "		SE1.E1_VALOR"												+ CRLF
			cQuery	+= "FROM	" + RetSQLName("SE1") + " AS SE1 "							+ CRLF
			cQuery	+= "WHERE	SE1.E1_FILIAL = '" 	+ FWxFilial("SE1") 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_CLIENTE = '" + M->UQO_CLIENT 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_LOJA = '" 	+ M->UQO_LOJA	 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_NUM = '" 	+ M->UQP_TITFAT 		+ "' "				+ CRLF
			cQuery	+= "AND		SE1.D_E_L_E_T_ <> '*' "										+ CRLF

			// Define o campos que devem passar pela função TCSetField
			aTam := TamSX3("E1_EMISSAO") ; Aadd( aTCSetField, { "E1_EMISSAO", aTam[3], aTam[1], aTam[2]	} )
			aTam := TamSX3("E1_VALOR"  ) ; Aadd( aTCSetField, { "E1_VALOR"  , aTam[3], aTam[1], aTam[2]	} )

			// Fecha a área de trabalho para nova pesquisa
			fFechaTab(cAliasQry)

			// Cria área de trabalho a partir da query definida
			MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

			// Se houver arquivos
			If !(cAliasQry)->(Eof())
				// Alimenta as variáveis referentes ao título
				cTipo		:= (cAliasQry)->E1_TIPO
				cPrefixo	:= (cAliasQry)->E1_PREFIXO
				cTitulo		:= (cAliasQry)->E1_NUM
				cParcela	:= (cAliasQry)->E1_PARCELA
				dEmissao 	:= (cAliasQry)->E1_EMISSAO
				nValor 		:= (cAliasQry)->E1_VALOR
			Else
				lContinua 		:= .F.
				M->UQP_TITFAT    := ""

				oGetDados:aCols[nI][nPsUQPTpFat]	:= CriaVar("UQP_TPFAT")
				oGetDados:aCols[nI][nPsUQPPfFat]	:= CriaVar("UQP_PFXFAT")
				oGetDados:aCols[nI][nPsUQPTtFat]	:= CriaVar("UQP_TITFAT")
				oGetDados:aCols[nI][nPsUQPPcFat]	:= CriaVar("UQP_PARFAT")
				oGetDados:aCols[nI][nPsUQPEmFat]	:= CtoD("  /  /    ")

				If Empty(oGetDados:aCols[nI][nPsUQPTit])
					oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
				EndIf

				oGetDados:aCols[nI][nPsUQPVlFat]	:= CriaVar("UQP_VLRFAT")
				oGetDados:aCols[nI][nPsUQPIcms]	:= CriaVar("UQP_ICMS")

				MsgAlert(CAT518051, cCadastro) //#"Título não encontrado para este cliente e loja."
			EndIf
		EndIf

		// Se encontrou o título
		If lContinua
			// Reinicia a variável para nova pesquisa
			cQuery 		:= ""
			aTCSetField := {}

			aTam := TamSX3("UQD_EMISSA") ; Aadd( aTCSetField, { "UQD_EMISSA", aTam[3], aTam[1], aTam[2]	} )
			aTam := TamSX3("UQD_VALOR"  ) ; Aadd( aTCSetField, { "UQD_VALOR"  , aTam[3], aTam[1], aTam[2]	} )
			aTam := TamSX3("UQD_ICMS"   ) ; Aadd( aTCSetField, { "UQD_ICMS"   , aTam[3], aTam[1], aTam[2]	} )

			// Fecha a área de trabalho para nova pesquisa
			fFechaTab(cAliasQry)

			// Verifica se existe um arquivo CTE/CRT vinculado ao título encontrado
			cQuery	+= "SELECT	UQD.UQD_FILIAL, UQD.UQD_NUMERO, UQD.UQD_EMISSA, "	+ CRLF
			cQuery	+= "		UQD.UQD_PREFIX, UQD.UQD_TITULO, UQD.UQD_PARCEL,"	+ CRLF
			cQuery	+= "		UQD.UQD_TIPOTI, UQD.UQD_VALOR, UQD.UQD_ICMS"		+ CRLF
			cQuery	+= "FROM	" + RetSQLName("UQD") + " AS UQD " 				+ CRLF
			cQuery	+= "WHERE	UQD.UQD_FILIAL = '" 	+ FWxFilial("UQD") + "' "	+ CRLF
			cQuery	+= "AND		UQD.UQD_PREFIX = '" + cPrefixo 	+ "' "			+ CRLF
			cQuery	+= "AND		UQD.UQD_TITULO = '" 	+ cTitulo 	+ "' "			+ CRLF
			cQuery	+= "AND		UQD.UQD_PARCEL = '" + cParcela 	+ "' "			+ CRLF
			cQuery	+= "AND		UQD.UQD_TIPOTI = '"	+ cTipo 	+ "' "			+ CRLF
			cQuery	+= "AND		UQD.UQD_STATUS = 'P' "							+ CRLF
			cQuery	+= "AND		UQD.D_E_L_E_T_ <> '*' "							+ CRLF

			// Cria área de trabalho a partir da query definida
			MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

			// Se encontrar um arquivo CTE/CRT
			If !(cAliasQry)->(Eof())
				cNota	:= AllTrim((cAliasQry)->UQD_TITULO)
				cSerie 	:= AllTrim(SubStr((cAliasQry)->UQD_NUMERO,;
					RAT("-", (cAliasQry)->UQD_NUMERO) + 1))

				cChaveSF2 	:= FWxFilial("SF2")
				cChaveSF2 	+= PadR(cNota, TamSX3("F2_DOC")[1])
				cChaveSF2 	+= PadR(cSerie, TamSX3("F2_SERIE")[1])
				cChaveSF2 	+= PadR(M->UQO_CLIENT, TamSX3("F2_CLIENTE")[1])
				cChaveSF2 	+= PadR(M->UQO_LOJA, TamSX3("F2_LOJA")[1])

				dEmissao 	:= (cAliasQry)->UQD_EMISSA
				nValor 		:= (cAliasQry)->UQD_VALOR
				//Coforme solicitado por Gustavo em 22/04, não deve ter valor de icms discriminado no valor
				//da fatura, sendo apenas apresentado no valor total
				nIcms 		:= 0 //Posicione("SF2", 1, cChaveSF2, "F2_VALICM")
			EndIf

			// Verifica se o título selecionado já não foi selecionado anteriormente
			AEval(oGetDados:aCols, {|x| nH++,;
										IIf(nH <> nI .And.;
											x[nPsUQPTpFat] == cTipo .And.;
											x[nPsUQPPfFat] == cPrefixo .And.;
											x[nPsUQPTtFat] == cTitulo .And.;
											x[nPsUQPPcFat] == cParcela, lContinua := .F., Nil)})

			// Verifica se o título selecionado já não foi selecionado anteriormente no bloco 2
			AEval(oGetDados:aCols, {|x| nH++,;
										IIf(nH <> nI .And.;
											x[nPsUQPTipo]	== cTipo .And.;
											x[nPsUQPPref] 	== cPrefixo .And.;
											x[nPsUQPTit] 	== cTitulo .And.;
											x[nPsUQPParc] 	== cParcela, lContinua := .F., Nil)})

			If lContinua
				// Verifica se o título seleciona compõe outra fatura
				If fCompoeFat(cPrefixo, cTitulo,;
					cParcela, cTipo)

					// Falsifica o retorno da consulta e limpa a variável de memória.
					lRet            := .F.
					M->UQP_TITFAT    := ""

					// Zera as informações da linha
					oGetDados:aCols[nI][nPsUQPTpFat]	:= CriaVar("UQP_TPFAT")
					oGetDados:aCols[nI][nPsUQPPfFat]	:= CriaVar("UQP_PFXFAT")
					oGetDados:aCols[nI][nPsUQPTtFat]	:= CriaVar("UQP_TITFAT")
					oGetDados:aCols[nI][nPsUQPPcFat]	:= CriaVar("UQP_PARFAT")
					oGetDados:aCols[nI][nPsUQPEmFat]	:= CtoD("  /  /    ")

					If Empty(oGetDados:aCols[nI][nPsUQPTit])
						oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
					EndIf

					oGetDados:aCols[nI][nPsUQPVlFat]	:= CriaVar("UQP_VLRFAT")
					oGetDados:aCols[nI][nPsUQPIcms]	:= CriaVar("UQP_ICMS")

					MsgAlert(CAT518052, cCadastro) // #"O título selecionado compõe outra fatura."
				Else
					// Verifica se houve uma troca de título
					If M->UQP_TITFAT <> oGetDados:aCols[nI][nPsUQPTtFat]
						// Desvincula o título anterior
						fDesTitulo(oGetDados:aCols[nI][nPsUQPPfFat],;
								oGetDados:aCols[nI][nPsUQPTtFat],;
								oGetDados:aCols[nI][nPsUQPPcFat],;
								oGetDados:aCols[nI][nPsUQPTpFat])
					EndIf

					// Vinculo o título a fatura
					//Função comentada dia 17/10/2019 - Icaro
					//Ela estava gravando o campo E1_XIDFAT ANTES da confirmação da gravação
					//fVinTitulo(cPrefixo, cTitulo, cParcela, cTipo)

					// Preenche os campos com as informações referentes ao arquivo selecionado
					oGetDados:aCols[nI][nPsUQPTpFat]	:= cTipo
					oGetDados:aCols[nI][nPsUQPPfFat]	:= cPrefixo
					oGetDados:aCols[nI][nPsUQPTtFat]	:= cTitulo
					oGetDados:aCols[nI][nPsUQPPcFat]	:= cParcela
					oGetDados:aCols[nI][nPsUQPEmFat]	:= dEmissao
					oGetDados:aCols[nI][nPsUQPEmFat]	:= dEmissao

					If Empty(oGetDados:aCols[nI][nPsUQPTit])
						oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
					EndIf

					oGetDados:aCols[nI][nPsUQPVlFat]	:= fGetValTit(cPrefixo, cTitulo, cParcela, cTipo, M->UQO_CLIENT, M->UQO_LOJA, nValor)
					oGetDados:aCols[nI][nPsUQPIcms]	:= IIf(Empty(nIcms), CriaVar("UQP_ICMS"), nIcms)
				EndIf
			Else
				// Falsifica o retorno da consulta e limpa a variável de memória.
				M->UQP_TITFAT    := ""

				// Zera as informações da linha
				oGetDados:aCols[nI][nPsUQPTpFat]	:= CriaVar("UQP_TPFAT")
				oGetDados:aCols[nI][nPsUQPPfFat]	:= CriaVar("UQP_PFXFAT")
				oGetDados:aCols[nI][nPsUQPTtFat]	:= CriaVar("UQP_TITFAT")
				oGetDados:aCols[nI][nPsUQPPcFat]	:= CriaVar("UQP_PARFAT")
				oGetDados:aCols[nI][nPsUQPEmFat]	:= CtoD("  /  /    ")

				If Empty(oGetDados:aCols[nI][nPsUQPTit])
					oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
				EndIf

				oGetDados:aCols[nI][nPsUQPVlFat]	:= CriaVar("UQP_VLRFAT")
				oGetDados:aCols[nI][nPsUQPIcms]	:= CriaVar("UQP_ICMS")

				MsgAlert(CAT518053, cCadastro) // #"O título selecionado já consta na fatura."
			EndIf
		EndIf
	ElseIf Empty(M->UQP_TITFAT) .And.;
			!Empty(oGetDados:aCols[nI][nPsUQPTtFat])

		// Falsifica o retorno da consulta e limpa a variável de memória.
		M->UQP_TITFAT    := CriaVar("UQP_TITFAT")

		// Desvincula o título apahado da fatura
		fDesTitulo(oGetDados:aCols[nI][nPsUQPPfFat],;
				oGetDados:aCols[nI][nPsUQPTtFat],;
				oGetDados:aCols[nI][nPsUQPPcFat],;
				oGetDados:aCols[nI][nPsUQPTpFat])

		// Zera as informações da linha
		oGetDados:aCols[nI][nPsUQPTpFat]	:= CriaVar("UQP_TPFAT")
		oGetDados:aCols[nI][nPsUQPPfFat]	:= CriaVar("UQP_PFXFAT")
		oGetDados:aCols[nI][nPsUQPTtFat]	:= CriaVar("UQP_TITFAT")
		oGetDados:aCols[nI][nPsUQPPcFat]	:= CriaVar("UQP_PARFAT")
		oGetDados:aCols[nI][nPsUQPEmFat]	:= CtoD("  /  /    ")

		If Empty(oGetDados:aCols[nI][nPsUQPTit])
			oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
		EndIf

		oGetDados:aCols[nI][nPsUQPVlFat]	:= CriaVar("UQP_VLRFAT")
		oGetDados:aCols[nI][nPsUQPIcms]	:= CriaVar("UQP_ICMS")
	EndIf

	// Atualiza o total da linha.
	fAtuTotLin()

	// Atualiza o total geral da fatura
	fAtuTotFat()

	RestArea(aAreaSE1)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fVldTitulo
Valida o título NCC, NDC ou RA informado para a fatura e executado gatilho nos campos necessários.
@author Paulo Carvalho
@since 15/03/2019
@type function
/*/
Static Function fVldTitulo()

	Local aArea			:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())
	Local aTCSetField	:= {}
	Local aTam			:= {}

	Local cAliasQry		:= GetNextAlias()
	Local cParcela		:= CriaVar("UQP_PARCEL")
	Local cPrefixo		:= CriaVar("UQP_PREFIX")
	Local cTipo			:= CriaVar("UQP_TIPO")
	Local cTitulo		:= CriaVar("UQP_TITULO")
	Local cQuery		:= ""

	Local dEmissao		:= CtoD("  /  /    ")

	Local lRepetido		:= .F.
	Local lRet			:= .T.

	Local nI			:= oGetDados:nAt
	Local nH			:= 0
	Local nValor		:= CriaVar("UQP_VALOR")

	// Verifica se foi digitado um título
	If !Empty(M->UQP_TITULO)
		// Verifica se o número do título é um retorno da consulta padrão.
		If M->UQP_TITULO == SE1->E1_NUM
			// Verifica se o título selecionado não já não foi selecionado anteriormente
			AEval(oGetDados:aCols, {|x| nH++,;
										IIf(nH <> nI .And.;
											x[nPsUQPTipo]    == SE1->E1_TIPO .And.;
											x[nPsUQPPref]    == SE1->E1_PREFIXO .And.;
											x[nPsUQPTit]		== SE1->E1_NUM .And.;
											x[nPsUQPParc]	== SE1->E1_PARCELA,;
											lRepetido := .T., Nil)})

			// Verifica se o título selecionado não foi selecionado no bloco 1
			AEval(oGetDados:aCols, {|x| nH++,;
										IIf(nH <> nI .And.;
											x[nPsUQPTpFat] == SE1->E1_TIPO .And.;
											x[nPsUQPPfFat] == SE1->E1_PREFIXO .And.;
											x[nPsUQPTtFat] == SE1->E1_NUM .And.;
											x[nPsUQPPcFat] == SE1->E1_PARCELA,;
											lRepetido := .T., Nil)})

			If !lRepetido
				// Preenche os campos com as informações referentes ao arquivo selecionado
				cTipo		:= SE1->E1_TIPO
				cPrefixo	:= SE1->E1_PREFIXO
				cTitulo		:= SE1->E1_NUM
				cParcela	:= SE1->E1_PARCELA
				dEmissao	:= SE1->E1_EMISSAO
				nValor		:= SE1->E1_VALOR
			EndIf
		Else
			// Define a query de pesquisa do título de débito ou crédito do cliente da fatura
			cQuery	+= "SELECT	SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA,"	+ CRLF
			cQuery	+= "		SE1.E1_TIPO, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_EMISSAO,"	+ CRLF
			cQuery	+= "		SE1.E1_VALOR"												+ CRLF
			cQuery	+= "FROM	" + RetSQLName("SE1") + " AS SE1 "							+ CRLF
			cQuery	+= "WHERE	SE1.E1_FILIAL = '" 	+ FWxFilial("SE1") 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_CLIENTE = '" + M->UQO_CLIENT 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_LOJA = '" 	+ M->UQO_LOJA	 	+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_NUM = '" 	+ M->UQP_TITULO 		+ "' "				+ CRLF
			cQuery	+= "AND		SE1.E1_TIPO IN('NCC', 'NDC', 'RA ') "						+ CRLF
			cQuery	+= "AND		SE1.D_E_L_E_T_ <> '*' "										+ CRLF

			// Define o campos que devem passar pela função TCSetField
			aTam := TamSX3("E1_EMISSAO") ; Aadd( aTCSetField, { "E1_EMISSAO", aTam[3], aTam[1], aTam[2]	} )
			aTam := TamSX3("E1_VALOR"  ) ; Aadd( aTCSetField, { "E1_VALOR"  , aTam[3], aTam[1], aTam[2]	} )

			// Fecha a área de trabalho caso esteja sendo utilizada
			fFechaTab(cAliasQry)

			// Cria área de trabalho a partir da query definida
			MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

			// Se houver arquivos
			If !(cAliasQry)->(Eof())
				// Verifica se o arquivo CTE/CRT selecionado não já não foi selecionado anteriormente
				AEval(oGetDados:aCols, {|x| nH++,;
											IIf(nH <> nI .And.;
												x[nPsUQPTipo]    == (cAliasQry)->E1_TIPO .And.;
												x[nPsUQPPref]    == (cAliasQry)->E1_PREFIXO .And.;
												x[nPsUQPTit]		== (cAliasQry)->E1_NUM .And.;
												x[nPsUQPParc]	== (cAliasQry)->E1_PARCELA,;
												lRepetido := .T., Nil)})

				// Verifica se o arquivo CTE/CRT selecionado não já não foi selecionado anteriormente
				AEval(oGetDados:aCols, {|x| nH++,;
											IIf(nH <> nI .And.;
												x[nPsUQPTpFat]   == (cAliasQry)->E1_TIPO .And.;
												x[nPsUQPPfFat]   == (cAliasQry)->E1_PREFIXO .And.;
												x[nPsUQPTtFat]	== (cAliasQry)->E1_NUM .And.;
												x[nPsUQPPcFat]	== (cAliasQry)->E1_PARCELA,;
												lRepetido := .T., Nil)})

				// Verifica se o título foi incluido em outra fatura
				IIf(fCompoeFat((cAliasQry)->E1_PREFIXO,;
					(cAliasQry)->E1_NUM, (cAliasQry)->E1_PARCELA,;
					(cAliasQry)->E1_TIPO), lRepetido := .T., Nil)

				If !lRepetido
					// Preenche os campos com as informações referentes ao arquivo selecionado
					cTipo		:= (cAliasQry)->E1_TIPO
					cPrefixo	:= (cAliasQry)->E1_PREFIXO
					cTitulo		:= (cAliasQry)->E1_NUM
					cParcela	:= (cAliasQry)->E1_PARCELA
					dEmissao	:= (cAliasQry)->E1_EMISSAO
					nValor		:= (cAliasQry)->E1_VALOR
				EndIf
			Else
				M->UQP_TITULO	:= CriaVar("UQP_TITULO")

				oGetDados:aCols[nI][nPsUQPTipo]	:= CriaVar("UQP_TIPO")
				oGetDados:aCols[nI][nPsUQPPref]	:= CriaVar("UQP_PREFIX")
				oGetDados:aCols[nI][nPsUQPTit]	:= CriaVar("UQP_TITULO")
				oGetDados:aCols[nI][nPsUQPParc]	:= CriaVar("UQP_PARCEL")
				oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
				oGetDados:aCols[nI][nPsUQPValor]	:= CriaVar("UQP_VALOR")

				MsgAlert(CAT518054, cCadastro) //#"O titulo digitado não está cadastrado no sistema para este cliente."
			EndIf
		EndIf

		// Verifica o tipo do título do primeiro bloco para validar a inclusão
		If AllTrim(oGetDados:aCols[nI][nPsUQPTpFat]) $ "NCC|RA"
			lRet := .F.
			MsgAlert(CAT518055, cCadastro) //#"Não é permitido compensar ou liquidar um título do tipo NCC ou RA."
		Else
			// Verifica se houve uma troca de título
			If M->UQP_TITULO <> oGetDados:aCols[nI][nPsUQPTit]
				// Desvincula o título anterior
				fDesTitulo(oGetDados:aCols[nI][nPsUQPPref],;
						oGetDados:aCols[nI][nPsUQPTit],;
						oGetDados:aCols[nI][nPsUQPParc],;
						oGetDados:aCols[nI][nPsUQPTipo])
			EndIf

			// Vinculo o título a fatura
			//Função comentada dia 17/10/2019 - Icaro
			//Ela estava gravando o campo E1_XIDFAT ANTES da confirmação da gravação
			//fVinTitulo(cPrefixo, cTitulo, cParcela, cTipo)

			// Atualiza GetDados
			oGetDados:aCols[nI][nPsUQPTipo]	:= cTipo
			oGetDados:aCols[nI][nPsUQPPref]	:= cPrefixo
			oGetDados:aCols[nI][nPsUQPTit]	:= cTitulo
			oGetDados:aCols[nI][nPsUQPParc]	:= cParcela
			oGetDados:aCols[nI][nPsUQPEmiss]	:= dEmissao
			oGetDados:aCols[nI][nPsUQPValor]	:= nValor
		EndIf

		If lRepetido
			lRet			:= .F.
			M->UQP_TITULO	:= CriaVar("UQP_TITULO")

			MsgAlert(CAT518056, cCadastro) // #"O título selecionado já consta nesta ou em outra fatura."
		EndIf
	ElseIf Empty(M->UQP_TITULO ) .And.;
			!Empty(oGetDados:aCols[nI][nPsUQPTit])

		// Desvincula o título apahado da fatura
		fDesTitulo(oGetDados:aCols[nI][nPsUQPPref],;
				oGetDados:aCols[nI][nPsUQPTit],;
				oGetDados:aCols[nI][nPsUQPParc],;
				oGetDados:aCols[nI][nPsUQPTipo])

		oGetDados:aCols[nI][nPsUQPTipo]	:= CriaVar("UQP_TIPO")
		oGetDados:aCols[nI][nPsUQPPref]	:= CriaVar("UQP_PREFIX")
		oGetDados:aCols[nI][nPsUQPTit]	:= CriaVar("UQP_TITULO")
		oGetDados:aCols[nI][nPsUQPParc]	:= CriaVar("UQP_PARCEL")
		oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
		oGetDados:aCols[nI][nPsUQPValor]	:= CriaVar("UQP_VALOR")
	EndIf

	// Atualiza o total da linha.
	fAtuTotLin()

	// Atualiza o total geral da fatura.
	fAtuTotFat()

	RestArea(aAreaSE1)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fCompoeFat
Atualiza o valor total da linha.
@author Paulo Carvalho
@since 15/03/2019
@return lCompoe, lógico, retorna true se compõe outra fatura e false se não compõe.
@type function
/*/
Static Function fCompoeFat(cPrefixo, cTitulo, cParcela, cTipo)

//	Local aArea		:= GetArea()
//	Local aAreaSE1	:= SE1->(GetArea())

	Local lCompoe	:= .F.

	DbSelectArea("SE1")
	SE1->(DbSetOrder(2))	// E1_FILIAL + E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO

	If SE1->(DbSeek(FWxFilial("SE1");
		+ M->UQO_CLIENT + M->UQO_LOJA + cPrefixo;
		+ cTitulo + cParcela + cTipo))

		If !Empty(SE1->E1_XIDFAT) .And. SE1->E1_XIDFAT <> M->UQO_ID
			lCompoe := .T.
		EndIf
	EndIf

Return lCompoe

/*/{Protheus.doc} fAtuTotLin
Atualiza o valor total da linha.
@author Paulo Carvalho
@since 15/03/2019
@type function
/*/
Static Function fAtuTotLin()

	Local aArea		:= GetArea()
	//Local aAreaSE1	:= SE1->(GetArea())

	Local cTipo		:= oGetDados:aCols[oGetDados:nAt][nPsUQPTipo]

	Local nIcms		:= oGetDados:aCols[oGetDados:nAt][nPsUQPIcms]
	Local nVlrFat	:= oGetDados:aCols[oGetDados:nAt][nPsUQPVlFat]
	Local nValor	:= oGetDados:aCols[oGetDados:nAt][nPsUQPValor]
	Local nTotLinha	:= IIf(AllTrim(cTipo) $ "NCC|RA", ((nVlrFat + nIcms) - nValor), ((nVlrFat + nIcms) + nValor))

	/*DbSelectArea("SE1")
	SE1->(DbSetOrder(1))//E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If SE1->(DbSeek(xFilial("SE1") + oGetDados:aCols[oGetDados:nAt][nPsUQPPfFat] + oGetDados:aCols[oGetDados:nAt][nPsUQPTtFat] + oGetDados:aCols[oGetDados:nAt][nPsUQPPcFat] + oGetDados:aCols[oGetDados:nAt][nPsUQPTpFat]))
		nTotLinha -= (SE1->E1_ISS + SE1->E1_INSS)
	EndIf*/

	If nTotLinha < 0

		nTotLinha := 0

	EndIf
	// Atualiza o valor total da linha
	oGetDados:aCols[oGetDados:nAt][nPsUQPTotal] := nTotLinha

	// Atualiza GetDados
	oGetDados:Refresh()

	//RestArea(aAreaSe1)
	RestArea(aArea)

Return

/*/{Protheus.doc} fAtuTotFat
Atualiza o valor total da fatura
@author Paulo Carvalho
@since 15/03/2019
@type function
/*/
Static Function fAtuTotFat()

	Local aArea		:= GetArea()
	Local aTitulos	:= oGetDados:aCols

	Local nI
	Local nTotal	:= 0

	// Realiza a somatória do total de todos os títulos selecionados
	For nI := 1 To Len(aTitulos)
		If !aTitulos[nI][nPsUQPDel]
			If AllTrim(aTitulos[nI][nPsUQPTpFat]) $ "NCC|RA"
				nTotal -= aTitulos[nI][nPsUQPTotal]
			Else
				nTotal += aTitulos[nI][nPsUQPTotal]
			EndIf
		EndIf
	Next

	// Atualiza o valor total da fatura
	nTotalFat := nTotal

	oTGTotal:Refresh()

	RestArea(aArea)

Return

/*/{Protheus.doc} fLinhaOk
Realiza a validação dos dados inseridos na linha.
@author Paulo Carvalho
@since 15/03/2019
@return lRet, lógico, true se a linha é válida e false se não é válida.
@type function
/*/
Static Function fLinhaOk()

	Local aArea		:= GetArea()

	Local cTipoFat	:= oGetDados:aCols[oGetDados:nAt][nPsUQPTpFat]
	Local cPfxFat	:= oGetDados:aCols[oGetDados:nAt][nPsUQPPfFat]
	Local cTitulo	:= oGetDados:aCols[oGetDados:nAt][nPsUQPTtFat]

	Local dEmissao	:= oGetDados:aCols[oGetDados:nAt][nPsUQPEmFat]

	Local lRet		:= .T.

	Local nVlrFat	:= oGetDados:aCols[oGetDados:nAt][nPsUQPVlFat]

	// Valida se os campos obrigatórios estão preenchidos
	If Empty(cTipoFat)
		lRet := .F.
		MsgAlert(CAT518057, cCadastro) //#"Selecione um arquivo CTE/CRT para adicionar a próxima linha."
	ElseIf Empty(cPfxFat)
		lRet := .F.
		MsgAlert(CAT518057, cCadastro) //#"Selecione um arquivo CTE/CRT para adicionar a próxima linha."
	ElseIf Empty(cTitulo)
		lRet := .F.
		MsgAlert(CAT518057, cCadastro) //#"Selecione um arquivo CTE/CRT para adicionar a próxima linha."
	ElseIf Empty(dEmissao)
		lRet := .F.
		MsgAlert(CAT518057, cCadastro) //#"Selecione um arquivo CTE/CRT para adicionar a próxima linha."
	ElseIf Empty(nVlrFat)
		lRet := .F.
		MsgAlert(CAT518057, cCadastro) //#"Selecione um arquivo CTE/CRT para adicionar a próxima linha."
	EndIf

	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fDelOk
Realiza a validação da exclusão da linha.
@author Paulo Carvalho
@since 15/03/2019
@return lRet, lógico, retorna true se a linha é válida para deleção e false se não é válida.
@type function
/*/
Static Function fDelOk()

	Local aArea		:= GetArea()
	Local aAreaSE1	:= SE1->(GetArea())

	Local cChaveSE1	:= ""

	Local lDeleted	:= .F.
	Local lRet		:= .T.

	Local nI		:= oGetDados:nAt
	Local nTotItem	:= oGetDados:aCols[nI][nPsUQPTotal]

	// Verifica se a linha está deletada ou não
	lDeleted := oGetDados:aCols[nI][nPsUQPDel]

	//-----------------------------------------------
	// Ao desmarcar um item deletado, verifica se o
	// titulo pertence ao cliente do cabeçalho (UQO)
	//-----------------------------------------------
	If lDeleted
		If !Empty(oGetDados:aCols[nI][nPsUQPPfFat])
			cChaveSE1 := xFilial("SE1")
			cChaveSE1 += PadR(M->UQO_CLIENT					 , TamSX3("E1_CLIENTE")[1])
			cChaveSE1 += PadR(M->UQO_LOJA					 , TamSX3("E1_LOJA"	  )[1])
			cChaveSE1 += PadR(oGetDados:aCols[nI][nPsUQPPfFat], TamSX3("E1_PREFIXO")[1])
			cChaveSE1 += PadR(oGetDados:aCols[nI][nPsUQPTtFat], TamSX3("E1_NUM"	  )[1])
			cChaveSE1 += PadR(oGetDados:aCols[nI][nPsUQPPcFat], TamSX3("E1_PARCELA")[1])
			cChaveSE1 += PadR(oGetDados:aCols[nI][nPsUQPTpFat], TamSX3("E1_TIPO"	  )[1])

			DbSelectArea("SE1")
			SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			If !SE1->(DbSeek( cChaveSE1 ))
				lRet := .F.

				MsgAlert(CAT518058 + AllTrim(M->UQO_NOMECL) + ".", cCadastro) //#"O título desta linha não pertence ao cliente "
			EndIf
		EndIf
	EndIf

	If lRet
		// Foi desmarcada para deleção.
		If lDeleted
			IIf(AllTrim(oGetDados:aCols[nI][nPsUQPTpFat]) $ "NCC|RA", nTotalFat -= nTotItem, nTotalFat += nTotItem)
		Else 	// Foi marcada para deleção.
			IIf(AllTrim(oGetDados:aCols[nI][nPsUQPTpFat]) $ "NCC|RA", nTotalFat += nTotItem, nTotalFat -= nTotItem)
		EndIf

		// Atualiza o total na tela
		oTGTotal:Refresh()
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

Return lRet

/*/{Protheus.doc} fFieldOk
Responsável por validar se o titulo pode ou não ser adicionado em uma fatura
@author Icaro Laudade
@since 18/10/2019
@return lRet, Retorna se é valido ou não
@type function
/*/
Static Function fFieldOk()
	Local cPrefixSE1	:=	""
	Local cTipoSE1		:=	""
	Local lRet			:=	.T.
	Local nI 			:=	oGetDados:nAt

	If oGetDados:oBrowse:nColPos == nPsUQPTtFat

		cPrefixSE1 := PadR(oGetDados:aCols[nI][nPsUQPPfFat], TamSX3("E1_PREFIXO")[1])
		cTipoSE1 := PadR(oGetDados:aCols[nI][nPsUQPTpFat], TamSX3("E1_TIPO")[1])

		If !Empty(oGetDados:aCols[nI][nPsUQPTtFat]) .And. !(AllTrim(cTipoSE1) $ "NDC|NCC|NF|NFS|RA") .And. !(cPrefixSE1 $ "CTE|CRT")

			oGetDados:aCols[nI][nPsUQPTpFat]	:= CriaVar("UQP_TPFAT")
			oGetDados:aCols[nI][nPsUQPPfFat]	:= CriaVar("UQP_PFXFAT")
			oGetDados:aCols[nI][nPsUQPTtFat]	:= CriaVar("UQP_TITFAT")
			oGetDados:aCols[nI][nPsUQPPcFat]	:= CriaVar("UQP_PARFAT")
			oGetDados:aCols[nI][nPsUQPEmFat]	:= CtoD("  /  /    ")

			If Empty(oGetDados:aCols[nI][nPsUQPTit])
				oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
			EndIf

			lRet := .F.

			MsgAlert( CAT518079, cCadastro) // "Apenas titulos NCC, NDC, NF, CTE, CRT e RA podem ser selecionados."

		EndIf

	ElseIf oGetDados:oBrowse:nColPos == nPsUQPTit

		cTipoSE1 := PadR(oGetDados:aCols[nI][nPsUQPTipo], TamSX3("E1_TIPO")[1])

		If !Empty(oGetDados:aCols[nI][nPsUQPTit]) .And. !(AllTrim(cTipoSE1) $ "NDC|NCC|RA")
			oGetDados:aCols[nI][nPsUQPTipo]	:= CriaVar("UQP_TIPO")
			oGetDados:aCols[nI][nPsUQPPref]	:= CriaVar("UQP_PREFIX")
			oGetDados:aCols[nI][nPsUQPTit]	:= CriaVar("UQP_TITULO")
			oGetDados:aCols[nI][nPsUQPParc]	:= CriaVar("UQP_PARCEL")
			oGetDados:aCols[nI][nPsUQPEmiss]	:= CtoD("  /  /    ")
			oGetDados:aCols[nI][nPsUQPValor]	:= CriaVar("UQP_VALOR")

			lRet := .F.

			MsgAlert( CAT518080, cCadastro) // "Apenas titulos NCC, NDC e RA podem ser selecionados."

		EndIf

	EndIf

Return lRet

/*/{Protheus.doc} fCria_nPos
Cria as variáveis de controle de posição das GetDados.
@author Juliano Fernandes
@since 25/01/2019
@type function
/*/
Static Function fCria_nPos()

	If Type("aHeader") == "A"
		// Posição do aHeader de itens da Fatura
		_SetNamedPrvt("nPsUQPItem"	, GDFieldPos("UQP_ITEM"		, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPTpFat"	, GDFieldPos("UQP_TPFAT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPPfFat"	, GDFieldPos("UQP_PFXFAT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPPcFat"	, GDFieldPos("UQP_PARFAT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPTtFat"	, GDFieldPos("UQP_TITFAT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPEmFat"	, GDFieldPos("UQP_EMISFA"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPVlFat"	, GDFieldPos("UQP_VLRFAT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPIcms"	, GDFieldPos("UQP_ICMS"		, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPTipo"	, GDFieldPos("UQP_TIPO"		, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPPref"	, GDFieldPos("UQP_PREFIX"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPTit"	, GDFieldPos("UQP_TITULO"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPParc"	, GDFieldPos("UQP_PARCEL"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPEmiss"	, GDFieldPos("UQP_EMISSA"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPValor"	, GDFieldPos("UQP_VALOR"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPTotal"	, GDFieldPos("UQP_TOTAL"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPRecno"	, GDFieldPos("UQP_REC_WT"	, aHeader)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQPDel"	, Len(aHeader) + 1						, "U_PRT0518")
	EndIf

	If Type("aHeaderUQD") == "A"
		// Posição do aHeader de seleção de CTEs
		_SetNamedPrvt("nPsUQDCheck"	, GDFieldPos("CHK"			, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDFilial", GDFieldPos("UQD_FILIAL"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDTipo"	, GDFieldPos("UQD_TIPOTI"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDPrefix", GDFieldPos("UQD_PREFIX"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDTit"	, GDFieldPos("UQD_TITULO"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDParc"	, GDFieldPos("UQD_PARCEL"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDCte"	, GDFieldPos("UQD_NUMERO"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDEmiss"	, GDFieldPos("UQD_EMISSA"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDValor"	, GDFieldPos("UQD_VALOR"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDIcms"	, GDFieldPos("UQD_ICMS"		, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDRecno"	, GDFieldPos("UQD_REC_WT"	, aHeaderUQD)	, "U_PRT0518")
		_SetNamedPrvt("nPsUQDDelet"	, Len(aHeaderUQD) + 1						, "U_PRT0518")
	EndIf

Return(Nil)

/*/{Protheus.doc} fAddCheck
Função para adicionar no aHeader o campo para legenda.
@author Juliano Fernandes
@since 09/01/2019
@param aArray, array, Array contendo a referência de aHeader
@type function
/*/
Static Function fAddCheck( aArray )

	Aadd( aArray, { "", "CHK", "@BMP", 1, 0, .T., "", "",;
					"", "R", "", "", .F., "V", "", "", "", ""	})

Return

/*/{Protheus.doc} fCheck
Realiza a marcação de um registro.
@author Juliano Fernandes
@since 11/01/2019
@type function
/*/
Static Function fCheck()

	Local oNo := LoadBitmap( GetResources(), "LBNO" )
	Local oOk := LoadBitmap( GetResources(), "LBOK" )

	If oGDCTE:aCols[oGDCTE:nAt, nPsUQDRecno] > 0
		If oGDCTE:aCols[oGDCTE:nAt, nPsUQDCheck]:cName == "LBNO"
			oGDCTE:aCols[oGDCTE:nAt, nPsUQDCheck] := oOk
		Else
			oGDCTE:aCols[oGDCTE:nAt, nPsUQDCheck] := oNo
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fSetCheck
Realiza integração do documento conforme o tipo de arquivo escolhido.
@author Paulo Carvalho
@since 28/12/2018
@type function
/*/
Static Function fSetCheck(nOpcao)

	Local nI	:= 0
	Local nAt	:= 0

	ProcRegua(1)

	nAt := oGDCTE:nAt

	If nOpcao == 1 /* Marcar todos */
		AEVal(oGDCTE:aCols, {|x| nI++, oGDCTE:GoTo(nI), IIf(x[nPsUQDRecno] > 0, x[nPsUQDCheck] := oOk, Nil)})
	ElseIf nOpcao == 2 /* Desmarcar todos */
		AEVal(oGDCTE:aCols, {|x| nI++, oGDCTE:GoTo(nI), IIf(x[nPsUQDRecno] > 0, x[nPsUQDCheck] := oNo, Nil)})
	ElseIf nOpcao == 3 /* Inverter seleção */
		AEVal(oGDCTE:aCols, {|x| nI++, oGDCTE:GoTo(nI), IIf(x[nPsUQDRecno] > 0, (x[nPsUQDCheck] := IIf(x[nPsUQDCheck]:cName == "LBOK", oNo, oOk)), Nil)})
	EndIf

	oGDCTE:GoTo(nAt)
	oGDCTE:Refresh()

Return

/*/{Protheus.doc} fIntegra
Executa a liquidação dos títulos vinculados a fatura.
@author Paulo Carvalho
@since 25/03/2019
@type function
@param nOpcao, numerico, Opção: 3=inclusão ou 4=Alteração
/*/
Static Function fIntegra(nOpcao)

	Local aArea			:= GetArea()
	Local aAreaUQO		:= UQO->(GetArea())
	Local aAreaSE1		:= SE1->(GetArea())
	Local aTCSetField	:= {}

	Local aCab			:= {}
	Local aItens		:= {}
	Local aRecNCC_RA	:= {}
	Local aRecSE1		:= {}
//	Local aTxMoeda		:= {}

	Local cFiltro		:= ""
	Local cChaveSE1		:= ""
	Local cNumTit		:= ""
	Local cParcTit		:= ""
	Local cPfxTit		:= SuperGetMV("PLG_PFXFAT", .F., "FAT")
	Local cAliasQry		:= ""
	Local cQuery		:= ""
	Local cNatFatNFS	:= SuperGetMV("PLG_NATFNF", .F., "120024")
	Local cNatEspNFS	:= SuperGetMV("PLG_NATENF", .F., "120013")
	Local cNatureza		:= ""
	Local cStatusFat	:= ""
	Local cNatureTit	:= ""

	Local dDtBaseBkp	:= dDataBase

	Local lContinua 	:= .T.
	Local lIntegra		:= .F.
	Local lCompensa		:= .F.
	Local lNCC_RA		:= .F.
	Local lNewNum		:= .F.
	Local lContabiliza	:= .F.
	Local lAglutina		:= .F.
	Local lDigita		:= .F.
	Local lMultipFat	:= IsInCallStack("fMultipFat")
	Local lFatNFS		:= .F.

	Local nVlCruz		:= 0
//	Local nTaxaCM		:= 0
	Local nSaldoComp	:= 0
	Local nPosPref		:= 0
	Local nPosNum		:= 0
	Local nPosParc		:= 0
	Local nPosTipo		:= 0
	Local nI			:= 0

	Private lMsErroAuto	:= .F.

	dDataBase := UQO->UQO_EMISSA

	// Inicia Integração
	ProcRegua(0)

	Begin Transaction

		//-------------------------------
		// Executa a validação dos dados
		//-------------------------------
/*		IncProc(CAT518059) // "Validando fatura..."
		lContinua := fVldInteg()

		If lContinua
			lContinua := MsgYesNo(CAT518060, cCadastro) // "Confirma a integração da fatura?"
		EndIf
*/
//		If lContinua
			//----------------------------------------
			// Grava os dados informados pelo usuário
			//----------------------------------------
//			IncProc(CAT518061) //#"Gravando dados da fatura..."
//			lContinua := IIf(fVldIncAlt(), fSalvar(nOpcao), .F.)
//		EndIf

		If lContinua
			IncProc(CAT518062) //#"Preparando dados para integração..."

			// --------------------------------------------------
			// Atualiza o Centro de Custo da tabela SE1 caso
			// não tenha sido gravado na integração CTE/CRT
			// --------------------------------------------------
			fAtuCCusto()

			If nOpcao == 6 		//Caso seja integrada a fatura, a variável não terá sido inicializada
				nTotalFat := UQO->UQO_TOTAL
			EndIf

			// ------------------------------------------------------------------
			// Obtém o valor total da fatura (recalcula) e indica na variável
			// lFatNFS se é uma fatura de Nota Fiscal de Serviço.
			// É considerada uma fatura de Nota Fiscal de Serviço a fatura
			// que tem apenas um item e esse ítem tem o prefixo que começa
			// com NF.
			// ------------------------------------------------------------------
			nVlCruz := fGetValFat(@lFatNFS, @cNatureTit) // nTotalFat

			If !lFatNFS
				nVlCruz := nTotalFat
			EndIf

			//--------------------------------------
			// Acrescenta o valor dos NCCs e RAs
			//--------------------------------------
			AEval(aCols, {|x| IIf(AllTrim(x[nPsUQPTpFat]) $ "NCC|RA"	, (lNCC_RA := .T., nVlCruz += x[nPsUQPTotal]), Nil)})
			AEval(aCols, {|x| IIf(AllTrim(x[nPsUQPTipo] ) $ "NCC|RA"	, (lNCC_RA := .T., nVlCruz += x[nPsUQPValor]), Nil)})

			// Filtro do Usuário
			cFiltro := "E1_FILIAL  == '" + xFilial("SE1")  + "' .And. "
			cFiltro += "E1_FILORIG == '" + cFilAnt         + "' .And. "
			cFiltro += "E1_CLIENTE == '" + UQO->UQO_CLIENT + "' .And. "
			cFiltro += "E1_LOJA    == '" + UQO->UQO_LOJA    + "' .And. "
			cFiltro += "E1_XIDFAT  == '" + UQO->UQO_ID      + "' .And. "
			cFiltro += "E1_TIPO    <> '" + "NCC"           + "' .And. "
			cFiltro += "E1_TIPO    <> '" + "RA "           + "'       "

			DbSelectArea("SA1")
			SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
			If SA1->(DbSeek(xFilial("SA1") + UQO->UQO_CLIENT + UQO->UQO_LOJA))

				cParcTit := SuperGetMV("MV_1DUP",,"")

				If Empty(UQO->UQO_NUMERO)
					cNumTit  := GetMV("PLG_NUMFAT")

					DbSelectArea("SE1")
					SE1->(DbSetOrder(2))	// E1_FILIAL + E1_CLIENTE + E1_LOJA + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
					While SE1->(DbSeek(FWxFilial("SE1") + UQO->UQO_CLIENT + UQO->UQO_LOJA + cPfxTit + cNumTit + cParcTit))
						cNumTit := Soma1(cNumTit)
						PutMV("PLG_NUMFAT", cNumTit)
					EndDo
				Else
					cNumTit	:= UQO->UQO_NUMERO
				EndIf

				If lFatNFS
					If !Empty(cNatureTit)
						// ----------------------------------------------------------------------------------------
						// Ajuste realizado por Juliano em 06/03/2020 conforme solicitação feita por Marcos Santos
						// O ajuste foi realizado pois em alguns casos, os impostos não estavam sendo exibidos na
						// tela de baixa do título ao gerar uma fatura com a natureza do parâmetro PLG_NATFNF. Então
						// para esses casos, a natureza utilizada será a do proprio título que compoe a fatura.
						// ----------------------------------------------------------------------------------------
						// Se a natureza do título da NFS estiver no parâmetro PLG_NATENF
						// então deve-se usar a natureza dele mesmo no ExecAuto da Liquidação
						// ----------------------------------------------------------------------------------------
						If AllTrim(cNatureTit) $ cNatEspNFS
							cNatureza := cNatureTit
						EndIf
					EndIf

					If Empty(cNatureza)
						cNatureza := cNatFatNFS
					EndIf
				Else
					cNatureza := SA1->A1_NATUREZ
				EndIf

				// Array do processo automatico (aAutoCab)
				aCab := { 		{"cCondicao", SA1->A1_COND 		},;
								{"cNatureza", cNatureza		 	},;
								{"E1_TIPO"	, "FAT" 			},;
								{"cCLIENTE"	, SA1->A1_COD		},;
								{"nMoeda"	, 1 				},;
								{"cLOJA"	, SA1->A1_LOJA 		} }

				Aadd(aItens, {	{"E1_PREFIXO", cPfxTit 			},;
								{"E1_NUM" 	 , cNumTit			},;
								{"E1_PARCELA", cParcTit 		},;
								{"E1_VENCTO" , UQO->UQO_VENCTO	},;
								{"E1_VLCRUZ" , nVlCruz			}})

				IncProc(CAT518063) //#"Processando integração..."

				MsExecAuto({|v,w,x,y,z| FINA460(v,w,x,y,z)}, Nil, aCab, aItens, 3, cFiltro)

				If lMsErroAuto
					lContinua := .F.

					If lMultipFat
						cErroInteg := fErrExecAut()
					Else
						MsgAlert(CAT518064, cCadastro) //#"Erro na integração da fatura."

						MostraErro()
					EndIf
				Else
					lIntegra := .T.

					// Grava a sequência da fatura no novo título gerado
					DbSelectArea("SE1")
					SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

					cChaveSE1 := FWxFilial("SE1")
					cChaveSE1 += PadR(UQO->UQO_CLIENT, TamSX3("E1_CLIENTE")[1])
					cChaveSE1 += PadR(UQO->UQO_LOJA   , TamSX3("E1_LOJA"   )[1])
					cChaveSE1 += PadR(cPfxTit        , TamSX3("E1_PREFIXO")[1])
					cChaveSE1 += PadR(cNumTit        , TamSX3("E1_NUM"    )[1])
					cChaveSE1 += PadR(cParcTit       , TamSX3("E1_PARCELA")[1])
					cChaveSE1 += PadR("FAT"          , TamSX3("E1_TIPO"   )[1])

					If SE1->(DbSeek( cChaveSE1 ))
						SE1->(RecLock("SE1", .F.))
							SE1->E1_XIDFAT := UQO->UQO_ID
						SE1->(MsUnlock())
					EndIf
				EndIf
			Else
				lContinua := .F.

				If lMultipFat
					cErroInteg := CAT518065 //#"Cliente não localizado."
				Else
					MsgAlert(CAT518065, cCadastro) //#"Cliente não localizado."
				EndIf
			EndIf
		EndIf

		If lContinua
			If lNCC_RA
				IncProc(CAT518066) //#"Preparando dados para compensação..."

				//--------------------------------
				// Posiciona no título NCC ou RA
				//--------------------------------
				DbSelectArea("SE1")
				SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

				For nI := 1 To Len(aCols)
					If AllTrim(aCols[nI,nPsUQPTpFat]) $ "NCC|RA"
						cChaveSE1 := FWxFilial("SE1")
						cChaveSE1 += PadR(UQO->UQO_CLIENT		, TamSX3("E1_CLIENTE")[1])
						cChaveSE1 += PadR(UQO->UQO_LOJA			, TamSX3("E1_LOJA"	 )[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPPfFat]	, TamSX3("E1_PREFIXO")[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPTtFat]	, TamSX3("E1_NUM"	 )[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPPcFat]	, TamSX3("E1_PARCELA")[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPTpFat]	, TamSX3("E1_TIPO"	 )[1])

						If SE1->(DbSeek( cChaveSE1 ))
							Aadd(aRecNCC_RA, SE1->(Recno()))

							nSaldoComp += SE1->E1_VALOR
						EndIf
					ElseIf AllTrim(aCols[nI,nPsUQPTipo]) $ "NCC|RA"
						cChaveSE1 := FWxFilial("SE1")
						cChaveSE1 += PadR(UQO->UQO_CLIENT		, TamSX3("E1_CLIENTE")[1])
						cChaveSE1 += PadR(UQO->UQO_LOJA			, TamSX3("E1_LOJA"	 )[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPPref]	, TamSX3("E1_PREFIXO")[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPTit]	, TamSX3("E1_NUM"	 )[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPParc]	, TamSX3("E1_PARCELA")[1])
						cChaveSE1 += PadR(aCols[nI][nPsUQPTipo]	, TamSX3("E1_TIPO"	 )[1])

						If SE1->(DbSeek( cChaveSE1 ))
							Aadd(aRecNCC_RA, SE1->(Recno()))

							nSaldoComp += SE1->E1_VALOR
						EndIf
					EndIf
				Next nI

				//--------------------------------------
				// Posiciona no título a ser compensado
				//--------------------------------------
				nPosPref 	:= AScan(aItens[1], {|x| x[1] == "E1_PREFIXO"})
				nPosNum		:= AScan(aItens[1], {|x| x[1] == "E1_NUM"	 })
				nPosParc	:= AScan(aItens[1], {|x| x[1] == "E1_PARCELA"})
				nPosTipo	:= AScan(aCab  	  , {|x| x[1] == "E1_TIPO"	 })

				cChaveSE1 := xFilial("SE1")
				cChaveSE1 += PadR(UQO->UQO_CLIENT	  , TamSX3("E1_CLIENTE")[1])
				cChaveSE1 += PadR(UQO->UQO_LOJA		  , TamSX3("E1_LOJA"   )[1])
				cChaveSE1 += PadR(aItens[1,nPosPref,2], TamSX3("E1_PREFIXO")[1])
				cChaveSE1 += PadR(aItens[1,nPosNum ,2], TamSX3("E1_NUM"	   )[1])
				cChaveSE1 += PadR(aItens[1,nPosParc,2], TamSX3("E1_PARCELA")[1])
				cChaveSE1 += PadR(aCab[nPosTipo,2]	  , TamSX3("E1_TIPO"   )[1])

				If SE1->(DbSeek( cChaveSE1 ))
					Aadd(aRecSE1, SE1->(Recno()))

					Pergunte("AFI340", .F.)

					lContabiliza	:= MV_PAR11 == 1
					lAglutina   	:= MV_PAR08 == 1
					lDigita   		:= MV_PAR09 == 1

/* 					nTaxaCM := RecMoeda(dDataBase,SE1->E1_MOEDA)

					Aadd(aTxMoeda, {1, 1	  })
					Aadd(aTxMoeda, {2, nTaxaCM})
*/
					SE1->(dbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_FORNECE+E1_LOJA

					IncProc(CAT518067) //#"Processando compensação..."
					If !MaIntBxCR(3,aRecSE1,,aRecNCC_RA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp)
						lContinua := .F.

						If lMultipFat
							cErroInteg := CAT518068 //#"Não foi possível gerar a compensação."
						Else
							MsgAlert(CAT518068, cCadastro) //#"Não foi possível gerar a compensação."
						EndIf
					Else
						lCompensa := .T.
					EndIf
				EndIf
			EndIf
		EndIf

		If lContinua
			DbSelectArea("UQO")
			UQO->(DbSetOrder(1)) // UQO_FILIAL+UQO_ID
			If UQO->(DbSeek(xFilial("UQO") + UQO->UQO_ID))

				cStatusFat := UQO->UQO_STATUS

				If (lCompensa .And. nSaldoComp == UQO->UQO_TOTAL)
					cStatusFat := "4" // Baixada totalmente
				Else
					If (lCompensa .And. nSaldoComp <> UQO->UQO_TOTAL)
						cStatusFat := "3" // Baixada parcialmente
					Else
						cStatusFat := "2" // Integrada
					EndIf
				EndIf

				UQO->(RecLock("UQO",.F.))
					If Empty(UQO->UQO_NUMERO)
						UQO->UQO_NUMERO := cNumTit
						lNewNum	:= .T.
					EndIf

					UQO->UQO_DTLIQ  := dDataBase
					UQO->UQO_STATUS := cStatusFat
				UQO->(MsUnlock())

				If lNewNum
					PutMV("PLG_NUMFAT", Soma1( GetMV("PLG_NUMFAT")))
					lNewNum := .F.
				EndIf

				// -------------------------------------------
				// Atualiza o número da fatura nos títulos
				// -------------------------------------------
				If !Empty(cNumTit)
					cAliasQry := GetNextAlias()
					cQuery := " SELECT R_E_C_N_O_ RECNOSE1 " 						+ CRLF
					cQuery += " FROM " + RetSQLName("SE1")							+ CRLF
					cQuery += " WHERE E1_FILIAL = '" + xFilial("SE1") + "' "		+ CRLF
					cQuery += " 	AND E1_CLIENTE = '" + UQO->UQO_CLIENT + "' "	+ CRLF
					cQuery += " 	AND E1_LOJA = '" + UQO->UQO_LOJA + "' "			+ CRLF
					cQuery += " 	AND E1_XIDFAT = '" + UQO->UQO_ID + "' "			+ CRLF
					cQuery += " 	AND D_E_L_E_T_ <> '*' "							+ CRLF

					Aadd( aTCSetField, { "RECNOSE1", "N", 17, 0	} )

					// Cria área de trabalho a partir da query definida
					MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

					If !(cAliasQry)->(EoF())
						DbSelectArea("SE1")

						While !(cAliasQry)->(EoF())
							SE1->(DbGoTo( (cAliasQry)->RECNOSE1 ))

							If SE1->(Recno()) == (cAliasQry)->RECNOSE1
								SE1->(RecLock("SE1", .F.))
									SE1->E1_XFAT518 := cNumTit
								SE1->(MsUnlock())
							EndIf

							(cAliasQry)->(DbSkip())
						EndDo
					EndIf

					(cAliasQry)->(DbCloseArea())

				EndIf

			EndIf
		EndIf

		If !lContinua
			DisarmTransaction()
		EndIf

	End Transaction

	dDataBase := dDtBaseBkp

	If lContinua
		If !lMultipFat
			If lIntegra .And. lCompensa
				MsgInfo(CAT518069, cCadastro) //#"Liquidação e compensação geradas com sucesso."
			Else
				MsgInfo(CAT518070, cCadastro) //#"Fatura gerada com sucesso."
			EndIf
		EndIf
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaUQO)
	RestArea(aArea)

Return(lContinua)

/*/{Protheus.doc} fVldInteg
Validação ao selecionar a opção de integração.
@author Juliano Fernandes
@since 26/03/2019
@return lValid, Indica se os dados da tela são válidos
@type function
/*/
Static Function fVldInteg()
	Local lValid := .T.

	//-------------------------------------------------
	// Valida se o cliente foi informado e se é válido
	//-------------------------------------------------
	If Empty(M->UQO_CLIENT)
		lValid := .F.
		MsgAlert(CAT518071, cCadastro) //#"Cliente não informado."
	EndIf

	If lValid
		lValid := fValidCli()
	EndIf

	If lValid .AND. !Empty(oGetDados)
		lValid := oGetDados:TudoOk()
	EndIf
Return(lValid)

/*/{Protheus.doc} fEmail
Envia por e-mail ao cliente o relatório da fatura gerada.
@author Paulo Carvalho
@since 25/03/2019
@type function
/*/
Static Function fEmail()

	Local cArqFat := U_PRT0555(cFatura)

Return(cArqFat)

/*/{Protheus.doc} fImprime
Executa impressão da fatura.
@author Paulo Carvalho
@since 13/03/2019
@type function
/*/
Static Function fImprime()

	// MsgAlert("Imprime relatório de fatura.", cCadastro)
	U_PRT0554(cFatura)

Return

/*/{Protheus.doc}fSetVK
Limpa todos os comandos de tecla definidos na criação da tela.
@author	Paulo Carvalho
@since 25/05/2018
@type function
/*/
Static Function fSetVK(nOpcao)

	SetKey(K_CTRL_A	, { || fGetCTE()	})
//	SetKey(K_CTRL_L	, { || Processa({|| IIf(fIntegra(nOpcao), oDialog:End(), Nil)}, CAT518017, CAT518063)}) //#"Aguarde", #"Processando integração..."
//	SetKey(K_CTRL_I	, { || fImprime()	})
//	SetKey(K_CTRL_E	, { || fEmail()	})

Return

/*/{Protheus.doc}fVKNil
Limpa todos os comandos de tecla definidos na criação da tela.
@author	Paulo Carvalho
@since 25/05/2018
@type function
/*/
Static Function fVKNil()

	SetKey (K_CTRL_A	, { || Nil })
//	SetKey (K_CTRL_L	, { || Nil })
//	SetKey (K_CTRL_R	, { || Nil })
//	SetKey (K_CTRL_I	, { || Nil })
//	SetKey (K_CTRL_E	, { || Nil })

Return

/*/{Protheus.doc} fDesTitulo
Desvincula o título da fatura.
@author Paulo Carvalho
@since 17/04/2019
@param cPrefixo, carácter, Prefixo do título a ser desvinculado da fatura.
@param cTitulo, carácter, Número do título a ser desvinculado da fatura.
@param cParcela, carácter, Parcela do título a ser desvinculado da fatura.
@param cTipo, carácter, Tipo do título a ser desvinculado da fatura.
@type function
/*/
Static Function fDesTitulo(cPrefixo, cTitulo, cParcela, cTipo)

	Local aArea		:= GetArea()
	Local aAreaSE1	:= SE1->(GetArea())

	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))	// E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO

	If SE1->(DbSeek(FWxFilial("SE1") + cPrefixo + cTitulo + cParcela + cTipo))
		RecLock("SE1", .F.)
			SE1->E1_XIDFAT := ""
		SE1->(MsUnlock())
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

Return

/*/{Protheus.doc} fVinTitulo
Vincula o título a fatura.
@author Paulo Carvalho
@since 17/04/2019
@param cPrefixo, carácter, Prefixo do título a ser desvinculado da fatura.
@param cTitulo, carácter, Número do título a ser desvinculado da fatura.
@param cParcela, carácter, Parcela do título a ser desvinculado da fatura.
@param cTipo, carácter, Tipo do título a ser desvinculado da fatura.
@type function
/*/
Static Function fVinTitulo(cPrefixo, cTitulo, cParcela, cTipo)

	Local aArea		:= GetArea()
	Local aAreaSE1	:= SE1->(GetArea())

	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))	// E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO

	If SE1->(DbSeek(FWxFilial("SE1") + cPrefixo + cTitulo + cParcela + cTipo))
		RecLock("SE1", .F.)
			SE1->E1_XIDFAT := M->UQO_ID
		SE1->(MsUnlock())
	EndIf

	RestArea(aAreaSE1)
	RestArea(aArea)

Return

/*/{Protheus.doc} fFechaTab
Encerra tabela aberta da memoria
@author Douglas Gregorio
@since 29/07/2014
@type function
/*/
Static Function fFechaTab(tab)

	If Select(tab) > 0
		DbSelectArea(tab)
		DbCloseArea()
	Endif

Return

/*/{Protheus.doc} fOrgItens
Reorganiza os itens na GetDados
@author Paulo Carvalho
@since 26/03/2019
@type function
/*/
Static Function fOrgItens()

	Local aArea			:= GetArea()
	Local aGetDadUQP	:= oGetDados:aCols

	Local cItem			:= "000"

	Local nI

	For nI := 1 To Len(aGetDadUQP)
		cItem := Soma1(cItem)
		aGetDadUQP[nI][nPsUQPItem] := cItem
	Next

	oGetDados:SetArray(aGetDadUQP)

	RestArea(aArea)

Return

/*/{Protheus.doc} fLegenda
Exibe as legendas possíveis para o status dos arquivos.
@author Paulo Carvalho
@since 25/02/2019
@type function
/*/
Static Function fLegenda()

	// Instancia browse para Legenda
	Local oLegenda	:= FWLegend():New()

	oLegenda:Add("", "BR_AMARELO"	, CAT518072) //#"Fatura em aberto"
	oLegenda:Add("", "BR_VERDE"		, CAT518073) //#"Fatura integrada"
	oLegenda:Add("", "BR_AZUL"		, CAT518074) //#"Fatura baixada parcialmente"
	oLegenda:Add("", "BR_VERMELHO"	, CAT518075) //"Fatura baixada totalmente"

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()

Return

/*/{Protheus.doc} fGetValTit
Calcula o valor do título removendo os impostos.
@author Juliano Fernandes
@since 28/10/2019
@param cPrefixo, caracter, Prefixo do título que está sendo inserido
@param cNum, caracter, Número do título que está sendo inserido
@param cParcela, caracter, Parcela do título que está sendo inserido
@param cTipo, caracter, Tipo do título que está sendo inserido
@param cCliente, caracter, Cliente do título que está sendo inserido
@param cLojaCli, caracter, Loja do título que está sendo inserido
@param nValTot, numérico, Valor total do título que está sendo inserido
@type function
/*/
Static Function fGetValTit(cPrefixo, cNum, cParcela, cTipo, cCliente, cLojaCli, nValTot)

	Local aTCSetField	:= {}
	Local aTam			:= {}

	Local cAliasQry		:= GetNextAlias()
	Local cQuery		:= ""
	Local cCposCalc		:= ""

	Local lIRRF			:= .F.

	Local nValor		:= nValTot

	cQuery := " SELECT E1_VALOR, E1_TIPO "														+ CRLF
	cQuery += " FROM " + RetSQLName("SE1") 														+ CRLF
	cQuery += " WHERE E1_FILIAL = '" + xFilial("SE1") + "' " 									+ CRLF
	cQuery += " 	AND E1_PREFIXO = '" + cPrefixo + "' " 										+ CRLF
	cQuery += " 	AND E1_NUM = '" + cNum + "' " 												+ CRLF
	cQuery += " 	AND E1_PARCELA = '" + cParcela + "' " 										+ CRLF
	cQuery += " 	AND E1_TIPO IN ('AB-','CF-','CS-','FU-','I2-','IN-','IR-','IS-','PI-') " 	+ CRLF
	cQuery += " 	AND E1_CLIENTE = '" + cCliente + "' " 										+ CRLF
	cQuery += " 	AND E1_LOJA = '" + cLojaCli + "' " 											+ CRLF
	cQuery += " 	AND D_E_L_E_T_ <> '*' " 													+ CRLF

	aTam := TamSX3("E1_VALOR") ; Aadd( aTCSetField, { "E1_VALOR", aTam[3], aTam[1], aTam[2]	} )

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	While !(cAliasQry)->(EoF())

		nValor -= (cAliasQry)->E1_VALOR

		If (cAliasQry)->E1_TIPO == "IR-"
			lIRRF := .T.
		EndIf

		(cAliasQry)->(DbSkip())

	EndDo

	fFechaTab(cAliasQry)

	// ------------------------------------------------------
	// Verifica se o título é uma Nota Fiscal de Serviço
	// ------------------------------------------------------
	If Left(cPrefixo, 2) == "NF" .And. lIRRF
		cCposCalc := "E1_PIS + E1_COFINS + E1_CSLL"
	Else
		cCposCalc := "E1_PIS + E1_COFINS + E1_IRRF + E1_CSLL"
	EndIf

	// ------------------------------------------------------
	// Quando os impostos vierem no proprio titulo
	// ------------------------------------------------------
	cQuery := " SELECT (" + cCposCalc + ") VAL_IMP "											+ CRLF
	cQuery += " FROM " + RetSQLName("SE1") 														+ CRLF
	cQuery += " WHERE E1_FILIAL = '" + xFilial("SE1") + "' " 									+ CRLF
	cQuery += " 	AND E1_PREFIXO = '" + cPrefixo + "' " 										+ CRLF
	cQuery += " 	AND E1_NUM = '" + cNum + "' " 												+ CRLF
	cQuery += " 	AND E1_PARCELA = '" + cParcela + "' " 										+ CRLF
	cQuery += " 	AND E1_TIPO = '" + cTipo + "' "		 										+ CRLF
	cQuery += " 	AND E1_CLIENTE = '" + cCliente + "' " 										+ CRLF
	cQuery += " 	AND E1_LOJA = '" + cLojaCli + "' " 											+ CRLF
	cQuery += " 	AND D_E_L_E_T_ <> '*' " 													+ CRLF

	aTam := TamSX3("E1_VALOR") ; Aadd( aTCSetField, { "VAL_IMP", aTam[3], aTam[1], aTam[2]	} )

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	While !(cAliasQry)->(EoF())

		nValor -= (cAliasQry)->VAL_IMP

		(cAliasQry)->(DbSkip())

	EndDo

	fFechaTab(cAliasQry)

Return(nValor)



/*/{Protheus.doc} fGeraExcel
Responsável por exportar para excel os dados a serem enviados para a diretoria
@author Douglas Gregorio
@since 27/11/2019
@return Nil, Nulo
@type function
/*/
Static Function fGeraExcel()
	Local aDados		:=	{}
	Local aCpoHead		:=	{}

	Local cArqXML		:=	""
	Local cNomeArq		:=	""
	Local cWorkSheet	:=	CAT518082 //"Fatura"
	Local cTable		:=	CAT518082 + ": " + cFatura
	Local lOK			:=	.T.
	Local lSalva		:=	.T.
	Local nI			:=	0

	Local nLeft			:=	1 //Alinha a esquerda
	Local nCentro		:=	2 //Centraliza
	Local nRight		:=	3 //Alinha a direita

	Local nGeral		:= 	1 //Formatação como caracter
	Local nNumber		:=	2 //Formatação como número
//	Local nMonetario	:=	3 //Formatação como moeda
	Local nDateTime		:=	4 //Formatação como Data/Hora

	Local oExcel		:=	Nil
	Local oFWMSExcel	:=	Nil

	ProcRegua(0)

	While .T.
		cArqXML := cGetFile( "*.XML",;
		CAT518109,;//Selecione o diretório para salvar o arquivo
		0,;
		IIf(IsSrvUnix(), "/SPOOL/","\SPOOL\"),;
		!lSalva,;
		GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_NETWORKDRIVE+GETF_LOCALFLOPPY,;
		.F.,;
		.F. )

		cNomeArq := SubStr(cArqXML, RAt(IIf(IsSrvUnix(), "/","\") , cArqXML) + 1 )
		cArqXML := SubStr(cArqXML, 1, RAt(IIf(IsSrvUnix(), "/","\") , cArqXML) )

		If (AllTrim(cArqXML) <> (IIf(IsSrvUnix(), "/","\")) .And. ExistDir(cArqXML)) .Or. Empty(cArqXML)
			Exit
		EndIf
	EndDo

	If Empty(cArqXML)
		lOK := .F.
	Else

		If Empty(cNomeArq)
			cNomeArq := "518" + DToS(Date()) + Replace(Time(),":","")
		EndIf

		cArqXML  += cNomeArq
	EndIf

	If lOk
		fAddCampos(@aCpoHead)
		aCols := {}
		fFillDados(2, .f.)
		aDados := aClone(aCols)

		If !Empty(aDados)
			oFWMSExcel := FWMSExcel():New()

			oFWMSExcel:AddWorkSheet(cWorkSheet)
			oFWMSExcel:AddTable(cWorkSheet, cTable) // FWX3Titulo( cField )

			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[01] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[02] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[03] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[04] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[05] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[06] )	, nCentro, nDateTime )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[07] )	, nRight, nNumber )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[08] )	, nRight, nNumber )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, ""							, nRight, nNumber )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[10] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[11] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[12] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[13] )	, nLeft, nGeral )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[14] )	, nCentro, nDateTime )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[15] )	, nRight, nNumber )
			oFWMSExcel:AddColumn( cWorkSheet, cTable, FWX3Titulo( aCpoHead[16] )	, nRight, nNumber )

			For nI := 1 To Len(aDados)
				IncProc()

				aSize(aDados[nI],16 )

				oFWMSExcel:AddRow( cWorkSheet, cTable , aDados[nI] )
			Next nI

			oFWMSExcel:Activate()
			oFWMSExcel:GetXMLFile(cArqXML + ".xls")

			oExcel := MSExcel():New()
			oExcel:WorkBooks:Open(cArqXML + ".xls")
			oExcel:SetVisible( .T.)

			oFWMSExcel:DeActivate()
			oExcel:Destroy()

			MsgAlert(CAT518083 + CRLF + CRLF + cArqXML + ".xls", cCadastro) // "Arquivo gerado com sucesso."
		Else
			MsgAlert(CAT518084 , cCadastro) // "Nenhum registro encontrado."
		EndIf

	EndIf

Return

/*/{Protheus.doc} fOrdBrw
Função para ordernar registros pela coluna clicada
@author Douglas Gregorio
@since 29/08/2018
@param oObjGet, object, Getdados com dados
@param nColPos, numerico, posição da coluna clicada
@type function
/*/
Static Function fOrdBrw( oGet, nCol )

	Private nColuna := nCol

	If AScan(aColNaoOrd, nCol) == 0
		nOrdena := 0

		If !Empty(aGetDados)
			aGetDados := &("aSort( aGetDados,,,{|a,b| a[nColuna]" + If(lCrescente,"<",">") + " b[nColuna]})")

			lCrescente := If(lCrescente,.F.,.T.)

			oGetDados:SetArray(aGetDados)
			oGetDados:Refresh()
		EndIf
	EndIf

Return

/*/{Protheus.doc} fGetValFat
Retorna o valor total da fatura.
@author Juliano Fernandes
@since 05/02/2020
@version 1.0
@param lFaturaNFS, logico, Indica se é uma fatura de NF de serviço (Referência)
@param cNatTitulo, caracter, Natureza do título da NF de serviço (Referência)
@return nValFat, Valor total da fatura
@type function
/*/
Static Function fGetValFat(lFaturaNFS, cNatTitulo)

	Local aArea			:= GetArea()
	Local aAreaUQO		:= UQO->(GetArea())
	Local aAreaUQP		:= UQP->(GetArea())
	Local aAreaSE1		:= SE1->(GetArea())

	Local cPrefixo		:= ""
	Local cChvSE1		:= ""

	Local nValItem		:= 0
	Local nValFat		:= 0
	Local nQtdIteFat	:= 0

	DbSelectArea("UQP")
	UQP->(DbSetOrder(1)) // UQP_FILIAL+UQP_IDFAT+UQP_ITEM+UQP_TPFAT+UQP_PFXFAT+UQP_TITFAT+UQP_PARFAT
	If UQP->(DbSeek(xFilial("UQP") + UQO->UQO_ID))
		While !UQP->(EoF()) .And. UQP->UQP_FILIAL == xFilial("UQP") .And. UQP->UQP_IDFAT == UQO->UQO_ID
			nQtdIteFat++

			cPrefixo := UQP->UQP_PFXFAT

			cChvSE1 := xFilial("SE1")
			cChvSE1 += UQO->UQO_CLIENT
			cChvSE1 += UQO->UQO_LOJA
			cChvSE1 += UQP->UQP_PFXFAT
			cChvSE1 += UQP->UQP_TITFAT
			cChvSE1 += UQP->UQP_PARFAT
			cChvSE1 += UQP->UQP_TPFAT

			DbSelectArea("SE1")
			SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			If SE1->(DbSeek( cChvSE1 ))
				If AllTrim(SE1->E1_TIPO) $ "NCC|RA"
					// -----------------------------------------------------------------------------------------
					// Se for um título NCC ou RA não soma o valor pois o mesmo será somado na função fIntegra
					// -----------------------------------------------------------------------------------------
					nValItem := 0
				Else
					nValItem := SE1->E1_VALOR
				EndIf

				If Empty(cNatTitulo)
					cNatTitulo := SE1->E1_NATUREZ
				EndIf
			Else
				nValItem := 0
			EndIf

			// -------------------------------------------------------------------------
			// Ajusta valor caso tenha sido informado títulos NDC (+) ou NCC e RA (-)
			// -------------------------------------------------------------------------
			If !Empty(UQP->UQP_TITULO) .And. !Empty(UQP->UQP_TIPO)
				If AllTrim(UQP->UQP_TIPO) $ "NDC"
					nValItem += UQP->UQP_VALOR
				ElseIf AllTrim(UQP->UQP_TIPO) $ "NCC|RA"
					nValItem -= UQP->UQP_VALOR
				EndIf
			EndIf

			nValFat += nValItem

			UQP->(DbSkip())
		EndDo
	EndIf

	If nQtdIteFat == 1
		// -----------------------------------------------------------------------
		// Verifica se o título do ítem da fatura é uma Nota Fiscal de Serviço
		// -----------------------------------------------------------------------
		If Left(cPrefixo, 2) == "NF"
			lFaturaNFS := .T.
		Else
			lFaturaNFS := .F.
			cNatTitulo := ""
		EndIf
	Else
		lFaturaNFS := .F.
	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaUQP)
	RestArea(aAreaUQO)
	RestArea(aArea)

Return(nValFat)

/*/{Protheus.doc} fMultipFat
Monta a tela para a exibição de múltiplas faturas para envio por e-mail ou integração.
@author Juliano Fernandes
@since 16/12/2019
@version 1.0
@return Nil, Não há retorno
@param nOpcao, numerico, Opção do menu
@type function
/*/
Static Function fMultipFat(nOpcao)

	Local aAreas			:= {}
	Local aCBStatus			:= fGetStatFat()
	Local aButtons			:= {}
	Local aFaturas			:= {}
	Local aIntegra			:= {}

	Local bEnchoice			:= {|| }
	Local bOk				:= {|| lContinua := fVldConf(nOpcao) }
	Local bCancel			:= {|| lContinua := .F., oDialogFat:End() }

	Local cCadOld			:= cCadastro
	Local cTitulo			:= IIf(nOpcao == 12, CAT518088, CAT518089) // "Enviar Múltiplas Faturas" "Integrar Múltiplas Faturas"
	Local cFatura			:= ""
	Local cArqZIP			:= "ft" + DToS(Date()) + StrTran(Time(),":","") + ".zip"

	Local lCentered			:= .T.
	Local lFocSel			:= .T.
	Local lHasButton		:= .T.
	Local lHasOk			:= .T.
	Local lNoButton			:= .T.
	Local lPassword			:= .T.
	Local lPixel			:= .T.
	Local lPictPriority		:= .T.
	Local lReadOnly			:= .T.
	Local lTransparent		:= .T.
	Local lHtml				:= .T.
	Local lContinua			:= .F.
	Local lIntegra			:= .F.

	Local nTopFat			:= 0
	Local nLeftFat			:= 0
	Local nBottomFat		:= 0
	Local nRightFat			:= 0
	Local nRow				:= 0
	Local nCol				:= 0
	Local nWidth			:= 0
	Local nHeight			:= 0
	Local nRowElem			:= 2
	Local nColRight			:= 0
	Local nLblPos			:= 1
	Local nRecno			:= 0
	Local nI				:= 0

	Local oFiltroFat		:= Nil
	Local oGCliente			:= Nil
	Local oGLojaCli			:= Nil
	Local oGNomeCli			:= Nil
	Local oGEmissaoDe		:= Nil
	Local oGEmissaoAte		:= Nil
	Local oGVenctoDe		:= Nil
	Local oGVenctoAte		:= Nil
	Local oSStatus			:= Nil
	Local oCBStatus			:= Nil
	Local oGCodUsuar		:= Nil
	Local oGNomUsuar		:= Nil

	Private aHeaderUQO		:= {}
	Private a518WrkAre		:= {}

	Private bVldCli			:= {|| If(nOpcao == 13, fVldCliente(nOpcao), NaoVazio() .And. fVldCliente())}

	Private cGCliente		:= Space(TamSX3("A1_COD" )[1])
	Private cGLojaCli		:= Space(TamSX3("A1_LOJA")[1])
	Private cGNomeCli		:= Space(TamSX3("A1_NOME")[1])
	Private cCBStatus		:= Left(aCBStatus[1],1)
	Private cGCodUsuar		:= Space( 6 )
	Private cGNomUsuar		:= Space( 25 )
	Private c518DirFat		:= ""
	Private c518Email		:= ""
	Private c518Faturas		:= ""
	Private cErroInteg		:= ""

	Private dGEmissaoDe		:= CToD("  /  /  ")
	Private dGEmissaoAte	:= CToD("  /  /  ")
	Private dGVenctoDe		:= CToD("  /  /  ")
	Private dGVenctoAte		:= CToD("  /  /  ")

	Private lAutoErrNoFile	:= .T.

	Private n518WrkAre		:= 0

	Private oSizeFat		:= Nil
	Private oDialogFat		:= Nil
	Private oGetDadFat		:= Nil
	Private oAmarelo		:= LoadBitmap( GetResources(), "BR_AMARELO" )	// UQO_STATUS == '1' - Fatura Em Aberto
	Private oVerde			:= LoadBitmap( GetResources(), "BR_VERDE"	)	// UQO_STATUS == '2' - Fatura Integrada
	Private oAzul			:= LoadBitmap( GetResources(), "BR_AZUL"	)	// UQO_STATUS == '3' - Fatura Baixada parcialmente
	Private oVermelho		:= LoadBitmap( GetResources(), "BR_VERMELHO")	// UQO_STATUS == '4' - Fatura Baixada totalmente

	Aadd(aAreas, GetArea())
	Aadd(aAreas, UQO->(GetArea()))
	Aadd(aAreas, UQP->(GetArea()))

	SetKey(K_CTRL_M	, { || fSetChkFat(1) }) // Marcar todos
	SetKey(K_CTRL_D	, { || fSetChkFat(2) }) // Desmarcar todos
	SetKey(K_CTRL_I	, { || fSetChkFat(3) }) // Inverter seleção

	cCadastro := NomePrt + " - " + cTitulo + " - " + VersaoJedi

	// Instancia o objeto para controle das coordenadas da aplicação
	oSizeFat := FWDefSize():New( .T. ) // Indica que a tela terá EnchoiceBar

	// Define que os objetos não serão expostos lado a lado
	oSizeFat:lProp		:= .T.
	oSizeFat:lLateral	:= .F.

	// Adiciona ao objeto oSizeFat os objetos que irão compor a tela
	oSizeFat:AddObject( "FILTROS" , 100, 020, .T., .T. )
	oSizeFat:AddObject( "GETDADOS", 100, 080, .T., .T. )

	// Realiza o cálculo das coordenadas
	oSizeFat:Process()

	// Define as coordenadas da Dialog principal
	nTopFat		:= oSizeFat:aWindSize[1]
	nLeftFat	:= oSizeFat:aWindSize[2]
	nBottomFat	:= oSizeFat:aWindSize[3]
	nRightFat	:= oSizeFat:aWindSize[4]

	nRow		:= oSizeFat:GetDimension( "FILTROS", "LININI" )
	nCol		:= oSizeFat:GetDimension( "FILTROS", "COLINI" )
	nWidth		:= oSizeFat:GetDimension( "FILTROS", "XSIZE"  )
	nHeight		:= oSizeFat:GetDimension( "FILTROS", "YSIZE"  )

	nColRight	:= oSizeFat:GetDimension( "FILTROS", "COLEND" ) - 55

	// Instancia a classe MSDialog
	oDialogFat := MsDialog():New(	nTopFat, nLeftFat, nBottomFat, nRightFat, cCadastro,;
									/*uParam6*/, /*uParam7*/, /*uParam8*/,;
									nOr( WS_VISIBLE, WS_POPUP ), /*nClrText*/, /*nClrBack*/,;
									/*uParam12*/, /*oWnd*/, lPixel, /*uParam15*/,;
									/*uParam16*/, /*uParam17*/, !lTransparent )

	// Cria o painel de filtros
	oFiltroFat	:= TPanel():New(	nRow, nCol, /*cTexto*/, oDialogFat, /*oFont*/, lCentered,;
									/*uParam7*/, /*nClrText*/, /*nClrBack*/, nWidth, nHeight,;
									/*lLowered*/, /*lRaised*/ )

	// Cliente
	oGCliente		:= TGet():New( 	nRowElem, 002, {|u| IIf(PCount() > 0, cGCliente := u, cGCliente)}, oFiltroFat, 050, 011,;
									/*cPicture*/, bVldCli,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SA1", "cGCliente",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518090, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;		// "Cliente"
									!lPictPriority, lFocSel )

	// Loja
	oGLojaCli		:= TGet():New( 	nRowElem, 057, {|u| IIf(PCount() > 0, cGLojaCli := u, cGLojaCli)}, oFiltroFat, 020, 011,;
									/*cPicture*/, bVldCli,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*F3*/, "cGLojaCli",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518091, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;		// "Loja"
									!lPictPriority, lFocSel )

	// Razão Social
	oGNomeCli		:= TGet():New( 	nRowElem, 082, {|u| IIf(PCount() > 0, cGNomeCli := u, cGNomeCli)}, oFiltroFat, 140, 011,;
									/*cPicture*/"@!", /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*F3*/, "cGNomeCli",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518092, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;		// "Razão Social"
									!lPictPriority, lFocSel )

	oGNomeCli:Disable()

	// Emissão de
	oGEmissaoDe		:= TGet():New(	nRowElem, 227, {|u| IIf(PCount() > 0, dGEmissaoDe := u, dGEmissaoDe)}, oFiltroFat, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dGEmissaoDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518093, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; 	// "Emissão de"
									!lPictPriority, lFocSel )

	// Emissão ate
	oGEmissaoAte	:= TGet():New(	nRowElem, 302, {|u| IIf(PCount() > 0, dGEmissaoAte := u, dGEmissaoAte)}, oFiltroFat, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dGEmissaoAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518094, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Emissão até"
									!lPictPriority, lFocSel )

	// Vencimento de
	oGVenctoDe		:= TGet():New(	nRowElem, 377, {|u| IIf(PCount() > 0, dGVenctoDe := u, dGVenctoDe)}, oFiltroFat, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dGVenctoDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518095, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;		// "Vencimento de"
									!lPictPriority, lFocSel )

	// Vencimento ate
	oGVenctoAte		:= TGet():New(	nRowElem, 452, {|u| IIf(PCount() > 0, dGVenctoAte := u, dGVenctoAte)}, oFiltroFat, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dGVenctoAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT518096, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Vencimento até"
									!lPictPriority, lFocSel )

	// Status
	oSStatus		:= TSay():New( 	nRowElem, 527, {|| CAT518097}, oFiltroFat, /*cPicture*/, /*oFont*/,; // "Status"
									/*uParam7*/, /*uParam8*/, /*uParam9*/, lPixel, /*nClrText*/,;
									/*nCrlBack*/, 070, 010, /*uParam15*/, /*uParam16*/, /*uParam17*/,;
									/*uParam18*/, /*uParam19*/, !lHtml, /*nTxtAlgHor*/,  /*nTxtAlgVer*/ )

	oCBStatus		:= TComboBox():New(	nRowElem + 8, 527, {|u| IIf(PCount() > 0, cCBStatus := u, cCBStatus) }, aCBStatus, 080, 013, oFiltroFat,;
									/*uParam8*/, /*bChange*/, /*bValid*/, /*nClrText*/,;
									/*nClrBack*/, lPixel, /*oFont*/, /*uParam15*/, /*uParam16*/, ;
									/*bWhen*/, /*uParam18*/, /*uParam19*/, /*uParam20*/, /*uParam21*/, ;
									cCBStatus, /*cLabelText*/, /*nLabelPos*/, /*nLabelFont*/,	/*nLabelColor*/	)

	If nOpcao == 13 // Integrar Faturas
		cCBStatus := Left(aCBStatus[2],1)
		oCBStatus:Disable()
	EndIf

	nRowElem += 25

	// Cod. Usuário
	oGCodUsuar	:= TGet():New( 	nRowElem, 002, {|u| IIf(PCount() > 0, cGCodUsuar := u, cGCodUsuar)}, oFiltroFat, 050, 011,;
								"@!", {|| fVldUsuar()},/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "USRPER", "cGCodUsuar",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT533045, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Cod. Usuário"
								!lPictPriority, lFocSel )

	// Nome (Usuario)
	oGNomUsuar	:= TGet():New( 	nRowElem, 057, {|u| IIf(PCount() > 0, cGNomUsuar := u, cGNomUsuar)}, oFiltroFat, 165, 011,;
								"@!", /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "cGNomUsuar",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT533046, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Usuário"
								!lPictPriority, lFocSel )
	oGNomUsuar:Disable()


	// Botão Filtrar
	oBtnFiltrar		:= TButton():New( 008, nColRight, CAT528043, oFiltroFat, {|| Processa({|| fFiltraFat()},CAT544001,CAT544002)}, 050, 015,;	// "Pesquisar" "Aguarde" "Filtrando Registros..."
									/*uParam8*/, /*oFont*/, /*uParam10*/, lPixel, /*uParam12*/, /*uParam13*/,;
									/*uParam14*/, /*bWhen*/, /*uParam16*/, /*uParam17*/	)

	fGetDadFat()

	Aadd( aButtons, { "", {|| fLegenda()   }, CAT528007 } )	// #"Legenda"
	Aadd( aButtons, { "", {|| fDetalhes()  }, CAT528008 } )	// #"Detalhes"
	Aadd( aButtons, { "", {|| fSetChkFat(1)}, CAT528014 } )	// #"Marcar todos"
	Aadd( aButtons, { "", {|| fSetChkFat(2)}, CAT528015 } )	// #"Desmarcar todos"
	Aadd( aButtons, { "", {|| fSetChkFat(3)}, CAT528016 } )	// #"Inverter seleção"

	// Define EnchoiceBar
	bEnchoice		:= {|| 	EnchoiceBar( oDialogFat, bOk, bCancel, .F., @aButtons, /*nRecno*/,;
							/*cAlias*/, .F., .F., .F., lHasOk, .F., ) }

	// Ativa a Dialog para visualização de log de registros
	oDialogFat:Activate( 	/*uParam1*/, /*uParam2*/, /*uParam3*/, lCentered,;
							/*bValid*/,/*uParam6*/, bEnchoice, /*uParam8*/, /*uParam9*/	)

	If lContinua
		lContinua := .F.

		For nI := 1 To Len(oGetDadFat:aCols)
			If oGetDadFat:aCols[nI,1]:cName == "LBOK"
				lContinua := .T.
				Exit
			EndIf
		Next nI

		If lContinua
			If nOpcao == 12

				// --------------------
				// E-mail Faturas
				// --------------------

				For nI := 1 To Len(oGetDadFat:aCols)
					If oGetDadFat:aCols[nI,1]:cName == "LBOK"
						nRecno := GDFieldGet("UQO_REC_WT",nI,,oGetDadFat:aHeader,oGetDadFat:aCols)

						UQO->(DbGoTo(nRecno))

						If UQO->(Recno()) == nRecno
							c518Faturas += AllTrim(UQO->UQO_NUMERO) + ", "

							MsgRun(CAT518108 + UQO->UQO_NUMERO, CAT518099, {|| cFatura := U_fMain518("UQO", nRecno, 8)}) // "Gerando a fatura "

							Aadd(aFaturas, cFatura)
						EndIf
					EndIf
				Next nI

				If !Empty(aFaturas)
					If Len(aFaturas) > 1
						// Deleta arquivo Faturas.zip caso já exista o arquivo no diretório
						FErase( c518DirFat + cArqZIP )

						// Gera arquivo zip com as faturas geradas
						FZip( c518DirFat + cArqZIP, aFaturas, c518DirFat )

						MsgRun(CAT518098, CAT518099, {|| Sleep(5000)}) // "Gerando email com as faturas" "Aguarde"

						c518Faturas := AllTrim(c518Faturas)

						While Right(c518Faturas, 1) == ","
							c518Faturas := Left(c518Faturas, Len(c518Faturas) - 1)
							c518Faturas := AllTrim(c518Faturas)
						EndDo

						If File( c518DirFat + cArqZIP )
							StaticCall(PRT0555, fEmail, c518DirFat + cArqZIP)
						EndIf

						MsgRun(CAT518098, CAT518099, {|| Sleep(10000)}) // "Gerando email com as faturas" "Aguarde"

						// Deleta os arquivos gerados
						AEval(aFaturas, {|x| FErase(x)})

						FErase( c518DirFat + cArqZIP )
					Else
						// Deleta arquivo Faturas.zip caso já exista o arquivo no diretório
						FErase( c518DirFat + aFaturas[1] )

						MsgRun(CAT518100, CAT518099, {|| Sleep(5000)}) // "Gerando email com a fatura" "Aguarde"

						c518Faturas := AllTrim(c518Faturas)

						While Right(c518Faturas, 1) == ","
							c518Faturas := Left(c518Faturas, Len(c518Faturas) - 1)
							c518Faturas := AllTrim(c518Faturas)
						EndDo

						If File( aFaturas[1] )
							StaticCall(PRT0555, fEmail, aFaturas[1])
						EndIf

						MsgRun(CAT518100, CAT518099, {|| Sleep(10000)}) // "Gerando email com a fatura" "Aguarde"

						// Deleta os arquivos gerados
						AEval(aFaturas, {|x| FErase(x)})

						FErase( aFaturas[1] )
					EndIf
				EndIf

			Else // nOpcao == 13

				// --------------------
				// Integrar Faturas
				// --------------------

				If Empty(a518WrkAre)
					a518WrkAre := fGetWorkArea()
					n518WrkAre := Len(a518WrkAre)
				EndIf

				For nI := 1 To Len(oGetDadFat:aCols)
					If oGetDadFat:aCols[nI,1]:cName == "LBOK"
						nRecno := GDFieldGet("UQO_REC_WT",nI,,oGetDadFat:aHeader,oGetDadFat:aCols)

						UQO->(DbGoTo(nRecno))

						If UQO->(Recno()) == nRecno
							cErroInteg := ""

							MsgRun(CAT518107 + UQO->UQO_ID, CAT518099, {|| lIntegra := U_fMain518("UQO", nRecno, 6)}) // "Integrando a fatura " "Aguarde"

							Aadd(aIntegra, {	Nil				,; // Legenda
												UQO->UQO_ID		,;
												UQO->UQO_NUMERO	,;
												UQO->UQO_CLIENT	,;
												UQO->UQO_LOJA	,;
												UQO->UQO_NOMECL	,;
												UQO->UQO_VENCTO	,;
												UQO->UQO_TOTAL	,;
												Nil				}) // Mensagem

							If lIntegra
								aIntegra[Len(aIntegra)][01] := "BR_VERDE"
								aIntegra[Len(aIntegra)][09] := CAT518101 // "Fatura integrada com sucesso "
							Else
								aIntegra[Len(aIntegra)][01] := "BR_VERMELHO"
								aIntegra[Len(aIntegra)][09] := CAT518102 + cErroInteg // "Erro ao integrar fatura "
							EndIf

							fRestWorkArea()
						EndIf
					EndIf
				Next nI

				MsgInfo(CAT518103, cCadastro) // "Processamento finalizado."

				fResultInt(aIntegra)
			EndIf
		Else
			MsgAlert(CAT518043, cCadastro) // "Nenhum registro selecionado."
		EndIf
	EndIf

	SetKey(K_CTRL_M	, Nil)
	SetKey(K_CTRL_D	, Nil)
	SetKey(K_CTRL_I	, Nil)

	cCadastro := cCadOld

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fGetDadFat
Cria a GetDados para Faturas.
@author Juliano Fernandes
@since 16/12/2019
@version 1.01
@type Function
/*/
Static Function fGetDadFat()

    Local aAreas		:= {}
    Local aArray		:= {}
    Local aCampos		:= {}
    Local aAlterFat		:= {}

	Local bChange       := {|| }

    Local nH, nI, nJ

	Local nRow			:= 0
	Local nLeft			:= 0
	Local nBottom		:= 0
	Local nRight		:= 0

	Aadd(aAreas, GetArea())
	Aadd(aAreas, SX3->(GetArea()))

    // Reinicia o array aHeader
    aHeaderUQO 	:= {}
    aCampos 	:= {}

	// Define as coordenadas seguindo o padrão de criação da página
	nRow	:= oSizeFat:GetDimension( "GETDADOS", "LININI" )
	nLeft	:= oSizeFat:GetDimension( "GETDADOS", "COLINI" )
	nBottom	:= oSizeFat:GetDimension( "GETDADOS", "LINEND" ) + 15 // + 15 para compensar a falta da barra de título
	nRight	:= oSizeFat:GetDimension( "GETDADOS", "COLEND" )

	// Adiciona, manualmente, os campos da tabela que serão visualizados para o array aCampos
	Aadd( aCampos, "UQO_ID"		)
	Aadd( aCampos, "UQO_NUMERO"	)
	Aadd( aCampos, "UQO_EMISSA"	)
	Aadd( aCampos, "UQO_CLIENT"	)
	Aadd( aCampos, "UQO_LOJA"	)
	Aadd( aCampos, "UQO_NOMECL"	)
	Aadd( aCampos, "UQO_VENCTO"	)
	Aadd( aCampos, "UQO_USUARI"	)
	Aadd( aCampos, "UQO_OBS"	)
	Aadd( aCampos, "UQO_TOTAL"	)

	// Adiciona campo para legenda no aHeader
	fAddCheck( @aHeaderUQO )

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeaderUQO )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		fAddHeader( @aHeaderUQO, aCampos[nI] )
	Next nI

	// Adiciona o Alias e o Recno
    AdHeadRec( "UQO", aHeaderUQO )

	// Popula o array com dados inicias em branco.
	Aadd( aArray, oNo )
	Aadd( aArray, oAmarelo )

	For nJ := 3 To Len( aHeaderUQO ) - 2
		Aadd( aArray, CriaVar( aHeaderUQO[nJ][2], .T. ) )
    Next nJ

    Aadd( aArray, "UQO" 	) // Alias WT
    Aadd( aArray, 0 		) // Recno WT
	Aadd( aArray, .F. 		) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len(aHeaderUQO)
		If Empty(aHeaderUQO[nH][3]) .And. aHeaderUQO[nH][8] == "C"
			aHeaderUQO[nH][3] := "@!"
		EndIf
	Next nH

	Aadd(aAlterFat, "UQO_OBS")

	// Instancia a GetDados
	oGetDadFat   := MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
											/*cIniCpos*/, aAlterFat, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
											/*cDelOk*/, oDialogFat, aHeaderUQO, { aArray }, bChange, /*cTela*/	)

	oGetDadFat:oBrowse:bLDblClick := {|| fLDblClick(), oGetDadFat:oBrowse:Refresh()}

	// Impede a edição de linha
	oGetDadFat:SetEditLine( .F. )

	// Atualiza a GetDados
	oGetDadFat:Refresh()

	fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fVldConf
Função para validar a confirmação do usuário na integração e envio de multiplas faturas.
@author Paulo Carvalho
@since 03/03/2020
@param nOpcao, numérico, Opção selecionada pelo usuário.
@version 12.1.25
@type function
/*/
Static Function fVldConf(nOpcao)

	Local cMensagem		:= ""
	Local lValida		:= .T.

	// Define a mensagem a ser exibida de acordo com a rotina selecionada.
	If nOpcao == 13
		cMensagem := CAT518105	// #"Deseja realmente integrar as faturas selecionadas?"
	Else
		cMensagem := CAT518106	// #"Deseja realmente enviar as faturas selecionadas?"
	EndIf

	// Valida junto ao usuárioa a execução da rotina.
	If !MsgYesNo(cMensagem, cCadastro)
		lValida := .F.
	Else
		oDialogFat:End()
	EndIf

Return lValida

/*/{Protheus.doc} fResultInt
Rotina responsável pela exibição dos resultados da integração múltipla de faturas.
@author Paulo Carvalho
@since 03/03/2020
@param aIntegra, array, Array contendo o resultado da integração de cada fatura selecionada.
@version 12.1.25
@type function
/*/
Static Function fResultInt(aIntegra)

	Local aBotoesEnc		:= {}

	Local bOk				:= {|| oDlgResult:End() }
	Local bCancel			:= {|| oDlgResult:End() }
	Local bEnchoice			:= {|| }
	Local bActLegend		:= {|| fLegLog() }
	Local bExpExcel			:= {|| fExpExcel() }

	Local lCentered			:= .T.
	Local lPixel			:= .T.
	Local lTransparent		:= .T.

	Local nTop				:= 0
	Local nLeft				:= 0
	Local nBottom			:= 0
	Local nRight			:= 0

	Private oGreen 			:= LoadBitmap( GetResources(), "BR_VERDE" 	 )
	Private oRed   			:= LoadBitmap( GetResources(), "BR_VERMELHO" )
	Private oDlgResult		:= Nil
	Private oGdResult		:= Nil
	Private oSizeRes		:= Nil

	// Instancia o objeto para controle das coordenadas da aplicação
	oSizeRes := FWDefSize():New( .T. ) // Indica que a tela terá EnchoiceBar

	// Define que os objetos não serão expostos lado a lado
	oSizeRes:lProp := .T.
	oSizeRes:lLateral := .F.

	// Adiciona ao objeto oSizeRes os objetos que irão compor a tela
	oSizeRes:AddObject( "GETDADOS", 100, 100, .T., .T. )

	// Realiza o cálculo das coordenadas
	oSizeRes:Process()

	// Define as coordenadas da Dialog principal
	nTop	:= oSizeRes:aWindSize[1]
	nLeft	:= oSizeRes:aWindSize[2]
	nBottom	:= oSizeRes:aWindSize[3]
	nRight	:= oSizeRes:aWindSize[4]

	// Instancia a classe MSDialog
	oDlgResult 	:= MSDialog():New( 	nTop, nLeft, nBottom, nRight, cCadastro,;
									/*uParam6*/, /*uParam7*/, /*uParam8*/,;
									nOr( WS_VISIBLE, WS_POPUP ), /*nClrText*/, /*nClrBack*/,;
									/*uParam12*/, /*oWnd*/, lPixel, /*uParam15*/,;
									/*uParam16*/, /*uParam17*/, !lTransparent )

	// Monta a GetDados dos resultados
	fGetResult(aIntegra)

	// Define os botões da Enchoice
	Aadd(aBotoesEnc, {"", bActLegend, CAT518011}) // "Legenda"
	Aadd(aBotoesEnc, {"", bExpExcel , CAT518085}) // "Exportar Excel"

	bEnchoice := {|| EnchoiceBar( oDlgResult, bOk ,	bCancel, .F., aBotoesEnc, /*nRecno*/,;
					 /*cAlias*/, .F., .F., .F., .F., .F., ) }

	// Ativa a Dialog para visualização de log das integrações
	oDlgResult:Activate(/*uParam1*/, /*uParam2*/, /*uParam3*/, lCentered,;
						/*bValid*/,/*uParam6*/, bEnchoice, /*uParam8*/, /*uParam9*/	)

Return

/*/{Protheus.doc} fGetResult
Rotina para criação da GetDados de exibição dos resultados da integração múltipla.
@author  Paulo Carvalho
@since   03/03/2020
@param	 aIntegra, array, array contendo o resultado da integração
@version 12.1.25
@type    Static Function
/*/
Static Function fGetResult(aIntegra)

	Local aCampos	:= {}
	Local aHdResult	:= {}
	Local aAlter	:= {}
	Local aArray	:= {}

	Local nJ

	Local nRow		:= 0
	Local nLeft		:= 0
	Local nBottom	:= 0
	Local nRight	:= 0

	Aadd(aCampos, "UQO_ID"     )
	Aadd(aCampos, "UQO_NUMERO" )
	Aadd(aCampos, "UQO_CLIENT" )
	Aadd(aCampos, "UQO_LOJA"   )
	Aadd(aCampos, "UQO_NOMECL" )
	Aadd(aCampos, "UQO_VENCTO" )
	Aadd(aCampos, "UQO_TOTAL"  )
	Aadd(aCampos, "UQF_MSG"    ) // Utilizado apenas a estrutura do campo UQF_MSG

	// Define as coordenadas seguindo o padrão de criação da página
	nRow	:= oSizeRes:GetDimension( "GETDADOS", "LININI" )
	nLeft	:= oSizeRes:GetDimension( "GETDADOS", "COLINI" )
	nBottom	:= oSizeRes:GetDimension( "GETDADOS", "LINEND" ) + 15 // + 15 para compensar a falta da barra de título
	nRight	:= oSizeRes:GetDimension( "GETDADOS", "COLEND" )

	// Adiciona campo para legenda no aHeader
	fAddLegenda(@aHdResult)

	// Adiciona os campos necessários no aHeader
	For nJ := 1 To Len(aCampos)
		fAddHeader(@aHdResult, aCampos[nJ])
	Next nJ

	// Popula o array com dados inicias em branco.
	For nJ := 1 To Len( aHdResult )
		If aHdResult[nJ][8] == "D"
			Aadd( aArray, CtoD( "  /  /  " ) )
		ElseIf aHdResult[nJ][8] == "C"
			Aadd( aArray, Space( aHdResult[nJ][4] ) )
		ElseIf aHdResult[nJ][8] == "N"
			Aadd( aArray, 0 )
		Else
			Aadd( aArray, Nil )
		EndIf
	Next

	Aadd( aArray, .F. ) // D_E_L_E_T_

	// Instancia a GetDados
	oGdResult	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, /*nStyle*/, /*cLinhaOk*/, /*cTudoOk*/,;
									/*cIniCpos*/, aAlter, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
									/*cDelOk*/, oDlgResult, aHdResult, { aArray }, /*bChange*//*uChange*/, /*cTela*/)

	// Preenche a GetDados
	fFillResult(aIntegra)

Return

/*/{Protheus.doc} fFillResult
Rotina para preencher a GetDados com os resultados da integração de múltiplas faturas.
@author  Paulo Carvalho
@since   04/03/2020
@param   aIntegra, array, array contendo os resultados da integração
@version 12.1.25
@type    Function
/*/
Static Function fFillResult(aIntegra)

	Local aDados		:= {}
	Local aLinha		:= {}

	Local nI, nJ
	Local nPosLegenda	:= 1

	// Preenche a GetDados com os resultados
	For nI := 1 To Len(aIntegra)
		// Limpa os dados da Linha
		aLinha := {}

		// Define a legenda
		If aIntegra[nI][nPosLegenda] == "BR_VERDE"
			Aadd(aLinha, oGreen)
		ElseIf aIntegra[nI][nPosLegenda] == "BR_VERMELHO"
			Aadd(aLinha, oRed)
		EndIf

		// Adiciona os demais campos da tela
		For nJ := 2 To Len(aIntegra[nI])
			Aadd(aLinha, aIntegra[nI][nJ])
		Next nJ

		Aadd(aLinha, .F.)

		// Adiciona a linha ao array de dados principal
		Aadd(aDados, aLinha)
	Next nI

	// Popula a GetDados
	oGdResult:SetArray(aDados)

	// Atualiza a GetDados
	oGdResult:Refresh()

Return

/*/{Protheus.doc} fLegLog
Exibe as legendas do log de integração possíveis ao usuário.
@author Paulo Carvalho
@since 03/03/2020
@version 12.1.25
@type Static Function
/*/
Static Function fLegLog()

	// Instancia browse para Legenda
	Local oLegenda	:= FWLegend():New()

	oLegenda:Add( "", "BR_VERDE"	, CAT518101 ) // Fatura integrada com sucesso
	oLegenda:Add( "", "BR_VERMELHO"	, CAT518102 ) // Erro ao integrar fatura

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()

Return

/*/{Protheus.doc} fExpExcel
Exportar os resultados da integração de múltiplas faturas para Excel
@author  Paulo Carvalho
@since   04/03/2020
@version 12.1.25
@type    Function
/*/
Static Function fExpExcel()

	Local aCabec		:= oGdResult:aHeader
	Local aDados		:= oGdResult:aCols
	Local aRow			:= {}

	Local cMascara		:= "*.xml"
	Local cTitulo		:= CAT518109 // "Selecione o diretório para salvar o arquivo"
	Local cDirinicial	:= ""
	Local cDirXML		:= ""
	Local cNomeArq		:= ""
	Local cTabela		:= CAT533005 // "Integração"
	Local cWorkSheet	:= CAT533005 // "Integração"

	Local lSalvar		:= .F.
	Local lArvore		:= .F.
	Local lKeepCase		:= .F.
	Local lContinua		:= .T.
	Local lTotal		:= .T.

	Local nMascPadrao	:= 0
	Local nOpcoes		:= GETF_RETDIRECTORY + GETF_LOCALHARD + GETF_NETWORKDRIVE + GETF_LOCALFLOPPY
	Local nI, nJ
	Local nEsquerda 	:= 1
	Local nCentro   	:= 2
	Local nDireita  	:= 3
	Local nGeral    	:= 1
	Local nNumero   	:= 2
	Local nMoeda    	:= 3
	Local nData     	:= 4

	Local oExcel		:= Nil
	Local oMsExcel		:= Nil

	While .T.
		cDirXML := CGetFile( cMascara, cTitulo, nMascPadrao, cDirinicial, lSalvar, nOpcoes, lArvore, lKeepCase )

		If (AllTrim(cDirXML) != (IIf(IsSrvUnix(),"/","\")) .And. ExistDir(cDirXML)) .Or. Empty(cDirXML)
			Exit
		EndIf
	EndDo

	If Empty(cDirXML)
		lContinua := .F.
	Else
		cNomeArq := "IntMult" + DToS(Date()) + Replace(Time(),":","")
		cDirXML  += cNomeArq
	EndIf

	If lContinua
		// Cria objeto Excel
		oExcel := FWMSExcel():New()

		// Cria Worksheet
		oExcel:AddWorkSheet(cWorkSheet)

		// Cria a tabela para o WorkSheet
		oExcel:AddTable(cWorkSheet, cTabela)

		For nI := 2 To Len(aCabec)
			If aCabec[nI][8] == "N"
				oExcel:AddColumn(cWorkSheet, cTabela, aCabec[nI][1], nDireita , nNumero, !lTotal)
			ElseIf aCabec[nI][8] == "D"
				oExcel:AddColumn(cWorkSheet, cTabela, aCabec[nI][1], nCentro  , nData  , !lTotal)
			Else
				oExcel:AddColumn(cWorkSheet, cTabela, aCabec[nI][1], nEsquerda, nGeral , !lTotal)
			EndIf
		Next nI

		// Popula a planilha com os resultados da integração
		For nI := 1 To Len(aDados)
			// Limpa a linha
			aRow := {}

			// Define os dados que serão exibidos
			For nJ := 2 To Len(aDados[nI]) - 1
				Aadd(aRow, aDados[nI][nJ])
			Next nJ

			// Adiciona a linha na planilha
			oExcel:AddRow(cWorkSheet, cTabela, aRow)
		Next

		MsgInfo(CAT533033 + CRLF + CAT533034 + AllTrim(cDirXML) + ".xml", cCadastro) // "Arquivo gerado com sucesso." "Diretório: "

		//Ativando o arquivo e gerando o xml
		oExcel:Activate()
		oExcel:GetXMLFile(cDirXML + ".xml")

		//Abrindo o excel e abrindo o arquivo xml
		oMsExcel := MsExcel():New() //Abre uma nova conexão com Excel

		oMsExcel:WorkBooks:Open(cDirXML + ".xml") //Abre uma planilha
		oMsExcel:SetVisible(.T.) //Visualiza a planilha

		oExcel:DeActivate()
		oMsExcel:Destroy() //Encerra o processo do gerenciador de tarefas
	EndIf

Return

/*/{Protheus.doc} fAddLegenda
Função para adicionar no aHeader o campo para legenda.
@author Juliano Fernandes
@since 01/10/2019
@param aArray, array, Array contendo a referência de aHeader
@version 1.01
@type function
/*/
Static Function fAddLegenda( aArray )

	Aadd( aArray, { "", "LEG", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", "" })

Return(Nil)

/*/{Protheus.doc} fCheckFat
Realiza a marcação de um registro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fCheckFat()

	Local oNo := LoadBitmap( GetResources(), "LBNO" )
	Local oOk := LoadBitmap( GetResources(), "LBOK" )

	If oGetDadFat:aCols[oGetDadFat:nAt,1]:cName == "LBNO"
		oGetDadFat:aCols[oGetDadFat:nAt,1] := oOk
	Else
		oGetDadFat:aCols[oGetDadFat:nAt,1] := oNo
	EndIf

Return(Nil)

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

/*/{Protheus.doc} fGetStatFat
Retorna array com os status das faturas conforme cadastrado no campo UQO_STATUS.
@author Juliano Fernandes
@since 03/01/2020
@version 1.0
@return aStatus, Array com todos os Status de faturas
@type function
/*/
Static Function fGetStatFat()

	Local aStatus	:= {}
	Local aAux		:= {}

	fAddHeader(@aAux, "UQO_STATUS")

	aAux[1,11] := "0=" + CAT518104 + ";" + aAux[1,11] // "Todos"

	aStatus := Separa(aAux[1,11],";",.F.)

Return(aStatus)

/*/{Protheus.doc} fVldCliente
Validação do cliente.
@author Juliano Fernandes
@since 17/12/2019
@param nOpcao, numérico, opção selecionada pelo usuário.
@version 1.0
@return lValid, Indica se é válido
@type function
/*/
Static Function fVldCliente(nOpcao)

	Local lPesquisa	:= .T.
	Local lValid 	:= .T.

	Default nOpcao 	:= 0

	// Verifica se é uma integração múltipla
	If nOpcao == 13 .And. Empty(cGCliente)
		lPesquisa := .F.

		cGLojaCli := Space(TamSX3("A1_LOJA")[1])
		cGNomeCli := Space(TamSX3("A1_NOME")[1])
	EndIf

	If lPesquisa
		DbSelectArea("SA1")
		SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
		If SA1->(DbSeek(xFilial("SA1") + cGCliente + IIf(!Empty(cGLojaCli),cGLojaCli,"")))
			cGLojaCli := SA1->A1_LOJA
			cGNomeCli := SA1->A1_NOME
		Else
			lValid := .F.
			Help(" ",1,"REGNOIS")
		EndIf
	EndIf

Return(lValid)

/*/{Protheus.doc} fFiltraFat
Filtro para a tela de diversas Faturas.
@author Juliano Fernandes
@since 17/12/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fFiltraFat()

    Local aAreas        := {}
    Local aDados        := {}
    Local aLinha        := {}
    Local aTCSetField   := {}

    Local cAliasQry     := GetNextAlias()
    Local cQuery        := ""
    Local cCampos		:= ""

	Local lDeleted		:= .F.
	Local lDados		:= .F.

	Local nI			:= 0

	Aadd(aAreas, GetArea())

	For nI := 3 To Len(aHeaderUQO) - 2
		If aHeaderUQO[nI,8] $ "M"
			cCampos += "ISNULL(CONVERT(VARCHAR(8000), CONVERT(VARBINARY(8000), UQO." + AllTrim(aHeaderUQO[nI,2]) + ")),'') " + AllTrim(aHeaderUQO[nI,2]) + ", "
		Else
			cCampos += "UQO." + AllTrim(aHeaderUQO[nI,2]) + ", "

			If aHeaderUQO[nI,8] $ ".D.N."
				Aadd( aTCSetField, { AllTrim(aHeaderUQO[nI,2]), aHeaderUQO[nI,8], aHeaderUQO[nI,4], aHeaderUQO[nI,5] } )
			EndIf
		EndIf
	Next nI

	cCampos += "UQO.UQO_STATUS, "
	cCampos += "'UQO' UQO_ALI_WT, "
	cCampos += "UQO.R_E_C_N_O_ UQO_REC_WT "

	Aadd( aTCSetField, { "UQO_REC_WT", "N", 17, 0 } )

	// Define a query para pesquisa dos arquivos.
	cQuery := " SELECT " + cCampos												+ CRLF
	cQuery += " FROM " + RetSQLName("UQO") + " UQO "							+ CRLF
	cQuery += " WHERE UQO.UQO_FILIAL = '" + xFilial("UQO") + "' "				+ CRLF

	If !Empty(cGCliente)
		cQuery += " 	AND UQO.UQO_CLIENT = '" + cGCliente + "' "				+ CRLF
	EndIf

	If !Empty(cGLojaCli)
		cQuery += " 	AND UQO.UQO_LOJA = '" + cGLojaCli + "' "					+ CRLF
	EndIf

	If !Empty(dGEmissaoDe)
		cQuery += " 	AND UQO.UQO_EMISSA >= '" + DtoS( dGEmissaoDe ) + "' "	+ CRLF
	EndIf

	If !Empty(dGEmissaoAte)
		cQuery += " 	AND UQO.UQO_EMISSA <= '" + DtoS( dGEmissaoAte ) + "' "	+ CRLF
	EndIf

	If !Empty(dGVenctoDe)
		cQuery += " 	AND UQO.UQO_VENCTO >= '" + DtoS( dGVenctoDe ) + "' "		+ CRLF
	EndIf

	If !Empty(dGVenctoAte)
		cQuery += " 	AND UQO.UQO_VENCTO <= '" + DtoS( dGVenctoAte ) + "' "	+ CRLF
	EndIf

	If cCBStatus != "0"
		cQuery += " 	AND UQO.UQO_STATUS = '" + cCBStatus + "' "				+ CRLF
	EndIf

	If !Empty(cGNomUsuar)
		cQuery += " 	AND UQO.UQO_USUARI = '" + cGNomUsuar + "' "				+ CRLF
	EndIf

	cQuery += " 	AND UQO.D_E_L_E_T_ <> '*' "									+ CRLF
	cQuery += " ORDER BY UQO.R_E_C_N_O_ "										+ CRLF

	MPSysOpenQuery( cQuery, cAliasQry, aTCSetField )

	ProcRegua(0)

	While !(cAliasQry)->(Eof())
		lDados := .T.

		IncProc()

		// Reinicia aLinha a cada iteração
		aLinha := {}

		Aadd( aLinha, oNo )

		// Define a legenda para o registro.
		If (cAliasQry)->UQO_STATUS == "1"		// Fatura Em Aberto
			Aadd( aLinha, oAmarelo )
		ElseIf (cAliasQry)->UQO_STATUS == "2"	// Fatura Integrada
			Aadd( aLinha, oVerde )
		ElseIf (cAliasQry)->UQO_STATUS == "3"	// Fatura Baixada parcialmente
			Aadd( aLinha, oAzul )
		ElseIf (cAliasQry)->UQO_STATUS == "4"	// Fatura Baixada totalmente
			Aadd( aLinha, oVermelho )
		EndIf

		// Popula o array com dados.
		For nI := 3 To Len( aHeaderUQO )
			Aadd( aLinha, (cAliasQry)->&(aHeaderUQO[nI][2]) )
		Next nI

		Aadd( aLinha, lDeleted )

		// Adiciona a linha ao array principal
		Aadd( aDados, aLinha )

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	If Empty(aDados)
		Aadd( aLinha, oNo )
		Aadd( aLinha, oAmarelo )

		// Popula o array com dados em branco.
		For nI := 3 To Len( aHeaderUQO ) - 2
			Aadd( aLinha, CriaVar( aHeaderUQO[nI][2], .T. ) )
		Next nI

		Aadd( aLinha, "UQO" 	) // Alias WT
		Aadd( aLinha, 0 		) // Recno WT
		Aadd( aLinha, .F. 		) // D_E_L_E_T_

		Aadd(aDados, aLinha)
	EndIf

	// Define array aDados como aCols da GetDados
	oGetDadFat:SetArray( aDados )

	// Atualiza a GetDados
	oGetDadFat:Refresh()

	If !lDados
		MsgAlert(CAT544010, cCadastro) //"Nenhum registro localizado com os filtros informados."
	EndIf

    fRestAreas(aAreas)

Return(Nil)

/*/{Protheus.doc} fSetChkFat
Marca e desmarca ou inverte o check em todos os registros.
@type function
@author Juliano Fernandes
@since 07/02/2018
@return Nil, Sem retorno
/*/
Static Function fSetChkFat(nOpc)

	Local nI	:= 0
	Local nAt	:= 0

	ProcRegua(0)

	nAt := oGetDadFat:nAt

	If nOpc == 1 /* Marcar todos */

		IncProc(CAT544016)	//Marcando registros
		AEVal(oGetDadFat:aCols, {|x| nI++, oGetDadFat:GoTo(nI), x[1] := oOk})

	ElseIf nOpc == 2 /* Desmarcar todos */

		IncProc(CAT544017)	//"Desmarcando registros"
		AEVal(oGetDadFat:aCols, {|x| nI++, oGetDadFat:GoTo(nI), x[1] := oNo})

	ElseIf nOpc == 3 /* Inverter seleção */

		IncProc(CAT544018)	//"Invertendo seleção de registros"
		AEVal(oGetDadFat:aCols, {|x| nI++, oGetDadFat:GoTo(nI), x[1] := IIf(x[1]:cName == "LBOK", oNo, oOk)})

	EndIf

	oGetDadFat:GoTo(nAt)
	oGetDadFat:Refresh()

Return(Nil)

/*/{Protheus.doc} fLDblClick
Função de duplo clique na MsNewGetDados da tela de Múltiplas Faturas.
@type function
@author Juliano Fernandes
@since 03/01/2020
@return Nil, Sem retorno
/*/
Static Function fLDblClick()

	If oGetDadFat:oBrowse:ColPos == GdFieldPos("UQO_OBS",aHeaderUQO)
		oGetDadFat:EditCell()
	Else
		fCheckFat()
	EndIf

Return(Nil)

/*/{Protheus.doc} fDetalhes
Exibe os detalhes da fatura na tela de Múltiplas Faturas.
@type function
@author Juliano Fernandes
@since 03/01/2020
@return Nil, Sem retorno
/*/
Static Function fDetalhes()

	Local nRecno := GDFieldGet("UQO_REC_WT",oGetDadFat:nAt,,oGetDadFat:aHeader,oGetDadFat:aCols)

	If nRecno > 0
		UQO->(DbGoTo(nRecno))

		If UQO->(Recno()) == nRecno
			U_fMain518("UQO", nRecno, 2)
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fErrExecAut
Retorna a mensagem de erro gerada pela Execauto.
@author Juliano Fernandes
@since 08/10/2019
@return cMensagem, caracter, Mensagem de erro tratada retornada pela Execauto.
@type function
/*/
Static Function fErrExecAut()

	Local aErro		:= {}

	Local cMensagem := ""

	// Captura o erro ocorrido em forma de array
	aErro := GetAutoGRLog()

	AEval(aErro, {|cErro| cMensagem += cErro + CRLF})

Return(cMensagem)

/*/{Protheus.doc} fVldUsuar
Validação do get de código do usuário.
@author Juliano Fernandes
@since 07/01/2020
@version 1.0
@return lValid, Indica se o conteúdo informado é válido
@type function
/*/
Static Function fVldUsuar()

	Local lValid := .T.

	If Empty(cGCodUsuar)
		cGNomUsuar := Space( 25 )
	Else
		cGNomUsuar := Upper(UsrRetName(cGCodUsuar))

		If Empty(cGNomUsuar)
			lValid := .F.
			Help(" ",1,"REGNOIS")
		EndIf
	EndIf

Return(lValid)

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

	Local c518Alias	:= ""

	Local nAlias	:= 1

	DbSelectArea(nAlias)

	c518Alias := Alias()

	While !Empty(c518Alias)

		Aadd(aWorkArea, (c518Alias)->(GetArea()))

		nAlias++

		DbSelectArea(nAlias)

		c518Alias := Alias()

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

	Local a518AliClo	:= {}

	Local c518Alias		:= ""

	Local nAlias		:= n518WrkAre
	Local nI			:= 0

	nAlias++

	DbSelectArea(nAlias)

	c518Alias := Alias()

	While !Empty(c518Alias)
		Aadd(a518AliClo, c518Alias)

		nAlias++

		DbSelectArea(nAlias)

		c518Alias := Alias()
	EndDo

	For nI := Len(a518AliClo) To 1 Step -1
		c518Alias := a518AliClo[nI]

		(c518Alias)->(DbCloseArea())
	Next nI

	RestArea( a518WrkAre[n518WrkAre] )

Return(Nil)

/*/{Protheus.doc} fAtuCCusto
Atualiza o Centro de Custo da tabela SE1 caso não tenha sido gravado na integração CTE/CRT.
@author Juliano Fernandes
@since 16/04/2020
@return Nil, Não há retorno
@type function
/*/
Static Function fAtuCCusto()

	Local aArea			:= GetArea()
	Local aAreaUQO		:= UQO->(GetArea())
	Local aAreaUQP		:= UQP->(GetArea())
	Local aAreaSE1		:= SE1->(GetArea())
	Local aAreaUQD		:= UQD->(GetArea())
	Local aAreaSA1		:= SA1->(GetArea())

	Local cCCustoSA1	:= ""
	Local cCCustoUQD	:= ""
	Local cChvSE1		:= ""
	Local cChvUQD		:= ""

	Local nTamUQDPref	:= TamSX3("UQD_PREFIX")[1]
	Local nTamUQDTitu	:= TamSX3("UQD_TITULO" )[1]
	Local nTamUQDParc	:= TamSX3("UQD_PARCEL")[1]
	Local nTamUQDTipo	:= TamSX3("UQD_TIPOTI")[1]

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
	If SA1->(DbSeek(xFilial("SA1") + UQO->UQO_CLIENT + UQO->UQO_LOJA))
		cClasseCC := Posicione("CTT", 1, xFilial("CTT") + SA1->A1_XCCUSTO, "CTT_CLASSE")'
		If cClasseCC == "2"
			cCCustoSA1 := SA1->A1_XCCUSTO
		EndIf
	EndIf

	DbSelectArea("UQP")
	UQP->(DbSetOrder(1)) // UQP_FILIAL+UQP_IDFAT+UQP_ITEM+UQP_TPFAT+UQP_PFXFAT+UQP_TITFAT+UQP_PARFAT
	If UQP->(DbSeek(xFilial("UQP") + UQO->UQO_ID))
		While !UQP->(EoF()) .And. UQP->UQP_FILIAL == xFilial("UQP") .And. UQP->UQP_IDFAT == UQO->UQO_ID

			If AllTrim(UQP->UQP_TPFAT) == "NF"

				cChvSE1 := xFilial("SE1")
				cChvSE1 += UQO->UQO_CLIENT
				cChvSE1 += UQO->UQO_LOJA
				cChvSE1 += UQP->UQP_PFXFAT
				cChvSE1 += UQP->UQP_TITFAT
				cChvSE1 += UQP->UQP_PARFAT
				cChvSE1 += UQP->UQP_TPFAT

				DbSelectArea("SE1")
				SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				If SE1->(DbSeek( cChvSE1 ))
					If Empty(SE1->E1_CCUSTO)
						cCCustoUQD := ""

						cChvUQD := xFilial("UQD")
						cChvUQD += PadR(SE1->E1_PREFIXO	, nTamUQDPref)
						cChvUQD += PadR(SE1->E1_NUM		, nTamUQDTitu)
						cChvUQD += PadR(SE1->E1_PARCELA	, nTamUQDParc)
						cChvUQD += PadR(SE1->E1_TIPO	, nTamUQDTipo)

						DbSelectArea("UQD")
						UQD->(DbSetOrder(5)) // UQD_FILIAL+UQD_PREFIX+UQD_TITULO+UQD_PARCEL+UQD_TIPOTI
						If UQD->(DbSeek( cChvUQD ))
							If UQO->UQO_CLIENT == UQD->UQD_CLIENT .And. UQO->UQO_LOJA == UQD->UQD_LOJACL
								cClasseCC := Posicione("CTT", 1, xFilial("CTT") + UQD->UQD_CCUSTO, "CTT_CLASSE")'
								If cClasseCC == "2"
									cCCustoUQD := UQD->UQD_CCUSTO
								EndIf
							EndIf
						EndIf

						SE1->(RecLock("SE1",.F.))
							SE1->E1_CCUSTO := IIf(!Empty(cCCustoUQD),cCCustoUQD,cCCustoSA1)
						SE1->(MsUnlock())
					EndIf
				EndIf

			EndIf

			If !Empty(UQP->UQP_TITULO) .And. AllTrim(UQP->UQP_TIPO) == "NF"

				cChvSE1 := xFilial("SE1")
				cChvSE1 += UQO->UQO_CLIENT
				cChvSE1 += UQO->UQO_LOJA
				cChvSE1 += UQP->UQP_PREFIX
				cChvSE1 += UQP->UQP_TITULO
				cChvSE1 += UQP->UQP_PARCEL
				cChvSE1 += UQP->UQP_TIPO

				DbSelectArea("SE1")
				SE1->(DbSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
				If SE1->(DbSeek( cChvSE1 ))
					If Empty(SE1->E1_CCUSTO)
						cCCustoUQD := ""

						cChvUQD := xFilial("UQD")
						cChvUQD += PadR(SE1->E1_PREFIXO	, nTamUQDPref)
						cChvUQD += PadR(SE1->E1_NUM		, nTamUQDTitu)
						cChvUQD += PadR(SE1->E1_PARCELA	, nTamUQDParc)
						cChvUQD += PadR(SE1->E1_TIPO	, nTamUQDTipo)

						DbSelectArea("UQD")
						UQD->(DbSetOrder(5)) // UQD_FILIAL+UQD_PREFIX+UQD_TITULO+UQD_PARCEL+UQD_TIPOTI
						If UQD->(DbSeek( cChvUQD ))
							If UQO->UQO_CLIENT == UQD->UQD_CLIENT .And. UQO->UQO_LOJA == UQD->UQD_LOJACL
								cCCustoUQD := UQD->UQD_CCUSTO
							EndIf
						EndIf

						SE1->(RecLock("SE1",.F.))
							SE1->E1_CCUSTO := IIf(!Empty(cCCustoUQD),cCCustoUQD,cCCustoSA1)
						SE1->(MsUnlock())
					EndIf
				EndIf

			EndIf

			UQP->(DbSkip())
		EndDo
	EndIf

	RestArea(aAreaSA1)
	RestArea(aAreaUQD)
	RestArea(aAreaSE1)
	RestArea(aAreaUQP)
	RestArea(aAreaUQO)
	RestArea(aArea)

Return(Nil)

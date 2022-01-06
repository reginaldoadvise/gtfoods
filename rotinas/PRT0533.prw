#Include 'Totvs.ch'
#Include 'CATTMS.ch'

Static NomePrt    := "PRT0533"
Static VersaoJedi := "V1.16"

/*/{Protheus.doc} PRT0533
Programa para visualização de logs de importação de arquivos.
@author Paulo Carvalho
@since 12/11/2018
@param cAliasLog, caracter, Alias da tabela de log que deve ser aberta.
@type User Function
/*/
User Function PRT0533( cAliasLog, lPar, cTpArq, cPar )

	Local aArea				:= GetArea()

	Local bOk				:= {|| lOk := .T., oDlgLog:End() }
	Local bCancel			:= {|| oDlgLog:End() }
	Local bEnchoice

	Local cFilBkp			:= cFilAnt

	Local nTop				:= Nil
	Local nLeft				:= Nil
	Local nBottom			:= Nil
	Local nRight			:= NIl

	Private aBtnEnchoice	:= {}
	Private aFiliais		:= {}
	Private aHeader			:= {}
	Private aGetDados		:= {}
	Private aColNaoOrd		:= {}
	Private aCNOCTECRT		:= {}
	Private aCNOCTRB		:= {}
	Private aCNOFolPag		:= {}

	Private bActLegend		:= { || fLegenda() }
	Private bGeraExcel		:= { || Processa({|| fGeraExcel()}, CAT544001, CAT544004) } // "Aguarde", "Processando"
	Private bGrvAlt			:= { || fGrvAlt() }

	Private cAlias			:= cAliasLog
	Private cCadastro		:= NomePrt + CAT533001 + VersaoJedi //- Logs de Importação -
	Private cTipoArq		:= cTpArq
	Private cAcaoLog		:= If(Empty(cPar), CAT533002, cPar) // Importação

	Private cDocDe			:= Space( 20 )
	Private cDocAte			:= Space( 20 )
	Private cGFilCTE		:= Space( 200 )
	Private cGFilCTRB		:= Space( 200 )
	Private cGFilVouch		:= Space( 200 )
	Private cGFilFolPag		:= Space( 200 )
	Private cGFiliais		:= Space( 200 )
	Private cLogImp			:= ""
	Private cStatus			:= ""
	Private cGCodUsuar		:= Space( 8 )
	Private cGNomUsuar		:= Space( 25 )
	Private	cGClienDe		:= Space( TamSX3("A1_COD")[1] )
	Private	cGClienAte		:= Space( TamSX3("A1_COD")[1] )

	Private dDataDe			:= Date()
	Private dDataAte		:= Date()

	Private lCentered		:= .T.
	Private lFocSel			:= .T.
	Private lFullView		:= .F.
	Private lHasButton		:= .T.
	Private lHtml			:= .T.
	Private lNaoLidos		:= If(Empty(lPar), .F., .T.)
	Private lNoButton		:= .T.
	Private lPassword		:= .T.
	Private lPicturePiority	:= .T.
	Private lPixel			:= .T.
	Private lReadOnly		:= .T.
	Private lTransparent	:= .T.
	Private lChkCTECRT		:= .F.
	Private lChkCTRB		:= .F.
	Private lChkImport		:= .F.
	Private lChkInteg		:= .F.
	Private lChkCF			:= .F.

	Private lCrescente		:= .F.
	Private lCreCTECRT		:= .F.
	Private lCreCTRB		:= .F.
	Private lCreFolPag		:= .F.

	Private nTamFilial		:= TamSX3("C5_FILIAL")[1] //Necessário para obter o tamanho da filial
	Private nOrdena			:= 0 // 0=Crescente;1=Decrescente
	Private nOrdCTECRT		:= 0
	Private nOrdCTRB		:= 0
	Private nOrdFolPag		:= 0

	Private oBlue  			:= LoadBitmap( GetResources(), "BR_AZUL" 	 )
	Private oGreen 			:= LoadBitmap( GetResources(), "BR_VERDE" 	 )
	Private oRed   			:= LoadBitmap( GetResources(), "BR_VERMELHO" )
	Private oBtnBusca		:= Nil
	Private oDlgLog			:= Nil
	Private oGet533			:= Nil
	Private oGetCTECRT		:= Nil
	Private oGetCF			:= Nil
	Private oGetCTRB		:= Nil
	Private oGetFolPag		:= Nil
	Private oGFilCTE		:= Nil
	Private oGFilCTRB		:= Nil
	Private oGFilVouch		:= Nil
	Private oGFilFolPag		:= Nil
	Private oGFiliais		:= Nil
	Private oPnlFiltro		:= Nil
	Private oSCbLogImp		:= Nil
	Private oSCbStatus		:= Nil
	Private oSCbAcaoLog		:= Nil

	Private oCbAcaoLog		:= Nil
	Private oCbLogImp		:= Nil
	Private oCbStatus		:= Nil
	Private oGDataDe		:= Nil
	Private oGDataAte		:= Nil
	Private oGDocDeUQF		:= Nil
	Private oGDocAteUQF		:= Nil
	Private oGDocDeUQJ		:= Nil
	Private oGDocAteUQJ		:= Nil
	Private	oGDocDe			:= Nil
	Private	oGDocAte		:= Nil
	Private	oGCodUsuar		:= Nil
	Private	oGNomUsuar		:= Nil
	Private	oGClienDe		:= Nil
	Private	oGClienAte		:= Nil

	Private oSize			:= Nil

	Private oGrpLogImp		:= Nil
	Private oChkCTECRT		:= Nil
	Private oChkCTRB		:= Nil
	Private oGrpAcaoLog		:= Nil
	Private oChkImport		:= Nil
	Private oChkInteg		:= Nil

	Private oFolder			:= Nil

	// Instancia o objeto para controle das coordenadas da aplicação
	oSize	:= FWDefSize():New( .T. ) // Indica que a tela terá EnchoiceBar

	// Define que os objetos não serão expostos lado a lado
	oSize:lProp 	:= .T.
	oSize:lLateral 	:= .F.

	// Adiciona ao objeto oSize os objetos que irão compor a tela
	If !lNaoLidos
		If cTipoArq != "CON"
			oSize:AddObject( "FILTROS"	, 100, 020, .T., .T.  )
			oSize:AddObject( "FOLDER"	, 100, 080, .T., .T.  )
		Else // cTipoArq == "CON"
			oSize:AddObject( "FILTROS"	, 100, 010, .T., .T.  )
			oSize:AddObject( "FOLDER"	, 100, 090, .T., .T.  )
		EndIf
	Else
		oSize:AddObject( "GETDADOS"	, 100, 100, .T., .T.  )
	EndIf

	// Realiza o cálculo das coordenadas
	oSize:Process()

	// Define as coordenadas da Dialog principal
	nTop	:= oSize:aWindSize[1]
	nLeft	:= oSize:aWindSize[2]
	nBottom	:= oSize:aWindSize[3]
	nRight	:= oSize:aWindSize[4]

	// Instancia a classe MSDialog
	oDlgLog := MSDialog():New( 	nTop, nLeft, nBottom, nRight, cCadastro,;
								/*uParam6*/, /*uParam7*/, /*uParam8*/,;
								nOr( WS_VISIBLE, WS_POPUP ), /*nClrText*/, /*nClrBack*/,;
								/*uParam12*/, /*oWnd*/, lPixel, /*uParam15*/,;
								/*uParam16*/, /*uParam17*/, !lTransparent )

	// Verifica se o programa foi chamado por uma importação de arquivos
	If Empty( cAliasLog ) // Tela de Log com filtros
		// Define que a tela será formada por completo: com filtro e GetDados
		lFullView	:= .T.

		// Monta o painel de filtragem.
		fMontPnl2()

		// Monta o Folder
		fMontFolder()

		If cTipoArq != "CON"
			// Monta a GetDados de CTE/CRT
			cAlias := "UQF" ; fMontGet()

			// Monta a GetDados de CTRB
			cAlias := "UQJ" ; fMontGet()

			// Monta a GetDados da carta frete
			cAlias := "UQF" ; fMontGet(.T.)
			cAlias := "UQF"
		EndIf

	Else // Tela de Log sem filtros (Apenas com registros não lidos)
		fMontGet(FwIsInCallStack("U_PRT0528C"))
	EndIf
	If FwIsInCallStack("U_PRT0528C")
		IF VALTYPE(oFolder)<>"U"
			oFolder:HidePage(1)
			oFolder:HidePage(2)
		EndIf	
	Else 
		IF VALTYPE(oFolder)<>"U"
			oFolder:HidePage(3)
		EndIf
	EndIf	
	// Define EnchoiceBar
	aadd( aBtnEnchoice, { "", bActLegend , CAT533003 		} ) // "Legenda"
	aAdd( aBtnEnchoice, { "", bGeraExcel , CAT533004		} ) // "Exportar Excel"

	If ((lFullView) .Or. (!lFullView .And. cAlias == "UQF")) .And. (cTipoArq != "CON")
		aAdd( aBtnEnchoice, { "", bGrvAlt, CAT533037		} ) // "Salvar alterações"
	EndIf

	bEnchoice 	:= {|| 	EnchoiceBar( oDlgLog, bOk ,	bCancel, .F., aBtnEnchoice, /*nRecno*/,;
						 /*cAlias*/, .F., .F., .F., .F., .F., ) }


	// Ativa a Dialog para visualização de log de registros
	oDlgLog:Activate( 	/*uParam1*/, /*uParam2*/, /*uParam3*/, lCentered,;
						/*bValid*/,/*uParam6*/, bEnchoice, /*uParam8*/, /*uParam9*/	)

	fAltFilial(cFilBkp)

	RestArea(aArea)

Return

/*/{Protheus.doc} fMontPnl2
Monta o painel de filtros para seleção dos logs de registro.
@author Juliano Fernandes
@since 07/01/2020
@type Function
/*/
Static Function fMontPnl2()

	Local aStatus		:= {CAT533006,CAT533007,CAT533008} // "Todos" "Importados" "Erro"

	Local bActVisual	:= { || Processa({|| fFiltraDad(FwIsInCallStack("U_PRT0528C"))}, CAT544001, CAT544002) } // "Aguarde" "Filtrando Registros..."
	Local bCbStatus		:= { || CAT533011	 } //Status
	Local bSGStatus		:= { |u| IIf(PCount() > 0, cStatus := u, cStatus) }

	Local nRow			:= oSize:GetDimension( "FILTROS", "LININI" )
	Local nCol			:= oSize:GetDimension( "FILTROS", "COLINI" )
	Local nWidth		:= oSize:GetDimension( "FILTROS", "XSIZE"  )
	Local nHeight		:= oSize:GetDimension( "FILTROS", "YSIZE"  )

	Local nRowElem		:= 002
	Local nColRight		:= oSize:GetDimension( "FILTROS", "COLEND" ) - 55

	Local nLblPos		:= 1
	Local bWhen			:= {|| IIf(FwIsInCallStack("U_PRT0528C"),.F.,.T.)}

	// Define as opções de log de acordo com o tipo de arquivo
	cAlias 	:= "UQF"
	cLogImp	:= CAT533012 // Importação de Arquivo CTE/CRT

	// Cria o painel de filtros
	oPnlFiltro 	:= TPanel():New(	nRow,nCol,/*cTexto*/,oDlgLog,/*oFont*/,lCentered,/*uParam7*/,/*nClrText*/,;
									/*nClrBack*/,nWidth, nHeight,/*lLowered*/,/*lRaised*/)

	If cTipoArq != "CON"
		// Visualizar log de
		oGrpLogImp := TGroup():New(nRowElem,002,047,085,CAT533009,oPnlFiltro,/*nClrText*/,/*nClrPane*/,lPixel,/*uParam10*/)

		oChkCTECRT	:= TCheckBox():New(	nRowElem + 012,005,CAT533053,{|u| IIf(PCount() > 0, lChkCTECRT := u, lChkCTECRT)},;
										oPnlFiltro,100,210,/*uParam8*/,/*bLClicked*/{|| fChgTpPesq()},/*oFont*/,/*bValid*/,/*nClrText*/,;
										/*nClrPane*/,/*uParam14*/,lPixel,/*cMsg*/,/*uParam17*/,bWhen) // "CTE/CRT"

		oChkCTRB	:= TCheckBox():New(	nRowElem + 022,005,CAT533054,{|u| IIf(PCount() > 0, lChkCTRB := u, lChkCTRB)},;
										oPnlFiltro,100,210,/*uParam8*/,/*bLClicked*/{|| fChgTpPesq()},/*oFont*/,/*bValid*/,/*nClrText*/,;
										/*nClrPane*/,/*uParam14*/,lPixel,/*cMsg*/,/*uParam17*/,bWhen) // "CTRB"
		oChkCF	:= TCheckBox():New(	nRowElem + 032,005,"Carta Frete",{|u| IIf(PCount() > 0, lChkCF := u, lChkCF)},;
										oPnlFiltro,100,210,/*uParam8*/,/*bLClicked*/{|| fChgTpPesq()},/*oFont*/,/*bValid*/,/*nClrText*/,;
										/*nClrPane*/,/*uParam14*/,lPixel,/*cMsg*/,/*uParam17*/,{|| IIf(!FwIsInCallStack("U_PRT0528C"),.F.,.T.)}) // "CTRB"

		oGrpAcaoLog := TGroup():New(nRowElem,090,047,175,CAT533010,oPnlFiltro,/*nClrText*/,/*nClrPane*/,lPixel,/*uParam10*/) // Rotina

		oChkImport	:= TCheckBox():New(	nRowElem + 012,093,CAT533002,{|u| IIf(PCount() > 0, lChkImport := u, lChkImport)},;
										oPnlFiltro,100,210,/*uParam8*/,/*bLClicked*/,/*oFont*/,/*bValid*/,/*nClrText*/,;
										/*nClrPane*/,/*uParam14*/,lPixel,/*cMsg*/,/*uParam17*/,/*bWhen*/)

		oChkInteg	:= TCheckBox():New(	nRowElem + 022,093,CAT533005,{|u| IIf(PCount() > 0, lChkInteg := u, lChkInteg)},;
										oPnlFiltro,100,210,/*uParam8*/,/*bLClicked*/,/*oFont*/,/*bValid*/,/*nClrText*/,;
										/*nClrPane*/,/*uParam14*/,lPixel,/*cMsg*/,/*uParam17*/,/*bWhen*/)

		// Data De
		oGDataDe	:= TGet():New( 	nRowElem, 180,  {|u| if( Pcount() > 0, dDataDe := u, dDataDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533015, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Data De
									!lPicturePiority, lFocSel )

		// Data Ate
		oGDataAte	:= TGet():New( 	nRowElem, 255, {|u| if( Pcount() > 0, dDataAte := u, dDataAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533016, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Data Ate
									!lPicturePiority, lFocSel )

		// UQF -> Documento De
		oGDocDeUQF	:= TGet():New( 	nRowElem, 330,  {|u| if( Pcount() > 0, cDocDe := u, cDocDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "UQD", "cDocDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533017, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Documento De
									!lPicturePiority, lFocSel )
		oGDocDeUQF:lVisible	:= .F.

		// UQF -> Documento Ate
		oGDocAteUQF	:= TGet():New( 	nRowElem, 405, {|u| if( Pcount() > 0, cDocAte := u, cDocAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "UQD", "cDocAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533018, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Documento Ate
									!lPicturePiority, lFocSel )
		oGDocAteUQF:lVisible	:= .F.

		// UQJ -> Documento De
		oGDocDeUQJ	:= TGet():New( 	nRowElem, 330,  {|u| if( Pcount() > 0, cDocDe := u, cDocDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "UQG", "cDocDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533017, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//"Documento De"
									!lPicturePiority, lFocSel )
		oGDocDeUQJ:lVisible	:= .F.

		// UQJ -> Documento Ate
		oGDocAteUQJ	:= TGet():New( 	nRowElem, 405, {|u| if( Pcount() > 0, cDocAte := u, cDocAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "UQG", "cDocAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533018, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//"Documento Ate"
									!lPicturePiority, lFocSel )
		oGDocAteUQJ:lVisible	:= .F.

		// Documento De
		oGDocDe		:= TGet():New( 	nRowElem, 330,  {|u| if( Pcount() > 0, cDocDe := u, cDocDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*cF3*/, "cDocDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533017, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//"Documento De"
									!lPicturePiority, lFocSel )
		oGDocDe:lVisible	:= .T.

		// Documento Ate
		oGDocAte	:= TGet():New( 	nRowElem, 405, {|u| if( Pcount() > 0, cDocAte := u, cDocAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/, "cDocAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533018, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//"Documento Ate"
									!lPicturePiority, lFocSel )
		oGDocAte:lVisible	:= .T.

		// Status do processamento
		oSCbStatus	:= TSay():New( 	nRowElem, 480, bCbStatus, oPnlFiltro, /*cPicture*/, /*oFont*/,;
									/*uParam7*/, /*uParam8*/, /*uParam9*/, lPixel, /*nClrText*/,;
									/*nCrlBack*/, 080, 10, /*uParam15*/, /*uParam16*/, /*uParam17*/,;
									/*uParam18*/, /*uParam19*/, !lHtml, /*nTxtAlgHor*/,  /*nTxtAlgVer*/ )

		cStatus := aStatus[1]
		oCbStatus 	:= TComboBox():New(	010, 480, bSGStatus, aStatus, 060, 13, oPnlFiltro,;
										/*uParam8*/, /*bChange*/, /*bValid*/, /*nClrText*/,;
										/*nClrBack*/, lPixel, /*oFont*/, /*uParam15*/, /*uParam16*/, ;
										/*bWhen*/, /*uParam18*/, /*uParam19*/, /*uParam20*/, /*uParam21*/, ;
										cStatus, /*cLabelText*/, /*nLabelPos*/, /*nLabelFont*/, /*nLabelColor*/	)

		// Filiais
		oGFiliais 	:= TGet():New( nRowElem, 545, {|u| if( Pcount() > 0, cGFiliais := u, cGFiliais)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/ {|| fVldFilial()}, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/ "StaticCall(PRT0533,fOpcFiliais,'oGFiliais')", "cGFiliais",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533019, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Filiais"
									!lPicturePiority, lFocSel )

		//-- Segunda linha
		nRowElem += 25

		// Cod. Usuário
		oGCodUsuar	:= TGet():New( 	nRowElem, 180,  {|u| if( Pcount() > 0, cGCodUsuar := u, cGCodUsuar)}, oPnlFiltro, 070, 011,;
									"@!", {|| fVldUsuar()},/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "USRPER", "cGCodUsuar",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533045, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Cod. Usuário"
									!lPicturePiority, lFocSel )

		// Nome (Usuario)
		oGNomUsuar	:= TGet():New( 	nRowElem, 255, {|u| if( Pcount() > 0, cGNomUsuar := u, cGNomUsuar)}, oPnlFiltro, 070, 011,;
									"@!", /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "cGNomUsuar",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533046, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Usuário"
									!lPicturePiority, lFocSel )
		oGNomUsuar:Disable()

		// Cliente De
		oGClienDe	:= TGet():New( 	nRowElem, 330, {|u| if( Pcount() > 0, cGClienDe := u, cGClienDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SA1CLI", "cGClienDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533047, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Cliente De"
									!lPicturePiority, lFocSel )
		oGClienDe:lVisible := .F.

		// Cliente Ate
		oGClienAte	:= TGet():New( 	nRowElem, 405,  {|u| if( Pcount() > 0, cGClienAte := u, cGClienAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SA1CLI", "cGClienAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533048, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Cliente Ate"
									!lPicturePiority, lFocSel )
		oGClienAte:lVisible := .F.

	Else // cTipoArq == "CON"

		// Data De
		oGDataDe	:= TGet():New( 	nRowElem, 005,  {|u| if( Pcount() > 0, dDataDe := u, dDataDe)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataDe",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533015, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Data De
									!lPicturePiority, lFocSel )

		// Data Ate
		oGDataAte	:= TGet():New( 	nRowElem, 080, {|u| if( Pcount() > 0, dDataAte := u, dDataAte)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataAte",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533016, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;//Data Ate
									!lPicturePiority, lFocSel )

		// Status do processamento
		oSCbStatus	:= TSay():New( 	nRowElem, 305, bCbStatus, oPnlFiltro, /*cPicture*/, /*oFont*/,;
									/*uParam7*/, /*uParam8*/, /*uParam9*/, lPixel, /*nClrText*/,;
									/*nCrlBack*/, 080, 10, /*uParam15*/, /*uParam16*/, /*uParam17*/,;
									/*uParam18*/, /*uParam19*/, !lHtml, /*nTxtAlgHor*/,  /*nTxtAlgVer*/ )

		cStatus := aStatus[1]
		oCbStatus 	:= TComboBox():New(	010, 305, bSGStatus, aStatus, 060, 13, oPnlFiltro,;
										/*uParam8*/, /*bChange*/, /*bValid*/, /*nClrText*/,;
										/*nClrBack*/, lPixel, /*oFont*/, /*uParam15*/, /*uParam16*/, ;
										/*bWhen*/, /*uParam18*/, /*uParam19*/, /*uParam20*/, /*uParam21*/, ;
										cStatus, /*cLabelText*/, /*nLabelPos*/, /*nLabelFont*/, /*nLabelColor*/	)

		// Filiais
		oGFiliais 	:= TGet():New( nRowElem, 370, {|u| if( Pcount() > 0, cGFiliais := u, cGFiliais)}, oPnlFiltro, 070, 011,;
									/*cPicture*/, /*bValid*/ {|| fVldFilial()}, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/ "StaticCall(PRT0533,fOpcFiliais,'oGFiliais')", "cGFiliais",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533019, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Filiais"
									!lPicturePiority, lFocSel )

		//-- Segunda linha
		// nRowElem += 25

		// Cod. Usuário
		oGCodUsuar	:= TGet():New( 	nRowElem, 445,  {|u| if( Pcount() > 0, cGCodUsuar := u, cGCodUsuar)}, oPnlFiltro, 070, 011,;
									"@!", {|| fVldUsuar()},/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "USRPER", "cGCodUsuar",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533045, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Cod. Usuário"
									!lPicturePiority, lFocSel )

		// Nome (Usuario)
		oGNomUsuar	:= TGet():New( 	nRowElem, 520, {|u| if( Pcount() > 0, cGNomUsuar := u, cGNomUsuar)}, oPnlFiltro, 070, 011,;
									"@!", /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
									/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
									/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "cGNomUsuar",;
									/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
									CAT533046, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Usuário"
									!lPicturePiority, lFocSel )
		oGNomUsuar:Disable()

	EndIf

	// Botão Pesquisar
	oBtnBusca	:= TButton():New(	008, nColRight, CAT533020, oPnlFiltro, bActVisual, 050, 015,;	//"Pesquisar"
									/*uParam8*/, /*oFont*/, /*uParam10*/, lPixel, /*uParam12*/, /*uParam13*/,;
									/*uParam14*/, /*bWhen*/, /*uParam16*/, /*uParam17*/	)

Return(Nil)

/*/{Protheus.doc} fMontGet
Monta a GetDados com registros selecionados de acordo com os parâmetros.
@author Paulo Carvalho
@since 20/12/2018
@type Static Function
/*/
Static Function fMontGet(lCf)

	Local aArea			:= GetArea()
	Local aAreaSX3		:= SX3->( GetArea() )
	Local aArray		:= {}
	Local aCampos		:= {}
	Local aDados		:= {}
	Local aAlter		:= {}

	Local cPrefixo		:= cAlias// Right(cAlias, 2)

	Local nI, nJ, nH
	Local nRow			:= 0
	Local nLeft			:= 0
	Local nBottom		:= 0
	Local nRight		:= 0

	Local oWnd			:= Nil
	Default lCf			:= .F.
	// Reinicia o array a header
	aHeader := {}

	If cAlias $ ".UQF.UQJ."
		Aadd( aCampos, cPrefixo + "_FILIAL"			)
		Aadd( aCampos, "UQK_DESCRI"					)
	EndIf

	Aadd( aCampos, "TIPOREG"						)

	If "UQF" $ cAlias
		Aadd( aCampos, cPrefixo + "_CANCEL"			)
		Aadd( aCampos, cPrefixo + "_BLQMAI"			)
	EndIf

    Aadd( aCampos, cPrefixo + "_DATA"				)
    Aadd( aCampos, cPrefixo + "_HORA"				)
    Aadd( aCampos, cPrefixo + "_REGCOD"				)

    If "UQF" $ cAlias
		If lCf
			Aadd( aCampos, cPrefixo + "_FORNEC"	)
		Else
			Aadd( aCampos, cPrefixo + "_CLIENT"	)
		ENDIF				
    	Aadd( aCampos, cPrefixo + "_VALOR"			)
    EndIf

    Aadd( aCampos, cPrefixo + "_MSG"				)
    Aadd( aCampos, cPrefixo + "_MSGDET"				)
    Aadd( aCampos, cPrefixo + "_NLINHA"				)
    Aadd( aCampos, cPrefixo + "_ARQUIV"				)
    Aadd( aCampos, cPrefixo + "_USER"				)

	// Adiciona campo para legenda no aHeader
	fAddLegenda( @aHeader )

	// Adiciona os campos no aHeader
	For nI := 1 To Len( aCampos )
		If aCampos[nI] == "TIPOREG"
			Aadd( aHeader, {CAT533049,"TIPOREG","",10,0,.T.,"","C",; // "Tipo"
							"","R","","",.F.,"V","","","",""})
		Else
			fAddHeader( @aHeader, aCampos[nI] )
		EndIf
	Next

	// Adiciona o Alias e o Recno
    AdHeadRec( cAlias, aHeader )

	// Popula o array com dados inicias em branco.
	For nJ := 1 To Len( aHeader )
		If aHeader[nJ][8] == "D"
			Aadd( aArray, CtoD( "  /  /  " ) )
		ElseIf aHeader[nJ][8] == "C"
			Aadd( aArray, Space( aHeader[nJ][4] ) )
		ElseIf aHeader[nJ][8] == "N"
			Aadd( aArray, 0 )
		Else
			Aadd( aArray, Nil )
		EndIf
	Next nJ

	Aadd( aArray, .F. ) // D_E_L_E_T_

	//Coloca máscara para os campos que não têm máscara informada
	For nH := 1 to Len (aHeader)
		If Empty(aHeader[nH][3]) .And. aHeader[nH][8] == "C"
			aHeader[nH][3] := "@!"
		EndIf
	Next nH

	If "UQF" $ cAlias .and. !lCf

		aAlter := {"UQF_MSGDET"}

		If !lFullView
			oWnd := oDlgLog
		Else
			oWnd := oFolder:aDialogs[1]
		EndIf

		oGetCTECRT	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, GD_UPDATE, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, aAlter, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oWnd, aHeader, { aArray }, /*bChange*//*uChange*/, /*cTela*/ )

		oGetCTECRT:oBrowse:bLDblClick := {|| fAltEmail()}

		// --------------------------------------------------------------------------
		// Colunas que não devem ser ordenadas ao clicar no cabeçalho da GetDados
		// --------------------------------------------------------------------------
		Aadd(aCNOCTECRT, GdFieldPos("COR"))
		Aadd(aCNOCTECRT, GdFieldPos("UQF_MSGDET"))
		Aadd(aCNOCTECRT, GdFieldPos("UQF_ALI_WT"))

		oGetCTECRT:oBrowse:bHeaderClick := {|x,y|	lCrescente := lCreCTECRT,;
													aColNaoOrd := aCNOCTECRT,;
													aGetDados := oGetCTECRT:aCols,;
													nOrdena := nOrdCTECRT,;
													IIf(nOrdena == 1, fOrdBrw(x,y), nOrdena++),;
													nOrdCTECRT := nOrdena,;
													lCreCTECRT := lCrescente }

		oGetCTECRT:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// Se a abertura da página for depois de uma importação
		If !lFullView
			// Popula a GetDados automaticamente.
			aDados := fFillGet(lcf)

			If Empty(aDados)
				MsgAlert(CAT533021, cCadastro) //"Nenhum registro encontrado."
			EndIf

			oGetCTECRT:SetArray(aDados)
			oGetCTECRT:Refresh()
		EndIf

	ElseIf "UQJ" $ cAlias

		aAlter := {"UQJ_MSGDET"}

		If !lFullView
			oWnd := oDlgLog
		Else
			oWnd := oFolder:aDialogs[2]
		EndIf

		oGetCTRB 	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, GD_UPDATE, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, aAlter, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oWnd, aHeader, { aArray }, /*bChange*//*uChange*/, /*cTela*/ )

		// --------------------------------------------------------------------------
		// Colunas que não devem ser ordenadas ao clicar no cabeçalho da GetDados
		// --------------------------------------------------------------------------
		Aadd(aCNOCTRB, GdFieldPos("COR"))
		Aadd(aCNOCTRB, GdFieldPos("UQJ_MSGDET"))
		Aadd(aCNOCTRB, GdFieldPos("UQJ_ALI_WT"))

		oGetCTRB:oBrowse:bHeaderClick := {|x,y|		lCrescente := lCreCTRB,;
													aColNaoOrd := aCNOCTRB,;
													aGetDados := oGetCTRB:aCols,;
													nOrdena := nOrdCTRB,;
													IIf(nOrdena == 1, fOrdBrw(x,y), nOrdena++),;
													nOrdCTRB := nOrdena,;
													lCreCTRB := lCrescente }

		oGetCTRB:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// Se a abertura da página for depois de uma importação
		If !lFullView
			// Popula a GetDados automaticamente.
			aDados := fFillGet(lCf)

			If Empty(aDados)
				MsgAlert(CAT533021, cCadastro) //"Nenhum registro encontrado."
			EndIf

			oGetCTRB:SetArray(aDados)
			oGetCTRB:Refresh()
		EndIf

	ElseIf "UQF" $ cAlias .and. lCf
		aAlter := {"UQF_MSGDET"}

		If !lFullView
			oWnd := oDlgLog
		Else
			oWnd := oFolder:aDialogs[3]
		EndIf

		oGetCF	:= MsNewGetDados():New(	nRow, nLeft, nBottom, nRight, GD_UPDATE, /*cLinhaOk*/, /*cTudoOk*/,;
										/*cIniCpos*/, aAlter, /*nFreeze*/, /*nMax*/, /*cFieldOk*/, /*cSuperDel*/,;
										/*cDelOk*/, oWnd, aHeader, { aArray }, /*bChange*//*uChange*/, /*cTela*/ )

		oGetCF:oBrowse:bLDblClick := {|| fAltEmail()}

		// --------------------------------------------------------------------------
		// Colunas que não devem ser ordenadas ao clicar no cabeçalho da GetDados
		// --------------------------------------------------------------------------
		Aadd(aCNOCTECRT, GdFieldPos("COR"))
		Aadd(aCNOCTECRT, GdFieldPos("UQF_MSGDET"))
		Aadd(aCNOCTECRT, GdFieldPos("UQF_ALI_WT"))

		oGetCF:oBrowse:bHeaderClick := {|x,y|	lCrescente := lCreCTECRT,;
													aColNaoOrd := aCNOCTECRT,;
													aGetDados := oGetCF:aCols,;
													nOrdena := nOrdCTECRT,;
													IIf(nOrdena == 1, fOrdBrw(x,y), nOrdena++),;
													nOrdCTECRT := nOrdena,;
													lCreCTECRT := lCrescente }

		oGetCF:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		// Se a abertura da página for depois de uma importação
		If !lFullView
			// Popula a GetDados automaticamente.
			aDados := fFillGet(lCf)

			If Empty(aDados)
				MsgAlert(CAT533021, cCadastro) //"Nenhum registro encontrado."
			EndIf

			oGetCF:SetArray(aDados)
			oGetCF:Refresh()
		EndIf

	EndIf

	RestArea(aAreaSX3)
	RestArea(aArea)

Return

/*/{Protheus.doc} fFillGet
Popula a GetDados de acordo com os filtros definidos pelo usuário ou aplicação.
@author Paulo Carvalho
@since 20/12/2018
@type Static Function
/*/
Static Function fFillGet(lCf)
	Local aArea			:= GetArea()

	Local aFilSel		:= {}
	Local aLinha		:= {}
	Local aDados		:= {}
	Local aTCSField		:= {}

	Local cAcao			:= Upper(Left(cAcaoLog, 3))
	Local cAliasQry		:= GetNextAlias()
	Local cAuxDocDe		:= ""
	Local cAuxDocAte	:= ""
	Local cIniCam		:= cAlias + "_"//Right( cAlias, 2 ) + "_"
	Local cQuery		:= ""
	Local cFiliaisIn	:= ""
	Local cTipoReg		:= ""

	Local lDeleted		:= .F.

	Local nI
	Local aSM0Data 		:= FWLoadSM0(.T.)
	Local nPosFil		:= 0
	Local cDesFil		:= ""
	Local cEntidad		:= ""
	Private cTabCam		:= fDefTab() // Define a tabela e o inicio do campo de acordo com o Alias.
	Default lCf	:= .F.
	Do Case
		Case ("INT" $ Upper(cAcaoLog))
			cTipoReg := CAT533005 // "Integração"
		Case ("IMP" $ Upper(cAcaoLog))
			cTipoReg := CAT533002 // "Importação"
	EndCase

	// -------------------------------------------------------------
	// Atualiza o campo Status, pois se o usuário abrir a tela
	// de Filiais o conteúdo da variável status é alterado
	// Juliano Fernandes - 06/05/2019
	// -------------------------------------------------------------
	If Type("oCbStatus") == "O"
		cStatus := oCbStatus:aItems[oCbStatus:nAt]
	EndIf

	// Define o campos que devem passar pela função TCSetField
	Aadd( aTCSField, { cTabCam 	+ "DATA"	, "D", 8	, 0	} )
	Aadd( aTCSField, { cTabCam 	+ "NLINHA"	, "N", 10	, 0	} )

	//-- Separa em array as filiais selecionadas pelo usuário
	aFilSel 	:= fSepFiliais()
	aFiliais 	:= {}
	cFiliaisIn	:= ""

	// Em cada filial selecionada
	For nI := 1 To Len(aFilSel)
		cFiliaisIn += aFilSel[nI]

		If nI < Len(aFilSel)
			cFiliaisIn += ","
		EndIf
	Next nI

	cFiliaisIn := FormatIn(cFiliaisIn, ",")

	cQuery := ""
	cEntidad:= If(lCf,"FORNEC","CLIENT")
	//-- Altera para a filial selecionada pelo usuário
	// fAltFilial(aFilSel[nI])

	// ----------------------------------------------------------
	// Juliano Fernandes - 06/05/19
	// Alterado para após o processamento da query
	// para que insira no array aFilials apenas as
	// filiais em que existem registros na tela
	// ----------------------------------------------------------
	//Aadd(aFiliais, {cFilAnt, xFilial("UQJ")})

	cQuery	+= "SELECT	" + cTabCam + "FILIAL, " 	+ cTabCam 	+ "DATA, "		+ cAlias  + ".R_E_C_N_O_, " 						+ CRLF
	cQuery	+= "  		" + cTabCam + "HORA, " 		+ cTabCam 	+ "USER, " 		+ cTabCam + "ARQUIV, "								+ CRLF
	cQuery	+= "  		" + cTabCam + "REGCOD, " 	+ cTabCam 	+ "NLINHA, " 	+ cTabCam + "STATUS, "								+ CRLF
	cQuery	+= "  		" + cTabCam + "MSG, "		+ cTabCam 	+ "LIDO, "		+ cTabCam + "ACAO   "								+ CRLF

	If "UQF" $ cAlias
		cQuery	+= "  	," 	+ cTabCam + cEntidad+", "	+ cTabCam 	+ "VALOR,  " 	+ cTabCam + "FIL " 									+ CRLF
		cQuery  += "    ,"  + cTabCam + "CANCEL, "   + cTabCam 	+ "BLQMAI "	 																+ CRLF
	ElseIf "UQJ" $ cAlias
		cQuery	+= "    ,"	+ cTabCam + "FIL "																						+ CRLF
	EndIf

	//cQuery	+= "    , ISNULL(CONVERT(VARCHAR(8000), CONVERT(VARBINARY(8000), " + cTabCam + "MSGDET)),'') " + cIniCam + "MSGDET "	+ CRLF
	cQuery	+= " ,UTL_RAW.CAST_TO_VARCHAR2(dbms_lob.substr("+ cIniCam + "MSGDET , 8000, 1)) " + cIniCam + "MSGDET "	+ CRLF

	cQuery	+= "    , UQK.UQK_DESCRI "																								+ CRLF
	cQuery	+= "    , '" + cTipoReg + "' TIPOREG "																					+ CRLF

	cQuery	+= "FROM  	" + RetSqlName( cAlias ) 	+ " " 	+ cAlias 		+ " "												+ CRLF
	cQuery	+= "	LEFT JOIN " + RetSqlName("UQK") + " UQK "																		+ CRLF
	cQuery	+= "		ON UQK.UQK_FILIAL = '" + xFilial("UQK") + "' "																+ CRLF
	cQuery	+= "		AND UQK.UQK_FILPRO = " + cTabCam + "FILIAL"																	+ CRLF
	cQuery	+= "		AND UQK.D_E_L_E_T_ <> '*' "																					+ CRLF

	// cQuery	+= "WHERE  	" + cTabCam	+ "FILIAL = '" 	+ xFilial(cAlias)			+ "' "											+ CRLF
	cQuery	+= "WHERE  	" + cTabCam	+ "FILIAL IN " 	+ cFiliaisIn			+ " "													+ CRLF

	If !Empty( dDataDe )
		cQuery	+= "AND  	" + cTabCam	+ "DATA >= '"		+ DtoS( dDataDe ) 	+ "' " 												+ CRLF
	EndIf

	If !Empty( dDataAte )
		cQuery	+= "AND  	" + cTabCam	+ "DATA <= '"		+ DtoS( dDataAte ) 	+ "' " 												+ CRLF
	EndIf

	If !Empty( cDocDe )
		cAuxDocDe := fDefDocDe(cDocDe, cFiliaisIn)

		cQuery += "AND     " + cTabCam	+ "REGCOD >= '" + cAuxDocDe	+ "' "							  	 							+ CRLF
	EndIf

	If !Empty( cDocAte )
		cAuxDocAte := fDefDocAte(cDocAte, cFiliaisIn)

		cQuery += "AND     " + cTabCam	+ "REGCOD <= '" + cAuxDocAte + "' "							   								+ CRLF

	EndIf

	If !Empty( cAcao )
		cQuery	+= "AND  	" + cTabCam	+ "ACAO = '"		+ cAcao 			+ "' " 												+ CRLF
	EndIf

	// Filtros para visualizações de log após a importação/integração
	If lNaoLidos
		cQuery	+= "AND     " + cTabCam + "USER = '" + UsrRetName( RetCodUsr() ) + "'"												+ CRLF
		cQuery 	+= "AND  	" + cTabCam	+ "LIDO = 'N' "																				+ CRLF
	EndIf

	If "UQF" $ cAlias
		If !Empty( cGClienDe )
			cQuery += "AND     " + cTabCam	+ cEntidad+" >= '" + cGClienDe + "' "							   							+ CRLF
		EndIf

		If !Empty( cGClienAte )
			cQuery += "AND     " + cTabCam	+ cEntidad+" <= '" + cGClienAte + "' "							   							+ CRLF
		EndIf
	EndIf

	If !Empty( cGNomUsuar )
		cQuery += "AND     UPPER(" + cTabCam	+ "USER) = '" + Upper(AllTrim(cGNomUsuar)) + "' "									+ CRLF
	EndIf

	If !Empty(cStatus)
		If  CAT533007 $ cStatus // "Importados"
			cQuery += "AND	" + cTabCam + "STATUS = 'I' "																			+ CRLF
		ElseIf CAT533008 $ cStatus // "Erro"
			cQuery += "AND	" + cTabCam + "STATUS IN ('E', 'D') "																	+ CRLF
		EndIf
	EndIf
	If lChkCF
		cQuery += "AND "+cTabCam+"XIDCF<>' ' "
	Else
		cQuery += "AND "+cTabCam+"XIDCF=' '  "	
	EndIf
	cQuery	+= "AND 	" + cAlias	+ ".D_E_L_E_T_ <> '*' "																			+ CRLF

	MPSysOpenQuery( cQuery, cAliasQry, aTCSField )

	While !(cAliasQry)->(Eof())
		If AScan(aFiliais, {|x| x[2] == (cAliasQry)->&(cIniCam + "FILIAL")}) == 0
			// ------------------------------------------------------------------
			// Inserido duas vezes no array aFilials por questão de adaptação
			// ao modo que o programa foi desenvolvido inicialmente.
			// ------------------------------------------------------------------
			Aadd(aFiliais, {(cAliasQry)->&(cIniCam + "FILIAL"), (cAliasQry)->&(cIniCam + "FILIAL")})
		EndIf

		// Reinicializa aLinha a cada iteração
		aLinha := {}

		// Define a legenda para o registro.
		If (cAliasQry)->&(cIniCam + "STATUS") == "I"
			Aadd( aLinha, oGreen )
		ElseIf (cAliasQry)->&(cIniCam + "STATUS") == "E"
			Aadd( aLinha, oRed )
		ElseIf (cAliasQry)->&(cIniCam + "STATUS") == "D"
			Aadd( aLinha, oBlue )
		EndIf

		/*/
		// 21/02/2019 - Paulo Carvalho
		// Alterado para aparecer a filial do sistema em que o log foi gravado.
		If "UQF" $ cAlias
			Aadd( aLinha, (cAliasQry)->&(cIniCam + "FIL") 	)
		ElseIf "UQJ" $ cAlias
			Aadd( aLinha, (cAliasQry)->&(cIniCam + "FIL") 	)
		EndIf
		/*/

		nPosFil  := aScan(aSM0Data,{|x| Alltrim(x[2]) == Alltrim((cAliasQry)->&(cIniCam + "FILIAL") ) })

		If nPosFil > 0
			cDesFil := aSM0Data[nPosFil][7]
		Else
			cDesFil := ""
		Endif

		Aadd( aLinha, (cAliasQry)->&(cIniCam + "FILIAL") 	)
		Aadd( aLinha, cDesFil				 				)

		Aadd( aLinha, (cAliasQry)->TIPOREG )

		If "UQF" $ cAlias
			Aadd( aLinha, (cAliasQry)->&(cIniCam + "CANCEL")   )
			Aadd( aLinha, (cAliasQry)->&(cIniCam + "BLQMAI")   )
		EndIf

		Aadd( aLinha, StoD((cAliasQry)->&(cIniCam + "DATA")))
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "HORA") 		)
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "REGCOD") 	)

		If "UQF" $ cAlias
			Aadd( aLinha, (cAliasQry)->&(cIniCam + cEntidad)	)
			Aadd( aLinha, (cAliasQry)->&(cIniCam + "VALOR")  	)
		EndIf

		Aadd( aLinha, (cAliasQry)->&(cIniCam + "MSG") 		)
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "MSGDET")	)
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "NLINHA") 	)
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "ARQUIV") 	)
		Aadd( aLinha, (cAliasQry)->&(cIniCam + "USER") 		)
		Aadd( aLinha, cAlias								)
		Aadd( aLinha, (cAliasQry)->R_E_C_N_O_				)
		Aadd( aLinha, lDeleted 								)

		// Adiciona a linha ao array principal
		Aadd( aDados, aLinha )

		(cAliasQry)->(DbSkip())
	EndDo

	(cAliasQry)->(DbCloseArea())

	RestArea(aArea)

Return(AClone(aDados))

/*/{Protheus.doc} fDefTab
Define o Alias que será utilizado de acordo com a importação escolhida.
@author Paulo Carvalho
@since 20/12/2018
@type Static Function
/*/
Static Function fDefTab()

	Local cTabCam	:= ""

	cTabCam := cAlias + "." + cAlias + "_" //Right( cAlias, 2 ) + "_"

Return cTabCam

/*/{Protheus.doc} fAddLegenda
Função para adicionar no aHeader o campo para legenda.
@author Paulo Carvalho
@since 21/12/2018
@param aArray, array, Array contendo a referência de aHeader
@version 1.01
@type function
/*/
Static Function fAddLegenda( aArray )

	Aadd( aArray, { "", "COR", "@BMP", 1, 0, .T., "", "",;
            		"", "R", "", "", .F., "V", "", "", "", ""	})

Return

/*/{Protheus.doc} fAddHeader
Função para adicionar no aHeader o campo determinado.
@author Douglas Gregorio
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

	Local uRet		:= Nil

	DbSelectArea("SX3")
	SX3->(dbSetOrder(2)) // X3_CAMPO

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

/*/{Protheus.doc} fLegenda
Exibe as legendas possíveis ao usuário.
@author Paulo Carvalho
@since 26/12/2018
@type Static Function
/*/
Static Function fLegenda()

	// Instancia browse para Legenda
	Local oLegenda	:= FWLegend():New()

	oLegenda:Add( "", "BR_VERDE"	, CAT533022 ) //Registro processado com sucesso.
	oLegenda:Add( "", "BR_AZUL"		, CAT533023 ) //Registro já processado anteriormente.
	oLegenda:Add( "", "BR_VERMELHO"	, CAT533024 ) //Registro contém erros.

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()

Return

/*/{Protheus.doc} fGeraExcel
Responsável por exportar para excel os dados de Log de importação
@author Icaro Laudade
@since 16/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fGeraExcel()

	Local aColunas		:=	{}
	Local aLinha		:=	{}
	Local aHeader		:=	{}
	Local aCols			:=	{}
	Local cArqXML		:=	""
	Local cNomeArq		:=	""
	Local cPrefixo		:=	""
	Local cWorkSheet	:=	"."//O ponto é apenas para não estourar Error Log caso o Alias seja diferente de UQJ,UQF
	Local cTable		:=	""
	Local cTipoDados	:=	""
	Local cTituloCel	:=	""
	Local lOK			:=	.T.
	Local lSalva		:=	.T.
	Local lTotal		:=	.T.
	Local lCTECRT		:=	.F.
	Local lCTRB			:=	.F.
	Local lFolPag		:=	.F.
	Local lCarta		:=  .F.
	Local nAlign		:=	0
	Local nFormat		:=	0
	Local nI			:=	0
	Local nJ			:=	0
	Local nPosTitulo	:=	1 //Posição do titulo no aHeader
	Local nPosCampo		:=	2 //Posição do campo no aHeader
	Local nPosTipo		:=	8 //Tipo do campo no aHeader
	Local nPosLegend	:=	0
	Local nPosLinha		:=	0
	Local nPosMsgDet	:=	0
	Local oExcel		:=	Nil
	Local oFWMSEx		:=	Nil

	If ValType(oGetCTECRT) == "O"
		If ( !Empty(oGetCTECRT:aCols) .And. !Empty(oGetCTECRT:aCols[1][2]) )
			lCTECRT := .T.
		EndIf
	EndIf

	If ValType(oGetCTRB) == "O"
		If ( !Empty(oGetCTRB:aCols) .And. !Empty(oGetCTRB:aCols[1][2]) )
			lCTRB := .T.
		EndIf
	EndIf

	If ValType(oGetFolPag) == "O"
		If ( !Empty(oGetFolPag:aCols) .And. !Empty(oGetFolPag:aCols[1][2]) )
			lFolPag := .T.
		EndIf
	EndIf
	If ValType(oGetCF) == "O"
		If ( !Empty(oGetCF:aCols) .And. !Empty(oGetCF:aCols[1][2]) )
			lCarta := .T.
		EndIf
	EndIf
	ProcRegua(0)

	If !lCTECRT .And. !lCTRB .And. !lCarta
		lOK := .F.
		MsgAlert(CAT533025, cCadastro) //Não há dados a serem exportados.
	EndIf

	If lOK
		While .T.
			cArqXML := cGetFile( "*.XML",;
			CAT533026,;//Selecione o diretório para salvar o arquivo
			0,;
			IIf(IsSrvUnix(), "/SPOOL/","\SPOOL\"),;
			!lSalva,;
			GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_NETWORKDRIVE+GETF_LOCALFLOPPY,;
			.F.,;
			.F. )

			If (AllTrim(cArqXML) <> (IIf(IsSrvUnix(), "/","\")) .And. ExistDir(cArqXML)) .Or. Empty(cArqXML)
				Exit
			EndIf
		EndDo

		If Empty(cArqXML)
			lOK := .F.
		Else
			cNomeArq := "533" + DToS(Date()) + Replace(Time(),":","")
			cArqXML  += cNomeArq
		EndIf

	EndIf

	If lOK

		For nJ := 1 To 3
			// Definição do Alias
			If nJ == 1
				If lCTECRT
					IncProc(CAT533050) // "Processando CTE/CRT"

					cAlias	:= "UQF"
					aHeader	:= oGetCTECRT:aHeader
					aCols	:= oGetCTECRT:aCols
				Else
					Loop
				EndIf
			ElseIf nJ == 2
				If lCTRB
					IncProc(CAT533051) // "Processando CTRB"

					cAlias := "UQJ"
					aHeader	:= oGetCTRB:aHeader
					aCols	:= oGetCTRB:aCols
				Else
					Loop
				EndIf
			ElseIf nJ == 3
				If lCarta
					IncProc("Processando Carta Frete") // "Processando CTRB"

					cAlias := "UQF"
					aHeader	:= oGetCF:aHeader
					aCols	:= oGetCF:aCols
				Else
					Loop
				EndIf
			EndIf

			If cAlias == "UQJ"
				cPrefixo := "UQJ"
				cTable := NomePrt + " - " + CAT533054 + " - " + VersaoJedi // "CTRB"
				cWorkSheet := CAT533030 //CTRB
			ElseIf cAlias == "UQF"
				If !lCarta
					cPrefixo := "UQF"
					cTable := NomePrt + " - " + CAT533053 + " - " + VersaoJedi // "CTE/CRT"
					cWorkSheet := CAT533032 //CTE CRT
				Else
					cPrefixo := "UQF"
					cTable := NomePrt + " - " + "Carta_frete" + " - " + VersaoJedi // "CTE/CRT"
					cWorkSheet := "Carta_Frete" //CTE CRT
				EndIf
			EndIf

			If ValType(oFWMSEx) == "U"
				oFWMSEx := FWMsExcelEx():New()
			EndIf

			oFWMSEx:AddWorkSheet(cWorkSheet)

			oFWMSEx:AddTable(cWorkSheet, cTable)

			aColunas	:= {}
			nPosLegend	:= 0
			nPosMsgDet	:= 0
			nPosLinha	:= 0

			For nI := 1 To Len(aHeader)

				If Empty(aHeader[nI][nPosTitulo]) .And. nPosLegend == 0 //Se o titulo estiver vazio quer dizer que é a coluna da legenda
					nPosLegend := nI
					Loop
				ElseIf AllTrim(aHeader[nI][nPosCampo]) == cPrefixo + "_MSGDET"
					nPosMsgDet := nI
					Loop
				ElseIf AllTrim(aHeader[nI][nPosCampo]) == cPrefixo + "_NLINHA"
					cTituloCel := aHeader[nI][nPosTitulo]
					cTipoDados := "C"
					nPosLinha := nI
				Else
					cTituloCel := aHeader[nI][nPosTitulo]

					If AllTrim(aHeader[nI][nPosCampo]) == cPrefixo + "_REC_WT"
						cTipoDados := "C"
					Else
						cTipoDados := aHeader[nI][nPosTipo]
					EndIf
				EndIf

				aAdd(aColunas, {cTituloCel, cTipoDados})
			Next

			If nPosLegend < nPosLinha
				nPosLinha -= 1 //A posição da legenda será excluida do aCols
				//por isso se estiver antes da posição do campo linha, a variavel nPosLinha
				//deverá voltar uma posição para representar sua nova posição
			EndIf

			If nPosLegend < nPosMsgDet
				nPosMsgDet -= 1 //A posição da legenda será excluida do aCols
				//por isso se estiver antes da posição do campo msgDet, a variavel nPosMsgDet
				//deverá voltar uma posição para representar sua nova posição
			EndIf

			If nPosMsgDet < nPosLinha
				nPosLinha -= 1 //A posição da mensagem detalhada será excluida do aCols
				//por isso se estiver antes da posição do campo linha, a variavel nPosLinha
				//deverá voltar uma posição para representar sua nova posição
			EndIf

			//Adicionando colunas
			For nI := 1 To Len(aColunas)

				If aColunas[nI][2] == "N" .And. nI != nPosLinha
					nAlign := 3  //Right
					nFormat := 2 //Number
				ElseIf aColunas[nI][2] == "D"
					nAlign := 2
					nFormat := 4
				Else
					If (nI == nPosLinha) .Or. (AllTrim(Upper(aColunas[nI][1])) == "RECNO WT")
						nAlign := 3  //Right
					Else
						nAlign := 1  //Left
					EndIf

					nFormat := 1 //General
				EndIf

				oFWMSEx:AddColumn(cWorkSheet, cTable, aColunas[nI][1], nAlign, nFormat, !lTotal)
			Next nI

			//Adicionando linhas
			For nI := 1 To Len(aCols)

				aLinha := aClone(aCols[nI])

				//Exclusão da coluna da legenda da exportação Excel
				aDel(aLinha, nPosLegend)
				aSize(aLinha, Len(aLinha)-1)

				aDel(aLinha, nPosMsgDet)
				aSize(aLinha, Len(aLinha)-1)

				//Exclusão da flag de exclusão do aCols
				aDel(aLinha,  Len(aLinha))
				aSize(aLinha, Len(aLinha)-1)

				aLinha[nPosLinha] := cValToChar(aLinha[nPosLinha]) //Conversão do número da linha para caracter

				aLinha[Len(aLinha)] := cValToChar(aLinha[Len(aLinha)]) //Conversão do Recno para caracter

				oFWMSEx:AddRow(cWorkSheet, cTable, aLinha)
			Next nI

		Next nJ

		//Ativando o arquivo e gerando o xml
	    oFWMsEx:Activate()
	    oFWMsEx:GetXMLFile(cArqXML + ".xml")

		MsgAlert(CAT533033 + CRLF + CAT533034 + AllTrim(cArqXML) + ".xml", cCadastro) // Arquivo gerado com sucesso!+CRLF+Diretório:

	    //Abrindo o excel e abrindo o arquivo xml
	    oExcel := MsExcel():New() //Abre uma nova conexão com Excel
	    oExcel:WorkBooks:Open(cArqXML + ".xml") //Abre uma planilha
	    oExcel:SetVisible(.T.) //Visualiza a planilha
	    oFWMsEx:DeActivate()
	    oExcel:Destroy() //Encerra o processo do gerenciador de tarefas

    EndIf

Return Nil

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

	Local aArea		:=	GetArea()
	Local cAliasQry	:=	GetNextAlias()
	Local cAuxDocDe	:=	""
	Local cQuery	:=	""

	cQuery	+= " SELECT "  + cTabCam + "REGCOD "										+ CRLF
	cQuery	+= " FROM " + RetSqlName(cAlias) + " " + cAlias + " "					+ CRLF
	// cQuery	+= " WHERE	"  + cTabCam + "FILIAL = '" + xFilial(cALias) + "' "			+ CRLF
	cQuery	+= " WHERE	"  + cTabCam + "FILIAL IN " + cFiliaisIn + " "					+ CRLF
	cQuery	+= "   AND	"  + cTabCam + "REGCOD LIKE '%" + AllTrim(cDocumento) + "%' "	+ CRLF
	cQuery	+= "   AND	"  + cAlias  + ".D_E_L_E_T_ <> '*' "							+ CRLF
	cQuery	+= "ORDER BY " + cTabCam + "REGCOD "										+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocDe := (cAliasQry)->&(cAlias+"_REGCOD")//(cAliasQry)->&(Right( cAlias, 2 )+"_REGCOD")
	EndIf

	If Empty(cAuxDocDe)
		If "UQJ" $ cAlias
			cAuxDocDe := "CTRB"+AllTrim(cDocumento)+"PR"
		Else
			cAuxDocDe := cDocumento
		EndIf
	EndIf

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

	Local aArea			:=	GetArea()
	Local cAliasQry		:=	GetNextAlias()
	Local cAuxDocAte	:=	""
	Local cQuery		:=	""

	cQuery	+= " SELECT "  + cTabCam + "REGCOD "										+ CRLF
	cQuery	+= " FROM " + RetSqlName(cAlias) + "  " + cAlias + " "					+ CRLF
	// cQuery	+= " WHERE	"  + cTabCam + "FILIAL = '" + xFilial(cALias) + "' "			+ CRLF
	cQuery	+= " WHERE	"  + cTabCam + "FILIAL IN " + cFiliaisIn + " "					+ CRLF
	cQuery	+= "   AND	"  + cTabCam + "REGCOD LIKE '%" + AllTrim(cDocumento) + "%' "	+ CRLF
	cQuery	+= "   AND	"  + cAlias + ".D_E_L_E_T_ <> '*' "								+ CRLF
	cQuery	+= "ORDER BY " + cTabCam + "REGCOD DESC"									+ CRLF

	MPSysOpenQuery(cQuery, cAliasQry)

	If !(cAliasQry)->(Eof())
		(cAliasQry)->(DbGoTop())
		cAuxDocAte := (cAliasQry)->&(cAlias+"_REGCOD")//&(Right( cAlias, 2 )+"_REGCOD")
	EndIf

	If Empty(cAuxDocAte)
		If "UQJ" $ cAlias
			cAuxDocAte := "CTRB"+AllTrim(cDocumento)+"RD"
		Else
			cAuxDocAte := cDocumento
		EndIf
	EndIf

	RestArea(aArea)

Return cAuxDocAte

/*/{Protheus.doc} fOpcFiliais
Executa a função f_Opcoes para a seleção de uma ou mais filiais a serem filtradas na pesquisa.
@author Juliano Fernandes
@since 18/02/2019
@version 1.01
@param cObj, caracter, Objeto a ser atualizado após a seleção das filiais
@type Function
/*/
Static Function fOpcFiliais(cObj)

	Local aArea			:= GetArea()
	Local aOpcoes		:= {}
	Local aInfoFil		:= {}
	Local cTitulo		:= CAT533019 //Filiais
	Local cReadVar		:= ReadVar()
	Local cF3Ret		:= ""
	Local cCadOld		:= cCadastro
	Local lContinua		:= .T.
	Local l1Elem		:= .F.
	Local cOpcoes		:= ""
	Local nElemRet		:= 0
	Local uVarRet		:= Nil

	If Empty(cReadVar)
		lContinua := .F.
	EndIf

	If lContinua
		CursorWait()

		cCadastro := StrTran(cCadastro, NomePrt, "")
		cCadastro := StrTran(cCadastro, VersaoJedi, "")
		cCadastro := StrTran(cCadastro, "-", "")
		cCadastro := AllTrim(cCadastro) + " - " + CAT533019//Filiais

		uVarRet := GetMemVar(cReadVar)

		nTamFilial := TamSX3("C5_FILIAL")[1] // Tamanho da chave que sera retornada.

		aInfoFil := fGetFilUser()

		aOpcoes := aInfoFil[1]
		cOpcoes := aInfoFil[2]

		If !Empty(aOpcoes)
			nElemRet := Len(aOpcoes)

			CursorArrow()

			IF f_Opcoes(	@uVarRet    ,;    //Variavel de Retorno
							cTitulo     ,;    //Titulo da Coluna com as opcoes
							@aOpcoes    ,;    //Opcoes de Escolha (Array de Opcoes)
							@cOpcoes    ,;    //String de Opcoes para Retorno
							Nil         ,;    //Nao Utilizado
							Nil         ,;    //Nao Utilizado
							l1Elem      ,;    //Se a Selecao sera de apenas 1 Elemento por vez
							nTamFilial  ,;    //Tamanho da Chave
							nElemRet    ,;    //No maximo de elementos na variavel de retorno
							.T.         ,;    //Inclui Botoes para Selecao de Multiplos Itens
							.F.         ,;    //Se as opcoes serao montadas a partir de ComboBox de Campo ( X3_CBOX )
							Nil         ,;    //Qual o Campo para a Montagem do aOpcoes
							.F.         ,;    //Nao Permite a Ordenacao
							.F.         ,;    //Nao Permite a Pesquisa
							.F.         ,;    //Forca o Retorno Como Array
							Nil          ;    //Consulta F3
						)

				// Atualiza a Variável de Retorno
				cF3Ret := uVarRet

				// Atualiza a Variável de Memória com o Conteúdo do Retorno
				SetMemVar(cReadVar,cF3Ret)
			Else
				// Se nao confirmou a f_Opcoes retorna o Conteudo de entrada
				cF3Ret := uVarRet
			EndIf
		Else
			// Se nao confirmou a f_Opcoes retorna o Conteudo de entrada
			cF3Ret := uVarRet
		EndIf

		cCadastro := cCadOld
	EndIf

	&(cObj + ":Refresh()")

	RestArea(aArea)

Return(.T.)

/*/{Protheus.doc} fGetFilUser
Retorna as filiais que o usuário tem acesso.
@author Juliano Fernandes
@since 18/02/2019
@version 1.01
@type Function
/*/
Static Function fGetFilUser()

	Local aFiliais	:= {}
	Local aSM0		:= FWLoadSM0()
    Local aUsrAux   := {}
	Local cCodUsr 	:= RetCodUsr()
	Local cFiliais	:= ""
    Local nPosFil   := 0
	Local nI		:= 0
	aUsrAux := AClone(FWUsrEmp( cCodUsr ))

	For nI := 1 To Len(aSM0)
		If aSM0[nI][1] == SM0->M0_CODIGO
			//Agora procura pela empresa + filial nos acessos
			nPosFil := AScan(aUsrAux, {|x| x == aSM0[nI,1] + aSM0[nI,2] })

			If nPosFil > 0 .Or. "@" $ aUsrAux[1]
				Aadd(aFiliais, AllTrim(aSM0[nI,2]) + " - " + AllTrim(aSM0[nI,7]))
				cFiliais += AllTrim(aSM0[nI,2])
			EndIf
		EndIf
	Next nI

Return({aFiliais, cFiliais})

/*/{Protheus.doc} fSepFiliais
Separa em array as filiais selecionadas pelo usuário.
@author Juliano Fernandes
@since 18/02/2019
@version 1.01
@type Function
/*/
Static Function fSepFiliais()

	Local aFilSel 		:= {}
	Local cFilAcesso	:= ""
	Local cFilAux 		:= ""
	Local cFilSel		:= ""

/*	If "CTE/CRT" $ cLogImp
		cFilSel := cGFilCTE
	ElseIf "CTRB" $ cLogImp
		cFilSel := cGFilCTRB
	ElseIf Lower(CAT533044) $ Lower(cLogImp)
	 	cFilSel := cGFilVouch
	EndIf
*/
	cFilSel := cGFiliais

	If !Empty(cFilSel)
		cFilAux := StrTran(cFilSel, "*", "")

		While !Empty(cFilAux)
			Aadd(aFilSel, Left(cFilAux, nTamFilial))

			cFilAux := SubStr(cFilAux, nTamFilial + 1, Len(cFilAux))
		EndDo
	EndIf

	If Empty(aFilSel)
		cFilAcesso := fGetFilUser()[2]

		While !Empty(cFilAcesso)
			Aadd(aFilSel, Left(cFilAcesso, nTamFilial))
			cFilAcesso := SubStr(cFilAcesso, nTamFilial + 1, Len(cFilAcesso))
		EndDo
	EndIf

	// ---------------------------------------------------------------------------------
	// Filial 'XXXX' se refere à registros selecionados para importação e que
	// não tem o cadastro da filial Veloce na tabela UQK.
	// É gravado o conteúdo 'XXXX' para que possa ser visualizado no Log.
	// ---------------------------------------------------------------------------------
	If !Empty(aFilSel)
		Aadd(aFilSel, Replicate("X", nTamFilial))
	EndIf

Return(aFilSel)

/*/{Protheus.doc} fVldFilial
Validação da Filial informada no Get.
@author Juliano Fernandes
@since 18/02/2019
@version 1.01
@type Function
/*/
Static Function fVldFilial()

	Local aFilSel	:= {}
	Local aFilAcess	:= {}
	Local cFilSel 	:= ""
	Local lValid 	:= .T.
	Local nI		:= 0

	cFilSel := cGFiliais

	cFilSel := StrTran(cFilSel, "*", "")

	If !Empty(cFilSel)
		While !Empty(cFilSel)
			Aadd(aFilSel, Left(cFilSel, nTamFilial))

			cFilSel := SubStr(cFilSel, nTamFilial + 1, Len(cFilSel))
		EndDo

		For nI := 1 To Len(aFilSel)
			If !FWFilExist(cEmpAnt, aFilSel[nI])
				lValid := .F.
				MsgAlert(CAT533035 + aFilSel[nI], cCadastro) //"Filial inválida: "
				Exit
			EndIf
		Next nI

		If lValid
			//-- Verifica se o usuário possui acesso às filiais selecionadas
			aFilAcess := fGetFilUser()[1]

			For nI := 1 To Len(aFilSel)
				If AScan(aFilAcess, {|x| aFilSel[nI] $ x}) == 0
					lValid := .F.
					MsgAlert(CAT533036 + aFilSel[nI], cCadastro) //"Usuário sem acesso à filial: "
					Exit
				EndIf
			Next nI
		EndIf
	EndIf

Return(lValid)

/*/{Protheus.doc} fAltFilial
Altera a filial para o processamento das linhas dos arquivos de importação de CTE/CRT e CTRB.
@author Juliano Fernandes
@since 07/02/2019
@version 1.01
@type Function
/*/
Static Function fAltFilial(cFilSel)

	If cFilAnt != cFilSel
		cFilAnt := cFilSel
		cNumEmp := cEmpAnt + cFilAnt

		OpenSM0(cEmpAnt + cFilAnt)
		OpenFile(cEmpAnt + cFilAnt)
	EndIf

Return(Nil)

/*/{Protheus.doc} fAltEmail
Define se a coluna de envio de email pode ser alterada.
@author Icaro Laudade
@since 30/08/2019
@return Nenhum, Não há retorno
@type function
/*/
Static Function fAltEmail()

	Local aAlter		:=	{}
	Local cNewFil		:=	""
	Local nLinPos		:=	0
	Local nPosCancel 	:=	0
	Local nPosEmail		:=	0
	Local nPosRecno		:=	0

	nPosCancel	:= AScan(oGetCTECRT:aHeader, {|x| AllTrim(x[2]) == "UQF_CANCEL" })
	nPosEmail	:= AScan(oGetCTECRT:aHeader, {|x| AllTrim(x[2]) == "UQF_BLQMAI"})
	nPosRecno	:= AScan(oGetCTECRT:aHeader, {|x| AllTrim(x[2]) == "UQF_REC_WT" })

	If nPosCancel > 0 .And. nPosRecno > 0 .And. nPosEmail > 0 .And. Len(oGetCTECRT:aCols) > 0
		If nPosEmail == oGetCTECRT:oBrowse:ColPos
			nLinPos := oGetCTECRT:nAt

			If AllTrim(oGetCTECRT:aCols[nLinPos][nPosCancel]) $ "RC"
				DbSelectArea("UQF")
				UQF->( DbGoto( oGetCTECRT:aCols[nLinPos][nPosRecno] ))
				If UQF->(Recno()) == oGetCTECRT:aCols[nLinPos][nPosRecno]

					If AllTrim(UQF->UQF_STATUS) == "E" .Or. AllTrim(UQF->UQF_ACAO) == "IMP"
						cNewFil := fGetFilial(UQF->UQF_FIL)

						If !Empty(cNewFil)
							fAltFilial(cNewFil)

							DbSelectArea("UQD")
							UQD->(DbSetOrder(1)) //UQD_FILIAL+UQD_IDIMP
							If UQD->(DbSeek(xFilial("UQD") + UQF->UQF_IDIMP))
								If UQD->UQD_STATUS == "P"
									MsgAlert( CAT533040 + AllTrim(UQD->UQD_NUMERO) + CAT533041, cCadastro) // "Alteração bloqueada. O arquivo " # " já foi integrado ao Protheus."
								Else
									Aadd( aAlter, "UQF_BLQMAI" )
								EndIf
							Else
								Aadd( aAlter, "UQF_BLQMAI" )
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	Aadd( aAlter, "UQF_MSGDET" )

	oGetCTECRT:oBrowse:aAlter := oGetCTECRT:aAlter := aAlter
	oGetCTECRT:oBrowse:Refresh()
	oGetCTECRT:Refresh()

	If !Empty(aAlter)
		oGetCTECRT:EditCell()
	EndIf

Return(Nil)

/*/{Protheus.doc} fGrvAlt
Grava as alterações do log
@author Icaro Laudade
@since 30/08/2019
@return Nenhum, Não há retorno
@type function
/*/
Static Function fGrvAlt()

	Local aAreaUQD		:=	UQD->(GetArea())
	Local aAreaUQF		:=	UQF->(GetArea())
	Local aCols 		:=	{}
	Local cNewFil		:=	""
	Local cQuery		:=	""
	Local lAlt			:=	.F. //Indica se houve uma alteração
	Local nI			:=	0
	Local nTotBlq		:=	0
	Local nPosCancel	:=	0
	Local nPosEmail		:=	0
	Local nPosRecno		:=	0

	aCols := oGetCTECRT:aCols

	If !Empty(aCols) .Or. !Empty(aCols[1,2])

		nPosCancel	:= aScan(oGetCTECRT:aHeader, { |x| AllTrim(x[2]) == "UQF_CANCEL" })
		nPosEmail	:= aScan(oGetCTECRT:aHeader, { |x| AllTrim(x[2]) == "UQF_BLQMAI"})
		nPosRecno	:= aScan(oGetCTECRT:aHeader, { |x| AllTrim(x[2]) == "UQF_REC_WT" })

		If nPosCancel > 0 .And. nPosEmail > 0 .And. Len(aCols) > 0
			For nI := 1 To Len(aCols)

				If AllTrim(aCols[nI][nPosCancel]) $ "RC"
					//Previne que grave se selecionar a opção em branco no combobox
					If !Empty(aCols[nI][nPosEmail])

						DbSelectArea("UQF")
						UQF->(DbGoto( aCols[nI][nPosRecno] ))
						If UQF->(Recno()) == aCols[nI][nPosRecno]

							//If !Empty(UQF->UQF_IDIMP) // Logs com IDIMP em branco indicam que o arquivo não foi importado e gravado na UQD

								lAlt := .T. //Como ao abrir a tela é criada uma linha em branco essa variavel lógica
											//previne que a mensagem de sucesso seja exibida antes de se pesquisar

								UQF->(Reclock("UQF", .F.))
									UQF->UQF_BLQMAI := aCols[nI][nPosEmail]
								UQF->(MsUnlock())

								cNewFil := fGetFilial(UQF->UQF_FIL)

								If AllTrim(aCols[nI][nPosEmail]) == "S"

									If !Empty(cNewFil)

										//Para o caso do usuário ter gravado "Sim"
										//Irá BLOQUEAR o envio de email de pendências para esse arquivo

										fAltFilial(cNewFil)

										DbSelectArea("UQD")
										UQD->(DbSetOrder(1)) //UQD_FILIAL+UQD_IDIMP
										If UQD->(DbSeek(xFilial("UQD") + UQF->UQF_IDIMP))

											UQD->(Reclock("UQD", .F.))
												UQD->UQD_BLQMAI := aCols[nI][nPosEmail]
											UQD->(MsUnlock())

										EndIf

										cNewFil := ""
									EndIf

								ElseIf AllTrim(aCols[nI][nPosEmail]) == "N"

									If !Empty(cNewFil)

										//Para o caso do usuário ter gravado "Não"
										//Irá verificar se existe algum outro registro de log relacionado a esse arquivo marcado como "Sim"
										//Se não houver irá LIBERAR o envio de email de pendências para esse arquivo

										fAltFilial(cNewFil)

										cQuery := " SELECT COUNT('UQF_BLQMAI') TOTBLQ "					+ CRLF
										cQuery += " FROM " + RetSQLName("UQF") + " UQF "				+ CRLF
										cQuery += " WHERE UQF.UQF_FILIAL = '" + xFilial("UQF") + "' "	+ CRLF
										cQuery += "   AND UQF.UQF_IDIMP = '" + UQF->UQF_IDIMP + "' "		+ CRLF
										cQuery += "   AND UQF.UQF_REGCOD = '" + UQF->UQF_REGCOD + "'"		+ CRLF
										cQuery += "   AND UQF.UQF_BLQMAI  = 'S' "						+ CRLF
										cQuery += "   AND UQF.D_E_L_E_T_ <> '*' "						+ CRLF

										nTotBlq := MPSysExecScalar(cQuery, "TOTBLQ")

										If nTotBlq == 0

											DbSelectArea("UQD")
											UQD->(DbSetOrder(1)) //UQD_FILIAL+UQD_IDIMP
											If UQD->(DbSeek(xFilial("UQD") + UQF->UQF_IDIMP))

												//Grava Não no campo de bloqueio de email da UQD

												UQD->(Reclock("UQD", .F.))
													UQD->UQD_BLQMAI := aCols[nI][nPosEmail]
												UQD->(MsUnlock())

											EndIf

										EndIf

										cNewFil := ""
									EndIf

								EndIf

							//EndIf
						EndIf

					EndIf

				EndIf
			Next nI
		EndIf

		If lAlt
			MsgInfo(CAT533038, cCadastro) //"Alterações salvas com sucesso."
		EndIf

	Else
		MsgAlert(CAT533039, cCadastro) //"Apenas logs de arquivos CTE/CRT podem ser alterados."
	EndIf

	RestArea(aAreaUQD)
	RestArea(aAreaUQF)

Return

/*/{Protheus.doc} fGetFilial
Responsável por retornar a filial cadastrada na tabela UQK de acordo com a filial Veloce
@author Icaro Laudade
@since 05/09/2019
@return cFilProt, Filial encontrada na UQK de acordo com a filial Veloce
@param cFilVeloce, characters, Filial Veloce
@type function
/*/
Static Function fGetFilial( cFilVeloce )
	Local aAreaUQK	:=	UQK->(GetArea())
	Local cFilProt	:=	""

	DbSelectArea("UQK")
	UQK->(DbSetOrder(1))//UQK_FILIAL+UQK_FILARQ
	If UQK->(DbSeek( xFilial("UQK") + cFilVeloce ))
		cFilProt := UQK->UQK_FILPRO
	EndIf

	RestArea(aAreaUQK)

Return cFilProt

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
		If "SCHED" $ cGCodUsuar
			cGNomUsuar := "SCHEDULE"
		Else
			cGNomUsuar := UsrRetName(cGCodUsuar)
		EndIf

		If Empty(cGNomUsuar)
			lValid := .F.
			Help(" ",1,"REGNOIS")
		EndIf
	EndIf

	cGCodUsuar := PadR(cGCodUsuar,8)

Return(lValid)

/*/{Protheus.doc} fMontFolder
Montagem do folder.
@author Juliano Fernandes
@since 07/01/2020
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fMontFolder()

	Local aFolder		:= {}

	Local bChgFolder	:= {|| fChgFolder()}

	Local nRow			:= oSize:GetDimension( "FOLDER", "LININI" )
	Local nLeft			:= oSize:GetDimension( "FOLDER", "COLINI" )
	Local nWidth		:= oSize:GetDimension( "FOLDER", "XSIZE"  )
	Local nHeight		:= oSize:GetDimension( "FOLDER", "YSIZE"  ) + 15 // + 15 para compensar a falta da barra de título

	If cTipoArq != "CON"
		aFolder := {CAT533053, CAT533054,'Carta Frete'} // "CTE/CRT" "CTRB"
		bChgFolder := {|| fChgFolder()}
	Else
		aFolder := {CAT533028} // "Contábil"
		bChgFolder := {|| }
	EndIf

	oFolder := TFolder():New(nRow,nLeft,aFolder,,oDlgLog,,,,lPixel,,nWidth,nHeight)

	oFolder:bChange := bChgFolder

Return(Nil)

/*/{Protheus.doc} fChgFolder
Função executada ao mudar de aba no Folder.
@author Juliano Fernandes
@since 03/03/2020
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fChgFolder()

	Do Case
		Case (oFolder:nOption == 1 .or. oFolder:nOption == 3 ) // CTE/CRT
			cAlias := "UQF"
		Case (oFolder:nOption == 2) // CTRB
			cAlias := "UQJ"
	EndCase

Return(Nil)

/*/{Protheus.doc} fFiltraDad
Função responsável por filtrar dados para a tela.
@author Juliano Fernandes
@since 07/01/2020
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fFiltraDad(lcf)

	Local aDadosImp	:= {}
	Local aDadosInt	:= {}
	Local aDados	:= {}

	aDados := {}

	ProcRegua(0)

	If cTipoArq != "CON"

		If lChkCTECRT .OR. lChkCF
			IncProc(CAT533050) // "Processando CTE/CRT"

			cAlias := "UQF"

			If lChkImport
				cAcaoLog	:= CAT533002 // "Importação"
				aDadosImp	:= fFillGet(lcf)

				If !Empty(aDadosImp)
					AEval(aDadosImp, {|x| Aadd(aDados, x)})
				EndIf
			EndIf

			If lChkInteg
				cAcaoLog	:= CAT533005 // "Integração"
				aDadosInt	:= fFillGet(lcf)

				If !Empty(aDadosInt)
					AEval(aDadosInt, {|x| Aadd(aDados, x)})
				EndIf
			EndIf
			If !lChkCF
				oFolder:ShowPage(1)
			Else
				oFolder:ShowPage(3)
			EndIf	
		EndIf
		If !lChkCF
			oGetCTECRT:SetArray(aDados)
			oGetCTECRT:Refresh()
		Else
			oGetCF:SetArray(aDados)
			oGetCF:Refresh()
		Endif	

		aDados := {}

		If lChkCTRB
			IncProc(CAT533051) // "Processando CTRB"

			cAlias := "UQJ"

			If lChkImport
				cAcaoLog	:= CAT533002 // "Importação"
				aDadosImp	:= fFillGet(lcf)

				If !Empty(aDadosImp)
					AEval(aDadosImp, {|x| Aadd(aDados, x)})
				EndIf
			EndIf

			If lChkInteg
				cAcaoLog	:= CAT533005 // "Integração"
				aDadosInt	:= fFillGet(lcf)

				If !Empty(aDadosInt)
					AEval(aDadosInt, {|x| Aadd(aDados, x)})
				EndIf
			EndIf

			oFolder:ShowPage(2)
		EndIf

		oGetCTRB:SetArray(aDados)
		oGetCTRB:Refresh()

		aDados := {}
	EndIf

Return(Nil)

/*/{Protheus.doc} fOrdBrw
Função para ordernar registros pela coluna clicada
@author Douglas Gregorio
@since 29/08/2018
@param oObjGet, object, Getdados com dados
@param nColPos, numerico, posição da coluna clicada
@type function
/*/
Static Function fOrdBrw(oGet, nCol)

	Local oGetDados := oGet

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

Return(Nil)

/*/{Protheus.doc} fChgTpPesq
Função executada ao mudar o tipo de visualização da tela de Log.
@author Juliano Fernandes
@since 03/03/2020
@version 1.0
@return Nil, Não há retorno
@type function
/*/
Static Function fChgTpPesq()

	Local bSelCTECRT	:= {||  lChkCTECRT .And. !lChkCTRB}
	Local bSelCTRB		:= {|| !lChkCTECRT .And.  lChkCTRB}
	Local bSelTodos		:= {||  lChkCTECRT .And.  lChkCTRB}
	Local bSelNenhum	:= {|| !lChkCTECRT .And. !lChkCTRB}

	cDocDe     := Space(20) ; cDocAte := Space(20)
	cGClienDe  := Space( TamSX3("A1_COD")[1] ) ; cGClienAte := Space( TamSX3("A1_COD")[1] )

	oGDocDe:lVisible   := .F. ; oGDocAte:lVisible   := .F.
	oGDocDeUQF:lVisible := .F. ; oGDocAteUQF:lVisible := .F.
	oGDocDeUQJ:lVisible := .F. ; oGDocAteUQJ:lVisible := .F.

	oGClienDe:lVisible := .F. ; oGClienAte:lVisible := .F.

	Do Case

		Case ( EVal(bSelCTECRT) ) // Selecionado somente CTE/CRT
			oGDocDeUQF:lVisible := .T. ; oGDocAteUQF:lVisible := .T.
			oGClienDe:lVisible := .T. ; oGClienAte:lVisible := .T.

		Case ( EVal(bSelCTRB) ) // Selecionado somente CTRB
			oGDocDeUQJ:lVisible := .T. ; oGDocAteUQJ:lVisible := .T.

		Case ( EVal(bSelTodos) ) // Selecionado todos
			oGDocDe:lVisible   := .T. ; oGDocAte:lVisible   := .T.
			oGClienDe:lVisible := .T. ; oGClienAte:lVisible := .T.

		Case ( EVal(bSelNenhum) ) // Nenhum selecionado
			oGDocDe:lVisible := .T. ; oGDocAte:lVisible := .T.

		Otherwise
			oGDocDe:lVisible := .T. ; oGDocAte:lVisible := .T.

			If lChkCTECRT
				oGClienDe:lVisible := .T. ; oGClienAte:lVisible := .T.
			EndIf

	EndCase

	oGDocDe:Refresh() ; oGDocAte:Refresh()
	oGDocDeUQF:Refresh() ; oGDocAteUQF:Refresh()
	oGDocDeUQJ:Refresh() ; oGDocAteUQJ:Refresh()

	oGClienDe:Refresh() ; oGClienAte:Refresh()

Return(Nil)

#Include 'Totvs.ch'
#Include "CATTMS.ch"

// Variáveis Estáticas
Static NomePrt		:= "PRT0528"
Static VersaoJedi	:= "V1.19"

/*/{Protheus.doc} PRT0528
Realiza a manutenção e integração dos conhecimentos importados.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type User Function
/*/
User Function PRT0528(lAuto, lCTECRT, lCTRB)

	Local aArea				:= GetArea()
	Local aRotina			:= {}

	Local bOk				:= {|| lOk := .T., oDialog:End() }
	Local bCancel			:= {|| oDialog:End() }
	Local bEnchoice

	Local cFilBkp			:= cFilAnt
	Local nTop				:= Nil
	Local nLeft				:= Nil
	Local nBottom			:= Nil
	Local nRight			:= NIl

	// Variáveis para controle de operações
	Private NGETDADOS		:= 1	// Define operação de criação da GetDados
	Private NFILTRAR		:= 2	// Define operação de filtragem dos dados
	Private NINTEGRAR		:= 3	// Define operação de integração dos dados
	Private NEXCLUIR		:= 4	// Define operação de exclusão do arquivo importado.
	Private NESTORNAR		:= 5	// Define operação de Estorno de Integração
	Private NCHECK			:= 6	// Define operação de marcar/desmarcar dados
	Private NDETALHES		:= 7	// Define operação de ver os detalhes dos dados
	Private NPEDVENDA		:= 8	// Define operação de ver o Pedido de Venda
	Private NNOTAFISCAL		:= 9	// Define operação de ver a Nota Fiscal
	Private NIMPRIMIR		:= 10	// Define operação de imprimir os dados
	Private NLANCCTB		:= 11	// Define operação de Visualizar os Lançamentos Contábeis
	Private NCONTAPAGAR		:= 12   // Define operação de ver as Contas a pagar

	Private CTE_CRT			:= CAT528003 // "CTE/CRT"		// Define operação de exclusão do documento selecionado
	Private CTRB			:= CAT528017 // "CTRB"			// Define operação de exclusão do documento selecionado
	Private CTE_CF			:= "CTE/CF"

	Private aHeaderUQD
	Private aHeaderUQE
	Private aHeaderUQB
	Private aHeaderUQC
	Private aHeaderUQG
	Private aHeaderUQH
	Private aHeaderUQI

	Private aFiliais		:= {}

	Private cAlias			:= "UQF"
	Private cCadasCTE		:= NomePrt + IIf(FwIsInCallStack("U_PRT0528C")," - CARTA FRETE ",CAT528001) + VersaoJedi // #" - Ordens de Venda - "
	Private cCadasCTRB		:= NomePrt + CAT528002 + VersaoJedi // #" - Pagamentos - "
	Private cCadastro		:= cCadasCTE

	Private cRecPag			:= IIf(FwIsInCallStack("U_PRT0528R"),"R",IIf(FwIsInCallStack("U_PRT0528P"),"P",IIf(FwIsInCallStack("U_PRT0528C"),"C","")))
	Private cTipoArq		:= IIf(cRecPag == "R", CTE_CRT, IIf(cRecPag == "P", CTRB, IIf(cRecPag == "C", CTE_CF, CAT528003))) // #"CTE/CRT"
	Private cPerg			:= "CATTIPOINT"
	Private cCbAgrupa		:= CAT528004	// #"Não"
	Private cCbStatus		:= CAT528005	// #"Todos"
	Private cClienteDe		:= Space( TamSX3("A1_COD")[1] )
	Private cClienteAte		:= Space( TamSX3("A1_COD")[1] )
	Private cFornecDe		:= Space( TamSX3("A2_COD")[1] )
	Private cFornecAte		:= Space( TamSX3("A2_COD")[1] )
	Private cFornecedorDe		:= Space( TamSX3("A2_COD")[1] )
	Private cFornecedorAte		:= Space( TamSX3("A2_COD")[1] )	
	Private cFornDe			:= Space( TamSX3("A2_COD")[1] )
	Private cFornAte		:= Space( TamSX3("A2_COD")[1] )
	Private cDocDe			:= Space( TamSX3("UQD_NUMERO")[1] )
	Private cDocAte			:= Space( TamSX3("UQD_NUMERO")[1] )
	Private cDocDeUQB		:= Space( TamSX3("UQB_NUMERO")[1] )
	Private cDocAteUQB		:= Space( TamSX3("UQB_NUMERO")[1] )
	Private cDocDeUQG		:= Space( TamSX3("UQG_REF")[1] )
	Private cDocAteUQG		:= Space( TamSX3("UQG_REF")[1] )
	Private cPedidoDe		:= Space( TamSX3("C5_NUM")[1] )
	Private cPedidoAte		:= Space( TamSX3("C5_NUM")[1] )
	Private cPedComDe		:= Space( TamSX3("C7_NUM")[1] )
	Private cPedComAte		:= Space( TamSX3("C7_NUM")[1] )
	Private cGNFDe			:= Space( TamSX3("F2_DOC")[1] )
	Private cGNFAte			:= Space( TamSX3("F2_DOC")[1] )
	Private cGNTitDe		:= Space( TamSX3("UQI_NUM")[1] )
	Private cGNTitAte		:= Space( TamSX3("UQI_NUM")[1] )
	Private cGLoteDe		:= Space( TamSX3("UQI_LOTE")[1] )
	Private cGLoteAte		:= Space( TamSX3("UQI_LOTE")[1] )
	Private cGFilCTE		:= Space( 200 )
	Private cGFilCTRB		:= Space( 200 )
	Private cMemIDImp		:= ""

	Private dDataDe			:= Date()
	Private dDataAte		:= Date()

	Private lFaturaPed		:= .T. //Declara a variável como private para alteração em tempo de execução
	Private lCentered		:= .T.
	Private lFocSel			:= .T.
	Private lHasButton		:= .T.
	Private lHtml			:= .T.
	Private lNoButton		:= .T.
	Private lPassword		:= .T.
	Private lPicturePiority	:= .T.
	Private lPixel			:= .T.
	Private lReadOnly		:= .T.
	Private lTransparent	:= .T.
	Private l528Auto		:= .F.

	Private nTamFilial		:= TamSX3("C5_FILIAL")[1]//Uso o tamanho da filial de qualquer tabela padrão
	Private nAt				:= 1
	Private nPsIdImp		:= 0

	Private oBtnFiltrar		:= Nil
	Private oDialog			:= Nil
	Private oFiltro			:= Nil
	Private oGetDadUQD		:= Nil
	Private oGetDadUQE		:= Nil
	Private oGetDadUQB		:= Nil
	Private oGetDadUQC		:= Nil	
	Private oGDadUQG		:= Nil
	Private oGDadUQH		:= Nil
	Private oGDadUQI		:= Nil
	Private oGDadUQB		:= Nil
	Private oGDadUQC		:= Nil

	Private oCbTipoArq		:= Nil
	Private oCbStatus		:= Nil
	Private oGClienteDe		:= Nil
	Private oGClienteAte	:= Nil
	Private oGFornecDe		:= Nil
	Private oGFornecAte		:= Nil
	Private oGForDe			:= Nil
	Private oGForAte		:= Nil
	Private oGPedidoDe		:= Nil
	Private oGPedidoAte		:= Nil
	Private oGNFDe			:= Nil
	Private oGNFAte			:= Nil
	Private oGDataDe		:= Nil
	Private oGDataAte		:= Nil
	Private oGDocDeUQD		:= Nil
	Private oGDocAteUQD		:= Nil
	Private oGDocDeUQB		:= Nil
	Private oGDocAteUQB		:= Nil	
	Private oGDocDeUQG		:= Nil
	Private oGDocAteUQG		:= Nil
	Private oGNTitDe		:= Nil
	Private oGNTitAte		:= Nil
	Private oGLoteDe		:= Nil
	Private oGLoteAte		:= Nil
	Private oGFilCTE		:= Nil
	Private oGFilCTRB		:= Nil
	Private oSTipoArq		:= Nil
	Private oSStatus		:= Nil

	Private oSize			:= Nil

	Default lAuto			:= .F.
	Default lCTECRT			:= .F.
	Default lCTRB			:= .F.

	l528Auto := lAuto

	If cRecPag == "R" .OR. cRecPag == "C"
		fAtuSX1(cPerg)

		// Inicializa as variáveis publicas de pergunta.
		Pergunte(cPerg, .F.)

		lFaturaPed := .T. //MV_PAR01 == 2

		//fSetF12(.T.)
	EndIf

	If l528Auto
		fIntegAuto(lCTECRT, lCTRB)
	Else
		// Define os botões da enchoice
		aRotina := fMenuDef()

		SetKey(K_CTRL_M	, { || fSetChek(1)	})
		SetKey(K_CTRL_D	, { || fSetChek(2)	})
		SetKey(K_CTRL_I	, { || fSetChek(3)	})

		// Instancia o objeto para controle das coordenadas da aplicação
		oSize	:= FWDefSize():New( .T. ) // Indica que a tela terá EnchoiceBar

		// Define que os objetos não serão expostos lado a lado
		oSize:lProp 	:= .T.
		oSize:lLateral 	:= .F.

		// Adiciona ao objeto oSize os objetos que irão compor a tela
		oSize:AddObject( "FILTROS"		, 100, 020, .T., .T.  )
		oSize:AddObject( "GETDADOS_UQD"	, 100, 040, .T., .T.  )
		oSize:AddObject( "GETDADOS_UQE"	, 100, 040, .T., .T.  )

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
									/*uParam12*/, /*oWnd*/, lPixel, /*uParam15*/,;
									/*uParam16*/, /*uParam17*/, !lTransparent )

		// Monta o Painel de filtros
		fPainel()

		// Monta a GetDados
		fGetDados()

		// Altera os gets de cliente e fornecedor conforme o tipo de arquivo selecionado
		fChgTpArq()

		// Define EnchoiceBar
		bEnchoice 	:= {|| 	EnchoiceBar( oDialog, bOk,	bCancel, .F., @aRotina, /*nRecno*/,;
							/*cAlias*/, .F., .F., .F., .F., .F., ) }


		// Ativa a Dialog para visualização de log de registros
		oDialog:Activate( 	/*uParam1*/, /*uParam2*/, /*uParam3*/, lCentered,;
							/*bValid*/,/*uParam6*/, bEnchoice, /*uParam8*/, /*uParam9*/	)

		SetKey(K_CTRL_M	, Nil)
		SetKey(K_CTRL_D	, Nil)
		SetKey(K_CTRL_I	, Nil)

	EndIf

	If cRecPag == "R"
		fSetF12(.F.)
	EndIf

	fAltFilial(cFilBkp)

	RestArea(aArea)

Return

/*/{Protheus.doc} fMenuDef
Define as funcionalidade disponíveis para o usuário.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fMenuDef()

	Local aRotina	:= {}

	Local cDescBtn1	:= IIf(cRecPag == "R", CAT528009, CAT528057) // #"Pedido de Venda" #"Lançamento Contábil"
	Local cDescBtn2	:= IIf(cRecPag == "R", CAT528010, CAT528058) // #"Nota Fiscal" #"Contas a Pagar"

	If !FwIsInCallStack("U_PRT0528C")
		aAdd( aRotina, { "", {|| U_PRT0527()		}, "Importação CTE/CRT"	} )	// #"Importação"
	Else	
		aAdd( aRotina, { "", {|| U_fProcCF()		}, "Importação Carta Frete"	} )	// #"Importação carta frete "
	EndIf	
	aAdd( aRotina, { "", {|| fIntegra()		}, CAT528006	} )	// #"Processar"
	aAdd( aRotina, { "", {|| fLegenda() 	}, CAT528007	} )	// #"Legenda"
	aAdd( aRotina, { "", {|| fDetalhes() 	}, CAT528008	} )	// #"Detalhes"
	If !FwIsInCallStack("U_PRT0528C")
		aAdd( aRotina, { "", {|| fFuncBtn1() 	}, cDescBtn1 	} )
	EndIf	
	aAdd( aRotina, { "", {|| fFuncBtn2() 	}, cDescBtn2	} )
	aAdd( aRotina, { "", {|| fExcluir() 	}, CAT528012	} )	// #"Excluir"
	aAdd( aRotina, { "", {|| fImprimir() 	}, CAT528013	} )	// #"Imprimir"
	aAdd( aRotina, { "", {|| fSetChek(1) 	}, CAT528014	} )	// #"Marcar todos"
	aAdd( aRotina, { "", {|| fSetChek(2) 	}, CAT528015	} )	// #"Desmarcar todos"
	aAdd( aRotina, { "", {|| fSetChek(3) 	}, CAT528016	} )	// #"Inverter seleção"
	aAdd( aRotina, { "", {|| U_PRT0533(Nil, Nil, "FAT","INT" ) }, "Logs Import/Processamento"	} )	// #"Inverter seleção"

Return AClone( aRotina )

/*/{Protheus.doc} fPainel
Cria o painel de filtros dos documentos.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fPainel()

	Local aTipoArq		:= {CAT528003, CAT528017,"CTE/CF"} //#"CTE/CRT" - #"CTRB"
	Local aCbStatus		:= {CAT528005, CAT528019, CAT528020, CAT528021, CAT528022} // "Todos", "Importado", "Protheus", "Erro", "Cancelado"

	Local bFiltrar		:= { | | fFiltrar() }
	Local bSTipoArq		:= { | | CAT528023 }	// "Arquivo"
	Local bSGTpoArq		:= { |u| if(PCount() > 0, cTipoArq := u, cTipoArq) }
	Local bSStatus		:= { | | CAT528025 }	// "Status"
	Local bCbStatus		:= { |u| if(PCount() > 0, cCbStatus := u, cCbStatus) }

	Local nRow			:= oSize:GetDimension( "FILTROS", "LININI" )
	Local nCol			:= oSize:GetDimension( "FILTROS", "COLINI" )
	Local nWidth		:= oSize:GetDimension( "FILTROS", "XSIZE"  )
	Local nHeight		:= oSize:GetDimension( "FILTROS", "YSIZE"  )

	Local nRowElem		:= 002
	Local nColRight		:= oSize:GetDimension( "FILTROS", "COLEND"  ) - 55

	Local nLblPos		:= 1

	// Cria o painel de filtros
	oFiltro 	:= TPanel():New( 	nRow, nCol, /*cTexto*/, oDialog, /*oFont*/, lCentered,;
									/*uParam7*/, /*nClrText*/, /*nClrBack*/, nWidth, nHeight,;
									/*lLowered*/, /*lRaised*/ )

	// Log a ser exibido
	oSTipoArq	:= TSay():New( 	nRowElem, 002, bSTipoArq, oFiltro, /*cPicture*/, /*oFont*/,;
								/*uParam7*/, /*uParam8*/, /*uParam9*/, lPixel, /*nClrText*/,;
								/*nCrlBack*/, 070, 010, /*uParam15*/, /*uParam16*/, /*uParam17*/,;
								/*uParam18*/, /*uParam19*/, !lHtml, /*nTxtAlgHor*/,  /*nTxtAlgVer*/ )

	oCbTipoArq 	:= TComboBox():New(	nRowElem + 8, 002, bSGTpoArq, aTipoArq, 070, 013, oFiltro,;
									/*uParam8*/, {|| fChgTpArq()}, /*bValid*/, /*nClrText*/,;
									/*nClrBack*/, lPixel, /*oFont*/, /*uParam15*/, /*uParam16*/, ;
									/*bWhen*/, /*uParam18*/, /*uParam19*/, /*uParam20*/, /*uParam21*/, ;
									cTipoArq, /*cLabelText*/, /*nLabelPos*/, /*nLabelFont*/,	/*nLabelColor*/	)

	IIf(!Empty(cRecPag), oCbTipoArq:Disable(), Nil)

	// Data De
	oGDataDe	:= TGet():New( 	nRowElem, 077,  {|u| if( Pcount() > 0, dDataDe := u, dDataDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528026, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; 	// "Data importação de"
								!lPicturePiority, lFocSel )

	// Data Ate
	oGDataAte	:= TGet():New( 	nRowElem, 152, {|u| if( Pcount() > 0, dDataAte := u, dDataAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*uParam23*/, "dDataAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528027, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Data importação até"
								!lPicturePiority, lFocSel )

	// UQD -> Documento De
	oGDocDeUQD	:= TGet():New( 	nRowElem, 227,  {|u| if( Pcount() > 0, cDocDe := u, cDocDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "UQD", "cDocDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528028, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento De"
								!lPicturePiority, lFocSel )

	// UQD -> Documento Ate
	oGDocAteUQD	:= TGet():New( 	nRowElem, 302, {|u| if( Pcount() > 0, cDocAte := u, cDocAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "UQD", "cDocAteUQD",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528029, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento Ate"
								!lPicturePiority, lFocSel )

	// UQG -> Documento De
	oGDocDeUQG	:= TGet():New( 	nRowElem, 227,  {|u| if( Pcount() > 0, cDocDeUQG := u, cDocDeUQG)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "UQG", "cDocDeUQG",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528028, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento De"
								!lPicturePiority, lFocSel )

	// UQG -> Documento Ate
	oGDocAteUQG	:= TGet():New( 	nRowElem, 302, {|u| if( Pcount() > 0, cDocAteUQG := u, cDocAteUQG)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "UQG", "cDocAteUQG",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528029, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento ate"
								!lPicturePiority, lFocSel )

	// UQB -> Documento De
	oGDocDeUQB	:= TGet():New( 	nRowElem, 227,  {|u| if( Pcount() > 0, cDocDeUQB := u, cDocDeUQB)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "UQB", "cDocDeUQB",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528028, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento De"
								!lPicturePiority, lFocSel )

	// UQC -> Documento Ate
	oGDocAteUQB	:= TGet():New( 	nRowElem, 302, {|u| if( Pcount() > 0, cDocAteUQB := u, cDocAteUQB)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "UQB", "cDocAteUQB",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528029, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Documento Ate"
								!lPicturePiority, lFocSel )
	
	// Cliente De
	oGClienteDe		:= TGet():New( 	nRowElem, 377,  {|u| if( Pcount() > 0, cClienteDe := u, cClienteDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SA1COD", "cClienteDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528030, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Cliente de"
								!lPicturePiority, lFocSel )

	// Cliente Ate
	oGClienteAte	:= TGet():New( 	nRowElem, 452, {|u| if( Pcount() > 0, cClienteAte := u, cClienteAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SA1COD", "cClienteAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528031, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Cliente ate"
								!lPicturePiority, lFocSel )

		// Fornecedor De
	oGForDe		:= TGet():New( 	nRowElem, 377,  {|u| if( Pcount() > 0, cFornecedorDe := u, cFornecedorDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SA2", "cFornecedorDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								"Fornecedor de?", nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Cliente de"
								!lPicturePiority, lFocSel )

	// Fornecedor Ate
	oGForAte	:= TGet():New( 	nRowElem, 452, {|u| if( Pcount() > 0, cFornecedorAte := u, cFornecedorAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SA2", "cFornecedorAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								"Fornecedor Ate?", nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;				// "Cliente ate"
								!lPicturePiority, lFocSel )

	// Transportadora De
	oGFornecDe		:= TGet():New( 	nRowElem, 377,  {|u| if( Pcount() > 0, cFornecDe := u, cFornecDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SA2COD", "cFornecDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528032, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;		// "Transportadora de"
								!lPicturePiority, lFocSel )

	// Transportadora Ate
	oGFornecAte	:= TGet():New( 	nRowElem, 452, {|u| if( Pcount() > 0, cFornecAte := u, cFornecAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SA2COD", "cFornecAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528033, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;	// "Transportadora ate"
								!lPicturePiority, lFocSel )

	// Status
	oSStatus	:= TSay():New( 	nRowElem, 527, bSStatus, oFiltro, /*cPicture*/, /*oFont*/,;
								/*uParam7*/, /*uParam8*/, /*uParam9*/, lPixel, /*nClrText*/,;
								/*nCrlBack*/, 070, 010, /*uParam15*/, /*uParam16*/, /*uParam17*/,;
								/*uParam18*/, /*uParam19*/, !lHtml, /*nTxtAlgHor*/,  /*nTxtAlgVer*/ )

	oCbStatus 	:= TComboBox():New(	nRowElem + 8, 527, bCbStatus, aCbStatus, 070, 013, oFiltro,;
									/*uParam8*/, /*bChange*/, /*bValid*/, /*nClrText*/,;
									/*nClrBack*/, lPixel, /*oFont*/, /*uParam15*/, /*uParam16*/, ;
									/*bWhen*/, /*uParam18*/, /*uParam19*/, /*uParam20*/, /*uParam21*/, ;
									cCbStatus, /*cLabelText*/, /*nLabelPos*/, /*nLabelFont*/,	/*nLabelColor*/	)

	//-- Segunda linha
	nRowElem += 25

	// Pedido De
	oGPedidoDe	:= TGet():New( 	nRowElem, 002,  {|u| if( Pcount() > 0, cPedidoDe := u, cPedidoDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SC5", "cPedidoDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528034, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Pedido De"
								!lPicturePiority, lFocSel )

	// Pedido Ate
	oGPedidoAte	:= TGet():New( 	nRowElem, 077, {|u| if( Pcount() > 0, cPedidoAte := u, cPedidoAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SC5", "cPedidoAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528035, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Pedido ate"
								!lPicturePiority, lFocSel )

	// Nota Fiscal De
	oGNFDe	:= TGet():New( 	nRowElem, 152,  {|u| if( Pcount() > 0, cGNFDe := u, cGNFDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/,/*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/,/*bChange*/, !lReadOnly, !lPassword, "SF2", "cGNFDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528036, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Nota Fiscal de"
								!lPicturePiority, lFocSel )

	// Nota Fiscal Ate
	oGNFAte	:= TGet():New( 	nRowElem, 227, {|u| if( Pcount() > 0, cGNFAte := u, cGNFAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SF2", "cGNFAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528037, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Nota Fiscal ate"
								!lPicturePiority, lFocSel )

	// Filiais CTE
	oGFilCTE := TGet():New( nRowElem, 302, {|u| if( Pcount() > 0, cGFilCTE := u, cGFilCTE)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/ {|| fVldFilial()}, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/ "StaticCall(PRT0528,fOpcFiliais,'oGFilCTE'), StaticCall(PRT0528,fSetF12,.T.)", "cGFilCTE",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528038, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Filiais"
								!lPicturePiority, lFocSel )

	//Segunda Linha CTRB
	// Número de Título De
	oGNTitDe:= TGet():New( 	nRowElem, 002, {|u| if( Pcount() > 0, cGNTitDe := u, cGNTitDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SE2NUM"/*cF3*/, "cGNTitDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528039, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; //"Título de"
								!lPicturePiority, lFocSel )

	// Número de Título Até
	oGNTitAte:= TGet():New(	nRowElem, 077, {|u| if( Pcount() > 0, cGNTitAte := u, cGNTitAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, "SE2NUM"/*cF3*/, "cGNTitAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528040, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; //"Título até"
								!lPicturePiority, lFocSel )

	// Código de Lote De
	oGLoteDe:= TGet():New( 	nRowElem, 152, {|u| if( Pcount() > 0, cGLoteDe := u, cGLoteDe)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/, "cGLoteDe",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528041, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; //"Lote de"
								!lPicturePiority, lFocSel )

	// Código de Lote Até
	oGLoteAte	:= TGet():New( 	nRowElem, 227, {|u| if( Pcount() > 0, cGLoteAte := u, cGLoteAte)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/, "cGLoteAte",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528042, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,; //"Lote até"
								!lPicturePiority, lFocSel )

	// Filiais CTRB
	oGFilCTRB := TGet():New( nRowElem, 302, {|u| if( Pcount() > 0, cGFilCTRB := u, cGFilCTRB)}, oFiltro, 070, 011,;
								/*cPicture*/, /*bValid*/ {|| fVldFilial()}, /*nClrFore*/, /*nClrBack*/, /*oFont*/, /*uParam12*/,;
								/*uParam13*/, lPixel, /*uParam15*/, /*uParam16*/, /*bWhen*/, /*uParam18*/,;
								/*uParam19*/, /*bChange*/, !lReadOnly, !lPassword, /*cF3*/ "StaticCall(PRT0528,fOpcFiliais,'oGFilCTRB')", "cGFilCTRB",;
								/*uParam25*/, /*uParam26*/, /*uParam27*/, lHasButton, !lNoButton, /*uParam30*/,;
								CAT528038, nLblPos, /*oLabelFont*/, /*nLabelColor*/, /*cPlaceHold*/,;					// "Filiais"
								!lPicturePiority, lFocSel )

	// Botão Filtrar
	oBtnFiltrar	:= TButton():New(	008, nColRight, CAT528043, oFiltro, bFiltrar, 050, 015,;							// "Pesquisar"
									/*uParam8*/, /*oFont*/, /*uParam10*/, lPixel, /*uParam12*/, /*uParam13*/,;
									/*uParam14*/, /*bWhen*/, /*uParam16*/, /*uParam17*/	)

Return

/*/{Protheus.doc} fGetDados
Cria a GetDados de acordo com a definição dos filtros.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fGetDados()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		U_PRT0544( NGETDADOS )
	ElseIf cTipoArq == CTRB
		U_PRT0545( NGETDADOS )
	ElseIf cTipoArq == CTE_CF	
		U_PRT0558( NGETDADOS )
	EndIf

Return

/*/{Protheus.doc} fIntegra
Realiza integração do documento conforme o tipo de arquivo escolhido.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fIntegra()

	Local cTextoLog	:= ""

	Local nHandle	:= 0

	If l528Auto .Or. MsgYesNo(CAT528044, cCadastro)//"Deseja realmente processar os arquivos selecionados?"
		If l528Auto
			// Abre arquivo de Log
			StaticCall(PRT0527, fLogSched, 3, @nHandle)
		EndIf

		// Verifica qual tipo de arquivo foi selecionado para manutenção.
		If cTipoArq == CTE_CRT

			If !l528Auto
				// Define a posição do campo IDIMP
				nPsIdImp := GDFieldPos("UQD_IDIMP", aHeaderUQD)

				// Verifica se a GetDados não está vazia
				If Len(oGetDadUQD:aCols) == 1 .And. Empty(oGetDadUQD:aCols[nAt][nPsIdImp])
					MsgAlert( CAT528045, cCadastro )	//"Nenhum registro foi pesquisado para ser integrado."
				Else
					U_PRT0544( NINTEGRAR, CAT528018 $ cCbAgrupa )	//"Sim"
				EndIf

				fSetF12(.T.)
			Else
				If !Empty(aCoUQDAuto)
					cTextoLog := CAT528046 ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Processando integracao CTE/CRT"
					U_PRT0544( NINTEGRAR, CAT528018 $ cCbAgrupa )	//"Sim"
				Else
					cTextoLog := CAT528047 ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Nenhum registro CTE/CRT encontrado para integracao"
				EndIf
			EndIf

		ElseIf cTipoArq == CTRB

			If !l528Auto
				// Define a posição do campo IDIMP
				nPsIdImp := GDFieldPos("UQG_IDIMP", aHeaderUQG)

				// Verifica se a GetDados está vazia
				If Len(oGDadUQG:aCols) == 1 .And. Empty(oGDadUQG:aCols[nAt][nPsIdImp])
					MsgAlert( CAT528045, cCadastro ) //"Nenhum registro foi pesquisado para ser integrado."
				Else
					U_PRT0545( NINTEGRAR )
				EndIf
			Else
				If !Empty(aCoUQGAuto)
					cTextoLog := CAT528048 ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Processando integracao CTRB"
					U_PRT0545( NINTEGRAR )
				Else
					cTextoLog := CAT528049 ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Nenhum registro CTRB encontrado para integracao"
				EndIf
			EndIf
		ElseIf cTipoArq == CTE_CF
			If !l528Auto
				// Define a posição do campo IDIMP
				nPsIdImp := GDFieldPos("UQB_IDIMP", aHeaderUQB)

				// Verifica se a GetDados não está vazia
				If Len(oGetDadUQB:aCols) == 1 .And. Empty(oGetDadUQB:aCols[nAt][nPsIdImp])
					MsgAlert( CAT528045, cCadastro )	//"Nenhum registro foi pesquisado para ser integrado."
				Else
					U_PRT0558( NINTEGRAR, CAT528018 $ cCbAgrupa )	//"Sim"
				EndIf

				fSetF12(.T.)
			Else
				If !Empty(aCoUQDAuto)
					cTextoLog := "Schedule: PRT0527 - Processando integracao CARTA FRETE" ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Processando integracao CTE/CRT"
					U_PRT0544( NINTEGRAR, CAT528018 $ cCbAgrupa )	//"Sim"
				Else
					cTextoLog := "Schedule: PRT0527 - Nenhum registro CARTA FRETE encontrado para integracao" ; ConOut(cTextoLog) ; IIf(nHandle > 0, StaticCall(PRT0527, fLogSched, 2, nHandle, cTextoLog), Nil) //"Schedule: PRT0527 - Nenhum registro CTE/CRT encontrado para integracao"
				EndIf
			EndIf	
		
		EndIf

		If l528Auto .And. nHandle > 0
			// Fecha arquivo de Log
			StaticCall(PRT0527, fLogSched, 4, nHandle)
		EndIf
	EndIf

Return

/*/{Protheus.doc} fFiltrar
Realiza a filtragem dos dados de acordo com os parâmetros determinados pelo usuário.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fFiltrar()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		U_PRT0544( NFILTRAR )
	ElseIf cTipoArq == CTRB
		U_PRT0545( NFILTRAR )
	ElseIf cTipoArq == CTE_CF
		U_PRT0558( NFILTRAR )
	EndIf

Return

/*/{Protheus.doc} fExcluir
Realiza a excluir dos arquivos selecionados.
@author Paulo Carvalho
@since 29/01/2019
@version 1.01
@type Static Function
/*/
Static Function fExcluir()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		U_PRT0544( NEXCLUIR )
	ElseIf cTipoArq == CTRB
		U_PRT0545( NEXCLUIR )
	ElseIf cTipoArq == CTE_CF
		U_PRT0558( NEXCLUIR )
	EndIf

Return

/*/{Protheus.doc} fEstornar
Realiza o estorno dos arquivos selecionados.
@author Paulo Carvalho
@since 29/01/2019
@version 1.01
@type Static Function
/*/
Static Function fEstornar()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		U_PRT0544( NESTORNAR, oGetDadUQD:nAt )
	ElseIf cTipoArq == CTRB
		U_PRT0545( NESTORNAR, oGDadUQG:nAt )
	ElseIf cTipoArq == CTE_CF
		U_PRT0558( NESTORNAR, oGDadUQB:nAt )
	EndIf

Return

/*/{Protheus.doc} fSetChek
Realiza integração do documento conforme o tipo de arquivo escolhido.
@author Paulo Carvalho
@since 28/12/2018
@version 1.01
@type Static Function
/*/
Static Function fSetChek(nOpcao)

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		U_PRT0544( NCHECK, nOpcao )
	ElseIf cTipoArq == CTRB
		U_PRT0545( NCHECK, Nil, nOpcao )
	ElseIf cTipoArq == CTE_CF
		U_PRT0558( NCHECK, nOpcao )
	EndIf

Return

/*/{Protheus.doc} fLegenda
Exibe as legendas possíveis ao usuário.
@author Paulo Carvalho
@since 02/01/2019
@version 1.01
@type Static Function
/*/
Static Function fLegenda()

	// Instancia browse para Legenda
	Local oLegenda	:= FWLegend():New()

	oLegenda:Add( "", "BR_AZUL"		, CAT528050	)	// "Arquivo importado."
	oLegenda:Add( "", "BR_VERDE"	, CAT528051 )	// "Arquivo integrado ao Protheus."
	oLegenda:Add( "", "BR_VIOLETA"	, CAT528071 )	// "Arquivo reprocessado."
	oLegenda:Add( "", "BR_VERMELHO"	, CAT528052 )	// "Arquivo com erros no processamento."
	oLegenda:Add( "", "BR_PRETO"	, CAT528053 )	// "Arquivo cancelado."
	oLegenda:Add( "", "CATTMS_INC"	, CAT528054	)	// "Arquivo para inclusão."
	oLegenda:Add( "", "CATTMS_REP"	, CAT528055 )	// "Arquivo para reprocessamento."
	oLegenda:Add( "", "BR_CANCEL"	, CAT528056	)	// "Arquivo para cancelamento."

	oLegenda:Activate()
	oLegenda:View()
	oLegenda:DeActivate()

Return

/*/{Protheus.doc} fChgTpArq
Função executada ao alterar o tipo de arquivo nos filtros.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fChgTpArq()

	cCbAgrupa	:= CAT528004	// #"Não"
	cCbStatus	:= CAT528005	// #"Todos"
	cClienteDe	:= Space( TamSX3("A1_COD")[1] 		)
	cClienteAte	:= Space( TamSX3("A1_COD")[1] 		)
	cDocDe		:= Space( TamSX3("UQD_NUMERO")[1]	)
	cDocAte		:= Space( TamSX3("UQD_NUMERO")[1]	)
	cDocDeUQB		:= Space( TamSX3("UQB_NUMERO")[1]	)
	cDocAteUQB		:= Space( TamSX3("UQB_NUMERO")[1]	)
	cDocDeUQG	:= Space( TamSX3("UQG_REF")[1] 		)
	cDocAteUQG	:= Space( TamSX3("UQG_REF")[1] 		)
	cFornecDe	:= Space( TamSX3("A2_COD")[1] 		)
	cFornecAte	:= Space( TamSX3("A2_COD")[1] 		)
	cFornDe		:= Space( TamSX3("A2_COD")[1] 		)
	cFornAte	:= Space( TamSX3("A2_COD")[1] 		)
	cPedidoDe	:= Space( TamSX3("C5_NUM")[1] 		)
	cPedidoAte	:= Space( TamSX3("C5_NUM")[1] 		)
	cPedComDe	:= Space( TamSX3("C7_NUM")[1] 		)
	cPedComAte	:= Space( TamSX3("C7_NUM")[1] 		)
	cGNFDe		:= Space( TamSX3("F2_DOC")[1] 		)
	cGNFAte		:= Space( TamSX3("F2_DOC")[1] 		)
	cGNTitDe	:= Space( TamSX3("UQI_NUM")[1] 		)
	cGNTitAte	:= Space( TamSX3("UQI_NUM")[1] 		)
	cGLoteDe	:= Space( TamSX3("UQI_LOTE")[1] 	)
	cGLoteAte	:= Space( TamSX3("UQI_LOTE")[1] 	)
	cGFilCTE	:= Space( 200 )
	cGFilCTRB	:= Space( 200 )

	dDataDe		:= Date()
	dDataAte	:= Date()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		cCadastro := cCadasCTE

		oGDocDeUQD:Show()
		oGDocAteUQD:Show()
		oGClienteDe:Show()
		oGClienteAte:Show()
		oGetDadUQD:Show()
		oGetDadUQE:Show()
		oGPedidoDe:Show()
		oGPedidoAte:Show()
		oGNFDe:Show()
		oGNFAte:Show()
		oGFilCTE:Show()

		If(Type("oGDadUQG")=="O",oGDadUQG:Hide(), Nil)
		If(Type("oGDadUQH")=="O",oGDadUQH:Hide(), Nil)
		If(Type("oGDadUQI")=="O",oGDadUQI:Hide(), Nil)

		oGDocDeUQG:Hide()
		oGDocAteUQG:Hide()
		oGForDe:Hide()
		oGForAte:Hide()
		oGFornecDe:Hide()
		oGFornecAte:Hide()
		oGNTitDe:Hide()
		oGNTitAte:Hide()
		oGLoteDe:Hide()
		oGLoteAte:Hide()
		oGFilCTRB:Hide()

		U_PRT0544(NGETDADOS)
	ElseIf cTipoArq == CTRB
		cCadastro := cCadasCTRB

		oGDocDeUQG:Show()
		oGDocAteUQG:Show()
		oGFornecDe:Show()
		oGFornecAte:Show()
		oGNTitDe:Show()
		oGNTitAte:Show()
		oGLoteDe:Show()
		oGLoteAte:Show()
		oGFilCTRB:Show()

		oGDocAteUQD:Hide()
		oGClienteDe:Hide()
		oGClienteAte:Hide()
		oGForDe:Hide()
		oGForAte:Hide()
		oGPedidoDe:Hide()
		oGPedidoAte:Hide()
		oGNFDe:Hide()
		oGNFAte:Hide()
		oGFilCTE:Hide()

		U_PRT0545(NGETDADOS)
	ElseIf cTipoArq == CTE_CF
		cCadastro := cCadasCTE

		oGDocDeUQB:Show()
		oGDocAteUQB:Show()
		oGForDe:Show()
		oGForAte:Show()
		oGetDadUQB:Show()
		oGetDadUQC:Show()
		

		If(Type("oGDadUQG")=="O",oGDadUQG:Hide(), Nil)
		If(Type("oGDadUQH")=="O",oGDadUQH:Hide(), Nil)
		If(Type("oGDadUQI")=="O",oGDadUQI:Hide(), Nil)
		If(Type("oGDadUQD")=="O",oGDadUQG:Hide(), Nil)
		If(Type("oGDadUQE")=="O",oGDadUQH:Hide(), Nil)
		//If(Type("oGDadUQI")=="O",oGDadUQI:Hide(), Nil)
		oGFilCTE:Hide()
		oGPedidoDe:Hide()
		oGPedidoAte:Hide()
		oGNFDe:Hide()
		oGNFAte:Hide()
		oGClienteDe:Hide()
		oGClienteAte:Hide()
		oGDocDeUQD:Hide()
		oGDocAteUQD:Hide()
		oGDocAteUQE:Hide()
		oGDocDeUQG:Hide()
		oGDocAteUQG:Hide()
		oGFornecDe:Hide()
		oGFornecAte:Hide()
		oGNTitDe:Hide()
		oGNTitAte:Hide()
		oGLoteDe:Hide()
		oGLoteAte:Hide()
		oGFilCTRB:Hide()

		U_PRT0558(NGETDADOS)
	EndIf

Return(Nil)

/*/{Protheus.doc} fFuncBtn1
Função executada ao selecionar o botão 1 em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fFuncBtn1()

	Do Case
		Case (cTipoArq == CTE_CRT) ; fPedVenda()
		Case (cTipoArq == CTRB   ) ; fLancCtb()
	EndCase

Return(Nil)

/*/{Protheus.doc} fFuncBtn2
Função executada ao selecionar o botão 2 em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fFuncBtn2()

	Do Case
		Case (cTipoArq == CTE_CRT) ; fNotaFiscal()
		Case (cTipoArq == CTRB   ) ; fContPagar()
		Case (cTipoArq == CTE_CF   ) ; fContPagar()
	EndCase

Return(Nil)

/*/{Protheus.doc} fDetalhes
Função executada ao selecionar a opção Detalhes em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fDetalhes()

	// Verifica o tipo de arquivo.
	If cTipoArq == CTE_CRT
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQD_IDIMP", aHeaderUQD)

		// Verifica se a GetDados está vázia.
		If Len(oGetDadUQD:aCols) == 1 .And. Empty(oGetDadUQD:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528059, cCadastro )//"Não existem registros para serem visualizados em detalhe."
		Else
			U_PRT0546()
		EndIf
	ElseIf cTipoArq == CTRB
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQG_IDIMP", aHeaderUQG)

		// Verifica se a GetDados está vázia.
		If Len(oGDadUQG:aCols) == 1 .And. Empty(oGDadUQG:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528059, cCadastro ) //"Não existem registros para serem visualizados em detalhe."
		Else
			U_PRT0546()
		EndIf
	ElseIf cTipoArq == CTE_CF
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQB_IDIMP", aHeaderUQB)

		// Verifica se a GetDados está vázia.
		If Len(oGetDadUQB:aCols) == 1 .And. Empty(oGetDadUQB:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528059, cCadastro )//"Não existem registros para serem visualizados em detalhe."
		Else
			U_PRT0546()
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fPedVenda
Função executada ao selecionar a opção Pedido de Venda em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fPedVenda()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQD_IDIMP", aHeaderUQD)

		// Verifica se a GetDados não está vazia
		If Len(oGetDadUQD:aCols) == 1 .And. Empty(oGetDadUQD:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528060, cCadastro )//"Nenhum registro pesquisado para visualização do pedido de venda."
		Else
			U_PRT0544( NPEDVENDA )
		EndIf
	Else
		MsgAlert( CAT528061, cCadastro )//"Este tipo de arquivo não possui pedido de venda."
	EndIf

Return(Nil)

/*/{Protheus.doc} fNotaFiscal
Função executada ao selecionar a opção Nota Fiscal em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fNotaFiscal()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQD_IDIMP", aHeaderUQD)

		// Valida se a GetDados não está vázia.
		If Len(oGetDadUQD:aCols) == 1 .And. Empty(oGetDadUQD:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528062, cCadastro )//"Nenhum registro pesquisado para visualização de nota fiscal."
		Else
			U_PRT0544( NNOTAFISCAL )
		EndIf
	Else
		MsgAlert( CAT528063, cCadastro )//"O tipo de arquivo selecionado não possui nota fiscal."
	EndIf

Return(Nil)

/*/{Protheus.doc} fImprimir
Função executada ao selecionar a opção Imprimir em Outras Ações.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@type function
/*/
Static Function fImprimir()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQD_IDIMP", aHeaderUQD)

		If Len(oGetDadUQD:aCols) == 1 .And. Empty(oGetDadUQD:aCols[nAt][nPsIdImp])
			MsgAlert(CAT528064, cCadastro) //"Nenhum arquivo pesquisado para impressão."
		Else
			U_PRT0544( NIMPRIMIR )
		EndIf
	ElseIf cTipoArq == CTRB
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQG_IDIMP", aHeaderUQG)

		If Len(oGDadUQG:aCols) == 1 .And. Empty(oGDadUQG:aCols[nAt][nPsIdImp])
			MsgAlert(CAT528064, cCadastro) //"Nenhum arquivo pesquisado para impressão."
		Else
			U_PRT0545( NIMPRIMIR )
		EndIf
	ElseIf cTipoArq == CTE_CF
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQB_IDIMP", aHeaderUQB)

		If Len(oGetDadUQB:aCols) == 1 .And. Empty(oGetDadUQB:aCols[nAt][nPsIdImp])
			MsgAlert(CAT528064, cCadastro) //"Nenhum arquivo pesquisado para impressão."
		Else
			U_PRT0558( NIMPRIMIR )
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} fLancCtb
Função executada ao selecionar a opção lançamentos contábeis em Outras Ações.
@author icaro-laudade
@since 18/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fLancCtb()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		MsgAlert( CAT528065, cCadastro )//"O tipo de arquivo selecionado não possui lançamentos contábeis."
	ElseIf cTipoArq == CTRB
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQG_IDIMP", aHeaderUQG)

		// Valida se a GetDados não está vázia.
		If Len(oGDadUQG:aCols) == 1 .And. Empty(oGDadUQG:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528066, cCadastro )//"Nenhum registro pesquisado para visualização de lançamentos contábeis."
		Else
			U_PRT0545( NLANCCTB )
		EndIf
	EndIf

Return

/*/{Protheus.doc} fContPagar
Função executada ao selecionar a opção conta a pagar em Outras Ações.
@author icaro-laudade
@since 18/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fContPagar()

	// Verifica qual tipo de arquivo foi selecionado para manutenção.
	If cTipoArq == CTE_CRT
		MsgAlert( CAT528067, cCadastro )//"O tipo de arquivo selecionado não possui contas a pagar."
	ElseIf cTipoArq == CTRB
		// Define a posição do campo IDIMP
		nPsIdImp := GDFieldPos("UQG_IDIMP", aHeaderUQG)

		// Valida se a GetDados não está vázia.
		If Len(oGDadUQG:aCols) == 1 .And. Empty(oGDadUQG:aCols[nAt][nPsIdImp])
			MsgAlert( CAT528068, cCadastro )//"Nenhum registro pesquisado para visualização de contas a pagar."
		Else
			U_PRT0545( NCONTAPAGAR )
		EndIf
	ElseIf cTipoArq == CTE_CF
		// Valida se a GetDados não está vázia.
		//If Len(oGDadUQB:aCols) >= 1 
			U_PRT0558( NCONTAPAGAR )
		//else
	//		MsgAlert( CAT528068, cCadastro )	
	//	EndIf		
	EndIf

Return(Nil)

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
	Local cTitulo		:= CAT528038 //"Filiais"
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
		cCadastro := AllTrim(cCadastro) + " - " + CAT528038//"Filiais"

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
	Local nI		:= 0
    Local nPosFil   := 0

	If !l528Auto
		aUsrAux := AClone(FWUsrEmp( cCodUsr ))
	EndIf

	For nI := 1 To Len(aSM0)
		If aSM0[nI][1] == SM0->M0_CODIGO
			//Agora procura pela empresa + filial nos acessos
			nPosFil := AScan(aUsrAux, {|x| x == aSM0[nI,1] + aSM0[nI,2] })

			If l528Auto .Or. nPosFil > 0 .Or. "@" $ aUsrAux[1]
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

	If cTipoArq == CTE_CRT
		cFilSel := cGFilCTE
	ElseIf cTipoArq == CTRB
		cFilSel := cGFilCTRB
	EndIf

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

	If cTipoArq == CTE_CRT
		cFilSel := cGFilCTE
	ElseIf cTipoArq == CTRB
		cFilSel := cGFilCTRB
	EndIf

	cFilSel := StrTran(cFilSel, "*", "")

	If !Empty(cFilSel)
		While !Empty(cFilSel)
			Aadd(aFilSel, Left(cFilSel, nTamFilial))

			cFilSel := SubStr(cFilSel, nTamFilial + 1, Len(cFilSel))
		EndDo

		For nI := 1 To Len(aFilSel)
			If !FWFilExist(cEmpAnt, aFilSel[nI])
				lValid := .F.
				MsgAlert( CAT528069 + aFilSel[nI], cCadastro) //"Filial inválida: "
				Exit
			EndIf
		Next nI

		If lValid
			//-- Verifica se o usuário possui acesso às filiais selecionadas
			aFilAcess := fGetFilUser()[1]

			For nI := 1 To Len(aFilSel)
				If AScan(aFilAcess, {|x| aFilSel[nI] $ x}) == 0
					lValid := .F.
					MsgAlert( CAT528070 + aFilSel[nI], cCadastro) //"Usuário sem acesso à filial: "
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

/*/{Protheus.doc} fIntegAuto
Função responsável pelo processamento da Integração automática executada via Schedule.
@author Juliano Fernandes
@since 28/02/2019
@version 1.01
@type Function
/*/
Static Function fIntegAuto(lCTECRT, lCTRB)

	Local aSM0			:= FWLoadSM0()
	Local nI 			:= 0

	Private aCoUQDAuto	:= {}
	Private aCoUQGAuto	:= {}

	//-- Primeiro realiza a integração dos CTEs e CRTs e após isso, integra os CTRBs
	For nI := 1 To 2
		//-- Define o tipo de arquivo a ser integrado
		If nI == 1
			If !lCTECRT
				Loop
			EndIf

			cTipoArq := CTE_CRT
			cGFilCTE := ""

			//-- Preenche a variavel cGFilCTE com todas as filiais.
			AEval(aSM0, {|x| IIf(x[1] == cEmpAnt, cGFilCTE += x[2], Nil)})
		ElseIf nI == 2
			If !lCTRB
				Loop
			EndIf

			cTipoArq := CTRB
			cGFilCTRB := ""

			//-- Preenche a variavel cGFilCTRB com todas as filiais.
			AEval(aSM0, {|x| IIf(x[1] == cEmpAnt, cGFilCTRB += x[2], Nil)})
		EndIf

		//-- Instancia a GetDados
		fGetDados()

		//-- Filtra os dados a serem processados
		fFiltrar()

		//-- Marca todos os registros filtrados
		fSetChek(1) // 1 = Marcar Todos

		//-- Integra os registros
		fIntegra()
	Next nI

Return(Nil)

/*/{Protheus.doc} fAltModulo
Função para retornar o módulo que está sendo utilizado ou alterar para o módulo passado por parâmetro.
@author Juliano Fernandes
@since 11/01/2019
@version 1.0
@param cMod, characters, Nome do módulo
@param nMod, numeric, Número do módulo
@type function
/*/
Static Function fAltModulo(cMod, nMod)

	If Empty(cMod) .And. Empty(nMod) //-- Guarda as informações do módulo atual
		cMod := cModulo
		nMod := nModulo
	Else //-- Altera para o módulo passado por parâmetro
		cModulo := cMod
		nModulo := nMod
	EndIf

Return(Nil)

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

/*/{Protheus.doc} PRT0528R
Chamada do programa PRT0528 do menu do Contas a Receber.
@type function
@version 1.0
@author Juliano Fernandes
@since 16/11/2020
/*/
User Function PRT0528R()

	U_PRT0528()

Return(Nil)

/*/{Protheus.doc} PRT0528P
Chamada do programa PRT0528 do menu do Contas a Pagar.
@type function
@version 1.0
@author Juliano Fernandes
@since 16/11/2020
/*/
User Function PRT0528P()

	U_PRT0528()

Return(Nil)

/*/{Protheus.doc} PRT0528P
Chamada do programa PRT0528 do menu do Carta Frete.
@type function
@version 1.0
@author Reginaldo
@since 27/12/2021
/*/
User Function PRT0528C()
	DbSelectArea("UQB")
	DbSelectArea("UQC")
	
	U_PRT0528()

Return(Nil)


/*/{Protheus.doc} fSetF12
Criação ou remoção do atalho F12.
@type function
@version 12.1.27
@author Juliano Fernandes
@since 01/02/2021
@param lSetF12, logical, Indica se cria ou remove o F12
/*/
Static Function fSetF12(lSetF12)

	If lSetF12
		SetKey(VK_F12,{|a,b| IIf(Pergunte(cPerg, .T., cCadastro), lFaturaPed := MV_PAR01 == 2, Nil)})
	Else
		SetKey(VK_F12,{|| })
	EndIf

Return(Nil)

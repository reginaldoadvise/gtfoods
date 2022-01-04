#Include "Protheus.ch"
#Include "colors.ch"
#Include "CATTMS.ch"

// Define as informa��es sobre o programa
Static NomePrt		:= "PRT0554"
Static VersaoJedi	:= "V1.26"

/*/{Protheus.doc} PRT0554
Imprime a fatura.
@author Paulo Carvalho
@since 05/04/2019
@param cFatura, caracter, Id da fatura a ser impressa.
@version 12.1.17
@type function
/*/
User Function PRT0554(cFatura)

	Local aArea			:= GetArea()
	Local lExecProg		:= .T.

	Private cCadastro	:= NomePrt + CAT554002 + VersaoJedi // " - Relat�rio de Fatura - "
	Private oReport		:= Nil

	Default cFatura		:= ""

	If lExecProg
		// Verifica se relat�rios personalizaveis est� dispon�vel
		If TRepInUse()
			// Verifica se o relat�rio inicia com uma requisi��o espec�fica a imprimir
			If Empty(cFatura)
				//Cria��o do Pergunte
				fAsrPerg("PRT0518")

				// Inicializa as vari�veis publicas de pergunta.
				Pergunte("PRT0518", .F.)
			EndIf

			// Instancia o objeto do relat�rio
			oReport := ReportDef(cFatura)

			// Inicia o programa do relat�rio
			oReport:PrintDialog()
		EndIf
	Else
		MsgAlert(CAT554042 + NomePrt + " - " +;  	//"O programa "
			AllTrim(StrTran( CAT554002,"-","")) +; 	// " - Relat�rio de Fatura - "
			CAT554043, cCadastro) 					//" n�o pode ser executado neste pa�s."
	EndIf

	RestArea(aArea)

Return

/*/{Protheus.doc} ReportDef
Respons�vel por criar o objeto TReport
@author Paulo Carvalho
@since 04/04/2019
@return oRelatorio, objeto do TReport
@param cFatura, caracter, id da fatura a ser impressa.
@type function
/*/
Static Function ReportDef(cFatura)

	Local cArquivo	:= CAT554003 + DtoS(Date()) + StrTran(Time(), ":", "") // Fatura
	Local bAction	:= {|oReport| PrintReport(oReport, cFatura)}

	Local oRelatorio

	// Instanciando o objeto TReport
	oRelatorio := TReport():New(cArquivo)

	// Define o T�tulo do relt�rio
	oRelatorio:SetTitle(cCadastro)

	// Define os par�metros de configura��o (perguntas) do relat�rio
	If Empty(cFatura)
		oRelatorio:SetParam("PRT0518")
	EndIf

	// Define o bloco de c�digo que ser� executado na confirma��o da impress�o
	oRelatorio:SetAction(bAction)

	// Define a orienta��o da impress�o do relat�rio
	oRelatorio:SetPortrait()

	// Define o tamanho do papel para landscape
	oRelatorio:oPage:SetPaperSize(DMPAPER_A4)

	// Define o nome do arquivo tempor�rio utilizado para a impress�o do relat�rio
	oRelatorio:SetFile(cArquivo)

	// Define a Descri��o do Relat�rio
	oRelatorio:SetDescription(CAT554004)//"Esta rotina imprime o relat�rio da(s) fatura(s)."

	// Desabilita o cabe�alho padr�o do TReport
	oRelatorio:lHeaderVisible := .F.

	// Desabilita o rodap� padr�o do TReport
	oRelatorio:lFooterVisible := .F.

Return oRelatorio

/*/{Protheus.doc} PrintReport
Realizada a defini��o do layout e o carregamento dos dados do objeto.
@author Paulo Carvalho
@since 05/04/2019
@param oReport, objeto que define e cria o relat�rio.
@param cFatura, caracter, id da fatura a ser impressa
@type function
/*/
Static Function PrintReport(oReport, cFatura)

	Local aArea			:= GetArea()
	Local aAreaSE1		:= SE1->(GetArea())
	Local aTam			:= {}
	Local aTCSetField	:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()

	Local lBold			:= .T.
	Local lItalic		:= .T.
	Local lRet			:= .T.
	Local lUnderline	:= .T.

	Local nRowDoc		:= .T.

	Private cCliente	:= ""
	Private cLoja		:= ""
	Private cNumero		:= ""
	Private cPrefixo	:= ""
	Private cParcela	:= ""
	Private cTipo		:= ""

	Private dEmissao	:= CtoD("  /  /    ")

	// Define orienta��es da p�gina (meio e final)
	Private nPages		:= 0
	Private nPageEnd	:= 1700
	Private nTotFrete	:= 0
	Private nTotGeral	:= 0
	Private nTotIcms	:= 0

	// Define a pag atual de impress�o
	Private nPagAtual	:= 1

	// Define os fontes utilizados no relat�rio
	Private oFont12		:= TFont():New("Lucida Console",,12,,!lBold,,,,,!lUnderline,!lItalic)
	Private oFont14		:= TFont():New("Lucida Console",,14,,!lBold,,,,,!lUnderline,!lItalic)
	Private oFont16		:= TFont():New("Lucida Console",,16,,!lBold,,,,,!lUnderline,!lItalic)

	// Define a query que busca as faturas a serem impressas
	cQuery	+= "SELECT 	UQO.UQO_FILIAL, UQO.UQO_ID, UQO.UQO_NUMERO, UQO.UQO_EMISSA,"	+ CRLF
	cQuery	+= "		UQO.UQO_CLIENT, UQO.UQO_LOJA, UQO.UQO_NOMECL, "					+ CRLF
	cQuery	+= "		UQO.UQO_VENCTO, UQO.UQO_TOTAL, UQO.UQO_STATUS, "				+ CRLF
	cQuery	+= "		ISNULL(CONVERT(VARCHAR(8000), "
	cQuery	+= "		CONVERT(VARBINARY(8000), UQO.UQO_OBS)),'') AS OBS"				+ CRLF
	cQuery	+= "FROM	" + RetSQLName("UQO") + " AS UQO "								+ CRLF
	cQuery	+= "WHERE	UQO.UQO_FILIAL = '" + FWxFilial("UQO") + "' "					+ CRLF

	// Verifica se foi enviada uma fatura espec�fica a ser impressa
	If !Empty(cFatura)
		cQuery	+= "AND		UQO.UQO_ID = '" + cFatura + "' "							+ CRLF
	Else // Define o filtro com os par�metros da pergunta PRT0518
		If !Empty(MV_PAR01)
			cQuery	+= "AND	UQO.UQO_ID >= '" + MV_PAR01 + "' "							+ CRLF
		EndIf

		If !Empty(MV_PAR02)
			cQuery	+= "AND	UQO.UQO_ID <= '" + MV_PAR02 + "' "							+ CRLF
		EndIf

		If !Empty(MV_PAR03)
			cQuery	+= "AND	UQO.UQO_EMISSA >= '" + DtoS(MV_PAR03) + "' "				+ CRLF
		EndIf

		If !Empty(MV_PAR04)
			cQuery	+= "AND	UQO.UQO_EMISSA <= '" + DtoS(MV_PAR04) + "' "				+ CRLF
		EndIf

		If !Empty(MV_PAR05)
			cQuery	+= "AND	UQO.UQO_VENCTO >= '" + DtoS(MV_PAR05) + "' "				+ CRLF
		EndIf

		If !Empty(MV_PAR06)
			cQuery	+= "AND	UQO.UQO_VENCTO <= '" + DtoS(MV_PAR06) + "' "				+ CRLF
		EndIf

		If !Empty(MV_PAR07)
			cQuery	+= "AND	UQO.UQO_CLIENT >= '" + MV_PAR07 + "' "						+ CRLF
		EndIf

		If !Empty(MV_PAR08)
			cQuery	+= "AND	UQO.UQO_LOJA >= '" + MV_PAR08 + "' "						+ CRLF
		EndIf

		If !Empty(MV_PAR09)
			cQuery	+= "AND	UQO.UQO_CLIENT <= '" + MV_PAR09 + "' "						+ CRLF
		EndIf

		If !Empty(MV_PAR10)
			cQuery	+= "AND	UQO.UQO_LOJA <= '" + MV_PAR10 + "' "						+ CRLF
		EndIf

		If !Empty(MV_PAR11)
			cQuery	+= "AND	UQO.UQO_STATUS = '" + MV_PAR11 + "' "						+ CRLF
		EndIf
	EndIf

	cQuery	+= "AND		UQO.D_E_L_E_T_ <> '*' "											+ CRLF

	// Define o campos que devem passar pela fun��o TCSetField
	aTam := TamSX3("UQO_EMISSA"); Aadd(aTCSetField, {"UQO_EMISSA"	, aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQO_VENCTO"); Aadd(aTCSetField, {"UQO_VENCTO" 	, aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQO_TOTAL")	; Aadd(aTCSetField, {"UQO_TOTAL"  	, aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQO_OBS")	; Aadd(aTCSetField, {"UQO_OBS"		, aTam[3], aTam[1], aTam[2]})

	// Fecha a �rea de trabalho para nova pesquisa
	fFechaTab(cAliasQry)

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	// Abre a tabela SE1 para pesquisa de informa��es do t�tulo
	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))	// E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO
	SE1->(DbGoTop())

	// Incrementa a r�gua de progress�o do relat�rio
	oReport:IncMeter(0)

	// Inicia a impress�o de cada fatura selecionada.
	While !(cAliasQry)->(Eof())
		cPrefixo	:= IIf(Empty((cAliasQry)->UQO_NUMERO), "", "FAT")
		cNumero		:= (cAliasQry)->UQO_NUMERO		// Titulo digitado manualmente

		If SE1->(DbSeek(FWxFilial("SE1") + cPrefixo + cNumero))
			cParcela	:= SE1->E1_PARCELA
			cTipo		:= SE1->E1_TIPO
		EndIf

		cCliente	:= (cAliasQry)->UQO_CLIENT
		cLoja		:= (cAliasQry)->UQO_LOJA

		dEmissao	:= (cAliasQry)->UQO_EMISSA
		dVencimento	:= (cAliasQry)->UQO_VENCTO

		nPages 		:= 0
		nTotGeral	:= (cAliasQry)->UQO_TOTAL

		oReport:StartPage()

		//--------------------------------------------------------------------------
		// Imprime Cabe�alho do Relat�rio
		//--------------------------------------------------------------------------
		fCabecalho(@oReport, cNumero, dEmissao, dVencimento)

		//--------------------------------------------------------------------------
		// Imprime os Dados do Cliente
		//--------------------------------------------------------------------------
		fCliente(@oReport, cCliente, cLoja)

		//--------------------------------------------------------------------------
		// Imprime o Cabe�alho dos Documentos que comp�em a fatura
		//--------------------------------------------------------------------------
		If lRet
			nRowDoc := fCorpo(@oReport, cFatura)

			//--------------------------------------------------------------------------
			// Imprime o Rodap� do Relat�rio
			//--------------------------------------------------------------------------
			fObs((cAliasQry)->OBS, @nRowDoc)
			fRodape(@oReport, nRowDoc)

			oReport:EndPage()

			nTotFrete	:= 0
			nTotIcms	:= 0
			// nTotGeral	:= 0
		Else
			oReport:CancelPrint()
			Exit
		EndIf

		(cAliasQry)->(DbSkip())
	EndDo

	IIf(Select(cAliasQry) > 0, (cAliasQry)->(dbCloseArea()), Nil)

	RestArea(aAreaSE1)
	RestArea(aArea)

Return

/*/{Protheus.doc} fCabecalho
Imprime o cabecalho da fatura.
@author Paulo Carvalho
@since 09/04/2019
@param oReport, object, Objeto TReport controlador do relat�rio.
@param cTitulo, car�cter, n�mero do t�tulo gerado pela fatura, caso j� tenha sido integrada.
@param dEmissao, data, data de emiss�o da fatura.
@param dVencimento, data, data de vencimento da fatura.
@type function
/*/
Static Function fCabecalho( oReport, cTitulo, dEmissao, dVencimento )

	Local cBmpLogo		:= "\logotipos\logo_empresa.jpg"  //Deve ser jpg na pasta system //FisxLogo("1")
										         //A fun��o FisxLogo("1") busca o logo(BMP) a ser impresso, mas
										         //esse logo n�o � impresso caso a op��o selecionada seja arquivo

	// Vari�veis de defini��o da empresa
	Local cEmpresa		:= SM0->M0_NOMECOM//"VELOCE LOGISTICA S.A"
	Local cEndereco		:= AllTrim(SM0->M0_ENDENT)//"Avenida Luigi Papaiz, 239 - Bloco Admin. 1� Piso"
	Local cBairro		:= SM0->M0_BAIRENT //"Jardim das Na��es SP"
	Local cCidade		:= SM0->M0_CIDENT  //"Diadema SP"
	Local cCep			:= fDefCep(AllTrim(SM0->M0_CEPENT))	//"09931610"
	Local cCnpj			:= fDefCnpj(SM0->M0_CGC, "J")  //"102995670001-64"
	Local cInsEst		:= SM0->M0_INSC //fDefInsc(SM0->M0_INSC) //"286220274118"

	oReport:Say(oReport:Row(), nPageEnd, "", oFont14 , ,CLR_BLACK)

	// Cria o primeiro box para os dados da empresa
	oReport:Box( 0010, 0150, 0520, 1195)

	// Cria o segundo box para os dados da fatura
	oReport:Box( 0010, 1205, 0520, 2240)

	// Cria o objeto com a imagem passada via par�metro
	oTImg := TBitmap():New(0070,0070,,,,cBmpLogo,,,,,,,,,,,,,)

	// Auto ajusta o tamanho, sem ele, � retornado 0
	oTImg:lAutoSize := .T.

	// Define altura
	nHeight := oTImg:nClientHeight

	// Define largura
	nWidth := oTImg:nClientWidth

	// Imprime o logo na p�gina
	oReport:SayBitmap( 0030, 0480, cBmpLogo, nWidth, nHeight 	)
	SaltaLinha(@oReport, 1)

	// Imprime cabe�alho da Fatura
	oReport:Say( 0090, 1630, CAT554009, oFont16 , ,CLR_BLACK) // "FATURA"

	// Escreve os dados da empresa e da fatura
	oReport:Say( 0210, 0160, cEmpresa, oFont14 	 , ,CLR_BLACK)

	// "N�mero da fatura: "
	oReport:Say( 0210, 1215, CAT554010, oFont12	 , ,CLR_BLACK) //"N�mero da fatura"
	oReport:Say( 0210, 1750, cTitulo, oFont12 	 , ,CLR_BLACK)

	oReport:Say( 0260, 0160, cEndereco, oFont12	 , ,CLR_BLACK)
	oReport:Say( 0310, 0160, cBairro, oFont12 	 , ,CLR_BLACK)
	oReport:Say( 0310, 0700, cCidade, oFont12 	 , ,CLR_BLACK)

	// "Data de Emiss�o: "
	oReport:Say( 0310, 1215, CAT554011, oFont12	 , ,CLR_BLACK) //"Data de emiss�o:"
	oReport:Say( 0310, 1750, DtoC(dEmissao), oFont12 , ,CLR_BLACK)

	oReport:Say( 0360, 0160, cCep, oFont12 		 , ,CLR_BLACK)

	// "Data de Vencimento: "
	oReport:Say( 0360, 1215, CAT554012, oFont12  , ,CLR_BLACK) //"Data de Vencimento:"
	oReport:Say( 0360, 1750, DtoC(dVencimento), oFont12 , ,CLR_BLACK)

	// "CNPJ: "
	oReport:Say( 0410, 0160, CAT554013 + cCnpj, oFont12 , ,CLR_BLACK) //"CNPJ:"

	// "INSCR. EST: "
	oReport:Say( 0460, 0160, CAT554016 + cInsEst, oFont12 , ,CLR_BLACK) //"INSCR. EST.:"

Return

/*/{Protheus.doc} fCliente
Imprime os dados do cliente no relat�rio
@author Paulo Carvalho
@since 09/04/2019
@param oReport, objeto, Objeto TReport repons�vel pelo relat�rio.
@param cCliente, car�cter, c�digo do cliente da fatura.
@param cLoja, car�cter, loja do cliente da fatura.
@type function
/*/
Static Function fCliente(oReport, cCliente, cLoja)

	// Vari�veis de defini��o do cliente
	Local aDadosCli		:= {"","","","","","","","",""}
	Local aCampos		:= {"A1_NOME" ,;
							"A1_END" ,;
							"A1_BAIRRO",;
							"A1_CEP" ,;
							"A1_MUN" ,;
							"A1_EST" ,;
							"A1_CGC" ,;
							"A1_INSCR",;
							"A1_PESSOA"}

	Local cCliNom		:= ""
	Local cCliEnd		:= ""
	Local cCliBai		:= ""
	Local cCliCep		:= ""
	Local cCliCid		:= ""
	Local cCliEst		:= ""
	Local cCliCnp		:= ""
	Local cCliIns		:= ""
	Local cCliPes		:= ""

	// Cria o terceiro box para os dados do cliente
	oReport:Box( 0530, 0150, 0760, 2240)

	aDadosCli := GetAdvFVal("SA1", ;
						aCampos,;
						xFilial("SA1") + cCliente + cLoja,;
						1,;
						aDadosCli)

	// Define as informa��es do cliente
	cCliNom := aDadosCli[1]
	cCliEnd := aDadosCli[2]
	cCliBai := aDadosCli[3]
	cCliCep := aDadosCli[4]
	cCliCid := aDadosCli[5]
	cCliEst := aDadosCli[6]
	cCliPes := aDadosCli[9]

	cCliCnp := IIf(!Empty(aDadosCli[7]),StrTran(Transform( aDadosCli[7],;
		PicPes(aDadosCli[9])),"%C","")," ")

	cCliIns := aDadosCli[8]

	// Imprime os dados do cliente
	oReport:Say( 0560, 0160, CAT554015 +  Upper( cCliNom ) , oFont12 , ,CLR_BLACK)		// "Cliente: "
	oReport:Say( 0610, 0160, AllTrim(cCliEnd) + " - " + AllTrim(cCliBai), oFont12 , ,CLR_BLACK)
	oReport:Say( 0660, 0160, fDefCep(cCliCep) + " " + AllTrim(cCliCid) + " " + AllTrim(cCliEst), oFont12 , ,CLR_BLACK)
	oReport:Say( 0710, 0160, CAT554013 + fDefCnpj(cCliCnp, cCliPes), oFont12 , ,CLR_BLACK) //CNPJ
	oReport:Say( 0710, 1215, CAT554016 + /*fDefInsc(*/cCliIns/*)*/, oFont12 , ,CLR_BLACK) //Insc. Est.:

Return

/*/{Protheus.doc} fCorpo
Imprime o corpo do relat�rio contendo os documentos que comp�em a fatura.
@author Paulo Carvalho
@since 09/04/2019
@param oReport, objeto, objeto respons�vel pela impress�o do relat�rio.
@param cFatura, car�cter, id da fatura que est� sendo impressa.
@type function
/*/
Static Function fCorpo(oReport, cFatura)

	Local aArea 		:= GetArea()
	Local aTCSetField	:= {}
	Local aTam			:= {}

	Local cQuery		:= ""
	Local cAliasQry		:= GetNextAlias()

	Local nTotDoc		:= 0
	Local nRowDoc		:= 0

	Private nDocPag		:= 39 // Documentos por p�gina

	// Imprime o cabe�alho dos documentos
	fCorCabec(@oReport)

	//--------------------------------------------------------------------------
	// Busca Itens que comp�em a fatura
	//--------------------------------------------------------------------------
	cQuery	+= "SELECT	UQP.UQP_FILIAL, UQP.UQP_IDFAT, UQP.UQP_ITEM,"			+ CRLF
	cQuery	+= "		UQP.UQP_TPFAT, UQP.UQP_PFXFAT, UQP.UQP_PARFAT PARCORI,"	+ CRLF
	cQuery	+= "		UQP.UQP_TITFAT, UQP.UQP_EMISFA, UQP.UQP_VLRFAT,"		+ CRLF
	cQuery	+= "		UQP.UQP_ICMS, UQP.UQP_TOTAL,"							+ CRLF
	cQuery	+= "		UQP.UQP_PARFAT "										+ CRLF
	cQuery	+= "FROM	" + RetSQLName("UQP") + " AS UQP"						+ CRLF
	cQuery	+= "WHERE	UQP.UQP_FILIAL = '" + xFilial("UQP") + "' "				+ CRLF
	cQuery	+= "AND		UQP.UQP_IDFAT = '" + cFatura + "' "						+ CRLF
	cQuery	+= "AND		UQP.D_E_L_E_T_ <> '*' "									+ CRLF

	// Define o campos que devem passar pela fun��o TCSetField
	aTam := TamSX3("UQP_EMISFA"); Aadd(aTCSetField, {"UQP_EMISFA" , aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQP_VLRFAT"); Aadd(aTCSetField, {"UQP_VLRFAT" , aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQP_ICMS"  ); Aadd(aTCSetField, {"UQP_ICMS"   , aTam[3], aTam[1], aTam[2]})
	aTam := TamSX3("UQP_TOTAL" ); Aadd(aTCSetField, {"UQP_TOTAL"  , aTam[3], aTam[1], aTam[2]})

	// Fecha a �rea de trabalho para nova pesquisa
	fFechaTab(cAliasQry)

	MPSysOpenQuery(cQuery, cAliasQry, aTCSetField)

	// Define quantos documentos comp�em esta fatura (incluindo as Notas de Cr�dito)
	// e o n�mero de p�ginas que ser�o impressas
	nTotDoc := Contar(cAliasQry, "!Eof()")

	nPages := Ceiling((nTotDoc/nDocPag))

	// Define a p�gina atual de impress�o
	nPagAtual := 1

	// Imprime o n�mero da p�gina
	oReport:Say( 0460, 1380, CAT554017 + cValToChar(oReport:Page()), oFont12 , ,CLR_BLACK) //P�gina

	// Posiciona no primeiro arquivo
	(cAliasQry)->(DbGoTop())

	nRowDoc := 860

	If nTotDoc <= nDocPag
		fImpPage(@oReport, cAliasQry, @nRowDoc)
	Else
		fImpPages(@oReport, cAliasQry, nTotDoc, @nRowDoc)
	EndIf

	IIf(Select(cAliasQry) > 0, (cAliasQry)->(dbCloseArea()), Nil)

	RestArea(aArea)
Return nRowDoc

/*/{Protheus.doc} fCorCabec
Imprime o cabe�alho do corpo do relat�rio.
@author Paulo Carvalho
@since 09/04/2019
@param oReport, objeto, objeto respons�vel pela impress�o do relat�rio.
@type function
/*/
Static Function fCorCabec(oReport)

	oReport:Box( 0770, 0150, 0850, 2240)

	oReport:Say( 0800, 0240, Upper(CAT554018), oFont12 , ,CLR_BLACK)	// "N� DOCUMENTO"
	oReport:Say( 0800, 0670, Upper(CAT554019), oFont12 , ,CLR_BLACK)	// "EMISS�O"
	oReport:Say( 0800, 1030, Upper(CAT554020), oFont12 , ,CLR_BLACK)	// "FRETE"
	oReport:Say( 0800, 1380, Upper(CAT554021), oFont12 , ,CLR_BLACK)	// "ICMS"
	oReport:Say( 0800, 1840, Upper(CAT554022), oFont12 , ,CLR_BLACK)	// "TOTAL"

Return

/*/{Protheus.doc} fImpPage
Imprime a rela��o de documentos que comp�e a fatura caso n�o ultrapasse o limite por p�gina.
@author Paulo Carvalho
@since 09/04/2019
@param oReport, objeto, objeto respons�vel pela impress�o do relat�rio.
@param cAliasQry, car�cter, Alias com a pesquisa dos t�tulos a serem impressos.
@param nRowDoc, num�rico, n�mero da linha de impress�o do documento.
@type function
/*/
Static Function fImpPage(oReport, cAliasQry, nRowDoc)

	Local aArea			:= GetArea()
	Local aAreaUQD		:= UQD->(GetArea())
	Local aAreaSA1		:= SA1->(GetArea())

	Local cAux			:= ""
	Local cDocumento	:= ""
	Local cData			:= ""
	Local cTipo			:= ""
	Local cTmpAlias		:= GetNextAlias()

	Local nFrete		:= 0
	Local nIcms			:= 0
	Local nTotal		:= nFrete + nIcms

	While !(cAliasQry)->(Eof())
		cTipo 	:= (cAliasQry)->UQP_TPFAT
		nRowDoc += 20

		// Verifica se � um t�tulo CTE/CRT
		If (cAliasQry)->UQP_PFXFAT == "CTE" .Or.;
			(cAliasQry)->UQP_PFXFAT == "CRT"

			//Altera��o 30/09/2019 - Icaro
			//Para o caso de uma fatura ser gerada em uma filial usando titulos CTE integradas em outra

			cQuery := " SELECT UQD.UQD_NUMERO, UQD.UQD_INDICA "						+ CRLF
			cQuery += " FROM " + RetSQLName("UQD") + " UQD "  						+ CRLF
			cQuery += " WHERE UQD.UQD_PREFIX = '" + (cAliasQry)->UQP_PFXFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_TITULO = '" + (cAliasQry)->UQP_TITFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_PARCEL = '" + (cAliasQry)->PARCORI + "' "		+ CRLF
			cQuery += "   AND UQD.UQD_TIPOTI = '" + (cAliasQry)->UQP_TPFAT + "' "	+ CRLF
			cQuery += "   AND UQD.D_E_L_E_T_ <> '*' "

			MpSysOpenQuery(cQuery, cTmpAlias)

			If !(cTmpAlias)->(Eof())
			/*DbSelectArea("UQD")
			UQD->(DbSetOrder(5))	// UQD_FILIAL + UQD_PREFIX + UQD_TITULO + UQD_PARCEL + UQD_TIPOTI

			If UQD->(DbSeek(FWxFilial("UQD") + (cAliasQry)->UQP_PFXFAT +;
				(cAliasQry)->UQP_TITFAT + (cAliasQry)->UQP_PARFAT +;
				(cAliasQry)->UQP_TPFAT))*/

				cAux := Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, RAT("-", (cTmpAlias)->UQD_NUMERO) + 1, 2))//Alltrim(SubStr(UQD->UQD_NUMERO, RAT("-", UQD->UQD_NUMERO) + 1, 2))

				cDocumento := AllTrim((cTmpAlias)->UQD_INDICA) +;//AllTrim(UQD->UQD_INDICA) +;
							  Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, 1, RAT("-", (cTmpAlias)->UQD_NUMERO) - 1 )) +;//Alltrim(SubStr(UQD->UQD_NUMERO, 1, RAT("-", UQD->UQD_NUMERO) - 1 )) +; //Ultima posi��o antes do tra�o
							  " - " + cAux

			//EndIf
			Else
				cDocumento := AllTrim((cAliasQry)->UQP_TITFAT) +;
				" - " +;
				AllTrim((cAliasQry)->UQP_TPFAT)
			EndIf
		Else
			cDocumento := AllTrim((cAliasQry)->UQP_TITFAT) +;
				" - " +;
				AllTrim((cAliasQry)->UQP_TPFAT)
		EndIf

		cData		:= DtoC((cAliasQry)->UQP_EMISFA)
		nFrete		:= (cAliasQry)->UQP_TOTAL
		nIcms		:= (cAliasQry)->UQP_ICMS
		nTotal		:= IIf(AllTrim(cTipo) $ "NCC|RA", ((nFrete + nIcms)* -1), (nFrete + nIcms))

		nTotFrete	:= IIf(AllTrim(cTipo) $ "NCC|RA", nTotFrete - nFrete, nTotFrete + nFrete)
		nTotIcms	+= nIcms
		// nTotGeral	:= IIf(AllTrim(cTipo) $ "NCC|RA", nTotGeral - nTotal, nTotGeral + nTotal)

		oReport:Say( nRowDoc, 0165, cDocumento										, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 0645, cData											, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 0930, Transform(nFrete, PesqPict("UQP", "UQP_TOTAL"))	, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 1290, Transform(nIcms , PesqPict("UQP", "UQP_ICMS"))	, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 1880, Transform(nTotal, PesqPict("UQP", "UQP_TOTAL"))	, oFont12 , ,CLR_BLACK)

		nRowDoc += 30

		(cAliasQry)->(DbSkip())
	EndDo

	nRowDoc += 60

	oReport:Box( 0860, 0150, nRowDoc, 0580)
	oReport:Box( 0860, 0580, nRowDoc, 0900)
	oReport:Box( 0860, 0900, nRowDoc, 1251)
	oReport:Box( 0860, 1250, nRowDoc, 1600)
	oReport:Box( 0860, 1600, nRowDoc, 2240)

	RestArea(aAreaSA1)
	RestArea(aAreaUQD)
	RestArea(aArea)

Return

/*/{Protheus.doc} fImpPages
Imprime a rela��o de documentos que comp�em a fatura caso ultrapasse o limite de documentos por p�gina
@author Paulo Carvalho
@since 09/04/2019
@param oReport, objeto, objeto respons�vel pela impress�o do relat�rio.
@param cAliasQry, car�cter, Alias com a pesquisa dos t�tulos a serem impressos.
@param nTotDoc, num�rico, total de documentos a serem impressos.
@param nRowDoc, num�rico, n�mero da linha de impress�o do documento.
@type function
/*/
Static Function fImpPages(oReport, cAliasQry, nTotDoc, nRowDoc)

	Local cDocumento	:= ""
	Local cAux			:= ""
	Local cData			:= ""
	Local cTipo			:= ""
	Local cTmpAlias		:= GetNextAlias()

	Local nDocs			:= 0
	Local nFrete		:= 0
	Local nIcms			:= 0
	Local nTotal		:= nFrete + nIcms

	While !(cAliasQry)->(Eof())
		cTipo	:= (cAliasQry)->UQP_TPFAT
		nRowDoc	+= 20
		nDocs	+= 1

		// Verifica se � um t�tulo CTE/CRT
		If (cAliasQry)->UQP_PFXFAT == "CTE" .Or.;
			(cAliasQry)->UQP_PFXFAT == "CRT"

			//Altera��o 30/09/2019 - Icaro
			//Para o caso de uma fatura ser gerada em uma filial usando titulos CTE integradas em outra

			cQuery := " SELECT UQD.UQD_NUMERO, UQD.UQD_INDICA "						+ CRLF
			cQuery += " FROM " + RetSQLName("UQD") + " UQD "  						+ CRLF
			cQuery += " WHERE UQD.UQD_PREFIX = '" + (cAliasQry)->UQP_PFXFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_TITULO = '" + (cAliasQry)->UQP_TITFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_PARCEL = '" + (cAliasQry)->PARCORI + "' "		+ CRLF
			cQuery += "   AND UQD.UQD_TIPOTI = '" + (cAliasQry)->UQP_TPFAT + "' "	+ CRLF
			cQuery += "   AND UQD.D_E_L_E_T_ <> '*' "

			MpSysOpenQuery(cQuery, cTmpAlias)

			If !(cTmpAlias)->(Eof())
			/*DbSelectArea("UQD")
			UQD->(DbSetOrder(5))	// UQD_FILIAL + UQD_PREFIX + UQD_TITULO + UQD_PARCEL + UQD_TIPOTI

			If UQD->(DbSeek(FWxFilial("UQD") + (cAliasQry)->UQP_PFXFAT +;
				(cAliasQry)->UQP_TITFAT + (cAliasQry)->UQP_PARFAT +;
				(cAliasQry)->UQP_TPFAT))*/

				cAux := Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, RAT("-", (cTmpAlias)->UQD_NUMERO) + 1, 2))//Alltrim(SubStr(UQD->UQD_NUMERO, RAT("-", UQD->UQD_NUMERO) + 1, 2))

				cDocumento := AllTrim((cTmpAlias)->UQD_INDICA) +;//AllTrim(UQD->UQD_INDICA) +;
							  Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, 1, RAT("-", (cTmpAlias)->UQD_NUMERO) - 1 )) +;//Alltrim(SubStr(UQD->UQD_NUMERO, 1, RAT("-", UQD->UQD_NUMERO) - 1 )) +; //Ultima posi��o antes do tra�o
							  " - " + cAux

				/*cDocumento := AllTrim((cAliasQry)->UQP_PFXFAT) +;
							  Alltrim(SubStr(UQD->UQD_NUMERO, 1, RAT("-", UQD->UQD_NUMERO) - 1 )) +; //Ultima posi��o antes do tra�o //AllTrim((cAliasQry)->UQP_TITFAT) //+;
							  " - " +;
							  Alltrim(SubStr(UQD->UQD_NUMERO, RAT("-", UQD->UQD_NUMERO) + 1, 2))*/
			//EndIf
			EndIf
		Else
			cDocumento := AllTrim((cAliasQry)->UQP_TITFAT) +;
				" - " +;
				AllTrim((cAliasQry)->UQP_TPFAT)
		EndIf

		cData		:= DtoC((cAliasQry)->UQP_EMISFA)
		nFrete		:= (cAliasQry)->UQP_TOTAL
		nIcms		:= (cAliasQry)->UQP_ICMS
		nTotal		:= IIf(AllTrim(cTipo) $ "NCC|RA", ((nFrete + nIcms)* -1), (nFrete + nIcms))

		nTotFrete	:= IIf(AllTrim(cTipo) $ "NCC|RA", nTotFrete - nFrete, nTotFrete + nFrete)
		nTotIcms	+= nIcms
		// nTotGeral	:= IIf(AllTrim(cTipo) $ "NCC|RA", nTotGeral - nTotal, nTotGeral + nTotal)

		// Se o Documento a ser impresso for maior do que limite por p�gina
		If nDocs > nDocPag
			nRowDoc += 20

			oReport:Box( 0860, 0150, nRowDoc, 0580)
			oReport:Box( 0860, 0580, nRowDoc, 0900)
			oReport:Box( 0860, 0900, nRowDoc, 1251)
			oReport:Box( 0860, 1250, nRowDoc, 1600)
			oReport:Box( 0860, 1600, nRowDoc, 2240)

			// Finalizo a p�gina
			oReport:EndPage()

			// Inicio uma p�gina nova
			oReport:StartPage()

			// Imprimo o cabe�alho
			fCabecalho(@oReport, cNumero, dEmissao, dVencimento)

			nPagAtual++
			oReport:Say(0460, 1380, CAT554017 + cValToChar(oReport:Page()) , oFont12 , ,CLR_BLACK) //P�gina

			// Imprimo os dados do cliente
			fCliente(@oReport, cCliente, cLoja)

			// Imprimo o cabe�alho do corpo do relat�rio
			fCorCabec(@oReport)

			// Redefino a linha de impress�o
			nRowDoc := 880

			// Redefino a quantidade de documentos impressos na p�gina
			nDocs	:= 1
		EndIf

		oReport:Say( nRowDoc, 0165, cDocumento										, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 0645, cData											, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 0920, Transform(nFrete, PesqPict("UQP", "UQP_TOTAL"))	, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 1280, Transform(nIcms , PesqPict("UQP", "UQP_ICMS"))	, oFont12 , ,CLR_BLACK)
		oReport:Say( nRowDoc, 1880, Transform(nTotal, PesqPict("UQP", "UQP_TOTAL"))	, oFont12 , ,CLR_BLACK)

		nRowDoc += 30

		(cAliasQry)->(DbSkip())
	EndDo

	nRowDoc += 30

	oReport:Box( 0860, 0150, nRowDoc, 0580)
	oReport:Box( 0860, 0580, nRowDoc, 0900)
	oReport:Box( 0860, 0900, nRowDoc, 1251)
	oReport:Box( 0860, 1250, nRowDoc, 1600)
	oReport:Box( 0860, 1600, nRowDoc, 2240)

Return

/*/{Protheus.doc} fObs
Gera o box de observa��es
@author Kevin Willians
@since 11/01/2019
@param cObservacao, caracter, observa��o da fatura a ser impressa.
@type function
/*/
Static Function fObs(cObservacao, nRow)

	Local cTexto		:= ""

	Local nI
	Local nLinBkp 		:= nRow
	Local nLin			:= nRow//2950
	Local nLinNewPage	:= 0
	Local nMaxLin		:= 0//8
	Local nQtdeLin		:= 0
	Local nSizePLin		:= 350
	Local nSizeSLin		:= 160//400

	// Determina a quantidade de linhas necess�rias para impress�o da fatura.
	nQtdeLin := MlCount(AllTrim(cObservacao), 95) //Por causa do limite do campo memo na query nQtdeLin ter� tamanho maximo de
	 											   //21 linhas com 95 caracteres
	nMaxLin := nQtdeLin

	If nQtdeLin <= 3

		nLin += 20

		oReport:Say( nLin, 0160, CAT554024, oFont12 , ,CLR_BLACK) // Observa��o:

		For nI := 1 To nQtdeLin
			nLin += 40

			cTexto 	:= MemoLine(AllTrim(cObservacao), 95, nI)
			nSize 	:= IIf(nLin == 1, nSizePLin, nSizeSLin)

			oReport:Say(nLin, nSize, cTexto, oFont12 , ,CLR_BLACK)

		Next

		nLin += 80

		oReport:Box( nLinBkp, 0150, nLin, 2240)

	Else

		nLin += 20

		oReport:Say( nLin, 0160, CAT554024, oFont12 , ,CLR_BLACK)	// "Observa��o: "

		// Imprime parte da observa��o na primeira p�gina
		For nI := 1 To nMaxLin
			nLin += 40

			cTexto := MemoLine(AllTrim(cObservacao), 95, nI)

			nSize := IIf(nLin == 1, nSizePLin, nSizeSLin)

			oReport:Say(nLin, nSize, cTexto, oFont12 , ,CLR_BLACK)

			nLinNewPage := nI

			If nLin >= 3100
				nLinNewPage++
				Exit
			EndIf
		Next

		nLin += 60

		oReport:Box( nLinBkp, 0150, nLin, 2240)

		// Gera a pr�xima p�gina
		lContinua := .T.
		Do While lContinua
			If nLin >= 3100

				oReport:EndPage()
				oReport:StartPage()

				// Reimprime o cabe�alho
				fCabecalho(@oReport, cNumero, dEmissao, dVencimento)

				// Reimprime o cliente
				fCliente(@oReport, cCliente, cLoja)

				//Imprime o n�mero da p�gina
				oReport:Say( 0460, 1380, CAT554017 + cValToChar(oReport:Page()) , oFont12 , ,CLR_BLACK) // P�gina

				nLin := 780

				// Imprime o restante da observa��o.
				For nI := nLinNewPage To nQtdeLin
					cTexto 	:= MemoLine(AllTrim(cObservacao), 95, nI)
					nSize 	:= IIf(nLin == 1, nSizePLin, nSizeSLin)

					If Empty(cTexto)
						Exit
					EndIf

					oReport:Say(nLin, nSize, cTexto, oFont12 , ,CLR_BLACK)
					nLin += 40

					//Quando estourar quantidade de linhas na pagina atual, gera outra pagina
					If nLin >= 3100
						nLinNewPage := nI

						Exit
					EndIf
				Next

				nLin += 10

				oReport:Box(770, 0150, nLin, 2240)
			Else
				lContinua := .F.
			EndIf
		EndDo

	EndIf

	nRow := nLin // Parametro nRow passado como referencia
Return

/*/{Protheus.doc} fRodape
Imprime as informa��es de rodap� da fatura
@author Paulo Carvalho
@since 16/10/2018
@version 1.01
@type Static Function
/*/
Static Function fRodape(oReport, nRow)
	Local cAux		:= ""
	Local cFrete	:= ""
	Local cIcms		:= ""
	Local cTotal	:= ""
	Local cValExten	:= ""
	Local nI		:= ""
	Local nLinBkp 	:= nRow
	Local nLin		:= nRow//2950

	cFrete	:= Transform(nTotFrete	, PesqPict("UQP", "UQP_VLRFAT"))
	cIcms	:= Transform(nTotIcms	, PesqPict("UQP", "UQP_ICMS"))
	cTotal	:= Transform(nTotGeral	, PesqPict("UQO", "UQO_TOTAL" ))

	nLin += 90

	// Cria o box para o total geral
	oReport:Box( nLinBkp, 0150, nLin, 2240)

	//nLin += 30

	oReport:Say( nLinBkp + 15, 0160, CAT554022, oFont12 , ,CLR_BLACK) // Total

	oReport:Say( nLinBkp + 15, 0920, cFrete, oFont12 , ,CLR_BLACK)
	oReport:Say( nLinBkp + 15, 1275, cIcms , oFont12 , ,CLR_BLACK)
	oReport:Say( nLinBkp + 15, 1680, cTotal, oFont12 , ,CLR_BLACK)

		// Cria Boxes complementares
	oReport:Box( nLin, 0150, nLin + 40, 2240)

	nLin += 40

	oReport:Box( nLin, 0150, nLin + 40, 2240)

	nLin += 40//Igualidade para obter o valor de nLin + 40 acima

	// Valor por extenso
	nLinBkp := nLin

	nLin += 30

	oReport:Say( nLin, 0160, CAT554023, oFont12 , ,CLR_BLACK) // Valor por extenso
	cValExten := Capital(Extenso(nTotGeral))
	If Len(cValExten) > 71

		For nI := 1 to MlCount(cValExten, 71)
			cAux := MemoLine( AllTrim(cValExten), 71, nI)

			oReport:Say( nLin, 0590, cAux, oFont12 , ,CLR_BLACK)
			nLin += 40
		Next

		oReport:Box( nLinBkp, 0150, nLin + 55, 0580)
		oReport:Box( nLinBkp, 0580, nLin + 55, 2240)
	Else
		oReport:Say( nLin, 0590, cValExten, oFont12 , ,CLR_BLACK)
		oReport:Box( nLinBkp, 0150, nLin + 95, 0580)
		oReport:Box( nLinBkp, 0580, nLin + 95, 2240)
	EndIf

Return

/*/{Protheus.doc} SaltaLinha
Aux�lio para saltar linha na impress�o da Ordem de Produ��o
@author Juliano Fernandes
@since 29/06/2016
@param oReport, object, Objeto TReport
@param nQtd, numeric, Quantidade de linhas a serem saltadas
@type function
/*/
Static Function SaltaLinha(oReport, nQtd)
	Default nQtd := 1

	While nQtd > 0
		oReport:SkipLine()
		nQtd--
	EndDo
Return

/*/{Protheus.doc} fAsrPerg
//Gera as perguntas necess�rias para o fonte atual
@author Kevin Willians
@since 12/12/2018
@version undefined
@param cPer, characters, NomePRT para grupo de perguntas
@type function
/*/
Static Function fAsrPerg(cPer)

	Local aTamSx3	:= {}
	Local aArea		:= GetArea()

	//�Limpa o conte�do de pergunta existente�
	/*DbSelectArea("SX1")
	SX1->(DbSetOrder(1))
	If SX1->(DbSeek(PADR(cPer,10)))
		While Alltrim(SX1->X1_GRUPO) == Alltrim(cPer)
			RecLock("SX1",.F.)
			SX1->(DbDelete())
			//SX1->X1_CNT01 := ""
			SX1->(MsUnlock())

			SX1->(DbSkip())
		EndDo
	EndIf
	SX1->(DbCloseArea())*/

	aTamSx3 := TamSX3("UQO_ID")
	u_PRT0557(cPer,"01","Fatura de?  ","�De Factura? ","Invoice From? ","mv_ch1", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","UQO","","","mv_par01","","","","","","","","","","","","",""," "," "," ",{"Fatura de"},{""},{""})

	aTamSx3 := TamSX3("UQO_ID")
	u_PRT0557(cPer,"02","Fatura at�?  ","�A Factura? ","Invoice to? ","mv_ch2", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","UQO","","","mv_par02","","","","","","","","","","","","",""," "," "," ",{"Fatura at�"},{""},{""})

	aTamSx3 := TamSX3("UQO_EMISSA")
	u_PRT0557(cPer,"03","Emiss�o de?  ","�De Emisi�n?","Emission From? ","mv_ch3", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","","","mv_par03","","","","","","","","","","","","",""," "," "," ",{"Emiss�o de"},{""},{""})

	aTamSx3 := TamSX3("UQO_EMISSA")
	u_PRT0557(cPer,"04","Emiss�o at�?  ","�A Emisi�n? ","Emission To? ","mv_ch4", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","","","mv_par04","","","","","","","","","","","","",""," "," "," ",{"Emiss�o at�"},{""},{""})

	aTamSx3 := TamSX3("UQO_VENCTO")
	u_PRT0557(cPer,"05","Vencimento de? ","�De Vencimiento?","Due From? ","mv_ch5", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","SE1","","","mv_par05","","","","","","","","","","","","",""," "," "," ",{"Vencimento de"},{""},{""})

	aTamSx3 := TamSX3("UQO_VENCTO")
	u_PRT0557(cPer,"06","Vencimento at�? ","�A Vencimiento? ","Due To? ","mv_ch6", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","","","mv_par06","","","","","","","","","","","","",""," "," "," ",{"Vencimento at�"},{""},{""})

	aTamSx3 := TamSX3("UQO_CLIENT")
	u_PRT0557(cPer,"07","Cliente de? ","�De Cliente? ","Customer from? ","mv_ch7", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","SA1","","","mv_par07","","","","","","","","","","","","",""," "," "," ",{"Cliente de"},{""},{""})

	aTamSx3 := TamSX3("UQO_LOJA")
	u_PRT0557(cPer,"08","Loja de? ","�De Tienda? ", "Store To?","mv_ch8", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","","","mv_par08","","","","","","","","","","","","",""," "," "," ",{"Loja de"},{""},{""})

	aTamSx3 := TamSX3("UQO_CLIENT")
	u_PRT0557(cPer,"09","Cliente at�? " ,"�A Cliente?" ,"Customer To?","mv_ch9", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","SA1","","","mv_par09","","","","","","","","","","","","",""," "," "," ",{"Cliente at�"},{""},{""})

	aTamSx3 := TamSX3("UQO_LOJA")
	u_PRT0557(cPer,"10","Loja at�?  " ,"�A Tienda?","Store to? ","mv_chA", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","",""	,"mv_par10","","","","","","","","","","","","",""," "," "," ",{"Loja at�"},{""},{""})

	aTamSx3 := TamSX3("UQO_STATUS")
	u_PRT0557(cPer,"11","Status     " ,"Estatus","Status","mv_chC", aTamSx3[3],  aTamSx3[1],  aTamSx3[2], 0,"G","","","","","mv_par11","","","","","","","","","","","","",""," "," "," ",{"Status"},{""},{""})

	RestArea(aArea)

Return

/*/{Protheus.doc} fDefCep
Insere m�scara de cep no cep passado.
@author Paulo Carvalho
@since 16/04/2019
@param cCep, car�cter, Cep a ser mascarado.
@type function
/*/
Static Function fDefCep(cCep)

	Local cCepMask	:= ""

	If !Empty(cCep)
		// Retira pontos, tra�os e barras do cep
		cCep := StrTran(cCep, ".", "")
		cCep := StrTran(cCep, "-", "")
		cCep := StrTran(cCep, "/", "")

		// Mascara o cep para retornar � chamada
		cCepMask := Transform(cCep, "@R 99999-999")
	EndIf

Return cCepMask

/*/{Protheus.doc} fDefCnpj
Insere m�scara de cnpj/cpf no cnpj/cpf passado.
@author Paulo Carvalho
@since 16/04/2019
@param cCnpj, car�cter, CNPJ/CPF a ser mascarado.
@type function
/*/
Static Function fDefCnpj(cCnpj, cTipoPessoa)

	Local cCnpjMask	:= ""

	If !Empty(cCnpj)
		// Retira pontos, tra�os e barras no cpnj
		cCnpj := StrTran(cCnpj, ".", "")
		cCnpj := StrTran(cCnpj, "-", "")
		cCnpj := StrTran(cCnpj, "/", "")

		// Mascara o cnpj para retornar � chamada
		If "F" $ cTipoPessoa
			cCnpjMask := Transform(cCnpj, "@R 999.999.999-99")
		ElseIf "J" $ cTipoPessoa
			cCnpjMask := Transform(cCnpj, "@R 99.999.999/9999-99")
		EndIf
	EndIf

Return cCnpjMask

/*/{Protheus.doc} fDefInsc
Insere m�scara de inscri��o estadual na inscri��o passada.
@author Paulo Carvalho
@since 16/04/2019
@param cInscricao, car�cter, Inscri��o estadual a ser mascarada.
@type function
/*/
Static Function fDefInsc(cInscricao)

	Local cInscMask	:= ""

	If !Empty(cInscricao)
		// Retira pontos, tra�os e barras na inscri��o
		cInscricao := StrTran(cInscricao, ".", "")
		cInscricao := StrTran(cInscricao, "-", "")
		cInscricao := StrTran(cInscricao, "/", "")

		// Mascara a incri��o para retornar � chamada
		cInscMask := Transform(cInscricao, "@R 999.999.999.999")
	EndIf

Return cInscMask

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
	EndIf

Return

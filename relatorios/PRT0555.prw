#Include 'Totvs.ch'
#Include "RPTDef.CH"
#Include "CATTMS.ch"

Static NomePrt		:= "PRT0555"
Static VersaoJedi	:= "V1.19"

/*/{Protheus.doc} PRT0555
Envia relatório de fatura via e-mail.
@author Paulo Carvalho
@param cCod, carácter, número identificador da fatura.
@since 11/10/2018
@version 1.01
@type User Function
/*/
User Function PRT0555(cCod)
	Private cTitulo		:= NomePrt + CAT554002 + VersaoJedi // " - Impressão de Fatura - "
	Private cFile		:= ""
	Private cLiquidacao	:= ""
	Private cZAId		:= cCod

	Private lCallMenu	:= !IsInCallStack("fina740")
	Private lMultipFat	:= IsInCallStack("fMultipFat")

	Private oReport	:= Nil

	DbselectArea("UQO")
	UQO->(DbSetOrder(1))
	UQO->(DbSeek(xFilial("UQO") + cZAId))

	cLiquidacao	:= UQO->UQO_NUMERO

	DbselectArea("UQP")
	UQP->(DbSetOrder(1))

	DbSelectArea("SE1")
	SE1->(DbSetOrder(1))

	If lCallMenu
		// Verifica se relatórios personalizaveis está disponível
		If TRepInUse()
			// Inicializa as variáveis publicas de pergunta.
			Pergunte( "PRT0518", .F. )

			// Instancia o objeto do relatório
			oReport := ReportDef() // Recno da 250319D16
			Processa({|| fProc()})
		EndIf
	Else
		// Instancia o objeto do relatório
		oReport := ReportDef()

		If lMultipFat
			fProc()
		Else
			Processa({|| fProc()})
		EndIf
	EndIf

Return(cFile)

/*/{Protheus.doc} fProc
Processa a fatura para ser enviada via e-mail.
@author Paulo Carvalho
@since 25/01/2019
@return Nil, Nulo
@type function
/*/
Static Function fProc()
	Local cNewFile := ""
	Private	cEmail := ""

	// Gera o relatório
	PrintReport( oReport )
	// Imprime o relatório
	IncProc()

	cNewFile := StrTran( cFile, "pd_", "pdf" )

	// Deleta arquivo caso já exista algum com o mesmo nome
	fErase( cNewFile )

	oReport:Preview()

	cFile := cNewFile

	If !lMultipFat
		IncProc()

		Sleep(5000)

		// Envia e-mail aos destinatários
		If fEmail( cFile )
			IncProc()
			MsgInfo( CAT555003) // E-mail criado com sucesso!
		Else
			//MsgAlert( "Erro na geração do email") Função fEnvia já exibe o erro ocorrido
		EndIf

		//Apaga os arquivos temporários(.rel e .pdf) gerados no sistema
		FErase(cFile)
		FErase(StrTran( cFile, ".pdf", ".rel" ))
	Else
		c518Email := cEmail
	EndIf

Return Nil

/*/{Protheus.doc} ReportDef
Define as características do relatório
@author Paulo Carvalho
@since 15/10/2018
@version 1.01
@param cFat, char, Número da Liquidação
@type Static Function
@return oReport, objeto TReport inicializado.
/*/
Static Function ReportDef(nRecno)
	Local cArquivo		:= "FT" + AllTrim(cLiquidacao) + ".PD_"//CAT554003 + DtoS( Date() ) + StrTran( Time(), ":", "" ) + ".PD_" // "fatura_"
	Local cNomeRel		:= "FAT_" + DToS(Date()) + Replace(Time(),":","")
	Local cFilePrint	:= ""
	Local cLocal		:= "C:\Temp\"

	Local lAdjustToLegacy	:= .F.
	Local lDisableSetup		:= .T.
	Local lTReport			:= .F.

	Local oRelatorio	:= Nil

	Default nRecno 		:= 0

	If !ExistDir( cLocal )
		MakeDir( cLocal )
	EndIf

	// Instanciando o objeto MsPrinter
	oRelatorio := FWMSPrinter():New( cArquivo, IMP_PDF, lAdjustToLegacy, cLocal, lDisableSetup, lTReport, , , .T., , .F., .F., )

	// Define as margens do relatório
	oRelatorio:SetMargin( 60, 60, 60, 60 )

	// Define a orientação da impressão do relatório
	oRelatorio:SetPortrait()

	cFilePrint := cLocal + cArquivo

	File2Printer( cFilePrint, "PDF" )

	cFile := cFilePrint

	// Path aonde será gravado o arquivo PDF
	oRelatorio:cPathPDF := cLocal

	If lMultipFat
		// c518DirFat = variável private do programa PRT0518
		c518DirFat := cLocal
	EndIf
Return oRelatorio

/*/{Protheus.doc} PrintReport
Realizada a definição do layout e o carregamento dos dados do objeto.
@author Paulo Carvalho
@since 11/10/2018
@param oReport, objeto que define e cria o relatório.
@param cFat, char, Número da Liquidação
@version 1.01
@type Static Function
/*/
Static Function PrintReport( oReport, nRecno )
	Local aRetObs		:= {}
	Local aTam			:= {}
	Local cQuery		:= ""
	Local cAliasTmp		:= GetNextAlias()
	Local cObserv		:= ""
	Local lRet			:= .T.

	Local lBold			:= .T.
	Local lItalic		:= .T.
	Local lUnderline	:= .T.

	Local nRowDoc		:= 0
	// Define orientações da página (meio e final)
	Private nPages		:= 0

	//Define a pag atual de impressão
	Private nPagAtual	:= 1

	// Define as informações principais do relatório
	Private cCliente		:= ""
	Private cLoja			:= ""

	Private dEmissao		:= Date()
	Private dVencimento		:= Date()

	// Define os totalizadores da fatura
	Private nTotFrete		:= 0
	Private nTotIcms		:= 0
	Private nTotGeral		:= 0

	// Define os fontes utilizados no relatório
	Private oFont10		:= TFont():New("Lucida Console",,10,,!lBold,,,,,!lUnderline,!lItalic)
	Private oFont14		:= TFont():New("Lucida Console",,14,,!lBold,,,,,!lUnderline,!lItalic)
	Private oFont16		:= TFont():New("Lucida Console",,16,,!lBold,,,,,!lUnderline,!lItalic)

	Private lImpNCC		:= .F.

	oReport:StartPage()

	dEmissao 	:= UQO->UQO_EMISSA
	dVencimento	:= UQO->UQO_VENCTO

	//--------------------------------------------------------------------------
	// Imprime Cabeçalho do Relatório
	//--------------------------------------------------------------------------
	fCabecalho( @oReport, cLiquidacao, dEmissao, dVencimento )

	cCliente	:= UQO->UQO_CLIENT
	cLoja		:= UQO->UQO_LOJA

	//--------------------------------------------------------------------------
	// Imprime os Dados do Cliente
	//--------------------------------------------------------------------------
	fCliente( @oReport )

	cQuery := "SELECT	UQP_FILIAL, UQP_IDFAT, UQP_ITEM, UQP_PFXFAT,  " 				+ CRLF
	cQuery += "			UQP_TITFAT, UQD_SERIE, UQD_CLIENT, UQP.UQP_PARFAT PARCORI, "	+ CRLF
	cQuery += "			UQP_EMISFA, UQP_VLRFAT, UQP_ICMS, UQP_TIPO, " 					+ CRLF
	cQuery += "	  		UQP_PREFIX, UQP_TITULO, UQP_EMISSA,"							+ CRLF
	cQuery += "	  		UQP_VALOR, UQP_TPFAT, UQP_TOTAL, "								+ CRLF
	cQuery += "	  		UQP.UQP_PARFAT "												+ CRLF
	cQuery += "FROM		" + RetSQLName("UQP") + " UQP "									+ CRLF
	cQuery += "LEFT JOIN " + RetSQLName("UQD") + " UQD "	 							+ CRLF
	cQuery += "		ON  UQD.UQD_FILIAL = '" + xFilial("UQD") + "' "						+ CRLF
	cQuery += "		AND UQD.UQD_PREFIX = UQP.UQP_PFXFAT "								+ CRLF
	cQuery += "		AND UQD_TITULO = UQP.UQP_TITFAT "									+ CRLF
	cQuery += "		AND UQD.UQD_PARCEL = UQP.UQP_PARFAT "								+ CRLF
	cQuery += "		AND UQD.UQD_TIPOTI = UQP_TPFAT "									+ CRLF
	cQuery += "		AND UQD.D_E_L_E_T_ <> '*' "											+ CRLF
	cQuery += "WHERE 	UQP_FILIAL = '" 	+ xFilial("UQP") 	+ "'" 					+ CRLF
	cQuery += "AND 		UQP_IDFAT = '" 	+ cZAId 			+ "'" 						+ CRLF
	cQuery += "AND UQP.D_E_L_E_T_ <> '*'" 												+ CRLF
	cQuery += "ORDER BY UQP.UQP_FILIAL, UQP.UQP_IDFAT, UQP.UQP_ITEM "					+ CRLF

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasTmp,.T.,.T.)

	aTam := TamSX3("UQP_EMISFA") ; TcSetField(cAliasTmp,"UQP_EMISFA",aTam[3], aTam[1], aTam[2])
	aTam := TamSX3("UQP_VLRFAT") ; TcSetField(cAliasTmp,"UQP_VLRFAT",aTam[3], aTam[1], aTam[2])
	aTam := TamSX3("UQP_ICMS"  ) ; TcSetField(cAliasTmp,"UQP_ICMS"  ,aTam[3], aTam[1], aTam[2])
	aTam := TamSX3("UQP_EMISSA") ; TcSetField(cAliasTmp,"UQP_EMISSA",aTam[3], aTam[1], aTam[2])
	aTam := TamSX3("UQP_VALOR" ) ; TcSetField(cAliasTmp,"UQP_VALOR" ,aTam[3], aTam[1], aTam[2])

	//Define o email a que deve ser enviado o relatório
	//cEmail := (cAliasTmp)->UQD_CLIENT
	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))//A1_FILIAL + A1_COD + A1_LOJA
	SA1->(DbSeek(xFilial("SA1") + cCliente + cLoja/*cEmail*/))
	cEmail := AllTrim(SA1->A1_EMAIL)

	nPages := 0

	cObserv := UQO->UQO_OBS

	aRetObs := fPagObs2(cObserv)

	nRowDoc := fCorpo2( @oReport, cAliasTmp, cCliente, cLoja, cLiquidacao, dEmissao, dVencimento )

	//--------------------------------------------------------------------------
	// Imprime o Rodapé do Relatório
	//--------------------------------------------------------------------------
	fObs2(aRetObs, @nRowDoc)//nRowDoc DEVE ser passada como referência

	oReport:EndPage()

	nTotFrete	:= 0
	nTotIcms	:= 0
	nTotGeral	:= 0

	IIf(Select(cAliasTmp) > 0, (cAliasTmp)->(dbCloseArea()), Nil)

Return

Static Function fPagObs2(cObs)
	Local nPosObs 	:= 0
	Local nRet		:= 0

	nPosObs := (Len(cObs) / 85 * 10) + 600

	IF nPosObs >= 700 //Rodapé na mesma página
		nRet++
	EndIf
Return({nRet, cObs})

/*/{Protheus.doc} fCabecalho
Imprime o cabecalho da fatura.
@author Paulo Carvalho
@since 16/10/2018
@param oReport, object, Objeto TReport controlador do relatório.
@version 1.01
@type Static Function
/*/
Static Function fCabecalho( oReport, cLiquidacao, dEmissao, dVencimento )

	Local cBmpLogo		:= "\logotipos\logo_empresa.jpg" // FisxLogo("1")//"\system\logos\logo_veloce.jpg"

	// Variáveis de definição da empresa
	Local cEmpresa		:= SM0->M0_NOMECOM//"VELOCE LOGISTICA S.A"
	Local cEndereco		:= Capital(AllTrim(SM0->M0_ENDENT))//"Avenida Luigi Papaiz, 239 - Bloco Admin. 1º Piso"
	Local cBairro		:= AllTrim(Capital(SM0->M0_BAIRENT)) //"Jardim das Nações SP"
	Local cCidade		:= AllTrim(Capital(SM0->M0_CIDENT))  //"Diadema"
	Local cEstado		:= SM0->M0_ESTENT // "SP"
	Local cCep			:= fDefCep(SM0->M0_CEPENT)//"09931610"
	Local cCnpj			:= fDefCnpj(SM0->M0_CGC, "J")  //"102995670001-64"
	Local cInsEst		:= SM0->M0_INSC//fDefInsc(SM0->M0_INSC) //"286220274118"

	// Cria o primeiro box para os dados da empresa
	oReport:Box( 0050, 0050, 0175, 300)//( 0010, 0150, 0520, 1195)

	// Cria o segundo box para os dados da fatura
	oReport:Box( 0050, 0305, 0175, 0555)//( 0050, 1205, 0520, 2200)

	// Cria o objeto com a imagem passada via parâmetro
	oTImg := TBitmap():New(0070,0010,,,,cBmpLogo,,,,/*10*/,,,,,,,.T.,,)//(0070,0070,,,,cBmpLogo,,,,,,,,,,,,,)

	// Auto ajusta o tamanho, sem ele, é retornado 0
	oTImg:lAutoSize := .T.

	// Define altura
	nHeight := oTImg:nClientHeight	/ 4

	// Define largura
	nWidth := oTImg:nClientWidth	/4
	// Imprime o logo na página
	oReport:SayBitmap( 0060, 0100, cBmpLogo, nWidth, nHeight )

	// Imprime cabeçalho da Fatura
	oReport:Say( 0080, 412, CAT554009, oFont16 , ,CLR_BLACK) // "FATURA"

	// Escreve os dados da empresa e da fatura
	oReport:Say( 0115, 0055, cEmpresa, oFont14 , ,CLR_BLACK)

	oReport:Say( 00115, 0310, CAT554010, oFont10 , ,CLR_BLACK)	// "Número da fatura: "
	oReport:Say( 00115, 0430, cLiquidacao, oFont10 , ,CLR_BLACK)

	oReport:Say( 0125, 0055, cEndereco, oFont10 , ,CLR_BLACK)
	oReport:Say( 0135, 0055, cBairro + " " + cCidade + " - " + cEstado, oFont10 , ,CLR_BLACK)
	//oReport:Say( 0135, 0150, cCidade + " - " + cEstado, oFont10 ) //Comentado para evitar casos de um bairro ser muito longo
																	//e ficar por cima da cidade

	oReport:Say( 0135, 0310, CAT554011, oFont10 , ,CLR_BLACK	)// "Data de Emissão: "
	oReport:Say( 0135, 0430, DtoC(dEmissao), oFont10, ,CLR_BLACK)

	oReport:Say( 0145, 0055, cCep, oFont10 , ,CLR_BLACK			)

	oReport:Say( 0145, 0310, CAT554012, oFont10 , ,CLR_BLACK	)// "Data de Vencimento: "
	oReport:Say( 0145, 0430, DtoC(dVencimento), oFont10, ,CLR_BLACK)

	oReport:Say( 0155, 0055, CAT554013 + cCnpj, oFont10 , ,CLR_BLACK)// "CNPJ: "
	oReport:Say( 0165, 0055, CAT554014 + cInsEst, oFont10 , ,CLR_BLACK)// "INSCR. EST: "

Return

/*/{Protheus.doc} fCliente
Imprime os dados do cliente no relatório
@author Paulo Carvalho
@since 16/10/2018
@version 1.01
@type Static Function
/*/
Static Function fCliente( oReport )

	// Variáveis de definição do cliente
	Local aDadosCli		:= {"","","","","","","","",""}
	Local aCampos		:= {"A1_NOME","A1_END"  ,"A1_BAIRRO",;
							"A1_CEP" ,"A1_MUN"  ,"A1_EST"   ,;
							"A1_CGC" ,"A1_INSCR","A1_PESSOA" }
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
	oReport:Box( 0180, 0050, 0250, 0555)

	aDadosCli := GetAdvFVal("SA1", ;
						aCampos,;
						xFilial("SA1") + cCliente + cLoja,;
						1,;
						aDadosCli)

	// Define as informações do cliente
	cCliNom := aDadosCli[1]
	cCliEnd := Capital(aDadosCli[2])
	cCliBai := Capital(aDadosCli[3])
	cCliCep := aDadosCli[4]
	cCliCid := Capital(aDadosCli[5])
	cCliEst := aDadosCli[6]
	cCliCnp := Iif(!Empty(aDadosCli[7]),StrTran(Transform( aDadosCli[7], PicPes(aDadosCli[9])),"%C","")," ")
	cCliIns := aDadosCli[8]
	cCliPes := aDadosCli[9]

	// Imprime os dados do cliente
	oReport:Say( 0195, 0055, CAT554015 +  Upper( cCliNom ) , oFont10 , ,CLR_BLACK)		// "Cliente: "
	oReport:Say( 0205, 0055, AllTrim(AllTrim(cCliEnd) + " - " + AllTrim(cCliBai)), oFont10 , ,CLR_BLACK)

	oReport:Say( 0215, 0055, fDefCep(cCliCep) + " " +;
		AllTrim(cCliCid) + " " + AllTrim(cCliEst), oFont10 , ,CLR_BLACK	)

	oReport:Say( 0225, 0055, CAT554013 + fDefCnpj(cCliCnp, cCliPes), oFont10 , ,CLR_BLACK) //CNPJ
	oReport:Say( 0225, 0250, CAT554016 + /*fDefInsc(*/cCliIns/*)*/, oFont10 , ,CLR_BLACK) //Insc. Est.:

Return

/*/{Protheus.doc} fCorpo
Imprime o corpo do relatório contendo os documentos que compõem a fatura.
@author Paulo Carvalho
@since 17/10/2018
@version 1.01
@type Static Function
/*/
Static Function fCorpo2( oReport, cAliasTmp, cCliente, cLoja, cLiquidacao, dEmissao, dVencimento )
	Local aTit		:= {}
	Local cAux		:= ""
	Local cTmpAlias	:= GetNextAlias()

	Local nI		:= 0
	Local nTotDoc	:= 0
	Local nDocs		:= 0
	Local nJaImp	:= 0
	Local nTotPag	:= 0
	Local nDocMin	:= 21 //Documentos por página sem forçar as observações para a próxima pagina

	Private nDocPag := 33	// Documentos por página forçando as observações para a próxima pagina

	//-- Separa os Titulos NCC e NDC
	While !(cAliasTmp)->(EoF())

		If (cAliasTmp)->UQP_PFXFAT == "CTE" .Or.;
			(cAliasTmp)->UQP_PFXFAT == "CRT"

			//Alteração 30/09/2019 - Icaro
			//Para o caso de uma fatura ser gerada em uma filial usando titulos CTE integradas em outra

			cQuery := " SELECT UQD.UQD_NUMERO, UQD.UQD_INDICA "						+ CRLF
			cQuery += " FROM " + RetSQLName("UQD") + " UQD "  						+ CRLF
			cQuery += " WHERE UQD.UQD_PREFIX = '" + (cAliasTmp)->UQP_PFXFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_TITULO = '" + (cAliasTmp)->UQP_TITFAT + "' "	+ CRLF
			cQuery += "   AND UQD.UQD_PARCEL = '" + (cAliasTmp)->PARCORI + "' "		+ CRLF
			cQuery += "   AND UQD.UQD_TIPOTI = '" + (cAliasTmp)->UQP_TPFAT + "' "	+ CRLF
			cQuery += "   AND UQD.D_E_L_E_T_ <> '*' "

			MpSysOpenQuery(cQuery, cTmpAlias)

			If !(cTmpAlias)->(Eof())
			/*DbSelectArea("UQD")
			UQD->(DbSetOrder(5))	// UQD_FILIAL + UQD_PREFIX + UQD_TITULO + UQD_PARCEL + UQD_TIPOTI

			If UQD->(DbSeek(FWxFilial("UQD") + (cAliasTmp)->UQP_PFXFAT +;
				(cAliasTmp)->UQP_TITFAT + (cAliasTmp)->UQP_PARFAT +;
				(cAliasTmp)->UQP_TPFAT))*/

				cAux := Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, RAT("-", (cTmpAlias)->UQD_NUMERO) + 1, 2))//Alltrim(SubStr(UQD->UQD_NUMERO, RAT("-", UQD->UQD_NUMERO) + 1, 2))

				cDocumento := AllTrim((cTmpAlias)->UQD_INDICA) +;//AllTrim(UQD->UQD_INDICA) +;
							  Alltrim(SubStr((cTmpAlias)->UQD_NUMERO, 1, RAT("-", (cTmpAlias)->UQD_NUMERO) - 1 )) +;//Alltrim(SubStr(UQD->UQD_NUMERO, 1, RAT("-", UQD->UQD_NUMERO) - 1 )) +; //Ultima posição antes do traço
							  " - " + cAux


				Aadd(aTit, 	{							 			;
					cDocumento									    ,;
					(cAliasTmp)->UQP_EMISFA							,;
					(cAliasTmp)->UQP_TOTAL							,;
					(cAliasTmp)->UQP_ICMS							,;
					(cAliasTmp)->UQP_TOTAL + (cAliasTmp)->UQP_ICMS	;
					})
			Else
				cDocumento := AllTrim((cAliasTmp)->UQP_TITFAT) +;
				" - " +;
				AllTrim((cAliasTmp)->UQP_TPFAT)

				Aadd(aTit, 	{							 			;
					cDocumento									    ,;
					(cAliasTmp)->UQP_EMISFA							,;
					(cAliasTmp)->UQP_TOTAL							,;
					(cAliasTmp)->UQP_ICMS							,;
					(cAliasTmp)->UQP_TOTAL + (cAliasTmp)->UQP_ICMS	;
					})
			EndIf
		ElseIf AllTrim((cAliasTmp)->UQP_TPFAT) $ "NCC|RA" //NCC ou RA nunca será um CTE/CRT


			Aadd(aTit, 	{								 				 ;
						AllTrim((cAliasTmp)->UQP_TITFAT) + " - " + AllTrim((cAliasTmp)->UQP_TPFAT) ,;
						(cAliasTmp)->UQP_EMISSA							,;
						((cAliasTmp)->UQP_VALOR * - 1)					,;
						0												,;
						((cAliasTmp)->UQP_VALOR * - 1)	 				 ;
						})
		/*
		ElseIf (cAliasTmp)->UQP_TPFAT == "NDC"

			Aadd(aTit, 	{							 	 				 ;
						AllTrim((cAliasTmp)->UQP_TITFAT) + " - " + AllTrim((cAliasTmp)->UQP_TPFAT) ,;
						(cAliasTmp)->UQP_EMISSA							,;
						(cAliasTmp)->UQP_VALOR							,;
						0												,;
						(cAliasTmp)->UQP_VALOR 		 	 				 ;
						})
		*/
		Else

			Aadd(aTit, 	{							 					;
						AllTrim((cAliasTmp)->UQP_TITFAT) + " - " + AllTrim((cAliasTmp)->UQP_TPFAT) ,;
						(cAliasTmp)->UQP_EMISFA							,;
						(cAliasTmp)->UQP_TOTAL							,;
						(cAliasTmp)->UQP_ICMS							,;
						(cAliasTmp)->UQP_TOTAL + (cAliasTmp)->UQP_ICMS	;
						})

		EndIf

		(cAliasTmp)->(DbSkip())
	EndDo

	(cAliasTmp)->(DbCloseArea())

	// Imprime o cabeçalho dos documentos
	fCorCabec( @oReport )

	// Define quantos documentos compõem esta fatura (incluindo as Notas de Crédito) e o número de páginas que serão impressas
	nTotDoc := Len(aTit)

	nPages := Round( (nTotDoc / nDocPag), 0 )

	If (nTotDoc / nDocPag) > nPages  //Caso o arredondamento do total de paginas resulte seja para baixo
		nPages += 1
	EndIf

	nPagAtual := 1

	oReport:Say( 0165, 0430, CAT554017 + cValToChar(nPagAtual), oFont10 , ,CLR_BLACK) //Página

	nPagAtual++

	nRowDoc := 270

	If nTotDoc <= nDocMin

		For nI := 1 To Len(aTit)
			nRowDoc += 15

			nTotFrete += aTit[nI,3]
			nTotIcms  += aTit[nI,4]
			nTotGeral += aTit[nI,5]

			oReport:SayAlign( nRowDoc, 0055, aTit[nI,1]											, oFont10, 90, 05, CLR_BLACK , 0, 1 )
			oReport:SayAlign( nRowDoc, 0180, DToC(aTit[nI,2])									, oFont10, 90, 05, CLR_BLACK , 2, 1 )
			oReport:SayAlign( nRowDoc, 0265, Transform(aTit[nI,3], PesqPict("UQP", "UQP_VLRFAT")), oFont10, 90, 05, CLR_BLACK , 1, 1 )
			oReport:SayAlign( nRowDoc, 0355, Transform(aTit[nI,4], PesqPict("UQP", "UQP_ICMS"  )), oFont10, 90, 05, CLR_BLACK , 1, 1 )
			oReport:SayAlign( nRowDoc, 0460, Transform(aTit[nI,5], PesqPict("UQP", "UQP_VLRFAT")), oFont10, 90, 05, CLR_BLACK , 1, 1 )

		Next nI

		nRowDoc += 15

		//Imprime as boxes da página atual
		oReport:Line(0280, 0050, 0280, 0555) 	  //Linha horizontal superior (-)
		oReport:Line(0280, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
		oReport:Line(nRowDoc, 0050, nRowDoc, 0555)//linha horizontal inferior(-)
		oReport:Line(0280, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

		//linhas verticais intermediarias
		oReport:Line(0280, 0180, nRowDoc, 0180 )
		oReport:Line(0280, 0270, nRowDoc, 0270 )
		oReport:Line(0280, 0360, nRowDoc, 0360 )
		oReport:Line(0280, 0450, nRowDoc, 0450 )

	Else

		For nI := 1 To Len(aTit)
			nRowDoc += 15
			nDocs   += 1
			nJaImp++

			nTotFrete += aTit[nI,3]
			nTotIcms  += aTit[nI,4]
			nTotGeral += aTit[nI,5]

			// Se o Documento a ser impresso for maior do que limite por página
			If nDocs > nDocPag

				oReport:Line(0275, 0050, 0275, 0555) 	  //Linha horizontal superior (-)
				oReport:Line(0275, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
				oReport:Line(nRowDoc, 0050, nRowDoc, 0555)//linha horizontal inferior(-)
				oReport:Line(0275, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

				oReport:Line(0275, 0180, nRowDoc, 0180 )
				oReport:Line(0275, 0270, nRowDoc, 0270 )
				oReport:Line(0275, 0360, nRowDoc, 0360 )
				oReport:Line(0275, 0450, nRowDoc, 0450 )

				// Finalizo a página
				oReport:EndPage()

				// Inicio uma página nova
				oReport:StartPage()

				// Redefino a linha de impressão
				nRowDoc := 275

				// Redefino a quantidade de documentos impressos na página
				nDocs	:= 1

				// Imprimo o cabeçalho
				fCabecalho( @oReport, cLiquidacao, dEmissao, dVencimento )

				//Imprime o nº da página
				If (nTotDoc / nDocPag) > nPages  //Caso o arredondamento do total de paginas resulte seja para baixo
					nTotPag += 1
				EndIf
				//Imprime o número da página
				oReport:Say( 0165, 0430, CAT554017 + cValToChar(nPagAtual) , oFont10 , ,CLR_BLACK) //Página
				nPagAtual++

				// Imprimo os dados do cliente
				fCliente( @oReport )

				// Imprimo o cabeçalho do corpo do relatório
				fCorCabec( @oReport )
			EndIf

			oReport:SayAlign( nRowDoc, 0055, aTit[nI,1]											, oFont10, 90, 05, CLR_BLACK , 0, 1 )
			oReport:SayAlign( nRowDoc, 0180, DToC(aTit[nI,2])									, oFont10, 90, 05, CLR_BLACK , 2, 1 )
			oReport:SayAlign( nRowDoc, 0265, Transform(aTit[nI,3], PesqPict("UQP", "UQP_VLRFAT")), oFont10, 90, 05, CLR_BLACK , 1, 1 )
			oReport:SayAlign( nRowDoc, 0355, Transform(aTit[nI,4], PesqPict("UQP", "UQP_ICMS"  )), oFont10, 90, 05, CLR_BLACK , 1, 1 )
			oReport:SayAlign( nRowDoc, 0460, Transform(aTit[nI,5], PesqPict("UQP", "UQP_VLRFAT")), oFont10, 90, 05, CLR_BLACK , 1, 1 )
		Next nI

		nRowDoc += 15

		oReport:Line(0275, 0050, 0275, 0555) 	  //Linha horizontal superior (-)
		oReport:Line(0275, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
		oReport:Line(nRowDoc, 0050, nRowDoc, 0555)//linha horizontal inferior(-)
		oReport:Line(0275, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

		//linhas verticais intermediarias
		oReport:Line(0275, 0180, nRowDoc, 0180 )
		oReport:Line(0275, 0270, nRowDoc, 0270 )
		oReport:Line(0275, 0360, nRowDoc, 0360 )
		oReport:Line(0275, 0450, nRowDoc, 0450 )
	EndIf

Return nRowDoc

/*/{Protheus.doc} fNCC
Busca Notas de Crédito do cliente informado para subtrair do valor do relatório
@author Kevin Willians
@since 10/01/2019
@param cCliente, characters, Cliente a ser pesquisado
@type function
/*/
Static Function fNCC()
	Local aArea 		:= GetArea()
	Local aRet			:= {}

	Local cQuery		:= ""
	Local cTemp			:= GetNextAlias()

	cQuery += "SELECT E1_NUM, E1_PREFIXO, E1_VALOR, E1_TIPO, E1_EMISSAO "	+ CRLF
	cQuery += "  FROM " + RetSQLName("SE1")									+ CRLF
	cQuery += " WHERE E1_TIPO = 'NCC'"										+ CRLF
	cQuery += "   AND E1_CLIENTE = '" + cCliente + "'"						+ CRLF
	cQuery += "   AND E1_LOJA = '" + cLoja + "'"							+ CRLF
	cQuery += "   AND E1_SALDO > 0"											+ CRLF
	cQuery += "   AND D_E_L_E_T_ <> '*' "									+ CRLF

	MPSysOpenQuery( cQuery, cTemp )

	While !(cTemp)->(Eof())
		aAdd(aRet, {(cTemp)->E1_NUM, (cTemp)->E1_PREFIXO, (cTemp)->E1_VALOR, (cTemp)->E1_EMISSAO })
		(cTemp)->(dbSkip())
	EndDo

	IIf(Select(cTemp) > 0, (cTemp)->(dbCloseArea()), Nil)

	RestArea(aArea)
Return aRet

/*/{Protheus.doc} fCorCabec
Imprime o cabeçalho do corpo do relatório.
@author Paulo Carvalho
@since 17/10/2018
@version 1.01
@type Static Function
/*/
Static Function fCorCabec( oReport )

	oReport:Box( 0255, 0050, 0275, 0555)

	oReport:Say( 0270, 0055, Upper(CAT554018), oFont10 , ,CLR_BLACK	)	// "Nº DOCUMENTO"
	oReport:Say( 0270, 0205, Upper(CAT554019), oFont10 , ,CLR_BLACK	)	// "EMISSÃO"
	oReport:Say( 0270, 0305, Upper(CAT554020), oFont10 , ,CLR_BLACK	)	// "FRETE"
	oReport:Say( 0270, 0395, Upper(CAT554021), oFont10 , ,CLR_BLACK	)	// "ICMS"
	oReport:Say( 0270, 0495, Upper(CAT554022), oFont10 , ,CLR_BLACK	)	// "TOTAL"

Return

/*/{Protheus.doc} fObs
//Gera o box de observações
@author Kevin Willians
@since 11/01/2019
@version undefined
@param aObs, Array, {numero de pags a mais, Observação informada no TGet}
@param cPre, characters, Prefixo do Titulo
@param cTit, characters, Numero do Titulo
@return nPosObs, numerico, posição linha final do box de obs
@type function
/*/
Static Function fObs2(aObs, nRowDoc)
	Local cAux			:= ""
	Local nI			:= 1
	Local nLinNewPag	:= 0
	Local nPosObs		:= 0	//Tamanho da Box de Obs
	Local nRowBkp		:= nRowDoc

	nRowDoc += 15

	oReport:Say( nRowDoc, 0060, CAT554024, oFont10 , ,CLR_BLACK	)	// "Observação: "

	nRowDoc += 10

	For nI := 1 to MlCount(aObs[2], 85)
		cAux := MemoLine( AllTrim(aObs[2]), 85, nI)

		oReport:Say( nRowDoc, 60, cAux, oFont10 , ,CLR_BLACK	)
		nRowDoc += 10

		nLinNewPag := nI

		If nRowDoc >= 770
			nLinNewPag++
			Exit
		EndIf
	Next

	oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior (-)
	oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
	oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
	oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

	// Gera a próxima página
	lContinua := .T.
	Do While lContinua
		If nRowDoc >= 770 .And. MlCount(aObs[2], 85) >= nLinNewPag
			nRowDoc := 255
			nRowBkp := 255

			oReport:EndPage()
			oReport:StartPage()

			fCabecalho( @oReport, cLiquidacao, dEmissao, dVencimento )
			fCliente( @oReport)
			//Imprime o número da página
			oReport:Say( 0165, 0430, CAT554017 + cValToChar(nPages + aObs[1]), oFont10 , ,CLR_BLACK	) //Página

			If Len(aObs[2]) > 0
				nRowDoc += 10
				For nI := nLinNewPag to MlCount(aObs[2], 85)
					cAux := MemoLine( AllTrim(aObs[2]), 85, nI)

					oReport:Say( nRowDoc, 60, cAux, oFont10 , ,CLR_BLACK	)
					nRowDoc += 10

					//Quando estourar quantidade de linhas na pagina atual, gera outra pagina
					If nRowDoc >= 770
						nLinNewPage := nI

						Exit
					EndIf
				Next

				oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior (-)
				oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
				oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
				oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)
			EndIf
		Else
			lContinua := .F.
		EndIf
	EndDo
	fRodape( @oReport, nRowDoc)

Return(nPosObs)

/*/{Protheus.doc} fRodape
Imprime as informações de rodapé da fatura
@author Paulo Carvalho
@since 16/10/2018
@version 1.01
@type Static Function
/*/
Static Function fRodape( oReport, nRowDoc)
	Local cAux		:= ""
	Local cFrete	:= ""
	Local cIcms		:= ""
	Local cTotal	:= ""
	Local cValExten	:= ""
	Local nI		:= ""
	Local nRowBkp	:= nRowDoc//+5 para dar um espaço em relação ao box de Observação

	nRowDoc += 12

	cFrete	:= Transform( nTotFrete	, PesqPict("UQP", "UQP_VLRFAT") )
	cIcms	:= Transform( nTotIcms	, PesqPict("UQP", "UQP_ICMS"  ) )
	cTotal	:= Transform( nTotGeral	, PesqPict("UQP", "UQP_TOTAL" ) )

	oReport:Say( nRowDoc, 0065, CAT554022, oFont10 , ,CLR_BLACK	) // Total
	oReport:Say( nRowDoc, 0285, cFrete	 , oFont10 , ,CLR_BLACK	)
	oReport:Say( nRowDoc, 0375, cIcms	 , oFont10 , ,CLR_BLACK	)
	oReport:Say( nRowDoc, 0465, cTotal	 , oFont10 , ,CLR_BLACK	)

	nRowDoc += 3

	// Cria o box para o total geral
	oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior(-)
	oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
	oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
	oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

	//nRowDoc += 3

	nRowBkp := nRowDoc
	nRowDoc += 10

	// Cria Boxes complementares
	oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior(-)
	oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
	oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
	oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

	nRowBkp := nRowDoc
	nRowDoc += 10

	oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior(-)
	oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
	oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
	oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)

	// Valor por extenso
	nRowBkp := nRowDoc
	nRowDoc += 10

	oReport:Say( nRowDoc, 0065, CAT554023, oFont10 , ,CLR_BLACK	) // Valor por extenso
	cValExten := Capital(Extenso(nTotGeral))
	If Len(cValExten) > 56

		For nI := 1 to MlCount(cValExten, 56)
			cAux := MemoLine( AllTrim(cValExten), 56, nI)

			oReport:Say( nRowDoc, 0220, cAux, oFont10 , ,CLR_BLACK	)
			nRowDoc += 10
		Next

	Else

		oReport:Say( nRowDoc, 0220, cValExten, oFont10 , ,CLR_BLACK	)

		nRowDoc += 10

	EndIf

	oReport:Line(nRowBkp, 0050, nRowBkp, 0555) 	  //Linha horizontal superior(-)
	oReport:Line(nRowBkp, 0555, nRowDoc, 0555)	  //linha vertical direita(|)
	oReport:Line(nRowDoc, 0050, nRowDoc, 0555)	  //linha horizontal inferior(-)
	oReport:Line(nRowBkp, 0050, nRowDoc, 0050)	  //linha vertical esquerda(|)
	oReport:Line(nRowBkp, 0210, nRowDoc, 0210)    //linha intermediaria vertical(|)

Return


/*/{Protheus.doc} fEmail
Prepara e-mail para envio.
@author Paulo Carvalho
@since 22/10/2018
@version 0.01
@return lRet, Lógico, indica se houve erro na geração e envio do email
@type Static Function
/*/
Static Function fEmail( cFile )

	Local cCopia		:= ""
	Local cUsersPara	:= ""
	Local cAssunto		:= ""
	Local cMsg			:= ""

	Local lMultipFat	:= IsInCallStack("fMultipFat")

	Local lRet			:= .T.

	If lMultipFat
		cUsersPara	:= Lower(c518Email)						// A1_EMAIL Lower("paulo.carvalho@aceex.com.br")  //SuperGetMv("TR_CTTMAIL", .F., "")
		cAssunto	:= CAT555004 + c518Faturas				// Faturamento referente a FT
	Else
		cUsersPara	:= Lower(cEmail)						// A1_EMAIL Lower("paulo.carvalho@aceex.com.br")  //SuperGetMv("TR_CTTMAIL", .F., "")
		cAssunto	:= CAT555004 + AllTrim(cLiquidacao)		// Faturamento referente a FT
	EndIf

	cMsg 	+= CAT555002 // "Prezado(a), segue em anexo a fatura selecionada no Protheus."

	cAnexo	:= cFile
	cCopia	:= SuperGetMV("PLG_EMAILC", .F., "")

	lRet 	:= fEnviar( cUsersPara, cAssunto, cMsg, cCopia, cFile )

Return lRet

/*/{Protheus.doc} fEnviar
Envia e-mail para envio.
@author Paulo Carvalho
@since 22/10/2018
@version 0.01
@return lRet, lógico, indica se houve erro na geração e envio do email
@type Static Function
/*/
Static Function fEnviar( cUsersPara, cAssunto, cCorpo, cCopia, cAnexo )

	Local cBody		:= ""
	Local cExecute	:= ""
	Local cTempPath := "C:\temp"

	Local lRet		:= .T.

	Local nPosRat 	:= 0

	nPosRat := Rat("\", cAnexo)	//Obtenho a posição de inicio do nome do arquivo(Da esquerda para direita)
	cAnexo := cTempPath + "\" + Right(cAnexo,Len(cAnexo) - nPosRat ) //A função right obtem o texto da direita para esquerda
																	 //por isso a subtração de nPosRat
	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))//A1_FILIAL + A1_COD + A1_LOJA
	If SA1->(DbSeek(xFilial("SA1") + cCliente + cLoja))
		cBody := SA1->A1_XCORPO
	EndIf

	// Valida se a mensagem do cadastro do cliente está vazia
	If Empty(cBody)
		cBody := cCorpo
	EndIf

    //Se tiver email, abre o outlook
    If !Empty(Alltrim(cUsersPara))
    	//É OBRIGATÓRIO o uso de aspas simples na variavel cExecute abaixo,pois o email após o /m DEVE usar aspas duplas
    	cExecute := '/a ' + cAnexo  +' /c ipm.note /m "' + Alltrim(cUsersPara) + '?cc=' + cCopia + '&subject=' + cAssunto + '&body=' + cBody + '"'//
        ShellExecute("OPEN", "outlook.exe", cExecute, "", 1)
    Else
    	lRet := .F.
    	MsgAlert(CAT555005, "") //"Cliente sem e-mail cadastrado."
    EndIf

Return lRet

/*/{Protheus.doc} fDefCep
Insere máscara de cep no cep passado.
@author Paulo Carvalho
@since 16/04/2019
@param cCep, carácter, Cep a ser mascarado.
@type function
/*/
Static Function fDefCep(cCep)

	Local cCepMask	:= ""

	If !Empty(cCep)
		// Retira pontos, traços e barras do cep
		cCep := StrTran(cCep, ".", "")
		cCep := StrTran(cCep, "-", "")
		cCep := StrTran(cCep, "/", "")

		// Mascara o cep para retornar à chamada
		cCepMask := Transform(cCep, "@R 99999-999")
	EndIf

Return cCepMask

/*/{Protheus.doc} fDefCnpj
Insere máscara de cnpj/cpf no cnpj/cpf passado.
@author Paulo Carvalho
@since 16/04/2019
@param cCnpj, carácter, CNPJ/CPF a ser mascarado.
@type function
/*/
Static Function fDefCnpj(cCnpj, cTipoPessoa)

	Local cCnpjMask	:= ""

	If !Empty(cCnpj)
		// Retira pontos, traços e barras no cpnj
		cCnpj := StrTran(cCnpj, ".", "")
		cCnpj := StrTran(cCnpj, "-", "")
		cCnpj := StrTran(cCnpj, "/", "")

		// Mascara o cnpj para retornar à chamada
		If "F" $ cTipoPessoa
			cCnpjMask := Transform(cCnpj, "@R 999.999.999-99")
		ElseIf "J" $ cTipoPessoa
			cCnpjMask := Transform(cCnpj, "@R 99.999.999/9999-99")
		EndIf
	EndIf

Return cCnpjMask

/*/{Protheus.doc} fDefInsc
Insere máscara de inscrição estadual na inscrição passada.
@author Paulo Carvalho
@since 16/04/2019
@param cInscricao, carácter, Inscrição estadual a ser mascarada.
@type function
/*/
Static Function fDefInsc(cInscricao)

	Local cInscMask	:= ""

	If !Empty(cInscricao)
		// Retira pontos, traços e barras na inscrição
		cInscricao := StrTran(cInscricao, ".", "")
		cInscricao := StrTran(cInscricao, "-", "")
		cInscricao := StrTran(cInscricao, "/", "")

		// Mascara a incrição para retornar à chamada
		cInscMask := Transform(cInscricao, "@R 999.999.999.999")
	EndIf

Return cInscMask

#Include 'Totvs.ch'
#Include 'CATTMS.ch'
#Include 'FileIO.ch'

Static NomePrt		:= "PRT0527"
Static VersaoJedi	:= "V1.34"

/*/{Protheus.doc} PRT0527
Importação de arquivos CTRB, CTE e CRT.
@author Paulo Carvalho / Juliano Fernandes
@since 18/12/2018
@version 1.03
@type User Function
/*/

User Function PRT0527(aParams)

	Local aAllFiles		:= {}
	Local aArqProc		:= {}
	Local aRetImpo		:= {}
	Local aNaoImport	:= {}
	Local cEmpBkp		:= ""
	Local cFilBkp		:= ""
	Local cErro			:= ""
	Local cTextoLog		:= ""
	Local lPrepareEnv	:= .F.
	Local lOk			:= .T.
	Local lEnvMail		:= .F.
	Local lIntCTECRT	:= .F.
	Local lIntCTRB		:= .F.
	Local nI,i			:= 0
	Local nHandle		:= 0
	Local aDados		:= {}
	Local aParamBox		:= {}
	Local lPercOk		:= .F.
	Local cAxCnpj		:= ""
	Local aRet			:= {}

	Private aFilDepara	:= {}
	Private aEmpProc	:= {}
	Private cTitulo		:= NomePrt + CAT527001 + VersaoJedi	// " - VersãoJedi: "
	Private cIdSched	:= ""
	Private cUserSched	:= "Schedule" // Usuário que será gravado nos campos UQF_USER e UQJ_USER ao executar via Schedule
	Private l527Auto 	:= .F.
	Private aFilsProc	:= FWLoadSM0()
	Private cEmpDe		:= space(Len(cFilAnt))
	Private cEmpAte		:= space(Len(cFilAnt))
	Private dDataD		:= Ctod("//")
	Private dDataA		:= Ctod("//")
	Private cAxProd	    := space(TamSx3("B1_COD")[1])
	Private cAxNat		:= space(TamSx3("ED_CODIGO")[1])

	cIdSched	:= DToS(Date()) + Replace(Time(),":","")

	Default aParams		:= {.F.}

	//-- Define se é um processamento automatico (Via Schedule)
	l527Auto := aParams[1]

	If !l527Auto
		aEmpProc := FWAllGrpCompany()

		aAdd(aParamBox ,{1,"Empresa De"	,cEmpDe		,"@!","","XM0"	,""	,50,.T.})
		aAdd(aParamBox ,{1,"Empresa Ate",cEmpAte	,"@!","","XM0"	,""	,50,.T.})
		aAdd(aParamBox ,{1,"Data De"	,dDataD		,"","",""	,""	,50,.T.})
		aAdd(aParamBox ,{1,"Data Ate"	,dDataA		,"","",""	,""	,50,.T.})
		aAdd(aParamBox ,{1,"Produto"	,cAxProd	,"",'ExistCpo("SB1")',"SB1"	,""	,50,.T.})
		aAdd(aParamBox ,{1,"Natureza"	,cAxNat		,"",'ExistCpo("SED")',"SED"	,""	,50,.T.})

		If ParamBox(aParamBox,"Parametros",@aRet)
			cEmpDe  := aRet[1]
			cEmpAte := aRet[2]
			dDataD  := aRet[3]
			dDataA  := aRet[4]
			cAxProd := aRet[5]
			cAxNat  := aRet[6]
			lPercOk := .T.
		Endif

	EndIf

	If l527Auto
		If Select("SX2") == 0
			If !fPrepEnv(@cErro, aParams[2], aParams[3])
				lOk := .F.
				ConOut(cErro)
			Else
				lPrepareEnv := .T.
			EndIf
		EndIf

		aEmpProc	:= FWAllGrpCompany()

		cEmpBkp		:= cEmpAnt
		cFilBkp		:= cFilAnt

		//cDirCTE		:= AllTrim(SuperGetMV("PLG_DIRCTE" , .F., ""))
		//cDirCRT		:= AllTrim(SuperGetMV("PLG_DIRCRT" , .F., ""))
		//cDirCTRB	:= AllTrim(SuperGetMV("PLG_DIRCTR" , .F., ""))

		aFilDepara	:= fGetFilVel()

		fLogSched(1, @nHandle)

		cTextoLog := "" ; ConOut(cTextoLog)
		cTextoLog := Replicate("-", 75) ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
		cTextoLog := "Schedule: " + cTitulo ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
		cTextoLog := "Schedule: " + NomePrt + " - ID Schedule: " + cIdSched ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
		cTextoLog := "Schedule: " + NomePrt + CAT527004 + DToC(Date()) + " " + Time() ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Iniciando execucao: "

		aAllFiles := Array(3)

		/*If fVldDiret(cDirCTE, "PLG_DIRCTE")
			cTextoLog := "Schedule: " + NomePrt + CAT527007 + cDirCTE ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) 	//" - Buscando arquivos do diretorio: "

			If Right(cDirCTE, 1) != cBarra
				cDirCTE += cBarra
			EndIf

			aFiles := Directory(cDirCTE + "*.txt")

			// Ordena o Array por Arquivo (Array multidimensional) - Crescente
			ASort(aFiles,,, {|x,y| x[1] < y[1]})

			fOrdArq(@aFiles)

			If !Empty(aFiles)
				AEval(aFiles, {|aFile| aFile[1] := cDirCTE + aFile[1]})
			EndIf

			aAux := AClone(aFiles)

			aAllFiles[1] := {}
			AEVal(aAux, {|x| Aadd(aAllFiles[1], x)})
		EndIf

		If fVldDiret(cDirCRT, "PLG_DIRCRT")
			cTextoLog := "Schedule: " + NomePrt + CAT527010 + cDirCRT ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)	//" - Buscando arquivos do diretorio: "

			If Right(cDirCRT, 1) != cBarra
				cDirCRT += cBarra
			EndIf

			aFiles := Directory(cDirCRT + "*.txt")

			// Ordena o Array por Arquivo (Array multidimensional) - Crescente
			ASort(aFiles,,, {|x,y| x[1] < y[1]})

			fOrdArq(@aFiles)

			If !Empty(aFiles)
				AEval(aFiles, {|aFile| aFile[1] := cDirCRT + aFile[1]})
			EndIf

			aAux := AClone(aFiles)

			aAllFiles[2] := {}
			AEVal(aAux, {|x| Aadd(aAllFiles[2], x)})
		EndIf

		If fVldDiret(cDirCTRB, "PLG_DIRCTR")
			cTextoLog := "Schedule: " + NomePrt + CAT527010 + cDirCTRB ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)	//" - Buscando arquivos do diretorio: "

			If Right(cDirCTRB, 1) != cBarra
				cDirCTRB += cBarra
			EndIf

			aFiles := Directory(cDirCTRB + "*.txt")

			// Ordena o Array por Arquivo (Array multidimensional) - Crescente
			ASort(aFiles,,, {|x,y| x[1] < y[1]})

			fOrdArq(@aFiles)

			If !Empty(aFiles)
				AEval(aFiles, {|aFile| aFile[1] := cDirCTRB + aFile[1]})
			EndIf

			aAux := AClone(aFiles)

			aAllFiles[3] := {}
			AEVal(aAux, {|x| Aadd(aAllFiles[3], x)})
		EndIf
		*/

		If nHandle > 0
			fLogSched(4, nHandle)
		EndIf

		For nI := 1 To Len(aEmpProc)
			aRetImpo := StartJob("U_f527Impo", GetEnvServer(), .T., aEmpProc[nI], "01", cIdSched, cUserSched, aAllFiles, lEnvMail, lIntCTECRT, lIntCTRB, aArqProc, aFilDepara, aNaoImport)

			// --------------------------------------------------------------------
			// Atualiza variáveis de controle a cada chamada da função f527Impo
			// --------------------------------------------------------------------
			If Len(aRetImpo) == 5
				lEnvMail	:= aRetImpo[1]
				lIntCTECRT	:= aRetImpo[2]
				lIntCTRB	:= aRetImpo[3]
				aArqProc	:= aRetImpo[4]
				aNaoImport	:= aRetImpo[5]
			EndIf
		Next nI

		If nHandle > 0
			fLogSched(3, @nHandle)
		EndIf

		// -----------------------------------------------------------------------
		// Ajusta os itens que não foram importados devido à problemas de
		// filial não localizada na tabela UQK.
		// -----------------------------------------------------------------------
		//fAjuNaoImp(aNaoImport)

		//-- Move os arquivos processados
		*//AEval(aArqProc, {|aArq| __CopyFile(aArq[1], aArq[2]), fErase(aArq[1])})

		//-- Realiza a integração dos registros importados com sucesso
		If lIntCTECRT .Or. lIntCTRB
			cTextoLog := "Schedule: " + NomePrt + CAT527012 ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)	// " - Processando integracao dos registros"

			AEval(aEmpProc, {|cEmp| StartJob("U_f527Inte", GetEnvServer(), .T., cEmp, "01", lIntCTECRT, lIntCTRB, cIdSched, cUserSched)})
		EndIf

		fAltEmpFil(cEmpBkp, cFilBkp)

		//-- Envia e-mail contendo as importações e integrações com erro
		// Comentado em 13/08/2019 por Juliano Fernandes para que seja enviado por e-mail as pendencias de integração
//		If lEnvMail
			cTextoLog := "Schedule: " + NomePrt + CAT527013 ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)	//" - Preparando envio de email"

			//fEnvMail(cDirCTE, cDirCRT, cDirCTRB, nHandle)
//		EndIf

		cTextoLog := "Schedule: " + NomePrt + " - ID Schedule: " + cIdSched ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
		cTextoLog := "Schedule: " + NomePrt + CAT527014 + DToC(Date()) + " " + Time() ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Execucao finalizada: "
		cTextoLog := Replicate("-", 75) ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
		cTextoLog := "" ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)

		If nHandle > 0
			fLogSched(4, nHandle)
		EndIf

		If lPrepareEnv
			RpcClearEnv()
		EndIf
	Else
		cEmpBkp	:= cEmpAnt
		cFilBkp := cFilAnt

		aFilDepara	:= fGetFilVel()

		If lPercOk
			For i := 1 to Len(aFilsProc)
				If aFilsProc[i][2] >= cEmpDe .and. aFilsProc[i][2] <= cEmpAte
			 		cAxCnpj := aFilsProc[i][18]
					aDados := intApi(cAxCnpj) //chama rotina de integração com a api atua
					fProc527(aDados)
				Endif
			Next i
		Endif

		fAltEmpFil(cEmpBkp, cFilBkp)

	EndIf

Return(Nil)

/*/{Protheus.doc} fVldDiret
Validação do diretório. Utilizado somente em modo automático (Via Schedule).
@author Juliano Fernandes
@since 07/02/2019
@version 1.01
@type Function
/*/
Static Function fVldDiret(cDiretorio, cParam)
	Local cMsgErro	:= ""
	Local lValid 	:= .T.

	If Empty(cDiretorio)
		lValid := .F.
		cMsgErro := CAT527015 + CRLF	//"Diretório de importação não cadastrado."
		cMsgErro += CAT527016 + cParam	//"Parâmetro: "
	EndIf

	If lValid
		If !ExistDir(cDiretorio)
			lValid := .F.
			cMsgErro := CAT527017 + CRLF	//"Diretório inválido."
			cMsgErro += CAT527016 + cParam	//"Parâmetro: "
		EndIf
	EndIf

	If !lValid
		ConOut(cMsgErro)
	EndIf
Return(lValid)

/*/{Protheus.doc} fProc527
Importação de arquivos CTRB, CTE e CRT.
@author Paulo Carvalho
@since 18/12/2018
@version 1.01
@type Function
/*/
Static Function fProc527(aDados)

	Local aArea			:= GetArea()

	Private aNaoImpFil	:= {}

	Private cAcao		:= ""	// Determina a ação que deve ser executada. C = Cancelamento, I = Inclusão
	Private cCadastro	:= CAT527018 // "Importação de arquivos"
	Private cArquivo	:= ""
	Private cTipoArq	:= ""
	Private cTitulo		:= NomePrt + CAT527019 + VersaoJedi // " - Importação de arquivos CTRB, CTE e CRT - "

	Private lCancela	:= .F.

	// Verifica o tipo de arquivo para realizar o processamento correspondente.
	If "CTRB" $ cTipoArq 		// Arquivo CTRB de pagamento
		Processa( {|| U_PRT0543( aDados ) }, CAT527020, CAT527021 ) // #"Importando Arquivo CTRB" #"Importando..."
	Else						// Arquivo CTE/CRT de recebimento
		Processa( {|| U_PRT0542( aDados ) }, CAT527022, CAT527021 ) //#"Importando Arquivo CTE/CRT" #"Importando..."
	Endif

	RestArea(aArea)

Return(Nil)

/*/{Protheus.doc} fArquivo
Cria a tela para escolha do arquivo de importação.
@author Paulo Carvalho
@since 17/10/2018
@version 1.01
@type Static Function
/*/
Static Function fArquivo()

	Local aAdvSize		:= {}
	Local aRetorno		:= {}
	Local aButtons		:= {}

	Local lRet			:= .F.
	Local lPixel		:= .T.
	Local lSalvar		:= .T.
	Local lHasOk		:= .T.

	Local oDialog		:= Nil
	Local oSArquivo		:= Nil
	Local oGArquivo		:= Nil
	Local oBtnImport	:= Nil

	Private cArquivo	:= ""
	Private cTipoArq	:= ""

	CursorWait()

	aAdvSize	:= MSAdvSize( .T. )

	If FindFunction( "MPDicInDB" ) .AND. MPDicInDB()//Caso lobo guara
		oDialog 	:= MsDialog():New( 1, 1, 130, 530, cTitulo, , , , /*cStyle*/, , , , GetWndDefault(), lPixel, , , , .F. )

		oSArquivo	:= TSay():New( 035, 010, { || CAT527023 }, oDialog, , , , , , lPixel, , , 100, 010 ) // "Escolha o arquivo para Importação"
		oGArquivo	:= TGet():New( 043, 010, { || cArquivo }, oDialog, 235, 010, , {|| .T.}, , , , , , .T., , , {|| .F.}, , , , .F., , , , , , , lPixel )
		oBtnImport	:= TButton():New( 043, 245, "...", oDialog, { || cArquivo := cGetFile(CAT527024, CAT527025, , ; //#"Arquivo TXT (*.txt) | *.txt | Arquivo DAT (*.dat) | *.dat" #"Selecione o arquivo TXT ou DAT"
								  IIf( IsSrvUnix(), "/SPOOL/", "\SPOOL\" ), lSalvar, GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE );
								  }, 012, 012, , , , lPixel, , , , {|| .T. }, , )

		oGArquivo:SetFocus()
	Else
		oDialog 	:= MsDialog():New( 1, 1, 130, 520, cTitulo, , , , /*cStyle*/, , , , GetWndDefault(), lPixel, , , , .F. )

		oSArquivo	:= TSay():New( 035, 010, { || CAT527023 }, oDialog, , , , , , lPixel, , , 100, 010 ) // "Escolha o arquivo para Importação"
		oGArquivo	:= TGet():New( 043, 010, { || cArquivo }, oDialog, 235, 010, , {|| .T.}, , , , , , .T., , , {|| .F.}, , , , .F., , , , , , , lPixel )
		oBtnImport	:= TButton():New( 043, 245, "...", oDialog, { || cArquivo := cGetFile(CAT527024, CAT527025, , ; //#"Arquivo TXT (*.txt) | *.txt | Arquivo DAT (*.dat) | *.dat" #"Selecione o arquivo TXT ou DAT"
								  IIf( IsSrvUnix(), "/SPOOL/", "\SPOOL\" ), lSalvar, GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE );
								  }, 012, 012, , , , lPixel, , , , {|| .T. }, , )

		oGArquivo:SetFocus()
	EndIf

	Aadd( aButtons, {CAT527026, { || U_PRT0533( Nil, Nil, "FAT") } , CAT527026, CAT527026, {|| .T.}} ) // #"Log de Importações" #"Log de Importações" #"Log de Importações"

	oDialog:bInit := {|| EnchoiceBar(oDialog, {|| lRet := fValArq(), If( lRet, oDialog:End(), Nil ) }, { || lRet := .F., oDialog:End() } ,, @aButtons, , , .F. , .F. , .F. , lHasOk := .T. , .F., ) }
	oDialog:Activate(,,, .T., {|| .T.},,,,)

	CursorArrow()

	If !lRet
		cArquivo := ""
	EndIf

	Aadd( aRetorno, lRet )
	Aadd( aRetorno, cArquivo )
	Aadd( aRetorno, cTipoArq )

Return AClone( aRetorno )

/*/{Protheus.doc} fValArq
Realiza a validação do arquivo escolhido para importação.
@author Paulo Carvalho
@since 26/12/2018
@return lRet, lógico, Retorna true se o arquivo é valido para importação e falso caso não o seja.
@version 1.01
@type Static Function
/*/
Static Function fValArq()

	Local lRet	:= .T.

	// Valida se foi escolhido algum arquivo.
	If Empty( cArquivo )
		lRet := .F.
		MsgAlert( CAT527027, cTitulo ) //#"Nenhum arquivo selecionado! Selecione um arquivo para realizar a importação."
	// Valida se o nome do arquivo está de acordo com o padrão.
	ElseIf !fVldNomArq()
		lRet := .F.
		MsgAlert( CAT527028, cTitulo ) //#"O nome do arquivo não está dentro do padrão necessário para importação."
	// Valida se existe conteúdo do arquivo escolhido.
	ElseIf fEmptyArq()
		lRet := .F.
		MsgAlert( CAT527029, cTitulo ) // #"O arquivo selecionado está vázio. Selecione um arquivo que contenha os dados necessários para importação."
	// Valida, por meio do conteúdo, se o arquivo é do tipo escolhido pelo usuário.
	ElseIf fTipoArq() == "ERRO"
		lRet := .F.
		MsgAlert( CAT527030, cTitulo ) //#"O conteúdo do arquivo não é compativel para importação."
	EndIf

Return lRet

/*/{Protheus.doc} fVldNomArq
Valida se o nome do arquivo está dentro do padrão necessário para importação.
@author Paulo Carvalho
@since 04/01/2019
@return lRet, lógico, Retorna true se o arquivo contém dados e falso se estiver vázio.
@version 1.01
@type Static Function
/*/
Static Function fVldNomArq()

	Local cNome		:= SubStr( cArquivo, -6, 2 )
	Local cTpArq	:= fTipoArq()
	Local lRet		:= .T.

	If cTpArq <> "PAGTOS" .And. cNome <> "01" .And. cNome <> "02"
		lRet := .F.
	EndIf

Return lRet

/*/{Protheus.doc} fEmptyArq
Valida se o arquivo contém algum conteúdo ou não.
@author Paulo Carvalho
@since 26/12/2018
@return lRet, lógico, Retorna true se o arquivo contém dados e falso se estiver vázio.
@version 1.01
@type Static Function
/*/
Static Function fEmptyArq()

	Local lRet		:= .T.
	Local nSize		:= 0

	// Instancia o objeto FileReader
	Local oFile	:= FWFileReader():New( cArquivo, CRLF )

	// Captura o tamanho do arquivo
	nSize := oFile:GetFileSize()

	// Se o arquivo for vazio.
	If Vazio( nSize )
		lRet := .F.
	EndIf

	// Fecha o arquivo
	oFile:Close()

Return lRet

/*/{Protheus.doc} fTipoArq
Determina o tipo de arquivo que está sendo importado.
@author Paulo Carvalho
@since 08/01/2019
@return cTipo, caracter, tipo do arquivo que está sendo importado.
@version 1.01
@type Static Function
/*/
Static Function fTipoArq()

	Local cLinha	:= ""
	Local cMensagem	:= ""
	Local lRet		:= .T.

	Local nHandle	:= 0

    //+---------------------------------------------------------------------+
	//| Valida o arquivo para processamento									|
    //+---------------------------------------------------------------------+
	If !File( cArquivo )
		lRet := .F.
		MsgStop( CAT527031, cTitulo ) // "Arquivo inválido para esta operação."
	EndIf

	If lRet
        //+---------------------------------------------------------------------+
        //| Abertura do arquivo texto                                           |
        //+---------------------------------------------------------------------+
		nHandle := fOpen( cArquivo )

        //+---------------------------------------------------------------------+
		//| Verifica se o arquivo se encontrar aberto pelo usuário				|
        //+---------------------------------------------------------------------+
		If nHandle == -1
			If fError() == 516
				Alert( CAT527032 ) // "Feche o arquivo para continuar o processamento."
			EndIf
		EndIf

        //+---------------------------------------------------------------------+
        //| Verifica se foi possível abrir o arquivo                            |
        //+---------------------------------------------------------------------+
        If nHandle == -1
        	lRet := .F.
        	cMensagem := CAT527033 + cArquivo + CAT527034 // #"O arquivo ", #" não pode ser aberto! Verifique o local onde o arquivo está armazenado."

        	MsgAlert( cMensagem, cTitulo )
        EndIf

		If lRet
			//+---------------------------------------------------------------------+
	        //| Posiciona no Inicio do Arquivo                                      |
	        //+---------------------------------------------------------------------+
			fSeek( nHandle, 0, 0 )

	        //+---------------------------------------------------------------------+
	        //| Posicona novamemte na primeira linha valida.                        |
	        //+---------------------------------------------------------------------+
	        fSeek( nHandle, 0, 0 )

	        //+---------------------------------------------------------------------+
	        //| Fecha o Arquivo                                                     |
	        //+---------------------------------------------------------------------+
	        fClose( nHandle )
	        FT_FUse( cArquivo )  				// Abre o arquivo
	        FT_FGoTop()         				// Posiciona na primeira linha do arquivo
	        FT_FGoTop()

			// Captura dos dados da linha atual
			cLinha := FT_FReadLN()

			// Realiza a verificação do tipo de arquivo escolhido com o seu conteúdo
			If Left( cLinha, 1 ) == "Z"
				cTipoArq := "CTE/CRT"
			ElseIf Left( cLinha, 1 ) == "H"
				cTipoArq := "CTRB"
			Else
				cTipoArq := "ERRO"
			EndIf

	        // Fecha o Arquivo.
	        FT_FUSE()
		EndIf
	EndIf

Return cTipoArq

/*/{Protheus.doc} fDefAcao
Define qual ação deve ser realizada na importação do arquivo: cancelamento ou inclusão.
@author Paulo Carvalho
@since 19/12/2018
@version 1.01
@type Static Function
/*/
Static Function fDefAcao()

	Local aArea		:= GetArea()
	Local cAcao		:= ""
	Local cAux		:= ""

	// Busca a ação no nome do arquivo
	cAux := SubStr( cArquivo, -6, 2 )

	// Define a ação que será realizada.
	cAcao := If("01" $ cAux, "I", "C" )

	RestArea(aArea)

Return cAcao

/*/{Protheus.doc} fGetFilVel
Busca a lista de filiais cadastradas na tabela UQK.
@author Juliano Fernandes
@since 07/02/2019
@version 1.01
@type Function
/*/
Static Function fGetFilVel()

	Local aFilVel 		:= {}

	Local cAliasQry		:= ""
	Local cQuery		:= ""
	Local cTable		:= ""

	Local nI			:= 0

	cAliasQry := GetNextAlias()

	For nI := 1 To Len(aEmpProc)

		If !fExisteTab("UQK")
			Loop
		EndIf

		cTable := "UQK"  + aEmpProc[nI] +  "0"

		If !Empty(cQuery)
			cQuery += "UNION" + CRLF
		EndIf

		cQuery += "SELECT UQK_FILARQ, '" + aEmpProc[nI] + "' EMP, UQK_FILPRO"	+ CRLF
		cQuery += "FROM " + cTable												+ CRLF
		cQuery += "WHERE D_E_L_E_T_ <> '*'"										+ CRLF

	Next nI

	If !Empty(cQuery)
		cQuery += "ORDER BY EMP, UQK_FILPRO"

		If Select(cAliasQry) > 0
			(cAliasQry)->(DbCloseArea())
		EndIf

		DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

		While !(cAliasQry)->(EoF())
			Aadd( aFilVel, { (cAliasQry)->UQK_FILARQ, (cAliasQry)->EMP, (cAliasQry)->UQK_FILPRO } )

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())
	EndIf

Return(AClone(aFilVel))

/*/{Protheus.doc} fExisteTab
Verifica se a tabela existe no banco de dados.
@author Juliano Fernandes
@since 20/05/2019
@version 1.0
@return lExiste, Indica se a tabela passada como parâmetro existe
@param cTable, caracter, Tabela a ser analisada
@type function
/*/
Static Function fExisteTab(cTable)

Local lExiste := .T.
Local cArqDic := ""

	/*Local cAliasQry	:= ""
	Local cQuery	:= ""

	cAliasQry := GetNextAlias()
	cQuery := " SELECT t.name AS 'TableName' " 		+ CRLF
	cQuery += " FROM sys.tables t " 				+ CRLF
	cQuery += " WHERE t.name = '" + cTable + "' " 	+ CRLF

	If Select(cAliasQry) > 0
		(cAliasQry)->(DbCloseArea())
	EndIf

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

	lExiste := !(cAliasQry)->(EoF())

	(cAliasQry)->(DbCloseArea())
	*/

	cArqDic := FWSX2Util():GetFile( cTable )

	If Empty(cArqDic)
		lExiste := .F.
	Endif 

Return(lExiste)

/*/{Protheus.doc} fAltFilial
Altera a filial para o processamento das linhas dos arquivos de importação de CTE/CRT e CTRB.
@author Juliano Fernandes
@since 07/02/2019
@version 1.01
@type Function
/*/
Static Function fAltFilial(cFilArq)

	Local lAlt 		:= .F.
	Local lContinua	:= .T.

	Local nPos 		:= 0

	nPos := AScan(aFilDepara, {|x| x[1] == PadR(cFilArq, TamSX3("UQK_FILARQ")[1])})

	If nPos > 0
		If l527Auto
			If aFilDepara[nPos][2] != cEmpAnt
				lContinua := .F.
			EndIf
		EndIf
	Else
		lContinua := .F.
	EndIf

	If lContinua

		lAlt := .T.

		fAltEmpFil(aFilDepara[nPos][2], aFilDepara[nPos][3])

	EndIf

Return(lAlt)

/*/{Protheus.doc} fAltEmpFil
Altera a filial para o processamento das linhas dos arquivos de importação de CTE/CRT e CTRB.
@author Juliano Fernandes
@since 07/02/2019
@version 1.01
@type Function
/*/
Static Function fAltEmpFil(_cEmpresa, _cFilial)

	If cEmpAnt != _cEmpresa .Or. cFilAnt != _cFilial

		DbCloseAll()

		cEmpAnt := _cEmpresa
		cFilAnt := _cFilial
		cNumEmp := cEmpAnt + cFilAnt

		OpenSM0(cEmpAnt + cFilAnt)
		OpenFile(cEmpAnt + cFilAnt)

	EndIf

Return(Nil)

/*/{Protheus.doc} fPrepEnv
Realiza a preparação do ambiente para o processamento de registros.
@type function
@author Juliano Fernandes
@since 01/02/2019
@version 1.0
@param cErro, caracter, Variavel para a gravação de erros
@param _cEmpresa, caracter, Código da empresa
@param _cFilial, caracter, Código da filial
@return lPrepEnv, Indica se obteve sucesso na preparação do ambiente
/*/
Static Function fPrepEnv(cErro, _cEmpresa, _cFilial)
	Local _aTables 		:= {}
	Local _cModulo		:= "FAT"
	Local _cUser		:= Nil
	Local _cPassword	:= Nil
	Local lPrepEnv		:= .T.

	Aadd(_aTables, "UQD")
	Aadd(_aTables, "UQE")
	Aadd(_aTables, "UQF")
	Aadd(_aTables, "SA1")
	Aadd(_aTables, "SB1")

	RpcSetType(3)
	If !RpcSetEnv(_cEmpresa,_cFilial,_cUser,_cPassword,_cModulo,,_aTables)
		lPrepEnv := .F.

		cErro += CAT527035 + CRLF				//"Erro 527001 - Erro na abertura do ambiente"
		cErro += CAT527005 + _cEmpresa + CRLF	//" - Empresa: "
		cErro += CAT527003 + _cFilial + CRLF	//" - Filial: "
	EndIf
Return(lPrepEnv)

/*/{Protheus.doc} fEnvMail
Realiza o envio do email após realizar as importações de CTE, CRT e CTRB.
Utilizado somente em modo automático (Via Schedule).
@author Juliano Fernandes
@since 11/02/2019
@version 1.01
@param cDirCTE, caracter, Diretório de processamento de arquivos CTE
@param cDirCRT, caracter, Diretório de processamento de arquivos CRT
@param cDirCTRB, caracter, Diretório de processamento de arquivos CTRB
@param nHandle, numerico, Handle do arquivo txt de Log
@type Function
/*/
Static Function fEnvMail(cDirCTE, cDirCRT, cDirCTRB, nHandle)

	Local aArqDel		:= {}

	Local cServer		:= Lower( SuperGetMv( "PLG_MAILSR", .F., "" ) )
	Local cUser			:= Lower( SuperGetMv( "PLG_MAILUS", .F., "" ) )
	Local cPass			:= SuperGetMv( "PLG_MAILSE" , .F., "" )
	Local cFrom			:= Lower( SuperGetMv( "PLG_EMAILR", .F., "" ) )
	Local cTo_Pag		:= Lower( SuperGetMv( "PLG_LOGPAG", .F., "" ) )
	Local cTo_Rec		:= Lower( SuperGetMv( "PLG_LOGREC", .F., "" ) )
	Local cSubject		:= CAT527036	//"Relatório de importação e integração"
	Local cDir			:= IIf(IsSrvUnix(),"/TEMP","\TEMP")
	Local cBarra		:= IIf(IsSrvUnix(),"/","\")
	Local cBody			:= ""
	Local cCC			:= "aceex.desenv@gmail.com"
	Local cBCC			:= ""
	Local cErro			:= ""
	Local cTextoLog		:= ""

	Local lOk			:= .T.
	Local lExcelRec		:= .F.
	Local lExcelPag		:= .F.

	Local nErro 		:= 0
	Local nPort			:= SuperGetMv( "PLG_MAILPO", .F., 587 )
	Local nTentAnexo	:= 10
	Local nAttach		:= 0

	Local oMailServer	:= Nil
	Local oMessagePag	:= Nil // Log a Pagar
	Local oMessageRec	:= Nil // Log a Receber

	Private cExcelRec	:= cDir + cBarra + "LOGREC" + cIdSched // Nome do arquivo Excel que será gerado (a receber)
	Private cExcelPag	:= cDir + cBarra + "LOGPAG" + cIdSched // Nome do arquivo Excel que será gerado (a pagar)

	oMailServer	:= TMailManager():New()
	oMailServer:SetUseSSL( .T. )

	nErro := oMailServer:Init("", cServer, cUser, cPass, 0, nPort)

	If nErro != 0
		lOk := .F.
		cErro := CAT527037 + oMailServer:GetErrorString(nErro) // "Não foi possível estabelecer uma conexão com o servidor: "
	Endif

	If lOk
		nErro := oMailServer:SetSMTPTimeOut(120)

		If nErro != 0
			lOk := .F.
			cErro := CAT527038 + CValToChar(120) // "O protocolo não pode ser configurado ", " timeout para "
		Endif
	EndIf

	If lOk
		nErro := oMailServer:SmtpConnect()

		If nErro != 0
			lOk := .F.
			cErro := CAT527039 + oMailServer:GetErrorString(nErro) // "Não foi possível estabelecer uma conexão com o servidor SMTP: "
		EndIf
	EndIf

	If lOk
		If !ExistDir(cDir)
			MakeDir(cDir)
		EndIf

		If ExistDir(cDir)
			fPrepExcel(cDirCTE, cDirCRT, cDirCTRB, @lExcelRec, @lExcelPag)

			// -----------------
			// Log a Receber
			// -----------------

			If lExcelRec
				cBody := fGetBodyMail( .T. ) // Ocorreram erros e/ou pendências
			Else
				cBody := fGetBodyMail( .F. ) // Não ocorreram erros e pendências
			EndIf

			lOk := .T.

			oMessageRec := TMailMessage():New()
			oMessageRec:Clear()

			oMessageRec:cDate		:= DToC(Date())
			oMessageRec:cFrom 		:= cFrom
			oMessageRec:cTo 		:= cTo_Rec
			oMessageRec:cSubject	:= cSubject
			oMessageRec:cCC 		:= cCC
			oMessageRec:cBCC 		:= cBCC

			If lExcelRec
				nAttach := oMessageRec:AttachFile( cExcelRec + ".xls" )

				nTentAnexo := 10

				While nAttach < 0 .And. nTentAnexo > 0
					nAttach := oMessageRec:AttachFile( cExcelRec + ".xls" )
					nTentAnexo--
					Sleep(10000)
				EndDo

				Aadd(aArqDel, cExcelRec + ".xls")
			EndIf

			oMessageRec:cBody := cBody
			oMessageRec:MsgBodyType( "text/html" )
			nErro := oMessageRec:Send( oMailServer )

			If nErro != 0
				lOk := .F.
				cErro := CAT527041 + oMailServer:GetErrorString(nErro) + Space(1) + cTo_Rec	//"Não enviou o e-mail. "
			EndIf

			If lOk
				cTextoLog := "Schedule: " + NomePrt + CAT527043 + Space(1) + cTo_Rec ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Email enviado com sucesso"
			Else
				cTextoLog := "Schedule: " + NomePrt + CAT527045 + Space(1) + cTo_Rec ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) // " - Erro ao enviar e-mail"
				cTextoLog := cErro ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
			EndIf

			// -----------------
			// Log a Pagar
			// -----------------

			If lExcelPag
				cBody := fGetBodyMail( .T. ) // Ocorreram erros e/ou pendências
			Else
				cBody := fGetBodyMail( .F. ) // Não ocorreram erros e pendências
			EndIf

			lOk := .T.

			oMessagePag := TMailMessage():New()
			oMessagePag:Clear()

			oMessagePag:cDate		:= DToC(Date())
			oMessagePag:cFrom 		:= cFrom
			oMessagePag:cTo 		:= cTo_Pag
			oMessagePag:cSubject 	:= cSubject
			oMessagePag:cCC 		:= cCC
			oMessagePag:cBCC 		:= cBCC

			If lExcelPag
				nAttach := oMessagePag:AttachFile( cExcelPag + ".xls" )

				nTentAnexo := 10

				While nAttach < 0 .And. nTentAnexo > 0
					nAttach := oMessagePag:AttachFile( cExcelPag + ".xls" )
					nTentAnexo--
					Sleep(10000)
				EndDo

				Aadd(aArqDel, cExcelPag + ".xls")
			EndIf

			oMessagePag:cBody := cBody
			oMessagePag:MsgBodyType( "text/html" )
			nErro := oMessagePag:Send( oMailServer )

			If nErro != 0
				lOk := .F.
				cErro := CAT527041 + oMailServer:GetErrorString(nErro) + Space(1) + cTo_Pag	//"Não enviou o e-mail. "
			EndIf

			If lOk
				cTextoLog := "Schedule: " + NomePrt + CAT527043 + Space(1) + cTo_Pag ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Email enviado com sucesso"
			Else
				cTextoLog := "Schedule: " + NomePrt + CAT527045 + Space(1) + cTo_Pag ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) // " - Erro ao enviar e-mail"
				cTextoLog := cErro ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
			EndIf

			nErro := oMailServer:SmtpDisconnect()

			If nErro != 0
				lOk := .F.
				cErro := CAT527042 + oMailServer:GetErrorString(nErro)	//"Não desconectou. "
				cTextoLog := cErro ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)
			EndIf

		EndIf

	EndIf

	// Deleta os arquivos gerados e que já foram anexados ao email
	AEval(aArqDel, {|cFile| FErase(cFile)})

Return(lOk)

/*/{Protheus.doc} fGetBodyMail
Monta o HTML do corpo do email que será enviado após realizar as importações de CTE, CRT e CTRB
Utilizado somente em modo automático (Via Schedule).
@author Juliano Fernandes
@since 11/02/2019
@version 1.01
@return cBody, String com o HTML do corpo do email a ser enviado
@param lErros, logico, Indica se há ou não erros/pendencias
@type Function
/*/
Static Function fGetBodyMail(lErros)

	Local cBody		:= ""
	Local cMensagem	:= ""

	If lErros
		cMensagem := BSCEncode(CAT527046) // "Relação de erros ocorridos no processo de importação e integração automática."
	Else
		cMensagem := BSCEncode(CAT527051) + DToC(Date()) + "." // "Não ocorreram erros no processo de importação / integração executado em "
	EndIf

	cBody := "<html>"
	cBody += "	<body>"
	cBody += "		<font face='Arial'>"
	cBody += "		<p style='font-size:12px;'>"
	cBody += "			" + cMensagem
	cBody += "		</p>"
	cBody += "		<p style='font-size:10px;'>"
	cBody += "			" + BSCEncode(CAT527049) // "Esta é uma mensagem automática. Por favor, não responda este e-mail."
	cBody += "		</p>"
	cBody += "	</body>"
	cBody += "</html>"

Return(cBody)

/*/{Protheus.doc} fAjuNaoImp
Ajusta os itens que não foram importados devido à problemas de filial não localizada na tabela UQK.
@author Juliano Fernandes
@since 06/08/2019
@version 1.0
@param aNaoImp, array, Dados de registros não importados
@type function
/*/
Static Function fAjuNaoImp(aNaoImp)

	Local aRegDel		:= {}

	Local cQuery		:= ""
	Local cQueryDel		:= ""
	Local cAliasQry		:= GetNextAlias()
	Local cAliasTab		:= ""
	Local cPrefixTab	:= ""
	Local cRegCod		:= ""
	Local cArq			:= ""
	Local cFilErro		:= Replicate("X", Len(cFilAnt))
	Local cTable		:= ""

	Local lDelLogErro	:= .F.

	Local nLinhaArq		:= 0

	Local nI			:= 0
	Local nJ			:= 0
	Local nK			:= 0

	For nI := 1 To Len(aNaoImp)
		aRegDel		:= {}
		lDelLogErro	:= .F.

		cAliasTab	:= aNaoImp[nI,1] // UQF ou UQJ
		cRegCod		:= aNaoImp[nI,2]
		nLinhaArq	:= aNaoImp[nI,3]
		cArq		:= aNaoImp[nI,4]

		cPrefixTab 	:= Right(cAliasTab, 2) // UQF OU UQJ

		cQuery := ""

		For nK := 1 To Len(aEmpProc)

			If !fExisteTab(cAliasTab)
				Loop
			EndIf

			cTable := cAliasTab + aEmpProc[nK] + "0"

			If !Empty(cQuery)
				cQuery += " UNION " + CRLF
			EndIf

			cQuery += " SELECT '" + aEmpProc[nK] + "' EMP, " + cPrefixTab + "_FILIAL FILIAL, " 			+ CRLF
			cQuery += " 	" + cPrefixTab + "_ARQUIVO, " + cPrefixTab + "_NLINHA, R_E_C_N_O_ RECNO "	+ CRLF
			cQuery += " FROM " + cTable																	+ CRLF
			cQuery += " WHERE   " + cPrefixTab + "_DATA    = '" + DToS(Date()) + "' " 					+ CRLF
			cQuery += " 	AND " + cPrefixTab + "_IDSCHED = '" + cIdSched + "' " 						+ CRLF
			cQuery += " 	AND " + cPrefixTab + "_REGCOD  = '" + cRegCod + "' " 						+ CRLF
			cQuery += " 	AND " + cPrefixTab + "_ARQUIVO = '" + cArq + "' " 							+ CRLF
			cQuery += " 	AND " + cPrefixTab + "_NLINHA  =  " + CValToChar(nLinhaArq)		 			+ CRLF
			cQuery += " 	AND D_E_L_E_T_ <> '*' " 													+ CRLF

		Next nK

		If !Empty(cQuery)
			cQuery += " ORDER BY " + cPrefixTab + "_ARQUIVO, " + cPrefixTab + "_NLINHA "
		EndIf

		If Select(cAliasQry) > 0
			(cAliasQry)->(DbCloseArea())
		EndIf

		DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

		TcSetField(cAliasQry, "RECNO", "N", 17, 0)

		While !(cAliasQry)->(EoF())
			If (cAliasQry)->FILIAL != cFilErro
				lDelLogErro := .T.
			Else
				cTable := cAliasTab + (cAliasQry)->EMP + "0"

				Aadd(aRegDel, {	cTable				,;
								(cAliasQry)->RECNO	})
			EndIf

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())

		// -------------------------------------------------------------------------------------
		// Deleta os registros com filial 'XXXX' pois o registro foi importado corretamente
		// -------------------------------------------------------------------------------------
		If lDelLogErro .And. !Empty(aRegDel)
			For nJ := 1 To Len(aRegDel)
				cTable := aRegDel[nJ,1]

				cQueryDel := " DELETE " + cTable								+ CRLF
				cQueryDel += " WHERE R_E_C_N_O_ = " + CValToChar(aRegDel[nJ,2])	+ CRLF

				TcSqlExec(cQueryDel)
			Next nJ
		EndIf

		// ----------------------------------------------------------------------
		// Deleta os registros de erro gravados nas empresas diferentes de
		// 01 para que seja exibido somente uma vez no e-mail enviado após
		// importação / integração via Schedule
		// ----------------------------------------------------------------------
		If Select(cAliasQry) > 0
			(cAliasQry)->(DbCloseArea())
		EndIf

		DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)

		TcSetField(cAliasQry, "RECNO", "N", 17, 0)

		While !(cAliasQry)->(EoF())
			If (cAliasQry)->EMP != "01" .And. (cAliasQry)->FILIAL == cFilErro
				cTable := cAliasTab + (cAliasQry)->EMP + "0"

				cQueryDel := " DELETE " + cTable										+ CRLF
				cQueryDel += " WHERE R_E_C_N_O_ = " + CValToChar((cAliasQry)->RECNO)	+ CRLF

				TcSqlExec(cQueryDel)
			EndIf

			(cAliasQry)->(DbSkip())
		EndDo

		(cAliasQry)->(DbCloseArea())

	Next nI

Return(Nil)

/*/{Protheus.doc} fxFilial
Retorna a filial da tabela passada por parâmetro. Semelhante à função xFilial.
Esta função foi desenvolvida pois conforme a troca de empresas utilizando a função fAltEmpFil,
ao utilizar o comando xFilial, em alguns casos não retorna a informação correta.
@author Juliano Fernandes
@since 13/08/2019
@version 1.0
@return cCodFilRet, Filial da tabela passada por parâmetro
@param cTab, caracter, Tabela a ser pesquisada
@type function
/*/
Static Function fxFilial(cTab)

	Local cCodFilRet 	:= ""

	cCodFilRet := FWxFilial(	cTab				,; // Alias da tabela a ser avaliada
								cFilAnt				,; // Indica a empresa, unidade de negócio e filial (Ex: cFilAnt)
								FWModeAccess(cTab,1),; // Indica o modo de compartilhamento da empresa
								FWModeAccess(cTab,2),; // Indica o modo de compartilhamento da unidade de negócios
								FWModeAccess(cTab,3) ) // Indica o modo de compartilhamento da filial

Return(cCodFilRet)

/*/{Protheus.doc} f527Impo
Executa a importação automática (Schedule).
@author Juliano Fernandes
@since 28/05/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
User Function f527Impo(_cEmpresa, _cFilial, cIdSche, cUserSche, aAllFiles, lEnvMail, lIntCTECRT, lIntCTRB, aArqProc, aFilDep, aNaoImp)

	Local aFiles		:= {}

	Local cErro			:= ""
	Local cTextoLog		:= ""

	Local nHandle		:= 0

	Private aFilDepara	:= AClone(aFilDep)

	Private cIdSched	:= cIdSche
	Private cUserSched	:= cUserSche

	Private l527Auto 	:= .T.

	fLogSched(3, @nHandle)

	cTextoLog := "Schedule: " + NomePrt + CAT527002 + _cEmpresa + CAT527003 + _cFilial; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Realizando conexao com: Empresa: " //" - Filial: "

	If fPrepEnv(@cErro, _cEmpresa, _cFilial)

		cTextoLog := "Schedule: " + NomePrt + CAT527005 + _cEmpresa + " - " + FWGrpName() ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil)	 //" - Empresa: "
		cTextoLog := "Schedule: " + NomePrt + CAT527003 + _cFilial  + " - " + FwFilialName() ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - Filial: "

		cTextoLog := "Schedule: " + NomePrt + CAT527006 ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - ### Processando CTE ###"

		aFiles := AClone(aAllFiles[1])

		If !Empty(aFiles)
			lEnvMail := .T.
			lIntCTECRT := .T.

			//AEVal(aFiles, {|aFile| cTextoLog := "Schedule: " + NomePrt + CAT527008 + aFile[1], ConOut(cTextoLog), IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil), fProc527(aFile[1], "CTE/CRT", @aArqProc, @aNaoImp)}) //" - Processando arquivo: "
		EndIf

		cTextoLog := "Schedule: " + NomePrt + CAT527009 ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - ### Processando CRT ###"

		aFiles := AClone(aAllFiles[2])

		If !Empty(aFiles)
			lEnvMail := .T.
			lIntCTECRT := .T.

			//AEval(aFiles, {|aFile| cTextoLog := "Schedule: " + NomePrt + CAT527008 + aFile[1], ConOut(cTextoLog), IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil), fProc527(aFile[1], "CTE/CRT", @aArqProc, @aNaoImp)}) //"Processando Arquivo"
		EndIf

		cTextoLog := "Schedule: " + NomePrt + CAT527011 ; ConOut(cTextoLog) ; IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil) //" - ### Processando CTRB ###"

		aFiles := AClone(aAllFiles[3])

		If !Empty(aFiles)
			lEnvMail := .T.
			lIntCTRB := .T.

			//AEval(aFiles, {|aFile| cTextoLog := "Schedule: " + NomePrt + CAT527008 + aFile[1], ConOut(cTextoLog), IIf(nHandle > 0, fLogSched(2, nHandle, cTextoLog), Nil), fProc527(aFile[1], "CTRB", @aArqProc, @aNaoImp)}) //" - Processando arquivo: "
		EndIf

		RpcClearEnv()
	Else
		ConOut(cErro) ; IIf(nHandle > 0, fLogSched(2, nHandle, cErro), Nil)
	EndIf

	fLogSched(4, nHandle)

Return({lEnvMail, lIntCTECRT, lIntCTRB, aArqProc, aNaoImp})

/*/{Protheus.doc} f527Inte
Executa a integração automática (Schedule).
@author Juliano Fernandes
@since 13/05/2019
@version 1.0
@return Nil, Não há retorno
@type function
/*/
User Function f527Inte(_cEmpresa, _cFilial, lIntCTECRT, lIntCTRB, cIdSche, cUserSche)

	Local cErro			:= ""

	Private cIdSched	:= cIdSche
	Private cUserSched	:= cUserSche

	If fPrepEnv(@cErro, _cEmpresa, _cFilial)
		U_PRT0528(.T., lIntCTECRT, lIntCTRB)

		RpcClearEnv()
	Else
		ConOut(cErro)
	EndIf

Return(Nil)

/*/{Protheus.doc} fPrepExcel
Responsavel por organizar a geração de Excel a ser enviado por email
@author Icaro Laudade
@since 24/10/2019
@param cDirCTE, caracter, Diretório de processamento de arquivos CTE
@param cDirCRT, caracter, Diretório de processamento de arquivos CRT
@param cDirCTRB, caracter, Diretório de processamento de arquivos CTRB
@param lRec, logico, Indica se existem registros para envio ao e-mail a Receber
@param lPag, logico, Indica se existem registros para envio ao e-mail a Pagar
@type function
/*/
Static Function fPrepExcel(cDirCTE, cDirCRT, cDirCTRB, lRec, lPag)

	Local aLnImpCTE		:=	{}
	Local aLnImpCRT		:=	{}
	Local aLnImpCar		:=	{}
	Local aLnImpCTRB	:=	{}
	Local aLnIntCTE		:=	{}
	Local aLnIntCRT		:=	{}
	Local aLnIntCar		:=	{}
	Local aLnIntCTRB	:=	{}
	Local aLnPenCTE		:=	{}
	Local aLnPenCRT		:=	{}
	Local aLnPenCar		:=	{}
	Local aLnPenCTRB	:=	{}

	Local nJ			:=	0

	For nJ := 1 To Len(aEmpProc)

		fAltEmpFil(aEmpProc[nJ], "01")

		fGetImp( @aLnImpCTE, @aLnImpCRT, @aLnImpCar, @aLnImpCTRB, cDirCTE, cDirCRT, cDirCTRB)
		fGetInt( @aLnIntCTE, @aLnIntCRT, @aLnIntCar, @aLnIntCTRB, cDirCTE, cDirCRT, cDirCTRB)
		fGetPen( @aLnPenCTE, @aLnPenCRT, @aLnPenCar, @aLnPenCTRB, cDirCTE, cDirCRT, cDirCTRB)

	Next nJ

	lRec := fExcelRec(aLnImpCTE, aLnImpCRT, aLnImpCar, aLnIntCTE, aLnIntCRT, aLnIntCar, aLnPenCTE, aLnPenCRT, aLnPenCar, cExcelRec)

	lPag := fExcelPag(aLnImpCTRB, aLnIntCTRB, aLnPenCTRB, cExcelPag)

Return(Nil)

/*/{Protheus.doc} fGetImp
Responsável por obter os registros com erros de integração para envio por email
@author Icaro Laudade
@since 24/10/2019
@return Nenhum, Não há retorno
@param aLnImpCTE, array, Armazena os erros de importação CTE
@param aLnImpCRT, array, Armazena os erros de importação CRT
@param aLnImpCar, array, Armazena os erros de importação Carta
@param aLnImpCTRB, array, Armazena os erros de importação CTRB
@param cDirCTE, caracter, Diretório de processamento de arquivos CTE
@param cDirCRT, caracter, Diretório de processamento de arquivos CRT
@param cDirCTRB, caracter, Diretório de processamento de arquivos CTRB
@type function
/*/
Static Function fGetImp(aLnImpCTE, aLnImpCRT, aLnImpCar, aLnImpCTRB, cDirCTE, cDirCRT, cDirCTRB)

	Local aAux		:=	{}
	Local aCampos	:=	{}

	Local cAliasTmp	:=	GetNextAlias()
	Local cQuery	:=	""
	Local cTipo		:=	""

	Local nI		:=	0

	Aadd(aCampos, "UQF_FIL"		)
	Aadd(aCampos, "UQF_DATA"	)
	Aadd(aCampos, "UQF_HORA"	)
	Aadd(aCampos, "UQF_REGCOD"	)
	Aadd(aCampos, "UQF_CLIENT"	)
	Aadd(aCampos, "UQF_VALOR"	)
	Aadd(aCampos, "UQF_ARQUIV"	)
	Aadd(aCampos, "UQF_NLINHA"	)
	Aadd(aCampos, "UQF_MSG"		)

	//---------------------------------------------------------------------------
	// ERROS DE IMPORTAÇÃO DE CTE
	//---------------------------------------------------------------------------

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"  					+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"				+ CRLF
	cQuery += "	AND UQF.UQF_STATUS IN ('E','D')" 						+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'IMP'" 								+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_USER = '" + cUserSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_CANCEL <> 'R' "								+ CRLF
	cQuery += " AND UQF.UQF_ARQUIV LIKE '" + AllTrim(cDirCTE) + "%'"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 								+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_"

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MPSysOpenQuery( cQuery, cAliasTmp)

	While !(cAliasTmp)->(EOF())

		aAdd(aAux, BSCEncode("CTE"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnImpCTE, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE IMPORTAÇÃO DE CRT
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"						+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"				+ CRLF
	cQuery += "	AND UQF.UQF_STATUS IN ('E','D')" 						+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'IMP'" 								+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_USER = '" + cUserSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_CANCEL <> 'R' "								+ CRLF
	cQuery += " AND UQF.UQF_ARQUIV LIKE '" + AllTrim(cDirCRT) + "%'"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 								+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_" 								+ CRLF

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MPSysOpenQuery( cQuery, cAliasTmp)

	While !(cAliasTmp)->(EOF())

		aAdd(aAux, BSCEncode("CRT"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnImpCRT, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE IMPORTAÇÃO DE CARTA DE CORREÇÃO
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"						+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"				+ CRLF
	cQuery += "	AND UQF.UQF_STATUS IN ('E','D')" 						+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'IMP'" 								+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_USER = '" + cUserSched + "'"				+ CRLF
	cQuery += " AND UQF.UQF_CANCEL = 'R' "								+ CRLF
	cQuery += " AND (UQF.UQF_ARQUIV LIKE '" + AllTrim(cDirCRT) + "%'"	+ CRLF
	cQuery += " OR UQF.UQF_ARQUIV LIKE '" + AllTrim(cDirCTE) + "%')"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 								+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_" 								+ CRLF

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MPSysOpenQuery( cQuery, cAliasTmp)

	While !(cAliasTmp)->(EOF())

		aAdd(aAux, BSCEncode(Upper(CAT527057))) // "Carta de Correção"

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnImpCar, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE IMPORTAÇÃO DE CTRB
	//---------------------------------------------------------------------------
	aCampos := {}

	Aadd(aCampos, "UQJ_FIL"		)
	Aadd(aCampos, "UQJ_DATA"	)
	Aadd(aCampos, "UQJ_HORA"	)
	Aadd(aCampos, "UQJ_REGCOD"	)
	Aadd(aCampos, "UQJ_ARQUIV"	)
	Aadd(aCampos, "UQJ_NLINHA"	)
	Aadd(aCampos, "UQJ_MSG"		)

	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQJ." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQJ") + " UQJ"						+ CRLF
	cQuery += "WHERE UQJ.UQJ_DATA = '" + DToS(Date()) + "'"				+ CRLF
	cQuery += "	AND UQJ.UQJ_STATUS IN ('E','D')"						+ CRLF
	cQuery += "	AND UQJ.UQJ_ACAO = 'IMP'" 								+ CRLF
	cQuery += " AND UQJ.UQJ_IDSCHE = '" + cIdSched + "'"				+ CRLF
	cQuery += " AND UQJ.UQJ_USER = '" + cUserSched + "'"				+ CRLF
	cQuery += " AND UQJ.UQJ_ARQUIV LIKE '" + AllTrim(cDirCTRB) + "%'"	+ CRLF
	cQuery += "	AND UQJ.D_E_L_E_T_ <> '*'" 								+ CRLF
	cQuery += "ORDER BY UQJ.R_E_C_N_O_" 								+ CRLF

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MPSysOpenQuery( cQuery, cAliasTmp)

	While !(cAliasTmp)->(EOF())

		aAdd(aAux, BSCEncode("CTRB"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else

				If aCampos[nI] == "UQJ_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnImpCTRB, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

Return

/*/{Protheus.doc} fGetInt
Responsável por obter os registros com erros de integração para envio por email
@author Icaro Laudade
@since 24/10/2019
@return Nenhum, Não há retorno
@param aLnIntCTE, array, Armazena os erros de integração CTE
@param aLnIntCRT, array, Armazena os erros de integração CRT
@param aLnIntCar, array, Armazena os erros de integração Carta
@param aLnIntCTRB, array, Armazena os erros de integração CTRB
@param cDirCTE, caracter, Diretório de processamento de arquivos CTE
@param cDirCRT, caracter, Diretório de processamento de arquivos CRT
@param cDirCTRB, caracter, Diretório de processamento de arquivos CTRB
@type function
/*/
Static Function fGetInt(aLnIntCTE, aLnIntCRT, aLnIntCar, aLnIntCTRB, cDirCTE, cDirCRT, cDirCTRB)

	Local aAux		:=	{}
	Local aCampos	:=	{}

	Local cAliasTmp	:=	GetNextAlias()
	Local cQuery	:=	""
	Local cTipo		:=	""

	Local nI		:=	0

	//---------------------------------------------------------------------------
	// ERROS DE INTEGRAÇÃO DE CTE
	//---------------------------------------------------------------------------

	Aadd(aCampos, "UQF_FIL"		)
	Aadd(aCampos, "UQF_DATA"	)
	Aadd(aCampos, "UQF_REGCOD"	)
	Aadd(aCampos, "UQF_CLIENT"	)
	Aadd(aCampos, "UQF_VALOR"	)
	Aadd(aCampos, "UQD_MOEDA"	)
	Aadd(aCampos, "UQF_MSG"		)

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"  		+ CRLF
	cQuery += "	INNER JOIN " + RetSQLName("UQD") + " UQD" 	+ CRLF
	cQuery += "		ON UQD.UQD_FILIAL = UQF.UQF_FILIAL" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDSCHE = UQF.UQF_IDSCHE" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDIMP = UQF.UQF_IDIMP" 		+ CRLF
	cQuery += "		AND UQD.UQD_TPCON = 'ZTRC'" 			+ CRLF
	cQuery += "		AND UQD.D_E_L_E_T_ <> '*'" 				+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"	+ CRLF
	cQuery += "	AND UQF.UQF_STATUS = 'E'"		 			+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'INT'" 					+ CRLF
	cQuery += " AND UQF.UQF_CANCEL <> 'R'"					+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 					+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_" 					+ CRLF

	cQuery := StrTran(cQuery,"UQF.UQD_MOEDA","UQD.UQD_MOEDA")

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CTE"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf

		Next nI

		aAdd(aLnIntCTE, aAux)
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE INTEGRAÇÃO DE CRT
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"			+ CRLF
	cQuery += "	INNER JOIN " + RetSQLName("UQD") + " UQD" 	+ CRLF
	cQuery += "		ON UQD.UQD_FILIAL = UQF.UQF_FILIAL" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDSCHE = UQF.UQF_IDSCHE" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDIMP = UQF.UQF_IDIMP" 		+ CRLF
	cQuery += "		AND UQD.UQD_TPCON = 'ZCRT'" 			+ CRLF
	cQuery += "		AND UQD.D_E_L_E_T_ <> '*'" 				+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"	+ CRLF
	cQuery += "	AND UQF.UQF_STATUS = 'E'" 					+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'INT'" 					+ CRLF
	cQuery += " AND UQF.UQF_CANCEL <> 'R'"					+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 					+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_" 					+ CRLF

	cQuery := StrTran(cQuery,"UQF.UQD_MOEDA","UQD.UQD_MOEDA")

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CRT"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnIntCRT, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE INTEGRAÇÃO DE CARTA DE CORREÇÃO
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQF." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQF") + " UQF"			+ CRLF
	cQuery += "	INNER JOIN " + RetSQLName("UQD") + " UQD" 	+ CRLF
	cQuery += "		ON UQD.UQD_FILIAL = UQF.UQF_FILIAL" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDSCHE = UQF.UQF_IDSCHE" 	+ CRLF
	cQuery += "		AND UQD.UQD_IDIMP = UQF.UQF_IDIMP" 		+ CRLF
	cQuery += "		AND UQD.UQD_CANCEL = UQF.UQF_CANCEL"	+ CRLF
	cQuery += "		AND UQD.D_E_L_E_T_ <> '*'" 				+ CRLF
	cQuery += "WHERE UQF.UQF_DATA = '" + DToS(Date()) + "'"	+ CRLF
	cQuery += "	AND UQF.UQF_STATUS = 'E'" 					+ CRLF
	cQuery += "	AND UQF.UQF_ACAO = 'INT'" 					+ CRLF
	cQuery += " AND UQF.UQF_CANCEL = 'R'"					+ CRLF
	cQuery += " AND UQF.UQF_IDSCHE = '" + cIdSched + "'"	+ CRLF
	cQuery += "	AND UQF.D_E_L_E_T_ <> '*'" 					+ CRLF
	cQuery += "ORDER BY UQF.R_E_C_N_O_" 					+ CRLF

	cQuery := StrTran(cQuery,"UQF.UQD_MOEDA","UQD.UQD_MOEDA")

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode(Upper(CAT527057))) // "Carta de Correção"

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQF_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnIntCar, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// ERROS DE INTEGRAÇÃO DE CTRB
	//---------------------------------------------------------------------------

	aCampos := {}

	Aadd(aCampos, "UQJ_FIL"		)
	Aadd(aCampos, "UQJ_DATA"	)
	Aadd(aCampos, "UQJ_REGCOD"	)
	Aadd(aCampos, "UQJ_MSG"		)

	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQJ." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQJ") + " UQJ"			+ CRLF
	cQuery += "	INNER JOIN " + RetSQLName("UQG") + " UQG" 	+ CRLF
	cQuery += "		ON UQG.UQG_FILIAL = UQJ.UQJ_FILIAL" 	+ CRLF
	cQuery += "		AND UQG.UQG_IDSCHE = UQJ.UQJ_IDSCHE" 	+ CRLF
	cQuery += "		AND UQG.UQG_IDIMP = UQJ.UQJ_IDIMP" 		+ CRLF
	cQuery += "		AND UQG.D_E_L_E_T_ <> '*'" 				+ CRLF
	cQuery += "WHERE UQJ.UQJ_DATA = '" + DToS(Date()) + "'"	+ CRLF
	cQuery += "	AND UQJ.UQJ_STATUS = 'E'"					+ CRLF
	cQuery += "	AND UQJ.UQJ_ACAO = 'INT'" 					+ CRLF
	cQuery += " AND UQJ.UQJ_IDSCHE = '" + cIdSched + "'"	+ CRLF
	cQuery += "	AND UQJ.D_E_L_E_T_ <> '*'" 					+ CRLF
	cQuery += "ORDER BY UQJ.R_E_C_N_O_" 					+ CRLF

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CTRB"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else
				If aCampos[nI] == "UQJ_MSG"
					aAdd(aAux, BSCEncode((cAliasTmp)->&(aCampos[nI])) )
				Else
					aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
				EndIf
			EndIf
		Next nI

		aAdd(aLnIntCTRB, aAux )
		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

Return

/*/{Protheus.doc} fGetPen
Responsável por obter os registros com pendencias de integração para envio por email
@author Icaro Laudade
@since 24/10/2019
@return Nenhum, Não há retorno
@param aLnPenCTE, array, Armazena as pendencias de integração CTE
@param aLnPenCRT, array, Armazena as pendencias de integração CRT
@param aLnPenCar, array, Armazena as pendencias de integração Carta
@param aLnPenCTRB, array, Armazena as pendencias de integração CTRB
@param cDirCTE, caracter, Diretório de processamento de arquivos CTE
@param cDirCRT, caracter, Diretório de processamento de arquivos CRT
@param cDirCTRB, caracter, Diretório de processamento de arquivos CTRB
@type function
/*/
Static Function fGetPen(aLnPenCTE, aLnPenCRT, aLnPenCar, aLnPenCTRB, cDirCTE, cDirCRT, cDirCTRB)

	Local aAux		:=	{}
	Local aCampos	:=	{}

	Local cAliasTmp	:=	GetNextAlias()
	Local cQuery	:=	""
	Local cTipo		:=	""

	Local nI		:=	0

	//---------------------------------------------------------------------------
	// PENDENCIAS DE INTEGRAÇÃO DE CTE
	//---------------------------------------------------------------------------

	Aadd(aCampos, "UQD_FIL"		)
	Aadd(aCampos, "UQD_DTIMP"	)
	Aadd(aCampos, "UQD_NUMERO"	)
	Aadd(aCampos, "A1_NOME"		)
	Aadd(aCampos, "UQD_VALOR"	)
	Aadd(aCampos, "UQD_MOEDA"	)
	Aadd(aCampos, "UQF_MSG"		)

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQD") + " UQD"					+ CRLF
	cQuery += "	LEFT JOIN " + RetSQLName("SA1") + " SA1"			+ CRLF
	cQuery += "		ON SA1.A1_FILIAL = '" + fxFilial("SA1") + "'"	+ CRLF
	cQuery += "		AND SA1.A1_COD = UQD.UQD_CLIENT"				+ CRLF
	cQuery += "		AND SA1.A1_LOJA = UQD.UQD_LOJACL"				+ CRLF
	cQuery += "		AND SA1.D_E_L_E_T_ <> '*'"						+ CRLF
	cQuery += "WHERE UQD.UQD_TPCON = 'ZTRC'"						+ CRLF
	cQuery += "	AND UQD.UQD_CANCEL <> 'R'"							+ CRLF
	cQuery += "	AND UQD.UQD_STATUS IN ('I','E')"					+ CRLF
	cQuery += "	AND UQD.UQD_IDSCHE <> '" + cIdSched + "'"			+ CRLF
	cQuery += " AND UQD.UQD_BLQMAI = 'N' "							+ CRLF
	cQuery += "	AND UQD.D_E_L_E_T_ <> '*' "							+ CRLF
	cQuery += "ORDER BY UQD.R_E_C_N_O_" 							+ CRLF

	cQuery := StrTran(cQuery,"A1_NOME","ISNULL(A1_NOME,'*** " + Upper(CAT527053) + " ***') A1_NOME") // "Cliente não localizado"
	cQuery := StrTran(cQuery,"UQF_MSG","'" + BSCEncode(CAT527069) + "' UQF_MSG") // "Registro pendente"

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery( cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CTE") )

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else

				aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
			EndIf
		Next nI

		aAdd(aLnPenCTE, aAux )

		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// PENDENCIAS DE INTEGRAÇÃO DE CRT
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQD") + " UQD"					+ CRLF
	cQuery += "	LEFT JOIN " + RetSQLName("SA1") + " SA1"			+ CRLF
	cQuery += "		ON SA1.A1_FILIAL = '" + fxFilial("SA1") + "'"	+ CRLF
	cQuery += "		AND SA1.A1_COD = UQD.UQD_CLIENT"				+ CRLF
	cQuery += "		AND SA1.A1_LOJA = UQD.UQD_LOJACL"				+ CRLF
	cQuery += "		AND SA1.D_E_L_E_T_ <> '*'"						+ CRLF
	cQuery += "WHERE UQD.UQD_TPCON = 'ZCRT'"						+ CRLF
	cQuery += "	AND UQD.UQD_CANCEL <> 'R'"							+ CRLF
	cQuery += "	AND UQD.UQD_STATUS IN ('I','E')"					+ CRLF
	cQuery += "	AND UQD.UQD_IDSCHE <> '" + cIdSched + "'"			+ CRLF
	cQuery += " AND UQD.UQD_BLQMAI = 'N' "							+ CRLF
	cQuery += "	AND UQD.D_E_L_E_T_ <> '*'" 							+ CRLF
	cQuery += "ORDER BY UQD.R_E_C_N_O_" 							+ CRLF

	cQuery := StrTran(cQuery,"A1_NOME","ISNULL(A1_NOME,'*** " + Upper(CAT527053) + " ***') A1_NOME") // "Cliente não localizado."
	cQuery := StrTran(cQuery,"UQF_MSG","'" + BSCEncode(CAT527069) + "' UQF_MSG") // "Registro pendente"

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CRT") )

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else

				aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
			EndIf
		Next nI

		aAdd(aLnPenCRT, aAux )

		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// PENDENCIAS DE INTEGRAÇÃO DE CARTA DE CORREÇÃO
	//---------------------------------------------------------------------------
	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQD") + " UQD"					+ CRLF
	cQuery += "	LEFT JOIN " + RetSQLName("SA1") + " SA1"			+ CRLF
	cQuery += "		ON SA1.A1_FILIAL = '" + fxFilial("SA1") + "'"	+ CRLF
	cQuery += "		AND SA1.A1_COD = UQD.UQD_CLIENT"				+ CRLF
	cQuery += "		AND SA1.A1_LOJA = UQD.UQD_LOJACL"				+ CRLF
	cQuery += "		AND SA1.D_E_L_E_T_ <> '*'"						+ CRLF
	cQuery += "WHERE UQD.UQD_CANCEL = 'R'"							+ CRLF
	cQuery += "	AND UQD.UQD_STATUS IN ('I','E')"					+ CRLF
	cQuery += "	AND UQD.UQD_IDSCHE <> '" + cIdSched + "'"			+ CRLF
	cQuery += " AND UQD.UQD_BLQMAI = 'N' "							+ CRLF
	cQuery += "	AND UQD.D_E_L_E_T_ <> '*'" 							+ CRLF
	cQuery += "ORDER BY UQD.R_E_C_N_O_" 							+ CRLF

	cQuery := StrTran(cQuery,"A1_NOME","ISNULL(A1_NOME,'*** " + Upper(CAT527053) + " ***') A1_NOME") // "Cliente não localizado."
	cQuery := StrTran(cQuery,"UQF_MSG","'" + BSCEncode(CAT527069) + "' UQF_MSG") // "Registro pendente"

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode(Upper(CAT527057))) // "Carta de Correção"

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else

				aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
			EndIf
		Next nI

		aAdd(aLnPenCar, aAux )

		aAux := {}

		(cAliasTmp)->(DbSkip())
	EndDo

	//---------------------------------------------------------------------------
	// PENDENCIAS DE INTEGRAÇÃO DE CTRB
	//---------------------------------------------------------------------------

	aCampos := {}

	Aadd(aCampos, "UQG_FIL"		)
	Aadd(aCampos, "UQG_DTIMP"	)
	Aadd(aCampos, "UQG_REF"		)
	Aadd(aCampos, "UQJ_MSG"		)

	nI := 0

	//-- Query não filtra por filial para que todas as filiais possam ser obtidas
	cQuery := "SELECT " ; AEVal(aCampos, {|x| nI++, cQuery += "UQG." + x + IIf(nI < Len(aCampos), ", ", CRLF)})
	cQuery += "FROM " + RetSQLName("UQG") + " UQG"			+ CRLF
	cQuery += "WHERE UQG.UQG_STATUS IN ('I','E')"			+ CRLF
	cQuery += "	AND UQG.UQG_IDSCHE <> '" + cIdSched + "'"	+ CRLF
	cQuery += "	AND UQG.D_E_L_E_T_ <> '*'" 					+ CRLF
	cQuery += "ORDER BY UQG.R_E_C_N_O_" 					+ CRLF

	cQuery := StrTran(cQuery,"UQG.UQJ_MSG","'" + BSCEncode(CAT527069) + "' UQJ_MSG") // "Registro pendente"

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	MpSysOpenQuery(cQuery, cAliasTmp)

	While !(cAliasTmp)->(EoF())

		aAdd(aAux, BSCEncode("CTRB"))

		For nI := 1 To Len(aCampos)
			cTipo := TamSX3(aCampos[nI])[3]

			If AllTrim(cTipo) $ "D"

				aAdd(aAux, SToD((cAliasTmp)->&(aCampos[nI])) )
			Else

				aAdd(aAux, (cAliasTmp)->&(aCampos[nI]) )
			EndIf
		Next nI

		aAdd(aLnPenCTRB, aAux )

		aAux := {}

		(cAliasTmp)->(DbSkip())

	EndDo

Return

/*/{Protheus.doc} fExcelRec
Responsável por gerar o Excel a ser anexado no email (Log a Receber)
@author Juliano Fernandes
@since 09/12/2019
@type function
/*/
Static Function fExcelRec(aLnImpCTE, aLnImpCRT, aLnImpCar, aLnIntCTE, aLnIntCRT, aLnIntCar, aLnPenCTE, aLnPenCRT, aLnPenCar, cArqXML)

	Local aCabImpRec	:= {}
	Local aCabIntRec	:= {}

	Local cTipoCampo	:= ""
	Local cWorkSheet	:= ""
	Local cTable		:= ""

	Local lRet			:= .F.
	Local lTotal		:= .T.
	Local lImp			:= .F.
	Local lInt			:= .F.

	Local nI			:= 0
	Local nAlign		:= 0
	Local nFormat		:= 0

	Local oFWMSEx		:= Nil

	lImp := !Empty(aLnImpCTE) .Or. !Empty(aLnImpCRT) .Or. !Empty(aLnImpCar)
	lInt := !Empty(aLnIntCTE) .Or. !Empty(aLnIntCRT) .Or. !Empty(aLnIntCar) .Or. !Empty(aLnPenCTE) .Or. !Empty(aLnPenCRT) .Or. !Empty(aLnPenCar)

	If lImp .Or. lInt
		lRet := .T.

		oFWMSEx	:= FWMSExcelEx():New()

		If lImp
			// -------------------------
			// Importação
			// -------------------------
			cWorkSheet := BSCEncode(CAT527070) // "ERRO_IMPORTACAO"
			cTable := BSCEncode(CAT527071) // "Erros de Importação"

			oFWMSEx:AddWorkSheet(cWorkSheet)
			oFWMSEx:AddTable(cWorkSheet, cTable)

			// Título do campo, Tipo do campo
			Aadd(aCabImpRec, {PadC(CAT527058, 20), "C"}) // "Tipo"
			Aadd(aCabImpRec, {PadC(CAT527059, 10), "C"}) // "Filial"
			Aadd(aCabImpRec, {PadC(CAT527060, 15), "D"}) // "Data"
			Aadd(aCabImpRec, {PadC(CAT527061, 15), "C"}) // "Hora"
			Aadd(aCabImpRec, {PadC(CAT527062, 20), "C"}) // "Registro"
			Aadd(aCabImpRec, {PadC(CAT527063, 40), "C"}) // "Cliente"
			Aadd(aCabImpRec, {PadC(CAT527064, 20), "N"}) // "Valor"
			Aadd(aCabImpRec, {PadC(CAT527065, 30), "C"}) // "Arquivo"
			Aadd(aCabImpRec, {PadC(CAT527066, 15), "N"}) // "Linha"
			Aadd(aCabImpRec, {PadC(CAT527067, 60), "C"}) // "Mensagem"

			For nI := 1 To Len(aCabImpRec)
				cTipoCampo := aCabImpRec[nI,2]

				If cTipoCampo == "N"
					nAlign	:= 3	// Right
					nFormat	:= 2	// Number
				ElseIf cTipoCampo == "D"
					nAlign	:= 2	// Center
					nFormat	:= 4	// Date
				Else
					nAlign	:= 1	// Left
					nFormat	:= 1	// General
				EndIf

				oFWMSEx:AddColumn(cWorkSheet, cTable, aCabImpRec[nI,1], nAlign, nFormat, !lTotal)
			Next nI

			For nI := 1 To Len(aLnImpCTE)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnImpCTE[nI])
			Next nI

			For nI := 1 To Len(aLnImpCRT)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnImpCRT[nI])
			Next nI

			For nI := 1 To Len(aLnImpCar)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnImpCar[nI])
			Next nI
		EndIf

		If lInt
			// -------------------------
			// Integração e pendencias
			// -------------------------
			cWorkSheet := BSCEncode(CAT527072) // "ERRO_INTEGRACAO"
			cTable := BSCEncode(CAT527073) // "Erros de Integração"

			oFWMSEx:AddWorkSheet(cWorkSheet)
			oFWMSEx:AddTable(cWorkSheet, cTable)

			// Título do campo, Tipo do campo
			Aadd(aCabIntRec, {PadC(CAT527058, 20), "C"}) // "Tipo"
			Aadd(aCabIntRec, {PadC(CAT527059, 10), "C"}) // "Filial"
			Aadd(aCabIntRec, {PadC(CAT527060, 15), "D"}) // "Data"
			Aadd(aCabIntRec, {PadC(CAT527062, 20), "C"}) // "Registro"
			Aadd(aCabIntRec, {PadC(CAT527063, 40), "C"}) // "Cliente"
			Aadd(aCabIntRec, {PadC(CAT527064, 20), "N"}) // "Valor"
			Aadd(aCabIntRec, {PadC(CAT527068, 10), "C"}) // "Moeda"
			Aadd(aCabIntRec, {PadC(CAT527067, 60), "C"}) // "Mensagem"

			For nI := 1 To Len(aCabIntRec)
				cTipoCampo := aCabIntRec[nI,2]

				If cTipoCampo == "N"
					nAlign	:= 3	// Right
					nFormat	:= 2	// Number
				ElseIf cTipoCampo == "D"
					nAlign	:= 2	// Center
					nFormat	:= 4	// Date
				Else
					nAlign	:= 1	// Left
					nFormat	:= 1	// General
				EndIf

				oFWMSEx:AddColumn(cWorkSheet, cTable, aCabIntRec[nI,1], nAlign, nFormat, !lTotal)
			Next nI

			For nI := 1 To Len(aLnIntCTE)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnIntCTE[nI])
			Next nI

			For nI := 1 To Len(aLnIntCRT)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnIntCRT[nI])
			Next nI

			For nI := 1 To Len(aLnIntCar)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnIntCar[nI])
			Next nI

			For nI := 1 To Len(aLnPenCTE)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnPenCTE[nI])
			Next nI

			For nI := 1 To Len(aLnPenCRT)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnPenCRT[nI])
			Next nI

			For nI := 1 To Len(aLnPenCar)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnPenCar[nI])
			Next nI
		EndIf

	    oFWMsEx:Activate()
	    oFWMsEx:GetXMLFile(cArqXML + ".xls")

		oFWMsEx:DeActivate()
	EndIf

Return(lRet)

/*/{Protheus.doc} fExcelPag
Responsável por gerar o Excel a ser anexado no email (Log a Pagar)
@author Juliano Fernandes
@since 10/12/2019
@type function
/*/
Static Function fExcelPag(aLnImpCTRB, aLnIntCTRB, aLnPenCTRB, cArqXML)

	Local aCabImpPag	:= {}
	Local aCabIntPag	:= {}

	Local cTipoCampo	:= ""
	Local cWorkSheet	:= ""
	Local cTable		:= ""

	Local lRet			:= .F.
	Local lTotal		:= .T.
	Local lImp			:= .F.
	Local lInt			:= .F.

	Local nI			:= 0
	Local nAlign		:= 0
	Local nFormat		:= 0

	Local oFWMSEx		:= Nil

	lImp := !Empty(aLnImpCTRB)
	lInt := !Empty(aLnIntCTRB) .Or. !Empty(aLnPenCTRB)

	If lImp .Or. lInt
		lRet := .T.

		oFWMSEx	:= FWMSExcelEx():New()

		If lImp
			// -------------------------
			// Importação
			// -------------------------
			cWorkSheet := BSCEncode(CAT527070) // "ERRO_IMPORTACAO"
			cTable := BSCEncode(CAT527071) // "Erros de Importação"

			oFWMSEx:AddWorkSheet(cWorkSheet)
			oFWMSEx:AddTable(cWorkSheet, cTable)

			Aadd(aCabImpPag, {PadC(CAT527058, 20), "C"}) // "Tipo"
			Aadd(aCabImpPag, {PadC(CAT527059, 10), "C"}) // "Filial"
			Aadd(aCabImpPag, {PadC(CAT527060, 15), "D"}) // "Data"
			Aadd(aCabImpPag, {PadC(CAT527061, 15), "C"}) // "Hora"
			Aadd(aCabImpPag, {PadC(CAT527062, 20), "C"}) // "Registro"
			Aadd(aCabImpPag, {PadC(CAT527065, 30), "C"}) // "Arquivo"
			Aadd(aCabImpPag, {PadC(CAT527066, 15), "N"}) // "Linha"
			Aadd(aCabImpPag, {PadC(CAT527067, 60), "C"}) // "Mensagem"

			For nI := 1 To Len(aCabImpPag)
				cTipoCampo := aCabImpPag[nI,2]

				If cTipoCampo == "N"
					nAlign	:= 3	// Right
					nFormat	:= 2	// Number
				ElseIf cTipoCampo == "D"
					nAlign	:= 2	// Center
					nFormat	:= 4	// Date
				Else
					nAlign	:= 1	// Left
					nFormat	:= 1	// General
				EndIf

				oFWMSEx:AddColumn(cWorkSheet, cTable, aCabImpPag[nI,1], nAlign, nFormat, !lTotal)
			Next nI

			For nI := 1 To Len(aLnImpCTRB)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnImpCTRB[nI])
			Next nI
		EndIf

		If lInt
			// -------------------------
			// Integração e pendencias
			// -------------------------
			cWorkSheet := BSCEncode(CAT527072) // "ERRO_INTEGRACAO"
			cTable := BSCEncode(CAT527073) // "Erros de Integração"

			oFWMSEx:AddWorkSheet(cWorkSheet)
			oFWMSEx:AddTable(cWorkSheet, cTable)

			Aadd(aCabIntPag, {PadC(CAT527058, 20), "C"}) // "Tipo"
			Aadd(aCabIntPag, {PadC(CAT527059, 10), "C"}) // "Filial"
			Aadd(aCabIntPag, {PadC(CAT527060, 15), "D"}) // "Data"
			Aadd(aCabIntPag, {PadC(CAT527062, 20), "C"}) // "Registro"
			Aadd(aCabIntPag, {PadC(CAT527067, 60), "C"}) // "Mensagem"

			For nI := 1 To Len(aCabIntPag)
				cTipoCampo := aCabIntPag[nI,2]

				If cTipoCampo == "N"
					nAlign	:= 3	// Right
					nFormat	:= 2	// Number
				ElseIf cTipoCampo == "D"
					nAlign	:= 2	// Center
					nFormat	:= 4	// Date
				Else
					nAlign	:= 1	// Left
					nFormat	:= 1	// General
				EndIf

				oFWMSEx:AddColumn(cWorkSheet, cTable, aCabIntPag[nI,1], nAlign, nFormat, !lTotal)
			Next nI

			For nI := 1 To Len(aLnIntCTRB)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnIntCTRB[nI])
			Next nI

			For nI := 1 To Len(aLnPenCTRB)
				oFWMSEx:AddRow(cWorkSheet, cTable, aLnPenCTRB[nI])
			Next nI
		EndIf

	    oFWMsEx:Activate()
	    oFWMsEx:GetXMLFile(cArqXML + ".xls")

		oFWMsEx:DeActivate()
	EndIf

Return(lRet)

/*/{Protheus.doc} fLogSched
Função para a criação e gravação de arquivo de Log exclusivo da
importação / integração automáticas (Schedule).
@author Juliano Fernandes
@since 19/11/2019
@version 1.0
@param nOpc, numerico, Opção: 1=Criar arquivo ; 2=Gravar arquivo ; 3=Abrir arquivo ; 4=Fechar arquivo
@param nHdl, numerico, Código do arquivo que deve ser gravado, aberto ou fechado
@param cTexto, caracter, Texto a ser gravado no arquivo
@return Nil, Não há retorno
@type function
/*/
Static Function fLogSched(nOpc, nHdl, cTexto)

	Local cBarra	:= IIf(IsSrvUnix(),"/","\")
	Local cDirLog	:= cBarra + "Log_Schedule"
	Local cArqLog	:= "Log_" + cIdSched + ".log"

	If nOpc == 1 // Criar arquivo log

		If !ExistDir(cDirLog)
			MakeDir(cDirLog)
		EndIf

		If ExistDir(cDirLog)
			nHdl := FCreate(cDirLog + cBarra + cArqLog)
		EndIf

	ElseIf nOpc == 2 // Gravar arquivo log

		If nHdl > 0
			// Posiciona no fim do arquivo
			FSeek(nHdl, 0, FS_END)

			FWrite(nHdl, cTexto + CRLF)
		EndIf

	ElseIf nOpc == 3 // Abrir o arquivo log

		nHdl := FOpen(cDirLog + cBarra + cArqLog, FO_READWRITE)

		If nHdl > 0
			// Posiciona no fim do arquivo
			FSeek(nHdl, 0, FS_END)
		EndIf

	Else // Fechar arquivo log

		FClose(nHdl)

	EndIf

Return(Nil)

/*/{Protheus.doc} fOrdArq
Ordena os arquivos a serem processados conforme o final do nome do arquivo.
@author Juliano Fernandes
@since 06/04/2020
@version 1.0
@param aFiles, array, Arquivos a serem ordenados
@return Nil, Não há retorno
@type function
/*/
Static Function fOrdArq(aFiles)

	Local aAux		:= AClone(aFiles)
	Local aFinArq	:= {}

	Local cNomeArq	:= ""
	Local cFinArq	:= ""

	Local nI		:= 0
	Local nJ		:= 0

	If Len(aFiles) > 1
		For nI := 1 To Len(aFiles)
			// Obtém o nome do arquivo sem extensão
			cNomeArq := Substr(aFiles[nI,1], 1, RAt(".", aFiles[nI,1]) - 1)

			// Obtém os 2 últimos números do nome do arquivo
			cFinArq := Right(cNomeArq, 2)

			If AScan(aFinArq, cFinArq) == 0
				Aadd(aFinArq, cFinArq)
			EndIf
		Next nI

		If Len(aFinArq) > 1
			ASort(aFinArq)

			aFiles := {}

			For nI := 1 To Len(aFinArq)
				For nJ := 1 To Len(aAux)
					// Obtém o nome do arquivo sem extensão
					cNomeArq := Substr(aAux[nJ,1], 1, RAt(".", aAux[nJ,1]) - 1)

					// Obtém os 2 últimos números do nome do arquivo
					cFinArq := Right(cNomeArq, 2)

					If cFinArq == aFinArq[nI]
						Aadd(aFiles, aAux[nJ])
					EndIf
				Next nJ
			Next nI
		EndIf
	EndIf

Return(Nil)

/*/{Protheus.doc} intApi
Função de integração com a api Atua
@author Tiago Malta
@since 18/10/2021
@version 1.0
@return array
@type function
/*/

Static Function intApi(cAxICnpj)

Local aHeader  		:= {}
Local oRestClient
Local cUrl 			:= "https://consulta.maisfrete.com.br"
Local cError		:= ""
Local cWarning		:= ""
Local aDados		:= {}
Local i
Local cXml			:= ""
Local cJson			:= ""
Local cAxCnpj		:= ""
Local nPos			:= 0
Local cAxCodF		:= ""
Local cSitx			:= ""
Local nI
Local cTpCte		:= ""
Local cModelo		:= ""
Local cIntUser		:= Alltrim(GetMv("PLG_INUSER"))
Local cIntPass		:= Alltrim(GetMv("PLG_INPASS"))

Private oXml
Private oAux

    oRestClient := FWRest():New(cUrl)

   	Aadd(aHeader,"Authorization: Basic " + Encode64(cIntUser+":"+cIntPass))	//integracao:gt.2021
	Aadd(aHeader,"Content-Type: multipart/form-data") 
	Aadd(aHeader,"Accept: application/json")

    oRestClient:setPath("/api/contabilidade/index.php")

	cJson := 'Content-Disposition: form-data; name="conjunto_de_dados"' + CRLF + CRLF 
	cJson += 'ctrcs' + CRLF

	cJson += 'Content-Disposition: form-data; name="cnpj"' + CRLF + CRLF 
	cJson += cAxICnpj + CRLF 

	cJson += 'Content-Disposition: form-data; name="dt_ini"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataD),1,4) + "-" + Substr(Dtos(dDataD),5,2) + "-" + Substr(Dtos(dDataD),7,2) + CRLF // '2021-08-01'

	cJson += 'Content-Disposition: form-data; name="dt_fim"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataA),1,4) + "-" + Substr(Dtos(dDataA),5,2) + "-" + Substr(Dtos(dDataA),7,2) + CRLF //'2021-08-30' 

	cJson += 'Content-Disposition: form-data; name="id"' + CRLF + CRLF 
	cJson += '' + CRLF 

	cJson += 'Content-Disposition: form-data; name="ambiente"' + CRLF + CRLF 
	cJson += Alltrim(GetMV("PLG_AMBATU")) + CRLF //'2'

	oRestClient:SetPostParams(cJson)
	
	If oRestClient:Post(aHeader)
		//ConOut("POST", oRestClient:GetResult())

		cXml := oRestClient:GetResult()

		oXml := XmlParser( cXml, "_", @cError, @cWarning )

		If Type("oXml:_CTRCS:_CTRC") == "A"

			For i := 1 to Len(oXml:_CTRCS:_CTRC)

				cAxCnpj := Alltrim(oXml:_CTRCS:_CTRC[i]:_EMITENTE:_CNPJCPF:TEXT)
				nPos := Ascan(aFilsProc,{|x| Alltrim(x[18]) == cAxCnpj })
				If nPos > 0
					cAxCodF := aFilsProc[nPos][02]
				EndIf

				oAux := oXml:_CTRCS:_CTRC[i]

				cSitx  := Alltrim(oXml:_CTRCS:_CTRC[i]:_situacao:TEXT)
				cModelo:= Upper(Alltrim(oXml:_CTRCS:_CTRC[i]:_modelo:TEXT))
				cTpCte := If( cSitx $ "CANCELADO*AUTORIZADO*",Upper(Alltrim(oXml:_CTRCS:_CTRC[i]:_cte:_tpCte:TEXT)),"")
				cTpCte := if(cTpCte=="NORMAL","0",if(cTpCte=="CTE DE COMPLEMENTO DE VALORES","1",if(cTpCte=="CTE DE ANULAÇÃO","2",if(cTpCte=="CTE SUBSTITUTO","3","4"))))

				If cSitx $ "CANCELADO*AUTORIZADO*" .AND. cTpCte <> "4" .AND. cModelo <> "CE"

					aAdd( aDados, Array(40) )

					nI := len(aDados)

					aDados[nI][1] := cAxCodF  	//1 Filial 
					aDados[nI][2] := "ZTRC"  	//2 Tipo de Contrato. Ex: CRT = "ZCRT", CTRC  =  "ZTRC"
					aDados[nI][3] := PadL(ALLTRIM(oXml:_CTRCS:_CTRC[i]:_ID:TEXT),9,"0")  //3 ID
					aDados[nI][4] := Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_CNPJCPF:TEXT)  //4 CNPJ REMETENTE
					aDados[nI][5] := UPPER(oXml:_CTRCS:_CTRC[i]:_MODELO:TEXT) //5 MODELO

					If Type("oAux:_CTE:_CHAVE:TEXT") <> "U"
						aDados[nI][6] := oAux:_CTE:_CHAVE:TEXT //6
					Else
						aDados[nI][6] := "" //6
					Endif

					aDados[nI][7] := oXml:_CTRCS:_CTRC[i]:_CTE:_PROTOCOLO:TEXT //7
					aDados[nI][8] := Stod(StrTran(Substr(oXml:_CTRCS:_CTRC[i]:_EMISSAO:TEXT,1,10),"-","")) //8
					aDados[nI][9] := Val(oXml:_CTRCS:_CTRC[i]:_vlTotal:TEXT) //9
					aDados[nI][10]:= Val(oXml:_CTRCS:_CTRC[i]:_vlPedagio:TEXT) //10
					aDados[nI][11]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_ibge:TEXT) //Alltrim(oXml:_CTRCS:_CTRC[i]:_ibgeOrigem:TEXT) //11
					aDados[nI][12]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_ibgeDestino:TEXT) //12
					aDados[nI][13]:= oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_ITEM:TEXT //13
					aDados[nI][14]:= oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_unidade:TEXT //14
					aDados[nI][15]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_quantidade:TEXT) //15
					aDados[nI][16]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_peso:TEXT) //16
					aDados[nI][17]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_valor:TEXT) //17
					aDados[nI][18]:= oXml:_CTRCS:_CTRC[i]:_cfop:TEXT //18
					aDados[nI][19]:= oXml:_CTRCS:_CTRC[i]:_icms:_cst:TEXT //19
					aDados[nI][20]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlBase:TEXT) //20
					aDados[nI][21]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_valor:TEXT) //21
					aDados[nI][22]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_valorSt:TEXT) //22
					aDados[nI][23]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlOutras:TEXT) //23
					aDados[nI][24]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlIsento:TEXT) //24

					If Type("oAux:_pisCofins") <> "U"
						aDados[nI][25]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlBase:TEXT) //25
						aDados[nI][26]:= oXml:_CTRCS:_CTRC[i]:_pisCofins:_cst:TEXT //26
						aDados[nI][27]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_prPis:TEXT) //27
						aDados[nI][28]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlPis:TEXT) //28
						aDados[nI][29]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_prCofins:TEXT) //29
						aDados[nI][30]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlCofins:TEXT) //30
					Else
						aDados[nI][25]:= 0 //25
						aDados[nI][26]:= "" //26
						aDados[nI][27]:= 0 //27
						aDados[nI][28]:= 0 //28
						aDados[nI][29]:= 0 //29
						aDados[nI][30]:= 0 //30
					Endif

					aDados[nI][31]:= oXml:_CTRCS:_CTRC[i]:_motorista:_nome:TEXT //31
					aDados[nI][32]:= oXml:_CTRCS:_CTRC[i]:_motorista:_cnpjCpf:TEXT //32
					aDados[nI][33]:= PadL(ALLTRIM(oXml:_CTRCS:_CTRC[i]:_NUMERO:TEXT),9,"0") //33
					aDados[nI][34]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_UF:TEXT) //34
					aDados[nI][35]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_destinatario:_UF:TEXT) //35
					aDados[nI][36]:= If(cSitx=="CANCELADO","C"," ") //36
					aDados[nI][37]:= cTpCte //37

					If Type("oAux:_CTE:_nrChaveRef:TEXT") <> "U" // .and. cTpCte == "2"
						aDados[nI][38] := oAux:_CTE:_nrChaveRef:TEXT //38	
					Else
						aDados[nI][38] := "" //38
					Endif

					aDados[nI][39] := cAxProd
					aDados[nI][40] := cAxNat

					If cSitx == "CANCELADO" //Verifica se não existe o registro autorizado

						DbSelectArea("UQD")
						UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
						If !UQD->(DbSeek( cAxCodF + Padr( PadL(ALLTRIM(oXml:_CTRCS:_CTRC[i]:_NUMERO:TEXT),9,"0") , TamSX3("UQD_NUMERO")[1]) + " " ))

							aAdd( aDados, Array(40) )
							
							nI := len(aDados)

							aDados[nI][1] := cAxCodF  	//1 Filial 
							aDados[nI][2] := "ZTRC"  	//2 Tipo de Contrato. Ex: CRT = "ZCRT", CTRC  =  "ZTRC"
							aDados[nI][3] := PadL(ALLTRIM(oXml:_CTRCS:_CTRC[i]:_ID:TEXT),9,"0")  //3 ID
							aDados[nI][4] := Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_CNPJCPF:TEXT)  //4 CNPJ REMETENTE
							aDados[nI][5] := UPPER(oXml:_CTRCS:_CTRC[i]:_MODELO:TEXT) //5 MODELO

							If Type("oAux:_CTE:_CHAVE:TEXT") <> "U"
								aDados[nI][6] := oAux:_CTE:_CHAVE:TEXT //6
							Else
								aDados[nI][6] := "" //6
							Endif

							aDados[nI][7] := oXml:_CTRCS:_CTRC[i]:_CTE:_PROTOCOLO:TEXT //7
							aDados[nI][8] := Stod(StrTran(Substr(oXml:_CTRCS:_CTRC[i]:_EMISSAO:TEXT,1,10),"-","")) //8
							aDados[nI][9] := Val(oXml:_CTRCS:_CTRC[i]:_vlTotal:TEXT) //9
							aDados[nI][10]:= Val(oXml:_CTRCS:_CTRC[i]:_vlPedagio:TEXT) //10
							aDados[nI][11]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_ibge:TEXT) //Alltrim(oXml:_CTRCS:_CTRC[i]:_ibgeOrigem:TEXT) //11
							aDados[nI][12]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_ibgeDestino:TEXT) //12
							aDados[nI][13]:= oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_ITEM:TEXT //13
							aDados[nI][14]:= oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_unidade:TEXT //14
							aDados[nI][15]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_quantidade:TEXT) //15
							aDados[nI][16]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_peso:TEXT) //16
							aDados[nI][17]:= Val(oXml:_CTRCS:_CTRC[i]:_PRODUTOS:_PRODUTO:_valor:TEXT) //17
							aDados[nI][18]:= oXml:_CTRCS:_CTRC[i]:_cfop:TEXT //18
							aDados[nI][19]:= oXml:_CTRCS:_CTRC[i]:_icms:_cst:TEXT //19
							aDados[nI][20]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlBase:TEXT) //20
							aDados[nI][21]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_valor:TEXT) //21
							aDados[nI][22]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_valorSt:TEXT) //22
							aDados[nI][23]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlOutras:TEXT) //23
							aDados[nI][24]:= Val(oXml:_CTRCS:_CTRC[i]:_icms:_vlIsento:TEXT) //24

							If Type("oAux:_pisCofins") <> "U"
								aDados[nI][25]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlBase:TEXT) //25
								aDados[nI][26]:= oXml:_CTRCS:_CTRC[i]:_pisCofins:_cst:TEXT //26
								aDados[nI][27]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_prPis:TEXT) //27
								aDados[nI][28]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlPis:TEXT) //28
								aDados[nI][29]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_prCofins:TEXT) //29
								aDados[nI][30]:= Val(oXml:_CTRCS:_CTRC[i]:_pisCofins:_vlCofins:TEXT) //30
							Else
								aDados[nI][25]:= 0 //25
								aDados[nI][26]:= "" //26
								aDados[nI][27]:= 0 //27
								aDados[nI][28]:= 0 //28
								aDados[nI][29]:= 0 //29
								aDados[nI][30]:= 0 //30
							Endif

							aDados[nI][31]:= oXml:_CTRCS:_CTRC[i]:_motorista:_nome:TEXT //31
							aDados[nI][32]:= oXml:_CTRCS:_CTRC[i]:_motorista:_cnpjCpf:TEXT //32
							aDados[nI][33]:= PadL(ALLTRIM(oXml:_CTRCS:_CTRC[i]:_NUMERO:TEXT),9,"0") //33
							aDados[nI][34]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_REMETENTE:_UF:TEXT) //34
							aDados[nI][35]:= Alltrim(oXml:_CTRCS:_CTRC[i]:_destinatario:_UF:TEXT) //35
							aDados[nI][36]:= " " //36
							aDados[nI][37]:= cTpCte //37

							//If Type("oAux:_CTE:_nrChaveRef:TEXT") <> "U" //.and. cTpCte == "2"
							//	aDados[nI][38] := oAux:_CTE:_nrChaveRef:TEXT //38							
							//Else
								aDados[nI][38] := "" //38
							//Endif

							aDados[nI][39] := cAxProd
							aDados[nI][40] := cAxNat

						Endif

					Endif

				Endif

			Next i

		Elseif Type("oXml:_CTRCS:_CTRC") == "O"

			cAxCnpj := Alltrim(oXml:_CTRCS:_CTRC:_EMITENTE:_CNPJCPF:TEXT)
			nPos := Ascan(aFilsProc,{|x| Alltrim(x[18]) == cAxCnpj })
			If nPos > 0
				cAxCodF := aFilsProc[nPos][02]
			EndIf

			cModelo:= Upper(Alltrim(oXml:_CTRCS:_CTRC:_modelo:TEXT))
			cSitx := Alltrim(oXml:_CTRCS:_CTRC:_situacao:TEXT)
			cTpCte := If( cSitx $ "CANCELADO*AUTORIZADO*",Upper(Alltrim(oXml:_CTRCS:_CTRC:_cte:_tpCte:TEXT)),"")
			cTpCte := if(cTpCte=="NORMAL","0",if(cTpCte=="CTE DE COMPLEMENTO DE VALORES","1",if(cTpCte=="CTE DE ANULAÇÃO","2",if(cTpCte=="CTE SUBSTITUTO","3","4"))))
			If cSitx $ "CANCELADO*AUTORIZADO*" .AND. cTpCte <> "4" .AND. cModelo <> "CE"

				aAdd( aDados, Array(40) )

				nI := len(aDados)

				aDados[nI][1] := cAxCodF  	//1 Filial 
				aDados[nI][2] := "ZTRC"  	//2 Tipo de Contrato. Ex: CRT = "ZCRT", CTRC  =  "ZTRC"
				aDados[nI][3] := PadL(ALLTRIM(oXml:_CTRCS:_CTRC:_ID:TEXT),9,"0")  //3 ID
				aDados[nI][4] := Alltrim(oXml:_CTRCS:_CTRC:_REMETENTE:_CNPJCPF:TEXT)  //4 CNPJ REMETENTE
				aDados[nI][5] := UPPER(oXml:_CTRCS:_CTRC:_MODELO:TEXT) //5 MODELO

				If Type("oXml:_CTRCS:_CTRC:_CTE:_CHAVE:TEXT") <> "U"
					aDados[nI][6] := oXml:_CTRCS:_CTRC:_CTE:_CHAVE:TEXT //6
				Else
					aDados[nI][6] := "" //6
				Endif

				aDados[nI][7] := oXml:_CTRCS:_CTRC:_CTE:_PROTOCOLO:TEXT //7
				aDados[nI][8] := Stod(StrTran(Substr(oXml:_CTRCS:_CTRC:_EMISSAO:TEXT,1,10),"-","")) //8
				aDados[nI][9] := Val(oXml:_CTRCS:_CTRC:_vlTotal:TEXT) //9
				aDados[nI][10]:= Val(oXml:_CTRCS:_CTRC:_vlPedagio:TEXT) //10
				aDados[nI][11]:= Alltrim(oXml:_CTRCS:_CTRC:_ibgeOrigem:TEXT) //11
				aDados[nI][12]:= Alltrim(oXml:_CTRCS:_CTRC:_ibgeDestino:TEXT) //12
				aDados[nI][13]:= oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_ITEM:TEXT //13
				aDados[nI][14]:= oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_unidade:TEXT //14
				aDados[nI][15]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_quantidade:TEXT) //15
				aDados[nI][16]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_peso:TEXT) //16
				aDados[nI][17]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_valor:TEXT) //17
				aDados[nI][18]:= oXml:_CTRCS:_CTRC:_cfop:TEXT //18
				aDados[nI][19]:= oXml:_CTRCS:_CTRC:_icms:_cst:TEXT //19
				aDados[nI][20]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlBase:TEXT) //20
				aDados[nI][21]:= Val(oXml:_CTRCS:_CTRC:_icms:_valor:TEXT) //21
				aDados[nI][22]:= Val(oXml:_CTRCS:_CTRC:_icms:_valorSt:TEXT) //22
				aDados[nI][23]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlOutras:TEXT) //23
				aDados[nI][24]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlIsento:TEXT) //24

				If Type("oXml:_CTRCS:_CTRC:_pisCofins") <> "U"
					aDados[nI][25]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlBase:TEXT) //25
					aDados[nI][26]:= oXml:_CTRCS:_CTRC:_pisCofins:_cst:TEXT //26
					aDados[nI][27]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_prPis:TEXT) //27
					aDados[nI][28]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlPis:TEXT) //28
					aDados[nI][29]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_prCofins:TEXT) //29
					aDados[nI][30]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlCofins:TEXT) //30
				Else
					aDados[nI][25]:= 0 //25
					aDados[nI][26]:= "" //26
					aDados[nI][27]:= 0 //27
					aDados[nI][28]:= 0 //28
					aDados[nI][29]:= 0 //29
					aDados[nI][30]:= 0 //30
				Endif

				aDados[nI][31]:= oXml:_CTRCS:_CTRC:_motorista:_nome:TEXT //31
				aDados[nI][32]:= oXml:_CTRCS:_CTRC:_motorista:_cnpjCpf:TEXT //32
				aDados[nI][33]:= PadL(ALLTRIM(oXml:_CTRCS:_CTRC:_NUMERO:TEXT),9,"0") //33
				aDados[nI][34]:= Alltrim(oXml:_CTRCS:_CTRC:_REMETENTE:_UF:TEXT) //34
				aDados[nI][35]:= Alltrim(oXml:_CTRCS:_CTRC:_destinatario:_UF:TEXT) //35
				aDados[nI][36]:= If(cSitx=="CANCELADO","C"," ") //36
				aDados[nI][37]:= cTpCte //37

				If Type("oXml:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT") <> "U" //.and. cTpCte == "2"
					aDados[nI][38] := oXml:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT //38	
				Else
					aDados[nI][38] := "" //38
				Endif

				aDados[nI][39] := cAxProd
				aDados[nI][40] := cAxNat

				If cSitx == "CANCELADO" //Verifica se não existe o registro autorizado

					DbSelectArea("UQD")
					UQD->(DbSetOrder(2)) //UQD_FILIAL+UQD_NUMERO+UQD_CANCEL
					If !UQD->(DbSeek( cAxCodF + Padr( PadL(ALLTRIM(oXml:_CTRCS:_CTRC:_NUMERO:TEXT),9,"0") , TamSX3("UQD_NUMERO")[1]) + " " ))

						aAdd( aDados, Array(40) )

						nI := len(aDados)

						aDados[nI][1] := cAxCodF  	//1 Filial 
						aDados[nI][2] := "ZTRC"  	//2 Tipo de Contrato. Ex: CRT = "ZCRT", CTRC  =  "ZTRC"
						aDados[nI][3] := PadL(ALLTRIM(oXml:_CTRCS:_CTRC:_ID:TEXT),9,"0")  //3 ID
						aDados[nI][4] := Alltrim(oXml:_CTRCS:_CTRC:_REMETENTE:_CNPJCPF:TEXT)  //4 CNPJ REMETENTE
						aDados[nI][5] := UPPER(oXml:_CTRCS:_CTRC:_MODELO:TEXT) //5 MODELO

						If Type("oXml:_CTRCS:_CTRC:_CTE:_CHAVE:TEXT") <> "U"
							aDados[nI][6] := oXml:_CTRCS:_CTRC:_CTE:_CHAVE:TEXT //6
						Else
							aDados[nI][6] := "" //6
						Endif

						aDados[nI][7] := oXml:_CTRCS:_CTRC:_CTE:_PROTOCOLO:TEXT //7
						aDados[nI][8] := Stod(StrTran(Substr(oXml:_CTRCS:_CTRC:_EMISSAO:TEXT,1,10),"-","")) //8
						aDados[nI][9] := Val(oXml:_CTRCS:_CTRC:_vlTotal:TEXT) //9
						aDados[nI][10]:= Val(oXml:_CTRCS:_CTRC:_vlPedagio:TEXT) //10
						aDados[nI][11]:= Alltrim(oXml:_CTRCS:_CTRC:_ibgeOrigem:TEXT) //11
						aDados[nI][12]:= Alltrim(oXml:_CTRCS:_CTRC:_ibgeDestino:TEXT) //12
						aDados[nI][13]:= oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_ITEM:TEXT //13
						aDados[nI][14]:= oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_unidade:TEXT //14
						aDados[nI][15]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_quantidade:TEXT) //15
						aDados[nI][16]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_peso:TEXT) //16
						aDados[nI][17]:= Val(oXml:_CTRCS:_CTRC:_PRODUTOS:_PRODUTO:_valor:TEXT) //17
						aDados[nI][18]:= oXml:_CTRCS:_CTRC:_cfop:TEXT //18
						aDados[nI][19]:= oXml:_CTRCS:_CTRC:_icms:_cst:TEXT //19
						aDados[nI][20]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlBase:TEXT) //20
						aDados[nI][21]:= Val(oXml:_CTRCS:_CTRC:_icms:_valor:TEXT) //21
						aDados[nI][22]:= Val(oXml:_CTRCS:_CTRC:_icms:_valorSt:TEXT) //22
						aDados[nI][23]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlOutras:TEXT) //23
						aDados[nI][24]:= Val(oXml:_CTRCS:_CTRC:_icms:_vlIsento:TEXT) //24

						If Type("oXml:_CTRCS:_CTRC:_pisCofins") <> "U"
							aDados[nI][25]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlBase:TEXT) //25
							aDados[nI][26]:= oXml:_CTRCS:_CTRC:_pisCofins:_cst:TEXT //26
							aDados[nI][27]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_prPis:TEXT) //27
							aDados[nI][28]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlPis:TEXT) //28
							aDados[nI][29]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_prCofins:TEXT) //29
							aDados[nI][30]:= Val(oXml:_CTRCS:_CTRC:_pisCofins:_vlCofins:TEXT) //30
						Else
							aDados[nI][25]:= 0 //25
							aDados[nI][26]:= "" //26
							aDados[nI][27]:= 0 //27
							aDados[nI][28]:= 0 //28
							aDados[nI][29]:= 0 //29
							aDados[nI][30]:= 0 //30
						Endif

						aDados[nI][31]:= oXml:_CTRCS:_CTRC:_motorista:_nome:TEXT //31
						aDados[nI][32]:= oXml:_CTRCS:_CTRC:_motorista:_cnpjCpf:TEXT //32
						aDados[nI][33]:= PadL(ALLTRIM(oXml:_CTRCS:_CTRC:_NUMERO:TEXT),9,"0") //33
						aDados[nI][34]:= Alltrim(oXml:_CTRCS:_CTRC:_REMETENTE:_UF:TEXT) //34
						aDados[nI][35]:= Alltrim(oXml:_CTRCS:_CTRC:_destinatario:_UF:TEXT) //35
						aDados[nI][36]:= " " //36
						aDados[nI][37]:= cTpCte //37

						//If Type("oXml:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT") <> "U" //.and. cTpCte == "2"
						//	aDados[nI][38] := oXml:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT //38	
						//Else
							aDados[nI][38] := "" //38
						//Endif

						aDados[nI][39] := cAxProd
						aDados[nI][40] := cAxNat

					Endif

				Endif

			Endif

		Endif
	Else        
		//If Empty(oRestClient:ORESPONSEH:CSTATUSCODE)
		//	oRestClient:ORESPONSEH:CSTATUSCODE := HttpGetStatus()
		//Endif	   	
		//Alert("erro, Erro:"+U_GetHttpCod(oRestClient:ORESPONSEH:CSTATUSCODE))
	EndIf

		
return aDados

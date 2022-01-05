#include "protheus.ch"
#include "parmtype.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fProcCF l ºAutor  ³Reginaldo G Ribeiro º Data ³  23/09/21   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³      ±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                               º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function fProcCF()
local aInfo   
Local aRet			:= {}
Local aParamBox		:= {}
Local lPercOk		:= .F.
Private cEmpDe		:= space(Len(cFilAnt))
Private cEmpAte		:= space(Len(cFilAnt))
Private dDataD		:= Ctod("//")
Private dDataA		:= Ctod("//")
Private cBanco      := SuperGetMv("MV_XBCOCF",.F.,"341")
Private cAgencia    := SuperGetMv("MV_XAGECF",.F.,"0113")
Private cConta      := SuperGetMv("MV_XCTOCF",.F.,"14935")
Private cPref       := "LOG"
Private cNat        := SuperGetMV("MV_XNATCF",.F.,"202001")
Private aFilsProc	:= FWLoadSM0()
Private cCondPg     := SuperGetMV("MV_XCPCF",.F.,"422")
aEmpProc := FWAllGrpCompany()

    aAdd(aParamBox ,{1,"Empresa De"	,cEmpDe		,"@!","","XM0"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Empresa Ate",cEmpAte	,"@!","","XM0"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Data De"	,dDataD		,"","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Data Ate"	,dDataA		,"","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Banco PA"   ,cBanco		,"@!","","SA6"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Agencia PA"	,cAgencia	,"@!","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Conta PA"	,cConta	    ,"@!","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Prefixo"	,cPref	    ,"@!","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Natureza"	,cNat	    ,"@!","",""	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Cond. Pgto"	,cCondPg    ,"@!","",""	,""	,50,.T.})
    If ParamBox(aParamBox,"Parametros",@aRet)
        cEmpDe  := aRet[1]
        cEmpAte := aRet[2]
        dDataD  := aRet[3]
        dDataA  := aRet[4]
        cBanco  := aRet[5]
        cAgencia:= aRet[6]
        cConta  := aRet[7]
        cPref   := aRet[8]
        cNat    := aRet[9]
        lPercOk := .T.
    Endif
    For i := 1 to Len(aFilsProc)
        If aFilsProc[i][2] >= cEmpDe .and. aFilsProc[i][2] <= cEmpAte
            cAxCnpj := aFilsProc[i][18]
            aInfo:=Processa( {|| fGetApi(cAxCnpj) }, "Aguarde...", "Integração Atua Carta Frete...",.T.)
        Endif
	Next i    
        
Return

Static Function fGetApi(cAxICnpj)

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
Local aArray        := {}
Local cMsgErr       := ""
Local cMemoMsg      := ""
Local cForn         := ""
Local lGrvLog       :=.T.
Local cStcf         := ""
Private oXml
Private lMsErroAuto := .F.
    DBSelectArea("SA2")
    DbSetOrder(3)
    oRestClient := FWRest():New(cUrl)

   	Aadd(aHeader,"Authorization: Basic " + Encode64("integracao:gt.2021"))	
	Aadd(aHeader,"Content-Type: multipart/form-data") 
	Aadd(aHeader,"Accept: application/json")

    oRestClient:setPath("/api/contabilidade/index.php")

	cJson := 'Content-Disposition: form-data; name="conjunto_de_dados"' + CRLF + CRLF 
	cJson += 'cartasFrete' + CRLF

	cJson += 'Content-Disposition: form-data; name="cnpj"' + CRLF + CRLF 
	cJson += cAxICnpj + CRLF 

	cJson += 'Content-Disposition: form-data; name="dt_ini"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataD),1,4) + "-" + Substr(Dtos(dDataD),5,2) + "-" + Substr(Dtos(dDataD),7,2) + CRLF // '2021-08-01'

	cJson += 'Content-Disposition: form-data; name="dt_fim"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataA),1,4) + "-" + Substr(Dtos(dDataA),5,2) + "-" + Substr(Dtos(dDataA),7,2) + CRLF //'2021-08-30' 

	cJson += 'Content-Disposition: form-data; name="id"' + CRLF + CRLF 
	cJson += '' + CRLF 

	cJson += 'Content-Disposition: form-data; name="ambiente"' + CRLF + CRLF 
	cJson += '2' + CRLF 

	oRestClient:SetPostParams(cJson)
	Begin Transaction
	If oRestClient:Post(aHeader)
		//ConOut("POST", oRestClient:GetResult() )

		cXml := oRestClient:GetResult()

		oXml := XmlParser( cXml, "_", @cError, @cWarning )

		If Type("oXml:_CARTASFRETES:_CARTAFRETE")== "A"
        	For _nzi := 1 to Len(oXml:_CARTASFRETES:_CARTAFRETE)
                oCFPagar:= oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_CARTAFRETEPARCELAMENTOS:_CARTAFRETEPARCELAMENTO
				IF tYPE("oCFPagar")=="A"
                    lCont:=.F.
                    For _nr:= 1 to Len(oCFPagar)                   
                        cCnpjPro:= oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_PROPRIETARIO:_CNPJCPF:TEXT
                        DBSelectArea("SA2")
                        DbSetOrder(3)
                        If SA2->(dbSeek(xFilial("SA2")+cCnpjPro))
                            // VERIFICA SE O iD JA FOI PROCESSADO
                            cForn:= SA2->A2_COD
                            If !fVerSC7(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT) .or. lCont
                                cAdministradora:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ADMINISTRADORA:_NOME:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ADMINISTRADORA:_NOME:TEXT,"")
                                aCtrcs:=fApiCP(cAxICnpj,oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,"ctrcs")
                                fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,"I",SubStr(oCFPagar[_nr]:_tipo:TEXT,1,1),Val(oCFPagar[_nr]:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_SERIE:TEXT,aCtrcs,cAdministradora)
                                cAdministradora:= ""
                                cStcf:="I"
                                cMsgErr:= "Pronto para Realizar Integração do "+oCFPagar[_nr]:_tipo:TEXT
                                lCont:= .T.
                            else
                                lGrvLog:=.F.
                            EndIf    
                        ELSE
                            cMsgErr:= "Fornecedor CNPJ: "+cCnpjPro+" não encontrado"
                            cStcf:= "E" 
                            //fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,"E",SubStr(oCFPagar[_nr]:_tipo:TEXT,1,1),Val(oCFPagar[_nr]:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_SERIE:TEXT)
                        EndIf
                        If lGrvLog
                            fGrvLg(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,cMsgErr,cMemoMsg,Val(oCFPagar[_nr]:_VALOR:TEXT),cStcf,cForn,oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT)
                        EndIf    
                        lGrvLog:=.T.
                    Next _nr
                EndIf    
            Next i    
        EndIf
    EndIf
	END Transaction	
return aDados


Static Function fVerSC7(cIdCf)
Local cQryC7:= ""
Local  lRet:=.F.

    cQryC7:= " SELECT C7_NUM FROM "+RetSqlName("SC7")+" SC7"
    cQryC7+= " WHERE C7_XIDCF='"+cIdCf+"' AND SC7.D_E_L_E_T_<>'*'"
    cQryC7:= ChangeQuery(cQryC7)
	    If SELECT("TMPC7")>0
            dbSelectArea("TMPC7")
            TMPC7->(dbCloseArea())
        EndIf
        dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryC7), 'TMPC7', .F., .T.)

        If TMPC7->(!Eof())
            lRet:=.T.
        EndIf
Return lRet

Static Function fApiCP(cAxICnpj,cIdCF,cCnjDd)

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
Local aArray := {}
Local aRet  := {}
Local cTpCte        := ""
Local __cTpcte      := "0"
Local cChvRef       := ""
Private oXmlCp
    DBSelectArea("SA2")
    DbSetOrder(3)
    oRestClient := FWRest():New(cUrl)

   	Aadd(aHeader,"Authorization: Basic " + Encode64("integracao:gt.2021"))	
	Aadd(aHeader,"Content-Type: multipart/form-data") 
	Aadd(aHeader,"Accept: application/json")

    oRestClient:setPath("/api/contabilidade/index.php")

	cJson := 'Content-Disposition: form-data; name="conjunto_de_dados"' + CRLF + CRLF 
	cJson += cCnjDd + CRLF

	cJson += 'Content-Disposition: form-data; name="cnpj"' + CRLF + CRLF 
	cJson += cAxICnpj + CRLF 

	cJson += 'Content-Disposition: form-data; name="dt_ini"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataD),1,4) + "-" + Substr(Dtos(dDataD),5,2) + "-" + Substr(Dtos(dDataD),7,2) + CRLF // '2021-08-01'

	cJson += 'Content-Disposition: form-data; name="dt_fim"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataA),1,4) + "-" + Substr(Dtos(dDataA),5,2) + "-" + Substr(Dtos(dDataA),7,2) + CRLF //'2021-08-30' 

	cJson += 'Content-Disposition: form-data; name="id"' + CRLF + CRLF 
	cJson += cIdCF + CRLF 

	cJson += 'Content-Disposition: form-data; name="ambiente"' + CRLF + CRLF 
	cJson += '2' + CRLF 

	oRestClient:SetPostParams(cJson)
	
	If oRestClient:Post(aHeader)
		//ConOut("POST", oRestClient:GetResult())

		cXml := oRestClient:GetResult()

		oXmlCp := XmlParser( cXml, "_", @cError, @cWarning )
        If Alltrim(cCnjDd)=='contasAPagar'
            If Type("oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR")== "A"
                For _nrg:=1 to Len(oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR)
                    If type("oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO")=="O"
                        If cIdCF==oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO:_ID:TEXT
                            If oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO:_TIPO:TEXT=="Adiantamento"
                                // retorna o numero do contrato
                                aRet:= {oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_NUMERO:TEXT }
                            EndIf    
                        EndIf
                    ElseIf type("oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO")=="A"
                        For _nrgr:=1 to Len(oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO)
                            If cIdCF==oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO[_nrgr]:_ID:TEXT
                                If oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_CARTAFRETEPAGAMENTOS:_CARTAFRETEPAGAMENTO[_nrgr]:_TIPO:TEXT=="Adiantamento"
                                    // retorna o numero do contrato
                                    aRet:= {oXmlCP:_CONTASAPAGAR:_CONTAAPAGAR[_nrg]:_NUMERO:TEXT }
                                EndIf    
                            EndIf
                        Next _nrgr
                    EndIf    
                Next _nrg
            EndIf       
        ElseIf Alltrim(cCnjDd)=='ctrcs'
            If Type("oXmlCP:_CTRCS:_CTRC")== "O"
                cTpCte:= oXmlCP:_CTRCS:_CTRC:_CTE:_TPCTE:TEXT
                If cTpCte $ "NORMAL"
                    __cTpcte:="0" 
                ElseIf   cTpCte $ "CTe de Complemento"
                    __cTpcte:="1"
                ElseIf cTpCte $ "CTe de Anulação"
                    __cTpcte:="2"
                EndIf
                If Type("oXmlCP:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT")=="C"
                    cChvRef:= oXmlCP:_CTRCS:_CTRC:_CTE:_nrChaveRef:TEXT
                EndIf
            EndIf
        EndIf    
    EndIf
Return {__cTpcte,cChvRef}

Static Function fGrvLg(cIdCferr,cMsgErr,cMemoMsg,nVlrCf,cStcf,cForn,cIDImp)
    RecLock("UQF", .T.)
    UQF->UQF_FILIAL:= xFilial("UQF")
	UQF->UQF_FIL	:= xFilial("UQF")
    UQF->UQF_IDIMP	:= StrZero(Val(cIDImp),9)
    UQF->UQF_DATA   := DATE()
    UQF->UQF_HORA   := TIME()
	UQF->UQF_REGCOD	:= cIdCferr
    UQF->UQF_MSG    := cMsgErr
    UQF->UQF_MSGDET := cMemoMsg
    UQF->UQF_USER   := UsrRetName(RetCodUsr())
    UQF->UQF_ACAO   := "IMP"
    UQF->UQF_STATUS := cStcf
    UQF->UQF_VALOR  := nVlrCf
    UQF->UQF_FORNEC := cForn
    msUnlock()
Return                    

/*/{Protheus.doc} nomeStaticFunction
    (long_description)
    @type  Static Function
    @author user
    @since 30/12/2021
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function fGrvProc(cIDImp,cCodFor,cLojFor,nValCf,cNumCf,cStatus,cTpCf,nValAS,cSer,aCtrs,cAdministradora)
    DbSelectArea("UQB")
    UQB->(DBSETORDER(1))
    If UQB->(dbSeek(xFilial("UQB")+StrZero(Val(cIDImp),9)+cTpCf))
        RecLock("UQB", .F.)
    Else
        RecLock("UQB", .T.)        
    EndIf
    
    UQB->UQB_FILIAL	:= xFilial("UQB")
    UQB->UQB_IDIMP	:= StrZero(Val(cIDImp),9)
    UQB->UQB_DTIMP	:= Date()
    UQB->UQB_TPCON	:= "CF"
    UQB->UQB_FORNEC	:= cCodFor
    UQB->UQB_LOJA	:= cLojFor
    UQB->UQB_VALOR	:= nValAS
    UQB->UQB_MOEDA  := "BRL"
    UQB->UQB_INDICA	:= "CF"
    UQB->UQB_NUMERO	:= StrZero(Val(cNumCf),16)
    UQB->UQB_EMISSA	:= date()
    UQB->UQB_STATUS	:= cStatus  
    UQB->UQB_TPCF   := cTpCf
    UQB->UQB_VLRPED := nValCf
    UQB->UQB_NF     := StrZero(Val(cNumCf),9)
    UQB->UQB_SERIE  := StrZero(Val(cSer) ,3)
    UQB->UQB_XTPCTE := aCtrs[1] 
    UQB->UQB_CTEREF := aCtrs[2]
    UQB->UQB_ADMCF  := cAdministradora
    UQB->UQB_CONPG  := cCondPg
    MsUnlock()    
    If cTpCf=="S"
        DbSelectArea("UQC")
        UQC->(DBSETORDER(1))
        If UQC->(dbSeek(xFilial("UQC")+StrZero(Val(cIDImp),9)))
            RecLock("UQC", .F.)
        Else
            RecLock("UQC", .T.)        
        EndIf
        UQC->UQC_FILIAL	:= xFilial("UQC")
        UQC->UQC_IDIMP	:= StrZero(Val(cIDImp),9)
        UQC->UQC_ITEM   := "001" 
        UQC->UQC_PRODUT := SuperGetMV("MV_XPRDCF",.F.,"SERV000062")
        UQC->UQC_PRCVEN := nValCf
        msUnlock()
    EndIf

Return 

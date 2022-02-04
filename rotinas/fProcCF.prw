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
Local i             := 0
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
Private cPrdUqc     := SuperGetMV("MV_XPRDCF",.F.,"SERV000062")
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
    aAdd(aParamBox ,{1,"Cond. Pgto"	,cCondPg    ,"@!","","SE4"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Produto"	,cPrdUqc    ,"@!","","SB1"	,""	,50,.T.})
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
        cCondPg := aRet[10]
        cPrdUqc := aRet[11]
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
Local aVerC7        := {}
Local _nr           := 0
Local _nzi          := 0
local _cCiot        := ""  
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
				IF tYPE("oCFPagar")=="O"
                    oCFPagar:={oCFPagar}
                ENDIF
                IF tYPE("oCFPagar")=="A"
                    lCont:=.F.
                    For _nr:= 1 to Len(oCFPagar)                   
                        cCnpjPro:= oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_PROPRIETARIO:_CNPJCPF:TEXT
                        DBSelectArea("SA2")
                        DbSetOrder(3)
                        If SA2->(dbSeek(xFilial("SA2")+cCnpjPro))
                            // VERIFICA SE O iD JA FOI PROCESSADO
                            cForn:= SA2->A2_COD
                            aCtrcs:=fApiCP(cAxICnpj,oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,"ctrcs")
                            aVerC7:= fVerSC7(StrZero(Val(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT),9))
                            If (!aVerC7[1] .or. lCont).and. !(Alltrim(aCtrcs[3])$("CANCELADO/INULITIZADO"))
                                _cCiot:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_CIOT:TEXT," ") 
                                cAdministradora:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_ADMINISTRADORA:_NOME:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ADMINISTRADORA:_NOME:TEXT,"")
                                cEmis:= strtran(If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_EMISSAO:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_EMISSAO:TEXT," "),"-","" )
                                fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,;
                                "I",SubStr(oCFPagar[_nr]:_tipo:TEXT,1,1),Val(oCFPagar[_nr]:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_SERIE:TEXT,aCtrcs,cAdministradora,_cCiot,cEmis)
                                cAdministradora:= ""
                                cStcf:="I"
                                cMsgErr:= "Pronto para Realizar Integração do "+oCFPagar[_nr]:_tipo:TEXT
                                lCont:= .T.
                            ElseIf Alltrim(aCtrcs[3])$("CANCELADO/INULITIZADO")
                                lGrvLog:=.F.
                                DbSelectArea("SC7")
                                If !Empty(aVerC7[2])
                                    SC7->(dbGoto(aVerC7[2]))
                                    fExcCanc()
                                Else
                                    cAdministradora:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_ADMINISTRADORA:_NOME:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ADMINISTRADORA:_NOME:TEXT,"")
                                    _cCiot:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_CIOT:TEXT," ") 
                                    cEmis:= strtran(If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_EMISSAO:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_EMISSAO:TEXT," "),"-","" )
                                    fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,;
                                    "M",SubStr(oCFPagar[_nr]:_tipo:TEXT,1,1),Val(oCFPagar[_nr]:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_SERIE:TEXT,aCtrcs,cAdministradora,_cCiot,cEmis)
                                    cAdministradora:= ""
                                    cStcf:="I"
                                    cMsgErr:= "Cancelamento de Carta Frete "+oCFPagar[_nr]:_tipo:TEXT
                                    lCont:= .T.
                                EndIf    
                            Else
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
        ElseIf Type("oXml:_CARTASFRETES:_CARTAFRETE")== "O"
            oCFPagar:= oXml:_CARTASFRETES:_CARTAFRETE:_CARTAFRETEPARCELAMENTOS:_CARTAFRETEPARCELAMENTO
			IF tYPE("oCFPagar")=="O"
                cCnpjPro:= oXml:_CARTASFRETES:_CARTAFRETE:_PROPRIETARIO:_CNPJCPF:TEXT
                DBSelectArea("SA2")
                DbSetOrder(3)
                If SA2->(dbSeek(xFilial("SA2")+cCnpjPro))
                    // VERIFICA SE O iD JA FOI PROCESSADO
                    cForn:= SA2->A2_COD
                    aCtrcs:=fApiCP(cAxICnpj,oXml:_CARTASFRETES:_CARTAFRETE:_ID:TEXT,"ctrcs")
                    aVerC7:= fVerSC7(StrZero(Val(oXml:_CARTASFRETES:_CARTAFRETE:_ID:TEXT),9))
                    If (!aVerC7[1] .or. lCont).and. !(Alltrim(aCtrcs[3]) =="CANCELADO/INULITIZADO")
                        _cCiot:=If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT,"")
                        cAdministradora:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_ADMINISTRADORA:_NOME:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_ADMINISTRADORA:_NOME:TEXT,"")
                        cEmis:= strtran(If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_EMISSAO:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_EMISSAO:TEXT," "),"-","" )
                        fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE:_NUMERO:TEXT,"I",SubStr(oCFPagar:_tipo:TEXT,1,1),Val(oCFPagar:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE:_SERIE:TEXT,aCtrcs,cAdministradora,_cCiot,cEmis)
                        cAdministradora:= ""
                        cStcf:="I"
                        cMsgErr:= "Pronto para Realizar Integração do "+oCFPagar:_tipo:TEXT
                        lCont:= .T.
                    ElseIf Alltrim(aCtrcs[3]) =="CANCELADO/INULITIZADO"
                        lGrvLog:=.F.
                        DbSelectArea("SC7")
                        If !Empty(aVerC7[2])
                            SC7->(dbGoto(aVerC7[2]))
                            fExcCanc()
                        Else
                            _cCiot:=If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT,"")
                            cAdministradora:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_ADMINISTRADORA:_NOME:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_ADMINISTRADORA:_NOME:TEXT,"")
                            cEmis:= strtran(If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_EMISSAO:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_EMISSAO:TEXT," "),"-","" )
                            fGrvProc(oXml:_CARTASFRETES:_CARTAFRETE:_ID:TEXT,SA2->A2_COD,SA2->A2_LOJA,Val(oXml:_CARTASFRETES:_CARTAFRETE:_VLFRETE:TEXT),oXml:_CARTASFRETES:_CARTAFRETE:_NUMERO:TEXT,"M",SubStr(oCFPagar:_tipo:TEXT,1,1),Val(oCFPagar:_VALOR:TEXT),oXml:_CARTASFRETES:_CARTAFRETE:_SERIE:TEXT,aCtrcs,cAdministradora,_cCiot,cEmis)
                            cAdministradora:= ""
                            cStcf:="I"
                            cMsgErr:= "Carta Frete Cancelada"+oCFPagar:_tipo:TEXT
                            lCont:= .T.
                        EndIf
                    else
                        lGrvLog:=.F.
                    EndIf    
                ELSE
                    cMsgErr:= "Fornecedor CNPJ: "+cCnpjPro+" não encontrado"
                    cStcf:= "E"
                EndIf
                If lGrvLog
                    fGrvLg(oXml:_CARTASFRETES:_CARTAFRETE:_NUMERO:TEXT,cMsgErr,cMemoMsg,Val(oCFPagar:_VALOR:TEXT),cStcf,cForn,oXml:_CARTASFRETES:_CARTAFRETE:_ID:TEXT)
                EndIf    
                lGrvLog:=.T.
            EndIf        
        EndIf
    EndIf
	END Transaction	
return aDados


Static Function fVerSC7(cIdCf)
Local cQryC7:= ""
Local  lRet:=.F.
Local nRecSC7:= 0

    cQryC7:= " SELECT R_E_C_N_O_ RECSC7 FROM "+RetSqlName("SC7")+" SC7"
    cQryC7+= " WHERE C7_XIDCF='"+cIdCf+"' AND SC7.D_E_L_E_T_<>'*'"
    cQryC7:= ChangeQuery(cQryC7)
	    If SELECT("TMPC7")>0
            dbSelectArea("TMPC7")
            TMPC7->(dbCloseArea())
        EndIf
        dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryC7), 'TMPC7', .F., .T.)

        If TMPC7->(!Eof())
            lRet:=.T.
            nRecSC7:= TMPC7->RECSC7
        EndIf
Return {lRet,nRecSC7}

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
Local _cSitCte      := ""
Local _nrgr         := 0
Local _nrg          := 0
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
                If Type("oXmlCP:_CTRCS:_CTRC:_CTE:_TPCTE:TEXT")=="C"
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
                If Type("oXmlCP:_CTRCS:_CTRC:_situacao:TEXT")=="C"
                    _cSitCte:= oXmlCP:_CTRCS:_CTRC:_situacao:TEXT
                EndIf                
            EndIf
            aRet:={__cTpcte,cChvRef,_cSitCte} 
        EndIf    
    EndIf
Return aRet

Static Function fGrvLg(cIdCferr,cMsgErr,cMemoMsg,nVlrCf,cStcf,cForn,cIDImp)
    RecLock("UQF", .T.)
    UQF->UQF_FILIAL:= xFilial("UQF")
	UQF->UQF_FIL	:= xFilial("UQF")
    UQF->UQF_IDIMP	:= StrZero(Val(cIDImp),9)
    UQF->UQF_DATA   := DATE()
    UQF->UQF_HORA   := TIME()
	UQF->UQF_REGCOD	:= StrZero(Val(cIdCferr),16)
    UQF->UQF_MSG    := cMsgErr
    UQF->UQF_MSGDET := cMemoMsg
    UQF->UQF_USER   := UsrRetName(RetCodUsr())
    UQF->UQF_ACAO   := "IMP"
    UQF->UQF_STATUS := cStcf
    UQF->UQF_VALOR  := nVlrCf
    UQF->UQF_FORNEC := cForn
    UQF->UQF_XIDCF	:= StrZero(Val(cIDImp),9)
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
Static Function fGrvProc(cIDImp,cCodFor,cLojFor,nValCf,cNumCf,cStatus,cTpCf,nValAS,cSer,aCtrs,cAdministradora,cCiot,cEmis)
Local lIncUqb   := .F.
    DbSelectArea("UQB")
    UQB->(DBSETORDER(1))
    If UQB->(dbSeek(xFilial("UQB")+StrZero(Val(cIDImp),9)+cTpCf))
        RecLock("UQB", .F.)
    Else
        RecLock("UQB", .T.)   
        lIncUqb:=.T.     
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
    UQB->UQB_EMISSA	:= stod(cEmis)//date()
    UQB->UQB_STATUS	:= If(cStatus=="M",If(lIncUqb,"I",UQB->UQB_STATUS),cStatus )
    UQB->UQB_TPCF   := cTpCf
    UQB->UQB_VLRPED := nValCf
    UQB->UQB_NF     := StrZero(Val(cNumCf),9)
    UQB->UQB_SERIE  := StrZero(Val(cSer) ,3)
    UQB->UQB_XTPCTE := aCtrs[1] 
    UQB->UQB_CTEREF := aCtrs[2]
    UQB->UQB_CANCEL := If(SUBSTR(aCtrs[3],1,1)$"C|I","C"," ")
    UQB->UQB_ADMCF  := cAdministradora
    UQB->UQB_CONPG  := cCondPg
    UQB->UQB_XCIOT  := cCiot 
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
        UQC->UQC_PRODUT := cPrdUqc//SuperGetMV("MV_XPRDCF",.F.,"SERV000062")
        UQC->UQC_PRCVEN := nValCf
        msUnlock()
    EndIf

Return 
Static Function fExcCanc
Local nOpc      := 5
Local aVerUqb   := fVerUQB(SC7->C7_NUM)
Local aArray    :={}
Local cChaveFie := ""
Local aCabec    :={}
Local aLinha    := {}
Local aItens    := {}
Private lMsErroAuto:= .F.
    
    If aVerUqb[1]
        // EXCLUI PEDIDO
        cChaveFie:= SC7->C7_FILIAL+"P"+SC7->C7_NUM
        aadd(aCabec,{"C7_NUM" ,SC7->C7_NUM})
        aadd(aCabec,{"C7_EMISSAO" ,SC7->C7_EMISSAO})
        aadd(aCabec,{"C7_FORNECE" ,SC7->C7_FORNECE})
        aadd(aCabec,{"C7_LOJA" ,SC7->C7_LOJA})
        aadd(aCabec,{"C7_COND" ,SC7->C7_COND})
        aadd(aCabec,{"C7_CONTATO" ,SC7->C7_CONTATO})
        aadd(aCabec,{"C7_FILENT" ,SC7->C7_FILENT})

        aLinha := {}

        aadd(aLinha,{"C7_ITEM" ,SC7->C7_ITEM ,Nil})
        aadd(aLinha,{"C7_PRODUTO" ,SC7->C7_PRODUTO,Nil})
        aadd(aLinha,{"C7_QUANT" ,SC7->C7_QUANT ,Nil})
        aadd(aLinha,{"C7_PRECO" ,SC7->C7_PRECO ,Nil})
        aadd(aLinha,{"C7_TOTAL" ,SC7->C7_TOTAL ,Nil})
        aadd(aItens,aLinha)

        MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCabec,aItens,nOpc,.F.)

        If !lMsErroAuto
            ConOut("Exclusao PC: ")
        Else
            ConOut("Erro na exclusao!")
            MostraErro()
        EndIf
        DbSelectArea("UQB")
        dbGoto(aVerUqb[2])
        cIdImp:= UQB->UQB_IDIMP
        DbSelectArea("SE2")
        While UQB->(!Eof()) .and. UQB->UQB_IDIMP==cIdImp
            If UQB->UQB_RECSE2>0
                SE2->(dbGoto(UQB->UQB_RECSE2))
                aArray := { { "E2_PREFIXO" , SE2->E2_PREFIXO , NIL },;
                            { "E2_NUM"     , SE2->E2_NUM     , NIL },; 
                            { "E2_PARCELA" , SE2->E2_PARCELA , NIL }}
    
                MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, nOpc)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
    
                If lMsErroAuto
                    MostraErro()
                Else
                    DbSelectArea("FIE")
                    dbSetOrder(1)
                    FIE->(dbSeek(cChaveFie))
                    cChv:= FIE->FIE_FILIAL+FIE->FIE_PEDIDO
                    While FIE->(!Eof()) .and. cChv== FIE->FIE_FILIAL+FIE->FIE_PEDIDO
                        RecLock("FIE", .F.)
                        FIE->(dbDelete())
                        MsUnlock() 
                        FIE->(DBSKIP() )
                    end
                Endif
            EndIf
             RecLock("UQB", .F.)
                UQB->UQB_CANCEL:="C"
                UQB->UQB_PREFIX:= ""
				UQB->UQB_TITULO:= ""
				UQB->UQB_PARCEL:= ""
				UQB->UQB_TIPOTI:= "" 
                UQB->UQB_PEDIDO:= ""
            MsUnlock()
            UQB->(dbSkip())
        END
    EndIf
    
    
Return

Static Function  fVerUQB(cPed)
Local lRet      := .F.
Local cQryUqb   := " "
Local nRecUQB   := 0

    cQryUqb:= " SELECT MIN(R_E_C_N_O_) RECUQB "
    cQryUqb+= " FROM "+RetSqlName("UQB")+" UQB"
    cQryUqb+= " WHERE UQB.UQB_PEDIDO='"+cPed+"' AND UQB.D_E_L_E_T_<>'*'
    cQryUqb:= ChangeQuery(cQryUqb)
	    If SELECT("TMPUQB")>0
            dbSelectArea("TMPUQB")
            TMPUQB->(dbCloseArea())
        EndIf
        dbUseArea(.T., "TOPCONN", TCGENQRY(,,cQryUqb), 'TMPUQB', .F., .T.)

        If TMPUQB->(!Eof())
            lRet:=.T.
            nRecUQB:= TMPUQB->RECUQB
        EndIf

Return {lRet,nRecUQB }

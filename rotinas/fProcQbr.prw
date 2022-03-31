#include "protheus.ch"
#include "parmtype.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³fProQbr l ºAutor  ³Reginaldo G Ribeiro º Data ³  23/09/21   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³      ±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                               º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/ 

User Function fProQbr()
local aInfo   
Local aRet			:= {}
Local aParamBox		:= {}
Local lPercOk		:= .F.
Local i             := 0
Private cPref       := "LOG"
Private cNat        := Space(6)
Private cNatNCC     := Space(6)
Private cNatNDF     := Space(6)
Private cCC         := Space(11)
Private cItemC      := Space(11)
Private cCondPg     := SPACE(6)
Private dDataE		:= Ctod("//")

    aAdd(aParamBox ,{6,"Arquivo"   ,Space(50),"","","",50,.F.,"Todos os arquivos (*.*) | *.*"})
    //aAdd(aParamBox ,{1,"Natureza"	,cNat	    ,"@!","","SED"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Centro de Custo",cCC    ,"@!","","CTT"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Item Contabil"	,cItemC ,"@!","","CTD"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Cond. Pgto"	,cCondPg    ,"@!","","SE4"	,""	,50,.T.})
    If ParamBox(aParamBox,"Parametros",@aRet)
        cArqQ  := aRet[1]
        //cNat := aRet[2]
        cCC  := aRet[2]
        cItemC  := aRet[3]
        lPercOk := .T.
        cCondPg:= aRet[4]
    Endif
    aInfo:=Processa( {|| fImpArQu(cArqQ) }, "Aguarde...", "Integração Quebras...",.T.)
     
Return


///////////////////////////////////////////////////////////////////////////////////
//+-----------------------------------------------------------------------------+//
//| PROGRAMA | Import | AUTOR |Reginaldo G Ribeiro | DATA | 01/03/2021 |//
//+-----------------------------------------------------------------------------+//
//| DESCRICAO | Funcao - Import() |//
//| | Funcao de importacao de dados |//
//+-----------------------------------------------------------------------------+//
//| MANUTENCAO DESDE SUA CRIACAO |//
//+-----------------------------------------------------------------------------+//
//| DATA | AUTOR | DESCRICAO |//
//+-----------------------------------------------------------------------------+//
//| | | |//
//+-----------------------------------------------------------------------------+//
///////////////////////////////////////////////////////////////////////////////////

STATIC FUNCTION fImpArQu(cFile)
Local cFileOpen := ""
Local cExtens   := "Arquivo csv | *.csv"
Local _aBuffer  := {}
Local cLoja     := "01"
Local cerro     := ""   
Local lDulpic   :=.F. 
Local nRecZ8    := 0
Local nRecZ7    := 0
Local aSE2Dpl   := {}
Local _nRg      := 0
Local aInfoQCte := {}
Local aInfoQCF  := {}
local _ny       := 0
local cFornecUQB:= ""
Local cLojaUQB  := ""
Local cCiot     := ""
Local cChv      := ""
Local cTpCte    := ""
Local aRetCf    := {}
Private lMsErroAuto := .F. 

    cFileOpen := cFile//cGetFile(cExtens,"Seleciona Arquivo",,,.T.)

    If !File(cFileOpen)
        MsgAlert("Arquivo texto: "+cFileOpen+" não localizado",cCadastro)
        Return
    Endif

    _aBuffer := CargaArray(cFileOpen)
    _nPosNumCte := ASCAN(_aBuffer[2],"nr_ctrc")
    _nPosEmiCte := ASCAN(_aBuffer[2],"dt_emissao") 
    _nPosSerCte := ASCAN(_aBuffer[2],"ds_serie") 
    _nPosnumCF  := ASCAN(_aBuffer[2],"nr_cf")
    _nPosEmiCF  := ASCAN(_aBuffer[2],"dt_emissao_cf") 
    _nPosVlrCte := ASCAN(_aBuffer[2],"vl_quebra_ctrc") 
    _nPosVLrCF  := ASCAN(_aBuffer[2],"vl_quebra_cf") 

    ProcRegua(Len(_aBuffer[1]))
    For _nRg := 1 to Len(_aBuffer[1])    
        IncProc("Carregando Linha "+AllTrim(Str(_nRg))+" de "+AllTrim(Str(Len(_aBuffer[1]))))
        nVlrCteQ   := If(_nPosVlrCte>0,val(strtran(_aBuffer[1,_nRg,_nPosVlrCte],",",".")),"")
        nVlrCFQ    := If(_nPosVLrCF>0,val(strtran(_aBuffer[1,_nRg,_nPosVLrCF],",",".")),"")
        
        If nVlrCteQ > 0
            aadd(aInfoQCte,{If(_nPosNumCte>0,Alltrim(_aBuffer[1,_nRg,_nPosNumCte]),""),;
                                If(_nPosSerCte>0,Alltrim(_aBuffer[1,_nRg,_nPosSerCte]),""),;
                                If(_nPosnumCF>0,Alltrim(_aBuffer[1,_nRg,_nPosnumCF]),""),;
                                If(_nPosEmiCte>0,Alltrim(_aBuffer[1,_nRg,_nPosEmiCte]),""),;
                                nVlrCteQ;
                })
        EndIf

        If nVlrCFQ > 0
            aadd(aInfoQCF,{If(_nPosNumCte>0,Alltrim(_aBuffer[1,_nRg,_nPosNumCte]),""),;
                                If(_nPosSerCte>0,Alltrim(_aBuffer[1,_nRg,_nPosSerCte]),""),;
                                If(_nPosnumCF>0,Alltrim(_aBuffer[1,_nRg,_nPosnumCF]),""),;
                                If(_nPosEmiCF>0,Alltrim(_aBuffer[1,_nRg,_nPosEmiCF]),""),;
                                nVlrCFQ;
                })
        EndIf
    Next _nRg     
    If Len(aInfoQCte) > 0
        For _ny:= 1 to Len(aInfoQCte)
            aRetCf  := fGetcjCf(SM0->M0_CGC,Ctod(aInfoQCte[_ny,4]),aInfoQCte[_ny,3])
            aRetCte := fGetcjCte(SM0->M0_CGC,Ctod(aInfoQCte[_ny,4]),aInfoQCte[_ny,3])
            cFornecUQB  := aRetCte[3]
            cLojaUQB    := aRetCte[4]
            cCiot       := aRetCf[3]
            cChvcte     := aRetCte[1]
            cTpCte      := aRetCte[2]
           
            If !Empty(cFornecUQB)
                RecLock("UQB", .T.)
                UQB->UQB_FILIAL:= xFilial("UQB") 
                UQB->UQB_IDIMP := strZero(Val(aInfoQCte[_ny,1]),9)
                UQB->UQB_DTIMP	:= Date()
                UQB->UQB_TPCON	:= "QBRCTE"
                UQB->UQB_FORNEC	:= cFornecUQB
                UQB->UQB_LOJA	:= cLojaUQB
                UQB->UQB_VALOR	:= If(Valtype(aInfoQCte[_ny,5])=="C",Val(aInfoQCte[_ny,5]),aInfoQCte[_ny,5])
                UQB->UQB_MOEDA  := "BRL"
                UQB->UQB_INDICA	:= "QBRCTE"
                UQB->UQB_NUMERO	:= StrZero(Val(aInfoQCte[_ny,3]),16)
                UQB->UQB_EMISSA	:= Ctod(aInfoQCte[_ny,4])
                UQB->UQB_STATUS	:= "I"
                UQB->UQB_TPCF   := "S"
                UQB->UQB_VLRPED := 0//Val(aInfoQCte[_ny,5])
                UQB->UQB_NF     := StrZero(Val(aInfoQCte[_ny,1]),9)
                UQB->UQB_SERIE  := StrZero(Val(aInfoQCte[_ny,2]) ,3)
                UQB->UQB_CONPG  := cCondPg
                UQB->UQB_XCIOT  := cCiot 
                UQB->UQB_XTPCTE := cTpCte
                UQB->UQB_CTEREF := cChvcte
                MsUnlock()
            Endif
        Next _ny
    EndIf
    If Len(aInfoQCF) > 0
        For _ny:= 1 to Len(aInfoQCF)
            aRetCf  := fGetcjCf(SM0->M0_CGC,Ctod(aInfoQCF[_ny,4]),aInfoQCF[_ny,3])
            aRetCte := fGetcjCte(SM0->M0_CGC,Ctod(aInfoQCF[_ny,4]),aInfoQCF[_ny,3])
            cFornecUQB  := aRetCf[1]
            cLojaUQB    := aRetCf[2]
            cCiot       := aRetCf[3]
            cChvcte     := aRetCte[1]
            cTpCte      := aRetCte[2]
           
            If !Empty(cFornecUQB)
                RecLock("UQB", .T.)
                UQB->UQB_FILIAL:= xFilial("UQB") 
                UQB->UQB_IDIMP := strZero(Val(aInfoQCF[_ny,1]),9)
                UQB->UQB_DTIMP	:= Date()
                UQB->UQB_TPCON	:= "QBRCF"
                UQB->UQB_FORNEC	:= cFornecUQB
                UQB->UQB_LOJA	:= cLojaUQB
                UQB->UQB_VALOR	:= If(Valtype(aInfoQCF[_ny,5])=="C",Val(aInfoQCF[_ny,5]),aInfoQCF[_ny,5])//Val(aInfoQCF[_ny,5])
                UQB->UQB_MOEDA  := "BRL"
                UQB->UQB_INDICA	:= "QBRCF"
                UQB->UQB_NUMERO	:= StrZero(Val(aInfoQCF[_ny,3]),16)
                UQB->UQB_EMISSA	:= Ctod(aInfoQCF[_ny,4])
                UQB->UQB_STATUS	:= "I"
                UQB->UQB_TPCF   := "S"
                UQB->UQB_VLRPED := 0//Val(aInfoQCF[_ny,5])
                UQB->UQB_NF     := StrZero(Val(aInfoQCF[_ny,1]),9)
                UQB->UQB_SERIE  := StrZero(Val(aInfoQCF[_ny,2]) ,3)
                UQB->UQB_XCIOT  := cCiot 
                UQB->UQB_XTPCTE := cTpCte
                UQB->UQB_CTEREF := cChvcte
                MsUnlock()
            EndIf
        Next _ny
    EndIf
Return

//FUNÇÃO QUE CARREGA AS INFORMAÇÃO DO CSV PARA O ARRAY
Static Function CargaArray(cArq)
Local cPath := cArq
Local oFile := FwFileReader():New(cPath)
Local aAux  := {}
Local aLine := {}
Local aHead := {}

     // SE FOR POSSÍVEL ABRIR O ARQUIVO, LEIA-O
    // SE NÃO, EXIBA O ERRO DE ABERTURA
    If (oFile:Open())
        aAux := oFile:GetAllLines() // ACESSA TODAS AS LINHAS

        // CRIA O CABEÇALHO E DELETA DO CONJUNTO DE LINHAS
        aHead := StrTokArr2(aAux[1], ";")
        ADel(aAux, 1)
        ASize(aAux, Len(aAux) - 1)

        // SEPARA O VETOR EM NÍVEL CONFORME TOKEN
        AEval(aAux, {|x| AAdd(aLine, StrTokArr2(x, ";", .T.))})
    Else
        MsgLAert("Couldn't find/open file: " + cPath,"Atenção")
    EndIf
Return {aLine,aHead}

Static Function fGetcjCF(cAxICnpj,dDataE,cCteN)

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
Local cForn         := ""
Local cLoja         := ""
local _cCiot        := ""
Local _cchv         := ""
Local _ctetp        := ""
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
	cJson += Substr(Dtos(dDataE),1,4) + "-" + Substr(Dtos(dDataE),5,2) + "-" + Substr(Dtos(dDataE),7,2) + CRLF // '2021-08-01'

	cJson += 'Content-Disposition: form-data; name="dt_fim"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataE),1,4) + "-" + Substr(Dtos(dDataE),5,2) + "-" + Substr(Dtos(dDataE),7,2) + CRLF //'2021-08-30' 

	cJson += 'Content-Disposition: form-data; name="id"' + CRLF + CRLF 
	cJson += '' + CRLF 

	cJson += 'Content-Disposition: form-data; name="ambiente"' + CRLF + CRLF 
	cJson += '2' + CRLF 

	oRestClient:SetPostParams(cJson)
	//Begin Transaction
	If oRestClient:Post(aHeader)
		cXml := oRestClient:GetResult()
		oXml := XmlParser( cXml, "_", @cError, @cWarning )
        If Type("oXml:_CARTASFRETES:_CARTAFRETE")== "A"
            For _nzi := 1 to Len(oXml:_CARTASFRETES:_CARTAFRETE)
                If Alltrim(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT)==Alltrim(cCteN)
                    oCFPagar:= oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_CARTAFRETEPARCELAMENTOS:_CARTAFRETEPARCELAMENTO
                    IF tYPE("oCFPagar")=="O"
                        oCFPagar:={oCFPagar}
                    ENDIF
                    IF tYPE("oCFPagar")=="A"
                        lCont:=.F.
                        For _nr:= 1 to Len(oCFPagar)                   
                            cCnpjPro:= oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_PROPRIETARIO:_CNPJCPF:TEXT
                            _cCiot:= If(Type("oXml:_CARTASFRETES:_CARTAFRETE["+cvaltochar(_nzi)+"]:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_CIOT:TEXT," ")                                
                            DBSelectArea("SA2")
                            DbSetOrder(3)
                            If SA2->(dbSeek(xFilial("SA2")+cCnpjPro))
                                // VERIFICA SE O iD JA FOI PROCESSADO
                                cForn:= SA2->A2_COD
                                cLoja:= SA2->A2_LOJA	
                                Return {cForn,cLoja,_cCiot} 
                            Else
                                cMsgErr:= "Fornecedor CNPJ: "+cCnpjPro+" não encontrado"
                                cStcf:= "E" 
                                fGrvLg(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,cMsgErr,"",Val(oCFPagar[_nr]:_VALOR:TEXT),cStcf,cForn,oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT)
                            ENDIF
                        NEXT _nr
                    EndIf
                EndIf    
            Next _nzi
        ElseIf Type("oXml:_CARTASFRETES:_CARTAFRETE")== "O"
            oCFPagar:= oXml:_CARTASFRETES:_CARTAFRETE:_CARTAFRETEPARCELAMENTOS:_CARTAFRETEPARCELAMENTO
            IF tYPE("oCFPagar")=="O"
                If Alltrim(oXml:_CARTASFRETES:_CARTAFRETE:_NUMERO:TEXT)==Alltrim(cCteN)
                    cCnpjPro:= oXml:_CARTASFRETES:_CARTAFRETE:_PROPRIETARIO:_CNPJCPF:TEXT
                    _cCiot:=If(Type("oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT")=="C",oXml:_CARTASFRETES:_CARTAFRETE:_CIOT:TEXT,"")
                    DBSelectArea("SA2")
                    DbSetOrder(3)
                    If SA2->(dbSeek(xFilial("SA2")+cCnpjPro))
                        cForn:= SA2->A2_COD
                        cLoja:= SA2->A2_LOJA
                        Return {cForn,cLoja,_cCiot}
                    Else
                        cMsgErr:= "Fornecedor CNPJ: "+cCnpjPro+" não encontrado"
                        cStcf:= "E" 
                        fGrvLg(oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_NUMERO:TEXT,cMsgErr,"",Val(oCFPagar[_nr]:_VALOR:TEXT),cStcf,cForn,oXml:_CARTASFRETES:_CARTAFRETE[_nzi]:_ID:TEXT)
                    ENDIF
                Endif
            EndIf
        EndIf
    EndIf
  
Return {cForn,cLoja,_cCiot}

Static Function fGetcjCte(cAxICnpj,dDataE,cCteN)

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
Local cForn         := ""
Local cLoja         := ""
local _cCiot        := ""
Local _cchv         := ""
Local __cTpcte      := ""
Local cTpCte        := ""
Local _cCnpj        := ""
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
	cJson += 'ctrcs' + CRLF

	cJson += 'Content-Disposition: form-data; name="cnpj"' + CRLF + CRLF 
	cJson += cAxICnpj + CRLF 

	cJson += 'Content-Disposition: form-data; name="dt_ini"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataE),1,4) + "-" + Substr(Dtos(dDataE),5,2) + "-" + Substr(Dtos(dDataE),7,2) + CRLF // '2021-08-01'

	cJson += 'Content-Disposition: form-data; name="dt_fim"' + CRLF + CRLF 
	cJson += Substr(Dtos(dDataE),1,4) + "-" + Substr(Dtos(dDataE),5,2) + "-" + Substr(Dtos(dDataE),7,2) + CRLF //'2021-08-30' 

	cJson += 'Content-Disposition: form-data; name="id"' + CRLF + CRLF 
	cJson += '' + CRLF 

	cJson += 'Content-Disposition: form-data; name="ambiente"' + CRLF + CRLF 
	cJson += '2' + CRLF 

	oRestClient:SetPostParams(cJson)
	//Begin Transaction
	If oRestClient:Post(aHeader)
		cXml := oRestClient:GetResult()
		oXml := XmlParser( cXml, "_", @cError, @cWarning )

        If Type("oXml:_CTRCS:_CTRC")== "O" 
            If Alltrim(oXml:_CTRCS:_CTRC:_NUMERO:TEXT)==Alltrim(cCteN)
                If Type("oXml:_CTRCS:_CTRC:_CTE:_TPCTE:TEXT")=="C"
                    cTpCte:= oXml:_CTRCS:_CTRC:_CTE:_TPCTE:TEXT
                    If cTpCte $ "NORMAL"
                        __cTpcte:="0" 
                    ElseIf   cTpCte $ "CTe de Complemento"
                        __cTpcte:="1"
                    ElseIf cTpCte $ "CTe de Anulação"
                        __cTpcte:="2"
                    EndIf
                EndIf
                If Type("oXml:_CTRCS:_CTRC:_CTE:_Chave:TEXT")=="C"
                    _cchv:= oXml:_CTRCS:_CTRC:_CTE:_Chave:TEXT
                EndIf
                If Type("oXml:_CTRCS:_CTRC:_REMETENTE:_cnpjCpf:TEXT")=="C"
                    _cCnpj:= oXml:_CTRCS:_CTRC:_REMETENTE:_cnpjCpf:TEXT 
                    If !Empty(_cCnpj)
                        DBSelectArea("SA1")
                        DbSetOrder(3)
                        If SA1->(dbSeek(xFilial("SA1")+_cCnpj))
                            cForn:= SA1->A1_COD
                            cLoja:= SA1->A1_LOJA
                        EndIF
                    EndIf
                EndIf
                Return {_cchv,__cTpcte,cForn,cLoja}
            EndIf   
        elseIf Type("oXml:_CTRCS:_CTRC")== "A" 
            For _nzi := 1 to Len(oXml:_CTRCS:_CTRC)
                If Alltrim(oXml:_CTRCS:_CTRC[_nzi]:_NUMERO:TEXT)==Alltrim(cCteN)
                    If Type("oXml:_CTRCS:_CTRC["+cvaltochar(_nzi)+"]:_CTE:_TPCTE:TEXT")=="C"
                        cTpCte:= oXml:_CTRCS:_CTRC[_nzi]:_CTE:_TPCTE:TEXT
                        If cTpCte $ "NORMAL"
                            __cTpcte:="0" 
                        ElseIf   cTpCte $ "CTe de Complemento"
                            __cTpcte:="1"
                        ElseIf cTpCte $ "CTe de Anulação"
                            __cTpcte:="2"
                        EndIf
                    EndIf
                    If Type("oXml:_CTRCS:_CTRC["+cvaltochar(_nzi)+"]:_CTE:_Chave:TEXT")=="C"
                        _cchv:= oXml:_CTRCS:_CTRC[_nzi]:_CTE:_Chave:TEXT
                    EndIf
                    If Type("oXml:_CTRCS:_CTRC["+cvaltochar(_nzi)+"]:_REMETENTE:_cnpjCpf:TEXT")=="C"
                        _cCnpj:= oXml:_CTRCS:_CTRC[_nzi]:_REMETENTE:_cnpjCpf:TEXT 
                        If !Empty(_cCnpj)
                            DBSelectArea("SA1")
                            DbSetOrder(3)
                            If SA1->(dbSeek(xFilial("SA1")+_cCnpj))
                                cForn:= SA1->A1_COD
                                cLoja:= SA1->A1_LOJA
                            EndIF
                        Endif
                    EndIf
                    Return {_cchv,__cTpcte,cForn,cLoja}
                EndIf
            Next _nzi  
        EndIf
    EndIf
      
Return {_cchv,__cTpcte,cForn,cLoja}

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

User Function fPQrb()
Local aRet  := {}
Local _cNATNCC  := Space(6)
Local _cNATNDF  := Space(6)
Private aParamBox := {}
    aAdd(aParamBox ,{1,"Natureza NCC"	,_cNATNCC	    ,"@!","","SED"	,""	,50,.T.})
    aAdd(aParamBox ,{1,"Natureza NDF"	,_cNATNDF	    ,"@!","","SED"	,""	,50,.T.})
    If ParamBox(aParamBox,"Parametros",@aRet)
        cNatNCC:= aRet[1]
        cNatNDF:= aRet[2]
        fIntegra(.F.)
    EndIF
    
Return
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

	Local nI, nJ, nK,_ngr	:= 0

	Local nLinha		:= 0
	Local nModBkp		:= 0
	Local nRecProc		:= 0
	Local aCabecC7		:= {}
	Local aLinhaC7		:= {}
	Local aItensC7		:= {}

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
    Private cPref       := "QBR"
    Private cNat        := SuperGetMV("MV_XNATCF",.F.,"202001")
    Private lMsErroAuto := .F.
	//Variáveis privadas movidas para a função inicial PRT0558
	cFornec	:= ""
	cFilArq		:= ""

	ProcRegua(0)
	IncProc()

	// Seta todos os logs anteriores como lidos
	//fSetLido()

	//-- Grava informações do módulo atual
	//StaticCall(PRT0528, fAltModulo, @cModBkp, @nModBkp)

	//-- Altera para o módulo de faturamento
	//StaticCall(PRT0528, fAltModulo, "FAT", 5)

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
		MsgAlert("Nenhum registro selecionado para processamento.", "Quebra - Carta Frete") //"Nenhum registro selecionado para processamento."
	EndIf

	If lOk
		aRegs := fGetRegSel(lAgrupa, SM0->M0_CODFIL)

		If Empty(aRegs)
			lOk := .F.
		EndIf

		If lOk
            For _ngr:= 1 to Len(aRegs)
                DbSelectArea("UQB")
                dbGoto(aRegs[_ngr,1])
                iF Alltrim(UQB->UQB_TPCON)=="QBRCTE"    
                    aVetSE1 := {}
                    aAdd(aVetSE1, {"E1_FILIAL",  FWxFilial("SE1"),  Nil})
                    aAdd(aVetSE1, {"E1_NUM",     UQB->UQB_NF,           Nil})
                    aAdd(aVetSE1, {"E1_PREFIXO", "NCC",          Nil})
                    //aAdd(aVetSE1, {"E1_PARCELA", cParcela,          Nil})
                    aAdd(aVetSE1, {"E1_TIPO",    "NCC",             Nil})
                    aAdd(aVetSE1, {"E1_NATUREZ", cNatNCC,         Nil})
                    aAdd(aVetSE1, {"E1_CLIENTE", UQB->UQB_FORNEC,          Nil})
                    aAdd(aVetSE1, {"E1_LOJA",    UQB->UQB_LOJA,             Nil})
                    //aAdd(aVetSE1, {"E1_NOMCLI",  cNomCli,           Nil})
                    aAdd(aVetSE1, {"E1_EMISSAO", If (!Empty(UQB->UQB_EMISSA),UQB->UQB_EMISSA,Date()),          Nil})
                    aAdd(aVetSE1, {"E1_VENCTO",  Date()+5,           Nil})
                    aAdd(aVetSE1, {"E1_VENCREA", DataValida(Date()+5),         Nil})
                    aAdd(aVetSE1, {"E1_VALOR",   UQB->UQB_VALOR,            Nil})
                    aAdd(aVetSE1, {"E1_TIPOCT",  UQB->UQB_XTPCTE,         Nil})
                    aAdd(aVetSE1, {"E1_CHVREF", UQB->UQB_CTEREF,        Nil})
                    aAdd(aVetSE1, {"E1_HIST",    "Quebra cte"+UQB->UQB_NF,             Nil})
                    aAdd(aVetSE1, {"E1_MOEDA",   1,                 Nil})
                    
                    //Inicia o controle de transação
                    Begin Transaction
                        //Chama a rotina automática
                        lMsErroAuto := .F.
                        MSExecAuto({|x,y| FINA040(x,y)}, aVetSE1, 3)
                        
                        //Se houve erro, mostra o erro ao usuário e desarma a transação
                        If lMsErroAuto
                            MostraErro()
                            DisarmTransaction()
                        else
                            RecLock("UQB", .F.)
                            UQB->UQB_PREFIX:= SE1->E1_PREFIXO
                            UQB->UQB_TITULO:= SE1->E1_NUM 
                            UQB->UQB_PARCEL:= SE1->E1_PARCELA
                            UQB->UQB_TIPOTI:= SE1->E1_TIPO     
                            UQB->UQB_STATUS:= "P"    
                            UQB->UQB_RECSE2:= SE1->(Recno())
                            MsUnlock()
                            nOk++
                        EndIf
                    //Finaliza a transação
                    End Transaction                
                EndIf
                //GRAVA TITULO NDF
                If Alltrim(UQB->UQB_TPCON)=="QBRCF"
                    aArray:={}
                    aAdd(aArray,{ "E2_PREFIXO" , "NDF" , NIL })
                    aAdd(aArray,{ "E2_NUM" , UQB->UQB_NF  , NIL })
                    //aAdd(aArray,{ "E2_PARCELA" , If(UQB->UQB_TPCF=="A","1","2") , NIL })
                    aAdd(aArray,{ "E2_TIPO" , "NDF" , NIL })
                    aAdd(aArray,{ "E2_NATUREZ" , cNatNDF , NIL })
                    aAdd(aArray,{ "E2_FORNECE" , UQB->UQB_FORNEC , NIL })
                    aAdd(aArray,{ "E2_LOJA"     ,  UQB->UQB_LOJA    , NIL })
                    aAdd(aArray,{ "E2_EMISSAO" , If (!Empty(UQB->UQB_EMISSA),UQB->UQB_EMISSA,Date()), NIL })
                    aAdd(aArray,{ "E2_VENCTO" , Date()+7, NIL })
                    aAdd(aArray,{ "E2_VENCREA" , DataValida(Date()+7,.T.), NIL })
                    aAdd(aArray,{ "E2_XCTRCF" , UQB->UQB_NF, NIL })
                    aAdd(aArray,{ "E2_XNUMCF" , RIGHT(UQB->UQB_IDIMP,9), NIL })
                    aAdd(aArray,{ "E2_VALOR" , UQB->UQB_VALOR , NIL })
                    aAdd(aArray,{ "E2_XTPCTE" , UQB->UQB_XTPCTE , NIL })
                    aAdd(aArray,{ "E2_XCHVREF" , UQB->UQB_CTEREF , NIL })
                    aAdd(aArray,{ "E2_XCIOT" , UQB->UQB_XCIOT , NIL })
                    //aAdd(aArray,{ "AUTBANCO" , cBanco , NIL })
                    //aAdd(aArray,{ "AUTAGENCIA" , cAgencia , NIL })
                    //aAdd(aArray,{ "AUTCONTA" , cConta , NIL })
                    pergunte("FIN050",.F.)
                    MV_PAR05:=2
                    MV_PAR09:=1
                    MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
                    /*
                    cFornec	    := UQB->UQB_FORNEC
                    cFilArq		:= UQB->UQB_FIL
                    cRegistro	:= "CF"+SUBSTR(UQB->UQB_NUMERO,3,14)
                    nValor		:= UQB->UQB_VALOR
                    cIDImp		:= UQB->UQB_IDIMP
                    cCancelLog	:= Space(TamSX3("UQF_CANCEL")[1])
                    */
                    If !lMsErroAuto
                        RecLock("UQB", .F.)
                        UQB->UQB_PREFIX:= SE2->E2_PREFIXO
                        UQB->UQB_TITULO:= SE2->E2_NUM 
                        UQB->UQB_PARCEL:= SE2->E2_PARCELA
                        UQB->UQB_TIPOTI:= SE2->E2_TIPO     
                        UQB->UQB_STATUS:= "P"    
                        UQB->UQB_RECSE2:= SE2->(Recno())
                        MsUnlock()
                        nOk++
                    Else 
                        MostraErro()
                    EndIf
                ENDIF
                /*
                aAdd(aLogs, {cFilArq, cRegistro, cFornec, nValor, cMensagem, cMsgDet, nLinha, cStatus, cIDImp, cCancelLog, cBlqEmail})
                */
                
                
            Next _ngr
		EndIf
	EndIf

	dDataBase := dDtBaseBkp

	//-- Atualização das informações na GetDados
	If !l528Auto
		If !Empty(aAtuGetDad)
			fAtuGetDad(aAtuGetDad)
		EndIf
	EndIf

	//fGrvLog()

	If !l528Auto
		// Exibe mensagem
		cMensagem 	:= 	 "Processamento de arquivos Carta Frete finalizado. Verifique o resultado abaixo." + CRLF +; // "Processamento de arquivos CTE/CRT finalizado. Verifique o resultado abaixo."
						CRLF + "Itens processados: " + cValToChar(nOk) + CRLF +; // "Itens processados: "
						"Itens não processados: " + cValToChar(nErro) + CRLF +; // "Itens não processados: "
						CRLF +  "Deseja visualizar o log de processamento?" // "Deseja visualizar o log de processamento?"
	EndIf
	//fFillDados()
	//-- Retorna para o módulo de origem
Return(Nil)

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
		If Alltrim(aAux[nI,nPsUQBFilial]) == Alltrim(cFilReg)
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

